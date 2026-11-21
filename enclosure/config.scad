// co-sensor enclosure: every dimension in one place.
//
// Units are millimetres. Device coordinates, as the unit hangs on the wall:
//   x  width:  0 on the centre line, + to the right when looking at the front
//   y  depth:  0 at the front surface, + toward the back (the wall)
//   z  height: 0 at the bottom surface (the USB-C end), + toward the top
//
// "Measured" values come from hardware/measurements.md; change them there first.
// "Nominal" marks datasheet values that only shape the models of purchased parts.

// ---------------------------------------------------------------------------
// Measured: the display (Seeed 1.54" panel on the Seeed ePaper Driver Board V2)
// ---------------------------------------------------------------------------

panel_w = 32.0;
panel_h = 37.5;
panel_t = 1.0;
view_w = 27.0;                  // the visible crop Kael chose
view_h = 28.0;
view_above_panel_bottom = 2.0;  // window starts this far above the panel's bottom edge
panel_above_board = 6.5;        // folded panel's bottom edge above the board's bottom edge
ribbon_w = 11.9;
ribbon_above_board = 5.0;       // the folded ribbon's bend, above the board's top edge

board_w = 24.9;
board_h = 42.0;
board_t = 1.5;
board_hole_d = 2.6;
board_hole_inset = 1.85;        // hole centres from the side edges
board_hole_z = [22.9, 40.0];    // hole centres above the board's bottom edge
breakout_inset = 1.2;           // 5V...D7 and RST...D6 columns, from the side edges
breakout_z = [2.7, 18.0];       // first and last breakout hole above the bottom edge
socket_tail_x = 8.95;           // XIAO socket solder tails, from the centre line
socket_tail_z = [2.7, 18.0];
tail_len = 1.0;                 // the board rests on these tails
header_tail_len = 1.5;          // a 2.54 mm header soldered into a breakout column
switch_z = [27.4, 31.6];        // slide switch pins on the +x breakout line

usb_w = 8.94;                   // USB-C receptacle
usb_t = 3.16;
usb_overhang = 2.0;             // Kael, confirmed 2026-11-20: the receptacle's face, past the
                                // driver board's bottom edge. The XIAO's own PCB is flush with that edge.
tail_to_usb_front = 13.5;       // from the tail tips to the receptacle's front and back faces
tail_to_usb_back = 16.5;

// ---------------------------------------------------------------------------
// Measured: the sensor (Winsen ZE15-CO) and its plug (Sullins NPPN101FGGN-RC)
// ---------------------------------------------------------------------------

ze15_w = 22.3;                  // along the pin rows (mounted: x)
ze15_h = 25.4;                  // across the rows (mounted: z)
ze15_row_inset = 1.3;           // pin rows from the board edges
ze15_depth = 24.0;              // front of the can to the pin tips
sensor_depth = 26.0;            // Kael, ~26 mm: front of the can to the plug's solder, the deepest point
ze15_pcb_t = 1.6;               // nominal
ze15_pin_exposed = 3.4;         // nominal: pin length above the header's plastic strip (places the
                                // plug in the model; sensor_depth sets the enclosure's depth)
can_d = 21.0;                   // at the lip
can_body_d = 20.0;
can_lip_h = 1.2;
can_h = 17.0;                   // above the module's PCB, lip included

plug_len = 20.4;
plug_depth = 4.3;               // along the pins
plug_t = 2.8;
plug_row_from_leg_face = 1.6;   // pin row from the face the legs leave by
plug_leg_len = 3.1;
wire_d = 1.3;                   // 26 AWG, PVC

// ---------------------------------------------------------------------------
// Design
// ---------------------------------------------------------------------------

wall = 2.0;                     // sides, top and bottom
back_clear = 2.0;               // behind the sensor's deepest point: 28 mm inside depth
front_t = 1.6;                  // face plates
back_t = 2.0;
corner_r = 2.5;                 // front-view corner radius
edge_chamfer = 0.6;

foot_h = 2.0;                   // feet on the back, against the wall
foot_d = 7.0;
foot_inset = 6.0;               // foot centres from the outer edges

panel_clear = 0.3;              // each side of the panel in its slot
slot_t = 1.2;                   // the panel's slot
rail_t = 3.0;                   // the rails the board rests on, behind the slot
rail_inner_x = 7.4;             // rails reach this close to the centre line
relief_w = 2.2;                 // channels under the breakout columns
relief_depth = 1.0;
board_clear = 0.3;              // around the board's edges

window_bevel = 1.0;             // the window widens by this much at the front surface

grille_hole_d = 1.8;
grille_pitch = 2.7;
grille_r = 7.6;                 // holes within this radius of the can's centre

finger_t = 1.0;
finger_len = 8.0;
finger_arc = 40;                // degrees per finger
finger_angles = [30, 150, 210, 330];
finger_grip = 0.15;             // squeeze on the can body, per side
can_clear = 0.15;               // around the lip

seam_y = 7.5;                   // where the faces meet the body
lip_len = 1.4;                  // faces' lip, into the body's rebate
lip_t = 0.85;
rebate = 1.0;                   // body wall thinned by this much at the front rim
rebate_depth = 1.5;
fit = 0.15;                     // general sliding clearance

pin_d = 2.0;                    // locating pins, faces into the body
pin_len = 3.5;
pin_hole_d = 2.3;
pin_from_seam = 3.0;            // above and below the seam between the faces

screw_x = 15.2;                 // M2 corner screws, faces into the body
screw_from_edge = 4.5;          // from the bottom or top surface
screw_d = 2.3;                  // clearance
csk_d = 4.2;                    // countersink for an M2 flat head
insert_hole_d = 3.2;            // M2 heat-set insert
insert_depth = 4.5;
column_d = 4.0;                 // the faces' screw columns
boss_d = 5.2;                   // the body's insert bosses
column_end_y = 9.0;             // faces' columns end here; the body's bosses start here

board_screw_pilot_d = 1.7;      // M2 thread-forming screws into the rails
board_support_d = 4.4;

keyhole_head_d = 8.6;           // #6 / #8 pan head or M4
keyhole_slot_w = 4.6;
keyhole_slot_len = 6.0;
keyhole_pocket = 3.2;           // room for the screw head inside the back wall
keyhole_z = [10.0, 30.0];       // entry hole centres, on the centre line (one above the other)

// ---------------------------------------------------------------------------
// Derived layout (don't edit; change the values above)
// ---------------------------------------------------------------------------

inner_w = panel_w + 2 * panel_clear;
outer_w = inner_w + 2 * wall;
half_in = inner_w / 2;
half_out = outer_w / 2;

// Heights
usb_recess = 0.3;                                 // receptacle face inside the bottom surface
board_z = usb_recess + usb_overhang;              // the driver board's bottom edge
board_top_z = board_z + board_h;
panel_z = board_z + panel_above_board;
panel_top_z = panel_z + panel_h;
view_z = panel_z + view_above_panel_bottom;
ribbon_top_z = board_top_z + ribbon_above_board;
seam_z = ribbon_top_z + 0.5;                      // between the display and sensor faces
ze15_z = seam_z + 0.3;                            // the sensor's PCB, bottom edge: wholly above
can_z = ze15_z + ze15_h / 2;                      // the seam, so either face can come off alone
inner_top_z = ze15_z + ze15_h + 0.4;
outer_h = inner_top_z + wall;

// Depths
slot_y = front_t;
rail_y = slot_y + slot_t;
rail_back_y = rail_y + rail_t;
board_y = rail_back_y + tail_len;                // the board's front face
board_back_y = board_y + board_t;
usb_y = [rail_back_y + tail_to_usb_front, rail_back_y + tail_to_usb_back];
ze15_pcb_y = front_t + can_h;
ze15_spacer_back_y = front_t + ze15_depth - ze15_pin_exposed;
plug_back_y = ze15_spacer_back_y + plug_depth;
inner_back_y = front_t + sensor_depth + back_clear;
outer_d = inner_back_y + back_t;

// Holes and screws
board_holes = [for (z = board_hole_z) for (s = [-1, 1])
               [s * (board_w / 2 - board_hole_inset), board_z + z]];
breakout_x = board_w / 2 - breakout_inset;
screw_pos = [for (s = [-1, 1]) for (z = [screw_from_edge, outer_h - screw_from_edge]) [s * screw_x, z]];
pin_x = screw_x - 0.2;
display_pin_z = seam_z - pin_from_seam;
sensor_pin_z = seam_z + pin_from_seam;

assert(board_z >= wall + 0.3, "the driver board and XIAO would hit the bottom wall");
assert(plug_back_y + wire_d <= front_t + sensor_depth + 0.5, "the modelled plug is deeper than the measured sensor");

echo(str("co-sensor enclosure: ", outer_w, " W x ", outer_h, " H x ", outer_d,
         " D mm (", outer_d + foot_h, " with feet)"));
