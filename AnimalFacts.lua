local addOnName, aFacts = ...

-- loading ace3
local AF = LibStub("AceAddon-3.0"):NewAddon("Bird Facts", "AceConsole-3.0", "AceTimer-3.0", "AceComm-3.0",
    "AceEvent-3.0")
local AC = LibStub("AceConfig-3.0")
local ACD = LibStub("AceConfigDialog-3.0")

AF.playerGUID = UnitGUID("player")
AF.playerName = UnitName("player")
AF._commPrefix = string.upper(addOnName)

local IsInRaid, IsInGroup, IsGUIDInGroup, isOnline = IsInRaid, IsInGroup, IsGUIDInGroup, isOnline
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

function AF:BuildOptionsPanel()
    local options = {
        name = "Animal Facts",
        handler = AF,
        type = "group",
        args = {
            generalHeader = {
                name = "General",
                type = "header",
                width = "full",
                order = 1.0
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
                    ["OFFICER"] = "Officer"
                },
                style = "dropdown",
                get = function()
                    return self.db.profile.defaultChannel
                end,
                set = function(_, value)
                    self.db.profile.defaultChannel = value
                end
            },
            selfTimerHeader = {
                name = "Auto Fact Timer",
                type = "header",
                width = "full",
                order = 2.0
            },
            factTimerToggle = {
                type = "toggle",
                name = "Toggle Auto-Facts",
                order = 2.1,
                desc =
                "Turns on/off the Auto-Fact Timer.",
                get = function()
                    return self.db.profile.toggleTimer
                end,
                set = function(_, value)
                    self.db.profile.toggleTimer = value
                    AF:OutputFactTimer()
                end,

            },
            factTimer = {
                type = "range",
                name = "Auto-Fact Timer",
                order = 2.2,
                desc =
                "Set the time in minutes to automatically output an animal fact.",
                min = 1,
                max = 60,
                step = 1,
                get = function()
                    return self.db.profile.factTimer
                end,
                set = function(_, value)
                    self.db.profile.factTimer = value
                    AF:OutputFactTimer()
                end,
            },
            autoChannel = {
                type = "select",
                name = "Auto-Fact channel",
                desc = "The output channel for the Auto-Fact timer",
                order = 2.3,
                values = {
                    ["SAY"] = "Say",
                    ["PARTY"] = "Party",
                    ["RAID"] = "Raid",
                    ["GUILD"] = "Guild",
                    ["YELL"] = "Yell",
                    ["RAID_WARNING"] = "Raid Warning",
                    ["INSTANCE_CHAT"] = "Instance / Battleground",
                    ["OFFICER"] = "Officer"
                },
                style = "dropdown",
                get = function()
                    return self.db.profile.defaultAutoChannel
                end,
                set = function(_, value)
                    self.db.profile.defaultAutoChannel = value
                end
            },
        }
    }
    AF.optionsFrame = ACD:AddToBlizOptions("AF_options", "AF")
    AC:RegisterOptionsTable("AF_options", options)
end

-- things to do on initialize
function AF:OnInitialize()
    local defaults = {
        profile = {
            defaultChannel = "SAY",
            timerToggle = false,
            factTimer = "1",
            defaultAutoChannel = "PARTY",
            leader = "",
            pleader = "",
            facts = {
                bird = true,
                cat = true,
                dog = true,
                racoon = true
            },
        }
    }
    SLASH_AF1 = "/af"
    SLASH_AF2 = "/animalfacts"
    SlashCmdList["AF"] = function(msg)
        AF:SlashCommand(msg)
    end
    self.db = LibStub("AceDB-3.0"):New("AnimalFactsDB", defaults, true)
end

function AF:OnEnable()
    self:RegisterComm(self._commPrefix)
    AF:BuildOptionsPanel()
    self:ScheduleTimer("TimerFeedback", 10)
    AF:OutputFactTimer()
    --register chat events
    self:RegisterEvent("CHAT_MSG_RAID", "readChat")
    self:RegisterEvent("CHAT_MSG_PARTY", "readChat")
    self:RegisterEvent("CHAT_MSG_PARTY_LEADER", "readChat")
    self:RegisterEvent("CHAT_MSG_RAID_LEADER", "readChat")
    self:RegisterEvent("GROUP_ROSTER_UPDATE")
end

function AF:OnDisable()
    self:CancelTimer(self.timer)
end

function AF:OutputFactTimer()
    self:CancelTimer(self.timer)
    self.timeInMinutes = self.db.profile.factTimer * 60
    if self.db.profile.toggleTimer == true then
        self.timer = self:ScheduleRepeatingTimer("SlashCommand", self.timeInMinutes, "auto", "SlashCommand")
    end
end

--register the events for chat messages, (Only for Raid and Party), and read the messages for the command "!bf", and then run the function AF:SlashCommand
function AF:readChat(event, msg, _, _, _, sender)
    local msg = string.lower(msg)
    local leader = self.db.profile.leader
    local channel = event:match("CHAT_MSG_(%w+)")
    local outChannel = ""

    if (msg == "!af" and leader == self.playerName) then
        if (channel == "RAID" or channel == "RAID_LEADER") then
            outChannel = "ra"
        elseif (channel == "PARTY" or channel == "PARTY_LEADER") then
            outChannel = "p"
        end
        AF:SlashCommand(outChannel)
    end
end

function AF:GROUP_ROSTER_UPDATE()
    if not AF:IsLeaderInGroup() then
        AF:BroadcastLead(self.playerName)
    end
end

function AF:IsLeaderInGroup()
    local leader = self.db.profile.leader
    if self.playerName == leader then
        return true
    elseif IsInGroup() then
        if not IsInRaid() then
            for i = 1, GetNumSubgroupMembers() do
                if (leader == UnitName(partyUnit[i]) and UnitIsConnected(partyUnit[i])) then
                    return true
                end
            end
        else
            for i = 1, GetNumGroupMembers() do
                if (leader == UnitName(raidUnit[i]) and UnitIsConnected(raidUnit[i])) then
                    return true
                end
            end
        end
    end
end

function AF:GetFactAll()
    -- get the database facts that are marked true from self.db.profile.defaults.facts
    -- pick a random one from that list
    -- pick a random fact from the randomly picked table
    -- hopefully....
    local trueFacts = {}

    for key, value in pairs(self.db.profile.defaults.facts) do
        if value then
            table.insert(trueFacts, key)
        end
    end

    local randomTable = trueFacts[math.random(1, #trueFacts)]
    local randomFact = randomTable(math.random(1, #randomTable))
    return randomFact
end

function AF:GetFactSpecific(animal)
    -- get which table the fact needs to be pulled on based on if the savedVariable is trueFacts
    local randomFact = #aFacts[animal][math.random(1, #aFacts[animal])]
    return randomFact
end

function AF:OnCommReceived(prefix, message, distribution, sender)
    --AF:Print("pre comm receive" .. self.db.profile.leader)
    if prefix ~= AF._commPrefix or sender == self.playerName then return end
    if distribution == "PARTY" or distribution == "RAID" then
        self.db.profile.leader = message
    end
    --AF:Print("post comm receive" .. self.db.profile.leader)
end

function AF:BroadcastLead(playerName)
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
    AF:SendCommMessage(AF._commPrefix, leader, commDistro)
    --AF:Print("Leader is " .. leader)
end

-- slash commands and their outputs
function AF:SlashCommand(msg)
    local msg = string.lower(msg)
    local out = AF:GetFactAll()

    AF:BroadcastLead(self.playerName)

    local table = {
        ["s"] = "SAY",
        ["p"] = "PARTY",
        ["g"] = "GUILD",
        ["ra"] = "RAID",
        ["rw"] = "RAID_WARNING",
        ["y"] = "YELL",
        ["bg"] = "INSTANCE_CHAT",
        ["i"] = "INSTANCE_CHAT",
        ["o"] = "OFFICER"
    }

    local animals = {
        bird,
        cat,
        dog,
        frog,
        generic,
        racoon,
    }

    if (msg == "r") then
        SendChatMessage(out, "WHISPER", nil, ChatFrame1EditBox:GetAttribute("tellTarget"))
    elseif (msg == "s" or msg == "p" or msg == "g" or msg == "ra" or msg == "rw" or msg == "y" or msg == "bg" or msg == "i" or msg == "o") then
        SendChatMessage(out, table[msg])
    elseif (msg == "w" or msg == "t") then
        if (UnitName("target")) then
            SendChatMessage(out, "WHISPER", nil, UnitName("target"))
        else
            SendChatMessage(out, self.db.profile.defaultChannel)
        end
    elseif (msg == "1" or msg == "2" or msg == "3" or msg == "4" or msg == "5") then
        SendChatMessage(out, "CHANNEL", nil, msg)
    elseif (msg == "opt" or msg == "options") then
        InterfaceOptionsFrame_OpenToCategory(self.optionsFrame)
        InterfaceOptionsFrame_OpenToCategory(self.optionsFrame)
    elseif (msg == "auto") then --this isn't a command a user would type
        SendChatMessage(out, self.db.profile.defaultAutoChannel)
    elseif (msg == animals[msg]) then
        SendChatMessage(AF:GetFactSpecific(msg), self.db.profile.defaultChannel)
    elseif (msg ~= "" or msg == "help") then
        AF:factError()
    else
        SendChatMessage(out, self.db.profile.defaultChannel)
    end
end

-- error message
function AF:factError()
    AF:Print("\'/af s\' to send a fact to /say")
    AF:Print("\'/af p\' to send a fact to /party")
    AF:Print("\'/af g\' to send a fact to /guild")
    AF:Print("\'/af ra\' to send a fact to /raid")
    AF:Print("\'/af rw\' to send a fact to /raidwarning")
    AF:Print("\'/af i\' to send a fact to /instance")
    AF:Print("\'/af y\' to send a fact to /yell")
    AF:Print("\'/af r\' to send a fact to the last person whispered")
    AF:Print("\'/af t\' to send a fact to your target")
    AF:Print("\'/af <1-5>\' to send a fact to general channels")
end

function AF:TimerFeedback()
    self:Print("Type \'/af help\' to view available channels or \'/af options\' to view the options panel")
end
