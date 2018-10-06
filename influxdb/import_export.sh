#!/bin/bash

BACKUP_BASE_DIR="/home/backups"
BACKUP_FILE_DIR="${BACKUP_BASE_DIR}/files"
LAST_BACKUP="${BACKUP_BASE_DIR}/last_backup"
LOG_FILE="${BACKUP_BASE_DIR}/log"


function export_and_sync()
{
    if [ ! -f "${LAST_BACKUP}" ]; then
	last_backup=$(date --iso-8601=seconds)
	influxd backup -portable -database tag_data "${BACKUP_FILE_DIR}/${last_backup}"
	echo "${last_backup}" > "${LAST_BACKUP}"
    else
	last_backup=$(cat "${LAST_BACKUP}")
	influxd backup -since "${last_backup}" -portable -database tag_data "${BACKUP_FILE_DIR}/${last_backup}"
	date --iso-8601=seconds > "${LAST_BACKUP}"
    fi

    if [ ! -z "${EXPORT_SYNC_PATH}" ]; then
	rsync -avz -e "ssh -p ${EXPORT_SYNC_PORT}" --ignore-existing --remove-source-files "${BACKUP_FILE_DIR}" "${EXPORT_SYNC_PATH}"
	echo "$(date --iso-8601=seconds)" " sync:" "$?"  >> "${LOG_FILE}"
	find "${BACKUP_FILE_DIR}" -type d -empty -delete
    fi
}

function import()
{
    for dir in "${BACKUP_FILE_DIR}"/*/; do
        if  [ -d "${dir}" ]; then
            /usr/bin/influxdb-incremental-restore -db tag_data "${dir}"
            echo "$(date --iso-8601=seconds)" " Incrementally restored ${dir}: $?" >> "${LOG_FILE}"
            rm -rf "${dir}"
        fi
    done
}

echo "$(date --iso-8601=seconds)" " MODE=${MODE} EXPORT_SYNC_PATH=${EXPORT_SYNC_PATH}"  >> "${LOG_FILE}"

if [ "${MODE}" = "import" ]; then
    import
elif [ "${MODE}" = "export" ]; then
    export_and_sync
fi
