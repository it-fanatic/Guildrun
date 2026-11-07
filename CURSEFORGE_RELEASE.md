# Guildrun – CurseForge Release Package (English & German)

This document contains all official English copy-paste texts, metadata, and step-by-step instructions for submitting **Guildrun** to CurseForge.

---

## 1. CurseForge Submission Fields (English)

### 📌 Project Metadata
* **Project Name:** `Guildrun - Darkmoon Derby`
* **Short Description / Summary** *(max 200 characters)*:
> Turn your guild's leveling into a thrilling Darkmoon Faire race! Live derby track, milestone pennants, custom mounts & Hall of Fame — 100% standalone via guild chat.

* **Primary Category:** `Guild`
* **Secondary Categories:** `Leveling`, `Minigames`, `Roleplay`
* **License:** `MIT License`
* **Project Avatar / Icon:** Upload `icon.png` (512×512 Darkmoon Faire emblem included in the repository root)

---

### 📝 Full Project Description (Markdown for CurseForge)

Copy and paste the markdown block below into the **Description** editor on CurseForge:

```markdown
# 🎪 GUILDRUN — The Guild Darkmoon Derby! 🏇

**Guildrun** turns leveling, alts, and fresh adventures in your guild into an exciting, animated race in authentic **Darkmoon Faire** carnival style!

Inspired by classic boardwalk horse-derby arcade games ("roll the ball into the hole"), every player gets their own animated lane. Watch the wooden racial mounts gallop across the track in real-time with every quest turned in and every level gained!

Whether playing on **Retail**, **Classic Era**, **Hardcore**, or **Cataclysm Classic**: all guild members with the addon automatically sync their progress quietly in the background — no external tools, websites, or accounts required!

---

## ✨ Key Features

### 🎠 1. Dynamic Darkmoon Derby Track
* **Individual Lanes:** Every guild member has their own track with race/mount icon, name, and current level.
* **Dynamic Track Expansion:** The track dynamically limits its view to the guild leader's bracket (e.g. up to Level 15 while everyone is below Level 10, expanding up to Level 60).
* **Real-Time Progress:** Every single percent of XP pushes your mount forward along its track.

### 🚩 2. Milestone Pennants
* At every 10-level milestone (Level 10, 20, 30, 40, 50, 60), a golden milestone pennant is hoisted.
* **Interactive Tooltip Inspector:** Hover over any milestone pennant to inspect:
  * ⏱️ **Time Played (`/played`):** Exact leveling time when reaching the milestone.
  * 🗺️ **Zone:** The zone where the milestone level was reached.
  * 💀 **Death Toll:** Number of deaths accumulated up to that milestone.

### 🏆 3. Hall of Fame & Statistics
Celebrate your guild's greatest achievements across four distinct leaderboards:
1. **Highest Level:** Who is currently leading the race?
2. **Speedrunner (`/played`):** Who levels the fastest in terms of pure played time?
3. **Most Deaths (Graveyard King):** Who visited the Spirit Healer the most?
4. **Top Characters (Account Ranking):** Groups alts together so a single player cannot hoard all top ranks.

### 🐴 4. Choose Your Mount
Customize your runner! Choose from iconic racial mounts:
* **Night Elf:** Nightsaber
* **Undead:** Skeletal Warhorse
* **Human:** Horse
* **Orc:** Wolf
* **Dwarf:** Ram
* **Gnome:** Mechanostrider
* **Tauren:** Kodo
* **Troll:** Raptor
* **Blood Elf:** Hawkstrider
* **Draenei:** Elekk

---

## 🔒 100% Standalone & Lightweight
* **No external servers, web host, or client required:** Works 100% in-game using Blizzard's native hidden guild addon communication channel (`SendAddonMessage`).
* **Silent Background Sync:** Automatically updates when logging in, leveling up, or gaining XP.
* **Low Footprint:** Ultra-lightweight memory usage, zero impact on FPS or raid performance.

---

## ⌨️ In-Game Slash Commands

| Command | Description |
| :--- | :--- |
| `/guildrun` or `/gr` | Toggles the main Darkmoon Derby window |
| `/gr mount` | Opens the mount selection dialog |
| `/gr sync` or `/gr refresh` | Requests a full data sync from all online guild members |
| `/gr sound` | Toggles Darkmoon Faire carnival sounds and cheering |
| `/gr remove <Name>` | Removes an inactive alt or test character from your local race list (or click the red **[X]** on the track) |
| `/gr deaths <count>` | Manually sets or corrects your death counter |
| `/gr reset` | *(Guild Master / Officer)* Resets the entire guild race for a fresh season |
| `/gr test` | Generates sample demo racers for testing |

---

## 🌍 Client Compatibility
* **Retail** (The War Within 11.0.x / 11.1.x)
* **Classic Era, Hardcore & Season of Discovery** (1.15.x)
* **Cataclysm Classic** (4.4.x)
* **WoW Forever / Classic 1.12+**

---

## 💻 Optional Web Tracker & Streaming Overlay
For guilds and streamers who wish to display the live race on a secondary monitor, stream overlay, or guild website, the full open-source suite (including a live web dashboard and automated Windows PowerShell background uploader) is available on GitHub:
👉 **[https://github.com/it-fanatic/Guildrun](https://github.com/it-fanatic/Guildrun)**
```

---

## 2. File Upload Details (For the "Files" tab on CurseForge)

* **Upload File:** [`Guildrun.zip`](file:///f:/Documents/Projekte/Guildrun/Guildrun.zip) (located in root of repository)
* **Display Name / Version:** `Guildrun v2.1.0`
* **Release Type:** `Release`
* **Supported WoW Versions:**
  * Retail (11.0.x / 11.1.x)
  * Cataclysm Classic (4.4.x)
  * Classic Era (1.15.x)
* **Changelog / Release Notes:**
```text
Guildrun v2.1.0 — The Darkmoon Derby Release!
- Brand-new Darkmoon Faire theme with carnival aesthetic, violet awning, and gold trim.
- Dynamic track scaling (up to Level 15/30/60 depending on leader).
- 10-level milestone pennants with detailed /played time, zone, and death tooltips.
- Hall of Fame leaderboards (Highest Level, Speedrunner, Most Deaths, Account Ranking).
- Mount selection dialog for all core racial mounts.
- Full multi-client support: Retail (11.x), Cataclysm Classic (4.4.x), Classic Era (1.15.x), and WoW Forever.
- 100% standalone P2P guild synchronization via addon communication.
```

---

## 3. Step-by-Step Submission Guide

1. Log into the [CurseForge Authors Portal](https://authors.curseforge.com/).
2. Click **Start a Project** (top right).
3. Select **World of Warcraft** -> **Addons**.
4. Fill in the form using the metadata and Markdown description above.
5. Upload `icon.png` as the project avatar.
6. Under **Files** -> **Upload File**, upload `Guildrun.zip` and paste the changelog.
7. Submit for review! (CurseForge usually approves new projects within 1–2 business days).
