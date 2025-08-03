# Hướng Dẫn Tích Hợp AI Assistant với Convai

## Tổng Quan

Dự án sách điện tử Flutter đã được tích hợp AI Assistant 3D sử dụng Convai Web SDK để tạo trợ giảng ảo thông minh cho việc học hóa học.

## Tính Năng

- 🤖 AI Assistant 3D với giao diện đẹp mắt
- 💬 Chat text với AI
- 🎤 Hỗ trợ giọng nói (voice chat)
- 🎨 Giao diện responsive cho mobile và desktop
- 📱 Tích hợp vào navigation chính của app
- 🔄 Real-time conversation với AI

## Cài Đặt

### 1. Cài Đặt Dependencies

Chạy lệnh sau để cài đặt các dependencies cần thiết:

```bash
flutter pub get
```

### 2. Cấu Hình Convai

#### Bước 1: Đăng ký tài khoản Convai
1. Truy cập [Convai Console](https://console.convai.com/)
2. Đăng ký tài khoản mới
3. Tạo project mới

#### Bước 2: Tạo Character
1. Trong Convai Console, tạo một character mới
2. Cấu hình character với thông tin:
   - **Name**: Trợ Giảng Ảo
   - **Description**: AI Assistant chuyên về hóa học
   - **Personality**: Thân thiện, kiên nhẫn, có kiến thức sâu rộng về hóa học
   - **Knowledge Base**: Upload tài liệu hóa học hoặc cấu hình knowledge base

#### Bước 3: Lấy API Key và Character ID
1. Trong project settings, copy **API Key**
2. Trong character settings, copy **Character ID**

#### Bước 4: Cập nhật Configuration
Mở file `lib/services/convai_service.dart` và cập nhật:

```dart
// Convai configuration
static const String _convaiApiKey = 'YOUR_CONVAI_API_KEY'; // Thay bằng API Key thật
static const String _characterId = 'YOUR_CHARACTER_ID'; // Thay bằng Character ID thật
```

### 3. Test Convai Web SDK

Trước khi tích hợp vào Flutter, bạn có thể test Convai Web SDK bằng file HTML:

1. Mở file `web/convai_test.html`
2. Cập nhật API Key và Character ID trong file
3. Mở file trong trình duyệt để test

## Sử Dụng

### 1. Truy Cập AI Assistant

1. Mở ứng dụng Flutter
2. Chọn tab "AI Assistant" trong navigation
3. Đợi AI Assistant khởi tạo và kết nối

### 2. Chat với AI

#### Text Chat
- Nhập tin nhắn vào ô input
- Nhấn Enter hoặc nút Send để gửi
- AI sẽ trả lời trong thời gian thực

#### Voice Chat
- Nhấn nút "Chế độ giọng nói" để bật/tắt
- Nói trực tiếp với AI Assistant
- AI sẽ phản hồi bằng giọng nói

### 3. Tính Năng Khác

- **Copy Message**: Nhấn icon copy để sao chép tin nhắn
- **Text-to-Speech**: Nhấn icon speaker để đọc tin nhắn
- **Connection Status**: Theo dõi trạng thái kết nối

## Cấu Trúc Code

```
lib/
├── services/
│   └── convai_service.dart          # Service quản lý Convai
├── models/
│   └── ai_assistant_model.dart      # Model cho AI Assistant
├── pages/
│   └── ai_assistant_page.dart       # Trang chính AI Assistant
├── widgets/
│   ├── ai_assistant_3d_widget.dart  # Widget 3D cho AI
│   └── chat_message_widget.dart     # Widget hiển thị tin nhắn
└── web/
    └── convai_test.html             # File test Convai Web SDK
```

## Tùy Chỉnh

### 1. Thay Đổi Giao Diện AI

Chỉnh sửa file `lib/widgets/ai_assistant_3d_widget.dart`:
- Thay đổi màu sắc, kích thước
- Thêm animation mới
- Tùy chỉnh avatar AI

### 2. Thay Đổi Character

Trong Convai Console:
- Cập nhật personality của character
- Thêm knowledge base mới
- Cấu hình voice và appearance

### 3. Thêm Tính Năng Mới

- Tích hợp với Firebase để lưu lịch sử chat
- Thêm file upload/sharing
- Tích hợp với camera để scan bài tập

## Troubleshooting

### 1. Lỗi Kết Nối

**Lỗi**: "Không thể kết nối"
**Giải pháp**:
- Kiểm tra API Key và Character ID
- Đảm bảo internet connection
- Kiểm tra Convai service status

### 2. Lỗi Voice Chat

**Lỗi**: "Không thể bật voice mode"
**Giải pháp**:
- Cho phép microphone access
- Kiểm tra browser permissions
- Đảm bảo HTTPS connection

### 3. Lỗi Performance

**Lỗi**: App chậm hoặc lag
**Giải pháp**:
- Kiểm tra memory usage
- Tối ưu animation
- Giảm số lượng particles

## API Reference

### ConvaiService

```dart
// Khởi tạo
await ConvaiService.instance.initialize();

// Kết nối
await ConvaiService.instance.connect();

// Gửi tin nhắn
await ConvaiService.instance.sendMessage("Hello");

// Voice chat
await ConvaiService.instance.startVoiceConversation();
await ConvaiService.instance.stopVoiceConversation();

// Ngắt kết nối
await ConvaiService.instance.disconnect();
```

### Events

```dart
// Lắng nghe tin nhắn
ConvaiService.instance.messageStream?.listen((message) {
  print('Received: $message');
});

// Lắng nghe trạng thái kết nối
ConvaiService.instance.connectionStream?.listen((connected) {
  print('Connected: $connected');
});
```

## Bảo Mật

### 1. API Key Security

- Không commit API Key vào git
- Sử dụng environment variables
- Rotate API Key định kỳ

### 2. User Data

- Không lưu tin nhắn nhạy cảm
- Mã hóa dữ liệu local
- Tuân thủ GDPR/CCPA

## Hỗ Trợ

Nếu gặp vấn đề:

1. Kiểm tra [Convai Documentation](https://docs.convai.com/)
2. Xem [Convai Community](https://community.convai.com/)
3. Liên hệ support team

## License

Dự án này sử dụng Convai Web SDK theo license của Convai. 