# Vision

## Who it's for, and why

Carbon monoxide is invisible, and a certified alarm only speaks up once levels are already
dangerous. This project gives a home **realtime visibility** of CO: a small wall-mounted
unit per room that shows the current level at a glance and, optionally, feeds it to Home
Assistant for history and automations. Kael runs at least three units together.

It's built **as if distributed to the public**: anyone should be able to go from this
repository to a printed, assembled, working unit from one entry point, with one firmware
image for every unit and nothing personal in the repo. It complements a certified CO
alarm; it never replaces one.

## How it works

A Winsen ZE15-CO electrochemical module streams readings over UART to a Seeed XIAO
ESP32-C6, which shows them on a 1.54" e-ink panel. The XIAO and panel sit on Seeed's ePaper
Driver Board (the "display module"); the ZE15 connects to it with a right-angle socket and
three wires, with no custom PCB. A three-part printed enclosure holds it all on a wall,
with the sensor facing the room through a grille.

The device is **standalone first**: it measures and displays with no network at all.
Integrations such as Home Assistant are optional consumers of the same readings.

### Firmware

The firmware is split along the same lines as the hardware:

- A **board** package maps logical pin roles (`pin_co_rx`, `pin_epd_cs`, ...) to GPIOs.
- **Modules** only refer to those roles and talk to each other through entity ids, not
  hardware: the display reads `co_ppm`; it doesn't know there's a UART.
- **Integrations** are optional consumers of those same entities. The device behaves
  identically with or without them, and never reboots for lack of Wi-Fi or a client.

Swapping the MCU means writing one board file; adding the display or an integration
means adding one package line.

## Decisions

| Decision | Choice | Why |
|---|---|---|
| MCU | Seeed XIAO ESP32-C6 | Tiny, socketable on two 1×7 headers, native USB logging. XIAO C3 and S3 share the footprint, so changing MCU later means one new board file. |
| Firmware | ESPHome with packages and an external component | Board, modules and device composition are separate. Modules talk through entity ids (`co_ppm`, `co_fault`), never hardware. |
| Sensor link | Initiative-upload UART, RX only | The module streams every second unprompted. TX stays unused (it would need a 1 kΩ series resistor). |
| Fault semantics | NaN + `problem` binary sensor on module fault **or** 10 s of silence | A dead or disconnected sensor must never look like "0 ppm". |
| Display | Seeed 1.54" 200×200 B/W panel on Seeed's ePaper Driver Board | The panel's FPC latch is its releasable "clamp". |
| Board architecture | Seeed's driver board (with XIAO and folded panel) as the "display module"; the ZE15 on a short cable, with no custom PCB | The driver board already has the fine-pitch FPC connector and the panel's boost circuit, the hardest parts to put on our own board. The panel's very short ribbon forces it flat behind the driver board, so nothing can mount underneath. A right-angle socket on the ZE15's own pins replaces a sensor board, which saves a PCB order for every builder. |
| Enclosure | Wall-mounted, three printed parts (body, display face, sensor face), M2 screws into heat-set inserts | Either face comes off forward on its own, so the sensor can be replaced with the body still on the wall. The sensor sits above the display, facing the room through a grille. Everything prints without supports on a hobby printer (PLA is fine). |
| Display content | Integer ppm, plus the time of the last refresh ("Oct 26 at 21:30:15 CDT") | E-ink keeps its image when the device dies; the timestamp exposes staleness. |
| Reporting rate | 1 Hz readings averaged; `co_ppm` published once per **Update interval** (HA-editable, default 15 s); the display refreshes on each publish | One tick drives every consumer, so HA and the screen always agree; faults are still published immediately. |
| Power | USB-C on the XIAO feeds the ZE15 from the 5V pin | Simplest. **To verify in M1:** the ZE15 is specced for ≥ 5 V. |
| Autonomy | Self-contained device; integrations are optional packages | It measures and displays with no network. Wi-Fi and API reboot timeouts are disabled so being offline never interrupts measurement. |
| Integrations | Home Assistant via the ESPHome API, in `firmware/integrations/` | One consumer of `co_ppm`/`co_fault` among possible others (MQTT, web server). Alerting logic lives in the consumer; see [Home Assistant](docs/integrations/home-assistant.md). |
| Cell lifecycle | Install date, service life and age kept in device flash; HA can edit them | The cell ages even unpowered and can't be recalibrated without test gas, so it's replaced on a schedule. Keeping the state on the device keeps it standalone. See [maintenance](docs/maintenance.md). |
| Credentials | None in the image; per-unit provisioning ([onboarding](docs/onboarding.md)) | One binary for everyone. Wi-Fi comes from the unit's hotspot/setup page (or Improv over USB), and the API key from Home Assistant at adoption. A 15-minute provisioning window keeps unconfigured units from staying open. |
| Update security | Shared image: open updates on the LAN; owners can adopt + add a password | A shared image can't hold a secret. ESPHome can't require API-key-encrypted updates with a runtime-provisioned key. |
| Clock | SNTP over Wi-Fi, plus time from Home Assistant when integrated | For the display's timestamp and cell-age tracking; shows "no clock" when offline. |
| Timezone | Built as UTC; Home Assistant's timezone applied at runtime | ESPHome would otherwise bake in the build machine's timezone. HA 2026.3+ sends its timezone with the time. Units without HA stay on UTC. |
