@echo off
cd /d E:\LedikAll\unknown-heaven

git add . >nul 2>&1
git commit -m "Auto-commit %date% %time%" > commit.log 2>&1
git push origin main >nul 2>&1
