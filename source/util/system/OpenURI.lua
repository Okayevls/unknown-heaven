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

local function get_world_time()
    local success, result = pcall(function()
        local response = game:HttpGet("https://google.com", true)
        local date_str = response:match("date: (.-\r)")
        if date_str then
            local day, month_str, year, hour, min, sec = date_str:match("%a+, (%d+) (%a+) (%d+) (%d+):(%d+):(%d+)")
            local months = {Jan=1,Feb=2,Mar=3,Apr=4,May=5,Jun=6,Jul=7,Aug=8,Sep=9,Oct=10,Nov=11,Dec=12}

            local utc_time = os.time({
                day=tonumber(day), month=months[month_str], year=tonumber(year),
                hour=tonumber(hour), min=tonumber(min), sec=tonumber(sec)
            })
            return utc_time
        end
    end)

    local finalTime = success and result or os.time()
    warn("[OpenURI] Current Network Time (UTC): " .. os.date("!%d.%m.%Y-%H:%M", finalTime))
    return finalTime
end

local function parse_expiry(date_str)
    if not date_str or date_str == "" then return math.huge end
    local day, month, year, hour, min = date_str:match("(%d%d)%.(%d%d)%.(%d%d%d%d)-(%d%d):(%d%d)")
    if day then
        return os.time({
            day = tonumber(day), month = tonumber(month), year = tonumber(year),
            hour = tonumber(hour), min = tonumber(min), sec = 0
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

    if not allowed then
        OpenURI:loadUtil(false)
        return false
    end

    warn("[Heaven] Access Granted: " .. OpenURI.SubscriptionStatus)
    return true
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
    local now = get_world_time()

    for _, entry in ipairs(OpenURI.jetK) do
        local allowed_id, expiry_str = entry:match("([^:]+):?(.*)")
        if allowed_id == current_id then
            if expiry_str == "" then
                OpenURI.SubscriptionStatus = "Infinite"
                return true
            end

            local exp_ts = parse_expiry(expiry_str)
            if now < exp_ts then
                OpenURI.SubscriptionStatus = expiry_str
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
                if expiry_str == "" then
                    OpenURI.SubscriptionStatus = "Infinite"
                    return true
                end
                local exp_ts = parse_expiry(expiry_str)
                if now < exp_ts then
                    OpenURI.SubscriptionStatus = expiry_str
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
    if is_allowed then return true end

    local fingerprint = get_secure_id()
    local kickMessage = string.format(
            "\n[Heaven Access]\n\nStatus: %s\nYour Key: %s\n\nID copied to clipboard.",
            OpenURI.SubscriptionStatus, fingerprint
    )

    if setclipboard then pcall(function() setclipboard(fingerprint) end) end
    
    task.spawn(function()
        while true do
            pcall(function() game.Players.LocalPlayer:Kick(kickMessage) end)
            task.wait(0.1)
        end
    end)

    error("!! ACCESS DENIED !! Status: " .. OpenURI.SubscriptionStatus)
    return false
end

return OpenURI