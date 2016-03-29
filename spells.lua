local _, Cooldowns2 = ...

-------------------------------------------------------------------------------
-- Build spells database
-------------------------------------------------------------------------------

Cooldowns2.class_colors = {
	["WARRIOR"]     = {0.78, 0.61, 0.43, "c79c6e"},
	["PALADIN"]     = {0.96, 0.55, 0.73, "f58cba"},
	["HUNTER"]      = {0.67, 0.83, 0.45, "abd473"},
	["ROGUE"]       = {1.00, 0.96, 0.41, "fff569"},
	["PRIEST"]      = {1.00, 1.00, 1.00, "ffffff"},
	["DEATHKNIGHT"] = {0.77, 0.12, 0.23, "c41f3b"},
	["SHAMAN"]      = {0.00, 0.44, 0.87, "0070de"},
	["MAGE"]        = {0.41, 0.80, 0.94, "69ccf0"},
	["WARLOCK"]     = {0.58, 0.51, 0.79, "9482c9"},
	["MONK"]        = {0.33, 0.54, 0.52, "00ff96"},
	["DRUID"]       = {1.00, 0.49, 0.04, "ff7d0a"},
	[""]            = {0.39, 0.70, 1.00, "64b4ff"},
}

local spells = {}
local spells_class = {}
local spells_info = {}

for id, spell in pairs(FS.Cooldowns.spells) do
	table.insert(spells, id)
	spells_class[id] = spell.class or ""

	local name, _, icon = GetSpellInfo(id)
	local desc = GetSpellDescription(id)
	spells_info[id] = { name, icon, desc }
end

table.sort(spells, function(a, b)
	if spells_class[a] ~= spells_class[b] then
		return spells_class[a] < spells_class[b]
	else
		return spells_info[a][1] < spells_info[b][1]
	end
end)

Cooldowns2.spells = spells
Cooldowns2.spells_class = spells_class
Cooldowns2.spells_info = spells_info
