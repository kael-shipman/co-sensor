# Plan

The approach: each milestone proves every interface the next one depends on, so the PCB
mostly copies a design that already works instead of introducing new decisions.

## Milestones

1. **M1: first readings end to end.** ZE15 wired to a XIAO with jumpers; ESPHome firmware;
   readings verified in Home Assistant (the display doesn't exist yet). Also measure the
   facts the PCB needs. See [bring-up](bringup.md).
2. **M2: custom PCB.** Releasable sockets: 1×7 2.54 mm female headers for the XIAO,
   1×10 and 1×5 2.0 mm sockets for the ZE15, the 24-pin FPC latch for the display.
   Brings out the reserved I2C (Qwiic) and spare pins. The firmware doesn't change because
   the pin map doesn't.
3. **M3: e-ink display.** Can start before M2 on Seeed's driver board, with identical pins
   and firmware. Enable `modules/epd-1in54.yaml`.
4. **M4: enclosure.** See [enclosure constraints](../enclosure/README.md).

## Decisions

| Decision | Choice | Why |
|---|---|---|
| MCU | Seeed XIAO ESP32-C6 | Tiny, socketable on two 1×7 headers, native USB logging. XIAO C3 and S3 share the footprint, so changing MCU later means one new board file. |
| Firmware | ESPHome with packages and an external component | Board, modules and device composition are separate. Modules talk through entity ids (`co_ppm`, `co_fault`), never hardware. |
| Sensor link | Initiative-upload UART, RX only | The module streams every second unprompted. TX is routed on the PCB through 1 kΩ but stays unused. |
| Fault semantics | NaN + `problem` binary sensor on module fault **or** 10 s of silence | A dead or disconnected sensor must never look like "0 ppm". |
| Display | Seeed 1.54" 200×200 B/W panel; pins per Seeed's ePaper Driver Board | Same firmware on the driver board and our PCB; the panel's FPC latch is the releasable "clamp". |
| Display content | Integer ppm, plus the time of the last refresh | E-ink keeps its image when the device dies; the timestamp exposes staleness. |
| Power | USB-C on the XIAO feeds the ZE15 from the 5V pin | Simplest. **To verify in M1:** the ZE15 is specced for ≥ 5 V. |
| Autonomy | Self-contained device; integrations are optional packages | It measures and displays with no network. Wi-Fi and API reboot timeouts are disabled so being offline never interrupts measurement. |
| Integrations | Home Assistant via the ESPHome API, in `firmware/integrations/` | One consumer of `co_ppm`/`co_fault` among possible others (MQTT, web server). Alerting logic lives in the consumer; see [Home Assistant](integrations/home-assistant.md). |
| Cell lifecycle | Install date, service life and age kept in device flash; HA can edit them | The cell ages even unpowered and can't be recalibrated without test gas, so it's replaced on a schedule. Keeping the state on the device keeps it standalone. See [maintenance](maintenance.md). |
| Clock | SNTP over Wi-Fi | For the display's "updated" timestamp and cell-age tracking. Doesn't depend on HA; shows "no clock" when offline. |

## Open questions

- **Offline liveness on the display.** Without Wi-Fi there's no clock, so a frozen screen
  (dead device) looks the same as a live one. Options for M3: a heartbeat mark that flips
  on every refresh, or an RTC on the PCB. An RTC would also let cell-age tracking work
  on a device that never sees a network.
- **5 V margin.** Does the XIAO's 5V pin stay at or above 5 V under load, and does the
  ZE15 care if it doesn't? (M1 measurement.)
- **Socket fit.** Do the ZE15's short 2.0 mm pins seat reliably in Adafruit's sockets?
  (M1 test-fit.) The alternative is low-profile sockets or longer-tail headers.
- **M2 display approach.** Either put the FPC connector and boost circuit on our PCB,
  copied from Seeed's published
  [driver board schematic](https://files.seeedstudio.com/wiki/xiao_075inch_epaper_panel/ePaper_Driver_Board.pdf),
  or keep the driver board as a module. The pin map works for both.
- **ESPHome display driver.** The display module uses `waveshare_epaper` (`1.54inv2`).
  ESPHome's newer `epaper_spi` driver supports this panel on its dev branch but not yet in
  2026.9; migrate once it ships in stable.
- **Q&A mode.** Untested on hardware. The manual's Q&A example checksum (0x7A)
  contradicts its own formula (0x70); the parser trusts the formula.
