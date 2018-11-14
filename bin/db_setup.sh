#!/usr/bin/env bash

source bin/activate

# Wait for rails server and postgres database to become available, then setup the db.
api_status='kubectl get pods --selector=app=api --output=jsonpath={.items..status.phase}'
rds_status='kubectl get pods --selector=app=rds --output=jsonpath={.items..status.phase}'
until [ "$(${api_status})" == "Running" ] && [ "$(${rds_status})" == "Running" ]
do
    echo "api status: $(${api_status})"
    echo "rds status: $(${rds_status})"
    sleep 5
done

pod=$(kubectl get pods --selector=app=api --output=jsonpath={.items..metadata.name})

kubectl exec ${pod} bundle exec rake db:create && \
kubectl exec ${pod} bundle exec rake db:schema:load && \
echo "User.create(email: 'seed-admin@example.com', password: 'PASSWORD', admin: true, confirmed_at: Time.now)" | kubectl exec -it ${pod} bundle exec rails console
