#!/bin/bash

ANONYMOUS_ACCESS=false

if [[ "${GRAFANA_AUTH_ENABLED}" != "true" ]]; then
   ANONYMOUS_ACCESS=true
fi

exec env GF_AUTH_ANONYMOUS_ENABLED="${ANONYMOUS_ACCESS}" \
     /run.sh
