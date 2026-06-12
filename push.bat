@echo off
cd /d C:\Projects\MIM\web
git add -A
git commit -m "fix: status bar margin-left auto, sticks to header right edge"
git push origin main
pause
