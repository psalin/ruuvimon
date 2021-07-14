#!/bin/bash

INFLUXDB_ADDR=influxdb:8086

# Set the InfluxDB url according to whether HTTPS is enabled or not
if [[ "${INFLUXDB_HTTPS_ENABLED}" == "true" ]]; then
    INFLUXDB_URL="https://${INFLUXDB_ADDR}"
else
    INFLUXDB_URL="http://${INFLUXDB_ADDR}"
fi

# Exec the original telegraf image entrypoint
exec env INFLUXDB_URL="${INFLUXDB_URL}" /entrypoint.sh telegraf
