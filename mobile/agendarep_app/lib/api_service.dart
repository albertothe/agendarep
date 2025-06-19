import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  static const String _defaultBaseUrl = 'http://10.5.59.85:8501';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<String> getBaseUrl() async {
    return await _storage.read(key: 'base_url') ?? _defaultBaseUrl;
  }

  Future<void> setBaseUrl(String url) async {
    await _storage.write(key: 'base_url', value: url);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'token');
  }

  Future<void> setToken(String token) async {
    await _storage.write(key: 'token', value: token);
  }

  Future<String?> getSavedUser() async {
    return await _storage.read(key: 'saved_user');
  }

  Future<void> setSavedUser(String user) async {
    await _storage.write(key: 'saved_user', value: user);
  }

  Future<void> removeSavedUser() async {
    await _storage.delete(key: 'saved_user');
  }

  Future<http.Response> post(String path, Map<String, dynamic> data) async {
    final baseUrl = await getBaseUrl();
    final response = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    return response;
  }

  Future<http.Response> get(String path) async {
    final baseUrl = await getBaseUrl();
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl$path'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return response;
  }

  Future<http.Response> put(String path, Map<String, dynamic> data) async {
    final baseUrl = await getBaseUrl();
    final token = await getToken();
    final response = await http.put(
      Uri.parse('$baseUrl$path'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );
    return response;
  }
}
