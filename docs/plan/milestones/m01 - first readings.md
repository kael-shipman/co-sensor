# M1: first readings end to end

**State: firmware done; units flashed, onboarded and in Home Assistant. Sensor not yet
connected.**

The ZE15 wired with jumpers to header pins on the driver board; ESPHome firmware; readings
verified on the display and in Home Assistant. Also measure the facts the hardware needs.
The step-by-step procedure is [bring-up](../../bringup.md); the wiring is
[wiring](../../wiring.md#m1-wiring).

## Tasks

- [x] Firmware: sensor, display, lifecycle and Home Assistant packages; host tests.
- [x] Flash with the no-credentials image, onboard through the hotspot, adopt in HA
      (2026-10-17).
- [ ] Solder one 1×7 header **pins up** on each driver board's 5V…D7 column; connect the
      ZE15 with two Adafruit 2.0↔2.54 mm jumper pairs.
- [ ] First readings on the display and in HA.
- [ ] Measure the 5 V rail under load (does it stay ≥ 5 V for the ZE15?).
- [ ] Verify on hardware (built, not yet flashed with `make run`):
  - the HA-editable *Update interval* (default 15 s; the display refreshes on each publish);
  - the timestamp line "Oct 26 at 21:30:15 CDT" fits the 200 px width;
  - the timezone from Home Assistant (units showed UTC before this change).

Done when: the checklist in [bring-up](../../bringup.md#done-when) passes.
