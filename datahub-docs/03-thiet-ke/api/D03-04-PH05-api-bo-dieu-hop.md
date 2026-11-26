---
ma_tai_lieu: D03-04-PH05
ten: Đặc tả API và sự kiện phân hệ PH-05 Bộ điều hợp và kết nối
phien_ban: 0.1
ngay: 2026-11-26
trang_thai: Dự thảo
nguoi_doc: Kỹ sư dh-integration, dh-runtime, giao diện; ATTT; hội đồng thẩm định
phan_he: PH-05
---

# D03-04-PH05 · Đặc tả API và sự kiện Bộ điều hợp và kết nối

## Tóm tắt cho hội đồng thẩm định

PH-05 công bố 92 operation REST (API-05-001…093, mã 042 để trống) dưới `/api/adapter/v1` và 15 sự kiện Kafka (EVT-05-01…15) cùng hai topic nội bộ của bộ chạy kiểm tra. Hợp đồng máy đọc được:

- [`ph05/openapi-adapter.yaml`](ph05/openapi-adapter.yaml): OpenAPI 3.1, 114 lược đồ, đã qua `openapi-spec-validator`; 11 ví dụ đã kiểm khớp lược đồ bằng [`check_contracts.py`](ph05/tools/check_contracts.py).
- [`ph05/asyncapi-adapter.yaml`](ph05/asyncapi-adapter.yaml): AsyncAPI 3.0, đã qua `@asyncapi/parser` 3 không lỗi, không cảnh báo.

Cả hai sinh từ bảng mã [`ph05/tools/spec.py`](ph05/tools/spec.py) bằng `gen_openapi.py`, `gen_asyncapi.py`; bảng §3 và §6 của tài liệu này sinh bằng `gen_md.py`. Ba nguyên tắc hợp đồng:

1. **Không API nào trả giá trị bí mật.** Bí mật chỉ đi vào qua hai lược đồ chỉ ghi (`SecretPayload`, `RotateRequest`, `writeOnly`); kiểm tra hợp đồng chặn trường `secrets` ở mọi lược đồ khác.
2. **API nội bộ cho PH-04 và runtime dùng token dịch vụ với scope riêng** (`adapter:verify`, `adapter:runtime-config`, `adapter:health-read`), tách khỏi quyền người dùng `PERM-05-*`.
3. **Mọi lệnh đổi trạng thái có `If-Match`, mọi lệnh tạo có `Idempotency-Key`**, giống PH-04 và PH-19.

## 1. Quy ước chung

| Mục | Quy ước |
|---|---|
| Đường gốc | `/api/adapter/v1`; người dùng qua BFF console của tenant, PH-04 và runtime qua dịch vụ trong cụm `dh-integration.dh-control.svc` |
| Phiên bản | Đường dẫn `v1`; thay đổi phá vỡ sang `v2`, chạy song song ≥ 6 tháng (oasdiff ở CI-5 chặn thay đổi phá vỡ trong `v1`) |
| Tenant | Lấy từ token (`tenant` claim), không bao giờ từ đường dẫn hay thân |
| Hành động | Hậu tố `:{hành-động}` trên tài nguyên (`:enable`, `:approve`, `:rotate-secret`, `:verify`) theo AIP-136 |
| Khóa lạc quan | `GET` trả `ETag`; `PUT`, `PATCH`, `DELETE` và hành động bắt buộc `If-Match`; lệch trả ERR-05-007 (412) |
| Chống trùng | `POST` tạo, chạy kiểm tra, xoay bí mật, nhập hệ cũ bắt buộc `Idempotency-Key` (16…128 ký tự, 24 giờ); cùng khóa khác thân trả ERR-05-039 |
| Phân trang | Con trỏ: `cursor`, `limit` (≤ 100), phản hồi `page.next`, `page.hasMore` |
| Lọc | Tham số lặp dạng `status=ACTIVE,SUSPENDED`; tìm `q` không dấu |
| Lỗi | RFC 9457 `application/problem+json`, `code` = `ERR-05-nnn`, `traceId`; thêm `errors` (theo trường), `usages` (ERR-05-010), `findings` (ERR-05-020…022) |
| Hành động được phép | Đối tượng trả `allowedActions` và `disabledReasons` để giao diện bật, tắt nút đúng như máy chủ sẽ kiểm (D03-06-PH05 §2) |
| Truy vết | `traceparent` W3C xuyên BFF → `dh-integration` → Kafka → `probe-jvm` |
| Ngôn ngữ | `Accept-Language: vi` (mặc định) hoặc `en` cho `title`, `detail`, `hint` |
| Tiến trình dài | Kiểm tra kết nối, kiểm thử bộ điều hợp, nhập hệ cũ, so sánh, chụp ảnh lại trả 202 kèm `Location`; kiểm tra có thêm SSE (`Accept: text/event-stream`) |

## 2. Xác thực và phân quyền

| Bên gọi | Luồng OAuth | Kiểm quyền |
|---|---|---|
| Người dùng console | OIDC Authorization Code + PKCE qua BFF (token không ra trình duyệt) | `PERM-05-*` (D02-08) theo vai trò PA, TA, TO, SO, IE, IA, VW, AU; bốn mắt kiểm ở máy chủ |
| Module `flow` PH-04 | Gọi trong tiến trình qua `AdapterReferenceApi`; khi tách DU dùng `client_credentials` + mTLS, scope `adapter:verify`, `adapter:runtime-config` | API-05-031, 089 |
| `dh-runtime` của tenant | `client_credentials` + `private_key_jwt`, client `dh-runtime-{tenant}` | API-05-032, 089 (`adapter:runtime-config`); token gắn tenant, gọi tenant khác trả 404 |
| PH-13 | `client_credentials`, scope `adapter:health-read` | API-05-093 |

Bảng quyền theo operation nằm ở cột "Quyền" của §3. Một số quy tắc vượt quyền chức năng:

- Duyệt PROD (API-05-015), duyệt tài khoản ghi (038), duyệt phiên bản (056), duyệt Kamelet (083): người duyệt khác người yêu cầu và khác người ghi bí mật hoặc người đồng ý (ERR-05-011).
- Đồng ý mục đích ghi CSDL (037) chỉ SO có `PERM-05-db-write-consent`.
- Kamelet `COMMON`: chỉ PA ở phiên `PLATFORM` duyệt, kèm ý kiến SO; tỉnh ghi đối tượng `COMMON` trả ERR-05-040.
- Nhật ký truy cập CSDL (041) cần `PERM-05-audit-read` (AU, SO).

## 3. Danh mục endpoint

Mỗi operation một mã. Cột FR là số FR-05; chi tiết tham số, lược đồ và mô tả lỗi theo từng operation ở OpenAPI.

<!-- gen:endpoints:start -->
**Loại kết nối**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-05-001 | `GET /connection-types` | Danh sách loại kết nối được hỗ trợ | 001 | `PERM-05-read` |  | 200 |
| API-05-002 | `GET /connection-types/{typeCode}` | Lược đồ tham số của một loại kết nối | 001 | `PERM-05-read` |  | 200 |

**Kết nối nguồn**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-05-003 | `GET /connections` | Danh sách, tìm kiếm kết nối nguồn | 002 | `PERM-05-read` |  | 200 |
| API-05-004 | `POST /connections` | Tạo kết nối nguồn | 004 | `PERM-05-connection` | có | 201 |
| API-05-005 | `GET /connections/{connectionCode}` | Chi tiết kết nối | 003 | `PERM-05-read` |  | 200 |
| API-05-006 | `PATCH /connections/{connectionCode}` | Sửa thông tin kết nối | 006 | `PERM-05-connection` |  | 200 |
| API-05-007 | `POST /connections/{connectionCode}:suspend` | Tạm ngừng kết nối | 008 | `PERM-05-operate` |  | 200 |
| API-05-008 | `POST /connections/{connectionCode}:resume` | Tiếp tục kết nối | 008 | `PERM-05-operate` |  | 200 |
| API-05-009 | `POST /connections/{connectionCode}:retire` | Ngừng dùng kết nối | 008 | `PERM-05-connection` |  | 200 |

**Giá trị môi trường và bí mật**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-05-010 | `GET /connections/{connectionCode}/environments` | Giá trị kết nối theo môi trường | 005 | `PERM-05-read` |  | 200 |
| API-05-011 | `PUT /connections/{connectionCode}/environments/{env}` | Khai báo tham số không bí mật cho môi trường | 005 | `PERM-05-connection` |  | 200 |
| API-05-012 | `PUT /connections/{connectionCode}/environments/{env}/secret` | Ghi bí mật một chiều cho môi trường | 005, 011 | `PERM-05-connection` |  | 204 |
| API-05-013 | `POST /connections/{connectionCode}/environments/{env}:enable` | Bật giá trị môi trường (PROD tạo đề nghị duyệt) | 007 | `PERM-05-connection` |  | 200 |
| API-05-014 | `POST /connections/{connectionCode}/environments/{env}:disable` | Tắt giá trị môi trường | 007 | `PERM-05-operate` |  | 200 |
| API-05-015 | `POST /connections/{connectionCode}/environments/{env}:approve` | Duyệt bật giá trị PROD | 007 | `PERM-05-approve` |  | 200 |
| API-05-016 | `POST /connections/{connectionCode}/environments/{env}:reject` | Từ chối bật giá trị PROD | 007 | `PERM-05-approve` |  | 200 |

**Kiểm tra kết nối**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-05-017 | `POST /connections/{connectionCode}/environments/{env}/tests` | Chạy kiểm tra kết nối | 010 | `PERM-05-test` | có | 202 |
| API-05-018 | `GET /connections/{connectionCode}/tests` | Lịch sử kiểm tra kết nối | 010 | `PERM-05-read` |  | 200 |
| API-05-019 | `GET /connections/{connectionCode}/tests/{testId}` | Kết quả một lần kiểm tra | 010 | `PERM-05-read` |  | 200 |

**Giá trị môi trường và bí mật**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-05-020 | `POST /connections/{connectionCode}/environments/{env}:rotate-secret` | Xoay vòng bí mật | 012 | `PERM-05-operate` | có | 202 |
| API-05-021 | `GET /connections/{connectionCode}/rotations` | Lịch sử xoay vòng bí mật | 012 | `PERM-05-read` |  | 200 |

**Cấp kết nối**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-05-022 | `GET /connections/{connectionCode}/grants` | Danh sách cấp quyền sử dụng | 009 | `PERM-05-read` |  | 200 |
| API-05-023 | `POST /connections/{connectionCode}/grants` | Cấp quyền sử dụng cho không gian làm việc hoặc luồng | 009 | `PERM-05-connection` | có | 201 |
| API-05-024 | `DELETE /connections/{connectionCode}/grants/{grantId}` | Thu hồi quyền sử dụng | 009 | `PERM-05-connection` |  | 204 |

**Kết nối nguồn**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-05-025 | `GET /connections/{connectionCode}/usages` | Nơi đang dùng kết nối | 013 | `PERM-05-read` |  | 200 |
| API-05-026 | `GET /connections/{connectionCode}/history` | Lịch sử thay đổi kết nối | 016 | `PERM-05-read` |  | 200 |
| API-05-027 | `GET /connections:export` | Xuất danh sách kết nối (CSV, không bí mật) | 017 | `PERM-05-read` |  | 200 |

**Nhập hệ cũ**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-05-028 | `POST /connections/legacy-imports` | Tải gói kết nối hệ cũ để phân tích | 018 | `PERM-05-connection` | có | 202 |
| API-05-029 | `GET /connections/legacy-imports/{jobId}` | Kết quả phân tích gói hệ cũ | 018 | `PERM-05-read` |  | 200 |
| API-05-030 | `POST /connections/legacy-imports/{jobId}:commit` | Tạo kết nối nháp từ gói hệ cũ | 018 | `PERM-05-connection` | có | 200 |

**Nội bộ (PH-04, runtime)**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-05-031 | `POST /internal/connection-references:verify` | Xác minh tham chiếu kết nối cho PH-04 | 014 | `adapter:verify` (dịch vụ) |  | 200 |
| API-05-032 | `GET /internal/runtime/connections` | Cấu hình kết nối không bí mật cho runtime | 015 | `adapter:runtime-config` (dịch vụ) |  | 200 |

**Sức khỏe**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-05-033 | `GET /health/overview` | Tổng quan sức khỏe kết nối và bộ điều hợp | 022 | `PERM-05-read` |  | 200 |
| API-05-034 | `GET /connections/{connectionCode}/health` | Sức khỏe một kết nối | 019, 020 | `PERM-05-read` |  | 200 |

**Tài khoản CSDL cho luồng**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-05-035 | `GET /connections/{connectionCode}/flow-accounts` | Tài khoản CSDL theo luồng | 024 | `PERM-05-read` |  | 200 |
| API-05-036 | `POST /connections/{connectionCode}/flow-accounts` | Yêu cầu cấp tài khoản CSDL cho luồng | 024, 026 | `PERM-05-connection` | có | 201 |
| API-05-037 | `POST /connections/{connectionCode}/flow-accounts/{accountId}:consent` | Cán bộ ATTT đồng ý mục đích ghi | 026 | `PERM-05-db-write-consent` |  | 200 |
| API-05-038 | `POST /connections/{connectionCode}/flow-accounts/{accountId}:approve` | Duyệt tài khoản ghi | 026 | `PERM-05-approve` |  | 200 |
| API-05-039 | `POST /connections/{connectionCode}/flow-accounts/{accountId}:revoke` | Thu hồi tài khoản CSDL | 028 | `PERM-05-connection` |  | 200 |
| API-05-040 | `POST /connections/{connectionCode}/environments/{env}:inspect-privileges` | Kiểm tra quyền thực tế của tài khoản CSDL | 025 | `PERM-05-test` |  | 200 |
| API-05-041 | `GET /db-access-logs` | Tra nhật ký truy cập CSDL của luồng | 027 | `PERM-05-audit-read` |  | 200 |

**Bộ điều hợp**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-05-043 | `GET /adapters` | Danh sách bộ điều hợp | 029 | `PERM-05-read` |  | 200 |
| API-05-044 | `POST /adapters` | Tạo bộ điều hợp | 031 | `PERM-05-adapter` | có | 201 |
| API-05-045 | `GET /adapters/{adapterCode}` | Chi tiết bộ điều hợp | 030 | `PERM-05-read` |  | 200 |
| API-05-046 | `PATCH /adapters/{adapterCode}` | Sửa thông tin chung bộ điều hợp | 031 | `PERM-05-adapter` |  | 200 |
| API-05-047 | `GET /adapters/{adapterCode}/versions` | Danh sách phiên bản | 045 | `PERM-05-read` |  | 200 |
| API-05-048 | `POST /adapters/{adapterCode}/versions` | Tạo phiên bản nháp mới | 045 | `PERM-05-adapter` | có | 201 |
| API-05-049 | `GET /adapters/{adapterCode}/versions/{version}` | Chi tiết một phiên bản | 030 | `PERM-05-read` |  | 200 |
| API-05-050 | `PUT /adapters/{adapterCode}/versions/{version}/operations/{operationCode}` | Khai báo hoặc sửa thao tác | 032-041 | `PERM-05-adapter` |  | 200 |
| API-05-051 | `DELETE /adapters/{adapterCode}/versions/{version}/operations/{operationCode}` | Xóa thao tác khỏi bản nháp | 032 | `PERM-05-adapter` |  | 204 |
| API-05-052 | `POST /adapters/{adapterCode}/versions/{version}/tests` | Chạy kiểm thử bộ điều hợp | 043 | `PERM-05-test` | có | 202 |
| API-05-053 | `GET /adapters/{adapterCode}/tests/{testId}` | Kết quả kiểm thử bộ điều hợp | 043 | `PERM-05-read` |  | 200 |
| API-05-054 | `POST /adapters/{adapterCode}/versions/{version}:preview-transform` | Chạy thử chuyển đổi định dạng với dữ liệu mẫu | 040, 041 | `PERM-05-test` |  | 200 |
| API-05-055 | `POST /adapters/{adapterCode}/versions/{version}:submit` | Gửi duyệt phiên bản | 044 | `PERM-05-adapter` |  | 200 |
| API-05-056 | `POST /adapters/{adapterCode}/versions/{version}:approve` | Duyệt phiên bản | 044 | `PERM-05-approve` |  | 200 |
| API-05-057 | `POST /adapters/{adapterCode}/versions/{version}:reject` | Từ chối phiên bản | 044 | `PERM-05-approve` |  | 200 |
| API-05-058 | `POST /adapters/{adapterCode}:suspend` | Tạm dừng bộ điều hợp | 044 | `PERM-05-operate` |  | 200 |
| API-05-059 | `POST /adapters/{adapterCode}:resume` | Tiếp tục bộ điều hợp | 044 | `PERM-05-operate` |  | 200 |
| API-05-060 | `POST /adapters/{adapterCode}:retire` | Ngừng dùng bộ điều hợp | 044 | `PERM-05-adapter` |  | 200 |

**Sức khỏe**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-05-061 | `GET /adapters/{adapterCode}/health` | Sức khỏe bộ điều hợp | 019, 020 | `PERM-05-read` |  | 200 |

**Bộ điều hợp**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-05-062 | `GET /adapters/{adapterCode}/usages` | Nơi đang dùng bộ điều hợp | 013 | `PERM-05-read` |  | 200 |
| API-05-063 | `POST /adapters/{adapterCode}/versions/{version}:compare` | Chạy so sánh phiên bản trên lưu lượng thật | 045 | `PERM-05-operate` | có | 202 |
| API-05-064 | `GET /adapters/{adapterCode}/comparisons/{comparisonId}` | Kết quả so sánh phiên bản | 045 | `PERM-05-read` |  | 200 |
| API-05-065 | `POST /adapter-drafts:from-spec` | Sinh bộ điều hợp nháp từ OpenAPI hoặc WSDL | 046 | `PERM-05-adapter` | có | 201 |
| API-05-066 | `GET /adapters/{adapterCode}/history` | Lịch sử thay đổi bộ điều hợp | 016 | `PERM-05-read` |  | 200 |

**CDC**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-05-067 | `GET /adapters/{adapterCode}/cdc` | Cấu hình và trạng thái CDC | 052 | `PERM-05-read` |  | 200 |
| API-05-068 | `PUT /adapters/{adapterCode}/cdc` | Khai báo cấu hình CDC | 048 | `PERM-05-adapter` |  | 200 |
| API-05-069 | `POST /adapters/{adapterCode}/cdc:check-prerequisites` | Kiểm tra điều kiện CDC ở CSDL nguồn | 049 | `PERM-05-test` |  | 200 |
| API-05-070 | `POST /adapters/{adapterCode}/cdc:start` | Chạy CDC | 050 | `PERM-05-operate` |  | 202 |
| API-05-071 | `POST /adapters/{adapterCode}/cdc:pause` | Tạm dừng CDC | 050 | `PERM-05-operate` |  | 200 |
| API-05-072 | `POST /adapters/{adapterCode}/cdc:resume` | Tiếp tục CDC | 050, 051 | `PERM-05-operate` |  | 200 |
| API-05-073 | `POST /adapters/{adapterCode}/cdc:resnapshot` | Chụp ảnh lại dữ liệu nguồn | 053 | `PERM-05-operate` | có | 202 |
| API-05-074 | `GET /cdc/schema-changes` | Thay đổi lược đồ chờ xử lý | 051 | `PERM-05-read` |  | 200 |
| API-05-075 | `POST /cdc/schema-changes/{changeId}:resolve` | Xử lý một thay đổi lược đồ | 051 | `PERM-05-adapter` |  | 200 |

**Kamelet**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-05-076 | `GET /kamelets` | Danh mục Kamelet | 054 | `PERM-05-read` |  | 200 |
| API-05-077 | `GET /kamelets/{kameletName}` | Chi tiết Kamelet | 055 | `PERM-05-read` |  | 200 |
| API-05-078 | `GET /kamelets/{kameletName}/versions/{version}` | Định nghĩa YAML một phiên bản | 055 | `PERM-05-read` |  | 200 |
| API-05-079 | `POST /kamelets` | Tạo bản nháp Kamelet hoặc phiên bản mới | 056 | `PERM-05-kamelet-submit` | có | 201 |
| API-05-080 | `PUT /kamelets/{kameletName}/versions/{version}` | Sửa bản nháp Kamelet | 056 | `PERM-05-kamelet-submit` |  | 200 |
| API-05-081 | `POST /kamelets/{kameletName}/versions/{version}:validate` | Kiểm tra tĩnh Kamelet | 056 | `PERM-05-kamelet-submit` |  | 200 |
| API-05-082 | `POST /kamelets/{kameletName}/versions/{version}:submit` | Gửi duyệt Kamelet | 056 | `PERM-05-kamelet-submit` |  | 200 |
| API-05-083 | `POST /kamelets/{kameletName}/versions/{version}:approve` | Duyệt Kamelet | 057 | `PERM-05-kamelet-approve` |  | 200 |
| API-05-084 | `POST /kamelets/{kameletName}/versions/{version}:reject` | Từ chối Kamelet | 057 | `PERM-05-kamelet-approve` |  | 200 |
| API-05-085 | `POST /kamelets/{kameletName}/versions/{version}:deprecate` | Đánh dấu ngừng khuyến nghị | 058 | `PERM-05-kamelet-approve` |  | 200 |
| API-05-086 | `POST /kamelets/{kameletName}/versions/{version}:withdraw` | Thu hồi phiên bản Kamelet | 058 | `PERM-05-kamelet-approve` |  | 200 |
| API-05-087 | `GET /kamelets/{kameletName}/usages` | Nơi đang dùng Kamelet | 055, 058 | `PERM-05-read` |  | 200 |
| API-05-088 | `POST /kamelets/{kameletName}:propose-common` | Đề xuất Kamelet tỉnh thành dùng chung | 060 | `PERM-05-kamelet-submit` |  | 200 |

**Nội bộ (PH-04, runtime)**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-05-089 | `GET /internal/catalog/kamelets` | Danh mục Kamelet cho trình thiết kế và runtime | 047, 059 | `adapter:runtime-config` (dịch vụ) |  | 200 |

**Tham số và báo cáo**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-05-090 | `GET /settings` | Tham số phân hệ của tenant | 061 | `PERM-05-read` |  | 200 |
| API-05-091 | `PUT /settings/connection-types/{typeCode}` | Bật, tắt loại kết nối và trần tham số | 061 | `PERM-05-admin` |  | 200 |
| API-05-092 | `GET /reports/usage` | Báo cáo sử dụng kết nối và bộ điều hợp | 062 | `PERM-05-read` |  | 200 |

**Nội bộ (PH-04, runtime)**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-05-093 | `GET /internal/health/states` | Trạng thái sức khỏe cho PH-04 và PH-13 | 021 | `adapter:health-read` (dịch vụ) |  | 200 |
<!-- gen:endpoints:end -->

**Mã dự trữ**

| Mã | Nội dung | Ghi chú |
|---|---|---|
| API-05-042 | Dự phòng: nhận bản ghi truy cập CSDL qua HTTP khi hồ sơ HT-B không cho runtime ghi Kafka chung | Để trống tới khi chốt Q05-08 của FRS; không có trong OpenAPI |

### 3.1. Ví dụ yêu cầu và phản hồi

Ví dụ dưới là giả lập, tenant T68. Các thân yêu cầu cũng nằm trong `examples` của lược đồ ở OpenAPI và được kiểm khớp lược đồ ở CI.

**API-05-004 Tạo kết nối**

```http
POST /api/adapter/v1/connections
Idempotency-Key: 6f0b1d8c-2f7e-4b7a-9d0e-4c1f7a5e2b10
Content-Type: application/json

{"connectionCode": "ndxp-ho-tich", "name": "NDXP tra cứu hộ tịch", "typeCode": "http-rest",
 "systemCode": "NDXP", "purpose": "READ", "owner": "an.nv", "labels": ["ndxp", "ho-tich"]}
```

```http
HTTP/1.1 201 Created
ETag: W/"0"
Location: /api/adapter/v1/connections/ndxp-ho-tich

{"code": "ndxp-ho-tich", "name": "NDXP tra cứu hộ tịch", "typeCode": "http-rest", "systemCode": "NDXP",
 "systemName": "Nền tảng NDXP", "purpose": "READ", "status": "DRAFT", "environments": [], "usageCount": 0,
 "configVersion": 1, "allowedActions": ["putEnvironmentParams", "retireConnection"],
 "disabledReasons": {"suspendConnection": "Kết nối chưa có môi trường nào được bật."}}
```

**API-05-012 Ghi bí mật (chỉ ghi)**

```http
PUT /api/adapter/v1/connections/ndxp-ho-tich/environments/PROD/secret
If-Match: W/"3"
Content-Type: application/json

{"secrets": {"clientId": "dh-t68", "clientSecret": "••••••"}}
```

```http
HTTP/1.1 204 No Content
ETag: W/"4"
```

Không có `GET` tương ứng. `GET .../environments` trả `secretVersion: 1` và `secretKeysSet: ["clientId", "clientSecret"]`, không có giá trị.

**API-05-017, 019 Kiểm tra kết nối**

```http
POST /api/adapter/v1/connections/ndxp-ho-tich/environments/PROD/tests
Idempotency-Key: 0c9a6a3e-51d2-4f1e-8b55-3a0b7d4c9e21

{}
```

```http
HTTP/1.1 202 Accepted
Location: /api/adapter/v1/connections/ndxp-ho-tich/tests/2b7c…

{"id": "2b7c…", "env": "PROD", "kind": "MANUAL", "status": "RUNNING", "secretVersion": 1, "steps": []}
```

Kết quả (thất bại ở bước TLS):

```json
{"id": "2b7c…", "env": "PROD", "status": "FAILED", "causeCode": "TLS_UNTRUSTED", "latencyMs": 412,
 "steps": [
  {"name": "DNS", "status": "PASSED", "durationMs": 3},
  {"name": "TCP", "status": "PASSED", "durationMs": 18},
  {"name": "TLS", "status": "FAILED", "durationMs": 391, "causeCode": "TLS_UNTRUSTED",
   "hint": "Chứng thư của ndxp.example.gov.vn do 'CA Nội bộ X' cấp, chưa có trong kho tin cậy của tenant. Tải chuỗi chứng thư CA lên mục Chứng thư tin cậy hoặc đề nghị đơn vị chủ quản dùng chứng thư công khai."},
  {"name": "AUTH", "status": "SKIPPED"}, {"name": "PROBE", "status": "SKIPPED"}],
 "secretVersion": 1, "startedAt": "2026-11-26T03:10:02Z", "finishedAt": "2026-11-26T03:10:02.412Z", "runBy": "an.nv"}
```

**API-05-015 Duyệt bật PROD bị chặn bốn mắt**

```http
HTTP/1.1 403 Forbidden
Content-Type: application/problem+json

{"type": "https://datahub.gov.vn/problems/adapter/err-05-011", "title": "Vi phạm bốn mắt", "status": 403,
 "code": "ERR-05-011", "detail": "Người duyệt bật PROD phải khác người xin bật và khác người ghi bí mật gần nhất (an.nv).",
 "traceId": "4bf92f3577b34da6a3ce929d0e0e4736"}
```

**API-05-009 Ngừng dùng khi còn nơi dùng**

```json
{"type": "https://datahub.gov.vn/problems/adapter/err-05-010", "title": "Còn nơi đang dùng", "status": 409, "code": "ERR-05-010",
 "usages": [{"kind": "FLOW_VERSION", "code": "ho-tich-tra-cuu", "version": 3, "env": "PROD", "deployed": true},
            {"kind": "ADAPTER_VERSION", "code": "ndxp-rest", "version": 1}],
 "traceId": "9a1c…"}
```

**API-05-031 Xác minh tham chiếu (PH-04 gọi khi phát hành)**

```json
{"workspaceCode": "DEFAULT", "flowCode": "ho-tich-tra-cuu", "flowVersion": 3, "stage": "PUBLISH", "targetEnv": "PROD",
 "references": [{"kind": "CONNECTION", "code": "ndxp-ho-tich", "keysUsed": ["baseUrl", "clientId", "clientSecret"]},
                {"kind": "ADAPTER", "code": "ndxp-rest", "operationCode": "tra-cuu-khai-sinh"}]}
```

```json
{"allOk": false, "results": [
  {"index": 0, "status": "OK", "code": "ndxp-ho-tich"},
  {"index": 1, "status": "NOT_ENABLED", "code": "ndxp-rest", "message": "Bộ điều hợp ndxp-rest chưa có phiên bản được duyệt."}]}
```

**API-05-032 Cấu hình cho runtime (không bí mật)**

```json
{"tenant": "T68", "env": "PROD", "generatedAt": "2026-11-26T03:12:00Z", "configVersion": 418,
 "connections": [
  {"code": "ndxp-ho-tich", "typeCode": "http-rest", "status": "ENABLED",
   "params": {"baseUrl": "https://ndxp.example.gov.vn/api", "auth": "OAUTH2_CLIENT_CREDENTIALS", "timeoutMs": 10000},
   "secretPath": "kv/dh/T68/conn/ndxp-ho-tich/PROD", "secretVersion": 2, "fallbackSecretVersion": 1,
   "limits": {"maxConcurrencyPerReplica": 5, "acquireTimeoutMs": 2000}},
  {"code": "dkkd-db", "typeCode": "db-flow", "status": "ENABLED", "params": {"jdbcUrl": "jdbc:postgresql://dkkd.example.gov.vn:5432/dkkd"},
   "secretPath": "kv/dh/T68/conn/dkkd-db/PROD", "secretVersion": 1, "dbRole": "dh-T68-dkkd-dong-bo-PROD",
   "limits": {"maxConcurrencyPerReplica": 4, "acquireTimeoutMs": 2000}}],
 "adapters": [{"code": "ndxp-rest", "status": "ACTIVE", "version": "1.2", "maxConcurrency": 10, "replicas": 2}]}
```

**API-05-036 Yêu cầu tài khoản CSDL chỉ đọc**

Thân như ví dụ `FlowAccountRequest` trong OpenAPI; phản hồi 201 trả hai dòng (TEST, PROD) trạng thái `ISSUED`, `openbaoRole = dh-T68-dkkd-dong-bo-PROD`, `ttlSeconds = 3600`. Cùng yêu cầu với `accessMode = WRITE` trả hai dòng `REQUESTED` và tạo việc cho SO.

**API-05-075 Xử lý thay đổi lược đồ**

```json
{"resolution": "MAP_COLUMN", "columnMap": {"DIEN_TICH_M2": "DIEN_TICH"},
 "comment": "Cột đổi tên ở bản nâng cấp phần mềm đất đai 3.2; giữ tên cũ ở topic."}
```

Phản hồi trả `SchemaChange` với `status = RESOLVED`; khi không còn thay đổi chờ, `allowedActions` của CDC có `resumeCdc`.

## 4. Danh mục sự kiện

Topic theo `{tenant}.adapter.{thực-thể}.{sự-kiện}.v1` (D00-04 §4). Lược đồ trong [`asyncapi-adapter.yaml`](ph05/asyncapi-adapter.yaml), đăng ký ở Apicurio chế độ BACKWARD.

| Mã | Topic | Người phát | Khóa | Giữ | Người nhận |
|---|---|---|---|---|---|
| EVT-05-01 | `{tenant}.adapter.connection.enabled.v1` | `dh-integration` (outbox) | `connectionCode` | 7 ngày | `dh-runtime`, PH-04 |
| EVT-05-02 | `{tenant}.adapter.connection.changed.v1` | outbox | `connectionCode` | 7 ngày | `dh-runtime` |
| EVT-05-03 | `{tenant}.adapter.connection.secret-rotated.v1` | outbox | `connectionCode` | 7 ngày | `dh-runtime` |
| EVT-05-04 | `{tenant}.adapter.connection.state-changed.v1` | outbox | `connectionCode` | 7 ngày | `dh-runtime`, PH-04, PH-13 |
| EVT-05-05 | `{tenant}.adapter.connection.grant-changed.v1` | outbox | `connectionCode` | 7 ngày | PH-04 |
| EVT-05-06 | `{tenant}.adapter.health.changed.v1` | outbox | `{kind}:{code}` | 7 ngày | PH-04, PH-13 |
| EVT-05-07 | `{tenant}.adapter.adapter.version-approved.v1` | outbox | `adapterCode` | 7 ngày | PH-04, `dh-runtime` |
| EVT-05-08 | `{tenant}.adapter.adapter.state-changed.v1` | outbox | `adapterCode` | 7 ngày | `dh-runtime`, PH-04 |
| EVT-05-09 | `{tenant}.adapter.kamelet.published.v1`; `common.adapter.kamelet.published.v1` | outbox | `name` | 7 ngày | PH-04 |
| EVT-05-10 | `{tenant}.adapter.kamelet.lifecycle-changed.v1` | outbox | `name` | 7 ngày | PH-04, PH-13 |
| EVT-05-11 | `{tenant}.adapter.cdc.schema-changed.v1` | outbox | `adapterCode` | 30 ngày | PH-10, PH-13 |
| EVT-05-12 | `{tenant}.adapter.cdc.state-changed.v1` | outbox | `adapterCode` | 7 ngày | PH-13 |
| EVT-05-13 | `{tenant}.cdc.{adapterCode}.{schema}.{table}.v1` | Kafka Connect (Debezium) | Khóa chính | Theo PH-10 | Luồng PH-04, PH-06 |
| EVT-05-14 | `{tenant}.adapter.db.access-recorded.v1` | `dh-runtime` | `flowCode` | 3 ngày | `dh-integration`, PH-13 |
| EVT-05-15 | `{tenant}.adapter.flow-account.changed.v1` | outbox | `{connectionCode}:{flowCode}` | 7 ngày | PH-04, PH-13 |
| Nội bộ | `{tenant}.adapter.probe.command.v1`, `….probe.result.v1` | `dh-integration`, `probe-jvm` | `connectionCode`, `testId` | 1 ngày | Bộ chạy kiểm tra |

Sự kiện từ outbox mang CloudEvents 1.0 nhị phân (`ce_type = vn.datahub.adapter.connection.enabled.v1`, `ce_subject` = mã). Người nhận lũy đẳng theo `configVersion` hoặc `secretVersion`: runtime bỏ qua sự kiện có số nhỏ hơn số đang giữ. Ví dụ EVT-05-03:

```json
{"tenantId": "T68", "connectionCode": "ndxp-ho-tich", "typeCode": "http-rest", "configVersion": 419,
 "env": "PROD", "secretVersion": 2, "fallbackVersion": 1, "transitionUntil": "2026-11-27T03:15:00Z", "phase": "TRANSITION"}
```

## 5. Hợp đồng với phân hệ khác và bên ngoài

| Bên | Hướng | Hợp đồng | Ghi chú |
|---|---|---|---|
| PH-04 | PH-04 → PH-05 | API-05-031 (`AdapterReferenceApi.verify`), API-05-089 (catalog Kamelet), API-05-093 | Gọi trong tiến trình khi cùng DU; REST khi tách |
| PH-04 | PH-05 → PH-04 | `FlowQueryApi`: không gian, luồng tồn tại, sự kiện luồng ngừng dùng | Thu hồi tài khoản CSDL khi luồng ngừng (FR-05-028) |
| PH-01 | PH-05 đọc | Bản sao `system_replica` qua EVT-01-* | HTTT `ACTIVE`, đầu mối kỹ thuật |
| PH-10 | PH-05 → PH-10 | `POST /api/event/v1/topics` đăng ký topic CDC và lược đồ Avro | ERR-05-029 khi không khả dụng |
| PH-13 | PH-05 → PH-13 | Kiểm toán qua outbox, EVT-05-06, 10, 11, 14 | Bản WORM 5 năm của bản ghi truy cập CSDL |
| PH-18 | PH-05 đọc | Tham số `05.*` | Đệm 60 giây |
| OpenBao | PH-05 ghi; runtime đọc | KV v2, database engine, PKI (D03-03-PH05 §6.1) | Không qua API này |
| Kafka Connect | PH-05 → Kafka Connect | CRD `KafkaConnector` qua GitOps; REST `pause`, `resume`, `status` | SDD §4.12 |
| HTTT thành viên, NDXP, NGSP | Runtime → HTTT | Qua Kamelet giao thức, không qua API này | Hợp đồng của HTTT do bộ điều hợp mô tả |

## 6. Bảng mã lỗi ERR-05

Ý nghĩa theo FRS §8.1; cột "API phát sinh" sinh từ OpenAPI (operation nêu mã trong mô tả hoặc dùng phản hồi lỗi mặc định có mã đó). Mã ở phản hồi lỗi mặc định (ERR-05-001, 003, 007, 008, 012) xuất hiện ở hầu hết API nên ghi số lượng.

<!-- gen:errors:start -->
### 6.1. Lỗi API điều khiển (ERR-05-001…040)

| Mã | HTTP | Ý nghĩa | API phát sinh (API-05-) |
|---|---|---|---|
| ERR-05-001 | 404 | Không tìm thấy đối tượng hoặc đối tượng thuộc tenant khác | Chung |
| ERR-05-002 | 409 | Mã đã tồn tại (kể cả đối tượng đã ngừng dùng) | 004, 079 |
| ERR-05-003 | 400 | Dữ liệu không hợp lệ theo lược đồ, kèm danh sách lỗi theo trường | 003, 011, 012, 041, 043, 079 |
| ERR-05-004 | 422 | Loại kết nối không được hỗ trợ hoặc bị tắt ở tenant | 004 |
| ERR-05-005 | 422 | HTTT không tồn tại hoặc không `ACTIVE` ở PH-01 | 004 |
| ERR-05-006 | 422 | Bí mật gửi qua trường không phải bí mật | 011 |
| ERR-05-007 | 412 | Phiên bản đối tượng đã thay đổi (`If-Match`) | Chung |
| ERR-05-008 | 409 | Chuyển trạng thái không hợp lệ | 004, 006, 007, 008, 009, 013, 014, 015 và 38 API khác |
| ERR-05-009 | 409 | Chưa có kiểm tra hoặc kiểm thử đạt trong 24 giờ | 013, 015, 055 |
| ERR-05-010 | 409 | Còn nơi đang dùng | 006, 009, 060, 091 |
| ERR-05-011 | 403 | Vi phạm bốn mắt | 008, 015, 038 |
| ERR-05-012 | 403 | Không có quyền | Chung |
| ERR-05-013 | 422 | Kết nối chưa được cấp cho không gian làm việc hoặc luồng | 044 |
| ERR-05-014 | 422 | Môi trường chưa có giá trị hoặc thiếu bí mật bắt buộc | 013 |
| ERR-05-015 | 422 | Tài khoản khai báo chỉ đọc nhưng có quyền ghi | 040 |
| ERR-05-016 | 422 | Phạm vi trỏ tới CSDL control plane hoặc `pg-payment` | 036 |
| ERR-05-017 | 409 | Mục đích ghi chưa được phép (kết nối chỉ đọc hoặc chưa có SO đồng ý) | 036 |
| ERR-05-018 | 409 | Đang có lần kiểm tra chạy cho cùng giá trị | 017 |
| ERR-05-019 | 429 | Vượt số lần kiểm tra cho phép | 017 |
| ERR-05-020 | 422 | Kamelet vi phạm chính sách tĩnh | 082 |
| ERR-05-021 | 422 | Kamelet dùng thành phần không có ở runtime | Chung |
| ERR-05-022 | 422 | Phiên bản Kamelet không tương thích ngược với số phụ | Chung |
| ERR-05-023 | 422 | Không phân tích hoặc không tải được OpenAPI, WSDL | 065 |
| ERR-05-024 | 400 | Tệp nhập sai định dạng hoặc quá lớn (413 khi quá lớn) | 028 |
| ERR-05-025 | 422 | CSDL nguồn không đáp ứng điều kiện (CDC hoặc tạo tài khoản động) | 070 |
| ERR-05-026 | 409 | Còn thay đổi lược đồ chưa xử lý | 072 |
| ERR-05-027 | 422 | Bảng hoặc schema ngoài phạm vi cho phép | 011, 036, 068 |
| ERR-05-028 | 503 | OpenBao không khả dụng | Chung |
| ERR-05-029 | 503 | Phân hệ hoặc dịch vụ phụ thuộc không khả dụng (PH-01, PH-04, PH-10, Kafka Connect, bộ chạy kiểm tra) | 012, 017, 020, 026, 031, 036, 038, 040 và 4 API khác |
| ERR-05-030 | 422 | Vượt trần tham số của tenant | 011, 068, 091 |
| ERR-05-031 | 423 | Đang đóng băng thay đổi PROD | 011, 012 |
| ERR-05-032 | 422 | Đặc tả thao tác không hợp lệ (giao thức, câu lệnh SQL, mã hóa ký tự) | 004, 011, 012, 013, 023, 028, 030, 036 và 12 API khác |
| ERR-05-033 | 422 | Không gian làm việc hoặc luồng không tồn tại ở PH-04 | 023 |
| ERR-05-034 | 422 | Tệp hoặc dữ liệu mẫu có mã độc | 050 |
| ERR-05-035 | 413 | Dữ liệu mẫu vượt 1 MiB | 028, 050, 054, 065 |
| ERR-05-036 | 409 | Đang có lần xoay bí mật trong chuyển tiếp | 020 |
| ERR-05-037 | 422 | Thời hạn tài khoản ghi vượt tối đa | 036 |
| ERR-05-038 | 400 | Thiếu lý do bắt buộc | Chung |
| ERR-05-039 | 422 | `Idempotency-Key` đã dùng với thân khác | Chung |
| ERR-05-040 | 403 | Thao tác ghi trên đối tượng `COMMON` từ tenant tỉnh | 079 |

### 6.2. Lỗi runtime (ERR-05-101…120)

Không trả qua API này; Kamelet giao thức ném ngoại lệ mang mã, PH-04 ánh xạ sang lớp lỗi và ERR-04-1xx trả cho bên gọi luồng.

| Mã | Ý nghĩa | Lớp lỗi ở PH-04 (SDD §8.4) |
|---|---|---|
| ERR-05-101 | Không lấy được bí mật (OpenBao không khả dụng và hết đệm) | Tạm thời |
| ERR-05-102 | Hệ đích từ chối xác thực | Nghiệp vụ, không thử lại |
| ERR-05-103 | Không kết nối được tới hệ đích (DNS, từ chối, egress) | Tạm thời |
| ERR-05-104 | Hệ đích quá thời gian chờ hoặc trả 5xx | Tạm thời |
| ERR-05-105 | Nhóm kết nối cạn, chờ quá hạn | Tạm thời |
| ERR-05-106 | Hệ đích giới hạn tần suất (429) quá thời gian chờ | Tạm thời |
| ERR-05-107 | Hệ đích trả SOAP Fault | Theo `faultMapping` |
| ERR-05-108 | Phản hồi sai định dạng hoặc sai lược đồ khai báo | Dữ liệu (DLQ) |
| ERR-05-109 | Thiếu trường bắt buộc sau chuẩn hóa | Dữ liệu (DLQ) |
| ERR-05-110 | Vượt số trang tối đa | Dữ liệu (DLQ) |
| ERR-05-111 | Câu lệnh CSDL quá thời gian hoặc vượt số dòng | Dữ liệu (DLQ) |
| ERR-05-112 | Tệp chưa ghi xong hoặc không khóa được (thông tin) | Thông tin, không lỗi |
| ERR-05-113 | Tệp sai định dạng | Dữ liệu (DLQ) |
| ERR-05-114 | Mất kết nối môi giới bản tin quá 5 phút | Tạm thời |
| ERR-05-115 | Đính kèm thư có mã độc | Nghiệp vụ, sự kiện an ninh |
| ERR-05-116 | CDC dừng do thay đổi lược đồ phá vỡ | CDC: trạng thái PAUSED_SCHEMA |
| ERR-05-117 | CDC mất nhật ký giao dịch chưa đọc | CDC: trạng thái FAILED |
| ERR-05-118 | Kết nối, giá trị môi trường hoặc bộ điều hợp đang bị chặn (tạm ngừng, tắt) | Nghiệp vụ, không thử lại |
| ERR-05-119 | TLS dưới 1.2 hoặc chứng thư không tin cậy | Nghiệp vụ, sự kiện an ninh |
| ERR-05-120 | Kamelet đã bị thu hồi | Nghiệp vụ, không thử lại |
<!-- gen:errors:end -->

### 6.3. Thông điệp và trường bổ sung

| Mã | Trường bổ sung | Ví dụ `detail` |
|---|---|---|
| ERR-05-003 | `errors[]` (`path`, `rule`, `message`) | "Tham số `baseUrl` phải là URL https." |
| ERR-05-006 | `errors[]` chỉ tên khóa | "Trường `password` là bí mật; khai qua mục Bí mật, không qua tham số." |
| ERR-05-009 | `lastPassedAt` | "Chưa có kiểm tra đạt trong 24 giờ trên đúng tham số và bí mật hiện tại." |
| ERR-05-010 | `usages[]` | "Kết nối đang dùng ở 2 nơi." |
| ERR-05-011 | — | Nêu vai trò bị trùng (người xin, người ghi bí mật, người đồng ý), không nêu thêm dữ liệu cá nhân |
| ERR-05-019 | `retryAfterSeconds` | "Đã chạy 10 lần kiểm tra trong 5 phút. Thử lại sau 3 phút." |
| ERR-05-020…022 | `findings[]` (`rule` KR-nn, `line`) | "KR-04 dòng 18: không dùng ngôn ngữ `groovy`." |
| ERR-05-028 | `retryAfterSeconds` | "Kho bí mật tạm thời không khả dụng; dữ liệu chưa được ghi." |

Không thông điệp nào lặp lại giá trị bí mật hay chuỗi kết nối có mật khẩu; bộ lọc che ở `ProblemDetailsFactory` áp lên `detail` trước khi trả.

## 7. Kiểm tra hợp đồng trong CI

| Kiểm | Công cụ | Cổng |
|---|---|---|
| OpenAPI 3.1 hợp lệ, ví dụ khớp lược đồ, mỗi operation có `x-datahub-id`, `x-datahub-fr`, `x-datahub-permission`, lệnh ghi có `If-Match` | `check_contracts.py` (`openapi-spec-validator`, `jsonschema`) | CI-5 |
| Không trường `secrets` ngoài lược đồ chỉ ghi; `writeOnly` có mặt | `check_contracts.py` | CI-5 |
| AsyncAPI 3.0 hợp lệ | `@asyncapi/parser` 3 | CI-5 |
| Lint quy ước | Spectral với bộ luật dự án | CI-5 |
| Thay đổi phá vỡ trong `v1` | oasdiff `breaking` so với `main` | CI-5 |
| Tệp sinh khớp nguồn | Chạy lại `gen_openapi.py`, `gen_asyncapi.py`, `gen_md.py` rồi `git diff --exit-code` | CI-5 |
| Mã API, EVT, ERR khớp FRS | `build/tools/kiem_tra_ma.py` | CI-1 |

Kết quả ngày 26/11/2026: OpenAPI hợp lệ, 11 ví dụ khớp; AsyncAPI hợp lệ, 0 cảnh báo.

## 8. Ánh xạ từ hệ cũ và mã đang chạy

| Hệ cũ, mã hiện tại | API mới | Ghi chú |
|---|---|---|
| Bus: JMX/Jolokia xem endpoint, start, stop route | Không có tương đương ở PH-05 | Điều khiển luồng thuộc PH-04 (API-04-06x); PH-05 chỉ quản lý kết nối và bộ điều hợp |
| Bus: datasource khai trong XML context | API-05-004, 011, 012, 017, 013 | Tách tham số và bí mật, thêm kiểm tra và duyệt |
| Bus: nhập, xuất context | API-05-028…030 (nhập kết nối), API-05-027 (xuất danh sách không bí mật) | Không xuất bí mật |
| Productivity Tooling: thành phần tự viết | API-05-079…086 | Kamelet có kiểm tra tĩnh, duyệt |
| `apps/adapter-mgr` `GET /api/v1/adapters`, `GET /api/v1/adapters/{id}` | API-05-003, 005 | Đường dẫn mới, có quyền, tenant; route cũ gỡ cùng ứng dụng (SDD §2.4) |

## 9. Câu hỏi mở

| Mã | Câu hỏi | Đề xuất tạm |
|---|---|---|
| Q05-60 | API-05-032 trả cấu hình cả tenant mỗi lần; tỉnh lớn (QM-LON, 500 kết nối) khoảng 600 KB | Đủ với `ETag`, `If-None-Match`; nếu vượt 2 MB thì thêm tham số `since=configVersion` trả phần đổi |
| Q05-61 | Có công bố API-05-031 qua APISIX cho PH-04 khi tách DU không | Không; gọi trong cụm, mTLS mesh, không qua biên |
| Q05-62 | SSE của API-05-019 qua BFF có cần giữ kết nối khi tab ẩn | Không; giao diện đóng SSE khi tab ẩn và hỏi lại API-05-019 khi hiện |

## Lịch sử phiên bản

| Phiên bản | Ngày | Nội dung | Người thực hiện |
|---|---|---|---|
| 0.1 | 26/11/2026 | Bản đầu theo khuôn K-API; OpenAPI, AsyncAPI sinh từ bảng mã, đã kiểm | Nhóm viết tài liệu (Claude) |
