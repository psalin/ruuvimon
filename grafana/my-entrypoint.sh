#!/bin/bash

SSL_KEY="${HOME}/grafana-selfsigned.key"
SSL_CERT="${HOME}/grafana-selfsigned.crt"
PROTOCOL=http
INFLUXDB_ADDR=influxdb:8086
ANONYMOUS_ACCESS=false

# Enable anonymous access if authentication is disabled
if [[ "${GRAFANA_AUTH_ENABLED}" != "true" ]]; then
   ANONYMOUS_ACCESS=true
fi

# Generate a self-signed cert if HTTPS is enabled
if [[ "${GRAFANA_HTTPS_ENABLED}" == "true" ]]; then
    if [[ ! -e "${SSL_CERT}" ]]; then
        openssl req -x509 -nodes -newkey rsa:2048 -keyout "${SSL_KEY}" -out "${SSL_CERT}" -days 3650 -subj "/O=RuuviMon/OU=RuuviMon/CN=localhost"
    fi
    PROTOCOL=https
fi

# Set the InfluxDB url according to whether HTTPS is enabled or not
if [[ "${INFLUXDB_HTTPS_ENABLED}" == "true" ]]; then
    INFLUXDB_URL="https://${INFLUXDB_ADDR}"
else
    INFLUXDB_URL="http://${INFLUXDB_ADDR}"
fi

# Exec the original grafana image entrypoint
exec env GF_AUTH_ANONYMOUS_ENABLED="${ANONYMOUS_ACCESS}" \
     env GF_SERVER_PROTOCOL="${PROTOCOL}" \
     env GF_SERVER_CERT_KEY="${SSL_KEY}" \
     env GF_SERVER_CERT_FILE="${SSL_CERT}" \
     env INFLUXDB_URL="${INFLUXDB_URL}" \
     /run.sh
