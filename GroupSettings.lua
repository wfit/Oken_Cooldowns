local _, Cooldowns = ...
local Media = LibStub("LibSharedMedia-3.0")

-------------------------------------------------------------------------------
-- Management
-------------------------------------------------------------------------------

function Cooldowns:CreateGroupSettings(name)
	local settings = self:BuildGroupSettings(name, self.settings.groups[name])
	self.config.args.groups.args[name] = settings
	return settings
end

function Cooldowns:RemoveGroupSettings(name)
	self.config.args.groups.args[name] = nil
end

-------------------------------------------------------------------------------
-- Builder
-------------------------------------------------------------------------------

function Cooldowns:BuildGroupSettings(name, group)
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
					Cooldowns:RebuildGroup(name)
				end
			},
			remove = {
				order = 2,
				name = "Delete group",
				type = "execute",
				func = function()
					Cooldowns:RemoveGroup(name)
				end
			},
			void1 = {
				order = 3,
				name = "",
				type = "description"
			},
			icons_settings = {
				order = 3,
				name = "Icons settings",
				type = "group",
				inline = true,
				args = {
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
							Cooldowns:RebuildGroup(name)
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
							Cooldowns:RebuildGroup(name)
						end
					},
				}
			},
			bars_settings = {
				order = 4,
				name = "Bars settings",
				type = "group",
				inline = true,
				args = {
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
							Cooldowns:RebuildGroup(name)
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
							Cooldowns:RebuildGroup(name)
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
							Cooldowns:RebuildGroup(name)
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
							Cooldowns:RebuildGroup(name)
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
							Cooldowns:RebuildGroup(name)
						end
					},
				}
			},
			fonts_settings = {
				order = 5,
				name = "Fonts settings",
				type = "group",
				inline = true,
				args = {
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
							Cooldowns:RebuildGroup(name)
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
							Cooldowns:RebuildGroup(name)
						end
					},
				}
			},
			group_behavior = {
				order = 6,
				name = "Group behavior",
				type = "group",
				inline = true,
				args = {
					missing = {
						order = 21,
						name = "Display missing cooldowns",
						type = "toggle",
						width = "full",
						get = function() return group.missing end,
						set = function(_, value)
							group.missing = value
							Cooldowns:RebuildGroup(name)
						end
					},
					missingDesc = {
						order = 22,
						name = "|cff999999Display cooldown icon even if nobody in the group can cast it\n",
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
							Cooldowns:RebuildGroup(name)
						end
					},
					chargesDesc = {
						order = 24,
						name = "|cff999999Display charges count next to the player's name if more than one charge is available\n",
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
							Cooldowns:RebuildGroup(name)
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
							Cooldowns:RebuildGroup(name)
						end
					},
					limitDesc = {
						order = 27,
						name = "|cff999999Limit the number of visible cooldowns at any one time, for each spell\n",
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
							Cooldowns:RebuildGroup(name)
						end
					},
					excluseSelfDesc = {
						order = 29,
						name = "|cff999999Do not display yourself in the list of available cooldowns\n",
						type = "description"
					},
					showOnlyIn = {
						order = 30,
						name = "Limit visibility",
						type = "toggle",
						width = "full",
						get = function() return group.show_only_in end,
						set = function(_, value)
							group.show_only_in = value
							Cooldowns:RebuildGroup(name)
						end
					},
					showOnlyInSelect = {
						order = 33,
						name = "Show only in",
						type = "multiselect",
						values = {
							party = "Dungeons",
							raid = "Raids",
							none = "Outside"
						},
						hidden = function() return not group.show_only_in end,
						get = function(_, type) return group["show_only_in_" .. type] end,
						set = function(_, type, value)
							group["show_only_in_" .. type] = value
							Cooldowns:RebuildGroup(name)
						end
					},
					showOnlyInDesc = {
						order = 34,
						name = "|cff999999Show this group only in some instance types\n",
						type = "description"
					},
				}
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

	for i = #cooldowns_list, 1, -1 do
		if not self.spell_data[cooldowns_list[i]] then
			table.remove(cooldowns_list, i)
		end
	end

	local function rebuild_active_cds()
		wipe(settings.args.active_cooldowns.args)
		wipe(cooldowns_idx)

		for idx, id in ipairs(cooldowns_list) do
			cooldowns_idx[id] = idx
			local spell, icon, desc = unpack(self.spell_data[id])
			local class = self.spell_class[id]

			settings.args.active_cooldowns.args[spell] = {
				type = "group",
				type = "toggle",
				width = "double",
				name = "|T" .. icon .. ":21|t |cff" .. self:GetClassColor(class, true) .. spell,
				desc = desc .. "\n|cff999999" .. id,
				get = function() return true end,
				set = function()
					table.remove(cooldowns_list, idx)
					rebuild_active_cds()
					Cooldowns:RebuildGroup(name)
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
					Cooldowns:RebuildGroup(name)
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
		local spell, icon, desc = unpack(self.spell_data[id])
		local class = self.spell_class[id]

		settings.args.inactive_cooldowns.args[spell] = {
			type = "toggle",
			name = "|T" .. icon .. ":21|t |cff" .. self:GetClassColor(class, true) .. spell,
			desc = desc .. "\n|cff999999" .. id,
			hidden = function() return cooldowns_idx[id] end,
			get = function() return false end,
			set = function()
				table.insert(cooldowns_list, id)
				rebuild_active_cds()
				Cooldowns:RebuildGroup(name)
			end,
			order = idx
		}
	end

	return settings
end
