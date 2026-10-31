# Enclosure (M4)

**This is the next piece of work.** Nothing is designed yet. The inputs gathered so far
are below, along with what's still needed from Kael.

## What it has to hold

Based on the real hardware (see [hardware/measurements.md](../hardware/measurements.md)):

- **Display module:** Seeed's ePaper Driver Board with the XIAO in its socket, and the
  1.54" panel folded flat against the board's underside, face out, 1–4 mm away (the
  ribbon allows no more). The driver board is ~25.5 mm wide and ~42 mm long, with 4
  mounting holes.
  - Stack on the XIAO side: socket ~4.7 mm, plus ~3.5 mm of bare pin unless the XIAO's
    pins are trimmed, plus spacer, XIAO board and USB-C. About 22 mm as assembled, or
    ~18.5 mm trimmed.
  - USB-C sits at the end opposite the panel's ribbon.
- **Sensor:** the ZE15-CO, upright, with its can (Ø21 mm, 17 mm above its board) open to
  room air. Proposed: on a small sensor board connected by a short 3-wire cable, placed
  wherever the enclosure wants it. Below the display module is the natural spot: the
  XIAO's warmth rises away from it.

## Requirements

- **Assembly:** compact and efficient, but tidy, professional and practical to assemble
  by hand. Not so tight it can't be put together.
- **Sensor chemistry (Winsen manual):**
  - No silicone, solvents, coatings or adhesives near the sensor. That includes hot glue,
    conformal coating and silicone gaskets. Use mechanical fixings.
  - Passive airflow to the sensor face, not a draught; no fans.
  - Avoid resin (SLA) prints unless fully cured: uncured resin gives off vapours. MJF
    nylon or PETG are good fits.
- **Environment:** -10–55 °C, 15–90 % RH, non-condensing. Keep away from kitchens and
  bathrooms, where alcohol and vapours cause false readings.
- **Access:** USB-C, and swapping the sensor (3–5 year life) without tools if possible.
- **Display window** for the panel: active area about 27.6 × 27.6 mm; confirm on the part.

## Still needed from Kael

1. **Architecture.** Approve the sensor board on a cable, or choose the jumper harness
   plus a cradle (no custom PCB).
2. **Mounting:** wall, shelf/desk, or both? Portrait or landscape screen? Which way does
   the USB cable exit?
3. **Battery backup:** include a LiPo bay or not (unverified feature; adds size).
4. **Assembly style:** screws (heat-set inserts plus M2) or snap-fit; tool-less sensor
   access or not.
5. **Printing:** own printer (which?) or a service; material and colour.
6. **XIAO pins:** trimmed or not (sets the module's depth).
7. **Measurements:**
   - the ZE15's total height and pin length, plus the paper-test result;
   - the driver board's mounting-hole diameter and positions;
   - the panel's outline, active-area position and ribbon edge;
   - the USB plug's housing size (and whether a right-angle cable is OK);
   - the 5 V reading from bring-up.

## The model

`assembly.py` is a CadQuery model of an assembled unit. It takes the board layout from
`hardware/carrier/geometry.py`, so the model tracks the PCB generator. `render.py` is a
small headless renderer for sketch views. `make assembly` writes `build/assembly.step`,
`build/assembly.glb` and renders.

**It still models the shelved carrier v0.2** (panel floating above the driver board).
Update it to the real arrangement before designing the enclosure: panel folded behind the
driver board, sensor board on a cable, and the measured heights above.
