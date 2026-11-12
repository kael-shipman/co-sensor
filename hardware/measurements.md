# Measurements from real hardware

Captured 2026-10-17 from the first assembled unit: XIAO ESP32-C6 (pre-soldered) in a
Seeed ePaper Driver Board V2, with the 1.54" panel attached and no ZE15 yet. Photos are
in [`photos/`](photos/). Estimates scaled from photos are marked "photo est.", using the
driver board's 1.6 mm thickness or the XIAO's 17.8 mm width as the scale.

## 2026-10-31 caliper measurements (Kael) — these supersede the photo estimates below

Orientation terms (used from here on): **bottom** = USB-C end, **top** = display-ribbon
end, **front** = the driver board's underside, where the panel folds to face out,
**back** = the XIAO side; width, depth and height follow from those.

| Item | Value |
|---|---|
| Panel outline | 32 W × 37.5 H mm, glass 1 mm thick |
| Panel image area (visible crop) | 27 W × 28 H mm |
| Panel position, folded | its bottom edge 6.5 mm above the driver board's bottom edge |
| Driver board | 25 W × 42 H × 1.5 mm |
| Solder tails on the board's front | protrude 1 mm; the board rests on them |
| Tail tips → front of the XIAO's USB-C port | 13.5 mm |
| Tail tips → back of the XIAO's USB-C port | 16.5 mm (deepest point of the display module) |
| ZE15 can | Ø21 mm (lip); Winsen drawing: Ø20 body, 1.2 mm lip at the face end, 17 mm above the module PCB, 24.5 ± 1 mm overall including pins |
| Driver board, from a 300 dpi scan of its front (deskewed; ±0.2 mm) | 24.9 W × ~41.7 H mm |
| Driver board mounting holes | 4 × Ø ~2.6 mm (Kael: 2.5–3 mm), centres 1.85 mm in from each side edge (21.2 mm apart): one pair 22.9 mm and one pair 40.0 mm above the USB (bottom) edge |
| Breakout columns (5V…D7, RST…D6) | 1.2 mm in from each side edge (22.6 mm apart); first hole 2.7 mm above the bottom edge; 2.54 mm pitch |
| XIAO socket solder tails on the front | two columns ~17.9 mm apart (≈3.5 mm in from each side edge), spanning ~2.7–18 mm above the bottom edge; they protrude 1 mm |
| USB-C receptacle | overhangs the board's bottom edge by ~2 mm (Kael) |
| Display ribbon | 11.9 mm wide, centred on the board |
| Slide switch | protrudes ~0.7 mm past the right edge (seen from the front), ~29 mm above the bottom edge |
| ZE15 depth | 24 mm from the front of the can to the tips of its pins (pins point back, away from the can) |
| ZE15 pin rows, as mounted | the 10-pin row along the edge nearest the driver board, the 5-pin row along the top edge |
| ZE15 footprint check | printed 1:1 and confirmed: scale bar exactly 50 mm, every pin on its hole, square pads on pins 1 and 6. Winsen's drawing is a top view. |

## Display module stack (driver board outward, XIAO side)

| Item | Value | Source |
|---|---|---|
| Driver board thickness | 1.6 mm | standard |
| Driver board's XIAO socket height | ~4.7 mm | photo est. (side view) |
| Bare XIAO pin between socket and the XIAO's pin spacer | ~3.5 mm | measured by Kael |
| XIAO pin spacer (plastic) | ~2.5–3 mm | photo est. |
| XIAO PCB | ~1.2 mm | photo est. |
| USB-C receptacle above the XIAO | ~3 mm | photo est. |
| **Total stack, as assembled** | **~22 mm** | measured by Kael |

The gap is the XIAO's ~6 mm pins bottoming out in the ~4.7 mm socket, with only
~2–2.5 mm inserted. Trimming each pin by the gap (minus ~0.3 mm) would keep the same
engagement and seat the spacer on the socket, for a stack of ~18.5 mm. **Decided
(2026-11-05): leave the pins untrimmed.** The sensor, not the display module, sets the
enclosure's depth, so trimming would gain nothing.

## Driver board

| Item | Value | Source |
|---|---|---|
| Width | ~25.5 mm | photo est. (USB-end view); Seeed product photo gave ~24.7 mm |
| Tallest part at the display end: battery JST connector | ~6–7 mm | photo est. (side view) |
| Mounting holes | 4: two at the display/FPC end corners, two midway near the battery connector | top-view photo |
| Slide switch (side edge, near the battery connector) | Switches the LiPo battery input; does nothing without a battery | Seeed schematic |
| White 2-pin connector | LiPo battery input (JST, 2.0 mm). Check polarity against the board's +/− marks before connecting. | Seeed schematic, datasheet |

## Panel and its ribbon

- The panel's ribbon is **very short**. Folded around, the panel lies back-to-back
  against the driver board's underside (the side without components), face out.
- **Panel-to-board distance when folded: ~1 mm to ~4 mm.** At 1 mm the panel is touching
  the solder joints on the driver board's underside.
- So nothing can mount under the driver board. This rules out carrier v0.2, which plugs
  into the driver board from below.

## Constraint from Kael

Compact and efficient, but **tidy, professional and practical to assemble**. Don't make
it so tight that it can't be put together by hand.

## Photos

- `photos/2026-10-17-unit-top.jpg`: top view. The driver board with the XIAO (USB-C at
  the bottom) and the panel showing SENSOR FAULT before the ZE15 was connected.
- `photos/2026-10-17-unit-side.jpg`: side view. The XIAO-to-socket gap, the tall battery
  connector and the panel ribbon.
- `photos/2026-10-17-unit-usb-end.jpg`: from the USB end. The pin gap between the XIAO
  and the driver board.

## Still to measure

- How far the XIAO's board and its USB-C port stick out past the driver board's bottom
  edge, the ZE15's exposed pin length and its board thickness: still estimates in
  `enclosure/config.scad` (see [enclosure: still estimated](../enclosure/README.md#still-estimated)).
- The 5 V rail under load, during M1 bring-up ([bring-up](../docs/bringup.md)).

The sensor-board idea that used to be proposed here was dropped: the ZE15 connects through
a right-angle socket and three wires ([enclosure: the sensor plug](../enclosure/README.md#the-sensor-plug)).
