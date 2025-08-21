#!/usr/bin/env bash
set -euo pipefail

# bricksum-monitoring 중앙 컴포넌트 설치 스크립트

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${SCRIPT_DIR%/scripts}"
cd "$REPO_ROOT"

echo "[Bricksum Monitoring] 중앙 컴포넌트 설치를 시작합니다..."

# 필수 디렉토리 생성
mkdir -p grafana/dashboards grafana/provisioning/datasources grafana/provisioning/dashboards prometheus alertmanager

# docker compose 명령 탐지
if command -v docker >/dev/null 2>&1; then
  if docker compose version >/dev/null 2>&1; then
    COMPOSE_CMD="docker compose"
  elif command -v docker-compose >/dev/null 2>&1; then
    COMPOSE_CMD="docker-compose"
  else
    echo "오류: Docker Compose 플러그인/바이너리를 찾을 수 없습니다. docker compose 또는 docker-compose를 설치하세요." >&2
    exit 1
  fi
else
  echo "오류: Docker가 설치되어 있지 않습니다." >&2
  exit 1
fi

echo "[Bricksum Monitoring] 컨테이너를 기동합니다..."
$COMPOSE_CMD -f docker-compose.yml up -d

echo "[Bricksum Monitoring] 설치 완료"
echo "- Prometheus: http://localhost:9090"
echo "- Grafana:    http://localhost:3000 (ID: admin / PW: admin)"
echo "- Alertmanager: http://localhost:9093"


