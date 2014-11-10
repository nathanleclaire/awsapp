#!/bin/bash

DOCKER_HOST_NAME="aws_lightning_fast"
DOCKER_HUB_USER="nathanleclaire"
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

run_app_containers_from_image () {
    # take down backup container when main is still running...
    docker stop ${APP_CONTAINER}_backup &>/dev/null || true
    docker rm ${APP_CONTAINER}_backup &>/dev/null || true
    docker run -d \
        -p 8002:5000 \
        --link redis:redis \
        --name ${APP_CONTAINER}_backup \
        ${TAGGED_IMAGE}

    # ...then restart main
    docker stop ${APP_CONTAINER} &>/dev/null || true
    docker rm ${APP_CONTAINER} &>/dev/null || true
    docker run -d \
        -p 8001:5000 \
        --link redis:redis \
        --name ${APP_CONTAINER} \
        ${TAGGED_IMAGE}
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
        # check if host exists
        docker hosts inspect ${DOCKER_HOST_NAME} >/dev/null
        if [[ $? -eq 0 ]]; then
            echo "Host already exists, exiting."
            exit 0
        fi 

        push_haproxy_image
        push_tagged_image

        # make new ec2 host since one doesn't exit yet
        docker hosts create --driver ec2 --no-install ${DOCKER_HOST_NAME}

        docker run -d  \
            --net host \
            --name ${HAPROXY_CONTAINER} \
            ${HAPROXY_IMAGE}

        # start "database"
        docker run -d \
            --name redis \
            redis

        run_app_containers_from_image
        ;;
    down)
        docker hosts rm ${DOCKER_HOST_NAME}
        ;;
    deploy)
        set -e
        docker hosts active default

        # (DOCKER ON LAPTOP)
        # tag image with current timestamp for easy rollback
        push_tagged_image

        # (DOCKER ON SERVER)
        docker hosts active ${DOCKER_HOST_NAME}
        docker pull ${TAGGED_IMAGE}

        run_app_containers_from_image

        # go back to using local docker
        docker hosts active default

        print_deployed_msg
        echo "Access at " $(docker hosts ip ${DOCKER_HOST_NAME})
        ;;
    *)
        echo "Usage: deploy.sh [up|down|deploy]"
        exit 1
esac
