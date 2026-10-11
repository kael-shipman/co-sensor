# M1 bring-up

Goal: CO readings from the ZE15 are verified end to end, and everything M2 depends on
has been measured. The display doesn't exist yet in M1, so readings are checked in the logs
and in Home Assistant.

## 1. Flash the bare XIAO (before wiring anything)

1. `cp firmware/secrets.example.yaml firmware/secrets.yaml` and fill it in. Generate the
   API key with `openssl rand -base64 32`.
2. Plug the XIAO in over USB-C, then run `make run PORT=/dev/ttyACM0`.
   - If the port doesn't appear or flashing fails, hold **BOOT** while plugging in.
3. With no sensor attached, expect the logs to show, after 10 s:
   `No valid frame for 10000 ms; check wiring and power`. This shows the timeout path
   works; the fault entity should be on.

## 2. Wire the sensor

Follow [wiring → M1](wiring.md#m1-wiring-no-soldering). Unplug USB first, and check that
Vin and GND aren't swapped.

## 3. First readings

Run `make logs`. The `No valid frame` warning from step 1 should no longer appear. The CO
value stays unknown until the 60 s warm-up ends, then updates every 5 s.

| Check | Expected |
|---|---|
| Checksum warnings | none (a few right at power-up are fine) |
| Clean-air reading | 0–2 ppm. Give a brand-new cell at least 5 minutes, ideally a day, to settle. |
| Response | Hold an open bottle of hand sanitizer near the sensor: alcohol is a known cross-sensitivity and the reading should spike, then recover within about 30 s. |
| Fault entity | off |
| Unplug the TX jumper | the fault entity turns on after 10 s and CO goes unknown; both recover when it's reconnected |

For per-frame detail, temporarily set `logger: level: VERBOSE` in `common/base.yaml`.

## 4. Home Assistant

1. Follow [integrations/home-assistant.md](integrations/home-assistant.md) to adopt the
   device. Assign an area and add the `co_sensor` label.
2. Confirm that a reboot (the Restart button) and an OTA update (`make run` without
   `PORT`) both work.
3. Optional: unplug the router (or block the device) for 20+ minutes. Uptime should keep
   counting when it comes back, which shows it didn't reboot while offline.

## 5. Record for M2

Fill these in; the PCB design depends on them.

| Measurement | Value |
|---|---|
| XIAO 5V pin voltage, sensor running (ZE15 spec: ≥ 5.0 V) | |
| ZE15 current draw | |
| ZE15 row-to-row pin spacing, centre to centre (drawing: ~22.8 mm) | |
| ZE15 outline and can height (drawing: 25.4 × 22.3 mm, 24.5 mm tall) | |
| ZE15 pin length below its board | |
| Fit in Adafruit 2 mm sockets: seats firmly? removable without stress? | |
| Frame interval observed | |

If the 5 V rail measures under 5 V and readings misbehave, the PCB should take USB power
directly instead of through the XIAO's 5V pin.

## Done when

- Realistic readings in the logs and in Home Assistant, with the fault path verified.
- The device survives a reboot and an OTA update.
- The table above is filled in.
