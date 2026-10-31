# Hardware

- [`measurements.md`](measurements.md): dimensions measured on the first real unit, with
  [`photos/`](photos/). Start here; it overrides estimates elsewhere.
- [`carrier/`](carrier/README.md): carrier v0.2, **shelved**. It plugged into the driver
  board from below, but the panel's very short ribbon means the panel must fold flat
  against the driver board's underside, so nothing can mount there. Its KiCad generator,
  footprint check and ZE15 footprint remain useful starting points.
- **Next board (proposed, not designed):** a small sensor board holding the ZE15 in 2.0 mm
  sockets, with a 3-pin connector (5V, GND, D7) on a short cable to a header on the
  driver board. See [docs/plan.md](../docs/plan.md).

Constraints any board should keep:

- **Pin map:** [docs/wiring.md](../docs/wiring.md). The firmware and Seeed's driver board
  both depend on it.
- **Everything socketed, nothing soldered to a module.** Winsen says not to pull the
  sensor cell off the module's own board; socketing the whole module is fine.
- **ZE15 RXD (pin 7) ← D6,** through a 1 kΩ series resistor, is optional; the firmware
  doesn't transmit.
- **Keep the sensor away** from the ESP32's heat and the driver board's boost inductor.
- **Practical to assemble by hand:** tidy and professional, but not so tight it can't be
  put together (Kael's requirement).

Ideas for later: a Qwiic (I2C on D4/D5) port for a temperature/humidity sensor, and an
RTC for offline timekeeping (see [docs/plan.md](../docs/plan.md)).
