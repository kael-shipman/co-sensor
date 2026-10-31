> **Shelved (2026-10-17).** This board plugs into the driver board from below. Real
> hardware showed the panel's ribbon is so short that the panel must fold flat against
> the driver board's underside (see [measurements](../measurements.md)), so nothing can
> mount there. Don't order it. It's kept because its generator, DRC flow, printable
> footprint check and ZE15 footprint are the starting point for the proposed sensor board.

# Carrier board

The base of a unit: a 2-layer board, 61 × 44 mm. Seeed's ePaper Driver Board, with the
XIAO ESP32-C6 in its socket, plugs into it like a shield, and the ZE15-CO plugs in beside
it. Nothing is soldered to the XIAO, the driver board's circuitry or the sensor.

```
 USB-C edge
┌───────────────┬─────────────────────────────┐
│ ePaper Driver │                             │
│ Board         │   ZE15-CO                   │
│  + XIAO       │                             │
│ (plugs into   │                             │
│  2 × 1×7      │                             │
│  sockets)     ├─────────────────────────────┤
│               │   R1 (optional)             │
│  display FPC  │                             │
└───────────────┴─────────────────────────────┘
```

**Forward compatible:** without a panel, this is an M1 unit. Plug a panel into the driver
board's FPC connector and enable the display package, and it's M3, with no new board.

| Connection | Driver board breakout (XIAO pin) | ZE15 |
|---|---|---|
| 5 V | 5V | pin 15 |
| Ground | GND | pin 14 |
| Sensor TXD → MCU RX | D7 | pin 8 |
| MCU TX → sensor RXD (through optional R1, 1 kΩ) | D6 | pin 7 |

Same pin map as [docs/wiring.md](../../docs/wiring.md), so the firmware doesn't change.
The display pins (D0–D3, D8, D10) are wired on the driver board itself. Four M2.5
mounting holes: three corners plus one between the breakout sockets.

## Source

`generate.py` builds `co-sensor-carrier.kicad_pcb` with KiCad's Python API. It holds the
geometry, nets and routing, with the dimension sources and their confidence noted at the
top. Don't edit the `.kicad_pcb` by hand; change the script and run:

```sh
make carrier         # regenerate + KiCad DRC (fails on any violation or unrouted net)
make carrier-check   # build/carrier-footprint-check.pdf, the printable 1:1 check
make carrier-fab     # build/co-sensor-carrier-fab.zip, Gerbers + drill for ordering
```

There's no schematic yet: with four nets, the table above and `NETS` in the script are
the schematic. Add a real one before this design grows.

## 1. Footprint check: do this before ordering

Two sets of dimensions are unconfirmed:

- **The ZE15's footprint** comes from Winsen's drawing, which doesn't say whether it's a
  top or bottom view. A wrong guess means the module won't fit.
- **The driver board's breakout rows** were measured from Seeed's product photo: about
  22.3 mm apart. A photo can be off by half a millimetre.

The check catches both, at no cost. First solder the male headers into the driver board
(step 3 below), because the check uses them.

1. Run `make carrier-check` and print `build/carrier-footprint-check.pdf` at **100 % /
   actual size**, with no "fit to page".
2. Measure the scale bar under the board. It must be **50 mm**. If it isn't, fix the
   print settings and print again.
3. Put the page on a piece of corrugated cardboard.
4. **ZE15:** hold it can up, pins down, and press it onto its outline.
   - Every pin should land on a hole.
   - Its square pads (pins 1 and 6) should land on the page's square pads.
5. **Driver board:** components up, headers pointing down, USB end toward the "USB-C"
   label. Press it onto the two 7-hole columns; all 14 pins should land on holes.

If anything is off, measure what's wrong: centre-to-centre distance between the driver
board's two header columns, or which ZE15 pins miss and by how much. The design gets
corrected before ordering.

## 2. Order

Upload `build/co-sensor-carrier-fab.zip` to [Seeed Fusion](https://www.seeedstudio.com/fusion_pcb.html)
(or any PCB fab). The defaults are fine: 2 layers, FR-4, 1.6 mm, 1 oz copper, lead-free
HASL, any colour. Minimum quantities are usually 5 or 10, which gives you spares for all
three units.

## 3. Parts per unit

| Qty | Part | Where it goes | Source |
|---|---|---|---|
| 1 | Seeed ePaper Driver Board for XIAO | plugs into the carrier | Seeed 114993558 |
| 2 | 1×7 male header, 2.54 mm | soldered into the driver board's breakout rows, **pins pointing down** | cut from a 36-pin strip (Adafruit 4151) |
| 2 | 1×7 female header, 2.54 mm | carrier J1/J2 | cut from a 36-pin strip ([Adafruit 598](https://www.adafruit.com/product/598)); cutting sacrifices one position |
| 1 | 1×10 female socket, 2.0 mm | carrier J3 | [Adafruit 366](https://www.adafruit.com/product/366) |
| 1 | 1×5 female socket, 2.0 mm | carrier J4 | a second 366 socket cut down to 5 |
| opt. | 1 kΩ ¼ W axial resistor | R1 | only if the firmware ever transmits to the sensor; it doesn't today |

## 4. Assemble

Through-hole only.

1. **Driver board headers.** Push the two 1×7 male headers into the driver board's
   breakout holes from the **bottom**, so the long pins point down and the plastic spacer
   sits under the board. Solder the short ends on top: 14 joints.
   - These pins plug into the carrier.
   - They also take jumper wires (M1 before the carrier arrives; see the wiring docs).
2. **Carrier sockets for the driver board.** Push the two 1×7 female headers into J1/J2
   and plug the driver board into them. That holds them square while you solder. Solder
   from underneath, then unplug.
3. **ZE15 sockets.** Don't solder with the sensor plugged in; the cell is heat-sensitive.
   - Push the 10- and 5-position sockets into J3/J4 and solder **one pin of each**.
   - Test-fit the ZE15 cold, adjust if a socket is crooked, then remove it and solder
     the rest.
4. Optional: R1.
5. **Plug in the parts.**
   - XIAO into the driver board, USB-C at the board edge.
   - The driver board into the carrier, USB end at the "USB-C" label.
   - The ZE15 can up, square pads on the silkscreen "1" and "6" marks.
6. Bring it up as in [docs/bringup.md](../../docs/bringup.md); the firmware is the same.
