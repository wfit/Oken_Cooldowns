local _, Cooldowns2 = ...

-------------------------------------------------------------------------------
-- Build spells database
-------------------------------------------------------------------------------

local class_colors = {
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
	["DRUID"]       = {1.00, 0.49, 0.04, "ff7d0a" },
	["DEMONHUNTER"] = {0.64, 0.19, 0.79, "a330c9" },
	[""]            = {0.39, 0.70, 1.00, "64b4ff"},
}

function Cooldowns2:GetClassColor(class, as_hex)
	local colors = class and class_colors[class] or class_colors[""]
	if as_hex then
		return colors[4]
	else
		return unpack(colors)
	end
end

-------------------------------------------------------------------------------
-- Build spells database
-------------------------------------------------------------------------------

local spells = {}
local spell_class = {}
local spell_data = {}

for id, spell in FS.Cooldowns:IterateSpells() do
	table.insert(spells, id)
	spell_class[id] = spell.class or ""

	local name, _, icon = GetSpellInfo(id)
	local desc = GetSpellDescription(id)
	spell_data[id] = { name, spell.icon or icon, desc }
end

table.sort(spells, function(a, b)
	if spell_class[a] ~= spell_class[b] then
		return spell_class[a] < spell_class[b]
	else
		return spell_data[a][1] < spell_data[b][1]
	end
end)

Cooldowns2.spells = spells
Cooldowns2.spell_class = spell_class
Cooldowns2.spell_data = spell_data
