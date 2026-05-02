// lib/core/sync/sync_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../database/database_helper.dart';
import '../connectivity/connectivity_service.dart';
import '../../api_service.dart';
import '../../constants.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  bool _isSyncing       = false;
  Timer? _syncTimer;
  StreamSubscription<bool>? _connectivitySub;

  // Notifier l'UI de l'état de synchronisation
  final _syncController = StreamController<SyncStatus>.broadcast();
  Stream<SyncStatus> get onSyncStatusChanged => _syncController.stream;

  // ── Démarrer la synchronisation automatique ─
  void startAutoSync() {
    // Écouter les changements de connexion
    _connectivitySub = ConnectivityService().listen((isConnected) {
      if (isConnected && !_isSyncing) {
        syncAll();
      }
    });

    // Synchronisation périodique toutes les 2 minutes
    _syncTimer = Timer.periodic(const Duration(minutes: 2), (_) async {
      final connected = await ConnectivityService().isConnected();
      if (connected && !_isSyncing) {
        syncAll();
      }
    });
  }

  void stopAutoSync() {
    _syncTimer?.cancel();
    _connectivitySub?.cancel();
  }

  // ── Synchronisation complète ─────────────────
  Future<SyncResult> syncAll() async {
    if (_isSyncing) {
      return SyncResult(succes: 0, echecs: 0, message: 'Sync déjà en cours');
    }

    _isSyncing = true;
    _emit(SyncStatus.enCours);

    int succes = 0;
    int echecs = 0;

    try {
      // 1. Syncer les lots non synchronisés
      final resultLots = await _syncLots();
      succes += resultLots.succes;
      echecs += resultLots.echecs;

      // 2. Syncer les transferts non synchronisés
      final resultTransferts = await _syncTransferts();
      succes += resultTransferts.succes;
      echecs += resultTransferts.echecs;

      // 3. Vider la file d'attente générale
      final resultQueue = await _processSyncQueue();
      succes += resultQueue.succes;
      echecs += resultQueue.echecs;

      // 4. Rafraîchir les données depuis le serveur
      await _refreshFromServer();

      _emit(succes > 0 ? SyncStatus.reussie : SyncStatus.idle);

      return SyncResult(
        succes:  succes,
        echecs:  echecs,
        message: '$succes opération(s) synchronisée(s)',
      );
    } catch (e) {
      _emit(SyncStatus.echec);
      return SyncResult(succes: succes, echecs: echecs + 1,
          message: 'Erreur: $e');
    } finally {
      _isSyncing = false;
    }
  }

  // ── Syncer les lots ──────────────────────────
  Future<SyncResult> _syncLots() async {
    int succes = 0;
    int echecs = 0;

    final lots = await DatabaseHelper.getLotsNonSynces();
    for (final lot in lots) {
      try {
        final headers = await _authHeaders();
        final res = await http.post(
          Uri.parse('$kBaseUrl/lots/'),
          headers: headers,
          body: jsonEncode({
            'type_culture': lot['type_culture'],
            'poids_kg':     lot['poids_kg'],
            'latitude':     lot['latitude'],
            'longitude':    lot['longitude'],
            'date_recolte': lot['date_recolte'],
          }),
        ).timeout(const Duration(seconds: 10));

        if (res.statusCode == 201) {
          final data     = jsonDecode(res.body);
          final hashBc   = data['hash_blockchain'] ?? '';
          await DatabaseHelper.marquerLotSynce(
              lot['id_lot'] as String, hashBc);
          succes++;
        } else {
          echecs++;
        }
      } catch (_) {
        echecs++;
      }
    }
    return SyncResult(succes: succes, echecs: echecs);
  }

  // ── Syncer les transferts ────────────────────
  Future<SyncResult> _syncTransferts() async {
    int succes = 0;
    int echecs = 0;

    final transferts = await DatabaseHelper.getTransfertsNonSynces();
    for (final t in transferts) {
      try {
        final headers = await _authHeaders();
        final lotId   = t['lot_id_local'];
        final res = await http.post(
          Uri.parse('$kBaseUrl/lots/$lotId/transferer/'),
          headers: headers,
          body: jsonEncode({
            'destinataire':       t['destinataire_id'],
            'role_destinataire':  t['role_destinataire'],
            'poids_kg':           t['poids_kg'],
            'prix_fcfa':          t['prix_fcfa'],
            'moyen_paiement':     t['moyen_paiement'],
          }),
        ).timeout(const Duration(seconds: 10));

        if (res.statusCode == 201) {
          final _ = await DatabaseHelper.getStatsLocales();
          succes++;
        } else {
          echecs++;
        }
      } catch (_) {
        echecs++;
      }
    }
    return SyncResult(succes: succes, echecs: echecs);
  }

  // ── Vider la file d'attente ──────────────────
  Future<SyncResult> _processSyncQueue() async {
    int succes = 0;
    int echecs = 0;

    final queue = await DatabaseHelper.getSyncQueueEnAttente();
    for (final item in queue) {
      try {
        final headers = await _authHeaders();
        final payload = jsonDecode(item['payload'] as String);
        final res = await http.post(
          Uri.parse('$kBaseUrl${item['endpoint']}'),
          headers: headers,
          body: jsonEncode(payload),
        ).timeout(const Duration(seconds: 10));

        if (res.statusCode >= 200 && res.statusCode < 300) {
          await DatabaseHelper.marquerSyncReussie(
              item['id'] as int);
          succes++;
        } else {
          await DatabaseHelper.incrementerTentative(
              item['id'] as int);
          echecs++;
        }
      } catch (_) {
        await DatabaseHelper.incrementerTentative(
            item['id'] as int);
        echecs++;
      }
    }
    return SyncResult(succes: succes, echecs: echecs);
  }

  // ── Rafraîchir depuis le serveur ─────────────
  Future<void> _refreshFromServer() async {
    try {
      // Rafraîchir les lots
      final lots = await ApiService.getLots();
      for (final lot in lots) {
        await DatabaseHelper.saveLot({
          ...Map<String, dynamic>.from(lot),
          'synced': 1,
        });
      }

      // Rafraîchir le dashboard
      try {
        final dashboard = await ApiService.getDashboardNational();
        await DatabaseHelper.cacheDashboard('national', dashboard);
      } catch (_) {}
    } catch (_) {}
  }

  // ── Headers d'authentification ───────────────
  Future<Map<String, String>> _authHeaders() async {
    final token = await ApiService.getToken();
    return {
      'Content-Type':  'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  void _emit(SyncStatus status) {
    if (!_syncController.isClosed) {
      _syncController.add(status);
    }
  }

  void dispose() {
    stopAutoSync();
    _syncController.close();
  }
}

// ── Modèles ──────────────────────────────────────
enum SyncStatus { idle, enCours, reussie, echec }

class SyncResult {
  final int    succes;
  final int    echecs;
  final String message;
  SyncResult({
    required this.succes,
    required this.echecs,
    this.message = '',
  });
}