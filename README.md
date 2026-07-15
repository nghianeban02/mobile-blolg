# Nook Mobile

Ứng dụng Flutter dành cho Nook, dùng chung API với `web-blog` và `be-blog`.

## Tính năng

- Auth: đăng nhập, tài khoản khách, đăng ký, xác minh email, gửi lại email, quên/đặt lại mật khẩu và khôi phục JWT khi mở app.
- Feed: post/review, ảnh gallery, like/reaction, bình luận luồng, profile, bạn bè và thông báo.
- Editorial: tạo/sửa/xóa post, tạo/sửa/xóa review, moderation admin.
- Library: catalog sách, thêm/sửa sách, cover, tác giả, thể loại và reading list.
- Search: tìm kiếm server-side theo post/review/book, đếm theo bộ lọc; fallback local khi API search không dùng được.
- Saved & streak: bookmark đồng bộ web và streak hoạt động 7 ngày.
- Notes: CRUD, search, màu, pin, folder, label, archive, trash, restore, duplicate và xóa vĩnh viễn.
- Calendar: task theo ngày, hoàn thành, Pomodoro, số phiên và tổng thời gian tập trung.
- Messaging: direct/group chat, realtime qua WebSocket (ticket + heartbeat + auto-reconnect, polling chỉ là dự phòng khi mất kết nối), typing indicator, presence online, unread/read receipt, search, quick reactions (❤️ 👍 😂 😮 😢 🙏), revoke và upload/xem ảnh riêng tư qua presigned URL.
- Admin: quản lý user, post moderation và catalog.
- Push: FCM token được đăng ký/gỡ với `be-blog` khi Firebase native đã được cấu hình.

## Yêu cầu

- Flutter `3.38.7`, Dart `3.10.7`.
- iOS `15.0+` (yêu cầu của Firebase Apple SDK 12.15).
- `be-blog` ở port `8080` khi chạy local.
- `messaging-service` ở port `8081` khi bật chat local.

## Chạy nhanh

Production API là mặc định:

```bash
flutter pub get
flutter run
```

Android emulator/iOS simulator với backend local:

```bash
flutter run --dart-define-from-file=config/dev.example.json
```

iPhone thật cần URL LAN cụ thể:

```bash
flutter run \
  --dart-define=API_BASE_URL=http://192.168.1.3:8080 \
  --dart-define=MESSAGING_API_URL=http://192.168.1.3:8081
```

Các define hỗ trợ:

| Define | Mặc định | Ý nghĩa |
|---|---|---|
| `API_BASE_URL` | Railway `be-blog` | Ghi đè URL API chính |
| `USE_LOCAL_API` | `false` | Tự dùng `10.0.2.2` Android, `127.0.0.1` iOS simulator |
| `MESSAGING_ENABLED` | `true` | Bật/tắt toàn bộ chat |
| `MESSAGING_API_URL` | Railway messaging | Ghi đè URL dịch vụ chat |

## Firebase push

App vẫn build khi thiếu Firebase và tự tắt push an toàn. Để bật push:

1. Android: đặt `google-services.json` vào `android/app/`.
2. iOS: đặt `GoogleService-Info.plist` vào `ios/Runner/` và thêm file vào Runner target trong Xcode.
3. Bật Push Notifications và Background Modes → Remote notifications cho App ID `com.nguyenhuunghia.mobileblog`.
4. Cấu hình APNs key trong Firebase Console.

Android 13+ đã khai báo `POST_NOTIFICATIONS`; iOS đã có background mode và `aps-environment` theo build configuration.

## Deep link đặt lại mật khẩu

App nhận:

- `https://nooknh.com/reset-password?token=...`
- `nook://reset-password?token=...`

Để Universal/App Link được xác minh hoàn toàn, domain cần phục vụ:

- `https://nooknh.com/.well-known/apple-app-site-association`
- `https://nooknh.com/.well-known/assetlinks.json`

Khi domain chưa cấu hình hai file này, người dùng vẫn có thể dán token từ email vào màn “Đặt lại mật khẩu”.

## Release signing

Android:

```bash
cp android/key.properties.example android/key.properties
# Điền upload keystore thật; key.properties và *.jks đã được gitignore.
flutter build appbundle --release --dart-define-from-file=config/production.example.json
```

Nếu chưa có `key.properties`, release build local dùng debug key chỉ để smoke test và không được dùng để phát hành.

iOS:

```bash
cd ios && pod install && cd ..
flutter build ios --release --dart-define-from-file=config/production.example.json
```

Chọn đúng Team/provisioning profile trong `ios/Runner.xcworkspace`. Xem thêm `ios/IOS_DEVICE_SETUP.md`.

## Kiểm tra chất lượng

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test --coverage
flutter build apk --debug
flutter build ios --simulator --debug
flutter build appbundle --release --dart-define-from-file=config/production.example.json
flutter build ios --release --no-codesign --dart-define-from-file=config/production.example.json
```

CI tương ứng nằm tại `.github/workflows/mobile-ci.yml`.

## Cấu trúc

```text
lib/
├── app/                 # MaterialApp, startup/session restore, routes
├── core/                # HTTP, cache, config, theme, shared widgets/services
├── data/                # DTO + repositories cho be-blog/messaging-service
└── features/            # auth, feed, library, notes, calendar, messaging, ...
```
