# farmos-k8s

This project sets up a Docker image for farmOS with additional modules, designed to run on Kubernetes.

## Included Modules

The following modules are included in this setup:

- `farm_ledger`
- `farmos_asset_link`
- `gin_login`
- `farm_organic`
- `farm_map_custom_layers`
- `farm_map_google`
- `farm_crop_plan`
- `oauth_login_oauth2`

## Building the Docker Image

To build the Docker image, run the following command:

```sh
docker build -t farmos-k8s .
```

## Running the Docker Container
```sh
docker run -p 80:80 farmos-k8s
```

## Deploying to Kubernetes

1. Ensure you have a Kubernetes cluster set up and `kubectl` configured.
2. Create a Kubernetes deployment and service configuration in the `k8s` directory.
3. Apply the configurations using `kubectl`:

```sh
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
```

## Adding Modules

To add or update modules, modify the `composer.json` file in the `project` directory and rebuild the Docker image.


## Support

For support, visit the following resources:

- [Documentation](https://farmOS.org/guide)
- [Forum](https://farmOS.discourse.group)
- [Chat](https://matrix.to/#/#farmOS:matrix.org)