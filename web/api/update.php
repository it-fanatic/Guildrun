<?php
/**
 * Guildrun API - Gesicherte Schnittstelle fuer Renn-Updates
 * Erfasst Spielerdaten inklusive Account-Identifier fuer Max-Chars Leaderboards
 * Unterstuetzt vollstaendigen Renn-Reset via action=reset
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, X-API-KEY');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

// Optionale externe Konfigurationsdatei laden (z. B. ausserhalb von Git)
if (file_exists(__DIR__ . '/config.php')) {
    require_once __DIR__ . '/config.php';
}

// Fallback falls nicht in config.php definiert
if (!isset($SECRET_KEY) || empty($SECRET_KEY)) {
    $SECRET_KEY = "DEIN_GEHEIMER_API_SCHLUESSEL_HIER";
}
$DATA_FILE = __DIR__ . '/derby_data.json';

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    if (file_exists($DATA_FILE)) {
        echo file_get_contents($DATA_FILE);
    } else {
        echo json_encode(["players" => [], "lastUpdate" => 0]);
    }
    exit;
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $providedKey = $_SERVER['HTTP_X_API_KEY'] ?? $_POST['api_key'] ?? '';
    
    if (empty($providedKey) || $providedKey !== $SECRET_KEY) {
        http_response_code(403);
        echo json_encode([
            "error" => "Zugriff verweigert! Ungueltiges Admin-Passwort.",
            "status" => 403
        ]);
        exit;
    }

    $rawInput = file_get_contents('php://input');

    // -------------------------------------------------------------
    // RENN-RESET BEFEHL: Wenn RESET gesendet wird, Datei leeren
    // -------------------------------------------------------------
    if (isset($_GET['action']) && $_GET['action'] === 'reset') {
        $emptyData = ["lastUpdate" => time(), "players" => []];
        file_put_contents($DATA_FILE, json_encode($emptyData, JSON_PRETTY_PRINT));
        echo json_encode(["success" => true, "message" => "Rennstrecke auf dem Server erfolgreich zurueckgesetzt!"]);
        exit;
    }

    $players = [];
    $jsonData = json_decode($rawInput, true);
    if ($jsonData && isset($jsonData['players'])) {
        $players = $jsonData['players'];
    } 
    else if (strpos($rawInput, 'GuildrunDB') !== false) {
        $players = parseLuaGuildrunDB($rawInput);
    }

    if (!empty($players)) {
        $output = [
            "lastUpdate" => time(),
            "players" => $players
        ];
        file_put_contents($DATA_FILE, json_encode($output, JSON_PRETTY_PRINT));
        echo json_encode(["success" => true, "count" => count($players)]);
    } else {
        http_response_code(400);
        echo json_encode(["error" => "Keine gueltigen Spielerdaten in der Datei gefunden."]);
    }
    exit;
}

function parseLuaGuildrunDB($luaContent) {
    $players = [];

    // Finde den Inhalt von ["players"] = { ... }
    $pStart = strpos($luaContent, '["players"] = {');
    if ($pStart === false) {
        $pStart = strpos($luaContent, '["players"]={');
    }
    if ($pStart === false) {
        return $players;
    }

    $sub = substr($luaContent, $pStart);
    // Jeder Spieler beginnt mit: ["Spielername"] = {
    // Da innerhalb von ["milestones"] = { ... } geschweifte Klammern sind,
    // parsen wir die einzelnen Spielerbloecke zeilenweise oder per Token:
    $lines = explode("\n", $sub);
    $inPlayers = false;
    $currentName = null;
    $currentBlock = "";
    $depth = 0;

    foreach ($lines as $line) {
        $trimmed = trim($line);
        if (!$inPlayers) {
            if (strpos($trimmed, '["players"]') !== false) {
                $inPlayers = true;
                $depth = 1;
            }
            continue;
        }

        // Spieler-Start: ["Name"] = {
        if ($depth === 1 && preg_match('/^\["([^"]+)"\]\s*=\s*\{/', $trimmed, $m)) {
            $currentName = $m[1];
            $currentBlock = "";
            $depth = 2;
            continue;
        }

        if ($currentName !== null) {
            // Tracke geschweifte Klammern innerhalb des Spielerblocks
            $openCount = substr_count($trimmed, '{');
            $closeCount = substr_count($trimmed, '}');
            $depth += ($openCount - $closeCount);

            if ($depth <= 1) {
                // Spielerblock abgeschlossen!
                $raw = $currentBlock;
                $key = $currentName;
                $name = preg_match('/\["name"\]\s*=\s*"([^"]+)"/', $raw, $s) ? $s[1] : $key;
                if (strpos($key, '-') !== false && strpos($name, '-') === false) {
                    $name = $key; // Voller Charaktername inkl. Nachname (z.B. Mirulas-Rindenmulch)
                }
                $realm = preg_match('/\["realm"\]\s*=\s*"([^"]+)"/', $raw, $s) ? $s[1] : '';
                if ($realm === 'Rindenmulch' || $realm === 'Rindenmantel' || $realm === 'Manastrudel' || $realm === 'WoWForever' || $realm === '93') {
                    $realm = '';
                }

                $account = preg_match('/\["account"\]\s*=\s*"([^"]+)"/', $raw, $s) ? $s[1] : ('ACC_' . substr(md5($name), 0, 6));
                $class = preg_match('/\["class"\]\s*=\s*"([^"]+)"/', $raw, $s) ? $s[1] : 'WARRIOR';
                $race = preg_match('/\["race"\]\s*=\s*"([^"]+)"/', $raw, $s) ? $s[1] : 'Human';
                $mount = preg_match('/\["mount"\]\s*=\s*"([^"]+)"/', $raw, $s) ? $s[1] : 'HORSE';
                $level = preg_match('/\["level"\]\s*=\s*(\d+)/', $raw, $s) ? intval($s[1]) : 1;
                $progress = preg_match('/\["progress"\]\s*=\s*([0-9.]+)/', $raw, $s) ? floatval($s[1]) : 0;
                $xpPercent = preg_match('/\["xpPercent"\]\s*=\s*(\d+)/', $raw, $s) ? intval($s[1]) : 0;
                $zone = 'Azeroth';
                if (preg_match('/\["zone"\]\s*=\s*"((?:\\\\.|[^"\\\\])*)"/', $raw, $s)) {
                    $zone = stripslashes($s[1]);
                    $zone = trim(str_replace(['"', '\\'], '', $zone));
                }
                $deaths = preg_match('/\["deaths"\]\s*=\s*(\d+)/', $raw, $s) ? intval($s[1]) : 0;
                $totalTime = preg_match('/\["totalTime"\]\s*=\s*([0-9.]+)/', $raw, $s) ? intval($s[1]) : 0;
                $totalTimeFormatted = preg_match('/\["totalTimeFormatted"\]\s*=\s*"((?:\\\\.|[^"\\\\])*)"/', $raw, $s) ? stripslashes($s[1]) : '';

                $milestones = [];
                if (preg_match('/\["milestones"\]\s*=\s*\{/', $raw)) {
                    preg_match_all('/\[(\d+)\]\s*=\s*\{([^}]+)\}/s', $raw, $msMatches, PREG_SET_ORDER);
                    foreach ($msMatches as $ms) {
                        $lvlNum = intval($ms[1]);
                        $msRaw = $ms[2];
                        $msTime = preg_match('/\["timeFormatted"\]\s*=\s*"((?:\\\\.|[^"\\\\])*)"/', $msRaw, $st) ? stripslashes($st[1]) : '';
                        $msZone = preg_match('/\["zone"\]\s*=\s*"((?:\\\\.|[^"\\\\])*)"/', $msRaw, $st) ? stripslashes($st[1]) : '';
                        $msZone = trim(str_replace(['"', '\\'], '', $msZone));
                        $msDeaths = preg_match('/\["deaths"\]\s*=\s*(\d+)/', $msRaw, $st) ? intval($st[1]) : 0;

                        $milestones[$lvlNum] = [
                            "level" => $lvlNum,
                            "timeFormatted" => $msTime,
                            "zone" => $msZone,
                            "deaths" => $msDeaths
                        ];
                    }
                }

                $players[$key] = [
                    "key" => $key,
                    "name" => $name,
                    "realm" => $realm,
                    "account" => $account,
                    "class" => $class,
                    "race" => $race,
                    "mount" => $mount,
                    "level" => $level,
                    "progress" => $progress,
                    "xpPercent" => $xpPercent,
                    "zone" => $zone,
                    "deaths" => $deaths,
                    "totalTime" => $totalTime,
                    "totalTimeFormatted" => $totalTimeFormatted,
                    "milestones" => $milestones
                ];

                $currentName = null;
                $currentBlock = "";
                $depth = 1;
            } else {
                $currentBlock .= $line . "\n";
            }
        } else {
            // Wenn wir in players sind und die abschliessende Klammer von players kommt
            if ($trimmed === '},' || $trimmed === '}') {
                break;
            }
        }
    }

    return $players;
}
