# PMS External Service Flutter App (PMS 外部服務觸發器)

## 1. Project Overview (專案總覽)

This is a Flutter desktop application designed to interact with the Nuwa Robotics Platform Management System (PMS). It serves as an external tool for triggering and monitoring robot missions.

(這是一個 Flutter 桌面應用程式，旨在與女媧機器人平台管理系統 (PMS) 進行互動。它作為一個外部工具，用於觸發和監控機器人任務。)

---

## 2. Core Features (核心功能)

*   **Mission Triggering (任務觸發)**: Users can select a field (場域) and a specific robot to send on a delivery mission. The UI provides a form to specify mission details like destination, pickup location, and item information.
    (使用者可以選擇一個場域和特定的機器人來執行遞送任務。UI 提供一個表單來指定任務細節，如目的地、取貨點和物品資訊。)

*   **Robot Status Monitoring (機器人狀態監控)**: The application displays a real-time table of all robots within a selected field, showing their serial number, battery level, connection status, software version, and more.
    (應用程式會顯示一個即時的表格，其中包含所選場域內所有機器人的狀態，顯示其序號、電池電量、連線狀態、軟體版本等。)

*   **Recent Missions List (近期任務列表)**: A list on the main page shows the most recently triggered missions, providing a quick overview of recent activity.
    (主頁上的一個列表會顯示最近觸發的任務，提供近期活動的快速概覽。)

*   **Real-time Map Tracking (即時地圖追蹤)**: For each recent mission, users can click a "View Map" (查看地圖) button to open a dialog. This dialog displays:
    (對於每個近期任務，使用者可以點擊「查看地圖」按鈕來打開一個對話框。該對話框會顯示：)
    *   The specific map for that mission. (該任務的特定地圖。)
    *   Fixed points of interest (e.g., charging stations, locations) relevant to that map. (與該地圖相關的固定點位（例如充電站、地點）。)
    *   The robot's live position and trail, updated in real-time via MQTT. (透過 MQTT 即時更新的機器人位置和軌跡。)

---

## 3. Project Structure (專案結構)

The project follows a standard Flutter structure, with the core logic located in the `lib/` directory.

(該專案遵循標準的 Flutter 結構，核心邏輯位於 `lib/` 目錄中。)

*   **`main.dart`**: The application's entry point. (應用程式的入口點。)
*   **`config.dart`**: A singleton class that manages global configuration, including API endpoints and cached data like the list of fields. (一個單例類別，管理全域設定，包括 API 端點和快取的資料，如場域列表。)
*   **`lib/providers/`**: Contains the state management logic using the `provider` package.
    (包含使用 `provider` 套件的狀態管理邏輯。)
    *   `trigger_page_provider.dart`: Manages the state for the main trigger page, including form data, robot lists, and recent missions. (管理主觸發頁面的狀態，包括表單資料、機器人列表和近期任務。)
*   **`lib/pages/`**: Contains the main UI screens (views) of the application.
    (包含應用程式的主要 UI 畫面（視圖）。)
    *   `trigger_page.dart`: The main page of the application, containing the mission trigger form and status displays. (應用程式的主頁面，包含任務觸發器表單和狀態顯示。)
*   **`lib/widgets/`**: Contains reusable UI components.
    (包含可重複使用的 UI 組件。)
    *   `map_tracking_dialog.dart`: The dialog widget that contains all the logic for rendering the map, fixed points, and the robot's real-time trail. (包含所有繪製地圖、固定點和機器人即時軌跡邏輯的對話框 widget。)
*   **`lib/utils/`**: Contains utility classes and services.
    (包含工具類別和服務。)
    *   `api_service.dart`: Handles communication with the external REST API. (處理與外部 REST API 的通訊。)
    *   `mqtt_service.dart`: A singleton service to manage the MQTT connection and data stream. (一個單例服務，用於管理 MQTT 連接和資料流。)

---

## 4. How to Run (如何執行)

1.  **Clone the repository:**
    (複製儲存庫：)
    ```bash
    git clone <repository_url>
    cd PMS_Flutter
    ```

2.  **Get dependencies:**
    (獲取依賴項：)
    ```bash
    flutter pub get
    ```

3.  **Configure API Token:**
    (設定 API Token：)
    The application requires an API token to communicate with the backend. This token should be set within the application, likely on a settings page.
    (本應用程式需要一個 API token 才能與後端通訊。此 token 應在應用程式內設定，可能在設定頁面中。)

4.  **Run the application:**
    (執行應用程式：)
    ```bash
    flutter run -d <windows|macos|linux>
    ```

---
This README provides a basic overview. For detailed logic, please refer to the source code and the bilingual comments within.
(本 README 提供了基本概述。有關詳細邏輯，請參考原始碼及其中的雙語註解。)
