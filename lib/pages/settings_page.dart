import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config.dart';
import '../providers/theme_provider.dart';
import '../theme/themes.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _tokenController;
  late String _selectedThemeName;

  @override
  void initState() {
    super.initState();
    _tokenController = TextEditingController(text: Config.prodToken);
    // Initialize with the current theme from the provider
    _selectedThemeName = Provider.of<ThemeProvider>(context, listen: false).themeName;
  }

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _confirmClearToken() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('確認'),
        content: const Text('您確定要清除並移除已儲存的 API 金鑰嗎？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('確定清除'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await Config.clearToken();
      _tokenController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API 金鑰已清除。')),
      );
    }
  }

  void applySettings() async {
    if (!_formKey.currentState!.validate()) return;

    // Save the token
    await Config.saveToken(_tokenController.text.trim());
    Config.prodToken = _tokenController.text.trim();

    // The theme is now applied directly in the onChanged callback.

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('設定'),
          content: const Text('API 金鑰已儲存。'),
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
              value: _selectedThemeName,
              items: AppThemes.themes.keys.map((name) {
                return DropdownMenuItem(value: name, child: Text(name));
              }).toList(),
              onChanged: (v) {
                if (v != null) {
                  setState(() {
                    _selectedThemeName = v;
                  });
                  // Apply the theme immediately
                  Provider.of<ThemeProvider>(context, listen: false).setTheme(v);
                }
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
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: _confirmClearToken,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                  child: const Text('清除金鑰'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: applySettings,
                  child: const Text('儲存設定'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
