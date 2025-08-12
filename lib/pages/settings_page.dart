import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config.dart';
import '../providers/theme_provider.dart';
import '../theme/themes.dart';

class SettingsPage extends StatefulWidget {
  final VoidCallback? onApply; // This is probably not needed anymore

  const SettingsPage({Key? key, this.onApply}) : super(key: key);

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

  void applySettings() async {
    if (!_formKey.currentState!.validate()) return;

    // Save the token
    await Config.saveToken(_tokenController.text.trim());
    Config.prodToken = _tokenController.text.trim();

    // Set the theme using the provider
    // This will also save the theme and notify listeners to rebuild the UI
    Provider.of<ThemeProvider>(context, listen: false).setTheme(_selectedThemeName);

    // The onApply callback is likely no longer needed since Provider handles the rebuild.
    // if (widget.onApply != null) {
    //   widget.onApply!();
    // }

    // We don't need to call fetchFields here anymore, as that is part of a different workflow.

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('設定'),
          content: const Text('設定已儲存！'),
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
