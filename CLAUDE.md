# MIM Control — Web Interface

> Lies diese Datei am Anfang jeder Session. Sie beschreibt den aktuellen Stand des Projekts vollständig.
> Bei Änderungen an Struktur, CSS oder Verhalten: diese Datei aktualisieren.

---

## Projekt-Übersicht

Statische Web-UI für das MIM (Mouse Input Modifier) Gerät. Kein Build-System, kein Framework — reines HTML/CSS/JS.

- **Live-URL:** `https://mim-control.com`
- **Hosting:** GitHub Pages, deployed aus dem `docs/` Ordner
- **Repo:** `https://github.com/Boa-Constrictor-42/mim-control-io`
- **Branch:** `main`
- **Lokaler Pfad:** `C:\Projects\MIM\web`

---

## Dateistruktur

```
C:\Projects\MIM\web\
├── push.bat                        ← Git-Push-Skript (IMMER so pushen, nie anders)
├── CLAUDE.md                       ← Diese Datei
└── docs/                           ← GitHub Pages Root
    ├── index.html                  ← Control-Seite (Hauptseite, ~2100 Zeilen)
    ├── mim_logo_v6.png             ← Haupt-Logo (PNG)
    ├── mim_logo_v6.svg             ← Haupt-Logo Fallback (SVG)
    ├── mim_logo.png                ← Altes Logo (nicht mehr in Verwendung)
    ├── update/
    │   └── index.html              ← Firmware-Update-Seite
    └── dev-options/
        └── index.html              ← Developer Options (versteckt, /dev-options/)
```

---

## Git Push

Direkt aus dem Linux-Sandbox via GitHub Token. Token liegt unter `C:\Projects\GitHubToken.txt` (projekt-übergreifend).

### Ablauf (in bash):
```bash
TOKEN=$(cat /sessions/lucid-keen-franklin/mnt/Projects/GitHubToken.txt | tr -d '[:space:]')
cd /sessions/lucid-keen-franklin/mnt/web
git add -A
git commit -m "commit message hier"
git -c credential.helper="" \
    -c "url.https://${TOKEN}@github.com/.insteadOf=https://github.com/" \
    push origin main
```

### Bash-Pfade:
| Windows-Pfad | Bash-Pfad |
|---|---|
| `C:\Projects\GitHubToken.txt` | `/sessions/lucid-keen-franklin/mnt/Projects/GitHubToken.txt` |
| `C:\Projects\MIM\web` | `/sessions/lucid-keen-franklin/mnt/web` |

> `push.bat` existiert noch als Fallback, wird aber nicht mehr verwendet.

---

## CSS Design System

Alle drei Seiten teilen dieselben CSS-Variablen:

```css
--bg:#0a0a0a        /* Haupt-Hintergrund */
--bg2:#111111       /* Header, Sidebar, Card-Header */
--bg3:#1a1a1a       /* Hover-States, Chart-Hintergründe */
--bg4:#222222       /* Tiefe Elemente */
--border:#282828
--border2:#333333
--text:#cccccc
--dim:#666666       /* Inaktiver Text */
--dim2:#444444      /* Sehr gedimmter Text */
--green:#00cc66     /* Akzentfarbe: aktiv, verbunden */
--blue:#0088cc
--orange:#cc6600
--red:#cc3333       /* Fehler, Disconnect */
```

Font: `"Consolas", "Courier New", monospace` — konsistent auf allen Seiten.

---

## Layout-Architektur

### Sidebar (alle Seiten)
- `position:fixed; left:0; top:0; bottom:0; width:152px`
- `overflow:hidden` — verhindert Text-Bleed bei Collapse-Animation
- `z-index:150`
- `body{margin-left:152px}` — schiebt Content nach rechts

**Responsive Collapse:**
```css
@media(max-width:1100px){
  #sidebar{width:48px !important}
  #sb-subtitle{display:none !important}   /* nur index.html */
  .nav-label{display:none !important}
  .nav-item{padding:11px 0 !important; justify-content:center !important}
  body{margin-left:48px !important}
}
```
> Kein JS, kein Toggle-Button — rein CSS-basiert. Kollabiert bei ≤1100px.

**Sidebar HTML (aktuell — kein Logo darin!):**
```html
<nav id="sidebar">
  <div id="sb-top"></div>   <!-- leer, nur für Höhenausrichtung mit Header -->
  <div id="sb-subtitle">release alpha 0.2</div>  <!-- nur index.html -->
  <a class="nav-item active" href="/">
    <svg>...</svg>
    <span class="nav-label">Control</span>
  </a>
  <a class="nav-item" href="/update/">
    <svg>...</svg>
    <span class="nav-label">Update</span>
  </a>
</nav>
```
> `#sb-top` ist bewusst leer — kein Logo in der Sidebar. Das Logo ist im Header.

### Header (alle Seiten)
- `position:sticky; top:0; z-index:100; height:57px`
- `#hdr-inner`: `max-width:1140px; margin:0 auto` — Content-Frame wie zeit.de
- Logo: `position:absolute; left:50%; transform:translateX(-50%)` — immer zentriert
- Status-Bar: `margin-left:auto` — klebt am rechten Rand des Content-Frames

```html
<!-- index.html Header -->
<header id="hdr">
  <div id="hdr-inner">
    <a id="hdr-logo-wrap" href="/">
      <img id="hdr-logo" src="mim_logo_v6.png" alt="MIM" onerror="this.src='mim_logo_v6.svg'">
    </a>
    <div id="status-bar">
      <div id="dot"></div>
      <span id="s-text">Disconnected</span>
      <span id="s-fw"></span>
      <span id="s-lat"></span>
    </div>
  </div>
</header>

<!-- update/ und dev-options/ Header (kein Status-Bar) -->
<header id="hdr">
  <div id="hdr-inner">
    <a id="hdr-logo-wrap" href="/">
      <img id="hdr-logo" src="../mim_logo_v6.png" alt="MIM" onerror="this.src='../mim_logo_v6.svg'">
    </a>
  </div>
</header>
```

> Logo-Link führt immer zur Homepage (`/`). Auf update/dev-options: `../mim_logo_v6.png`.

### Connect-Wrap (nur index.html)
```html
<div id="conn-wrap">
  <div id="conn-spacer"></div>           <!-- flex:1, schiebt alles auseinander -->
  <button id="conn-btn">⏻  Connect</button>
  <div id="mode-btns">                   <!-- flex:1, justify-content:flex-end -->
    <div class="mb-wrap">
      <button class="mb" id="btn-out-joypad" disabled>Joypad output mode</button>
      <span class="mb-sub">[CIM / AIM]</span>
    </div>
    <div class="mb-wrap">
      <button class="mb" id="btn-out-mnk" disabled>MnK output mode</button>
      <span class="mb-sub">[MIM / KIM / Kombi]</span>
    </div>
    <span id="s-mode"></span>
  </div>
</div>
```

**MnK-Button Verhalten:**
- `btn-out-joypad` → öffnet Joypad-Modal (AIM / CIM Auswahl)
- `btn-out-mnk` → öffnet MnK-Modal (`MnKModal.open()`) mit 3 Optionen:
  - Mouse only (MIM)
  - Keyboard only (KIM)
  - Mouse + Keyboard Kombi (MKCOMBO — Hub mit Maus + Tastatur)

**MKCOMBO-Modus (`mode === 'MKCOMBO'`):**
- `#s-mode` zeigt `"MIM+KIM"`
- Beide Tabs (MIM + KIM) entsperrt; MIM-Panel als Standard sichtbar
- User kann per Tab zwischen MIM- und KIM-Einstellungen wechseln
- `btn-out-mnk` bleibt aktiv (grün), `btn-out-joypad` wechselbar

---

## Seiten im Detail

### `docs/index.html` — Control (Hauptseite)
- ~2100 Zeilen, alles inline (HTML + CSS + JS)
- Externe Abhängigkeit: `chart.js@4.4.0` via CDN
- `#main{opacity:.35; pointer-events:none}` → `#main.on` bei Verbindung
- WebSerial-basiert (`navigator.serial`)
- Enthält: X/Y-Speed Charts, OLED-Preview, Velocity Spline Sliders, Parameter-Tabelle, KIM-Konsole, OLED-Seitenauswahl

### `docs/update/index.html` — Firmware Update
- WebSerial für Firmware-Flash
- Eigener `#btn-connect` (unabhängig von Control-Seite — Verbindung wird beim Seitenwechsel getrennt)
- Enthält Fortschrittsanzeige, Datei-Upload, Flash-Button

### `docs/dev-options/index.html` — Developer Options
- Nicht in der Sidebar verlinkt (versteckte Seite, direkt via URL `/dev-options/`)
- Enthält erweiterte Debug/Konfigurations-Optionen

---

## Bekannte Probleme / Entscheidungen

| Problem | Lösung |
|---|---|
| Sidebar-Collapse funktionierte nicht | `!important` auf alle Collapsed-Regeln + Transition auf `width` |
| Logo-Link in Sidebar wurde entfernt | `#sb-top` bleibt als leerer Spacer für Höhenausrichtung |
| Verbindung bricht beim Seitenwechsel ab | WebSerial kann nicht zwischen Seiten geteilt werden — bekanntes Browser-Limit |
| Status-Bar Position | `margin-left:auto` in Flex + `max-width:1140px` auf `#hdr-inner` → verhält sich wie zeit.de "Abo testen" |
| WebHID/WebSerial auf Mobile | Nicht unterstützt auf Android/iOS — Desktop-only |

---

## Content-Breiten

| Element | max-width |
|---|---|
| `#hdr-inner` | 1140px |
| `#conn-wrap` | 1140px |
| `.wrap` (update, dev-options) | 860px |

---

## Sidebar-Breiten

| Zustand | Breite |
|---|---|
| Normal (>1100px) | 152px |
| Kollabiert (≤1100px) | 48px |
