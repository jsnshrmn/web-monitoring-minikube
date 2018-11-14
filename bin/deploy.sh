#!/usr/bin/env bash

if [  -z "$1" ]; then
    set="all"
else
    set=${1}
fi

source bin/activate

# Delete processing pods and secrets
if [ "$set" == "all" ] || [ "$set" == "processing" ]
then
    kubectl delete secrets/processing-secrets
    kubectl delete deployment.apps/diffing
    kubectl delete service/diffing

    # Delete envirodg images from the local registry
    minikube ssh 'docker rmi --force envirodgi/processing'

    # Build processing
    cd processing
    docker build -t envirodgi/processing .
    cd ..
fi

# Delete ui pods and secrets
if [ "$set" == "all" ] || [ "$set" == "ui" ]
then
    kubectl delete secrets/ui-secrets
    kubectl delete deployment.apps/ui
    kubectl delete service/ui

    # Delete envirodg images from the local registry
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

# Delete db pods and secrets
if [ "$set" == "all" ] || [ "$set" == "db" ]
then
    kubectl delete secrets/api-secrets
    kubectl delete deployment.apps/api
    kubectl delete service/api

    kubectl delete deployment.apps/rds
    kubectl delete service/rds

    # Delete envirodg images from the local registry
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
