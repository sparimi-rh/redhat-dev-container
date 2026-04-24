#!/bin/bash
# Remove the Red Hat development container (preserves the volume)

CONTAINER_NAME="redhat-dev"

if podman ps -a --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
    echo "Removing container '${CONTAINER_NAME}'..."
    sudo podman rm -f ${CONTAINER_NAME}
    echo "Container removed. The volume 'redhat-dev-home' is preserved."
    echo "Run ./start.sh to create a new container with the same data."
else
    echo "Container '${CONTAINER_NAME}' does not exist."
fi
