# Hướng Dẫn Tích Hợp Avatar 3D Ready Player Me

## Tổng Quan

Dự án này đã được tích hợp model avatar 3D từ Ready Player Me để render trên cả Android và Web. Avatar được export từ Unity dưới dạng file GLB và được hiển thị bằng thư viện `model_viewer_plus`.

## Cấu Trúc Files

```
assets/
  models/
    avatar.glb          # Model 3D từ Ready Player Me
lib/
  widgets/
    avatar_3d_widget.dart      # Widget phức tạp với animations
    simple_avatar_widget.dart  # Widget đơn giản để test
  pages/
    avatar_demo_page.dart      # Trang demo avatar
```

## Dependencies

Đã thêm vào `pubspec.yaml`:
```yaml
dependencies:
  model_viewer_plus: ^1.7.0
```

## Cấu Hình Web

Đã cập nhật `web/index.html` để hỗ trợ model-viewer:
```html
<!-- Model Viewer for 3D GLB files -->
<script type="module" src="https://unpkg.com/@google/model-viewer@^3.4.0/dist/model-viewer.min.js"></script>
<script nomodule src="https://unpkg.com/@google/model-viewer@^3.4.0/dist/model-viewer-legacy.js"></script>
```

## Cách Sử Dụng

### 1. Widget Đơn Giản
```dart
import 'package:your_app/widgets/simple_avatar_widget.dart';

SimpleAvatarWidget(
  width: 300,
  height: 400,
  autoRotate: true,
  enableControls: true,
)
```

### 2. Widget Nâng Cao
```dart
import 'package:your_app/widgets/avatar_3d_widget.dart';

EnhancedAvatar3DWidget(
  width: 300,
  height: 400,
  autoRotate: true,
  enableControls: true,
  showParticles: true,
  backgroundColor: Colors.blue,
  onTap: () {
    // Xử lý khi nhấn avatar
  },
)
```

### 3. Trang Demo
Điều hướng đến trang demo từ trang chủ bằng nút "Xem Avatar 3D".

## Tính Năng

### ✅ Đã Hoàn Thành
- [x] Render model GLB trên Android
- [x] Render model GLB trên Web
- [x] Auto-rotate avatar
- [x] Camera controls (zoom, pan, rotate)
- [x] Loading indicator
- [x] Error handling
- [x] Responsive design
- [x] Animation effects
- [x] Interactive controls

### 🔄 Có Thể Cải Thiện
- [ ] Thêm animations cho avatar
- [ ] Tích hợp với AI assistant
- [ ] Thêm nhiều model khác nhau
- [ ] Custom shaders và materials
- [ ] AR support

## Troubleshooting

### Lỗi Thường Gặp

1. **Model không hiển thị trên Web**
   - Kiểm tra console browser để xem lỗi CORS
   - Đảm bảo file GLB được copy vào `assets/models/`
   - Kiểm tra `pubspec.yaml` đã include assets

2. **Model không hiển thị trên Android**
   - Kiểm tra file GLB có hợp lệ không
   - Đảm bảo đã chạy `flutter pub get`
   - Kiểm tra log để xem lỗi cụ thể

3. **Performance issues**
   - Giảm kích thước model
   - Tắt auto-rotate nếu không cần
   - Sử dụng widget đơn giản thay vì enhanced

### Debug Commands

```bash
# Clean và rebuild
flutter clean
flutter pub get
flutter run

# Build cho web
flutter build web

# Build cho Android
flutter build apk
```

## Tích Hợp Với Ready Player Me

### Từ Unity
1. Import model vào Unity
2. Setup scene với lighting phù hợp
3. Export thành GLB file
4. Copy vào `assets/models/`

### Từ Ready Player Me API
```dart
// Có thể load model từ URL
ModelViewer(
  src: 'https://models.readyplayer.me/avatar.glb',
  // ... other properties
)
```

## Performance Tips

1. **Optimize Model Size**
   - Giảm polygon count
   - Compress textures
   - Remove unused materials

2. **Lazy Loading**
   - Chỉ load avatar khi cần
   - Sử dụng placeholder trong khi loading

3. **Caching**
   - Cache model trên device
   - Preload cho smooth experience

## Tương Lai

- [ ] Tích hợp với AI assistant để tạo avatar động
- [ ] Thêm facial expressions
- [ ] Voice sync với avatar
- [ ] Multiplayer avatar support
- [ ] Custom avatar creation

## Liên Hệ

Nếu có vấn đề hoặc cần hỗ trợ, vui lòng tạo issue hoặc liên hệ team phát triển. 