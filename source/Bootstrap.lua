local data = game:GetService("HttpService"):JSONDecode(game:HttpGet("https://api.github.com/repos/Okayevls/unknown-heaven/commits/main"))
print("Heaven: Step - 1 (Loading Data...)")
local downloader = loadstring(game:HttpGet("https://raw.githubusercontent.com/Okayevls/unknown-heaven/"..data["sha"].."/source/util/other/FastDownloader.lua?v="..os.time()))()
print("Heaven: Step - 1 (Loading Utility...)")

local inject = downloader.new("Okayevls", "unknown-heaven", "main"):GetLatestSHA()
print("Heaven: Step - 2 (Loading Injector...)")

--Utility
local RenderUtil = inject:Load("source/util/render/RenderUtil.lua")
local Service = inject:Load("source/util/offsets/Service.lua")
print("Heaven: Step - 3 (Loading Utility...)")

getgenv().ctx = {
    Inject = inject,
    Render = RenderUtil,
    Service = Service,
}

--Main
inject:Load("source/panel/loaderGui/LoaderPanel.lua")
print("Heaven: Step - 4 (Loading Main...)")

print("Heaven: Welcome")