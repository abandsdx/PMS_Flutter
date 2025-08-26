import 'package:flutter/material.dart';
import '../models/field_data.dart';
import '../config.dart';
import '../utils/api_service.dart';
import '../utils/trigger_storage.dart';

/// A provider for managing the state and business logic of the TriggerPage.
/// (用於管理 TriggerPage 狀態和業務邏輯的 Provider。)
class TriggerPageProvider with ChangeNotifier {
  /// The string used to represent that a robot is not specified.
  /// (用於表示未指定機器人的字串。)
  static const String notSpecified = '不指定';

  // --- STATE VARIABLES ---
  /// The currently selected field.
  /// (當前選擇的場域。)
  Field? _selectedField;
  /// The serial number of the currently selected robot.
  /// (當前選擇的機器人序號。)
  String? _selectedRobot = notSpecified;
  /// The map information for the selected destination.
  /// (所選目標點的地圖資訊。)
  MapInfo? _selectedDestMap;
  /// The type of mission to be triggered.
  /// (要觸發的任務類型。)
  String _missionType = "到取貨點取貨再送到目標點";
  /// The type of device (robot) to be used.
  /// (要使用的裝置(機器人)類型。)
  String _deviceType = "單艙機器人";
  /// The list of available robot serial numbers for the selected field.
  /// (所選場域的可用機器人序號列表。)
  List<String> _robotList = [];
  /// The detailed information for all robots in the selected field.
  /// (所選場域中所有機器人的詳細資訊。)
  List<Map<String, dynamic>> _robotInfo = [];
  /// A flag to indicate if the robot list is currently being fetched.
  /// (一個旗標，用於表示機器人列表是否正在讀取中。)
  bool _isLoadingRobots = false;
  /// A message to display the current status to the user.
  /// (向使用者顯示當前狀態的訊息。)
  String _statusMessage = '';
  /// A list of recently triggered missions, shown on the UI.
  /// (近期觸發的任務列表，顯示在 UI 上。)
  final List<Map<String, dynamic>> _recentMissions = [];

  // --- CONTROLLERS ---
  /// Controller for the destination text field.
  /// (目標點文字欄位的控制器。)
  final destController = TextEditingController();
  /// Controller for the pickup location text field.
  /// (取貨點文字欄位的控制器。)
  final pickupController = TextEditingController();
  /// Controller for the password text field.
  /// (密碼文字欄位的控制器。)
  final pwdController = TextEditingController();
  /// Controller for the item name text field.
  /// (物品名稱文字欄位的控制器。)
  final nameController = TextEditingController();
  /// Controller for the item size/quantity text field.
  /// (物品大小/數量文字欄位的控制器。)
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

  /// Initializes the provider, selecting the first available field and fetching its robots.
  /// (初始化提供者，選擇第一個可用的場域並獲取其機器人。)
  void _initialize() {
    // This provider is created after Config.load() is complete.
    if (Config.fields.isNotEmpty) {
      _statusMessage = "場域與機器人資料已載入。";
      _selectedField = Config.fields.first;
      fetchRobots();
    } else {
      _statusMessage = "錯誤：找不到任何場域資料。";
    }
  }

  // --- PUBLIC METHODS ---
  /// Updates the selected field and fetches the corresponding robot list.
  /// (更新所選場域並獲取相應的機器人列表。)
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

  /// Sets the destination location based on user selection from the dialog.
  /// (根據使用者從對話框中的選擇設定目標位置。)
  void setDestination(Map<String, dynamic> selection) {
    _selectedDestMap = selection['map'] as MapInfo;
    destController.text = selection['location'] as String;
    notifyListeners();
  }

  /// Updates the selected robot.
  /// (更新所選的機器人。)
  void selectRobot(String? newRobot) {
    _selectedRobot = newRobot;
    notifyListeners();
  }

  /// Updates the mission type.
  /// (更新任務類型。)
  void setMissionType(String newType) {
    _missionType = newType;
    notifyListeners();
  }

  /// Updates the device type.
  /// (更新裝置類型。)
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

  /// Constructs and sends the mission trigger payload to the API.
  /// (建構並發送任務觸發的 payload 到 API。)
  /// On success, it saves a record of the mission and adds it to the recent missions list.
  /// (成功後，它會儲存任務記錄並將其添加到近期任務列表中。)
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

  /// Clears all the input fields on the form.
  /// (清除表單上的所有輸入欄位。)
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
