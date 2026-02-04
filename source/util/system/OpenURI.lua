local _gethwid = gethwid
local _identify = identifyexecutor
local _crypt = crypt

local _list = "https://gist.githubusercontent.com/Okayevls/ab7b1a5639c7ee25e58593c93eb832d9/raw/gistfile1.txt"

local _k = {"TH6ERT", "SE1TC", "OPT0I", "DH6YR", "TG9HE", "SBT8YH", "AZ7SQ", "HGH6YR","NB4GH", "WS1FDT", "JU5KUE", "WA4SGH","JU9RW", "ZX7CT", "UU1KU", "SAD6WAG"}
local secret_key = table.concat(_k) .. "10101010101010101"

local OpenURI = {}
OpenURI.__index = OpenURI
OpenURI.jetK = {}
OpenURI.discordLink = "https://discord.gg/R7ABPb2f"
OpenURI.SubscriptionStatus = "None"

local function parse_expiry(date_str)
    if not date_str or date_str == "" then return math.huge end

    local day, month, year, hour, min = date_str:match("(%d%d)%.(%d%d)%.(%d%d%d%d)-(%d%d):(%d%d)")
    if day then
        return os.time({
            day = tonumber(day),
            month = tonumber(month),
            year = tonumber(year),
            hour = tonumber(hour),
            min = tonumber(min)
        })
    end
    return math.huge
end

function OpenURI.loading(config, discordLink)
    if discordLink then OpenURI.discordLink = discordLink end
    if type(config) == "table" and config.System then
        OpenURI.jetK = config.System
    end

    local allowed = OpenURI:verify_access()
    local _ctx = getgenv().ctx

    if _ctx and _ctx.Meta then
        _ctx.Meta.SubDate = OpenURI.SubscriptionStatus
    end

    return OpenURI:loadUtil(allowed)
end

local function get_env_score()
    local score = 0
    local checks = {
        getgenv, getreg, getrenv, getgc, getinstances,
        getconnections, setclipboard, writefile, make_readonly
    }
    for i, func in ipairs(checks) do
        if func then score = score + (2 ^ i) end
    end
    return tostring(score)
end

local function get_hardware_info()
    local info = {}
    pcall(function()
        if _gethwid then table.insert(info, tostring(_gethwid())) end
    end)
    if _identify then
        local name, ver = _identify()
        table.insert(info, tostring(name))
    end
    table.insert(info, get_env_score())
    table.insert(info, _VERSION)
    return table.concat(info, "::")
end

local function get_secure_id()
    local _raw = get_hardware_info()
    local _data = string.format("%s:%s:%s", secret_key:sub(1, 10), _raw, secret_key)

    if _crypt and _crypt.hash then
        local mthd = (_crypt.hash and "sha256") or "sha1"
        return _crypt.hash(_data, mthd)
    end

    local b64 = game:GetService("HttpService"):UrlEncode(_raw)
    return "ALT-" .. string.reverse(b64):sub(1, 32)
end

function OpenURI:verify_access()
    local current_id = get_secure_id()
    local now = os.time()

    for _, entry in ipairs(OpenURI.jetK) do
        local allowed_id, expiry_str = entry:match("([^:]+):?(.*)")
        if allowed_id == current_id then
            local exp_ts = parse_expiry(expiry_str)
            if now < exp_ts then
                OpenURI.SubscriptionStatus = (expiry_str ~= "" and expiry_str) or "Infinite"
                return true
            else
                OpenURI.SubscriptionStatus = "Expired"
                return false
            end
        end
    end

    local success, content = pcall(function() return game:HttpGet(_list) end)
    if success then
        for line in content:gmatch("[^\r\n]+") do
            local clean_line = line:gsub("%s+", "")
            local allowed_id, expiry_str = clean_line:match("([^:]+):?(.*)")
            if allowed_id == current_id then
                local exp_ts = parse_expiry(expiry_str)
                if now < exp_ts then
                    OpenURI.SubscriptionStatus = (expiry_str ~= "" and expiry_str) or "Infinite"
                    return true
                else
                    OpenURI.SubscriptionStatus = "Expired"
                    return false
                end
            end
        end
    end

    OpenURI.SubscriptionStatus = "Not Whitelisted"
    return false
end

function OpenURI:loadUtil(forced_status)
    local is_allowed = (forced_status ~= nil) and forced_status or self:verify_access()

    if is_allowed then
        warn("[Heaven] Access Granted. Time: " .. OpenURI.SubscriptionStatus)
        return true
    else
        local fingerprint = get_secure_id()
        local player = game:GetService("Players").LocalPlayer

        local status_info = OpenURI.SubscriptionStatus or "Access Denied"
        local kickMessage = string.format(
                "\n[Heaven Access]\n\nStatus: %s\nYour Key: %s\n\nInvite: %s\n\nID has been copied to clipboard.",
                status_info, fingerprint, OpenURI.discordLink
        )
        
        if setclipboard then pcall(function() setclipboard(fingerprint) end) end

        task.spawn(function()
            while task.wait(0.1) do
                if player then
                    player:Kick(kickMessage)
                end
                pcall(function()
                    game:Shutdown()
                end)
            end
        end)

        task.wait(0.5)
        error("!! ACCESS DENIED !! Status: " .. status_info)
        return false
    end
end

return OpenURI