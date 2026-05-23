import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../config/api_config.dart';
import '../main.dart';

class ApiClient {
  static const String _tokenKey = 'access_token';
  static const String _refreshKey = 'refresh_token';
  static const String _userKey = 'user_data';

  static Future<void> saveTokens(String accessToken, String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, accessToken);
    await prefs.setString(_refreshKey, refreshToken);
  }

  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(userData));
  }

  static Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_userKey);
    if (data != null) return jsonDecode(data);
    return null;
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshKey);
    await prefs.remove(_userKey);
  }

  static Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  static Future<bool>? _refreshFuture;

  static Future<bool> _attemptRefresh() async {
    if (_refreshFuture != null) return _refreshFuture!;
    _refreshFuture = _doRefresh();
    final result = await _refreshFuture!;
    _refreshFuture = null;
    return result;
  }

  static Future<bool> _doRefresh() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString(_refreshKey);
    if (refreshToken == null) return false;

    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/auth/refresh-token');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = jsonDecode(response.body);
        final tokens = body['data']['tokens'];
        await saveTokens(tokens['accessToken'], tokens['refreshToken']);
        return true;
      }
    } catch (_) {}
    return false;
  }

  static Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (auth) {
      final token = await getAccessToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static Future<Map<String, dynamic>> get(String endpoint, {bool auth = true}) async {
    final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
    var headers = await _headers(auth: auth);
    var response = await http.get(url, headers: headers);
    
    if (response.statusCode == 401 && auth) {
      final refreshed = await _attemptRefresh();
      if (refreshed) {
        headers = await _headers(auth: auth);
        response = await http.get(url, headers: headers);
      }
    }
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> body, {bool auth = true}) async {
    final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
    var headers = await _headers(auth: auth);
    var response = await http.post(url, headers: headers, body: jsonEncode(body));
    
    if (response.statusCode == 401 && auth) {
      final refreshed = await _attemptRefresh();
      if (refreshed) {
        headers = await _headers(auth: auth);
        response = await http.post(url, headers: headers, body: jsonEncode(body));
      }
    }
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> put(String endpoint, Map<String, dynamic> body, {bool auth = true}) async {
    final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
    var headers = await _headers(auth: auth);
    var response = await http.put(url, headers: headers, body: jsonEncode(body));
    
    if (response.statusCode == 401 && auth) {
      final refreshed = await _attemptRefresh();
      if (refreshed) {
        headers = await _headers(auth: auth);
        response = await http.put(url, headers: headers, body: jsonEncode(body));
      }
    }
    return _handleResponse(response);
  }

  static Map<String, dynamic> _handleResponse(http.Response response) {
    final body = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) return body;
    
    final message = body['message'] ?? body['error'] ?? 'Something went wrong';
    
    if (response.statusCode == 401) {
      clearAll();
      navigatorKey.currentState?.pushNamedAndRemoveUntil('/login', (route) => false);
    }
    
    throw ApiException(message, response.statusCode);
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;
  ApiException(this.message, this.statusCode);
  @override
  String toString() => message;
}
