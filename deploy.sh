#!/bin/bash

set -e

DOCKER_HOST_NAME="awslightningfast"

if [[ -z "$DOCKER_HUB_USER" ]]; then
    DOCKER_HUB_USER="nathanleclaire"
fi
APP_IMAGE="awsapp"
REMOTE_IMAGE=${DOCKER_HUB_USER}/${APP_IMAGE}
IMAGE_TAG=$(date | sed 's/ /_/g' | sed 's/:/_/g')
TAGGED_IMAGE=${REMOTE_IMAGE}:${IMAGE_TAG}
NUM_BACKUPS=2
APP_CONTAINER="aws_lightning_app"
HAPROXY_CONTAINER="lightning_haproxy"
HAPROXY_IMAGE="${DOCKER_HUB_USER}/haproxy"

MESSAGE_FILENAME=msg.txt

print_deployed_msg () {
    cat ${MESSAGE_FILENAME}
}

set_host_default () {
    if [[ ! -e /var/run/docker.sock ]]; then
        $(boot2docker shellinit)
    fi
}

cfg () {
    echo $(docker-machine config ${DOCKER_HOST_NAME})
}

set_health () {
    # why || true?
    # because when we run for the first time our app
    # containers will not exist yet.
    # this would cause an error (non-0 exit code) 
    # which would stop the script due to set -e.
    docker \
        $(cfg) \
        run -it \
        --net host \
        nathanleclaire/curl \
        curl "localhost:$1/health/$2" &>/dev/null || true

    # give haproxy a second to catch up
    # health check is done in 100ms intervals so this is 
    # a decent amount of "catch-up" time
    sleep 1
}

run_app_containers_from_image () {
    for i in {0..1}; do
        PORT=800${i}
        # take down backup container when main is still running...
        set_health $PORT off

        # same reason for || true here as listed above.
        # these containers don't exist first time we run this.
        docker $(cfg) stop ${APP_CONTAINER}_${i} &>/dev/null || true
        docker $(cfg) rm ${APP_CONTAINER}_${i} &>/dev/null || true

        docker $(cfg) \
            run -d \
            -e SRV_NAME=s${i} \
            -p ${PORT}:5000 \
            --link redis:redis \
            --name ${APP_CONTAINER}_${i} \
            $1

        # give app a second to come back up
        sleep 1
    done
}

push_tagged_image () {
    echo ${TAGGED_IMAGE}
    docker build -t ${TAGGED_IMAGE} .

    # push image out to docker hub
    docker push ${TAGGED_IMAGE}
}

push_haproxy_image () {
    # only push haproxy image once so no function
    cd haproxy
    docker build -t ${HAPROXY_IMAGE} .
    docker push ${HAPROXY_IMAGE}
    cd ..
}

case $1 in 
    up)
        set +e
        # check if host exists
        docker-machine inspect ${DOCKER_HOST_NAME} >/dev/null
        if [[ $? -eq 0 ]]; then
            echo "Host already exists, exiting."
            exit 0
        fi 
        set -e

        push_haproxy_image
        push_tagged_image

        # make new ec2 host since one doesn't exit yet
        docker-machine create --driver amazonec2 ${DOCKER_HOST_NAME}

        docker $(cfg) \
            run -d  \
            --net host \
            --name ${HAPROXY_CONTAINER} \
            ${HAPROXY_IMAGE}

        # start "database"
        docker $(cfg) \
            run -d \
            --name redis \
            redis

        run_app_containers_from_image ${TAGGED_IMAGE}
        ;;
    down)
        docker-machine rm ${DOCKER_HOST_NAME}
        ;;
    deploy)
        set_host_default

        # (DOCKER ON LAPTOP)
        # tag image with current timestamp for easy rollback
        push_tagged_image

        # (DOCKER ON SERVER)
        docker-machine active ${DOCKER_HOST_NAME}
        docker pull ${TAGGED_IMAGE}

        run_app_containers_from_image ${TAGGED_IMAGE}

        set_host_default

        print_deployed_msg
        echo "Access at " $(docker-machine ip ${DOCKER_HOST_NAME})
        ;;
    reload-haproxy)
        push_haproxy_image
        docker-machine active ${DOCKER_HOST_NAME}
        docker pull ${HAPROXY_IMAGE}
        docker stop ${HAPROXY_CONTAINER}
        docker rm ${HAPROXY_CONTAINER}
        docker run -d  \
            --net host \
            --name ${HAPROXY_CONTAINER} \
            ${HAPROXY_IMAGE}
        set_host_default
        ;;
    rollback)
        docker-machine active ${DOCKER_HOST_NAME}
        run_app_containers_from_image ${REMOTE_IMAGE}:$2
        set_host_default
        ;;
    *)
        echo "Usage: deploy.sh [up|down|deploy|reload-haproxy|rollback]"
        exit 1
esac
