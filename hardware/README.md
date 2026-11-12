# Hardware

- [`measurements.md`](measurements.md): dimensions measured on the first real unit, with
  [`photos/`](photos/). Start here; it overrides estimates elsewhere.
- **No custom PCB.** The ZE15 connects to the driver board through a right-angle socket on
  its own pins and three wires (see [enclosure](../enclosure/README.md#the-sensor-plug)).
  Two earlier PCB designs, a carrier under the driver board and a small sensor board, were
  dropped; the carrier's KiCad generator is in the git history.

Constraints any future board should keep:

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
RTC for offline timekeeping (see [RESUME.md](../RESUME.md)).
