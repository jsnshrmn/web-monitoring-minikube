
Install [minikube](https://github.com/kubernetes/minikube) and start it.
Install [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/).


## Activate your shell environment.

This configures the development namespace in minikube and causes your docker builds to land in the kubernetes vm registry.

``source bin/activate``

## When finished, Deactivate.


This will allow your builds to land in your host-side docker registry again.

``source bin/deactivate``

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


## Troubleshooting.

While building ui, you may find that the yarn install steps error out. Yarn seems to have some sensitivity to the network conditions within kubernetes.  I found that doing a simple try loop got me through the build after a while.
```
time until docker build -t envirodgi/ui .; do echo "ERROR: build failed; retrying"; done
```

