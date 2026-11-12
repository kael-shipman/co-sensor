# Bill of materials

Quantities are for **three units** running together, plus spares. Prices and stock
checked 2026-10-10. Everything that Seeed makes comes from Seeed. Two parts can't come
from Seeed: the sensor (sold by its manufacturer) and the 2.0 mm-pitch connectors that
fit it.

## Order 1: Seeed Studio (seeedstudio.com)

| Qty | Item | SKU | Each | Notes |
|---|---|---|---|---|
| 4 | [XIAO ESP32-C6 (Pre-Soldered)](https://www.seeedstudio.com/Seeed-Studio-XIAO-ESP32C6-Pre-Soldered-p-6328.html) | 102010636 | $6.20 | One per unit plus a spare. Pre-soldered pins fit the jumpers and sockets directly. |
| 3 | [ePaper Driver Board for XIAO (V2)](https://www.seeedstudio.com/ePaper-breakout-Board-for-XIAO-V2-p-6374.html) | 114993558 | $5.99 | One per unit. The XIAO's permanent home: 24-pin FPC for the display, XIAO socket, breakout of every XIAO pin, LiPo connector. |
| 4 | [1.54" Monochrome ePaper, 200×200](https://www.seeedstudio.com/1-54-Monochrome-ePaper-Display-with-200x200-Pixels-p-5776.html) | 104990843 | $6.50 | One per unit plus a spare (bare panels crack easily). Works with ESPHome's `waveshare_epaper` / `1.54inv2`. |

Subtotal ≈ **$69** before shipping.

## Sensors: ZE15-CO

**Bought separately (AliExpress).** You need one per unit (3), plus at most one sealed
spare for accidents or a dead-on-arrival unit. Don't keep spares for end-of-life
replacement: the cell ages on the shelf too (see [maintenance](maintenance.md)). If the
cells carry a date code, check it on arrival.

For more later, [Winsen's official store](https://shop.winsen-sensor.com/products/electrochemical-co-module-ze15-co)
sells them in pairs ($20.00 / 2; ships from Zhengzhou by DHL/FedEx in 3–7 working days,
or e-Packet in 15–35). Order replacements when a unit says they're due.

## Order 2: Adafruit (adafruit.com)

| Qty | Item | PID | Each | Notes |
|---|---|---|---|---|
| 1 | [Female-Female 2.54 to 2.0 mm jumper wires ×40](https://www.adafruit.com/product/1919) | 1919 | $6.95 | The sensor harness (see [wiring](wiring.md#m1-wiring)). Two pairs per unit, so one strip covers all three. |
| 3 | [2 mm 10-pin socket headers, pack of 2](https://www.adafruit.com/product/366) | 366 | $0.95 | Not needed by the final design (the sensor plug below replaces them). They confirmed the ZE15's pins are standard 2.0 mm. |
| 1 | [Break-away 0.1" 36-pin male header ×10](https://www.adafruit.com/product/4151) | 4151 | $4.95 | One 1×7 per driver board, on the 5V…D7 breakout column, pins **up**, for the sensor connection (see [wiring](wiring.md#m1-wiring)). Any colour or brand works; black (392) was out of stock, so this is red. |
| 1 | [36-pin 0.1" female header, pack of 5](https://www.adafruit.com/product/598) | 598 | $2.95 | Bought for the carrier PCB, since dropped. Spare. |

Subtotal ≈ **$18** before shipping.

## Order 3: the sensor plug and the enclosure's hardware

No custom PCB. Per unit:

- one [Sullins NPPN101FGGN-RC](https://www.digikey.com/en/products/detail/sullins-connector-solutions/NPPN101FGGN-RC/804829)
  (DigiKey, about $1.50): the right-angle socket that plugs onto the ZE15;
- the screws and heat-set inserts listed in [enclosure](../enclosure/README.md#hardware).

Shared by all units: three short wires per plug and a sleeve over each of its three solder
joints; one spool of each colour covers many units. Both must be **PVC (or PTFE) and
non-adhesive**: silicone insulation and adhesive-lined heat-shrink can outgas onto the
sensor cell. The enclosure
leaves room for 26 AWG PVC wire (1.3 mm across; `wire_d` in `enclosure/config.scad`), so
the 22 AWG sets common at hobby shops (1.5 mm) are too thick.

| Qty | Item | Part number | Each | Notes |
|---|---|---|---|---|
| 1 | [26 AWG stranded UL1007 hook-up wire, 25 ft, **red**](https://www.remingtonindustries.com/hook-up-wire/hook-up-wire-26-awg-stranded-solid-10-colors-7-sizes-available) | Remington 26UL1007STRRED25 | from $11 | 5V (ZE15 pin 15). PVC, 1.27 mm across. Stranded, because it flexes when the sensor face comes off. Bought from Remington Industries directly. |
| 1 | Same, **black** | Remington 26UL1007STRBLA25 | from $11 | GND (ZE15 pin 14). |
| 1 | Same, **yellow** | Remington 26UL1007STRYEL25 | from $11 | TXD → D7 (ZE15 pin 8). Yellow is the usual hobby colour for a single signal line, not a formal standard. |
| 1 | [1/16" heat-shrink, 2:1, black, 4 ft](https://www.digikey.com/en/products/detail/alpha-wire/F221B1-16-BK100/281667) | Alpha Wire F221B1/16 BK100 | not checked | Alpha's FIT-221: plain polyolefin, no adhesive lining. Added to the DigiKey order with the plugs. 1/16" is the size for the plug's legs: pins 14 and 15 are only 2.0 mm apart, so a larger sleeve won't fit side by side. |

Not ordered yet. This list becomes the single build guide once the enclosure has been
printed and test-fitted.

## Assumed on hand

- USB-C data cable (for flashing) and a 5 V USB supply per unit
- Multimeter (needed in M1 to measure the 5 V rail; see [bring-up](bringup.md))
- Soldering iron, for the driver boards' sensor header (through-hole only)

## Deliberately not bought yet

- **A 1 kΩ resistor** for the sensor's RXD line. Only needed if the firmware ever transmits
  to the sensor; it doesn't today.
- **A LiPo battery** for the driver board's battery connector. Possible power-cut backup,
  unverified (see [RESUME](../RESUME.md)).
- **A temperature/humidity sensor.** A possible later addition on I2C (D4/D5).

## Alternative: fewer shops

DigiKey stocks the Seeed parts (XIAO ESP32-C6, the ePaper driver board) and Adafruit's 366
and 1919, so everything except the sensors could come from one shop. When checked,
DigiKey showed **no stock** of the pre-soldered XIAO ESP32-C6. Check stock before
choosing this route.
