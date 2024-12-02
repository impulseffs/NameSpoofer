-- Create our addon frame and register events
local frame = CreateFrame("Frame")
local addonName = "NameSpoofer"

-- Initialize saved variables
NameSpooferDB = NameSpooferDB or {
    spoofedName = nil
}

-- Addon information
local ADDON_INFO = {
    AUTHOR = "impulseffs",
    GITHUB = "https://github.com/impulseffs/NameSpoofer",
    VERSION = "1.0"
}

-- Function to print colored messages
local function PrintMessage(msg)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage(msg)
    end
end

-- Function to update character frame name
local function UpdateCharacterFrameName()
    if not NameSpooferDB.spoofedName then return end
    
    -- Update character name in title
    if CharacterFrame and CharacterFrame.TitleText then
        CharacterFrame.TitleText:SetText(NameSpooferDB.spoofedName)
    end
    
    -- Update name in character frame
    if CharacterNameText then
        CharacterNameText:SetText(NameSpooferDB.spoofedName)
    end
end

-- Function to update all name displays
local function UpdateNames()
    if not NameSpooferDB.spoofedName then return end
    
    -- Update player frame name
    if PlayerFrame and PlayerFrame.name then
        PlayerFrame.name:SetText(NameSpooferDB.spoofedName)
    end
    
    -- Update target frame if targeting self
    if TargetFrame and TargetFrame.name and UnitIsUnit("target", "player") then
        TargetFrame.name:SetText(NameSpooferDB.spoofedName)
    end
    
    -- Update character frame
    UpdateCharacterFrameName()
end

-- Hook character frame functions
if CharacterFrame_OnShow then
    hooksecurefunc("CharacterFrame_OnShow", UpdateCharacterFrameName)
end

-- Hook PaperDollFrame functions
if PaperDollFrame_OnShow then
    hooksecurefunc("PaperDollFrame_OnShow", UpdateCharacterFrameName)
end

-- Hook SetPaperDollBackground if it exists
if SetPaperDollBackground then
    hooksecurefunc("SetPaperDollBackground", UpdateCharacterFrameName)
end

-- Hook PaperDollFrame_UpdateTabs if it exists
if PaperDollFrame_UpdateTabs then
    hooksecurefunc("PaperDollFrame_UpdateTabs", UpdateCharacterFrameName)
end

-- Hook TargetFrame_Update specifically
if TargetFrame_Update then
    hooksecurefunc("TargetFrame_Update", function()
        if UnitIsUnit("target", "player") and NameSpooferDB.spoofedName then
            TargetFrame.name:SetText(NameSpooferDB.spoofedName)
        end
    end)
end

-- Create slash command handler
SLASH_NAMESPOOFER1 = "/name"
SlashCmdList["NAMESPOOFER"] = function(msg)
    msg = msg:trim()
    if msg == "" then
        print("|cFF00FF00NameSpoofer:|r Usage: /name <new name> - Changes your displayed name")
        print("|cFF00FF00Current spoofed name:|r " .. (NameSpooferDB.spoofedName or "None"))
        return
    end
    
    NameSpooferDB.spoofedName = msg
    print("|cFF00FF00NameSpoofer:|r Your name has been changed to: " .. msg)
    
    -- Force immediate updates
    UpdateNames()
    
    -- If character frame is open, update it
    if CharacterFrame and CharacterFrame:IsShown() then
        UpdateCharacterFrameName()
    end
end

-- Hook the GetUnitName function
local originalGetUnitName = GetUnitName
_G.GetUnitName = function(unit, showServerName)
    if (unit == "player" or (unit == "target" and UnitIsUnit("target", "player"))) and NameSpooferDB.spoofedName then
        return NameSpooferDB.spoofedName
    end
    return originalGetUnitName(unit, showServerName)
end

-- Hook UnitName function as well
local originalUnitName = UnitName
_G.UnitName = function(unit)
    if (unit == "player" or (unit == "target" and UnitIsUnit("target", "player"))) and NameSpooferDB.spoofedName then
        return NameSpooferDB.spoofedName
    end
    return originalUnitName(unit)
end

-- Hook chat messages
local function HookChatMessage(self, event, msg, playerName, ...)
    local realPlayerName = originalUnitName("player")
    if NameSpooferDB.spoofedName and playerName == realPlayerName then
        return false, msg, NameSpooferDB.spoofedName, ...
    end
end

-- Register chat events
local chatEvents = {
    "CHAT_MSG_SAY", "CHAT_MSG_YELL", 
    "CHAT_MSG_PARTY", "CHAT_MSG_PARTY_LEADER",
    "CHAT_MSG_RAID", "CHAT_MSG_RAID_LEADER",
    "CHAT_MSG_GUILD", "CHAT_MSG_WHISPER",
    "CHAT_MSG_WHISPER_INFORM", "CHAT_MSG_CHANNEL"
}

for _, event in ipairs(chatEvents) do
    ChatFrame_AddMessageEventFilter(event, HookChatMessage)
end

-- Register events
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("UNIT_NAME_UPDATE")
frame:RegisterEvent("PLAYER_TARGET_CHANGED")
frame:RegisterEvent("GROUP_ROSTER_UPDATE")
frame:RegisterEvent("ADDON_LOADED")

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        -- Display addon credits
        PrintMessage("|cFF00FF00NameSpoofer loaded!|r Type /name <newname> to change your displayed name")
        PrintMessage("|cFFFFFF00Created by|r |cFF00FF00" .. ADDON_INFO.AUTHOR .. "|r")
        PrintMessage("|cFFFFFF00GitHub:|r |cFF00FFFF" .. ADDON_INFO.GITHUB .. "|r")
        C_Timer.After(1, UpdateNames)
    elseif event == "UNIT_NAME_UPDATE" and ... == "player" then
        UpdateNames()
    elseif event == "PLAYER_TARGET_CHANGED" then
        if UnitIsUnit("target", "player") then
            C_Timer.After(0.1, UpdateNames)
        end
    elseif event == "GROUP_ROSTER_UPDATE" then
        UpdateNames()
    elseif event == "ADDON_LOADED" and ... == addonName then
        if NameSpooferDB.spoofedName then
            C_Timer.After(1, UpdateNames)
        end
    end
end)

-- Create a frame to handle character frame updates
local updateFrame = CreateFrame("Frame")
updateFrame:SetScript("OnUpdate", function(self, elapsed)
    if CharacterFrame and CharacterFrame:IsShown() then
        UpdateCharacterFrameName()
    end
end)

-- Hook character model frame if it exists
if CharacterModelFrame then
    CharacterModelFrame:HookScript("OnShow", UpdateCharacterFrameName)
end

-- Force initial update
C_Timer.After(1, UpdateNames)
