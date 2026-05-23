#!/usr/bin/env python3
"""CI wrapper around `esphome` that mutes board-inherent GPIO warnings.

ESPHome's ESP32-S3 pin validator
(`esphome/components/esp32/gpio_esp32_s3.py:51-56`) emits a USB-Serial-JTAG
conflict warning *unconditionally* whenever GPIO19 or GPIO20 are used as
GPIO. There is no per-pin opt-out flag in the schema and the warning fires
regardless of whether USB-Serial-JTAG is actually enabled in sdkconfig.

The Guition ESP32-S3-4848S040 board these panels target hard-wires GPIO19
to the touchscreen I2C SDA line and GPIO20 to the display's green data
line. Both are board-fixed and unavoidable, so the warnings are pure
noise on every compile.

Raising that one module's logger level to ERROR suppresses just those
warnings. Every other ESPHome warning still surfaces, so the CI guard
step that fails on `^WARNING ` lines still catches real issues.

Usage: `python tests/compile.py compile <config.yaml>` — same arguments
as `esphome` itself.
"""
import logging
import sys

logging.getLogger("esphome.components.esp32.gpio_esp32_s3").setLevel(
    logging.ERROR
)

from esphome.__main__ import main  # noqa: E402  (logger setup must precede import)

sys.exit(main() or 0)
