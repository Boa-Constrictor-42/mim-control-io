# MIM — Profil-Persistenz (EEPROM)

**Dokument:** `profile_persistence.md`  
**Firmware:** MIM v0.2.x  
**Modul:** `profile_storage.h` / `profile_storage.cpp`

---

## Übersicht

Alle MIM-Parameter werden automatisch im Flash des Teensy 4.1 gespeichert.
Wenn der Browser oder die Python-SW geschlossen wird, läuft MIM mit dem
zuletzt gespeicherten Parametersatz weiter — ohne erneute Konfiguration.

### Was wird gespeichert?

| Parameter | Typ | Beschreibung |
|---|---|---|
| `vX[0..6]` | `int16_t[7]` | X-Achse Spline-Stützstellen [px/s] |
| `vY[0..6]` | `int16_t[7]` | Y-Achse Spline-Stützstellen [px/s] |
| `xDelay` | `uint16_t` | X-Verzögerung [ms] |
| `yDelay` | `uint16_t` | Y-Verzögerung [ms] |
| `sigmaPct` | `float` | Gauss-Sigma [%] |
| `rfHz` | `int16_t` | Rapid-Fire Frequenz [Hz] |
| `rfSpread` | `float` | RF-Spread [%] |
| `rfDutyPct` | `uint8_t` | RF-Tastgrad [%] |
| `tEndMs` | `uint32_t` | Motion-Limiter Fenster [ms] |

---

## EEPROM-Layout

Die Daten werden als `ProfileData`-Struct ab **Adresse 0** gespeichert.

```
Offset  Größe  Feld          Inhalt
──────  ─────  ────────────  ──────────────────────────────────────────
0       4      magic         0xA1B20301 — Gültigkeitskennung
4       1      version       Struct-Versionsnummer (aktuell: 1)
5       1      crc           XOR-Checksumme über Bytes 6…53
──────── Payload (CRC-Bereich) ─────────────────────────────────────
6       4      sigmaPct      float
10      4      rfSpread      float
14      4      tEndMs        uint32_t
18      14     vX[0..6]      int16_t[7]
32      14     vY[0..6]      int16_t[7]
46      2      rfHz          int16_t
48      2      xDelay        uint16_t
50      2      yDelay        uint16_t
52      1      rfDutyPct     uint8_t
53      1      _reserved     0x00
──────  ─────
Total   54     Bytes
```

> **Teensy 4.1 EEPROM-Kapazität:** 4284 Bytes emuliert im 2 MB Flash.
> 54 Bytes belegen < 1,3 % davon.

### Validierung beim Laden

Beim Start prüft `loadProfile()` drei Bedingungen in dieser Reihenfolge:

1. **Magic Number** `== 0xA1B20301` — erkennt: nie beschrieben, Firmware-Update
   mit geänderter Struct-Layout
2. **Version** `== 1` — ermöglicht zukünftige Migration bei Struct-Erweiterungen
3. **CRC** (XOR über Payload-Bytes 6…53) — erkennt: Bitfehler, unvollständige Writes

Schlägt eine Prüfung fehl → Werks-Defaults werden geladen, `false` zurückgegeben.

---

## Wann wird gespeichert?

MIM verwendet **debounced saving**: Ein physischer EEPROM-Write findet
**frühestens 2 Sekunden** nach der letzten Parameteränderung statt.

### Save-Auslöser

| Aktion | Trigger |
|---|---|
| Encoder E2 drehen | `applyValueDelta()` → `profileMarkDirty()` |
| Encoder E2 SW drücken (Reset) | `resetCurrentParam()` → `profileMarkDirty()` |
| JSON `set_config` | `cmdSetConfig()` → `profileMarkDirty()` |

Der tatsächliche Write passiert in `loop()` via `profileSaveTick()`.

### TFT-Bestätigung

Nach jedem erfolgreichen Write erscheint **1,5 Sekunden lang „SAVED"**
(grüner Hintergrund) im TFT-Header. Bei hoher Schreibfrequenz erscheint
„WR WARN" (roter Hintergrund).

---

## Factory Reset

Der Factory Reset setzt alle Parameter auf Werks-Defaults zurück und
schreibt sie sofort ins EEPROM (ohne Debounce).

### Auslösung

Aktuell per Firmware-Code (z.B. in einem zukünftigen Menü-Eintrag):

```cpp
resetProfile();
// Danach globale Variablen neu laden:
ProfileData p;
loadProfile(p);
// p auf gVX, gVY, ... anwenden
```

> Factory Reset „löscht" nur den logischen Inhalt (schreibt neue gültige Defaults).
> Der physische Flash-Sektor wird **nicht** manuell gelöscht — das übernimmt
> die Wear-Leveling-Logik von Teensyduino automatisch. Kein manuelles Erase nötig.

---

## Flash-Lebensdauer und Wear Leveling

### Teensyduino EEPROM.h auf iMXRT1062

Die `EEPROM.h`-Implementierung von Teensyduino auf dem Teensy 4.1 emuliert
EEPROM im 2 MB NOR-Flash des iMXRT1062. Das Wear-Leveling erfolgt **automatisch**
in der Firmware: `EEPROM.update()` (genutzt von `EEPROM.put()`) schreibt nur
dann physisch, wenn sich der Wert geändert hat.

- **Effektive Schreibzyklen pro Speicherzelle:** ~100.000 (NOR-Flash-Spec)
- **Bytes pro ProfileData:** 54
- **Wear-Leveling-Faktor:** Teensyduino verteilt Writes intern über den
  Flash-Bereich → effektiv höhere Zyklenzahl als 100.000

### Worst-Case-Berechnung (mit Debounce)

| Szenario | Writes/Tag | Lebensdauer |
|---|---|---|
| Aktiver Nutzer, 5 Anpassungen/min, 8 h/Tag | ~240 | **>416 Jahre** |
| Sehr aktiver Nutzer, 1 Anpassung/10 s, 8 h/Tag | ~2.880 | **>34 Jahre** |
| Stress-Test ohne Debounce (1 Write/s) | 86.400 | ~3,2 Jahre |

> **Fazit:** Selbst bei intensivem Gebrauch ist die Flash-Lebensdauer
> kein praktisches Problem. Der Debounce (2 s) ist primär für Performance
> (5 ms Write-Latenz), nicht für Flash-Schonung.

### Write Counter

Der Session-Write-Counter (`profileSessionWrites()`) zählt nur im RAM und
wird bei jedem Neustart zurückgesetzt. Er verursacht **keinen eigenen Write-Zyklus**.

Ab **50 Writes pro Session** erscheint im Serial Monitor:
```
[MIM] WARN: High write frequency this session
```
und auf dem TFT kurz „WR WARN" — ein Hinweis dass möglicherweise der Debounce
nicht greift (z.B. wenn `saveProfile()` direkt aus Tests aufgerufen wird).

---

## API-Referenz

```cpp
// profile_storage.h

// Werks-Defaults in p eintragen (kein EEPROM-Zugriff)
void profileDefaults(ProfileData& p);

// Profil mit CRC+Magic speichern → true (immer auf Teensy 4.1)
bool saveProfile(ProfileData& p);

// Profil laden und validieren → true = gültig, false = Defaults geladen
bool loadProfile(ProfileData& p);

// Defaults sofort ins EEPROM schreiben (Factory Reset)
void resetProfile();

// Debounce-Timer starten/verlängern (nach jeder Parameteränderung)
void profileMarkDirty();

// In loop(): true wenn Debounce abgelaufen und Write fällig ist
bool profileSaveTick();

// Anzahl physischer Writes dieser Session (RAM only)
uint16_t profileSessionWrites();
```

---

## Test-Sketch

Der Sketch `test_profile_persistence.ino` testet das Modul isoliert
(kein TFT, kein USB-Handler). Er liegt in:

```
Arduino/test_profile_persistence/test_profile_persistence.ino
```

| Test | Was wird geprüft |
|---|---|
| TEST 1 | Cold Start → Defaults korrekt geladen bei leerem EEPROM |
| TEST 2 | Save & direkte EEPROM-Auswertung → Magic, Version, CRC, Werte |
| TEST 3 | Checksum-Fehler erkannt → Defaults geladen |
| TEST 4 | 10 verschiedene Parametersätze, float-Roundtrip mit ε=0.001 |
| TEST 5 | 100 dirty-Aufrufe → Debounce → genau 1 physischer Write |

Erwartete Ausgabe bei vollem Erfolg:
```
>> ALL TESTS PASSED <<
```

---

*Letzte Aktualisierung: 2026-05 · MIM Firmware v0.2.x*
