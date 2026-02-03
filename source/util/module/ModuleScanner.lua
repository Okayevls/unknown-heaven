local ModuleScanner = {}
ModuleScanner.__index = ModuleScanner

local http = game:GetService("HttpService")

function ModuleScanner.new(repoOwner, repoName)
    local self = setmetatable({}, ModuleScanner)
    self.repoOwner = repoOwner
    self.repoName = repoName
    return self
end

function ModuleScanner:GetModules(project)
    local apiUrl = string.format(
            "https://api.github.com/repos/%s/%s/contents/scripts/%s/module",
            self.repoOwner, self.repoName, project
    )

    local moduleFiles = {}
    local success, content = pcall(function()
        return http:JSONDecode(game:HttpGet(apiUrl))
    end)

    if success and type(content) == "table" then
        for _, file in ipairs(content) do
            if file.type == "file" and file.name:match("%.lua$") then
                table.insert(moduleFiles, file.path)
            end
        end
    else
        warn("[Heaven Scanner]: Could not fetch modules for " .. tostring(project))
    end

    return moduleFiles
end

return ModuleScanner