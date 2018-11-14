#!/usr/bin/env bash

source bin/activate


# Delete all pods and secrets
kubectl delete --all secrets
kubectl delete --all all

# Delete all envirodg images from the local registry
minikube ssh docker rmi envirodgi/db-rails-server
minikube ssh docker rmi envirodgi/db-import-worker
minikube ssh docker rmi envirodgi/processing
minikube ssh docker rmi envirodgi/ui

# Create secrets
kubectl apply -f secrets/

# Build processing
cd processing
docker build -t envirodgi/processing .

# Build ui
cd ../ui
# While building ui, you may find that the yarn install steps error out. Yarn seems to have some sensitivity to the network conditions within kubernetes.  I found that doing a simple try loop got me through the build after a while.
until docker build -t envirodgi/ui .
do
    echo "ERROR: build failed; retrying"
done

# Build db
cd ../db
docker build --target rails-server -t envirodgi/db-rails-server .
docker build --target import-worker -t envirodgi/db-import-worker .
cd ..

# Deploy the new images to minikube
kubectl apply -f templates/


# Wait for rails server and postgres database to become available, then setup the db.
api_status='kubectl get pods --selector=app=api --output=jsonpath={.items..status.phase}'
rds_status='kubectl get pods --selector=app=rds --output=jsonpath={.items..status.phase}'

until [ "$(${api_status})" == "Running" ] && [ "$(${rds_status})" == "Running" ]
do
    echo "api status: $(${api_status})"
    echo "rds status: $(${rds_status})"
    sleep 1
done

source bin/db_setup.sh
