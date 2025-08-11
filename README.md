# PMS_External_Service_Flutter

PMS Flutter版本同時讓iOS與Android平台使用，也支援Web以及桌面應用程式。由女媧場域配置，設定好要串接的額外的外部服務，MCS在指定的時機點呼叫下述NUWA Cloud Adapter標準API，達到串接外部服務的能力。

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
