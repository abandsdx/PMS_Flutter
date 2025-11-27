import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../utils/trigger_storage.dart';

class ResetPage extends StatefulWidget {
  @override
  _ResetPageState createState() => _ResetPageState();
}

class _ResetPageState extends State<ResetPage> {
  List<Map<String, dynamic>> records = [];
  Map<String, dynamic>? selectedRecord;
  String resultMessage = '';

  @override
  void initState() {
    super.initState();
    loadTriggerRecords();
  }

  Future<void> loadTriggerRecords() async {
    final loaded = await TriggerStorage.loadRecords();
    setState(() {
      records = loaded
          .map((r) => {
                'triggerId': r.triggerId,
                'fieldId': r.fieldId,
                'serialNumber': r.serialNumber,
                'timestamp': r.timestamp,
                'raw_payload': r.rawPayload,
              })
          .toList();
      selectedRecord = null;
      resultMessage = '';
    });
  }

  Future<void> resetPassword() async {
    if (selectedRecord == null) return;

    final fid = selectedRecord!["fieldId"];
    final sn = selectedRecord!["serialNumber"];
    final tid = selectedRecord!["triggerId"];

    final url = Uri.parse('${Config.baseUrl}/rms/mission/robot/reset/password');
    final headers = {
      'Authorization': Config.prodToken,
      'Content-Type': 'application/json',
    };

    final body = jsonEncode({
      "triggerId": tid,
      "fieldId": fid,
      "serialNumber": sn,
    });

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("重設密碼"),
            content: Text(response.body),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
        );
      } else {
        setState(() {
          resultMessage =
              "[${DateTime.now()}] 重設密碼失敗: ${response.statusCode}\n${response.body}";
        });
      }
    } catch (e) {
      setState(() {
        resultMessage = "[${DateTime.now()}] 例外錯誤: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              ElevatedButton(
                onPressed: loadTriggerRecords,
                child: const Text("重新載入記錄"),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () async {
                  await TriggerStorage.clearRecords();
                  await loadTriggerRecords();
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text("清空記錄"),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              children: [
                ...records.map((record) {
                  String fieldName;
                  try {
                    fieldName = Config.fields.firstWhere((f) => f.fieldId == record['fieldId']).fieldName;
                  } catch (e) {
                    fieldName = record['fieldId'];
                  }
                  final isSelected = selectedRecord == record;
                  return ListTile(
                    tileColor: isSelected
                        ? Theme.of(context).colorScheme.primary.withOpacity(0.15)
                        : null,
                    title: Text("[$fieldName] ${record['serialNumber']}"),
                    subtitle: Text("triggerId: ${record['triggerId']}"),
                    onTap: () {
                      setState(() {
                        selectedRecord = record;
                        resultMessage = '';
                      });
                    },
                  );
                }).toList(),
                const Divider(),
                if (selectedRecord != null) ...[
                  const Text(
                    "Payload 預覽：",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: surface,
                      border: Border.all(color: onSurface.withOpacity(0.15)),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SelectableText(
                        JsonEncoder.withIndent('  ').convert(selectedRecord!['raw_payload']),
                        style: TextStyle(
                          fontFamily: 'Courier',
                          color: onSurface,
                        ),
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: resetPassword,
                    icon: const Icon(Icons.refresh),
                    label: const Text("重設密碼"),
                  ),
                  const SizedBox(height: 10),
                  if (resultMessage.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        resultMessage,
                        style: TextStyle(color: onSurface),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
