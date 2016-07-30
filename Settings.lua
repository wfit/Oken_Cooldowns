local _, Cooldowns2 = ...

local AceAddon = LibStub("AceAddon-3.0")
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
				unlocked = true,
				show_only_in = false,
				show_only_in_party = false,
				show_only_in_raid = false,
				show_only_in_none = false
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
					name = "Raid cooldowns tracker\n\n",
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
							set = function(_, name) Cooldowns2:CreateGroup(name) end,
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
	self:RebuildEverything()
end
