local http = game:GetService("HttpService")
local success, data = pcall(function()
    return http:JSONDecode(game:HttpGet("https://api.github.com/repos/Okayevls/unknown-heaven/commits/main"))
end)

if success and data["sha"] then
    getgenv().LatestSHA = data["sha"]
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Okayevls/unknown-heaven/"..data["sha"].."/source/Bootstrap.lua?v="..os.time()))()
else
    warn("Heaven: Failed to fetch latest commit SHA")
end