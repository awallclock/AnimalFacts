local addOnName, aFacts = ...

-- loading ace3
local AnimalFacts =
	LibStub("AceAddon-3.0"):NewAddon("Animal Facts", "AceConsole-3.0", "AceTimer-3.0", "AceComm-3.0", "AceEvent-3.0")
local AC = LibStub("AceConfig-3.0")
local ACD = LibStub("AceConfigDialog-3.0")
_G["aFacts"] = aFacts
local GetAddOnMetadata = C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata

AnimalFacts.playerGUID = UnitGUID("player")
AnimalFacts.playerName = UnitName("player")
AnimalFacts._commPrefix = string.upper(addOnName)

local IsInRaid, IsInGroup, IsGUIDInGroup, isOnline = IsInRaid, IsInGroup, IsGUIDInGroup, isOnline
local IsInInstance, IsInGuild = IsInInstance, IsInGuild
local IsInCombat = UnitAffectingCombat("player")
local _G = _G

--yoinked from RankSentinel, sorry :(
-- cache relevant unitids once so we don't do concat every call
local raidUnit, raidUnitPet = {}, {}
local partyUnit, partyUnitPet = {}, {}
for i = 1, _G.MAX_RAID_MEMBERS do
	raidUnit[i] = "raid" .. i
	raidUnitPet[i] = "raidpet" .. i
end
for i = 1, _G.MAX_PARTY_MEMBERS do
	partyUnit[i] = "party" .. i
	partyUnitPet[i] = "partypet" .. i
end


-- things to do on initialize
function AnimalFacts:OnInitialize()
	local defaults = {
		profile = {
			defaultChannel = "SAY",
			timerToggle = false,
			factTimer = "10",
			defaultAutoChannel = "PARTY",
			leader = "",
			pleader = "",
			maxFactRepeat = 20,
			facts = {
				generic = true,
				bird = true,
				cat = true,
				dog = true,
				raccoon = true,
				rat = true,
				frog = true,
			},
		},
	}
	SLASH_AnimalFacts1 = "/af"
	SLASH_AnimalFacts2 = "/animalfacts"
	SlashCmdList["AnimalFacts"] = function(msg)
		AnimalFacts:SlashCommand(msg)
	end
	self.db = LibStub("AceDB-3.0"):New("AnimalFactsDB", defaults, true)
end

function AnimalFacts:OnEnable()
	self:RegisterComm(self._commPrefix)
	self:ScheduleTimer("TimerFeedback", 10)
	AnimalFacts:OutputFactTimer()
	--register chat events
	self:RegisterEvent("CHAT_MSG_RAID", "readChat")
	self:RegisterEvent("CHAT_MSG_PARTY", "readChat")
	self:RegisterEvent("CHAT_MSG_PARTY_LEADER", "readChat")
	self:RegisterEvent("CHAT_MSG_RAID_LEADER", "readChat")
	self:RegisterEvent("CHAT_MSG_GUILD", "readChat")
	self:RegisterEvent("CHAT_MSG_INSTANCE_CHAT", "readChat")
	self:RegisterEvent("GROUP_ROSTER_UPDATE")
end

function AnimalFacts:OnDisable()
	self:CancelTimer(self.timer)
end

function AnimalFacts:OutputFactTimer()
	if self.timer then
		self:CancelTimer(self.timer)
	end
	self.timeInMinutes = self.db.profile.factTimer * 60
	if self.db.profile.toggleTimer == true then
		self.timer = self:ScheduleRepeatingTimer("SlashCommand", self.timeInMinutes, "auto", "SlashCommand")
	end
end

--register the events for chat messages, (Only for Raid and Party), and read the messages for the command "!bf", and then run the function AnimalFacts:SlashCommand
function AnimalFacts:readChat(event, msg, _, _, _, sender)
	if IsInCombat
	 then
		return
	end
	local msgLower = string.lower(msg)
	local leader = self.db.profile.leader
	local channel = event:match("CHAT_MSG_(%w+)")
	local outChannel = ""

	if msgLower == "!af" and leader == self.playerName then
		if channel == "RAID" or channel == "RAID_LEADER" then
			outChannel = "ra"
		elseif channel == "PARTY" or channel == "PARTY_LEADER" then
			outChannel = "p"
		elseif channel == "GUILD" then
			outChannel = "g"
		end
		AnimalFacts:SlashCommand(outChannel)
	end
end

function AnimalFacts:GROUP_ROSTER_UPDATE()
	if not AnimalFacts:IsLeaderInGroup() then
		AnimalFacts:BroadcastLead(self.playerName)
	end
end

function AnimalFacts:IsLeaderInGroup()
	local leader = self.db.profile.leader
	if self.playerName == leader then
		return true
	elseif IsInGroup() then
		if not IsInRaid() then
			for i = 1, GetNumSubgroupMembers() do
				if leader == UnitName(partyUnit[i]) and UnitIsConnected(partyUnit[i]) then
					return true
				end
			end
		else
			for i = 1, GetNumGroupMembers() do
				if leader == UnitName(raidUnit[i]) and UnitIsConnected(raidUnit[i]) then
					return true
				end
			end
		end
	end
end

--Duplicate checker for the auto fact timer, so that the same fact is not repeated within a certain number of facts
local List = {}
function List.new()
	return { first = 0, last = -1 }
end

function List.pushleft(list, value)
	local first = list.first - 1
	list.first = first
	list[first] = value
end

function List.pushright(list, value)
	local last = list.last + 1
	list.last = last
	list[last] = value
end

function List.popleft(list)
	local first = list.first
	if first > list.last then
		error("list is empty")
	end
	local value = list[first]
	list[first] = nil -- to allow garbage collection
	list.first = first + 1
	return value
end

function List.popright(list)
	local last = list.last
	if list.first > last then
		error("list is empty")
	end
	local value = list[last]
	list[last] = nil -- to allow garbage collection
	list.last = last - 1
	return value
end

function AnimalFacts:DuplicateChecker(index)
	--returning true means there is a duplicate
	--returning false means there was not a duplicate
	local firstIndex = RecentlyUsedFacts["first"]
	local lastIndex = RecentlyUsedFacts["last"]
	local currentQueueLength = lastIndex - firstIndex
	local maxQueueLength = self.db.profile.maxFactRepeat
	if lastIndex < firstIndex then
		List.pushright(RecentlyUsedFacts, index)
		return false
	end
	while currentQueueLength > maxQueueLength do
		firstIndex = RecentlyUsedFacts["first"]
		lastIndex = RecentlyUsedFacts["last"]
		currentQueueLength = lastIndex - firstIndex
		List.popleft(RecentlyUsedFacts)
	end

	for i = firstIndex, lastIndex, 1 do
		if index == RecentlyUsedFacts[i] then --duplicate found
			return true
		end
	end
	List.pushright(RecentlyUsedFacts, index)
	return false
end





function AnimalFacts:GetFactAll()
	-- get the database facts that are marked true from self.db.profile.defaults.facts
	-- pick a random one from that list
	-- pick a random fact from the randomly picked table
	-- hopefully....
	local trueFacts = {}

	for key, value in pairs(self.db.profile.facts) do
		if value then
			table.insert(trueFacts, key)
		end
	end
	if next(trueFacts) == nil then
		AnimalFacts:Print("No facts are selected! Please type '/af options' and toggle a fact category ")
		return
	else
		local randomTable = trueFacts[math.random(1, #trueFacts)]
		local randomFact = aFacts[randomTable][math.random(1, #aFacts[randomTable])]
		return randomFact
	end
end

function AnimalFacts:GetFactAllSpecific(animal)
	-- get which table the fact needs to be pulled on based on if the savedVariable is trueFacts
	local randomFact = aFacts[animal][math.random(1, #aFacts[animal])]
	return randomFact
end

function AnimalFacts:OnCommReceived(prefix, message, distribution, sender)
	--AnimalFacts:Print("pre comm receive" .. self.db.profile.leader)
	if prefix ~= AnimalFacts._commPrefix or sender == self.playerName then
		return
	end
	if distribution == "PARTY" or distribution == "RAID" then
		self.db.profile.leader = message
	end
	--AnimalFacts:Print("post comm receive" .. self.db.profile.leader)
end

function AnimalFacts:BroadcastLead(playerName)
	local leader = playerName
	self.db.profile.leader = leader

	--if player is in party but not a raid, do one thing, if player is in raid, do another
	local commDistro = ""
	if IsInGroup() then
		if IsInRaid() then
			commDistro = "RAID"
		else
			commDistro = "PARTY"
		end
	end
	AnimalFacts:SendCommMessage(AnimalFacts._commPrefix, leader, commDistro)
	--AnimalFacts:Print("Leader is " .. leader)
end

-- slash commands and their outputs
function AnimalFacts:SlashCommand(arg)
	local function findKeyFromValue(table, input)
		for key, value in pairs(table) do
			if value == input then
				return key
			end
		end
	end
	local chatChannelDict = {
		["s"] = "SAY", -- requires group
		["p"] = "PARTY", -- rquires party
		["g"] = "GUILD", -- requires guild
		["ra"] = "RAID", -- requires raid
		["rw"] = "RAID_WARNING", --requires raid and assist
		["y"] = "YELL", -- requires group
		["bg"] = "INSTANCE_CHAT", --requires being in instancej
		["i"] = "INSTANCE_CHAT", --rquires bein in instance
		["o"] = "OFFICER", --requires guild
		["r"] = "WHISPER",
		["w"] = "WHISPER",
		["t"] = "WHISPER",
		["1"] = "CHANNEL",
		["2"] = "CHANNEL",
		["3"] = "CHANNEL",
		["4"] = "CHANNEL",
		["5"] = "CHANNEL",
	}


	local msg
	local out = AnimalFacts:GetFactAll()
	local default = findKeyFromValue(chatChannelDict, self.db.profile.defaultChannel)
	local defaultAuto = findKeyFromValue(chatChannelDict, self.db.profile.defaultAutoChannel)
	if arg == "" or arg == nil then
		msg = default
	else
		msg = string.lower(arg)
	end
	AnimalFacts:BroadcastLead(self.playerName)

	-- determines if the incoming arg is one of the valid animals
	local isMessageAnAnimal = false
	for key, value in pairs(self.db.profile.facts) do
		if msg == key then
			isMessageAnAnimal = true
			break
		end
	end

	if msg == "test" then
		AnimalFacts:Print(out)
		return
	end

	if msg == "opt" or msg == "options" then
		if isInCombat then
			AnimalFacts:Print("You cannot open the options panel while in combat.")
			return
		end
		BirdFacts:OpenSettings()
		return
	elseif msg == "auto" then
		if not IsInCombat then
			AnimalFacts:SlashCommand(defaultAuto)
		end
	elseif not chatChannelDict[msg] then
		AnimalFacts:Print("Not a valid command. Type '/bf opt' to view available commands.")
		return
	end

	if msg == "s" or msg == "y" then
		SendChatMessage(out, chatChannelDict[msg])
		return
	end

	if IsInGroup() then
		if msg == "p" then
			SendChatMessage(out, chatChannelDict[msg])
			return
		end
	end

	if IsInRaid() then
		if msg == "ra" or msg == "rw" then
			SendChatMessage(out, chatChannelDict[msg])
			return
		end
	end

	if IsInInstance() then
		if msg == "bg" or msg == "i" then
			SendChatMessage(out, chatChannelDict[msg])
			return
		end
	end

	if IsInGuild() then
		if msg == "g" or msg == "o" then
			SendChatMessage(out, chatChannelDict[msg])
			return
		end
	end

	if msg == "r" and ChatFrame1EditBox:GetAttribute("tellTarget") then
		SendChatMessage(out, chatChannelDict[msg], nil, ChatFrame1EditBox:GetAttribute("tellTarget"))
	elseif (msg == "w" or msg == "t") and UnitName("target") then
		if UnitName("target") then
			SendChatMessage(out, chatChannelDict[msg], nil, UnitName("target"))
		else
			SendChatMessage(out, default)
		end
	elseif isMessageAnAnimal then --for doing specific animals to the default channel
		SendChatMessage(AnimalFacts:GetFactAllSpecific(msg), self.db.profile.defaultChannel)
	elseif msg == "1" or msg == "2" or msg == "3" or msg == "4" or msg == "5" then
		SendChatMessage(out, chatChannelDict[msg], nil, msg)
		--elseif msg == "auto" then
		--	AnimalFacts:SlashCommand(defaultAuto)
		--	else
		--		if default == "1" or default == "2" or default == "3" or default == "4" or default == "5" then
		--			SendChatMessage(out, chatChannelDict[msg], nil, default)
		--		else
		--			AnimalFacts:SlashCommand(default)
		--		end
	end
end

-- error message
function AnimalFacts:factError()
	AnimalFacts:Print("'/af s' sends a fact to /say")
	AnimalFacts:Print("'/af p' sends a fact to /party")
	AnimalFacts:Print("'/af g' sends a fact to /guild")
	AnimalFacts:Print("'/af ra' sends a fact to /raid")
	AnimalFacts:Print("'/af rw' sends a fact to /raidwarning")
	AnimalFacts:Print("'/af i' sends a fact to /instance")
	AnimalFacts:Print("'/af y' sends a fact to /yell")
	AnimalFacts:Print("'/af r' sends a fact to the last person whispered")
	AnimalFacts:Print("'/af t' sends a fact to your target")
	AnimalFacts:Print("'/af <1-5>' sends a fact to global channels")
	AnimalFacts:Print("'/af <animal>' sends a specific animal fact ")
end

function AnimalFacts:TimerFeedback()
	self:Print("Type '/af help' to view available channels or '/af options' to view the options panel")
end
