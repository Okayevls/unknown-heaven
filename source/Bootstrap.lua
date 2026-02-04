local project = getgenv().Project
local sha = getgenv().LatestSHA or "main"
local discordLink = "https://discord.gg/R7ABPb2f"

local http = game:GetService("HttpService")
local startTime = os.clock()

local loggerUrl = "https://raw.githubusercontent.com/Okayevls/unknown-heaven/"..sha.."/source/util/time/Logger.lua"
local LoggerClass = getgenv().LoggerInstance or loadstring(game:HttpGet(loggerUrl))()
local log = LoggerClass.new("[Heaven]")

log:Info("Starting bootstrapper...")

local api = "https://api.github.com/repos/Okayevls/unknown-heaven/contents/scripts"
local success, result = pcall(function() return http:JSONDecode(game:HttpGet(api)) end)
if not success or type(result) ~= "table" then
    log:Error("GitHub API is unavailable or rate limited.")
    return
end
local exists = false
for _, item in ipairs(result) do
    if item.type == "dir" and item.name == project then exists = true break end
end
if not exists then
    if setclipboard then
        log:Warn("Project '"..tostring(project).."' not found (close or update). Invite copied.")
        setclipboard(discordLink)
    else
        log:Warn("Project '"..tostring(project).."' not found (close or update) join." ..discordLink)
    end
    return
end

log:Info("Loading Downloader...")
local downloaderRaw = game:HttpGet("https://raw.githubusercontent.com/Okayevls/unknown-heaven/"..sha.."/source/util/other/FastDownloader.lua")
local downloader = loadstring(downloaderRaw)()

log:Info("Initializing Injector...")
local inject = downloader.new("Okayevls", "unknown-heaven", "main"):GetLatestSHA()

local listPath = string.format("scripts/%s/Modules.lua", project)
local moduleRegistryList = inject:Load(listPath)

log:Info("Loading addition wait please...")

local meta = {}
if type(moduleRegistryList) == "table" then
    meta = moduleRegistryList.Meta or {}
end

local OpenURI = inject:Load("source/util/system/OpenURI.lua")

getgenv().ctx = {
    Inject = inject,
    Meta = meta,
}

OpenURI.loading(moduleRegistryList, discordLink)

local system = {}
if type(moduleRegistryList) == "table" then
    system = moduleRegistryList.System or {}
end
log:Info("Addition loading successful...")

log:Info("Scanning for modules in " .. project .. "...")

local ModuleManager = inject:Load("source/util/module/ModuleManager.lua")
local ModuleRegistryManager = inject:Load("source/util/module/ModuleRegistryManager.lua")
local moduleMgr = (getgenv().ctx and getgenv().ctx.moduleMgr) or ModuleManager.new()

local moduleList = moduleRegistryList
if type(moduleRegistryList) == "table" and moduleRegistryList.Modules then
    moduleList = moduleRegistryList.Modules
end

local reg = ModuleRegistryManager.new(moduleList)

log:Info("Registering modules...")

local loadedCount = 0
local listByCategory = reg:LoadAll(function(path)
    loadedCount = loadedCount + 1
    log:LogLoading(loadedCount, path)
    return inject:Load(path)
end)
moduleMgr:RegisterFromList(listByCategory)

log:Info("Successfully registered all modules.")

getgenv().ctx.moduleMgr = moduleMgr
getgenv().ctx.DebugMode = true

log:Info("Launching UI...")
local guiSuccess, guiErr = pcall(function()
    inject:Load("source/panel/mainGui/ClickGui.lua")
end)

if not guiSuccess then
    log:Error("GUI failed to load: " .. tostring(guiErr))
else
    local duration = string.format("%.2f", os.clock() - startTime)
    log:Info("Heaven loaded successfully in " .. duration .. "s!")
end