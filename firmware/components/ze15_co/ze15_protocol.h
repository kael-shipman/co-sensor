#pragma once

// Wire protocol for the Winsen ZE15-CO (manual v1.2, 2023-03-27).
//
// Deliberately free of ESPHome dependencies so it can be unit-tested on the host
// (see tests/unit/). The ESPHome component in ze15_co.{h,cpp} is a thin adapter around it.
//
// Every frame is 9 bytes at 9600 8N1 and starts with 0xFF. Byte 8 is a checksum over
// bytes 1..7: (~(b1 + ... + b7)) + 1. Two frame shapes exist:
//
//   Initiative upload (default; sent every ~1 s):
//     FF 04 03 DD CH CL RH RL SS
//     04 = gas type (CO), 03 = unit (ppm), DD = number of decimal places,
//     CH/CL = concentration, RH/RL = full range, SS = checksum.
//
//   Q&A response (only after the host sends READ_COMMAND; the module drops back to
//   initiative upload after 30 s without a query):
//     FF 86 CH CL 00 00 CH CL SS
//
// In both, bit 7 of CH is the sensor-fault flag and the concentration is
// ((CH & 0x1F) << 8 | CL) scaled by the decimal places (always 1 for Q&A).

#include <cstddef>
#include <cstdint>
#include <cstring>

namespace esphome {
namespace ze15_co {

static constexpr size_t FRAME_SIZE = 9;
static constexpr uint8_t START_BYTE = 0xFF;
static constexpr uint8_t GAS_TYPE_CO = 0x04;
static constexpr uint8_t CMD_READ = 0x86;
static constexpr uint8_t FAULT_MASK = 0x80;
static constexpr uint8_t CONCENTRATION_HIGH_MASK = 0x1F;
static constexpr uint8_t QA_DECIMALS = 1;
static constexpr uint8_t MAX_DECIMALS = 3;

// Switches the module to Q&A mode and requests one reading (manual table 5).
static constexpr uint8_t READ_COMMAND[FRAME_SIZE] = {0xFF, 0x01, 0x86, 0x00, 0x00, 0x00, 0x00, 0x00, 0x79};

enum class FrameType : uint8_t {
  INITIATIVE_UPLOAD,
  QA_RESPONSE,
};

struct Reading {
  FrameType type;
  float ppm;
  bool fault;
  // Only reported by initiative-upload frames; 0 for Q&A responses.
  float full_range_ppm;
};

inline uint8_t checksum(const uint8_t *frame) {
  uint8_t sum = 0;
  for (size_t i = 1; i < FRAME_SIZE - 1; i++)
    sum += frame[i];
  return static_cast<uint8_t>(~sum + 1);
}

inline float scale(uint16_t raw, uint8_t decimals) {
  float value = raw;
  for (uint8_t i = 0; i < decimals; i++)
    value /= 10.0f;
  return value;
}

inline uint16_t concentration_raw(uint8_t high, uint8_t low) {
  return static_cast<uint16_t>(((high & CONCENTRATION_HIGH_MASK) << 8) | low);
}

// Decodes a complete frame whose checksum has already been verified.
// Returns false if the frame is well-formed but isn't a CO reading.
inline bool decode(const uint8_t *frame, Reading &out) {
  if (frame[0] != START_BYTE)
    return false;

  if (frame[1] == GAS_TYPE_CO) {
    const uint8_t decimals = frame[3];
    if (decimals > MAX_DECIMALS)
      return false;
    out.type = FrameType::INITIATIVE_UPLOAD;
    out.fault = (frame[4] & FAULT_MASK) != 0;
    out.ppm = scale(concentration_raw(frame[4], frame[5]), decimals);
    out.full_range_ppm = scale(static_cast<uint16_t>((frame[6] << 8) | frame[7]), decimals);
    return true;
  }

  if (frame[1] == CMD_READ) {
    out.type = FrameType::QA_RESPONSE;
    out.fault = (frame[2] & FAULT_MASK) != 0;
    out.ppm = scale(concentration_raw(frame[2], frame[3]), QA_DECIMALS);
    out.full_range_ppm = 0.0f;
    return true;
  }

  return false;
}

// Reassembles frames from a byte stream, resynchronising on the next 0xFF after
// garbage, truncated frames or checksum failures.
class FrameParser {
 public:
  // Feeds one byte. Returns true when `out` holds a newly decoded reading.
  bool feed(uint8_t byte, Reading &out) {
    if (this->len_ == 0 && byte != START_BYTE)
      return false;

    this->buf_[this->len_++] = byte;
    if (this->len_ < FRAME_SIZE)
      return false;

    if (checksum(this->buf_) != this->buf_[FRAME_SIZE - 1]) {
      this->checksum_errors_++;
      this->resync_();
      return false;
    }

    this->len_ = 0;
    if (decode(this->buf_, out))
      return true;
    this->unknown_frames_++;
    return false;
  }

  uint32_t checksum_errors() const { return this->checksum_errors_; }
  uint32_t unknown_frames() const { return this->unknown_frames_; }

 protected:
  // Drops the current start byte and slides the buffer to the next candidate start byte,
  // so a real frame that began inside a corrupt one isn't lost.
  void resync_() {
    size_t next = 1;
    while (next < FRAME_SIZE && this->buf_[next] != START_BYTE)
      next++;
    this->len_ = FRAME_SIZE - next;
    std::memmove(this->buf_, this->buf_ + next, this->len_);
  }

  uint8_t buf_[FRAME_SIZE]{};
  size_t len_{0};
  uint32_t checksum_errors_{0};
  uint32_t unknown_frames_{0};
};

}  // namespace ze15_co
}  // namespace esphome
