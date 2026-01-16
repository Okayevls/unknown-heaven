local data = game:GetService("HttpService"):JSONDecode(game:HttpGet("https://api.github.com/repos/Okayevls/unknown-heaven/commits/main"))
local rawUrl = "https://raw.githubusercontent.com/Okayevls/unknown-heaven/"..data["sha"].."/source/Bootstrap.lua?v="..os.time()
loadstring(game:HttpGet(rawUrl))()