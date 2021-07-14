#!/bin/bash

INTERVAL_MINS="${IMEX_INTERVAL_MINS}"
SSL_KEY=/etc/ssl/influxdb-selfsigned.key
SSL_CERT=/etc/ssl/influxdb-selfsigned.crt

function start_ssh_server() {
    echo "root:${IMEX_PASSWORD}" | chpasswd
    sed -ri 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
    service ssh restart
}

# Generate SSH key
ssh-keygen -f /root/.ssh/id_rsa -t rsa -N ''

# In import mode, start a SSH server for receiving data
if [[ "${RUUVIMON_MODE}" == "import" ]]; then
    start_ssh_server
fi

# Run import/export in case enabled
if [[ "${RUUVIMON_MODE}" != "standalone" ]]; then
    while true
    do
        ./import_export.sh
        sleep $((INTERVAL_MINS*60))
    done &
fi

if [[ "${INFLUXDB_HTTPS_ENABLED}" == "true" ]]; then
    openssl req -x509 -nodes -newkey rsa:2048 -keyout "${SSL_KEY}" -out "${SSL_CERT}" -days 3650 -subj "/O=Ruuvimon/OU=Ruuvimon/CN=localhost"
fi

INFLUXDB_HTTP_AUTH_ENABLED="${INFLUXDB_AUTH_ENABLED}" \
                          INFLUXDB_ADMIN_USER="${INFLUXDB_USER}" \
                          INFLUXDB_ADMIN_PASSWORD="${INFLUXDB_PASSWORD}" \
                          /init-influxdb.sh

INFLUXDB_HTTP_AUTH_ENABLED="${INFLUXDB_AUTH_ENABLED}" \
                          INFLUXDB_HTTP_HTTPS_CERTIFICATE="${SSL_CERT}" \
                          INFLUXDB_HTTP_HTTPS_PRIVATE_KEY="${SSL_KEY}" \
                          INFLUXDB_HTTP_HTTPS_ENABLED="${INFLUXDB_HTTPS_ENABLED}" \
                          influxd
