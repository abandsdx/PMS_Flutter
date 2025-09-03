import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../models/field_data.dart';

class QueryPage extends StatefulWidget {
  const QueryPage({Key? key}) : super(key: key);

  @override
  _QueryPageState createState() => _QueryPageState();
}

class _QueryPageState extends State<QueryPage> {
  Field? selectedField;
  String? selectedRobot;
  String selectedType = 'arrival';

  List<String> robotSerials = [];

  String outputText = "";

  @override
  void initState() {
    super.initState();
    loadFields();
  }

  void loadFields() {
    if (Config.fields.isNotEmpty) {
      setState(() {
        selectedField = Config.fields.first;
        loadRobots();
      });
    }
  }

  Future<void> loadRobots() async {
    if (selectedField == null) return;

    final fieldId = selectedField!.fieldId;
    final url = Uri.parse("${Config.baseUrl}/rms/mission/robots?fieldId=$fieldId");
    final headers = {
      'Authorization': Config.prodToken,
      'Content-Type': 'application/json',
    };
    try {
      final resp = await http.get(url, headers: headers);
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body)['data']['payload'] as List<dynamic>;
        final robots = data.map<String>((r) => r['sn'] as String).toList();
        setState(() {
          robotSerials = robots;
          selectedRobot = robots.isNotEmpty ? robots.first : null;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("無法載入機器人清單：$e")));
    }
  }

  Future<void> query() async {
    if (selectedField == null || selectedRobot == null) return;

    final fieldId = selectedField!.fieldId;
    final url = Uri.parse("${Config.baseUrl}/rms/mission/notification");
    final headers = {
      'Authorization': Config.prodToken,
      'Content-Type': 'application/json',
    };
    final params = {
      "fieldId": fieldId,
      "serialNumber": selectedRobot!,
      "type": selectedType,
    };
    final uri = url.replace(queryParameters: params);

    try {
      final resp = await http.get(uri, headers: headers);
      final now = DateTime.now().toString();
      setState(() {
        outputText += "\n" + "=" * 60 + "\n";
        outputText += "[$now] 查詢：場域=${selectedField!.fieldName}, 序號=$selectedRobot, 類型=$selectedType\n";
        outputText += resp.body + "\n";
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void clearOutput() {
    setState(() {
      outputText = "";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 左側控制欄
          SizedBox(
            width: 280,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                DropdownButtonFormField<Field>(
                  decoration: const InputDecoration(labelText: "選擇場域"),
                  value: selectedField,
                  items: Config.fields
                      .map((f) => DropdownMenuItem(value: f, child: Text(f.fieldName)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setState(() {
                        selectedField = v;
                        selectedRobot = null;
                        robotSerials = [];
                      });
                      loadRobots();
                    }
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: "機器人序號"),
                  value: selectedRobot,
                  items: robotSerials
                      .map((sn) => DropdownMenuItem(value: sn, child: Text(sn)))
                      .toList(),
                  onChanged: (v) {
                    setState(() {
                      selectedRobot = v;
                    });
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: "狀態類型"),
                  value: selectedType,
                  items: const [
                    DropdownMenuItem(value: "arrival", child: Text("arrival")),
                    DropdownMenuItem(value: "status", child: Text("status")),
                    DropdownMenuItem(value: "exception", child: Text("exception")),
                  ],
                  onChanged: (v) {
                    setState(() {
                      selectedType = v ?? "arrival";
                    });
                  },
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: query,
                      child: const Text("查詢"),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: clearOutput,
                      child: const Text("清空"),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const VerticalDivider(),

          // 右側文字輸出區
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(8),
              color: Theme.of(context).colorScheme.surfaceVariant,
              child: SingleChildScrollView(
                child: SelectableText(
                  outputText,
                  style: const TextStyle(fontFamily: 'Courier'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}