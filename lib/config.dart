import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pms_external_service_flutter/models/field_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A centralized class for managing global application configuration.
///
/// This class holds static variables for configuration data that needs to be
/// accessed from anywhere in the app, such as API keys, base URLs, and theme
/// preferences. It also provides methods for loading and saving these
/// preferences to the device's local storage using [SharedPreferences].
class Config {
  /// The base URL for the Nuwa Robotics PMS API.
  static String baseUrl = "https://api.nuwarobotics.com/v1";

  /// The name of the currently selected UI theme.
  static String theme = "darkly";

  /// The production API token for authorization.
  static String prodToken = "";

  /// A cached list of field data fetched from the external service.
  static List<Field> fields = [];

  /// A cached list of trigger records for the ResetPage.
  static List<Map<String, dynamic>> triggerRecords = [];

  /// Loads the API token from local storage.
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

  /// 清除 token
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
    // This method now contains the full logic to get the detailed field map.
    if (prodToken.isEmpty) {
      print("No prodToken available, skip fetchFields");
      return;
    }

    try {
      // The API requires a "trigger" call before fetching the map.
      final refreshUrl = Uri.parse("http://64.110.100.118:8001/trigger-refresh");
      final headers = {'Authorization': prodToken};
      final refreshResponse = await http.post(refreshUrl, headers: headers);

      if (refreshResponse.statusCode == 200) {
        // A 3-second delay seems to be required by the backend.
        // await Future.delayed(const Duration(seconds: 3)); // REMOVED to improve performance

        final mapUrl = Uri.parse("http://64.110.100.118:8001/field-map");
        final mapResponse = await http.get(mapUrl, headers: headers);

        if (mapResponse.statusCode == 200) {
          final newFields = fieldFromJson(utf8.decode(mapResponse.bodyBytes));
          fields = newFields;
          print("Fetched and updated fields: ${fields.map((f) => f.fieldName).toList()}");
        } else {
          print("field-map fetch failed: ${mapResponse.statusCode}");
          fields.clear(); // Clear fields on failure
        }
      } else {
        print("trigger-refresh failed: ${refreshResponse.statusCode}");
        fields.clear(); // Clear fields on failure
      }
    } catch (e) {
      print("Fetch fields failed with exception: $e");
      fields.clear();
    }
  }
}