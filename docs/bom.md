# Bill of materials

Prices and stock checked 2026-10-10. Everything that Seeed makes comes from Seeed. Two
parts can't come from Seeed: the sensor (sold by its manufacturer) and the 2.0 mm-pitch
connectors that fit it.

## Order 1: Seeed Studio (seeedstudio.com)

| Qty | Item | SKU | Each | Notes |
|---|---|---|---|---|
| 3 | [XIAO ESP32-C6 (Pre-Soldered)](https://www.seeedstudio.com/Seeed-Studio-XIAO-ESP32C6-Pre-Soldered-p-6328.html) | 102010636 | $6.20 | One for the build, one for development, one spare. Pre-soldered pins fit the jumpers and sockets directly. |
| 1 | [ePaper Driver Board for XIAO (V2)](https://www.seeedstudio.com/ePaper-breakout-Board-for-XIAO-V2-p-6374.html) | 114993558 | $5.99 | 24-pin FPC, XIAO socket, breakout of every XIAO pin. Its pinout defines our display pins; its schematic is the reference for M2. |
| 2 | [1.54" Monochrome ePaper, 200×200](https://www.seeedstudio.com/1-54-Monochrome-ePaper-Display-with-200x200-Pixels-p-5776.html) | 104990843 | $6.50 | Works with ESPHome's `waveshare_epaper` / `1.54inv2`. Bare panels crack easily; the second is insurance. |

Subtotal ≈ **$37** before shipping.

## Order 2: Winsen official store (shop.winsen-sensor.com)

| Qty | Item | Price | Notes |
|---|---|---|---|
| 1 pack (2 pcs) | [ZE15-CO electrochemical CO module](https://shop.winsen-sensor.com/products/electrochemical-co-module-ze15-co) | $20.00 / 2 | The manufacturer's own store; ships from Zhengzhou by DHL/FedEx (3–7 working days) or e-Packet (15–35). Sold only in pairs, which gives a spare: the cell lasts 3–5 years. |

Skip this order if you already have a ZE15-CO and don't want a spare.

## Order 3: Adafruit (adafruit.com)

| Qty | Item | PID | Each | Notes |
|---|---|---|---|---|
| 1 | [Female-Female 2.54 to 2.0 mm jumper wires ×40](https://www.adafruit.com/product/1919) | 1919 | $6.95 | M1 harness, no soldering (see [wiring](wiring.md#m1-wiring-no-soldering)). |
| 2 | [2 mm 10-pin socket headers, pack of 2](https://www.adafruit.com/product/366) | 366 | $0.95 | The ZE15 sockets for M2. Cut one down to 5 positions for the short row. Test-fit them in M1. |
| 1 | [Break-away 0.1" 36-pin male header ×10](https://www.adafruit.com/product/392) | 392 | $4.95 | For the driver board's breakout rows (M3), plus spares. Only 7 were in stock when checked; any 0.1" male header works. |

Subtotal ≈ **$14** before shipping.

## Assumed on hand

- USB-C data cable and a 5 V USB supply
- Multimeter (needed in M1 to measure the 5 V rail; see [bring-up](bringup.md))
- Soldering iron, for M3's breakout headers only

## Deliberately not bought yet

- **PCB-level parts for M2** (the 24-pin FPC connector, e-paper boost circuit, 1 kΩ
  resistor, 2.54 mm female sockets for the XIAO). These come with the board order. Seeed
  Fusion's PCB assembly service can source and populate them, so M2 stays a Seeed order.
- **A temperature/humidity sensor** for the reserved I2C/Qwiic port. Optional; decide in M2.

## Alternative: fewer shops

DigiKey stocks the Seeed parts (XIAO ESP32-C6, the ePaper driver board) and Adafruit's 366
and 1919, so DigiKey plus Winsen would be two orders instead of three. When checked,
DigiKey showed **no stock** of the pre-soldered XIAO ESP32-C6. Check stock before
choosing this route.
