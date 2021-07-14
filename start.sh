#!/bin/bash
#
# Ruuvimon startup script

function generate_password()
{
    head -n 10 /dev/urandom | tr -dc A-Za-z0-9 | head -c10
}

function replace_password_in_env_file()
{
    local -r password=$1
    sed -i -e "s/INFLUXDB_PASSWORD=<auto-generate>/INFLUXDB_PASSWORD=${password}/g" .env
}

# Auto-generates a password for InfluxDB and sets it in the .env file if needed
function auto_generate_influxdb_password()
{
    if grep -Fxq "INFLUXDB_PASSWORD=<auto-generate>" .env; then
        local -r new_password=$(generate_password)
        replace_password_in_env_file "${new_password}"
    fi
}

auto_generate_influxdb_password
docker-compose up -d
