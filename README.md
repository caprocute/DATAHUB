# LGSP — Nền tảng tích hợp, chia sẻ dữ liệu

Trục tích hợp nội bộ cấp bộ/tỉnh: Apache Camel · Spring Boot DU · GitOps · open-source.

## Điểm vào tài liệu

| Tài liệu | Khi nào đọc |
|---|---|
| [wiki/00-INDEX.md](wiki/00-INDEX.md) | Mọi phiên làm việc |
| [IP-03 Stack chốt](docs/08-implementation/03-stack-cong-nghe.md) | Chọn thư viện |
| [IP-04 Kế hoạch](docs/08-implementation/04-ke-hoach-phat-trien.md) | Phát triển / giao agent |
| [AGENTS.md](AGENTS.md) | Trước khi AI/agent viết mã |
| [ADR](docs/05-adr/README.md) | Vì sao chọn công nghệ |

## Yêu cầu máy DEV

- **Java 21** (Temurin) — bắt buộc theo ADR-020 (máy có JDK mới hơn vẫn được nếu `maven.compiler.release=21`)
- Maven 3.9+
- Node 22 LTS (console)
- Docker + Compose

```bash
# gợi ý macOS
brew install --cask temurin@21
export JAVA_HOME=$(/usr/libexec/java_home -v 21)
```

## Chạy hạ tầng DEV

```bash
cp .env.example .env
make up-dev          # Postgres, Valkey, Garage, Keycloak, Mailpit
make ps
make down-dev
```

Cổng mặc định (xem `.env.example`):

| Dịch vụ | Cổng |
|---|---|
| Postgres | 5432 |
| Valkey | 6379 |
| Garage S3 API | 3900 |
| Garage Admin | 3902 |
| SeaweedFS S3 (WORM) | 8333 |
| Keycloak | 8081 |
| Mailpit UI | 8025 |
| Control API (local) | 8080 |
| Console Vite | 5173 |

## Build mã

```bash
make build-java      # libs + apps/control
make run-control     # Spring Boot control (cần infra)
cd camel/dancu && ./mvnw quarkus:dev   # sau khi có wrapper
cd apps/console && npm install && npm run dev
```

## Cấu trúc monorepo

Xem [IP-02 §1](docs/08-implementation/02-huong-dan-lap-trinh.md). Tóm tắt: `apps/` (Boot DU) · `camel/` (Quarkus) · `contracts/` · `deploy/` · `docs/` · `mockup/`.

## Wave hiện tại

**W1 — Thin-slice E2E** (IP-04): kết nạp → catalog → APISIX → Camel → WireMock.

```bash
make up-dev
make run-control    # :8080
make run-adapter    # :8082
make run-camel      # :8088
make console-dev    # :5173
make e2e-thin       # WP-16
```

## Branch protection (bật khi có remote)

- `main`: require PR + Gate A/S xanh · cấm force-push
- Environments: `staging` / `production` cần approve
