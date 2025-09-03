import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config.dart';
import '../models/field_data.dart';
import '../providers/trigger_page_provider.dart';
import '../widgets/location_picker_dialog.dart';
import '../widgets/map_tracking_dialog.dart';

/// The main page for triggering new missions.
/// (用於觸發新任務的主頁面。)
///
/// This widget is the root of the "Trigger" tab. It sets up the
/// [TriggerPageProvider] to manage the state for this feature.
/// (此小工具是「觸發」標籤的根。它設定 [TriggerPageProvider] 來管理此功能的狀態。)
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

/// The stateful view for the TriggerPage, which contains the UI.
/// (TriggerPage 的有狀態視圖，其中包含 UI。)
class _TriggerPageView extends StatefulWidget {
  const _TriggerPageView({Key? key}) : super(key: key);

  @override
  __TriggerPageViewState createState() => __TriggerPageViewState();
}

/// The state class for `_TriggerPageView`.
/// (`_TriggerPageView` 的狀態類別。)
/// It uses [AutomaticKeepAliveClientMixin] to preserve the state of the tab
/// when switching between tabs.
/// (它使用 [AutomaticKeepAliveClientMixin] 在切換標籤時保留標籤的狀態。)
class __TriggerPageViewState extends State<_TriggerPageView> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  /// Shows the location picker dialog to select a destination or pickup point.
  /// (顯示位置選擇器對話框以選擇目的地或取貨點。)
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

  /// A utility method to show a simple alert dialog with a title and message.
  /// (一個實用方法，用於顯示帶有標題和訊息的簡單警報對話框。)
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

  /// Handles the "Trigger Mission" button press. It calls the provider to
  /// trigger the mission and shows a success or failure message.
  /// (處理「觸發任務」按鈕的點擊事件。它會呼叫 provider 來觸發任務，並顯示成功或失敗的訊息。)
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
    final theme = Theme.of(context);

    // The main layout is a Row with two panels.
    // (主佈局是一個包含兩個面板的 Row。)
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Panel: Mission Triggering Form
          // (左側面板：任務觸發窗體)
          SizedBox(
            width: 380,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("觸發新任務", style: theme.textTheme.titleLarge),
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
                    onChanged: provider.selectRobot,
                    decoration: const InputDecoration(labelText: "機器人序號"),
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
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 20),
          // Right Panel: Robot Status and Recent Missions
          // (右側面板：機器人狀態和近期任務)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text("機器人狀態", style: theme.textTheme.titleMedium),
                SizedBox(
                  height: 200,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(border: Border.all(color: theme.dividerColor), borderRadius: BorderRadius.circular(8)),
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
                                  // This is the final, correct parsing logic for the raw API data.
                                  final isOnline = r['connStatus'] == 1;
                                  final supportMcsText = (r['supportMCS'] == true) ? '是支援' : '不支援';
                                  final isChargingText = (r['batteryCharging'] == true) ? '是' : '否';

                                  String maxPlatform = 'N/A';
                                  if (r['middleLayer'] is Map) {
                                      final data = r['middleLayer']['data'];
                                      if (data is Map) {
                                          final platformValue = data['maxPlatform'];
                                          if (platformValue != null && platformValue.toString().isNotEmpty) {
                                              maxPlatform = platformValue.toString();
                                          }
                                      }
                                  }

                                  final cellTextStyle = theme.textTheme.bodyMedium;
                                  return DataRow(cells: [
                                    DataCell(Text(r['sn']?.toString() ?? 'N/A', style: cellTextStyle)),
                                    DataCell(Text(r['imageVersion']?.toString() ?? 'N/A', style: cellTextStyle)),
                                    DataCell(Text(isChargingText, style: cellTextStyle)),
                                    DataCell(Text(r['battery']?.toString() ?? 'N/A', style: cellTextStyle)),
                                    DataCell(Text(isOnline ? '在線' : '離線', style: cellTextStyle)),
                                    DataCell(Text(r['chassisUuid']?.toString() ?? 'N/A', style: cellTextStyle)),
                                    DataCell(Text(supportMcsText, style: cellTextStyle)),
                                    DataCell(Text(r['deliveriorStatus']?.toString() ?? 'N/A', style: cellTextStyle)),
                                    DataCell(Text(maxPlatform, style: cellTextStyle)),
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
                Text("近期任務", style: theme.textTheme.titleMedium),
                Expanded(
                  child: Container(
                     decoration: BoxDecoration(border: Border.all(color: theme.dividerColor), borderRadius: BorderRadius.circular(8)),
                     child: provider.recentMissions.isEmpty
                      ? const Center(child: Text("無資料"))
                      : ListView.builder(
                          itemCount: provider.recentMissions.length,
                          itemBuilder: (context, index) {
                            final mission = provider.recentMissions[index];
                            return Card(
                              color: theme.cardColor,
                              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: theme.colorScheme.primary,
                                  foregroundColor: theme.colorScheme.onPrimary,
                                  child: Text('${index + 1}')
                                ),
                                title: Text(
                                  '機器人 #${mission['sn']}',
                                  style: theme.textTheme.titleSmall,
                                ),
                                subtitle: Text(
                                  '目標: ${mission['destination']}',
                                  style: theme.textTheme.bodySmall,
                                ),
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
