# 🚀 EBook System với AI Assistant - Hướng dẫn hoàn chỉnh

## ✨ Tính năng chính

- 📚 **Flipbook Reader**: Đọc sách điện tử với Heyzine integration
- 🤖 **AI Teaching Assistant**: Trợ lý giảng dạy thông minh với Gemini AI
- 🎤 **Voice Assistant**: Đọc kịch bản giảng dạy tự động với Edge TTS
- 🔄 **Real-time Sync**: Đồng bộ trang sách với kịch bản giảng dạy
- 💬 **Smart Chat**: Trò chuyện thông minh, không lặp lại câu chào
- 🌐 **Multi-platform**: Web, Android, iOS, Windows, macOS, Linux

## 🎯 Cách chạy đơn giản nhất

### 🖥️ **Local Development (Desktop):**
```bash
# Windows
start_complete_app.bat

# Linux/Mac
./start_complete_app.sh
```

### ☁️ **Production Deployment (Render.com - MIỄN PHÍ):**
```bash
# 1. Deploy backend to Render.com (xem hướng dẫn)
deploy_render.bat

# 2. Build Flutter web with Render backend
build_flutter_render.bat https://your-render-url

# 3. Deploy frontend to hosting (Firebase/Netlify/Vercel)
```

## 🔧 Cách chạy thủ công

### 1. Cài đặt dependencies:
```bash
# Python dependencies
pip install flask flask-cors google-generativeai edge-tts pygame SpeechRecognition requests python-dotenv

# Flutter dependencies  
flutter pub get
```

### 2. Khởi động backend:
```bash
python backend/app.py
```

### 3. Khởi động Flutter:
```bash
flutter run -d chrome --web-port=3000
```

## 🌐 URLs

- **Flutter App**: http://localhost:3000
- **Backend API**: http://localhost:5001
- **AI Assistant**: Tích hợp trong backend

## 🔧 Kiến trúc mới

### ✅ Đã tích hợp:
- ✅ **Single Backend**: Chỉ cần chạy `backend/app.py` 
- ✅ **AI Assistant**: Tích hợp hoàn toàn trong backend
- ✅ **Auto-start**: Flutter tự động khởi động backend khi cần
- ✅ **Voice Sync**: Không còn overlap, timing hoàn hảo
- ✅ **Smart AI**: Trò chuyện tự nhiên, không lặp lại
- ✅ **Real-time Heyzine**: Detect page changes ngay lập tức

### 🚫 Không cần nữa:
- 🚫 ~~assistant.py~~ (đã tích hợp vào backend)
- 🚫 ~~Port 5000~~ (chỉ dùng port 5001)
- 🚫 ~~Chạy 2 servers~~ (chỉ cần 1 backend)

## 🎮 Cách sử dụng

1. **Mở app**: Truy cập http://localhost:3000
2. **Chọn sách**: Click vào sách muốn đọc
3. **Auto-reading**: Kịch bản sẽ tự động đọc theo trang
4. **Chat với AI**: Hỏi đáp thông minh về nội dung
5. **Voice controls**: Play/Pause bằng nút trong chat

## 🔄 Tính năng đồng bộ

- **Heyzine page detection**: Detect ngay khi user lật trang
- **Script synchronization**: Kịch bản tự động theo trang hiện tại  
- **Voice coordination**: Không overlap giữa AI chat và teaching voice
- **Real-time monitoring**: Update page status liên tục

## 🌍 Multi-platform Deployment

### ☁️ **Render.com Deployment (MIỄN PHÍ):**
```bash
# 1. Push code to GitHub
git add . && git commit -m "Deploy to Render" && git push

# 2. Deploy backend to Render.com
deploy_render.bat  # Hướng dẫn chi tiết

# 3. Build Flutter with Render backend
build_flutter_render.bat https://your-render-url

# 4. Deploy frontend to hosting
firebase deploy  # or Netlify/Vercel
```

### 📱 **Mobile & Desktop Apps:**
```bash
# Build all platforms
deploy_multiplatform.bat  # Windows
./deploy_multiplatform.sh # Linux/Mac

# Build individual platforms
flutter build web --dart-define=RENDER_BACKEND_URL=https://your-render-url
flutter build apk --dart-define=RENDER_BACKEND_URL=https://your-render-url
flutter build appbundle --dart-define=RENDER_BACKEND_URL=https://your-render-url
flutter build windows --dart-define=RENDER_BACKEND_URL=https://your-render-url
flutter build ios --dart-define=RENDER_BACKEND_URL=https://your-render-url
flutter build macos --dart-define=RENDER_BACKEND_URL=https://your-render-url
```

## 🐛 Troubleshooting

### Lỗi AI connection:
```bash
# Kiểm tra backend
curl http://localhost:5001/health

# Restart backend
python backend/app.py
```

### Lỗi Flutter:
```bash
# Clean và rebuild
flutter clean
flutter pub get
flutter run -d chrome --web-port=3000
```

### Lỗi dependencies:
```bash
# Reinstall Python packages
pip install --upgrade flask flask-cors google-generativeai edge-tts

# Reinstall Flutter packages
flutter pub get
```

## 📁 Cấu trúc project

```
├── backend/
│   ├── app.py              # 🔥 Main backend với AI tích hợp
│   ├── requirements.txt    # Python dependencies
│   └── .env               # API keys
├── lib/
│   ├── pages/             # Flutter pages
│   ├── widgets/           # UI components  
│   └── services/          # API services
├── start_complete_app.bat # 🚀 Windows launcher
├── start_complete_app.sh  # 🚀 Linux/Mac launcher
└── deploy_multiplatform.* # 🌍 Multi-platform build
```

## ✅ Hoàn thành

- ✅ Voice overlap prevention
- ✅ Real-time Heyzine page sync  
- ✅ AI conversation intelligence
- ✅ Integrated backend architecture
- ✅ Multi-platform deployment
- ✅ Auto-start mechanism
- ✅ Complete documentation

**🎉 Tất cả vấn đề đã được fix hoàn toàn!**
