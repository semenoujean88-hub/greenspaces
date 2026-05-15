from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from .models import User, Lot, Transfert, Certification, Parcelle

@admin.register(User)
class CustomUserAdmin(UserAdmin):
    list_display   = ['username', 'email', 'role', 'region', 'est_verifie', 'date_joined']
    list_filter    = ['role', 'est_verifie']
    search_fields  = ['username', 'email', 'telephone']
    fieldsets      = UserAdmin.fieldsets + (
        ('GreenSpace', {'fields': ('role', 'telephone', 'region', 'est_verifie')}),
    )

@admin.register(Lot)
class LotAdmin(admin.ModelAdmin):
    list_display    = ['id_lot', 'agriculteur', 'type_culture', 'poids_kg', 'statut', 'conforme_eudr', 'date_creation']
    list_filter     = ['type_culture', 'statut', 'conforme_eudr']
    search_fields   = ['id_lot', 'agriculteur__username']
    readonly_fields = ['id_lot', 'date_creation', 'hash_blockchain']

@admin.register(Transfert)
class TransfertAdmin(admin.ModelAdmin):
    list_display  = ['lot', 'expediteur', 'destinataire', 'role_destinataire', 'poids_kg', 'date_transfert']
    list_filter   = ['role_destinataire']
    search_fields = ['lot__id_lot']

@admin.register(Certification)
class CertificationAdmin(admin.ModelAdmin):
    list_display  = ['lot', 'type_cert', 'valide', 'verificateur', 'date_emission']
    list_filter   = ['type_cert', 'valide']

@admin.register(Parcelle)
class ParcelleAdmin(admin.ModelAdmin):
    list_display  = ['nom', 'agriculteur', 'region', 'superficie_ha', 'certifiee_non_deforestation']
    search_fields = ['agriculteur__username', 'region']