/**
 * Guildrun Derby Frontend Logic
 * - Reittier Mouse-Over Tooltip (Reittiername, Level, Spielzeit, Zone, Tode, Status)
 * - Wimpel Tooltip (Meilenstein /played, Zone, Tode)
 * - Grosszuegiges Spacing zwischen letztem Spieler und unterer Scrollleiste
 */

const CLASS_ICONS = {
  WARRIOR: "https://wow.zamimg.com/images/wow/icons/large/classicon_warrior.jpg",
  PALADIN: "https://wow.zamimg.com/images/wow/icons/large/classicon_paladin.jpg",
  HUNTER: "https://wow.zamimg.com/images/wow/icons/large/classicon_hunter.jpg",
  ROGUE: "https://wow.zamimg.com/images/wow/icons/large/classicon_rogue.jpg",
  PRIEST: "https://wow.zamimg.com/images/wow/icons/large/classicon_priest.jpg",
  DEATHKNIGHT: "https://wow.zamimg.com/images/wow/icons/large/classicon_deathknight.jpg",
  SHAMAN: "https://wow.zamimg.com/images/wow/icons/large/classicon_shaman.jpg",
  MAGE: "https://wow.zamimg.com/images/wow/icons/large/classicon_mage.jpg",
  WARLOCK: "https://wow.zamimg.com/images/wow/icons/large/classicon_warlock.jpg",
  DRUID: "https://wow.zamimg.com/images/wow/icons/large/classicon_druid.jpg"
};

const MOUNT_NAMES = {
  HORSE: "Schlachtross (Mensch)",
  RAM: "Widder (Zwerg)",
  SABER: "Saebelzahntiger (Nachtelf)",
  STRIDER: "Schreithahn (Gnom)",
  ELEKK: "Elekk (Draenei)",
  WOLF: "Kriegswolf (Orc)",
  KODO: "Kodo (Tauren)",
  RAPTOR: "Raptor (Troll)",
  SKELETON: "Skelettpferd (Untot)",
  HAWKSTRIDER: "Falkenschreiter (Blutelf)"
};

const MOUNT_ICONS = {
  HORSE: "https://wow.zamimg.com/images/wow/icons/large/ability_mount_ridinghorse.jpg",
  RAM: "https://wow.zamimg.com/images/wow/icons/large/ability_mount_mountainram.jpg",
  SABER: "https://wow.zamimg.com/images/wow/icons/large/ability_mount_blackpanther.jpg",
  STRIDER: "https://wow.zamimg.com/images/wow/icons/large/ability_mount_mechastrider.jpg",
  ELEKK: "https://wow.zamimg.com/images/wow/icons/large/ability_mount_ridingelekk.jpg",
  WOLF: "https://wow.zamimg.com/images/wow/icons/large/ability_mount_blackdirewolf.jpg",
  KODO: "https://wow.zamimg.com/images/wow/icons/large/ability_mount_kodo_01.jpg",
  RAPTOR: "https://wow.zamimg.com/images/wow/icons/large/ability_mount_raptor.jpg",
  SKELETON: "https://wow.zamimg.com/images/wow/icons/large/ability_mount_undeadhorse.jpg",
  HAWKSTRIDER: "https://wow.zamimg.com/images/wow/icons/large/ability_mount_cockatricemount.jpg"
};

const LEVEL_SEGMENTS = [
  { min: 1, max: 10, title: "Lvl 1 - 10" },
  { min: 10, max: 20, title: "Lvl 10 - 20" },
  { min: 20, max: 30, title: "Lvl 20 - 30" },
  { min: 30, max: 40, title: "Lvl 30 - 40" },
  { min: 40, max: 50, title: "Lvl 40 - 50" },
  { min: 50, max: 60, title: "Lvl 50 - 60" }
];

let players = {};
let maxCalculatedLimit = 30;

function formatPlayerDisplayName(p) {
  if (!p) return '';
  const isExcluded = !p.realm || p.realm === 'WoWForever' || p.realm === '93' || p.realm === 'Rindenmulch' || p.realm === 'Rindenmantel' || p.realm === 'Manastrudel';
  return isExcluded ? p.name : `${p.name} (${p.realm})`;
}

const trackViewport = document.getElementById('trackViewport');
const trackCanvas = document.getElementById('trackCanvas');
const scaleZonesWrapper = document.getElementById('scaleZonesWrapper');
const lanesContainer = document.getElementById('lanesContainer');
const totalPlayersCount = document.getElementById('totalPlayersCount');
const leaderLevelEl = document.getElementById('leaderLevel');
const trackLimitText = document.getElementById('trackLimitText');
const unlockedLevelBadge = document.getElementById('unlockedLevelBadge');
const pennantTooltip = document.getElementById('pennantTooltip');
const tooltipBackdrop = document.getElementById('tooltipBackdrop');
let activeTooltipId = null;

const isMobileScreen = () => window.innerWidth <= 768;

const lbHighestLevel = document.getElementById('lbHighestLevel');
const lbFastestLevel = document.getElementById('lbFastestLevel');
const lbMaxDeaths = document.getElementById('lbMaxDeaths');
const lbTopAccounts = document.getElementById('lbTopAccounts');

function calculateDynamicMaxLevel() {
  const playerList = Object.values(players);
  if (playerList.length === 0) return 15;

  let highest = 1;
  playerList.forEach(p => {
    if (p.level > highest) highest = p.level;
  });

  if (highest >= 58) return 60;
  let limit = Math.ceil((highest + 2) / 5) * 5;
  return Math.min(60, Math.max(15, limit));
}

function renderTrackScale() {
  maxCalculatedLimit = calculateDynamicMaxLevel();

  const playerColWidth = 220;
  const viewportWidth = trackViewport.clientWidth || 1200;
  const availableTrackWidth = Math.max(800, viewportWidth - playerColWidth);

  const minPixelsPerLevel = 60;
  const computedTrackWidth = (maxCalculatedLimit - 1) * minPixelsPerLevel;
  
  const finalTrackWidth = Math.max(availableTrackWidth, computedTrackWidth);
  const totalCanvasWidth = finalTrackWidth + playerColWidth;

  trackCanvas.style.width = `${totalCanvasWidth}px`;

  scaleZonesWrapper.innerHTML = '';
  scaleZonesWrapper.style.width = `${finalTrackWidth}px`;

  LEVEL_SEGMENTS.forEach(seg => {
    if (seg.min < maxCalculatedLimit) {
      const segStart = seg.min - 1;
      const segEnd = Math.min(seg.max, maxCalculatedLimit) - 1;
      const spanLevels = segEnd - segStart;
      
      if (spanLevels > 0) {
        const segWidthRatio = spanLevels / (maxCalculatedLimit - 1);
        const segWidthPx = segWidthRatio * finalTrackWidth;

        const segEl = document.createElement('div');
        segEl.className = 'scale-zone';
        segEl.style.width = `${segWidthPx}px`;
        segEl.innerHTML = `<span>${seg.title}</span>`;
        scaleZonesWrapper.appendChild(segEl);
      }
    }
  });

  trackLimitText.textContent = `Lvl ${maxCalculatedLimit}`;
  unlockedLevelBadge.textContent = `Level ${maxCalculatedLimit}`;

  return finalTrackWidth;
}

function renderLanes() {
  const trackWidth = renderTrackScale();
  lanesContainer.innerHTML = '';
  const playerList = Object.values(players);

  playerList.sort((a, b) => {
    const progA = (a.level || 1) + (a.progress || 0);
    const progB = (b.level || 1) + (b.progress || 0);
    return progB - progA;
  });

  totalPlayersCount.textContent = playerList.length;
  if (playerList.length > 0) {
    leaderLevelEl.textContent = `Lvl ${playerList[0].level}`;
  }

  playerList.forEach(player => {
    const lane = document.createElement('div');
    lane.className = 'player-lane';

    const mountName = MOUNT_NAMES[player.mount] || 'Reittier';
    const xpPct = player.xpPercent || (player.progress ? Math.floor(player.progress * 100) : 0);
    const timeStr = player.totalTimeFormatted || (player.totalTime ? `${Math.floor(player.totalTime / 3600)}h` : '0m');

    // 1. STICKY Spieler Info links (Desktop) & Kartenkopf (Mobile)
    const playerInfo = document.createElement('div');
    playerInfo.className = 'lane-player-info';
    playerInfo.innerHTML = `
      <div class="player-avatar">
        <img src="${CLASS_ICONS[player.class] || CLASS_ICONS.WARRIOR}" alt="${player.class}">
      </div>
      <div class="player-meta">
        <div class="player-name class-${player.class}">${formatPlayerDisplayName(player)}</div>
        <div class="player-zone">${player.zone || 'Azeroth'}</div>
        <div class="player-sub-mobile">${player.race || ''} • ${mountName}</div>
      </div>
      <div class="player-mobile-badge">
        <span class="pm-level">Lvl ${player.level}</span>
        <span class="pm-xp">+${xpPct}%</span>
      </div>
    `;

    // 2. Mobile Mini-Skala über der Schiene
    const mobileScale = document.createElement('div');
    mobileScale.className = 'mobile-track-scale';
    mobileScale.innerHTML = `<span>START (Lvl 1)</span><span>🚩 ZIEL (Lvl ${maxCalculatedLimit})</span>`;

    // 3. Rennstrecke
    const trackStrip = document.createElement('div');
    trackStrip.className = 'lane-track-strip';
    trackStrip.style.width = `${trackWidth}px`;

    const rail = document.createElement('div');
    rail.className = 'lane-rail';

    const effectiveLvl = (player.level || 1) + (player.progress || 0);
    const progressRatio = Math.min(1.0, Math.max(0, (effectiveLvl - 1) / (maxCalculatedLimit - 1)));
    const progressPct = (progressRatio * 100).toFixed(2);

    const progressBar = document.createElement('div');
    progressBar.className = 'lane-progress-bar';
    progressBar.style.width = `${progressPct}%`;

    // Meilenstein Wimpel
    for (let lvl = 10; lvl <= 60; lvl += 10) {
      if (lvl <= maxCalculatedLimit) {
        const flagRatio = (lvl - 1) / (maxCalculatedLimit - 1);
        const flagPct = (flagRatio * 100).toFixed(2);
        const reached = player.level >= lvl;
        const msData = player.milestones && player.milestones[lvl];

        const flagEl = document.createElement('div');
        flagEl.className = `milestone-pennant ${reached ? 'reached' : 'locked'}`;
        flagEl.style.left = `${flagPct}%`;
        flagEl.innerHTML = `
          <svg class="pennant-flag" viewBox="0 0 24 24" fill="${reached ? '#ffcc00' : '#888'}">
            <path d="M14.4 6L14 4H5v17h2v-7h5.6l.4 2h7V6z"/>
          </svg>
        `;

        const flagTargetId = `flag_${player.name}_${lvl}`;

        flagEl.addEventListener('mouseenter', (e) => {
          if (!isMobileScreen()) {
            showPennantTooltip(e, lvl, msData, player, flagTargetId);
          }
        });
        flagEl.addEventListener('mouseleave', () => {
          if (!isMobileScreen()) {
            hideTooltip();
          }
        });
        flagEl.addEventListener('click', (e) => {
          if (isMobileScreen()) {
            e.stopPropagation();
            if (!pennantTooltip.classList.contains('hidden') && activeTooltipId === flagTargetId) {
              hideTooltip();
            } else {
              showPennantTooltip(e, lvl, msData, player, flagTargetId);
            }
          }
        });

        trackStrip.appendChild(flagEl);
      }
    }

    // Volksreittier mit interaktivem Hover-Tooltip & Mobile-Modal
    const mountImgUrl = MOUNT_ICONS[player.mount] || MOUNT_ICONS.HORSE;
    const horse = document.createElement('div');
    horse.className = 'derby-horse';
    horse.style.left = `${progressPct}%`;
    horse.innerHTML = `
      <div class="horse-chassis">
        <img src="${mountImgUrl}" alt="${player.mount || 'Reittier'}">
        <span class="horse-level-bubble">${player.level}</span>
      </div>
    `;

    const horseTargetId = `horse_${player.name}`;

    // Desktop: Hover / Mobile: Click Toggle & Centered Modal
    horse.addEventListener('mouseenter', (e) => {
      if (!isMobileScreen()) {
        showHorseTooltip(e, player, horseTargetId);
      }
    });
    horse.addEventListener('mouseleave', () => {
      if (!isMobileScreen()) {
        hideTooltip();
      }
    });
    horse.addEventListener('click', (e) => {
      if (isMobileScreen()) {
        e.stopPropagation();
        if (!pennantTooltip.classList.contains('hidden') && activeTooltipId === horseTargetId) {
          hideTooltip();
        } else {
          showHorseTooltip(e, player, horseTargetId);
        }
      }
    });

    trackStrip.appendChild(rail);
    trackStrip.appendChild(progressBar);
    trackStrip.appendChild(horse);

    // 4. Mobile Karten-Footer
    const cardFooter = document.createElement('div');
    cardFooter.className = 'lane-mobile-footer';
    cardFooter.innerHTML = `
      <span class="lmf-loc">📍 ${player.zone || 'Azeroth'}</span>
      <span class="lmf-stats">⏱ ${timeStr} • 💀 ${player.deaths || 0}</span>
    `;

    lane.appendChild(playerInfo);
    lane.appendChild(mobileScale);
    lane.appendChild(trackStrip);
    lane.appendChild(cardFooter);
    lanesContainer.appendChild(lane);
  });

  renderLeaderboards();
}

/**
 * Tooltip beim Hovern ueber ein Reittier (Desktop) / Modal (Mobile)
 */
function showHorseTooltip(e, p, targetId) {
  activeTooltipId = targetId || `horse_${p.name}`;
  const mountName = MOUNT_NAMES[p.mount] || 'Volksreittier';
  const pct = p.xpPercent || (p.progress ? Math.floor(p.progress * 100) : 0);
  const timeStr = p.totalTimeFormatted || (p.totalTime ? `${Math.floor(p.totalTime/3600)}h` : 'Wird ermittelt...');

  pennantTooltip.innerHTML = `
    <div class="tt-header">
      <span class="tt-flag-icon">🏇</span>
      <span class="tt-title class-${p.class}">${formatPlayerDisplayName(p)} (Lvl ${p.level})</span>
      <button type="button" class="tt-close-btn" aria-label="Schließen" onclick="hideTooltip()">✕</button>
    </div>
    <div class="tt-body">
      <div class="tt-row">
        <span class="tt-label">🐴 Reittier:</span>
        <span class="tt-val" style="color:var(--gold);">${mountName}</span>
      </div>
      <div class="tt-row">
        <span class="tt-label">📈 Fortschritt:</span>
        <span class="tt-val" style="color:#00e5ff;">Level ${p.level} + ${pct}%</span>
      </div>
      <div class="tt-row">
        <span class="tt-label">⏱️ Spielzeit:</span>
        <span class="tt-val">${timeStr}</span>
      </div>
      <div class="tt-row">
        <span class="tt-label">🗺️ Zone:</span>
        <span class="tt-val">${p.zone || 'Welt'}</span>
      </div>
      <div class="tt-row">
        <span class="tt-label">💀 Tode:</span>
        <span class="tt-val danger">${p.deaths || 0}</span>
      </div>
    </div>
    <div class="tt-close-hint">✕ Tippen zum Schließen</div>
  `;

  pennantTooltip.classList.remove('hidden');

  if (isMobileScreen()) {
    if (tooltipBackdrop) tooltipBackdrop.classList.remove('hidden');
    pennantTooltip.style.left = '';
    pennantTooltip.style.top = '';
  } else {
    if (tooltipBackdrop) tooltipBackdrop.classList.add('hidden');
    pennantTooltip.style.left = `${e.clientX + 16}px`;
    pennantTooltip.style.top = `${e.clientY - 20}px`;
  }
}

/**
 * Tooltip beim Hovern ueber einen Meilenstein-Wimpel (Desktop) / Modal (Mobile)
 */
function showPennantTooltip(e, level, msData, player, targetId) {
  activeTooltipId = targetId || `flag_${player.name}_${level}`;
  let timeStr = 'Noch nicht erreicht';
  let zoneStr = '-';
  let deathsStr = '-';

  if (msData) {
    timeStr = msData.timeFormatted || 'Unbekannt';
    zoneStr = msData.zone || player.zone || 'Unbekannt';
    deathsStr = msData.deaths !== undefined ? msData.deaths : '0';
  } else if (player.level >= level) {
    timeStr = 'Erreicht';
    zoneStr = player.zone || 'Welt';
    deathsStr = player.deaths || 0;
  }

  pennantTooltip.innerHTML = `
    <div class="tt-header">
      <span class="tt-flag-icon">🚩</span>
      <span class="tt-title">Meilenstein Level ${level}</span>
      <button type="button" class="tt-close-btn" aria-label="Schließen" onclick="hideTooltip()">✕</button>
    </div>
    <div class="tt-body">
      <div class="tt-row">
        <span class="tt-label">⏱️ Spielzeit (/played):</span>
        <span class="tt-val">${timeStr}</span>
      </div>
      <div class="tt-row">
        <span class="tt-label">🗺️ Erreicht in Zone:</span>
        <span class="tt-val">${zoneStr}</span>
      </div>
      <div class="tt-row">
        <span class="tt-label">💀 Tode bis dahin:</span>
        <span class="tt-val danger">${deathsStr}</span>
      </div>
    </div>
    <div class="tt-close-hint">✕ Tippen zum Schließen</div>
  `;

  pennantTooltip.classList.remove('hidden');

  if (isMobileScreen()) {
    if (tooltipBackdrop) tooltipBackdrop.classList.remove('hidden');
    pennantTooltip.style.left = '';
    pennantTooltip.style.top = '';
  } else {
    if (tooltipBackdrop) tooltipBackdrop.classList.add('hidden');
    pennantTooltip.style.left = `${e.clientX + 16}px`;
    pennantTooltip.style.top = `${e.clientY - 20}px`;
  }
}

function hideTooltip() {
  activeTooltipId = null;
  pennantTooltip.classList.add('hidden');
  if (tooltipBackdrop) tooltipBackdrop.classList.add('hidden');
}

// Schließen beim Tippen auf das Backdrop oder das Tooltip selbst auf Mobilgeräten
if (tooltipBackdrop) {
  tooltipBackdrop.addEventListener('click', hideTooltip);
}

pennantTooltip.addEventListener('click', () => {
  if (isMobileScreen()) {
    hideTooltip();
  }
});

// Klick irgendwo ausserhalb schliesst das Tooltip auf Mobilgeräten
document.addEventListener('click', (e) => {
  if (isMobileScreen() && !pennantTooltip.classList.contains('hidden')) {
    if (!e.target.closest('.derby-horse') && !e.target.closest('.milestone-pennant') && !e.target.closest('#pennantTooltip')) {
      hideTooltip();
    }
  }
});

/**
 * Leaderboards
 */
function renderLeaderboards() {
  const playerList = Object.values(players);
  if (playerList.length === 0) return;

  const getRankClass = (idx) => idx === 0 ? 'r1' : (idx === 1 ? 'r2' : (idx === 2 ? 'r3' : ''));

  // 1. Höchstes Level
  const sortedLevel = [...playerList].sort((a, b) => {
    const la = (a.level || 1) + (a.progress || 0);
    const lb = (b.level || 1) + (b.progress || 0);
    return lb - la;
  }).slice(0, 5);

  lbHighestLevel.innerHTML = sortedLevel.map((p, idx) => `
    <div class="lb-item">
      <span class="lb-rank ${getRankClass(idx)}">#${idx + 1}</span>
      <div class="lb-player-badge">
        <img class="lb-avatar" src="${CLASS_ICONS[p.class] || CLASS_ICONS.WARRIOR}">
        <span class="lb-name class-${p.class}">${formatPlayerDisplayName(p)}</span>
      </div>
      <span class="lb-value gold">Lvl ${p.level}</span>
    </div>
  `).join('');

  // 2. Speedrunner (/played)
  const sortedSpeed = [...playerList].filter(p => (p.totalTime || 0) > 0).sort((a, b) => {
    const rateA = ((a.level || 1) + (a.progress || 0)) / (a.totalTime / 3600);
    const rateB = ((b.level || 1) + (b.progress || 0)) / (b.totalTime / 3600);
    return rateB - rateA;
  }).slice(0, 5);

  lbFastestLevel.innerHTML = (sortedSpeed.length > 0 ? sortedSpeed : sortedLevel).map((p, idx) => `
    <div class="lb-item">
      <span class="lb-rank ${getRankClass(idx)}">#${idx + 1}</span>
      <div class="lb-player-badge">
        <img class="lb-avatar" src="${CLASS_ICONS[p.class] || CLASS_ICONS.WARRIOR}">
        <span class="lb-name class-${p.class}">${formatPlayerDisplayName(p)}</span>
      </div>
      <span class="lb-value speed">${p.totalTimeFormatted || 'Speed'}</span>
    </div>
  `).join('');

  // 3. Meiste Tode
  const sortedDeaths = [...playerList].sort((a, b) => (b.deaths || 0) - (a.deaths || 0)).slice(0, 5);

  lbMaxDeaths.innerHTML = sortedDeaths.map((p, idx) => `
    <div class="lb-item">
      <span class="lb-rank ${getRankClass(idx)}">#${idx + 1}</span>
      <div class="lb-player-badge">
        <img class="lb-avatar" src="${CLASS_ICONS[p.class] || CLASS_ICONS.WARRIOR}">
        <span class="lb-name class-${p.class}">${formatPlayerDisplayName(p)}</span>
      </div>
      <span class="lb-value danger">💀 ${p.deaths || 0}</span>
    </div>
  `).join('');

  // 4. Top Charaktere (Gruppiert nach Account + Anzeige Anzahl Charaktere des Spielers)
  const accountGroups = {};
  playerList.forEach(p => {
    const acc = p.account || p.name;
    if (!accountGroups[acc]) {
      accountGroups[acc] = {
        account: acc,
        bestChar: p,
        totalChars: 0,
        chars: []
      };
    }
    accountGroups[acc].totalChars++;
    accountGroups[acc].chars.push(p);

    const curBestProg = (accountGroups[acc].bestChar.level || 1) + (accountGroups[acc].bestChar.progress || 0);
    const thisProg = (p.level || 1) + (p.progress || 0);
    if (thisProg > curBestProg) {
      accountGroups[acc].bestChar = p;
    }
  });

  const sortedAccounts = Object.values(accountGroups).sort((a, b) => {
    const la = (a.bestChar.level || 1) + (a.bestChar.progress || 0);
    const lb = (b.bestChar.level || 1) + (b.bestChar.progress || 0);
    return lb - la;
  }).slice(0, 5);

  lbTopAccounts.innerHTML = sortedAccounts.map((grp, idx) => {
    const p = grp.bestChar;
    const charLabel = grp.totalChars === 1 ? '1 Char' : `${grp.totalChars} Chars`;
    return `
      <div class="lb-item">
        <span class="lb-rank ${getRankClass(idx)}">#${idx + 1}</span>
        <div class="lb-player-badge">
          <img class="lb-avatar" src="${MOUNT_ICONS[p.mount] || MOUNT_ICONS.HORSE}">
          <span class="lb-name class-${p.class}">${formatPlayerDisplayName(p)}</span>
          <span class="lb-chars-badge" title="${grp.totalChars} Charaktere von diesem Account im Rennen">${charLabel}</span>
        </div>
        <span class="lb-value gold">Lvl ${p.level}</span>
      </div>
    `;
  }).join('');
}

async function fetchServerData() {
  try {
    const res = await fetch('api/update.php');
    if (res.ok) {
      const data = await res.json();
      if (data && data.players && Object.keys(data.players).length > 0) {
        Object.values(data.players).forEach(p => {
          if (p.key && p.key.includes('-') && (!p.name || !p.name.includes('-'))) {
            p.name = p.key;
          }
          if (p.realm === 'Rindenmulch' || p.realm === 'Rindenmantel' || p.realm === 'Manastrudel' || p.realm === 'WoWForever' || p.realm === '93') {
            p.realm = '';
          }
        });
        players = data.players;
        renderLanes();
        document.getElementById('connStatus').textContent = 'Server Live-Daten aktiv';
        return true;
      }
    }
  } catch (err) {}
  return false;
}

function loadDemoData() {
  players = {
    // Gruppe 20 - 25
    "Ironbeard": {
      name: "Ironbeard",
      account: "ACC_ALPHA",
      class: "WARRIOR",
      mount: "RAM",
      level: 24,
      progress: 0.65,
      totalTime: 196200,
      totalTimeFormatted: "2t 6h 30m",
      zone: "Vorgebirge des Huegellands",
      deaths: 2,
      milestones: {
        10: { level: 10, timeFormatted: "1t 1h 10m", zone: "Dun Morogh", deaths: 0 },
        20: { level: 20, timeFormatted: "2t 6h 30m", zone: "Loch Modan", deaths: 1 }
      }
    },
    "Lumina": {
      name: "Lumina",
      account: "ACC_BETA",
      class: "PRIEST",
      mount: "SABER",
      level: 22,
      progress: 0.40,
      totalTime: 180300,
      totalTimeFormatted: "2t 2h 05m",
      zone: "Eschental",
      deaths: 0,
      milestones: {
        10: { level: 10, timeFormatted: "22h 15m", zone: "Dunkelkueste", deaths: 0 },
        20: { level: 20, timeFormatted: "2t 2h 05m", zone: "Eschental", deaths: 0 }
      }
    },
    "Shadowblade": {
      name: "Shadowblade",
      account: "ACC_GAMMA",
      class: "ROGUE",
      mount: "WOLF",
      level: 21,
      progress: 0.85,
      totalTime: 166320,
      totalTimeFormatted: "1t 22h 12m",
      zone: "Das Brachland",
      deaths: 7,
      milestones: {
        10: { level: 10, timeFormatted: "19h 40m", zone: "Durotar", deaths: 1 },
        20: { level: 20, timeFormatted: "1t 22h 12m", zone: "Brachland", deaths: 4 }
      }
    },

    // Mittelfeld 10 - 20
    "Froststrike": {
      name: "Froststrike",
      account: "ACC_DELTA",
      class: "MAGE",
      mount: "HORSE",
      level: 18,
      progress: 0.30,
      totalTime: 115200,
      totalTimeFormatted: "1t 8h 00m",
      zone: "Westfall",
      deaths: 1,
      milestones: {
        10: { level: 10, timeFormatted: "16h 20m", zone: "Wald von Elwynn", deaths: 0 }
      }
    },
    "Oakenshield": {
      name: "Oakenshield",
      account: "ACC_ALPHA",
      class: "PALADIN",
      mount: "RAM",
      level: 14,
      progress: 0.55,
      totalTime: 72000,
      totalTimeFormatted: "20h 00m",
      zone: "Rotkammgebirge",
      deaths: 0,
      milestones: {
        10: { level: 10, timeFormatted: "12h 10m", zone: "Dun Morogh", deaths: 0 }
      }
    },
    "Nightstalker": {
      name: "Nightstalker",
      account: "ACC_GAMMA",
      class: "DRUID",
      mount: "SABER",
      level: 11,
      progress: 0.90,
      totalTime: 54000,
      totalTimeFormatted: "15h 00m",
      zone: "Dunkelkueste",
      deaths: 2,
      milestones: {
        10: { level: 10, timeFormatted: "13h 45m", zone: "Teldrassil", deaths: 1 }
      }
    },

    // Gruppe 5 - 10
    "Thunderhoof": {
      name: "Thunderhoof",
      account: "ACC_EPSILON",
      class: "SHAMAN",
      mount: "KODO",
      level: 9,
      progress: 0.70,
      totalTime: 28800,
      totalTimeFormatted: "8h 00m",
      zone: "Mulgore",
      deaths: 1,
      milestones: {}
    },
    "Sparkplug": {
      name: "Sparkplug",
      account: "ACC_ZETA",
      class: "MAGE",
      mount: "STRIDER",
      level: 7,
      progress: 0.50,
      totalTime: 18000,
      totalTimeFormatted: "5h 00m",
      zone: "Wald von Elwynn",
      deaths: 3,
      milestones: {}
    },
    "Rotface": {
      name: "Rotface",
      account: "ACC_ETA",
      class: "WARLOCK",
      mount: "SKELETON",
      level: 6,
      progress: 0.20,
      totalTime: 10800,
      totalTimeFormatted: "3h 00m",
      zone: "Tirisfal",
      deaths: 11,
      milestones: {}
    },
    "Bloodfang": {
      name: "Bloodfang",
      account: "ACC_GAMMA",
      class: "HUNTER",
      mount: "RAPTOR",
      level: 5,
      progress: 0.45,
      totalTime: 7200,
      totalTimeFormatted: "2h 00m",
      zone: "Durotar",
      deaths: 0,
      milestones: {}
    }
  };

  renderLanes();
}

window.addEventListener('resize', () => {
  hideTooltip();
  renderLanes();
});

const urlParams = new URLSearchParams(window.location.search);
const isDemoForced = urlParams.has('demo') || urlParams.has('test');

if (isDemoForced) {
  loadDemoData();
  const connStatus = document.getElementById('connStatus');
  if (connStatus) connStatus.textContent = "Demo-Modus aktiv (?demo)";
} else {
  fetchServerData().then(hasData => {
    if (!hasData) {
      loadDemoData();
    }
  });

  setInterval(fetchServerData, 15000);
}
