@echo off

echo pushing to device...
adb push dump.sh /tmp/
echo.

echo running...
adb shell sh /tmp/dump.sh >repit-dump.log
