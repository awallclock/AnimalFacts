local addOnName, aFacts = ...
local _G = _G
_G["aFacts"] = aFacts
local self = AnimalFacts


local channelNames = {}
for i = 1, 5, 1 do
	local _, temp = GetChannelName(i)
	if temp ~= nil then
		channelNames[i] = i .. "." .. temp
	end
end
local options = {
	name = "AnimalFacts",
	handler = AnimalFacts,
	type = "group",
	args = {
		titleText = {
			type = "description",
			fontSize = "large",
			order = 1,
			name = "              |cFF36F7BC" .. "Animal Facts: v" .. AnimalFacts.GetAddOnMetadata("AnimalFacts", "Version"),
		},
		authorText = {
			type = "description",
			fontSize = "medium",
			order = 2,
			name =
			"|TInterface\\AddOns\\AnimalFacts\\Media\\Icon64:64:64:0:20|t |cFFFFFFFFMade with love by  |cFFC41E3AHylly|r",
		},

		main = {
			name = "General Options",
			type = "group",
			order = 1,
			args = {
				generalHeader = {
					name = "General",
					type = "header",
					width = "full",
					order = 1.0,
				},
				channel = {
					type = "select",
					name = "Default channel",
					desc = "The default animal fact channel",
					order = 1.1,
					values = {
						["SAY"] = "Say",
						["PARTY"] = "Party",
						["RAID"] = "Raid",
						["GUILD"] = "Guild",
						["YELL"] = "Yell",
						["RAID_WARNING"] = "Raid Warning",
						["INSTANCE_CHAT"] = "Instance / Battleground",
						["OFFICER"] = "Officer",
						["1"] = channelNames[1],
						["2"] = channelNames[2],
						["3"] = channelNames[3],
						["4"] = channelNames[4],
						["5"] = channelNames[5],
					},
					style = "dropdown",
					get = function()
						return self.db.profile.defaultChannel
					end,
					set = function(_, value)
						self.db.profile.defaultChannel = value
					end,
				},
				selfTimerHeader = {
					name = "Auto Fact Timer",
					type = "header",
					width = "full",
					order = 2.0,
				},
				factTimerToggle = {
					type = "toggle",
					name = "Toggle Auto-Facts",
					order = 2.1,
					desc = "Turns on/off the Auto-Fact Timer.",
					get = function()
						return self.db.profile.toggleTimer
					end,
					set = function(_, value)
						self.db.profile.toggleTimer = value
						AnimalFacts:OutputFactTimer()
					end,
				},
				factTimer = {
					type = "range",
					name = "Auto-Fact Timer",
					order = 2.2,
					desc = "Set the time in minutes to automatically output an animal fact.",
					min = 1,
					max = 60,
					step = 1,
					get = function()
						return self.db.profile.factTimer
					end,
					set = function(_, value)
						self.db.profile.factTimer = value
						AnimalFacts:OutputFactTimer()
					end,
				},
				autoChannel = {
					type = "select",
					name = "Auto-Fact channel",
					desc =
					"The output channel for the Auto-Fact timer. |cF0FF0000NOTE:|r Say and Yell ONLY work while inside an instance",
					order = 2.3,
					values = {
						["SAY"] = "Say",
						["PARTY"] = "Party",
						["RAID"] = "Raid",
						["GUILD"] = "Guild",
						["YELL"] = "Yell",
						["RAID_WARNING"] = "Raid Warning",
						["INSTANCE_CHAT"] = "Instance / Battleground",
						["OFFICER"] = "Officer",
					},
					style = "dropdown",
					get = function()
						return self.db.profile.defaultAutoChannel
					end,
					set = function(_, value)
						self.db.profile.defaultAutoChannel = value
					end,
				},
				animalTypes = {
					name = "Animal Categories",
					desc = "Toggle which facts you want to see",
					type = "header",
					width = "full",
					order = 3.0,
				},
				genericToggle = {
					type = "toggle",
					name = "Generic (" .. #( _G.aFacts and _G.aFacts.generic or {} ) .. " facts)",
					order = 3.1,
					desc = "Has a generic list of facts for many different types of animals",
					get = function()
						return self.db.profile.facts.generic
					end,
					set = function(_, value)
						self.db.profile.facts.generic = value
					end,
				},
				catToggle = {
					type = "toggle",
					name = "Cat (" .. #(aFacts.cat or {}) .. " facts)",
					order = 3.2,
					desc = "Turns off cat facts from the overall /af command",
					get = function()
						return self.db.profile.facts.cat
					end,
					set = function(_, value)
						self.db.profile.facts.cat = value
					end,
				},
				dogToggle = {
					type = "toggle",
					name = "Dog (" .. #(aFacts.dog or {}) .. " facts)",
					order = 3.3,
					desc = "Turns off dog facts from the overall /af command",
					get = function()
						return self.db.profile.facts.dog
					end,
					set = function(_, value)
						self.db.profile.facts.dog = value
					end,
				},
				birdToggle = {
					type = "toggle",
					name = "Bird (" .. #(aFacts.bird or {}) .. " facts)",
					order = 3.4,
					desc = "Turns off bird facts from the overall /af command",
					get = function()
						return self.db.profile.facts.bird
					end,
					set = function(_, value)
						self.db.profile.facts.bird = value
					end,
				},
				frogToggle = {
					type = "toggle",
					name = "Frog (" .. #(aFacts.frog or {}) .. " facts)",
					order = 3.5,
					desc = "Turns off frog facts from the overall /af command",
					get = function()
						return self.db.profile.facts.frog
					end,
					set = function(_, value)
						self.db.profile.facts.frog = value
					end,
				},
				raccoonToggle = {
					type = "toggle",
					name = "Raccoon (" .. #(aFacts.raccoon or {}) .. " facts)",
					order = 3.6,
					desc = "Turns off raccoon facts from the overall /af command",
					get = function()
						return self.db.profile.facts.raccoon
					end,
					set = function(_, value)
						self.db.profile.facts.raccoon = value
					end,
				},
				ratToggle = {
					type = "toggle",
					name = "Rat (" .. #(aFacts.rat or {}) .. " facts)",
					order = 3.7,
					desc = "Turns off rat facts from the overall /af command",
					get = function()
						return self.db.profile.facts.rat
					end,
					set = function(_, value)
						self.db.profile.facts.rat = value
					end,
				},
			},
		},
		info = {
			name = "Information",
			type = "group",
			order = 2,
			args = {
				infoText = {
					type = "description",
					fontSize = "medium",
					name = "A simple dumb addon that allows you to say / yell / raid warning a random animal fact\n"
						.. "How to use:\n"
						.. "|cFFF5A242/af|r |cFF42BEF5<command>|r  OR  |cFFF5A242/animalfact|r |cFF42BEF5<command>|r\n\n"
						.. "List of commands:\n"
						.. "|cFF42BEF5s|r: Sends fact to the /say channel.\n\n"
						.. "|cFF42BEF5p|r: Sends fact to the /party channel.\n\n"
						.. "|cFF42BEF5ra|r: Sends fact to the /raid channel.\n\n"
						.. "|cFF42BEF5rw|r: Sends fact to the /raidwarning channel.\n\n"
						.. "|cFF42BEF5g|r: Sends fact to the /guild channel.\n\n"
						.. "|cFF42BEF5i|r or |cFF42BEF5bg|r: Sends an animal fact to /instance or /bg channel.\n\n"
						.. "|cFF42BEF5w|r or |cFF42BEF5t|r: Whispers an animal fact to your current target\n\n"
						..
						"|cFF42BEF5r|r: Whispers an animal fact to your last reply. Or you can start a new whisper and type '|cFFF5A242/af|r |cFF42BEF5r|r' to send them a fact\n\n"
						..
						"|cFF42BEF51-5|r: Use the numbers 1 through 5 to send a bird fact to global channels ('|cFFF5A242/af|r |cFF42BEF51|r' for example)\n\n"
						.. "You can also use '|cFFF5A242/af|r |cFF42BEF5<animal>|r to send facts about that animal to the default channel.\n"
						.. "Animal choices are: |cFF42BEF5cat, dog, frog, bird, raccoon, rat, generic|r\n\n"
						.. "Also responds when people say |cFF42BEF5!af|r in chat (party and raid)",
				},
			},
		},
	},
}

AnimalFacts.optionsFrame, AnimalFacts.categoryID = ACD:AddToBlizOptions(addOnName, "AnimalFacts")
AC:RegisterOptionsTable("AnimalFacts", options)


function AnimalFacts:OpenSettings()
	if C_SettingsUtil and C_SettingsUtil.OpenSettingsPanel then
		C_SettingsUtil.OpenSettingsPanel(AnimalFacts.categoryID)
	elseif Settings then
		Settings.OpenToCategory(AnimalFacts.categoryID)
	elseif InterfaceOptionsFrame_OpenToCategory then
		InterfaceOptionsFrame_OpenToCategory("AnimalFacts")
	end
end

