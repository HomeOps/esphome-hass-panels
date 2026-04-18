# ESP32 Alarm Keypad

ESPHome firmware for a wall-mounted touch-screen alarm keypad, wired to a Home Assistant `alarm_control_panel` via the native API.

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

- **PIN keypad** — 0–9, CLR, OK; entered digits shown as `*` in an overlay
- **Arm modes** — Away (🔒), Home (🏠), Night (🌙) — MDI icon glyphs, language-neutral
- **Dynamic disarm button** — full-width, shown only when the alarm is armed
- **State animations**
  - *Arming / Pending / Disarming* — slow orange pulse on the DISARM button
  - *Triggered* — fast red strobe on the DISARM button
  - *Armed* — static dark red
- **PIN gating** — code entry is only shown when the HA panel requires it (`code_arm_required` / `code_disarm_required` attributes read live from HA)
- **OTA updates** — backlight fades out during flash to avoid visual glitches
- **Fallback AP** — captive portal on first boot / wifi loss

## File

| File | Description |
|---|---|
| `esp32-alarm-keypad.yaml` | ESPHome configuration (reusable component) |
| `secrets.yaml` | *(not committed)* wifi, API key, OTA password, AP credentials |

## Substitutions

The YAML uses ESPHome [substitutions](https://esphome.io/components/substitutions) so a single config can be reused for multiple keypads:

| Variable | Default | Description |
|---|---|---|
| `name` | `esp32-alarm-keypad` | Device name (used for hostname, mDNS, etc.) |
| `friendly_name` | `ESP32 Alarm Keypad` | Human-readable name shown in Home Assistant |
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

Override them on the command line or in a per-device YAML:

```yaml
# home-alarm-keypad-downstairs.yaml
substitutions:
  name: home-alarm-keypad-downstairs
  friendly_name: Home Alarm Keypad Downstairs

<<: !include esp32-alarm-keypad.yaml
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

Add a manual alarm panel to your HA `configuration.yaml`:

```yaml
alarm_control_panel:
  - platform: manual
    name: Home Alarm
    code: YOUR_CODE
    code_arm_required: false
```

The keypad subscribes to `alarm_control_panel.home_alarm` — change the entity ID in the YAML if yours differs.

Enable **"Allow Home Assistant actions"** on the ESPHome device page in HA after first adoption.

## Toolchain note

The ESPHome add-on (`addon_5c53de3b_esphome`) ships a broken xtensa toolchain for ESP32-S3 builds — the `lib/` dynconfig directory is missing. Run `patch-esphome-toolchain.sh` (in the parent HA config) after any add-on reinstall. Tracked upstream: [esphome/esphome#8942](https://github.com/esphome/esphome/issues/8942).

## Framework

Requires `esp-idf` (not Arduino) — mandatory for the RGB parallel display + LVGL framebuffer.
