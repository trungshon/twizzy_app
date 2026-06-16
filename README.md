# Twizzy Mobile Client (Flutter App)

Đây là ứng dụng di động mạng xã hội Twizzy dành cho người dùng, được phát triển bằng framework **Flutter** (hỗ trợ cả Android và iOS).

---

## 🚀 Các chức năng chính của App
- **Đăng ký / Đăng nhập**: Hỗ trợ đăng ký tài khoản thường (xác thực qua OTP Email) và Đăng nhập nhanh bằng tài khoản Google.
- **Bảng tin (News Feed)**: Xem bài viết (Twizz), tìm kiếm, like, bookmark, bình luận và chia sẻ bài viết của người khác (Retwizz).
- **Trò chuyện trực tuyến (Realtime Chat)**: Gửi tin nhắn tức thời và kết nối qua Socket.io.
- **Bản đồ và Vị trí (Location)**: Tích hợp định vị (Geolocator) để lấy vị trí hiện tại khi tương tác hoặc đăng bài.
- **Thông báo đẩy (Firebase Push Notification)**: Nhận thông báo realtime khi có người tương tác, nhắn tin hoặc cập nhật trạng thái mới.

---

## 🛠️ Yêu cầu môi trường
- **Flutter SDK**: Phiên bản >= 3.22.x
- **Dart SDK**: Phiên bản ^3.7.2
- **Android Studio / VS Code**: Đã cài đặt Flutter extension và Dart extension.
- **JDK**: Phiên bản 17 (Cần thiết cho quá trình build Android).
- **Xcode** (Chỉ dành cho macOS nếu muốn build iOS).

---

## ⚙️ Hướng dẫn Cài đặt & Cấu hình

### Bước 1: Cài đặt Dependencies (Thư viện)
Mở terminal tại thư mục `twizzy_app` và chạy lệnh:
```bash
flutter pub get
```

### Bước 2: Cấu hình biến môi trường (`.env`)
1. Tạo file `.env` bằng cách copy từ file mẫu `.env.example`:
   ```bash
   cp .env.example .env
   ```
2. Mở file `.env` mới tạo và điều chỉnh các địa chỉ IP kết nối đến API Server (Backend):
   - **Chạy trên Emulator Android**: `BASE_URL_ANDROID=http://10.0.2.2:3000`
   - **Chạy trên iOS Simulator**: `BASE_URL_IOS=http://localhost:3000`
   - **Chạy trên thiết bị thật (Physical Device)**: Thay đổi `localhost` thành địa chỉ IP mạng LAN của máy tính chạy server của bạn (Ví dụ: `http://192.168.1.15:3000`).
   - Cập nhật `GOOGLE_WEB_CLIENT_ID` để sử dụng Google Sign-In (lấy từ Google Cloud Console).

---

## 📱 Quyền truy cập (Permissions) cần lưu ý
Để ứng dụng hoạt động không bị crash, hãy đảm bảo cấp các quyền sau trên thiết bị kiểm thử:
- **Location (Định vị)**: Cần thiết để lấy địa chỉ/tọa độ.
- **Camera & Photo Library (Máy ảnh & Thư viện ảnh)**: Cần thiết khi chọn ảnh/video đăng bài hoặc đổi avatar.
- **Notification (Thông báo)**: Cho phép hiển thị thông báo đẩy từ Firebase.

---

## 🚀 Khởi chạy ứng dụng

### Chạy thử nghiệm trên thiết bị/giả lập
Đảm bảo bạn đã khởi chạy một thiết bị Android Emulator hoặc iOS Simulator, sau đó chạy lệnh:
```bash
flutter run
```

### Build file cài đặt
Để đóng gói ứng dụng phục vụ việc cài đặt trực tiếp lên điện thoại hoặc nộp đồ án:

- **Build Android (APK)**:
  ```bash
  flutter build apk --release
  ```
  File APK kết quả sẽ nằm tại thư mục: `build/app/outputs/flutter-apk/app-release.apk`

- **Build iOS (Cần máy macOS)**:
  ```bash
  flutter build ipa --release
  ```
