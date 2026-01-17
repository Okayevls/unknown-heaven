local data = game:GetService("HttpService"):JSONDecode(game:HttpGet("https://api.github.com/repos/Okayevls/unknown-heaven/commits/main"))
local downloader = loadstring(game:HttpGet("https://raw.githubusercontent.com/Okayevls/unknown-heaven/"..data["sha"].."/source/FastDownloader.lua?v="..os.time()))()
local inject = downloader.new("Okayevls", "unknown-heaven", "main"):GetLatestSHA()

--inject:Load("source/Main/Gui/GuiRenderer.lua")

print("Heaven: Welcome")