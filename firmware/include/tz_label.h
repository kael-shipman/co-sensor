#pragma once

// Short, human label for the device's current timezone, e.g. "CST", "CEST" or "UTC+5:30".
//
// The timezone ESPHome receives (from Home Assistant, or the build) is just offsets plus
// DST rules, with no names, and strftime's %Z only yields "-0600". This maps the common,
// reasonably unambiguous cases to their usual abbreviation and falls back to a numeric
// "UTC±H[:MM]" label otherwise. Deliberately free of ESPHome dependencies so it can be
// unit-tested on the host (tests/unit/test_tz_label.cpp).

#include <cstddef>
#include <cstdint>
#include <cstdio>

namespace co_sensor {

enum class Hemisphere : int8_t { NONE, NORTH, SOUTH };

struct TzName {
  int16_t utc_offset_min;  // standard time, minutes east of UTC
  Hemisphere dst;          // NONE: zone without DST; else where its DST rule starts
  const char *std_name;
  const char *dst_name;
};

// Offsets shared by several regions (e.g. UTC+8, or UTC+9) are left out on purpose: a
// wrong name is worse than a numeric label.
static constexpr TzName TZ_NAMES[] = {
    {-600, Hemisphere::NONE, "HST", "HST"},
    {-540, Hemisphere::NORTH, "AKST", "AKDT"},
    {-480, Hemisphere::NORTH, "PST", "PDT"},
    {-420, Hemisphere::NORTH, "MST", "MDT"},
    {-420, Hemisphere::NONE, "MST", "MST"},  // Arizona
    {-360, Hemisphere::NORTH, "CST", "CDT"},
    {-300, Hemisphere::NORTH, "EST", "EDT"},
    {-240, Hemisphere::NORTH, "AST", "ADT"},
    {-210, Hemisphere::NORTH, "NST", "NDT"},
    {0, Hemisphere::NONE, "UTC", "UTC"},
    {0, Hemisphere::NORTH, "GMT", "BST"},
    {60, Hemisphere::NORTH, "CET", "CEST"},
    {120, Hemisphere::NORTH, "EET", "EEST"},
    {330, Hemisphere::NONE, "IST", "IST"},
    {570, Hemisphere::SOUTH, "ACST", "ACDT"},
    {600, Hemisphere::SOUTH, "AEST", "AEDT"},
    {720, Hemisphere::SOUTH, "NZST", "NZDT"},
};

// posix_std_offset / posix_dst_offset: seconds WEST of UTC, as in POSIX TZ strings and
// ESPHome's ParsedTimezone. dst_start_month: month (1-12) the DST rule starts, or 0 if
// unknown. Writes the label into buf and returns buf.
inline const char *tz_label(int32_t posix_std_offset, int32_t posix_dst_offset, bool has_dst,
                            uint8_t dst_start_month, bool in_dst, char *buf, size_t buf_size) {
  const int std_min = -posix_std_offset / 60;
  Hemisphere hemi = Hemisphere::NONE;
  if (has_dst)
    hemi = dst_start_month == 0 ? Hemisphere::NONE : (dst_start_month <= 6 ? Hemisphere::NORTH : Hemisphere::SOUTH);

  // A zone with DST but an unknown rule month can't be matched safely.
  if (!has_dst || dst_start_month != 0) {
    for (const auto &z : TZ_NAMES) {
      if (z.utc_offset_min == std_min && z.dst == hemi) {
        std::snprintf(buf, buf_size, "%s", in_dst ? z.dst_name : z.std_name);
        return buf;
      }
    }
  }

  const int now_min = -(in_dst ? posix_dst_offset : posix_std_offset) / 60;
  const int abs_min = now_min < 0 ? -now_min : now_min;
  const char sign = now_min < 0 ? '-' : '+';
  if (abs_min % 60 == 0) {
    std::snprintf(buf, buf_size, "UTC%c%d", sign, abs_min / 60);
  } else {
    std::snprintf(buf, buf_size, "UTC%c%d:%02d", sign, abs_min / 60, abs_min % 60);
  }
  return buf;
}

}  // namespace co_sensor
