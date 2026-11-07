# Guildrun – CurseForge Veröffentlichungs-Paket

Dieses Paket bereitet das Addon **Guildrun** für den offiziellen Upload auf CurseForge vor.

---

## 1. Sicherheits- & Datenschutz-Audit (Abgeschlossen ✅)

* **Keine Webseiten-Abhängigkeit:** Das Addon funktioniert zu 100 % autark über Blizzards interne Gilden-Addon-Nachrichten (`SendAddonMessage`). Weder die PowerShell-Upload-Skripte noch Web-Backends oder Server-URLs sind im Addon enthalten.
* **Keine privaten Daten:**
  * Alle hardgecodeten Account-IDs, Servernamen, API-Tokens und privaten Spielernamen wurden aus dem Quellcode entfernt.
  * Namensauflösungen und Datenmigrationen arbeiten vollständig generisch für jede beliebige Gilde auf jedem beliebigen Realm.
* **Multi-Client Unterstützung:**
  * `Guildrun.toc` (Universal / Fallback)
  * `Guildrun_Mainline.toc` (World of Warcraft Retail – The War Within 11.x)
  * `Guildrun_Vanilla.toc` (World of Warcraft Classic Era / Hardcore / Season of Discovery 1.15.x)
  * `Guildrun_Cata.toc` (World of Warcraft Cataclysm Classic 4.4.x)
  * `Guildrun_Forever.toc` (WoW Forever / 1.12 / 1.60)

---

## 2. Fertige ZIP-Datei für CurseForge

Die fertige Datei liegt im Projektverzeichnis bereit:
📁 **`f:\Documents\Projekte\Guildrun\Guildrun.zip`**

**Inhalt des Zip-Archivs:**
```text
Guildrun/
├── Guildrun.toc
├── Guildrun_Mainline.toc
├── Guildrun_Vanilla.toc
├── Guildrun_Cata.toc
├── Guildrun_Forever.toc
├── Guildrun.lua
├── GuildrunUI.lua
└── icon.png
```

---

## 3. Angaben für das CurseForge-Formular (Copy & Paste)

### Projekt-Stammdaten:
* **Project Name:** `Guildrun - Das Dunkelmond-Derby` (oder `Guildrun`)
* **Short Description / Summary (max. 200 Zeichen):**
  > Verwandelt das gemeinsame Leveln in deiner Gilde in ein spannendes Dunkelmond-Derby! Mit Live-Rennstrecke, Meilenstein-Wimpeln, Reittieren und Hall of Fame – 100% autark über den Gildenkanal.
* **Primary Category:** `Guild`
* **Secondary Categories:** `Leveling`, `Minigames` oder `Roleplay`
* **License:** `MIT License` (oder `GNU General Public License v3.0`)

---

### Vollständige Projektbeschreibung (Description) für CurseForge:

```markdown
# 🎪 GUILDRUN – Das Dunkelmond-Derby für deine Gilde! 🏇

**Guildrun** verwandelt das gemeinsame Leveln, Twinken oder Neuanfangen in deiner Gilde in ein atmosphärisches Volksreittier-Rennen im originalen **Dunkelmond-Jahrmarkt**-Stil!

Egal ob Retail, Classic Era, Hardcore oder Cataclysm: Sobald du und deine Gildenmitglieder Guildrun installiert haben, synchronisieren sich eure Level-Fortschritte automatisch und völlig unkompliziert im Hintergrund.

---

## ✨ Die Hauptfeatures

### 🎠 1. Die Dunkelmond-Rennstrecke
* Jeder Spieler steuert ein hölzernes Volksreittier über eine dynamische Rennbahn im Dunkelmond-Stil.
* Die Rennbahn passt sich automatisch dem höchsten Level der Gilde an (z. B. von Level 1 bis 15, 30 oder 60).
* Fortschritt in Echtzeit: Jedes Prozent Erfahrung schiebt dein Reittier auf seiner Bahn weiter nach vorne!

### 🚩 2. Meilenstein-Wimpel
* An jedem 10er-Schritt (Level 10, 20, 30, 40, 50, 60) steht ein Meilenstein-Wimpel.
* Sobald ein Spieler einen Meilenstein erreicht, wird der Wimpel gehisst.
* **Tooltip-Inspektor:** Fahre mit der Maus über die Wimpel, um genau zu sehen:
  * In welcher Spielzeit (`/played`) wurde das Level erreicht?
  * In welcher Zone befand sich der Charakter beim Levelaufstieg?
  * Wie oft ist der Spieler bis dorthin gestorben?

### 🏆 3. Hall of Fame (Statistiken & Top 5)
In der Hall of Fame werden die Champions der Gilde in vier Kategorien gekürt:
1. **Höchstes Level:** Wer führt das Rennen aktuell an?
2. **Speedrunner (`/played`):** Wer levelt gemessen an seiner effektiven Spielzeit am schnellsten?
3. **Meiste Tode (Friedhofs-König):** Wer hat die meisten Bekanntschaften mit dem Geistheiler gemacht?
4. **Top Chars (Account-Wertung):** Fasst Twinks desselben Spielers zusammen, damit ein Spieler nicht alle Plätze belegt.

### 🐴 4. Wähle dein Reittier
Jeder Charakter kann sein persönliches Volksreittier wählen:
* Mensch: Pferd
* Zwerg: Widder
* Nachtelf: Säbelzahntiger
* Gnom: Roboschreiter
* Draenei: Elekk
* Ork: Wolf
* Untoter: Skelettross
* Taure: Kodo
* Troll: Raptor
* Blutelf: Falkenschreiter

---

## 🔒 100% Sicher & Standalone (Kein Server nötig!)
* **Keine externe Webseite oder Software erforderlich:** Das Addon nutzt ausschließlich Blizzards internen, nativen Gilden-Addon-Kanal (`SendAddonMessage`).
* **Automatischer Abgleich:** Sobald du einloggst oder ein Level aufsteigst, teilt das Addon deinen aktuellen Stand lautlos mit deinen Gildenkollegen.
* **Geringe Systemlast:** Minimale Speichernutzung, keine FPS-Einbrüche.

---

## ⌨️ Befehle im Spiel
* `/guildrun` oder `/gr` – Öffnet oder schließt das Hauptfenster.
* `/gr sync` – Fordert einen sofortigen Datenabgleich von allen anwesenden Gildenmitgliedern an.
* `/gr mount` – Öffnet den Auswahldialog für dein Reittier.
* `/gr remove <Name>` – Entfernt einen Twink oder inaktiven Charakter aus deiner lokalen Rennliste (alternativ über das rote **[X]** direkt auf der Rennbahn).
* `/gr reset` – Setzt die Renndaten zurück (ideal zum Start eines neuen Rennens).
* `/gr deaths <Anzahl>` – Setzt oder korrigiert deine getrackten Tode manuell.

---

## 🌍 Kompatibilität
* **Retail** (The War Within 11.x)
* **Classic Era & Season of Discovery** (1.15.x)
* **Cataclysm Classic** (4.4.x)
* Abwärtskompatibel mit Classic 1.12 Clients
```

---

## 4. Schritt-für-Schritt Anleitung zum Veröffentlichen

1. **CurseForge Creators Portal öffnen:**
   Gehe auf [https://authors.curseforge.com/](https://authors.curseforge.com/) und logge dich ein (mit Twitch / CurseForge-Konto).
2. **Neues Projekt anlegen:**
   * Klicke oben rechts auf **"Start a Project"**.
   * Wähle **"World of Warcraft"** und danach **"Addons"**.
3. **Projektangaben ausfüllen:**
   * Trage die Daten aus **Abschnitt 3** oben ein (Name, Summary, Beschreibung, Lizenz, Kategorien).
   * Lade optional ein 512x512 Logo/Icon hoch.
4. **Erste Version hochladen:**
   * Nach dem Erstellen gehst du im Projekt auf den Reiter **"Files"** -> **"Upload File"**.
   * Wähle die Datei `f:\Documents\Projekte\Guildrun\Guildrun.zip` aus.
   * Wähle den Release-Typ: **Release** (oder **Beta**).
   * Wähle die unterstützten Spielversionen (z. B. The War Within 11.0.x / 11.1.x, Classic Era 1.15.x, Cataclysm Classic 4.4.x).
5. **Einreichung & Review:**
   * CurseForge prüft neue Addon-Projekte vor der Freischaltung manuell (dauert meist ca. 1–2 Tage).
   * Da der Code sauber strukturiert, frei von externen URLs/Webskripten und ohne verdächtige Abhängigkeiten ist, geht die Freigabe erfahrungsgemäß zügig durch!
