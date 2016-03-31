local _, Cooldowns2 = ...
local Media = LibStub("LibSharedMedia-3.0")

local Bar = {}
Bar.__index = Bar
Cooldowns2.Bar = Bar

function Bar:New(display)
	local wrapper = CreateFrame("Frame", nil, display.frame)
	local bar = CreateFrame("StatusBar", nil, wrapper)
	local text = bar:CreateFontString()
	local time = bar:CreateFontString()

	local self = setmetatable({
		display = display,
		settings = display.settings,
		frame = wrapper,
		bar = bar,
		text = text,
		time = time,
		cd = nil
	}, Bar)

	local settings = self.settings
	local wrapper = self.frame

	local backdrop = {
		bgFile = "Interface\\BUTTONS\\WHITE8X8",
		edgeFile = "",
		tile = false, tileSize = 0, edgeSize = 1,
		insets = { left = 0, right = 0, top = 0, bottom = 0 }
	}

	wrapper:SetBackdrop(backdrop)
	wrapper:SetBackdropColor(0.12, 0.12, 0.12, 0.4)
	wrapper:SetFrameStrata("BACKGROUND")

	bar:SetStatusBarTexture(Media:Fetch("statusbar", settings.texture))
	bar:SetAllPoints(wrapper)

	text:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
	text:SetJustifyV("MIDDLE")
	text:SetJustifyH("LEFT")
	text:SetTextColor(1, 1, 1, 1)
	text:SetPoint("LEFT", wrapper, "LEFT", 2, 0)
	text:SetPoint("RIGHT", wrapper, "RIGHT", -35, 0)
	text:SetWordWrap(false)

	time:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
	time:SetJustifyV("MIDDLE")
	time:SetJustifyH("RIGHT")
	time:SetTextColor(1, 1, 1, 1)
	time:SetPoint("LEFT", text, "RIGHT", 2, 0)
	time:SetPoint("RIGHT", wrapper, "RIGHT", 0, 0)

	return self
end

function Bar:Show()
	self.frame:Show()
end

function Bar:Hide()
	self.frame:Hide()
end

function Bar:SetCooldown(cd)
	self.cd = cd
end

function Bar:Rebuild()
	local settings = self.settings

	local wrapper = self.frame
	wrapper:SetWidth(settings.width)
	wrapper:SetHeight(settings.height)

	self.bar:SetStatusBarTexture(Media:Fetch("statusbar", settings.texture))
	self.text:SetFont(Media:Fetch("font", settings.font), settings.font_size, "OUTLINE")
	self.time:SetFont(Media:Fetch("font", settings.font), settings.font_size, "OUTLINE")
end

function Bar:Refresh()
	local settings = self.settings
	local cd = self.cd

	local wrapper = self.frame
	local bar = self.bar
	local text = self.text
	local time = self.time

	local active = cd:IsActive()
	local cooling_down = cd:IsCoolingDown()

	-- Text
	local max_charges = cd:MaxCharges()
	if max_charges > 1 and settings.charges then
		text:SetText(cd:AvailableCharges() .. " - " .. cd.unit:GetName())
	else
		text:SetText(cd.unit:GetName())
	end

	-- Color and alpha
	local color_ratio = 0.8
	wrapper:SetAlpha(1.0)

	if active then
		color_ratio = 2
	elseif not Cooldowns2:IsPlayerAvailabe(cd.unit.guid) then
		color_ratio = 0.2
		wrapper:SetAlpha(0.4)
	elseif not cd:IsReady() then
		color_ratio = 0
	end

	local r, g, b = Cooldowns2:GetClassColor(Cooldowns2.spell_class[cd.spell.id])
	local function blend(color) return color * color_ratio + 0.3 * (1 - color_ratio) end
	bar:SetStatusBarColor(blend(r), blend(g), blend(b), 1)

	-- Animation
	if active or cooling_down then

		local left, total, elapsed
		if active then
			left, total, elapsed = cd:Duration()
		else
			left, total, elapsed = cd:Cooldown()
		end

		local deadline = GetTime() + left
		bar:SetMinMaxValues(0, total)

		local throttler = 0
		local function update_time(now)
			throttler = throttler + 1
			if throttler % 10 == 0 then
				local remaining = math.ceil(deadline - now)
				local sec = remaining % 60
				local min = math.floor(remaining / 60)
				time:SetFormattedText("%d:%02d", min, sec)
			end
		end

		if active then
			wrapper:SetScript("OnUpdate", function()
				local now = GetTime()
				bar:SetValue(deadline - now)
				update_time(now)
			end)
		else
			wrapper:SetScript("OnUpdate", function()
				local now = GetTime()
				bar:SetValue(total - (deadline - now))
				update_time(now)
			end)
		end
	else
		wrapper:SetScript("OnUpdate", nil)
		bar:SetMinMaxValues(0, 1)
		bar:SetValue(1)
		time:SetText("")
	end
end
