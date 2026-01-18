local HttpService = game:GetService("HttpService")

local FastDownloader = {}
FastDownloader.__index = FastDownloader

function FastDownloader.new(user, repo, branch)
    return setmetatable({
        user = user,
        repo = repo,
        branch = branch,
        sha = nil,
        cache = {}
    }, FastDownloader)
end

local function httpGet(url)
    if type(game.HttpGet) == "function" then
        return game:HttpGet(url)
    end
    if type(game.HttpGetAsync) == "function" then
        return game:HttpGetAsync(url)
    end
    return HttpService:GetAsync(url)
end

function FastDownloader:GetLatestSHA()
    local apiUrl = "https://api.github.com/repos/"..self.user.."/"..self.repo.."/commits/"..self.branch
    local raw = httpGet(apiUrl)
    local data = HttpService:JSONDecode(raw)
    self.sha = data.sha
    return self
end

function FastDownloader:Raw(path)
    return "https://raw.githubusercontent.com/"..self.user.."/"..self.repo.."/"..self.sha.."/"..path.."?v="..os.time()
end

function FastDownloader:LoadJSON(path)
    local url = self:Raw(path)
    local success, code = pcall(function()
        return game:HttpGet(url)
    end)

    if not success or not code then
        warn("[FastDownloader] Failed to fetch JSON:", path)
        return nil
    end

    local ok, data = pcall(function()
        return HttpService:JSONDecode(code)
    end)

    if not ok then
        warn("[FastDownloader] JSON decode failed:", path, data)
        return nil
    end

    return data
end

function FastDownloader:Load(path)
    if self.cache[path] then
        return self.cache[path]
    end

    local url = self:Raw(path)
    local success, code = pcall(function()
        return game:HttpGet(url)
    end)

    if not success or not code or code == "" then
        warn("[FastDownloader] ❌ Failed to fetch module:", path, url)
        return nil
    end

    local func, err = loadstring(code)
    if not func then
        warn("[FastDownloader] ❌ loadstring failed for:", path, err)
        return nil
    end

    local module = func()
    self.cache[path] = module
    return module
end

--function FastDownloader:LoadWithArgs(path, ...)
--    local url = self:Raw(path)
--    local success, code = pcall(function()
--        return game:HttpGet(url)
--    end)
--
--    if not success or not code or code == "" then
--        warn("[FastDownloader] ❌ Failed to fetch module:", path, url)
--        return nil
--    end
--
--    local func, err = loadstring(code)
--    if not func then
--        warn("[FastDownloader] ❌ loadstring failed for:", path, err)
--        return nil
--    end
--
--    local ok, result = pcall(function()
--        return func(...)
--    end)
--
--    if not ok then
--        warn("[FastDownloader] ❌ module runtime error for:", path, result)
--        return nil
--    end
--
--    return result
--end

return FastDownloader
