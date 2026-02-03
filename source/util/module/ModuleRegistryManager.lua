--!strict
-- ModuleRegistry.lua
-- Универсальный реестр модулей: хранит список путей и грузит def-таблицы через loader(path)

export type ModuleDef = {
    Name: string,
    Desc: string?,
Class: string?,
Category: string?, -- опционально
Settings: { any }?,
OnEnable: ((ctx: any) -> ())?,
OnDisable: ((ctx: any) -> ())?,
}

export type Loader = (path: string) -> any

export type Registry = {
_paths: { string },
_defsByName: { [string]: ModuleDef },

AddPath: (self: Registry, path: string) -> (),
RemovePath: (self: Registry, path: string) -> (),
ListPaths: (self: Registry) -> { string },

LoadAll: (self: Registry, loader: Loader) -> { [string]: { ModuleDef } },
LoadOne: (self: Registry, loader: Loader, path: string) -> (boolean, string?),

GetDef: (self: Registry, moduleName: string) -> ModuleDef?,
}

local ModuleRegistry = {}
ModuleRegistry.__index = ModuleRegistry

local function safeLoad(loader: Loader, path: string): (boolean, any)
local ok, res = pcall(loader, path)
return ok, res
end

local function normalizeCategory(def: any): string
if type(def) ~= "table" then return "Utility" end
if type(def.Category) == "string" and #def.Category > 0 then
return def.Category
end
-- если Category не задана, используем Utility
return "Utility"
end

local function isValidDef(def: any): boolean
return type(def) == "table" and type(def.Name) == "string" and #def.Name > 0
end

function ModuleRegistry.new(initialPaths: { string }?): Registry
local self = setmetatable({}, ModuleRegistry) :: any
self._paths = {}
self._defsByName = {}

if initialPaths then
for _, p in ipairs(initialPaths) do
table.insert(self._paths, p)
end
end

return self
end

function ModuleRegistry:AddPath(path: string)
if table.find(self._paths, path) then return end
table.insert(self._paths, path)
end

function ModuleRegistry:RemovePath(path: string)
local i = table.find(self._paths, path)
if not i then return end
table.remove(self._paths, i)
end

function ModuleRegistry:ListPaths(): { string }
local out = table.clone(self._paths)
table.sort(out)
return out
end

function ModuleRegistry:GetDef(moduleName: string): ModuleDef?
return self._defsByName[moduleName]
end

function ModuleRegistry:LoadOne(loader: Loader, path: string): (boolean, string?)
local ok, defOrErr = safeLoad(loader, path)
if not ok then
return false, ("load failed for %s: %s"):format(path, tostring(defOrErr))
end

local def = defOrErr
if not isValidDef(def) then
return false, ("bad module def in %s (expected table with Name)"):format(path)
end

-- сохраняем по имени (последний загруженный с тем же Name перезапишет)
self._defsByName[def.Name] = def :: any
return true, nil
end

function ModuleRegistry:LoadAll(loader: Loader): { [string]: { ModuleDef } }
self._defsByName = {}

for _, path in ipairs(self._paths) do
local ok, err = self:LoadOne(loader, path)
if not ok then
warn("ModuleRegistry: " .. tostring(err))
end
end

-- собираем в формат для ModuleManager:RegisterFromList
local byCat: { [string]: { ModuleDef } } = {}
for _, def in pairs(self._defsByName) do
local cat = normalizeCategory(def)
byCat[cat] = byCat[cat] or {}
table.insert(byCat[cat], def)
end

-- сортировка внутри категорий
for _, list in pairs(byCat) do
table.sort(list, function(a, b)
return a.Name < b.Name
end)
end

return byCat
end

return ModuleRegistry
