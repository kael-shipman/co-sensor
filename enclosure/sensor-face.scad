// Print file: the sensor face. Prints upside down, standing on its top edge, no supports.
include <config.scad>
use <parts.scad>
translate([0, 0, outer_h]) rotate([0, 180, 0]) sensor_face();
