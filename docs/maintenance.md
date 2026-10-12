# Maintenance: the CO cell

The ZE15-CO's sensing element is a Winsen ME2-CO electrochemical cell, and it's a
consumable.

## It ages whether or not it's powered

The cell works like a tiny fuel cell: it reacts with the air reaching it whether or not
the module is powered, and power only runs the circuit that reads it. What wears it out
happens either way: the electrolyte slowly dries out or takes on water, the electrodes
lose activity, and vapours (silicones, solvents, alcohol) poison it.

- The ZE15 manual rates its life as **3–5 years "in air"**, not 3–5 years of operation.
- The ME2-CO cell datasheet gives sensitivity drift of **under 10 % per year**.
- Sealed, cool, dry storage slows aging but doesn't stop it. The datasheet also asks for
  **more than 48 hours powered on** before a stored cell's readings settle.

So **don't stockpile spares** for end-of-life replacement. A spare on the shelf ages
alongside the installed one. Keep one sealed spare for accidents and dead-on-arrival units;
buy end-of-life replacements when they're due.

The project has no way to recalibrate without test gas, so replacing on a schedule is
the practical way to manage drift.

## Lifecycle tracking on the device

`firmware/modules/co-lifecycle.yaml` keeps the cell's install date in the device's flash,
where it survives reboots, firmware updates, and Home Assistant being down or replaced.

| Entity | Kind | Meaning |
|---|---|---|
| CO sensor installed | date, editable | Recorded automatically on the first clock sync after flashing. Edit it to backdate a sensor installed earlier. |
| CO sensor replaced | button | Sets the install date to today. Press it after swapping the module. |
| CO sensor service life | number, editable | Years before replacement is due. Default 3, the low end of Winsen's 3–5 year rating. |
| CO sensor age | sensor | Days since installation; unknown until the clock has synced. |
| CO sensor replacement due | binary sensor | On once the age reaches the service life. The display swaps its title for an inverted **REPLACE CO SENSOR** banner. |

How it works and where it falls short:

- **It depends on the clock.** Dates come from SNTP, so a device that has never had network
  access never records an install date and never warns. The button logs a warning if
  pressed before the clock has synced.
- **It can't detect a sensor swap.** The ZE15 doesn't report a serial number, so you have
  to press the button.
- **Erasing flash resets it.** Normal and OTA flashing keep the stored values, but a full
  USB flash erase does not, and neither does renaming these entities: their names key the
  storage. After either, the first clock sync records that day as the install date, so
  backdate it by hand.

## Replacing the sensor

1. Unplug USB power.
2. Swap the ZE15 module: unclip the sockets once the PCB exists (M2), or move the two
   jumper pairs before that. Mind Vin/GND (see [wiring](wiring.md)).
3. Power up and press **CO sensor replaced**.
4. Give the new cell 48 hours before trusting its readings, especially if it was
   stored for a while.
5. Write the date on the module with a marker (not tape or adhesive; see the enclosure
   constraints).
