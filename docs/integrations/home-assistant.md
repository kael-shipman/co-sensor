# Home Assistant integration

Optional. `firmware/integrations/home-assistant.yaml` adds ESPHome's native API, which
Home Assistant's ESPHome integration connects to. Without it the device still measures and
displays CO; Home Assistant is just one consumer of its readings.

## Enable

1. Include the package in the device file (`co-sensor-01.yaml` does by default):
   ```yaml
   packages:
     home_assistant: !include integrations/home-assistant.yaml
   ```
2. Set `api_encryption_key` in `firmware/secrets.yaml` (`openssl rand -base64 32`).
3. Flash. In HA, Settings → Devices & services: ESPHome discovers the device. Configure it
   and paste the key.

The package sets `api: reboot_timeout: 0s`. ESPHome otherwise reboots the device after
15 minutes without an API client, which would interrupt measurement whenever HA is down.

## Entities

| Entity | Notes |
|---|---|
| `sensor.<name>_carbon_monoxide` | ppm (`co_ppm`), device class `carbon_monoxide`. Unknown during warm-up, faults and timeouts. |
| `binary_sensor.<name>_co_sensor_fault` | `problem` class (`co_fault`). |
| Wi-Fi signal, uptime, restart | diagnostics |

## Alerting pattern

Keep the device a pure reporter and put decisions in HA:

- One **Threshold helper** per sensor turns ppm into "CO elevated".
- Tag every CO sensor with a `co_sensor` **label** and find the helpers by that label.
  Don't hard-code devices.
- **Alerting routines** (notifications, ventilation, lights) consume the helpers' state,
  never raw ppm.

A new sensor then joins the system by getting a helper and a label, with no new
automations. The sensor's own display keeps working when HA or the network doesn't.

## Network logs

`make logs` without `PORT` streams logs over the native API, so it needs this
integration. Without it, use `make logs PORT=/dev/ttyACM0` over USB.
