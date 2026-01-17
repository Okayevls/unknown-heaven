local HttpService = game:GetService("HttpService")

local GitHubLoader = {}
GitHubLoader.__index = GitHubLoader

function GitHubLoader.new(user, repo, branch)
    return setmetatable({
        user = user,
        repo = repo,
        branch = branch,
        sha = nil,
        cache = {}
    }, GitHubLoader)
end

function GitHubLoader:GetLatestSHA()
    local apiUrl = "https://api.github.com/repos/"..self.user.."/"..self.repo.."/commits/"..self.branch
    local data = HttpService:JSONDecode(game:HttpGet(apiUrl))
    self.sha = data.sha
    return self
end

function GitHubLoader:Raw(path)
    return "https://raw.githubusercontent.com/"..self.user.."/"..self.repo.."/"..self.sha.."/"..path.."?v="..os.time()
end

function GitHubLoader:LoadJSON(path)
    local url = self:Raw(path)
    local success, code = pcall(function()
        return game:HttpGet(url)
    end)

    if not success or not code then
        warn("[GitHubLoader] Failed to fetch JSON:", path)
        return nil
    end

    local ok, data = pcall(function()
        return HttpService:JSONDecode(code)
    end)

    if not ok then
        warn("[GitHubLoader] JSON decode failed:", path, data)
        return nil
    end

    return data
end

--function GitHubLoader:Load(path)
--    if self.cache[path] then
--        return self.cache[path]
--    end
--
--    local url = self:Raw(path)
--    local success, code = pcall(function()
--        return game:HttpGet(url)
--    end)
--
--    if not success or not code or code == "" then
--        warn("[GitHubLoader] ❌ Failed to fetch module:", path, url)
--        return nil
--    end
--
--    local func, err = loadstring(code)
--    if not func then
--        warn("[GitHubLoader] ❌ loadstring failed for:", path, err)
--        return nil
--    end
--
--    local module = func()
--    self.cache[path] = module
--    return module
--end

function GitHubLoader:Load(path, ...)
    if self.cache[path] then
        return self.cache[path]
    end

    local url = self:Raw(path)
    local success, code = pcall(function()
        return game:HttpGet(url)
    end)

    if not success or not code or code == "" then
        warn("[GitHubLoader] ❌ Failed to fetch module:", path, url)
        return nil
    end

    local func, err = loadstring(code)
    if not func then
        warn("[GitHubLoader] ❌ loadstring failed for:", path, err)
        return nil
    end

    local ok, moduleOrErr = pcall(function()
        return func(...)
    end)

    if not ok then
        warn("[GitHubLoader] ❌ module runtime error for:", path, moduleOrErr)
        return nil
    end

    self.cache[path] = moduleOrErr
    return moduleOrErr
end

return GitHubLoader
