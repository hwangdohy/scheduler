# 위클리 (Toss-style Schedule App)

Flutter app: weekly timetable + todo + calendar + AI-summarized diary, styled after Toss (white background, black text, fluorescent-yellow `#F2FF3A` accent).

## Setup (Flutter is not installed in this environment)

1. Install the Flutter SDK: https://docs.flutter.dev/get-started/install
2. From this folder, generate the missing platform projects (this repo only has `lib/` and `pubspec.yaml` so far):
   ```
   flutter create .
   ```
   This fills in `android/`, `ios/`, etc. around the existing `lib/` code without touching it.
3. Install packages:
   ```
   flutter pub get
   ```
4. Android only — add these permissions inside `android/app/src/main/AndroidManifest.xml` (inside `<manifest>`, above `<application>`) for the diary reminder notification:
   ```xml
   <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
   <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
   <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
   ```
5. Run:
   ```
   flutter run
   ```

## Gemini API key

The diary summary feature (Settings → AI 요약) needs a Gemini API key pasted in-app — get one free at https://aistudio.google.com/apikey. Without a key, diary summaries fall back to a simple local keyword picker so the app still works offline.

## Project layout

```
lib/
  models/       Schedule, TodoItem, CalendarEvent, DiaryEntry
  services/     DatabaseService (sqflite), SettingsService, GeminiService, NotificationService
  theme/        AppColors, AppTheme (Toss palette)
  screens/
    timetable/  Main screen — weekly Mon–Sun x 24h grid (priority 1)
    diary/      Diary entry + Gemini keyword summary (priority 2)
    todo/       Todo list with priority + strikethrough
    calendar/   Monthly calendar with per-date events
    settings/   Notification time/toggle, font size, Gemini key
    root/       Bottom-tab shell (timetable is tab 0, shown on launch)
```

## Status vs. spec

- ✅ Weekly timetable main screen, tap-to-add/edit schedule blocks
- ✅ Diary writing + Gemini keyword summarization (with offline fallback)
- ✅ Local daily reminder notification → opens diary for today
- ✅ Todo list (add/check/delete, priority, strikethrough)
- ✅ Monthly calendar with event dots + per-date detail sheet
- ⏳ Not yet done: app icon/launcher assets, dark mode, dedicated automated tests
