local _, Cooldowns2 = ...

local Media = LibStub("LibSharedMedia-3.0")

-------------------------------------------------------------------------------
-- Display groups management
-------------------------------------------------------------------------------

local displays = {}

function Cooldowns2:RebuildDisplayGroups()
	for name in pairs(displays) do
		self:RemoveDisplayGroup(name, true)
	end

	wipe(displays)

	for name in pairs(self.settings.groups) do
		self:CreateDisplayGroup(name)
	end
end

function Cooldowns2:CreateDisplayGroup(name)
	if displays[name] then return end

	-- Create config entry
	local settings = self:BuildGroupSettings(name, self.settings.groups[name])
	self.config.args.groups.args[name] = settings

	-- Create group anchor
	local anchor = CreateFrame("Frame", nil, UIParent)

	anchor:SetPoint(unpack(self.settings.groups[name].position))

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
		self.settings.groups[name].position = { anchor:GetPoint() }
	end)

	anchor:Show()
	displays[name] = anchor

	self:RebuildDisplay(name)
end

function Cooldowns2:RemoveDisplayGroup(name, dispose_only)
	self.config.args.groups.args[name] = nil
	if not dispose_only then self.settings.groups[name] = nil end
	displays[name]:Hide()

	for id, icon in pairs(displays[name].icons) do
		for _, bar in ipairs(icon.bars) do
			bar:Hide()
		end
	end

	displays[name] = nil
end

function Cooldowns2:RebuildDisplay(name)
	local anchor = displays[name]
	local group = self.settings.groups[name]
	anchor.settings = group

	if not anchor.icons then
		anchor.icons = {}
	end

	if group.unlocked then
		anchor:SetBackdropColor(0.39, 0.71, 1.00, 0.3)
		anchor:EnableMouse(true)
	else
		anchor:SetBackdropColor(0, 0, 0, 0)
		anchor:EnableMouse(false)
	end

	for id, icon in pairs(anchor.icons) do
		icon:Hide()
		icon.visible = false
		for i, bar in ipairs(icon.bars) do
			bar:Hide()
		end
	end

	local player_guid = UnitGUID("player")
	local last_icon
	for _, spell in ipairs(group.cooldowns) do
		local only_mine = true
		if group.exclude_self and self.cooldowns_idx[spell] then
			for i, data in ipairs(self.cooldowns_idx[spell]) do
				if data.unit.guid ~= player_guid then
					only_mine = false
					break
				end
			end
		end

		if group.missing or (self.cooldowns_idx[spell] and not (group.exclude_self and only_mine)) then
			local icon = anchor.icons[spell]
			if not icon then
				icon = self:CreateCooldownIcon(anchor, spell)
				anchor.icons[spell] = icon
			end

			icon:ClearAllPoints()

			icon:SetSize(group.size, group.size)
			icon.tex:SetPoint("TOPLEFT", icon, "TOPLEFT", group.border, -group.border)
			icon.tex:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", -group.border, group.border)
			icon.cd:SetPoint("TOPLEFT", icon, "TOPLEFT", group.border, -group.border)
			icon.cd:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", -group.border, group.border)

			if last_icon then
				local bars_height = (last_icon.bars_count * (group.height + 2)) - 2
				local overflow = (bars_height > group.size) and bars_height - group.size or 0

				if group.attach == "LEFTUP" or group.attach == "RIGHTUP" then
					icon:SetPoint("BOTTOMLEFT", last_icon, "TOPLEFT", 0, group.spacing + overflow)
				else
					icon:SetPoint("TOPLEFT", last_icon, "BOTTOMLEFT", 0, -(group.spacing + overflow))
				end
			else
				local attach_to = {
					LEFTDOWN = "TOPLEFT",
					LEFTUP = "BOTTOMLEFT",
					RIGHTDOWN = "TOPRIGHT",
					RIGHTUP = "BOTTOMRIGHT"
				}
				icon:SetPoint(attach_to[group.attach], anchor, attach_to[group.attach], 0, 0)
			end

			icon.visible = true
			icon:Show()

			local available = false
			icon.bars_count = 0

			local last_bar
			if self.cooldowns_idx[spell] then
				for i, data in ipairs(self.cooldowns_idx[spell]) do
					if not group.exclude_self or (data.unit.guid ~= player_guid) then
						if not icon.bars[i] then
							icon.bars[i] = self:CreateCooldownBar(icon, group)
						end

						local bar = icon.bars[i]
						bar:SetWidth(group.width)
						bar:SetHeight(group.height)

						bar:ClearAllPoints()
						if not last_bar then
							if group.attach == "RIGHTUP" then
								bar:SetPoint("BOTTOMRIGHT", icon, "BOTTOMLEFT", -math.min(5, group.spacing), 0)
							elseif group.attach == "RIGHTDOWN" then
								bar:SetPoint("TOPRIGHT", icon, "TOPLEFT", -math.min(5, group.spacing), 0)
							elseif group.attach == "LEFTUP" then
								bar:SetPoint("BOTTOMLEFT", icon, "BOTTOMRIGHT", math.min(5, group.spacing), 0)
							else
								bar:SetPoint("TOPLEFT", icon, "TOPRIGHT", math.min(5, group.spacing), 0)
							end
						else
							if group.attach == "LEFTUP" or group.attach == "RIGHTUP" then
								bar:SetPoint("BOTTOMLEFT", last_bar, "TOPLEFT", 0, 2)
							else
								bar:SetPoint("TOPLEFT", last_bar, "BOTTOMLEFT", 0, -2)
							end
						end

						bar.bar:SetStatusBarTexture(Media:Fetch("statusbar", group.texture))
						bar.text:SetFont(Media:Fetch("font", group.font), group.font_size, "OUTLINE")
						bar.time:SetFont(Media:Fetch("font", group.font), group.font_size, "OUTLINE")
						bar:Show()
						bar:SetData(data)

						available = true
						icon.bars_count = icon.bars_count + 1

						last_bar = bar

						if group.limit and icon.bars_count == group.limit_nb then
							break
						end
					end
				end
			end

			if available then
				icon:SetAlpha(1)
				icon:SetDesaturated(false)
			else
				icon:SetAlpha(0.5)
				icon:SetDesaturated(true)
			end

			last_icon = icon
		end
	end
end

function Cooldowns2:CreateCooldownIcon(anchor, spell)
	local icon = CreateFrame("BUTTON", nil, anchor);
	icon:SetFrameStrata("BACKGROUND")
	icon:SetWidth(24)
	icon:SetHeight(24)
	icon:SetPoint("CENTER", 0, 0)

	local back = icon:CreateTexture(nil, "BACKGROUND")
	back:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
	back:SetAllPoints()
	icon.back = back

	local tex = icon:CreateTexture(nil, "MEDIUM")
	tex:SetTexture(self.spells_info[spell][2])
	tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	icon.tex = tex

	icon.cd = CreateFrame("Cooldown", nil, icon, "CooldownFrameTemplate")

	local glowing = false
	function icon:SetGlow(glow)
		if glow and not glowing then
			glowing = true
			ActionButton_ShowOverlayGlow(icon);
		elseif not glow and glowing then
			glowing = false
			ActionButton_HideOverlayGlow(icon);
		end
	end

	function icon:SetCooldown(from, to)
		icon.cd:SetCooldown(from, to - from)
	end

	function icon:SetDesaturated(desaturated)
		if desaturated then
			icon.tex:SetDesaturated(1)
			icon.back:SetVertexColor(0.5, 0.5, 0.5, 1)
		else
			icon.tex:SetDesaturated()
			local r, g, b = unpack(Cooldowns2.class_colors[Cooldowns2.spells_class[spell]])
			icon.back:SetVertexColor(r, g, b, 1)
		end
	end

	icon.bars = {}

	icon:EnableMouse(false)
	return icon
end

function Cooldowns2:CreateCooldownBar(icon, group)
	local wrapper = CreateFrame("Frame", nil, icon)

	local backdrop = {
		bgFile = "Interface\\BUTTONS\\WHITE8X8",
		edgeFile = "",
		tile = false, tileSize = 0, edgeSize = 1,
		insets = { left = 0, right = 0, top = 0, bottom = 0 }
	}

	wrapper:SetBackdrop(backdrop)
	wrapper:SetBackdropColor(0.12, 0.12, 0.12, 0.4)
	wrapper:SetFrameStrata("BACKGROUND")

	local bar = CreateFrame("StatusBar", nil, wrapper)
	bar:SetStatusBarTexture(Media:Fetch("statusbar", group.texture))
	--bar:SetPoint("TOPLEFT", wrapper, "TOPLEFT", 1, -1)
	--bar:SetPoint("BOTTOMRIGHT", wrapper, "BOTTOMRIGHT", -1, 1)
	bar:SetAllPoints(wrapper)
	wrapper.bar = bar

	local text = bar:CreateFontString()
	text:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
	text:SetJustifyV("MIDDLE")
	text:SetJustifyH("LEFT")
	text:SetTextColor(1, 1, 1, 1)
	text:SetPoint("LEFT", wrapper, "LEFT", 2, 0)
	text:SetPoint("RIGHT", wrapper, "RIGHT", -35, 0)
	text:SetWordWrap(false)
	wrapper.text = text

	local time = bar:CreateFontString()
	time:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
	time:SetJustifyV("MIDDLE")
	time:SetJustifyH("RIGHT")
	time:SetTextColor(1, 1, 1, 1)
	time:SetPoint("LEFT", text, "RIGHT", 2, 0)
	time:SetPoint("RIGHT", wrapper, "RIGHT", 0, 0)
	wrapper.time = time

	function wrapper:SetData(data)
		wrapper.data = data
		wrapper.player = UnitName(data.unit.info.lku)
		self:Update()
	end

	local throttler = 0
	local function duration_updater(cast_start, duration_end, cd)
		return function()
			bar:SetValue(duration_end - GetTime() + cast_start)
			throttler = throttler + 1
			if throttler % 10 == 0 then
				local remaining = math.ceil(cd.expire - GetTime())
				local sec = remaining % 60
				local min = math.floor(remaining / 60)
				time:SetFormattedText("%d:%02d", min, sec)
			end
		end
	end

	local function cd_updater(cd)
		return function()
			bar:SetValue(GetTime())
			throttler = throttler + 1
			if throttler % 10 == 0 then
				local remaining = math.ceil(cd.cooldown - GetTime())
				local sec = remaining % 60
				local min = math.floor(remaining / 60)
				time:SetFormattedText("%d:%02d", min, sec)
			end
		end
	end

	function wrapper:Update()
		local cd = wrapper.data

		local r, g, b = unpack(Cooldowns2.class_colors[Cooldowns2.spells_class[cd.spell.id]])
		local max_charges = cd:MaxCharges()

		if max_charges > 1 and group.charges then
			local charges_avail = cd:MaxCharges() - cd.used
			text:SetText(charges_avail .. " - " .. wrapper.player)
		else
			text:SetText(wrapper.player)
		end

		local color_ratio = 0.8
		local animating = false
		local animate_duration = false
		wrapper:SetAlpha(1.0)

		if cd:IsActive() then
			color_ratio = 2
			animating = true
			animate_duration = true
		elseif not Cooldowns2.player_available[cd.unit.guid] then
			color_ratio = 0.2
			wrapper:SetAlpha(0.4)
		elseif cd:IsCoolingDown() then
			if not cd:IsReady() then
				color_ratio = 0
			end
			animating = true
		end

		local function blend(color) return color * color_ratio + 0.3 * (1 - color_ratio) end
		bar:SetStatusBarColor(blend(r), blend(g), blend(b), 1)

		if animating then
			throttler = 0
			bar:SetMinMaxValues(cd.cast, animate_duration and cd.expire or cd.cooldown)
			if animate_duration then
				wrapper:SetScript("OnUpdate", duration_updater(cd.cast, cd.expire, cd))
			else
				wrapper:SetScript("OnUpdate", cd_updater(cd))
			end
		else
			wrapper:SetScript("OnUpdate", nil)
			bar:SetMinMaxValues(0, 1)
			bar:SetValue(1)
			time:SetText("")
		end
	end

	return wrapper
end

function Cooldowns2:RefreshCooldown(spell)
	if not self.cooldowns_idx[spell] then return end
	local now = GetTime()
	local player_guid = UnitGUID("player")

	for _, display in pairs(displays) do
		local icon = display.icons[spell]
		if icon and icon.visible then
			local one_available = false
			local glow = false
			local first
			local i = 1

			for _, cd in ipairs(self.cooldowns_idx[spell]) do
				if display.settings.limit and i > display.settings.limit_nb then break end
				if not display.settings.exclude_self or (cd.unit.guid ~= player_guid) then
					local bar = icon.bars[i]
					if bar then
						bar:SetData(cd)
						if cd:IsActive() then
							glow = true
						end

						if cd:IsReady() then
							one_available = true
							break
						end

						if not first then
							first = cd
						end

						i = i + 1
					else
						break
					end
				end
			end

			icon:SetGlow(glow)

			if one_available or glow then
				icon:SetDesaturated(false)
				icon:SetCooldown(0, 0)
			else
				icon:SetDesaturated(true)
				if first then
					local cd_elapsed, cd_left, cd_total = first:Cooldown()
					icon:SetCooldown(now - cd_elapsed, now + cd_left)
				else
					icon:SetCooldown(0, 0)
				end
			end
		end
	end
end

function Cooldowns2:RefreshAllCooldowns()
	for spell in pairs(self.cooldowns_idx) do
		self:RefreshCooldown(spell)
	end
end

function Cooldowns2:RebuildAllDisplays()
	for name in pairs(displays) do
		self:RebuildDisplay(name)
	end
	self:RefreshAllCooldowns()
end
