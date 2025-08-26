# PMS External Service Flutter UI

An internal Flutter application for interacting with the PMS (Project Management System) external service API. This tool allows users to trigger missions for robots, monitor their status, and view their real-time location on a map.

一個用於與 PMS (專案管理系統) 外部服務 API 互動的內部 Flutter 應用程式。此工具允許使用者觸發機器人任務、監控其狀態並在地圖上查看其即時位置。

---

## ✨ Features (功能特色)

- **Dynamic Configuration (動態設定)**: Fetches field and map data from a remote server on startup. (啟動時從遠端伺服器獲取場域和地圖資料。)
- **Mission Triggering (任務觸發)**: A form to select a field, robot, and destination to trigger a new delivery mission. (一個表單，用於選擇場域、機器人和目的地以觸發新的運送任務。)
- **Robot Status Table (機器人狀態表)**: Displays a detailed table of all robots in the selected field, including their software version, battery status, connection status, and more. The table is horizontally scrollable to accommodate all columns. (顯示所選場域中所有機器人的詳細表格，包括其軟體版本、電池狀態、連線狀態等。該表格可水平滾動以容納所有欄位。)
- **Recent Missions List (近期任務列表)**: Shows a list of the last 10 successfully triggered missions. (顯示最近 10 個成功觸發的任務列表。)
- **Real-time Map Tracking (即時地圖追蹤)**: Clicking "View Map" on a recent mission opens a dialog showing the robot's current position and trail on the field map, updated in real-time via MQTT. The map is interactive, allowing for panning and zooming. (點擊近期任務上的「查看地圖」會打開一個對話框，在地圖上顯示機器人的當前位置和軌跡，並透過 MQTT 即時更新。地圖是互動式的，可以平移和縮放。)
- **Theming (主題)**: Supports light and dark themes, which can be changed in the Settings tab. (支援淺色和深色主題，可在「設定」標籤頁中更改。)

## 🚀 Setup and Running (設定與執行)

1.  **Prerequisites (先決條件)**:
    - Flutter SDK installed. (已安裝 Flutter SDK。)
    - An editor like VS Code or Android Studio. (像 VS Code 或 Android Studio 這樣的編輯器。)
    - A connected device (emulator or physical) to run the app. (一個已連接的裝置（模擬器或實體機）來執行應用程式。)

2.  **Get Dependencies (獲取依賴)**:
    ```bash
    flutter pub get
    ```

3.  **Run the App (執行應用程式)**:
    ```bash
    flutter run
    ```

4.  **API Key (API 金鑰)**:
    - On the first launch, the app will prompt you to enter an API key. This key is required to communicate with the PMS external service.
    - (首次啟動時，應用程式會提示您輸入 API 金鑰。此金鑰是與 PMS 外部服務通訊所必需的。)
    - The key is saved locally on the device for future sessions. It can be cleared in the "Settings" tab.
    - (金鑰會保存在裝置本機以供將來使用。它可以在「設定」標籤頁中清除。)

## 🏗️ 軟體架構 (Software Architecture)

本專案採用基於 `provider` 的狀態管理架構，實作了類似 **MVVM (Model-View-ViewModel)** 的模式，將職責清晰地分離開來。

-   `lib/`**: 應用程式原始碼主目錄。
    -   **`main.dart`**: 應用程式進入點。負責初始化全域服務、`ThemeProvider`，並啟動 App。
    -   **`config.dart`**: **(Model)** 全域設定檔。負責管理 API 金鑰、主題偏好等，並透過 `shared_preferences` 進行本地儲存。
    -   **`models/`**: **(Model)** 存放資料模型，定義了從 API 獲取的資料結構 (例如 `field_data.dart`)。
    -   **`utils/api_service.dart`**: **(Service Layer)** 集中管理所有對外部 API 的網路請求，將資料獲取邏輯與業務邏輯分離。
    -   **`providers/`**: **(ViewModel)** 存放狀態管理的 Provider。
        -   `ThemeProvider.dart`: 管理當前主題，並在主題變更時通知 UI 更新。
        -   `TriggerPageProvider.dart`: 負責 `TriggerPage` 的所有業務邏輯和狀態管理，例如處理使用者輸入、呼叫 `ApiService`、更新 UI 狀態等。
    -   **`pages/`**: **(View)** 存放主要的頁面元件。這些元件是「啞的」(dumb)，它們只負責根據 Provider 的狀態來渲染 UI，並將使用者操作委派給 Provider 處理。
        -   `TriggerPage` 使用 `AutomaticKeepAliveClientMixin` 來保持頁面狀態，避免在 Tab 切換時重複載入資料。
    -   **`widgets/`**: **(View)** 存放共用的 UI 元件，例如 `LocationPickerDialog`。
    -   **`theme/`**: 存放主題相關的定義 (`themes.dart`)。

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
