#!/bin/bash
# Stop the Red Hat development container (doesn't remove it)

CONTAINER_NAME="redhat-dev"

if sudo podman ps --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
    echo "Stopping container '${CONTAINER_NAME}'..."
    sudo podman stop ${CONTAINER_NAME}
    echo "Container stopped. Run ./start.sh to restart it."
else
    echo "Container '${CONTAINER_NAME}' is not running."
fi
