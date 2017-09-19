local _, Cooldowns = ...

-------------------------------------------------------------------------------
-- Group instance
-------------------------------------------------------------------------------

local Group = {}
Group.__index = Group

local GROUP_ATTACH = {
	LEFTDOWN = "TOPLEFT",
	LEFTUP = "BOTTOMLEFT",
	RIGHTDOWN = "TOPRIGHT",
	RIGHTUP = "BOTTOMRIGHT"
}

function Group:New(name)
	local self = setmetatable({
		name = name,
		anchor = CreateFrame("Frame", nil, UIParent),
		settings = Cooldowns.settings.groups[name],
		displays = {}
	}, Group)

	-- Create group anchor
	local anchor = self.anchor

	anchor:SetPoint(unpack(self.settings.position))

	local backdrop = {
		bgFile = "Interface\\BUTTONS\\WHITE8X8",
		edgeFile = "",
		tile = false, tileSize = 0, edgeSize = 1,
		insets = { left = 0, right = 0, top = 0, bottom = 0 }
	}

	anchor:SetBackdrop(backdrop)
	anchor:SetSize(80, 80)

	anchor:SetClampedToScreen(true)
	anchor:SetMovable(true)
	anchor:RegisterForDrag("LeftButton")
	anchor:SetScript("OnDragStart", anchor.StartMoving)
	anchor:SetScript("OnDragStop", function()
		anchor:StopMovingOrSizing()
		self.settings.position = { anchor:GetPoint() }
	end)

	anchor:Show()
	self:Rebuild()
	return self
end

function Group:Rebuild()
	local settings = self.settings

	if self.settings.unlocked then
		self.anchor:SetBackdropColor(0.39, 0.71, 1.00, 0.3)
		self.anchor:EnableMouse(true)
	else
		self.anchor:SetBackdropColor(0, 0, 0, 0)
		self.anchor:EnableMouse(false)
	end

	self:HideDisplays()

	if settings.show_only_in and (not self.settings.unlocked) then
		local _, instType = GetInstanceInfo()
		if (not instType) or (not settings["show_only_in_" .. instType]) then
			return
		end
	end

	local last_display
	for _, spell in ipairs(settings.cooldowns) do
		local display = self:GetDisplay(spell)
		display:Rebuild()

		if settings.missing or display:IsActive() then
			display:Show()

			display.frame:ClearAllPoints()
			if last_display then
				if settings.attach == "LEFTUP" or settings.attach == "RIGHTUP" then
					display.frame:SetPoint("BOTTOMLEFT", last_display.frame, "TOPLEFT", 0, settings.spacing)
				else
					display.frame:SetPoint("TOPLEFT", last_display.frame, "BOTTOMLEFT", 0, -settings.spacing)
				end
			else
				display.frame:SetPoint(GROUP_ATTACH[settings.attach], self.anchor, 0, 0)
			end

			last_display = display
		end
	end
end

function Group:GetDisplay(spell)
	local display = self.displays[spell]
	if not display then
		display = Cooldowns.Display:New(self, spell)
		self.displays[spell] = display
	end
	return display
end

function Group:IterateDisplays()
	return pairs(self.displays)
end

function Group:Refresh(spell)
	local display = self.displays[spell]
	if display then
		display:Refresh()
	end
end

function Group:Dispose()
	self.anchor:Hide()
	self:HideDisplays()
end

function Group:HideDisplays()
	for id, display in self:IterateDisplays() do
		display:Hide()
	end
end

-------------------------------------------------------------------------------
-- Groups management
-------------------------------------------------------------------------------

Cooldowns.groups = {}

-- Returns a display group by name
function Cooldowns:GetGroup(name)
	return self.groups[name]
end

-- Creates a new display group with the given name
function Cooldowns:CreateGroup(name)
	if self.groups[name] then return end
	self:CreateGroupSettings(name)
	self.groups[name] = Group:New(name)
end

-- Remove the given display group
function Cooldowns:RemoveGroup(name)
	self:RemoveGroupSettings(name)
	self.settings.groups[name] = nil

	self.groups[name]:Dispose()
	self.groups[name] = nil
end

-- Iterates over defined groups
function Cooldowns:IterateGroups()
	return pairs(self.groups)
end

-- Rebuild everything !
function Cooldowns:RebuildEverything()
	for name, group in self:IterateGroups() do
		group:Dispose()
	end

	wipe(self.groups)

	for name in pairs(self.settings.groups) do
		self:CreateGroup(name)
	end
end
