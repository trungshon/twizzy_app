# Hướng dẫn Setup Google Sign-In cho Android

## Tổng quan

Code đã được implement xong. Bạn cần thực hiện các bước cấu hình sau để Google Sign-In hoạt động.

## Bước 1: Lấy SHA-1 Fingerprint

Chạy lệnh sau trong terminal (thay đổi đường dẫn nếu cần):

### Windows:
```bash
keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

### macOS/Linux:
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

Copy giá trị **SHA1** (ví dụ: `DA:39:A3:EE:5E:6B:4B:0D:32:55:BF:EF:95:60:18:90:AF:D8:07:09`)

## Bước 2: Tạo Android OAuth Client ID trong Google Cloud Console

1. Truy cập [Google Cloud Console](https://console.cloud.google.com/apis/credentials)
2. Chọn project **twizzy-484113** (hoặc project của bạn)
3. Click **Create Credentials** > **OAuth client ID**
4. Chọn **Application type**: **Android**
5. Điền thông tin:
   - **Name**: `Twizzy Android`
   - **Package name**: `com.example.twizzy_app` (xem trong `android/app/build.gradle.kts`)
   - **SHA-1 certificate fingerprint**: Paste SHA-1 từ Bước 1
6. Click **Create**

**Lưu ý**: Không cần download file JSON, chỉ cần tạo OAuth Client ID cho Android.

## Bước 3: Tạo Web OAuth Client ID (nếu chưa có)

Client ID bạn đã có (`591303968844-...`) là loại "installed". Bạn cần tạo thêm **Web** OAuth Client:

1. Trong Google Cloud Console, click **Create Credentials** > **OAuth client ID**
2. Chọn **Application type**: **Web application**
3. Điền thông tin:
   - **Name**: `Twizzy Web`
   - **Authorized redirect URIs**: `http://localhost:3000/users/oauth/google` (hoặc domain của backend)
4. Click **Create**
5. Copy **Client ID** và **Client Secret**

## Bước 4: Cập nhật Backend .env

Tạo file `.env` trong thư mục `Twizzy-BE/` với nội dung:

```env
# MongoDB
DB_HOST=mongodb://localhost:27017/twizzy

# JWT
JWT_SECRET_ACCESS_TOKEN=your-access-token-secret
JWT_SECRET_REFRESH_TOKEN=your-refresh-token-secret
JWT_SECRET_EMAIL_VERIFY_TOKEN=your-email-verify-token-secret
JWT_SECRET_FORGOT_PASSWORD_TOKEN=your-forgot-password-token-secret
ACCESS_TOKEN_EXPIRES_IN=900
REFRESH_TOKEN_EXPIRES_IN=604800
EMAIL_VERIFY_TOKEN_EXPRIRES_IN=604800
FORGOT_PASSWORD_TOKEN_EXPRIRES_IN=604800

# Google OAuth
GOOGLE_CLIENT_ID=your-web-client-id.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=your-web-client-secret
GOOGLE_REDIRECT_URI=http://localhost:3000/users/oauth/google

# Client Redirect (for web OAuth flow)
CLIENT_REDIRECT_CALLBACK=http://localhost:3000/oauth-callback
```

**Quan trọng**: 
- `GOOGLE_CLIENT_ID` và `GOOGLE_CLIENT_SECRET` là từ **Web OAuth Client** (Bước 3)
- Nếu bạn chỉ dùng mobile, có thể bỏ qua `GOOGLE_CLIENT_SECRET`

## Bước 5: Cập nhật main.dart (nếu cần)

File `lib/main.dart` đã được cấu hình với Web Client ID. Nếu bạn tạo Web Client ID mới ở Bước 3, hãy cập nhật:

```dart
// Google OAuth Client IDs
const String googleWebClientId =
    'YOUR-WEB-CLIENT-ID.apps.googleusercontent.com';
```

## Bước 6: Test

1. Restart backend:
```bash
cd Twizzy-BE
npm run dev
```

2. Run Flutter app:
```bash
cd twizzy_app
flutter run
```

3. Nhấn nút "Đăng ký bằng Google" hoặc "Đăng nhập bằng Google"

## Troubleshooting

### Lỗi "sign_in_failed" hoặc "10"
- Kiểm tra SHA-1 fingerprint đã đúng chưa
- Kiểm tra package name trong Google Cloud Console khớp với `android/app/build.gradle.kts`

### Lỗi "DEVELOPER_ERROR"
- Thiếu Android OAuth Client ID trong Google Cloud Console
- SHA-1 fingerprint không đúng

### Không nhận được idToken
- Chưa cấu hình `serverClientId` (Web Client ID) trong Flutter
- Web OAuth Client ID chưa được tạo trong Google Cloud Console

### Lỗi backend "Google ID token không hợp lệ"
- ID token hết hạn (thường sau 1 giờ)
- Web Client ID không khớp giữa Flutter và Google Cloud Console

## Cấu trúc files đã tạo/sửa

### Backend (Twizzy-BE):
- `src/routes/users.routes.ts` - Thêm route `/users/oauth/google/mobile`
- `src/controllers/users.controllers.ts` - Thêm `oauthMobileController`
- `src/services/users.services.ts` - Thêm `oauthMobile()` và `verifyGoogleIdToken()`
- `src/middlewares/users.middlewares.ts` - Thêm `googleOAuthMobileValidator`
- `src/constants/messages.ts` - Thêm messages cho Google OAuth
- `src/models/requests/User.requests.ts` - Thêm `GoogleOAuthMobileReqBody`

### Flutter (twizzy_app):
- `lib/services/google_auth/google_auth_service.dart` - Google Sign-In service
- `lib/models/auth/auth_models.dart` - Thêm Google OAuth models
- `lib/services/auth_service/auth_service.dart` - Thêm `googleOAuthMobile()`
- `lib/viewmodels/auth/auth_viewmodel.dart` - Thêm `googleSignIn()` method
- `lib/core/constants/api_constants.dart` - Thêm endpoint
- `lib/views/auth/register_screen.dart` - Cập nhật UI
- `lib/views/auth/login_screen.dart` - Cập nhật UI
- `lib/main.dart` - Initialize GoogleAuthService
- `pubspec.yaml` - Thêm google_sign_in package

## API Endpoint mới

```
POST /users/oauth/google/mobile
Body: { "id_token": "google-id-token-from-mobile" }
Response: {
  "message": "Đăng nhập bằng Google thành công",
  "result": {
    "access_token": "...",
    "refresh_token": "...",
    "newUser": 0 | 1,
    "verify": 0 | 1 | 2
  }
}
```
