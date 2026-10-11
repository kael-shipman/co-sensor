#include "ze15_co.h"

#include <cinttypes>
#include <cmath>

#include "esphome/core/hal.h"
#include "esphome/core/log.h"

namespace esphome {
namespace ze15_co {

static const char *const TAG = "ze15_co";

void ZE15COComponent::setup() {
  this->setup_ms_ = millis();
  this->last_frame_ms_ = this->setup_ms_;
}

void ZE15COComponent::loop() {
  uint8_t byte;
  Reading reading;
  while (this->available() > 0 && this->read_byte(&byte)) {
    if (this->parser_.feed(byte, reading))
      this->handle_reading_(reading);
  }

  if (this->parser_.checksum_errors() != this->reported_checksum_errors_) {
    this->reported_checksum_errors_ = this->parser_.checksum_errors();
    ESP_LOGW(TAG, "Checksum mismatch (%" PRIu32 " total); check wiring and baud rate", this->reported_checksum_errors_);
  }

  this->check_timeout_();
}

void ZE15COComponent::handle_reading_(const Reading &reading) {
  this->last_frame_ms_ = millis();
  const bool resumed = this->timed_out_;
  if (resumed) {
    this->timed_out_ = false;
    this->status_clear_warning();
    ESP_LOGI(TAG, "Sensor data resumed");
  }

  ESP_LOGV(TAG, "%s frame: %.1f ppm, fault=%s, full range=%.0f ppm",
           reading.type == FrameType::INITIATIVE_UPLOAD ? "Upload" : "Q&A", reading.ppm, YESNO(reading.fault),
           reading.full_range_ppm);

  if (this->warming_up_()) {
    // Clear the timeout fault, but keep withholding readings until warm-up ends.
    if (resumed)
      this->publish_(NAN, reading.fault);
    return;
  }

  if (reading.fault)
    ESP_LOGW(TAG, "Module reports a sensor fault");
  this->publish_(reading.fault ? NAN : reading.ppm, reading.fault);
}

void ZE15COComponent::check_timeout_() {
  if (this->timed_out_ || millis() - this->last_frame_ms_ < this->timeout_ms_)
    return;

  this->timed_out_ = true;
  this->status_set_warning();
  ESP_LOGW(TAG, "No valid frame for %" PRIu32 " ms; check wiring and power", this->timeout_ms_);
  this->publish_(NAN, true);
}

bool ZE15COComponent::warming_up_() const { return millis() - this->setup_ms_ < this->warmup_time_ms_; }

void ZE15COComponent::publish_(float ppm, bool fault) {
#ifdef USE_SENSOR
  if (this->carbon_monoxide_sensor_ != nullptr)
    this->carbon_monoxide_sensor_->publish_state(ppm);
#endif
#ifdef USE_BINARY_SENSOR
  if (this->fault_binary_sensor_ != nullptr)
    this->fault_binary_sensor_->publish_state(fault);
#endif
}

void ZE15COComponent::dump_config() {
  ESP_LOGCONFIG(TAG,
                "ZE15-CO:\n"
                "  Warm-up time: %" PRIu32 " ms\n"
                "  Timeout: %" PRIu32 " ms",
                this->warmup_time_ms_, this->timeout_ms_);
#ifdef USE_SENSOR
  LOG_SENSOR("  ", "Carbon monoxide", this->carbon_monoxide_sensor_);
#endif
#ifdef USE_BINARY_SENSOR
  LOG_BINARY_SENSOR("  ", "Fault", this->fault_binary_sensor_);
#endif
}

}  // namespace ze15_co
}  // namespace esphome
