# 룬 (Rune) - A Flutter-Based Calendar App

A simple, offline-first calendar application built with Flutter.

## 🚀 Overview

This project is a mobile-first calendar application designed for personal use. It provides a clean and intuitive interface for managing your schedule, with all data stored locally on your device.

### Who is this for?

- Users who want a private, no-frills calendar.
- Developers looking for a practical example of a Flutter application using `table_calendar` and `hive` for local storage.

### When to use this?

- For personal scheduling and event tracking.
- As a starting point for building a more feature-rich calendar app.

### When not to use this?

- If you need collaborative features or cloud synchronization across multiple devices.

## ✨ Key Features

- **Intuitive Calendar View**: A customizable calendar display powered by `table_calendar`.
- **Offline-First**: All your data is stored locally using `hive`, so you can access your schedule without an internet connection.
- **Clean UI**: A minimalist user interface with custom fonts from `google_fonts`.
- **Cross-Platform**: Built with Flutter, this app can be compiled for Android, iOS, and other platforms.
- **CSV-input Supported**: Supports CSV import for bulk creation of events.

## 🏗️ How It Works

The application is built using a standard Flutter architecture.

- The UI is built with Flutter widgets.
- The main screen features a calendar view from the `table_calendar` package.
- Events and user data are stored in a local `hive` database.
- The `intl` package is used for date formatting and localization.

## 📁 Project Structure

```
├── lib
│   ├── main.dart           # App entry point
│   └── pages
│       └── calendar.dart   # Main calendar screen
├── android
├── ios
├── web
├── linux
├── macos
├── windows
└── pubspec.yaml            # Project dependencies
```

## 🔧 Installation

### Prerequisites

- Flutter SDK
- A code editor (like VS Code or Android Studio)
- An Android emulator, iOS simulator, or a physical device

### Steps

1.  **Clone the repository:**
    ```sh
    git clone https://github.com/your-username/rune.git
    cd rune
    ```
2.  **Install dependencies:**
    ```sh
    flutter pub get
    ```
3.  **Run the app:**
    ```sh
    flutter run
    ```

## 💻 Usage

- Launch the app on your device or emulator.
- The main screen will display a calendar.
- Tap on a date to view, add, or edit events for that day.

## ⚙️ Configuration

There are no environment variables or special configuration files to set up. All project dependencies and settings are managed in `pubspec.yaml`.

## ⚠️ Limitations & Assumptions

- **Local Data Only**: This application does not support cloud synchronization. All data is stored on the device and will be lost if the app is uninstalled.
- **Single User**: Designed for a single user on a single device.

## 🐞 Troubleshooting

- If you encounter issues with your Flutter environment, run `flutter doctor` to diagnose the problem.
- For dependency-related issues, try running `flutter clean` followed by `flutter pub get`.

## 🤝 Contributing

Contributions are welcome! If you'd like to help improve this project, please follow these steps:

1.  Fork the repository.
2.  Create a new branch (`git checkout -b feature/your-feature`).
3.  Make your changes.
4.  Commit your changes (`git commit -m 'Add some feature'`).
5.  Push to the branch (`git push origin feature/your-feature`).
6.  Open a pull request.

Please run `flutter analyze` to check for any code style issues before submitting a pull request.


