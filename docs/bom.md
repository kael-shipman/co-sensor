# Bill of materials

Quantities are for **three units** running together, plus spares. Prices and stock
checked 2026-10-10. Everything that Seeed makes comes from Seeed. Two parts can't come
from Seeed: the sensor (sold by its manufacturer) and the 2.0 mm-pitch connectors that
fit it.

## Order 1: Seeed Studio (seeedstudio.com)

| Qty | Item | SKU | Each | Notes |
|---|---|---|---|---|
| 4 | [XIAO ESP32-C6 (Pre-Soldered)](https://www.seeedstudio.com/Seeed-Studio-XIAO-ESP32C6-Pre-Soldered-p-6328.html) | 102010636 | $6.20 | One per unit plus a spare. Pre-soldered pins fit the jumpers and sockets directly. |
| 1 | [ePaper Driver Board for XIAO (V2)](https://www.seeedstudio.com/ePaper-breakout-Board-for-XIAO-V2-p-6374.html) | 114993558 | $5.99 | 24-pin FPC, XIAO socket, breakout of every XIAO pin. Its pinout defines our display pins; its schematic is the reference for M2. One is enough to prototype the display; buy **3** if you want displays on all units before the PCB exists. |
| 4 | [1.54" Monochrome ePaper, 200×200](https://www.seeedstudio.com/1-54-Monochrome-ePaper-Display-with-200x200-Pixels-p-5776.html) | 104990843 | $6.50 | One per unit plus a spare (bare panels crack easily). Works with ESPHome's `waveshare_epaper` / `1.54inv2`. |

Subtotal ≈ **$57** before shipping (≈ $69 with three driver boards).

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
| 1 | [Female-Female 2.54 to 2.0 mm jumper wires ×40](https://www.adafruit.com/product/1919) | 1919 | $6.95 | M1 harness, no soldering (see [wiring](wiring.md#m1-wiring-no-soldering)). Two pairs per unit, so one strip covers all three. |
| 3 | [2 mm 10-pin socket headers, pack of 2](https://www.adafruit.com/product/366) | 366 | $0.95 | The ZE15 sockets for M2: one pack per unit. Cut one socket down to 5 positions for the short row. Test-fit them in M1. |
| 1 | [Break-away 0.1" 36-pin male header ×10](https://www.adafruit.com/product/4151) | 4151 | $4.95 | Only for the driver board's breakout rows (M3, before the PCB exists). Any colour or brand of 0.1" male header works; black (392) was out of stock, so this is red. Seeed's [pin header pack](https://www.seeedstudio.com/Pin-headers-experimental-pack.html) also works, or skip it if M3 happens on the PCB. |

Subtotal ≈ **$15** before shipping.

## Assumed on hand

- USB-C data cable (for flashing) and a 5 V USB supply per unit
- Multimeter (needed in M1 to measure the 5 V rail; see [bring-up](bringup.md))
- Soldering iron, for M3's breakout headers only

## Deliberately not bought yet

- **PCB-level parts for M2** (the 24-pin FPC connector, e-paper boost circuit, 1 kΩ
  resistor, 2.54 mm female sockets for the XIAO). These come with the board order. Seeed
  Fusion's PCB assembly service can source and populate them, so M2 stays a Seeed order.
- **A temperature/humidity sensor** for the reserved I2C/Qwiic port. Optional; decide in M2.

## Alternative: fewer shops

DigiKey stocks the Seeed parts (XIAO ESP32-C6, the ePaper driver board) and Adafruit's 366
and 1919, so everything except the sensors could come from one shop. When checked,
DigiKey showed **no stock** of the pre-soldered XIAO ESP32-C6. Check stock before
choosing this route.
