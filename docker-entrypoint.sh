#!/bin/bash

: ${REPLICA_MAX_RETRIES:=40}
: ${REQUEST_TIMEOUT:=30}
: ${THREADS:=200}
: ${KEYFS_CACHE_SIZE:=100000}
: ${MIRROR_URL:="None"}

function defaults {
    : ${DEVPI_SERVERDIR="/data/server"}
    : ${DEVPI_CLIENTDIR="/data/client"}

    echo "DEVPI_SERVERDIR is ${DEVPI_SERVERDIR}"
    echo "DEVPI_CLIENTDIR is ${DEVPI_CLIENTDIR}"

    export DEVPI_SERVERDIR DEVPI_CLIENTDIR
}

function initialise_devpi {
    echo "[RUN]: Initialise devpi-server"
    devpi-server --restrict-modify root --start --host 127.0.0.1 --port 3141 --init
    devpi-server --status
    devpi use http://localhost:3141
    devpi login root --password=''
    devpi user -m root password="${DEVPI_PASSWORD}"
    devpi index -y -c public pypi_whitelist='*'
    if [ "$MIRROR_URL" != "None" ]; then
        devpi index root/pypi mirror_url="${MIRROR_URL}"
    fi
    devpi-server --stop
    devpi-server --status
}

defaults

if [ "$1" = 'devpi' ]; then
    if [ ! -f  $DEVPI_SERVERDIR/.serverversion ]; then
        initialise_devpi
    fi

    echo "[RUN]: Launching devpi-server"
    exec devpi-server --restrict-modify root --host 0.0.0.0 --port 3141 \
        --replica-max-retries $REPLICA_MAX_RETRIES --request-timeout $REQUEST_TIMEOUT \
        --threads $THREADS --keyfs-cache-size $KEYFS_CACHE_SIZE
fi

echo "[RUN]: Builtin command not provided [devpi]"
echo "[RUN]: $@"

exec "$@"
