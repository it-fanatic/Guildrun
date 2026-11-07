--[[
    GuildrunUI - In-Game Dunkelmond-Derby Rennstrecke
    Authentisches Dunkelmond-Jahrmarkt Design
    Tabs: [1] Rennstrecke (Derby) | [2] Hall of Fame (Statistiken & Top 5)
    Inklusive edlem Goldrahmen bei Reittier-Auswahl
--]]

GuildrunUI = GuildrunUI or {}

local RACIAL_MOUNTS = {
    { key = "HORSE",       name = "Pferd (Mensch)",              race = "Human",    icon = "Interface\\Icons\\Ability_Mount_RidingHorse" },
    { key = "RAM",         name = "Widder (Zwerg)",              race = "Dwarf",    icon = "Interface\\Icons\\Ability_Mount_MountainRam" },
    { key = "SABER",       name = "Saebelzahntiger (Nachtelf)",  race = "NightElf", icon = "Interface\\Icons\\Ability_Mount_BlackPanther" },
    { key = "STRIDER",     name = "Schreithahn (Gnom)",          race = "Gnome",    icon = "Interface\\Icons\\Ability_Mount_MechaStrider" },
    { key = "ELEKK",       name = "Elekk (Draenei)",             race = "Draenei",  icon = "Interface\\Icons\\Ability_Mount_RidingElekk" },
    { key = "WOLF",        name = "Wolf (Orc)",                  race = "Orc",      icon = "Interface\\Icons\\Ability_Mount_BlackDireWolf" },
    { key = "KODO",        name = "Kodo (Tauren)",               race = "Tauren",   icon = "Interface\\Icons\\Ability_Mount_Kodo_01" },
    { key = "RAPTOR",      name = "Raptor (Troll)",              race = "Troll",    icon = "Interface\\Icons\\Ability_Mount_Raptor" },
    { key = "SKELETON",    name = "Skelettpferd (Untot)",        race = "Undead",   icon = "Interface\\Icons\\Ability_Mount_Undeadhorse" },
    { key = "HAWKSTRIDER", name = "Falkenschreiter (Blutelf)",   race = "BloodElf", icon = "Interface\\Icons\\Ability_Mount_CockatriceMount" },
}

local MOUNT_LOOKUP = {}
for _, m in ipairs(RACIAL_MOUNTS) do
    MOUNT_LOOKUP[m.key] = m
end

local CLASS_ICON_COORDS = CLASS_ICON_TCOORDS or {
    WARRIOR     = { 0,       0.25,    0,      0.25 },
    MAGE        = { 0.25,    0.496,   0,      0.25 },
    ROGUE       = { 0.496,   0.742,   0,      0.25 },
    DRUID       = { 0.742,   0.988,   0,      0.25 },
    HUNTER      = { 0,       0.25,    0.25,   0.5 },
    SHAMAN      = { 0.25,    0.496,   0.25,   0.5 },
    PRIEST      = { 0.496,   0.742,   0.25,   0.5 },
    WARLOCK     = { 0.742,   0.988,   0.25,   0.5 },
    PALADIN     = { 0,       0.25,    0.5,    0.75 },
    DEATHKNIGHT = { 0.25,    0.496,   0.5,    0.75 },
    MONK        = { 0.496,   0.742,   0.5,    0.75 },
    DEMONHUNTER = { 0.742,   0.988,   0.5,    0.75 },
}

local function SetClassAvatarTexture(texture, classEn)
    local coords = CLASS_ICON_COORDS[classEn]
    if coords then
        texture:SetTexture("Interface\\TargetingFrame\\UI-Classes-Circles")
        texture:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
    else
        texture:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    end
end

local CLASS_COLORS = {
    WARRIOR = "C79C6E",
    PALADIN = "F58CBA",
    HUNTER = "ABD473",
    ROGUE = "FFF569",
    PRIEST = "FFFFFF",
    DEATHKNIGHT = "C41F3B",
    SHAMAN = "0070DE",
    MAGE = "69CCF0",
    WARLOCK = "9482C9",
    MONK = "00FF96",
    DRUID = "FF7D0A",
    DEMONHUNTER = "A330C9",
    EVOKER = "33937F"
}

local function GetCleanDisplayName(name, realm)
    if not name then return "Unbekannt" end
    local _, sur = name:match("^([^-]+)%-(.*)$")
    local curRealm = GetRealmName()
    if realm and realm ~= "" and realm ~= curRealm and realm ~= "WoWForever" and realm ~= "93" and realm ~= sur then
        return string.format("%s (%s)", name, realm)
    end
    return name
end

local mainFrame = nil
local regDialog = nil
local trackRows = {}
local scaleMarkers = {}
local currentTab = "TRACK"
local statBoxes = {}
local demoLoaded = false

local TRACK_START_X = 270
local TRACK_WIDTH = 630

function GuildrunUI.LoadDemoData()
    demoLoaded = true
    GuildrunDB.players = {}
    local myName = UnitName("player")
    local demoList = {
        { name = "Ironbeard", race = "Dwarf", class = "WARRIOR", level = 28, progress = 0.45, zone = "Vorgebirge des Huegellandes", deaths = 2, totalTime = 79200, mount = "RAM", account = "ACC_DEMO_1", milestones = { [10] = { timeFormatted = "4h 12m", zone = "Dun Morogh", deaths = 0 }, [20] = { timeFormatted = "11h 45m", zone = "Loch Modan", deaths = 1 } } },
        { name = "Lumina", race = "Human", class = "PRIEST", level = 24, progress = 0.80, zone = "Eschental", deaths = 0, totalTime = 64800, mount = "HORSE", account = "ACC_DEMO_2", milestones = { [10] = { timeFormatted = "3h 50m", zone = "Wald von Elwynn", deaths = 0 }, [20] = { timeFormatted = "10h 10m", zone = "Westfall", deaths = 0 } } },
        { name = "Shadowblade", race = "Orc", class = "ROGUE", level = 21, progress = 0.15, zone = "Das Brachland", deaths = 4, totalTime = 57600, mount = "WOLF", account = "ACC_DEMO_3", milestones = { [10] = { timeFormatted = "4h 40m", zone = "Durotar", deaths = 1 }, [20] = { timeFormatted = "12h 05m", zone = "Brachland", deaths = 3 } } },
        { name = "Froststrike", race = "Gnome", class = "MAGE", level = 18, progress = 0.60, zone = "Westfall", deaths = 1, totalTime = 43200, mount = "HORSE", account = "ACC_DEMO_2", milestones = { [10] = { timeFormatted = "4h 05m", zone = "Dun Morogh", deaths = 0 } } },
        { name = "Oakenshield", race = "Dwarf", class = "PALADIN", level = 14, progress = 0.30, zone = "Rotkammgebirge", deaths = 0, totalTime = 36000, mount = "RAM", account = "ACC_DEMO_1", milestones = { [10] = { timeFormatted = "4h 22m", zone = "Dun Morogh", deaths = 0 } } },
        { name = "Nightstalker", race = "NightElf", class = "DRUID", level = 11, progress = 0.90, zone = "Dunkelkueste", deaths = 2, totalTime = 25200, mount = "SABER", account = "ACC_DEMO_4", milestones = { [10] = { timeFormatted = "4h 55m", zone = "Teldrassil", deaths = 1 } } },
        { name = "Thunderhoof", race = "Tauren", class = "SHAMAN", level = 9, progress = 0.50, zone = "Mulgore", deaths = 0, totalTime = 18000, mount = "KODO", account = "ACC_DEMO_5", milestones = {} },
        { name = "Sparkplug", race = "Gnome", class = "WARLOCK", level = 7, progress = 0.75, zone = "Wald von Elwynn", deaths = 3, totalTime = 14400, mount = "STRIDER", account = "ACC_DEMO_6", milestones = {} },
        { name = "Bloodfang", race = "Troll", class = "HUNTER", level = 6, progress = 0.20, zone = "Durotar", deaths = 1, totalTime = 10800, mount = "RAPTOR", account = "ACC_DEMO_7", milestones = {} },
        { name = "Rotwalker", race = "Undead", class = "WARLOCK", level = 4, progress = 0.85, zone = "Tirisfal", deaths = 0, totalTime = 7200, mount = "SKELETON", account = "ACC_DEMO_8", milestones = {} },
    }
    for _, p in ipairs(demoList) do
        GuildrunDB.players[p.name] = p
    end
end

local function ApplyBackdropSafe(frame, bgFile, edgeFile, edgeSize)
    if BackdropTemplateMixin and Mixin then
        Mixin(frame, BackdropTemplateMixin)
    end
    if frame.SetBackdrop then
        frame:SetBackdrop({
            bgFile = bgFile or "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
            edgeFile = edgeFile or "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 32, edgeSize = edgeSize or 24,
            insets = { left = 6, right = 6, top = 6, bottom = 6 }
        })
    end
end

-- ==========================================
-- REITTIER-AUSWAHL FUER DIE RENNBAHN
-- ==========================================
function GuildrunUI.ShowMountDialog()
    if not regDialog then
        local template = BackdropTemplateMixin and "BackdropTemplate" or nil
        regDialog = CreateFrame("Frame", "GuildrunMountDialog", UIParent, template)
        regDialog:SetSize(480, 320)
        regDialog:SetPoint("CENTER", UIParent, "CENTER", 0, 50)
        regDialog:SetFrameStrata("FULLSCREEN_DIALOG")
        regDialog:SetToplevel(true)
        regDialog:SetMovable(true)
        regDialog:EnableMouse(true)
        regDialog:RegisterForDrag("LeftButton")
        regDialog:SetScript("OnDragStart", regDialog.StartMoving)
        regDialog:SetScript("OnDragStop", regDialog.StopMovingOrSizing)
        ApplyBackdropSafe(regDialog, "Interface\\FrameGeneral\\UI-Background-Marble", "Interface\\DialogFrame\\UI-DialogBox-Gold-Border", 24)
        if regDialog.SetBackdropColor then
            regDialog:SetBackdropColor(0.12, 0.08, 0.05, 0.98)
        end

        local title = regDialog:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
        title:SetPoint("TOP", 0, -16)
        title:SetText("|cffffd100Reittier-Auswahl fuer das Derby|r")

        local desc = regDialog:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        desc:SetPoint("TOP", title, "BOTTOM", 0, -10)
        desc:SetWidth(420)
        desc:SetText("Waehle dein persoenliches Reittier fuer deine Rennbahn-Spur:")

        regDialog.mountButtons = {}
        regDialog.selectedMountKey = GuildrunDB.selectedMount or "HORSE"

        local startX = 35
        local startY = -75
        for i, m in ipairs(RACIAL_MOUNTS) do
            local col = (i - 1) % 5
            local row = math.floor((i - 1) / 5)

            local mBtn = CreateFrame("Button", nil, regDialog)
            mBtn:SetSize(40, 40)
            mBtn:SetPoint("TOPLEFT", regDialog, "TOPLEFT", startX + (col * 84), startY - (row * 60))

            -- Reittier Icon
            mBtn.icon = mBtn:CreateTexture(nil, "BACKGROUND")
            mBtn.icon:SetAllPoints()
            mBtn.icon:SetTexture(m.icon)
            mBtn.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

            -- Hochwertiger Goldener Auswahlrahmen (4 Linien als sichtbare Umrandung)
            mBtn.goldBorder = CreateFrame("Frame", nil, mBtn)
            mBtn.goldBorder:SetAllPoints()

            -- Oben
            mBtn.goldTop = mBtn.goldBorder:CreateTexture(nil, "OVERLAY")
            mBtn.goldTop:SetPoint("TOPLEFT", -3, 3)
            mBtn.goldTop:SetPoint("TOPRIGHT", 3, 3)
            mBtn.goldTop:SetHeight(3)
            mBtn.goldTop:SetColorTexture(1.0, 0.85, 0.1, 1.0)

            -- Unten
            mBtn.goldBot = mBtn.goldBorder:CreateTexture(nil, "OVERLAY")
            mBtn.goldBot:SetPoint("BOTTOMLEFT", -3, -3)
            mBtn.goldBot:SetPoint("BOTTOMRIGHT", 3, -3)
            mBtn.goldBot:SetHeight(3)
            mBtn.goldBot:SetColorTexture(1.0, 0.85, 0.1, 1.0)

            -- Links
            mBtn.goldLeft = mBtn.goldBorder:CreateTexture(nil, "OVERLAY")
            mBtn.goldLeft:SetPoint("TOPLEFT", -3, 3)
            mBtn.goldLeft:SetPoint("BOTTOMLEFT", -3, -3)
            mBtn.goldLeft:SetWidth(3)
            mBtn.goldLeft:SetColorTexture(1.0, 0.85, 0.1, 1.0)

            -- Rechts
            mBtn.goldRight = mBtn.goldBorder:CreateTexture(nil, "OVERLAY")
            mBtn.goldRight:SetPoint("TOPRIGHT", 3, 3)
            mBtn.goldRight:SetPoint("BOTTOMRIGHT", 3, -3)
            mBtn.goldRight:SetWidth(3)
            mBtn.goldRight:SetColorTexture(1.0, 0.85, 0.1, 1.0)

            -- Goldener Glow-Hintergrund um den Button herum
            mBtn.goldGlow = mBtn:CreateTexture(nil, "BORDER")
            mBtn.goldGlow:SetPoint("TOPLEFT", -5, 5)
            mBtn.goldGlow:SetPoint("BOTTOMRIGHT", 5, -5)
            mBtn.goldGlow:SetColorTexture(1.0, 0.8, 0.0, 0.3)

            local mLabel = mBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            mLabel:SetPoint("TOP", mBtn, "BOTTOM", 0, -3)
            mLabel:SetWidth(78)
            mLabel:SetText(m.name:match("^[^(]+"))
            mBtn.label = mLabel

            mBtn.mountKey = m.key
            mBtn:SetScript("OnClick", function(self)
                regDialog.selectedMountKey = self.mountKey
                regDialog.UpdateMountSelection()
            end)

            mBtn:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_TOP")
                GameTooltip:AddLine("|cffffd100" .. m.name .. "|r")
                GameTooltip:AddLine("Dieses Reittier rennt auf deiner Spur!", 1, 1, 1)
                GameTooltip:Show()
            end)
            mBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

            table.insert(regDialog.mountButtons, mBtn)
        end

        function regDialog.UpdateMountSelection()
            for _, btn in ipairs(regDialog.mountButtons) do
                if btn.mountKey == regDialog.selectedMountKey then
                    btn.goldBorder:Show()
                    btn.goldGlow:Show()
                    btn.icon:SetVertexColor(1, 1, 1)
                    btn.label:SetTextColor(1, 0.85, 0.1) -- Goldener Text
                else
                    btn.goldBorder:Hide()
                    btn.goldGlow:Hide()
                    btn.icon:SetVertexColor(0.55, 0.55, 0.55)
                    btn.label:SetTextColor(0.7, 0.7, 0.7)
                end
            end
        end

        local statusText = regDialog:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        statusText:SetPoint("BOTTOM", 0, 60)
        statusText:SetWidth(420)
        regDialog.statusText = statusText

        local saveBtn = CreateFrame("Button", nil, regDialog, "UIPanelButtonTemplate")
        saveBtn:SetSize(160, 28)
        saveBtn:SetPoint("BOTTOMLEFT", 60, 18)
        saveBtn:SetText("Reittier speichern")
        saveBtn:SetScript("OnClick", function()
            local charKey = Guildrun_GetFullPlayerName("player")
            GuildrunDB.selectedMount = regDialog.selectedMountKey
            GuildrunDB.characters = GuildrunDB.characters or {}
            GuildrunDB.characters[charKey] = GuildrunDB.characters[charKey] or {}
            GuildrunDB.characters[charKey].mount = regDialog.selectedMountKey
            GuildrunDB.characters[charKey].name = charKey

            local me = Guildrun_UpdateLocalPlayerRecord and Guildrun_UpdateLocalPlayerRecord()
            if me and Guildrun_BroadcastPlayer then
                Guildrun_BroadcastPlayer(me)
            end

            regDialog.statusText:SetText(string.format("|cff00ff00Reittier %s gewaehlt!|r", regDialog.selectedMountKey))
            if GuildrunUI and GuildrunUI.Refresh then
                GuildrunUI.Refresh()
            end
            C_Timer.After(0.8, function()
                regDialog:Hide()
            end)
        end)

        local closeBtn = CreateFrame("Button", nil, regDialog, "UIPanelButtonTemplate")
        closeBtn:SetSize(120, 28)
        closeBtn:SetPoint("BOTTOMRIGHT", -60, 18)
        closeBtn:SetText("Schliessen")
        closeBtn:SetScript("OnClick", function()
            regDialog:Hide()
        end)
    end

    local charKey = Guildrun_GetFullPlayerName("player")
    local charCfg = GuildrunDB.characters and GuildrunDB.characters[charKey]
    if charCfg and charCfg.mount then
        regDialog.selectedMountKey = charCfg.mount
    elseif GuildrunDB.selectedMount then
        regDialog.selectedMountKey = GuildrunDB.selectedMount
    else
        local _, raceEn = UnitRace("player")
        for _, m in ipairs(RACIAL_MOUNTS) do
            if m.race == raceEn then
                regDialog.selectedMountKey = m.key
                break
            end
        end
    end

    regDialog.UpdateMountSelection()
    local mInfo = MOUNT_LOOKUP[regDialog.selectedMountKey or "HORSE"] or MOUNT_LOOKUP["HORSE"]
    regDialog.statusText:SetText(string.format("Aktuell gewaehlt: |cffffd100%s|r", mInfo.name))
    regDialog:Show()
end

GuildrunUI.ShowRegistrationDialog = GuildrunUI.ShowMountDialog

-- ==========================================
-- DERBY HAUPTFENSTER MIT TABS
-- ==========================================
function GuildrunUI.CreateFrame()
    if mainFrame then return mainFrame end

    local template = BackdropTemplateMixin and "BackdropTemplate" or nil
    mainFrame = CreateFrame("Frame", "GuildrunDerbyFrame", UIParent, template)
    mainFrame:SetSize(960, 560)
    mainFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    mainFrame:SetFrameStrata("DIALOG")
    mainFrame:SetToplevel(true)
    mainFrame:SetMovable(true)
    mainFrame:EnableMouse(true)
    mainFrame:RegisterForDrag("LeftButton")
    mainFrame:SetScript("OnDragStart", mainFrame.StartMoving)
    mainFrame:SetScript("OnDragStop", mainFrame.StopMovingOrSizing)
    mainFrame:SetClampedToScreen(true)

    ApplyBackdropSafe(mainFrame, "Interface\\FrameGeneral\\UI-Background-Marble", "Interface\\DialogFrame\\UI-DialogBox-Gold-Border", 32)
    if mainFrame.SetBackdropColor then
        mainFrame:SetBackdropColor(0.08, 0.05, 0.10, 0.98)
    end

    -- Dunkelmond-Jahrmarkt Baldachin Markise (Dunkelmond-Violett & Gold)
    local awning = mainFrame:CreateTexture(nil, "BACKGROUND", nil, 1)
    awning:SetPoint("TOPLEFT", 8, -8)
    awning:SetPoint("TOPRIGHT", -8, -8)
    awning:SetHeight(48)
    awning:SetColorTexture(0.20, 0.08, 0.32, 0.95)

    local awningTrim = mainFrame:CreateTexture(nil, "BORDER", nil, 2)
    awningTrim:SetPoint("BOTTOMLEFT", awning, "BOTTOMLEFT", 0, 0)
    awningTrim:SetPoint("BOTTOMRIGHT", awning, "BOTTOMRIGHT", 0, 0)
    awningTrim:SetHeight(4)
    awningTrim:SetColorTexture(1.0, 0.82, 0.25, 1)

    -- Haupt-Titel
    local title = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    title:SetPoint("TOP", 0, -14)
    title:SetText("|cffffd100GUILDRUN|r")

    local subtitle = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    subtitle:SetPoint("TOP", title, "BOTTOM", 0, -2)
    subtitle:SetText("|cff00e5ffDunkelmond-Jahrmarkt|r  *  |cffffd100Gilden-Levelrennen & Meilensteine|r")
    mainFrame.subtitle = subtitle

    local closeBtn = CreateFrame("Button", nil, mainFrame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", -4, -4)

    -- Toolbar oben mit TAB-Wechsler
    local topBar = CreateFrame("Frame", nil, mainFrame, template)
    topBar:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 14, -58)
    topBar:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", -14, -58)
    topBar:SetHeight(32)
    ApplyBackdropSafe(topBar, "Interface\\Buttons\\WHITE8X8", "Interface\\Tooltips\\UI-Tooltip-Border", 8)
    if topBar.SetBackdropColor then topBar:SetBackdropColor(0.05, 0.03, 0.07, 0.9) end

    local tabTrack = CreateFrame("Button", nil, topBar, "UIPanelButtonTemplate")
    tabTrack:SetSize(130, 24)
    tabTrack:SetPoint("LEFT", 8, 0)
    tabTrack:SetText("|TInterface\\Icons\\Ability_Mount_RidingHorse:14:14:0:0|t Derby-Strecke")
    mainFrame.tabTrack = tabTrack

    local tabStats = CreateFrame("Button", nil, topBar, "UIPanelButtonTemplate")
    tabStats:SetSize(140, 24)
    tabStats:SetPoint("LEFT", tabTrack, "RIGHT", 8, 0)
    tabStats:SetText("|TInterface\\Icons\\Inv_Misc_Ticket_Tarot_Darkmoon_01:14:14:0:0|t Hall of Fame")
    mainFrame.tabStats = tabStats

    tabTrack:SetScript("OnClick", function()
        currentTab = "TRACK"
        GuildrunUI.Refresh()
    end)

    tabStats:SetScript("OnClick", function()
        currentTab = "STATS"
        GuildrunUI.Refresh()
    end)

    local limitBadge = topBar:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    limitBadge:SetPoint("LEFT", tabStats, "RIGHT", 14, 0)
    limitBadge:SetText("|cff00e5ffStrecke:|r bis |cffffcc00Level 15|r")
    mainFrame.limitBadge = limitBadge

    local mountBtn = CreateFrame("Button", nil, topBar, "UIPanelButtonTemplate")
    mountBtn:SetSize(120, 24)
    mountBtn:SetPoint("RIGHT", -8, 0)
    mountBtn:SetText("Reittier waehlen")
    mountBtn:SetScript("OnClick", function()
        GuildrunUI.ShowMountDialog()
    end)

    local syncBtn = CreateFrame("Button", nil, topBar, "UIPanelButtonTemplate")
    syncBtn:SetSize(120, 24)
    syncBtn:SetPoint("RIGHT", mountBtn, "LEFT", -6, 0)
    syncBtn:SetText("|TInterface\\Icons\\Spell_Frost_Stun:14:14:0:0|t Aktualisieren")
    syncBtn:SetScript("OnClick", function()
        if Guildrun_RequestGuildSync then
            Guildrun_RequestGuildSync()
        end
        if GuildrunUI and GuildrunUI.Refresh then
            GuildrunUI.Refresh()
        end
    end)

    -- CONTAINER 1: RENNBAHN
    local trackContainer = CreateFrame("Frame", nil, mainFrame)
    trackContainer:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 14, -94)
    trackContainer:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -14, 38)
    mainFrame.trackContainer = trackContainer

    local scaleBar = CreateFrame("Frame", nil, trackContainer, template)
    scaleBar:SetPoint("TOPLEFT", trackContainer, "TOPLEFT", 0, 0)
    scaleBar:SetPoint("TOPRIGHT", trackContainer, "TOPRIGHT", 0, 0)
    scaleBar:SetHeight(32)
    ApplyBackdropSafe(scaleBar, "Interface\\Buttons\\WHITE8X8", "Interface\\Tooltips\\UI-Tooltip-Border", 8)
    if scaleBar.SetBackdropColor then scaleBar:SetBackdropColor(0.08, 0.05, 0.03, 0.95) end
    mainFrame.scaleBar = scaleBar

    local scaleLabel = scaleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    scaleLabel:SetPoint("LEFT", 12, 0)
    scaleLabel:SetText("|cffffd100SPUR / SPIELER|r")

    local scrollFrame = CreateFrame("ScrollFrame", "GuildrunScrollFrame", trackContainer, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", scaleBar, "BOTTOMLEFT", 0, -6)
    scrollFrame:SetPoint("BOTTOMRIGHT", trackContainer, "BOTTOMRIGHT", -22, 0)
    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local cur = self:GetVerticalScroll()
        local maxScroll = self:GetVerticalScrollRange()
        local step = 45
        if delta > 0 then
            self:SetVerticalScroll(math.max(0, cur - step))
        else
            self:SetVerticalScroll(math.min(maxScroll, cur + step))
        end
    end)

    local content = CreateFrame("Frame", "GuildrunContentFrame", scrollFrame)
    content:SetSize(905, 10)
    content:EnableMouseWheel(true)
    content:SetScript("OnMouseWheel", function(self, delta)
        scrollFrame:GetScript("OnMouseWheel")(scrollFrame, delta)
    end)
    scrollFrame:SetScrollChild(content)
    mainFrame.scrollFrame = scrollFrame
    mainFrame.content = content

    -- CONTAINER 2: HALL OF FAME
    local statsContainer = CreateFrame("Frame", nil, mainFrame)
    statsContainer:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 14, -94)
    statsContainer:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -14, 40)
    mainFrame.statsContainer = statsContainer

    local boxWidth = 224
    local boxHeight = 416
    local boxStartX = 0
    local boxGap = 12

    local boxConfigs = {
        { title = "|TInterface\\Icons\\Inv_Misc_Coin_01:14:14:0:0|t HOECHSTES LEVEL", color = "ffd700" },
        { title = "|TInterface\\Icons\\Spell_Nature_Swiftness:14:14:0:0|t SPEEDRUNNER (/played)", color = "00e5ff" },
        { title = "|TInterface\\Icons\\Ability_Creature_Cursed_02:14:14:0:0|t MEISTE TODE", color = "ff5252" },
        { title = "|TInterface\\Icons\\Inv_Misc_Ticket_Tarot_Darkmoon_01:14:14:0:0|t TOP CHARS (ACCOUNT)", color = "ffd700" }
    }

    statBoxes = {}
    for i = 1, 4 do
        local box = CreateFrame("Frame", nil, statsContainer, template)
        box:SetSize(boxWidth, boxHeight)
        box:SetPoint("TOPLEFT", statsContainer, "TOPLEFT", boxStartX + ((i - 1) * (boxWidth + boxGap)), 0)
        ApplyBackdropSafe(box, "Interface\\Buttons\\WHITE8X8", "Interface\\Tooltips\\UI-Tooltip-Border", 10)
        if box.SetBackdropColor then box:SetBackdropColor(0.06, 0.04, 0.08, 0.95) end

        local bTitle = box:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        bTitle:SetPoint("TOP", 0, -10)
        bTitle:SetText(boxConfigs[i].title)

        local line = box:CreateTexture(nil, "ARTWORK")
        line:SetPoint("TOPLEFT", 8, -28)
        line:SetPoint("TOPRIGHT", -8, -28)
        line:SetHeight(1)
        line:SetColorTexture(0.35, 0.25, 0.15, 0.8)

        box.rows = {}
        for r = 1, 5 do
            local row = CreateFrame("Frame", nil, box)
            row:SetSize(boxWidth - 16, 64)
            row:SetPoint("TOPLEFT", box, "TOPLEFT", 8, -34 - ((r - 1) * 72))

            row.rankText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
            row.rankText:SetPoint("LEFT", 2, 0)
            row.rankText:SetWidth(24)
            row.rankText:SetJustifyH("CENTER")

            row.avatar = row:CreateTexture(nil, "ARTWORK")
            row.avatar:SetSize(32, 32)
            row.avatar:SetPoint("LEFT", 28, 0)
            row.avatar:SetTexCoord(0.08, 0.92, 0.08, 0.92)

            row.nameText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            row.nameText:SetPoint("TOPLEFT", row.avatar, "TOPRIGHT", 6, -2)
            row.nameText:SetPoint("RIGHT", row, "RIGHT", -4, 0)
            row.nameText:SetJustifyH("LEFT")
            if row.nameText.SetWordWrap then row.nameText:SetWordWrap(false) end

            row.valText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            row.valText:SetPoint("BOTTOMLEFT", row.avatar, "BOTTOMRIGHT", 6, 2)
            row.valText:SetPoint("RIGHT", row, "RIGHT", -4, 0)
            row.valText:SetJustifyH("LEFT")
            if row.valText.SetWordWrap then row.valText:SetWordWrap(false) end

            box.rows[r] = row
        end

        statBoxes[i] = box
    end

    local statusBar = CreateFrame("Frame", nil, mainFrame, template)
    statusBar:SetPoint("BOTTOMLEFT", mainFrame, "BOTTOMLEFT", 14, 10)
    statusBar:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -14, 10)
    statusBar:SetHeight(24)
    ApplyBackdropSafe(statusBar, "Interface\\Buttons\\WHITE8X8", "Interface\\Tooltips\\UI-Tooltip-Border", 8)
    if statusBar.SetBackdropColor then statusBar:SetBackdropColor(0.04, 0.03, 0.02, 0.8) end
    
    local statusText = statusBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    statusText:SetPoint("LEFT", 8, 0)
    mainFrame.statusText = statusText

    mainFrame:Hide()
    return mainFrame
end

function GuildrunUI.Toggle()
    local f = GuildrunUI.CreateFrame()
    if f:IsShown() then
        f:Hide()
    else
        f:Show()
        GuildrunUI.Refresh()
        if (Guildrun_IsInGuild and Guildrun_IsInGuild()) or (IsInGuild and IsInGuild()) or (GetGuildInfo and GetGuildInfo("player") ~= nil) then
            if Guildrun_SendGuildMessage then
                Guildrun_SendGuildMessage("REQ")
            end
            if Guildrun_UpdateLocalPlayerRecord and Guildrun_BroadcastPlayer then
                local me = Guildrun_UpdateLocalPlayerRecord()
                if me then Guildrun_BroadcastPlayer(me) end
            end
        end
    end
end

function GuildrunUI.Refresh()
    if not mainFrame or not mainFrame:IsShown() then return end
    local db = GuildrunDB and GuildrunDB.players or {}

    local myCharKey, myName = Guildrun_GetFullPlayerName("player")
    local playerList = {}
    local highestLevel = 1
    for key, p in pairs(db) do
        if not (demoLoaded and (key == myCharKey or p.name == myName)) then
            table.insert(playerList, p)
            if (p.level or 1) > highestLevel then
                highestLevel = p.level
            end
        end
    end

    if mainFrame.statusText then
        local inGuild = (Guildrun_IsInGuild and Guildrun_IsInGuild()) or (IsInGuild and IsInGuild()) or (GetGuildInfo and GetGuildInfo("player") ~= nil)
        local pCount = #playerList
        if inGuild then
            local guildName = (Guildrun_GetGuildName and Guildrun_GetGuildName()) or (GetGuildInfo and GetGuildInfo("player")) or "Gilde"
            mainFrame.statusText:SetText(string.format("Gilde: |cffffd100%s|r  |  Teilnehmer im Levelrennen: |cff00e5ff%d|r  |  Klicke [Aktualisieren] zum Abgleichen", guildName, pCount))
        else
            mainFrame.statusText:SetText("|cffff5555Hinweis: Du bist in keiner Gilde! Tritt der Gilde bei, um am Gilden-Levelrennen teilzunehmen.|r")
        end
    end

    if currentTab == "TRACK" then
        mainFrame.trackContainer:Show()
        mainFrame.statsContainer:Hide()
        mainFrame.tabTrack:LockHighlight()
        mainFrame.tabStats:UnlockHighlight()
    else
        mainFrame.trackContainer:Hide()
        mainFrame.statsContainer:Show()
        mainFrame.tabTrack:UnlockHighlight()
        mainFrame.tabStats:LockHighlight()
        GuildrunUI.RefreshStats(playerList)
        return
    end

    local content = mainFrame.content
    if mainFrame.scrollFrame and mainFrame.scrollFrame.SetVerticalScroll then
        mainFrame.scrollFrame:SetVerticalScroll(0)
    end
    table.sort(playerList, function(a, b)
        local la = (a.level or 1) + (a.progress or 0)
        local lb = (b.level or 1) + (b.progress or 0)
        return la > lb
    end)

    local visibleMaxLevel = math.min(60, math.max(15, math.ceil((highestLevel + 2) / 5) * 5))
    if highestLevel >= 58 then visibleMaxLevel = 60 end

    if mainFrame.limitBadge then
        mainFrame.limitBadge:SetText(string.format("|cff00e5ffStrecke:|r bis |cffffcc00Level %d|r  (Max 60)", visibleMaxLevel))
    end

    for _, marker in pairs(scaleMarkers) do marker:Hide() end
    local scaleBar = mainFrame.scaleBar
    local markerIdx = 1

    -- Markierung fuer Startpunkt: Level 1
    local m1 = scaleMarkers[markerIdx]
    if not m1 then
        m1 = CreateFrame("Frame", nil, scaleBar)
        m1:SetSize(80, 28)
        m1.line = m1:CreateTexture(nil, "OVERLAY")
        m1.line:SetSize(1, 28)
        m1.line:SetPoint("LEFT", 0, 0)
        m1.line:SetColorTexture(1.0, 0.8, 0.2, 0.6)

        m1.text = m1:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        m1.text:SetPoint("LEFT", m1.line, "RIGHT", 4, 0)
        scaleMarkers[markerIdx] = m1
    end
    m1:ClearAllPoints()
    m1:SetPoint("LEFT", scaleBar, "LEFT", TRACK_START_X, 0)
    m1.text:SetText("|cffffcc00Lvl 1|r")
    m1:Show()
    markerIdx = markerIdx + 1

    for lvl = 10, 60, 10 do
        if lvl <= visibleMaxLevel then
            local marker = scaleMarkers[markerIdx]
            if not marker then
                marker = CreateFrame("Frame", nil, scaleBar)
                marker:SetSize(80, 28)
                marker.line = marker:CreateTexture(nil, "OVERLAY")
                marker.line:SetSize(1, 28)
                marker.line:SetPoint("LEFT", 0, 0)
                marker.line:SetColorTexture(1.0, 0.8, 0.2, 0.6)

                marker.text = marker:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                marker.text:SetPoint("LEFT", marker.line, "RIGHT", 4, 0)
                scaleMarkers[markerIdx] = marker
            end

            local ratio = (lvl - 1) / (visibleMaxLevel - 1)
            local posX = TRACK_START_X + (ratio * (TRACK_WIDTH - 24))
            marker:ClearAllPoints()
            marker:SetPoint("LEFT", scaleBar, "LEFT", posX, 0)
            marker.text:SetText(string.format("|cffffcc00Lvl %d|r", lvl))
            marker:Show()
            markerIdx = markerIdx + 1
        end
    end

    for _, row in pairs(trackRows) do row:Hide() end
    local rowHeight = 68
    local yOffset = 0
    local template = BackdropTemplateMixin and "BackdropTemplate" or nil

    for idx, player in ipairs(playerList) do
        local row = trackRows[idx]
        if not row then
            row = CreateFrame("Frame", nil, content, template)
            row:SetSize(905, rowHeight)
            row:EnableMouseWheel(true)
            row:SetScript("OnMouseWheel", function(self, delta)
                if mainFrame.scrollFrame and mainFrame.scrollFrame:GetScript("OnMouseWheel") then
                    mainFrame.scrollFrame:GetScript("OnMouseWheel")(mainFrame.scrollFrame, delta)
                end
            end)
            ApplyBackdropSafe(row, "Interface\\Buttons\\WHITE8X8", "Interface\\Tooltips\\UI-Tooltip-Border", 10)

            row.avatar = row:CreateTexture(nil, "ARTWORK")
            row.avatar:SetSize(42, 42)
            row.avatar:SetPoint("LEFT", 8, 0)
            row.avatar:SetTexCoord(0.08, 0.92, 0.08, 0.92)

            -- Zeile 1: Vollstaendiger Name (Klassenfarbe)
            row.nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            row.nameText:SetPoint("TOPLEFT", row.avatar, "TOPRIGHT", 10, 6)
            row.nameText:SetWidth(205)
            row.nameText:SetJustifyH("LEFT")
            row.nameText:SetWordWrap(false)

            -- Zeile 2: Level & EP-Fortschritt
            row.levelText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            row.levelText:SetPoint("TOPLEFT", row.nameText, "BOTTOMLEFT", 0, -2)
            row.levelText:SetWidth(205)
            row.levelText:SetJustifyH("LEFT")
            row.levelText:SetWordWrap(false)

            -- Zeile 3: Standort / Zone
            row.zoneText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            row.zoneText:SetPoint("TOPLEFT", row.levelText, "BOTTOMLEFT", 0, -2)
            row.zoneText:SetWidth(205)
            row.zoneText:SetJustifyH("LEFT")
            row.zoneText:SetWordWrap(false)

            -- Zeile 4: Reittier & Tode
            row.infoText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            row.infoText:SetPoint("TOPLEFT", row.zoneText, "BOTTOMLEFT", 0, -2)
            row.infoText:SetWidth(205)
            row.infoText:SetJustifyH("LEFT")
            row.infoText:SetWordWrap(false)

            -- Entfernen-Button (rotes X) fuer Twinks / inaktive Charaktere
            local delBtn = CreateFrame("Button", nil, row)
            delBtn:SetSize(16, 16)
            delBtn:SetPoint("LEFT", row, "LEFT", 244, 18)
            delBtn:SetNormalTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up")
            delBtn:SetHighlightTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Highlight")
            delBtn:SetPushedTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Down")
            delBtn:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:AddLine("|cffff5555Charakter entfernen|r", 1, 1, 1)
                GameTooltip:AddLine("Entfernt diesen Charakter aus deiner lokalen Rennliste.", 0.8, 0.8, 0.8, true)
                GameTooltip:Show()
            end)
            delBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
            row.delBtn = delBtn

            row.trackRail = row:CreateTexture(nil, "BACKGROUND", nil, 1)
            row.trackRail:SetPoint("LEFT", row, "LEFT", TRACK_START_X, 0)
            row.trackRail:SetSize(TRACK_WIDTH, 20)
            row.trackRail:SetColorTexture(0.05, 0.03, 0.02, 0.9)

            row.railLineTop = row:CreateTexture(nil, "BACKGROUND", nil, 2)
            row.railLineTop:SetPoint("TOPLEFT", row.trackRail, "TOPLEFT", 0, -2)
            row.railLineTop:SetPoint("TOPRIGHT", row.trackRail, "TOPRIGHT", 0, -2)
            row.railLineTop:SetHeight(2)
            row.railLineTop:SetColorTexture(0.35, 0.25, 0.15, 0.8)

            row.railLineBot = row:CreateTexture(nil, "BACKGROUND", nil, 2)
            row.railLineBot:SetPoint("BOTTOMLEFT", row.trackRail, "BOTTOMLEFT", 0, 2)
            row.railLineBot:SetPoint("BOTTOMRIGHT", row.trackRail, "BOTTOMRIGHT", 0, 2)
            row.railLineBot:SetHeight(2)
            row.railLineBot:SetColorTexture(0.35, 0.25, 0.15, 0.8)

            row.fill = row:CreateTexture(nil, "BORDER", nil, 1)
            row.fill:SetPoint("LEFT", row.trackRail, "LEFT", 0, 0)
            row.fill:SetHeight(16)
            row.fill:SetColorTexture(0.9, 0.65, 0.1, 0.4)

            row.horse = CreateFrame("Button", nil, row)
            row.horse:SetSize(36, 36)
            
            row.horseChassis = row.horse:CreateTexture(nil, "BACKGROUND")
            row.horseChassis:SetAllPoints()
            row.horseChassis:SetColorTexture(0.1, 0.05, 0.02, 1)

            row.horseBorder = row.horse:CreateTexture(nil, "BORDER")
            row.horseBorder:SetPoint("TOPLEFT", -2, 2)
            row.horseBorder:SetPoint("BOTTOMRIGHT", 2, -2)
            row.horseBorder:SetColorTexture(1.0, 0.8, 0.2, 0.9)

            row.horseIcon = row.horse:CreateTexture(nil, "ARTWORK")
            row.horseIcon:SetPoint("TOPLEFT", 2, -2)
            row.horseIcon:SetPoint("BOTTOMRIGHT", -2, 2)
            row.horseIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

            row.levelBadge = row.horse:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            row.levelBadge:SetPoint("BOTTOMRIGHT", row.horse, "BOTTOMRIGHT", 2, -4)

            row.horse:SetScript("OnEnter", function(self)
                if not self.playerData then return end
                local p = self.playerData
                local mInfo = MOUNT_LOOKUP[p.mount or "HORSE"] or MOUNT_LOOKUP["HORSE"]
                
                GameTooltip:SetOwner(self, "ANCHOR_TOP")
                local titleStr = GetCleanDisplayName(p.name, p.realm)
                GameTooltip:AddLine(string.format("|cffffd100%s|r  |cffffffff(Level %d)|r", titleStr, p.level or 1))
                GameTooltip:AddLine("Reittier: |cffffcc00" .. mInfo.name .. "|r", 1, 1, 1)
                
                local pct = p.xpPercent or (p.progress and math.floor(p.progress * 100)) or 0
                GameTooltip:AddLine(string.format("Fortschritt: |cff00e5ffLevel %d + %d%%|r", p.level or 1, pct), 1, 1, 1)
                
                local timeStr = p.totalTimeFormatted or (p.totalTime and Guildrun_FormatTime(p.totalTime)) or "Wird ermittelt..."
                GameTooltip:AddLine("Gesamtspielzeit: |cffffffff" .. timeStr .. "|r", 1, 1, 1)
                GameTooltip:AddLine("Aktuelle Zone: |cffffffff" .. (p.zone or "Welt") .. "|r", 1, 1, 1)
                GameTooltip:AddLine(string.format("Tode: |cffff5555%d|r", p.deaths or 0), 1, 1, 1)
                GameTooltip:Show()
            end)
            row.horse:SetScript("OnLeave", function() GameTooltip:Hide() end)

            row.pennants = {}
            for lvl = 10, 60, 10 do
                local pen = CreateFrame("Button", nil, row)
                pen:SetSize(22, 22)
                
                local penTex = pen:CreateTexture(nil, "OVERLAY")
                penTex:SetAllPoints()
                penTex:SetTexture("Interface\\Icons\\INV_Banner_03")
                penTex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                pen.icon = penTex
                pen.level = lvl

                pen:SetScript("OnEnter", function(self)
                    GameTooltip:SetOwner(self, "ANCHOR_TOP")
                    GameTooltip:AddLine(string.format("|cffffcc00Meilenstein Level %d|r", self.level))
                    if self.msData then
                        GameTooltip:AddLine("Spielzeit (/played): " .. (self.msData.timeFormatted or "Unbekannt"), 1, 1, 1)
                        GameTooltip:AddLine("Erreicht in Zone: " .. (self.msData.zone or "Unbekannt"), 1, 1, 1)
                        GameTooltip:AddLine("Tode bis dahin: " .. (self.msData.deaths or 0), 1, 0.3, 0.3)
                    else
                        GameTooltip:AddLine("Noch nicht erreicht", 0.6, 0.6, 0.6)
                    end
                    GameTooltip:Show()
                end)
                pen:SetScript("OnLeave", function() GameTooltip:Hide() end)
                row.pennants[lvl] = pen
            end

            trackRows[idx] = row
        end

        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -yOffset)
        if row.SetBackdropColor then
            row:SetBackdropColor(0.07, 0.05, 0.03, (idx % 2 == 0) and 0.85 or 0.65)
        end
        row:Show()

        local colorHex = CLASS_COLORS[player.class] or "FFFFFF"
        SetClassAvatarTexture(row.avatar, player.class)

        local mountInfo = MOUNT_LOOKUP[player.mount or "HORSE"] or MOUNT_LOOKUP["HORSE"]
        local mountIcon = mountInfo.icon

        local pct = player.xpPercent or (player.progress and math.floor(player.progress * 100)) or 0
        local displayName = GetCleanDisplayName(player.name, player.realm)
        -- Zeile 1: Name in Klassenfarbe (vollstaendig ohne Kuerzung)
        row.nameText:SetText(string.format("|cff%s%s|r", colorHex, displayName))
        -- Zeile 2: Level & EP-Fortschritt
        row.levelText:SetText(string.format("|cffffd100Level %d|r  |cff00e5ff(+%d%%)|r", player.level or 1, pct))
        -- Zeile 3: Standort
        local locStr = player.zone or "Welt"
        if player.subzone and player.subzone ~= "" and player.subzone ~= player.zone and (#locStr + #player.subzone < 26) then
            locStr = locStr .. " (" .. player.subzone .. ")"
        end
        row.zoneText:SetText(string.format("|cffffffff%s|r", locStr))
        -- Zeile 4: Reittier + Tode
        row.infoText:SetText(string.format("|cffffcc00%s|r  *  |cffff5555%d Tode|r", mountInfo.name:match("^[^(]+"), player.deaths or 0))

        if row.delBtn then
            local myCharKey, myName = Guildrun_GetFullPlayerName("player")
            local pKey = player.key or player.name
            if pKey == myCharKey or pKey == myName or (pKey:gsub("-", " ") == myCharKey:gsub("-", " ")) then
                row.delBtn:Hide()
            else
                row.delBtn:Show()
                row.delBtn:SetScript("OnClick", function()
                    if GuildrunDB and GuildrunDB.players then
                        GuildrunDB.players[pKey] = nil
                        if GuildrunDB.characters then
                            GuildrunDB.characters[pKey] = nil
                        end
                        GuildrunUI.Refresh()
                        print(string.format("|cff00ff00[Guildrun]|r Charakter |cffffd100%s|r wurde aus deiner Rennliste entfernt!", pKey))
                    end
                end)
            end
        end

        row.horse.playerData = player

        local curEffectiveLevel = math.min(visibleMaxLevel, (player.level or 1) + (player.progress or 0))
        local ratio = math.min(1.0, math.max(0, (curEffectiveLevel - 1) / (visibleMaxLevel - 1)))
        local horseX = TRACK_START_X + (ratio * (TRACK_WIDTH - 36))

        row.horse:ClearAllPoints()
        row.horse:SetPoint("LEFT", row, "LEFT", horseX, 0)
        row.horseIcon:SetTexture(mountIcon)
        row.levelBadge:SetText(string.format("|cffffffff%d|r", player.level or 1))

        row.fill:SetWidth(math.max(2, ratio * TRACK_WIDTH))

        for lvl = 10, 60, 10 do
            local pen = row.pennants[lvl]
            if lvl <= visibleMaxLevel then
                local penRatio = (lvl - 1) / (visibleMaxLevel - 1)
                local penX = TRACK_START_X + (penRatio * (TRACK_WIDTH - 22))
                pen:ClearAllPoints()
                pen:SetPoint("LEFT", row, "LEFT", penX, 16)
                pen:Show()

                local msData = player.milestones and player.milestones[lvl]
                if msData or (player.level >= lvl) then
                    pen.icon:SetVertexColor(1.0, 0.85, 0.1)
                    pen.msData = msData or {
                        timeFormatted = "Erreicht",
                        zone = player.zone,
                        deaths = player.deaths or 0
                    }
                else
                    pen.icon:SetVertexColor(0.3, 0.3, 0.3, 0.4)
                    pen.msData = nil
                end
            else
                pen:Hide()
            end
        end

        yOffset = yOffset + rowHeight + 6
    end

    content:SetHeight(math.max(100, yOffset + 20))
end

-- STATISTIKEN / HALL OF FAME IM ADDON
function GuildrunUI.RefreshStats(playerList)
    if not statBoxes or #statBoxes == 0 then return end

    local rankColors = { "ffd700", "c0c0c0", "cd7f32", "8c735d", "8c735d" }

    -- 1. Hoechstes Level
    local listLevel = {}
    for _, p in ipairs(playerList) do table.insert(listLevel, p) end
    table.sort(listLevel, function(a, b)
        local la = (a.level or 1) + (a.progress or 0)
        local lb = (b.level or 1) + (b.progress or 0)
        return la > lb
    end)

    for r = 1, 5 do
        local row = statBoxes[1].rows[r]
        local p = listLevel[r]
        if p then
            row.rankText:SetText(string.format("|cff%s#%d|r", rankColors[r], r))
            SetClassAvatarTexture(row.avatar, p.class)
            local colorHex = CLASS_COLORS[p.class] or "FFFFFF"
            local nameStr = GetCleanDisplayName(p.name, p.realm)
            row.nameText:SetText(string.format("|cff%s%s|r", colorHex, nameStr))
            row.valText:SetText(string.format("|cffffcc00Level %d|r", p.level or 1))
            row:Show()
        else
            row:Hide()
        end
    end

    -- 2. Speedrunner (/played)
    local listSpeed = {}
    for _, p in ipairs(playerList) do
        if (p.totalTime or 0) > 0 then table.insert(listSpeed, p) end
    end
    table.sort(listSpeed, function(a, b)
        local rateA = ((a.level or 1) + (a.progress or 0)) / (a.totalTime / 3600)
        local rateB = ((b.level or 1) + (b.progress or 0)) / (b.totalTime / 3600)
        return rateA > rateB
    end)
    local speedSource = #listSpeed > 0 and listSpeed or listLevel

    for r = 1, 5 do
        local row = statBoxes[2].rows[r]
        local p = speedSource[r]
        if p then
            row.rankText:SetText(string.format("|cff%s#%d|r", rankColors[r], r))
            SetClassAvatarTexture(row.avatar, p.class)
            local colorHex = CLASS_COLORS[p.class] or "FFFFFF"
            local nameStr = GetCleanDisplayName(p.name, p.realm)
            row.nameText:SetText(string.format("|cff%s%s|r", colorHex, nameStr))
            local tStr = p.totalTimeFormatted or (p.totalTime and Guildrun_FormatTime(p.totalTime)) or "0m"
            row.valText:SetText(string.format("|cff00e5ff%s|r", tStr))
            row:Show()
        else
            row:Hide()
        end
    end

    -- 3. Meiste Tode
    local listDeaths = {}
    for _, p in ipairs(playerList) do table.insert(listDeaths, p) end
    table.sort(listDeaths, function(a, b) return (a.deaths or 0) > (b.deaths or 0) end)

    for r = 1, 5 do
        local row = statBoxes[3].rows[r]
        local p = listDeaths[r]
        if p then
            row.rankText:SetText(string.format("|cff%s#%d|r", rankColors[r], r))
            SetClassAvatarTexture(row.avatar, p.class)
            local colorHex = CLASS_COLORS[p.class] or "FFFFFF"
            local nameStr = GetCleanDisplayName(p.name, p.realm)
            row.nameText:SetText(string.format("|cff%s%s|r", colorHex, nameStr))
            row.valText:SetText(string.format("|cffff5555|TInterface\\Icons\\Ability_Creature_Cursed_02:12:12:0:0|t %d Tode|r", p.deaths or 0))
            row:Show()
        else
            row:Hide()
        end
    end

    -- 4. Top Chars (Account)
    local accountGroups = {}
    for _, p in ipairs(playerList) do
        local acc = p.account or p.name
        if not accountGroups[acc] then
            accountGroups[acc] = { best = p, count = 0 }
        end
        accountGroups[acc].count = accountGroups[acc].count + 1
        local curProg = (accountGroups[acc].best.level or 1) + (accountGroups[acc].best.progress or 0)
        local thisProg = (p.level or 1) + (p.progress or 0)
        if thisProg > curProg then
            accountGroups[acc].best = p
        end
    end

    local listAcc = {}
    for _, grp in pairs(accountGroups) do table.insert(listAcc, grp) end
    table.sort(listAcc, function(a, b)
        local la = (a.best.level or 1) + (a.best.progress or 0)
        local lb = (b.best.level or 1) + (b.best.progress or 0)
        return la > lb
    end)

    for r = 1, 5 do
        local row = statBoxes[4].rows[r]
        local grp = listAcc[r]
        if grp then
            local p = grp.best
            row.rankText:SetText(string.format("|cff%s#%d|r", rankColors[r], r))
            local mInfo = MOUNT_LOOKUP[p.mount or "HORSE"] or MOUNT_LOOKUP["HORSE"]
            row.avatar:SetTexture(mInfo.icon)
            local colorHex = CLASS_COLORS[p.class] or "FFFFFF"
            local charBadge = grp.count == 1 and "(1 Char)" or string.format("(%d Chars)", grp.count)
            local nameStr = GetCleanDisplayName(p.name, p.realm)
            row.nameText:SetText(string.format("|cff%s%s|r", colorHex, nameStr))
            row.valText:SetText(string.format("|cffffcc00Level %d|r  |cffaaaaaa%s|r", p.level or 1, charBadge))
            row:Show()
        else
            row:Hide()
        end
    end
end

-- ==========================================
-- MINIMAP BUTTON
-- ==========================================
local minimapBtn = nil

function GuildrunUI.CreateMinimapButton()
    if minimapBtn then return minimapBtn end

    GuildrunDB.settings = GuildrunDB.settings or {}
    GuildrunDB.settings.minimapPos = GuildrunDB.settings.minimapPos or 215

    local btn = CreateFrame("Button", "GuildrunMinimapButton", Minimap)
    btn:SetSize(32, 32)
    btn:SetFrameStrata("HIGH")
    btn:SetFrameLevel(10)
    btn:EnableMouse(true)
    btn:SetMovable(true)
    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp", "MiddleButtonUp")
    btn:RegisterForDrag("LeftButton")

    -- Hintergrund
    local bg = btn:CreateTexture(nil, "BACKGROUND")
    bg:SetSize(20, 20)
    bg:SetPoint("CENTER", 0, 0)
    bg:SetTexture("Interface\\Icons\\Ability_Mount_RidingHorse")
    bg:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    btn.icon = bg

    -- Runder Rand passend zu WoW Minimap
    local border = btn:CreateTexture(nil, "OVERLAY")
    border:SetSize(52, 52)
    border:SetPoint("TOPLEFT", 0, 0)
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

    local function UpdatePosition()
        local angle = math.rad(GuildrunDB.settings.minimapPos or 215)
        local radius = (Minimap:GetWidth() / 2) + 10
        local x = math.cos(angle) * radius
        local y = math.sin(angle) * radius
        btn:ClearAllPoints()
        btn:SetPoint("CENTER", Minimap, "CENTER", x, y)
    end

    btn:SetScript("OnDragStart", function(self)
        self:SetScript("OnUpdate", function()
            local mx, my = Minimap:GetCenter()
            local px, py = GetCursorPosition()
            local scale = UIParent:GetEffectiveScale()
            px, py = px / scale, py / scale
            local angle = math.deg(math.atan2(py - my, px - mx))
            if angle < 0 then angle = angle + 360 end
            GuildrunDB.settings.minimapPos = angle
            UpdatePosition()
        end)
    end)

    btn:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
    end)

    btn:SetScript("OnClick", function(self, button)
        if button == "MiddleButton" then
            print("|cffffaa00[Guildrun]|r Interface wird neu geladen...")
            C_UI.Reload()
        elseif button == "RightButton" then
            GuildrunUI.ShowMountDialog()
        else
            GuildrunUI.Toggle()
        end
    end)

    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("|cffffd100Guildrun - Das Dunkelmond-Derby|r")
        GameTooltip:AddLine("|cff00e5ffDunkelmond-Gildenrennen & Meilensteine|r", 1, 1, 1)
        GameTooltip:AddLine("|cffffffffLinksklick:|r Rennbahn oeffnen / schliessen", 1, 1, 1)
        GameTooltip:AddLine("|cffffffffRechtsklick:|r Reittier auswaehlen", 1, 1, 1)
        GameTooltip:AddLine("|cff00ff00Mittelklick:|r /reload (Interface neu laden)", 1, 1, 1)
        GameTooltip:AddLine("|cffaaaaaaGedrueckt halten & Ziehen zum Verschieben|r", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)

    btn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    UpdatePosition()
    minimapBtn = btn
    return btn
end
