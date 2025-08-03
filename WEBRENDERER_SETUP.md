# Flutter + WebRenderer Integration Guide

## 🎯 Tổng Quan

Dự án sách điện tử Flutter đã được tích hợp **WebRenderer** để hỗ trợ 3D rendering trên web platform sử dụng **Three.js** và **Babylon.js**. Điều này cho phép tạo ra những trải nghiệm 3D mạnh mẽ và tương tác trong ứng dụng Flutter web.

## 🚀 Tính Năng Chính

### ✅ Đã Hoàn Thành
- [x] **Three.js Integration** - Render 3D models với Three.js
- [x] **Babylon.js Integration** - Render 3D models với Babylon.js
- [x] **GLB/GLTF Support** - Load và hiển thị 3D models
- [x] **Animation Support** - Play, pause và control animations
- [x] **Camera Controls** - Zoom, pan, rotate với mouse/touch
- [x] **Advanced Lighting** - Ambient, directional và point lights
- [x] **Shadow Mapping** - Real-time shadows với PCF filtering
- [x] **Renderer Switching** - Chuyển đổi giữa Three.js và Babylon.js
- [x] **Responsive Design** - Hoạt động trên mọi kích thước màn hình
- [x] **Error Handling** - Xử lý lỗi và fallback gracefully

### 🔄 Có Thể Cải Thiện
- [ ] **Particle Systems** - Thêm particle effects
- [ ] **Post-processing** - Bloom, SSAO, motion blur
- [ ] **VR/AR Support** - WebXR integration
- [ ] **Physics Engine** - Real-time physics simulation
- [ ] **Multiplayer** - Real-time collaboration

## 📁 Cấu Trúc Files

```
lib/
├── services/
│   └── web_renderer_service.dart      # Service quản lý WebRenderer
├── widgets/
│   └── web_renderer_widget.dart       # Flutter widgets cho WebRenderer
├── pages/
│   └── web_renderer_demo_page.dart    # Demo page
└── web/
    ├── index.html                     # Web configuration
    └── js/
        ├── three-renderer.js          # Three.js service
        └── babylon-renderer.js        # Babylon.js service
```

## 🛠 Cài Đặt

### 1. Dependencies

Đã thêm vào `pubspec.yaml`:
```yaml
dependencies:
  # WebRenderer Integration
  js: ^0.6.7
  universal_html: ^2.2.4
```

### 2. Web Configuration

Đã cập nhật `web/index.html` với các libraries cần thiết:
```html
<!-- Three.js Library -->
<script src="https://cdnjs.cloudflare.com/ajax/libs/three.js/r158/three.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/three@0.158.0/examples/js/controls/OrbitControls.js"></script>
<script src="https://cdn.jsdelivr.net/npm/three@0.158.0/examples/js/loaders/GLTFLoader.js"></script>

<!-- Babylon.js Library -->
<script src="https://cdn.babylonjs.com/babylon.js"></script>
<script src="https://cdn.babylonjs.com/loaders/babylonjs.loaders.min.js"></script>
```

## 🎨 Cách Sử Dụng

### 1. Basic Usage

```dart
import 'package:your_app/widgets/web_renderer_widget.dart';

// Three.js Widget
ThreeJsWidget(
  modelPath: 'assets/models/avatar.glb',
  modelId: 'avatar',
  width: 400,
  height: 400,
  autoRotate: true,
  enableControls: true,
  onTap: () => print('Clicked!'),
)

// Babylon.js Widget
BabylonJsWidget(
  modelPath: 'assets/models/avatar.glb',
  modelId: 'avatar',
  width: 400,
  height: 400,
  autoRotate: true,
  enableControls: true,
  onTap: () => print('Clicked!'),
)
```

### 2. Advanced Usage

```dart
WebRendererWidget(
  rendererType: WebRendererType.threejs, // or WebRendererType.babylon
  modelPath: 'assets/models/avatar.glb',
  modelId: 'avatar',
  modelOptions: {
    'scale': 1.5,
    'position': {'x': 0, 'y': 0, 'z': 0},
    'rotation': {'x': 0, 'y': 0, 'z': 0},
    'enableShadows': true,
    'autoRotate': true,
  },
  rendererOptions: {
    'backgroundColor': 0x0a0e27,
    'enableZoom': true,
    'enableRotate': true,
    'enablePan': true,
    'lighting': {
      'ambientIntensity': 0.4,
      'directionalIntensity': 0.8,
      'pointIntensity': 0.5,
    },
  },
  width: 500,
  height: 500,
  onTap: () => print('Renderer clicked!'),
)
```

### 3. Service Usage

```dart
import 'package:your_app/services/web_renderer_service.dart';

final rendererService = WebRendererService();

// Initialize
await rendererService.initialize(
  containerId: 'my-container',
  rendererType: WebRendererType.threejs,
  options: {'backgroundColor': 0x0a0e27},
);

// Load model
await rendererService.loadModel(
  modelId: 'avatar',
  modelPath: 'assets/models/avatar.glb',
  options: {'scale': 1.0},
);

// Play animation
await rendererService.playAnimation(
  modelId: 'avatar',
  animationIndex: 0,
  loop: true,
);

// Update position
await rendererService.updateModelPosition(
  modelId: 'avatar',
  position: {'x': 1, 'y': 0, 'z': 0},
);

// Switch renderer
await rendererService.switchRenderer(WebRendererType.babylon);
```

## 🎯 Demo Page

Truy cập **WebRenderer Demo** từ navigation menu để xem:
- Chuyển đổi giữa Three.js và Babylon.js
- Load 3D models với animations
- Camera controls và lighting
- Code examples và documentation

## 🔧 Configuration

### Model Options
```dart
{
  'scale': 1.0,                    // Model scale
  'position': {'x': 0, 'y': 0, 'z': 0},  // Model position
  'rotation': {'x': 0, 'y': 0, 'z': 0},  // Model rotation
  'enableShadows': true,           // Enable shadows
  'autoRotate': true,              // Auto rotation
}
```

### Renderer Options
```dart
{
  'backgroundColor': 0x0a0e27,     // Background color
  'enableZoom': true,              // Enable zoom controls
  'enableRotate': true,            // Enable rotate controls
  'enablePan': true,               // Enable pan controls
  'alpha': false,                  // Transparent background
  'lighting': {                    // Lighting configuration
    'ambientIntensity': 0.4,
    'directionalIntensity': 0.8,
    'pointIntensity': 0.5,
  },
}
```

## 🎨 Customization

### 1. Custom Loading Widget
```dart
ThreeJsWidget(
  loadingWidget: Column(
    children: [
      CircularProgressIndicator(),
      Text('Loading 3D Model...'),
    ],
  ),
)
```

### 2. Custom Error Widget
```dart
ThreeJsWidget(
  errorWidget: Column(
    children: [
      Icon(Icons.error),
      Text('Failed to load model'),
      ElevatedButton(
        onPressed: () => retry(),
        child: Text('Retry'),
      ),
    ],
  ),
)
```

### 3. Custom Styling
```dart
Container(
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.3),
        blurRadius: 20,
        offset: Offset(0, 10),
      ),
    ],
  ),
  child: ThreeJsWidget(...),
)
```

## 🚀 Performance Tips

### 1. Model Optimization
- Giảm polygon count
- Compress textures
- Remove unused materials
- Use LOD (Level of Detail)

### 2. Rendering Optimization
- Tắt shadows nếu không cần
- Giảm lighting complexity
- Sử dụng frustum culling
- Implement object pooling

### 3. Memory Management
- Dispose renderers khi không dùng
- Unload models khi chuyển trang
- Monitor memory usage
- Implement lazy loading

## 🔍 Troubleshooting

### 1. Model không hiển thị
```bash
# Kiểm tra console browser
# Đảm bảo file GLB hợp lệ
# Kiểm tra CORS policy
```

### 2. Performance issues
```bash
# Giảm model complexity
# Tắt auto-rotate
# Kiểm tra memory usage
# Optimize lighting setup
```

### 3. Controls không hoạt động
```bash
# Kiểm tra enableControls parameter
# Đảm bảo container có focus
# Kiểm tra event listeners
```

## 📚 Resources

### Documentation
- [Three.js Documentation](https://threejs.org/docs/)
- [Babylon.js Documentation](https://doc.babylonjs.com/)
- [Flutter Web Documentation](https://flutter.dev/web)

### Examples
- [Three.js Examples](https://threejs.org/examples/)
- [Babylon.js Examples](https://www.babylonjs.com/demos/)

### Tools
- [Blender](https://www.blender.org/) - 3D modeling
- [glTF Viewer](https://gltf-viewer.donmccurdy.com/) - Model validation
- [Draco Compression](https://google.github.io/draco/) - Model compression

## 🔮 Roadmap

### Phase 1: Core Features ✅
- [x] Three.js integration
- [x] Babylon.js integration
- [x] Basic model loading
- [x] Camera controls

### Phase 2: Advanced Features 🚧
- [ ] Particle systems
- [ ] Post-processing effects
- [ ] Physics simulation
- [ ] Audio integration

### Phase 3: Extended Features 📋
- [ ] VR/AR support
- [ ] Multiplayer capabilities
- [ ] AI integration
- [ ] Cloud rendering

## 🤝 Contributing

1. Fork the repository
2. Create feature branch
3. Implement changes
4. Add tests
5. Submit pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 📞 Support

Nếu gặp vấn đề:
1. Kiểm tra documentation
2. Xem troubleshooting guide
3. Tạo issue trên GitHub
4. Liên hệ team phát triển

---

**Happy 3D Rendering! 🎨✨** 

## 🎯 **Về Model Avatar với Three.js**

Khi chuyển từ Unity sang Three.js, bạn có nhiều nguồn model avatar:

### 1. **Ready Player Me (RPM)** - Đã có sẵn
```dart
<code_block_to_apply_changes_from>
```

### 2. **Tạo Model Mới từ Ready Player Me**

``` 