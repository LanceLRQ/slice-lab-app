#!/usr/bin/env bash
set -e

IMAGE_NAME="qwen3-asr-service"
VERSION="${IMAGE_VERSION:-latest}"

echo "Building ${IMAGE_NAME}:${VERSION} ..."
docker build -t "${IMAGE_NAME}:${VERSION}" .

echo ""
echo "Build complete:"
echo "  ${IMAGE_NAME}:${VERSION}"
echo ""
echo "Run example:"
echo "  docker run --gpus all -p 8765:8765 -v /path/to/models:/app/models ${IMAGE_NAME}:latest"
