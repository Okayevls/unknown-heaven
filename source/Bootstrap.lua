local project = getgenv().Project
local sha = getgenv().LatestSHA or "main"
local discordLink = "https://discord.gg/R7ABPb2f"

local http = game:GetService("HttpService")
local api = "https://api.github.com/repos/Okayevls/unknown-heaven/contents/scripts"
local _, folders = pcall(function() return http:JSONDecode(game:HttpGet(api)) end)
local exists = false
for _, item in ipairs(folders or {}) do
    if item.type == "dir" and item.name == project then exists = true break end
end
if not exists then
    warn("[Heaven]: Project '"..tostring(project).."' not found maybe (update or close) check discord server :L")
    warn("[Heaven]: Discord link copied to clipboard: " .. discordLink)
    return
end

print("Heaven: Step - (Loading Data...)")

local downloader = loadstring(game:HttpGet("https://raw.githubusercontent.com/Okayevls/unknown-heaven/"..sha.."/source/util/other/FastDownloader.lua"))()
print("Heaven: Step - (Loading Utility...)")

local inject = downloader.new("Okayevls", "unknown-heaven", "main"):GetLatestSHA()
print("Heaven: Step - (Loading Module...)")

local ModuleScanner = inject:Load("source/util/module/ModuleScanner.lua")
local scanner = ModuleScanner.new("Okayevls", "unknown-heaven")
local moduleFiles = scanner:GetModules(project)

local ModuleManager = inject:Load("source/util/module/ModuleManager.lua")
local ModuleRegistryManager = inject:Load("source/util/module/ModuleRegistryManager.lua")

local moduleMgr = ModuleManager.new()

local reg = ModuleRegistryManager.new(moduleFiles)

local listByCategory = reg:LoadAll(function(path) return inject:Load(path) end)
moduleMgr:RegisterFromList(listByCategory)

print("Heaven: Step - (Loading Getter...)")
getgenv().ctx = {
    Inject = inject,
    moduleMgr = moduleMgr,
}

print("Heaven: Step - (Loading Gui...)")
inject:Load("source/panel/mainGui/ClickGui.lua")

print("Heaven: Welcome")