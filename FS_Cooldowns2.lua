local _, Cooldowns2 = ...
LibStub("AceAddon-3.0"):NewAddon(Cooldowns2, "FSCooldowns2", "AceEvent-3.0", "AceConsole-3.0")

-------------------------------------------------------------------------------
-- Life-cycle
-------------------------------------------------------------------------------

function Cooldowns2:OnInitialize()
	self:InitializeSettings()
	self:InitializeIndex()
	self:InitializePlayerTracking()

	self:RebuildEverything()
end

function Cooldowns2:OnEnable()
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
end

function Cooldowns2:OnDisable()
end

do
	local last_instance_type
	function Cooldowns2:ZONE_CHANGED_NEW_AREA()
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

function Cooldowns2:RebuildGroup(name)
	self.groups[name]:Rebuild()
end

function Cooldowns2:RebuildAllGroups()
	for name, group in self:IterateGroups() do
		group:Rebuild()
	end
end

function Cooldowns2:RefreshDisplay(spell)
	for name, group in self:IterateGroups() do
		group:Refresh(spell)
	end
end

function Cooldowns2:RefreshAllDisplays()
	for name, group in self:IterateGroups() do
		group:RefreshAll()
	end
end

-------------------------------------------------------------------------------
-- Players availablity
-------------------------------------------------------------------------------

local Roster = FS.Roster

function Cooldowns2:InitializePlayerTracking()
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

function Cooldowns2:IsPlayerAvailabe(guid)
	return self.player_available[guid] or false
end
