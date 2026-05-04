#!/bin/bash
# Build script for Docker images in this monorepo
#
# Uses docker buildx to build for linux/amd64 platform.
# Requires docker buildx to be set up (run: docker buildx create --use)
#
# Usage:
#   ./build-docker.sh <tag> [push]
#
# Examples:
#   ./build-docker.sh latest
#   ./build-docker.sh v1.0.0 push

set -e

TAG="${1:-}"
PUSH="${2:-}"

if [ -z "$TAG" ]; then
  echo "Usage: $0 <tag> [push]"
  echo ""
  echo "Builds both Docker images (Rails and Python API) with the specified tag."
  echo "Uses docker buildx to build for linux/amd64 platform."
  echo ""
  echo "Arguments:"
  echo "  tag   - Docker image tag (required)"
  echo "  push  - Optional: specify 'push' to automatically push images to Docker Hub"
  echo ""
  echo "Examples:"
  echo "  $0 latest"
  echo "  $0 v1.0.0 push"
  exit 1
fi

RAILS_IMAGE="registry.nathanwhyte.dev/equal-risk/rails:${TAG}"
API_IMAGE="registry.nathanwhyte.dev/equal-risk/math:${TAG}"

# Build flags
BUILD_FLAGS="--platform linux/amd64"
if [ "${PUSH,,}" = "push" ]; then
  BUILD_FLAGS="${BUILD_FLAGS} --push"
fi

echo "=========================================="
echo "Building Docker Images"
echo "=========================================="
echo "Tag: ${TAG}"
echo "Platform: linux/amd64"
echo "Rails image: ${RAILS_IMAGE}"
echo "API image: ${API_IMAGE}"
if [ "${PUSH,,}" = "push" ]; then
  echo "Push to Docker Hub: enabled"
fi
echo ""

# Build Rails image
echo "Building Rails image..."
docker buildx build ${BUILD_FLAGS} -t "${RAILS_IMAGE}" .
echo "✓ Rails image built successfully"
echo ""

# Build API image
echo "Building API image..."
docker buildx build ${BUILD_FLAGS} -t "${API_IMAGE}" -f api/Dockerfile api/
echo "✓ API image built successfully"
echo ""

echo "=========================================="
echo "Build completed successfully!"
echo "=========================================="
echo ""
echo "Images:"
echo "  ${RAILS_IMAGE}"
echo "  ${API_IMAGE}"
