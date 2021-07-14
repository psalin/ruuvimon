#!/bin/bash

INFLUXDB_ADDR=influxdb:8086
ANONYMOUS_ACCESS=false

if [[ "${GRAFANA_AUTH_ENABLED}" != "true" ]]; then
   ANONYMOUS_ACCESS=true
fi


if [[ "${INFLUXDB_HTTPS_ENABLED}" == "true" ]]; then
    INFLUXDB_URL="https://${INFLUXDB_ADDR}"
else
    INFLUXDB_URL="http://${INFLUXDB_ADDR}"
fi

exec env GF_AUTH_ANONYMOUS_ENABLED="${ANONYMOUS_ACCESS}" \
     env INFLUXDB_URL="${INFLUXDB_URL}" \
     /run.sh
