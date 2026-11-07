--[[
    Guildrun - Live Gilden-Levelrennen im Dunkelmond-Jahrmarkt-Stil
    Kompatibel mit Retail (11.x), Classic Era (1.15.x), Cataclysm Classic und WoW Forever (1.60.1)
    Kommunikation ausschließlich über das native Blizzard Gilden-Addon-Protokoll (SendAddonMessage / "GUILD")
--]]

GuildrunDB = GuildrunDB or {
    players = {},
    characters = {},
    selectedMount = "HORSE",
    settings = {
        sound = true,
        broadcastInterval = 15,
        minimapPos = 215,
    }
}

local ADDON_PREFIX = "GUILDRUN"
local frame = CreateFrame("Frame", "GuildrunCoreFrame")

-- Sofortige Prefix-Registrierung beim Laden der Datei
local function RegisterAddonPrefixSafe()
    if C_ChatInfo and C_ChatInfo.RegisterAddonPrefix then
        pcall(C_ChatInfo.RegisterAddonPrefix, ADDON_PREFIX)
    elseif RegisterAddonMessagePrefix then
        pcall(RegisterAddonMessagePrefix, ADDON_PREFIX)
    end
    if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
        pcall(C_ChatInfo.RegisterAddonMessagePrefix, ADDON_PREFIX)
    end
end
RegisterAddonPrefixSafe()

-- C_Timer Fallback fuer aeltere WoW-Clients
if not C_Timer then C_Timer = {} end
if not C_Timer.After then
    C_Timer.After = function(seconds, func)
        local f = CreateFrame("Frame")
        local elapsed = 0
        f:SetScript("OnUpdate", function(self, dt)
            elapsed = elapsed + dt
            if elapsed >= seconds then
                self:SetScript("OnUpdate", nil)
                func()
            end
        end)
    end
end

-- Prueft zuverlaessig, ob der Spieler in einer Gilde ist (kompatibel mit WoW Forever 1.12 und Retail)
function Guildrun_IsInGuild()
    if IsInGuild and IsInGuild() then
        return true
    end
    if GetGuildInfo then
        local gName = GetGuildInfo("player")
        if gName and gName ~= "" then
            return true
        end
    end
    return false
end

-- Liefert den aktuellen Gildennamen
function Guildrun_GetGuildName()
    if GetGuildInfo then
        local gName = GetGuildInfo("player")
        if gName and gName ~= "" then
            return gName
        end
    end
    return nil
end

local localTotalTime = 0
local localDeaths = 0

-- Fragt die offiziellen Server-Tode direkt von Blizzard ab (Statistik-ID 60 = Tode)
function Guildrun_GetServerDeaths()
    if GetStatistic then
        local raw = GetStatistic(60)
        if raw and raw ~= "" and raw ~= "--" then
            local clean = tostring(raw):gsub("[%.,]", "")
            local n = tonumber(clean)
            if n then return n end
        end
    end
    return nil
end

-- Liefert den vollstaendigen Charakternamen (unterstuetzt auch Nachnamen/Bindestriche)
function Guildrun_GetFullPlayerName(unit)
    unit = unit or "player"
    local first, last = UnitName(unit)
    first = first or "Unbekannt"

    local currentRealm = GetRealmName()
    if last and last ~= "" and last ~= currentRealm and last ~= "WoWForever" and last ~= "93" then
        return first .. "-" .. last, first, last
    end

    if GetUnitName then
        local full = GetUnitName(unit, true)
        if full and full ~= "" and full:find("-") then
            local f, l = full:match("^([^-]+)-(.*)$")
            if f and l and l ~= currentRealm and l ~= "WoWForever" and l ~= "93" then
                return f .. "-" .. l, f, l
            end
        end
    end

    return first, first, nil
end

-- Sicherer Account-Identifikator fuer die Hall of Fame
local function GetAccountIdentifier()
    GuildrunDB = GuildrunDB or {}
    if not GuildrunDB.accountId or GuildrunDB.accountId == "" then
        local guid = UnitGUID("player") or ""
        local realm = GetRealmName() or "Realm"
        local raw = guid .. realm .. tostring(time())
        local hash = 5381
        for i = 1, #raw do
            hash = ((hash * 33) + string.byte(raw, i)) % 2147483647
        end
        GuildrunDB.accountId = string.format("ACC_%x", hash)
    end
    return GuildrunDB.accountId
end

-- Zonen-Ermittlung
local function GetSafeZoneInfo()
    local zone = "Unbekannt"
    local subzone = ""

    local rz = GetRealZoneText and GetRealZoneText()
    local z = GetZoneText and GetZoneText()
    local sz = GetSubZoneText and GetSubZoneText()

    if rz and rz ~= "" then
        zone = rz
    elseif z and z ~= "" then
        zone = z
    end

    if sz and sz ~= "" then
        subzone = sz
    end

    if (zone == "Unbekannt" or zone == "" or not zone) and C_Map and C_Map.GetBestMapForUnit then
        local mapID = C_Map.GetBestMapForUnit("player")
        if mapID then
            local mapInfo = C_Map.GetMapInfo(mapID)
            if mapInfo and mapInfo.name then
                zone = mapInfo.name
            end
        end
    end

    -- Anfuehrungszeichen und Backslashes entfernen (100% sicher mit tostring)
    zone = tostring(zone or "Unbekannt"):gsub('["\\]', '')
    subzone = tostring(subzone or ""):gsub('["\\]', '')

    return zone, subzone
end

-- Zeit-Formatierung
function Guildrun_FormatTime(seconds)
    if not seconds or seconds <= 0 then return "0m" end
    local days = math.floor(seconds / 86400)
    local hours = math.floor((seconds % 86400) / 3600)
    local mins = math.floor((seconds % 3600) / 60)
    if days > 0 then
        return string.format("%dt %dh %dm", days, hours, mins)
    elseif hours > 0 then
        return string.format("%dh %dm", hours, mins)
    else
        return string.format("%dm", mins)
    end
end

-- Aktuelle Spielerdaten erfassen
local function GetCurrentPlayerData()
    local fullName, firstName, lastName = Guildrun_GetFullPlayerName("player")
    local _, raceEn = UnitRace("player")
    local _, classEn = UnitClass("player")
    local level = UnitLevel("player") or 1
    local zone, subzone = GetSafeZoneInfo()

    local maxExp = UnitXPMax("player") or 0
    local curExp = UnitXP("player") or 0
    local progress = 0
    local xpPercent = 0
    if maxExp and maxExp > 0 then
        progress = math.floor((curExp / maxExp) * 100) / 100
        xpPercent = math.floor((curExp / maxExp) * 100)
    end

    local charCfg = GuildrunDB.characters and GuildrunDB.characters[fullName]
    local mount = (charCfg and charCfg.mount) or GuildrunDB.selectedMount or "HORSE"

    return {
        key = fullName,
        name = fullName,
        firstName = firstName,
        surname = lastName,
        realm = "",
        account = GetAccountIdentifier(),
        race = raceEn or "Human",
        class = classEn or "WARRIOR",
        level = level,
        progress = progress,
        curExp = curExp,
        maxExp = maxExp,
        xpPercent = xpPercent,
        mount = mount,
        totalTime = localTotalTime,
        zone = zone,
        subzone = subzone,
        deaths = localDeaths,
        lastSeen = time()
    }
end

-- Lokalen Spieler-Eintrag in der Datenbank aktualisieren
function Guildrun_UpdateLocalPlayerRecord()
    local data = GetCurrentPlayerData()
    GuildrunDB.players = GuildrunDB.players or {}
    GuildrunDB.characters = GuildrunDB.characters or {}
    local charKey = data.key

    if not GuildrunDB.characters[charKey] then
        GuildrunDB.characters[charKey] = {
            key = charKey,
            name = data.name,
            mount = data.mount or "HORSE",
        }
    end

    if not GuildrunDB.players[charKey] then
        GuildrunDB.players[charKey] = {
            key = charKey,
            name = data.name,
            realm = "",
            surname = data.surname,
            account = data.account,
            race = data.race,
            class = data.class,
            milestones = {}
        }
    end

    local entry = GuildrunDB.players[charKey]
    entry.key = charKey
    entry.name = data.name
    entry.realm = ""
    entry.surname = data.surname
    entry.account = data.account
    entry.race = data.race
    entry.class = data.class
    entry.level = data.level
    entry.progress = data.progress
    entry.curExp = data.curExp
    entry.maxExp = data.maxExp
    entry.xpPercent = data.xpPercent
    entry.mount = data.mount
    entry.totalTime = data.totalTime or entry.totalTime or 0
    entry.totalTimeFormatted = Guildrun_FormatTime(entry.totalTime)
    entry.zone = data.zone
    entry.subzone = data.subzone
    local statDeaths = Guildrun_GetServerDeaths()
    if statDeaths ~= nil then
        localDeaths = math.max(localDeaths, statDeaths)
    end
    entry.deaths = localDeaths
    entry.lastSeen = data.lastSeen
    entry.isOnline = true
    entry.milestones = entry.milestones or {}

    -- Veralteten Eintrag mit unvollstaendigem Namen (nur Vorname) bereinigen
    if data.firstName and data.firstName ~= data.name and GuildrunDB.players[data.firstName] then
        local old = GuildrunDB.players[data.firstName]
        if old.class == data.class and old.race == data.race then
            GuildrunDB.players[data.firstName] = nil
        end
    end

    -- Meilensteine bei Level 10, 20, 30, 40, 50, 60 erfassen
    for lvl = 10, math.min(60, data.level), 10 do
        if not entry.milestones[lvl] and lvl <= data.level then
            entry.milestones[lvl] = {
                level = lvl,
                timeSeconds = entry.totalTime or 0,
                timeFormatted = Guildrun_FormatTime(entry.totalTime or 0),
                zone = data.zone,
                deaths = entry.deaths,
                timestamp = time()
            }
        elseif entry.milestones[lvl] and (entry.milestones[lvl].timeSeconds or 0) == 0 and (entry.totalTime or 0) > 0 then
            entry.milestones[lvl].timeSeconds = entry.totalTime
            entry.milestones[lvl].timeFormatted = Guildrun_FormatTime(entry.totalTime)
        end
    end

    if GuildrunUI and GuildrunUI.Refresh then
        GuildrunUI.Refresh()
    end

    return entry
end

-- Nativer Blizzard Gilden-Addon-Versand
function Guildrun_SendGuildMessage(msg)
    if not Guildrun_IsInGuild() then return false end
    if C_ChatInfo and C_ChatInfo.SendAddonMessage then
        local ok = pcall(C_ChatInfo.SendAddonMessage, ADDON_PREFIX, msg, "GUILD")
        if ok then return true end
    end
    if SendAddonMessage then
        local ok = pcall(SendAddonMessage, ADDON_PREFIX, msg, "GUILD")
        if ok then return true end
    end
    return false
end

-- Eigenen Spielerdatensatz an alle Gildenmitglieder senden
function Guildrun_BroadcastPlayer(entry)
    if not Guildrun_IsInGuild() then return end
    entry = entry or Guildrun_UpdateLocalPlayerRecord()
    if not entry then return end

    local msParts = {}
    if entry.milestones then
        for lvl, ms in pairs(entry.milestones) do
            local safeZone = (ms.zone or ""):gsub("[:@;]", "")
            table.insert(msParts, string.format("%d@%d@%s@%d", lvl, ms.timeSeconds or 0, safeZone, ms.deaths or 0))
        end
    end
    local msStr = table.concat(msParts, ";")

    local mountKey = entry.mount or "HORSE"
    local acc = entry.account or GetAccountIdentifier()
    local sendKey = (entry.key or entry.name or "Unbekannt"):gsub("[:;]", "")
    local safeZone = (entry.zone or ""):gsub("[:;]", "")

    local msg = string.format("SYNC:%s:%s:%s:%d:%.2f:%s:%d:%d:%d:%s:%s:%s",
        sendKey, entry.race or "Human", entry.class or "WARRIOR", entry.level or 1, entry.progress or 0, safeZone, entry.deaths or 0,
        entry.totalTime or 0, entry.xpPercent or 0, mountKey, acc, msStr
    )

    -- Laengencheck: Addon-Nachrichten duerfen maximal 255 Zeichen lang sein
    if #msg > 230 then
        msg = string.format("SYNC:%s:%s:%s:%d:%.2f:%s:%d:%d:%d:%s:%s:",
            sendKey, entry.race or "Human", entry.class or "WARRIOR", entry.level or 1, entry.progress or 0, safeZone, entry.deaths or 0,
            entry.totalTime or 0, entry.xpPercent or 0, mountKey, acc
        )
    end

    Guildrun_SendGuildMessage(msg)
end

-- Daten-Synchronisation von der Gilde anfordern
function Guildrun_RequestGuildSync()
    if RequestTimePlayed then
        pcall(RequestTimePlayed)
    end
    if not Guildrun_IsInGuild() then
        print("|cffff5555[Guildrun]|r Du bist in keiner Gilde! Tritt einer Gilde bei, um am Levelrennen teilzunehmen.|r")
        return
    end
    local me = Guildrun_UpdateLocalPlayerRecord()
    Guildrun_SendGuildMessage("REQ")
    if me then
        Guildrun_BroadcastPlayer(me)
    end
    print("|cffffaa00[Guildrun]|r Synchronisations-Anfrage an die Gilde gesendet!")
end

-- Hilfsfunktion: String zerlegen
local function SplitString(str, delim)
    local result = {}
    if not str then return result end
    if not delim or delim == "" then
        table.insert(result, str)
        return result
    end
    local start = 1
    local dLen = #delim
    while true do
        local pos = string.find(str, delim, start, true)
        if not pos then
            table.insert(result, string.sub(str, start))
            break
        end
        table.insert(result, string.sub(str, start, pos - 1))
        start = pos + dLen
    end
    return result
end

-- Eingehende Addon-Nachrichten verarbeiten
local function HandleAddonMessage(prefix, message, channel, sender)
    if prefix ~= ADDON_PREFIX then return end
    if channel ~= "GUILD" and channel ~= "PARTY" and channel ~= "RAID" and channel ~= "WHISPER" then
        -- Native Gilden-Addon-Kommunikation
    end

    local myCharKey, myName = Guildrun_GetFullPlayerName("player")
    local parts = SplitString(message, ":")
    local cmd = parts[1]

    -- 1. Synchronisations-Anforderung empfangen
    if cmd == "REQ" or cmd == "PING" then
        if Guildrun_IsInGuild() then
            local me = Guildrun_UpdateLocalPlayerRecord()
            if me then
                -- Jitter (0.1 - 0.4s) gegen gleichzeitiges Senden im selben Tick
                C_Timer.After(0.1 + (math.random(1, 4) * 0.1), function()
                    Guildrun_BroadcastPlayer(me)
                end)
            end
        end
        return
    end

    -- 2. Datenpaket (SYNC) empfangen
    if cmd == "SYNC" then
        -- Unterstuetzung fuer aeltere Versionen, falls zusaetzlicher Prefix im Paket war
        local offset = 0
        local knownRaces = { Human=true, Orc=true, Dwarf=true, NightElf=true, Undead=true, Tauren=true, Gnome=true, Troll=true, BloodElf=true, Draenei=true }
        if parts[3] and knownRaces[parts[3]] then
            offset = 1
        end

        local pRawName = parts[2 + offset]
        if not pRawName or pRawName == "" then return end

        local pKey = pRawName
        local pName = pRawName
        local pRealm = ""

        -- Filter: Eigene Nachrichten ignorieren
        if pKey == myCharKey or pKey == myName or (pKey:gsub("-", " ") == myCharKey:gsub("-", " ")) then
            return
        end
        local senderClean = sender
        if senderClean and senderClean:find("-") then
            local sFirst, sLast = senderClean:match("^([^-]+)-(.*)$")
            if sLast == GetRealmName() or sLast == "WoWForever" or sLast == "93" then
                senderClean = sFirst
            end
        end
        if sender == myName or sender == myCharKey or senderClean == myName or senderClean == myCharKey or (senderClean and senderClean:gsub("-", " ") == myCharKey:gsub("-", " ")) then
            return
        end

        local pRace = parts[3 + offset] or "Human"
        local pClass = parts[4 + offset] or "WARRIOR"
        local pLevel = tonumber(parts[5 + offset]) or 1
        local pProg = tonumber(parts[6 + offset]) or 0
        local pZone = parts[7 + offset] or ""
        local pDeaths = tonumber(parts[8 + offset]) or 0
        local pTime = tonumber(parts[9 + offset]) or 0
        local pXpPct = tonumber(parts[10 + offset]) or math.floor(pProg * 100)
        local pMount = parts[11 + offset] or "HORSE"
        local pAcc = parts[12 + offset] or "ACC_UNKNOWN"
        local msRaw = parts[13 + offset] or ""

        if string.find(pAcc, "@") then
            msRaw = pAcc
            pAcc = "ACC_UNKNOWN"
        end

        local isNew = not GuildrunDB.players[pKey]
        GuildrunDB.players[pKey] = GuildrunDB.players[pKey] or {}
        local p = GuildrunDB.players[pKey]
        p.key = pKey
        p.name = pName
        p.realm = pRealm
        p.account = pAcc
        p.race = pRace
        p.class = pClass
        p.level = pLevel
        p.progress = pProg
        p.xpPercent = pXpPct
        p.mount = pMount
        p.totalTime = pTime
        p.totalTimeFormatted = Guildrun_FormatTime(pTime)
        p.zone = pZone
        p.deaths = pDeaths
        p.lastSeen = time()
        p.isOnline = true
        p.milestones = p.milestones or {}
        -- Veraltete Meilensteine ueber dem aktuellen Level entfernen (z.B. nach Neustart auf Level 1)
        for mlvl, _ in pairs(p.milestones) do
            if mlvl > pLevel then
                p.milestones[mlvl] = nil
            end
        end

        if isNew then
            print(string.format("|cff00ff00[Guildrun Live]|r Gildenmitglied |cffffd100%s|r im Levelrennen! (Level %d, %s %s)", pName, pLevel, pRace, pClass))
            -- Handshake: Sofort antworten, damit der andere Teilnehmer uns auch sofort sieht!
            local me = Guildrun_UpdateLocalPlayerRecord()
            if me then
                C_Timer.After(0.3, function()
                    Guildrun_BroadcastPlayer(me)
                end)
            end
        end

        if msRaw ~= "" then
            for msEntry in string.gmatch(msRaw, "[^;]+") do
                local ml, mt, mz, md = string.match(msEntry, "(%d+)@(%d+)@([^@]*)@(%d+)")
                if ml then
                    local lvlNum = tonumber(ml)
                    local timeSec = tonumber(mt) or 0
                    p.milestones[lvlNum] = {
                        level = lvlNum,
                        timeSeconds = timeSec,
                        timeFormatted = Guildrun_FormatTime(timeSec),
                        zone = mz,
                        deaths = tonumber(md) or 0
                    }
                end
            end
        end

        if GuildrunUI and GuildrunUI.Refresh then
            GuildrunUI.Refresh()
        end
    end
end

-- Renndaten zuruecksetzen (fuer neuen Gilden-Wettbewerb)
function Guildrun_ResetRace()
    GuildrunDB.players = {}
    localDeaths = 0
    localTotalTime = 0
    Guildrun_UpdateLocalPlayerRecord()

    if GuildrunUI and GuildrunUI.Refresh then
        GuildrunUI.Refresh()
    end
    print("|cffffaa00[Guildrun]|r Alle Renn-Daten wurden erfolgreich zurueckgesetzt!")
end

-- Events registrieren
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("CHAT_MSG_ADDON")
frame:RegisterEvent("PLAYER_LEVEL_UP")
frame:RegisterEvent("PLAYER_DEAD")
frame:RegisterEvent("TIME_PLAYED_MSG")
frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
frame:RegisterEvent("ZONE_CHANGED")
frame:RegisterEvent("PLAYER_XP_UPDATE")
frame:RegisterEvent("GUILD_ROSTER_UPDATE")
frame:RegisterEvent("PLAYER_GUILD_UPDATE")
frame:RegisterEvent("CRITERIA_UPDATE")

-- Heartbeat-Timer fuer Spielzeit & periodischen Sync
local timer = 0
frame:SetScript("OnUpdate", function(self, elapsed)
    localTotalTime = localTotalTime + elapsed
    timer = timer + elapsed
    if timer >= 15 then
        timer = 0
        if Guildrun_IsInGuild() then
            local me = Guildrun_UpdateLocalPlayerRecord()
            Guildrun_BroadcastPlayer(me)
        end
    end
end)

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local addonName = ...
        if addonName == "Guildrun" then
            RegisterAddonPrefixSafe()

            GuildrunDB = GuildrunDB or {}
            GuildrunDB.players = GuildrunDB.players or {}
            GuildrunDB.characters = GuildrunDB.characters or {}
            GuildrunDB.selectedMount = GuildrunDB.selectedMount or "HORSE"
            GuildrunDB.settings = GuildrunDB.settings or {
                sound = true,
                broadcastInterval = 15,
                minimapPos = 215,
            }

            -- Migration von veralteten Datenfeldern
            for k, p in pairs(GuildrunDB.players) do
                local _, sur = k:match("^([^-]+)%-(.*)$")
                if sur and p.realm == sur then
                    p.name = k
                    p.realm = ""
                elseif p.realm == "WoWForever" or p.realm == "93" then
                    p.realm = ""
                end
            end
            for k, c in pairs(GuildrunDB.characters) do
                local _, sur = k:match("^([^-]+)%-(.*)$")
                if sur and c.realm == sur then
                    c.name = k
                    c.realm = nil
                elseif c.realm == "WoWForever" or c.realm == "93" then
                    c.realm = nil
                end
            end

            local charKey, name = Guildrun_GetFullPlayerName("player")
            local pEntry = GuildrunDB.players and (GuildrunDB.players[charKey] or GuildrunDB.players[name])
            if pEntry then
                localDeaths = pEntry.deaths or 0
                localTotalTime = pEntry.totalTime or 0
            end

            print("|cffffaa00[Guildrun]|r Geladen! Befehle: |cff00ff00/gr|r (UI) | |cff00ff00/gr sync|r (Sync) | |cff00ff00/gr mount|r (Reittier)")
            if GuildrunUI and GuildrunUI.CreateMinimapButton then
                GuildrunUI.CreateMinimapButton()
            end
        end
    elseif event == "PLAYER_LOGIN" then
        RegisterAddonPrefixSafe()

        local charKey, name = Guildrun_GetFullPlayerName("player")
        local pEntry = GuildrunDB.players and (GuildrunDB.players[charKey] or GuildrunDB.players[name])
        if pEntry then
            localDeaths = pEntry.deaths or 0
            localTotalTime = pEntry.totalTime or 0
        else
            localDeaths = 0
            localTotalTime = 0
        end

        local statDeaths = Guildrun_GetServerDeaths()
        if statDeaths ~= nil then
            localDeaths = math.max(localDeaths, statDeaths)
        end

        local me = Guildrun_UpdateLocalPlayerRecord()
        if Guildrun_IsInGuild() then
            C_Timer.After(1.5, function()
                local sD = Guildrun_GetServerDeaths()
                if sD ~= nil then
                    localDeaths = math.max(localDeaths, sD)
                    me = Guildrun_UpdateLocalPlayerRecord()
                end
                Guildrun_SendGuildMessage("REQ")
                if me then Guildrun_BroadcastPlayer(me) end
            end)
        end
    elseif event == "CHAT_MSG_ADDON" then
        local prefix, msg, channel, sender = ...
        HandleAddonMessage(prefix, msg, channel, sender)
    elseif event == "PLAYER_DEAD" then
        local statDeaths = Guildrun_GetServerDeaths()
        if statDeaths ~= nil then
            localDeaths = math.max(localDeaths + 1, statDeaths)
        else
            localDeaths = localDeaths + 1
        end
        local me = Guildrun_UpdateLocalPlayerRecord()
        Guildrun_BroadcastPlayer(me)
    elseif event == "PLAYER_LEVEL_UP" then
        local newLevel = ...
        local me = Guildrun_UpdateLocalPlayerRecord()
        Guildrun_BroadcastPlayer(me)
        if Guildrun_IsInGuild() then
            print(string.format("|cff00ff00[Guildrun]|r Glueckwunsch zu |cffffd100Level %d|r! Daten an die Gilde uebertragen.", newLevel or UnitLevel("player")))
        end
    elseif event == "TIME_PLAYED_MSG" then
        local totalTime, levelTime = ...
        if totalTime and totalTime > 0 then
            localTotalTime = totalTime
            local me = Guildrun_UpdateLocalPlayerRecord()
            if me and Guildrun_IsInGuild() then
                Guildrun_BroadcastPlayer(me)
            end
        end
    elseif event == "ZONE_CHANGED_NEW_AREA" or event == "ZONE_CHANGED" or event == "PLAYER_XP_UPDATE" or event == "GUILD_ROSTER_UPDATE" or event == "PLAYER_GUILD_UPDATE" or event == "CRITERIA_UPDATE" then
        Guildrun_UpdateLocalPlayerRecord()
        if (event == "GUILD_ROSTER_UPDATE" or event == "PLAYER_GUILD_UPDATE") and GuildrunUI and GuildrunUI.Refresh then
            GuildrunUI.Refresh()
        end
    end
end)

-- Sichere Trim-Funktion ohne Abhaengigkeit von globalem strtrim
local function SafeTrim(s)
    if not s then return "" end
    return (string.gsub(tostring(s), "^%s*(.-)%s*$", "%1"))
end

-- Slash-Befehle
SLASH_GUILDRUN1 = "/guildrun"
SLASH_GUILDRUN2 = "/gr"
SlashCmdList["GUILDRUN"] = function(msg)
    local raw = SafeTrim(msg or "")
    local cmd, arg = raw:match("^(%S+)%s*(.*)$")
    cmd = string.lower(cmd or "")
    arg = SafeTrim(arg or "")

    if cmd == "" or cmd == "ui" or cmd == "show" or cmd == "open" then
        if GuildrunUI and GuildrunUI.Toggle then
            GuildrunUI.Toggle()
        end
    elseif cmd == "reset" then
        Guildrun_ResetRace()
    elseif cmd == "remove" or cmd == "delete" or cmd == "del" or cmd == "rm" or cmd == "loeschen" or cmd == "entfernen" then
        if arg == "" then
            print("|cffffaa00[Guildrun]|r Verwendung: |cff00ff00/gr remove <Charaktername>|r")
            local charList = {}
            for k, _ in pairs(GuildrunDB.players or {}) do
                table.insert(charList, k)
            end
            if #charList > 0 then
                print("|cffaaaaaaIn deiner Rennliste:|r |cffffd100" .. table.concat(charList, ", ") .. "|r")
                print("|cffaaaaaaTipp: Du kannst auch nur den Vor- oder Nachnamen eingeben (z.B. /gr remove Charname).|r")
            else
                print("|cffaaaaaa(Keine Charaktere in der Rennliste vorhanden)|r")
            end
            return
        end

        local myCharKey, myName = Guildrun_GetFullPlayerName("player")
        local targetLower = string.lower(arg)
        local targetClean = targetLower:gsub("[-_ ]", "")

        local foundKey = nil
        local candidates = {}

        for k, p in pairs(GuildrunDB.players or {}) do
            local kLower = string.lower(k)
            local kClean = kLower:gsub("[-_ ]", "")
            local pNameLower = string.lower(p.name or "")
            local pNameClean = pNameLower:gsub("[-_ ]", "")

            -- 1. Exakter Treffer oder Treffer ohne Trennzeichen (z.B. mit oder ohne Bindestrich)
            if kLower == targetLower or pNameLower == targetLower or kClean == targetClean or pNameClean == targetClean then
                foundKey = k
                break
            end

            -- 2. Vorname / Nachname / Substring
            local first, last = k:match("^([^-]+)-(.*)$")
            if first and (string.lower(first) == targetLower or string.lower(first):gsub("[-_ ]", "") == targetClean) then
                table.insert(candidates, k)
            elseif last and (string.lower(last) == targetLower or string.lower(last):gsub("[-_ ]", "") == targetClean) then
                table.insert(candidates, k)
            elseif string.find(kLower, targetLower, 1, true) then
                table.insert(candidates, k)
            end
        end

        if not foundKey then
            if #candidates == 1 then
                foundKey = candidates[1]
            elseif #candidates > 1 then
                print(string.format("|cffffaa00[Guildrun]|r Mehrere Charaktere passen auf '%s': |cffffd100%s|r. Bitte genauer angeben.", arg, table.concat(candidates, ", ")))
                return
            end
        end

        if foundKey then
            if foundKey == myCharKey or foundKey == myName or (foundKey:gsub("-", " ") == myCharKey:gsub("-", " ")) then
                print(string.format("|cffffaa00[Guildrun]|r Hinweis: |cffffd100%s|r ist dein aktuell eingeloggter Charakter. Er wird beim Weiterspielen automatisch neu erfasst.|r", foundKey))
            end

            GuildrunDB.players[foundKey] = nil
            if GuildrunDB.characters then
                GuildrunDB.characters[foundKey] = nil
            end

            if GuildrunUI and GuildrunUI.Refresh then
                GuildrunUI.Refresh()
            end
            print(string.format("|cff00ff00[Guildrun]|r Charakter |cffffd100%s|r wurde erfolgreich aus deiner Rennliste entfernt!", foundKey))
        else
            print(string.format("|cffff5555[Guildrun]|r Charakter '%s' wurde nicht in deiner Rennliste gefunden.|r", arg))
            local charList = {}
            for k, _ in pairs(GuildrunDB.players or {}) do table.insert(charList, k) end
            if #charList > 0 then
                print("|cffaaaaaaVerfuegbare Charaktere: |cffffd100" .. table.concat(charList, ", ") .. "|r")
            end
        end
    elseif cmd == "deaths" or cmd == "tode" then
        local numStr, targetChar = arg:match("^(%d+)%s*(.*)$")
        local num = tonumber(numStr)
        if num ~= nil then
            targetChar = SafeTrim(targetChar or "")
            if targetChar ~= "" then
                local foundKey = nil
                local tLower = string.lower(targetChar)
                local tClean = tLower:gsub("[-_ ]", "")
                for k, p in pairs(GuildrunDB.players or {}) do
                    if string.lower(k) == tLower or string.lower(p.name or "") == tLower or string.lower(k):gsub("[-_ ]", "") == tClean then
                        foundKey = k
                        break
                    end
                end
                foundKey = foundKey or targetChar
                GuildrunDB.players[foundKey] = GuildrunDB.players[foundKey] or {}
                GuildrunDB.players[foundKey].deaths = num
                local curKey = Guildrun_GetFullPlayerName("player")
                if foundKey == curKey then
                    localDeaths = num
                end
                if GuildrunUI and GuildrunUI.Refresh then GuildrunUI.Refresh() end
                if Guildrun_IsInGuild() and GuildrunDB.players[foundKey] then
                    Guildrun_BroadcastPlayer(GuildrunDB.players[foundKey])
                end
                print(string.format("|cff00ff00[Guildrun]|r Tode fuer |cffffd100%s|r wurden auf |cffff5555%d|r gesetzt!", foundKey, num))
            else
                localDeaths = num
                local me = Guildrun_UpdateLocalPlayerRecord()
                if me then
                    me.deaths = num
                    Guildrun_BroadcastPlayer(me)
                end
                print(string.format("|cff00ff00[Guildrun]|r Deine Tode (%s) wurden auf |cffff5555%d|r gesetzt!", me and me.name or "aktueller Char", num))
            end
        else
            local sDeaths = Guildrun_GetServerDeaths()
            local curKey = Guildrun_GetFullPlayerName("player")
            print(string.format("|cffffaa00[Guildrun Tode]|r Charakter: |cff00ff00%s|r | Getrackte Tode: |cffff5555%d|r | Server-Statistik (ID 60): |cffffd100%s|r",
                curKey, localDeaths, tostring(sDeaths ~= nil and sDeaths or "nicht verfuegbar")
            ))
            print("|cffaaaaaaTipp: Mit /gr deaths <anzahl> kannst du den Wert manuell ueberschreiben.|r")
        end
    elseif cmd == "played" then
        if RequestTimePlayed then
            pcall(RequestTimePlayed)
            print("|cffffaa00[Guildrun]|r Spielzeit (/played) vom Server angefordert...")
        end
    elseif cmd == "sync" or cmd == "testsync" or cmd == "req" then
        Guildrun_RequestGuildSync()
    elseif cmd == "mount" or cmd == "reittier" or cmd == "reg" or cmd == "register" then
        if GuildrunUI and GuildrunUI.ShowMountDialog then
            GuildrunUI.ShowMountDialog()
        elseif GuildrunUI and GuildrunUI.ShowRegistrationDialog then
            GuildrunUI.ShowRegistrationDialog()
        end
    elseif cmd == "demo" then
        if GuildrunUI and GuildrunUI.LoadDemoData then
            GuildrunUI.LoadDemoData()
            if not (GuildrunUI.CreateFrame():IsShown()) then
                GuildrunUI.Toggle()
            end
            print("|cffffaa00[Guildrun]|r Demo-Modus mit 10 Rennteilnehmern geladen!")
        end
    elseif cmd == "status" or cmd == "debug" then
        local charKey, name = Guildrun_GetFullPlayerName("player")
        local inGuild = Guildrun_IsInGuild()
        local guildName = (inGuild and Guildrun_GetGuildName()) or "Keine Gilde"
        local count = 0
        local names = {}
        for k, _ in pairs(GuildrunDB.players or {}) do
            count = count + 1
            table.insert(names, k)
        end
        print("|cffffd100=== GUILDRUN STATUS & DEBUG ===|r")
        print(string.format("Charakter: |cff00ff00%s|r", charKey))
        print(string.format("Gildenstatus: %s (Gilde: '|cffffd100%s|r')", inGuild and "|cff00ff00Verbunden|r" or "|cffff5555Keine Gilde|r", guildName))
        print(string.format("Rennteilnehmer in deiner Datenbank: |cff00e5ff%d|r", count))
        if count > 0 then
            print("Teilnehmer: " .. table.concat(names, ", "))
        end
        print("|cffffd100================================|r")
    else
        if GuildrunUI and GuildrunUI.Toggle then
            GuildrunUI.Toggle()
        end
    end
end
