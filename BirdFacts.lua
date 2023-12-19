local addOnName, bFacts = ...

-- loading ace3
local BirdFacts = LibStub("AceAddon-3.0"):NewAddon("Bird Facts", "AceConsole-3.0", "AceTimer-3.0", "AceComm-3.0",
    "AceEvent-3.0")
local AC = LibStub("AceConfig-3.0")
local ACD = LibStub("AceConfigDialog-3.0")

BirdFacts.playerGUID = UnitGUID("player")
BirdFacts.playerName = UnitName("player")
BirdFacts._commPrefix = string.upper(addOnName)

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

function BirdFacts:BuildOptionsPanel()
    local options = {
        name = "BirdFacts",
        handler = BirdFacts,
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
                desc = "The default bird fact channel",
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
            fakeFacts = {
                type = "select",
                name = "Fact types",
                desc = "Pick from having the option to only have real bird facts, facts about fictional birds, or both",
                order = 1.2,
                values = {
                    ["REAL"] = "Only real facts",
                    ["FAKE"] = "Only fictional facts",
                    ["BOTH"] = "Both real and fictional facts"
                },
                get = function()
                    return self.db.profile.realFake
                end,
                set = function(_, value)
                    self.db.profile.realFake = value
                    BirdFacts:OutputFactTimer()
                end,
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
                "Turns on/off the Auto-Fact Timer. ",
                get = function()
                    return self.db.profile.toggleTimer
                end,
                set = function(_, value)
                    self.db.profile.toggleTimer = value
                    BirdFacts:OutputFactTimer()
                end,

            },
            factTimer = {
                type = "range",
                name = "Auto-Fact Timer",
                order = 2.2,
                desc =
                "Set the time in minutes to automatically output a bird fact.",
                min = 1,
                max = 60,
                step = 1,
                get = function()
                    return self.db.profile.factTimer
                end,
                set = function(_, value)
                    self.db.profile.factTimer = value
                    BirdFacts:OutputFactTimer()
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
    BirdFacts.optionsFrame = ACD:AddToBlizOptions("BirdFacts_options", "BirdFacts")
    AC:RegisterOptionsTable("BirdFacts_options", options)
end

-- things to do on initialize
function BirdFacts:OnInitialize()
    local defaults = {
        profile = {
            defaultChannel = "SAY",
            realFake = "REAL",
            timerToggle = false,
            factTimer = "1",
            defaultAutoChannel = "PARTY",
            leader = "",
            pleader = ""
        }
    }
    SLASH_BIRDFACTS1 = "/bf"
    SLASH_BIRDFACTS2 = "/birdfacts"
    SlashCmdList["BIRDFACTS"] = function(msg)
        BirdFacts:SlashCommand(msg)
    end
    self.db = LibStub("AceDB-3.0"):New("BirdFactsDB", defaults, true)
end

function BirdFacts:OnEnable()
    self:RegisterComm(self._commPrefix)
    BirdFacts:BuildOptionsPanel()
    self:ScheduleTimer("TimerFeedback", 10)
    BirdFacts:OutputFactTimer()
    --register chat events
    self:RegisterEvent("CHAT_MSG_RAID", "readChat")
    self:RegisterEvent("CHAT_MSG_PARTY", "readChat")
    self:RegisterEvent("CHAT_MSG_PARTY_LEADER", "readChat")
    self:RegisterEvent("CHAT_MSG_RAID_LEADER", "readChat")
    self:RegisterEvent("GROUP_ROSTER_UPDATE")
end

function BirdFacts:OnDisable()
    self:CancelTimer(self.timer)
end

function BirdFacts:OutputFactTimer()
    self:CancelTimer(self.timer)
    self.timeInMinutes = self.db.profile.factTimer * 60
    if self.db.profile.toggleTimer == true then
        self.timer = self:ScheduleRepeatingTimer("SlashCommand", self.timeInMinutes, "auto", "SlashCommand")
    end
end

--register the events for chat messages, (Only for Raid and Party), and read the messages for the command "!bf", and then run the function BirdFacts:SlashCommand
function BirdFacts:readChat(event, msg, _, _, _, sender)
    local msg = string.lower(msg)
    local leader = self.db.profile.leader
    local channel = event:match("CHAT_MSG_(%w+)")
    local outChannel = ""

    if (msg == "!bf" and leader == self.playerName) then
        if (channel == "RAID" or channel == "RAID_LEADER") then
            outChannel = "ra"
        elseif (channel == "PARTY" or channel == "PARTY_LEADER") then
            outChannel = "p"
        end
        BirdFacts:SlashCommand(outChannel)
    end
end

function BirdFacts:GROUP_ROSTER_UPDATE()
    if not BirdFacts:IsLeaderInGroup() then
        BirdFacts:BroadcastLead(self.playerName)
    end
end

function BirdFacts:IsLeaderInGroup()
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

function BirdFacts:GetFact()
    local rf = self.db.profile.realFake
    local out = ""
    if (rf == "REAL") then
        out = bFacts.fact[math.random(1, #bFacts.fact)]
    elseif (rf == "FAKE") then
        out = bFacts.fake[math.random(1, #bFacts.fake)]
    elseif (rf == "BOTH") then
        local bothFactsLength = #bFacts.fact + #bFacts.fake
        local num = math.random(1, bothFactsLength)
        if (num < #bFacts.fact) then
            out = bFacts.fact[math.random(1, #bFacts.fact)]
        elseif (num > #bFacts.fact) then
            out = bFacts.fake[math.random(1, #bFacts.fake)]
        end
    end
    return out
end

function BirdFacts:OnCommReceived(prefix, message, distribution, sender)
    --BirdFacts:Print("pre comm receive" .. self.db.profile.leader)
    if prefix ~= BirdFacts._commPrefix or sender == self.playerName then return end
    if distribution == "PARTY" or distribution == "RAID" then
        self.db.profile.leader = message
    end
    --BirdFacts:Print("post comm receive" .. self.db.profile.leader)
end

function BirdFacts:BroadcastLead(playerName)
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
    BirdFacts:SendCommMessage(BirdFacts._commPrefix, leader, commDistro)
    --BirdFacts:Print("Leader is " .. leader)
end

-- slash commands and their outputs
function BirdFacts:SlashCommand(msg)
    local msg = string.lower(msg)
    local out = BirdFacts:GetFact()

    BirdFacts:BroadcastLead(self.playerName)

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
    elseif (msg == "auto") then
        SendChatMessage(out, self.db.profile.defaultAutoChannel)
    elseif (msg ~= "" or msg == "flags") then
        BirdFacts:factError()
    else
        SendChatMessage(out, self.db.profile.defaultChannel)
    end
end

-- error message
function BirdFacts:factError()
    BirdFacts:Print("\'/bf s\' to send a fact to /say")
    BirdFacts:Print("\'/bf p\' to send a fact to /party")
    BirdFacts:Print("\'/bf g\' to send a fact to /guild")
    BirdFacts:Print("\'/bf ra\' to send a fact to /raid")
    BirdFacts:Print("\'/bf rw\' to send a fact to /raidwarning")
    BirdFacts:Print("\'/bf i\' to send a fact to /instance")
    BirdFacts:Print("\'/bf y\' to send a fact to /yell")
    BirdFacts:Print("\'/bf r\' to send a fact to the last person whispered")
    BirdFacts:Print("\'/bf t\' to send a fact to your target")
    BirdFacts:Print("\'/bf <1-5>\' to send a fact to general channels")
end

function BirdFacts:TimerFeedback()
    self:Print("Type \'/bf flags\' to view available channels")
end
