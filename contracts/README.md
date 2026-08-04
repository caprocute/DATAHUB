# Hợp đồng liên DU (`contracts/`)

Nguồn sự thật cho API và sự kiện giữa các đơn vị triển khai. **Semver tệp**: đổi phá vỡ tương thích → tăng major trong tên (`…-v1.yaml` → `…-v2.yaml`).

## Cấu trúc

```text
contracts/
├── openapi/           # OpenAPI 3.1 — REST
├── asyncapi/          # (tuỳ chọn) AsyncAPI
├── events/            # JSON Schema CloudEvents / payload
└── opa/               # Rego + test
```

## Đặt tên

| Loại | Mẫu |
|---|---|
| OpenAPI | `{du}-{ph}-v{n}.yaml` — ví dụ `control-onboarding-v0.yaml` |
| Sự kiện | `{bounded-context}.{event}.v{n}.json` — ví dụ `onboarding.system-approved.v1.json` |
| Kafka topic | `{mien}.{thuc_the}.v{n}` — xem từ điển dữ liệu SRS-00 |

## Quy tắc

1. Consumer chỉ phụ thuộc bản đã tag / merge `main`.
2. PR đổi `contracts/` cần approve lane tiêu thụ (IP-04 §14).
3. FE typegen từ `openapi/` — cấm gọi path ngoài types.
4. Sự kiện: producer ghi schema trước; consumer tolerant reader.
