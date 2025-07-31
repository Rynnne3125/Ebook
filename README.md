# 📚 EBook Flutter App với AI Assistant

Ứng dụng đọc sách điện tử tích hợp AI Assistant sử dụng Flutter và Google Gemini AI.

## 🚀 Cách Chạy Ứng Dụng

### Phương pháp 1: Hệ thống hoàn chỉnh (Khuyến nghị)

**Windows:**
```bash
start_full_app.bat
```

**Linux/macOS:**
```bash
chmod +x start_full_app.sh
./start_full_app.sh
```

### Phương pháp 2: Chỉ AI Assistant (Cũ)

**Windows:**
```bash
start_app.bat
```

**Linux/macOS:**
```bash
chmod +x start_app.sh
./start_app.sh
```

### Phương pháp 3: Chạy thủ công từng service

1. **Cài đặt dependencies:**
```bash
# Backend dependencies
cd backend
pip install -r requirements.txt
cd ..

# AI Assistant dependencies
pip install flask flask-cors google-generativeai edge-tts pygame SpeechRecognition

# Flutter dependencies
flutter pub get
```

2. **Khởi động Backend API (Terminal 1):**
```bash
python backend/app.py
```

3. **Khởi động AI Assistant (Terminal 2):**
```bash
python assistant.py
```

4. **Chạy Flutter App (Terminal 3):**
```bash
flutter run
```

## 🏗️ Kiến Trúc Hệ Thống

```
[Flutter App] ←→ [Backend API] ←→ [Cloudinary] ←→ [Heyzine API]
     ↓               ↓              ↓              ↓
[Admin Panel]   [PDF Processing]  [File Storage]  [Flipbook Gen]
     ↓               ↓              ↓              ↓
[Book Reader]   [AI Processing]   [PDF URLs]     [Embed URLs]
     ↓               ↓
[AI Assistant] ←→ [assistant.py] ←→ [Google Gemini API]
     ↓               ↓                    ↓
[Auto Scripts]  [Edge TTS]         [Teaching Scripts]
```

### Luồng Xử Lý:
1. **Admin Upload PDF** → Backend API
2. **Backend** → Upload PDF to Cloudinary
3. **Backend** → Call Heyzine API to create flipbook
4. **Backend** → Extract text from PDF
5. **Backend** → Generate teaching scripts with Gemini AI
6. **Backend** → Save all data to Firestore
7. **User** → Read book with auto-playing teaching scripts

## 🔧 Tính Năng

### ✅ Đã Hoàn Thành:
- 📚 Đọc sách PDF qua Heyzine Flipbook
- 🤖 AI Assistant với Google Gemini
- 🔊 Text-to-Speech với Edge TTS
- 📱 Giao diện responsive (Mobile/Desktop)
- 🎯 Tách riêng iframe và chat box
- 🚀 Tự động khởi động AI Server
- 👨‍💼 Admin Panel để upload PDF
- ☁️ Tích hợp Cloudinary cho file storage
- 📖 Tích hợp Heyzine API cho flipbook
- 🎓 Auto-generate teaching scripts với AI
- 🎤 Auto-play teaching scripts khi lật trang

### 🚧 Đang Phát Triển:
- 🔗 Heyzine API integration (cần API key)
- 💾 Lưu teaching scripts vào Firestore
- 🎵 TTS integration với teaching scripts
- 📊 Analytics và tracking

## 📱 Giao Diện

### Desktop Layout
```
┌─────────────────┬─────────────┐
│                 │             │
│   Flipbook      │ AI Assistant│
│   (70%)         │   (30%)     │
│                 │             │
└─────────────────┴─────────────┘
```

### Mobile Layout
```
┌─────────────────┐
│   Flipbook      │
│   (70%)         │
├─────────────────┤
│ AI Assistant    │
│   (30%)         │
└─────────────────┘
```

## 🛠️ Cấu Hình

1. **Google Gemini API Key:** Cập nhật trong `assistant.py`
2. **Firebase:** Cấu hình trong `firebase_options.dart`
3. **Heyzine URLs:** Lưu trong Firestore

## 📋 Yêu Cầu Hệ Thống

- Flutter SDK ≥ 3.8.1
- Python ≥ 3.8
- Node.js (cho web)
- Firebase project
- Google Gemini API key

## 🔍 Troubleshooting

**AI Server không khởi động:**
- Kiểm tra Python đã cài đặt
- Kiểm tra port 5000 có bị chiếm
- Chạy thủ công: `python assistant.py`

**Flutter build lỗi:**
- Chạy: `flutter clean && flutter pub get`
- Kiểm tra Firebase configuration

## 📞 Hỗ Trợ

Nếu gặp vấn đề, vui lòng kiểm tra:
1. Console output của AI Server
2. Flutter debug console
3. Browser developer tools (cho web)
