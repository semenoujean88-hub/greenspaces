// lib/core/database/local_database.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalDatabase {
  static Database? _db;
  static const int _version = 1;
  static const String _dbName = 'greenspace.db';

  // ── Singleton ────────────────────────────────
  static Future<Database> get instance async {
    _db ??= await _initDB();
    return _db!;
  }

  static Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), _dbName);
    return await openDatabase(
      path,
      version: _version,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // ── Création des tables ──────────────────────
  static Future<void> _onCreate(Database db, int version) async {
    // Table des lots
    await db.execute('''
      CREATE TABLE lots (
        id              INTEGER PRIMARY KEY AUTOINCREMENT,
        id_lot          TEXT UNIQUE,
        agriculteur_id  INTEGER,
        agriculteur_nom TEXT,
        type_culture    TEXT DEFAULT 'CACAO',
        poids_kg        REAL,
        date_recolte    TEXT,
        latitude        REAL,
        longitude       REAL,
        statut          TEXT DEFAULT 'ENREGISTRE',
        conforme_eudr   INTEGER DEFAULT 0,
        prix_final_fcfa REAL,
        hash_blockchain TEXT,
        qr_code_path    TEXT,
        synced          INTEGER DEFAULT 0,
        created_at      TEXT,
        updated_at      TEXT
      )
    ''');

    // Table des transferts
    await db.execute('''
      CREATE TABLE transferts (
        id                  INTEGER PRIMARY KEY AUTOINCREMENT,
        lot_id_local        INTEGER,
        lot_id_lot          TEXT,
        expediteur_id       INTEGER,
        expediteur_nom      TEXT,
        destinataire_id     INTEGER,
        destinataire_nom    TEXT,
        role_destinataire   TEXT,
        poids_kg            REAL,
        prix_fcfa           REAL,
        moyen_paiement      TEXT,
        date_transfert      TEXT,
        hash_blockchain     TEXT,
        synced              INTEGER DEFAULT 0,
        created_at          TEXT
      )
    ''');

    // Table des certifications
    await db.execute('''
      CREATE TABLE certifications (
        id              INTEGER PRIMARY KEY AUTOINCREMENT,
        lot_id_lot      TEXT,
        verificateur_id INTEGER,
        verificateur_nom TEXT,
        type_cert       TEXT,
        valide          INTEGER DEFAULT 0,
        date_emission   TEXT,
        notes           TEXT,
        synced          INTEGER DEFAULT 0,
        created_at      TEXT
      )
    ''');

    // Table de la file d'attente de synchronisation
    await db.execute('''
      CREATE TABLE sync_queue (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        operation   TEXT,
        endpoint    TEXT,
        payload     TEXT,
        tentatives  INTEGER DEFAULT 0,
        statut      TEXT DEFAULT 'EN_ATTENTE',
        created_at  TEXT,
        last_try    TEXT
      )
    ''');

    // Table utilisateur local (session)
    await db.execute('''
      CREATE TABLE utilisateur_local (
        id          INTEGER PRIMARY KEY,
        username    TEXT,
        email       TEXT,
        nom         TEXT,
        prenom      TEXT,
        role        TEXT,
        telephone   TEXT,
        region      TEXT,
        token       TEXT,
        created_at  TEXT
      )
    ''');

    // Table des stats dashboard (cache)
    await db.execute('''
      CREATE TABLE dashboard_cache (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        cle         TEXT UNIQUE,
        valeur      TEXT,
        updated_at  TEXT
      )
    ''');
  }

  static Future<void> _onUpgrade(
      Database db, int oldVersion, int newVersion) async {
    // Migration future si besoin
  }

  // ── Fermer la base ───────────────────────────
  static Future<void> close() async {
    final db = _db;
    if (db != null) {
      await db.close();
      _db = null;
    }
  }
}