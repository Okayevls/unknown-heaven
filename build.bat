@echo off
cd /d "E:\LedikAll\unknown-heaven"

git status --porcelain | findstr /r "^" >nul || (echo Нет изменений для деплоя. && exit /b)
echo Обновление: %time%
git add . && git commit -m "upd %date:~0,5% %time:~0,5%" --quiet && git push origin main --quiet --no-verify

if %errorlevel% equ 0 (
    echo [OK] %time%
) else (
    echo [ERROR] %time%
)