import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'constants.dart';

class ApiService {
  static String? _token;

  // ── Token management ──────────────────────
  static Future<void> saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', token);
  }

  static Future<String?> getToken() async {
    if (_token != null) return _token;
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('access_token');
    return _token;
  }

  static Future<void> logout() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
  }

  static Future<Map<String, String>> _headers() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<dynamic> _handleResponse(http.Response res) {
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return Future.value(body);
    }
    throw Exception(body['erreur'] ?? body['detail'] ?? 'Erreur ${res.statusCode}');
  }

  // ── AUTH ──────────────────────────────────
  static Future<Map> inscription(Map<String, dynamic> data) async {
    final res = await http.post(
      Uri.parse('$kBaseUrl/auth/inscription/'),
      headers: await _headers(),
      body: jsonEncode(data),
    );
    final body = await _handleResponse(res);
    await saveToken(body['access']);
    return body;
  }

  static Future<Map> connexion(String username, String password) async {
    final res = await http.post(
      Uri.parse('$kBaseUrl/auth/connexion/'),
      headers: await _headers(),
      body: jsonEncode({'username': username, 'password': password}),
    );
    final body = await _handleResponse(res);
    await saveToken(body['access']);
    return body;
  }

  static Future<Map> getProfil() async {
    final res = await http.get(
      Uri.parse('$kBaseUrl/auth/profil/'),
      headers: await _headers(),
    );
    return await _handleResponse(res);
  }

  // ── DASHBOARD ─────────────────────────────
  static Future<Map> getDashboardNational() async {
    final res = await http.get(
      Uri.parse('$kBaseUrl/dashboard/national/'),
      headers: await _headers(),
    );
    return await _handleResponse(res);
  }

  static Future<Map> getDashboardAgriculteur() async {
    final res = await http.get(
      Uri.parse('$kBaseUrl/dashboard/agriculteur/'),
      headers: await _headers(),
    );
    return await _handleResponse(res);
  }

  // ── LOTS ──────────────────────────────────
  static Future<List> getLots() async {
    final res = await http.get(
      Uri.parse('$kBaseUrl/lots/'),
      headers: await _headers(),
    );
    return await _handleResponse(res);
  }

  static Future<Map> getLot(int id) async {
    final res = await http.get(
      Uri.parse('$kBaseUrl/lots/$id/'),
      headers: await _headers(),
    );
    return await _handleResponse(res);
  }

  static Future<Map> creerLot(Map<String, dynamic> data) async {
    final res = await http.post(
      Uri.parse('$kBaseUrl/lots/'),
      headers: await _headers(),
      body: jsonEncode(data),
    );
    return await _handleResponse(res);
  }

  static Future<Map> scannerLot(String idLot) async {
    final res = await http.post(
      Uri.parse('$kBaseUrl/lots/scanner/'),
      headers: await _headers(),
      body: jsonEncode({'id_lot': idLot}),
    );
    return await _handleResponse(res);
  }

  static Future<Map> transfererLot(int lotId, Map<String, dynamic> data) async {
    final res = await http.post(
      Uri.parse('$kBaseUrl/lots/$lotId/transferer/'),
      headers: await _headers(),
      body: jsonEncode(data),
    );
    return await _handleResponse(res);
  }

  static Future<Map> certifierLot(int lotId, Map<String, dynamic> data) async {
    final res = await http.post(
      Uri.parse('$kBaseUrl/lots/$lotId/certifier/'),
      headers: await _headers(),
      body: jsonEncode(data),
    );
    return await _handleResponse(res);
  }

  // ── RAPPORTS EUDR ─────────────────────────
  static Future<List> getRapports() async {
    final res = await http.get(
      Uri.parse('$kBaseUrl/rapports/'),
      headers: await _headers(),
    );
    return await _handleResponse(res);
  }

  static Future<Map> genererRapportEUDR(int rapportId) async {
    final res = await http.post(
      Uri.parse('$kBaseUrl/rapports/$rapportId/generer/'),
      headers: await _headers(),
    );
    return await _handleResponse(res);
  }
}
