# Hardware (M2)

Not started. Constraints gathered so far:

- Pin map: [docs/wiring.md](../docs/wiring.md). Don't change it; the firmware and Seeed's
  driver board both depend on it.
- XIAO: 2× 1×7 2.54 mm female headers (socketed, never soldered).
- ZE15-CO: 1×10 + 1×5 2.0 mm sockets, rows ~22.8 mm apart. Confirm against the M1
  measurements in [docs/bringup.md](../docs/bringup.md). Winsen says not to pull the
  sensor cell off the module's own board; socketing the whole module is fine.
- ZE15 RX (pin 7) ← D6 through a 1 kΩ series resistor. ZE15 pin 3 (fault output) → D9
  is optional.
- Display: 24-pin FPC + boost circuit per Seeed's
  [ePaper Driver Board schematic](https://files.seeedstudio.com/wiki/xiao_075inch_epaper_panel/ePaper_Driver_Board.pdf),
  or carry the driver board itself (see [docs/plan.md](../docs/plan.md)).
- Qwiic (JST-SH 4-pin) on D4/D5 for expansion.
- Keep the sensor away from the ESP32's heat and the boost inductor.
