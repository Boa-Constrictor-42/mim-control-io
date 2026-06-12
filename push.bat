@echo off
cd /d C:\Projects\MIM\web
git add -A
git commit -m "fix: hdr-inner max-width 1140px, status bar tracks content frame right edge"
git push origin main
pause
