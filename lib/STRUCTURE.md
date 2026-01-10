# Cấu trúc thư mục Twizzy App

```
twizzy_app/
│
├── 📁 assets/                           # Assets (Root level)
│   ├── 📁 images/                        # Hình ảnh (logo, backgrounds)
│   ├── 📁 icons/                         # Custom icons
│   └── 📁 fonts/                         # Custom fonts
│
├── 📁 lib/
│   │
│   ├── 📄 main.dart                      # Entry point
│   │
├── 📁 models/                            # Data Models
│   ├── 📁 auth/                          # Authentication models
│   ├── 📁 user/                          # User models
│   ├── 📁 post/                          # Post models
│   ├── 📁 comment/                       # Comment models
│   └── 📁 notification/                  # Notification models
│
├── 📁 views/                             # UI Screens
│   ├── 📁 auth/                          # Login, Register screens
│   ├── 📁 home/                          # Home, Feed screens
│   ├── 📁 profile/                       # Profile screens
│   ├── 📁 post/                          # Post screens
│   ├── 📁 search/                        # Search screen
│   └── 📁 notifications/                 # Notifications screen
│
├── 📁 viewmodels/                        # Business Logic (Provider)
│   ├── 📁 auth/                          # Auth ViewModel & Provider
│   ├── 📁 user/                          # User ViewModel & Provider
│   ├── 📁 post/                          # Post ViewModel & Provider
│   └── 📁 home/                           # Home ViewModel & Provider
│
├── 📁 services/                          # Services Layer
│   ├── 📁 api/                           # API Client, Endpoints, Interceptors
│   ├── 📁 auth_service.dart              # Authentication service
│   └── 📁 local_storage/                 # Storage services
│
├── 📁 widgets/                           # Reusable Widgets
│   ├── 📁 common/                        # Common widgets (buttons, textfields)
│   ├── 📁 auth/                          # Auth-specific widgets
│   └── 📁 post/                          # Post-specific widgets
│
├── 📁 routes/                            # Navigation & Routing
│   ├── 📄 app_router.dart                # Route definitions
│   └── 📄 route_names.dart               # Route name constants
│
└── 📁 core/                              # Core Components
    ├── 📁 constants/                     # API, App constants, Storage keys
    ├── 📁 theme/                         # Theme, Colors, Text styles
    ├── 📁 utils/                         # Validators, Formatters, Helpers
    └── 📁 config/                        # App configuration
```

## Tóm tắt nhanh

| Thư mục | Mục đích | Ví dụ |
|---------|----------|-------|
| `assets/` | Hình ảnh, Icons, Fonts | `logo.png`, custom icons |
| `models/` | Định nghĩa cấu trúc dữ liệu | `LoginRequest`, `User`, `Post` |
| `views/` | Giao diện người dùng (Screens) | `LoginScreen`, `HomeScreen` |
| `viewmodels/` | Business logic & State management | `AuthViewModel`, `PostViewModel` |
| `services/` | API calls & Business logic | `AuthService`, `ApiClient` |
| `widgets/` | Reusable UI components | `CustomButton`, `PostCard` |
| `routes/` | Navigation & Routing | `AppRouter`, `RouteNames` |
| `core/` | Constants, Theme, Utils, Config | `ApiConstants`, `AppTheme` |

## Luồng dữ liệu

```
View (UI)
  ↓
ViewModel (Provider) - Business Logic
  ↓
Service - API Calls
  ↓
Model - Data Structure
```

## File README trong mỗi thư mục

Mỗi thư mục chính đều có file `README.md` giải thích chi tiết:
- `assets/README.md` - Hướng dẫn về assets (hình ảnh, icons, fonts)
- `lib/models/README.md`
- `lib/views/README.md`
- `lib/viewmodels/README.md`
- `lib/services/README.md`
- `lib/widgets/README.md`
- `lib/core/README.md`
- `lib/routes/README.md`

Xem file `ARCHITECTURE.md` ở root của `lib/` để biết chi tiết đầy đủ về kiến trúc MVVM.
