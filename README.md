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

## CSV로 매주 반복하는 기본 일정 가져오기

1. 정해진 양식의 UTF-8 CSV를 준비합니다. API 키와 네트워크는 필요하지 않습니다.
2. 양식 변환이 필요하면 설정 → **Gemini API 키가 없어요** → **변환 프롬프트 복사**를 누릅니다.
   ChatGPT나 Gemini에 일정 자료와 함께 붙여넣고 결과를 UTF-8 CSV 파일로 저장하세요.
3. 첫 행은 반드시 `요일,시작 시간,종료 시간,제목,메모`이며 모든 행에 5개 열이 필요합니다.
   요일은 월요일~일요일, 시간은 HH:mm 형식입니다. 종료 시간만 24:00을 허용합니다.
   예제는 `examples/weekly_schedule.csv`를 참고하세요. 최대 100KB, 일정 최대 200개입니다.
4. 기본 일정 화면의 파일 업로드 아이콘으로 CSV를 선택합니다. CSV는 외부로 전송되지 않습니다.
   미리보기에서 요일과 시간을 확인하고 추가할 일정을 선택합니다.
5. 추가 버튼을 누르면 매주 반복하는 기본 일정에 저장합니다.

기존 일정과 일기는 유지하며 같은 요일·시작/종료 시간·제목은 중복으로 추가하지 않습니다.
개별 수정한 날짜의 일정은 기존 동작대로 유지됩니다.
미리보기에서 제외한 일정은 저장되지 않으며 추가 후 기본 일정 편집으로 수정할 수 있습니다.

## 웹 배포

`main` 브랜치에 커밋을 push하면 `.github/workflows/deploy-pages.yml`의 GitHub Actions가
테스트와 웹 빌드를 거쳐 GitHub Pages로 배포합니다.
GitHub 저장소의 Actions에서 배포 성공 여부를 확인하세요.

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
