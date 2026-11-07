# =========================================================================
# GUILDRUN - MEILENSTEIN WIEDERHERSTELLUNG
# =========================================================================
# Dieses Skript liest die gesicherten Meilensteine aus milestones_backup.json
# und fuegt sie wieder sauber in deine WoW Guildrun.lua ein.
# =========================================================================

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$uploaderScript = Join-Path $scriptDir "GuildrunUploader.ps1"

if (Test-Path $uploaderScript) {
    & $uploaderScript -Restore
} else {
    Write-Host "Fehler: GuildrunUploader.ps1 nicht im selben Ordner gefunden!" -ForegroundColor Red
}

Write-Host "Druecke eine beliebige Taste zum Beenden..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
