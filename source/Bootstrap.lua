local projectName = getgenv().Project or "Unknown111"
local sha = getgenv().LatestSHA or "main"

if not projectName or projectName == "Unknown111" then
    warn(" [Heaven Error]: Project name is not defined!")
    return
end

print("Heaven: Step - 1 (Loading Data...)")

local downloader = loadstring(game:HttpGet("https://raw.githubusercontent.com/Okayevls/unknown-heaven/"..sha.."/source/util/other/FastDownloader.lua"))()
print("Heaven: Step - 2 (Loading Utility...)")

local inject = downloader.new("Okayevls", "unknown-heaven", "main"):GetLatestSHA()
print("Heaven: Step - 3 (Loading Injector...)")

local listPath = string.format("scripts/%s/ModuleRegistryList.lua", projectName)
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