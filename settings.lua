local _, Cooldowns2 = ...

local AceAddon = LibStub("AceAddon-3.0")
local Media = LibStub("LibSharedMedia-3.0")
local LibDualSpec = LibStub("LibDualSpec-1.0")

-------------------------------------------------------------------------------
-- Database defaults
-------------------------------------------------------------------------------

local defaults = {
	profile = {
		groups = {
			["**"] = {
				position = { "TOPLEFT", nil, "TOPLEFT", 250, -250 },
				size = 24,
				border = 1,
				spacing = 2,
				width = 100,
				height = 15,
				attach = "LEFTDOWN",
				texture = "Blizzard",
				font = "Friz Quadrata TT",
				font_size = 11,
				missing = true,
				charges = true,
				limit = false,
				limit_nb = 3,
				exclude_self = false,
				cooldowns = {},
				unlocked = true
			}
		}
	}
}

-------------------------------------------------------------------------------
-- Config dialog
-------------------------------------------------------------------------------

Cooldowns2.config = {
	type = "group",
	args = {
		groups = {
			name = "Display groups",
			type = "group",
			args = {
				["$title"] = {
					type = "description",
					name = "|cff64b4ffFSCooldowns2",
					fontSize = "large",
					order = 0
				},
				["$desc"] = {
					type = "description",
					name = "Raid cooldowns tracker.\n\n",
					fontSize = "medium",
					order = 1
				},
				["$author"] = {
					type = "group",
					inline = true,
					name = "Create new display group",
					order = 2,
					args = {
						help = {
							type = "description",
							name = "Display groups are the building blocks of FSCD. Each of them can display a customized set of cooldowns with individual display settings.\n",
							order = 1
						},
						help2 = {
							type = "description",
							name = "You can manage existing display groups from the left menu.\n",
							order = 2
						},
						name = {
							type = "input",
							name = "New group name",
							width = "full",
							get = function() return "" end,
							set = function(_, name) Cooldowns2:CreateDisplayGroup(name) end,
							order = 50
						}
					}
				},
			}
		}
	}
}

LibStub("AceConfig-3.0"):RegisterOptionsTable("FSCooldowns2", Cooldowns2.config)

function Cooldowns2:InitializeSettings()
	local has_fsc1 = AceAddon:GetAddon("FSCooldowns", true)
	local chat_cmd = has_fsc1 and "fsc2" or "fsc"

	if has_fsc1 then
		C_Timer.After(5, function()
			self:Print("|cffffff00You seem to have both FSCooldowns and FSCooldowns2 enabled at the same time. " ..
					"FSCooldowns2 config command will be bound to /fsc2 instead.")
		end)
	end

	self:RegisterChatCommand(chat_cmd, function()
		LibStub("AceConfigDialog-3.0"):Open("FSCooldowns2")
	end)

	self.db = LibStub("AceDB-3.0"):New("FSCooldowns2", defaults, true)
	self.config.args.profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
	LibDualSpec:EnhanceDatabase(self.db, "FSCooldowns2")
	LibDualSpec:EnhanceOptions(self.config.args.profiles, self.db)
	self.settings = self.db.profile

	self.db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileCopied", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileReset", "RefreshConfig")
end

function Cooldowns2:RefreshConfig()
	self.settings = self.db.profile
	self:RebuildDisplayGroups()
end

function Cooldowns2:BuildGroupSettings(name, group)
	-- Create config entry
	local settings = {
		name = name,
		type = "group",
		args = {
			unlock = {
				order = 1,
				name = "Display anchor",
				type = "toggle",
				get = function() return group.unlocked end,
				set = function(_, value)
					group.unlocked = value
					Cooldowns2:RebuildDisplay(name)
				end
			},
			remove = {
				order = 2,
				name = "Delete group",
				type = "execute",
				func = function()
					Cooldowns2:RemoveDisplayGroup(name)
				end
			},
			void1 = {
				order = 3,
				name = "",
				type = "description"
			},
			settings_header = {
				order = 3,
				name = "Group settings",
				type = "header"
			},
			size = {
				order = 10,
				name = "Icon size",
				min = 16,
				max = 64,
				type = "range",
				step = 1,
				get = function() return group.size end,
				set = function(_, value)
					group.size = value
					Cooldowns2:RebuildDisplay(name)
				end
			},
			border = {
				order = 11,
				name = "Border size",
				min = 0,
				max = 5,
				type = "range",
				step = 1,
				get = function() return group.border end,
				set = function(_, value)
					group.border = value
					Cooldowns2:RebuildDisplay(name)
				end
			},
			width = {
				order = 12,
				name = "Bar width",
				min = 50,
				max = 200,
				type = "range",
				step = 1,
				get = function() return group.width end,
				set = function(_, value)
					group.width = value
					Cooldowns2:RebuildDisplay(name)
				end
			},
			height = {
				order = 13,
				name = "Bar height",
				min = 10,
				max = 50,
				type = "range",
				step = 1,
				get = function() return group.height end,
				set = function(_, value)
					group.height = value
					Cooldowns2:RebuildDisplay(name)
				end
			},
			spacing = {
				order = 14,
				name = "Spacing",
				min = 0,
				max = 50,
				type = "range",
				step = 1,
				get = function() return group.spacing end,
				set = function(_, value)
					group.spacing = value
					Cooldowns2:RebuildDisplay(name)
				end
			},
			attach = {
				order = 15,
				name = "Attach - Grow",
				type = "select",
				values = {
					LEFTDOWN = "Left - Down",
					LEFTUP = "Left - Up",
					RIGHTDOWN = "Right - Down",
					RIGHTUP = "Right - Up",
				},
				get = function() return group.attach end,
				set = function(_, value)
					group.attach = value
					Cooldowns2:RebuildDisplay(name)
				end
			},
			font_size = {
				order = 16,
				name = "Font size",
				min = 5,
				max = 30,
				type = "range",
				step = 1,
				get = function() return group.font_size end,
				set = function(_, value)
					group.font_size = value
					Cooldowns2:RebuildDisplay(name)
				end
			},
			font = {
				order = 17,
				name = "Font",
				type = "select",
				dialogControl = "LSM30_Font",
				values = Media:HashTable("font"),
				get = function() return group.font end,
				set = function(_, value)
					group.font = value
					Cooldowns2:RebuildDisplay(name)
				end
			},
			texture = {
				order = 18,
				name = "Texture",
				type = "select",
				width = "double",
				dialogControl = "LSM30_Statusbar",
				values = Media:HashTable("statusbar"),
				get = function() return group.texture end,
				set = function(_, value)
					group.texture = value
					Cooldowns2:RebuildDisplay(name)
				end
			},
			void2 = {
				order = 20,
				name = "\n",
				type = "description"
			},
			missing = {
				order = 21,
				name = "Display missing cooldowns",
				type = "toggle",
				width = "full",
				get = function() return group.missing end,
				set = function(_, value)
					group.missing = value
					Cooldowns2:RebuildDisplay(name)
				end
			},
			missingDesc = {
				order = 22,
				name = "Display cooldown icon even if nobody in the group can cast it\n",
				type = "description"
			},
			charges = {
				order = 23,
				name = "Display charges",
				type = "toggle",
				width = "full",
				get = function() return group.charges end,
				set = function(_, value)
					group.charges = value
					Cooldowns2:RebuildDisplay(name)
				end
			},
			chargesDesc = {
				order = 24,
				name = "Display charges count next to the player's name if more than one charge of the cooldown is available\n",
				type = "description"
			},
			limit = {
				order = 25,
				name = "Limit number of visible cooldowns",
				type = "toggle",
				width = "full",
				get = function() return group.limit end,
				set = function(_, value)
					group.limit = value
					Cooldowns2:RebuildDisplay(name)
				end
			},
			limit_nb = {
				order = 26,
				name = "Limit",
				min = 1,
				max = 10,
				type = "range",
				step = 1,
				hidden = function() return not group.limit end,
				get = function() return group.limit_nb end,
				set = function(_, value)
					group.limit_nb = value
					Cooldowns2:RebuildDisplay(name)
				end
			},
			limitDesc = {
				order = 27,
				name = "Limit the number of visible cooldowns at any one time, for each spell\n",
				type = "description"
			},
			excluseSelf = {
				order = 28,
				name = "Exclude self",
				type = "toggle",
				width = "full",
				get = function() return group.exclude_self end,
				set = function(_, value)
					group.exclude_self = value
					Cooldowns2:RebuildDisplay(name)
				end
			},
			excluseSelfDesc = {
				order = 29,
				name = "Do not display yourself in the list of available cooldowns\n",
				type = "description"
			},
			cooldowns = {
				order = 100,
				name = "Cooldowns",
				type = "header"
			},
			active_cooldowns = {
				order = 150,
				name = "Active cooldowns",
				type = "group",
				inline = true,
				args = {}
			},
			inactive_cooldowns = {
				order = 160,
				name = "Inactive cooldowns",
				type = "group",
				inline = true,
				args = {}
			}
		}
	}

	local cooldowns_idx = {}
	local cooldowns_list = group.cooldowns

	local function rebuild_active_cds()
		wipe(settings.args.active_cooldowns.args)
		wipe(cooldowns_idx)

		for idx, id in ipairs(cooldowns_list) do
			cooldowns_idx[id] = idx
			local spell, icon, desc = unpack(self.spells_info[id])
			local class = self.spells_class[id]
			settings.args.active_cooldowns.args[spell] = {
				type = "group",
				type = "toggle",
				width = "double",
				name = "|T" .. icon .. ":21|t |cff" .. self.class_colors[class][4] .. spell,
				desc = desc .. "\n|cff999999" .. id,
				get = function() return true end,
				set = function()
					table.remove(cooldowns_list, idx)
					rebuild_active_cds()
					Cooldowns2:RebuildDisplay(name)
				end,
				order = idx * 10
			}
			settings.args.active_cooldowns.args[spell .. "$move"] = {
				type = "execute",
				name = "up",
				width = "half",
				hidden = idx == 1,
				func = function()
					cooldowns_list[idx - 1], cooldowns_list[idx] = cooldowns_list[idx], cooldowns_list[idx - 1]
					rebuild_active_cds()
					Cooldowns2:RebuildDisplay(name)
				end,
				order = idx * 10 + 2
			}
			settings.args.active_cooldowns.args[spell .. "$line"] = {
				type = "description",
				name = "",
				width = "full",
				order = idx * 10 + 9
			}
		end
	end

	rebuild_active_cds()

	for idx, id in ipairs(self.spells) do
		local spell, icon, desc = unpack(self.spells_info[id])
		local class = self.spells_class[id]
		settings.args.inactive_cooldowns.args[spell] = {
			type = "toggle",
			name = "|T" .. icon .. ":21|t |cff" .. self.class_colors[class][4] .. spell,
			desc = desc .. "\n|cff999999" .. id,
			hidden = function() return cooldowns_idx[id] end,
			get = function() return false end,
			set = function()
				table.insert(cooldowns_list, id)
				rebuild_active_cds()
				Cooldowns2:RebuildDisplay(name)
			end,
			order = idx
		}
	end

	return settings
end
