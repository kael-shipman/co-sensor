import esphome.codegen as cg
from esphome.components import binary_sensor
import esphome.config_validation as cv
from esphome.const import DEVICE_CLASS_PROBLEM, ENTITY_CATEGORY_DIAGNOSTIC

from . import CONF_ZE15_CO_ID, ZE15COComponent

DEPENDENCIES = ["ze15_co"]

CONF_FAULT = "fault"

CONFIG_SCHEMA = cv.Schema(
    {
        cv.GenerateID(CONF_ZE15_CO_ID): cv.use_id(ZE15COComponent),
        cv.Optional(CONF_FAULT): binary_sensor.binary_sensor_schema(
            device_class=DEVICE_CLASS_PROBLEM,
            entity_category=ENTITY_CATEGORY_DIAGNOSTIC,
        ),
    }
)


async def to_code(config):
    hub = await cg.get_variable(config[CONF_ZE15_CO_ID])
    if conf := config.get(CONF_FAULT):
        sens = await binary_sensor.new_binary_sensor(conf)
        cg.add(hub.set_fault_binary_sensor(sens))
