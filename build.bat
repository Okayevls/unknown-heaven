@echo off
setlocal
cd /d "E:\LedikAll\unknown-heaven"

:: Проверка изменений
git status --porcelain | findstr /r "^" >nul || (echo Нет изменений для деплоя. && exit /b)

:: Запоминаем время старта (в секундах)
set "start_time=%time: =0%"
set /a "start_s=(1%start_time:~0,2%-100)*3600 + (1%start_time:~3,2%-100)*60 + (1%start_time:~6,2%-100)"
set /a "start_ms=(1%start_time:~9,2%-100)"

echo [Build] Отправка изменений на GitHub...

:: Выполнение команд
git add . 2>nul && git commit -m "upd %date:~0,5% %time:~0,5%" --quiet && git push origin main --quiet

if %errorlevel% equ 0 (
    :: Запоминаем время окончания
    set "end_time=%time: =0%"
    set /a "end_s=(1%end_time:~0,2%-100)*3600 + (1%end_time:~3,2%-100)*60 + (1%end_time:~6,2%-100)"
    set /a "end_ms=(1%end_time:~9,2%-100)"

    :: Считаем разницу
    set /a "total_s=end_s - start_s"
    set /a "total_ms=end_ms - start_ms"
    if %total_ms% lss 0 (
        set /a "total_s-=1"
        set /a "total_ms+=100"
    )

    echo ---------------------------------------
    echo [Успешно] Завершено в %time%
    echo [Время] Сбилдилось за: %total_s%.%total_ms% сек.
    echo ---------------------------------------
) else (
    echo [Ошибка] Не удалось отправить билд. Проверь интернет.
)

pause