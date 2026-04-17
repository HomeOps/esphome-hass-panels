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
| `home-alarm-keypad-downstairs.yaml` | ESPHome configuration |
| `secrets.yaml` | *(not committed)* wifi, API key, OTA password, AP credentials |

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
