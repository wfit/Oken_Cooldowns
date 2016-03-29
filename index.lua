local _, Cooldowns2 = ...
local Roster = FS.Roster

-------------------------------------------------------------------------------
-- Cooldowns index
-------------------------------------------------------------------------------

function Cooldowns2:InitializeIndex()
	self:RegisterMessage("FS_COOLDOWNS_GAINED")
	self:RegisterMessage("FS_COOLDOWNS_LOST")

	self:RegisterMessage("FS_COOLDOWNS_USED")
	self:RegisterMessage("FS_COOLDOWNS_READY")
	self:RegisterMessage("FS_COOLDOWNS_UPDATE")

	self.cooldowns_idx = {}
	self.refresh_scheduled = nil
end

function Cooldowns2:FS_COOLDOWNS_GAINED(_, guid, spell)
	local cds = self.cooldowns_idx[spell]

	if not cds then
		cds = {}
		self.cooldowns_idx[spell] = cds
	end

	if not self.player_available[guid] then
		self.player_available[guid] = true
	end

	local cd = FS.Cooldowns:GetCooldown(guid, spell)
	table.insert(cds, cd)
	self:ScheduleRefreshIndex(spell, true)
end

function Cooldowns2:FS_COOLDOWNS_LOST(_, guid, spell)
	local cds = self.cooldowns_idx[spell]
	if not cds then return end

	for idx, cd in ipairs(cds) do
		if cd.unit.guid == guid then
			table.remove(cds, idx)
			if #cds == 0 then
				self.cooldowns_idx[spell] = nil
			end
			break
		end
	end

	self:ScheduleRefreshIndex(spell, true)
end

function Cooldowns2:FS_COOLDOWNS_USED(_, guid, spell, duration)
	self:ScheduleRefreshIndex(spell)
	C_Timer.After(duration, function() self:ScheduleRefreshIndex(spell) end)
end

function Cooldowns2:FS_COOLDOWNS_READY(_, guid, spell)
	self:ScheduleRefreshIndex(spell)
end

function Cooldowns2:FS_COOLDOWNS_UPDATE(_, guid, spell)
	if self.cooldowns_idx[spell] then
		self:ScheduleRefreshIndex(spell)
	end
end

function Cooldowns2:ScheduleRefreshIndex(spell, rebuild)
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
					self:RefreshCooldown(spell)
				end
			else
				self:RebuildAllDisplays()
			end

			self.refresh_scheduled = nil
		end)
	end
end

function Cooldowns2:RefreshIndex(spell)
	local cds = self.cooldowns_idx[spell]
	if not cds then return end

	local ready_cache = setmetatable({}, {
		__index = function(self, key)
			local ready = key:IsReady()
			self[key] = ready
			return ready
		end
	})

	table.sort(cds, function(a, b)
		local ad_elapsed, ad_left, ad_total = a:Duration()
		local bd_elapsed, bd_left, bd_total = b:Duration()
		local a_active, b_active = ad_total == 0, bd_total == 0

		if a_active ~= b_active then
			return a_active
		elseif a_active then
			return ad_left < bd_left
		else
			local a_avail = self.player_available[a.unit.guid] and ready_cache[a]
			local b_avail = self.player_available[b.unit.guid] and ready_cache[b]

			if a_avail ~= b_avail then
				return a_avail
			elseif a_avail then
				if a.used ~= b.used then
					return a.used < b.used
				else
					return a:MaxCharges() > b:MaxCharges()
				end
			else
				local acd_elapsed, acd_left = a:Cooldown()
				local bcd_elapsed, bcd_left = b:Cooldown()
				return acd_left < bcd_left
			end
		end
	end)
end

-------------------------------------------------------------------------------
-- Players availablity
-------------------------------------------------------------------------------

function Cooldowns2:InitializePlayerTracking()
	self.player_available = {}
	C_Timer.NewTicker(2, function()
		local one_changed = false
		for guid, available in pairs(self.player_available) do
			local unit = Roster:GetUnit(guid)
			if not UnitExists(unit) or UnitGUID(unit) ~= guid then
				self.player_available[guid] = nil
			else
				local a = UnitIsVisible(unit) and not UnitIsDeadOrGhost(unit)
				if a ~= available then
					self.player_available[guid] = a
					one_changed = true
				end
			end
		end
		if one_changed then
			self:RefreshAllCooldowns()
		end
	end)
end
