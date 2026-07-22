# Bảng đối chiếu chức năng Web (web-blog) ↔ Mobile (Flutter)

Cập nhật: 2026-07-22. Trạng thái: ✅ tương đương · 🟡 tương đương một phần · ❌ chưa có · ➖ không áp dụng cho mobile.

Mobile shell đã căn theo web mobile: header (menu + search + streak + bell),
drawer sidebar, bottom nav Home/Search/Write/Library/Me(profile), settings
khớp `/settings`. Đã gỡ màn Developer/API demo (web không có).

## Xác thực & phiên

| Chức năng | Web | Mobile | Ghi chú |
|---|---|---|---|
| Đăng nhập / khách | `/login` | `login_screen` | ✅ cùng `POST /api/auth/login\|guest` |
| Đăng ký + xác thực email | `/register`, `/verify-email` | `register_screen`, `verify_email_screen` | ✅ |
| Quên / đặt lại mật khẩu | `/forgot-password`, `/reset-password` | 2 screen tương ứng | ✅ deep link reset qua GoRouter |
| Hết hạn phiên → đăng nhập lại | session-expiry guard | `SessionEvents` + AuthBloc redirect | ✅ |
| Đổi mật khẩu | `/settings/password` | `change_password_screen` | ✅ |

## Nội dung & mạng xã hội

| Chức năng | Web | Mobile | Ghi chú |
|---|---|---|---|
| Bảng tin + trending + streak | `/home` | `home_screen` | ✅ |
| Bài viết: xem/tạo/sửa/xóa + gallery ảnh | `/posts/*` | 4 screens + `post_image_viewer` | ✅ multipart cùng contract |
| Review sách: xem/tạo/sửa | `/reviews/*` | review feature (3 screens) | ✅ |
| Sách + thư viện + reading list | `/books/*`, `/library`, `/reading-list` | reading_list feature (5 screens) | ✅ |
| Like / comment / bookmark | components dùng chung | likes/comments/engagement repos | ✅ |
| Bạn bè (mời/chấp nhận/gợi ý) | `/friends` | `friends_screen` | ✅ |
| Tìm kiếm (archive + user) | `/search` | `search_screen` | ✅ |
| Đã lưu | `/saved` | `saved_screen` | ✅ |
| Hồ sơ (xem/sửa) | `/profile/*` | `user_profile_screen`, `edit_profile_screen` | ✅ |
| Admin (users/posts/catalog) | `/admin/*` | admin feature (3 screens) | ✅ ẩn theo role |
| Trang public SEO (`/p/*`, RSS, sitemap) | có | — | ➖ chỉ có ý nghĩa trên web |

## Năng suất

| Chức năng | Web | Mobile | Ghi chú |
|---|---|---|---|
| Ghi chú (labels, màu, rich text) | `/notes` | `notes_screen` + editor | ✅ |
| Lịch + nhiệm vụ ngày | `/calendar` | `calendar_screen` | ✅ |
| Pomodoro | floating timer toàn app | calendar + floating overlay toàn app | ✅ `PomodoroTimerController` + `PomodoroFloatingTimer` |

## Nhắn tin & cuộc gọi

| Chức năng | Web | Mobile | Ghi chú |
|---|---|---|---|
| Danh sách hội thoại + unread + tìm kiếm | Messenger sidebar | `conversations_screen` | ✅ |
| Chat text/sticker + reply/reaction/thu hồi/sửa | Messenger | `chat_screen` | ✅ |
| Gửi ảnh (presign → upload → complete) + xem ảnh | Messenger (mới 2026-07) | `chat_screen` (image_picker) | ✅ hai bên cùng pipeline |
| Typing / presence / seen | Messenger | `chat_screen` (WS) | ✅ |
| Nhóm chat (tạo/đổi tên/thành viên) | Messenger dialogs | conversations/chat widgets | ✅ |
| Gọi thoại / video (WebRTC) | chat-call-context + TURN | `CallController` + `CallOverlay` + nút trên chat | ✅ cùng signaling WS + REST calls + poll `/api/chat/call-signals` fallback |
| Ringtone / ringback | Web Audio | SystemSound + Haptic | ✅ |
| Nhận push cuộc gọi + mở đúng hội thoại | SW notification actions | FCM tap → conversation; overlay nhận cuộc gọi khi WS/poll có offer | ✅ auto-answer deep link `answer=1` |

## Thông báo

| Chức năng | Web | Mobile | Ghi chú |
|---|---|---|---|
| Danh sách + đã đọc + realtime | `/notifications` (SSE) | `notifications_screen` | ✅ |
| Push khi app đóng (FCM) | Web Push SW (mới) | `push_notifications_service` | ✅ cùng pipeline be-blog |
| Tùy chọn push theo 6 loại | Settings → Thông báo đẩy (mới) | Settings → PUSH NOTIFICATIONS (**mới 2026-07-18**) | ✅ cùng `GET/PUT /api/notifications/preferences` |
| Deep link từ notification | SW `data.link` | `getInitialMessage`/`onMessageOpenedApp` | ✅ |

## Cài đặt & trải nghiệm

| Chức năng | Web | Mobile | Ghi chú |
|---|---|---|---|
| Theme sáng/tối + cỡ chữ | display preferences | `SettingsBloc` + DisplayPreferences | ✅ |
| Âm thanh tin nhắn / cuộc gọi | ChatSoundSettings | Settings → sounds + SystemSound | ✅ |
| Chia sẻ bài / review | ShareButton | ShareButton (share_plus) | ✅ |
| Đa ngôn ngữ (vi/en/ja/de) | locale context | `LocaleController` + Settings | ✅ catalog JSON sync từ web |
| Loading / empty / error state | skeleton + EmptyState | mỗi screen tự xử lý | ✅ |

## Việc còn lại (đã thống nhất là gap, không phải bug)

1. **i18n coverage**: chrome chính đã dùng `t()`; một số màn nội dung vẫn còn chuỗi cứng — chạy `node scripts/sync_i18n_from_web.mjs` khi web cập nhật copy rồi thay dần.
2. **Call polish**: chọn thiết bị I/O chi tiết như web; ringtone dùng SystemSound/Haptic.
3. **Push FCM end-to-end**: cần file Firebase config trên máy build (chưa có trong repo).
4. **Public SEO pages** (`/p/*`, RSS): ➖ chỉ web.
