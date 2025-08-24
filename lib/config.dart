import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pms_external_service_flutter/models/field_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A centralized singleton class for managing global application configuration.
/// (一個集中的單例類別，用於管理全域應用程式設定。)
///
/// This class holds static variables for configuration data that needs to be
/// accessed from anywhere in the app, such as API keys, base URLs, and theme
/// preferences. It also provides methods for loading and saving these
/// preferences to the device's local storage using [SharedPreferences].
/// (這個類別持有需要從應用程式任何地方存取的靜態設定資料，例如 API 金鑰、基礎 URL 和主題偏好。
/// 它也提供了使用 [SharedPreferences] 從裝置的本機儲存中載入和儲存這些偏好的方法。)
class Config {
  /// The base URL for the Nuwa Robotics PMS API.
  /// (Nuwa Robotics PMS API 的基礎 URL。)
  static String baseUrl = "https://api.nuwarobotics.com/v1";

  /// The name of the currently selected UI theme.
  /// (當前選擇的 UI 主題名稱。)
  static String theme = "darkly";

  /// The production API token for authorization. Loaded from SharedPreferences.
  /// (用於授權的生產環境 API token。從 SharedPreferences 載入。)
  static String prodToken = "";

  /// A cached list of field data fetched from the external service.
  /// (從外部服務獲取的場域資料快取列表。)
  static List<Field> fields = [];

  /// A cached list of trigger records for the ResetPage.
  /// (用於重置頁面的觸發記錄快取列表。)
  static List<Map<String, dynamic>> triggerRecords = [];

  /// Loads the API token from local storage.
  /// (從本機儲存載入 API token。)
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

  /// Saves the API token to local storage.
  /// (儲存 API token 到本機儲存。)
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

  /// Clears the API token from local storage.
  /// (從本機儲存清除 API token。)
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

  /// Loads the UI theme preference from local storage.
  /// (從本機儲存載入 UI 主題偏好。)
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

  /// Saves the UI theme preference to local storage.
  /// (儲存 UI 主題偏好到本機儲存。)
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

  /// Main loading method, fetches all necessary initial data.
  /// (主要的載入方法，獲取所有必要初始資料。)
  static Future<void> load() async {
    await fetchFields();
  }

  /// Placeholder for a save method.
  /// (儲存方法的佔位符。)
  static Future<void> save() async {
    print("Config save() called but no implementation");
  }

  /// Fetches the detailed field and map data from the external service API.
  /// (從外部服務 API 獲取詳細的場域和地圖資料。)
  /// This involves a two-step process: triggering a refresh and then fetching the map data.
  /// (這包含一個兩步驟過程：觸發刷新，然後獲取地圖資料。)
  static Future<void> fetchFields() async {
    if (prodToken.isEmpty) {
      print("No prodToken available, skip fetchFields");
      return;
    }

    try {
      // The API requires a "trigger" call before fetching the map.
      // (API 要求在獲取地圖前先進行 "trigger" 呼叫。)
      final refreshUrl = Uri.parse("http://64.110.100.118:8001/trigger-refresh");
      final headers = {'Authorization': prodToken};
      final refreshResponse = await http.post(refreshUrl, headers: headers);

      if (refreshResponse.statusCode == 200) {
        // The backend seems to require a delay after the trigger.
        // (後端在觸發後似乎需要一個延遲。)
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