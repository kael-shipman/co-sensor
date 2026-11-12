// Fit checks, run by check.py (`make enclosure-check`). Each `check` value renders the
// overlap between two things that must not touch; check.py fails if any overlap has volume.
include <config.scad>
use <parts.scad>
use <components.scad>

check = 0;
d = 0;          // how far a face has been pulled forward, for the removal checks

// The fingers squeeze the can on purpose; check against a can that's just small enough.
module ze15_checked() { ze15(can_squeeze = finger_grip + 0.01); }

if (check == 1) intersection() { body(); display_face(); }
if (check == 2) intersection() { body(); sensor_face(); }
if (check == 3) intersection() { display_face(); sensor_face(); }
if (check == 4) intersection() { body(); union() { display_parts(); ze15(); plug(); } }
if (check == 5) intersection() { display_face(); union() { display_parts(); ze15(); plug(); } }
if (check == 6) intersection() { sensor_face(); union() { display_parts(); ze15_checked(); plug(); } }
// Each face, with what it carries, comes straight off forward without the other moving.
if (check == 7) intersection() {
    translate([0, -d, 0]) { display_face(); display_parts(); }
    union() { body(); sensor_face(); ze15(); }
}
if (check == 8) intersection() {
    translate([0, -d, 0]) { sensor_face(); ze15_checked(); }
    union() { body(); display_face(); display_parts(); }
}
// The panel slides into its slot from the top; the board lifts off its rails.
if (check == 9) intersection() { display_face(); translate([0, 0, d]) panel(); }
if (check == 10) intersection() { display_face(); translate([0, d, 0]) { driver_board(); xiao(); header(); } }
