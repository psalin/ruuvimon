#!/bin/bash

INFLUXDB_ADDR=influxdb:8086

if [[ "${INFLUXDB_HTTPS_ENABLED}" == "true" ]]; then
    INFLUXDB_URL="https://${INFLUXDB_ADDR}"
else
    INFLUXDB_URL="http://${INFLUXDB_ADDR}"
fi

exec env INFLUXDB_URL="${INFLUXDB_URL}" /entrypoint.sh telegraf
