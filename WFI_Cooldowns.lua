local _, Cooldowns = ...
LibStub("AceAddon-3.0"):NewAddon(Cooldowns, "WFICooldowns", "AceEvent-3.0", "AceConsole-3.0")

-------------------------------------------------------------------------------
-- Life-cycle
-------------------------------------------------------------------------------

function Cooldowns:OnInitialize()
end

function Cooldowns:OnEnable()
	self:InitializeSettings()
	self:InitializeIndex()
	self:InitializePlayerTracking()
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA")

	self:RebuildEverything()
end

function Cooldowns:OnDisable()
end

do
	local last_instance_type
	function Cooldowns:ZONE_CHANGED_NEW_AREA()
		local _, instance_type = GetInstanceInfo()
		if last_instance_type ~= instance_type then
			last_instance_type = instance_type
			self:RebuildAllGroups()
		end
	end
end

-------------------------------------------------------------------------------
-- Helpers
-------------------------------------------------------------------------------

function Cooldowns:RebuildGroup(name)
	self.groups[name]:Rebuild()
end

function Cooldowns:RebuildAllGroups()
	for name, group in self:IterateGroups() do
		group:Rebuild()
	end
end

function Cooldowns:RefreshDisplay(spell)
	for name, group in self:IterateGroups() do
		group:Refresh(spell)
	end
end

function Cooldowns:RefreshAllDisplays()
	for name, group in self:IterateGroups() do
		group:RefreshAll()
	end
end

-------------------------------------------------------------------------------
-- Players availablity
-------------------------------------------------------------------------------

local Roster = WFI.Roster

function Cooldowns:InitializePlayerTracking()
	self.player_available = {}

	C_Timer.NewTicker(2, function()
		local one_changed = false

		for guid, available in pairs(self.player_available) do
			local unit = Roster:GetUnit(guid)
			if not unit or not UnitExists(unit) or UnitGUID(unit) ~= guid then
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
			self:ScheduleIndexRefreshAll(true)
		end
	end)
end

function Cooldowns:IsPlayerAvailabe(guid)
	return self.player_available[guid] or false
end
