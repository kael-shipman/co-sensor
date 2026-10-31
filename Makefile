# Host-side checks. Firmware checks run ESPHome in Docker so nothing needs installing.

ESPHOME_IMAGE ?= ghcr.io/esphome/esphome:stable
CACHE_DIR ?= $(HOME)/.cache/co-sensor
FIRMWARE_TESTS := $(wildcard tests/firmware/*.yaml)
FIRMWARE_CONFIGS := $(FIRMWARE_TESTS)

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

# Hardware: KiCad in Docker, like ESPHome.
KICAD_IMAGE ?= kicad/kicad:9.0
CARRIER_DIR := hardware/carrier
CARRIER_PCB := $(CARRIER_DIR)/co-sensor-carrier.kicad_pcb
KICAD = docker run --rm --user $(shell id -u):$(shell id -g) -e HOME=/tmp \
	-v "$(CURDIR)":/work -w /work/$(CARRIER_DIR) $(KICAD_IMAGE)

# Mechanical models: CadQuery in a small local image (tools/cad.Dockerfile).
CAD_IMAGE ?= co-sensor-cad
CAD = docker run --rm --user $(shell id -u):$(shell id -g) -e HOME=/tmp \
	-v "$(CURDIR)":/work -w /work $(CAD_IMAGE)

.PHONY: test test-unit validate compile run logs clean carrier carrier-check carrier-fab cad-image assembly

## test: unit tests + firmware config validation (fast)
test: test-unit validate

## test-unit: host-side tests for the firmware's pure C++ helpers
test-unit: build/test_ze15_protocol build/test_tz_label
	./build/test_ze15_protocol
	./build/test_tz_label

build/test_tz_label: tests/unit/test_tz_label.cpp firmware/include/tz_label.h
	@mkdir -p build
	$(CXX) $(CXXFLAGS) -I firmware/include $< -o $@

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
run: | $(CACHE_DIR)
	$(ESPHOME_DEVICE) run firmware/$(DEVICE).yaml $(if $(PORT),--device $(PORT))

## logs: follow logs from firmware/$(DEVICE).yaml
logs:
	$(ESPHOME_DEVICE) logs firmware/$(DEVICE).yaml $(if $(PORT),--device $(PORT))

## carrier: regenerate the carrier PCB from its script and run KiCad's DRC (fails on any violation)
carrier:
	$(KICAD) python3 generate.py
	$(KICAD) kicad-cli pcb drc --severity-all --exit-code-violations \
		-o /tmp/drc.rpt co-sensor-carrier.kicad_pcb

## carrier-check: printable 1:1 footprint check -> build/carrier-footprint-check.pdf
carrier-check: carrier
	@mkdir -p build
	$(KICAD) kicad-cli pcb export pdf --mode-single --black-and-white \
		-l F.Cu,F.Fab,Edge.Cuts,User.Drawings \
		-o /work/build/carrier-footprint-check.pdf co-sensor-carrier.kicad_pcb

## carrier-fab: Gerbers + drill files for ordering -> build/co-sensor-carrier-fab.zip
carrier-fab: carrier
	@rm -rf build/carrier-fab && mkdir -p build/carrier-fab
	$(KICAD) kicad-cli pcb export gerbers \
		-l F.Cu,B.Cu,F.Mask,B.Mask,F.Silkscreen,B.Silkscreen,Edge.Cuts \
		-o /work/build/carrier-fab/ co-sensor-carrier.kicad_pcb
	$(KICAD) kicad-cli pcb export drill -o /work/build/carrier-fab/ co-sensor-carrier.kicad_pcb
	cd build/carrier-fab && rm -f ../co-sensor-carrier-fab.zip && zip -q ../co-sensor-carrier-fab.zip *
	@echo "Upload build/co-sensor-carrier-fab.zip to the PCB fab."

cad-image:
	docker build -q -t $(CAD_IMAGE) -f tools/cad.Dockerfile tools/ >/dev/null

## assembly: 3D model of an assembled unit -> build/assembly.{step,glb} + build/assembly-*.png
assembly: cad-image
	@mkdir -p build
	$(CAD) python enclosure/assembly.py

$(CACHE_DIR):
	mkdir -p $(CACHE_DIR)/cache $(CACHE_DIR)/build

clean:
	rm -rf build
