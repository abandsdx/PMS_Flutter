import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pms_external_service_flutter/models/field_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A centralized class for managing global application configuration.
class Config {
  static String baseUrl = "https://api.nuwarobotics.com/v1";
  static String theme = "darkly";
  static String prodToken = "";
  static List<Field> fields = [];
  static List<Map<String, dynamic>> triggerRecords = [];

  static Future<void> loadToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      prodToken = prefs.getString('Prod_token') ?? '';
      print("Loaded token: $prodToken");
    } catch (e) {
      print("Failed to load token: $e");
      prodToken = '';
    }
  }

  static Future<void> saveToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('Prod_token', token);
      prodToken = token;
      print("Saved token: $prodToken");
    } catch (e) {
      print("Failed to save token: $e");
    }
  }

  static Future<void> clearToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('Prod_token');
      prodToken = '';
      print("Cleared token");
    } catch (e) {
      print("Failed to clear token: $e");
    }
  }

  static Future<void> loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      theme = prefs.getString('theme') ?? 'darkly';
      print("Loaded theme: $theme");
    } catch (e) {
      print("Failed to load theme: $e");
      theme = 'darkly';
    }
  }

  static Future<void> saveTheme(String newTheme) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('theme', newTheme);
      theme = newTheme;
      print("Saved theme: $theme");
    } catch (e) {
      print("Failed to save theme: $e");
    }
  }

  static Future<void> load() async {
    await fetchFields();
  }

  static Future<void> save() async {
    print("Config save() called but no implementation");
  }

  static Future<void> fetchFields() async {
    if (prodToken.isEmpty) {
      print("No prodToken available, skip fetchFields");
      return;
    }
    try {
      final refreshUrl = Uri.parse("http://64.110.100.118:8001/trigger-refresh");
      final headers = {'Authorization': prodToken};
      final refreshResponse = await http.post(refreshUrl, headers: headers);
      if (refreshResponse.statusCode == 200) {
        final mapUrl = Uri.parse("http://64.110.100.118:8001/field-map");
        final mapResponse = await http.get(mapUrl, headers: headers);
        if (mapResponse.statusCode == 200) {
          final newFields = fieldFromJson(utf8.decode(mapResponse.bodyBytes));
          fields = newFields;
          print("Fetched and updated fields: ${fields.map((f) => f.fieldName).toList()}");
        } else {
          print("field-map fetch failed: ${mapResponse.statusCode}");
          fields.clear();
        }
      } else {
        print("trigger-refresh failed: ${refreshResponse.statusCode}");
        fields.clear();
      }
    } catch (e) {
      print("Fetch fields failed with exception: $e");
      fields.clear();
    }
  }
}