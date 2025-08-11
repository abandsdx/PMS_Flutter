import 'dart:io'; // 加入這行
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 加入這行

class ApiKeyDialog extends StatefulWidget {
  @override
  _ApiKeyDialogState createState() => _ApiKeyDialogState();
}

class _ApiKeyDialogState extends State<ApiKeyDialog> {
  final _controller = TextEditingController();

  // ✅ 通用的關閉 App 方法
  void closeApp() {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        SystemNavigator.pop();
      } else {
        exit(0);
      }
    } catch (_) {
      exit(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('API 金鑰設定'),
      content: TextField(
        controller: _controller,
        decoration: InputDecoration(labelText: '請輸入 API 金鑰'),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(null); // 關閉對話框
            closeApp(); // ✅ 取消直接結束 App
          },
          child: Text('取消'),
        ),
        ElevatedButton(
          onPressed: () {
            final input = _controller.text.trim();
            if (input.isEmpty) {
              closeApp(); // ✅ 空白輸入也強制關閉 App
            } else {
              Navigator.of(context).pop(input);
            }
          },
          child: Text('確認'),
        ),
      ],
    );
  }
}