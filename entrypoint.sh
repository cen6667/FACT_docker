#!/bin/bash

set -e

start () {
    # This path could be configurable
    # It is not really necessary to make it configurable since there is no
    # usecase to change the database path inside the docker container
    if [ -e /media/data/fact_wt_mongodb/REINITIALIZE_DB ]; then
        python3 /opt/FACT_core/src/init_database.py && \
            rm /media/data/fact_wt_mongodb/REINITIALIZE_DB
    fi
    exec /opt/FACT_core/start_all_installed_fact_components "$@"
}

case "$1" in
    "start")
        shift 1
        start $@
    ;;
    "start-branch")
        shift 1
        git --git-dir=/opt/FACT_core/.git checkout $1
        shift 1
        start $@
    ;;
    "pull-containers")
        # We can't to this in the Dockerfile, because the docker socket is not shared to there
        exec /opt/FACT_core/src/install.py \
            --backend-docker-images \
            --frontend-docker-images
    ;;
    *)
        printf "See https://github.com/fkie-cad/FACT_docker for how to start this container\n"
        exit 0
esac