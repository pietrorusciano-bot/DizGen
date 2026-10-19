import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  static const _dbName = 'dizgen.db';
  static const _dbVersion = 1;
  static const _seedAsset = 'assets/seed/terms_dump.json';
  static const _seedVersionKey = 'seed_version';

  static const List<Map<String, Object>> _generations = [
    {'key': 'boomers', 'name': 'Boomers', 'start_year': 1946, 'end_year': 1964},
    {'key': 'genx', 'name': 'Generazione X', 'start_year': 1965, 'end_year': 1980},
    {'key': 'millennials', 'name': 'Millennials', 'start_year': 1981, 'end_year': 1996},
    {'key': 'genz', 'name': 'Generazione Z', 'start_year': 1997, 'end_year': 2012},
    {'key': 'genalpha', 'name': 'Generazione Alpha', 'start_year': 2013, 'end_year': 2025},
  ];

  Database? _db;

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<void> initialize() async {
    await database;
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    final path = p.join(dir, _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.transaction((txn) async {
      await txn.execute('''
        CREATE TABLE generations (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          key TEXT NOT NULL UNIQUE,
          name TEXT NOT NULL,
          start_year INTEGER NOT NULL,
          end_year INTEGER NOT NULL
        )
      ''');
      await txn.execute('''
        CREATE TABLE terms (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          language TEXT NOT NULL DEFAULT 'it',
          term TEXT NOT NULL,
          definition TEXT NOT NULL DEFAULT '',
          example TEXT NOT NULL DEFAULT '',
          source TEXT NOT NULL DEFAULT ''
        )
      ''');
      await txn.execute(
        'CREATE INDEX idx_terms_term ON terms(term)',
      );
      await txn.execute('''
        CREATE TABLE term_generations (
          term_id INTEGER NOT NULL,
          generation_id INTEGER NOT NULL,
          PRIMARY KEY (term_id, generation_id),
          FOREIGN KEY (term_id) REFERENCES terms(id) ON DELETE CASCADE,
          FOREIGN KEY (generation_id) REFERENCES generations(id) ON DELETE CASCADE
        )
      ''');
      await txn.execute('''
        CREATE TABLE users (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          username TEXT NOT NULL UNIQUE,
          password_hash TEXT NOT NULL,
          birth_year INTEGER,
          gender TEXT,
          generation_id INTEGER,
          created_at INTEGER
        )
      ''');
      await txn.execute('''
        CREATE TABLE discovered_terms (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          term_id INTEGER NOT NULL,
          discovered_at INTEGER,
          FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
          FOREIGN KEY (term_id) REFERENCES terms(id) ON DELETE CASCADE
        )
      ''');
      await txn.execute('''
        CREATE TABLE app_meta (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL
        )
      ''');
    });
    await _seed(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {}

  Future<void> _seed(Database db) async {
    final already = await db.query(
      'app_meta',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [_seedVersionKey],
    );
    if (already.isNotEmpty) return;

    final raw = await rootBundle.loadString(_seedAsset);
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final terms = data['terms'] as List<dynamic>? ?? [];

    await db.transaction((txn) async {
      final genIds = <String, int>{};
      for (final g in _generations) {
        final id = await txn.insert('generations', g);
        genIds[g['key'] as String] = id;
      }

      for (final t in terms) {
        final m = t as Map<String, dynamic>;
        final gens = (m['generations'] as List<dynamic>? ?? [])
            .map((e) => e as String)
            .toList();
        final termId = await txn.insert('terms', {
          'language': m['language'] as String? ?? 'it',
          'term': m['term'] as String? ?? '',
          'definition': m['definition'] as String? ?? '',
          'example': m['example'] as String? ?? '',
          'source': m['source'] as String? ?? '',
        });
        for (final key in gens) {
          final gid = genIds[key];
          if (gid != null) {
            await txn.insert('term_generations', {
              'term_id': termId,
              'generation_id': gid,
            });
          }
        }
      }

      await txn.insert('app_meta', {'key': _seedVersionKey, 'value': '1'});
    });
  }
}
