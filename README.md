
Install [minikube](https://github.com/kubernetes/minikube) and start it.
Install [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/).


## Activate your shell environment.
``source bin/activate``

## When finished, detivate your shell environment to have docker images stored in your host-side docker registry.
``source bin/deactivate``

## Work on code.
Components are laid out in git submodules: db, processing, and ui.

## Build an image to be stored in minikube's docker registry.
```
cd processing
docker build -t processing .
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

@TODO: Figure out how to exposed a properly mapped service port in minikube.
