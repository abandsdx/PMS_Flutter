import 'package:flutter/material.dart';
import 'config.dart';
import 'pages/trigger_page.dart';
import 'pages/query_page.dart';
import 'pages/reset_page.dart';
import 'pages/settings_page.dart';
import 'widgets/api_key_dialog.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Config.loadToken(); // Load token from storage
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PMS External Service',
      theme: ThemeData(primarySwatch: Colors.teal),
      home: PMSHome(),
    );
  }
}

class PMSHome extends StatefulWidget {
  @override
  _PMSHomeState createState() => _PMSHomeState();
}

class _PMSHomeState extends State<PMSHome> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final tabs = [
    Tab(text: "觸發新任務"),
    Tab(text: "查詢任務狀態"),
    Tab(text: "密碼重設"),
    Tab(text: "設定"),
  ];

  @override
void initState() {
  super.initState();
  _tabController = TabController(length: tabs.length, vsync: this);

  WidgetsBinding.instance.addPostFrameCallback((_) async {
    if (Config.prodToken.isEmpty) {
      final result = await showDialog<String>(
        context: context,
        builder: (_) => ApiKeyDialog(),
      );

      if (result == null || result.trim().isEmpty) {
        Navigator.of(context).pop(); // 沒輸入金鑰就退出
      } else {
        Config.prodToken = result;
        await Config.saveToken(Config.prodToken);
        await Config.fetchFields();  // 新增：輸入新金鑰後抓資料
        setState(() {});
      }
    } else {
      // 新增區塊： app 啟動且有 token，主動抓場域資料
      await Config.fetchFields();
      setState(() {});
    }
  });
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("PMS External Service"),
        bottom: TabBar(controller: _tabController, tabs: tabs),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          TriggerPage(),
          QueryPage(),
          ResetPage(),
          SettingsPage(onApply: () {
            setState(() {}); // Refresh all
          }),
        ],
      ),
    );
  }
}
