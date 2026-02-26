# Android 에뮬레이터 크래시 원인 확인 방법

에뮬레이터에서 앱이 바로 죽을 때, **원인 파악 없이** 로직을 바꾸지 말고, 먼저 크래시 로그를 봅니다.

## 1. 로그 수집 (앱 실행 전에 터미널에서 실행)

```bash
# 로그 버퍼 비우기
adb logcat -c

# 크래시 관련 로그만 파일로 저장 (앱 실행한 뒤 죽으면 이 파일에 원인이 남음)
adb logcat -v time *:E AndroidRuntime:E DEBUG:E flutter:V \
  -s "AndroidRuntime:F" "libc:F" "DEBUG:E" \
  2>&1 | tee crash_log.txt
```

- 위 명령을 **실행한 상태로 두고**, 다른 터미널이나 IDE에서 앱을 실행합니다.
- 앱이 죽은 뒤 `crash_log.txt` 내용을 확인합니다.
- **FATAL EXCEPTION**, **Caused by**, **at ...** 로 시작하는 스택이 **진짜 원인**입니다.

## 2. 더 넓게 보고 싶을 때

```bash
adb logcat -c
adb logcat -v threadtime 2>&1 | tee full_log.txt
```

- 앱 실행 → 크래시 후 `full_log.txt`에서 프로세스가 죽기 직전 구간을 찾습니다.
- `FATAL`, `Exception`, `Error`, `crash` 로 검색하면 됩니다.

## 3. 로그에서 확인할 것

- **Java/Kotlin 예외**: `FATAL EXCEPTION`, `Caused by: java...` → 어떤 라이브러리/초기화에서 터졌는지 확인.
- **Native 크래시**: `signal 6 (SIGABRT)`, `backtrace:`, `#00 pc` → 네이티브(NDK) 쪽이면 해당 so/플러그인 확인.
- **Flutter**: `flutter:` 태그와 Dart 예외 메시지.

## 4. 다음 단계

- `crash_log.txt`(또는 해당 구간)에서 **정확한 예외 메시지와 스택**을 확인한 뒤,
- 그 원인(특정 SDK 초기화, 권한, ABI, 의존성 등)에 맞춰 수정합니다.
- 에뮬레이터/실기기 **동일 로직**을 유지하고, 원인에만 대응합니다.
