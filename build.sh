#!/bin/bash
# Build the Red Hat development container

set -e

# Get current user's username
USERNAME=$(id -un)

# For high UIDs (>100000), use default UID 1000 in container
# File ownership will be handled by podman's user namespace mapping
USER_ID=$(id -u)
GROUP_ID=$(id -g)

if [ ${USER_ID} -gt 100000 ]; then
    echo "High UID detected (${USER_ID}), using UID 1000 inside container"
    echo "Podman will handle UID mapping automatically"
    USER_ID=1000
    GROUP_ID=1000
fi

echo "Building Red Hat development container..."
echo "  User: ${USERNAME}"
echo "  Container UID: ${USER_ID}"
echo "  Container GID: ${GROUP_ID}"

podman build \
    --build-arg USER_ID=${USER_ID} \
    --build-arg GROUP_ID=${GROUP_ID} \
    --build-arg USERNAME=${USERNAME} \
    -t redhat-dev:latest .

echo ""
echo "Build complete! Run ./start.sh to start the container."
