import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Config {
  static const String baseUrl = "https://api.nuwarobotics.com/v1";
  static const String theme = "darkly";
  static String prodToken = "";
  static Map<String, String> fieldMap = {};
  static List<Map<String, dynamic>> triggerRecords = [];

  static const String _tokenKey = 'prod_token';
  static const String _triggerRecordKey = 'trigger_records';

  /// 載入設定（包含 token 與場域資訊）
  static Future<void> load() async {
    await _loadToken();
    await fetchFields();
  }

  /// 儲存 token 到 SharedPreferences
  static Future<void> saveToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, prodToken);
  }

  /// 載入 token
  static Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    prodToken = prefs.getString(_tokenKey) ?? "";
  }

  /// 取得場域列表並更新 fieldMap
  static Future<void> fetchFields() async {
    fieldMap.clear();
    final url = Uri.parse("$baseUrl/rms/mission/fields");

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': prodToken,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final fields = data['data']?['payload'] ?? [];
        for (var field in fields) {
          fieldMap[field['fieldName']] = field['fieldId'];
        }
      } else {
        print("Fetch fields failed with status: ${response.statusCode}");
      }
    } catch (e) {
      print("Fetch fields exception: $e");
    }
  }

  /// (可選) 儲存觸發紀錄
  static Future<void> saveTriggerRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(triggerRecords);
    await prefs.setString(_triggerRecordKey, jsonString);
  }

  /// (可選) 載入觸發紀錄
  static Future<void> loadTriggerRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_triggerRecordKey);
    if (jsonString != null) {
      final records = json.decode(jsonString);
      triggerRecords = List<Map<String, dynamic>>.from(records);
    }
  }
}
