local _, Cooldowns2 = ...
local Roster = FS.Roster

-------------------------------------------------------------------------------
-- Cooldowns index
--
-- The Index is the central cooldown tracking object
-- It provides the correct ordering for iteration by displays
-------------------------------------------------------------------------------

function Cooldowns2:InitializeIndex()
	self:RegisterMessage("FS_COOLDOWNS_GAINED")
	self:RegisterMessage("FS_COOLDOWNS_LOST")

	self:RegisterMessage("FS_COOLDOWNS_USED")
	self:RegisterMessage("FS_COOLDOWNS_BEGIN")
	self:RegisterMessage("FS_COOLDOWNS_READY")
	self:RegisterMessage("FS_COOLDOWNS_RESET")
	self:RegisterMessage("FS_COOLDOWNS_UPDATE")

	self.index = {}
	self.refresh_scheduled = nil
end

function Cooldowns2:FS_COOLDOWNS_GAINED(_, guid, spell)
	local cds = self.index[spell]

	if not cds then
		cds = {}
		self.index[spell] = cds
	end

	if self.player_available[guid] == nil then
		self.player_available[guid] = true
	end

	local cd = FS.Cooldowns:GetCooldown(guid, spell)
	table.insert(cds, cd)
	self:ScheduleIndexRefresh(spell, true)
end

function Cooldowns2:FS_COOLDOWNS_LOST(_, guid, spell)
	local cds = self.index[spell]
	if not cds then return end

	for idx, cd in ipairs(cds) do
		if cd.unit.guid == guid then
			table.remove(cds, idx)
			if #cds == 0 then
				self.index[spell] = nil
			end
			break
		end
	end

	self:ScheduleIndexRefresh(spell, true)
end

function Cooldowns2:FS_COOLDOWNS_USED(_, guid, spell, duration)
	if duration > 0 then
		self:ScheduleIndexRefresh(spell)
		C_Timer.After(duration, function() self:ScheduleIndexRefresh(spell) end)
	end
end

function Cooldowns2:FS_COOLDOWNS_BEGIN(_, guid, spell, cooldown)
	self:ScheduleIndexRefresh(spell)
end

function Cooldowns2:FS_COOLDOWNS_READY(_, guid, spell)
	self:ScheduleIndexRefresh(spell)
end

function Cooldowns2:FS_COOLDOWNS_UPDATE(_, guid, spell)
	self:ScheduleIndexRefresh(spell)
end

function Cooldowns2:FS_COOLDOWNS_RESET(_, guid, spell)
	self:ScheduleIndexRefresh(spell)
end

function Cooldowns2:ScheduleIndexRefresh(spell, rebuild)
	local value = rebuild and 2 or 1
	if self.refresh_scheduled then
		local prev_value = self.refresh_scheduled[spell]
		if not prev_value or prev_value < value then
			self.refresh_scheduled[spell] = value
		end
	else
		self.refresh_scheduled = { [spell] = value }
		C_Timer.After(0, function()
			local should_rebuild = false

			for spell, type in pairs(self.refresh_scheduled) do
				if type == 2 then should_rebuild = true end
				self:RefreshIndex(spell)
			end

			if not should_rebuild then
				for spell in pairs(self.refresh_scheduled) do
					self:RefreshDisplay(spell)
				end
			else
				self:RebuildAllGroups()
			end

			self.refresh_scheduled = nil
		end)
	end
end

function Cooldowns2:ScheduleIndexRefreshAll(rebuild)
	for spell in pairs(self.index) do
		self:ScheduleIndexRefresh(spell, rebuild)
	end
end

function Cooldowns2:RefreshIndex(spell)
	local cds = self.index[spell]
	if not cds then return end

	local ready_cache = setmetatable({}, {
		__index = function(self, key)
			local ready = key:IsReady()
			self[key] = ready
			return ready
		end
	})

	table.sort(cds, function(a, b)
		local ad_left, ad_total, ad_elapsed = a:Duration()
		local bd_left, bd_total, bd_elapsed = b:Duration()
		local a_active, b_active = ad_total ~= 0, bd_total ~= 0

		if a_active ~= b_active then
			return a_active
		elseif a_active then
			return ad_left < bd_left
		else
			local a_avail = self:IsPlayerAvailabe(a.unit.guid) and ready_cache[a]
			local b_avail = self:IsPlayerAvailabe(b.unit.guid) and ready_cache[b]

			if a_avail ~= b_avail then
				return a_avail
			elseif a_avail then
				local a_used = a:UsedCharges()
				local b_used = b:UsedCharges()
				if a_used ~= b_used then
					return a_used < b_used
				else
					return a:MaxCharges() > b:MaxCharges()
				end
			else
				return a:Cooldown() <  b:Cooldown()
			end
		end
	end)
end

function Cooldowns2:IndexHasSpell(spell)
	return self.index[spell] ~= nil
end

function Cooldowns2:IterateIndex(spell)
	local cds = self.index[spell]
	if not cds then return end
	return ipairs(cds)
end
