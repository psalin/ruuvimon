#!/bin/bash
#
# RuuviMon stop script

function usage() {
       cat << HEREDOC

   Usage: $0 [--remove] [--help]

   Stops the RuuviMon app.

   Optional arguments:
     -h, --help           show this help message and exit
     -r, --remove         removes containers after stopping

HEREDOC
}

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -h|--help) usage; exit 0;;
        -r|--remove) remove=1;;
        *) echo "Unknown parameter passed: $1"; usage; exit 1;;
    esac
    shift
done

if [[ "${remove}" -eq 1 ]]; then
    # Stops and removes containers
    docker-compose down
else
    # Stops but doesn't remove the containers
    docker-compose stop
fi
