import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config.dart';

class SettingsPage extends StatefulWidget {
  final VoidCallback? onApply;

  const SettingsPage({Key? key, this.onApply}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _tokenController;
  String _themeMode = 'light'; // 你可以用 'light' / 'dark' 來模擬切換主題

  @override
  void initState() {
    super.initState();
    _tokenController = TextEditingController(text: Config.prodToken);
    _themeMode = Config.theme == "darkly" ? 'dark' : 'light'; // 簡單映射
  }

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  void applySettings() async {
    if (!_formKey.currentState!.validate()) return;

    Config.prodToken = _tokenController.text.trim();
    Config.theme = (_themeMode == 'dark') ? 'darkly' : 'flatly'; // 範例映射
    await Config.fetchFields();
    await Config.saveToken(Config.prodToken); // Also save the token
    await Config.saveTheme(Config.theme); // And the theme

    // Config.save() is empty, so I removed it and used specific save methods.

    if (widget.onApply != null) {
      widget.onApply!();
    }

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('設定'),
          content: const Text('設定已套用，場域與機器人資料已更新！'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('確定'),
            )
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            DropdownButtonFormField<String>(
              value: _themeMode,
              items: const [
                DropdownMenuItem(value: 'light', child: Text('亮色主題')),
                DropdownMenuItem(value: 'dark', child: Text('暗色主題')),
              ],
              onChanged: (v) {
                setState(() {
                  _themeMode = v!;
                });
              },
              decoration: const InputDecoration(labelText: '介面主題'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _tokenController,
              decoration: const InputDecoration(
                labelText: 'API 金鑰',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) {
                  return 'API 金鑰不可為空';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: applySettings,
                child: const Text('套用設定'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
