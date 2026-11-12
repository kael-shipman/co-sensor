# M4: enclosure and build guide

**State: first design done in OpenSCAD, not yet printed.**

A wall-mounted case in three printed parts (body, display face, sensor face), fit-checked
against models of the hardware (`make enclosure-check`). Design, parts and assembly are in
[enclosure](../../../enclosure/README.md).

Decisions made with Kael on 2026-10-31:

- the sensor sits above the display, can facing out the front through a grille;
- the front splits into two faces that come off independently: two corner screws each,
  plus two pins into bosses on the body's side walls, and a lip/rebate around the rim
  (Kael's "tongue and groove");
- the panel slides into its slot from the top; the board rests on 3 mm rails on its 1 mm
  solder tails and screws to them through its top holes;
- a tab on the display face fills the front of the USB-C notch in the body;
- wall-mounted with two keyholes and 2 mm feet on the back; M2 screws and inserts;
- no custom PCB (see [M2](<m02 - sensor connection.md>)).

## Tasks

1. [ ] **Kael reviews the renders** (`enclosure/renders/`) and the design choices in
   `enclosure/README.md`.
2. [ ] **Measure the estimates** in
   [enclosure: still estimated](../../../enclosure/README.md#still-estimated), chiefly how
   far the XIAO's own board and its USB-C port stick out past the driver board's bottom
   edge (Kael said ~2 mm; a photo suggests 2.7 + 2.5 mm). Update `config.scad`, then
   `make enclosure`.
3. [ ] **Order** the sensor plugs and the enclosure hardware ([BOM, order 3](../../bom.md)).
4. [ ] **Print and test-fit** on Kael's Ender 3 (PLA). Expect to tune clearances: the panel
   slot, the spring fingers' grip on the can, the face lips, and the pin holes.
5. [ ] **Firmware:** `rotation: 180°` was added to the display for the folded panel; flash
   and check it on hardware.
6. [ ] **Write the single build guide** (Kael's requirement: anyone can go from GitHub to a
   working unit from one entry point): what to buy and where, what to print from which
   file, soldering, assembly, flashing, onboarding. `docs/bom.md` folds into it.
