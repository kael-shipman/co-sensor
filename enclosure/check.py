#!/usr/bin/env python3
"""Fit checks for the enclosure: renders each overlap in checks.scad with OpenSCAD and
fails if any of them has volume. Parts that merely touch (a face against the body, the
board on its tails) produce zero-thickness results, which are ignored.

Usage: check.py [openscad binary]
"""
import os
import re
import subprocess
import sys
import tempfile
from collections import defaultdict
from concurrent.futures import ThreadPoolExecutor

HERE = os.path.dirname(os.path.abspath(__file__))
OPENSCAD = sys.argv[1] if len(sys.argv) > 1 else "openscad"

CHECKS = [
    (1, "body vs display face", [0]),
    (2, "body vs sensor face", [0]),
    (3, "display face vs sensor face", [0]),
    (4, "body vs purchased parts", [0]),
    (5, "display face vs purchased parts", [0]),
    (6, "sensor face vs purchased parts", [0]),
    (7, "display face comes off forward", [1, 3, 6, 12, 20, 30, 45]),
    (8, "sensor face comes off forward", [1, 3, 6, 12, 20, 30, 45]),
    (9, "panel slides in from the top", [1, 5, 10, 20, 30, 40]),
    (10, "board lifts off its rails", [1, 3, 6, 12, 20, 30]),
]
MIN_THICKNESS = 0.02


def regions(stl_text):
    """Bounding boxes of the connected pieces of an ASCII STL."""
    pts = [tuple(round(float(c), 3) for c in m.groups())
           for m in re.finditer(r"vertex\s+(\S+)\s+(\S+)\s+(\S+)", stl_text)]
    parent = {}

    def find(a):
        while parent.setdefault(a, a) != a:
            a = parent[a]
        return a

    tris = [pts[i:i + 3] for i in range(0, len(pts), 3)]
    for t in tris:
        for v in t[1:]:
            parent[find(v)] = find(t[0])
    groups = defaultdict(list)
    for t in tris:
        groups[find(t[0])].extend(t)
    for g in groups.values():
        xs, ys, zs = zip(*g)
        yield (min(xs), max(xs)), (min(ys), max(ys)), (min(zs), max(zs))


def run(check, d):
    with tempfile.TemporaryDirectory() as tmp:
        out = os.path.join(tmp, "overlap.stl")
        proc = subprocess.run([OPENSCAD, "-D", f"check={check}", "-D", f"d={d}", "--export-format", "asciistl",
                               "-o", out, os.path.join(HERE, "checks.scad")], capture_output=True, text=True)
        if "ERROR" in proc.stderr or "WARNING: Ignoring unknown" in proc.stderr:
            sys.exit(f"OpenSCAD failed on check {check}:\n{proc.stderr}")
        if not os.path.exists(out):
            return []  # "Current top level object is empty"
        return [r for r in regions(open(out).read()) if min(hi - lo for lo, hi in r) > MIN_THICKNESS]


def main():
    jobs = [(check, d) for check, _, distances in CHECKS for d in distances]
    with ThreadPoolExecutor(os.cpu_count()) as pool:
        results = dict(zip(jobs, pool.map(lambda job: run(*job), jobs)))
    failed = 0
    for check, name, distances in CHECKS:
        bad = [(d, r) for d in distances for r in results[(check, d)]]
        print(f"{'FAIL' if bad else 'ok  '}  {name}")
        for d, (x, y, z) in bad:
            print(f"        at {d} mm: x {x[0]:.2f}..{x[1]:.2f}  y {y[0]:.2f}..{y[1]:.2f}  z {z[0]:.2f}..{z[1]:.2f}")
        failed += bool(bad)
    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()
