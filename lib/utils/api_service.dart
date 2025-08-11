// lib/utils/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static String baseUrl = 'https://api.nuwarobotics.com/v1';
  static String token = '';

  static Map<String, String> get headers => {
        'Authorization': token,
        'Content-Type': 'application/json',
      };

  // 取得所有場域資訊
  static Future<List<dynamic>> fetchFields() async {
    final url = Uri.parse('$baseUrl/rms/mission/fields');
    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      return jsonData['data']['payload'];
    } else {
      throw Exception('載入場域失敗: ${response.statusCode}');
    }
  }

  // 觸發新任務
  static Future<Map<String, dynamic>> triggerMission(Map<String, dynamic> payload) async {
    final url = Uri.parse('$baseUrl/rms/mission/robot/trigger');
    final response = await http.post(url, headers: headers, body: jsonEncode(payload));
    return jsonDecode(response.body);
  }

  // 查詢任務狀態
  static Future<Map<String, dynamic>> queryMissionStatus(String triggerId) async {
    final url = Uri.parse('$baseUrl/rms/mission/robot/status/$triggerId');
    final response = await http.get(url, headers: headers);
    return jsonDecode(response.body);
  }

  // 密碼重設（假設 API endpoint）
  static Future<Map<String, dynamic>> resetPassword(Map<String, dynamic> payload) async {
    final url = Uri.parse('$baseUrl/rms/robot/password/reset');
    final response = await http.post(url, headers: headers, body: jsonEncode(payload));
    return jsonDecode(response.body);
  }
}
