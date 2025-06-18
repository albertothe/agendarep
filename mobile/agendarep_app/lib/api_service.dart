import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  static const String _defaultBaseUrl = 'http://10.0.2.2:8501';
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
}
