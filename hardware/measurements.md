# Measurements from real hardware

Captured 2026-10-17 from the first assembled unit: XIAO ESP32-C6 (pre-soldered) in a
Seeed ePaper Driver Board V2, with the 1.54" panel attached and no ZE15 yet. Photos are
in [`photos/`](photos/). Estimates scaled from photos are marked "photo est.", using the
driver board's 1.6 mm thickness or the XIAO's 17.8 mm width as the scale.

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
engagement and seat the spacer on the socket, for a stack of ~18.5 mm. Not done yet.

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

## Pending (not decided)

- **Proposed direction:** the display module (driver board + XIAO + folded panel) plus a
  separate small **sensor board** (ZE15 sockets and a 3-pin connector for 5V, GND and
  D7), joined by a short cable. Placement is then left to the enclosure.
- Whether to trim the XIAO pins.
- **Still to measure:** the ZE15 itself, the driver board's mounting holes, the panel
  outline, the USB plug housing, and the 5 V rail under load (see
  [enclosure](../enclosure/README.md)).
