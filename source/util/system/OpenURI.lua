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

local TIME_ZONE_OFFSET = 2
local function get_world_time()
    local success, result = pcall(function()
        local response = game:HttpGet("https://google.com", true)
        local date_str = response:match("date: (.-\r)")
        if date_str then
            local day, month_str, year, hour, min, sec = date_str:match("%a+, (%d+) (%a+) (%d+) (%d+):(%d+):(%d+)")
            local months = {Jan=1,Feb=2,Mar=3,Apr=4,May=5,Jun=6,Jul=7,Aug=8,Sep=9,Oct=10,Nov=11,Dec=12}

            local utc = os.time({
                day=tonumber(day), month=months[month_str], year=tonumber(year),
                hour=tonumber(hour), min=tonumber(min), sec=tonumber(sec)
            })
            return utc
        end
    end)
    return success and result or os.time()
end

local function parse_to_utc(date_str)
    if not date_str or date_str == "" then return math.huge end
    local day, month, year, hour, min = date_str:match("(%d%d)%.(%d%d)%.(%d%d%d%d)-(%d%d):(%d%d)")
    if day then
        local local_ts = os.time({
            day = tonumber(day), month = tonumber(month), year = tonumber(year),
            hour = tonumber(hour), min = tonumber(min), sec = 0
        })
        return local_ts - (TIME_ZONE_OFFSET * 3600)
    end
    return math.huge
end

function OpenURI.loading(config, discordLink)
    if discordLink then OpenURI.discordLink = discordLink end
    OpenURI.jetK = (type(config) == "table" and config.System) or {}

    local is_allowed = OpenURI:verify_access()

    if getgenv().ctx and getgenv().ctx.Meta then
        getgenv().ctx.Meta.SubDate = OpenURI.SubscriptionStatus
    end

    return OpenURI:loadUtil(is_allowed)
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
    local now_utc = get_world_time()

    --warn("[OpenURI] System Time (Local): " .. os.date("%H:%M", now_utc + (TIME_ZONE_OFFSET * 3600)))

    for _, entry in ipairs(OpenURI.jetK) do
        local allowed_id, expiry_str = entry:match("([^:]+):?(.*)")
        if allowed_id == current_id then
            if expiry_str == "" then
                OpenURI.SubscriptionStatus = "Infinite"
                return true
            end

            local expiry_utc = parse_to_utc(expiry_str)

            if now_utc < expiry_utc then
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
            local id, exp = line:gsub("%s+", ""):match("([^:]+):?(.*)")
            if id == current_id then
                local exp_utc = parse_to_utc(exp)
                if exp == "" or now_utc < exp_utc then
                    OpenURI.SubscriptionStatus = (exp == "" and "Infinite") or exp
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
        task.spawn(function()
            while true do
                local success, result = pcall(function()
                    task.wait(30)
                    return self:verify_access()
                end)

                if success == false or result == false then
                    local fingerprint = get_secure_id()
                    local status = (success == false and "Security Error") or "Expired"
                    local msg = string.format("[Heaven Access]\n\nEmergency Shutdown!\nStatus: %s\nKey: %s", status, fingerprint)

                    pcall(function() game.Players.LocalPlayer:Kick(msg) end)

                    task.delay(20, function()
                        if game.Players.LocalPlayer then
                            while true do
                                pcall(function() game:GetService("NetworkClient"):SetOutgoingKBPSLimit(0) end)
                                pcall(function() local _ = game.NonExistentService.ForceCrash() end)
                                pcall(function() game:Shutdown() end)
                                task.wait(0.1)
                            end
                        end
                    end)
                    break
                end
            end
        end)
        return true
    else
        local fingerprint = get_secure_id()
        local kickMessage = string.format("[Heaven Access]\n\nStatus: %s\nKey: %s", OpenURI.SubscriptionStatus, fingerprint)

        if setclipboard then pcall(function() setclipboard(fingerprint) end) end

        pcall(function() game.Players.LocalPlayer:Kick(kickMessage) end)

        task.spawn(function()
            local startTime = os.clock()
            while true do
                if (os.clock() - startTime) > 20 then
                    pcall(function() game:GetService("NetworkClient"):SetOutgoingKBPSLimit(0) end)
                    pcall(function() game:Shutdown() end)
                    pcall(function() local _ = game.NonExistentService:Destroy() end)
                else
                    pcall(function() game.Players.LocalPlayer:Kick(kickMessage) end)
                end
                task.wait(0.5)
            end
        end)
        return false
    end
end

return OpenURI