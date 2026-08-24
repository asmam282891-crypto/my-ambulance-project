@echo off
REM يشغّل سيرفر الإسعاف + نفق ngrok سوا (مناسب لاتصال MiFi/هوتسبوت بدون IP عام)
REM لازم يكون عندك ngrok.exe بنفس هذا المجلد أو بمسار النظام (PATH)
REM ولازم تكون سويت: ngrok config add-authtoken [التوكن]
REM وحجزت نطاق ثابت من لوحة تحكم ngrok

set NGROK_DOMAIN=xxxx.ngrok-free.app

echo تشغيل نفق ngrok بالخلفية...
start "ngrok tunnel" cmd /c "ngrok http --domain=%NGROK_DOMAIN% 3000"

timeout /t 3 >nul

echo تشغيل سيرفر الإسعاف...
:loop
echo [%date% %time%] بدء تشغيل السيرفر...
dart run bin/server.dart
echo.
echo [%date% %time%] توقف السيرفر! إعادة التشغيل خلال 5 ثوانٍ...
timeout /t 5
goto loop
