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

# Enclosure: OpenSCAD, installed locally (e.g. `apt install openscad`). The STLs and
# renders are committed, so building a unit doesn't need it.
OPENSCAD ?= openscad
ENCLOSURE_PARTS := body display-face sensor-face
ENCLOSURE_SRC := enclosure/config.scad enclosure/parts.scad enclosure/components.scad
RENDER = $(if $(DISPLAY),,xvfb-run -a) $(OPENSCAD) --imgsize=1100,1300 --colorscheme=Tomorrow --projection=p

.PHONY: test test-unit validate compile run logs clean enclosure enclosure-check enclosure-renders

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

## enclosure: printable STLs -> enclosure/stl/, plus fit checks and renders
enclosure: $(ENCLOSURE_PARTS:%=enclosure/stl/%.stl) enclosure-check enclosure-renders

enclosure/stl/%.stl: enclosure/%.scad $(ENCLOSURE_SRC)
	@mkdir -p enclosure/stl
	$(OPENSCAD) --export-format binstl -o $@ $<

## enclosure-check: fail if any printed part collides with another or with the hardware
enclosure-check:
	python3 enclosure/check.py $(OPENSCAD)

## enclosure-renders: pictures of the assembled unit -> enclosure/renders/
enclosure-renders: $(ENCLOSURE_SRC) enclosure/assembly.scad
	@mkdir -p enclosure/renders
	$(RENDER) -o enclosure/renders/front.png --camera=0,15,42,70,0,-35,250 enclosure/assembly.scad
	$(RENDER) -o enclosure/renders/back.png --camera=0,15,42,70,0,150,250 enclosure/assembly.scad
	$(RENDER) -o enclosure/renders/exploded.png --camera=0,0,42,70,0,-40,290 -D explode=22 enclosure/assembly.scad
	$(RENDER) -o enclosure/renders/cutaway.png --camera=0,15,42,90,0,90,270 -D cutaway=true enclosure/assembly.scad

$(CACHE_DIR):
	mkdir -p $(CACHE_DIR)/cache $(CACHE_DIR)/build

clean:
	rm -rf build
