# Bricksum 경량 모니터링 MVP

Prometheus + Grafana + Alertmanager로 구성된 최소 실행(MVP) 모니터링 스택입니다. GPU(NVIDIA DCGM)와 시스템(Node Exporter) 지표를 수집/시각화/알림합니다.

## 구성

```
bricksum-monitoring/
├── docker-compose.yml
├── prometheus/
│   ├── prometheus.yml
│   └── alert.rules.yml
├── grafana/
│   ├── dashboards/
│   │   ├── node-exporter.json
│   │   └── nvidia-dcgm.json
│   └── provisioning/
│       ├── dashboards/dashboards.yml
│       └── datasources/prometheus.yml
├── alertmanager/alertmanager.yml
├── scripts/
│   ├── install.sh
│   └── install_exporter.sh
└── README.md
```

## 사전 준비

- 중앙 서버: Docker, Docker Compose(플러그인 또는 docker-compose 바이너리)
- 대상 서버(GPU 모니터링 시): NVIDIA 드라이버 + NVIDIA Container Toolkit (dcgm-exporter 구동용)

## 빠른 시작 (중앙 서버)

1) 저장소 루트에서 설치 스크립트 실행

```bash
cd bricksum-monitoring
./scripts/install.sh
```

2) 접속 URL

- Prometheus: `http://<중앙서버IP>:9090`
- Grafana: `http://<중앙서버IP>:3000` (기본 계정: admin / admin)
- Alertmanager: `http://<중앙서버IP>:9093`

## 대상 서버 Exporter 설치

대상 서버(모니터링할 서버)에서 다음 스크립트를 실행해 Exporter를 컨테이너로 기동합니다.

```bash
# 대상 서버에서
./scripts/install_exporter.sh
```

노드 Exporter는 9100, DCGM Exporter는 9400 포트로 노출됩니다.

## Prometheus 스크레이프 대상 추가

`prometheus/prometheus.yml`의 `scrape_configs`에 대상 서버의 IP:PORT를 추가하세요.

```yaml
scrape_configs:
  - job_name: "node_exporter"
    static_configs:
      - targets:
          - "10.0.0.10:9100"
          - "10.0.0.11:9100"

  - job_name: "dcgm_exporter"
    static_configs:
      - targets:
          - "10.0.0.10:9400"
          - "10.0.0.11:9400"
```

변경 후 Prometheus 핫리로드:

```bash
curl -X POST http://<중앙서버IP>:9090/-/reload
```

## Grafana 대시보드

- `grafana/dashboards/node-exporter.json` (Node Exporter 기본 지표)
- `grafana/dashboards/nvidia-dcgm.json` (GPU 사용률/메모리/온도)

컨테이너 기동 시 자동 Import 됩니다.

## Alertmanager 알림 설정

`alertmanager/alertmanager.yml`에서 이메일/슬랙 정보를 실제 운영 값으로 수정하세요.

```yaml
global:
  smtp_smarthost: 'smtp.example.com:587'
  smtp_from: 'alerts@example.com'
  smtp_auth_username: 'username'
  smtp_auth_password: 'password'
  slack_api_url: 'https://hooks.slack.com/services/...' 
```

변경 후 Alertmanager 재시작:

```bash
docker compose -f docker-compose.yml restart alertmanager
```

## 기본 계정/포트

- Grafana: `admin` / `admin` (3000)
- Prometheus: 9090
- Alertmanager: 9093
- Node Exporter: 9100 (대상 서버)
- DCGM Exporter: 9400 (대상 서버)

## 문제 해결

- Grafana가 대시보드를 못 읽는 경우: `grafana/provisioning/datasources`/`dashboards` 경로와 권한을 확인하세요.
- GPU가 감지되지 않는 경우: `nvidia-smi` 출력, NVIDIA Container Toolkit 설치 및 `--gpus all` 옵션 확인.



