import 'package:flutter/material.dart';
import '../models/field_data.dart';
import '../config.dart';
import '../utils/api_service.dart';
import '../utils/trigger_storage.dart';

/// A provider for managing the state and business logic of the TriggerPage.
///
/// This class follows the ViewModel pattern, separating UI concerns from the underlying
/// state and business logic. It uses [ChangeNotifier] to notify listening widgets
/// of state changes, prompting them to rebuild.
class TriggerPageProvider with ChangeNotifier {
  /// The value representing a non-selection for the robot.
  static const String notSpecified = '不指定';

  // --- STATE VARIABLES ---

  Field? _selectedField;
  String? _selectedRobot = notSpecified;
  MapInfo? _selectedDestMap;
  String _missionType = "到取貨點取貨再送到目標點";
  String _deviceType = "單艙機器人";

  List<String> _robotList = [];
  List<Map<String, String>> _robotInfo = [];

  bool _isLoadingRobots = false;

  // --- CONTROLLERS ---

  final destController = TextEditingController();
  final pickupController = TextEditingController();
  final pwdController = TextEditingController();
  final nameController = TextEditingController();
  final sizeController = TextEditingController();

  // --- GETTERS ---

  Field? get selectedField => _selectedField;
  String? get selectedRobot => _selectedRobot;
  MapInfo? get selectedDestMap => _selectedDestMap; // Getter for the selected map
  String get missionType => _missionType;
  String get deviceType => _deviceType;
  List<String> get robotList => [notSpecified, ..._robotList];
  List<Map<String, String>> get robotInfo => _robotInfo;
  bool get isLoadingRobots => _isLoadingRobots;

  // --- INITIALIZATION ---

  TriggerPageProvider() {
    // Initialize with the first field if data is already loaded from startup.
    if (Config.fields.isNotEmpty) {
      _selectedField = Config.fields.first;
      fetchRobots();
    }
  }

  // --- PUBLIC METHODS (UI ACTIONS) ---

  /// Updates the selected field and fetches the corresponding robot list.
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

  /// Sets the destination location and the map it belongs to.
  void setDestination(Map<String, dynamic> selection) {
    _selectedDestMap = selection['map'] as MapInfo;
    destController.text = selection['location'] as String;
    notifyListeners();
  }

  /// Updates the selected robot from the dropdown.
  void selectRobot(String? newRobot) {
    _selectedRobot = newRobot;
    notifyListeners();
  }

  /// Updates the mission type from the dropdown.
  void setMissionType(String newType) {
    _missionType = newType;
    notifyListeners();
  }

  /// Updates the device type from the dropdown.
  void setDeviceType(String newType) {
    _deviceType = newType;
    notifyListeners();
  }

  /// Fetches the list of robots for the currently selected field from the API.
  Future<void> fetchRobots() async {
    if (_selectedField == null) return;

    _isLoadingRobots = true;
    notifyListeners();

    try {
      final robots = await ApiService.fetchRobots(_selectedField!.fieldId);
      _robotList = robots.map((r) => r['sn']!).where((sn) => sn.isNotEmpty).toList();
      _robotInfo = robots;
      // Always default to "Not Specified" after fetching, letting the user choose.
      _selectedRobot = notSpecified;
    } catch (e) {
      print("Failed to fetch robots: $e");
      _robotList = [];
      _robotInfo = [];
      _selectedRobot = notSpecified;
    } finally {
      _isLoadingRobots = false;
      notifyListeners();
    }
  }

  /// Builds the payload and triggers a new mission via the ApiService.
  /// Returns a map with 'success' (bool) and 'message' (String).
  Future<Map<String, dynamic>> triggerMission() async {
    if (_selectedField == null) {
      return {'success': false, 'message': '請先選擇一個場域。'};
    }

    // Handle the "Not Specified" case for the robot serial number.
    final serialNumber = (_selectedRobot == notSpecified || _selectedRobot == null)
        ? ""
        : _selectedRobot!;

    final missionMap = {"到取貨點取貨再送到目標點": "2", "貨物放入艙門，機器人介面輸入指定目標點送貨": "3"};
    final deviceMap = {"未指定": "0", "單艙機器人": "1", "雙艙機器人": "2", "開放式機器人": "3"};
    int? size;
    if (sizeController.text.isNotEmpty) {
      size = int.tryParse(sizeController.text);
      if (size == null) {
        return {'success': false, 'message': '請輸入有效的數量。'};
      }
    }
    final itemName = nameController.text;
    final Map<String, dynamic> destination = {
      "destinationName": destController.text,
      "pickUpLocationName": pickupController.text,
      "passWord": pwdController.text,
      "priority": "2",
    };
    if (itemName.isNotEmpty && size != null) {
      destination["door"] = [{"id": "0", "orderList": [{"type": "normal", "name": itemName, "size": size}]}, {"id": "1", "orderList": [{"type": "normal", "name": itemName, "size": size}]}];
    }
    final payload = {
      "triggerId": "PMS-${DateTime.now().toIso8601String().replaceAll(RegExp(r'[-:.]'), '').substring(0, 14)}",
      "fieldId": _selectedField!.fieldId,
      "serialNumber": serialNumber,
      "missionType": missionMap[_missionType],
      "deviceType": deviceMap[_deviceType],
      "destination": [destination]
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

        return {'success': true, 'message': response.body};
      } else {
        return {'success': false, 'message': "觸發失敗: ${response.statusCode}\n${response.body}"};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Clears all text controllers and resets dropdowns to their default values.
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

  // --- LIFECYCLE ---

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
