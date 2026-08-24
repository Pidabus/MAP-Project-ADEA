# 🌟 AllInOne — Personal Productivity & Finance Dashboard

AllInOne is a comprehensive personal management and productivity application designed to help users streamline their daily lives. By combining secure user accounts, dynamic finance tracking, automated budgets, task management with calendar integration, and interactive goal tracking, AllInOne serves as a premium, unified hub for everyday efficiency.

> 🚀 **Current Status:** Sprint 1, 2, and 3 are fully completed. Sprint 4 (Premium Features & Advanced Insights) is currently in progress.

---

## 📸 Key Features

### 👤 Secure User Accounts & Customization (Sprint 1)
*   **Secure Authentication:** Log in safely using email/password or Google Sign-In.
*   **Onboarding Flow (Sprint 2):** A guided, multi-page onboarding walkthrough introducing key features to new users.
*   **Profile Management:** Access user details, toggle app-wide Dark Mode/Light Mode settings, and set daily notification preferences.

### 💰 Finance Tracking & Automation (Sprint 1 & 2)
*   **Manual Recurring Transactions (Bank API Replacement):** Easily set up, track, and manage weekly, monthly, or yearly bills.
*   **Budgeting:** Establish monthly budget limits by category with automatic notifications/alerts when overspending.
*   **Auto-Categorization:** Input transactions and watch categories auto-select using smart title keyword heuristics (e.g., "KFC" maps to *Food & Dining*, "Grab" to *Transport*).

### 📋 Task Management (Sprint 1 & 2)
*   **Daily Tasks CRUD:** Create, toggle completion, and swipe to delete everyday tasks.
*   **Calendar View:** Seamless integration with `table_calendar` to display task markers on due dates.
*   **Due Dates & Reminders:** Set custom due dates with individual local reminders for each task.

### 🎯 Goal Tracking & Insights (Sprint 2 & 3)
*   **Goal Progress Indicators:** Visualize progress with dynamic, color-coded progress bars.
*   **Personalized Coaching/Feedback:** Context-aware feedback based on goal pace, target dates, and progress percentage.
*   **Smart Daily Summary (Sprint 3):** Receive an automated daily summary notification of total expenses at 8:00 PM.

---

## 🧰 Tech Stack & Packages
*   **Frontend Framework:** Flutter (Dart)
*   **State Management:** BLoC / Cubit
*   **Backend & DB:** Firebase (Auth, Firestore)
*   **Notification Engine:** `flutter_local_notifications`
*   **UI/UX Packages:** `table_calendar`, `fl_chart`, `google_fonts`

---

## 🏗️ Roadmap & Sprint Status

| Sprint | Feature Area | Status | Notes |
|---|---|---|---|
| **Sprint 1** | Foundation | ✅ Completed | Auth, Basic Finance, Auto-Categorization, Tasks, Navigation |
| **Sprint 2** | Core Features | ✅ Completed | Onboarding Flow, Financial Summaries, Task Calendar, Reminders |
| **Sprint 3** | Engagement | ✅ Completed | Goal visual progress, coaching feedback, Daily Notifications |
| **Sprint 4** | Premium & Polish | ✅ Completed | Premium upgrade flows, Cashflow Trends charts, AI-based insights |

---

## ⚙️ Local Setup

Follow these steps to run the development version of the application locally:

### Prerequisites
*   Flutter SDK installed (v3.0.0 or higher recommended)
*   An emulator, simulator, or physical test device connected

### Steps
1.  **Clone the Repository:**
    ```bash
    git clone https://github.com/azimadanan/MAP-Project-ADEA.git
    ```
2.  **Install Dependencies:**
    ```bash
    flutter pub get
    ```
3.  **Run the App:**
    ```bash
    flutter run
    ```
    To run specifically on Google Chrome:
    ```bash
    flutter run -d chrome
    ```
