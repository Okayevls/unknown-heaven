local http = game:GetService("HttpService")
local data = http:JSONDecode(game:HttpGet("https://api.github.com/repos/Okayevls/unknown-heaven/commits/main"))
local sha = data["sha"]
print("Heaven: Step - 1 (Loading Data...)")

local downloader = loadstring(game:HttpGet("https://raw.githubusercontent.com/Okayevls/unknown-heaven/"..sha.."/source/util/other/FastDownloader.lua"))()
print("Heaven: Step - 2 (Loading Utility...)")

local inject = downloader.new("Okayevls", "unknown-heaven", "main"):GetLatestSHA()
print("Heaven: Step - 3 (Loading Injector...)")

local ModuleManager = inject:Load("scripts/ModuleManager.lua")
local ModuleRegistry = inject:Load("scripts/ModuleRegistry.lua")

local moduleMgr = ModuleManager.new()
local reg = ModuleRegistry.new({
    "scripts/RoStreet/module/Test.lua",
})

local loaderFunc = function(path)
    return inject:Load(path)
end

local listByCategory = reg:LoadAll(loaderFunc)
moduleMgr:RegisterFromList(listByCategory)

print("Heaven: Step - 4 (Loading Modules...)")

getgenv().ctx = {
    Inject = inject,
    moduleMgr = moduleMgr,
}

inject:Load("source/panel/mainGui/ClickGui.lua")
print("Heaven: Step - 5 (Loading Gui...)")
print("Heaven: Welcome")