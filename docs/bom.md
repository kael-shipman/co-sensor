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
| 3 | [2 mm 10-pin socket headers, pack of 2](https://www.adafruit.com/product/366) | 366 | $0.95 | The ZE15's sockets on the future sensor board: one pack per unit. Cut one socket down to 5 positions for the short row. Test-fit them now. |
| 1 | [Break-away 0.1" 36-pin male header ×10](https://www.adafruit.com/product/4151) | 4151 | $4.95 | One 1×7 per driver board, on the 5V…D7 breakout column, pins **up**, for the sensor connection (see [wiring](wiring.md#m1-wiring)). Any colour or brand works; black (392) was out of stock, so this is red. |
| 1 | [36-pin 0.1" female header, pack of 5](https://www.adafruit.com/product/598) | 598 | $2.95 | Bought for the shelved carrier v0.2. Spare; may be useful for the sensor board. |

Subtotal ≈ **$18** before shipping.

## Order 3: Sensor boards (not designed yet)

The proposed sensor board (ZE15 sockets plus a 3-pin connector) will be a small 2-layer
PCB from [Seeed Fusion](https://www.seeedstudio.com/fusion_pcb.html), plus a short 3-wire
cable. **Don't order the carrier v0.2 boards**: that design is shelved (see
[hardware/carrier](../hardware/carrier/README.md)).

## Assumed on hand

- USB-C data cable (for flashing) and a 5 V USB supply per unit
- Multimeter (needed in M1 to measure the 5 V rail; see [bring-up](bringup.md))
- Soldering iron, for the driver boards' sensor header (through-hole only)

## Deliberately not bought yet

- **A 1 kΩ resistor** for the sensor's RXD line. Only needed if the firmware ever transmits
  to the sensor; it doesn't today.
- **A LiPo battery** for the driver board's battery connector. Possible power-cut backup,
  unverified (see [plan](plan.md)).
- **A temperature/humidity sensor.** A possible later addition on I2C (D4/D5).

## Alternative: fewer shops

DigiKey stocks the Seeed parts (XIAO ESP32-C6, the ePaper driver board) and Adafruit's 366
and 1919, so everything except the sensors could come from one shop. When checked,
DigiKey showed **no stock** of the pre-soldered XIAO ESP32-C6. Check stock before
choosing this route.
