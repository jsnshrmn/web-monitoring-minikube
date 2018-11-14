#!/usr/bin/env bash

source bin/activate

kubectl apply -f secrets/

cd processing
docker build -t envirodgi/processing .
cd ../ui
# While building ui, you may find that the yarn install steps error out. Yarn seems to have some sensitivity to the network conditions within kubernetes.  I found that doing a simple try loop got me through the build after a while.
time until docker build -t envirodgi/ui .; do echo "ERROR: build failed; retrying"; done
cd ../db
docker build --target rails-server -t envirodgi/db-rails-server .
docker build --target import-worker -t envirodgi/db-import-worker .
cd ..

kubectl apply -f templates/

source bin/db_setup.sh
