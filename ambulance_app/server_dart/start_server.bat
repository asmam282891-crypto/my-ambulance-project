@echo off
REM هذا الملف يشغّل سيرفر الإسعاف + يحدّث عنوان DuckDNS تلقائيًا + يعيد تشغيل السيرفر لو تعطل
REM اضغط عليه مرتين لتشغيل كل شي، أو أضفه لبداية تشغيل الويندوز (اقرأ الشرح بـ README)

title Ambulance Server - لا تقفل هذه النافذة

echo تحديث DuckDNS...
call update_duckdns.bat

echo بدء تحديث DuckDNS كل 5 دقائق بالخلفية...
start /min cmd /c "for /l %%x in (1,1,999999) do (timeout /t 300 >nul & call update_duckdns.bat)"

:loop
echo [%date% %time%] بدء تشغيل السيرفر...
dart run bin/server.dart
echo.
echo [%date% %time%] توقف السيرفر! إعادة التشغيل خلال 5 ثوانٍ...
timeout /t 5
goto loop
