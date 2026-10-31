"""Minimal headless renderer for CadQuery shapes.

Orthographic, z-buffered, flat-shaded faces with dark outline edges and optional labels,
like a technical sketch. Pure numpy + Pillow, so it runs in a container with no display
or OpenGL. It's meant for documentation sketches, not photorealism.
"""

import math

import numpy as np
from OCP.TopAbs import TopAbs_EDGE, TopAbs_FACE
from OCP.TopExp import TopExp
from OCP.TopTools import TopTools_IndexedDataMapOfShapeListOfShape
from PIL import Image, ImageDraw, ImageFont

SUPERSAMPLE = 2
BACKGROUND = (255, 255, 255)
EDGE_DEPTH_BIAS = 0.15  # mm: edges on a visible face's boundary pass the depth test


def _camera(azimuth, elevation):
    az, el = math.radians(azimuth), math.radians(elevation)
    to_cam = np.array([math.cos(el) * math.cos(az), math.cos(el) * math.sin(az), math.sin(el)])
    right = np.cross([0.0, 0.0, 1.0], to_cam)
    right = right / np.linalg.norm(right) if np.linalg.norm(right) > 1e-9 else np.array([1.0, 0, 0])
    up = np.cross(to_cam, right)
    return right, up, to_cam


def _tessellate(shape):
    verts, tris = shape.tessellate(0.05, 0.2)
    v = np.array([[p.x, p.y, p.z] for p in verts], dtype=float)
    return v, np.array(tris, dtype=int).reshape(-1, 3)


def _visible_edges(shape, step=0.4):
    """Polylines for each edge, skipping cylinder seams (edges with only one face)."""
    emap = TopTools_IndexedDataMapOfShapeListOfShape()
    TopExp.MapShapesAndAncestors_s(shape.wrapped, TopAbs_EDGE, TopAbs_FACE, emap)
    seams = set()
    for i in range(1, emap.Extent() + 1):
        faces = emap.FindFromIndex(i)
        distinct = {f.__hash__() for f in faces}
        if len(distinct) < 2:
            seams.add(emap.FindKey(i).__hash__())
    lines = []
    for e in shape.Edges():
        if e.wrapped.__hash__() in seams:
            continue
        n = 2 if e.geomType() == "LINE" else max(8, int(e.Length() / step))
        pts = [e.positionAt(t) for t in np.linspace(0, 1, n)]
        lines.append(np.array([[p.x, p.y, p.z] for p in pts]))
    return lines


def render(items, path, azimuth=-55, elevation=28, width=1800, height=1100, title=None):
    """items: [(cadquery Shape, (r, g, b) in 0-1, label or None)]"""
    right, up, to_cam = _camera(azimuth, elevation)
    light = to_cam + 0.9 * np.array([0, 0, 1.0]) - 0.4 * right
    light /= np.linalg.norm(light)

    meshes = [(_tessellate(s), np.array(c), label, s) for s, c, label in items]
    allv = np.vstack([m[0][0] for m in meshes])
    u, v = allv @ right, allv @ up
    W, H = width * SUPERSAMPLE, height * SUPERSAMPLE
    # Leave side margins for the label columns.
    scale = min(0.56 * W / np.ptp(u), 0.78 * H / np.ptp(v))
    u0 = (u.min() + u.max()) / 2
    v0 = (v.min() + v.max()) / 2

    def project(p):
        pu, pv, pw = p @ right, p @ up, p @ to_cam
        return (pu - u0) * scale + W / 2, H / 2 - (pv - v0) * scale, pw

    img = np.empty((H, W, 3), dtype=float)
    img[:] = np.array(BACKGROUND) / 255.0
    zbuf = np.full((H, W), -np.inf)

    for (verts, tris), colour, _, _ in meshes:
        px, py, pw = project(verts)
        for a, b, c in tris:
            n = np.cross(verts[b] - verts[a], verts[c] - verts[a])
            nn = np.linalg.norm(n)
            if nn < 1e-12:
                continue
            shade = 0.38 + 0.62 * abs(np.dot(n / nn, light))
            _raster(px[[a, b, c]], py[[a, b, c]], pw[[a, b, c]], np.clip(colour * shade, 0, 1), img, zbuf)

    for (_, _), colour, _, shape in meshes:
        edge_colour = np.clip(colour * 0.3, 0, 1)
        for line in _visible_edges(shape):
            ex, ey, ew = project(line)
            _draw_polyline(ex, ey, ew, edge_colour, img, zbuf)

    anchors = _visible_anchors(meshes, project, zbuf)
    out = Image.fromarray((img * 255).astype(np.uint8)).resize((width, height), Image.LANCZOS)
    _annotate(out, [(x / SUPERSAMPLE, y / SUPERSAMPLE, label) for x, y, label in anchors], allv, title)
    out.save(path)


def _visible_anchors(meshes, project, zbuf):
    """For each labelled part, a point of it that's actually visible in this view (the
    visible triangle centroid nearest the middle of its visible area), or nothing."""
    H, W = zbuf.shape
    anchors = []
    for (verts, tris), _, label, _ in meshes:
        if not label:
            continue
        cent = verts[tris].mean(axis=1)
        px, py, pw = project(cent)
        ix, iy = px.astype(int), py.astype(int)
        ok = (ix >= 0) & (ix < W) & (iy >= 0) & (iy < H)
        vis = np.zeros(len(cent), dtype=bool)
        vis[ok] = pw[ok] >= zbuf[iy[ok], ix[ok]] - 0.05
        if not vis.any():
            continue
        vx, vy = px[vis], py[vis]
        i = np.argmin((vx - vx.mean()) ** 2 + (vy - vy.mean()) ** 2)
        anchors.append((vx[i], vy[i], label))
    return anchors


def _raster(xs, ys, ws, colour, img, zbuf):
    H, W = zbuf.shape
    x0, x1 = max(int(math.floor(xs.min())), 0), min(int(math.ceil(xs.max())), W - 1)
    y0, y1 = max(int(math.floor(ys.min())), 0), min(int(math.ceil(ys.max())), H - 1)
    if x0 > x1 or y0 > y1:
        return
    area = (xs[1] - xs[0]) * (ys[2] - ys[0]) - (xs[2] - xs[0]) * (ys[1] - ys[0])
    if abs(area) < 1e-9:
        return
    X, Y = np.meshgrid(np.arange(x0, x1 + 1) + 0.5, np.arange(y0, y1 + 1) + 0.5)
    w0 = ((xs[1] - X) * (ys[2] - Y) - (xs[2] - X) * (ys[1] - Y)) / area
    w1 = ((xs[2] - X) * (ys[0] - Y) - (xs[0] - X) * (ys[2] - Y)) / area
    w2 = 1.0 - w0 - w1
    inside = (w0 >= -1e-6) & (w1 >= -1e-6) & (w2 >= -1e-6)
    z = w0 * ws[0] + w1 * ws[1] + w2 * ws[2]
    zb = zbuf[y0:y1 + 1, x0:x1 + 1]
    m = inside & (z > zb)
    zb[m] = z[m]
    img[y0:y1 + 1, x0:x1 + 1][m] = colour


def _draw_polyline(xs, ys, ws, colour, img, zbuf):
    H, W = zbuf.shape
    for i in range(len(xs) - 1):
        n = int(max(abs(xs[i + 1] - xs[i]), abs(ys[i + 1] - ys[i]))) + 2
        t = np.linspace(0, 1, n)
        sx = xs[i] + (xs[i + 1] - xs[i]) * t
        sy = ys[i] + (ys[i + 1] - ys[i]) * t
        sw = ws[i] + (ws[i + 1] - ws[i]) * t
        for dx in (0, 1):  # 2 px wide at supersample scale
            ix, iy = (sx + dx).astype(int), sy.astype(int)
            ok = (ix >= 0) & (ix < W) & (iy >= 0) & (iy < H)
            ix, iy, iw = ix[ok], iy[ok], sw[ok]
            vis = iw >= zbuf[iy, ix] - EDGE_DEPTH_BIAS
            img[iy[vis], ix[vis]] = colour


def _annotate(out, anchors, allv, title):
    """Callout labels in a column on each side, leader lines to their anchors."""
    draw = ImageDraw.Draw(out)
    font = ImageFont.load_default(size=26)
    small = ImageFont.load_default(size=20)
    W, H = out.size
    gap = 44
    for side in ("left", "right"):
        group = sorted((a for a in anchors if (a[0] < W / 2) == (side == "left")), key=lambda a: a[1])
        last = -1e9
        for ax, ay, label in group:
            ly = min(max(ay, last + gap, 60), H - 90)
            last = ly
            tw = draw.textlength(label, font=font)
            if side == "left":
                tx, end = 30, 30 + tw + 10
            else:
                tx, end = W - 30 - tw, W - 30 - tw - 10
            draw.line([(ax, ay), (end, ly)], fill=(80, 80, 80), width=2)
            draw.ellipse([ax - 5, ay - 5, ax + 5, ay + 5], fill=(80, 80, 80))
            draw.text((tx, ly - 15), label, fill=(25, 25, 25), font=font)

    size = np.ptp(allv, axis=0)
    caption = (f"overall ~{size[0]:.0f} x {size[1]:.0f} x {size[2]:.0f} mm without enclosure"
               "  |  sketch: simplified parts at real positions")
    draw.text((30, H - 40), caption, fill=(90, 90, 90), font=small)
    if title:
        draw.text((30, 20), title, fill=(25, 25, 25), font=font)
