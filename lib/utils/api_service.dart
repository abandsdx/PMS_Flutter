// lib/utils/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../models/field_data.dart';

/// A service class for handling all API communications.
class ApiService {
  /// A centralized getter for request headers.
  /// Uses the token from the global [Config].
  static Map<String, String> get _headers => {
        'Authorization': Config.prodToken,
        'Content-Type': 'application/json',
      };

  /// Fetches the list of robots for a given fieldId.
  static Future<List<Map<String, String>>> fetchRobots(String fieldId) async {
    final url = Uri.parse("${Config.baseUrl}/rms/mission/robots?fieldId=$fieldId");
    final response = await http.get(url, headers: _headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final payload = (data['data']['payload'] ?? []) as List;

      return payload.map<Map<String, String>>((r) {
        final online = r['connStatus'] == 1;
        return {
          "sn": r['sn']?.toString() ?? '',
          "battery": online ? r['battery']?.toString() ?? "未知" : "未知",
          "charging": online ? ((r['batteryCharging'] == true) ? "是" : "否") : "未知",
          "status": online ? "在線" : "離線",
          "chassisUuid": r['chassisUuid']?.toString() ?? '',
          "chassisVersion": r['chassisVersion']?.toString() ?? '',
          "deliveriorStatus": online ? r['deliveriorStatus']?.toString() ?? "未知" : "未知",
          "imageVersion": r['imageVersion']?.toString() ?? '',
        };
      }).toList();
    } else {
      throw Exception('Failed to load robots: ${response.statusCode}');
    }
  }

  /// Triggers a new mission with the given payload.
  static Future<http.Response> triggerMission(Map<String, dynamic> payload) async {
    final url = Uri.parse('${Config.baseUrl}/rms/mission/robot/trigger');
    final response = await http.post(
      url,
      headers: _headers,
      body: jsonEncode(payload),
    );
    // Return the full response so the caller can handle status codes.
    return response;
  }

  /// Queries the status of a previously triggered mission.
  static Future<Map<String, dynamic>> queryMissionStatus(String triggerId) async {
    final url = Uri.parse('${Config.baseUrl}/rms/mission/robot/status/$triggerId');
    final response = await http.get(url, headers: _headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to query mission status: ${response.statusCode}');
    }
  }

  /// Resets the password for a robot.
  static Future<http.Response> resetPassword(Map<String, dynamic> payload) async {
    final url = Uri.parse('${Config.baseUrl}/rms/robot/password/reset');
    final response = await http.post(
      url,
      headers: _headers,
      body: jsonEncode(payload),
    );
    return response;
  }
}
