# 🚀 Hướng dẫn Deploy lên Render.com - MIỄN PHÍ

## 🎯 **Tại sao chọn Render.com?**
- ✅ **Hoàn toàn MIỄN PHÍ** (750 hours/month)
- ✅ **Dễ setup** (chỉ cần GitHub)
- ✅ **Auto-deploy** khi push code
- ✅ **HTTPS miễn phí**
- ✅ **Auto-sleep/wake** (tiết kiệm tài nguyên)
- ✅ **No credit card required**

## 📋 **Bước 1: Chuẩn bị**

### 1.1 Push code lên GitHub
```bash
git add .
git commit -m "Ready for Render deployment"
git push origin main
```

### 1.2 Chuẩn bị API Keys
- **Gemini API Key**: https://makersuite.google.com/app/apikey
- **Cloudinary**: https://cloudinary.com (free account)

## 🌐 **Bước 2: Deploy Backend lên Render.com**

### 2.1 Tạo tài khoản Render
1. Truy cập: https://render.com
2. Sign up với GitHub account
3. Authorize Render to access repositories

### 2.2 Tạo Web Service
1. Click **"New +"** → **"Web Service"**
2. Connect repository: `your-username/Ebook`
3. Configuration:
   ```
   Name: ebook-backend
   Environment: Python 3
   Build Command: pip install -r backend/requirements.txt
   Start Command: cd backend && python app.py
   Plan: Free
   ```

### 2.3 Environment Variables
Trong Render dashboard, thêm:
```
PORT = 10000
FLASK_ENV = production
GEMINI_API_KEY = your_gemini_api_key
CLOUDINARY_CLOUD_NAME = your_cloud_name
CLOUDINARY_API_KEY = your_api_key
CLOUDINARY_API_SECRET = your_api_secret
```

### 2.4 Deploy
1. Click **"Create Web Service"**
2. Đợi 3-5 phút để build & deploy
3. Copy URL: `https://ebook-backend-xxx.onrender.com`

## 📱 **Bước 3: Build Flutter với Render Backend**

### 3.1 Build Flutter Web
```bash
# Windows
build_flutter_render.bat https://your-render-url

# Manual
flutter build web --dart-define=RENDER_BACKEND_URL=https://your-render-url
```

### 3.2 Test Local với Render Backend
```bash
flutter run -d chrome --dart-define=RENDER_BACKEND_URL=https://your-render-url
```

## 🌐 **Bước 4: Deploy Frontend**

### Option 1: Firebase Hosting (Khuyên dùng)
```bash
npm install -g firebase-tools
firebase login
firebase init hosting
firebase deploy
```

### Option 2: Netlify (Đơn giản nhất)
1. Vào https://netlify.com
2. Drag & drop thư mục `build/web`
3. Done!

### Option 3: Vercel
```bash
npm install -g vercel
cd build/web
vercel --prod
```

### Option 4: GitHub Pages
```bash
# Copy build/web to gh-pages branch
cp -r build/web/* docs/
git add docs/
git commit -m "Deploy to GitHub Pages"
git push
```

## 💰 **Chi phí: HOÀN TOÀN MIỄN PHÍ**

### Render.com Free Plan:
- **750 hours/month** (đủ cho 1 app chạy 24/7)
- **512MB RAM**
- **Auto-sleep** sau 15 phút không dùng
- **Auto-wake** khi có request (cold start ~30s)
- **Custom domain** support

### Frontend Hosting (Free):
- **Firebase**: 10GB storage, 360MB/day transfer
- **Netlify**: 100GB bandwidth/month
- **Vercel**: 100GB bandwidth/month
- **GitHub Pages**: Unlimited static hosting

## 🔧 **Auto-Deploy Setup**

### Render sẽ tự động deploy khi:
1. Push code lên GitHub
2. Merge pull request
3. Update environment variables

### Monitoring:
- **Logs**: Render dashboard → Service → Logs
- **Metrics**: CPU, Memory usage
- **Health checks**: Automatic `/health` endpoint monitoring

## ✅ **Checklist hoàn thành**

- [ ] ✅ GitHub repository updated
- [ ] ✅ Render.com account created
- [ ] ✅ Web Service configured
- [ ] ✅ Environment variables set
- [ ] ✅ Backend deployed successfully
- [ ] ✅ Backend URL working (test /health)
- [ ] ✅ Flutter built với Render backend URL
- [ ] ✅ Frontend deployed to hosting
- [ ] ✅ End-to-end testing completed

## 🆘 **Troubleshooting**

### Backend không start:
```bash
# Check logs trong Render dashboard
# Thường do thiếu environment variables
```

### Cold start chậm:
```bash
# Render free plan có cold start ~30s
# Có thể dùng cron job để keep-alive:
# https://cron-job.org → ping your-render-url/health mỗi 10 phút
```

### CORS errors:
```bash
# Đã config CORS trong backend/app.py
# Nếu vẫn lỗi, check Render logs
```

## 🎉 **Kết quả cuối cùng**

Sau khi hoàn thành:
- ✅ **Backend**: Chạy trên Render.com (miễn phí, auto-scale)
- ✅ **Frontend**: Deploy trên hosting (Firebase/Netlify/Vercel)
- ✅ **AI Assistant**: Hoạt động hoàn hảo với voice & chat
- ✅ **Multi-platform**: Web, Android, iOS đều dùng chung backend
- ✅ **Production-ready**: Monitoring, logs, auto-deploy

**🌐 App của bạn giờ đã live trên internet - HOÀN TOÀN MIỄN PHÍ!**
