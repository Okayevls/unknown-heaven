@echo off
cd /d "E:\LedikAll\unknown-heaven"

git status --porcelain | findstr /r "^" >nul || (echo Нет изменений для деплоя. && exit /b)
echo Обновление: %time%
git add . 2>nul && git commit -m "upd" --quiet && git push origin main --quiet

if %errorlevel% equ 0 (
    echo [OK] %time%
) else (
    echo [ERROR] %time%
)