import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config.dart';
import '../models/field_data.dart';
import '../providers/trigger_page_provider.dart';
import '../widgets/location_picker_dialog.dart';
import '../widgets/map_tracking_dialog.dart';

/// A page for triggering new missions, acting as the main View.
class TriggerPage extends StatelessWidget {
  const TriggerPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TriggerPageProvider(),
      child: const _TriggerPageView(),
    );
  }
}

class _TriggerPageView extends StatefulWidget {
  const _TriggerPageView({Key? key}) : super(key: key);

  @override
  __TriggerPageViewState createState() => __TriggerPageViewState();
}

class __TriggerPageViewState extends State<_TriggerPageView> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  Future<void> _showLocationPicker(BuildContext context, {required bool isDestination}) async {
    final provider = Provider.of<TriggerPageProvider>(context, listen: false);
    if (provider.selectedField == null) {
      _showMessage(context, "提醒", "請先選擇一個場域。");
      return;
    }
    if (provider.selectedField!.maps.isEmpty) {
      _showMessage(context, "提醒", "此場域沒有可用的地圖資訊。");
      return;
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => LocationPickerDialog(maps: provider.selectedField!.maps),
    );

    if (result != null) {
      if (isDestination) {
        provider.setDestination(result);
      } else {
        provider.pickupController.text = result['location'] as String;
      }
    }
  }

  void _showMessage(BuildContext context, String title, String msg) {
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(msg)),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("確定"))],
      ),
    );
  }

  Future<void> _onTriggerMission(BuildContext context) async {
    final provider = Provider.of<TriggerPageProvider>(context, listen: false);
    final result = await provider.triggerMission();
    if (result['success'] == true && context.mounted) {
      _showMessage(context, '成功', '任務已成功觸發，請至右側列表查看地圖。');
    } else if (context.mounted) {
      _showMessage(context, '失敗', result['message']);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final provider = context.watch<TriggerPageProvider>();

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
                    value: provider.selectedField,
                    items: Config.fields.map((f) => DropdownMenuItem(value: f, child: Text(f.fieldName))).toList(),
                    onChanged: provider.selectField,
                    decoration: const InputDecoration(labelText: "選擇場域"),
                  ),
                  DropdownButtonFormField<String>(
                    value: provider.selectedRobot,
                    items: provider.robotList.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                    // Disable dropdown if no field is selected
                    onChanged: provider.selectedField == null ? null : provider.selectRobot,
                    decoration: InputDecoration(
                      labelText: "機器人序號",
                      filled: provider.selectedField == null,
                      fillColor: Colors.grey.shade200,
                    ),
                  ),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    value: provider.missionType,
                    items: const ["到取貨點取貨再送到目標點"].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (v) => provider.setMissionType(v!),
                    decoration: const InputDecoration(labelText: "任務類型"),
                  ),
                  DropdownButtonFormField<String>(
                    value: provider.deviceType,
                    items: const ["未指定", "單艙機器人", "雙艙機器人", "開放式機器人"].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (v) => provider.setDeviceType(v!),
                    decoration: const InputDecoration(labelText: "裝置類型"),
                  ),
                  TextFormField(
                    controller: provider.destController,
                    readOnly: true,
                    decoration: const InputDecoration(labelText: "遞送目標點", suffixIcon: Icon(Icons.arrow_drop_down)),
                    onTap: () => _showLocationPicker(context, isDestination: true),
                  ),
                  TextFormField(
                    controller: provider.pickupController,
                    readOnly: true,
                    decoration: const InputDecoration(labelText: "中途取貨地點", suffixIcon: Icon(Icons.arrow_drop_down)),
                    onTap: () => _showLocationPicker(context, isDestination: false),
                  ),
                  TextFormField(controller: provider.nameController, decoration: const InputDecoration(labelText: "物品名稱")),
                  TextFormField(controller: provider.sizeController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "數量")),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(onPressed: provider.clearForm, child: const Text("清除")),
                      ElevatedButton(onPressed: () => _onTriggerMission(context), child: const Text("觸發任務")),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (provider.statusMessage.isNotEmpty)
                    Center(
                      child: Text(
                        provider.statusMessage,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
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
                Text("機器人狀態", style: Theme.of(context).textTheme.titleMedium),
                SizedBox(
                  height: 200,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                    child: provider.robotInfo.isEmpty
                        ? const Center(child: Text("無資料"))
                        : SingleChildScrollView(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                columns: const [
                                  DataColumn(label: Text("SN")),
                                  DataColumn(label: Text("軟體版本")),
                                  DataColumn(label: Text("充電中")),
                                  DataColumn(label: Text("電量")),
                                  DataColumn(label: Text("連線狀態")),
                                  DataColumn(label: Text("底盤ID")),
                                  DataColumn(label: Text("支援MCS")),
                                  DataColumn(label: Text("遞送狀態")),
                                  DataColumn(label: Text("層數")),
                                ],
                                rows: provider.robotInfo.map((r) {
                                  String maxPlatform = 'N/A';
                                  if (r['middleLayer'] is Map) {
                                    final middleLayer = r['middleLayer'] as Map<String, dynamic>;
                                    if (middleLayer['data'] is Map) {
                                      final data = middleLayer['data'] as Map<String, dynamic>;
                                      if (data.containsKey('maxPlatform')) {
                                        maxPlatform = data['maxPlatform']?.toString() ?? 'N/A';
                                      }
                                    }
                                  }
                                  return DataRow(cells: [
                                    DataCell(Text(r['sn']?.toString() ?? '')),
                                    DataCell(Text(r['imageVersion']?.toString() ?? '')),
                                    DataCell(Text((r['batteryCharging']?.toString() ?? 'false') == 'true' ? '是' : '否')),
                                    DataCell(Text(r['battery']?.toString() ?? '')),
                                    DataCell(Text((r['connStatus']?.toString() ?? '0') == '1' ? '在線' : '離線')),
                                    DataCell(Text(r['chassisUuid']?.toString() ?? '')),
                                    DataCell(Text((r['supportMCS']?.toString() ?? 'false') == 'true' ? '是支援' : '不支援')),
                                    DataCell(Text(r['deliveriorStatus']?.toString() ?? '')),
                                    DataCell(Text(maxPlatform)),
                                  ]);
                                }).toList(),
                              ),
                            ),
                          ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: provider.isLoadingRobots ? null : provider.fetchRobots,
                    child: provider.isLoadingRobots
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.0))
                        : const Text("重新整理"),
                  ),
                ),
                const SizedBox(height: 16),
                Text("近期任務", style: Theme.of(context).textTheme.titleMedium),
                Expanded(
                  child: Container(
                     decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                     child: provider.recentMissions.isEmpty
                      ? const Center(child: Text("無近期任務"))
                      : ListView.builder(
                          itemCount: provider.recentMissions.length,
                          itemBuilder: (context, index) {
                            final mission = provider.recentMissions[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: ListTile(
                                leading: CircleAvatar(child: Text('${index + 1}')),
                                title: Text('機器人 #${mission['sn']}'),
                                subtitle: Text('目標: ${mission['destination']}'),
                                trailing: ElevatedButton(
                                  child: const Text('查看地圖'),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (_) => MapTrackingDialog(
                                        mapImagePartialPath: mission['mapImagePartialPath'],
                                        mapOrigin: mission['mapOrigin'],
                                        robotUuid: mission['robotUuid'],
                                        responseText: mission['responseText'],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),
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
