## Prerequisites

- Install [minikube](https://github.com/kubernetes/minikube) and start it.
- Install [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/).
- Clone this repo.
- Initialize the submodules
  -  `git submodule init && git submodule update`


## Start minikube.


If you are using something other than virtualbox, specify the VM driver, like:

``minikube start --vm-driver hyperv``


## Activate your shell environment.

This configures the development namespace in minikube and causes your docker builds to land in the kubernetes vm registry.

``source bin/activate``

## When finished, Deactivate.


This will allow your builds to land in your host-side docker registry again.

``source bin/deactivate``


## Copy secrets template and fill in the values.


## Deploy secrets.
kubectl apply -f secrets/

## Work on code.

Components are laid out in git submodules: db, processing, and ui.

## Build an image to be stored in minikube's docker registry.

```
cd processing
docker build -t envirodgi/processing .
cd ..
```

You can verify that the image is in minikube's docker registry:
``minikube ssh docker images``


## Deploy the image you just built.
kubectl apply -f templates/processing.yaml

## Access it

The following will open a browser to the deployment endpoint.
```
minikube service diffing --namespace ${NAMESPACE}
```

The following will return the url to that same endpoint.
```
minikube service diffing --url --namespace ${NAMESPACE}
```

For convenience, you can also a forward a deployment's ports to localhost.
```
kubectl port-forward deployment.apps/diffing 80:80
```

would allow you to access the diffing app at ``http://127.0.0.1``


## Interact with a pod

If you need to execute a command within a pod, get its name by running

```
kubectl get pods
```

then exec your command using kubectl exec, like:
```
kubectl exec api-bd98678dd-24fvb bundle exec rake db:setup
```

## Troubleshooting.

While building ui, you may find that the yarn install steps error out. Yarn seems to have some sensitivity to the network conditions within kubernetes.  I found that doing a simple try loop got me through the build after a while.
```
time until docker build -t envirodgi/ui .; do echo "ERROR: build failed; retrying"; done
```

Over the course of several redeploys to an existing minikube cluster, you may find that memory usage creeps up.
If kubernetes begins to run out of memory, you can either configure plenty of memory before recreating the cluster, like:

``minikube config set memory 4096``

or just delete the cluster and start fresh.
