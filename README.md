# Offline-First Queue App with Geolocation (TP5)

An **Offline-First**, location-aware queue management application built with **Flutter**, **SQLite (`sqflite`)**, **Geolocation (`geolocator`)**, **Provider**, and **Supabase (PostgreSQL)**.

Clients are saved locally in SQLite immediately and synchronized to the cloud in the background. The app captures GPS coordinates with 4-decimal precision and gracefully falls back when location services are unavailable.

---

## 📌 Features

- **Offline-First Persistence**: Instant local writes using SQLite (`sqflite`). Works seamlessly without internet connectivity.
- **Non-Blocking Cloud Sync**: Background synchronization engine using `upsert` to update Supabase without degrading UI performance.
- **Geolocation Capture**: Captures latitude and longitude with 4-decimal precision (approx. 11m accuracy) via `geolocator`.
- **Real-Time Synchronization**: Instant multi-device updates via Supabase WebSocket channels (`supabase_realtime`).
- **Optimistic UI Updates**: State mutations reflect immediately for instantaneous user feedback.
- **Cross-Platform Compatibility**: Fully verified on Web (Microsoft Edge / Chrome) with memory fallback, Windows Desktop via SQLite FFI, and Mobile (Android / iOS).
- **100% Automated Test Coverage**: 17 passing tests across model, local storage, provider, geolocation, and widget suites.

---

## 🏗️ Project Architecture

```
tp5_flutter/
├── lib/
│   ├── models/
│   │   └── client.dart               # Data model with lat, lng, and sync state
│   ├── local_queue_service.dart      # SQLite local persistence & web fallback
│   ├── geolocation_service.dart      # GPS position & permission management
│   ├── queue_provider.dart           # Offline-first state manager & Supabase sync
│   └── main.dart                     # App entry point & WaitingRoomScreen UI
│
├── test/
│   ├── client_model_test.dart        # Model serialization & deserialization tests
│   ├── local_queue_service_test.dart # SQLite local storage & flag tests
│   ├── queue_provider_geolocation_test.dart # Geolocation capture & UI widget tests
│   ├── queue_provider_test.dart      # Supabase upsert verification test
│   ├── waiting_room_manager_test.dart# Queue provider FIFO and CRUD tests
│   └── waiting_room_widget_test.dart # UI widget interaction & button tests
│
├── documentation/
│   ├── DOCUMENTATION.md              # Detailed technical documentation
│   ├── DOCUMENTATION_TP5.docx        # Formatted Microsoft Word deliverable
│   └── DOCUMENTATION_TP5.pdf         # Printable PDF deliverable
│
└── compte_rendu_ai/
    ├── forma.md                      # AI interaction report with 5 student prompts
    ├── FORMA_TP5.docx                # Formatted AI report in Word
    └── FORMA_TP5.pdf                 # Printable AI report PDF
```

---

## ⚙️ Core Components

1. **`LocalQueueService` (`lib/local_queue_service.dart`)**:
   Manages the `local_clients` SQLite table (`id`, `name`, `lat`, `lng`, `created_at`, `is_synced`). Features transparent in-memory fallback for web browsers (Microsoft Edge).

2. **`GeolocationService` (`lib/geolocation_service.dart`)**:
   Requests location permissions and queries current coordinates with low accuracy and a 5-second timeout. Traps platform exceptions safely.

3. **`QueueProvider` (`lib/queue_provider.dart`)**:
   Coordinates local SQLite persistence, optimistic UI updates, real-time Supabase subscriptions, and non-blocking background synchronization (`unawaited(_syncLocalToRemote())`).

4. **`WaitingRoomScreen` (`lib/main.dart`)**:
   Responsive user interface displaying queued clients with their formatted coordinates (`📍 36.8065, 10.1815`) or fallback text (`📍 Location not captured`).

---

## 🧪 Testing

To execute all 17 automated tests:

```bash
flutter test
```

To run static analysis:

```bash
dart analyze
```

---

## 🚀 How to Run

1. **Setup environment variables**:
   ```bash
   cp .env.example .env
   # Add your SUPABASE_URL and SUPABASE_ANON_KEY in .env
   ```

2. **Launch on Microsoft Edge (Web)**:
   ```bash
   flutter run -d edge
   ```

3. **Launch on Windows Desktop**:
   ```bash
   flutter run -d windows
   ```

4. **Launch on Android**:
   ```bash
   flutter run -d android
   ```
