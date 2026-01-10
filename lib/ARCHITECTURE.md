# Cấu trúc thư mục Twizzy App - MVVM Architecture

## Tổng quan
Dự án Twizzy sử dụng kiến trúc **MVVM (Model-View-ViewModel)** với **Provider** để quản lý trạng thái.

## Cấu trúc thư mục

```
twizzy_app/
├── assets/                        # Assets - Hình ảnh, Icons, Fonts
│   ├── images/                    # Hình ảnh (logo, backgrounds, placeholders)
│   │   └── logo.png              # Logo của app
│   ├── icons/                     # Custom icons
│   └── fonts/                     # Custom fonts
│
├── lib/
├── main.dart                    # Entry point của ứng dụng
├── models/                      # Data Models - Định nghĩa cấu trúc dữ liệu
│   ├── auth/                    # Models liên quan đến authentication
│   │   └── (auth_models.dart)   # LoginRequest, RegisterRequest, TokenResponse, etc.
│   ├── user/                    # Models liên quan đến user
│   │   └── (user_models.dart)   # User, UserProfile, etc.
│   ├── post/                    # Models liên quan đến bài viết
│   │   └── (post_models.dart)   # Post, CreatePostRequest, etc.
│   ├── comment/                 # Models liên quan đến comment
│   │   └── (comment_models.dart) # Comment, CreateCommentRequest, etc.
│   └── notification/            # Models liên quan đến thông báo
│       └── (notification_models.dart) # Notification, etc.
│
├── views/                       # Views - Giao diện người dùng (UI)
│   ├── auth/                    # Màn hình authentication
│   │   ├── login_screen.dart    # Màn hình đăng nhập
│   │   ├── register_screen.dart # Màn hình đăng ký
│   │   └── forgot_password_screen.dart
│   ├── home/                    # Màn hình chính
│   │   ├── home_screen.dart     # Màn hình home (feed)
│   │   └── main_navigation_screen.dart # Bottom navigation
│   ├── profile/                 # Màn hình profile
│   │   ├── profile_screen.dart  # Profile của user
│   │   └── edit_profile_screen.dart
│   ├── post/                    # Màn hình liên quan đến post
│   │   ├── create_post_screen.dart
│   │   └── post_detail_screen.dart
│   ├── search/                  # Màn hình tìm kiếm
│   │   └── search_screen.dart
│   └── notifications/           # Màn hình thông báo
│       └── notifications_screen.dart
│
├── viewmodels/                  # ViewModels - Business Logic (sử dụng Provider)
│   ├── auth/                    # ViewModels cho authentication
│   │   ├── auth_viewmodel.dart  # Quản lý trạng thái login, register, logout
│   │   └── auth_provider.dart   # Provider cho authentication
│   ├── user/                    # ViewModels cho user
│   │   ├── user_viewmodel.dart  # Quản lý thông tin user, profile
│   │   └── user_provider.dart
│   ├── post/                    # ViewModels cho post
│   │   ├── post_viewmodel.dart  # Quản lý CRUD post, like, comment
│   │   └── post_provider.dart
│   └── home/                    # ViewModels cho home
│       ├── home_viewmodel.dart  # Quản lý feed, load posts
│       └── home_provider.dart
│
├── services/                    # Services - Xử lý logic nghiệp vụ và API
│   ├── api/                     # API services
│   │   ├── api_client.dart      # HTTP client (Dio/Http)
│   │   ├── api_endpoints.dart   # Định nghĩa các endpoints
│   │   └── api_interceptor.dart # Interceptor cho request/response
│   ├── auth_service.dart        # Service xử lý authentication
│   │   └── (login, register, logout, refreshToken)
│   └── local_storage/           # Local storage services
│       ├── storage_service.dart # FlutterSecureStorage wrapper
│       └── token_storage.dart   # Lưu trữ tokens
│
├── widgets/                     # Reusable Widgets - Widgets tái sử dụng
│   ├── common/                  # Widgets dùng chung
│   │   ├── custom_button.dart
│   │   ├── custom_textfield.dart
│   │   ├── loading_indicator.dart
│   │   └── error_widget.dart
│   ├── auth/                    # Widgets cho authentication
│   │   └── (auth specific widgets)
│   └── post/                    # Widgets cho post
│       ├── post_card.dart       # Card hiển thị post
│       └── comment_widget.dart
│
├── routes/                      # Navigation & Routing
│   ├── app_router.dart          # Định nghĩa routes
│   └── route_names.dart         # Tên các routes (constants)
│
└── core/                        # Core - Các thành phần cốt lõi
    ├── constants/               # Constants
    │   ├── api_constants.dart   # API URLs, endpoints
    │   ├── app_constants.dart   # App-wide constants
    │   ├── storage_keys.dart    # Keys cho FlutterSecureStorage
    │   └── asset_paths.dart     # Paths cho assets (images, icons)
    ├── theme/                   # Theme & Styling
    │   ├── app_theme.dart       # Theme configuration
    │   ├── app_colors.dart     # Color palette
    │   └── text_styles.dart     # Text styles
    ├── utils/                   # Utilities
    │   ├── validators.dart      # Form validators
    │   ├── formatters.dart     # Data formatters
    │   └── helpers.dart         # Helper functions
    └── config/                  # Configuration
        └── app_config.dart      # App configuration
```

## Giải thích chi tiết từng thư mục

### 📁 `assets/` (Root level)
**Mục đích**: Chứa các assets tĩnh của ứng dụng (hình ảnh, icons, fonts)

- **`images/`**: Hình ảnh của app (logo, backgrounds, placeholders)
- **`icons/`**: Custom icons (nếu có)
- **`fonts/`**: Custom fonts (nếu có)

**Lưu ý**: 
- Assets được khai báo trong `pubspec.yaml` trong section `flutter: assets:`
- Sử dụng `Image.asset('assets/images/logo.png')` để hiển thị
- Xem chi tiết trong `assets/README.md`

---

### 📁 `models/`
**Mục đích**: Định nghĩa cấu trúc dữ liệu (Data Models)

- Chứa các class định nghĩa cấu trúc dữ liệu từ API và local
- Mỗi model thường có `fromJson()` và `toJson()` để convert với API
- Tổ chức theo feature/module (auth, user, post, etc.)

**Ví dụ**: `models/auth/auth_models.dart` chứa `LoginRequest`, `RegisterRequest`, `TokenResponse`

---

### 📁 `views/`
**Mục đích**: Giao diện người dùng (UI Screens)

- Chứa các màn hình (Screens) của ứng dụng
- Chỉ xử lý UI, không chứa business logic
- Sử dụng ViewModels thông qua Provider để lấy dữ liệu và xử lý events
- Tổ chức theo feature/module

**Ví dụ**: `views/auth/login_screen.dart` - Màn hình đăng nhập

---

### 📁 `viewmodels/`
**Mục đích**: Business Logic Layer (sử dụng Provider)

- Chứa logic nghiệp vụ, quản lý trạng thái
- Kế thừa `ChangeNotifier` để notify UI khi state thay đổi
- Gọi Services để lấy dữ liệu từ API
- Cập nhật Models và notify listeners (UI)

**Ví dụ**: 
- `viewmodels/auth/auth_viewmodel.dart` - Xử lý login, register, logout
- `viewmodels/auth/auth_provider.dart` - Provider wrapper

---

### 📁 `services/`
**Mục đích**: Xử lý API calls và business logic phức tạp

- **`api/`**: HTTP client, endpoints, interceptors
- **`auth_service.dart`**: Service xử lý authentication (login, register, refresh token)
- **`local_storage/`**: Lưu trữ dữ liệu local (tokens, user info) sử dụng FlutterSecureStorage

**Ví dụ**: `services/auth_service.dart` có method `login(email, password)` trả về `TokenResponse`

---

### 📁 `widgets/`
**Mục đích**: Reusable UI Components

- Chứa các widgets có thể tái sử dụng
- **`common/`**: Widgets dùng chung (buttons, textfields, loaders)
- **`auth/`**: Widgets riêng cho authentication
- **`post/`**: Widgets riêng cho post (post card, comment widget)

**Ví dụ**: `widgets/common/custom_button.dart` - Button component tái sử dụng

---

### 📁 `routes/`
**Mục đích**: Navigation & Routing

- Định nghĩa các routes của ứng dụng
- Quản lý navigation giữa các màn hình
- Có thể sử dụng `go_router` hoặc `flutter_navigation`

**Ví dụ**: `routes/app_router.dart` định nghĩa route `/login`, `/home`, etc.

---

### 📁 `core/`
**Mục đích**: Core components và utilities

- **`constants/`**: 
  - `api_constants.dart`: Base URL, API endpoints
  - `app_constants.dart`: App-wide constants
  - `storage_keys.dart`: Keys cho FlutterSecureStorage
  - `asset_paths.dart`: Paths cho assets (images, icons, fonts)
  
- **`theme/`**: 
  - `app_theme.dart`: Theme configuration
  - `app_colors.dart`: Color palette
  - `text_styles.dart`: Text styles
  
- **`utils/`**: 
  - `validators.dart`: Form validation (email, password, etc.)
  - `formatters.dart`: Format data (date, currency, etc.)
  - `helpers.dart`: Helper functions
  
- **`config/`**: 
  - `app_config.dart`: App configuration (environment, API URLs)

---

## Luồng hoạt động (Flow)

### 1. User tương tác với UI (View)
```
User nhấn nút Login
    ↓
views/auth/login_screen.dart
```

### 2. View gọi ViewModel thông qua Provider
```
login_screen.dart
    ↓
Provider.of<AuthViewModel>(context).login(email, password)
```

### 3. ViewModel gọi Service
```
viewmodels/auth/auth_viewmodel.dart
    ↓
services/auth_service.dart.login(email, password)
```

### 4. Service gọi API
```
auth_service.dart
    ↓
api/api_client.dart (HTTP request)
    ↓
Backend API
```

### 5. Response quay ngược lại
```
Backend Response
    ↓
Service parse response → Model
    ↓
ViewModel cập nhật state → notifyListeners()
    ↓
View rebuild với data mới
```

---

## Best Practices

1. **Separation of Concerns**: Mỗi layer chỉ làm việc của mình
   - View: Chỉ UI
   - ViewModel: Business logic
   - Service: API calls
   - Model: Data structure

2. **Provider Usage**: 
   - Mỗi feature có Provider riêng
   - Sử dụng `ChangeNotifierProvider` hoặc `Provider` trong main.dart

3. **Error Handling**: 
   - Xử lý lỗi trong ViewModel
   - Hiển thị lỗi trong View

4. **Loading States**: 
   - Quản lý loading state trong ViewModel
   - Hiển thị loading indicator trong View

---

## Dựa trên Backend hiện tại

Backend hiện có các endpoints:
- `POST /users/login` - Đăng nhập
- `POST /users/register` - Đăng ký
- `POST /users/logout` - Đăng xuất
- `POST /users/refresh-token` - Refresh token

Cấu trúc này đã được thiết kế để dễ dàng mở rộng khi backend thêm các features mới (posts, comments, notifications, etc.)
