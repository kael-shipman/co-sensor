import esphome.codegen as cg
from esphome.components import uart
import esphome.config_validation as cv
from esphome.const import CONF_ID, CONF_TIMEOUT, CONF_WARMUP_TIME

DEPENDENCIES = ["uart"]
MULTI_CONF = True

CONF_ZE15_CO_ID = "ze15_co_id"

ze15_co_ns = cg.esphome_ns.namespace("ze15_co")
ZE15COComponent = ze15_co_ns.class_("ZE15COComponent", cg.Component, uart.UARTDevice)

CONFIG_SCHEMA = (
    cv.Schema(
        {
            cv.GenerateID(): cv.declare_id(ZE15COComponent),
            cv.Optional(
                CONF_WARMUP_TIME, default="60s"
            ): cv.positive_time_period_milliseconds,
            cv.Optional(CONF_TIMEOUT, default="10s"): cv.All(
                cv.positive_time_period_milliseconds,
                cv.Range(min=cv.TimePeriod(seconds=2)),
            ),
        }
    )
    .extend(cv.COMPONENT_SCHEMA)
    .extend(uart.UART_DEVICE_SCHEMA)
)

# The module streams readings unprompted, so only RX is required.
FINAL_VALIDATE_SCHEMA = uart.final_validate_device_schema(
    "ze15_co",
    baud_rate=9600,
    require_rx=True,
    data_bits=8,
    parity="NONE",
    stop_bits=1,
)


async def to_code(config):
    var = cg.new_Pvariable(config[CONF_ID])
    await cg.register_component(var, config)
    await uart.register_uart_device(var, config)
    cg.add(var.set_warmup_time(config[CONF_WARMUP_TIME]))
    cg.add(var.set_timeout(config[CONF_TIMEOUT]))
