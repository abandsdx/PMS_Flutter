import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config.dart';
import '../models/field_data.dart';
import '../utils/trigger_storage.dart';
import '../widgets/location_picker_dialog.dart';

class TriggerPage extends StatefulWidget {
  @override
  _TriggerPageState createState() => _TriggerPageState();
}

class _TriggerPageState extends State<TriggerPage> with AutomaticKeepAliveClientMixin<TriggerPage> {
  Field? selectedField;
  String? selectedRobot;
  String missionType = "到取貨點取貨再送到目標點";
  String deviceType = "單艙機器人";

  List<String> robotList = [];
  List<Map<String, String>> robotInfo = [];

  final destController = TextEditingController();
  final pickupController = TextEditingController();
  final pwdController = TextEditingController();
  final nameController = TextEditingController();
  final sizeController = TextEditingController();
  bool isLoadingRobots = false;
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Data is now pre-loaded by the main screen's initState.
    // We just need to initialize the state from the pre-loaded data.
    if (Config.fields.isNotEmpty) {
      selectedField = Config.fields.first;
      fetchRobots();
    }
  }

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    destController.dispose();
    pickupController.dispose();
    pwdController.dispose();
    nameController.dispose();
    sizeController.dispose();
    super.dispose();
  }

  Future<void> fetchRobots() async {
    if (selectedField == null) {
      setState(() {
        robotList.clear();
        robotInfo.clear();
        selectedRobot = null;
      });
      return;
    }

    setState(() {
      isLoadingRobots = true;
    });

    final fieldId = selectedField!.fieldId;
    final url = Uri.parse("${Config.baseUrl}/rms/mission/robots?fieldId=$fieldId");
    final headers = {'Authorization': Config.prodToken, 'Content-Type': 'application/json'};

    try {
      final resp = await http.get(url, headers: headers);
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        final payload = data['data']['payload'] ?? [];
        setState(() {
          robotList = payload.map<String>((r) => r['sn']?.toString() ?? '').toList();
          selectedRobot = robotList.isNotEmpty ? robotList.first : null;
          robotInfo = payload.map<Map<String, String>>((r) {
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
        });
      }
    } catch (e) {
      print("Robot fetch error: $e");
    } finally {
      setState(() {
        isLoadingRobots = false;
      });
    }
  }

  Future<void> triggerMission() async {
    if (selectedField == null || selectedRobot == null) {
      _showMessage("錯誤", "請先選擇一個場域和機器人。");
      return;
    }
    final fieldId = selectedField!.fieldId;
    final sn = selectedRobot!;

    final missionMap = {
      "到取貨點取貨再送到目標點": "2",
      "貨物放入艙門，機器人介面輸入指定目標點送貨": "3"
    };
    final deviceMap = {
      "未指定": "0",
      "單艙機器人": "1",
      "雙艙機器人": "2",
      "開放式機器人": "3"
    };

    int? size;
    if (sizeController.text.isNotEmpty) {
      try {
        size = int.parse(sizeController.text);
      } catch (_) {
        _showMessage("錯誤", "請輸入有效的數量");
        return;
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
      destination["door"] = [
        {
          "id": "0",
          "orderList": [
            {"type": "normal", "name": itemName, "size": size}
          ]
        },
        {
          "id": "1",
          "orderList": [
            {"type": "normal", "name": itemName, "size": size}
          ]
        },
      ];
    }

    final payload = {
      "triggerId":
          "PMS-${DateTime.now().toIso8601String().replaceAll(RegExp(r'[-:.]'), '').substring(0, 14)}",
      "fieldId": fieldId,
      "serialNumber": sn,
      "missionType": missionMap[missionType],
      "deviceType": deviceMap[deviceType],
      "destination": [destination]
    };

    final url = Uri.parse("${Config.baseUrl}/rms/mission/robot/trigger");
    final headers = {'Authorization': Config.prodToken, 'Content-Type': 'application/json'};

    try {
      final resp = await http.post(url, headers: headers, body: json.encode(payload));

      if (resp.statusCode == 200) {
        final triggerId = payload["triggerId"]?.toString() ?? "unknown";

        final newRecord = TriggerRecord(
          triggerId: triggerId,
          fieldId: fieldId,
          serialNumber: sn,
          timestamp: DateTime.now().toIso8601String(),
          rawPayload: payload,
        );

        final currentRecords = await TriggerStorage.loadRecords();
        currentRecords.add(newRecord);
        await TriggerStorage.saveRecords(currentRecords);

        _showMessage("觸發成功", resp.body);
      } else {
        _showMessage("觸發失敗", "狀態碼：${resp.statusCode}\n內容：${resp.body}");
      }
    } catch (e) {
      _showMessage("錯誤", e.toString());
    }
  }

  void _clearForm() {
    destController.clear();
    pickupController.clear();
    pwdController.clear();
    nameController.clear();
    sizeController.clear();
    setState(() {
      missionType = "到取貨點取貨再送到目標點";
      deviceType = "單艙機器人";
    });
  }

  Future<void> _showLocationPicker(TextEditingController controller) async {
    if (selectedField == null) {
      _showMessage("提醒", "請先選擇一個場域。");
      return;
    }
    if (selectedField!.maps.isEmpty) {
      _showMessage("提醒", "此場域沒有可用的地圖資訊。");
      return;
    }

    final selectedLocation = await showDialog<String>(
      context: context,
      builder: (context) => LocationPickerDialog(maps: selectedField!.maps),
    );

    if (selectedLocation != null) {
      controller.text = selectedLocation;
    }
  }

  void _showMessage(String title, String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(msg),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text("確定"))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // See AutomaticKeepAliveClientMixin.
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 380,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("觸發新任務", style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<Field>(
                    value: selectedField,
                    items: Config.fields
                        .map((f) => DropdownMenuItem(value: f, child: Text(f.fieldName)))
                        .toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() {
                        selectedField = v;
                        fetchRobots();
                      });
                    },
                    decoration: const InputDecoration(labelText: "選擇場域"),
                  ),
                  DropdownButtonFormField<String>(
                    value: selectedRobot,
                    items: robotList
                        .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                        .toList(),
                    onChanged: (v) => setState(() => selectedRobot = v),
                    decoration: const InputDecoration(labelText: "機器人序號"),
                  ),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    value: missionType,
                    items: [
                      "到取貨點取貨再送到目標點",
                      //"貨物放入艙門，機器人介面輸入指定目標點送貨"
                    ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (v) => setState(() => missionType = v!),
                    decoration: const InputDecoration(labelText: "任務類型"),
                  ),
                  DropdownButtonFormField<String>(
                    value: deviceType,
                    items: ["未指定", "單艙機器人", "雙艙機器人", "開放式機器人"]
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) => setState(() => deviceType = v!),
                    decoration: const InputDecoration(labelText: "裝置類型"),
                  ),
                  TextFormField(
                    controller: destController,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: "遞送目標點",
                      suffixIcon: Icon(Icons.arrow_drop_down),
                    ),
                    onTap: () => _showLocationPicker(destController),
                  ),
                  TextFormField(
                    controller: pickupController,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: "中途取貨地點",
                      suffixIcon: Icon(Icons.arrow_drop_down),
                    ),
                    onTap: () => _showLocationPicker(pickupController),
                  ),
                  //TextFormField(
                      //controller: pwdController,
                      //decoration: const InputDecoration(labelText: "密碼")),
                  TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: "物品名稱")),
                  TextFormField(
                      controller: sizeController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "數量")),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(onPressed: _clearForm, child: const Text("清除")),
                      ElevatedButton(onPressed: triggerMission, child: const Text("觸發任務")),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 20),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: robotInfo.isEmpty
                        ? const Center(child: Text("無資料"))
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              return Scrollbar(
                                controller: _horizontalController,
                                thumbVisibility: true,
                                scrollbarOrientation: ScrollbarOrientation.bottom,
                                child: SingleChildScrollView(
                                  controller: _horizontalController,
                                  scrollDirection: Axis.horizontal,
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                                    child: Scrollbar(
                                      controller: _verticalController,
                                      thumbVisibility: true,
                                      child: SingleChildScrollView(
                                        controller: _verticalController,
                                        scrollDirection: Axis.vertical,
                                        child: DataTable(
                                          columnSpacing: 20,
                                          columns: const [
                                            DataColumn(label: Text("序號")),
                                            DataColumn(label: Text("電量")),
                                            DataColumn(label: Text("充電中")),
                                            DataColumn(label: Text("連線狀態")),
                                            DataColumn(label: Text("遞送狀態")),
                                            DataColumn(label: Text("底車UUID")),
                                            DataColumn(label: Text("底車版本")),
                                            DataColumn(label: Text("軟體版本")),
                                          ],
                                          rows: robotInfo.map((r) {
                                            return DataRow(cells: [
                                              DataCell(Text(r['sn']!)),
                                              DataCell(Text(r['battery']!)),
                                              DataCell(Text(r['charging']!)),
                                              DataCell(Text(r['status']!)),
                                              DataCell(Text(r['deliveriorStatus']!)),
                                              DataCell(Text(r['chassisUuid']!)),
                                              DataCell(Text(r['chassisVersion']!)),
                                              DataCell(Text(r['imageVersion']!)),
                                            ]);
                                          }).toList(),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: isLoadingRobots ? null : fetchRobots,
                    child: isLoadingRobots
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.0,
                            ),
                          )
                        : const Text("重新整理機器人資訊"),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
