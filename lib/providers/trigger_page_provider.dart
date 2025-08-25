import 'package:flutter/material.dart';
import '../models/field_data.dart';
import '../config.dart';
import '../utils/api_service.dart';
import '../utils/trigger_storage.dart';

/// A provider for managing the state and business logic of the TriggerPage.
/// (用於管理 TriggerPage 狀態和業務邏輯的 Provider。)
class TriggerPageProvider with ChangeNotifier {
  static const String notSpecified = '不指定';

  // --- STATE VARIABLES ---
  Field? _selectedField;
  String? _selectedRobot = notSpecified;
  MapInfo? _selectedDestMap;
  String _missionType = "到取貨點取貨再送到目標點";
  String _deviceType = "單艙機器人";
  List<String> _robotList = [];
  List<Map<String, dynamic>> _robotInfo = [];
  bool _isLoadingRobots = false;
  String _statusMessage = '';
  final List<Map<String, dynamic>> _recentMissions = [];

  // --- CONTROLLERS ---
  final destController = TextEditingController();
  final pickupController = TextEditingController();
  final pwdController = TextEditingController();
  final nameController = TextEditingController();
  final sizeController = TextEditingController();

  // --- GETTERS ---
  Field? get selectedField => _selectedField;
  String? get selectedRobot => _selectedRobot;
  MapInfo? get selectedDestMap => _selectedDestMap;
  String get missionType => _missionType;
  String get deviceType => _deviceType;
  List<String> get robotList => [notSpecified, ..._robotList];
  List<Map<String, dynamic>> get robotInfo => _robotInfo;
  bool get isLoadingRobots => _isLoadingRobots;
  String get statusMessage => _statusMessage;
  List<Map<String, dynamic>> get recentMissions => _recentMissions;

  // --- INITIALIZATION ---
  TriggerPageProvider() {
    _initialize();
  }

  void _initialize() {
    // Now that this provider is only created after Config.load() is complete,
    // we can safely assume Config.fields is populated.
    if (Config.fields.isNotEmpty) {
      _statusMessage = "場域與機器人資料已載入。";
      _selectedField = Config.fields.first;
      fetchRobots();
    } else {
      // This case indicates an error during the initial load.
      _statusMessage = "錯誤：找不到任何場域資料。";
    }
  }

  // --- PUBLIC METHODS ---
  void selectField(Field? newField) {
    if (newField == null || newField.fieldId == _selectedField?.fieldId) return;
    _selectedField = newField;
    _selectedRobot = notSpecified;
    _robotList = [];
    _robotInfo = [];
    destController.clear();
    pickupController.clear();
    _selectedDestMap = null;
    notifyListeners();
    fetchRobots();
  }

  void setDestination(Map<String, dynamic> selection) {
    _selectedDestMap = selection['map'] as MapInfo;
    destController.text = selection['location'] as String;
    notifyListeners();
  }

  void selectRobot(String? newRobot) {
    _selectedRobot = newRobot;
    notifyListeners();
  }

  void setMissionType(String newType) {
    _missionType = newType;
    notifyListeners();
  }

  void setDeviceType(String newType) {
    _deviceType = newType;
    notifyListeners();
  }

  Future<void> fetchRobots() async {
    if (_selectedField == null) return;
    _isLoadingRobots = true;
    _statusMessage = "正在讀取 '${_selectedField!.fieldName}' 的機器人列表...";
    notifyListeners();
    try {
      final robots = await ApiService.fetchRobots(_selectedField!.fieldId);
      _robotList = robots.map((r) => r['sn'].toString()).where((sn) => sn.isNotEmpty).toList();
      _robotInfo = robots;
      _selectedRobot = notSpecified;
      _statusMessage = "機器人列表已更新。";
    } catch (e) {
      _statusMessage = "讀取機器人列表失敗: $e";
      _robotList = [];
      _robotInfo = [];
      _selectedRobot = notSpecified;
    } finally {
      _isLoadingRobots = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> triggerMission() async {
    if (_selectedField == null) return {'success': false, 'message': '請先選擇一個場域。'};
    final serialNumber = (_selectedRobot == notSpecified || _selectedRobot == null) ? "" : _selectedRobot!;
    final missionMap = {"到取貨點取貨再送到目標點": "2", "貨物放入艙門，機器人介面輸入指定目標點送貨": "3"};
    final deviceMap = {"未指定": "0", "單艙機器人": "1", "雙艙機器人": "2", "開放式機器人": "3"};
    int? size;
    if (sizeController.text.isNotEmpty) {
      size = int.tryParse(sizeController.text);
      if (size == null) return {'success': false, 'message': '請輸入有效的數量。'};
    }
    final itemName = nameController.text;
    final Map<String, dynamic> destination = {
      "destinationName": destController.text, "pickUpLocationName": pickupController.text,
      "passWord": pwdController.text, "priority": "2",
    };
    if (itemName.isNotEmpty && size != null) {
      destination["door"] = [{"id": "0", "orderList": [{"type": "normal", "name": itemName, "size": size}]}, {"id": "1", "orderList": [{"type": "normal", "name": itemName, "size": size}]}];
    }
    final payload = {
      "triggerId": "PMS-${DateTime.now().toIso8601String().replaceAll(RegExp(r'[-:.]'), '').substring(0, 14)}",
      "fieldId": _selectedField!.fieldId, "serialNumber": serialNumber,
      "missionType": missionMap[_missionType], "deviceType": deviceMap[_deviceType],
      "destination": [destination]
    };
    try {
      final response = await ApiService.triggerMission(payload);
      if (response.statusCode == 200) {
        final newRecord = TriggerRecord(
          triggerId: payload["triggerId"].toString(), fieldId: _selectedField!.fieldId,
          serialNumber: serialNumber, timestamp: DateTime.now().toIso8601String(),
          rawPayload: payload,
        );
        final currentRecords = await TriggerStorage.loadRecords();
        currentRecords.add(newRecord);
        await TriggerStorage.saveRecords(currentRecords);
        if (_selectedDestMap != null && serialNumber.isNotEmpty) {
          final robotData = _robotInfo.firstWhere((r) => r['sn'] == serialNumber, orElse: () => {});
          _recentMissions.insert(0, {
            'sn': serialNumber, 'destination': destController.text, 'timestamp': DateTime.now(),
            'mapImagePartialPath': _selectedDestMap!.mapImage, 'mapOrigin': _selectedDestMap!.mapOrigin,
            'robotUuid': robotData['chassisUuid'], 'responseText': response.body,
          });
          if (_recentMissions.length > 10) _recentMissions.removeLast();
          notifyListeners();
        }
        return {'success': true, 'message': response.body};
      } else {
        return {'success': false, 'message': "觸發失敗: ${response.statusCode}\n${response.body}"};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  void clearForm() {
    destController.clear();
    pickupController.clear();
    pwdController.clear();
    nameController.clear();
    sizeController.clear();
    _missionType = "到取貨點取貨再送到目標點";
    _deviceType = "單艙機器人";
    notifyListeners();
  }

  @override
  void dispose() {
    destController.dispose();
    pickupController.dispose();
    pwdController.dispose();
    nameController.dispose();
    sizeController.dispose();
    super.dispose();
  }
}
