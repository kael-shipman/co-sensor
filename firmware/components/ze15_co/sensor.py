import esphome.codegen as cg
from esphome.components import sensor
import esphome.config_validation as cv
from esphome.const import (
    CONF_CARBON_MONOXIDE,
    DEVICE_CLASS_CARBON_MONOXIDE,
    STATE_CLASS_MEASUREMENT,
    UNIT_PARTS_PER_MILLION,
)

from . import CONF_ZE15_CO_ID, ZE15COComponent

DEPENDENCIES = ["ze15_co"]

CONFIG_SCHEMA = cv.Schema(
    {
        cv.GenerateID(CONF_ZE15_CO_ID): cv.use_id(ZE15COComponent),
        cv.Optional(CONF_CARBON_MONOXIDE): sensor.sensor_schema(
            unit_of_measurement=UNIT_PARTS_PER_MILLION,
            accuracy_decimals=1,
            device_class=DEVICE_CLASS_CARBON_MONOXIDE,
            state_class=STATE_CLASS_MEASUREMENT,
        ),
    }
)


async def to_code(config):
    hub = await cg.get_variable(config[CONF_ZE15_CO_ID])
    if conf := config.get(CONF_CARBON_MONOXIDE):
        sens = await sensor.new_sensor(conf)
        cg.add(hub.set_carbon_monoxide_sensor(sens))
