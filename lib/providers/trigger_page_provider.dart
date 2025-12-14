import 'package:flutter/material.dart';
import '../models/field_data.dart';
import '../config.dart';
import '../utils/api_service.dart';
import '../utils/trigger_storage.dart';

/// Provider handling state and logic for the Trigger page.
class TriggerPageProvider with ChangeNotifier {
  static const String notSpecified = '不指定';

  // --- STATE VARIABLES ---
  Field? _selectedField;
  String? _selectedRobot = notSpecified;
  MapInfo? _selectedDestMap;
  String _missionType = "到取貨點取貨再送到目標點";
  String _deviceType = "不指定";
  List<String> _robotList = [];
  List<Map<String, dynamic>> _robotInfo = [];
  bool _isLoadingRobots = false;
  String _statusMessage = '';
  final List<Map<String, dynamic>> _recentMissions = [];

  // --- CONTROLLERS ---
  final destController = TextEditingController();
  final pickupController = TextEditingController();
  final List<TextEditingController> _itemControllers = [
    TextEditingController(),
  ];
  bool _isEnablePassword = false;

  // --- GETTERS ---
  Field? get selectedField => _selectedField;
  String? get selectedRobot => _selectedRobot;
  MapInfo? get selectedDestMap => _selectedDestMap;
  String get missionType => _missionType;
  String get deviceType => _deviceType;
  bool get requiresPickup => _missionType == "到取貨點取貨再送到目標點";
  List<String> get robotList => [notSpecified, ..._robotList];
  List<Map<String, dynamic>> get robotInfo => _robotInfo;
  bool get isLoadingRobots => _isLoadingRobots;
  String get statusMessage => _statusMessage;
  List<Map<String, dynamic>> get recentMissions => _recentMissions;
  List<TextEditingController> get itemControllers =>
      List.unmodifiable(_itemControllers);
  bool get isEnablePassword => _isEnablePassword;
  bool get canAddItem => _itemControllers.length < 2;

  TriggerPageProvider() {
    _initialize();
  }

  void _initialize() {
    if (Config.fields.isNotEmpty) {
      _statusMessage = "機器人資料已載入";
      _selectedField = Config.fields.first;
      fetchRobots();
    } else {
      _statusMessage = "錯誤：找不到任何場域資料";
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
    _isEnablePassword = false;
    _resetItemControllers();
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
    if (!requiresPickup) {
      pickupController.clear();
      _resetItemControllers();
      _isEnablePassword = false;
    }
    notifyListeners();
  }

  void setDeviceType(String newType) {
    _deviceType = newType;
    notifyListeners();
  }

  void addItemField() {
    if (!canAddItem) return;
    _itemControllers.add(TextEditingController());
    notifyListeners();
  }

  void removeItemField(int index) {
    if (index < 0 || index >= _itemControllers.length) return;
    if (_itemControllers.length == 1) {
      _itemControllers.first.clear();
      notifyListeners();
      return;
    }
    final controller = _itemControllers.removeAt(index);
    controller.dispose();
    notifyListeners();
  }

  void setEnablePassword(bool value) {
    _isEnablePassword = value;
    notifyListeners();
  }

  void _resetItemControllers() {
    for (final controller in _itemControllers) {
      controller.clear();
    }
    while (_itemControllers.length > 1) {
      final controller = _itemControllers.removeLast();
      controller.dispose();
    }
  }

  Future<void> fetchRobots() async {
    if (_selectedField == null) return;
    _isLoadingRobots = true;
    _statusMessage = "正在讀取 '${_selectedField!.fieldName}' 的機器人列表...";
    notifyListeners();
    try {
      final robots = await ApiService.fetchRobots(_selectedField!.fieldId);
      _robotList = robots
          .map((r) => r['sn'].toString())
          .where((sn) => sn.isNotEmpty)
          .toList();
      _robotInfo = robots;
      _selectedRobot = notSpecified;
      _statusMessage = "機器人列表已更新";
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
    if (_selectedField == null)
      return {'success': false, 'message': '請先選擇一個場域'};
    final serialNumber =
        (_selectedRobot == notSpecified || _selectedRobot == null)
        ? ""
        : _selectedRobot!;
    final missionMap = {"到取貨點取貨再送到目標點": "2", "機器人派遣到目標點且不返回待命點": "4"};
    final deviceMap = {"不指定": "0", "單艙機器人": "1", "雙艙機器人": "2", "開放式機器人": "3"};
    final itemNames = _itemControllers
        .map((c) => c.text.trim())
        .where((name) => name.isNotEmpty)
        .toList();
    final Map<String, dynamic> destination = {
      "destinationName": destController.text,
      "pickUpLocationName": pickupController.text,
    };
    if (itemNames.isNotEmpty) {
      final orderList = itemNames
          .map((name) => {"type": "normal", "name": name})
          .toList();
      destination["door"] = [
        {"orderList": orderList},
        {"orderList": orderList},
      ];
    }
    final payload = {
      "triggerId":
          "PMS-${DateTime.now().toIso8601String().replaceAll(RegExp(r'[-:.]'), '').substring(0, 14)}",
      "fieldId": _selectedField!.fieldId,
      "serialNumber": serialNumber,
      "missionType": missionMap[_missionType],
      "deviceType": deviceMap[_deviceType],
      "isEnablePassword": _isEnablePassword.toString(),
      "destination": [destination],
    };
    try {
      final response = await ApiService.triggerMission(payload);
      if (response.statusCode == 200) {
        final newRecord = TriggerRecord(
          triggerId: payload["triggerId"].toString(),
          fieldId: _selectedField!.fieldId,
          serialNumber: serialNumber,
          timestamp: DateTime.now().toIso8601String(),
          rawPayload: payload,
        );
        final currentRecords = await TriggerStorage.loadRecords();
        currentRecords.add(newRecord);
        await TriggerStorage.saveRecords(currentRecords);
        if (_selectedDestMap != null && serialNumber.isNotEmpty) {
          final robotData = _robotInfo.firstWhere(
            (r) => r['sn'] == serialNumber,
            orElse: () => {},
          );
          _recentMissions.insert(0, {
            'sn': serialNumber,
            'destination': destController.text,
            'timestamp': DateTime.now(),
            'mapImagePartialPath': _selectedDestMap!.mapImage,
            'mapOrigin': _selectedDestMap!.mapOrigin,
            'robotUuid': robotData['chassisUuid'],
            'responseText': response.body,
          });
          if (_recentMissions.length > 10) _recentMissions.removeLast();
          notifyListeners();
        }
        return {'success': true, 'message': response.body};
      } else {
        return {
          'success': false,
          'message': "觸發失敗: ${response.statusCode}\n${response.body}",
        };
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Clears all the input fields on the form.
  void clearForm() {
    destController.clear();
    pickupController.clear();
    _resetItemControllers();
    _isEnablePassword = false;
    _missionType = "到取貨點取貨再送到目標點";
    _deviceType = "不指定";
    notifyListeners();
  }

  @override
  void dispose() {
    destController.dispose();
    pickupController.dispose();
    for (final controller in _itemControllers) {
      controller.dispose();
    }
    super.dispose();
  }
}
