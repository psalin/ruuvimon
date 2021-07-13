#!/bin/bash

INTERVAL_MINS="${IMEX_INTERVAL_MINS}"


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

INFLUXDB_HTTP_AUTH_ENABLED="${INFLUXDB_AUTH_ENABLED}" \
                          INFLUXDB_ADMIN_USER="${INFLUXDB_USER}" \
                          INFLUXDB_ADMIN_PASSWORD="${INFLUXDB_PASSWORD}" \
                          /init-influxdb.sh

INFLUXDB_HTTP_AUTH_ENABLED="${INFLUXDB_AUTH_ENABLED}" \
                          influxd
