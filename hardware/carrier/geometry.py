"""Carrier board geometry, shared by the PCB generator (generate.py) and the mechanical
models (enclosure/). Plain Python, no KiCad dependency.

Coordinates are millimetres, origin at the board's top-left corner, x right, y down,
viewed from the top (component) side. Dimension sources and their confidence are listed
in generate.py's docstring.
"""

# --- Geometry ---------------------------------------------------------------------------

BOARD_W, BOARD_H = 61.0, 44.0
PITCH = 2.54

# Driver board: USB edge flush with the carrier's top edge, breakout rows vertical.
DRV_ORIGIN = (1.0, 0.0)  # its outline's top-left corner
DRV_W, DRV_L = 24.7, 41.6  # estimated outline
DRV_COL_INSET = 1.2  # left breakout column from the driver board's left edge (estimated)
DRV_ROW_SPACING = 22.3  # between the two breakout columns (estimated)
DRV_FIRST_HOLE = 2.68  # first hole from the USB edge (estimated)

# Breakout columns, top to bottom, as seen from the top with the USB edge up.
DRV_LEFT = ["D0", "D1", "D2", "D3", "D4", "D5", "D6"]
DRV_RIGHT = ["5V", "GND", "3V3", "D10", "D9", "D8", "D7"]

# ZE15 outline's top-left corner, in the manual's orientation (10-pin column on the
# right), beside the XIAO end of the driver board; the display FPC end stays clear.
ZE15_W, ZE15_H = 25.4, 22.3
ZE15_ORIGIN = (DRV_ORIGIN[0] + DRV_W + 3.3, 2.0)  # 3.3 mm clears the driver board's switch
CAN_CENTRE_FIG = (ZE15_W / 2, 10.8)
CAN_DIAMETER = 21.0

R1_POS = (42.0, 27.5)  # pad 1; pad 2 is 7.62 mm to the right

HOLES = [(BOARD_W - 3.2, 3.2), (BOARD_W - 3.2, BOARD_H - 3.2), (3.2, BOARD_H - 3.2),
         # Top-left corner is taken by the breakout socket; this one sits between the
         # two columns, under the XIAO.
         (DRV_ORIGIN[0] + DRV_COL_INSET + DRV_ROW_SPACING / 2, 3.2)]



def drv_pin(name):
    """Driver board breakout pin by XIAO signal name, in board coordinates."""
    x0 = DRV_ORIGIN[0] + DRV_COL_INSET
    for col, x in ((DRV_LEFT, x0), (DRV_RIGHT, x0 + DRV_ROW_SPACING)):
        if name in col:
            return (x, DRV_ORIGIN[1] + DRV_FIRST_HOLE + PITCH * col.index(name))
    raise KeyError(name)


def ze15_fig(n):
    """ZE15 pin n (1-15) in the manual's figure coordinates (top view)."""
    if n <= 5:
        return (1.3, 10.8 + 2.0 * (n - 1))
    return (1.3 + 22.8, 2.5 + 2.0 * (15 - n))


def ze15_to_board(fx, fy):
    return (ZE15_ORIGIN[0] + fx, ZE15_ORIGIN[1] + fy)


DP = {name: drv_pin(name) for name in DRV_LEFT + DRV_RIGHT}
ZP = {n: ze15_to_board(*ze15_fig(n)) for n in range(1, 16)}
R1A, R1B = R1_POS, (R1_POS[0] + 7.62, R1_POS[1])
