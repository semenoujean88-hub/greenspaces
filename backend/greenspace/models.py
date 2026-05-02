from django.db import models
from django.contrib.auth.models import AbstractUser
import uuid


# ──────────────────────────────────────────────
# UTILISATEUR MULTI-RÔLE
# ──────────────────────────────────────────────
class User(AbstractUser):
    ROLE_CHOICES = [
        ('AGRICULTEUR',   'Agriculteur'),
        ('EXPORTATEUR',   'Exportateur'),
        ('VERIFICATEUR',  'Vérificateur'),
        ('TRANSFORMATEUR','Transformateur'),
        ('COOPERATIVE',   'Coopérative'),
        ('ADMIN',         'Admin / Ministère'),
    ]
    role            = models.CharField(max_length=20, choices=ROLE_CHOICES)
    telephone       = models.CharField(max_length=20, blank=True)
    region          = models.CharField(max_length=100, blank=True)
    est_verifie     = models.BooleanField(default=False)
    date_inscription= models.DateTimeField(auto_now_add=True)
    photo_profil    = models.ImageField(upload_to='profils/', blank=True)

    def __str__(self):
        return f"{self.username} ({self.role})"


# ──────────────────────────────────────────────
# PARCELLE AGRICOLE
# ──────────────────────────────────────────────
class Parcelle(models.Model):
    agriculteur     = models.ForeignKey(User, on_delete=models.CASCADE, related_name='parcelles')
    nom             = models.CharField(max_length=200)
    superficie_ha   = models.DecimalField(max_digits=10, decimal_places=2)
    latitude        = models.DecimalField(max_digits=10, decimal_places=7)
    longitude       = models.DecimalField(max_digits=10, decimal_places=7)
    region          = models.CharField(max_length=100)
    certifiee_non_deforestation = models.BooleanField(default=False)
    date_enregistrement = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Parcelle {self.nom} — {self.agriculteur.username}"


# ──────────────────────────────────────────────
# LOT DE PRODUCTION
# ──────────────────────────────────────────────
class Lot(models.Model):
    CULTURE_CHOICES = [('CACAO', 'Cacao'), ('CAFE', 'Café')]
    STATUT_CHOICES  = [
        ('ENREGISTRE',    'Enregistré'),
        ('EN_TRANSIT',    'En transit'),
        ('EN_TRANSFORMATION', 'En transformation'),
        ('TRANSFORME',    'Transformé'),
        ('EN_EXPORT',     'En cours d\'export'),
        ('EXPORTE',       'Exporté'),
        ('REFUSE',        'Refusé'),
    ]

    id_lot          = models.CharField(max_length=30, unique=True, editable=False)
    agriculteur     = models.ForeignKey(User, on_delete=models.PROTECT, related_name='lots')
    parcelle        = models.ForeignKey(Parcelle, on_delete=models.PROTECT, null=True, blank=True)
    type_culture    = models.CharField(max_length=10, choices=CULTURE_CHOICES, default='CACAO')
    poids_kg        = models.DecimalField(max_digits=10, decimal_places=2)
    date_recolte    = models.DateField()
    latitude        = models.DecimalField(max_digits=10, decimal_places=7, null=True, blank=True)
    longitude       = models.DecimalField(max_digits=10, decimal_places=7, null=True, blank=True)
    statut          = models.CharField(max_length=20, choices=STATUT_CHOICES, default='ENREGISTRE')
    conforme_eudr   = models.BooleanField(default=False)
    prix_final_fcfa = models.DecimalField(max_digits=15, decimal_places=2, null=True, blank=True)
    hash_blockchain = models.CharField(max_length=255, blank=True)  # tx hash Polygon
    date_creation   = models.DateTimeField(auto_now_add=True)
    qr_code         = models.ImageField(upload_to='qrcodes/', blank=True)

    def save(self, *args, **kwargs):
        if not self.id_lot:
            # Format: LOT-TG-2026-XXXX
            from django.utils import timezone
            annee = timezone.now().year
            count = Lot.objects.filter(date_creation__year=annee).count() + 1
            self.id_lot = f"LOT-TG-{annee}-{count:04d}"
        super().save(*args, **kwargs)

    def __str__(self):
        return self.id_lot


# ──────────────────────────────────────────────
# TRANSFERT (chaîne de custody)
# ──────────────────────────────────────────────
class Transfert(models.Model):
    ROLE_DEST = [
        ('COLLECTEUR',    'Collecteur'),
        ('COOPERATIVE',   'Coopérative'),
        ('TRANSFORMATEUR','Transformateur'),
        ('EXPORTATEUR',   'Exportateur'),
    ]
    lot             = models.ForeignKey(Lot, on_delete=models.PROTECT, related_name='transferts')
    expediteur      = models.ForeignKey(User, on_delete=models.PROTECT, related_name='envois')
    destinataire    = models.ForeignKey(User, on_delete=models.PROTECT, related_name='receptions')
    role_destinataire = models.CharField(max_length=20, choices=ROLE_DEST)
    poids_kg        = models.DecimalField(max_digits=10, decimal_places=2)
    prix_fcfa       = models.DecimalField(max_digits=15, decimal_places=2, null=True, blank=True)
    moyen_paiement  = models.CharField(max_length=20, blank=True)  # FLOOZ, TMONEY, ESPECES
    date_transfert  = models.DateTimeField(auto_now_add=True)
    hash_blockchain = models.CharField(max_length=255, blank=True)
    notes           = models.TextField(blank=True)

    def __str__(self):
        return f"{self.lot.id_lot} → {self.destinataire.username}"


# ──────────────────────────────────────────────
# CERTIFICATION
# ──────────────────────────────────────────────
class Certification(models.Model):
    TYPE_CHOICES = [
        ('NON_DEFORESTATION', 'Non-déforestation'),
        ('BIO',               'Agriculture biologique'),
        ('FAIR_TRADE',        'Commerce équitable'),
        ('EUDR',              'Conformité EUDR'),
    ]
    lot             = models.ForeignKey(Lot, on_delete=models.CASCADE, related_name='certifications')
    verificateur    = models.ForeignKey(User, on_delete=models.PROTECT)
    type_cert       = models.CharField(max_length=30, choices=TYPE_CHOICES)
    valide          = models.BooleanField(default=False)
    date_emission   = models.DateTimeField(auto_now_add=True)
    date_expiration = models.DateField(null=True, blank=True)
    document        = models.FileField(upload_to='certifications/', blank=True)
    notes           = models.TextField(blank=True)

    def __str__(self):
        return f"{self.type_cert} — {self.lot.id_lot}"


# ──────────────────────────────────────────────
# RAPPORT EUDR
# ──────────────────────────────────────────────
class RapportEUDR(models.Model):
    lot             = models.OneToOneField(Lot, on_delete=models.CASCADE, related_name='rapport_eudr')
    exportateur     = models.ForeignKey(User, on_delete=models.PROTECT)
    date_generation = models.DateTimeField(auto_now_add=True)
    pdf             = models.FileField(upload_to='rapports_eudr/', blank=True)
    hash_blockchain = models.CharField(max_length=255, blank=True)
    soumis_douanes  = models.BooleanField(default=False)

    def __str__(self):
        return f"EUDR — {self.lot.id_lot}"


# ──────────────────────────────────────────────
# STATISTIQUES DASHBOARD (cache calculé)
# ──────────────────────────────────────────────
class StatsDashboard(models.Model):
    date            = models.DateField(auto_now=True)
    total_lots      = models.IntegerField(default=0)
    total_certifications = models.IntegerField(default=0)
    total_agriculteurs = models.IntegerField(default=0)
    total_cooperatives = models.IntegerField(default=0)
    tonnage_mensuel = models.JSONField(default=dict)   # {"Jan": 12, "Fev": 18 ...}
    repartition_certif = models.JSONField(default=dict) # {"Bio": 320, "Fair": 280 ...}
    zones_production = models.JSONField(default=dict)  # {"Plateaux": 423, ...}

    class Meta:
        verbose_name = "Statistiques Dashboard"
