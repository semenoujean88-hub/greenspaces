from rest_framework import viewsets, status, generics
from rest_framework.decorators import action, api_view, permission_classes
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.response import Response
from rest_framework_simplejwt.tokens import RefreshToken
from django.contrib.auth import authenticate
from django.db.models import Sum, Count
import qrcode, io, base64
from PIL import Image

from .models import User, Parcelle, Lot, Transfert, Certification, RapportEUDR, StatsDashboard
from .serializers import (
    UserSerializer, InscriptionSerializer, ParcelleSerializer,
    LotSerializer, LotListSerializer, TransfertSerializer,
    CertificationSerializer, RapportEUDRSerializer, StatsDashboardSerializer
)


# ─────────────────────────────────────────────
# AUTH
# ─────────────────────────────────────────────
class InscriptionView(generics.CreateAPIView):
    """POST /api/auth/inscription/ — créer un compte selon le rôle"""
    serializer_class   = InscriptionSerializer
    permission_classes = [AllowAny]

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()
        refresh = RefreshToken.for_user(user)
        return Response({
            'user':    UserSerializer(user).data,
            'access':  str(refresh.access_token),
            'refresh': str(refresh),
        }, status=status.HTTP_201_CREATED)


@api_view(['POST'])
@permission_classes([AllowAny])
def connexion(request):
    """POST /api/auth/connexion/ — login"""
    username = request.data.get('username')
    password = request.data.get('password')
    user = authenticate(username=username, password=password)
    if not user:
        return Response({'erreur': 'Identifiants invalides'}, status=status.HTTP_401_UNAUTHORIZED)
    refresh = RefreshToken.for_user(user)
    return Response({
        'user':    UserSerializer(user).data,
        'access':  str(refresh.access_token),
        'refresh': str(refresh),
    })


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def profil(request):
    """GET /api/auth/profil/ — données de l'utilisateur connecté"""
    return Response(UserSerializer(request.user).data)


# ─────────────────────────────────────────────
# DASHBOARD
# ─────────────────────────────────────────────
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def dashboard_national(request):
    """
    GET /api/dashboard/national/
    Dashboard Ministère de l'Agriculture - Togo
    """
    from django.utils import timezone
    from datetime import timedelta

    today = timezone.now()
    mois_actuel = today.month

    # Stats globales
    total_lots   = Lot.objects.count()
    total_certif = Certification.objects.filter(valide=True).count()
    total_agri   = User.objects.filter(role='AGRICULTEUR').count()
    total_coop   = User.objects.filter(role='COOPERATIVE').count()
    conformes    = Lot.objects.filter(conforme_eudr=True).count()
    pc_conforme  = round((conformes / total_lots * 100) if total_lots > 0 else 0, 1)

    # Production mensuelle (6 derniers mois)
    mois_labels = ['Jan','Fév','Mar','Avr','Mai','Jun','Jul','Aoû','Sep','Oct','Nov','Déc']
    production_mensuelle = []
    for m in range(max(1, mois_actuel - 5), mois_actuel + 1):
        tonnage = Lot.objects.filter(
            date_creation__month=m, date_creation__year=today.year
        ).aggregate(t=Sum('poids_kg'))['t'] or 0
        production_mensuelle.append({'mois': mois_labels[m - 1], 'tonnes': round(tonnage / 1000, 1)})

    # Zones de production
    zones = {}
    for lot in Lot.objects.select_related('agriculteur'):
        r = lot.agriculteur.region or 'Autre'
        zones[r] = zones.get(r, 0) + float(lot.poids_kg)

    # Répartition certifications
    repartition = {}
    for c in Certification.objects.filter(valide=True).values('type_cert').annotate(n=Count('id')):
        repartition[c['type_cert']] = c['n']

    return Response({
        'total_lots':          total_lots,
        'total_certifications':total_certif,
        'total_agriculteurs':  total_agri,
        'total_cooperatives':  total_coop,
        'conformes_eudr':      conformes,
        'pc_conforme_eudr':    pc_conforme,
        'production_mensuelle':production_mensuelle,
        'zones_production':    zones,
        'repartition_certif':  repartition,
    })


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def dashboard_agriculteur(request):
    """GET /api/dashboard/agriculteur/ — stats personnelles de l'agriculteur"""
    lots = Lot.objects.filter(agriculteur=request.user)
    return Response({
        'total_lots':    lots.count(),
        'total_kg':      lots.aggregate(t=Sum('poids_kg'))['t'] or 0,
        'conformes':     lots.filter(conforme_eudr=True).count(),
        'en_transit':    lots.filter(statut='EN_TRANSIT').count(),
        'mes_lots':      LotListSerializer(lots.order_by('-date_creation')[:10], many=True).data,
    })


# ─────────────────────────────────────────────
# LOTS
# ─────────────────────────────────────────────
class LotViewSet(viewsets.ModelViewSet):
    """
    /api/lots/                  GET liste, POST créer
    /api/lots/{id}/             GET détail, PATCH modifier
    /api/lots/{id}/transferer/  POST transférer le lot
    /api/lots/{id}/certifier/   POST ajouter une certification
    /api/lots/scanner/          POST vérifier par QR code ou id_lot
    """
    permission_classes = [IsAuthenticated]

    def get_serializer_class(self):
        if self.action == 'list':
            return LotListSerializer
        return LotSerializer

    def get_queryset(self):
        user = self.request.user
        qs   = Lot.objects.select_related('agriculteur', 'parcelle').prefetch_related('transferts', 'certifications')

        if user.role == 'AGRICULTEUR':
            return qs.filter(agriculteur=user)
        elif user.role == 'COOPERATIVE':
            # lots reçus par la coopérative
            ids = Transfert.objects.filter(destinataire=user).values_list('lot_id', flat=True)
            return qs.filter(id__in=ids)
        elif user.role == 'TRANSFORMATEUR':
            ids = Transfert.objects.filter(destinataire=user).values_list('lot_id', flat=True)
            return qs.filter(id__in=ids)
        elif user.role in ['EXPORTATEUR', 'VERIFICATEUR', 'ADMIN']:
            return qs.all()
        return qs.none()

    def perform_create(self, serializer):
        lot = serializer.save(agriculteur=self.request.user)
        self._generer_qr(lot)
        self._enregistrer_blockchain(lot)

    def _generer_qr(self, lot):
        """Génère le QR code du lot"""
        qr = qrcode.QRCode(version=1, box_size=10, border=4)
        qr.add_data(lot.id_lot)
        qr.make(fit=True)
        img = qr.make_image(fill='black', back_color='white')
        buffer = io.BytesIO()
        img.save(buffer, format='PNG')
        from django.core.files.base import ContentFile
        lot.qr_code.save(f'{lot.id_lot}.png', ContentFile(buffer.getvalue()), save=True)

    def _enregistrer_blockchain(self, lot):
        """Enregistre le lot sur Polygon (appel web3.py)"""
        # TODO: intégrer web3.py + smart contract GreenSpace
        # from web3 import Web3
        # w3 = Web3(Web3.HTTPProvider(settings.POLYGON_RPC_URL))
        # tx = contract.functions.declarerRecolte(...).build_transaction(...)
        # lot.hash_blockchain = tx_hash
        # lot.save()
        pass

    @action(detail=True, methods=['post'])
    def transferer(self, request, pk=None):
        """POST /api/lots/{id}/transferer/ — créer un transfert de lot"""
        lot = self.get_object()
        data = {**request.data, 'lot': lot.id}
        serializer = TransfertSerializer(data=data)
        if serializer.is_valid():
            transfert = serializer.save(expediteur=request.user)
            # Mettre à jour le statut du lot
            statut_map = {
                'COOPERATIVE':    'EN_TRANSIT',
                'TRANSFORMATEUR': 'EN_TRANSFORMATION',
                'EXPORTATEUR':    'EN_EXPORT',
            }
            nouveau_statut = statut_map.get(request.data.get('role_destinataire'), lot.statut)
            lot.statut = nouveau_statut
            lot.save()
            return Response(TransfertSerializer(transfert).data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    @action(detail=True, methods=['post'])
    def certifier(self, request, pk=None):
        """POST /api/lots/{id}/certifier/ — vérificateur ajoute une certification"""
        if request.user.role not in ['VERIFICATEUR', 'ADMIN']:
            return Response({'erreur': 'Non autorisé'}, status=status.HTTP_403_FORBIDDEN)
        lot  = self.get_object()
        data = {**request.data, 'lot': lot.id}
        serializer = CertificationSerializer(data=data)
        if serializer.is_valid():
            cert = serializer.save(verificateur=request.user)
            # Vérifier conformité EUDR globale
            if cert.type_cert == 'EUDR' and cert.valide:
                lot.conforme_eudr = True
                lot.save()
            return Response(CertificationSerializer(cert).data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    @action(detail=False, methods=['post'])
    def scanner(self, request):
        """POST /api/lots/scanner/ — vérifier un lot via id_lot ou QR"""
        id_lot = request.data.get('id_lot', '').strip().upper()
        if not id_lot:
            return Response({'erreur': 'id_lot requis'}, status=status.HTTP_400_BAD_REQUEST)
        try:
            lot = Lot.objects.prefetch_related('transferts__expediteur',
                                               'transferts__destinataire',
                                               'certifications').get(id_lot=id_lot)
            return Response(LotSerializer(lot).data)
        except Lot.DoesNotExist:
            return Response({'erreur': 'Lot introuvable'}, status=status.HTTP_404_NOT_FOUND)


# ─────────────────────────────────────────────
# RAPPORTS EUDR
# ─────────────────────────────────────────────
class RapportEUDRViewSet(viewsets.ModelViewSet):
    """
    /api/rapports/              GET liste
    /api/rapports/{id}/generer/ POST générer le PDF EUDR
    """
    serializer_class   = RapportEUDRSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        if self.request.user.role == 'EXPORTATEUR':
            return RapportEUDR.objects.filter(exportateur=self.request.user)
        return RapportEUDR.objects.all()

    def perform_create(self, serializer):
        serializer.save(exportateur=self.request.user)

    @action(detail=True, methods=['post'])
    def generer(self, request, pk=None):
        """Génère le PDF de conformité EUDR et l'enregistre sur Polygon"""
        rapport = self.get_object()
        lot     = rapport.lot
        # Construction du rapport
        data_rapport = {
            'id_lot':         lot.id_lot,
            'agriculteur':    lot.agriculteur.get_full_name(),
            'gps':            f"{lot.latitude}, {lot.longitude}",
            'date_recolte':   str(lot.date_recolte),
            'type_culture':   lot.type_culture,
            'poids_kg':       str(lot.poids_kg),
            'certifications': [c.type_cert for c in lot.certifications.filter(valide=True)],
            'historique':     [
                {
                    'acteur': t.destinataire.get_full_name(),
                    'role':   t.role_destinataire,
                    'date':   str(t.date_transfert),
                    'poids':  str(t.poids_kg),
                }
                for t in lot.transferts.all()
            ],
            'conforme_eudr': lot.conforme_eudr,
            'hash_blockchain': lot.hash_blockchain,
        }
        # TODO: générer PDF avec reportlab
        return Response({'rapport': data_rapport, 'message': 'Rapport EUDR généré avec succès'})


# ─────────────────────────────────────────────
# PARCELLES
# ─────────────────────────────────────────────
class ParcelleViewSet(viewsets.ModelViewSet):
    serializer_class   = ParcelleSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return Parcelle.objects.filter(agriculteur=self.request.user)

    def perform_create(self, serializer):
        serializer.save(agriculteur=self.request.user)
