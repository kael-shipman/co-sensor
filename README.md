# co-sensor

A small, realtime carbon monoxide sensor: a Winsen ZE15-CO electrochemical module read by
a Seeed XIAO ESP32-C6, showing the current level on an e-ink display. It's built on
ESPHome, so it can also report to Home Assistant (or anything else ESPHome talks to), but
it doesn't need to: with the display attached it's a self-contained device that keeps
working with no network at all.

> **Not a life-safety device.** Winsen states the module must not be used in systems
> related to human safety. Keep a certified CO alarm (UL 2034 / EN 50291) in the home;
> this sensor is for visibility and automation, not protection.

## Status

| Milestone | Scope | State |
|---|---|---|
| M1 | ZE15 → XIAO, readings verified end to end (via Home Assistant) | firmware done; awaiting parts ([bring-up](docs/bringup.md)) |
| M2 | Custom PCB with releasable sockets for XIAO, ZE15 and display | not started |
| M3 | 1.54" e-ink display | firmware module written and compiled; not enabled |
| M4 | Enclosure | not started |

See [docs/plan.md](docs/plan.md) for the milestone plan and the decisions that keep
later milestones from forcing rework.

## Layout

```
firmware/
  co-sensor.yaml                  the product: a name + a list of packages
  common/base.yaml                identity, Wi-Fi, OTA, clock (every device)
  boards/xiao-esp32c6.yaml        logical pin roles -> this board's GPIOs
  modules/ze15.yaml               the CO sensor; publishes `co_ppm` and `co_fault`
  modules/co-lifecycle.yaml       CO cell install date, age and replacement-due flag
  modules/epd-1in54.yaml          the display; consumes `co_ppm`, `co_fault`, replacement-due
  integrations/home-assistant.yaml  optional: ESPHome native API for Home Assistant
  components/ze15_co/             ESPHome external component for the ZE15-CO
tests/
  unit/                           host-side tests for the ZE15 protocol parser
  firmware/                       configs that validate/compile the firmware with dummy secrets
docs/                             plan, wiring, bill of materials, bring-up, maintenance, integrations
hardware/  enclosure/             M2 and M4 (constraints so far)
```

The firmware is split along the same lines as the hardware:

- A **board** package maps logical pin roles (`pin_co_rx`, `pin_epd_cs`, ...) to GPIOs.
- **Modules** only refer to those roles and talk to each other through entity ids, not
  hardware: the display reads `co_ppm`; it doesn't know there's a UART.
- **Integrations** are optional consumers of those same entities. The device behaves
  identically with or without them, and never reboots for lack of Wi-Fi or a client.

Swapping the MCU means writing one board file; adding the display or an integration
means adding one package line.

## Quick start

Everything runs through Docker; nothing needs installing besides `make`, `g++` and Docker.

```sh
cp firmware/secrets.example.yaml firmware/secrets.yaml   # then fill it in
make run PORT=/dev/ttyACM0     # first flash over USB; later `make run` flashes over Wi-Fi
make logs PORT=/dev/ttyACM0    # follow logs over USB (over Wi-Fi needs the HA/API integration)
```

Every unit runs the same image and names itself at boot from its MAC address, e.g.
`co-sensor-3fa2c1` (hostname, fallback hotspot and Home Assistant device alike). Building
a second sensor needs no new config. `make run` and `make logs` find units on the network
by mDNS; if several are online, ESPHome asks which one.

For Home Assistant, see [docs/integrations/home-assistant.md](docs/integrations/home-assistant.md).

## Tests

```sh
make test       # protocol unit tests + `esphome config` on every firmware config
make compile    # full firmware builds (first run downloads the ESP-IDF toolchain)
```

- `tests/unit/test_ze15_protocol.cpp` covers checksum maths against the manual's examples,
  frame decoding (fault bit, decimal scaling, Q&A frames, foreign gas types) and stream
  resynchronisation (garbage, truncated frames, checksum errors, `0xFF` in payloads).
- `tests/firmware/` builds:
  - `co-sensor`: the real device config;
  - `co-sensor-full`: the real device plus every optional module (so the display is
    compile-checked before any device enables it);
  - `co-sensor-standalone`: sensor + display with **no** integrations, which guards
    against modules quietly depending on Home Assistant.

## Readings

The ZE15 module publishes two values, which the display and any integration consume:

| Id | Meaning |
|---|---|
| `co_ppm` | CO in ppm, 0.1 resolution, averaged over 5 s. NaN (unknown) during the 60 s warm-up, while the module reports a fault, and when no valid frame has arrived for 10 s, so a dead sensor never reads as "0 ppm". |
| `co_fault` | On when the module reports a fault or has stopped reporting. |

The CO cell is a consumable that ages even unpowered, so `modules/co-lifecycle.yaml`
keeps its install date in the device's flash. It publishes `co_cell_age` (days) and
`co_cell_replacement_due`, with a "replaced" button and an editable service life. See
[docs/maintenance.md](docs/maintenance.md).
