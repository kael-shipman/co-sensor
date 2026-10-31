# RESUME: handoff for the next session

Last updated 2026-10-31. Read this first, then `README.md`, `docs/plan.md` and
`enclosure/README.md`.

## Next task: design the enclosure (M4)

1. **Get Kael's answers** to the open questions in [`enclosure/README.md`](enclosure/README.md#still-needed-from-kael):
   - the architecture (sensor board on a cable vs harness + cradle);
   - mounting and orientation, battery bay, assembly style, printing method, and XIAO pin
     trimming;
   - measurements.
2. **Check the footprint test.** The ZE15 footprint check was printed on 2026-10-31
   (CUPS job 22). Ask whether the scale bar measured 50 mm, whether every ZE15 pin landed
   on a hole, and whether the square pads (pins 1 and 6) matched.
   - If not: the datasheet figure may be a bottom view, not the top view assumed in
     `hardware/carrier/geometry.py`. A mirror image calls for a re-route, not a tweak.
3. **Update `enclosure/assembly.py`** to the real arrangement, using
   [`hardware/measurements.md`](hardware/measurements.md):
   - the panel folded flat behind the driver board (1–4 mm gap, face out);
   - the XIAO stack (~22 mm, or ~18.5 mm with trimmed pins);
   - the sensor board on a cable.
   It still models the shelved carrier v0.2.
4. **If the sensor board is approved,** design it by adapting
   `hardware/carrier/generate.py`: the ZE15 2.0 mm sockets, a 3-pin connector (5V, GND,
   D7), and mounting holes. Keep the printable footprint check.
5. **Design the enclosure** in CadQuery (STEP/STL for print services). Follow the
   requirements in `enclosure/README.md`. Kael's emphasis: **compact but tidy,
   professional and practical to assemble by hand.**

## Also outstanding

- **M1 sensor bring-up.** The ZE15s have arrived but aren't connected yet. Follow
  `docs/bringup.md` and `docs/wiring.md#m1-wiring`: one 1×7 header soldered **pins up**
  on the driver board's 5V…D7 column, then two Adafruit 2.0↔2.54 mm jumper pairs. Record
  the 5 V rail under load.
- **Firmware built but not yet verified on hardware** (flash with `make run`, OTA):
  - the HA-editable *Update interval* (default 15 s; the display refreshes on each publish);
  - the timestamp line "Oct 26 at 21:30:15 CDT": check it fits the 200 px width;
  - the timezone from Home Assistant (units showed UTC before this change).
- **Home Assistant alerting isn't built.** Offered, not done:
  - one Threshold helper per unit (suggested 9 ppm elevated, 35 ppm high);
  - one alerting automation and one replacement-reminder automation, both driven by the
    `co_sensor` **label**, not per device.
  Load the `home-assistant-best-practices` skill first; the HA MCP server is available.
- **Battery backup is unverified.** The driver board's LiPo connector and charger/boost
  might keep the 5 V rail (and the ZE15) alive through power cuts. Test before claiming it.
- **Standalone timezone.** Units without HA show UTC; `web_server` could add a setting.
  Not requested.
- **When the repo goes public:** add `dashboard_import` (needs a git source for the
  external components), and consider ESP Web Tools for browser flashing.

## Current state (2026-10-31)

- **Hardware on hand:** 4 XIAO ESP32-C6 (pre-soldered), 3 Seeed ePaper Driver Boards V2,
  4 Seeed 1.54" panels, ZE15-COs (from AliExpress), and the Adafruit parts (1919 jumpers,
  366 2 mm sockets, 4151 red male headers, 598 female headers). Kael runs **at least 3
  units together**.
- **Proven on hardware (2026-10-17):** the XIAO in the driver board with the panel,
  flashed over USB with the **no-credentials** firmware. Onboarded through the unit's
  hotspot, then adopted in HA (2026.10.2), which provisioned the API key automatically.
  The display showed SENSOR FAULT, which is correct without a sensor. It worked first try.
- **Repo:** private, `github.com/kael-shipman/co-sensor`, branch `main`. Commit and push
  only when Kael asks. The first commit's message was `:sunrise:` (Kael's choice). End
  commit messages with the `Co-Authored-By` trailer from the session's attribution
  instructions.

## Kael's preferences (apply throughout)

- **Build as if distributing to the public:**
  - one firmware image for all units, with no personal values in the repo;
  - unique, collision-free identities. Kael's habit is an 8-hex random suffix; we chose
    ESPHome's 6-hex MAC suffix because it needs no per-unit builds and survives reflashing.
- **It's a realtime CO sensor that works standalone;** Home Assistant is an optional
  integration, never a defining feature. The repo was renamed from `ha-co-sensor` for this
  reason.
- **Home Assistant work** uses systems thinking: helpers, labels and reusable routines, not
  per-device point-to-point rules.
- **Shopping:** Seeed first; **only reputable shops**. Adafruit for the 2.0 mm parts. ZE15
  replacements from Winsen's official store.
- **Mechanical:** compact, but tidy and assemblable; no adhesives near the sensor.

## Hard-won technical facts (not obvious from the code)

- **Toolchain:** everything runs in Docker via `make`.
  - ESPHome is `ghcr.io/esphome/esphome:stable`, 2026.9.1 when built. Caches live in
    `~/.cache/co-sensor`.
  - KiCad 9 is `kicad/kicad:9.0`.
  - CadQuery 2.8.0 comes from a local image built from `tools/cad.Dockerfile`.
  - The Makefile adds the `dialout` group to the container, so Kael doesn't need to be in it.
- **ESPHome package merging:** two packages' `esphome: on_boot:` written as **dicts merge
  into one automation** (the board's priority-800 antenna setup got demoted). Always write
  `on_boot` as list items. Use `!extend <id>` to add to another package's entity (the
  display does this to refresh on `co_ppm`).
- **Timezones in ESPHome 2026.x:**
  - Without `timezone:`, the build machine's zone is baked in (Docker gave UTC), so
    `base.yaml` sets UTC explicitly.
  - The `homeassistant` time platform applies HA's timezone globally, but only if that
    platform has no `timezone:` of its own.
  - `strftime %Z` yields `-0500`, not `CST`; hence `firmware/include/tz_label.h`.
- **Provisioning (ESPHome `provisioning:`):**
  - The window is 15 minutes from each boot. A unit counts as provisioned once it has
    joined a network and received the API key from HA.
  - When the window expires, the hotspot closes and unprovisioned API connections are
    refused. A power cycle reopens it. Measurement continues regardless.
  - HA provisions the key by connecting with the all-zeros key.
  - OTA encryption can't be *required* with a runtime-provisioned key, so the shared image
    has open OTA on the LAN. Owners adopt via `firmware/local/` and `!extend ota_esphome`
    to add a password (`docs/onboarding.md`).
- **The XIAO ESP32-C6's RF switch:** GPIO3 low powers it, and GPIO14 low selects the
  ceramic antenna (in `boards/xiao-esp32c6.yaml`).
- **Display driver:** `epaper_spi` in 2026.9 stable lacks the 1.54" V2, so we use
  `waveshare_epaper` `1.54inv2`, which is confirmed working with Seeed's panel. Full
  refreshes (visible flashes) happen every 120 updates.
- **Seeed ePaper Driver Board V2:**
  - **Pins:** display RST D0, CS D1, BUSY D2, DC D3, SCK D8, MOSI D10; our pin map follows
    it.
  - **Breakout columns:** mirror the XIAO's pins (D0–D6, and 5V/GND/3V3/D10/D9/D8/D7).
  - **Battery:** an ETA9740 charger/boost, a LiPo JST 2.0 connector, and a battery-only
    slide switch.
  - **Schematic:** https://files.seeedstudio.com/wiki/xiao_075inch_epaper_panel/ePaper_Driver_Board.pdf
- **ZE15-CO (Winsen manual v1.2):**
  - 15 pins at 2.0 mm pitch; pins 1 and 6 have square pads. Vin 5–12 V.
  - The UART streams a 9-byte frame every second at 9600 baud.
  - Bit 7 of byte 4 is the fault flag.
  - The manual's Q&A-mode example checksum (0x7A) contradicts its own formula (0x70); the
    parser trusts the formula. Q&A mode is untested.
  - The ME2-CO cell **ages on the shelf**, so spares are for accidents, not end-of-life
    replacement (`docs/maintenance.md`).
  - Winsen says it is **not for life-safety use**; keep a certified CO alarm.
- **The KiCad generator** places items with random UUIDs and ordering. To check that a
  refactor didn't change the board, compare `.kicad_pcb` files order-insensitively with
  UUIDs stripped.
- **Printing the 1:1 footprint check:** CUPS default printer `HP-OfficeJet-Pro-8030-series`.
  Run `lp -d HP-OfficeJet-Pro-8030-series -o media=Letter -o print-scaling=none build/carrier-footprint-check.pdf`
  (the PDF is A4 landscape; unscaled, it fits Letter). Always check the 50 mm scale bar.

## Resume commands

```sh
cd ~/Repos/co-sensor
make test                 # host unit tests + esphome config on all firmware configs
make compile              # full firmware builds
make run                  # OTA-flash a unit (asks which, if several); PORT=/dev/ttyACM0 for USB
make carrier-check        # printable footprint check (ZE15 outline)
make assembly             # CadQuery model + renders (needs updating, see above)
```
