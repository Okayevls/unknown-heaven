local project = getgenv().Project
local sha = getgenv().LatestSHA or "main"
local discordLink = "https://discord.gg/R7ABPb2f"

local http = game:GetService("HttpService")
local startTime = os.clock()

local loggerRaw = game:HttpGet("https://raw.githubusercontent.com/Okayevls/unknown-heaven/"..sha.."/source/util/other/Logger.lua")
local LoggerClass = getgenv().LoggerInstance or loadstring(game:HttpGet(loggerRaw))()
local log = LoggerClass.new("[Heaven]")

log:Info("Starting bootstrapper...")

local success, result = pcall(function() return http:JSONDecode(game:HttpGet("https://api.github.com/repos/Okayevls/unknown-heaven/contents/scripts")) end)
local folder = success and type(result) == "table" and table.find(result, function(v) return v.name == project end)
if not success then return log:Error("GitHub API rate limited.") end
if not folder then
    if setclipboard then setclipboard(discordLink) end
    return log:Warn("Project '"..tostring(project).."' not found (close or update). Invite copied.")
end

log:Info("Loading FastDownloader...")
local downloaderRaw = game:HttpGet("https://raw.githubusercontent.com/Okayevls/unknown-heaven/"..sha.."/source/util/other/FastDownloader.lua")
local downloader = loadstring(downloaderRaw)()

log:Info("Initializing Injector...")
local inject = downloader.new("Okayevls", "unknown-heaven", "main"):GetLatestSHA()

log:Info("Scanning for modules in " .. project .. "...")
local ModuleScanner = inject:Load("source/util/module/ModuleScanner.lua")
local scanner = ModuleScanner.new("Okayevls", "unknown-heaven")
local moduleFiles = scanner:GetModules(project)

log:Info(string.format("Found %d modules.", #moduleFiles))

local ModuleManager = inject:Load("source/util/module/ModuleManager.lua")
local ModuleRegistryManager = inject:Load("source/util/module/ModuleRegistryManager.lua")

local moduleMgr = ModuleManager.new()
local reg = ModuleRegistryManager.new(moduleFiles)

log:Info("Registering modules...")

local loadedCount = 0
local listByCategory = reg:LoadAll(function(path)
    loadedCount = loadedCount + 1
    log:LogLoading(loadedCount, path)
    return inject:Load(path)
end)
moduleMgr:RegisterFromList(listByCategory)

log:Info("Successfully registered all modules.")

getgenv().ctx = {
    Inject = inject,
    moduleMgr = moduleMgr,
    DebugMode = true
}

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