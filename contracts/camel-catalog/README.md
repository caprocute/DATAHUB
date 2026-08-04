# Danh mục thành phần Camel (contract)

## Nguồn

| Mục | Giá trị |
|---|---|
| Gói | `@kaoto/camel-catalog` |
| Phiên bản ghim | `0.7.0` |
| Giấy phép | **Apache-2.0** |
| Nhánh dùng | `dist/camel-catalog/camel-quarkus/3.35.0` |
| Camel | 4.20.0 (CEQ 3.35.0) |

Chọn nhánh **camel-quarkus** để khớp runtime PH-04 theo [ADR-002](../../docs/05-adr/README.md#adr-002) và
[ADR-020](../../docs/05-adr/README.md#adr-020). Không dùng nhánh `camel-main` / `camel-springboot`:
danh mục lệch runtime sẽ cho phép người thiết kế chọn thành phần mà bản native không nạp được.

## Số lượng đã kiểm chứng

| Loại | Số nút |
|---|---|
| component | 323 |
| pattern (EIP/model) | 74 |
| kamelet | 252 |
| dataformat | 48 |
| language | 26 |
| entity | 21 |
| loadbalancer | 7 |
| **Tổng** | **751** |

Chốt chặn số lượng nằm ở `apps/console/src/designer/catalog/catalog.count.test.ts` — tụt dưới ngưỡng thì CI đỏ.

## Sinh lại

```bash
cd apps/console && npm run catalog
```

Đầu ra (đã commit, **không sửa tay**):

```text
src/designer/catalog/generated/catalog-index.json      # siêu dữ liệu cho bảng thành phần
src/designer/catalog/generated/schemas/<kind>/<name>.json  # lược đồ tham số, nạp lười
```

Đầu ra được commit để dựng lại được ngoại tuyến và trong CI mà không phải tải gói 50 MB.

## Giữ nguyên dữ liệu gốc

Script chỉ **trích** và **rút gọn mô tả cho bảng thành phần**; không sửa `title`, `description`,
`label`, `syntax`, `scheme`, `consumerOnly`, `producerOnly`, `supportLevel`, `deprecated`,
`propertiesSchema`. Cách chia loại nút và cách nhóm theo nhãn lấy nguyên của Kaoto.

Nhãn tiếng Việt chỉ là **lớp hiển thị** (`LABEL_VI` trong `catalog/index.ts`), mã nhóm vẫn là nhãn gốc.
