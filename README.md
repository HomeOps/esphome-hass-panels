# ESP32 Alarm Keypad & Thermostat Panel

ESPHome firmware for a wall-mounted touch-screen panel, wired to Home Assistant via the native API. Ships two swipe-navigable LVGL pages: an **alarm keypad** (`alarm_control_panel`) and a **thermostat** (`climate`).

## Hardware

**Guition ESP32-S3-4848S040** (also sold as "Sunton 4848S040")

| | |
|---|---|
| MCU | ESP32-S3-WROOM-1, 8 MB flash, 8 MB octal PSRAM |
| Display | 4.0" 480×480 IPS, ST7701S, 16-bit RGB parallel |
| Touch | GT911 capacitive (I2C) |
| Backlight | GPIO38, PWM via LEDC |

Available on AliExpress — search: *"ESP32-S3 Arduino LVGL Wifi 4.0 inch 480x480 capacitive touch"*

**References:**
- [ESPHome device page](https://devices.esphome.io/devices/guition-esp32-s3-4848s040/)
- [Community full config](https://github.com/esphome/esphome-devices/blob/main/src/docs/devices/Guition-ESP32-S3-4848S040/index.md)
- [Board overview & pin map](https://homeding.github.io/boards/esp32s3/panel-4848S040.htm)

## Features

### Alarm keypad page
- **PIN keypad** — 0–9, CLR, OK; entered digits shown as `*` in an overlay
- **Arm modes** — Away (🔒), Home (🏠), Night (🌙) — MDI icon glyphs, language-neutral
- **Dynamic disarm button** — full-width, shown only when the alarm is armed
- **State animations**
  - *Arming / Pending / Disarming* — slow orange pulse on the DISARM button
  - *Triggered* — fast red strobe on the DISARM button
  - *Armed* — static dark red
- **PIN gating** — code entry is only shown when the HA panel requires it (`code_arm_required` / `code_disarm_required` attributes read live from HA)

### Thermostat page
- **Current & target temperature** — large readout with ± step buttons
- **HVAC modes** — Off, Heat, Cool, Auto, Fan, Dry — 2×3 button grid, active mode highlighted
- **Presets** — Home, Away, Sleep, Eco, Boost, Comfort — 2×3 button grid
- **Live sync** — reads `current_temperature`, `temperature`, `hvac_action`, and `preset_mode` attributes from HA

### Navigation
- **Swipe gestures** — swipe left/right to cycle between registered pages
- **Connecting overlay** — full-screen "Connecting…" animation shown on boot and HA disconnect; panels are hidden until the API is up
- **Idle auto-return** — returns to the home page after a configurable timeout (default 30 s)
- **Extensible** — supports up to 4 pages via substitutions; unused slots safely no-op

### Sleep mode (for bedrooms)
- **Touch-to-wake** — when enabled, the backlight stays off and a black overlay blocks click-through. The first touch only wakes the screen; it does not activate the widget under the finger
- **Idle auto-off** — after a configurable period of inactivity, the panel sleeps itself again
- **HA-exposed controls** — `switch.<device>_sleep_mode` and `number.<device>_sleep_mode_timeout`, both persisted to flash and toggleable per device without re-flashing
- **Timeout values** — `-1` (default) never auto-sleeps after a wake; `0–5 s` are snapped to `-1` (too short to use); `≥6 s` re-sleeps after that many idle seconds
- **Programmatic bypass** — other packages (e.g. `energy-ui`'s low-power alert) can flip a `g_sleep_bypass` global via the `sleep_bypass_set` / `sleep_bypass_clear` scripts to forcibly keep the screen on during an alert condition

### Energy monitoring page
- **Battery state of charge** — color-coded percentage readout + LVGL bar from a HA numeric sensor (green ≥ 60, amber 30–59, red < 30)
- **Grid status** — `ON GRID` / `OFF GRID` driven by a HA binary sensor, color-coded
- **Low-power alert** — when a designated HA binary sensor goes on, the panel bypasses sleep mode, force-navigates to `energy_page` (if the page is in the swipe cycle), and flashes the page background red. All three reverse when the sensor clears
- **Opt-in via nav** — the page is always compiled; register it with `nav_page_N: energy_page` and bump `nav_page_count` to expose it. Sleep bypass + flash fire on alert even when the page isn't in the swipe cycle

### Area page
- **One control per kind** — a single page that controls a whole Home Assistant *area* by acting on one entity per device kind: lights, switches, covers, and locks. Toggling fans the command out to every member in HA; the entity's state drives each toggle
- **Group or single device** — each kind's entity can be a HA group (Settings → Devices & Services → Helpers → Group → Light/Switch/Cover/Lock) *or* a single device entity — both behave identically
- **Lights mandatory, the rest optional** — only the lights kind must be set. Any kind left at its `<domain>.none` sentinel default is hidden, and the remaining cards reflow up the column (FLEX layout — no gaps)
- **Light popup (dimming + colour)** — tapping the Lights card anywhere *except* the on/off button opens a popup with an on/off toggle, a brightness slider, and colour swatches. Controls are capability-gated from the group's `supported_color_modes`: a dimmable-but-not-colour group shows only the slider; an on/off-only light has no popup. Colour is sent as `rgb_color` via a `data_template` (HA can't take list values through plain `data:`)
- **Climate readout** — optional temperature + humidity shown at the top (bind a single sensor, or a `min_max`/`group` sensor that averages the area's sensors); each half hides independently when unset
- **Groups, not enumeration** — ESPHome binds entity IDs at compile time and can't enumerate an area, so each kind binds one entity. Every action can instead target an area directly by swapping `entity_id:` for `area_id:` in the package's `homeassistant.service` calls
- **Opt-in via nav** — always compiled; register it with `nav_page_N: area_page` and bump `nav_page_count` to expose it

### General
- **OTA updates** — backlight fades out during flash to avoid visual glitches
- **Fallback AP** — captive portal on first boot / wifi loss

## Files

| File | Description |
|---|---|
| `esp32-hass-panel.yaml` | Full-bundle entry point — `core` + every UI page wired into the swipe cycle |
| `packages/core.yaml` | Common scaffolding — board + nav + sleep + connectivity + framework/version; everything **except** the UI pages. Compose with selected UI packages for a slim build |
| `packages/board.yaml` | Board hardware — display, touchscreen, backlight, SPI, I2C, touch-state globals |
| `packages/alarm-keypad-ui.yaml` | Alarm keypad UI — globals, HA sensors, animations, fonts, LVGL page |
| `packages/thermostat-ui.yaml` | Thermostat UI — target/current temp, HVAC modes, presets, LVGL page |
| `packages/cover-ui.yaml` | Cover UI — any `cover.*` entity (garage door, blinds, gate), open/stop/close + state + progress, LVGL page |
| `packages/energy-ui.yaml` | Energy UI — battery state of charge + grid status + low-power alert (bypasses sleep, force-navigates, flashes page bg) |
| `packages/area-ui.yaml` | Area UI — whole-area control via one entity per kind (lights / switches / covers / locks) + temp/humidity readout; optional kinds hide when unset, LVGL page |
| `packages/nav.yaml` | Navigation orchestrator — swipe cycling, connecting overlay, idle auto-return |
| `packages/sleep-mode.yaml` | Bedroom sleep mode — touch-to-wake backlight + idle auto-off, exposed to HA as a switch + number |
| `tests/secrets.yaml` | Dummy secrets for CI config validation |
| `secrets.yaml` | *(not committed)* wifi, API key, OTA password, AP credentials |
| `3d/cradle.scad` | OpenSCAD source for the 3D-printable wall-mount cradle |
| `3d/cradle.stl` | Pre-rendered STL ready to slice |

### Architecture

The configuration is split into composable [ESPHome packages](https://esphome.io/components/packages). `packages/core.yaml` holds everything common (hardware, nav, sleep, connectivity, framework + firmware version); each UI page is a separate package. The full-bundle entry includes them all:

```
esp32-hass-panel.yaml                ← full bundle: nav wiring + all UI pages
  ├─ packages/core.yaml              ← board + nav + sleep + connectivity + version
  │    ├─ packages/board.yaml        ← hardware peripherals (swappable per board)
  │    ├─ packages/nav.yaml          ← swipe nav, connecting overlay, idle return
  │    └─ packages/sleep-mode.yaml   ← touch-to-wake backlight + idle auto-off
  ├─ packages/alarm-keypad-ui.yaml   ← alarm LVGL page (reusable UI component)
  ├─ packages/thermostat-ui.yaml     ← thermostat LVGL page (reusable UI component)
  ├─ packages/cover-ui.yaml          ← cover LVGL page (garage / blinds / gate)
  ├─ packages/energy-ui.yaml         ← energy LVGL page (battery / grid / low-power alert)
  └─ packages/area-ui.yaml           ← area LVGL page (lights / switches / covers / locks + climate)
```

**Slim builds — only compile the pages you use.** Every UI page you compile costs flash whether or not it's in the swipe cycle, so a device that needs just one page can compose `core` + that page instead of the full bundle:

A single git source with a `files:` list pulls the repo once — no repeated `url`/`ref`:

```yaml
substitutions:
  name: panel-den
  friendly_name: Den Panel
  nav_page_1: area_page
  nav_page_count: "1"
  area_lights_entity_id: light.den_panel_lights

packages:
  panel:
    url: https://github.com/HomeOps/esphome-hass-panels
    ref: v2.2.0            # or a later tag
    refresh: 0d
    files:
      - packages/core.yaml          # board + nav + sleep + connectivity
      - packages/area-ui.yaml       # the one page this device uses
      # other UI pages omitted -> not compiled
```

This drops the unused pages from flash (~140 KB measured for four). When composing slim, point every active `nav_page_N` at a page you actually included. You only need to set as many `nav_page_N` as you have active pages — unused slots fall back to `nav_page_1`, so they always resolve to a compiled page (the alarm UI need not be included).

#### When the image still doesn't fit — opt-in 16 MB flash

The default partition layout gives **~1.75 MB per OTA app slot** (a 4 MB layout, fully OTA-friendly). If a fully-loaded build overflows it, set the **`flash_size`** substitution to `16MB` — ESPHome auto-generates **~7.75 MB** app slots:

```yaml
substitutions:
  flash_size: "16MB"     # default is "4MB"
```

⚠️ **This is a partition-table change — adopt it with a one-time USB-serial flash, not OTA.** OTA never rewrites the partition table, so it can't move you onto the bigger layout (a too-big image just fails to fit the old slot). Run `esptool.py erase_flash`, then do the first install over serial; OTA works normally afterward. Requires a device with ≥ 16 MB flash (`esptool.py flash_id`). Prefer slimming first — if dropping unused pages keeps you under 1.75 MB, you never need this and stay fully OTA-updatable.

Each UI package contributes its own LVGL **page**. The navigation package wires
swipe gestures, a connecting overlay, and idle auto-return across all registered
pages. To add more panels, include additional UI packages and register them in
the `nav_page_*` substitutions.

## Substitutions

The YAML uses ESPHome [substitutions](https://esphome.io/components/substitutions) so a single config can be reused for multiple keypads:

| Variable | Default | Description |
|---|---|---|
| `name` | `esp32-hass-panel` | Device name (used for hostname, mDNS, etc.) |
| `friendly_name` | `ESP32 Home Panel` | Human-readable name shown in Home Assistant |
| `flash_size` | `4MB` | Flash/OTA partition layout. `4MB` = ~1.75 MB app slots (OTA-friendly). Set to `16MB` on a ≥16 MB device to get ~7.75 MB slots — **partition change, adopt via one-time USB-serial flash** |
| `display_platform` | `st7701s` | ESPHome display platform component |
| `display_width` | `480` | Display panel width in pixels |
| `display_height` | `480` | Display panel height in pixels |
| `display_rotation` | `270` | LVGL display rotation in degrees (0, 90, 180, 270) |
| `display_color_order` | `RGB` | Panel color byte order |
| `display_invert_colors` | `False` | Invert display colors |
| `display_spi_mode` | `MODE3` | SPI mode for display init |
| `display_data_rate` | `2MHz` | SPI data rate for display init |
| `display_pclk_frequency` | `12MHz` | Pixel clock frequency |
| `display_pclk_inverted` | `False` | Invert pixel clock |
| `display_hsync_pulse_width` | `8` | Horizontal sync pulse width |
| `display_hsync_front_porch` | `10` | Horizontal sync front porch |
| `display_hsync_back_porch` | `20` | Horizontal sync back porch |
| `display_vsync_pulse_width` | `8` | Vertical sync pulse width |
| `display_vsync_front_porch` | `10` | Vertical sync front porch |
| `display_vsync_back_porch` | `10` | Vertical sync back porch |
| `display_cs_pin` | `39` | Display chip-select GPIO |
| `display_de_pin` | `18` | Display data-enable GPIO |
| `display_hsync_pin` | `16` | Horizontal sync GPIO |
| `display_vsync_pin` | `17` | Vertical sync GPIO |
| `display_pclk_pin` | `21` | Pixel clock GPIO |
| `spi_clk_pin` | `GPIO48` | SPI clock GPIO (display init bus) |
| `spi_mosi_pin` | `GPIO47` | SPI MOSI GPIO (display init bus) |
| `i2c_sda_pin` | `GPIO19` | I2C SDA GPIO (touch controller) |
| `i2c_scl_pin` | `45` | I2C SCL GPIO (touch controller) |
| `touchscreen_platform` | `gt911` | ESPHome touchscreen platform component |
| `backlight_pin` | `GPIO38` | Backlight PWM GPIO |
| **Alarm** | | |
| `alarm_entity_id` | `alarm_control_panel.home_alarm` | HA alarm entity to control |
| **Thermostat** | | |
| `thermostat_entity_id` | `climate.thermostat` | HA climate entity to control |
| `thermostat_temp_min` | `16.0` | Minimum settable target temperature |
| `thermostat_temp_max` | `30.0` | Maximum settable target temperature |
| `thermostat_temp_step` | `0.5` | Temperature increment per button press |
| **Cover** | | |
| `cover_entity_id` | `cover.garage_door` | HA `cover.*` entity (garage door, blinds, gate, …) shown on the cover page |
| **Energy** | | |
| `energy_battery_entity_id` | `sensor.home_battery_charge` | HA numeric sensor (0-100) for whole-home battery state of charge |
| `energy_grid_status_entity_id` | `binary_sensor.grid_online` | HA binary sensor: on = on-grid, off = islanded / off-grid |
| `energy_low_power_entity_id` | `binary_sensor.home_low_power_alert` | HA binary sensor: when on, bypasses sleep mode, force-navigates to `energy_page` (if registered), and flashes the page background |
| **Area** | | |
| `area_name` | `Living Room` | Friendly label shown at the top of the area page and in the navbar |
| `area_lights_entity_id` | `light.living_room` | **Mandatory.** HA light group or single light entity — toggling it controls every member; its state drives the Lights toggle |
| `area_switches_entity_id` | `switch.none` | *Optional.* HA switch group or single switch. Left at `switch.none` → card hidden |
| `area_covers_entity_id` | `cover.none` | *Optional.* HA cover group or single cover (open/stop/close). Left at `cover.none` → card hidden |
| `area_locks_entity_id` | `lock.none` | *Optional.* HA lock group or single lock (lock/unlock). Left at `lock.none` → card hidden |
| `area_temp_entity_id` | `sensor.none` | *Optional.* HA temperature sensor (single, or an averaging `min_max`/`group` sensor). Left at `sensor.none` → hidden |
| `area_humidity_entity_id` | `sensor.none` | *Optional.* HA humidity sensor. Left at `sensor.none` → hidden |
| **Navigation** | | |
| `nav_page_1` | `alarm_page` | LVGL page ID at swipe slot 1 (leftmost) |
| `nav_page_2` | `${nav_page_1}` | Page at slot 2 (unused slots fall back to `nav_page_1`) |
| `nav_page_3` | `${nav_page_1}` | Page at slot 3 |
| `nav_page_4` | `${nav_page_1}` | Page at slot 4 |
| `nav_page_count` | `1` | Number of active pages in the swipe cycle (1–4) |
| `nav_home_page` | `"1"` | 1-based index (1…`nav_page_count`) of the landing page. The home page is shown on connect, when sleep mode wakes, and as the idle auto-return target. Must be ≤ `nav_page_count`. |
| `nav_auto_return_delay` | `30s` | Idle time before auto-returning to home page |
| **Sleep mode** | | |
| `sleep_mode_default_state` | `OFF` | Factory-default state of the sleep-mode switch (`OFF` / `ON`). Set to `ON` for bedroom panels so they boot dark. HA-stored state wins on subsequent boots. |
| `sleep_mode_default_timeout` | `-1` | Factory-default value of the auto-off timeout, in seconds. `-1` = never; values `0–5` snap to `-1`; `>=6` re-sleeps after that many idle seconds. |

Per-device YAML pulls in `esp32-hass-panel.yaml` as a single [ESPHome git
package](https://esphome.io/components/packages#git-source) and overrides
only what's specific to that device.

### 1-page panel (bedroom — alarm only, sleep mode on)

`panel-bedroom.yaml`:

```yaml
substitutions:
  name: panel-bedroom
  friendly_name: Bedroom Panel
  alarm_entity_id: alarm_control_panel.home_alarm
  nav_page_count: "1"
  sleep_mode_default_state: "ON"
  sleep_mode_default_timeout: "60"

packages:
  keypad:
    url: https://github.com/HomeOps/esphome-hass-panels
    ref: main          # or a tag like `v1.9.1` to pin
    file: esp32-hass-panel.yaml
    refresh: 0d        # always re-pull on compile
```

### 2-page panel (alarm + thermostat)

`panel-hallway.yaml`:

```yaml
substitutions:
  name: panel-hallway
  friendly_name: Hallway Panel
  alarm_entity_id: alarm_control_panel.home_alarm
  thermostat_entity_id: climate.hallway_thermostat
  nav_page_1: alarm_page
  nav_page_2: thermostat_page
  nav_page_count: "2"

packages:
  keypad:
    url: https://github.com/HomeOps/esphome-hass-panels
    ref: main
    file: esp32-hass-panel.yaml
    refresh: 0d
```

### 2-page panel with cover first, alarm second

Reorder the swipe slots. The landing page is whichever `nav_page_N`
slot `nav_home_page` points at (default `"1"`, the leftmost).

`panel-garage.yaml`:

```yaml
substitutions:
  name: panel-garage
  friendly_name: Garage Panel
  alarm_entity_id: alarm_control_panel.home_alarm
  cover_entity_id: cover.garage_door
  nav_page_1: cover_page       # landing page (nav_home_page defaults to "1")
  nav_page_2: alarm_page
  nav_page_count: "2"

packages:
  keypad:
    url: https://github.com/HomeOps/esphome-hass-panels
    ref: main
    file: esp32-hass-panel.yaml
    refresh: 0d
```

### Substitution cheat sheet

| Want… | Set… |
|---|---|
| 1 page — alarm only | `nav_page_count: "1"` |
| 2 pages — alarm + thermostat | `nav_page_1: alarm_page`, `nav_page_2: thermostat_page`, `nav_page_count: "2"`, `thermostat_entity_id: …` |
| 3 pages — alarm + thermostat + cover (default) | `nav_page_count: "3"` (other defaults already match) |
| 4 pages — add energy monitoring | `nav_page_4: energy_page`, `nav_page_count: "4"`, `energy_battery_entity_id: …`, `energy_grid_status_entity_id: …`, `energy_low_power_entity_id: …` |
| Add an area page (lights only — the rest hide) | `nav_page_N: area_page`, bump `nav_page_count`, `area_name: …`, `area_lights_entity_id: …` |
| Area page with more kinds | also set any of `area_switches_entity_id`, `area_covers_entity_id`, `area_locks_entity_id`, `area_temp_entity_id`, `area_humidity_entity_id` (group or single device); unset ones stay hidden |
| Reorder, e.g. cover-first / alarm-second | `nav_page_1: cover_page`, `nav_page_2: alarm_page`, `nav_page_count: "2"`, `cover_entity_id: …` |
| Keep swipe order but pin home to a different slot | `nav_home_page: "2"` (must be ≤ `nav_page_count`) |
| Bedroom sleep behaviour | `sleep_mode_default_state: "ON"` and optionally `sleep_mode_default_timeout: "<seconds>"` |
| Pin to a release | `ref: v2.0.0` instead of `ref: main` |

### secrets.yaml requirements

The per-device YAML's directory must contain a `secrets.yaml`. ESPHome
resolves every `!secret` reference (including ones inside the
git-fetched panel YAML) against the *entry-point* config's directory,
so all of the following keys must be present even though the references
live in the fetched file:

```yaml
wifi_ssid: "..."
wifi_password: "..."
api_encryption_key: "..."   # generate: esphome generate-api-key
ota_password: "..."
ap_ssid: "..."
ap_password: "..."
```

## secrets.yaml format

```yaml
wifi_ssid: "your-ssid"
wifi_password: "your-password"
api_encryption_key: "base64-key"   # generate: esphome generate-api-key
ota_password: "random-string"
ap_ssid: "Keypad Fallback"
ap_password: "random-string"
```

## Home Assistant setup

### Allow the device to perform actions (required)

Every control on the panel — arm/disarm, cover open/close, lock/unlock, and
the area page's light/switch toggles — issues a Home Assistant **service
call**. ESPHome devices are **not** permitted to do this by default: HA
accepts the connection and the panel reads entity state fine, but every
command is silently dropped until you authorise the device.

After adopting each panel in **Settings → Devices & Services → ESPHome**,
open its device entry and enable **“Allow the device to perform Home
Assistant actions”**, then submit (the integration reloads). This is
per‑device, so every physical panel needs it.

Symptom when it's missing: state displays update correctly, but buttons do
nothing. The device log shows the command being sent (e.g. `Area lights:
sending light.turn_off`) while HA's own log records the refusal.

### Alarm panel

Add a manual alarm panel to your HA `configuration.yaml`:

```yaml
alarm_control_panel:
  - platform: manual
    name: Home Alarm
    code: YOUR_CODE
    code_arm_required: false
```

The keypad subscribes to `alarm_control_panel.home_alarm` — change the `alarm_entity_id` substitution if yours differs.

### Thermostat

The thermostat page subscribes to a `climate` entity. Point the `thermostat_entity_id` substitution at your climate entity (default: `climate.thermostat`). No extra HA configuration is needed beyond having the climate integration set up.

### General

Enable **"Allow Home Assistant actions"** on the ESPHome device page in HA after first adoption.

## 3D-printed wall mount

A single-part wall-mount cradle is included under `3d/` — plate bolts to a US single-gang old-work box, cradle holds the device via a front retention lip that drops into the 5 mm notch around the device's bezel.

| | |
|---|---|
| Plate | 100 × 110 × 5 mm, mounts to US single-gang box (83.3 mm screw spacing) |
| Cradle | 93 × 93 × 13 mm, 88.4 × 88.4 mm cavity with 5 mm front retention frame |
| Wire passthrough | 80 × 70 mm, split into 4 quadrants by a 15 mm cross of plate material |
| Bottom slot | 60 mm-wide opening for USB-C / microSD access |
| Material | PETG (survives 40 °C ambient — do not use PLA) |
| Print | 0.2 mm layer, 30 % infill, 4 perimeters, no supports |
| Orientation | Wall plate flat on the bed, cradle rising up |

Device installs by tilting it in from the front — the top retention bar is closed, so it can't be slid in from the top. Edit parameters at the top of `cradle.scad` and re-render with OpenSCAD (`openscad -o cradle.stl cradle.scad`) if you need to tweak.

## Toolchain note

The ESPHome add-on (`addon_5c53de3b_esphome`) ships a broken xtensa toolchain for ESP32-S3 builds — the `lib/` dynconfig directory is missing. Run `patch-esphome-toolchain.sh` (in the parent HA config) after any add-on reinstall. Tracked upstream: [esphome/esphome#8942](https://github.com/esphome/esphome/issues/8942).

## Framework

Requires `esp-idf` (not Arduino) — mandatory for the RGB parallel display + LVGL framebuffer.
