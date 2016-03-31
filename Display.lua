local _, Cooldowns2 = ...

local Display = {}
Display.__index = Display
Cooldowns2.Display = Display

local ICON_ATTACH = {
	LEFTDOWN = "TOPLEFT",
	LEFTUP = "BOTTOMLEFT",
	RIGHTDOWN = "TOPRIGHT",
	RIGHTUP = "BOTTOMRIGHT"
}

function Display:New(group, spell)
	local self = setmetatable({
		group = group,
		spell = spell,
		settings = group.settings,
		frame = CreateFrame("Frame", nil, UIParent),
		icon = nil,
		glowing = false,
		bars = {},
		count = 0,
		active = false
	}, Display)

	self:BuildIcon()
	return self
end

function Display:BuildIcon()
	local icon = CreateFrame("BUTTON", nil, self.frame);
	icon:SetFrameStrata("BACKGROUND")
	icon:SetWidth(24)
	icon:SetHeight(24)

	local back = icon:CreateTexture(nil, "BACKGROUND")
	back:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
	back:SetAllPoints()
	icon.back = back

	local tex = icon:CreateTexture(nil, "MEDIUM")
	tex:SetTexture(Cooldowns2.spell_data[self.spell][2])
	tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	icon.tex = tex

	icon.cd = CreateFrame("Cooldown", nil, icon, "CooldownFrameTemplate")
	icon:EnableMouse(false)

	self.icon = icon
end

function Display:SetGlow(glow)
	if glow and not self.glowing then
		self.glowing = true
		ActionButton_ShowOverlayGlow(self.icon);
	elseif not glow and self.glowing then
		self.glowing = false
		ActionButton_HideOverlayGlow(self.icon);
	end
end

function Display:SetCooldown(from, total)
	self.icon.cd:SetCooldown(from, total)
end

function Display:SetDesaturated(desaturated)
	if desaturated then
		self.icon.tex:SetDesaturated(1)
		self.icon.back:SetVertexColor(0.5, 0.5, 0.5, 1)
	else
		self.icon.tex:SetDesaturated()
		local r, g, b = Cooldowns2:GetClassColor(Cooldowns2.spell_class[self.spell])
		self.icon.back:SetVertexColor(r, g, b, 1)
	end
end

function Display:Rebuild()
	-- Settings
	local settings = self.settings

	local size = settings.size
	local border = settings.border
	local spacing = settings.spacing
	local width = settings.width
	local height = settings.height
	local attach = settings.attach

	-- Rebuild icon
	local icon = self.icon
	icon:SetSize(size, size)

	icon:ClearAllPoints()
	icon:SetPoint(ICON_ATTACH[attach], 0, 0)

	icon.tex:SetPoint("TOPLEFT", icon, "TOPLEFT", border, -border)
	icon.tex:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", -border, border)
	icon.cd:SetPoint("TOPLEFT", icon, "TOPLEFT", border, -border)
	icon.cd:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", -border, border)

	-- Rebuild bars
	local bars = self.bars
	for _, bar in ipairs(bars) do
		bar:Hide()
	end

	local count = 0
	local player_guid = UnitGUID("player")
	local last_bar

	for idx, cd in self:IterateCooldowns() do
		count = idx
		local bar = bars[idx]

		if not bar then
			bar = Cooldowns2.Bar:New(self)
			bars[idx] = bar
		end

		bar:Rebuild()
		bar:Show()

		local frame = bar.frame
		frame:ClearAllPoints()

		if not last_bar then
			if attach == "RIGHTUP" then
				frame:SetPoint("BOTTOMRIGHT", icon, "BOTTOMLEFT", -math.min(5, spacing), 0)
			elseif attach == "RIGHTDOWN" then
				frame:SetPoint("TOPRIGHT", icon, "TOPLEFT", -math.min(5, spacing), 0)
			elseif attach == "LEFTUP" then
				frame:SetPoint("BOTTOMLEFT", icon, "BOTTOMRIGHT", math.min(5, spacing), 0)
			else
				frame:SetPoint("TOPLEFT", icon, "TOPRIGHT", math.min(5, spacing), 0)
			end
		else
			if attach == "LEFTUP" or attach == "RIGHTUP" then
				frame:SetPoint("BOTTOMLEFT", last_bar.frame, "TOPLEFT", 0, 2)
			else
				frame:SetPoint("TOPLEFT", last_bar.frame, "BOTTOMLEFT", 0, -2)
			end
		end

		last_bar = bar
	end

	self.count = count
	self.active = count > 0

	-- Resize frame
	local bars_height = count * (height + 2) - 2
	self.width = size + spacing + width
	self.height = math.max(size, bars_height)
	self.frame:SetSize(self.width, self.height)

	if self.active then
		self:Refresh()
	else
		self:SetDesaturated(true)
		self:SetGlow(false)
		self:SetCooldown(0, 0)
	end
end

function Display:Refresh()
	if not self.active then return end

	local settings = self.settings
	local player_guid = UnitGUID("player")

	for idx, cd in self:IterateCooldowns() do
		local bar = self.bars[idx]
		bar:SetCooldown(cd)
		bar:Refresh()
	end

	local first = self.bars[1].cd
	local active = first:IsActive()
	local ready = active or first:IsReady()

	self:SetDesaturated(not ready)
	self:SetGlow(active)

	local left, total, elapsed = first:Cooldown()
	if not active and left > 0 then
		self:SetCooldown(GetTime() - elapsed, total)
	else
		self:SetCooldown(0, 0)
	end
end

function Display:IterateCooldowns()
	if not Cooldowns2:IndexHasSpell(self.spell) then
		return function() end
	end

	local settings = self.settings
	local player_guid = UnitGUID("player")

	local cds = {}

	for id, cd in Cooldowns2:IterateIndex(self.spell) do
		if not settings.exclude_self or (cd.unit.guid ~= player_guid) then
			cds[#cds + 1] = cd
			if #cds >= settings.limit_nb then
				break
			end
		end
	end

	return ipairs(cds)
end

function Display:IsActive()
	return self.active
end

function Display:Show()
	self.frame:Show()
end

function Display:Hide()
	self.frame:Hide()
end
