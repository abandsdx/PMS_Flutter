import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config.dart';
import 'pages/trigger_page.dart';
import 'pages/query_page.dart';
import 'pages/reset_page.dart';
import 'pages/settings_page.dart';
import 'widgets/api_key_dialog.dart';
import 'providers/theme_provider.dart';

/// The main entry point for the application.
/// (應用程式的主要進入點。)
void main() async {
  // Ensure that the Flutter binding is initialized before calling native code.
  // (確保在呼叫原生程式碼之前已初始化 Flutter。)
  WidgetsFlutterBinding.ensureInitialized();
  // Load the saved API token and theme from persistent storage.
  // (從持久性儲存中載入已儲存的 API 金鑰和主題。)
  await Config.loadToken();
  await Config.loadTheme();
  // Run the app, providing the ThemeProvider to the widget tree.
  // (執行應用程式，並將 ThemeProvider 提供給小工具樹。)
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(Config.theme),
      child: const MyApp(),
    ),
  );
}

/// The root widget of the application.
/// (應用程式的根小工具。)
/// It consumes the [ThemeProvider] to apply the selected theme.
/// (它會使用 [ThemeProvider] 來應用所選的主題。)
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'PMS External Service',
          theme: themeProvider.themeData,
          home: PMSHome(),
        );
      },
    );
  }
}

/// The main home widget of the app, which contains the tab-based navigation.
/// (應用程式的主要主頁小工具，其中包含基於標籤的導航。)
class PMSHome extends StatefulWidget {
  @override
  _PMSHomeState createState() => _PMSHomeState();
}

/// The state for the [PMSHome] widget.
/// ([PMSHome] 小工具的狀態。)
class _PMSHomeState extends State<PMSHome> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final tabs = [
    const Tab(text: "觸發新任務"),
    const Tab(text: "查詢任務狀態"),
    const Tab(text: "密碼重設"),
    const Tab(text: "設定"),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: tabs.length, vsync: this);

    // After the first frame is rendered, check if an API key exists.
    // (第一幀渲染後，檢查 API 金鑰是否存在。)
    // If not, show a dialog to prompt the user for one.
    // (如果不存在，則顯示一個對話框提示使用者輸入。)
    // If a key exists, fetch the initial field data.
    // (如果金鑰存在，則獲取初始場域資料。)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (Config.prodToken.isEmpty) {
        final result = await showDialog<String>(
          context: context,
          builder: (_) => ApiKeyDialog(),
        );

        if (result == null || result.trim().isEmpty) {
          Navigator.of(context).pop(); // Exit if no key is entered
        } else {
          Config.prodToken = result;
          await Config.saveToken(Config.prodToken);
          await Config.fetchFields(); // Fetch data after getting a new key
          setState(() {});
        }
      } else {
        // App starts with a token, so fetch field data immediately.
        // (應用程式啟動時已有 token，因此立即獲取場域資料。)
        await Config.fetchFields();
        setState(() {});
      }
    });
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
        children: [
          const TriggerPage(),
          const QueryPage(),
          ResetPage(),
          const SettingsPage(),
        ],
      ),
    );
  }
}
