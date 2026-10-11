#pragma once

#include "esphome/core/component.h"
#include "esphome/core/defines.h"
#include "esphome/components/uart/uart.h"
#ifdef USE_SENSOR
#include "esphome/components/sensor/sensor.h"
#endif
#ifdef USE_BINARY_SENSOR
#include "esphome/components/binary_sensor/binary_sensor.h"
#endif

#include "ze15_protocol.h"

namespace esphome {
namespace ze15_co {

// Listens to the ZE15-CO's initiative-upload stream (one frame per second; no TX needed).
//
// Publishing rules:
//  - Nothing is published during `warmup_time` after boot (the cell needs time to settle).
//  - The CO sensor publishes NaN while the module reports a fault or no valid frame has
//    arrived within `timeout`, so a dead or disconnected sensor never looks like "0 ppm".
//  - The fault binary sensor is true in either of those cases.
class ZE15COComponent : public Component, public uart::UARTDevice {
 public:
  void setup() override;
  void loop() override;
  void dump_config() override;
  float get_setup_priority() const override { return setup_priority::DATA; }

  void set_warmup_time(uint32_t warmup_time_ms) { this->warmup_time_ms_ = warmup_time_ms; }
  void set_timeout(uint32_t timeout_ms) { this->timeout_ms_ = timeout_ms; }
#ifdef USE_SENSOR
  void set_carbon_monoxide_sensor(sensor::Sensor *sensor) { this->carbon_monoxide_sensor_ = sensor; }
#endif
#ifdef USE_BINARY_SENSOR
  void set_fault_binary_sensor(binary_sensor::BinarySensor *sensor) { this->fault_binary_sensor_ = sensor; }
#endif

 protected:
  void handle_reading_(const Reading &reading);
  void check_timeout_();
  bool warming_up_() const;
  void publish_(float ppm, bool fault);

  FrameParser parser_;
  uint32_t warmup_time_ms_{60000};
  uint32_t timeout_ms_{10000};
  uint32_t setup_ms_{0};
  uint32_t last_frame_ms_{0};
  bool timed_out_{false};
  uint32_t reported_checksum_errors_{0};

#ifdef USE_SENSOR
  sensor::Sensor *carbon_monoxide_sensor_{nullptr};
#endif
#ifdef USE_BINARY_SENSOR
  binary_sensor::BinarySensor *fault_binary_sensor_{nullptr};
#endif
};

}  // namespace ze15_co
}  // namespace esphome
