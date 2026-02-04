local _gethwid = gethwid
local _identify = identifyexecutor
local _crypt = crypt

local _list = "https://gist.githubusercontent.com/Okayevls/ab7b1a5639c7ee25e58593c93eb832d9/raw/gistfile1.txt"

local _k = {"TH6ERT", "SE1TC", "OPT0I", "DH6YR", "TG9HE", "SBT8YH", "AZ7SQ", "HGH6YR","NB4GH", "WS1FDT", "JU5KUE", "WA4SGH","JU9RW", "ZX7CT", "UU1KU", "SAD6WAG"}
local secret_key = table.concat(_k) .. "10101010101010101"

local OpenURI = {}
OpenURI.__index = OpenURI
OpenURI.jetK = {}
OpenURI.discordLink = {}

function OpenURI.loading(config, discordLink)
    OpenURI.discordLink = discordLink
    if type(config) == "table" and config.System then
        OpenURI.jetK = config.System
    end

    return OpenURI:loadUtil()
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

    for _, sys_id in ipairs(OpenURI.jetK) do
        if sys_id == current_id then
            return true
        end
    end

    local success, content = pcall(function()
        return game:HttpGet(_list)
    end)

    if success then
        for line in content:gmatch("[^\r\n]+") do
            if line:gsub("%s+", "") == current_id then
                return true
            end
        end
    else
        warn("[OpenURI] Failed to fetch remote whitelist")
    end

    return false
end

function OpenURI:loadUtil()
    if self:verify_access() then
        return true
    else
        local fingerprint = get_secure_id()
        local player = game:GetService("Players").LocalPlayer
        if setclipboard then
            setclipboard("|"..fingerprint.."|")
            if player then
                player:Kick("\n[Access Denied]\nYour Key has been copied to clipboard.\nSend it to discord ticket.\nID: 404")
            end
        else
            player:Kick("\n[Access Denied]\nYour Key has been not copied to clipboard.\nSend ID to discord ticket.\nError: 109")
        end

        return false
    end
end

return OpenURI