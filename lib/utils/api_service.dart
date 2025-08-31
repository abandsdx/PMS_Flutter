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
  /// Returns the raw payload from the API.
  static Future<List<Map<String, dynamic>>> fetchRobots(String fieldId) async {
    final url = Uri.parse("${Config.baseUrl}/rms/mission/robots?fieldId=$fieldId");
    final response = await http.get(url, headers: _headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final payload = (data['data']['payload'] ?? []) as List;
      // Return the raw payload directly. The UI will handle parsing.
      return List<Map<String, dynamic>>.from(payload);
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
