import 'package:flutter/material.dart';
import '../models/field_data.dart';
import '../config.dart';
import '../utils/api_service.dart';
import '../utils/trigger_storage.dart';

/// A provider for managing the state and business logic of the TriggerPage.
/// (用於管理 TriggerPage 狀態和業務邏輯的 Provider。)
///
/// This class follows the ViewModel pattern, separating UI concerns from the underlying
/// state and business logic. It uses [ChangeNotifier] to notify listening widgets
/// of state changes, prompting them to rebuild.
/// (這個類別遵循 ViewModel 模式，將 UI 關注點與底層狀態和業務邏輯分離。
/// 它使用 [ChangeNotifier] 來通知監聽的 widget 狀態已變更，促使它們重建。)
class TriggerPageProvider with ChangeNotifier {
  /// The value representing a non-selection for the robot.
  /// (代表未選擇任何機器人的值。)
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

  /// A list to hold information about recently triggered missions.
  /// (一個列表，用於儲存最近觸發的任務資訊。)
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

  /// Initializes the provider state, loading field data and robots if available.
  /// (初始化 provider 狀態，如果場域資料已載入則獲取機器人列表。)
  void _initialize() {
    if (Config.fields.isNotEmpty) {
      _statusMessage = "場域資料已載入。";
      _selectedField = Config.fields.first;
      fetchRobots();
    } else {
      _statusMessage = "正在讀取場域資料...";
    }
    // No need to call notifyListeners() here as it's the constructor.
  }

  // --- PUBLIC METHODS (UI ACTIONS) ---

  /// Updates the selected field and fetches the corresponding robot list.
  /// (更新所選的場域，並獲取對應的機器人列表。)
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
  /// (設定目的地點位及其所屬的地圖。)
  void setDestination(Map<String, dynamic> selection) {
    _selectedDestMap = selection['map'] as MapInfo;
    destController.text = selection['location'] as String;
    notifyListeners();
  }

  /// Updates the selected robot from the dropdown.
  /// (從下拉選單更新所選的機器人。)
  void selectRobot(String? newRobot) {
    _selectedRobot = newRobot;
    notifyListeners();
  }

  /// Updates the mission type from the dropdown.
  /// (從下拉選單更新任務類型。)
  void setMissionType(String newType) {
    _missionType = newType;
    notifyListeners();
  }

  /// Updates the device type from the dropdown.
  /// (從下拉選單更新裝置類型。)
  void setDeviceType(String newType) {
    _deviceType = newType;
    notifyListeners();
  }

  /// Fetches the list of robots for the currently selected field from the API.
  /// (從 API 獲取當前所選場域的機器人列表。)
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

  /// Builds the payload and triggers a new mission via the ApiService.
  /// (建立 payload 並透過 ApiService 觸發新任務。)
  /// Returns a map with 'success' (bool) and 'message' (String).
  /// (返回一個包含 'success' (布林值) 和 'message' (字串) 的 map。)
  Future<Map<String, dynamic>> triggerMission() async {
    if (_selectedField == null) {
      return {'success': false, 'message': '請先選擇一個場域。'};
    }

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
        // Upon success, save the trigger record locally.
        // (成功後，將觸發記錄儲存到本機。)
        final newRecord = TriggerRecord(
          triggerId: payload["triggerId"].toString(), fieldId: _selectedField!.fieldId,
          serialNumber: serialNumber, timestamp: DateTime.now().toIso8601String(),
          rawPayload: payload,
        );
        final currentRecords = await TriggerStorage.loadRecords();
        currentRecords.add(newRecord);
        await TriggerStorage.saveRecords(currentRecords);

        // Add the successful mission to the recent missions list for UI display.
        // (將成功的任務添加到近期任務列表中，以便在 UI 中顯示。)
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

  /// Clears all text controllers and resets dropdowns to their default values.
  /// (清除所有文字控制器並將下拉選單重設為預設值。)
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
