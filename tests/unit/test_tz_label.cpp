// Host-side tests for firmware/include/tz_label.h. Run with `make test-unit`.

#include <cstdio>
#include <cstring>

#include "tz_label.h"

static int failures = 0;
static int checks = 0;

// Offsets are given the readable way (hours east of UTC) and converted to POSIX seconds.
static void expect(const char *what, double std_h, double dst_h, bool has_dst, int start_month, bool in_dst,
                   const char *want) {
  char buf[16];
  const auto posix = [](double h) { return static_cast<int32_t>(-h * 3600); };
  co_sensor::tz_label(posix(std_h), posix(dst_h), has_dst, static_cast<uint8_t>(start_month), in_dst, buf,
                      sizeof(buf));
  checks++;
  const bool ok = std::strcmp(buf, want) == 0;
  if (!ok)
    failures++;
  std::printf("%s %-40s got %-9s want %s\n", ok ? "ok  " : "FAIL", what, buf, want);
}

int main() {
  expect("US Central, winter", -6, -5, true, 3, false, "CST");
  expect("US Central, summer", -6, -5, true, 3, true, "CDT");
  expect("US Eastern, summer", -5, -4, true, 3, true, "EDT");
  expect("US Pacific, winter", -8, -7, true, 3, false, "PST");
  expect("Arizona (no DST)", -7, -7, false, 0, false, "MST");
  expect("Hawaii", -10, -10, false, 0, false, "HST");
  expect("UTC", 0, 0, false, 0, false, "UTC");
  expect("UK, summer", 0, 1, true, 3, true, "BST");
  expect("Central Europe, summer", 1, 2, true, 3, true, "CEST");
  expect("India (half hour)", 5.5, 5.5, false, 0, false, "IST");
  expect("Sydney, southern summer", 10, 11, true, 10, true, "AEDT");
  expect("New Zealand, southern winter", 12, 13, true, 9, false, "NZST");
  // Ambiguous or unlisted zones fall back to numeric labels
  expect("Mexico City (no DST since 2022)", -6, -6, false, 0, false, "UTC-6");
  expect("China/Singapore/Perth (UTC+8)", 8, 8, false, 0, false, "UTC+8");
  expect("Nepal (UTC+5:45)", 5.75, 5.75, false, 0, false, "UTC+5:45");
  expect("Newfoundland, winter", -3.5, -2.5, true, 3, false, "NST");
  expect("Chile (southern DST at -4)", -4, -3, true, 9, true, "UTC-3");
  expect("DST rule with unknown month", -6, -5, true, 0, false, "UTC-6");

  std::printf("\n%d checks, %d failed\n", checks, failures);
  return failures == 0 ? 0 : 1;
}
