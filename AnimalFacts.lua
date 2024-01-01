local addonName, aFacts = ...

-- loading ace3
local AF = LibStub("AceAddon-3.0"):NewAddon("Animal Facts", "AceConsole-3.0", "AceTimer-3.0", "AceComm-3.0",
    "AceEvent-3.0")
local AC = LibStub("AceConfig-3.0")
local ACD = LibStub("AceConfigDialog-3.0")
_G["aFacts"] = aFacts
local GetAddOnMetadata = C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata

AF.playerGUID = UnitGUID("player")
AF.playerName = UnitName("player")
AF._commPrefix = string.upper(addonName)
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
        type = "group",
        handler = AF,
        name = "",
        args = {
            titleText = {
                type = "description",
                fontSize = "large",
                order = 1,
                name = "              |cFF36F7BC" .. "Animal Facts: v" .. GetAddOnMetadata("AnimalFacts", "Version")
            },
            authorText = {
                type = "description",
                fontSize = "medium",
                order = 2,
                name =
                "|TInterface\\AddOns\\AnimalFacts\\Media\\Icon64:64:64:0:20|t |cFFFFFFFFMade with love by  |cFFC41E3AHylly/Hogcrankr-Faerlina|r \n |cFFFFFFFFhttps://discord.gg/AqGTbYMgtK",
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
                    animalTypes = {
                        name = "Animal Categories",
                        desc = "Toggle which facts you want to see",
                        type = "header",
                        width = "full",
                        order = 3.0
                    },
                    genericToggle = {
                        type = "toggle",
                        name = "Generic (" .. #aFacts.generic .. " facts)",
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
                        name = "Cat (" .. #aFacts.cat .. " facts)",
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
                        name = "Dog (" .. #aFacts.dog .. " facts)",
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
                        name = "Bird (" .. #aFacts.bird .. " facts)",
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
                        name = "Frog (" .. #aFacts.frog .. " facts)",
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
                        name = "Raccoon (" .. #aFacts.raccoon .. " facts)",
                        order = 3.6,
                        desc = "Turns off raccoon facts from the overall /af command",
                        get = function()
                            return self.db.profile.facts.raccoon
                        end,
                        set = function(_, value)
                            self.db.profile.facts.raccoon = value
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
                        name =
                            "A simple dumb addon that allows you to say / yell / raid warning a random animal fact\n" ..
                            "For help or to submit a fact: https://discord.gg/AqGTbYMgtK\n\n" ..
                            "How to use:\n" ..
                            "|cFFF5A242/af|r |cFF42BEF5<command>|r  OR  |cFFF5A242/animalfact|r |cFF42BEF5<command>|r\n\n" ..
                            "List of commands:\n" ..
                            "|cFF42BEF5s|r: Sends fact to the /say channel.\n\n" ..
                            "|cFF42BEF5p|r: Sends fact to the /party channel.\n\n" ..
                            "|cFF42BEF5ra|r: Sends fact to the /raid channel.\n\n" ..
                            "|cFF42BEF5rw|r: Sends fact to the /raidwarning channel.\n\n" ..
                            "|cFF42BEF5g|r: Sends fact to the /guild channel.\n\n" ..
                            "|cFF42BEF5i|r or |cFF42BEF5bg|r: Sends an animal fact to /instance or /bg channel.\n\n" ..
                            "|cFF42BEF5w|r or |cFF42BEF5t|r: Whispers an animal fact to your current target\n\n" ..
                            "|cFF42BEF5r|r: Whispers an animal fact to your last reply. Or you can start a new whisper and type '|cFFF5A242/af|r |cFF42BEF5r|r' to send them a fact\n\n" ..
                            "|cFF42BEF51-5|r: Use the numbers 1 through 5 to send a bird fact to global channels ('|cFFF5A242/af|r |cFF42BEF51|r' for example)\n\n" ..
                            "You can also use '|cFFF5A242/af|r |cFF42BEF5<animal>|r to send facts about that animal to the default channel.\n" ..
                            "Animal choices are: |cFF42BEF5cat, dog, frog, bird, raccoon, generic|r"
                    },
                },
            },
        },
    }



    AF.optionsFrame = ACD:AddToBlizOptions("AnimalFacts", "Animal Facts")
    AC:RegisterOptionsTable("AnimalFacts", options)
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
                generic = true,
                bird = true,
                cat = true,
                dog = true,
                raccoon = true
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

    for key, value in pairs(self.db.profile.facts) do
        if value then
            table.insert(trueFacts, key)
        end
    end
    if next(trueFacts) == nil then
        AF:Print("No facts are selected! Please type '/af options' and toggle a fact category ")
        return
    else
        local randomTable = trueFacts[math.random(1, #trueFacts)]
        local randomFact = aFacts[randomTable][math.random(1, #aFacts[randomTable])]
        return randomFact
    end
end

function AF:GetFactSpecific(animal)
    -- get which table the fact needs to be pulled on based on if the savedVariable is trueFacts
    local randomFact = aFacts[animal][math.random(1, #aFacts[animal])]
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
    local isAnimal = false
    local animals = {}
    for key, value in pairs(self.db.profile.facts) do
        if (msg == key) then
            isAnimal = true
            break
        end
    end

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
    elseif (isAnimal) then      --for doing specific animals to the default channel
        SendChatMessage(AF:GetFactSpecific(msg), self.db.profile.defaultChannel)
    elseif (msg ~= "" or msg == "help") then
        AF:factError()
    else
        SendChatMessage(out, self.db.profile.defaultChannel)
    end
end

-- error message
function AF:factError()
    AF:Print("\'/af s\' sends a fact to /say")
    AF:Print("\'/af p\' sends a fact to /party")
    AF:Print("\'/af g\' sends a fact to /guild")
    AF:Print("\'/af ra\' sends a fact to /raid")
    AF:Print("\'/af rw\' sends a fact to /raidwarning")
    AF:Print("\'/af i\' sends a fact to /instance")
    AF:Print("\'/af y\' sends a fact to /yell")
    AF:Print("\'/af r\' sends a fact to the last person whispered")
    AF:Print("\'/af t\' sends a fact to your target")
    AF:Print("\'/af <1-5>\' sends a fact to global channels")
    AF:Print("\'/af <animal>\' sends a specific animal fact ")
end

function AF:TimerFeedback()
    self:Print("Type \'/af help\' to view available channels or \'/af options\' to view the options panel")
end
