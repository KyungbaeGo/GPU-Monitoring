#!/usr/bin/env bash
set -euo pipefail

# 모니터링 대상 서버에 node exporter와 NVIDIA DCGM exporter를 Docker로 설치합니다.

echo "[Bricksum Monitoring] Exporter 설치를 시작합니다..."

if ! command -v docker >/dev/null 2>&1; then
  echo "오류: Docker가 설치되어 있지 않습니다. Docker를 먼저 설치하세요." >&2
  exit 1
fi

# 기존 컨테이너 정리
if docker ps -a --format '{{.Names}}' | grep -wq node-exporter; then
  docker rm -f node-exporter >/dev/null 2>&1 || true
fi
if docker ps -a --format '{{.Names}}' | grep -wq dcgm-exporter; then
  docker rm -f dcgm-exporter >/dev/null 2>&1 || true
fi

echo "[Bricksum Monitoring] node-exporter 컨테이너를 실행합니다 (포트 9100)."
docker run -d \
  --name node-exporter \
  --restart unless-stopped \
  --net host \
  --pid host \
  -v "/:/host:ro,rslave" \
  quay.io/prometheus/node-exporter:v1.8.2 \
  --path.rootfs=/host

if command -v nvidia-smi >/dev/null 2>&1; then
  echo "[Bricksum Monitoring] NVIDIA GPU가 감지되었습니다. dcgm-exporter 컨테이너를 실행합니다 (포트 9400)."
  # NVIDIA Container Toolkit이 설치되어 있어야 합니다.
  docker run -d \
    --name dcgm-exporter \
    --restart unless-stopped \
    --net host \
    --gpus all \
    nvidia/dcgm-exporter:3.3.5-3.4.2-ubuntu22.04
else
  echo "경고: nvidia-smi를 찾을 수 없습니다. GPU가 없거나 드라이버/툴킷이 설치되지 않았습니다. dcgm-exporter는 생략합니다."
fi

echo "[Bricksum Monitoring] Exporter 설치 완료"
echo "- node-exporter : 9100/tcp"
echo "- dcgm-exporter : 9400/tcp (GPU 및 NVIDIA Container Toolkit 필요)"

