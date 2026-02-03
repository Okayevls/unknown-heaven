local project = getgenv().Project
local sha = getgenv().LatestSHA or "main"
local discordLink = "https://discord.gg/R7ABPb2f"

local http = game:GetService("HttpService")
local startTime = os.clock() -- Фиксируем время старта

-- Функция для красивых логов
local function log(mode, msg)
    local prefix = "[Heaven]"
    local timestamp = os.date("%H:%M:%S")
    if mode == "info" then
        print(string.format("%s [%s] (INFO): %s", prefix, timestamp, msg))
    elseif mode == "warn" then
        warn(string.format("%s [%s] (WARN): %s", prefix, timestamp, msg))
    elseif mode == "error" then
        error(string.format("%s [%s] (ERROR): %s", prefix, timestamp, msg))
    end
end

log("info", "Starting bootstrapper...")

-- Проверка папки проекта
local api = "https://api.github.com/repos/Okayevls/unknown-heaven/contents/scripts"
local success, result = pcall(function() return http:JSONDecode(game:HttpGet(api)) end)

if not success or type(result) ~= "table" then
    log("error", "GitHub API is unavailable or rate limited.")
    return
end

local exists = false
for _, item in ipairs(result) do
    if item.type == "dir" and item.name == project then exists = true break end
end

if not exists then
    if setclipboard then setclipboard(discordLink) end
    log("warn", "Project '"..tostring(project).."' not found. Join Discord: " .. discordLink)
    return
end

-- Загрузка утилит
log("info", "Loading FastDownloader...")
local downloaderRaw = game:HttpGet("https://raw.githubusercontent.com/Okayevls/unknown-heaven/"..sha.."/source/util/other/FastDownloader.lua")
local downloader = loadstring(downloaderRaw)()

log("info", "Initializing Injector...")
local inject = downloader.new("Okayevls", "unknown-heaven", "main"):GetLatestSHA()

-- Сканирование модулей
log("info", "Scanning for modules in " .. project .. "...")
local ModuleScanner = inject:Load("source/util/module/ModuleScanner.lua")
local scanner = ModuleScanner.new("Okayevls", "unknown-heaven")
local moduleFiles = scanner:GetModules(project)

log("info", string.format("Found %d modules.", #moduleFiles))

-- Менеджеры
local ModuleManager = inject:Load("source/util/module/ModuleManager.lua")
local ModuleRegistryManager = inject:Load("source/util/module/ModuleRegistryManager.lua")

local moduleMgr = ModuleManager.new()
local reg = ModuleRegistryManager.new(moduleFiles)

-- Регистрация модулей с отловом ошибок
log("info", "Registering modules...")
local listByCategory = reg:LoadAll(function(path)
    log("info", "  -> Loading: " .. path)
    return inject:Load(path)
end)
moduleMgr:RegisterFromList(listByCategory)

-- Глобальный контекст
getgenv().ctx = {
    Inject = inject,
    moduleMgr = moduleMgr,
    DebugMode = true -- Добавим флаг отладки
}

-- Запуск GUI
log("info", "Launching UI...")
local guiSuccess, guiErr = pcall(function()
    inject:Load("source/panel/mainGui/ClickGui.lua")
end)

if not guiSuccess then
    log("error", "GUI failed to load: " .. tostring(guiErr))
else
    local duration = string.format("%.2f", os.clock() - startTime)
    log("info", "Heaven loaded successfully in " .. duration .. "s!")
end