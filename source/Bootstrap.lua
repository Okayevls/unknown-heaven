local data = game:GetService("HttpService"):JSONDecode(game:HttpGet("https://api.github.com/repos/Okayevls/unknown-heaven/commits/main"))
local downloader = loadstring(game:HttpGet("https://raw.githubusercontent.com/Okayevls/unknown-heaven/"..data["sha"].."/source/util/other/FastDownloader.lua?v="..os.time()))()
local inject = downloader.new("Okayevls", "unknown-heaven", "main"):GetLatestSHA()

--Utility
local RenderUtil = inject:Load("source/util/render/RenderUtil.lua")

local ctx = {
    Inject = inject,
    Render = RenderUtil,
}

--Main
inject:Load("source/panel/loaderGui/LoaderPanel.lua", ctx)

print("Heaven: Welcome")