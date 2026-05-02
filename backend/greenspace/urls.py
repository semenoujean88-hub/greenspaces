from django.urls import path, include
from rest_framework.routers import DefaultRouter
from rest_framework_simplejwt.views import TokenRefreshView
from . import views

router = DefaultRouter()
router.register(r'lots',     views.LotViewSet,       basename='lot')
router.register(r'rapports', views.RapportEUDRViewSet, basename='rapport')
router.register(r'parcelles',views.ParcelleViewSet,  basename='parcelle')

urlpatterns = [
    # Auth
    path('auth/inscription/',  views.InscriptionView.as_view(), name='inscription'),
    path('auth/connexion/',    views.connexion,                 name='connexion'),
    path('auth/profil/',       views.profil,                    name='profil'),
    path('auth/refresh/',      TokenRefreshView.as_view(),      name='token_refresh'),

    # Dashboard
    path('dashboard/national/',    views.dashboard_national,    name='dashboard-national'),
    path('dashboard/agriculteur/', views.dashboard_agriculteur, name='dashboard-agriculteur'),

    # Ressources
    path('', include(router.urls)),
]
