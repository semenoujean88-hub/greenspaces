from rest_framework import serializers
from .models import User, Parcelle, Lot, Transfert, Certification, RapportEUDR, StatsDashboard


class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model  = User
        fields = ['id', 'username', 'email', 'first_name', 'last_name',
                  'role', 'telephone', 'region', 'est_verifie', 'photo_profil']
        read_only_fields = ['est_verifie']


class InscriptionSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, min_length=6)

    class Meta:
        model  = User
        fields = ['username', 'email', 'first_name', 'last_name',
                  'password', 'role', 'telephone', 'region']

    def create(self, validated_data):
        password = validated_data.pop('password')
        user = User(**validated_data)
        user.set_password(password)
        user.save()
        return user


class ParcelleSerializer(serializers.ModelSerializer):
    class Meta:
        model  = Parcelle
        fields = '__all__'
        read_only_fields = ['agriculteur', 'date_enregistrement']


class CertificationSerializer(serializers.ModelSerializer):
    verificateur_nom = serializers.CharField(source='verificateur.get_full_name', read_only=True)

    class Meta:
        model  = Certification
        fields = '__all__'
        read_only_fields = ['verificateur', 'date_emission']


class TransfertSerializer(serializers.ModelSerializer):
    expediteur_nom   = serializers.CharField(source='expediteur.get_full_name', read_only=True)
    destinataire_nom = serializers.CharField(source='destinataire.get_full_name', read_only=True)

    class Meta:
        model  = Transfert
        fields = '__all__'
        read_only_fields = ['expediteur', 'date_transfert']


class LotSerializer(serializers.ModelSerializer):
    transferts     = TransfertSerializer(many=True, read_only=True)
    certifications = CertificationSerializer(many=True, read_only=True)
    agriculteur_nom = serializers.CharField(source='agriculteur.get_full_name', read_only=True)

    class Meta:
        model  = Lot
        fields = '__all__'
        read_only_fields = ['id_lot', 'agriculteur', 'hash_blockchain',
                            'date_creation', 'qr_code', 'conforme_eudr']


class LotListSerializer(serializers.ModelSerializer):
    """Version légère pour les listes"""
    agriculteur_nom = serializers.CharField(source='agriculteur.get_full_name', read_only=True)

    class Meta:
        model  = Lot
        fields = ['id', 'id_lot', 'type_culture', 'poids_kg', 'statut',
                  'conforme_eudr', 'date_recolte', 'agriculteur_nom', 'qr_code']


class RapportEUDRSerializer(serializers.ModelSerializer):
    lot_details = LotListSerializer(source='lot', read_only=True)

    class Meta:
        model  = RapportEUDR
        fields = '__all__'
        read_only_fields = ['exportateur', 'date_generation', 'hash_blockchain']


class StatsDashboardSerializer(serializers.ModelSerializer):
    class Meta:
        model  = StatsDashboard
        fields = '__all__'
