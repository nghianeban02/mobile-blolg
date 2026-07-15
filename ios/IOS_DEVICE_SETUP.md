# Chạy app trên iPhone thật (fix signing)

## Lỗi thường gặp

1. **Unable to log in with account … rejected** — Apple ID trong Xcode hết hạn / sai mật khẩu.
2. **No profiles for 'com.example.mobile'** — Bundle ID mặc định không tạo được profile.

Project đã đổi Bundle ID thành: **`com.nguyenhuunghia.mobileblog`**

## Các bước (làm trên Mac)

### 1. Đăng nhập lại Apple ID trong Xcode

1. Mở **Xcode** → **Settings** (⌘,) → tab **Accounts**
2. Chọn `nghiamc147@icloud.com` → **Sign Out** (hoặc dấu **−** xóa account)
3. Bấm **+** → **Apple ID** → đăng nhập lại (mật khẩu + mã 2FA)
4. Chọn team **Personal Team** (miễn phí, đủ để cài lên máy của bạn)

### 2. Cấu hình Signing cho Runner

1. Mở workspace (không mở `.xcodeproj`):

   ```bash
   open ios/Runner.xcworkspace
   ```

2. Cột trái: **Runner** (project) → target **Runner** → tab **Signing & Capabilities**
3. Bật **Automatically manage signing**
4. **Team**: chọn team của bạn (ví dụ tên bạn / Personal Team)
5. **Bundle Identifier**: `com.nguyenhuunghia.mobileblog` (phải trùng project)

Nếu báo đỏ “Failed to register bundle identifier”, đổi thành ID duy nhất, ví dụ:

`com.nguyenhuunghia.mobileblog.dev`

và cập nhật lại trong Xcode + `ios/Runner.xcodeproj` nếu cần.

### 3. Tin cậy máy phát triển trên iPhone

**Settings** → **General** → **VPN & Device Management** → tin cậy developer certificate.

### 4. Build lại từ terminal

```bash
cd "/Users/nguyenhuunghia/N/Personal Blog/mobile-blog"
flutter clean
flutter pub get
cd ios && pod install && cd ..
flutter run -d HuuNghia
```

## Đăng nhập báo "Không có kết nối mạng"

Trên **iPhone thật**, `localhost` là chính iPhone — không trỏ tới Mac chạy be-blog.

1. Mac và iPhone **cùng Wi‑Fi**
2. Chạy backend: `./mvnw spring-boot:run` (port **8080**)
3. Lấy IP Mac: `ifconfig en0` → ví dụ `192.168.1.3`
4. Sửa `lib/core/constants/api_constants.dart` → `devLanHost = '192.168.1.3'`
5. `flutter run` lại trên iPhone

Hoặc: `flutter run --dart-define=API_BASE_URL=http://192.168.1.3:8080`

### Ảnh post không hiện trên iPhone

API trả `titleImageUrl` dạng `http://localhost:8080/...` — iPhone không mở được. App đã tự đổi sang IP Mac (`devLanHost`).

Nên cấu hình backend (tùy chọn, trên Mac):

```bash
export APP_API_BASE_URL=http://192.168.1.3:8080
# rồi chạy lại be-blog
```

Hoặc sửa `be-blog/src/main/resources/application.properties`:

`app.api.base-url=http://192.168.1.3:8080`

## Lỗi: "Flutter could not access the local network" (wireless)

```
SocketException: Send failed ... No route to host, errno = 65 ... port = 5353
```

Flutter/Cursor cần quyền **Mạng cục bộ (Local Network)** trên Mac để tìm iPhone qua Wi‑Fi (mDNS cổng 5353). **Không sửa được bằng code Dart** — cấp quyền trên macOS.

### Cách sửa (làm lần lượt)

1. **System Settings** → **Privacy & Security** → **Local Network**
2. Bật **ON** cho:
   - **Cursor** (hoặc VS Code nếu dùng)
   - **Terminal** / **iTerm**
   - **Dart** / **flutter** (nếu có trong danh sách)
3. Tắt app Cursor/Terminal → mở lại → chạy lại:

   ```bash
   flutter devices
   flutter run -d HuuNghia
   ```

4. **Firewall Mac**: **System Settings** → **Network** → **Firewall** → tạm **Off** khi dev, hoặc **Options** → cho phép app dev nhận kết nối đến.

5. **Cùng Wi‑Fi**, tắt **VPN** trên Mac và iPhone. Router: tắt **AP isolation / Guest network** (guest thường không thấy máy trong LAN).

6. Xcode: **Window** → **Devices and Simulators** → iPhone có biểu tượng **mạng** (Connect via network). Nếu không: cắm USB 1 lần, tick lại **Connect via network**.

7. Vẫn lỗi → dùng **cáp USB** (ổn định hơn, đặc biệt iOS 26):

   ```bash
   flutter run -d HuuNghia
   ```

   App sau khi cài vẫn dùng backend qua Wi‑Fi (`devLanHost`) — **không cần dây khi chỉ mở app**.

8. Khởi động lại dịch vụ Flutter:

   ```bash
   killall -9 dart 2>/dev/null; flutter doctor -v
   ```

### Kiểm tra nhanh

```bash
flutter devices -v
```

Phải thấy `HuuNghia (wireless)`. Nếu không thấy → vấn đề pairing/quyền mạng, chưa phải project Flutter.

---

## Dùng iPhone không cắm dây (Wi‑Fi)

Cáp USB chỉ cần khi **cài / cập nhật** app lên iPhone. Sau khi app đã nằm trên máy, hàng ngày bạn chỉ cần **Wi‑Fi + backend chạy trên Mac** — không cần dây để đăng nhập hay xem ảnh.

### A. Cài app lần đầu qua Wi‑Fi (sau khi bật “Connect via network”)

1. **Một lần duy nhất** (nếu chưa bật): cắm iPhone → Xcode → **Window** → **Devices and Simulators** → chọn iPhone → tick **Connect via network** → đợi icon mạng xuất hiện.
2. Rút dây. Mac và iPhone **cùng Wi‑Fi**.
3. Kiểm tra Flutter thấy máy:

   ```bash
   flutter devices
   ```

   Ví dụ: `HuuNghia (wireless) • ios • ...`

4. Cài / cập nhật app không dây:

   ```bash
   cd "/Users/nguyenhuunghia/N/Personal Blog/mobile-blog"
   flutter run -d HuuNghia
   ```

   (thay `HuuNghia` bằng tên device trong `flutter devices`)

App **giữ nguyên trên iPhone** sau khi cài — mở icon như app thường, không cần cắm dây.

### B. Mỗi lần dùng với backend trên Mac (không cần dây)

| Việc cần làm | Ghi chú |
|--------------|---------|
| Mac + iPhone **cùng Wi‑Fi** | Không dùng 4G riêng cho iPhone nếu Mac chỉ có Wi‑Fi office/home |
| Chạy **be-blog** trên Mac | Port `8080` |
| IP Mac đúng trong app | `lib/core/constants/api_constants.dart` → `devLanHost` |
| Mở app trên iPhone | Không cần `flutter run` mỗi ngày nếu không sửa code |

Lấy IP Mac:

```bash
ipconfig getifaddr en0
```

Nếu router đổi IP Mac (ví dụ hôm nay `192.168.1.3`, mai `192.168.1.8`) → sửa `devLanHost` và **build lại** app (có thể qua Wi‑Fi).

Gợi ý: đặt **IP tĩnh cho Mac** trong router để không phải sửa IP thường xuyên.

### C. Chỉ cần cắm dây lại khi nào?

- Cài bản app **mới** sau khi sửa code (hoặc dùng `flutter run` qua Wi‑Fi nếu đã bật Connect via network).
- Certificate **Personal Team** hết hạn (~7 ngày) — app không mở được → build lại từ Mac.
- Mất pairing wireless trong Xcode → bật lại **Connect via network** (có thể cần cắm 1 lần).

### D. Backend khi Mac tắt / không cùng mạng

App trên iPhone đang trỏ `http://<IP-Mac>:8080`. Mac **tắt** hoặc **không cùng Wi‑Fi** → login / ảnh sẽ lỗi (bình thường).

Muốn dùng **không cần Mac bật**: deploy be-blog lên server (VPS, cloud) rồi build app với:

```bash
flutter build ios --dart-define=API_BASE_URL=https://api.cua-ban.com
```

(rồi cài bản release — khác với dev hàng ngày trên LAN)

## Nếu vẫn lỗi

- Chạy thử **Simulator** (không cần provisioning): `flutter run` chọn simulator.
- Kiểm tra [developer.apple.com](https://developer.apple.com) — account còn active.
- Trong Xcode: **Product** → **Clean Build Folder**, rồi build lại.
- Mac Firewall: cho phép Java/Spring nhận kết nối cổng **8080**.
