local GlobalSharedStorage = {}

export type Bind =
{ kind: "KeyCode", code: Enum.KeyCode }
        | { kind: "UserInputType", code: Enum.UserInputType }

export type SettingDef =
    { Type: "Boolean", Name: string, Default: boolean? }
    | { Type: "Slider", Name: string, Default: number?, Min: number, Max: number, Step: number? }
    | { Type: "ModeSetting", Name: string, Default: string?, Options: { string } }
    | { Type: "MultiBoolean", Name: string, Default: { [string]: boolean }? }
    | { Type: "BindSetting", Name: string, Default: Bind? }
    | { Type: "String", Name: string, Default: string? }

export type ModuleCtx = {
   Category: string,
   Name: string,
   Class: string?,

   GetSetting: (self: ModuleCtx, settingName: string) -> any,
   SetSetting: (self: ModuleCtx, settingName: string, value: any) -> (),
   GetSettingData: (self: ModuleCtx, settingName: string) -> SettingDef?,

   Shared: { [string]: any },
   SetEnabled: (self: ModuleCtx, enabled: boolean) -> (),
}

export type ModuleDef = {
   Name: string,
   Desc: string?,
   Class: string?,
   Settings: { SettingDef },

   AlwaysEnabled: boolean?,
   OnEnable: ((ctx: ModuleCtx) -> ())?,
   OnDisable: ((ctx: ModuleCtx) -> ())?,
}

export type ModuleState = {
   Enabled: boolean,
   Bind: Bind?,
   Settings: { [string]: any },
   Definition: ModuleDef,
}

export type ChangedPayload = {
   kind: "Enabled" | "Bind" | "Setting" | "Register" | "Reset",
   category: string,
   moduleName: string,
   key: string?,
   value: any,
}

type CategoryMap = { [string]: { [string]: ModuleState } }

local ModuleManager = {}
ModuleManager.__index = ModuleManager

-- ========= utils =========

local function deepCopy(v: any): any
if type(v) ~= "table" then
return v
end
local out = {}
for k, vv in pairs(v :: any) do
out[k] = deepCopy(vv)
end
return out
end

local function clamp(n: number, mn: number, mx: number): number
if n < mn then return mn end
if n > mx then return mx end
return n
end

local function roundToStep(v: number, mn: number, step: number): number
local x = (v - mn) / step
local r = math.floor(x + 0.5)
return mn + r * step
end

local function validateAndNormalizeSetting(def: SettingDef, value: any): any
if def.Type == "Boolean" then
   return (value == true)
elseif def.Type == "String" then
   return tostring(value or "")
elseif def.Type == "BindSetting" then
if type(value) == "table" and value.kind and value.code then
return value
end
return def.Default
elseif def.Type == "ModeSetting" then
   local options = def.Options
   local str = tostring(value)

   if table.find(options, str) ~= nil then
       return str
   end

if #options == 0 then
return tostring(def.Default or "")
end

local d = def.Default
if d and table.find(options, d) ~= nil then
return d
end

return options[1]

elseif def.Type == "Slider" then
local num = tonumber(value)
if num == nil then
num = def.Default
end
if num == nil then
num = def.Min
end

num = clamp(num, def.Min, def.Max)

local step = def.Step or 1
if step <= 0 then
step = 1
end

num = roundToStep(num, def.Min, step)
num = clamp(num, def.Min, def.Max)

local stabilized = tonumber(string.format("%.6f", num))
return stabilized or num

elseif def.Type == "MultiBoolean" then
local out: { [string]: boolean } = {}
local src = (type(value) == "table") and (value :: any) or {}
local defaults = def.Default or {}

for k, dv in pairs(defaults) do
if src[k] == true then
out[k] = true
elseif src[k] == false then
out[k] = false
else
out[k] = (dv == true)
end
end

return out
end

return value
end

local function buildDefaultSettings(defs: { SettingDef }): { [string]: any }
local settings: { [string]: any } = {}
for _, s in ipairs(defs) do
local rawDefault: any = nil

if s.Type == "MultiBoolean" then
rawDefault = deepCopy(s.Default or {})
else
rawDefault = (s :: any).Default
end

settings[s.Name] = validateAndNormalizeSetting(s, rawDefault)
end
return settings
end

local function indexSettingDefs(defs: { SettingDef }): { [string]: SettingDef }
local map: { [string]: SettingDef } = {}
for _, s in ipairs(defs) do
map[s.Name] = s
end
return map
end

-- ========= ctor =========

export type ModuleManager = {
     _categories: CategoryMap,
     _ChangedEvent: BindableEvent,
     Changed: RBXScriptSignal,

     RegisterFromList: (self: ModuleManager, modulesByCategory: { [string]: { ModuleDef } }) -> (),
     GetCategories: (self: ModuleManager) -> { string },
     GetModuleDefs: (self: ModuleManager, categoryName: string) -> { ModuleDef },
     GetState: (self: ModuleManager, categoryName: string, moduleName: string) -> ModuleState?,
     GetSetting: (self: ModuleManager, categoryName: string, moduleName: string, settingName: string) -> any,
     SetSetting: (self: ModuleManager, categoryName: string, moduleName: string, settingName: string, value: any) -> (),
     SetEnabled: (self: ModuleManager, categoryName: string, moduleName: string, enabled: boolean) -> (),
     Toggle: (self: ModuleManager, categoryName: string, moduleName: string) -> (),
     SetBind: (self: ModuleManager, categoryName: string, moduleName: string, bind: Bind?) -> (),
     ResetModule: (self: ModuleManager, categoryName: string, moduleName: string) -> (),
     ResetCategory: (self: ModuleManager, categoryName: string) -> (),
}

function ModuleManager.new(): ModuleManager
local self = setmetatable({}, ModuleManager) :: any
(self :: any)._categories = {} :: CategoryMap
(self :: any)._ChangedEvent = Instance.new("BindableEvent") :: BindableEvent
(self :: any).Changed = ((self :: any)._ChangedEvent.Event) :: RBXScriptSignal
return (self :: any) :: ModuleManager
end


local function makeCtx(mgr: ModuleManager, categoryName: string, moduleName: string): ModuleCtx
local st = mgr:GetState(categoryName, moduleName)

local ctx: ModuleCtx = {
Category = categoryName,
Name = moduleName,
Class = if st then st.Definition.Class else nil,
Shared = GlobalSharedStorage,

GetSetting = function(self: ModuleCtx, settingName: string)
    return mgr:GetSetting(categoryName, moduleName, settingName)
end,

SetSetting = function(self: ModuleCtx, settingName: string, value: any)
    mgr:SetSetting(categoryName, moduleName, settingName, value)
end,

SetEnabled = function(self, enabled: boolean)
    mgr:SetEnabled(categoryName, moduleName, enabled)
end,

GetSettingData = function(self: ModuleCtx, settingName: string): SettingDef?
   local state = mgr:GetState(categoryName, moduleName)
   local settings = if state then state.Definition.Settings else nil

       if settings then
          for _, sDef in ipairs(settings) do
              if sDef.Name == settingName then
                  return sDef
              end
          end
       end
       return nil
   end,
   }
   return ctx
end

-- ========= registration =========

function ModuleManager:RegisterFromList(modulesByCategory: { [string]: { ModuleDef } })
for categoryName, list in pairs(modulesByCategory) do
self._categories[categoryName] = self._categories[categoryName] or {}
local cat = self._categories[categoryName]

for _, def in ipairs(list) do
local existing = cat[def.Name]

if existing then
-- обновляем дефинишн, но НЕ перетираем включение/бинды/настройки
existing.Definition = def

-- добавляем недостающие настройки и нормализуем существующие по новым дефам
local defIndex = indexSettingDefs(def.Settings or {})
local defaultSettings = buildDefaultSettings(def.Settings or {})

for sName, sDef in pairs(defIndex) do
local cur = existing.Settings[sName]
if cur == nil then
existing.Settings[sName] = defaultSettings[sName]
else
existing.Settings[sName] = validateAndNormalizeSetting(sDef, cur)
end
end

if def.AlwaysEnabled then
task.defer(function()
self:SetEnabled(categoryName, def.Name, true)
end)
end

-- (опционально) удалять лишние настройки не будем (чтобы не терять данные)

else
local settings = buildDefaultSettings(def.Settings or {})
cat[def.Name] = {
Enabled = false,
Bind = (def :: any).Bind or nil,
Settings = settings,
Definition = def,
}

self._ChangedEvent:Fire({
kind = "Register",
category = categoryName,
moduleName = def.Name,
key = nil,
value = true,
} :: ChangedPayload)
end
end
end
end

-- ========= GUI API =========

function ModuleManager:GetCategories(): { string }
local out: { string } = {}
for name in pairs(self._categories) do
table.insert(out, name)
end
table.sort(out)
return out
end

function ModuleManager:GetModuleDefs(categoryName: string): { ModuleDef }
local cat = self._categories[categoryName]
if not cat then
return {}
end

local out: { ModuleDef } = {}
for _, st in pairs(cat) do
table.insert(out, st.Definition)
end

table.sort(out, function(a, b)
return a.Name < b.Name
end)

return out
end

function ModuleManager:GetState(categoryName: string, moduleName: string): ModuleState?
local cat = self._categories[categoryName]
if not cat then return nil end
return cat[moduleName]
end

function ModuleManager:GetSetting(categoryName: string, moduleName: string, settingName: string): any
local st = self:GetState(categoryName, moduleName)
if not st then return nil end
return st.Settings[settingName]
end

function ModuleManager:SetSetting(categoryName: string, moduleName: string, settingName: string, value: any)
local st = self:GetState(categoryName, moduleName)
if not st then return end

local defSettings = st.Definition.Settings or {}
local sDef: SettingDef? = nil
for _, s in ipairs(defSettings) do
if s.Name == settingName then
sDef = s
break
end
end
if not sDef then return end

local normalized = validateAndNormalizeSetting(sDef, value)
st.Settings[settingName] = normalized

self._ChangedEvent:Fire({
kind = "Setting",
category = categoryName,
moduleName = moduleName,
key = settingName,
value = normalized,
} :: ChangedPayload)
end

function ModuleManager:SetEnabled(categoryName: string, moduleName: string, enabled: boolean)
local st = self:GetState(categoryName, moduleName)
if not st then return end

if st.Definition.AlwaysEnabled and enabled == false then
return
end

local newValue = (enabled == true)
if st.Enabled == newValue then return end

st.Enabled = newValue

-- callbacks (безопасно)
local ctx = makeCtx(self, categoryName, moduleName)
if newValue then
local f = st.Definition.OnEnable
if f then
local ok, err = pcall(f, ctx)
if not ok then
warn(("Module %s/%s OnEnable error: %s"):format(categoryName, moduleName, tostring(err)))
end
end
else
local f = st.Definition.OnDisable
if f then
local ok, err = pcall(f, ctx)
if not ok then
warn(("Module %s/%s OnDisable error: %s"):format(categoryName, moduleName, tostring(err)))
end
end
end

self._ChangedEvent:Fire({
kind = "Enabled",
category = categoryName,
moduleName = moduleName,
key = nil,
value = st.Enabled,
} :: ChangedPayload)
end

function ModuleManager:Toggle(categoryName: string, moduleName: string)
local st = self:GetState(categoryName, moduleName)
if not st then return end
self:SetEnabled(categoryName, moduleName, not st.Enabled)
end

local function validateBind(bind: Bind?): boolean
if bind == nil then
return true
end

-- typeof(Enum.KeyCode.A) == "EnumItem"
if bind.kind == "KeyCode" then
local item = bind.code
if typeof(item) ~= "EnumItem" then return false end
if item.EnumType ~= Enum.KeyCode then return false end
return true
elseif bind.kind == "UserInputType" then
local item = bind.code
if typeof(item) ~= "EnumItem" then return false end
if item.EnumType ~= Enum.UserInputType then return false end
return true
end

return false
end

function ModuleManager:SetBind(categoryName: string, moduleName: string, bind: Bind?)
local st = self:GetState(categoryName, moduleName)
if not st then return end

if not validateBind(bind) then
return
end

st.Bind = bind

self._ChangedEvent:Fire({
kind = "Bind",
category = categoryName,
moduleName = moduleName,
key = nil,
value = bind,
} :: ChangedPayload)
end

-- ========= resets =========

function ModuleManager:ResetModule(categoryName: string, moduleName: string)
local st = self:GetState(categoryName, moduleName)
if not st then return end

-- FIX: если был включён — выключаем через SetEnabled, чтобы вызвался OnDisable
if st.Enabled then
self:SetEnabled(categoryName, moduleName, false)
else
st.Enabled = false
end

st.Bind = nil
st.Settings = buildDefaultSettings(st.Definition.Settings or {})

self._ChangedEvent:Fire({
kind = "Reset",
category = categoryName,
moduleName = moduleName,
key = nil,
value = true,
} :: ChangedPayload)
end

function ModuleManager:ResetCategory(categoryName: string)
local cat = self._categories[categoryName]
if not cat then return end
for moduleName in pairs(cat) do
self:ResetModule(categoryName, moduleName)
end
end

return ModuleManager
