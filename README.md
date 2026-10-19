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

## 가계부 사용법

- 캘린더에서 날짜를 누르면 **하루 지출**에 고정 지출을 제외한 생활비 합계를 저장할 수 있습니다. 같은 날짜를 다시 저장하면 기존 금액을 대체하며, 0원 기록과 기록 삭제도 지원합니다.
- **가계부** 탭에서 년도와 월을 선택한 뒤 **예산 수정**으로 월급, 추가수입, 저축 목표와 고정 지출 항목별 이름·금액을 설정합니다. 예산은 월별로 따로 저장됩니다.
- 월 생활비 예산 = 월급 + 추가수입 − 저축 목표 − 고정 지출 합계.
- 남은 생활비 = 월 생활비 예산 − 해당 월에 기록한 생활비 지출 합계.
- 하루 가용 금액은 남은 생활비를 오늘을 포함한 월말까지의 날짜 수로 나누고 원 미만을 버립니다. 미래 월은 전체 일수로 나누며, 지난 월과 예산 초과 시에는 0원을 표시합니다. 초과 금액은 별도로 표시합니다.
- 월 전체 기준 하루 예산도 함께 표시합니다. 윤년과 월별 일수를 반영합니다.
- 데이터는 기기 또는 웹 브라우저의 로컬 저장소에 저장됩니다. 기기 간 동기화는 제공하지 않습니다.

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
