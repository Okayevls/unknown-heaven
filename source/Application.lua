local http = game:GetService("HttpService")

local success, data = pcall(function()
    return http:JSONDecode(game:HttpGet("https://api.github.com/repos/Okayevls/unknown-heaven/commits/main"))
end)

if success and data and data.sha then
    local sha = data.sha
    getgenv().LatestSHA = sha
    local url = string.format("https://raw.githubusercontent.com/Okayevls/unknown-heaven/%s/source/Bootstrap.lua?v=%s", sha, os.time())
    
    local ok, err = pcall(function()
        loadstring(game:HttpGet(url))()
    end)

    if not ok then
        warn("[Heaven]: Critical error during Bootstrap execution: " .. tostring(err))
    end
else
    warn("[Heaven]: Failed to fetch latest commit SHA. Check your internet or GitHub API limits.")
end