# Assets

Thư mục này chứa các **Assets** của ứng dụng - hình ảnh, icons, fonts, và các file tĩnh khác.

## Cấu trúc

```
assets/
├── images/          # Hình ảnh (logo, backgrounds, placeholders)
│   ├── logo.png     # Logo của app
│   ├── logo_dark.png
│   └── placeholder.png
├── icons/           # Icons tùy chỉnh (nếu có)
│   └── custom_icon.png
└── fonts/           # Custom fonts (nếu có)
    └── (font files)
```

## Mục đích từng thư mục

### 📁 `images/`
**Mục đích**: Chứa các hình ảnh của ứng dụng

- **Logo**: Logo của app (logo.png, logo_dark.png cho dark mode)
- **Backgrounds**: Hình nền cho các màn hình
- **Placeholders**: Hình ảnh placeholder (avatar mặc định, image placeholder)
- **Onboarding**: Hình ảnh cho màn hình onboarding
- **Splash**: Hình ảnh splash screen

**Ví dụ sử dụng**:
```dart
// Hiển thị logo
Image.asset('assets/images/logo.png')

// Hoặc với width/height
Image.asset(
  'assets/images/logo.png',
  width: 100,
  height: 100,
)
```

### 📁 `icons/`
**Mục đích**: Chứa các icons tùy chỉnh

- Icons không có trong Material Icons hoặc Cupertino Icons
- Custom icons cho app
- App icon (nếu cần)

**Lưu ý**: Thông thường Flutter sử dụng Material Icons hoặc Cupertino Icons, chỉ thêm custom icons khi cần thiết.

### 📁 `fonts/`
**Mục đích**: Chứa custom fonts (nếu có)

- Font files (.ttf, .otf)
- Cần khai báo trong `pubspec.yaml` trong section `fonts`

**Ví dụ khai báo trong pubspec.yaml**:
```yaml
fonts:
  - family: CustomFont
    fonts:
      - asset: assets/fonts/CustomFont-Regular.ttf
      - asset: assets/fonts/CustomFont-Bold.ttf
        weight: 700
```

## Best Practices

### 1. Đặt tên file
- Sử dụng snake_case: `logo.png`, `app_icon.png`
- Mô tả rõ ràng: `login_background.png` thay vì `bg1.png`
- Phân biệt dark mode: `logo_light.png`, `logo_dark.png`

### 2. Kích thước và format
- **PNG**: Cho logo, icons (hỗ trợ transparency)
- **JPEG**: Cho ảnh nền, ảnh lớn (kích thước nhỏ hơn)
- **SVG**: Không được hỗ trợ trực tiếp, cần convert sang PNG hoặc sử dụng package `flutter_svg`

### 3. Resolution variants
Flutter hỗ trợ resolution-aware images:
```
assets/images/
├── logo.png          # 1x (base)
├── 2.0x/
│   └── logo.png      # 2x (retina)
└── 3.0x/
    └── logo.png      # 3x (super retina)
```

Hoặc đặt tên theo convention:
```
assets/images/
├── logo.png          # 1x
├── logo@2x.png       # 2x
└── logo@3x.png       # 3x
```

### 4. Tối ưu hóa
- Nén ảnh trước khi thêm vào project
- Sử dụng WebP format nếu có thể (cần package hỗ trợ)
- Không thêm ảnh quá lớn (nên < 1MB mỗi file)

## Sử dụng trong code

### Image.asset
```dart
Image.asset('assets/images/logo.png')
```

### Với error handling
```dart
Image.asset(
  'assets/images/logo.png',
  errorBuilder: (context, error, stackTrace) {
    return Icon(Icons.error);
  },
)
```

### Với width/height
```dart
Image.asset(
  'assets/images/logo.png',
  width: 100,
  height: 100,
  fit: BoxFit.contain,
)
```

### Trong AppBar
```dart
AppBar(
  title: Image.asset(
    'assets/images/logo.png',
    height: 40,
  ),
)
```

## Khai báo trong pubspec.yaml

Đã được khai báo trong `pubspec.yaml`:
```yaml
flutter:
  assets:
    - assets/images/
    - assets/icons/
```

**Lưu ý**: Sau khi thêm assets mới, chạy:
```bash
flutter pub get
```

Hoặc nếu vẫn không thấy, thử:
```bash
flutter clean
flutter pub get
```

## Ví dụ cấu trúc cho app mạng xã hội

```
assets/
├── images/
│   ├── logo.png              # Logo chính
│   ├── logo_dark.png         # Logo cho dark mode
│   ├── splash_logo.png       # Logo cho splash screen
│   ├── placeholder_avatar.png  # Avatar mặc định
│   ├── placeholder_image.png   # Placeholder cho ảnh post
│   ├── onboarding_1.png     # Onboarding images
│   ├── onboarding_2.png
│   └── onboarding_3.png
├── icons/
│   └── (custom icons nếu có)
└── fonts/
    └── (custom fonts nếu có)
```
