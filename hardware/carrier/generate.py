"""Generates the co-sensor carrier board (co-sensor-carrier.kicad_pcb).

The carrier is the base of a unit. Seeed's ePaper Driver Board (with the XIAO ESP32-C6
in its socket) plugs into it like a shield, through male headers soldered into the
driver board's two breakout rows, and the Winsen ZE15-CO plugs in beside it. Nothing is
soldered to the XIAO, the driver board's circuitry or the sensor. Without a panel this
is an M1 unit; connect a panel to the driver board's FPC and it becomes M3, with no new
board.

This script is the source of truth: geometry, nets and routing live here, and the
.kicad_pcb is regenerated from it with `make carrier` (KiCad's Docker image provides
the pcbnew module).

Coordinates are millimetres, origin at the board's top-left corner, x right, y down,
viewed from the top (component) side.

Sources and confidence:
- Driver board breakout rows (CN1/CN2): Seeed's schematic and silkscreen give the pin
  order. Geometry is ESTIMATED from Seeed's product photo, scaled by the known 2.54 mm
  pitch: rows ~22.3 mm apart, first holes ~2.7 mm from the USB edge, board ~24.7 x 41.6.
- ZE15-CO: Winsen manual v1.2, figure 1, read as a TOP view. Outline 25.4 x 22.3; a
  10-pin column 1.3 from one edge, first pin 2.5 from the top; a 5-pin column 22.8
  across, first pin 10.8 from the top; 2.0 mm pitch.
Both are confirmed by the printed footprint check (`make carrier-check`) before ordering.
"""

import os

import pcbnew

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "co-sensor-carrier.kicad_pcb")
FP_LIB = "/usr/share/kicad/footprints"
VERSION = "v0.2"

# Board origin on the KiCad page, so plots land on the sheet.
OX, OY = 50.0, 50.0

# Geometry lives in geometry.py, shared with the mechanical models.
from geometry import (  # noqa: E402
    BOARD_H, BOARD_W, CAN_CENTRE_FIG, CAN_DIAMETER, DP, DRV_COL_INSET, DRV_L, DRV_ORIGIN,
    DRV_ROW_SPACING, DRV_W, HOLES, R1A, R1B, ZE15_H, ZE15_ORIGIN, ZE15_W, ZP, ze15_to_board,
)

POWER_W, SIGNAL_W = 0.5, 0.25

# --- Connectivity -----------------------------------------------------------------------
# Net -> pad positions it owns. Pads are matched to nets by position after placement,
# so footprint pad numbering never matters.

NETS = {
    "+5V": [DP["5V"], ZP[15]],
    "GND": [DP["GND"], ZP[14]],
    "D7_CO_TXD": [DP["D7"], ZP[8]],  # ZE15 TXD -> XIAO RX (D7)
    "D6": [DP["D6"], R1A],  # XIAO TX (D6) -> R1
    "CO_RXD": [R1B, ZP[7]],  # R1 -> ZE15 RXD; R1 optional, firmware doesn't transmit
}

# Routing: (net, layer, width, waypoints), derived from pin positions so moving a part
# moves its traces with it.
TEN_COL_X = ZP[15][0]
BELOW_ZE15_Y = ZE15_ORIGIN[1] + ZE15_H - 0.3  # under the module's bottom edge
LEFT_OF_TEN = TEN_COL_X - 1.5  # channel just left of the 10-pin column
RIGHT_OF_TEN = TEN_COL_X + 1.5  # ... and just right of it
D6_LANE_Y = 29.0  # bottom-layer lane under the driver board

ROUTES = [
    # Power straight across the top, under the ZE15 module
    ("+5V", "F", POWER_W, [DP["5V"], (TEN_COL_X - (ZP[15][1] - DP["5V"][1]), DP["5V"][1]), ZP[15]]),
    ("GND", "F", POWER_W, [DP["GND"], (DP["GND"][0] + 2.5, DP["GND"][1]),
                          (DP["GND"][0] + 2.5 + (ZP[14][1] - DP["GND"][1]), ZP[14][1]), ZP[14]]),
    # ZE15 TXD -> D7: down past the 5-pin column, along the module's bottom edge, up the
    # channel left of the 10-pin column
    ("D7_CO_TXD", "F", SIGNAL_W, [DP["D7"], (DP["D7"][0], BELOW_ZE15_Y - 1.0),
                                  (DP["D7"][0] + 1.0, BELOW_ZE15_Y), (LEFT_OF_TEN, BELOW_ZE15_Y),
                                  (LEFT_OF_TEN, ZP[8][1] + 1.5), ZP[8]]),
    # D6 -> R1 under the driver board (bottom layer), R1 -> ZE15 RXD up the right channel
    ("D6", "B", SIGNAL_W, [DP["D6"], (DP["D6"][0] + 1.3, DP["D6"][1] + 1.3),
                           (DP["D6"][0] + 1.3, D6_LANE_Y), (R1A[0] - 1.5, D6_LANE_Y), R1A]),
    ("CO_RXD", "B", SIGNAL_W, [R1B, (RIGHT_OF_TEN, R1B[1]), (RIGHT_OF_TEN, ZP[7][1] + 1.5), ZP[7]]),
]

# --- Build ------------------------------------------------------------------------------


def mm(v):
    return pcbnew.FromMM(v)


def pt(p):
    return pcbnew.VECTOR2I(mm(OX + p[0]), mm(OY + p[1]))


def load(lib, name):
    fp = pcbnew.FootprintLoad(os.path.join(FP_LIB, lib + ".pretty"), name)
    assert fp is not None, f"footprint {lib}:{name} not found"
    return fp


def place(board, lib, name, ref, value, at, angle=0.0):
    fp = load(lib, name)
    fp.SetReference(ref)
    fp.SetValue(value)
    fp.SetPosition(pt(at))
    fp.SetOrientationDegrees(angle)
    fp.Reference().SetVisible(False)
    fp.Value().SetVisible(False)
    board.Add(fp)
    return fp


def add_shape(board, shape, layer, start, end, width=0.12):
    s = pcbnew.PCB_SHAPE(board)
    s.SetShape(shape)
    s.SetLayer(layer)
    s.SetStart(pt(start))
    s.SetEnd(pt(end))
    s.SetWidth(mm(width))
    board.Add(s)


def add_rect(board, layer, top_left, bottom_right, width=0.12):
    add_shape(board, pcbnew.SHAPE_T_RECT, layer, top_left, bottom_right, width)


def add_circle(board, layer, centre, radius, width=0.12):
    add_shape(board, pcbnew.SHAPE_T_CIRCLE, layer, centre, (centre[0] + radius, centre[1]), width)


def add_line(board, layer, start, end, width=0.12):
    add_shape(board, pcbnew.SHAPE_T_SEGMENT, layer, start, end, width)


def add_text(board, layer, text, at, size=1.0, angle=0.0):
    t = pcbnew.PCB_TEXT(board)
    t.SetText(text)
    t.SetLayer(layer)
    t.SetPosition(pt(at))
    t.SetTextSize(pcbnew.VECTOR2I(mm(size), mm(size)))
    t.SetTextThickness(mm(size * 0.15))
    t.SetTextAngleDegrees(angle)
    board.Add(t)


def build():
    board = pcbnew.NewBoard(OUT)
    tb = board.GetTitleBlock()
    tb.SetTitle("co-sensor carrier")
    tb.SetRevision(VERSION)
    tb.SetComment(0, "Seeed ePaper Driver Board (with XIAO ESP32-C6) + Winsen ZE15-CO, socketed")

    nets = {}
    for name in NETS:
        net = pcbnew.NETINFO_ITEM(board, name)
        board.Add(net)
        nets[name] = net

    add_rect(board, pcbnew.Edge_Cuts, (0, 0), (BOARD_W, BOARD_H), width=0.1)
    for i, h in enumerate(HOLES, 1):
        place(board, "MountingHole", "MountingHole_2.7mm_M2.5", f"H{i}", "M2.5", h)

    # Driver board breakout sockets (vertical footprints: pin 1 at the top)
    place(board, "Connector_PinSocket_2.54mm", "PinSocket_1x07_P2.54mm_Vertical", "J1",
          "Driver board D0-D6", DP["D0"])
    place(board, "Connector_PinSocket_2.54mm", "PinSocket_1x07_P2.54mm_Vertical", "J2",
          "Driver board 5V-D7", DP["5V"])

    # ZE15 sockets. Socket pin 1 (square pad) sits on ZE15 pins 6 and 1, matching the
    # module's own square pads, so the printed check doubles as an orientation check.
    place(board, "Connector_PinSocket_2.00mm", "PinSocket_1x10_P2.00mm_Vertical", "J3",
          "ZE15 pins 6-15", ZP[6], angle=180)
    place(board, "Connector_PinSocket_2.00mm", "PinSocket_1x05_P2.00mm_Vertical", "J4",
          "ZE15 pins 1-5", ZP[1])

    place(board, "Resistor_THT", "R_Axial_DIN0207_L6.3mm_D2.5mm_P7.62mm_Horizontal", "R1",
          "1k (optional)", R1A)

    assign_nets(board, nets)
    for net, layer, width, waypoints in ROUTES:
        route(board, nets[net], pcbnew.F_Cu if layer == "F" else pcbnew.B_Cu, width, waypoints)

    draw_graphics(board)
    pcbnew.SaveBoard(OUT, board)
    print(f"wrote {OUT}")


def assign_nets(board, nets):
    owners = {}
    for name, positions in NETS.items():
        for p in positions:
            owners[(round(p[0], 2), round(p[1], 2))] = name
    matched = set()
    for fp in board.GetFootprints():
        for pad in fp.Pads():
            pos = pad.GetPosition()
            key = (round(pcbnew.ToMM(pos.x) - OX, 2), round(pcbnew.ToMM(pos.y) - OY, 2))
            if key in owners:
                pad.SetNet(nets[owners[key]])
                matched.add(key)
    missing = set(owners) - matched
    assert not missing, f"net positions with no pad (placement bug): {sorted(missing)}"


def route(board, net, layer, width, waypoints):
    for a, b in zip(waypoints, waypoints[1:]):
        t = pcbnew.PCB_TRACK(board)
        t.SetStart(pt(a))
        t.SetEnd(pt(b))
        t.SetWidth(mm(width))
        t.SetLayer(layer)
        t.SetNet(net)
        board.Add(t)


def draw_graphics(board):
    silk, fab = pcbnew.F_SilkS, pcbnew.F_Fab

    # Driver board outline and labels
    dx, dy = DRV_ORIGIN
    add_rect(board, fab, (dx, dy), (dx + DRV_W, dy + DRV_L))
    mid = dx + DRV_COL_INSET + DRV_ROW_SPACING / 2
    add_text(board, silk, "USB-C", (mid, 6.6), size=1.0)
    add_text(board, silk, "ePaper Driver Board", (mid, 9.2), size=1.0)
    add_text(board, silk, "+ XIAO ESP32-C6", (mid, 10.9), size=1.0)
    add_text(board, silk, "display FPC end", (mid, dy + DRV_L - 3.0), size=0.9)
    for name in ("D0", "D6"):
        x, y = DP[name]
        add_text(board, silk, name, (x + 2.4, y), size=0.8)
    for name in ("5V", "D7"):
        x, y = DP[name]
        add_text(board, silk, name, (x - 2.4, y), size=0.8)

    # ZE15 outline and can
    zx, zy = ZE15_ORIGIN
    add_rect(board, fab, (zx, zy), (zx + ZE15_W, zy + ZE15_H))
    can = ze15_to_board(*CAN_CENTRE_FIG)
    add_circle(board, fab, can, CAN_DIAMETER / 2)
    add_text(board, silk, "ZE15-CO", (can[0], can[1] - 2.0), size=1.4)
    add_text(board, silk, "can up - sockets only", (can[0], can[1]), size=0.9)
    add_text(board, silk, "never solder the module", (can[0], can[1] + 1.6), size=0.9)
    for n in range(1, 16):  # pin numbers for the footprint check
        x, y = ZP[n]
        add_text(board, fab, str(n), (x + 1.6 if n <= 5 else x - 1.6, y), size=0.8)
    for n, dx_ in ((1, -1.7), (6, 1.7)):  # the module's square-pad pins
        x, y = ZP[n]
        add_text(board, silk, str(n), (x + dx_, y), size=0.8)

    add_text(board, silk, "R1 1k opt.", ((R1A[0] + R1B[0]) / 2, R1A[1] + 2.0), size=0.8)
    add_text(board, silk, f"co-sensor carrier {VERSION}", (41.5, BOARD_H - 2.0), size=1.0)

    # Scale bar and instructions for the printed footprint check (not fabricated)
    drw = pcbnew.Dwgs_User
    y = BOARD_H + 8.0
    add_line(board, drw, (0, y), (50.0, y), width=0.3)
    for x in (0, 50.0):
        add_line(board, drw, (x, y - 1.5), (x, y + 1.5), width=0.3)
    add_text(board, drw, "This line must measure exactly 50 mm (print at 100%, no scaling)",
             (30.0, y + 3.0), size=1.5)
    add_text(board, drw, "Place parts pins-down on this page, as they'd sit on the board",
             (30.0, y + 6.0), size=1.5)


if __name__ == "__main__":
    build()
