import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Config {
  static String baseUrl = "https://api.nuwarobotics.com/v1";
  static String theme = "darkly";
  static String prodToken = "";
  static Map<String, String> fieldMap = {};
  static List<Map<String, dynamic>> triggerRecords = [];

  /// 讀取 token
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

  /// 儲存 token
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

  /// 讀取 theme
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

  /// 儲存 theme
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
    // 建議改成儲存整個設定物件，或移除此方法
    print("Config save() called but no implementation");
  }

  static Future<void> fetchFields() async {
    if (prodToken.isEmpty) {
      print("No prodToken available, skip fetchFields");
      return;
    }
    fieldMap.clear();
    final url = Uri.parse("$baseUrl/rms/mission/fields");
    final headers = {
      'Authorization': prodToken,
      'Content-Type': 'application/json',
    };

    try {
      final resp = await http.get(url, headers: headers);
      if (resp.statusCode == 200) {
        final jsonResp = jsonDecode(resp.body);
        final List<dynamic> fields = jsonResp['data']['payload'] ?? [];
        for (var field in fields) {
          if (field['fieldName'] != null && field['fieldId'] != null) {
            fieldMap[field['fieldName']] = field['fieldId'];
          }
        }
        print("Fetched fields: ${fieldMap.keys.toList()}");
      } else {
        print("fetchFields failed: ${resp.statusCode}");
      }
    } catch (e) {
      print("Fetch fields failed: $e");
    }
  }
}