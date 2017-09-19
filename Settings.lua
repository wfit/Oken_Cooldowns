local _, Cooldowns = ...

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

Cooldowns.config = {
	type = "group",
	args = {
		groups = {
			name = "Display groups",
			type = "group",
			args = {
				["$title"] = {
					type = "description",
					name = "|cff64b4ffWFICooldowns",
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
							name = "Display groups are the building blocks of WFICD. Each of them can display a customized set of cooldowns with individual display settings.\n",
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
							set = function(_, name) Cooldowns:CreateGroup(name) end,
							order = 50
						}
					}
				},
			}
		}
	}
}

LibStub("AceConfig-3.0"):RegisterOptionsTable("WFICooldowns", Cooldowns.config)

function Cooldowns:InitializeSettings()
	self:RegisterChatCommand("wfic", function()
		LibStub("AceConfigDialog-3.0"):Open("WFICooldowns")
	end)

	self.db = LibStub("AceDB-3.0"):New("WFICooldowns", defaults, true)
	self.config.args.profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
	LibDualSpec:EnhanceDatabase(self.db, "WFICooldowns")
	LibDualSpec:EnhanceOptions(self.config.args.profiles, self.db)
	self.settings = self.db.profile

	self.db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileCopied", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileReset", "RefreshConfig")
end

function Cooldowns:RefreshConfig()
	self.settings = self.db.profile
	self:RebuildEverything()
end
