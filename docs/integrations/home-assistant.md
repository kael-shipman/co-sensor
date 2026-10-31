# Home Assistant integration

Optional. `firmware/integrations/home-assistant.yaml` adds ESPHome's native API, which
Home Assistant's ESPHome integration connects to. Without it the device still measures and
displays CO; Home Assistant is just one consumer of its readings.

## Enable

1. Include the package in the device file (`co-sensor.yaml` does by default):
   ```yaml
   packages:
     home_assistant: !include integrations/home-assistant.yaml
   ```
2. Flash and put the unit on Wi-Fi ([onboarding](../onboarding.md)).
3. In HA, Settings → Devices & services: ESPHome discovers the device as
   `co-sensor-xxxxxx` (the last 6 hex digits of its MAC). Click **Configure**.
   - HA generates a unique encryption key and provisions it to the unit; there's nothing
     to paste.
   - This needs HA 2026.x, and must happen within the unit's 15-minute provisioning
     window after boot. Power-cycle the unit if it has passed.

The package sets `api: reboot_timeout: 0s`. ESPHome otherwise reboots the device after
15 minutes without an API client, which would interrupt measurement whenever HA is down.

## Entities

`<name>` below is the unit's suffixed name, e.g. `co_sensor_3fa2c1`, so several sensors
coexist without renaming anything.

| Entity | Notes |
|---|---|
| `sensor.<name>_carbon_monoxide` | ppm (`co_ppm`), device class `carbon_monoxide`. Averaged and published once per update interval. Unknown during warm-up, faults and timeouts. |
| `number.<name>_update_interval` | Seconds between published readings and display refreshes (5–600, default 15). Stored on the device. |
| `binary_sensor.<name>_co_sensor_fault` | `problem` class (`co_fault`). |
| `date.<name>_co_sensor_installed` | Editable install date; see [maintenance](../maintenance.md). |
| `button.<name>_co_sensor_replaced` | Sets the install date to today. |
| `number.<name>_co_sensor_service_life` | Editable, in years (default 3). |
| `sensor.<name>_co_sensor_age` | Days since install. |
| `binary_sensor.<name>_co_sensor_replacement_due` | `problem` class. |
| Wi-Fi signal, uptime, restart | diagnostics |

The lifecycle entities are owned by the device, so edits made in HA are stored in the
device's flash. Don't duplicate them as HA helpers.

## Time and timezone

The package also syncs time from Home Assistant, and with it **HA's timezone** (Settings →
System → General). The display's timestamp (e.g. "Oct 26 at 21:30:15 CDT") follows it,
including daylight-saving changes, with nothing to configure on the unit. Without this
package, a unit shows UTC.

## Alerting pattern

Keep the device a pure reporter and put decisions in HA:

- One **Threshold helper** per sensor turns ppm into "CO elevated".
- Tag every CO sensor with a `co_sensor` **label** and find the helpers by that label.
  Don't hard-code devices.
- **Alerting routines** (notifications, ventilation, lights) consume the helpers' state,
  never raw ppm.

Replacement reminders follow the same pattern: one automation over every
`co_sensor`-labelled device's *replacement due* entity, rather than one per device.

A new sensor then joins the system by getting a helper and a label, with no new
automations. The sensor's own display keeps working when HA or the network doesn't.

## Network logs

`make logs` without `PORT` streams logs over the native API, so it needs this
integration. Without it, use `make logs PORT=/dev/ttyACM0` over USB.
