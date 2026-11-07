# =========================================================================
# GUILDRUN LIVE UPLOADER & AUTOMATISCHES MEILENSTEIN-BACKUP
# =========================================================================
param(
    [switch]$Restore
)

# Standardpfade & Konfiguration
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$CONFIG_FILE = Join-Path $SCRIPT_DIR "uploader_config.json"

# Standard-Fallbacks (falls keine uploader_config.json existiert)
$SERVER_URL = "https://deine-gilde.de/api/update.php"
$API_KEY    = "DEIN_GEHEIMER_API_SCHLUESSEL"
$CUSTOM_WTF = ""

if (Test-Path $CONFIG_FILE) {
    try {
        $cfg = Get-Content $CONFIG_FILE -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($cfg.server_url) { $SERVER_URL = $cfg.server_url }
        if ($cfg.api_key) { $API_KEY = $cfg.api_key }
        if ($cfg.wow_savedvariables_path) { $CUSTOM_WTF = $cfg.wow_savedvariables_path }
    } catch {
        Write-Warning "Konnte uploader_config.json nicht lesen: $_"
    }
}

# WoW SavedVariables Pfad dynamisch ermitteln
$WTF_FILE = ""
if ($CUSTOM_WTF -and (Test-Path $CUSTOM_WTF)) {
    $WTF_FILE = $CUSTOM_WTF
} else {
    # Dynamische Suche nach Guildrun.lua in bekannten WoW-Ordnern und Accounts
    $commonRoots = @(
        "C:\Games\World of Warcraft",
        "C:\Program Files (x86)\World of Warcraft",
        "C:\Program Files\World of Warcraft",
        "D:\Games\World of Warcraft",
        "D:\World of Warcraft",
        "E:\Games\World of Warcraft",
        "E:\World of Warcraft"
    )
    foreach ($root in $commonRoots) {
        if (Test-Path $root) {
            $found = Get-ChildItem -Path "$root\*_\WTF\Account\*\SavedVariables\Guildrun.lua" -ErrorAction SilentlyContinue
            if ($found) {
                $WTF_FILE = $found[0].FullName
                break
            }
        }
    }
}

$BACKUP_JSON = Join-Path $SCRIPT_DIR "milestones_backup.json"
$BACKUP_DIR  = Join-Path $SCRIPT_DIR "backups"
if (-not (Test-Path $BACKUP_DIR)) {
    New-Item -ItemType Directory -Path $BACKUP_DIR -Force | Out-Null
}

# -------------------------------------------------------------------------
# Funktion: Meilensteine aus der Guildrun.lua extrahieren
# -------------------------------------------------------------------------
function Parse-MilestonesFromLua([string]$filePath) {
    if (-not (Test-Path $filePath)) { return @{} }
    $lines = Get-Content $filePath
    $currentPlayer = $null
    $currentMs = $null
    $inMilestones = $false
    $inMsEntry = $false
    $allMilestones = @{}

    foreach ($line in $lines) {
        $trim = $line.Trim()
        if ($trim -match '^\["([^"]+)"\]\s*=\s*\{$') {
            $key = $matches[1]
            if ($key -ne "players" -and $key -ne "settings" -and $key -ne "characters" -and $key -ne "milestones") {
                if (-not $inMilestones) {
                    $currentPlayer = $key
                    if (-not $allMilestones.ContainsKey($currentPlayer)) {
                        $allMilestones[$currentPlayer] = @{}
                    }
                }
            }
        }
        if ($trim -match '^\["milestones"\]\s*=\s*\{') {
            $inMilestones = $true
            continue
        }
        if ($inMilestones -and $trim -match '^\[(\d+)\]\s*=\s*\{') {
            $currentMs = "$($matches[1])"
            $allMilestones[$currentPlayer][$currentMs] = @{}
            $inMsEntry = $true
            continue
        }
        if ($inMsEntry) {
            if ($trim -match '^\["([^"]+)"\]\s*=\s*"([^"]*)"') {
                $allMilestones[$currentPlayer][$currentMs][$matches[1]] = $matches[2]
            } elseif ($trim -match '^\["([^"]+)"\]\s*=\s*([0-9\.]+)') {
                $allMilestones[$currentPlayer][$currentMs][$matches[1]] = [double]$matches[2]
            } elseif ($trim -match '^\},?$') {
                $inMsEntry = $false
                $currentMs = $null
                continue
            }
        }
        if ($inMilestones -and -not $inMsEntry -and $trim -match '^\},?$') {
            $inMilestones = $false
        }
    }
    return $allMilestones
}

# -------------------------------------------------------------------------
# Funktion: Parst die gesamte Guildrun.lua in ein sauberes JSON-Objekt
# -------------------------------------------------------------------------
function Parse-GuildrunLuaToPlayers([string]$filePath) {
    if (-not (Test-Path $filePath)) { return @{} }
    $lines = Get-Content $filePath
    $players = @{}
    $currentName = $null
    $inPlayers = $false
    $inPlayer = $false
    $inMilestones = $false
    $currentMs = $null

    foreach ($line in $lines) {
        $trim = $line.Trim()

        if (-not $inPlayers) {
            if ($trim -match '^\["players"\]\s*=\s*\{') {
                $inPlayers = $true
            }
            continue
        }

        if ($trim -match '^\},?$') {
            if ($inMilestones) {
                if ($currentMs -ne $null) {
                    $currentMs = $null
                } else {
                    $inMilestones = $false
                }
                continue
            }
            if ($inPlayer) {
                $inPlayer = $false
                $currentName = $null
                continue
            }
            break
        }

        if (-not $inPlayer -and $trim -match '^\["([^"]+)"\]\s*=\s*\{$') {
            $currentName = $matches[1]
            $inPlayer = $true
            $players[$currentName] = @{
                key = $currentName
                name = $currentName
                realm = ""
                account = "ACC_UNKNOWN"
                class = "WARRIOR"
                race = "Human"
                mount = "HORSE"
                level = 1
                progress = 0.0
                xpPercent = 0
                zone = "Azeroth"
                subzone = ""
                deaths = 0
                totalTime = 0
                totalTimeFormatted = "0m"
                milestones = @{}
            }
            continue
        }

        if ($inPlayer) {
            if ($trim -match '^\["milestones"\]\s*=\s*\{') {
                $inMilestones = $true
                continue
            }

            if ($inMilestones) {
                if ($trim -match '^\[(\d+)\]\s*=\s*\{') {
                    $currentMs = "$($matches[1])"
                    $players[$currentName]["milestones"][$currentMs] = @{
                        level = [int]$matches[1]
                        deaths = 0
                        timeSeconds = 0
                        timeFormatted = "0m"
                        zone = "Azeroth"
                    }
                    continue
                }
                if ($currentMs -ne $null) {
                    if ($trim -match '^\["timeFormatted"\]\s*=\s*"([^"]*)"') {
                        $players[$currentName]["milestones"][$currentMs]["timeFormatted"] = $matches[1]
                    } elseif ($trim -match '^\["zone"\]\s*=\s*"((?:\\.|[^"\\])*)"') {
                        $zClean = $matches[1] -replace '["\\]', ''
                        $players[$currentName]["milestones"][$currentMs]["zone"] = $zClean
                    } elseif ($trim -match '^\["deaths"\]\s*=\s*(\d+)') {
                        $players[$currentName]["milestones"][$currentMs]["deaths"] = [int]$matches[1]
                    } elseif ($trim -match '^\["timeSeconds"\]\s*=\s*([0-9\.]+)') {
                        $players[$currentName]["milestones"][$currentMs]["timeSeconds"] = [double]$matches[1]
                    }
                    continue
                }
            }

            if ($trim -match '^\["name"\]\s*=\s*"([^"]*)"') {
                $players[$currentName]["name"] = $matches[1]
            } elseif ($trim -match '^\["class"\]\s*=\s*"([^"]*)"') {
                $players[$currentName]["class"] = $matches[1]
            } elseif ($trim -match '^\["race"\]\s*=\s*"([^"]*)"') {
                $players[$currentName]["race"] = $matches[1]
            } elseif ($trim -match '^\["mount"\]\s*=\s*"([^"]*)"') {
                $players[$currentName]["mount"] = $matches[1]
            } elseif ($trim -match '^\["account"\]\s*=\s*"([^"]*)"') {
                $players[$currentName]["account"] = $matches[1]
            } elseif ($trim -match '^\["level"\]\s*=\s*(\d+)') {
                $players[$currentName]["level"] = [int]$matches[1]
            } elseif ($trim -match '^\["progress"\]\s*=\s*([0-9\.]+)') {
                $players[$currentName]["progress"] = [double]$matches[1]
            } elseif ($trim -match '^\["xpPercent"\]\s*=\s*(\d+)') {
                $players[$currentName]["xpPercent"] = [int]$matches[1]
            } elseif ($trim -match '^\["deaths"\]\s*=\s*(\d+)') {
                $players[$currentName]["deaths"] = [int]$matches[1]
            } elseif ($trim -match '^\["totalTime"\]\s*=\s*([0-9\.]+)') {
                $players[$currentName]["totalTime"] = [double]$matches[1]
            } elseif ($trim -match '^\["totalTimeFormatted"\]\s*=\s*"([^"]*)"') {
                $players[$currentName]["totalTimeFormatted"] = $matches[1]
            } elseif ($trim -match '^\["zone"\]\s*=\s*"((?:\\.|[^"\\])*)"') {
                $rawZone = $matches[1] -replace '["\\]', ''
                $players[$currentName]["zone"] = $rawZone
            } elseif ($trim -match '^\["subzone"\]\s*=\s*"((?:\\.|[^"\\])*)"') {
                $players[$currentName]["subzone"] = $matches[1] -replace '["\\]', ''
            }
        }
    }

    return $players
}

# -------------------------------------------------------------------------
# Funktion: Meilensteine kumulativ im Backup sichern (geht nie verloren!)
# -------------------------------------------------------------------------
function Save-CumulativeMilestonesBackup([string]$wtfPath, [string]$jsonPath) {
    $existing = @{}
    if (Test-Path $jsonPath) {
        try {
            $raw = Get-Content $jsonPath -Raw
            $existing = $raw | ConvertFrom-Json -AsHashtable
        } catch {
            $existing = @{}
        }
    }

    $current = Parse-MilestonesFromLua $wtfPath
    $savedCount = 0

    foreach ($player in $current.Keys) {
        if (-not $existing.ContainsKey($player)) {
            $existing[$player] = @{}
        }
        foreach ($msKey in $current[$player].Keys) {
            $ms = $current[$player][$msKey]
            if ($ms -and ($ms["timeSeconds"] -gt 0 -or $ms["timeFormatted"] -ne "" -or $ms["zone"] -ne "")) {
                # Nur speichern, wenn neu oder bessere Zeit
                if (-not $existing[$player].ContainsKey($msKey) -or ($ms["timeSeconds"] -gt 0 -and $existing[$player][$msKey]["timeSeconds"] -eq 0)) {
                    $existing[$player][$msKey] = $ms
                    $savedCount++
                }
            }
        }
    }

    $existing | ConvertTo-Json -Depth 5 | Set-Content -Path $jsonPath -Encoding UTF8
    return $savedCount
}

# -------------------------------------------------------------------------
# Funktion: Ersetzt den Meilenstein-Block eines Spielers mit exakter Klammer-Balance
# -------------------------------------------------------------------------
function Replace-MilestonesBlock([string]$source, [string]$playerName, [string]$newMsBlock) {
    $playerIdx = $source.IndexOf('["' + $playerName + '"]')
    if ($playerIdx -lt 0) { return $source }

    $msIdx = $source.IndexOf('["milestones"]', $playerIdx)
    if ($msIdx -lt 0) { return $source }

    $braceOpen = $source.IndexOf('{', $msIdx)
    if ($braceOpen -lt 0) { return $source }

    $depth = 1
    $pos = $braceOpen + 1
    while ($pos -lt $source.Length -and $depth -gt 0) {
        $c = $source[$pos]
        if ($c -eq '{') { $depth++ }
        elseif ($c -eq '}') { $depth-- }
        $pos++
    }

    if ($pos -lt $source.Length -and $source[$pos] -eq ',') { $pos++ }

    $before = $source.Substring(0, $msIdx)
    $after = $source.Substring($pos)

    return $before + $newMsBlock + $after
}

# -------------------------------------------------------------------------
# Funktion: Meilensteine aus dem Backup in Guildrun.lua zurueckspielen
# -------------------------------------------------------------------------
function Restore-Milestones([string]$wtfPath, [string]$jsonPath) {
    Write-Host "`n=== GUILDRUN MEILENSTEIN-WIEDERHERSTELLUNG ===" -ForegroundColor Yellow
    if (-not (Test-Path $jsonPath)) {
        Write-Host "Keine Meilenstein-Backupdatei ($jsonPath) vorhanden!" -ForegroundColor Red
        return
    }
    if (-not (Test-Path $wtfPath)) {
        Write-Host "Zieldatei ($wtfPath) nicht gefunden!" -ForegroundColor Red
        return
    }

    $backupData = (Get-Content $jsonPath -Raw) | ConvertFrom-Json -AsHashtable

    # Vorab Sicherheits-Backup der aktuellen Datei erstellen
    $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $safeguard = "$wtfPath.bak_before_restore_$timestamp"
    Copy-Item $wtfPath $safeguard -Force
    Write-Host "Sicherheitskopie deiner aktuellen Datei erstellt: $safeguard" -ForegroundColor Gray

    $luaContent = Get-Content $wtfPath -Raw
    $restoredCount = 0

    foreach ($player in $backupData.Keys) {
        $pMilestones = $backupData[$player]
        if ($pMilestones -and $pMilestones.Keys.Count -gt 0) {
            $msLines = @('["milestones"] = {')
            foreach ($lvl in ($pMilestones.Keys | Sort-Object { [int]$_ })) {
                $m = $pMilestones[$lvl]
                $timeSec = if ($m["timeSeconds"]) { $m["timeSeconds"] } else { 0 }
                $timeF = if ($m["timeFormatted"]) { $m["timeFormatted"] } else { "0m" }
                $zone = if ($m["zone"]) { $m["zone"] } else { "Unbekannt" }
                $deaths = if ($m["deaths"]) { $m["deaths"] } else { 0 }

                $msLines += "[$lvl] = {"
                $msLines += '["deaths"] = ' + $deaths + ','
                $msLines += '["zone"] = "' + $zone + '",'
                $msLines += '["level"] = ' + $lvl + ','
                $msLines += '["timeSeconds"] = ' + $timeSec + ','
                $msLines += '["timeFormatted"] = "' + $timeF + '",'
                $msLines += "},"
            }
            $msLines += "},"

            $newBlock = ($msLines -join "`n")

            if ($luaContent.IndexOf('["' + $player + '"]') -ge 0) {
                $luaContent = Replace-MilestonesBlock $luaContent $player $newBlock
                Write-Host "  -> Meilensteine fuer '$player' erfolgreich restauriert! ($($pMilestones.Keys.Count) Wimpel)" -ForegroundColor Green
                $restoredCount++
            } else {
                Write-Host "  -> Spieler '$player' ist aktuell nicht in Guildrun.lua (noch nicht eingeloggt)." -ForegroundColor Yellow
            }
        }
    }

    Set-Content -Path $wtfPath -Value $luaContent -Encoding UTF8
    Write-Host "`nFertig! $restoredCount Spieler aktualisiert. Bitte im Spiel einmal /reload ausfuehren!`n" -ForegroundColor Green
}

# -------------------------------------------------------------------------
# Start-Verzweigung
# -------------------------------------------------------------------------
if ($Restore) {
    Restore-Milestones -wtfPath $WTF_FILE -jsonPath $BACKUP_JSON
    exit 0
}

Write-Host "=== Guildrun Live Uploader mit automatischem Meilenstein-Backup ===" -ForegroundColor Yellow
Write-Host "Ueberwache:       $WTF_FILE" -ForegroundColor Cyan
Write-Host "Meilenstein-Safe: $BACKUP_JSON" -ForegroundColor Green
Write-Host "Web-Ziel-URL:     $SERVER_URL"
Write-Host "Tipp: Zum Wiederherstellen von Meilensteinen: .\RestoreMilestones.ps1 ausfuehren`n" -ForegroundColor Gray

$lastHash = ""

while ($true) {
    if (Test-Path $WTF_FILE) {
        $currentHash = (Get-FileHash -Path $WTF_FILE -Algorithm MD5).Hash
        if ($currentHash -ne $lastHash) {
            $lastHash = $currentHash
            $timeStr = Get-Date -Format 'HH:mm:ss'
            Write-Host "[$timeStr] Aenderung in Guildrun.lua erkannt!" -ForegroundColor Cyan

            # 1. Meilensteine automatisch sichern
            try {
                Save-CumulativeMilestonesBackup -wtfPath $WTF_FILE -jsonPath $BACKUP_JSON | Out-Null
                Write-Host "[$timeStr] Meilensteine automatisch gesichert in milestones_backup.json" -ForegroundColor Green
            } catch {
                Write-Host "[$timeStr] Hinweis Meilenstein-Backup: $_" -ForegroundColor Yellow
            }

            # 2. Rollendes Sicherheitsbackup der Datei (letzte 20 Versionen behalten)
            try {
                $ts = Get-Date -Format 'yyyyMMdd_HHmmss'
                $fileBak = Join-Path $BACKUP_DIR "Guildrun_$ts.lua"
                Copy-Item $WTF_FILE $fileBak -Force

                # Alte Backups aufraumen (maximal 20 behalten)
                $oldBaks = Get-ChildItem -Path $BACKUP_DIR -Filter "Guildrun_*.lua" | Sort-Object CreationTime -Descending | Select-Object -Skip 20
                if ($oldBaks) { $oldBaks | Remove-Item -Force }
            } catch {}

            # 3. Upload zur Webseite (als sauberes JSON, damit alle Zonen und Meilensteine perfekt uebertragen werden)
            try {
                $parsedPlayers = Parse-GuildrunLuaToPlayers $WTF_FILE
                $jsonPayload = @{ players = $parsedPlayers } | ConvertTo-Json -Depth 6
                $response = Invoke-RestMethod -Uri $SERVER_URL -Method Post -Body $jsonPayload -Headers @{ "X-API-KEY" = $API_KEY } -ContentType "application/json; charset=utf-8"
                Write-Host "[$timeStr] Upload zur Webseite erfolgreich! ($($response.count) Rennteilnehmer synchronisiert)" -ForegroundColor Green
            } catch {
                Write-Host "[$timeStr] Fehler beim Upload zur Webseite: $_" -ForegroundColor Red
            }
        }
    } else {
        Write-Host "Warte auf Erstellung von $WTF_FILE..." -ForegroundColor Yellow
    }
    Start-Sleep -Seconds 10
}
