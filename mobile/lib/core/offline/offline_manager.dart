// lib/core/offline/offline_manager.dart
import 'dart:async';
import '../database/database_helper.dart';
import '../sync/sync_service.dart';
import '../connectivity/connectivity_service.dart';
import '../../api_service.dart';

class OfflineManager {
  static final OfflineManager _instance = OfflineManager._internal();
  factory OfflineManager() => _instance;
  OfflineManager._internal();

  bool _isOnline = false;
  bool get isOnline => _isOnline;

  final _connectivityService = ConnectivityService();
  final _syncService         = SyncService();

  StreamSubscription<bool>? _sub;

  // ── Initialisation au démarrage de l'app ────
  Future<void> init() async {
    // Vérifier la connexion initiale
    _isOnline = await _connectivityService.isConnected();

    // Écouter les changements
    _sub = _connectivityService.listen((connected) {
      _isOnline = connected;
    });

    // Démarrer la synchronisation automatique
    _syncService.startAutoSync();

    // Première synchronisation si en ligne
    if (_isOnline) {
      _syncService.syncAll();
    }
  }

  // ── Créer un lot (online ou offline) ────────
  Future<OfflineResult> creerLot(
      Map<String, dynamic> data) async {
    if (_isOnline) {
      // En ligne → envoyer directement au serveur
      try {
        final res = await ApiService.creerLot(data);
        final lot = Map<String, dynamic>.from(res);

        // Sauvegarder aussi localement
        await DatabaseHelper.saveLot({...lot, 'synced': 1});

        return OfflineResult(
          succes:  true,
          data:    lot,
          message: 'Lot enregistré et synchronisé ✓',
          source:  DataSource.serveur,
        );
      } catch (e) {
        // Si le serveur échoue → sauvegarder localement
        return await _saveLotOffline(data);
      }
    } else {
      // Hors ligne → sauvegarder localement
      return await _saveLotOffline(data);
    }
  }

  Future<OfflineResult> _saveLotOffline(
      Map<String, dynamic> data) async {
    // Générer un ID local temporaire
    final now    = DateTime.now();
    final idLot  = 'LOT-TG-${now.year}-LOCAL-${now.millisecondsSinceEpoch}';

    final lotLocal = {
      'id_lot':       idLot,
      'type_culture': data['type_culture'] ?? 'CACAO',
      'poids_kg':     data['poids_kg'],
      'latitude':     data['latitude'],
      'longitude':    data['longitude'],
      'date_recolte': data['date_recolte'],
      'statut':       'ENREGISTRE',
      'synced':       0,
    };

    await DatabaseHelper.saveLot(lotLocal);

    // Ajouter à la file de synchronisation
    await DatabaseHelper.addToSyncQueue(
      operation: 'POST',
      endpoint:  '/lots/',
      payload:   data,
    );

    return OfflineResult(
      succes:  true,
      data:    lotLocal,
      message: 'Lot enregistré localement — synchronisation en attente',
      source:  DataSource.local,
    );
  }

  // ── Récupérer les lots (online ou offline) ──
  Future<OfflineResult> getLots() async {
    if (_isOnline) {
      try {
        final res = await ApiService.getLots();
        final lots = res
            .map((l) => Map<String, dynamic>.from(l))
            .toList();

        // Mettre à jour le cache local
        for (final lot in lots) {
          await DatabaseHelper.saveLot({...lot, 'synced': 1});
        }

        return OfflineResult(
          succes:  true,
          data:    lots,
          message: 'Données à jour',
          source:  DataSource.serveur,
        );
      } catch (_) {
        return await _getLotsOffline();
      }
    } else {
      return await _getLotsOffline();
    }
  }

  Future<OfflineResult> _getLotsOffline() async {
    final lots = await DatabaseHelper.getLots();
    return OfflineResult(
      succes:  true,
      data:    lots,
      message: 'Données locales — hors ligne',
      source:  DataSource.local,
    );
  }

  // ── Scanner un lot (online ou offline) ──────
  Future<OfflineResult> scannerLot(String idLot) async {
    if (_isOnline) {
      try {
        final res = await ApiService.scannerLot(idLot);
        final lot = Map<String, dynamic>.from(res);
        await DatabaseHelper.saveLot({...lot, 'synced': 1});
        return OfflineResult(
            succes: true, data: lot, source: DataSource.serveur);
      } catch (_) {
        return await _scannerLotLocal(idLot);
      }
    } else {
      return await _scannerLotLocal(idLot);
    }
  }

  Future<OfflineResult> _scannerLotLocal(String idLot) async {
    final lot = await DatabaseHelper.getLotById(idLot);
    if (lot != null) {
      return OfflineResult(
        succes:  true,
        data:    lot,
        message: 'Données locales',
        source:  DataSource.local,
      );
    }
    return OfflineResult(
      succes:  false,
      message: 'Lot introuvable localement',
      source:  DataSource.local,
    );
  }

  // ── Transférer un lot (online ou offline) ───
  Future<OfflineResult> transfererLot(
      int lotId, String idLot, Map<String, dynamic> data) async {
    if (_isOnline) {
      try {
        final res = await ApiService.transfererLot(lotId, data);
        return OfflineResult(
          succes:  true,
          data:    Map<String, dynamic>.from(res),
          message: 'Transfert enregistré ✓',
          source:  DataSource.serveur,
        );
      } catch (_) {
        return await _transfererLotOffline(idLot, data);
      }
    } else {
      return await _transfererLotOffline(idLot, data);
    }
  }

  Future<OfflineResult> _transfererLotOffline(
      String idLot, Map<String, dynamic> data) async {
    await DatabaseHelper.saveTransfert({
      'lot_id_lot':       idLot,
      'role_destinataire':data['role_destinataire'],
      'poids_kg':         data['poids_kg'],
      'prix_fcfa':        data['prix_fcfa'],
      'moyen_paiement':   data['moyen_paiement'] ?? 'ESPECES',
      'date_transfert':   DateTime.now().toIso8601String(),
    });
    return OfflineResult(
      succes:  true,
      message: 'Transfert enregistré localement — sync en attente',
      source:  DataSource.local,
    );
  }

  // ── Statistiques de synchronisation ─────────
  Future<Map<String, dynamic>> getSyncStats() async {
    return await DatabaseHelper.getStatsLocales();
  }

  // ── Forcer une synchronisation manuelle ─────
  Future<SyncResult> forcerSync() async {
    if (!_isOnline) {
      return SyncResult(
          succes: 0,
          echecs: 0,
          message: 'Pas de connexion internet');
    }
    return await _syncService.syncAll();
  }

  Stream<SyncStatus> get syncStatus =>
      _syncService.onSyncStatusChanged;

  void dispose() {
    _sub?.cancel();
    _syncService.dispose();
  }
}

// ── Modèles résultat ─────────────────────────────
enum DataSource { serveur, local }

class OfflineResult {
  final bool       succes;
  final dynamic    data;
  final String     message;
  final DataSource source;

  OfflineResult({
    required this.succes,
    this.data,
    this.message = '',
    this.source  = DataSource.serveur,
  });

  bool get estLocal => source == DataSource.local;
}