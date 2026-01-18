@echo off
cd /d E:\LedikAll\unknown-heaven


echo 🔄 Добавление изменений...
git add . >nul 2>&1
echo 💾 Создание коммита...
git commit -m "Auto-commit %date% %time%" > commit.log 2>&1
echo 🚀 Отправка в репозиторий...
git push origin main >nul 2>&1
