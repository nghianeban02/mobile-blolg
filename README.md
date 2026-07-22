# Nook Mobile

Ứng dụng Flutter (iOS + Android) cho Nook — dùng chung nghiệp vụ và API với `web-blog`, `be-blog` và `messaging-service`.

## Kiến trúc

Clean Architecture feature-first với **Bloc**, **Dio**, **GoRouter**, **flutter_secure_storage**. Chi tiết: [ARCHITECTURE.md](ARCHITECTURE.md). Ánh xạ màn hình ↔ API: [API_MAPPING.md](API_MAPPING.md).

## Yêu cầu

- Flutter ổn định (SDK ^3.10), Dart 3
- iOS 15.0+
- `be-blog` (port 8080) và tùy chọn `messaging-service` (port 8081) khi chạy local

## Cấu hình môi trường

Sao chép ví dụ rồi chỉnh URL/IP:

```bash
cp config/dev.example.json config/dev.json
cp config/production.example.json config/production.json
```

| Key | Ý nghĩa |
|---|---|
| `APP_ENV` | `development` / `production` — ảnh hưởng `AppConfig.appLabel` |
| `API_BASE_URL` | Ghi đè URL be-blog |
| `USE_LOCAL_API` | Local: Android emulator `10.0.2.2`, iOS simulator loopback, thiết bị thật dùng `DEV_LAN_HOST` |
| `MESSAGING_BASE_URL` | Ghi đè URL messaging-service |
| `USE_LOCAL_MESSAGING` | Tương tự cho chat |
| `MESSAGING_ENABLED` | Bật/tắt chat |
| `DEV_LAN_HOST` | IP LAN máy dev (iPhone thật) |

## Chạy

```bash
flutter pub get

# Production (mặc định Railway)
flutter run --dart-define-from-file=config/production.json

# Dev local
flutter run --dart-define-from-file=config/dev.json
```

Thiết bị thật:

```bash
flutter run \
  --dart-define=API_BASE_URL=http://192.168.1.3:8080 \
  --dart-define=MESSAGING_BASE_URL=http://192.168.1.3:8081 \
  --dart-define=APP_ENV=development
```

## Kiểm thử

```bash
flutter analyze
flutter test
```

## Build

```bash
# Android APK
flutter build apk --release --dart-define-from-file=config/production.json

# Android App Bundle (Play Store)
flutter build appbundle --release --dart-define-from-file=config/production.json

# iOS (cần signing trên Xcode)
flutter build ios --release --dart-define-from-file=config/production.json --no-codesign
```

Bundle ID: `com.nguyenhuunghia.mobileblog`. Tên hiển thị theo `APP_ENV` (`Nook` / `Nook Dev` trong app title).

## Auth & phiên

- JWT dài hạn (khớp BE / web), **không có refresh token** — phiên kết thúc khi đăng xuất hoặc server trả 401.
- Token lưu trong `flutter_secure_storage` (có migrate một lần từ SharedPreferences `auth_token`).
- HTTP 401 có auth → `SessionEvents` → `AuthBloc` đăng xuất → GoRouter về `/login`.

## i18n

Catalog 4 ngôn ngữ (vi/en/ja/de) lấy từ `web-blog/lib/i18n/messages` → `assets/i18n/*.json`.

```bash
node scripts/sync_i18n_from_web.mjs
```

Đổi ngôn ngữ trong Settings; dùng `context.t('nav.home')` / `LocaleController.instance.t(...)`.

## Firebase push

App build được khi thiếu Firebase và tự tắt push. Để bật:

1. Android: `android/app/google-services.json`
2. iOS: `ios/Runner/GoogleService-Info.plist` + Push Notifications / Background Modes
3. APNs key trong Firebase Console

**Chưa kiểm chứng end-to-end** trong repo này (file Firebase chưa có).

## Deep link

- `https://nooknh.com/reset-password?token=...`
- `https://nooknh.com/posts/:id`, `/reviews/:id`, `/users/:id`
- `nook://reset-password`, `nook://posts/...`, …

## Quyền đã khai báo

- Android: `INTERNET`, `CAMERA`, `READ_MEDIA_IMAGES`, `POST_NOTIFICATIONS`
- iOS: Camera, Photo Library (+ add), background remote notifications

## Tính năng

Hoàn thành (nghiệp vụ + nền tảng mới): auth, feed (Bloc + phân trang), posts (tạo có progress upload), social likes/comments/bookmarks (Bloc), search (Bloc debounce), notifications badge toàn cục, messages (stack hợp nhất + ConversationsBloc + Dio + WebRTC gọi thoại/video), library/reading list, notes, calendar + Pomodoro floating toàn app, friends, profile, admin, settings theme, dark/light.

Chưa / hạn chế:

- Freezed/json_serializable: giữ DTO viết tay (đã có test) để tránh nổ bán kính thay đổi
- Onboarding: web không có → bỏ qua
- Một số màn (chat thread chi tiết, admin, notes/calendar) vẫn setState nội bộ; đã có Bloc cho auth/feed/create-post/conversations/notifications/search/settings/social
- Một số chuỗi nội dung màn hình chưa thay hết sang `t()` (catalog đã sẵn)
- Push FCM: chưa kiểm chứng thiếu Firebase config
- iOS IPA: cần signing thủ công trên máy Mac có certificate
