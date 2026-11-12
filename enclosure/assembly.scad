// The assembled unit with its purchased parts, for checking fit. `explode` (mm) pulls the
// faces forward; `show` picks what to draw.
include <config.scad>
use <parts.scad>
use <components.scad>

explode = 0;
show_body = true;
show_faces = true;
show_parts = true;
cutaway = false;        // cut along the centre line to see inside

module unit() {
    if (show_body) color([0.93, 0.93, 0.90]) body();
    if (show_faces) {
        color([0.85, 0.86, 0.83]) translate([0, -explode, 0]) display_face();
        color([0.80, 0.81, 0.78]) translate([0, -1.6 * explode, 0]) sensor_face();
    }
    if (show_parts) {
        translate([0, -explode, 0]) display_parts();
        translate([0, -1.6 * explode, 0]) sensor_parts(wires = explode == 0);
    }
}

if (cutaway) difference() { unit(); translate([0, -50, -1]) cube([100, 200, 200]); }
else unit();
