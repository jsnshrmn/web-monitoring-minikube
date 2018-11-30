#!/usr/bin/env bash

if [  -z "$1" ]; then
    set="all"
else
    set=${1}
fi

source bin/activate

# Attempt to delete dangling images. If a dangling image is in use, delete the offending containers.
killfail=$(minikube ssh 'docker rmi --force $(docker images -f "dangling=true" -q)'| grep 'image is being used by running container')
if [ "${killfail}" ]
then
    echo ${killfail}
    killme=${killfail##* }
    minikube ssh "docker rm --force ${killme}" && echo "Deleted running container ${killme}."
    minikube ssh 'docker rmi --force $(docker images -f "dangling=true" -q)'
fi

if [ "$set" == "all" ] || [ "$set" == "processing" ]
then
    # Delete processing pods, secrets, and service
    kubectl delete secrets/processing-secrets
    kubectl delete deployment.apps/diffing
    kubectl delete service/diffing

    # Delete envirodgi processing images from the local registry
    minikube ssh 'docker rmi --force envirodgi/processing'

    # Build processing
    cd processing
    docker build -t envirodgi/processing .
    cd ..
fi

if [ "$set" == "all" ] || [ "$set" == "ui" ]
then
    # Delete ui pods, secrets, and service
    kubectl delete secrets/ui-secrets
    kubectl delete deployment.apps/ui
    kubectl delete service/ui

    # Delete envirodgi ui images from the local registry
    minikube ssh 'docker rmi --force envirodgi/ui'

    # Build ui
    cd ui
    # While building ui, you may find that the yarn install steps error out. Yarn seems to have some sensitivity to the network conditions within kubernetes.  I found that doing a simple try loop got me through the build after a while.
    until docker build -t envirodgi/ui .
    do
        echo "ERROR: build failed; retrying"
    done
    cd ..
fi

if [ "$set" == "all" ] || [ "$set" == "db" ]
then
    # Delete db pods, secrets, and service
    kubectl delete secrets/api-secrets
    kubectl delete deployment.apps/api
    kubectl delete deployment.apps/import-worker
    kubectl delete service/api

    # Delete postgres database pod and service.
    kubectl delete deployment.apps/rds
    kubectl delete service/rds
    # Start recreating it immediately so it's up when we need it.
    kubectl apply -f templates/rds.yaml

    # Delete envirodgi api images from the local registry
    minikube ssh 'docker rmi --force envirodgi/db-rails-server'
    minikube ssh 'docker rmi --force envirodgi/db-import-worker'

    # Build db
    cd db
    docker build --target rails-server -t envirodgi/db-rails-server .
    docker build --target import-worker -t envirodgi/db-import-worker .
    cd ..
fi

if [ "$set" == "db-min" ]
then
    # Delete db pods, secrets, and service
    kubectl delete secrets/api-secrets
    kubectl delete deployment.apps/api
    kubectl delete deployment.apps/import-worker
    kubectl delete service/api

    # Delete envirodgi api images from the local registry
    minikube ssh 'docker rmi --force envirodgi/db-rails-server'
    minikube ssh 'docker rmi --force envirodgi/db-import-worker'

    # Build db
    cd db
    docker build --target rails-server -t envirodgi/db-rails-server .
    docker build --target import-worker -t envirodgi/db-import-worker .
    cd ..
fi

# Create secrets
kubectl apply -f secrets/

# Deploy the new images to minikube
kubectl apply -f templates/

if [ "$set" == "all" ] || [ "$set" == "db" ]
then
    source bin/db_setup.sh
fi
