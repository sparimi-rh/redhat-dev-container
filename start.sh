#!/bin/bash
# Start or attach to the Red Hat development container

CONTAINER_NAME="redhat-dev"
IMAGE_NAME="redhat-dev:latest"
USERNAME=$(id -un)

# VDDK path (optional - mount only if exists)
VDDK_MOUNT=""
if [ -d "${HOME}/vmware-vix-disklib" ]; then
    echo "VDDK found at ${HOME}/vmware-vix-disklib - mounting into container"
    VDDK_MOUNT="-v ${HOME}/vmware-vix-disklib:/opt/vmware-vix-disklib:ro"
fi

# Check if container already exists
if podman ps -a --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
    echo "Container '${CONTAINER_NAME}' exists."

    # Check if it's running
    if podman ps --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
        echo "Container is already running. Attaching..."
        podman exec -it ${CONTAINER_NAME} /bin/bash
    else
        echo "Starting existing container..."
        podman start ${CONTAINER_NAME}
        podman exec -it ${CONTAINER_NAME} /bin/bash
    fi
else
    echo "Creating and starting new container..."
    # Use --group-add keep-groups to handle high GID ranges
    podman run -it \
        --name ${CONTAINER_NAME} \
        --hostname redhat-dev \
        --userns=keep-id:uid=1000,gid=1000 \
        --group-add keep-groups \
        -v "${HOME}/.gitconfig:/home/${USERNAME}/.gitconfig:ro" \
        -v "${HOME}/.ssh:/home/${USERNAME}/.ssh:ro" \
        -v "${HOME}/workspace:/workspace:z" \
        ${VDDK_MOUNT} \
        -v "redhat-dev-home:/home/${USERNAME}" \
        ${IMAGE_NAME} \
        /bin/bash
fi
