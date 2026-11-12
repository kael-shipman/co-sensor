# M3: e-ink display

**State: done, working on hardware.**

The 1.54" panel plugs into Seeed's ePaper Driver Board, and the display package
(`firmware/modules/epd-1in54.yaml`) is enabled. No new board needed.

Follow-ups tracked elsewhere: `rotation: 180°` for the folded panel is part of
[M4](<m04 - enclosure.md>); migrating from `waveshare_epaper` to `epaper_spi` is an open
question in [RESUME.md](../../../RESUME.md).
