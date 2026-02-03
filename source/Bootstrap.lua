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

print("Heaven: Step - 1 (Loading Data...)")

local downloader = loadstring(game:HttpGet("https://raw.githubusercontent.com/Okayevls/unknown-heaven/"..sha.."/source/util/other/FastDownloader.lua"))()
print("Heaven: Step - 2 (Loading Utility...)")

local inject = downloader.new("Okayevls", "unknown-heaven", "main"):GetLatestSHA()
print("Heaven: Step - 3 (Loading Injector...)")

local listPath = string.format("scripts/%s/ModuleRegistryList.lua", project)
local moduleRegistryList = inject:Load(listPath)

local ModuleManager = inject:Load("source/util/module/ModuleManager.lua")
local ModuleRegistryManager = inject:Load("source/util/module/ModuleRegistryManager.lua")

local moduleMgr = ModuleManager.new()

local reg = ModuleRegistryManager.new(moduleRegistryList)

local listByCategory = reg:LoadAll(function(path) return inject:Load(path) end)
moduleMgr:RegisterFromList(listByCategory)

print("Heaven: Step - 4 (Loading Modules...)")

getgenv().ctx = {
    Inject = inject,
    moduleMgr = moduleMgr,
}

inject:Load("source/panel/mainGui/ClickGui.lua")
print("Heaven: Step - 5 (Loading Gui...)")
print("Heaven: Welcome")