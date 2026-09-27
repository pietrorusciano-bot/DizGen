import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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
    defaultValue: 'http://10.0.2.2:8000',
  );

  String? _token;
  User? _user;

  String? get token => _token;
  User? get user => _user;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    final userJson = prefs.getString('user');
    if (userJson != null) {
      try {
        _user = User.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
      } catch (_) {
        _user = null;
      }
    }
  }

  Future<void> _saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  Future<void> _saveUser(User user) async {
    _user = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', jsonEncode(user.toJson()));
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
  }

  Future<void> deleteAccount() async {
    final res = await http.delete(
      Uri.parse('$baseUrl/api/profile'),
      headers: _headers,
    );
    if (res.statusCode != 204 && res.statusCode != 200) {
      throw ApiException(_error(res));
    }
    await logout();
  }

  Future<List<Generation>> generations() async {
    final res = await http.get(Uri.parse('$baseUrl/api/generations'));
    if (res.statusCode != 200) throw ApiException('Errore nel caricamento generazioni');
    final data = jsonDecode(res.body) as List<dynamic>;
    return data
        .map((e) => Generation.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> register({
    required String username,
    required String password,
    required int birthYear,
    String? gender,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
        'birth_year': birthYear,
        if (gender != null) 'gender': gender,
      }),
    );
    if (res.statusCode != 201) throw ApiException(_error(res));
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    await _saveToken(data['access_token'] as String);
    await _saveUser(User.fromJson(data['user'] as Map<String, dynamic>));
  }

  Future<void> updateGender(String gender) async {
    final res = await http.patch(
      Uri.parse('$baseUrl/api/profile'),
      headers: _headers,
      body: jsonEncode({'gender': gender}),
    );
    if (res.statusCode != 200) throw ApiException(_error(res));
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    _user = User.fromJson(data);
    await _saveUser(_user!);
  }

  Future<void> login({required String username, required String password}) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'username': username, 'password': password},
    );
    if (res.statusCode != 200) throw ApiException(_error(res));
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    await _saveToken(data['access_token'] as String);
    await _saveUser(User.fromJson(data['user'] as Map<String, dynamic>));
  }

  Future<List<Term>> terms({String language = 'it'}) async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/terms?language=$language'),
      headers: _headers,
    );
    if (res.statusCode != 200) throw ApiException(_error(res));
    final data = jsonDecode(res.body) as List<dynamic>;
    return data.map((e) => Term.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<TermMatch>> analyze(String text, {String language = 'it'}) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/analyze'),
      headers: _headers,
      body: jsonEncode({'text': text, 'language': language}),
    );
    if (res.statusCode != 200) throw ApiException(_error(res));
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final matches = data['matches'] as List<dynamic>;
    return matches
        .map((e) => TermMatch.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<String> transcribe(List<int> pcm16,
      {int sampleRate = 16000, int channels = 1}) async {
    final res = await http.post(
      Uri.parse(
          '$baseUrl/api/transcribe?sample_rate=$sampleRate&channels=$channels'),
      headers: {
        'Content-Type': 'application/octet-stream',
        if (_token != null) 'Authorization': 'Bearer $_token',
      },
      body: pcm16,
    );
    if (res.statusCode != 200) throw ApiException(_error(res));
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return data['text'] as String? ?? '';
  }

  Future<List<Term>> discovered() async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/discovered'),
      headers: _headers,
    );
    if (res.statusCode != 200) throw ApiException(_error(res));
    final data = jsonDecode(res.body) as List<dynamic>;
    return data.map((e) => Term.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> markDiscovered(int termId) async {
    await http.post(
      Uri.parse('$baseUrl/api/discovered/$termId'),
      headers: _headers,
    );
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
