import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config.dart';
import '../models/field_data.dart';
import '../providers/trigger_page_provider.dart';
import '../widgets/location_picker_dialog.dart';
import '../widgets/map_tracking_dialog.dart';

/// A page for triggering new missions, acting as the main View.
///
/// This widget uses a [ChangeNotifierProvider] to create and provide the
/// [TriggerPageProvider] to its widget sub-tree. The actual UI is built
/// by the [_TriggerPageView] widget.
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

/// The private view component that consumes the [TriggerPageProvider].
///
/// It is a StatefulWidget to support the [AutomaticKeepAliveClientMixin],
/// which preserves the page's state when switching tabs.
class _TriggerPageView extends StatefulWidget {
  const _TriggerPageView({Key? key}) : super(key: key);

  @override
  __TriggerPageViewState createState() => __TriggerPageViewState();
}

class __TriggerPageViewState extends State<_TriggerPageView> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  /// Shows a location picker dialog and updates the provider with the result.
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
        // For now, just update the controller for pickup location
        provider.pickupController.text = result['location'] as String;
      }
    }
  }

  /// Shows a simple dialog with a title and message.
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

  /// Handles the trigger mission button press, awaiting the result and showing a dialog.
  Future<void> _onTriggerMission(BuildContext context) async {
    final provider = Provider.of<TriggerPageProvider>(context, listen: false);
    final result = await provider.triggerMission();

    if (result['success'] == true && context.mounted) {
      // Find the selected robot's info to get the UUID
      final robotData = provider.robotInfo.firstWhere(
        (r) => r['sn'] == provider.selectedRobot,
        orElse: () => {}, // Return an empty map if not found
      );
      final robotUuid = robotData['chassisUuid'];
      final selectedMap = provider.selectedDestMap;

      // Check if we have all the data needed to show the map
      if (robotUuid != null && robotUuid.isNotEmpty && selectedMap != null) {
        showDialog(
          context: context,
          // Use a barrier to make it a fullscreen-like dialog
          barrierDismissible: false,
          builder: (_) => MapTrackingDialog(
            mapImagePartialPath: selectedMap.mapImage,
            mapOrigin: selectedMap.mapOrigin,
            robotUuid: robotUuid,
            responseText: result['message'],
          ),
        );
      } else {
        // Fallback to the old simple dialog if data is missing
        _showMessage(context, '成功 (但無法顯示地圖)', result['message']);
      }
    } else if (context.mounted) {
      _showMessage(context, '失敗', result['message']);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Necessary for AutomaticKeepAliveClientMixin

    // Use a Consumer to listen for changes in the provider and rebuild the UI.
    final provider = context.watch<TriggerPageProvider>();

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Left side: Form ---
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
                ],
              ),
            ),
          ),

          const SizedBox(width: 20),

          // --- Right side: Robot Info Table ---
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                    child: provider.robotInfo.isEmpty
                        ? const Center(child: Text("無資料"))
                        : SingleChildScrollView(
                            scrollDirection: Axis.vertical,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
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
                                rows: provider.robotInfo.map((r) {
                                  return DataRow(cells: [
                                    DataCell(Text(r['sn'] ?? '')),
                                    DataCell(Text(r['battery'] ?? '')),
                                    DataCell(Text(r['charging'] ?? '')),
                                    DataCell(Text(r['status'] ?? '')),
                                    DataCell(Text(r['deliveriorStatus'] ?? '')),
                                    DataCell(Text(r['chassisUuid'] ?? '')),
                                    DataCell(Text(r['chassisVersion'] ?? '')),
                                    DataCell(Text(r['imageVersion'] ?? '')),
                                  ]);
                                }).toList(),
                              ),
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: provider.isLoadingRobots ? null : provider.fetchRobots,
                    child: provider.isLoadingRobots
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.0))
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
