"""3D model of an assembled co-sensor unit, without the enclosure.

Builds simplified solids for every part at its real position, taking the board layout
from hardware/carrier/geometry.py (the same source the PCB is generated from), and
writes to build/:

- assembly.step  every part, coloured, for any CAD tool (and the enclosure design)
- assembly.glb   the same, for web/3D viewers
- assembly-*.png sketch renders (see render.py)

Run with `make assembly`. Heights are from datasheets where known; the rest (marked
"est.") are estimates from product photos, good enough for a sketch and for sizing the
enclosure, and get confirmed when the parts arrive.
"""

import os
import sys

import cadquery as cq

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(HERE)
sys.path.insert(0, os.path.join(REPO, "hardware", "carrier"))
sys.path.insert(0, HERE)

import geometry as g  # noqa: E402
from render import render  # noqa: E402

OUT_DIR = os.path.join(REPO, "build")

# --- Stack heights (z = 0 at the carrier's underside) -----------------------------------

PCB_T = 1.6
SOCKET_254_H = 8.5  # standard 0.1" female header
HEADER_SPACER_H = 2.5  # male header's plastic spacer, under the driver board
SOCKET_200_H = 4.3  # 2.0 mm female socket (est.)
ZE15_COLLAR_H = 2.2  # plastic collars on the ZE15's pins (manual, side view)
ZE15_PCB_T = 1.2
CAN_H, CAN_D, CAN_LIP_D, CAN_LIP_H = 17.0, 20.0, 21.0, 1.2  # manual: 17 mm above the module PCB
XIAO_SOCKET_H = 4.6  # driver board's XIAO socket (est.)
XIAO_W, XIAO_L, XIAO_T = 17.8, 21.0, 1.2
PANEL_W, PANEL_L, PANEL_T = 31.8, 37.32, 1.05  # 1.54" 200x200 panel glass (typical GDEY0154D67)
PANEL_GAP = 4.0  # clearance above the tallest part (illustrative; the enclosure decides)

CARRIER_TOP = PCB_T
DRV_BOTTOM = CARRIER_TOP + SOCKET_254_H + HEADER_SPACER_H
DRV_TOP = DRV_BOTTOM + PCB_T
XIAO_BOTTOM = DRV_TOP + XIAO_SOCKET_H
ZE15_PCB_BOTTOM = CARRIER_TOP + SOCKET_200_H + ZE15_COLLAR_H
CAN_BASE = ZE15_PCB_BOTTOM + ZE15_PCB_T

# Colours (RGB 0-1)
GREEN, BLACK, MATTE = (0.12, 0.42, 0.22), (0.10, 0.10, 0.11), (0.16, 0.16, 0.18)
SILVER, GOLD, BEIGE = (0.78, 0.79, 0.80), (0.85, 0.68, 0.25), (0.88, 0.82, 0.68)
WHITE, BLUE, AMBER = (0.93, 0.93, 0.90), (0.20, 0.38, 0.75), (0.85, 0.52, 0.12)
GLASS, INK = (0.80, 0.81, 0.79), (0.93, 0.93, 0.91)


def box(x0, y0, x1, y1, z0, z1):
    """Axis-aligned box from board coordinates (x right, y down) and heights.

    CAD space is x right, y up, z up, so board y is negated: the top view matches the PCB.
    """
    xa, xb = sorted((x0, x1))
    ya, yb = sorted((-y0, -y1))
    return cq.Workplane("XY").box(xb - xa, yb - ya, z1 - z0, centered=False).translate((xa, ya, z0))


def cylinder(cx, cy, d, z0, z1):
    return cq.Workplane("XY").circle(d / 2).extrude(z1 - z0).translate((cx, -cy, z0))


def column_box(x, y_first, y_last, width, z0, z1, pitch):
    """A pin strip's body around a column of pins at x, from the first to the last pin."""
    ya, yb = sorted((y_first, y_last))
    return box(x - width / 2, ya - pitch / 2, x + width / 2, yb + pitch / 2, z0, z1)


def build_parts(with_panel=True):
    parts = []  # (name, workplane, colour)

    # Carrier PCB with its mounting holes
    carrier = box(0, 0, g.BOARD_W, g.BOARD_H, 0, PCB_T)
    for hx, hy in g.HOLES:
        carrier = carrier.cut(cylinder(hx, hy, 2.7, -1, PCB_T + 1))
    parts.append(("carrier PCB", carrier, GREEN))

    # Driver board sockets on the carrier, and the male headers' spacers above them
    for col in (g.DRV_LEFT, g.DRV_RIGHT):
        x, y0 = g.DP[col[0]]
        y1 = g.DP[col[-1]][1]
        parts.append(("driver socket", column_box(x, y0, y1, 2.54, CARRIER_TOP, CARRIER_TOP + SOCKET_254_H, g.PITCH), BLACK))
        parts.append(("header spacer", column_box(x, y0, y1, 2.54, DRV_BOTTOM - HEADER_SPACER_H, DRV_BOTTOM, g.PITCH), MATTE))

    # ePaper Driver Board
    dx, dy = g.DRV_ORIGIN
    parts.append(("driver board", box(dx, dy, dx + g.DRV_W, dy + g.DRV_L, DRV_BOTTOM, DRV_TOP), MATTE))
    mid = dx + g.DRV_COL_INSET + g.DRV_ROW_SPACING / 2
    first, last = g.DP["D0"][1], g.DP["D6"][1]
    for x in (mid - 7.62, mid + 7.62):  # XIAO socket rows
        parts.append(("xiao socket", column_box(x, first, last, 2.54, DRV_TOP, XIAO_BOTTOM, g.PITCH), BLACK))
    end = dy + g.DRV_L
    parts.append(("FPC connector", box(mid - 8.5, end - 4.6, mid + 8.5, end - 0.8, DRV_TOP, DRV_TOP + 2.0), BEIGE))
    parts.append(("FPC latch", box(mid - 8.5, end - 1.4, mid + 8.5, end - 0.4, DRV_TOP, DRV_TOP + 2.3), MATTE))
    parts.append(("BAT connector", box(dx + 2.5, end - 15.5, dx + 8.5, end - 10.9, DRV_TOP, DRV_TOP + 6.0), WHITE))
    parts.append(("inductor", box(mid - 1.0, 22.0, mid + 3.0, 26.0, DRV_TOP, DRV_TOP + 2.0), (0.35, 0.35, 0.36)))
    parts.append(("charger IC", box(mid + 4.0, 22.5, mid + 7.0, 25.5, DRV_TOP, DRV_TOP + 1.0), BLACK))
    parts.append(("power switch", box(dx + g.DRV_W - 2.0, 28.0, dx + g.DRV_W + 1.4, 34.5, DRV_TOP, DRV_TOP + 1.5), SILVER))

    # XIAO ESP32-C6, USB end at the board edge
    xy = (first + last) / 2
    parts.append(("XIAO", box(mid - XIAO_W / 2, xy - XIAO_L / 2, mid + XIAO_W / 2, xy + XIAO_L / 2,
                              XIAO_BOTTOM, XIAO_BOTTOM + XIAO_T), (0.10, 0.11, 0.14)))
    xt = XIAO_BOTTOM + XIAO_T
    parts.append(("USB-C", box(mid - 4.45, xy - XIAO_L / 2 - 1.5, mid + 4.45, xy - XIAO_L / 2 + 5.9, xt, xt + 3.2), SILVER))
    parts.append(("ESP32-C6", box(mid - 3.5, xy - 1.0, mid + 3.5, xy + 6.0, xt, xt + 0.9), BLACK))
    parts.append(("antenna", box(mid - 1.5, xy + 7.5, mid + 1.5, xy + 9.5, xt, xt + 1.0), (0.55, 0.45, 0.30)))

    # ZE15-CO: sockets, pin collars, module PCB, can
    for pins in ((6, 15), (1, 5)):
        x, y0 = g.ZP[pins[0]]
        y1 = g.ZP[pins[1]][1]
        parts.append(("ze15 socket", column_box(x, y0, y1, 2.0, CARRIER_TOP, CARRIER_TOP + SOCKET_200_H, 2.0), BLACK))
        parts.append(("ze15 collars", column_box(x, y0, y1, 1.4, CARRIER_TOP + SOCKET_200_H, ZE15_PCB_BOTTOM, 2.0), MATTE))
    zx, zy = g.ZE15_ORIGIN
    parts.append(("ZE15 PCB", box(zx, zy, zx + g.ZE15_W, zy + g.ZE15_H, ZE15_PCB_BOTTOM, CAN_BASE), (0.10, 0.50, 0.25)))
    cx, cy = g.ze15_to_board(*g.CAN_CENTRE_FIG)
    can_top = CAN_BASE + CAN_H
    parts.append(("ZE15 can", cylinder(cx, cy, CAN_D, CAN_BASE, can_top - CAN_LIP_H), SILVER))
    parts.append(("ZE15 lip", cylinder(cx, cy, CAN_LIP_D, can_top - CAN_LIP_H, can_top), SILVER))
    parts.append(("ZE15 cap", cylinder(cx, cy, CAN_D - 2.0, can_top, can_top + 0.3), BLUE))

    if with_panel:
        # 1.54" panel above the driver board, its FPC looping back to the connector.
        # Position is illustrative; the enclosure decides where the panel sits.
        pz = max(can_top, xt + 3.2) + PANEL_GAP
        py0, py1 = xy - PANEL_L / 2 + 1.5, xy + PANEL_L / 2 + 1.5
        parts.append(("panel", box(mid - PANEL_W / 2, py0, mid + PANEL_W / 2, py1, pz, pz + PANEL_T), GLASS))
        parts.append(("panel face", box(mid - 13.8, py0 + 2.5, mid + 13.8, py0 + 30.1, pz + PANEL_T, pz + PANEL_T + 0.05), INK))
        loop = end + 2.5
        fw = 6.0  # FPC half-width
        parts.append(("FPC", box(mid - fw, py1, mid + fw, loop, pz + 0.3, pz + 0.45), AMBER))
        parts.append(("FPC", box(mid - fw, loop - 0.15, mid + fw, loop, DRV_TOP + 1.0, pz + 0.45), AMBER))
        parts.append(("FPC", box(mid - fw, end - 3.0, mid + fw, loop, DRV_TOP + 1.0, DRV_TOP + 1.15), AMBER))

    return parts


LABELS = {  # part name -> label for the annotated render
    "carrier PCB": "carrier board (ours)",
    "driver board": "Seeed ePaper Driver Board",
    "XIAO": "XIAO ESP32-C6",
    "ZE15 lip": "Winsen ZE15-CO",
    "panel": '1.54" e-paper panel',
    "USB-C": "USB-C",
}


def export(parts, stem):
    assy = cq.Assembly(name="co-sensor")
    for i, (name, wp, colour) in enumerate(parts):
        assy.add(wp, name=f"{i:02d} {name}", color=cq.Color(*colour))
    for ext in ("step", "glb"):
        path = os.path.join(OUT_DIR, f"{stem}.{ext}")
        assy.export(path)
        print(f"wrote {path}")


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    full = build_parts(with_panel=True)
    boards = build_parts(with_panel=False)
    export(full, "assembly")

    shots = [
        ("assembly-iso.png", full, dict(azimuth=-55, elevation=28,
                                        title="Assembled unit with display (M3), panel position illustrative")),
        ("assembly-iso-no-panel.png", boards, dict(azimuth=-55, elevation=28, title="Without the panel (M2)")),
        ("assembly-usb-end.png", full, dict(azimuth=140, elevation=22, title="From the USB end")),
        ("assembly-top.png", boards, dict(azimuth=-90, elevation=89.9, title="Top view, without the panel")),
    ]
    for filename, parts, view in shots:
        path = os.path.join(OUT_DIR, filename)
        render([(wp.val(), colour, LABELS.get(name)) for name, wp, colour in parts], path, **view)
        print(f"wrote {path}")


if __name__ == "__main__":
    main()
