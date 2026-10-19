import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'data/app_database.dart';
import 'data/matcher.dart';
import 'data/security.dart';
import 'models.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}

class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://generatalk-api.onrender.com',
  );

  final ValueNotifier<bool> authState = ValueNotifier<bool>(false);

  User? _user;

  User? get user => _user;

  Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt('current_user_id');
    if (id == null) {
      _user = null;
      authState.value = false;
      return;
    }
    final user = await _loadUser(id);
    _user = user;
    authState.value = user != null;
  }

  Future<User?> _loadUser(int userId) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('users', where: 'id = ?', whereArgs: [userId]);
    if (rows.isEmpty) return null;
    final r = rows.first;
    final gen = await _generationForId(r['generation_id'] as int?);
    return User(
      id: r['id'] as int,
      username: r['username'] as String,
      birthYear: (r['birth_year'] as int?) ?? 0,
      gender: r['gender'] as String?,
      generation: gen,
    );
  }

  Future<Generation?> _generationForId(int? id) async {
    if (id == null) return null;
    final db = await AppDatabase.instance.database;
    final rows =
        await db.query('generations', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    final r = rows.first;
    return Generation(
      id: r['id'] as int,
      key: r['key'] as String,
      name: r['name'] as String,
      startYear: r['start_year'] as int,
      endYear: r['end_year'] as int,
    );
  }

  Future<Generation?> _generationForBirthYear(int birthYear) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'generations',
      where: 'start_year <= ? AND end_year >= ?',
      whereArgs: [birthYear, birthYear],
      orderBy: 'end_year DESC',
    );
    if (rows.isNotEmpty) {
      final r = rows.first;
      return Generation(
        id: r['id'] as int,
        key: r['key'] as String,
        name: r['name'] as String,
        startYear: r['start_year'] as int,
        endYear: r['end_year'] as int,
      );
    }
    final fallback =
        await db.query('generations', orderBy: 'end_year DESC', limit: 1);
    if (fallback.isNotEmpty) {
      final r = fallback.first;
      return Generation(
        id: r['id'] as int,
        key: r['key'] as String,
        name: r['name'] as String,
        startYear: r['start_year'] as int,
        endYear: r['end_year'] as int,
      );
    }
    return null;
  }

  Future<void> _setSession(int userId) async {
    final user = await _loadUser(userId);
    _user = user;
    authState.value = user != null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('current_user_id', userId);
  }

  Future<void> logout() async {
    _user = null;
    authState.value = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_user_id');
  }

  Future<void> login({required String username, required String password}) async {
    final db = await AppDatabase.instance.database;
    final rows =
        await db.query('users', where: 'username = ?', whereArgs: [username]);
    if (rows.isEmpty ||
        !verifyPassword(password, rows.first['password_hash'] as String)) {
      throw ApiException('Credenziali non valide');
    }
    await _setSession(rows.first['id'] as int);
  }

  Future<void> register({
    required String username,
    required String password,
    required int birthYear,
    String? gender,
  }) async {
    final db = await AppDatabase.instance.database;
    final existing =
        await db.query('users', where: 'username = ?', whereArgs: [username]);
    if (existing.isNotEmpty) throw ApiException('Username già in uso');
    final gen = await _generationForBirthYear(birthYear);
    final id = await db.insert('users', {
      'username': username,
      'password_hash': hashPassword(password),
      'birth_year': birthYear,
      'gender': gender,
      'generation_id': gen?.id,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
    await _setSession(id);
  }

  Future<void> updateGender(String gender) async {
    final userId = _user?.id;
    if (userId == null) return;
    final db = await AppDatabase.instance.database;
    await db.update(
      'users',
      {'gender': gender},
      where: 'id = ?',
      whereArgs: [userId],
    );
    final user = await _loadUser(userId);
    _user = user;
  }

  Future<void> deleteAccount() async {
    final userId = _user?.id;
    if (userId == null) return;
    final db = await AppDatabase.instance.database;
    await db.delete('users', where: 'id = ?', whereArgs: [userId]);
    await logout();
  }

  Future<List<Generation>> generations() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('generations', orderBy: 'start_year DESC');
    return rows
        .map((r) => Generation(
              id: r['id'] as int,
              key: r['key'] as String,
              name: r['name'] as String,
              startYear: r['start_year'] as int,
              endYear: r['end_year'] as int,
            ))
        .toList();
  }

  Future<List<Term>> terms({String language = 'it'}) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.rawQuery('''
      SELECT t.id, t.term, t.definition, t.example, t.source,
             GROUP_CONCAT(g.key) AS gen_keys
      FROM terms t
      LEFT JOIN term_generations tg ON tg.term_id = t.id
      LEFT JOIN generations g ON g.id = tg.generation_id
      WHERE t.language = ?
      GROUP BY t.id
      ORDER BY t.term
    ''', [language]);
    return rows
        .map((r) => Term(
              id: r['id'] as int,
              term: r['term'] as String,
              definition: r['definition'] as String? ?? '',
              example: r['example'] as String? ?? '',
              source: r['source'] as String? ?? '',
              usingGenerations: (r['gen_keys'] as String? ?? '')
                  .split(',')
                  .where((s) => s.isNotEmpty)
                  .toList(),
            ))
        .toList();
  }

  Future<List<TermMatch>> analyze(String text, {String language = 'it'}) async {
    final allTerms = await terms(language: language);
    final matched = findMatches(text, allTerms);
    final userKey = _user?.generation?.key;
    final userId = _user?.id;

    final results = <TermMatch>[];
    for (final t in matched) {
      final familiar = userKey != null && t.usingGenerations.contains(userKey);
      if (!familiar && userId != null) {
        await _markDiscovered(userId, t.id);
      }
      results.add(TermMatch(
        id: t.id,
        term: t.term,
        definition: t.definition,
        example: t.example,
        familiar: familiar,
        usingGenerations: t.usingGenerations,
      ));
    }
    return results;
  }

  Future<List<Term>> discovered() async {
    final userId = _user?.id;
    if (userId == null) return [];
    final db = await AppDatabase.instance.database;
    final rows = await db.rawQuery('''
      SELECT t.id, t.term, t.definition, t.example, t.source,
             GROUP_CONCAT(g.key) AS gen_keys
      FROM discovered_terms dt
      JOIN terms t ON t.id = dt.term_id
      LEFT JOIN term_generations tg ON tg.term_id = t.id
      LEFT JOIN generations g ON g.id = tg.generation_id
      WHERE dt.user_id = ?
      GROUP BY t.id
      ORDER BY dt.discovered_at DESC
    ''', [userId]);
    return rows
        .map((r) => Term(
              id: r['id'] as int,
              term: r['term'] as String,
              definition: r['definition'] as String? ?? '',
              example: r['example'] as String? ?? '',
              source: r['source'] as String? ?? '',
              usingGenerations: (r['gen_keys'] as String? ?? '')
                  .split(',')
                  .where((s) => s.isNotEmpty)
                  .toList(),
            ))
        .toList();
  }

  Future<void> markDiscovered(int termId) async {
    final userId = _user?.id;
    if (userId == null) return;
    await _markDiscovered(userId, termId);
  }

  Future<void> _markDiscovered(int userId, int termId) async {
    final db = await AppDatabase.instance.database;
    final existing = await db.query(
      'discovered_terms',
      where: 'user_id = ? AND term_id = ?',
      whereArgs: [userId, termId],
    );
    if (existing.isEmpty) {
      await db.insert('discovered_terms', {
        'user_id': userId,
        'term_id': termId,
        'discovered_at': DateTime.now().millisecondsSinceEpoch,
      });
    }
  }

  Future<String> transcribe(List<int> pcm16,
      {int sampleRate = 16000, int channels = 1}) async {
    final http.Response res;
    try {
      res = await http
          .post(
            Uri.parse(
                '$baseUrl/api/transcribe?sample_rate=$sampleRate&channels=$channels'),
            headers: {'Content-Type': 'application/octet-stream'},
            body: pcm16,
          )
          .timeout(const Duration(seconds: 90));
    } on TimeoutException {
      throw ApiException('Tempo scaduto durante la trascrizione. Riprova.');
    }
    if (res.statusCode != 200) throw ApiException(_error(res));
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return data['text'] as String? ?? '';
  }

  String _error(http.Response res) {
    try {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return data['detail']?.toString() ?? 'Errore sconosciuto';
    } catch (_) {
      return 'Errore ${res.statusCode}';
    }
  }
}
