#!/bin/bash
# Start container using root podman (works around high UID namespace issues)

CONTAINER_NAME="redhat-dev"
IMAGE_NAME="redhat-dev:latest"
USERNAME=$(id -un)
USER_ID=$(id -u)
GROUP_ID=$(id -g)

# VDDK path (optional - mount only if exists)
VDDK_MOUNT=""
if [ -d "${HOME}/vmware-vix-disklib" ]; then
    echo "VDDK found at ${HOME}/vmware-vix-disklib - mounting into container"
    VDDK_MOUNT="-v ${HOME}/vmware-vix-disklib:/opt/vmware-vix-disklib:ro"
fi

# Check if container already exists
if sudo podman ps -a --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
    echo "Container '${CONTAINER_NAME}' exists."

    # Check if it's running
    if sudo podman ps --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
        echo "Container is already running. Attaching..."
        sudo podman exec -it -u ${USERNAME} ${CONTAINER_NAME} /bin/bash
    else
        echo "Starting existing container..."
        sudo podman start ${CONTAINER_NAME}
        sudo podman exec -it -u ${USERNAME} ${CONTAINER_NAME} /bin/bash
    fi
else
    echo "Creating and starting new container (using root podman)..."
    sudo podman run -it \
        --name ${CONTAINER_NAME} \
        --hostname redhat-dev \
        -v "${HOME}/.gitconfig:/home/${USERNAME}/.gitconfig:ro" \
        -v "${HOME}/.ssh:/home/${USERNAME}/.ssh:ro" \
        -v "${HOME}/workspace:/workspace" \
        ${VDDK_MOUNT} \
        -v "redhat-dev-home:/home/${USERNAME}" \
        ${IMAGE_NAME} \
        /bin/bash
fi
