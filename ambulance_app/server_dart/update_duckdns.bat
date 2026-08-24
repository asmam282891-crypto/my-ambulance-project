@echo off
REM سكريبت تحديث DuckDNS التلقائي - يحدّث الـ IP كل مرة تشغّله
REM عدّل السطرين التاليين ببياناتك من duckdns.org

set DUCKDNS_DOMAIN=ambulance-riyadh
set DUCKDNS_TOKEN=ضع-التوكن-هنا

curl "https://www.duckdns.org/update?domains=%DUCKDNS_DOMAIN%&token=%DUCKDNS_TOKEN%&ip="

echo.
echo تم تحديث عنوان DuckDNS
