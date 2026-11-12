// Simplified models of the purchased parts, placed where they sit in an assembled unit.
// They're for the assembly view and for collision checks, not for printing.

include <config.scad>

$fn = 48;

GLASS = [0.82, 0.83, 0.80];
INK = [0.12, 0.12, 0.13];
PCB_BLACK = [0.10, 0.10, 0.11];
PCB_GREEN = [0.10, 0.48, 0.25];
PLASTIC = [0.08, 0.08, 0.08];
METAL = [0.78, 0.79, 0.80];
CAN_BLUE = [0.25, 0.42, 0.78];
AMBER = [0.85, 0.52, 0.12];
WHITE = [0.92, 0.90, 0.84];
RED = [0.80, 0.12, 0.10];

// Box from corner ranges: box([x0, x1], [y0, y1], [z0, z1])
module box(x, y, z) {
    translate([min(x), min(y), min(z)])
        cube([abs(x[1] - x[0]), abs(y[1] - y[0]), abs(z[1] - z[0])]);
}

// Cylinder along y, centred on (x, z), from y0 to y1.
module ycyl(x, z, d, y0, y1, fn = 48) {
    translate([x, y0, z]) rotate([-90, 0, 0]) cylinder(d = d, h = y1 - y0, $fn = fn);
}

module panel() {
    color(GLASS) box([-panel_w / 2, panel_w / 2], [slot_y + 0.02, slot_y + panel_t], [panel_z, panel_top_z]);
    color(INK) box([-view_w / 2, view_w / 2], [slot_y, slot_y + 0.02], [view_z, view_z + view_h]);
}

module ribbon() {
    t = 0.15;
    y_back = board_back_y + 1.0;
    color(AMBER) {
        box([-ribbon_w / 2, ribbon_w / 2], [slot_y + 0.2, slot_y + 0.2 + t], [panel_top_z - 2, ribbon_top_z]);
        box([-ribbon_w / 2, ribbon_w / 2], [slot_y + 0.2, y_back], [ribbon_top_z - t, ribbon_top_z]);
        box([-ribbon_w / 2, ribbon_w / 2], [y_back - t, y_back], [board_top_z - 4, ribbon_top_z]);
    }
}

module driver_board() {
    color(PCB_BLACK) difference() {
        box([-board_w / 2, board_w / 2], [board_y, board_back_y], [board_z, board_top_z]);
        for (h = board_holes) ycyl(h[0], h[1], board_hole_d, board_y - 1, board_back_y + 1);
    }
    // XIAO socket tails: the board rests on these.
    color(METAL) for (s = [-1, 1]) for (i = [0:6])
        ycyl(s * socket_tail_x, board_z + socket_tail_z[0] + i * 2.54, 0.9, board_y - tail_len, board_y, 12);
    // FPC connector, battery connector and slide switch on the back
    color(WHITE) box([-8.5, 8.5], [board_back_y, board_back_y + 2.2], [board_top_z - 5, board_top_z - 0.6]);
    color(WHITE) box([-8.5, -2.0], [board_back_y, board_back_y + 7.0], [board_z + 25, board_z + 32]);
    color(METAL) box([board_w / 2 - 2, board_w / 2 + 0.7], [board_back_y, board_back_y + 2.0],
                     [board_z + switch_z[0], board_z + switch_z[1]]);
}

module xiao() {
    // The driver board's XIAO sockets, the XIAO and its USB-C receptacle
    color(PLASTIC) for (s = [-1, 1])
        box([s * socket_tail_x - 1.27, s * socket_tail_x + 1.27], [board_back_y, board_back_y + 4.7],
            [board_z + socket_tail_z[0] - 1.27, board_z + socket_tail_z[1] + 1.27]);
    usb_len = 7.35;
    usb_z0 = board_z - usb_overhang;
    color(PCB_BLACK) box([-17.8 / 2, 17.8 / 2], [usb_y[0] - 1.2, usb_y[0]], [board_z - xiao_overhang, board_z - xiao_overhang + 21]);
    color(PLASTIC) for (s = [-1, 1])
        box([s * socket_tail_x - 1.27, s * socket_tail_x + 1.27], [board_back_y + 4.7, usb_y[0] - 1.2],
            [board_z + socket_tail_z[0] - 1.27, board_z + socket_tail_z[1] + 1.27]);
    color(METAL) box([-6.5, 6.5], [usb_y[0], usb_y[0] + 2.4], [usb_z0 + 11, usb_z0 + 19]);
    color(METAL) hull() for (s = [-1, 1])
        translate([s * (usb_w - usb_t) / 2, (usb_y[0] + usb_y[1]) / 2, usb_z0])
            cylinder(d = usb_t, h = usb_len, $fn = 24);
}

// Kael's units: a 1x7 header soldered into the +x breakout column, pins toward the back.
module header() {
    color(RED) box([breakout_x - 1.27, breakout_x + 1.27], [board_back_y, board_back_y + 2.5],
                   [board_z + breakout_z[0] - 1.27, board_z + breakout_z[1] + 1.27]);
    color(METAL) for (i = [0:6]) {
        z = board_z + breakout_z[0] + i * 2.54;
        box([breakout_x - 0.32, breakout_x + 0.32], [board_y - header_tail_len, board_back_y + 8.5], [z - 0.32, z + 0.32]);
    }
}

function ze15_row_z(top) = top ? ze15_z + ze15_h - ze15_row_inset : ze15_z + ze15_row_inset;

// can_squeeze shrinks the can body, for checking against the fingers that grip it.
module ze15(can_squeeze = 0) {
    color(METAL) {
        ycyl(0, can_z, can_d, front_t, front_t + can_lip_h);
        ycyl(0, can_z, can_body_d - 2 * can_squeeze, front_t + can_lip_h, ze15_pcb_y);
    }
    color(CAN_BLUE) ycyl(0, can_z, can_body_d - 3, front_t, front_t + 0.01);
    color(PCB_GREEN) box([-ze15_w / 2, ze15_w / 2], [ze15_pcb_y, ze15_pcb_y + ze15_pcb_t], [ze15_z, ze15_z + ze15_h]);
    // Pin rows: 10 along the bottom edge, 5 along the top
    for (row = [[10, false], [5, true]]) {
        n = row[0];
        z = ze15_row_z(row[1]);
        x0 = row[1] ? -9 : -(n - 1);
        color(PLASTIC) box([x0 - 1, x0 + 2 * (n - 1) + 1], [ze15_pcb_y + ze15_pcb_t, ze15_spacer_back_y], [z - 1, z + 1]);
        color(METAL) for (i = [0:n - 1])
            box([x0 + 2 * i - 0.25, x0 + 2 * i + 0.25], [ze15_pcb_y, front_t + ze15_depth], [z - 0.25, z + 0.25]);
    }
}

// The plug on the 10-pin row, legs pointing down, with the three wires we use.
// Which end of the row carries pins 14 and 15 is still to be confirmed; this assumes +x.
module plug(wires = true) {
    z = ze15_row_z(false);
    color(PLASTIC) box([-plug_len / 2, plug_len / 2], [ze15_spacer_back_y, plug_back_y],
                       [z - plug_row_from_leg_face, z - plug_row_from_leg_face + plug_t]);
    legs = [9, 7, -5];                              // pins 15, 14 and 8 (2.0 mm pitch)
    leg_y = plug_back_y - 0.5;
    leg_bottom = z - plug_row_from_leg_face - plug_leg_len;
    color(METAL) for (x = legs) box([x - 0.25, x + 0.25], [leg_y - 0.25, leg_y + 0.25], [leg_bottom, z]);
    wire_y = leg_y + 0.25 + wire_d / 2;
    if (wires) for (i = [0:2]) {
        x = legs[i];
        tz = board_z + breakout_z[0] + 2.54 * [0, 1, 6][i];  // 5V, GND, D7
        color([[0.8, 0.1, 0.1], [0.1, 0.1, 0.1], [0.9, 0.8, 0.2]][i]) {
            hull() {
                translate([x, wire_y, leg_bottom + 1]) sphere(d = wire_d, $fn = 12);
                translate([breakout_x - 1.4 * i, wire_y, leg_bottom - 4]) sphere(d = wire_d, $fn = 12);
            }
            hull() {
                translate([breakout_x - 1.4 * i, wire_y, leg_bottom - 4]) sphere(d = wire_d, $fn = 12);
                translate([breakout_x - 1.4 * i, wire_y, tz + 1.5]) sphere(d = wire_d, $fn = 12);
            }
            hull() {
                translate([breakout_x - 1.4 * i, wire_y, tz + 1.5]) sphere(d = wire_d, $fn = 12);
                translate([breakout_x, board_back_y + 0.6, tz]) sphere(d = wire_d, $fn = 12);
            }
        }
    }
}

module display_parts(with_header = true) {
    panel();
    ribbon();
    driver_board();
    xiao();
    if (with_header) header();
}

module sensor_parts(wires = true) {
    ze15();
    plug(wires);
}

module all_components() {
    display_parts();
    sensor_parts();
}
