// lib/core/database/database_helper.dart
import 'package:sqflite/sqflite.dart';
import 'dart:convert';
import '../database/local_database.dart';

class DatabaseHelper {

  // ════════════════════════════════════════════
  // LOTS
  // ════════════════════════════════════════════

  /// Sauvegarder un lot localement
  static Future<int> saveLot(Map<String, dynamic> lot) async {
    final db = await LocalDatabase.instance;
    final now = DateTime.now().toIso8601String();

    // Vérifier si le lot existe déjà
    final existing = await db.query(
      'lots',
      where: 'id_lot = ?',
      whereArgs: [lot['id_lot']],
    );

    if (existing.isNotEmpty) {
      // Mettre à jour
      await db.update(
        'lots',
        {...lot, 'updated_at': now},
        where: 'id_lot = ?',
        whereArgs: [lot['id_lot']],
      );
      return existing.first['id'] as int;
    } else {
      // Insérer
      return await db.insert('lots', {
        ...lot,
        'created_at': now,
        'updated_at': now,
        'synced': lot['synced'] ?? 0,
      });
    }
  }

  /// Récupérer tous les lots locaux
  static Future<List<Map<String, dynamic>>> getLots({
    String? statut,
    bool? syncedOnly,
  }) async {
    final db = await LocalDatabase.instance;
    String? where;
    List<dynamic>? whereArgs;

    if (statut != null && syncedOnly != null) {
      where     = 'statut = ? AND synced = ?';
      whereArgs = [statut, syncedOnly ? 1 : 0];
    } else if (statut != null) {
      where     = 'statut = ?';
      whereArgs = [statut];
    } else if (syncedOnly != null) {
      where     = 'synced = ?';
      whereArgs = [syncedOnly ? 1 : 0];
    }

    return await db.query(
      'lots',
      where:    where,
      whereArgs:whereArgs,
      orderBy:  'created_at DESC',
    );
  }

  /// Récupérer un lot par son ID
  static Future<Map<String, dynamic>?> getLotById(
      String idLot) async {
    final db  = await LocalDatabase.instance;
    final res = await db.query(
      'lots',
      where:    'id_lot = ?',
      whereArgs:[idLot],
    );
    return res.isNotEmpty ? res.first : null;
  }

  /// Lots non encore synchronisés
  static Future<List<Map<String, dynamic>>>
      getLotsNonSynces() async {
    final db = await LocalDatabase.instance;
    return await db.query(
      'lots',
      where:    'synced = 0',
      orderBy:  'created_at ASC',
    );
  }

  /// Marquer un lot comme synchronisé
  static Future<void> marquerLotSynce(
      String idLot, String hashBlockchain) async {
    final db = await LocalDatabase.instance;
    await db.update(
      'lots',
      {
        'synced':          1,
        'hash_blockchain': hashBlockchain,
        'updated_at':      DateTime.now().toIso8601String(),
      },
      where:    'id_lot = ?',
      whereArgs:[idLot],
    );
  }

  // ════════════════════════════════════════════
  // TRANSFERTS
  // ════════════════════════════════════════════

  static Future<int> saveTransfert(
      Map<String, dynamic> transfert) async {
    final db = await LocalDatabase.instance;
    return await db.insert('transferts', {
      ...transfert,
      'created_at': DateTime.now().toIso8601String(),
      'synced': 0,
    });
  }

  static Future<List<Map<String, dynamic>>> getTransfertsLot(
      String idLot) async {
    final db = await LocalDatabase.instance;
    return await db.query(
      'transferts',
      where:    'lot_id_lot = ?',
      whereArgs:[idLot],
      orderBy:  'created_at ASC',
    );
  }

  static Future<List<Map<String, dynamic>>>
      getTransfertsNonSynces() async {
    final db = await LocalDatabase.instance;
    return await db.query(
      'transferts',
      where:   'synced = 0',
      orderBy: 'created_at ASC',
    );
  }

  // ════════════════════════════════════════════
  // SYNC QUEUE
  // ════════════════════════════════════════════

  /// Ajouter une opération à la file d'attente
  static Future<int> addToSyncQueue({
    required String operation,
    required String endpoint,
    required Map<String, dynamic> payload,
  }) async {
    final db = await LocalDatabase.instance;
    return await db.insert('sync_queue', {
      'operation':  operation,
      'endpoint':   endpoint,
      'payload':    jsonEncode(payload),
      'tentatives': 0,
      'statut':     'EN_ATTENTE',
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Récupérer les opérations en attente
  static Future<List<Map<String, dynamic>>>
      getSyncQueueEnAttente() async {
    final db = await LocalDatabase.instance;
    return await db.query(
      'sync_queue',
      where:    'statut = ? AND tentatives < 5',
      whereArgs:['EN_ATTENTE'],
      orderBy:  'created_at ASC',
    );
  }

  /// Marquer une opération comme réussie
  static Future<void> marquerSyncReussie(int id) async {
    final db = await LocalDatabase.instance;
    await db.update(
      'sync_queue',
      {'statut': 'REUSSIE'},
      where:    'id = ?',
      whereArgs:[id],
    );
  }

  /// Incrémenter le compteur de tentatives
  static Future<void> incrementerTentative(int id) async {
    final db = await LocalDatabase.instance;
    await db.rawUpdate(
      'UPDATE sync_queue SET tentatives = tentatives + 1, '
      'last_try = ?, statut = CASE WHEN tentatives >= 4 '
      'THEN ? ELSE statut END WHERE id = ?',
      [DateTime.now().toIso8601String(), 'ECHEC', id],
    );
  }

  // ════════════════════════════════════════════
  // UTILISATEUR LOCAL
  // ════════════════════════════════════════════

  static Future<void> saveUtilisateur(
      Map<String, dynamic> user, String token) async {
    final db = await LocalDatabase.instance;
    await db.delete('utilisateur_local');
    await db.insert('utilisateur_local', {
      ...user,
      'token':      token,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  static Future<Map<String, dynamic>?> getUtilisateur() async {
    final db  = await LocalDatabase.instance;
    final res = await db.query('utilisateur_local', limit: 1);
    return res.isNotEmpty ? res.first : null;
  }

  static Future<void> supprimerUtilisateur() async {
    final db = await LocalDatabase.instance;
    await db.delete('utilisateur_local');
  }

  // ════════════════════════════════════════════
  // DASHBOARD CACHE
  // ════════════════════════════════════════════

  static Future<void> cacheDashboard(
      String cle, dynamic valeur) async {
    final db = await LocalDatabase.instance;
    await db.insert(
      'dashboard_cache',
      {
        'cle':       cle,
        'valeur':    jsonEncode(valeur),
        'updated_at':DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<dynamic> getDashboardCache(String cle) async {
    final db  = await LocalDatabase.instance;
    final res = await db.query(
      'dashboard_cache',
      where:    'cle = ?',
      whereArgs:[cle],
    );
    if (res.isEmpty) return null;
    return jsonDecode(res.first['valeur'] as String);
  }

  // ════════════════════════════════════════════
  // STATISTIQUES LOCALES
  // ════════════════════════════════════════════

  static Future<Map<String, dynamic>> getStatsLocales() async {
    final db = await LocalDatabase.instance;

    final totalLots = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM lots'));
    final lotsNonSynces = Sqflite.firstIntValue(
        await db.rawQuery(
            'SELECT COUNT(*) FROM lots WHERE synced = 0'));
    final transfertsNonSynces = Sqflite.firstIntValue(
        await db.rawQuery(
            'SELECT COUNT(*) FROM transferts WHERE synced = 0'));
    final syncEnAttente = Sqflite.firstIntValue(
        await db.rawQuery(
            'SELECT COUNT(*) FROM sync_queue WHERE statut = "EN_ATTENTE"'));

    return {
      'total_lots':            totalLots ?? 0,
      'lots_non_synces':       lotsNonSynces ?? 0,
      'transferts_non_synces': transfertsNonSynces ?? 0,
      'sync_en_attente':       syncEnAttente ?? 0,
    };
  }
}