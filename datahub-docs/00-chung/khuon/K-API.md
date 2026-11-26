---
ma_tai_lieu: D03-04-PH{nn}
ten: Đặc tả API và sự kiện phân hệ PH-{nn} {Tên}
phien_ban: 0.1
ngay: yyyy-MM-dd
trang_thai: Dự thảo
nguoi_doc: Kỹ sư, đơn vị kết nối, hội đồng thẩm định
phan_he: PH-{nn}
---

# D03-04-PH{nn} · Đặc tả API và sự kiện {Tên}

## Tóm tắt cho hội đồng thẩm định  [BB]
## 1. Quy ước chung  [BB]
Đường gốc `/api/{nhóm}/v1`, phiên bản, phân trang, lọc, `Idempotency-Key`, lỗi RFC 9457, header truy vết `traceparent`.
## 2. Xác thực và phân quyền  [BB]
OAuth 2.1 `client_credentials` + mTLS hoặc `private_key_jwt` cho máy gọi máy; OIDC + PKCE qua BFF cho người dùng; scope và `PERM-*`.
## 3. Danh mục endpoint  [BB]
Mỗi operation **một mã** `API-{nn}-nnn` (không dùng chung mã cho hai operation). Mỗi endpoint có ví dụ yêu cầu và phản hồi.
## 4. Danh mục sự kiện  [BB]
`EVT-{nn}-nn`, topic `{tenant}.{miền}.{thực-thể}.{sự-kiện}.v1`, schema, khóa phân vùng, chính sách tương thích; tệp AsyncAPI 3.0.
## 5. Hợp đồng với phân hệ khác và bên ngoài  [BB]
NDXP/NDOP, PayGov, dịch vụ NGSP nếu liên quan.
## 6. Bảng mã lỗi ERR-{nn}  [BB]
`ERR-{nn}-nnn | HTTP | Ý nghĩa`; 001–099 control plane, 101–199 runtime.
## 7. Kiểm tra hợp đồng trong CI  [BB]
Spectral, oasdiff, kiểm ví dụ khớp schema (CI-5).
## 8. Ánh xạ từ hệ cũ
## 9. Câu hỏi mở  [BB]
## Lịch sử phiên bản

Tệp đi kèm: `03-thiet-ke/api/ph{nn}/openapi-{nhóm}.yaml` (OpenAPI 3.1), `asyncapi-{nhóm}.yaml` (AsyncAPI 3.0). Nên sinh bảng §3 từ OpenAPI bằng script (như `api/ph04/tools/`).

---

### Ví dụ ngắn (rút từ D03-04-PH04 §3)

```markdown
| Mã | Operation | Mục đích | FR | Quyền | Idem. | Thành công |
|---|---|---|---|---|---|---|
| API-04-010 | `GET /flows` | Danh sách luồng | 001 | `PERM-04-read` |  | 200 |
| API-04-003 | `POST /workspaces/{workspaceCode}:archive` | Lưu trữ không gian làm việc | 007 | `PERM-04-admin` |  | 200 |
```

Ví dụ phản hồi lỗi:

```json
{ "type": "https://datahub.gov.vn/errors/ERR-07-026", "title": "Vượt mức tối đa", "status": 400,
  "code": "ERR-07-026", "traceId": "4bf92f3577b34da6a3ce929d0e0e4736", "errors": [{"field": "size", "max": 200}] }
```

### Tự soát
- [ ] Mỗi FR có ít nhất một API hoặc ghi rõ "chỉ giao diện".
- [ ] OpenAPI, AsyncAPI qua lint; ví dụ khớp schema.
- [ ] Mỗi mã ERR dùng ở FRS, UC, màn hình có trong §6.
