@echo off
echo 🚀 Deploy EBook Backend to Render.com
echo ====================================

echo 📋 Hướng dẫn deploy lên Render.com:
echo.
echo 1. 🌐 Truy cập: https://render.com
echo 2. 📝 Đăng ký tài khoản miễn phí
echo 3. 🔗 Connect GitHub repository
echo 4. ➕ Tạo New Web Service
echo 5. 📂 Chọn repository: %cd%
echo 6. ⚙️ Configuration:
echo    - Name: ebook-backend
echo    - Environment: Python 3
echo    - Build Command: pip install -r backend/requirements.txt
echo    - Start Command: cd backend ^&^& python app.py
echo    - Plan: Free
echo    - Auto-Deploy: Yes (from main branch)
echo.
echo 7. 🔑 Environment Variables (trong Render dashboard):
echo    - PORT: 10000
echo    - FLASK_ENV: production
echo    - GEMINI_API_KEY: your_gemini_key
echo    - CLOUDINARY_CLOUD_NAME: your_cloud_name
echo    - CLOUDINARY_API_KEY: your_api_key
echo    - CLOUDINARY_API_SECRET: your_api_secret
echo.
echo 8. 🚀 Deploy!
echo.
echo 📝 Sau khi deploy thành công:
echo 1. Copy URL từ Render (VD: https://ebook-backend-xxx.onrender.com)
echo 2. Chạy: build_flutter_render.bat https://your-render-url
echo.
echo 💡 Render.com Free Plan:
echo - ✅ 750 hours/month (đủ cho 1 app chạy 24/7)
echo - ✅ Auto-sleep sau 15 phút không dùng
echo - ✅ Auto-wake khi có request
echo - ✅ HTTPS miễn phí
echo - ✅ Custom domain support
echo.
pause
