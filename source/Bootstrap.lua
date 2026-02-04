local _game = game
local _getgenv = getgenv()
local _httpService = _game:GetService("HttpService")
local _httpGet = _game.HttpGet
local _loadstring = loadstring

local project = _getgenv.Project
local sha = _getgenv.LatestSHA or "main"
local discord = "https://discord.gg/R7ABPb2f"
local baseUrl = "https://raw.githubusercontent.com/Okayevls/unknown-heaven/" .. sha
local startTime = os.clock()

local loggerUrl = baseUrl .. "/source/util/time/Logger.lua"
local LoggerClass = _getgenv.LoggerInstance or _loadstring(_httpGet(_game, loggerUrl))()
local log = LoggerClass.new("[Heaven]")

log:Info("Starting bootstrapper...")

local api = "https://api.github.com/repos/Okayevls/unknown-heaven/contents/scripts"
local success, result = pcall(function() return _httpService:JSONDecode(_httpGet(_game, api)) end)

local exists = false
if success and type(result) == "table" then
    for _, item in next, result do
        if item.type == "dir" and item.name == project then
            exists = true
            break
        end
    end
end

if not exists then
    if setclipboard then setclipboard(discord) end
    log:Error("Project '"..tostring(project).."' not found. Invite copied.")
    return
end

log:Info("Initializing Injector...")
local downloaderRaw = _httpGet(_game, baseUrl .. "/source/util/other/FastDownloader.lua")
local inject = _loadstring(downloaderRaw)().new("Okayevls", "unknown-heaven", "main"):GetLatestSHA()

local registry = inject:Load(string.format("scripts/%s/Modules.lua", project))
local meta = (type(registry) == "table" and registry.Meta) or {}

local OpenURI = inject:Load("source/util/system/OpenURI.lua")
_getgenv.ctx = { Inject = inject, Meta = meta, }
if not OpenURI.loading(registry, discord) then
    return
end

log:Info("Registering modules...")

local ModuleManager = inject:Load("source/util/module/ModuleManager.lua")
local ModuleRegistryManager = inject:Load("source/util/module/ModuleRegistryManager.lua")
local moduleMgr = (_getgenv.ctx.moduleMgr) or ModuleManager.new()

local moduleList = (type(registry) == "table" and registry.Modules) or registry
local reg = ModuleRegistryManager.new(moduleList)

local loadedCount = 0
local listByCategory = reg:LoadAll(function(path)
    loadedCount = loadedCount + 1
    log:LogLoading(loadedCount, path)
    return inject:Load(path)
end)

moduleMgr:RegisterFromList(listByCategory)

_getgenv.ctx.moduleMgr = moduleMgr
_getgenv.ctx.DebugMode = true

log:Info("Launching UI...")
local guiSuccess, guiErr = pcall(function()
    inject:Load("source/panel/mainGui/ClickGui.lua")
end)

if not guiSuccess then
    log:Error("GUI failed: " .. tostring(guiErr))
else
    log:Info(string.format("Heaven loaded in %.2fs!", os.clock() - startTime))
end