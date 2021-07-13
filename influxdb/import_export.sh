#!/bin/bash

BACKUP_DIR="/home/ruuvimon/backups"
LAST_BACKUP="${BACKUP_DIR}/last_backup"
LOG_FILE="imex.log"
DB_NAME="tag_data"


function log()
{
    local -r msg="$1"
    printf "$(date --iso-8601=seconds) %b" "${msg}\n" | tee -a "${LOG_FILE}" >&2
}

function sync_files_to_remote()
{
    rsync -avz -e "ssh -p ${IMEX_PORT}" --ignore-existing --remove-source-files "${BACKUP_DIR}/" "${IMEX_USER}@${IMEX_HOST}:${IMEX_PATH}"
}

function enable_key_based_login()
{
    sshpass -p "${IMEX_PASSWORD}" ssh-copy-id -o StrictHostKeyChecking=no -p "${IMEX_PORT}" "${IMEX_USER}@${IMEX_HOST}"
}

function export_and_sync()
{
    log "Exporting..."
    if [ ! -f "${LAST_BACKUP}" ]; then
	last_backup=$(date --iso-8601=seconds)
	influxd backup -portable -database "${DB_NAME}" "${BACKUP_DIR}/${last_backup}"
	echo "${last_backup}" > "${LAST_BACKUP}"
    else
	last_backup=$(cat "${LAST_BACKUP}")
	influxd backup -since "${last_backup}" -portable -database "${DB_NAME}" "${BACKUP_DIR}/${last_backup}"
	date --iso-8601=seconds > "${LAST_BACKUP}"
    fi

    if [ -n "${IMEX_PATH}" ]; then
        sync_files_to_remote || enable_key_based_login && sync_files_to_remote
	find "${BACKUP_DIR}" -type d -empty -delete
    fi
}

function import()
{
    if [ ! -e "${IMEX_PATH}" ]; then
        mkdir -p "${IMEX_PATH}"
    fi

    log "Importing..."
    for dir in "${IMEX_PATH}"/*/; do
        if  [ -d "${dir}" ]; then
            /usr/bin/influxdb-incremental-restore -db "${DB_NAME}" -username "${INFLUXDB_USER}" -password "${INFLUXDB_PASSWORD}" "${dir}"
            log "Incrementally restored ${dir}: $?"
            rm -rf "${dir}"
        fi
    done
}

if [ "${RUUVIMON_MODE}" = "import" ]; then
    import
elif [ "${RUUVIMON_MODE}" = "export" ]; then
    export_and_sync
fi
