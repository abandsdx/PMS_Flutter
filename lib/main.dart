import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config.dart';
import 'pages/trigger_page.dart';
import 'pages/query_page.dart';
import 'pages/reset_page.dart';
import 'pages/settings_page.dart';
import 'widgets/api_key_dialog.dart';
import 'providers/theme_provider.dart';

// A future that completes when all initial data is loaded.
// (一個 future，在所有初始資料載入完成後完成。)
late Future<void> _initialization;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Chain all loading operations together.
  // (將所有載入操作連結在一起。)
  _initialization = Config.loadToken()
      .then((_) => Config.loadTheme())
      .then((_) => Config.fetchFields());

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(Config.theme),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'PMS External Service',
          theme: themeProvider.themeData,
          // Use a FutureBuilder to handle the async initialization.
          // (使用 FutureBuilder 來處理非同步初始化。)
          home: FutureBuilder(
            future: _initialization,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                // If the future is complete, check if we need the API key, then show the main app.
                // (如果 future 已完成，檢查是否需要 API 金鑰，然後顯示主應用程式。)
                return const PMSHomeWrapper();
              }
              // While waiting, show a loading spinner.
              // (等待時，顯示一個載入中的轉圈圖示。)
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            },
          ),
        );
      },
    );
  }
}

/// A wrapper for PMSHome to handle the initial API key dialog logic.
/// (PMSHome 的一個包裝器，用於處理初始 API 金鑰對話框的邏輯。)
class PMSHomeWrapper extends StatefulWidget {
  const PMSHomeWrapper({Key? key}) : super(key: key);

  @override
  _PMSHomeWrapperState createState() => _PMSHomeWrapperState();
}

class _PMSHomeWrapperState extends State<PMSHomeWrapper> {
  @override
  void initState() {
    super.initState();
    // This logic now runs after all initial data is loaded.
    // (這段邏輯現在會在所有初始資料載入完成後執行。)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (Config.prodToken.isEmpty) {
        final result = await showDialog<String>(
          context: context,
          builder: (_) => const ApiKeyDialog(),
        );

        if (result == null || result.trim().isEmpty) {
          // No action needed, user can't proceed without a key.
          // Maybe show a message. For now, they are stuck on a blank page.
        } else {
          await Config.saveToken(result.trim());
          // Re-fetch fields with the new key and rebuild the UI.
          // (用新的金鑰重新獲取場域資料並重建 UI。)
          setState(() {});
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // If we have a token, show the main UI. Otherwise, show a message or loading.
    // (如果我們有 token，就顯示主 UI。否則，顯示訊息或載入中。)
    if (Config.prodToken.isNotEmpty) {
      return const PMSHome();
    } else {
      return const Scaffold(
        body: Center(
          child: Text("Please provide an API Key."),
        ),
      );
    }
  }
}


class PMSHome extends StatefulWidget {
  const PMSHome({Key? key}) : super(key: key);

  @override
  _PMSHomeState createState() => _PMSHomeState();
}

class _PMSHomeState extends State<PMSHome> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Tab> tabs = const [
    Tab(text: "觸發新任務"),
    Tab(text: "查詢任務狀態"),
    Tab(text: "密碼重設"),
    Tab(text: "設定"),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: tabs.length, vsync: this);
    // REMOVED all the complex logic from here.
    // (移除了這裡所有複雜的邏輯。)
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("PMS External Service"),
        bottom: TabBar(controller: _tabController, tabs: tabs),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          TriggerPage(),
          QueryPage(),
          ResetPage(),
          SettingsPage(),
        ],
      ),
    );
  }
}
