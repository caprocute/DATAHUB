# Deploy — DEV compose & Kustomize

Lane: **L-PLAT**. Bám [IP-04 WP-01](../docs/08-implementation/04-ke-hoach-phat-trien.md) · [ADR-020](../docs/05-adr/README.md#adr-020).

## Compose DEV

```bash
cp ../.env.example ../.env
make -C .. up-dev
```

### Cổng (mặc định)

| Dịch vụ | Host port | Ghi chú |
|---|---|---|
| Postgres 17 | 5432 | schemas `ph01`… qua init-db |
| Valkey 8 | 6379 | |
| Garage S3 | 3900 | S3 chung DEV — **không** Object Lock |
| Garage RPC | 3901 | |
| Garage Admin | 3902 | |
| SeaweedFS S3 | 8333 | **Audit / WORM** (CMP-28) |
| SeaweedFS Master | 9333 | |
| Keycloak | 8081 | realm `lgsp` |
| OPA | 8181 | PEP `contracts/opa` (WP-30) |
| Mailpit SMTP / UI | 1025 / 8025 | |
| Control (app local) | 8080 | ngoài compose |
| Adapter-mgr (app local) | 8082 | ngoài compose |
| Data `lgsp-data` (app local) | 8083 | ngoài compose · `make run-data` |
| Camel dancu (app local) | 8088 | ngoài compose |
| Console Vite | 5173 | ngoài compose |

## Token Keycloak DEV

```bash
curl -s -X POST 'http://localhost:8081/realms/lgsp/protocol/openid-connect/token' \
  -d 'client_id=lgsp-console' \
  -d 'grant_type=password' \
  -d 'username=dev-reviewer' \
  -d 'password=dev-reviewer' | jq -r .access_token
```

Users DEV: `dev-reviewer` / `dev-reviewer` · `dev-admin` / `dev-admin` (xem `compose/keycloak/realm-lgsp.json`).

Issuer JWT cho control: `http://localhost:8081/realms/lgsp`.

## Object storage — biên bản kiểm chứng (W0 · 2026-08-04)

### A. Garage (S3 chung)

| Hạng mục | Giá trị |
|---|---|
| Ảnh | `dxflrs/garage:v2.1.0` (Docker Hub chính thức; **không** `dxflue/…`) |
| Cấu hình | `compose/garage/garage.toml` — 1 nút, `replication_factor=1` |
| S3 endpoint | `http://localhost:3900` · region `garage` |
| Layout | Node assign zone `dc1` capacity `1G` · `layout apply --version 1` — **OK** |
| Put/Get object | Bucket `lgsp-audit` — **OK** |

| Object Lock API | Kết quả trên Garage 2.1.0 |
|---|---|
| `PutObjectLockConfiguration` | `NotImplemented` |
| `PutObjectRetention` | `NotImplemented` |
| `GetObjectRetention` | `NotImplemented` |

→ Garage **không đủ** WORM/CMP-28 tại thời điểm kiểm chứng. Giữ Garage cho object thường; audit dùng SeaweedFS.

### B. SeaweedFS (audit WORM — CMP-28)

| Hạng mục | Giá trị |
|---|---|
| Ảnh | `chrislusf/seaweedfs:3.97` |
| S3 endpoint | `http://localhost:8333` |
| Credential DEV | `lgsp_audit_dev` / xem `compose/seaweedfs/s3.json` |
| Ngày kiểm chứng | 2026-08-04 |

| Bước | Kết quả | Người / ngày |
|---|---|---|
| `create-bucket --object-lock-enabled-for-bucket` | **OK** — `ObjectLockEnabled=Enabled` | agent · 2026-08-04 |
| Put object + retention `COMPLIANCE` 30 ngày | **OK** — `get-object-retention` trả Mode/RetainUntilDate | agent · 2026-08-04 |
| `delete-object --version-id` trong kỳ retention | **Bị từ chối** `AccessDenied` — object vẫn HEAD được | agent · 2026-08-04 |

**Kết luận W0:** Object storage DEV = **Garage (chung) + SeaweedFS (WORM audit)**. **Không dùng MinIO.**

## Baseline phiên bản cụm (điền khi có cluster)

| Thành phần | Bản xác nhận trên cụm | Ngày |
|---|---|---|
| CloudNativePG → PG major | _chưa_ (DEV compose = Postgres 17) | |
| Strimzi → Kafka | _chưa_ (Kafka optional W0) | |
| GraalVM khớp Camel Quarkus 3.33 / Camel 4.18 | _chưa_ | |

## Kustomize

```text
deploy/
├── base/                 # Deployment/Service stub control + camel-dancu
├── overlays/dev/
└── compose/              # Docker Compose DEV
```

```bash
kubectl apply -k deploy/overlays/dev   # khi có cluster
```

## External Secrets (DEV fake)

Mẫu: `base/external-secret-dev.yaml` — SecretStore giả; không dùng cho PROD.

## Garage bootstrap (sau `make up-dev` lần đầu)

```bash
NODE=$(docker exec lgsp-garage-1 /garage status | awk '/NO ROLE/{print $1; exit}')
docker exec lgsp-garage-1 /garage layout assign -z dc1 -c 1G "$NODE"
docker exec lgsp-garage-1 /garage layout apply --version 1
```
