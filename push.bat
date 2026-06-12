@echo off
cd /d C:\Projects\MIM\web
git add -A
git commit -m "feat: responsive sidebar auto-collapse below 900px, no toggle button"
git push origin main
pause
