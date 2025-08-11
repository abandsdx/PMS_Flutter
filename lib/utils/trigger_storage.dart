//trigger_storage
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class TriggerRecord {
  final String triggerId;
  final String fieldId;
  final String serialNumber;
  final String timestamp;
  final Map<String, dynamic> rawPayload;

  TriggerRecord({
    required this.triggerId,
    required this.fieldId,
    required this.serialNumber,
    required this.timestamp,
    required this.rawPayload,
  });

  Map<String, dynamic> toJson() => {
    'triggerId': triggerId,
    'fieldId': fieldId,
    'serialNumber': serialNumber,
    'timestamp': timestamp,
    'rawPayload': rawPayload,
  };

  static TriggerRecord fromJson(Map<String, dynamic> json) {
    return TriggerRecord(
      triggerId: json['triggerId'],
      fieldId: json['fieldId'],
      serialNumber: json['serialNumber'],
      timestamp: json['timestamp'],
      rawPayload: Map<String, dynamic>.from(json['rawPayload']),
    );
  }
}

class TriggerStorage {
  static const String _key = 'trigger_records';

  static Future<List<TriggerRecord>> loadRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_key);
    if (jsonStr == null) return [];
    final List decoded = json.decode(jsonStr);
    return decoded.map((e) => TriggerRecord.fromJson(e)).toList();
  }

  static Future<void> saveRecords(List<TriggerRecord> records) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = json.encode(records.map((e) => e.toJson()).toList());
    await prefs.setString(_key, jsonStr);
  }

  static Future<void> clearRecords() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
