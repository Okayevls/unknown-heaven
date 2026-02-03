local data = game:GetService("HttpService"):JSONDecode(game:HttpGet("https://api.github.com/repos/Okayevls/unknown-heaven/commits/main"))
print("Heaven: Step - 1 (Loading Data...)")
local downloader = loadstring(game:HttpGet("https://raw.githubusercontent.com/Okayevls/unknown-heaven/"..data["sha"].."/source/util/other/FastDownloader.lua?v="..os.time()))()
print("Heaven: Step - 2 (Loading Utility...)")

local inject = downloader.new("Okayevls", "unknown-heaven", "main"):GetLatestSHA()
print("Heaven: Step - 3 (Loading Injector...)")

local ModuleManager = inject:Load("scripts/ModuleManager.lua")
local moduleList = inject:Load("scripts/ModuleList.lua")
print("Heaven: Step - 4 (Loading Modules...)")

local moduleMgr = ModuleManager.new()

getgenv().ctx = {
    Inject = inject,
    moduleMgr = moduleMgr,
}

moduleMgr:RegisterFromList(moduleList)

inject:Load("source/panel/mainGui/ClickGui.lua")
print("Heaven: Step - 5 (Loading Gui...)")

print("Heaven: Welcome")