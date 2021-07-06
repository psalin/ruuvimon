#!/bin/bash

IMPORT_EXPORT_INTERVAL_MINS="${IMPORT_EXPORT_INTERVAL_MINS:-240}"

while true
do
    ./import_export.sh
    sleep $((IMPORT_EXPORT_INTERVAL_MINS*60))
done &

influxd
