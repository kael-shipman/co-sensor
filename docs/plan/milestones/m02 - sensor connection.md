# M2: sensor connection

**State: designed, not built. No custom PCB.**

A right-angle 2.0 mm socket (Sullins NPPN101FGGN-RC) plugs onto the ZE15's 10-pin row;
three wires soldered to its legs run to the driver board's 5V, GND and D7 holes. Details
in [enclosure: the sensor plug](../../../enclosure/README.md#the-sensor-plug).

Two PCB designs came before this and were dropped:

- a carrier under the driver board: the panel has to fold flat there (see
  [measurements](../../../hardware/measurements.md));
- a small sensor board: the enclosure didn't need one.

## Tasks

- [x] Confirm the ZE15's pins are standard 2.0 mm and Winsen's drawing is a top view
      (printed 1:1 footprint check, 2026-10-31).
- [ ] Order the sockets (see [BOM, order 3](../../bom.md)).
- [ ] Build one plug harness and test it against the M1 jumper wiring.
