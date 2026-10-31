# M1 bring-up

Goal: CO readings from the ZE15 verified end to end, and everything the sensor board and
enclosure depend on measured.

## 1. Flash and onboard (before the sensor is connected)

1. Assemble: XIAO into the ePaper Driver Board's socket (USB-C at the board edge), and
   the panel's ribbon into the driver board's FPC connector.
2. Plug the XIAO in over USB-C (a data cable), then run `make run PORT=/dev/ttyACM0`.
   - If the port doesn't appear or flashing fails, hold the XIAO's **B** button while
     plugging in.
   - No secrets file is needed: the firmware contains no credentials.
3. Onboard it: join its `co-sensor-xxxxxx` hotspot, pick your Wi-Fi network, and adopt
   it in Home Assistant within 15 minutes of boot. See [onboarding](onboarding.md).
4. With no sensor attached, expect:
   - the screen shows **WARMING UP**, then **SENSOR FAULT**;
   - after 10 s the log shows `No valid frame for 10000 ms; check wiring and power`;
   - the fault entity is on.

   That proves the timeout path.

## 2. Wire the sensor

Follow [wiring → M1](wiring.md#m1-wiring): one header soldered onto the driver board, then
two jumper pairs to the ZE15. Unplug USB first, and check that Vin and GND aren't
swapped. Stand the ZE15 can up, away from drafts and the XIAO's warmth.

## 3. First readings

Run `make logs`. The `No valid frame` warning from step 1 should no longer appear. The CO
value stays unknown until the 60 s warm-up ends, then updates once per Update interval (15 s by default).

| Check | Expected |
|---|---|
| Checksum warnings | none (a few right at power-up are fine) |
| Clean-air reading | 0–2 ppm. Give a brand-new cell at least 5 minutes, ideally a day, to settle. |
| Response | Hold an open bottle of hand sanitizer near the sensor: alcohol is a known cross-sensitivity and the reading should spike, then recover within about 30 s. |
| Fault entity | off |
| Unplug the TX jumper | the fault entity turns on after 10 s and CO goes unknown; both recover when it's reconnected |

For per-frame detail, temporarily set `logger: level: VERBOSE` in `common/base.yaml`.

## 4. Home Assistant

1. If you haven't already, adopt the device (see [onboarding](onboarding.md)). Assign an
   area and add the `co_sensor` label.
2. Confirm that a reboot (the Restart button) and an OTA update (`make run` without
   `PORT`) both work.
3. Check that **CO sensor installed** shows today's date (recorded once the sensor
   reports and the clock has synced) and **CO sensor age** shows 0 d.
4. Optional: unplug the router (or block the device) for 20+ minutes. Uptime should keep
   counting when it comes back, which shows it didn't reboot while offline.

## 5. Record for the sensor board and enclosure

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
