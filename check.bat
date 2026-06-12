@echo off
cd /d C:\Projects\MIM\web
git log --oneline -5 > C:\Projects\MIM\web\git_log.txt 2>&1
git status >> C:\Projects\MIM\web\git_log.txt 2>&1
