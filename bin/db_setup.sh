#!/usr/bin/env bash

source bin/activate

app=api
pod=$(kubectl get pods --selector=app=${api} --output=jsonpath={.items..metadata.name})

kubectl exec ${db_pod} bundle exec rake db:create

kubectl exec ${db_pod} bundle exec rake db:schema:load

echo "User.create(email: 'seed-admin@example.com', password: 'PASSWORD', admin: true, confirmed_at: Time.now)" | kubectl exec -it ${pod} bundle exec rails console
