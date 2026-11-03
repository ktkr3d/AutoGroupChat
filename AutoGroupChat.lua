local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("GROUP_ROSTER_UPDATE")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")

local wasInGroup = false
local pendingChatSwitch = false

-- Core function to handle chat switching safely
local function SafeSwitchChat()
    local editBox = ChatEdit_GetActiveWindow() or LAST_ACTIVE_CHAT_EDIT_BOX
    if not editBox then return end

    local targetTarget = "PARTY"

    -- Determine the correct chat channel
    if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
        targetTarget = "INSTANCE_CHAT"
    elseif IsInRaid() then
        targetTarget = "RAID"
    else
        targetTarget = "PARTY"
    end

    -- Update the EditBox attributes directly to prevent nil-value errors
    editBox:SetAttribute("chatType", targetTarget)
    editBox:SetAttribute("stickyType", targetTarget)
    
    -- Force the chat frame UI header to update (e.g., changing "[Say]" to "[Party]")
    if ChatEdit_UpdateHeader then
        ChatEdit_UpdateHeader(editBox)
    end

    print("|cff00ff00[AutoGroupChat]: Chat switched to " .. targetTarget .. ".|r")
    pendingChatSwitch = false
end

frame:SetScript("OnEvent", function(self, event, ...)
    local arg1 = ...
    
    if event == "ADDON_LOADED" and arg1 == "AutoGroupChat" then
        if AGC_Settings == nil then
            AGC_Settings = { enabled = true }
        end
        frame:UnregisterEvent("ADDON_LOADED")
        
    elseif event == "GROUP_ROSTER_UPDATE" then
        if AGC_Settings and not AGC_Settings.enabled then return end
        
        local isInGroup = IsInGroup()
        
        if isInGroup and not wasInGroup then
            if InCombatLockdown() then
                pendingChatSwitch = true
            else
                SafeSwitchChat()
            end
        end
        wasInGroup = isInGroup

    elseif event == "PLAYER_REGEN_ENABLED" then
        if pendingChatSwitch then
            SafeSwitchChat()
        end
    end
end)

-- Slash Command Implementation (/agc)
SLASH_AUTOGROUPCHAT1 = "/agc"
SlashCmdList["AUTOGROUPCHAT"] = function(msg)
    if not AGC_Settings then return end
    msg = string.lower(string.trim(msg or ""))
    
    if msg == "on" then
        AGC_Settings.enabled = true
        print("|cff00ff00[AutoGroupChat]: Enabled.|r")
    elseif msg == "off" then
        AGC_Settings.enabled = false
        print("|cffeedd00[AutoGroupChat]: Disabled.|r")
    elseif msg == "status" or msg == "check" then
        if AGC_Settings.enabled then
            print("|cff00ff00[AutoGroupChat]: Current status is [ON].|r")
        else
            print("|cffeedd00[AutoGroupChat]: Current status is [OFF].|r")
        end
    else
        AGC_Settings.enabled = not AGC_Settings.enabled
        if AGC_Settings.enabled then
            print("|cff00ff00[AutoGroupChat]: Enabled.|r")
        else
            print("|cffeedd00[AutoGroupChat]: Disabled.|r")
        end
    end
end
