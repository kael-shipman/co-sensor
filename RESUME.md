RESUME
============================================================================

**Current Milestone: [M4](<./docs/plan/milestones/m04 - enclosure.md>)** (M1's sensor
bring-up can run in parallel: [M1](<./docs/plan/milestones/m01 - first readings.md>))

Last updated 2026-11-12. Read this first, then [README.md](README.md),
[VISION.md](VISION.md), [docs/plan/](docs/plan/README.md) and
[enclosure/README.md](enclosure/README.md). Each milestone file has its own task list.

Notes:

- The first enclosure design is done in OpenSCAD (`enclosure/`) and fit-checked
  (`make enclosure-check`), with STLs and renders committed (2026-11-12, branch
  `sensor-enclosure-plan`). Nothing printed yet. Next: Kael reviews the renders (M4 task 1).
- Changed direction on M2: no custom PCB. A Sullins NPPN101FGGN-RC right-angle socket on
  the ZE15's 10-pin row, three wires to the driver board's 5V, GND and D7 (ZE15 pins 15,
  14 and 8). The carrier PCB and its CadQuery tooling were removed.
- Shopping for the plug and enclosure hardware is in [docs/bom.md](docs/bom.md#order-3-the-sensor-plug-and-the-enclosures-hardware);
  not ordered yet. Wire colours (2026-11-05): red 5V, black GND, yellow TXD; 26 AWG PVC
  from Remington, 1/16" non-adhesive heat-shrink from DigiKey. Confirm Remington part numbers
  and the heat-shrink price at checkout (not verified online).
- Repo restructured to the execute-project layout on 2026-11-05: `docs/plan.md` split into
  `VISION.md` (architecture, decisions) and `docs/plan/` (milestones); open questions
  moved here.
- **Home Assistant alerting isn't built.** Offered, not done: one Threshold helper per
  unit (suggested 9 ppm elevated, 35 ppm high); one alerting automation and one
  replacement-reminder automation, both driven by the `co_sensor` **label**, not per
  device. Load the `home-assistant-best-practices` skill first; the HA MCP server is
  available.
- **When the repo goes public:** add `dashboard_import` (needs a git source for the
  external components), and consider ESP Web Tools for browser flashing.

Outstanding Questions:

1. **5 V margin.** Does the XIAO's 5V pin stay at or above 5 V under load, and does the
   ZE15 care if it doesn't? (M1 measurement.)
2. **Enclosure estimates.** A few dimensions in `enclosure/config.scad` are still from
   photos rather than calipers; see [enclosure](enclosure/README.md#still-estimated).
   (Settled: the ZE15 drawing is a top view and its pins are standard 2.0 mm; the XIAO's
   pins stay untrimmed, since the sensor, not the display, sets the depth.)
3. **Offline liveness on the display.** Without Wi-Fi there's no clock, so a frozen screen
   (dead device) looks the same as a live one. Options: a heartbeat mark that flips on
   every refresh, or an RTC. An RTC would also let cell-age tracking work on a device that
   never sees a network.
4. **Battery backup (worth investigating).** The driver board has a battery connector and
   a charger/boost chip on the same 5 V rail that feeds the ZE15, so a LiPo might keep a
   unit measuring through power cuts. Unverified; test before claiming it.
5. **Timezone without Home Assistant.** Standalone units show UTC. ESPHome's `web_server`
   could expose a timezone setting, at some flash cost and with an open settings page.
   Not requested.
6. **ESPHome display driver.** The display module uses `waveshare_epaper` (`1.54inv2`).
   ESPHome's newer `epaper_spi` driver supports this panel on its dev branch but not yet
   in 2026.9; migrate once it ships in stable.
7. **Q&A mode.** Untested on hardware. The manual's Q&A example checksum (0x7A)
   contradicts its own formula (0x70); the parser trusts the formula.

## Current state (2026-11-12)

- **Hardware on hand:** 4 XIAO ESP32-C6 (pre-soldered), 3 Seeed ePaper Driver Boards V2,
  4 Seeed 1.54" panels, ZE15-COs (from AliExpress), and the Adafruit parts (1919 jumpers,
  366 2 mm sockets, 4151 red male headers, 598 female headers). Kael runs **at least 3
  units together**.
- **Proven on hardware (2026-10-17):** the XIAO in the driver board with the panel,
  flashed over USB with the **no-credentials** firmware. Onboarded through the unit's
  hotspot, then adopted in HA (2026.10.2), which provisioned the API key automatically.
  The display showed SENSOR FAULT, which is correct without a sensor. It worked first try.
- **Repo:** private, `github.com/kael-shipman/co-sensor`. `main` has the firmware; the
  enclosure, licensing and plan restructure are on `sensor-enclosure-plan` (pushed
  2026-11-12, not merged). Commit and push
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

- **Toolchain:** the firmware runs in Docker via `make`.
  - ESPHome is `ghcr.io/esphome/esphome:stable`, 2026.9.1 when built. Caches live in
    `~/.cache/co-sensor`.
  - The enclosure uses a locally installed OpenSCAD (2021.01 on Kael's machine) plus
    `xvfb-run` for headless renders. `make enclosure-check` takes ~4 minutes on 20 cores.
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
- **ZE15 orientation:** Winsen's drawing is a **top view** (confirmed by a printed 1:1
  footprint check, 2026-10-31), and its pins fit standard 2.0 mm sockets. With the 10-pin
  row along the bottom and the can facing front, pin 15 is at the right-hand end.
- **Printing 1:1 on paper:** CUPS default printer `HP-OfficeJet-Pro-8030-series`; use
  `-o print-scaling=none` and always include a 50 mm scale bar. Its scanner works for
  measuring boards: 300 dpi, deskew, and calibrate against the 2.54 mm header pitch.
- **Enclosure fit checks** (`enclosure/check.py`) intersect each part with the others and
  with models of the hardware; touching faces give zero-thickness results, which it
  ignores. The spring fingers squeeze the can on purpose, so that check uses a slightly
  smaller can.

## Resume commands

```sh
cd ~/Repos/co-sensor
make test                 # host unit tests + esphome config on all firmware configs
make compile              # full firmware builds
make run                  # OTA-flash a unit (asks which, if several); PORT=/dev/ttyACM0 for USB
make enclosure            # STLs, fit checks and renders (needs OpenSCAD + xvfb-run)
```
