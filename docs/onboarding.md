# Onboarding a unit

Every unit runs the same firmware image, and it contains **no credentials**: no Wi-Fi
network, no Home Assistant key, no passwords. Each unit is set up after flashing, so the
image can be handed to anyone.

## The provisioning window

An unprovisioned unit opens a **provisioning window for 15 minutes after every boot**:

- **Wi-Fi.** It runs an open hotspot named after itself, `co-sensor-xxxxxx` (the last 6
  hex digits of its MAC). Joining it opens a setup page for choosing a Wi-Fi network. The
  choice is saved in the unit's flash.
- **Home Assistant** (with `integrations/home-assistant.yaml`). Its API is encrypted but
  has no key. When you adopt the unit, Home Assistant generates a unique key and gives it
  to the unit. That needs the ESPHome integration in HA 2026.x.

The unit counts as provisioned once it has joined a network and, if the HA package is
included, received its key. If the window expires first:

- the hotspot shuts down and the API refuses unprovisioned connections;
- power-cycling the unit reopens the window;
- **the unit keeps measuring and displaying either way.** A unit that's never put on a
  network is a working standalone CO display.

## First boot, step by step

1. Flash the unit (see [bring-up](bringup.md)) and give it power.
2. On a phone or laptop, join the Wi-Fi network **co-sensor-xxxxxx**. There's no
   password.
3. The setup page should open by itself. If it doesn't, browse to `http://192.168.4.1`.
4. Pick your **2.4 GHz** network, enter its password and save. The unit joins your
   network and the hotspot disappears.
5. **Home Assistant:** Settings → Devices & services. The ESPHome integration discovers
   `co-sensor-xxxxxx`. Click **Configure**; HA provisions the key itself, with nothing
   to paste. Do this within 15 minutes of the unit booting, or power-cycle it first.

**No phone handy, or the window closed?** Wi-Fi can also be set over USB: connect the unit
and use the Wi-Fi setup at [web.esphome.io](https://web.esphome.io). This is Improv
Serial, which needs physical access.

## Changing networks later

- **Provisioned Wi-Fi lives in the unit's flash** and survives firmware updates.
- **To move a unit to a new network,** use Improv over USB as above. Alternatively, erase
  its flash, which also clears the HA key and the sensor's install date, and onboard it
  again.

## Firmware updates and security

Updates go over Wi-Fi with `make run` (no `PORT`). If several units are online, ESPHome
asks which one.

**The shared image has no update password**, because a shared image can't hold a secret.
So anything on your local network can upload firmware to a unit. Note too that the
setup page offers firmware upload while its hotspot is up. If that's not acceptable,
**adopt** the firmware: keep your own config that extends the product image with a
password. For example, in a gitignored `firmware/local/` directory:

```yaml
# firmware/local/my-co-sensors.yaml
substitutions:
  components_dir: ../components   # relative to this file's directory

packages:
  product: !include ../co-sensor.yaml

ota:
  - id: !extend ota_esphome
    password: "your-own-password"
```

Then flash it with `make run DEVICE=local/my-co-sensors`.

- The first update from the shared image needs no password; after that the password is
  required.
- Holders of the HA-provisioned key (Home Assistant itself, and the ESPHome dashboard
  once HA shares the key with it) can update over an encrypted connection without the
  password. ESPHome recommends the provisioning window for exactly this reason, and we
  have one.
- `tests/firmware/co-sensor-adopted.yaml` keeps this pattern building.
