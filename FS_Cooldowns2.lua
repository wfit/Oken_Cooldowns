local _, Cooldowns2 = ...
LibStub("AceAddon-3.0"):NewAddon(Cooldowns2, "FSCooldowns2", "AceEvent-3.0", "AceConsole-3.0")

-------------------------------------------------------------------------------
-- Life-cycle
-------------------------------------------------------------------------------

function Cooldowns2:OnInitialize()
	self:InitializeSettings()
	self:InitializeIndex()
	self:InitializePlayerTracking()

	self:RebuildDisplayGroups()
end

function Cooldowns2:OnEnable()
end

function Cooldowns2:OnDisable()
end
