# MIM Control — Online Control Interface

Browser-based configuration and control interface for the **MIM** (Mouse Input Modifier) hardware device. The interface connects to the MIM via **WebSerial (USB)** and provides real-time parameter editing, velocity curve visualization, firmware OTA updates, and keyboard macro management — all in a single-page app with no installation required.

**Live:** [mim-control.com](https://mim-control.com)

---

## Pages

| URL | Purpose |
|---|---|
| `mim-control.com/` | Main control interface |
| `mim-control.com/update/` | Firmware OTA update |
| `mim-control.com/dev-options/` | Developer tools (not linked publicly) |

---

## Browser Requirements

WebSerial is required. **Chrome or Edge ≥ 89** over HTTPS or `localhost`.  
Firefox and Safari are not supported.

---

## Main Control Page (`/`)

### Connection

The page connects to the MIM via **WebSerial at 115200 baud**. On connect it automatically:

1. Sends `ping` → reads active mode and firmware version (shown in the status bar)
2. Sends `get_status` → reads sleep state
3. Sends `get_config` → populates all sliders and charts
4. Starts a background **auto-sync** (`get_config` every 3 s) — paused while the device is asleep

The status bar shows connection state, firmware version (e.g. `FW 2.3.7-alpha`), round-trip latency, and the currently active mode (`MIM` / `KIM` / `AIM` / `CIM`).

**Sleep/wake:** the device sends unsolicited `{event:"sleep"}` and `{event:"wake"}` events; on wake the config is re-fetched immediately.

### Output Mode Switching

Two mode-switch buttons are always visible in the header:

| Button | Effect |
|---|---|
| **Joypad output mode** | 3-step wizard → switches to `AIM` (Mouse→Stick) or `CIM` (Controller pass-through) |
| **MnK output mode** | Switches back to `MIM` / `KIM` |

Mode switches trigger a device reboot; the browser disconnects automatically and must reconnect manually.

---

### Tab: MIM

The MIM tab is the main operating mode: mouse input is processed through velocity splines and output as modified mouse movement.

#### Profiles

Three named profile slots stored in `localStorage`. Each slot can be:

- **Loaded** (single click) — sends all stored values to the device
- **Saved** (Save button) — captures current parameter state into the slot
- **Renamed** (double-click on the slot name) — inline editable
- **Reset** (Default button) — resets all parameters to factory defaults

The active slot highlight is cleared as soon as any parameter is changed, making unsaved modifications visually obvious.

#### Velocity Curves

Two live **Chart.js** plots display the current X/Y spline curves in real time:

- **X-Speed** chart — blue, X axis `t [ms]` (0–5000), Y axis `px/s`
- **Y-Speed** chart — orange

Both charts use a **Catmull-Rom Hermite spline** (7 control points), identical to the firmware and Python implementation. Charts redraw 250 ms after the last parameter change.

#### Velocity Spline Parameters

14 vertical range sliders (7 for X, 7 for Y), each with a manual text input and a `Set` button. Slider changes are debounced and sent to the device 120 ms after the last input.

| Parameter | Range | Unit | Default |
|---|---|---|---|
| vX0 – vX6 | −500 … +500 | px/s | 0 |
| vY0 – vY6 | −500 … +500 | px/s | 0 |

#### Parameters

| Parameter | Range | Step | Unit | Default | Description |
|---|---|---|---|---|---|
| X-Delay | 0 – 3000 | 5 | ms | 0 | X-axis output delay |
| Y-Delay | 0 – 3000 | 5 | ms | 0 | Y-axis output delay |
| Sigma | 0.1 – 15 | 0.1 | % | 1 | Gaussian smoothing width |
| RF-Hz | 0 – 20 | 0.1 | Hz | 0 | Rapid-Fire frequency |
| RF-Sprd | 0.1 – 15 | 0.1 | % | 1 | Rapid-Fire timing spread |
| RF-Duty | 5 – 95 | 5 | % | 70 | Rapid-Fire duty cycle |
| T-End | 500 – 10000 | 25 | ms | 5000 | Motion limiter window |

#### OLED Preview

A **256×128 px canvas** renders a live preview of what the device's OLED display shows. Three pages can be toggled:

| Page | Content |
|---|---|
| **P1** | X-Speed spline values (vX0–vX6) |
| **P2** | Y-Speed spline values (vY0–vY6) |
| **P3** | Settings: Sigma · RF-Hz · RF-Sprd · RF-Duty · T-End |

Preview redraws 60 ms after any parameter change.

#### Serial Monitor

A scrollable live log (up to 400 lines) shows all JSON messages sent to (`→`) and received from (`←`) the device. A `clear` button resets the log.

#### Export / Import

Profiles can be exported and imported as JSON files:

- **Export** — downloads `mim_preset_<profile_name>.json` with all 21 parameters plus metadata (`_schema`, `_fw_version`, export timestamp)
- **Import** — loads a `.json` file; validates `_mim_preset` flag and schema version before applying

---

### Tab: KIM (Keyboard Input Modifier)

KIM mode lets the device intercept and remap keyboard input. The tab provides a full macro editor.

#### Active Toggle

A toggle switch enables/disables KIM mode on the device without changing the entry list.

#### Entry Types

Each entry maps one trigger (key or chord) to an action:

| Type | Trigger | Action |
|---|---|---|
| **Key Sequence** | Single key | Up to 4 steps, each with a key, hold duration, and pause duration |
| **Double-Tap** | Single key | A separate key output fires on double-tap within a configurable gap (50–500 ms) |
| **Chord** | Two simultaneous keys | Same step sequence as Key Sequence |

All entries support three **trigger modes**: `Tap`, `Hold`, or `Toggle`.

#### Key Binding

Clicking a bind button enters capture mode: the firmware listens for the next physical keypress and reports the HID keycode back to the browser. Supported keys include A–Z, 0–9, F1–F12, all punctuation, modifier keys, and navigation keys.

#### Step Configuration (Key Sequence / Chord)

Each of up to 4 steps has:
- **Key** — bound via firmware capture
- **Hold** — 1–2000 ms, how long the key is held down
- **Pause** — 0–2000 ms, pause after releasing before the next step

#### Global Sigma (KIM)

A `Spread σ` slider (0–50 %, step 0.5, default 5.0 %) applies Gaussian jitter to all hold and pause timings in every KIM entry, mirroring the smoothing concept from MIM mode.

#### KIM Export / Import

- **Export** — downloads `kim_profile.json` with the complete KIM profile
- **Import** — loads a `.json` KIM profile
- **Reset** — resets to defaults: inactive, σ = 5.0 %, no entries

---

### Tab: CIM (Controller Input Modifier)

Controller pass-through mode is active. Axis assignment, fire-button configuration, and a spline curve editor are planned for a later phase.

---

## Firmware Update Page (`/update/`)

**URL:** `mim-control.com/update/`

Provides a one-click **OTA firmware update** over WebSerial — no file selection, no Teensy Loader required.

### Features

- **Version comparison** — shows installed firmware version (read from device via `ping`) vs. the latest available version (from `version.json`)
- **Status indicator** — `up to date` (green) or `update available` (orange)
- **Changelog** — displays the release notes for the available version
- **Flash Firmware** button — triggers a confirmation modal, then:
  1. Downloads the `.hex` file from `version.json → hex_url`
  2. Parses the Intel HEX format in the browser
  3. Transfers firmware in **256-byte blocks** over the JSON OTA protocol (`ota_start` → `ota_block` × N → `ota_finish`)
  4. Verifies a **CRC32** checksum end-to-end
  5. Device reboots; the page attempts an **automatic reconnect** after 5 s
- **Progress bar** with percentage during transfer

### OTA Protocol (JSON over UART)

```
Browser → Device:  {cmd:"ota_start", total_bytes:N, block_size:256}
Device → Browser:  {ota:"ready"}

Browser → Device:  {cmd:"ota_block", seq:i, addr:0x..., data:"<base64>"}
Device → Browser:  {ota:"ack"} | {ota:"nack", msg:"..."}

Browser → Device:  {cmd:"ota_finish", crc32:0x...}
Device → Browser:  {ota:"ok"}          → device reboots

Browser → Device:  {cmd:"ota_abort", reason:"browser_error"}  (on error)
```

---

## Developer Options Page (`/dev-options/`)

**URL:** `mim-control.com/dev-options/` — not linked from the main UI.

Intended for developers and technical testers.

### Features

| Section | Description |
|---|---|
| **Device Connection** | WebSerial connect/disconnect (same as main page) |
| **Firmware Download (Rollback)** | Select any released firmware version from `versions.json` and download the `.hex` for manual flashing via Teensy Loader |
| **Serial Monitor / Console** | Full bidirectional serial terminal at 115200 baud — accepts raw text commands (`p`, `t`, …) and JSON commands (`{"cmd":"ping"}`); auto-scrolls while at bottom; 600-line cap |
| **WebHID Flash (Legacy)** | Direct HID-based flash via the Teensy HalfKay bootloader — **not functional on Windows** (OS HID driver conflict); use OTA update or Teensy Loader instead |

---

## Profile Persistence (EEPROM)

All MIM parameters are automatically saved to the Teensy 4.1's emulated EEPROM after a **2-second debounce** (triggered by any parameter change via the web interface, the physical encoder, or a `set_config` command).

The TFT display briefly shows **SAVED** (green) after each successful write.

Stored parameters: `vX[0–6]`, `vY[0–6]`, `xDelay`, `yDelay`, `sigmaPct`, `rfHz`, `rfSpread`, `rfDutyPct`, `tEndMs`.

See [`docs/profile_persistence.md`](docs/profile_persistence.md) for the full EEPROM layout, validation logic, wear analysis, and API reference.

---

## Repository Structure

```
docs/               GitHub Pages root (mim-control.com)
├── index.html          Main control interface
├── update/
│   └── index.html      Firmware OTA update page
├── dev-options/
│   └── index.html      Developer tools (not linked publicly)
├── firmware/
│   └── *.hex           Firmware binaries (v2.3.4-alpha … v2.3.7-alpha)
├── version.json        Latest firmware version + changelog
├── versions.json       All available versions (for rollback)
├── mim_logo_v6.png/svg Logo assets
└── profile_persistence.md  EEPROM layout documentation

src/                Source files (build pipeline — in progress)
```
