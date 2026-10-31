# Plan

The approach: each milestone proves every interface the next one depends on, so the PCB
mostly copies a design that already works instead of introducing new decisions.

## Milestones

1. **M1: first readings end to end.** The ZE15 wired with jumpers to header pins on the
   driver board; ESPHome firmware; readings verified on the display and in Home Assistant.
   Also measure the facts the hardware needs. See [bring-up](bringup.md).
2. **M2: custom PCB foundation.** Proposed: a small **sensor board** holding the ZE15 in
   2.0 mm sockets, plus a 3-pin connector (5V, GND, D7), on a short cable to the driver
   board. The first design, [carrier v0.2](../hardware/carrier/README.md), plugged into the
   driver board from below and is shelved: real hardware showed the panel has to fold
   flat against the driver board's underside (see [measurements](../hardware/measurements.md)).
3. **M3: e-ink display.** Done: the panel plugs into Seeed's driver board, and the display
   package is enabled. No new board needed.
4. **M4: enclosure.** **Next.** See [enclosure](../enclosure/README.md) for the
   constraints and the open questions.

## Decisions

| Decision | Choice | Why |
|---|---|---|
| MCU | Seeed XIAO ESP32-C6 | Tiny, socketable on two 1×7 headers, native USB logging. XIAO C3 and S3 share the footprint, so changing MCU later means one new board file. |
| Firmware | ESPHome with packages and an external component | Board, modules and device composition are separate. Modules talk through entity ids (`co_ppm`, `co_fault`), never hardware. |
| Sensor link | Initiative-upload UART, RX only | The module streams every second unprompted. TX is routed on the PCB through 1 kΩ but stays unused. |
| Fault semantics | NaN + `problem` binary sensor on module fault **or** 10 s of silence | A dead or disconnected sensor must never look like "0 ppm". |
| Display | Seeed 1.54" 200×200 B/W panel on Seeed's ePaper Driver Board | The panel's FPC latch is its releasable "clamp". |
| Board architecture | Seeed's driver board (with XIAO and folded panel) as the "display module"; **proposed:** a separate sensor board on a cable | The driver board already has the fine-pitch FPC connector and the panel's boost circuit, the hardest parts to put on our own board. The panel's very short ribbon forces it flat behind the driver board, so nothing can mount underneath; a cable to a separate sensor board leaves the sensor's placement to the enclosure. The sensor-board half is not yet approved. |
| Display content | Integer ppm, plus the time of the last refresh ("Oct 26 at 21:30:15 CDT") | E-ink keeps its image when the device dies; the timestamp exposes staleness. |
| Reporting rate | 1 Hz readings averaged; `co_ppm` published once per **Update interval** (HA-editable, default 15 s); the display refreshes on each publish | One tick drives every consumer, so HA and the screen always agree; faults are still published immediately. |
| Power | USB-C on the XIAO feeds the ZE15 from the 5V pin | Simplest. **To verify in M1:** the ZE15 is specced for ≥ 5 V. |
| Autonomy | Self-contained device; integrations are optional packages | It measures and displays with no network. Wi-Fi and API reboot timeouts are disabled so being offline never interrupts measurement. |
| Integrations | Home Assistant via the ESPHome API, in `firmware/integrations/` | One consumer of `co_ppm`/`co_fault` among possible others (MQTT, web server). Alerting logic lives in the consumer; see [Home Assistant](integrations/home-assistant.md). |
| Cell lifecycle | Install date, service life and age kept in device flash; HA can edit them | The cell ages even unpowered and can't be recalibrated without test gas, so it's replaced on a schedule. Keeping the state on the device keeps it standalone. See [maintenance](maintenance.md). |
| Credentials | None in the image; per-unit provisioning ([onboarding](onboarding.md)) | One binary for everyone. Wi-Fi comes from the unit's hotspot/setup page (or Improv over USB), and the API key from Home Assistant at adoption. A 15-minute provisioning window keeps unconfigured units from staying open. |
| Update security | Shared image: open updates on the LAN; owners can adopt + add a password | A shared image can't hold a secret. ESPHome can't require API-key-encrypted updates with a runtime-provisioned key. |
| Clock | SNTP over Wi-Fi, plus time from Home Assistant when integrated | For the display's timestamp and cell-age tracking; shows "no clock" when offline. |
| Timezone | Built as UTC; Home Assistant's timezone applied at runtime | ESPHome would otherwise bake in the build machine's timezone. HA 2026.3+ sends its timezone with the time. Units without HA stay on UTC. |

## Open questions

- **Offline liveness on the display.** Without Wi-Fi there's no clock, so a frozen screen
  (dead device) looks the same as a live one. Options for M3: a heartbeat mark that flips
  on every refresh, or an RTC on the PCB. An RTC would also let cell-age tracking work
  on a device that never sees a network.
- **5 V margin.** Does the XIAO's 5V pin stay at or above 5 V under load, and does the
  ZE15 care if it doesn't? (M1 measurement.)
- **ZE15 footprint and socket fit.** The datasheet drawing doesn't say whether it's a top
  or bottom view, and its row spacing is ±0.5 mm. The printed footprint check
  (`make carrier-check`, ZE15 outline) settles the first; a test-fit in Adafruit's 2 mm
  sockets settles the second. Both feed the sensor board.
- **Sensor-board architecture.** Proposed, awaiting Kael's go-ahead. The alternative is no
  custom PCB: the jumper harness plus a cradle in the enclosure.
- **XIAO pin length.** The pre-soldered XIAO's pins bottom out ~3.5 mm proud of the driver
  board's ~4.7 mm socket. Trimming them would save ~3.5 mm of depth; not decided.
- **Timezone without Home Assistant.** Standalone units show UTC. ESPHome's `web_server`
  could expose a timezone setting, at some flash cost and with an open settings page.
- **Battery backup (worth investigating).** The driver board has a battery connector and
  a charger/boost chip on the same 5 V rail that feeds the ZE15, so a LiPo might keep a
  unit measuring through power cuts. Unverified.
- **ESPHome display driver.** The display module uses `waveshare_epaper` (`1.54inv2`).
  ESPHome's newer `epaper_spi` driver supports this panel on its dev branch but not yet in
  2026.9; migrate once it ships in stable.
- **Q&A mode.** Untested on hardware. The manual's Q&A example checksum (0x7A)
  contradicts its own formula (0x70); the parser trusts the formula.
