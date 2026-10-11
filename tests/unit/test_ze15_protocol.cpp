// Host-side tests for firmware/components/ze15_co/ze15_protocol.h.
// Build and run with `make test-unit`.

#include <cmath>
#include <cstdio>
#include <initializer_list>
#include <vector>

#include "ze15_co/ze15_protocol.h"

using namespace esphome::ze15_co;

static int failures = 0;
static int checks = 0;

#define CHECK(cond)                                                     \
  do {                                                                  \
    checks++;                                                           \
    if (!(cond)) {                                                      \
      failures++;                                                       \
      std::printf("  FAIL %s:%d: %s\n", __FILE__, __LINE__, #cond);     \
    }                                                                   \
  } while (0)

#define CHECK_NEAR(a, b) CHECK(std::fabs((a) - (b)) < 1e-4f)

using Bytes = std::vector<uint8_t>;

// Builds a frame from its first 8 bytes, appending the correct checksum.
static Bytes frame(std::initializer_list<uint8_t> first8) {
  Bytes f(first8);
  f.push_back(checksum(f.data()));
  return f;
}

static Bytes upload_frame(uint8_t conc_high, uint8_t conc_low, uint8_t decimals = 1) {
  return frame({0xFF, 0x04, 0x03, decimals, conc_high, conc_low, 0x13, 0x88});
}

static Bytes concat(std::initializer_list<Bytes> parts) {
  Bytes out;
  for (const auto &p : parts)
    out.insert(out.end(), p.begin(), p.end());
  return out;
}

static std::vector<Reading> parse_all(FrameParser &parser, const Bytes &stream) {
  std::vector<Reading> readings;
  Reading r;
  for (uint8_t b : stream) {
    if (parser.feed(b, r))
      readings.push_back(r);
  }
  return readings;
}

static void test_checksum_matches_manual_examples() {
  // Manual table 4: initiative upload example.
  const uint8_t upload[] = {0xFF, 0x04, 0x03, 0x01, 0x00, 0x05, 0x13, 0x88, 0x58};
  CHECK(checksum(upload) == 0x58);
  // Manual table 5: read command.
  CHECK(checksum(READ_COMMAND) == READ_COMMAND[8]);
  // Manual table 6 prints 0x7A for its Q&A example, which contradicts the manual's own
  // formula (0x86 + 0x05 + 0x05 = 0x90 -> 0x70). We trust the formula, which matches
  // the other two examples.
  const uint8_t qa[] = {0xFF, 0x86, 0x00, 0x05, 0x00, 0x00, 0x00, 0x05, 0x00};
  CHECK(checksum(qa) == 0x70);
}

static void test_decode_manual_upload_example() {
  const uint8_t f[] = {0xFF, 0x04, 0x03, 0x01, 0x00, 0x05, 0x13, 0x88, 0x58};
  Reading r{};
  CHECK(decode(f, r));
  CHECK(r.type == FrameType::INITIATIVE_UPLOAD);
  CHECK_NEAR(r.ppm, 0.5f);
  CHECK(!r.fault);
  CHECK_NEAR(r.full_range_ppm, 500.0f);
}

static void test_decode_full_scale() {
  // 0x1388 = 5000 -> 500.0 ppm.
  Bytes f = upload_frame(0x13, 0x88);
  Reading r{};
  CHECK(decode(f.data(), r));
  CHECK_NEAR(r.ppm, 500.0f);
}

static void test_decode_fault_bit_is_masked_out_of_value() {
  // Fault bit set, bits 5-6 set (not part of the value), value 0x0105 = 261 -> 26.1 ppm.
  Bytes f = upload_frame(0x80 | 0x60 | 0x01, 0x05);
  Reading r{};
  CHECK(decode(f.data(), r));
  CHECK(r.fault);
  CHECK_NEAR(r.ppm, 26.1f);
}

static void test_decode_respects_decimals_byte() {
  Bytes f = upload_frame(0x00, 0x7B, 2);  // 123 / 100
  Reading r{};
  CHECK(decode(f.data(), r));
  CHECK_NEAR(r.ppm, 1.23f);
  CHECK_NEAR(r.full_range_ppm, 50.0f);

  Bytes bad = upload_frame(0x00, 0x7B, 9);
  CHECK(!decode(bad.data(), r));
}

static void test_decode_qa_response() {
  Bytes f = frame({0xFF, 0x86, 0x00, 0x64, 0x00, 0x00, 0x00, 0x64});  // 100 -> 10.0 ppm
  Reading r{};
  CHECK(decode(f.data(), r));
  CHECK(r.type == FrameType::QA_RESPONSE);
  CHECK_NEAR(r.ppm, 10.0f);
  CHECK(!r.fault);
  CHECK_NEAR(r.full_range_ppm, 0.0f);

  Bytes faulted = frame({0xFF, 0x86, 0x80, 0x00, 0x00, 0x00, 0x80, 0x00});
  CHECK(decode(faulted.data(), r));
  CHECK(r.fault);
}

static void test_decode_rejects_other_gases() {
  Bytes f = frame({0xFF, 0x17, 0x04, 0x00, 0x00, 0x25, 0x13, 0x88});  // ZE08 formaldehyde
  Reading r{};
  CHECK(!decode(f.data(), r));
}

static void test_parser_back_to_back_frames() {
  FrameParser p;
  auto readings = parse_all(p, concat({upload_frame(0x00, 0x05), upload_frame(0x00, 0x0A)}));
  CHECK(readings.size() == 2);
  if (readings.size() == 2) {
    CHECK_NEAR(readings[0].ppm, 0.5f);
    CHECK_NEAR(readings[1].ppm, 1.0f);
  }
  CHECK(p.checksum_errors() == 0);
}

static void test_parser_skips_leading_garbage() {
  FrameParser p;
  auto readings = parse_all(p, concat({Bytes{0x00, 0x13, 0x42}, upload_frame(0x00, 0x05)}));
  CHECK(readings.size() == 1);
  CHECK(p.checksum_errors() == 0);
}

static void test_parser_recovers_after_checksum_error() {
  FrameParser p;
  Bytes corrupt = upload_frame(0x00, 0x05);
  corrupt[5] ^= 0x01;
  auto readings = parse_all(p, concat({corrupt, upload_frame(0x00, 0x0A)}));
  CHECK(readings.size() == 1);
  if (readings.size() == 1)
    CHECK_NEAR(readings[0].ppm, 1.0f);
  CHECK(p.checksum_errors() == 1);
}

static void test_parser_resyncs_into_frame_after_truncation() {
  // A frame cut off after 3 bytes (e.g. connected mid-transmission), immediately
  // followed by a good frame: the good frame's start byte is inside the first
  // 9-byte window and must not be thrown away.
  FrameParser p;
  Bytes good = upload_frame(0x00, 0x2A);
  auto readings = parse_all(p, concat({Bytes{0xFF, 0x04, 0x03}, good}));
  CHECK(readings.size() == 1);
  if (readings.size() == 1)
    CHECK_NEAR(readings[0].ppm, 4.2f);
  CHECK(p.checksum_errors() == 1);
}

static void test_parser_handles_0xff_inside_payload() {
  // 0xFF as the concentration low byte (0x00FF = 25.5 ppm) mustn't confuse framing.
  FrameParser p;
  auto readings = parse_all(p, concat({upload_frame(0x00, 0xFF), upload_frame(0x00, 0x01)}));
  CHECK(readings.size() == 2);
  if (readings.size() == 2) {
    CHECK_NEAR(readings[0].ppm, 25.5f);
    CHECK_NEAR(readings[1].ppm, 0.1f);
  }
}

static void test_parser_counts_unknown_frames_without_checksum_errors() {
  FrameParser p;
  Bytes other = frame({0xFF, 0x17, 0x04, 0x00, 0x00, 0x25, 0x13, 0x88});
  auto readings = parse_all(p, concat({other, upload_frame(0x00, 0x05)}));
  CHECK(readings.size() == 1);
  CHECK(p.unknown_frames() == 1);
  CHECK(p.checksum_errors() == 0);
}

int main() {
  const struct {
    const char *name;
    void (*fn)();
  } tests[] = {
      {"checksum matches manual examples", test_checksum_matches_manual_examples},
      {"decode manual upload example", test_decode_manual_upload_example},
      {"decode full scale", test_decode_full_scale},
      {"decode fault bit is masked out of value", test_decode_fault_bit_is_masked_out_of_value},
      {"decode respects decimals byte", test_decode_respects_decimals_byte},
      {"decode Q&A response", test_decode_qa_response},
      {"decode rejects other gases", test_decode_rejects_other_gases},
      {"parser back-to-back frames", test_parser_back_to_back_frames},
      {"parser skips leading garbage", test_parser_skips_leading_garbage},
      {"parser recovers after checksum error", test_parser_recovers_after_checksum_error},
      {"parser resyncs into frame after truncation", test_parser_resyncs_into_frame_after_truncation},
      {"parser handles 0xFF inside payload", test_parser_handles_0xff_inside_payload},
      {"parser counts unknown frames", test_parser_counts_unknown_frames_without_checksum_errors},
  };

  for (const auto &t : tests) {
    const int before = failures;
    t.fn();
    std::printf("%s %s\n", failures == before ? "ok  " : "FAIL", t.name);
  }
  std::printf("\n%d checks, %d failed\n", checks, failures);
  return failures == 0 ? 0 : 1;
}
