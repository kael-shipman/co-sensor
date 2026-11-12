// The three printed parts, in device coordinates (see config.scad):
//
//   body()          the wall-mounted shell: back, sides, top and bottom, open at the front
//   display_face()  lower front: window, panel slot, rails the driver board screws to,
//                   and the tab that closes the USB-C opening
//   sensor_face()   upper front: grille and the spring fingers that hold the ZE15's can
//
// Each face has two corner screws into heat-set inserts in the body, two locating pins
// into bosses on the body's side walls, and a lip that seats in a rebate around the body's
// front rim. Either face comes off forward without disturbing the other.

include <config.scad>

$fn = 64;

// --- 2D helpers, in the (x, z) plane of the front view ---------------------------------

module rrect(x0, x1, z0, z1, r) {
    r2 = min(r, (x1 - x0) / 2 - 0.01, (z1 - z0) / 2 - 0.01);
    translate([x0 + r2, z0 + r2]) offset(r = r2) square([x1 - x0 - 2 * r2, z1 - z0 - 2 * r2]);
}

// The device's front-view outline, shrunk by `inset`.
module outline(inset = 0) {
    rrect(-half_out + inset, half_out - inset, inset, outer_h - inset, max(corner_r - inset, 0.4));
}

module zband(z0, z1) { translate([-100, z0]) square([200, z1 - z0]); }

// Extrude a front-view (x, z) profile along y, from y0 to y1.
module along_y(y0, y1) {
    translate([0, y1, 0]) rotate([90, 0, 0]) linear_extrude(y1 - y0) children();
}

// Cylinder along y, centred on (x, z).
module ycyl(x, z, d, y0, y1) {
    translate([x, y0, z]) rotate([-90, 0, 0]) cylinder(d = d, h = y1 - y0);
}

module box(x, y, z) {
    translate([min(x), min(y), min(z)]) cube([abs(x[1] - x[0]), abs(y[1] - y[0]), abs(z[1] - z[0])]);
}

// The outer solid between y0 and y1, its edges chamfered at the front and/or back.
module shell(y0, y1, front_chamfer = 0, back_chamfer = 0) {
    c = edge_chamfer;
    hull() {
        if (front_chamfer > 0) along_y(y0, y0 + 0.01) outline(c);
        along_y(y0 + front_chamfer * c, y1 - back_chamfer * c) outline(0);
        if (back_chamfer > 0) along_y(y1 - 0.01, y1) outline(c);
    }
}

// --- Shared features --------------------------------------------------------------------

// USB-C opening in the bottom wall: a stadium around the receptacle.
usb_open_w = usb_w + 0.6;
usb_open_t = usb_t + 0.6;
usb_mid_y = (usb_y[0] + usb_y[1]) / 2;
module usb_opening(grow = 0) {
    hull() for (s = [-1, 1])
        translate([s * (usb_open_w - usb_open_t) / 2, usb_mid_y, -1])
            cylinder(d = usb_open_t + 2 * grow, h = wall + 2);
}
// The notch in the body's bottom wall, open toward the front; the display face's tab fills
// it up to the opening.
module usb_notch(grow = 0) {
    hull() {
        usb_opening(grow);
        box([-usb_open_w / 2 - grow, usb_open_w / 2 + grow], [seam_y - 2, usb_mid_y], [-1, wall + 1]);
    }
}

// The lip around a face's back rim, as a front-view profile.
module lip_profile() {
    difference() {
        outline(wall - rebate + fit);
        outline(wall);
    }
}

// Screw column (faces) or insert boss (body), merged into the nearest corner.
module corner_profile(p, d) {
    top = p[1] > outer_h / 2;
    sx = p[0] > 0 ? 1 : -1;
    wall_z = top ? inner_top_z : wall;
    hull() {
        translate(p) circle(d = d);
        translate([sx > 0 ? p[0] : -half_in - 0.1, min(p[1], wall_z) - (top ? 0 : 0.1)])
            square([half_in + 0.1 - abs(p[0]), abs(wall_z - p[1]) + 0.1]);
        // 45-degree support under the top bosses, for printing upright
        if (top) translate([sx * (half_in + 0.05), p[1] - d / 2 * sqrt(2) - (half_in - abs(p[0]))]) square(0.1, center = true);
    }
}

// --- Body -------------------------------------------------------------------------------

module body() {
    difference() {
        union() {
            difference() {
                shell(seam_y, outer_d, back_chamfer = 1);
                along_y(seam_y - 1, inner_back_y) outline(wall);
                along_y(seam_y - 1, seam_y + rebate_depth) outline(wall - rebate);
            }
            // Insert bosses at the four corners, running to the back wall
            for (p = screw_pos) along_y(column_end_y + fit, inner_back_y + 0.1) corner_profile(p, boss_d);
            // Locating-pin bosses on the side walls, at the seam between the faces
            // (In front of the rebate's end they stop short of the wall, clear of the faces' lips.)
            for (s = [-1, 1]) intersection() {
                along_y(seam_y + fit, seam_y + pin_len + 1.5) hull() {
                    translate([s > 0 ? pin_x - 2.2 : -half_in - 0.1, display_pin_z - 2.2])
                        square([half_in + 0.1 - pin_x + 2.2, sensor_pin_z - display_pin_z + 4.4]);
                    translate([s * (half_in + 0.05), display_pin_z - 2.2 - (half_in - pin_x + 2.2)]) square(0.1, center = true);
                }
                union() {
                    box([-half_in + 0.05, half_in - 0.05], [seam_y, seam_y + rebate_depth + 0.01], [0, outer_h]);
                    box([-half_out, half_out], [seam_y + rebate_depth, outer_d], [0, outer_h]);
                }
            }
            keyhole_pockets();
            // Feet, against the wall
            for (sx = [-1, 1]) for (z = [foot_inset, outer_h - foot_inset])
                ycyl(sx * (half_out - foot_inset), z, foot_d, outer_d - 0.1, outer_d + foot_h);
        }
        usb_notch(fit);
        for (p = screw_pos) {
            ycyl(p[0], p[1], insert_hole_d, column_end_y, column_end_y + insert_depth);
            ycyl(p[0], p[1], screw_d, column_end_y, column_end_y + insert_depth + 3);
        }
        for (s = [-1, 1]) for (z = [display_pin_z, sensor_pin_z])
            ycyl(s * pin_x, z, pin_hole_d, seam_y, seam_y + pin_len + 0.6);
        keyhole_cuts();
    }
}

// Keyholes, one above the other on the centre line. A screw head goes in through the round
// hole; the unit then drops so the shank sits at the top of the slot, with the head held in a
// closed pocket inside the back wall.
module keyhole_profile(z, head, slot) {
    translate([0, z]) circle(d = head);
    hull() for (dz = [0, keyhole_slot_len]) translate([0, z + dz]) circle(d = slot);
}
module keyhole_pockets() {
    for (z = keyhole_z) {
        y0 = inner_back_y - keyhole_pocket - 1.2;
        hull() {
            along_y(y0, inner_back_y + 0.1) offset(r = 1.2) keyhole_profile(z, keyhole_head_d, keyhole_head_d);
            // 45-degree underside back to the wall, for printing upright
            along_y(inner_back_y - 0.01, inner_back_y + 0.1) translate([0, -(inner_back_y - y0)])
                offset(r = 1.2) keyhole_profile(z, keyhole_head_d, keyhole_head_d);
        }
    }
}
module keyhole_cuts() {
    for (z = keyhole_z) {
        along_y(inner_back_y - 0.01, outer_d + 1) keyhole_profile(z, keyhole_head_d, keyhole_slot_w);
        // The head's channel, with a pointed top so it prints without support
        along_y(inner_back_y - keyhole_pocket, inner_back_y + 0.01) hull() {
            keyhole_profile(z, keyhole_head_d, keyhole_head_d);
            translate([0, z + keyhole_slot_len + keyhole_head_d / 2 * sqrt(2)]) square(0.1, center = true);
        }
    }
}

// --- Faces ------------------------------------------------------------------------------

// A face's tray: front plate, outer walls from the front to the seam, and its lip.
// `lower` selects the display face (below the seam) or the sensor face (above it).
module face_tray(lower) {
    z0 = lower ? 0 : seam_z + fit / 2;
    z1 = lower ? seam_z - fit / 2 : outer_h;
    difference() {
        union() {
            intersection() {
                shell(0, seam_y, front_chamfer = 1);
                along_y(-1, seam_y + 1) zband(z0, z1);
            }
            along_y(seam_y - 0.01, seam_y + lip_len) intersection() {
                lip_profile();
                zband(z0, z1);
            }
        }
        // Hollow, open at the seam edge
        along_y(front_t, seam_y + lip_len + 1) intersection() {
            outline(wall);
            zband(lower ? wall : z0 - 1, lower ? z1 + 1 : inner_top_z);
        }
    }
}

module screw_column(p) {
    along_y(front_t - 0.01, seam_y) corner_profile(p, column_d);
    ycyl(p[0], p[1], column_d, seam_y - 0.01, column_end_y);
}

// Clearance hole and countersink for a flat-head screw, through a face and its column.
module screw_hole(p) {
    ycyl(p[0], p[1], screw_d, -1, column_end_y + 1);
    translate([p[0], -0.01, p[1]]) rotate([-90, 0, 0])
        cylinder(d1 = csk_d + 0.4, d2 = screw_d, h = (csk_d + 0.4 - screw_d) / 2);
}

module locating_pin(x, z) {
    ycyl(x, z, pin_d, seam_y - 0.01, seam_y + pin_len - 0.4);
    translate([x, seam_y + pin_len - 0.4, z]) rotate([-90, 0, 0]) cylinder(d1 = pin_d, d2 = pin_d - 0.8, h = 0.4);
}

module display_face() {
    difference() {
        union() {
            face_tray(true);
            // Below the panel: fill the slot, so the panel stops 6.5 mm above the board's bottom edge
            box([-half_in, half_in], [front_t - 0.01, rail_y], [wall - 0.01, panel_z]);
            // Rails the board rests on, behind the panel's slot
            for (s = [-1, 1]) box([s * rail_inner_x, s * (half_in + 0.01)], [rail_y - 0.01, rail_back_y], [wall - 0.01, display_pin_z - 2.0]);
            // Supports under the board's mounting holes (they stand in for the tails' 1 mm)
            for (h = board_holes) ycyl(h[0], h[1], board_support_d, rail_back_y - 0.01, board_y);
            // Blocks carrying the locating pins
            for (s = [-1, 1]) {
                box([s * (pin_x - 2.0), s * (half_in + 0.01)], [rail_y - 0.01, seam_y], [display_pin_z - 2.0, seam_z - fit / 2]);
                locating_pin(s * pin_x, display_pin_z);
            }
            for (p = screw_pos) if (p[1] < seam_z) screw_column(p);
            // Tab that fills the body's USB notch up to the receptacle
            difference() {
                box([-usb_open_w / 2, usb_open_w / 2], [seam_y - 0.01, usb_mid_y], [0, wall]);
                usb_opening();
            }
        }
        // The visible window, bevelled toward the front
        hull() {
            box([-view_w / 2, view_w / 2], [front_t - 0.01, front_t + 0.01], [view_z, view_z + view_h]);
            box([-view_w / 2 - window_bevel, view_w / 2 + window_bevel], [-0.01, 0], [view_z - window_bevel, view_z + view_h + window_bevel]);
        }
        // The panel's slot, open at the top so the panel slides in from above
        box([-half_in, half_in], [slot_y, rail_y], [panel_z, seam_z + 1]);
        // Channels under the breakout columns: header tails and wire joints stand 1.5 mm proud
        for (s = [-1, 1]) box([s * breakout_x - relief_w / 2, s * breakout_x + relief_w / 2],
                              [rail_back_y - relief_depth, board_y + 0.01], [wall + 0.5, display_pin_z - 2.0 - 0.5]);
        // Pilot holes for the board's M2 screws (stop short of the panel's slot)
        for (h = board_holes) ycyl(h[0], h[1], board_screw_pilot_d, rail_y + 0.6, board_y + 0.1);
        // Room for the USB-C plug's shell around the receptacle
        usb_opening();
        for (p = screw_pos) if (p[1] < seam_z) screw_hole(p);
    }
}

// Spring fingers that hold the can by its body; the lip passes them on the way in.
module finger(angle) {
    r_in = can_d / 2 + can_clear;
    r_out = r_in + finger_t;
    r_grip = can_body_d / 2 - finger_grip;
    L = finger_len;
    translate([0, front_t - 0.01, can_z]) rotate([-90, 0, 0]) rotate([0, 0, -angle - finger_arc / 2])
        rotate_extrude(angle = finger_arc, $fn = 96)
            polygon([[r_in, 0], [r_out, 0], [r_out, L], [r_in, L],
                     [r_grip, L - 1.0], [r_grip, L - 1.8], [r_in, L - 2.8]]);
}

module sensor_face() {
    difference() {
        union() {
            face_tray(false);
            for (a = finger_angles) finger(a);
            for (s = [-1, 1]) {
                // 45-degree top: this face prints upside down
                along_y(front_t - 0.01, seam_y) hull() {
                    translate([s > 0 ? pin_x - 2.0 : -half_in - 0.01, seam_z + fit / 2])
                        square([half_in + 0.01 - pin_x + 2.0, sensor_pin_z + 2.0 - seam_z - fit / 2]);
                    translate([s * (half_in + 0.01), sensor_pin_z + 2.0 + half_in - pin_x + 2.0]) square(0.02, center = true);
                }
                locating_pin(s * pin_x, sensor_pin_z);
            }
            for (p = screw_pos) if (p[1] > seam_z) screw_column(p);
        }
        // Grille over the can's face: a hex pattern of holes
        for (i = [-6:6]) for (j = [-6:6]) {
            x = (i + (j % 2) / 2) * grille_pitch;
            z = j * grille_pitch * sqrt(3) / 2;
            if (sqrt(x * x + z * z) <= grille_r) ycyl(x, can_z + z, grille_hole_d, -1, front_t + 1);
        }
        for (p = screw_pos) if (p[1] > seam_z) screw_hole(p);
        // A shallow ring around the grille
        difference() {
            ycyl(0, can_z, 2 * grille_r + 4.0, -1, 0.4);
            ycyl(0, can_z, 2 * grille_r + 2.4, -2, 1);
        }
    }
}
