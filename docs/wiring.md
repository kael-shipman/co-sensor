# Wiring

## Pin map

One pin map for every stage: loose wires (M1), Seeed's ePaper Driver Board (M3 before the
PCB exists) and our own PCB (M2+). The display pins are dictated by the Seeed driver
board; everything else was chosen around them. The firmware encodes this table in
`firmware/boards/xiao-esp32c6.yaml`.

| Role | XIAO pin | GPIO | Connects to | Substitution |
|---|---|---|---|---|
| UART RX | D7 | 17 | ZE15 pin 8 (TXD) | `pin_co_rx` |
| UART TX | D6 | 16 | ZE15 pin 7 (RXD) through 1 kΩ; **unconnected until needed** | `pin_co_tx` |
| 5 V | 5V | – | ZE15 pin 15 (Vin) | – |
| Ground | GND | – | ZE15 pin 14 (and pin 5) | – |
| Display RST | D0 | 0 | ePaper RST | `pin_epd_reset` |
| Display CS | D1 | 1 | ePaper CS | `pin_epd_cs` |
| Display BUSY | D2 | 2 | ePaper BUSY | `pin_epd_busy` |
| Display DC | D3 | 21 | ePaper DC | `pin_epd_dc` |
| SPI SCK | D8 | 19 | ePaper CLK | `pin_spi_clk` |
| SPI MOSI | D10 | 18 | ePaper DIN | `pin_spi_mosi` |
| I2C SDA / SCL | D4 / D5 | 22 / 23 | reserved for a Qwiic port | `pin_i2c_sda/scl` |
| Spare | D9 | 20 | ZE15 fault output (pin 3) or a button | `pin_spare` |

None of these are ESP32-C6 strapping pins. Logs go over the C6's native USB, which frees
the hardware UART on D6/D7 for the sensor.

Why the ZE15's RX stays disconnected: the module streams a reading every second without
being asked, so M1 needs only its TX. The 1 kΩ footprint on the PCB covers the small
mismatch (the ESP drives 3.3 V; the module's UART is 3.0 V) if Q&A mode is ever wanted.

## ZE15-CO pins

15 pins at **2.0 mm pitch** in two single rows on opposite edges (about 22.8 mm apart):
pins 1–5 on one side, pins 6–15 on the other. Pins 1 and 6 have square pads.

| Pin | Function |
|---|---|
| 15 | Vin, 5–12 V DC |
| 14, 5 | GND |
| 8 | UART TXD (3 V TTL) |
| 7 | UART RXD (3 V TTL) |
| 10 | Analog out, 0.4–2.0 V = 0–500 ppm |
| 3 | Fault output (1 Hz, 10 % duty) |
| 1 | 3.0 V output |
| 2, 4, 6, 9, 11–13 | NC / reserved |

Every pin M1 needs is in the 10-pin row, at the end away from the square pad (pin 6).

## M1 wiring (no soldering)

Uses Adafruit's female-female 2.54↔2.0 mm jumpers, which come in **pairs**: one 2-pin
2.0 mm housing splitting into two 2.54 mm sockets. Two adjacent ZE15 pin pairs cover
everything:

| Jumper pair | 2.0 mm end on ZE15 | 2.54 mm ends on the XIAO |
|---|---|---|
| A | pins 14 + 15 | pin 14 (GND) → **GND**; pin 15 (Vin) → **5V** |
| B | pins 7 + 8 | pin 8 (TXD) → **D7**; pin 7 (RXD) → leave unconnected, insulate the socket with tape |

The pre-soldered XIAO's pins point down; push the 2.54 mm sockets directly onto them.
XIAO pin order, USB end up and components facing you: left side D0–D6 top to bottom,
right side 5V, GND, 3V3, D10, D9, D8, D7 top to bottom.

**Before powering up, check pair A twice.** Swapping Vin and GND can destroy the module.
Colour-code or label the wires and keep them labelled.

## M3 wiring (Seeed ePaper Driver Board)

1. Solder 1×7 male headers into the driver board's two unpopulated breakout rows (CN1
   and CN2). This is the only soldering, and it isn't on the sensor.
2. Plug the XIAO into the driver board's socket and the panel's FPC into the 24-pin
   connector (contacts down, latch closed).
3. Move the M1 jumpers from the XIAO to the matching breakout pins: CN2 carries 5V, GND
   and D7.
4. Enable `display: !include modules/epd-1in54.yaml` in the device file.
