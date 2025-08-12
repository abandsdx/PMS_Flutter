# PMS External Service Flutter

PMS Flutter 版本，用於串接 Nuwa Cloud PMS 與外部服務，同時支援 iOS、Android、Web 及桌面應用程式。

## ✨ 功能特色 (Features)

- **觸發機器人任務**: 透過表單介面，向指定的機器人觸發新任務。
- **查詢任務狀態**: 查詢已觸發任務的目前狀態。
- **重設機器人密碼**: 提供重設機器人密碼的功能。
- **動態場域選擇**:
    - App 啟動時自動從外部服務獲取場域與地圖資訊。
    - 提供互動式彈窗，讓使用者能方便地從不同樓層選擇配送及取貨地點。
- **動態界面主題**:
    - 內建四種界面主題 (亮色、暗色系)。
    - 使用者可在設定頁面自由切換，主題偏好會被儲存並在下次啟動時自動套用。

## 🏗️ 軟體架構 (Software Architecture)

本專案採用基於 `provider` 的狀態管理架構，將 UI、業務邏輯和資料模型分離。

-   **`lib/`**: 應用程式原始碼主目錄。
    -   **`main.dart`**: 應用程式進入點。負責初始化設定、`ThemeProvider`，並啟動 App。
    -   **`config.dart`**: 全域設定檔。負責管理 API 金鑰、主題偏好等，並透過 `shared_preferences` 進行本地儲存。
    -   **`pages/`**: 存放主要的頁面元件，例如 `TriggerPage`, `QueryPage`, `SettingsPage`。
        -   `TriggerPage` 使用 `AutomaticKeepAliveClientMixin` 來保持頁面狀態，避免在 Tab 切換時重複載入資料。
    -   **`widgets/`**: 存放共用的 UI 元件，例如 `LocationPickerDialog`。
    -   **`providers/`**: 存放狀態管理的 Provider。
        -   `ThemeProvider.dart`: 使用 `ChangeNotifier` 管理當前主題，並在主題變更時通知 UI 更新。
    -   **`models/`**: 存放資料模型。
        -   `field_data.dart`: 定義了從外部服務獲取的場域、地圖、地點等資料的類別。
    -   **`theme/`**: 存放主題相關的定義。
        -   `themes.dart`: 定義了 App 中所有可用的 `ThemeData` 物件。

---

## 🌐 Build for Web

```bash
flutter build web
```

- 輸出位置：`build/web/`
- 可搭配任意 Web Server 部署（如 nginx、Apache、Docker）


## 🤖 Build for Android

```bash
flutter build apk --release
```

- 輸出 APK：`build/app/outputs/flutter-apk/app-release.apk`

### 附加設定：

- `android/app/build.gradle` 中可調整版本號與簽章資訊。
- 若未安裝 Android SDK，請透過 Android Studio 或執行：

```bash
flutter doctor --android-licenses
```

---

## 🍎 Build for iOS (僅限 macOS)

```bash
flutter build ios --release
```

- 輸出位置：`build/ios/`
- 需使用 Xcode 開啟 `ios/Runner.xcworkspace` 進行簽章與發佈。

---

## 🖥️ Build for Windows

```bash
flutter build windows  
```
- 輸出位置：`build/windows/runner/Release/`
- Windows 平台需先啟用：

```bash
flutter config --enable-windows-desktop
```
- 如果有存金鑰或其他資訊在shared_preferences,可以在Poweshell下指令找出檔案
```bash
Get-ChildItem -Path $env:USERPROFILE\AppData\Roaming -Recurse -Filter "shared_preferences.json" -ErrorAction SilentlyContinue
```
清除資訊後再Build App

---

## 🧑‍💻 Build for macOS

```bash
flutter build macos
```

- macOS 平台需先啟用：

```bash
flutter config --enable-macos-desktop
```

---

## 🐧 Build for Linux

```bash
flutter build linux
```

- Linux 平台需先安裝：

```bash
sudo apt-get install clang cmake ninja-build pkg-config libgtk-3-dev
flutter config --enable-linux-desktop
```

---

## 🧪 測試與除錯

```bash
flutter run
```

### 指定平台裝置：

- Android：`flutter run -d android`
- Chrome：`flutter run -d chrome`
- Windows：`flutter run -d windows`

查看所有可用設備：
```bash
flutter devices
```

---

## ✅ Flutter 狀態檢查

```bash
flutter doctor
```

請確保所有項目都為綠勾✔️以避免建置錯誤。

---

## 📦 發佈與部署建議

- Web：可直接將 `build/web` 放入 Web Server 或部署至 Firebase Hosting、Vercel 等。
- Android/iOS：依照標準程序上架至 Google Play / Apple App Store。
- Desktop：打包後提供可執行檔或整合為安裝程式（如 Inno Setup、dmg）。

---

## 📮 聯絡方式

如有任何問題，請聯繫 Nuwa 工程團隊或提出 Pull Request/Issue。
