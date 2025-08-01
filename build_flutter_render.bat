@echo off
echo 🚀 Building Flutter Web with Render Backend
echo ============================================

REM Get Render URL
set RENDER_BACKEND_URL=%1
if "%RENDER_BACKEND_URL%"=="" (
    set RENDER_BACKEND_URL=https://ebook-baend.onrender.com
    echo 🔗 Using default URL: %RENDER_BACKEND_URL%
    echo 💡 Usage: build_flutter_render.bat https://your-render-url
) else (
    echo 🔗 Using provided URL: %RENDER_BACKEND_URL%
)

echo 🧹 Cleaning previous build...
flutter clean
flutter pub get

echo 📦 Building Flutter web with Render backend...
flutter build web --release ^
  --dart-define=RENDER_BACKEND_URL=%RENDER_BACKEND_URL% ^
  --web-renderer html

echo.
echo ✅ Build completed!
echo 📁 Output: build/web/
echo 🌐 Backend URL: %RENDER_BACKEND_URL%
echo.
echo 📝 Deploy options:
echo 1. 🔥 Firebase: firebase deploy
echo 2. 🌐 Netlify: drag build/web folder to netlify.com
echo 3. ⚡ Vercel: vercel --prod
echo 4. 📄 GitHub Pages: copy build/web to gh-pages branch
echo.
echo 🧪 Test locally:
echo flutter run -d chrome --dart-define=RENDER_BACKEND_URL=%RENDER_BACKEND_URL%
pause
