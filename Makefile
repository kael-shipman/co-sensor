# Host-side checks. Firmware checks run ESPHome in Docker so nothing needs installing.

ESPHOME_IMAGE ?= ghcr.io/esphome/esphome:stable
CACHE_DIR ?= $(HOME)/.cache/co-sensor
FIRMWARE_TESTS := $(wildcard tests/firmware/*.yaml)
FIRMWARE_CONFIGS := $(filter-out tests/firmware/secrets.yaml,$(FIRMWARE_TESTS))

CXX ?= g++
CXXFLAGS ?= -std=c++17 -Wall -Wextra -Werror -O1

ESPHOME = docker run --rm \
	--user $(shell id -u):$(shell id -g) \
	-e HOME=/tmp \
	-v "$(CURDIR)":/config \
	-v "$(CACHE_DIR)/cache":/cache \
	-v "$(CACHE_DIR)/build":/build \
	$(ESPHOME_IMAGE)

# For run/logs: which device file in firmware/, and optionally a serial port
# (e.g. PORT=/dev/ttyACM0). Without PORT, ESPHome uses OTA/the network.
DEVICE ?= co-sensor
PORT ?=

ESPHOME_DEVICE = docker run --rm -it --network host \
	--user $(shell id -u):$(shell id -g) \
	--group-add $(shell getent group dialout | cut -d: -f3) \
	-e HOME=/tmp \
	$(if $(PORT),--device $(PORT):$(PORT)) \
	-v "$(CURDIR)":/config \
	-v "$(CACHE_DIR)/cache":/cache \
	-v "$(CACHE_DIR)/build":/build \
	$(ESPHOME_IMAGE)

.PHONY: test test-unit validate compile run logs clean

## test: unit tests + firmware config validation (fast)
test: test-unit validate

## test-unit: protocol parser tests on the host
test-unit: build/test_ze15_protocol
	./build/test_ze15_protocol

build/test_ze15_protocol: tests/unit/test_ze15_protocol.cpp firmware/components/ze15_co/ze15_protocol.h
	@mkdir -p build
	$(CXX) $(CXXFLAGS) -I firmware/components $< -o $@

## validate: `esphome config` on every config in tests/firmware
validate: | $(CACHE_DIR)
	@mkdir -p build
	@for c in $(FIRMWARE_CONFIGS); do \
		echo "== esphome config $$c"; \
		$(ESPHOME) config $$c > build/esphome-config.log 2>&1 \
			|| { cat build/esphome-config.log; exit 1; }; \
	done
	@echo "All firmware configs valid."

## compile: full firmware builds (slow the first time: downloads the toolchain)
compile: | $(CACHE_DIR)
	@for c in $(FIRMWARE_CONFIGS); do \
		echo "== esphome compile $$c"; \
		$(ESPHOME) compile $$c || exit 1; \
	done

## run: build and flash firmware/$(DEVICE).yaml (USB with PORT=..., else OTA), then follow logs
run: firmware/secrets.yaml | $(CACHE_DIR)
	$(ESPHOME_DEVICE) run firmware/$(DEVICE).yaml $(if $(PORT),--device $(PORT))

## logs: follow logs from firmware/$(DEVICE).yaml
logs: firmware/secrets.yaml
	$(ESPHOME_DEVICE) logs firmware/$(DEVICE).yaml $(if $(PORT),--device $(PORT))

firmware/secrets.yaml:
	@echo "Missing firmware/secrets.yaml: copy firmware/secrets.example.yaml and fill it in." >&2
	@exit 1

$(CACHE_DIR):
	mkdir -p $(CACHE_DIR)/cache $(CACHE_DIR)/build

clean:
	rm -rf build
