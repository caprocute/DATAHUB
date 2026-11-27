---
ma_tai_lieu: D03-04-PH05
ten: Đặc tả API và sự kiện phân hệ PH-05 Bộ điều hợp và kết nối
phien_ban: 0.3
ngay: 2026-11-27
trang_thai: Dự thảo
nguoi_doc: Kỹ sư dh-integration, dh-runtime, giao diện; ATTT; hội đồng thẩm định
phan_he: PH-05
mo_ta: Đặc tả 92 endpoint REST, sự kiện Kafka và mã lỗi của phân hệ Bộ điều hợp và kết nối, sinh từ OpenAPI và AsyncAPI đã kiểm tra trong CI.
tai_lieu_lien_quan: D02-03-PH05 FRS; D03-02-PH05 SDD; D03-03-PH05 CSDL; D03-06-PH05 Màn hình; D04-01 Quy ước mã
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

## 0. Giới thiệu

Tài liệu đặc tả giao diện lập trình của PH-05: 92 endpoint REST ở mặt phẳng điều khiển và nội bộ, các sự kiện Kafka, hợp đồng với phân hệ khác, bảng mã lỗi ERR-05. Nguồn chuẩn là hai tệp máy đọc được [`openapi-adapter.yaml`](ph05/openapi-adapter.yaml) và [`asyncapi-adapter.yaml`](ph05/asyncapi-adapter.yaml); bảng danh mục ở chương 3 và chương 10 (đặc tả từng endpoint, mỗi endpoint một bảng 10 mục) đều sinh từ OpenAPI nên không lệch nhau.

| Người đọc | Phần cần đọc |
|---|---|
| Kỹ sư `dh-integration`, giao diện | Chương 1, 2, 3, 10 |
| Kỹ sư PH-04, `dh-runtime` | Chương 4, 5 |
| Kiểm thử viên | Chương 6, 7, 10 |
| ATTT, hội đồng thẩm định | Tóm tắt, chương 2, 5 |

: Người đọc và phần cần đọc

Thuật ngữ dùng chung với [D02-03-PH05](../../02-yeu-cau/frs/D02-03-PH05-frs-bo-dieu-hop.md) §1.4 và D00-01. Câu thông báo người dùng thấy theo từng mã lỗi ở FRS §9.2. Tài liệu tham chiếu: D02-03-PH05 (FRS), D03-02-PH05 (SDD), D03-03-PH05 (CSDL), D03-06-PH05 (màn hình), D04-01 (quy ước API, RFC 9457).

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

: Quy ước chung

## 2. Xác thực và phân quyền

| Bên gọi | Luồng OAuth | Kiểm quyền |
|---|---|---|
| Người dùng console | OIDC Authorization Code + PKCE qua BFF (token không ra trình duyệt) | `PERM-05-*` (D02-08) theo vai trò PA, TA, TO, SO, IE, IA, VW, AU; bốn mắt kiểm ở máy chủ |
| Module `flow` PH-04 | Gọi trong tiến trình qua `AdapterReferenceApi`; khi tách DU dùng `client_credentials` + mTLS, scope `adapter:verify`, `adapter:runtime-config` | API-05-031, 089 |
| `dh-runtime` của tenant | `client_credentials` + `private_key_jwt`, client `dh-runtime-{tenant}` | API-05-032, 089 (`adapter:runtime-config`); token gắn tenant, gọi tenant khác trả 404 |
| PH-13 | `client_credentials`, scope `adapter:health-read` | API-05-093 |

: Xác thực và phân quyền

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

: Danh mục endpoint · Loại kết nối

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

: Danh mục endpoint · Kết nối nguồn

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

: Danh mục endpoint · Giá trị môi trường và bí mật

**Kiểm tra kết nối**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-05-017 | `POST /connections/{connectionCode}/environments/{env}/tests` | Chạy kiểm tra kết nối | 010 | `PERM-05-test` | có | 202 |
| API-05-018 | `GET /connections/{connectionCode}/tests` | Lịch sử kiểm tra kết nối | 010 | `PERM-05-read` |  | 200 |
| API-05-019 | `GET /connections/{connectionCode}/tests/{testId}` | Kết quả một lần kiểm tra | 010 | `PERM-05-read` |  | 200 |

: Danh mục endpoint · Kiểm tra kết nối

**Giá trị môi trường và bí mật**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-05-020 | `POST /connections/{connectionCode}/environments/{env}:rotate-secret` | Xoay vòng bí mật | 012 | `PERM-05-operate` | có | 202 |
| API-05-021 | `GET /connections/{connectionCode}/rotations` | Lịch sử xoay vòng bí mật | 012 | `PERM-05-read` |  | 200 |

: Danh mục endpoint · Giá trị môi trường và bí mật

**Cấp kết nối**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-05-022 | `GET /connections/{connectionCode}/grants` | Danh sách cấp quyền sử dụng | 009 | `PERM-05-read` |  | 200 |
| API-05-023 | `POST /connections/{connectionCode}/grants` | Cấp quyền sử dụng cho không gian làm việc hoặc luồng | 009 | `PERM-05-connection` | có | 201 |
| API-05-024 | `DELETE /connections/{connectionCode}/grants/{grantId}` | Thu hồi quyền sử dụng | 009 | `PERM-05-connection` |  | 204 |

: Danh mục endpoint · Cấp kết nối

**Kết nối nguồn**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-05-025 | `GET /connections/{connectionCode}/usages` | Nơi đang dùng kết nối | 013 | `PERM-05-read` |  | 200 |
| API-05-026 | `GET /connections/{connectionCode}/history` | Lịch sử thay đổi kết nối | 016 | `PERM-05-read` |  | 200 |
| API-05-027 | `GET /connections:export` | Xuất danh sách kết nối (CSV, không bí mật) | 017 | `PERM-05-read` |  | 200 |

: Danh mục endpoint · Kết nối nguồn

**Nhập hệ cũ**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-05-028 | `POST /connections/legacy-imports` | Tải gói kết nối hệ cũ để phân tích | 018 | `PERM-05-connection` | có | 202 |
| API-05-029 | `GET /connections/legacy-imports/{jobId}` | Kết quả phân tích gói hệ cũ | 018 | `PERM-05-read` |  | 200 |
| API-05-030 | `POST /connections/legacy-imports/{jobId}:commit` | Tạo kết nối nháp từ gói hệ cũ | 018 | `PERM-05-connection` | có | 200 |

: Danh mục endpoint · Nhập hệ cũ

**Nội bộ (PH-04, runtime)**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-05-031 | `POST /internal/connection-references:verify` | Xác minh tham chiếu kết nối cho PH-04 | 014 | `adapter:verify` (dịch vụ) |  | 200 |
| API-05-032 | `GET /internal/runtime/connections` | Cấu hình kết nối không bí mật cho runtime | 015 | `adapter:runtime-config` (dịch vụ) |  | 200 |

: Danh mục endpoint · Nội bộ (PH-04, runtime)

**Sức khỏe**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-05-033 | `GET /health/overview` | Tổng quan sức khỏe kết nối và bộ điều hợp | 022 | `PERM-05-read` |  | 200 |
| API-05-034 | `GET /connections/{connectionCode}/health` | Sức khỏe một kết nối | 019, 020 | `PERM-05-read` |  | 200 |

: Danh mục endpoint · Sức khỏe

**Tài khoản CSDL cho luồng**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-05-035 | `GET /connections/{connectionCode}/flow-accounts` | Tài khoản CSDL theo luồng | 024 | `PERM-05-read` |  | 200 |
| API-05-036 | `POST /connections/{connectionCode}/flow-accounts` | Yêu cầu cấp tài khoản CSDL cho luồng | 024, 026 | `PERM-05-connection` | có | 201 |
| API-05-037 | `POST /connections/{connectionCode}/flow-accounts/{accountId}:consent` | Cán bộ ATTT đồng ý mục đích ghi | 026 | `PERM-05-db-write-consent` |  | 200 |
| API-05-038 | `POST /connections/{connectionCode}/flow-accounts/{accountId}:approve` | Duyệt tài khoản ghi | 026 | `PERM-05-approve` |  | 200 |
| API-05-039 | `POST /connections/{connectionCode}/flow-accounts/{accountId}:revoke` | Thu hồi tài khoản CSDL | 028 | `PERM-05-connection` hoặc `PERM-05-operate` |  | 200 |
| API-05-040 | `POST /connections/{connectionCode}/environments/{env}:inspect-privileges` | Kiểm tra quyền thực tế của tài khoản CSDL | 025 | `PERM-05-test` |  | 200 |
| API-05-041 | `GET /db-access-logs` | Tra nhật ký truy cập CSDL của luồng | 027 | `PERM-05-audit-read` |  | 200 |

: Danh mục endpoint · Tài khoản CSDL cho luồng

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

: Danh mục endpoint · Bộ điều hợp

**Sức khỏe**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-05-061 | `GET /adapters/{adapterCode}/health` | Sức khỏe bộ điều hợp | 019, 020 | `PERM-05-read` |  | 200 |

: Danh mục endpoint · Sức khỏe

**Bộ điều hợp**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-05-062 | `GET /adapters/{adapterCode}/usages` | Nơi đang dùng bộ điều hợp | 013 | `PERM-05-read` |  | 200 |
| API-05-063 | `POST /adapters/{adapterCode}/versions/{version}:compare` | Chạy so sánh phiên bản trên lưu lượng thật | 045 | `PERM-05-operate` | có | 202 |
| API-05-064 | `GET /adapters/{adapterCode}/comparisons/{comparisonId}` | Kết quả so sánh phiên bản | 045 | `PERM-05-read` |  | 200 |
| API-05-065 | `POST /adapter-drafts:from-spec` | Sinh bộ điều hợp nháp từ OpenAPI hoặc WSDL | 046 | `PERM-05-adapter` | có | 201 |
| API-05-066 | `GET /adapters/{adapterCode}/history` | Lịch sử thay đổi bộ điều hợp | 016 | `PERM-05-read` |  | 200 |

: Danh mục endpoint · Bộ điều hợp

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

: Danh mục endpoint · CDC

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

: Danh mục endpoint · Kamelet

**Nội bộ (PH-04, runtime)**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-05-089 | `GET /internal/catalog/kamelets` | Danh mục Kamelet cho trình thiết kế và runtime | 047, 059 | `adapter:runtime-config` (dịch vụ) |  | 200 |

: Danh mục endpoint · Nội bộ (PH-04, runtime)

**Tham số và báo cáo**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-05-090 | `GET /settings` | Tham số phân hệ của tenant | 061 | `PERM-05-read` |  | 200 |
| API-05-091 | `PUT /settings/connection-types/{typeCode}` | Bật, tắt loại kết nối và trần tham số | 061 | `PERM-05-admin` |  | 200 |
| API-05-092 | `GET /reports/usage` | Báo cáo sử dụng kết nối và bộ điều hợp | 062 | `PERM-05-read` |  | 200 |

: Danh mục endpoint · Tham số và báo cáo

**Nội bộ (PH-04, runtime)**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-05-093 | `GET /internal/health/states` | Trạng thái sức khỏe cho PH-04 và PH-13 | 021 | `adapter:health-read` (dịch vụ) |  | 200 |

: Danh mục endpoint · Nội bộ (PH-04, runtime)
<!-- gen:endpoints:end -->

**Mã dự trữ**

| Mã | Nội dung | Ghi chú |
|---|---|---|
| API-05-042 | Dự phòng: nhận bản ghi truy cập CSDL qua HTTP khi hồ sơ HT-B không cho runtime ghi Kafka chung | Để trống tới khi chốt Q05-08 của FRS; không có trong OpenAPI |

: Danh mục endpoint · Mã dự trữ

### 3.1. Ví dụ yêu cầu và phản hồi

Ví dụ dưới là giả lập, tenant T68. Các thân yêu cầu cũng nằm trong `examples` của lược đồ ở OpenAPI và được kiểm khớp lược đồ ở CI.

**API-05-004 Tạo kết nối**

```http
POST /api/adapter/v1/connections
Idempotency-Key: 6f0b1d8c-2f7e-4b7a-9d0e-4c1f7a5e2b10
Content-Type: application/json

{"connectionCode": "ndxp-ho-tich", "name": "NDXP tra cứu hộ tịch", "typeCode": "oauth2-client",
 "systemCode": "NDXP", "purpose": "READ", "owner": "an.nv", "labels": ["ndxp", "ho-tich"]}
```

```http
HTTP/1.1 201 Created
ETag: W/"0"
Location: /api/adapter/v1/connections/ndxp-ho-tich

{"code": "ndxp-ho-tich", "name": "NDXP tra cứu hộ tịch", "typeCode": "oauth2-client", "systemCode": "NDXP",
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

{"type": "https://datahub.gov.vn/errors/ERR-05-011", "title": "Vi phạm bốn mắt", "status": 403,
 "code": "ERR-05-011", "detail": "Người duyệt bật PROD phải khác người xin bật và khác người ghi bí mật gần nhất (an.nv).",
 "traceId": "4bf92f3577b34da6a3ce929d0e0e4736"}
```

**API-05-009 Ngừng dùng khi còn nơi dùng**

```json
{"type": "https://datahub.gov.vn/errors/ERR-05-010", "title": "Còn nơi đang dùng", "status": 409, "code": "ERR-05-010",
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
  {"code": "ndxp-ho-tich", "typeCode": "oauth2-client", "status": "ENABLED",
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
| EVT-05-08 | `{tenant}.adapter.adapter.state-changed.v1` | outbox | `adapterCode` | 7 ngày | `dh-runtime`, PH-04, PH-16 (sổ kiến trúc, thành phần `ADAPTER`) |
| EVT-05-09 | `{tenant}.adapter.kamelet.published.v1`; `common.adapter.kamelet.published.v1` | outbox | `name` | 7 ngày | PH-04 |
| EVT-05-10 | `{tenant}.adapter.kamelet.lifecycle-changed.v1` | outbox | `name` | 7 ngày | PH-04, PH-13 |
| EVT-05-11 | `{tenant}.adapter.cdc.schema-changed.v1` | outbox | `adapterCode` | 30 ngày | PH-10, PH-13 |
| EVT-05-12 | `{tenant}.adapter.cdc.state-changed.v1` | outbox | `adapterCode` | 7 ngày | PH-13 |
| EVT-05-13 | `{tenant}.cdc.{adapterCode}.{schema}.{table}.v1` | Kafka Connect (Debezium) | Khóa chính | Theo PH-10 | Luồng PH-04, PH-06 |
| EVT-05-14 | `{tenant}.adapter.db.access-recorded.v1` | `dh-runtime` | `flowCode` | 3 ngày | `dh-integration`, PH-13 |
| EVT-05-15 | `{tenant}.adapter.flow-account.changed.v1` | outbox | `{connectionCode}:{flowCode}` | 7 ngày | PH-04, PH-13 |
| Nội bộ | `{tenant}.adapter.probe.command.v1`, `….probe.result.v1` | `dh-integration`, `probe-jvm` | `connectionCode`, `testId` | 1 ngày | Bộ chạy kiểm tra |

: Danh mục sự kiện

Sự kiện từ outbox mang CloudEvents 1.0 nhị phân (`ce_type = vn.datahub.adapter.connection.enabled.v1`, `ce_subject` = mã). Người nhận lũy đẳng theo `configVersion` hoặc `secretVersion`: runtime bỏ qua sự kiện có số nhỏ hơn số đang giữ. Ví dụ EVT-05-03:

```json
{"tenantId": "T68", "connectionCode": "ndxp-ho-tich", "typeCode": "oauth2-client", "configVersion": 419,
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

: Hợp đồng với phân hệ khác và bên ngoài

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
| ERR-05-011 | 403 | Vi phạm bốn mắt | 008, 015, 038, 056, 083 |
| ERR-05-012 | 403 | Không có quyền | Chung |
| ERR-05-013 | 422 | Kết nối chưa được cấp cho không gian làm việc hoặc luồng | 044 |
| ERR-05-014 | 422 | Môi trường chưa có giá trị hoặc thiếu bí mật bắt buộc | 013 |
| ERR-05-015 | 422 | Tài khoản khai báo chỉ đọc nhưng có quyền ghi | 040 |
| ERR-05-016 | 422 | Phạm vi trỏ tới CSDL control plane hoặc `pg-payment` | 011, 036 |
| ERR-05-017 | 409 | Mục đích ghi chưa được phép (kết nối chỉ đọc hoặc chưa có SO đồng ý) | 036, 050 |
| ERR-05-018 | 409 | Đang có lần kiểm tra chạy cho cùng giá trị | 017 |
| ERR-05-019 | 429 | Vượt số lần kiểm tra cho phép | 017 |
| ERR-05-020 | 422 | Kamelet vi phạm chính sách tĩnh | 082 |
| ERR-05-021 | 422 | Kamelet dùng thành phần không có ở runtime | Chung |
| ERR-05-022 | 422 | Phiên bản Kamelet không tương thích ngược với số phụ | Chung |
| ERR-05-023 | 422 | Không phân tích hoặc không tải được OpenAPI, WSDL | 065 |
| ERR-05-024 | 400 | Tệp nhập sai định dạng hoặc quá lớn (413 khi quá lớn) | 028, 065 |
| ERR-05-025 | 422 | CSDL nguồn không đáp ứng điều kiện (CDC hoặc tạo tài khoản động) | 070 |
| ERR-05-026 | 409 | Còn thay đổi lược đồ chưa xử lý | 072 |
| ERR-05-027 | 422 | Bảng hoặc schema ngoài phạm vi cho phép | 036, 068 |
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

: Lỗi API điều khiển (ERR-05-001…040)

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

: Lỗi runtime (ERR-05-101…120)
<!-- gen:errors:end -->

### 6.3. Thông điệp và trường bổ sung

| Mã | Trường bổ sung | Ví dụ `detail` |
|---|---|---|
| ERR-05-003 | `errors[]` (`path`, `rule`, `message`) | "Tham số `baseUrl` phải là URL https." |
| ERR-05-006 | `errors[]` chỉ tên khóa | "Trường `password` là bí mật; khai qua mục Bí mật, không qua tham số." |
| ERR-05-009 | `lastPassedAt` | "Chưa có kiểm tra đạt trong 24 giờ trên đúng tham số và bí mật hiện tại." |
| ERR-05-010 | `usages[]` | "Kết nối đang dùng ở 2 nơi." |
| ERR-05-011 | — | Nêu vai trò bị trùng (người xin, người ghi bí mật, người đồng ý), không nêu thêm dữ liệu cá nhân |
| ERR-05-019 | `retryAfterSeconds` | "Đã chạy 20 lần kiểm tra trong một giờ cho kết nối này. Thử lại sau 12 phút." |
| ERR-05-020…022 | `findings[]` (`rule` KR-nn, `line`) | "KR-04 dòng 18: không dùng ngôn ngữ `groovy`." |
| ERR-05-028 | `retryAfterSeconds` | "Kho bí mật tạm thời không khả dụng; dữ liệu chưa được ghi." |

: Thông điệp và trường bổ sung

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

: Kiểm tra hợp đồng trong CI

Kết quả ngày 26/11/2026: OpenAPI hợp lệ, 11 ví dụ khớp; AsyncAPI hợp lệ, 0 cảnh báo.

## 8. Ánh xạ từ hệ cũ và mã đang chạy

| Hệ cũ, mã hiện tại | API mới | Ghi chú |
|---|---|---|
| Bus: JMX/Jolokia xem endpoint, start, stop route | Không có tương đương ở PH-05 | Điều khiển luồng thuộc PH-04 (API-04-06x); PH-05 chỉ quản lý kết nối và bộ điều hợp |
| Bus: datasource khai trong XML context | API-05-004, 011, 012, 017, 013 | Tách tham số và bí mật, thêm kiểm tra và duyệt |
| Bus: nhập, xuất context | API-05-028…030 (nhập kết nối), API-05-027 (xuất danh sách không bí mật) | Không xuất bí mật |
| Productivity Tooling: thành phần tự viết | API-05-079…086 | Kamelet có kiểm tra tĩnh, duyệt |
| `apps/adapter-mgr` `GET /api/v1/adapters`, `GET /api/v1/adapters/{id}` | API-05-003, 005 | Đường dẫn mới, có quyền, tenant; route cũ gỡ cùng ứng dụng (SDD §2.4) |

: Ánh xạ từ hệ cũ và mã đang chạy

## 9. Câu hỏi mở

| Mã | Câu hỏi | Đề xuất tạm |
|---|---|---|
| Q05-60 | API-05-032 trả cấu hình cả tenant mỗi lần; tỉnh lớn (QM-LON, 500 kết nối) khoảng 600 KB | Đủ với `ETag`, `If-None-Match`; nếu vượt 2 MB thì thêm tham số `since=configVersion` trả phần đổi |
| Q05-61 | Có công bố API-05-031 qua APISIX cho PH-04 khi tách DU không | Không; gọi trong cụm, mTLS mesh, không qua biên |
| Q05-62 | SSE của API-05-019 qua BFF có cần giữ kết nối khi tab ẩn | Không; giao diện đóng SSE khi tab ẩn và hỏi lại API-05-019 khi hiện |

: Câu hỏi mở

## 10. Đặc tả từng endpoint

Chương này sinh tự động từ OpenAPI bằng `build/tools/sinh_dac_ta_api.py`; sửa OpenAPI rồi chạy lại, không sửa tay. Mỗi endpoint một bảng đặc tả 10 mục.

<!-- gen:dac-ta-api:start -->

### Loại kết nối

#### API-05-001 · Danh sách loại kết nối được hỗ trợ

::: dac-ta
**Mục đích.** Danh sách loại kết nối được hỗ trợ.

**Phương thức, đường dẫn.** `GET /connection-types`.

**Quyền.** `PERM-05-read`.

**FR hiện thực.** FR-05-001.

**Tham số.** `group` (query, ProtocolGroup, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ConnectionTypeList`; trường bắt buộc: `items`; tiêu đề `ETag`.

**Lỗi.** `401` Thiếu token hoặc token hết hạn.

**Ghi chú.** Không.
:::

#### API-05-002 · Lược đồ tham số của một loại kết nối

::: dac-ta
**Mục đích.** Lược đồ tham số của một loại kết nối.

**Phương thức, đường dẫn.** `GET /connection-types/{typeCode}`.

**Quyền.** `PERM-05-read`.

**FR hiện thực.** FR-05-001.

**Tham số.** `typeCode` (path, TypeCode, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ConnectionTypeDetail`; tiêu đề `ETag`.

**Lỗi.** `401` Thiếu token hoặc token hết hạn; `404` Không tìm thấy hoặc thuộc tenant khác (không phân biệt).

**Ghi chú.** Trả `paramsSchema` (JSON Schema 2020-12) để giao diện dựng biểu mẫu; trần đã áp theo tenant.
:::

### Kết nối nguồn

#### API-05-003 · Danh sách, tìm kiếm kết nối nguồn

::: dac-ta
**Mục đích.** Danh sách, tìm kiếm kết nối nguồn.

**Phương thức, đường dẫn.** `GET /connections`.

**Quyền.** `PERM-05-read`.

**FR hiện thực.** FR-05-002.

**Tham số.** `q` (query, string, tùy chọn); `status` (query, array, tùy chọn); `typeCode` (query, array, tùy chọn); `systemCode` (query, SystemCode, tùy chọn); `health` (query, array, tùy chọn); `env` (query, Environment, tùy chọn); `label` (query, string, tùy chọn); `secretOverdue` (query, boolean, tùy chọn); `protocolGroup` (query, array, tùy chọn); `grantedTo` (query, string, tùy chọn); `owner` (query, string, tùy chọn); `sort` (query, string, tùy chọn); `cursor` (query, string, tùy chọn); `limit` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ConnectionPage`; trường bắt buộc: `items`, `page`; tiêu đề `ETag`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ; kèm `errors` theo trường (gồm ERR-05-038 thiếu lý do); `401` Thiếu token hoặc token hết hạn.

**Ghi chú.** Kèm `facets`. Kết nối có môi trường UNHEALTHY xếp đầu khi không chỉ định `sort` (BR-05-014).
:::

#### API-05-004 · Tạo kết nối nguồn

::: dac-ta
**Mục đích.** Tạo kết nối nguồn.

**Phương thức, đường dẫn.** `POST /connections`.

**Quyền.** `PERM-05-connection`.

**FR hiện thực.** FR-05-004.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ConnectionCreate`; trường bắt buộc: `connectionCode`, `name`, `typeCode`, `systemCode`, `purpose`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `ConnectionDetail`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ; kèm `errors` theo trường (gồm ERR-05-038 thiếu lý do); `401` Thiếu token hoặc token hết hạn; `403` Không đủ quyền (gồm ERR-05-011 vi phạm bốn mắt, ERR-05-040 ghi đối tượng COMMON); `409` Trạng thái không cho phép; mã cụ thể trong `code` (ERR-05-002, 009, 010, 017, 018, 026, 036); `422` Lỗi nghiệp vụ dạng dữ liệu; mã cụ thể trong `code` (ERR-05-004…006, 013…016, 020…023, 025, 027, 030, 033, 034, 037, 039).

**Ghi chú.** Mã trùng ERR-05-002; loại tắt ERR-05-004; HTTT không ACTIVE ERR-05-005. Trạng thái DRAFT.
:::

#### API-05-005 · Chi tiết kết nối

::: dac-ta
**Mục đích.** Chi tiết kết nối.

**Phương thức, đường dẫn.** `GET /connections/{connectionCode}`.

**Quyền.** `PERM-05-read`.

**FR hiện thực.** FR-05-003.

**Tham số.** `connectionCode` (path, ConnectionCode, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ConnectionDetail`; tiêu đề `ETag`.

**Lỗi.** `401` Thiếu token hoặc token hết hạn; `404` Không tìm thấy hoặc thuộc tenant khác (không phân biệt).

**Ghi chú.** Không.
:::

#### API-05-006 · Sửa thông tin kết nối

::: dac-ta
**Mục đích.** Sửa thông tin kết nối.

**Phương thức, đường dẫn.** `PATCH /connections/{connectionCode}`.

**Quyền.** `PERM-05-connection`.

**FR hiện thực.** FR-05-006.

**Tham số.** `connectionCode` (path, ConnectionCode, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ConnectionUpdate`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ConnectionDetail`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ; kèm `errors` theo trường (gồm ERR-05-038 thiếu lý do); `401` Thiếu token hoặc token hết hạn; `403` Không đủ quyền (gồm ERR-05-011 vi phạm bốn mắt, ERR-05-040 ghi đối tượng COMMON); `404` Không tìm thấy hoặc thuộc tenant khác (không phân biệt); `409` Trạng thái không cho phép; mã cụ thể trong `code` (ERR-05-002, 009, 010, 017, 018, 026, 036); `412` ETag không khớp; kèm `currentEtag`.

**Ghi chú.** Đổi mục đích sang READ khi còn tài khoản ghi hiệu lực trả ERR-05-010.
:::

#### API-05-007 · Tạm ngừng kết nối

::: dac-ta
**Mục đích.** Tạm ngừng kết nối.

**Phương thức, đường dẫn.** `POST /connections/{connectionCode}:suspend`.

**Quyền.** `PERM-05-operate`.

**FR hiện thực.** FR-05-008.

**Tham số.** `connectionCode` (path, ConnectionCode, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `StateChangeRequest`; trường bắt buộc: `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ConnectionDetail`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ; kèm `errors` theo trường (gồm ERR-05-038 thiếu lý do); `401` Thiếu token hoặc token hết hạn; `403` Không đủ quyền (gồm ERR-05-011 vi phạm bốn mắt, ERR-05-040 ghi đối tượng COMMON); `404` Không tìm thấy hoặc thuộc tenant khác (không phân biệt); `409` Trạng thái không cho phép; mã cụ thể trong `code` (ERR-05-002, 009, 010, 017, 018, 026, 036); `412` ETag không khớp; kèm `currentEtag`.

**Ghi chú.** Phát EVT-05-04; runtime từ chối lượt gọi mới bằng ERR-05-118.
:::

#### API-05-008 · Tiếp tục kết nối

::: dac-ta
**Mục đích.** Tiếp tục kết nối.

**Phương thức, đường dẫn.** `POST /connections/{connectionCode}:resume`.

**Quyền.** `PERM-05-operate`.

**FR hiện thực.** FR-05-008.

**Tham số.** `connectionCode` (path, ConnectionCode, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `StateChangeRequest`; trường bắt buộc: `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ConnectionDetail`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ; kèm `errors` theo trường (gồm ERR-05-038 thiếu lý do); `401` Thiếu token hoặc token hết hạn; `403` Không đủ quyền (gồm ERR-05-011 vi phạm bốn mắt, ERR-05-040 ghi đối tượng COMMON); `404` Không tìm thấy hoặc thuộc tenant khác (không phân biệt); `409` Trạng thái không cho phép; mã cụ thể trong `code` (ERR-05-002, 009, 010, 017, 018, 026, 036); `412` ETag không khớp; kèm `currentEtag`.

**Ghi chú.** Kết nối do SO tạm ngừng chỉ SO tiếp tục (ERR-05-011).
:::

#### API-05-009 · Ngừng dùng kết nối

::: dac-ta
**Mục đích.** Ngừng dùng kết nối.

**Phương thức, đường dẫn.** `POST /connections/{connectionCode}:retire`.

**Quyền.** `PERM-05-connection`.

**FR hiện thực.** FR-05-008.

**Tham số.** `connectionCode` (path, ConnectionCode, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `StateChangeRequest`; trường bắt buộc: `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ConnectionDetail`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ; kèm `errors` theo trường (gồm ERR-05-038 thiếu lý do); `401` Thiếu token hoặc token hết hạn; `403` Không đủ quyền (gồm ERR-05-011 vi phạm bốn mắt, ERR-05-040 ghi đối tượng COMMON); `404` Không tìm thấy hoặc thuộc tenant khác (không phân biệt); `409` Trạng thái không cho phép; mã cụ thể trong `code` (ERR-05-002, 009, 010, 017, 018, 026, 036); `412` ETag không khớp; kèm `currentEtag`.

**Ghi chú.** Còn nơi dùng trả ERR-05-010 kèm `usages`. Thu hồi cấp, tài khoản CSDL; hủy bí mật sau 30 ngày.
:::

#### API-05-025 · Nơi đang dùng kết nối

::: dac-ta
**Mục đích.** Nơi đang dùng kết nối.

**Phương thức, đường dẫn.** `GET /connections/{connectionCode}/usages`.

**Quyền.** `PERM-05-read`.

**FR hiện thực.** FR-05-013.

**Tham số.** `connectionCode` (path, ConnectionCode, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `UsageList`; trường bắt buộc: `items`; tiêu đề `ETag`.

**Lỗi.** `401` Thiếu token hoặc token hết hạn; `404` Không tìm thấy hoặc thuộc tenant khác (không phân biệt).

**Ghi chú.** Không.
:::

#### API-05-026 · Lịch sử thay đổi kết nối

::: dac-ta
**Mục đích.** Lịch sử thay đổi kết nối.

**Phương thức, đường dẫn.** `GET /connections/{connectionCode}/history`.

**Quyền.** `PERM-05-read`.

**FR hiện thực.** FR-05-016.

**Tham số.** `connectionCode` (path, ConnectionCode, bắt buộc); `cursor` (query, string, tùy chọn); `limit` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `HistoryPage`; trường bắt buộc: `items`, `page`; tiêu đề `ETag`.

**Lỗi.** `401` Thiếu token hoặc token hết hạn; `404` Không tìm thấy hoặc thuộc tenant khác (không phân biệt); `503` Phụ thuộc chưa sẵn sàng (gồm ERR-05-028 OpenBao).

**Ghi chú.** Đọc từ PH-13; `before`, `after` không bao giờ chứa bí mật.
:::

#### API-05-027 · Xuất danh sách kết nối (CSV, không bí mật)

::: dac-ta
**Mục đích.** Xuất danh sách kết nối (CSV, không bí mật).

**Phương thức, đường dẫn.** `GET /connections:export`.

**Quyền.** `PERM-05-read`.

**FR hiện thực.** FR-05-017.

**Tham số.** `q` (query, string, tùy chọn); `status` (query, array, tùy chọn); `typeCode` (query, array, tùy chọn); `systemCode` (query, SystemCode, tùy chọn); `health` (query, array, tùy chọn); `env` (query, Environment, tùy chọn); `label` (query, string, tùy chọn); `secretOverdue` (query, boolean, tùy chọn); `protocolGroup` (query, array, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, string.

**Lỗi.** `401` Thiếu token hoặc token hết hạn.

**Ghi chú.** CSV UTF-8 có BOM, không có bí mật; cùng bộ lọc với API-05-003.
:::

### Giá trị môi trường và bí mật

#### API-05-010 · Giá trị kết nối theo môi trường

::: dac-ta
**Mục đích.** Giá trị kết nối theo môi trường.

**Phương thức, đường dẫn.** `GET /connections/{connectionCode}/environments`.

**Quyền.** `PERM-05-read`.

**FR hiện thực.** FR-05-005.

**Tham số.** `connectionCode` (path, ConnectionCode, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `EnvironmentList`; trường bắt buộc: `items`; tiêu đề `ETag`.

**Lỗi.** `401` Thiếu token hoặc token hết hạn; `404` Không tìm thấy hoặc thuộc tenant khác (không phân biệt).

**Ghi chú.** Không.
:::

#### API-05-011 · Khai báo tham số không bí mật cho môi trường

::: dac-ta
**Mục đích.** Khai báo tham số không bí mật cho môi trường.

**Phương thức, đường dẫn.** `PUT /connections/{connectionCode}/environments/{env}`.

**Quyền.** `PERM-05-connection`.

**FR hiện thực.** FR-05-005.

**Tham số.** `connectionCode` (path, ConnectionCode, bắt buộc); `env` (path, Environment, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `EnvironmentParams`; trường bắt buộc: `params`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Environment_`; trường bắt buộc: `env`, `status`, `params`, `secretVersion`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ; kèm `errors` theo trường (gồm ERR-05-038 thiếu lý do); `401` Thiếu token hoặc token hết hạn; `403` Không đủ quyền (gồm ERR-05-011 vi phạm bốn mắt, ERR-05-040 ghi đối tượng COMMON); `404` Không tìm thấy hoặc thuộc tenant khác (không phân biệt); `412` ETag không khớp; kèm `currentEtag`; `422` Lỗi nghiệp vụ dạng dữ liệu; mã cụ thể trong `code` (ERR-05-004…006, 013…016, 020…023, 025, 027, 030, 033, 034, 037, 039); `423` Đang đóng băng thay đổi PROD.

**Ghi chú.** Sai lược đồ ERR-05-003; khóa bí mật ERR-05-006; vượt trần ERR-05-030; `db-flow` trỏ CSDL control plane hoặc `pg-payment` ERR-05-016; đích ngoài egress: lưu kèm `warnings[]` và đề nghị bổ sung egress cho TA, bật môi trường bị chặn tới khi có (BR-05-013). PROD đang ENABLED: lưu bản chờ (BR-05-010).
:::

#### API-05-012 · Ghi bí mật một chiều cho môi trường

::: dac-ta
**Mục đích.** Ghi bí mật một chiều cho môi trường.

**Phương thức, đường dẫn.** `PUT /connections/{connectionCode}/environments/{env}/secret`.

**Quyền.** `PERM-05-connection`.

**FR hiện thực.** FR-05-005, FR-05-011.

**Tham số.** `connectionCode` (path, ConnectionCode, bắt buộc); `env` (path, Environment, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `SecretPayload`; trường bắt buộc: `secrets`.

**Chống trùng.** Không.

**Phản hồi thành công.** `204` không có nội dung.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ; kèm `errors` theo trường (gồm ERR-05-038 thiếu lý do); `401` Thiếu token hoặc token hết hạn; `403` Không đủ quyền (gồm ERR-05-011 vi phạm bốn mắt, ERR-05-040 ghi đối tượng COMMON); `404` Không tìm thấy hoặc thuộc tenant khác (không phân biệt); `412` ETag không khớp; kèm `currentEtag`; `422` Lỗi nghiệp vụ dạng dữ liệu; mã cụ thể trong `code` (ERR-05-004…006, 013…016, 020…023, 025, 027, 030, 033, 034, 037, 039); `423` Đang đóng băng thay đổi PROD; `503` Phụ thuộc chưa sẵn sàng (gồm ERR-05-028 OpenBao).

**Ghi chú.** Ghi một chiều vào OpenBao (cas theo phiên bản). Khóa ngoài `secretKeys` ERR-05-003. Trả 204, không trả giá trị; ghi giá trị trùng phiên bản hiện tại vẫn tạo phiên bản mới.
:::

#### API-05-013 · Bật giá trị môi trường (PROD tạo đề nghị duyệt)

::: dac-ta
**Mục đích.** Bật giá trị môi trường (PROD tạo đề nghị duyệt).

**Phương thức, đường dẫn.** `POST /connections/{connectionCode}/environments/{env}:enable`.

**Quyền.** `PERM-05-connection`.

**FR hiện thực.** FR-05-007.

**Tham số.** `connectionCode` (path, ConnectionCode, bắt buộc); `env` (path, Environment, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `EnableRequest`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Environment_`; trường bắt buộc: `env`, `status`, `params`, `secretVersion`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ; kèm `errors` theo trường (gồm ERR-05-038 thiếu lý do); `401` Thiếu token hoặc token hết hạn; `403` Không đủ quyền (gồm ERR-05-011 vi phạm bốn mắt, ERR-05-040 ghi đối tượng COMMON); `404` Không tìm thấy hoặc thuộc tenant khác (không phân biệt); `409` Trạng thái không cho phép; mã cụ thể trong `code` (ERR-05-002, 009, 010, 017, 018, 026, 036); `412` ETag không khớp; kèm `currentEtag`; `422` Lỗi nghiệp vụ dạng dữ liệu; mã cụ thể trong `code` (ERR-05-004…006, 013…016, 020…023, 025, 027, 030, 033, 034, 037, 039).

**Ghi chú.** Không có kiểm tra đạt 24 giờ khớp tham số và bí mật ERR-05-009; thiếu bí mật ERR-05-014. PROD chuyển PENDING_APPROVAL và tạo việc cho IA.
:::

#### API-05-014 · Tắt giá trị môi trường

::: dac-ta
**Mục đích.** Tắt giá trị môi trường.

**Phương thức, đường dẫn.** `POST /connections/{connectionCode}/environments/{env}:disable`.

**Quyền.** `PERM-05-operate`.

**FR hiện thực.** FR-05-007.

**Tham số.** `connectionCode` (path, ConnectionCode, bắt buộc); `env` (path, Environment, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `StateChangeRequest`; trường bắt buộc: `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Environment_`; trường bắt buộc: `env`, `status`, `params`, `secretVersion`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ; kèm `errors` theo trường (gồm ERR-05-038 thiếu lý do); `401` Thiếu token hoặc token hết hạn; `403` Không đủ quyền (gồm ERR-05-011 vi phạm bốn mắt, ERR-05-040 ghi đối tượng COMMON); `404` Không tìm thấy hoặc thuộc tenant khác (không phân biệt); `409` Trạng thái không cho phép; mã cụ thể trong `code` (ERR-05-002, 009, 010, 017, 018, 026, 036); `412` ETag không khớp; kèm `currentEtag`.

**Ghi chú.** Không.
:::

#### API-05-015 · Duyệt bật giá trị PROD

::: dac-ta
**Mục đích.** Duyệt bật giá trị PROD.

**Phương thức, đường dẫn.** `POST /connections/{connectionCode}/environments/{env}:approve`.

**Quyền.** `PERM-05-approve`.

**FR hiện thực.** FR-05-007.

**Tham số.** `connectionCode` (path, ConnectionCode, bắt buộc); `env` (path, Environment, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ApprovalDecision`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Environment_`; trường bắt buộc: `env`, `status`, `params`, `secretVersion`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ; kèm `errors` theo trường (gồm ERR-05-038 thiếu lý do); `401` Thiếu token hoặc token hết hạn; `403` Không đủ quyền (gồm ERR-05-011 vi phạm bốn mắt, ERR-05-040 ghi đối tượng COMMON); `404` Không tìm thấy hoặc thuộc tenant khác (không phân biệt); `409` Trạng thái không cho phép; mã cụ thể trong `code` (ERR-05-002, 009, 010, 017, 018, 026, 036); `412` ETag không khớp; kèm `currentEtag`.

**Ghi chú.** Bốn mắt: người duyệt khác người yêu cầu và người ghi bí mật (ERR-05-011, 403). Kiểm tra hết hạn trong lúc chờ trả ERR-05-009.
:::

#### API-05-016 · Từ chối bật giá trị PROD

::: dac-ta
**Mục đích.** Từ chối bật giá trị PROD.

**Phương thức, đường dẫn.** `POST /connections/{connectionCode}/environments/{env}:reject`.

**Quyền.** `PERM-05-approve`.

**FR hiện thực.** FR-05-007.

**Tham số.** `connectionCode` (path, ConnectionCode, bắt buộc); `env` (path, Environment, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `RejectRequest`; trường bắt buộc: `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Environment_`; trường bắt buộc: `env`, `status`, `params`, `secretVersion`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ; kèm `errors` theo trường (gồm ERR-05-038 thiếu lý do); `401` Thiếu token hoặc token hết hạn; `403` Không đủ quyền (gồm ERR-05-011 vi phạm bốn mắt, ERR-05-040 ghi đối tượng COMMON); `404` Không tìm thấy hoặc thuộc tenant khác (không phân biệt); `409` Trạng thái không cho phép; mã cụ thể trong `code` (ERR-05-002, 009, 010, 017, 018, 026, 036); `412` ETag không khớp; kèm `currentEtag`.

**Ghi chú.** Không.
:::

#### API-05-020 · Xoay vòng bí mật

::: dac-ta
**Mục đích.** Xoay vòng bí mật.

**Phương thức, đường dẫn.** `POST /connections/{connectionCode}/environments/{env}:rotate-secret`.

**Quyền.** `PERM-05-operate`.

**FR hiện thực.** FR-05-012.

**Tham số.** `connectionCode` (path, ConnectionCode, bắt buộc); `env` (path, Environment, bắt buộc); `If-Match` (header, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `RotateRequest`; trường bắt buộc: `secrets`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `Rotation`; trường bắt buộc: `id`, `env`, `status`; tiêu đề `Location`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ; kèm `errors` theo trường (gồm ERR-05-038 thiếu lý do); `401` Thiếu token hoặc token hết hạn; `403` Không đủ quyền (gồm ERR-05-011 vi phạm bốn mắt, ERR-05-040 ghi đối tượng COMMON); `404` Không tìm thấy hoặc thuộc tenant khác (không phân biệt); `409` Trạng thái không cho phép; mã cụ thể trong `code` (ERR-05-002, 009, 010, 017, 018, 026, 036); `412` ETag không khớp; kèm `currentEtag`; `503` Phụ thuộc chưa sẵn sàng (gồm ERR-05-028 OpenBao).

**Ghi chú.** Đang có lần xoay mở ERR-05-036. Kiểm tra phiên bản mới thất bại thì hủy phiên bản mới, lần xoay FAILED.
:::

#### API-05-021 · Lịch sử xoay vòng bí mật

::: dac-ta
**Mục đích.** Lịch sử xoay vòng bí mật.

**Phương thức, đường dẫn.** `GET /connections/{connectionCode}/rotations`.

**Quyền.** `PERM-05-read`.

**FR hiện thực.** FR-05-012.

**Tham số.** `connectionCode` (path, ConnectionCode, bắt buộc); `env` (query, Environment, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `RotationList`; trường bắt buộc: `items`; tiêu đề `ETag`.

**Lỗi.** `401` Thiếu token hoặc token hết hạn; `404` Không tìm thấy hoặc thuộc tenant khác (không phân biệt).

**Ghi chú.** Không.
:::

### Kiểm tra kết nối

#### API-05-017 · Chạy kiểm tra kết nối

::: dac-ta
**Mục đích.** Chạy kiểm tra kết nối.

**Phương thức, đường dẫn.** `POST /connections/{connectionCode}/environments/{env}/tests`.

**Quyền.** `PERM-05-test`.

**FR hiện thực.** FR-05-010.

**Tham số.** `connectionCode` (path, ConnectionCode, bắt buộc); `env` (path, Environment, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `TestRequest`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `ConnectionTest`; trường bắt buộc: `id`, `env`, `status`; tiêu đề `Location`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ; kèm `errors` theo trường (gồm ERR-05-038 thiếu lý do); `401` Thiếu token hoặc token hết hạn; `403` Không đủ quyền (gồm ERR-05-011 vi phạm bốn mắt, ERR-05-040 ghi đối tượng COMMON); `404` Không tìm thấy hoặc thuộc tenant khác (không phân biệt); `409` Trạng thái không cho phép; mã cụ thể trong `code` (ERR-05-002, 009, 010, 017, 018, 026, 036); `429` Vượt số lần kiểm tra cho phép; kèm `retryAfterSeconds`; `503` Phụ thuộc chưa sẵn sàng (gồm ERR-05-028 OpenBao).

**Ghi chú.** Chạy ở bộ chạy `probe-jvm` vùng Z4. Đang chạy cho cùng giá trị ERR-05-018; quá 20 lần mỗi giờ cho một kết nối (`05.test.max-per-hour`) ERR-05-019. Theo dõi qua API-05-019 hoặc SSE (`Accept: text/event-stream`).
:::

#### API-05-018 · Lịch sử kiểm tra kết nối

::: dac-ta
**Mục đích.** Lịch sử kiểm tra kết nối.

**Phương thức, đường dẫn.** `GET /connections/{connectionCode}/tests`.

**Quyền.** `PERM-05-read`.

**FR hiện thực.** FR-05-010.

**Tham số.** `connectionCode` (path, ConnectionCode, bắt buộc); `env` (query, Environment, tùy chọn); `cursor` (query, string, tùy chọn); `limit` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ConnectionTestPage`; trường bắt buộc: `items`, `page`; tiêu đề `ETag`.

**Lỗi.** `401` Thiếu token hoặc token hết hạn; `404` Không tìm thấy hoặc thuộc tenant khác (không phân biệt).

**Ghi chú.** Không.
:::

#### API-05-019 · Kết quả một lần kiểm tra

::: dac-ta
**Mục đích.** Kết quả một lần kiểm tra.

**Phương thức, đường dẫn.** `GET /connections/{connectionCode}/tests/{testId}`.

**Quyền.** `PERM-05-read`.

**FR hiện thực.** FR-05-010.

**Tham số.** `connectionCode` (path, ConnectionCode, bắt buộc); `testId` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ConnectionTest`; trường bắt buộc: `id`, `env`, `status`; tiêu đề `ETag`.

**Lỗi.** `401` Thiếu token hoặc token hết hạn; `404` Không tìm thấy hoặc thuộc tenant khác (không phân biệt).

**Ghi chú.** Với `Accept: text/event-stream` trả sự kiện `step` và `completed`.
:::

### Cấp kết nối

#### API-05-022 · Danh sách cấp quyền sử dụng

::: dac-ta
**Mục đích.** Danh sách cấp quyền sử dụng.

**Phương thức, đường dẫn.** `GET /connections/{connectionCode}/grants`.

**Quyền.** `PERM-05-read`.

**FR hiện thực.** FR-05-009.

**Tham số.** `connectionCode` (path, ConnectionCode, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `GrantList`; trường bắt buộc: `items`; tiêu đề `ETag`.

**Lỗi.** `401` Thiếu token hoặc token hết hạn; `404` Không tìm thấy hoặc thuộc tenant khác (không phân biệt).

**Ghi chú.** Không.
:::

#### API-05-023 · Cấp quyền sử dụng cho không gian làm việc hoặc luồng

::: dac-ta
**Mục đích.** Cấp quyền sử dụng cho không gian làm việc hoặc luồng.

**Phương thức, đường dẫn.** `POST /connections/{connectionCode}/grants`.

**Quyền.** `PERM-05-connection`.

**FR hiện thực.** FR-05-009.

**Tham số.** `connectionCode` (path, ConnectionCode, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `GrantCreate`; trường bắt buộc: `scope`, `targetCode`, `environments`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `Grant`; trường bắt buộc: `id`, `scope`, `targetCode`, `environments`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ; kèm `errors` theo trường (gồm ERR-05-038 thiếu lý do); `401` Thiếu token hoặc token hết hạn; `403` Không đủ quyền (gồm ERR-05-011 vi phạm bốn mắt, ERR-05-040 ghi đối tượng COMMON); `404` Không tìm thấy hoặc thuộc tenant khác (không phân biệt); `409` Trạng thái không cho phép; mã cụ thể trong `code` (ERR-05-002, 009, 010, 017, 018, 026, 036); `422` Lỗi nghiệp vụ dạng dữ liệu; mã cụ thể trong `code` (ERR-05-004…006, 013…016, 020…023, 025, 027, 030, 033, 034, 037, 039).

**Ghi chú.** Không gian hoặc luồng không tồn tại ở PH-04, hoặc API không tồn tại ở PH-02 (phạm vi API, API-02-002) ERR-05-033; kết nối không thuộc nhóm http-* với phạm vi API ERR-05-003. Phát EVT-05-05.
:::

#### API-05-024 · Thu hồi quyền sử dụng

::: dac-ta
**Mục đích.** Thu hồi quyền sử dụng.

**Phương thức, đường dẫn.** `DELETE /connections/{connectionCode}/grants/{grantId}`.

**Quyền.** `PERM-05-connection`.

**FR hiện thực.** FR-05-009.

**Tham số.** `connectionCode` (path, ConnectionCode, bắt buộc); `grantId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `204` không có nội dung.

**Lỗi.** `401` Thiếu token hoặc token hết hạn; `403` Không đủ quyền (gồm ERR-05-011 vi phạm bốn mắt, ERR-05-040 ghi đối tượng COMMON); `404` Không tìm thấy hoặc thuộc tenant khác (không phân biệt); `409` Trạng thái không cho phép; mã cụ thể trong `code` (ERR-05-002, 009, 010, 017, 018, 026, 036); `412` ETag không khớp; kèm `currentEtag`.

**Ghi chú.** Luồng đang chạy dùng cấp này được cảnh báo; thu hồi có hiệu lực ở lần phát hành kế tiếp của luồng.
:::

### Nhập hệ cũ

#### API-05-028 · Tải gói kết nối hệ cũ để phân tích

::: dac-ta
**Mục đích.** Tải gói kết nối hệ cũ để phân tích.

**Phương thức, đường dẫn.** `POST /connections/legacy-imports`.

**Quyền.** `PERM-05-connection`.

**FR hiện thực.** FR-05-018.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** multipart/form-data: object.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `LegacyImportJob`; trường bắt buộc: `id`, `status`; tiêu đề `Location`.

**Lỗi.** `401` Thiếu token hoặc token hết hạn; `403` Không đủ quyền (gồm ERR-05-011 vi phạm bốn mắt, ERR-05-040 ghi đối tượng COMMON); `413` Dữ liệu mẫu vượt 1 MiB hoặc tệp nhập quá lớn (ERR-05-024); `422` Lỗi nghiệp vụ dạng dữ liệu; mã cụ thể trong `code` (ERR-05-004…006, 013…016, 020…023, 025, 027, 030, 033, 034, 037, 039).

**Ghi chú.** multipart/form-data `file` (XML Context, ZIP gói xuất Bus, .properties; ≤ 20 MiB, quá lớn ERR-05-024 với 413). Sai định dạng ERR-05-024. Không thực thi, không lưu tệp; bí mật thay bằng vị trí (BR-05-025).
:::

#### API-05-029 · Kết quả phân tích gói hệ cũ

::: dac-ta
**Mục đích.** Kết quả phân tích gói hệ cũ.

**Phương thức, đường dẫn.** `GET /connections/legacy-imports/{jobId}`.

**Quyền.** `PERM-05-read`.

**FR hiện thực.** FR-05-018.

**Tham số.** `jobId` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `LegacyImportJob`; trường bắt buộc: `id`, `status`; tiêu đề `ETag`.

**Lỗi.** `401` Thiếu token hoặc token hết hạn; `404` Không tìm thấy hoặc thuộc tenant khác (không phân biệt).

**Ghi chú.** Không.
:::

#### API-05-030 · Tạo kết nối nháp từ gói hệ cũ

::: dac-ta
**Mục đích.** Tạo kết nối nháp từ gói hệ cũ.

**Phương thức, đường dẫn.** `POST /connections/legacy-imports/{jobId}:commit`.

**Quyền.** `PERM-05-connection`.

**FR hiện thực.** FR-05-018.

**Tham số.** `jobId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `LegacyCommit`; trường bắt buộc: `items`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `LegacyImportJob`; trường bắt buộc: `id`, `status`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ; kèm `errors` theo trường (gồm ERR-05-038 thiếu lý do); `401` Thiếu token hoặc token hết hạn; `403` Không đủ quyền (gồm ERR-05-011 vi phạm bốn mắt, ERR-05-040 ghi đối tượng COMMON); `404` Không tìm thấy hoặc thuộc tenant khác (không phân biệt); `409` Trạng thái không cho phép; mã cụ thể trong `code` (ERR-05-002, 009, 010, 017, 018, 026, 036); `412` ETag không khớp; kèm `currentEtag`; `422` Lỗi nghiệp vụ dạng dữ liệu; mã cụ thể trong `code` (ERR-05-004…006, 013…016, 020…023, 025, 027, 030, 033, 034, 037, 039).

**Ghi chú.** Tạo kết nối DRAFT; người dùng khai lại bí mật.
:::

### Nội bộ (PH-04, runtime)

#### API-05-031 · Xác minh tham chiếu kết nối cho PH-04

::: dac-ta
**Mục đích.** Xác minh tham chiếu kết nối cho PH-04.

**Phương thức, đường dẫn.** `POST /internal/connection-references:verify`.

**Quyền.** Token dịch vụ, scope `adapter:verify`.

**FR hiện thực.** FR-05-014.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `VerifyRequest`; trường bắt buộc: `workspaceCode`, `flowCode`, `stage`, `references`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `VerifyResult`; trường bắt buộc: `allOk`, `results`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ; kèm `errors` theo trường (gồm ERR-05-038 thiếu lý do); `401` Thiếu token hoặc token hết hạn; `403` Không đủ quyền (gồm ERR-05-011 vi phạm bốn mắt, ERR-05-040 ghi đối tượng COMMON); `503` Phụ thuộc chưa sẵn sàng (gồm ERR-05-028 OpenBao).

**Ghi chú.** Gọi bởi PH-04 ở mức DESIGN, SUBMIT, PUBLISH (VR-07). Không ném lỗi nghiệp vụ theo từng tham chiếu; cập nhật chỉ mục nơi dùng.
:::

#### API-05-032 · Cấu hình kết nối không bí mật cho runtime

::: dac-ta
**Mục đích.** Cấu hình kết nối không bí mật cho runtime.

**Phương thức, đường dẫn.** `GET /internal/runtime/connections`.

**Quyền.** Token dịch vụ, scope `adapter:runtime-config`.

**FR hiện thực.** FR-05-015.

**Tham số.** `env` (query, Environment, tùy chọn); `If-None-Match` (header, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `RuntimeConfig`; trường bắt buộc: `tenant`, `env`, `configVersion`, `connections`; tiêu đề `ETag`; `304` không đổi.

**Lỗi.** `401` Thiếu token hoặc token hết hạn.

**Ghi chú.** Gọi bởi `dh-runtime` của tenant (scope `adapter:runtime-config`). Có `ETag`; `If-None-Match` khớp trả 304.
:::

#### API-05-089 · Danh mục Kamelet cho trình thiết kế và runtime

::: dac-ta
**Mục đích.** Danh mục Kamelet cho trình thiết kế và runtime.

**Phương thức, đường dẫn.** `GET /internal/catalog/kamelets`.

**Quyền.** Token dịch vụ, scope `adapter:runtime-config`.

**FR hiện thực.** FR-05-047, FR-05-059.

**Tham số.** `runtimeProfile` (query, string, tùy chọn); `If-None-Match` (header, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `KameletCatalog`; trường bắt buộc: `items`, `catalogHash`; tiêu đề `ETag`; `304` không đổi.

**Lỗi.** `401` Thiếu token hoặc token hết hạn.

**Ghi chú.** Gọi bởi PH-04 và runtime; có `ETag`.
:::

#### API-05-093 · Trạng thái sức khỏe cho PH-04 và PH-13

::: dac-ta
**Mục đích.** Trạng thái sức khỏe cho PH-04 và PH-13.

**Phương thức, đường dẫn.** `GET /internal/health/states`.

**Quyền.** Token dịch vụ, scope `adapter:health-read`.

**FR hiện thực.** FR-05-021.

**Tham số.** `env` (query, Environment, tùy chọn); `level` (query, array, tùy chọn); `since` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `HealthStateList`; trường bắt buộc: `items`; tiêu đề `ETag`.

**Lỗi.** `401` Thiếu token hoặc token hết hạn.

**Ghi chú.** Gọi bởi PH-04, PH-13 (scope `adapter:health-read`).
:::

### Sức khỏe

#### API-05-033 · Tổng quan sức khỏe kết nối và bộ điều hợp

::: dac-ta
**Mục đích.** Tổng quan sức khỏe kết nối và bộ điều hợp.

**Phương thức, đường dẫn.** `GET /health/overview`.

**Quyền.** `PERM-05-read`.

**FR hiện thực.** FR-05-022.

**Tham số.** `env` (query, Environment, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `HealthOverview`; trường bắt buộc: `totals`, `attention`; tiêu đề `ETag`.

**Lỗi.** `401` Thiếu token hoặc token hết hạn.

**Ghi chú.** Không.
:::

#### API-05-034 · Sức khỏe một kết nối

::: dac-ta
**Mục đích.** Sức khỏe một kết nối.

**Phương thức, đường dẫn.** `GET /connections/{connectionCode}/health`.

**Quyền.** `PERM-05-read`.

**FR hiện thực.** FR-05-019, FR-05-020.

**Tham số.** `connectionCode` (path, ConnectionCode, bắt buộc); `env` (query, Environment, tùy chọn); `window` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `HealthDetail`; tiêu đề `ETag`.

**Lỗi.** `401` Thiếu token hoặc token hết hạn; `404` Không tìm thấy hoặc thuộc tenant khác (không phân biệt).

**Ghi chú.** Không.
:::

#### API-05-061 · Sức khỏe bộ điều hợp

::: dac-ta
**Mục đích.** Sức khỏe bộ điều hợp.

**Phương thức, đường dẫn.** `GET /adapters/{adapterCode}/health`.

**Quyền.** `PERM-05-read`.

**FR hiện thực.** FR-05-019, FR-05-020.

**Tham số.** `adapterCode` (path, AdapterCode, bắt buộc); `env` (query, Environment, tùy chọn); `window` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `HealthDetail`; tiêu đề `ETag`.

**Lỗi.** `401` Thiếu token hoặc token hết hạn; `404` Không tìm thấy hoặc thuộc tenant khác (không phân biệt).

**Ghi chú.** Không.
:::

### Tài khoản CSDL cho luồng

#### API-05-035 · Tài khoản CSDL theo luồng

::: dac-ta
**Mục đích.** Tài khoản CSDL theo luồng.

**Phương thức, đường dẫn.** `GET /connections/{connectionCode}/flow-accounts`.

**Quyền.** `PERM-05-read`.

**FR hiện thực.** FR-05-024.

**Tham số.** `connectionCode` (path, ConnectionCode, bắt buộc); `flowCode` (query, string, tùy chọn); `status` (query, array, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `FlowAccountList`; trường bắt buộc: `items`; tiêu đề `ETag`.

**Lỗi.** `401` Thiếu token hoặc token hết hạn; `404` Không tìm thấy hoặc thuộc tenant khác (không phân biệt).

**Ghi chú.** Không.
:::

#### API-05-036 · Yêu cầu cấp tài khoản CSDL cho luồng

::: dac-ta
**Mục đích.** Yêu cầu cấp tài khoản CSDL cho luồng.

**Phương thức, đường dẫn.** `POST /connections/{connectionCode}/flow-accounts`.

**Quyền.** `PERM-05-connection`.

**FR hiện thực.** FR-05-024, FR-05-026.

**Tham số.** `connectionCode` (path, ConnectionCode, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `FlowAccountRequest`; trường bắt buộc: `flowCode`, `environments`, `schemas`, `accessMode`, `justification`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `FlowAccountList`; trường bắt buộc: `items`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ; kèm `errors` theo trường (gồm ERR-05-038 thiếu lý do); `401` Thiếu token hoặc token hết hạn; `403` Không đủ quyền (gồm ERR-05-011 vi phạm bốn mắt, ERR-05-040 ghi đối tượng COMMON); `404` Không tìm thấy hoặc thuộc tenant khác (không phân biệt); `409` Trạng thái không cho phép; mã cụ thể trong `code` (ERR-05-002, 009, 010, 017, 018, 026, 036); `422` Lỗi nghiệp vụ dạng dữ liệu; mã cụ thể trong `code` (ERR-05-004…006, 013…016, 020…023, 025, 027, 030, 033, 034, 037, 039); `503` Phụ thuộc chưa sẵn sàng (gồm ERR-05-028 OpenBao).

**Ghi chú.** Một dòng mỗi môi trường. READ: cấp ngay (ISSUED) với kết nối `db-flow` DYNAMIC. WRITE: REQUESTED, tạo việc cho SO. Kết nối READ mà xin WRITE ERR-05-017; phạm vi CSDL control plane ERR-05-016; ngoài `allowedSchemas` ERR-05-027; hạn > 90 ngày ERR-05-037.
:::

#### API-05-037 · Cán bộ ATTT đồng ý mục đích ghi

::: dac-ta
**Mục đích.** Cán bộ ATTT đồng ý mục đích ghi.

**Phương thức, đường dẫn.** `POST /connections/{connectionCode}/flow-accounts/{accountId}:consent`.

**Quyền.** `PERM-05-db-write-consent`.

**FR hiện thực.** FR-05-026.

**Tham số.** `connectionCode` (path, ConnectionCode, bắt buộc); `accountId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ConsentRequest`; trường bắt buộc: `opinion`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `FlowAccount`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ; kèm `errors` theo trường (gồm ERR-05-038 thiếu lý do); `401` Thiếu token hoặc token hết hạn; `403` Không đủ quyền (gồm ERR-05-011 vi phạm bốn mắt, ERR-05-040 ghi đối tượng COMMON); `404` Không tìm thấy hoặc thuộc tenant khác (không phân biệt); `409` Trạng thái không cho phép; mã cụ thể trong `code` (ERR-05-002, 009, 010, 017, 018, 026, 036); `412` ETag không khớp; kèm `currentEtag`.

**Ghi chú.** Chỉ SO (`PERM-05-db-write-consent`).
:::

#### API-05-038 · Duyệt tài khoản ghi

::: dac-ta
**Mục đích.** Duyệt tài khoản ghi.

**Phương thức, đường dẫn.** `POST /connections/{connectionCode}/flow-accounts/{accountId}:approve`.

**Quyền.** `PERM-05-approve`.

**FR hiện thực.** FR-05-026.

**Tham số.** `connectionCode` (path, ConnectionCode, bắt buộc); `accountId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ApprovalDecision`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `FlowAccount`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ; kèm `errors` theo trường (gồm ERR-05-038 thiếu lý do); `401` Thiếu token hoặc token hết hạn; `403` Không đủ quyền (gồm ERR-05-011 vi phạm bốn mắt, ERR-05-040 ghi đối tượng COMMON); `404` Không tìm thấy hoặc thuộc tenant khác (không phân biệt); `409` Trạng thái không cho phép; mã cụ thể trong `code` (ERR-05-002, 009, 010, 017, 018, 026, 036); `412` ETag không khớp; kèm `currentEtag`; `503` Phụ thuộc chưa sẵn sàng (gồm ERR-05-028 OpenBao).

**Ghi chú.** IA khác người yêu cầu và SO (ERR-05-011). Ghi role OpenBao, ISSUED.
:::

#### API-05-039 · Thu hồi tài khoản CSDL

::: dac-ta
**Mục đích.** Thu hồi tài khoản CSDL.

**Phương thức, đường dẫn.** `POST /connections/{connectionCode}/flow-accounts/{accountId}:revoke`.

**Quyền.** `PERM-05-connection` hoặc `PERM-05-operate`.

**FR hiện thực.** FR-05-028.

**Tham số.** `connectionCode` (path, ConnectionCode, bắt buộc); `accountId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `StateChangeRequest`; trường bắt buộc: `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `FlowAccount`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ; kèm `errors` theo trường (gồm ERR-05-038 thiếu lý do); `401` Thiếu token hoặc token hết hạn; `403` Không đủ quyền (gồm ERR-05-011 vi phạm bốn mắt, ERR-05-040 ghi đối tượng COMMON); `404` Không tìm thấy hoặc thuộc tenant khác (không phân biệt); `409` Trạng thái không cho phép; mã cụ thể trong `code` (ERR-05-002, 009, 010, 017, 018, 026, 036); `412` ETag không khớp; kèm `currentEtag`.

**Ghi chú.** Xóa role, thu hồi lease; tài khoản động bị xóa ở CSDL nguồn ≤ 60 giây (NFR-05-007).
:::

#### API-05-040 · Kiểm tra quyền thực tế của tài khoản CSDL

::: dac-ta
**Mục đích.** Kiểm tra quyền thực tế của tài khoản CSDL.

**Phương thức, đường dẫn.** `POST /connections/{connectionCode}/environments/{env}:inspect-privileges`.

**Quyền.** `PERM-05-test`.

**FR hiện thực.** FR-05-025.

**Tham số.** `connectionCode` (path, ConnectionCode, bắt buộc); `env` (path, Environment, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `PrivilegeReport`; trường bắt buộc: `verdict`, `grants`.

**Lỗi.** `401` Thiếu token hoặc token hết hạn; `403` Không đủ quyền (gồm ERR-05-011 vi phạm bốn mắt, ERR-05-040 ghi đối tượng COMMON); `404` Không tìm thấy hoặc thuộc tenant khác (không phân biệt); `422` Lỗi nghiệp vụ dạng dữ liệu; mã cụ thể trong `code` (ERR-05-004…006, 013…016, 020…023, 025, 027, 030, 033, 034, 037, 039); `503` Phụ thuộc chưa sẵn sàng (gồm ERR-05-028 OpenBao).

**Ghi chú.** Tài khoản khai chỉ đọc mà có quyền ghi trả 200 với `verdict = EXCESSIVE` và chặn bật môi trường (ERR-05-015).
:::

#### API-05-041 · Tra nhật ký truy cập CSDL của luồng

::: dac-ta
**Mục đích.** Tra nhật ký truy cập CSDL của luồng.

**Phương thức, đường dẫn.** `GET /db-access-logs`.

**Quyền.** `PERM-05-audit-read`.

**FR hiện thực.** FR-05-027.

**Tham số.** `flowCode` (query, string, tùy chọn); `connectionCode` (query, ConnectionCode, tùy chọn); `from` (query, string, tùy chọn); `to` (query, string, tùy chọn); `outcome` (query, array, tùy chọn); `cursor` (query, string, tùy chọn); `limit` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `DbAccessPage`; trường bắt buộc: `items`, `page`; tiêu đề `ETag`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ; kèm `errors` theo trường (gồm ERR-05-038 thiếu lý do); `401` Thiếu token hoặc token hết hạn.

**Ghi chú.** Khoảng thời gian tối đa 31 ngày mỗi truy vấn.
:::

### Bộ điều hợp

#### API-05-043 · Danh sách bộ điều hợp

::: dac-ta
**Mục đích.** Danh sách bộ điều hợp.

**Phương thức, đường dẫn.** `GET /adapters`.

**Quyền.** `PERM-05-read`.

**FR hiện thực.** FR-05-029.

**Tham số.** `q` (query, string, tùy chọn); `systemCode` (query, SystemCode, tùy chọn); `systemGroup` (query, array, tùy chọn); `protocol` (query, array, tùy chọn); `status` (query, array, tùy chọn); `versionStatus` (query, array, tùy chọn); `health` (query, array, tùy chọn); `hasPendingSchemaChange` (query, boolean, tùy chọn); `hasPendingVersion` (query, boolean, tùy chọn); `sort` (query, string, tùy chọn); `cursor` (query, string, tùy chọn); `limit` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `AdapterPage`; trường bắt buộc: `items`, `page`; tiêu đề `ETag`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ; kèm `errors` theo trường (gồm ERR-05-038 thiếu lý do); `401` Thiếu token hoặc token hết hạn.

**Ghi chú.** Kèm `facets`, `cards`. UNHEALTHY xếp đầu khi không chỉ định `sort`.
:::

#### API-05-044 · Tạo bộ điều hợp

::: dac-ta
**Mục đích.** Tạo bộ điều hợp.

**Phương thức, đường dẫn.** `POST /adapters`.

**Quyền.** `PERM-05-adapter`.

**FR hiện thực.** FR-05-031.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `AdapterCreate`; trường bắt buộc: `adapterCode`, `name`, `systemCode`, `systemGroup`, `protocol`, `connectionCode`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `AdapterDetail`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ; kèm `errors` theo trường (gồm ERR-05-038 thiếu lý do); `401` Thiếu token hoặc token hết hạn; `403` Không đủ quyền (gồm ERR-05-011 vi phạm bốn mắt, ERR-05-040 ghi đối tượng COMMON); `409` Trạng thái không cho phép; mã cụ thể trong `code` (ERR-05-002, 009, 010, 017, 018, 026, 036); `422` Lỗi nghiệp vụ dạng dữ liệu; mã cụ thể trong `code` (ERR-05-004…006, 013…016, 020…023, 025, 027, 030, 033, 034, 037, 039).

**Ghi chú.** Tạo bộ điều hợp DRAFT và phiên bản 1.0 DRAFT. Kết nối khác HTTT ERR-05-013 (BR-05-015).
:::

#### API-05-045 · Chi tiết bộ điều hợp

::: dac-ta
**Mục đích.** Chi tiết bộ điều hợp.

**Phương thức, đường dẫn.** `GET /adapters/{adapterCode}`.

**Quyền.** `PERM-05-read`.

**FR hiện thực.** FR-05-030.

**Tham số.** `adapterCode` (path, AdapterCode, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `AdapterDetail`; tiêu đề `ETag`.

**Lỗi.** `401` Thiếu token hoặc token hết hạn; `404` Không tìm thấy hoặc thuộc tenant khác (không phân biệt).

**Ghi chú.** Không.
:::

#### API-05-046 · Sửa thông tin chung bộ điều hợp

::: dac-ta
**Mục đích.** Sửa thông tin chung bộ điều hợp.

**Phương thức, đường dẫn.** `PATCH /adapters/{adapterCode}`.

**Quyền.** `PERM-05-adapter`.

**FR hiện thực.** FR-05-031.

**Tham số.** `adapterCode` (path, AdapterCode, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `AdapterUpdate`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `AdapterDetail`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ; kèm `errors` theo trường (gồm ERR-05-038 thiếu lý do); `401` Thiếu token hoặc token hết hạn; `403` Không đủ quyền (gồm ERR-05-011 vi phạm bốn mắt, ERR-05-040 ghi đối tượng COMMON); `404` Không tìm thấy hoặc thuộc tenant khác (không phân biệt); `412` ETag không khớp; kèm `currentEtag`.

**Ghi chú.** Không.
:::

#### API-05-047 · Danh sách phiên bản

::: dac-ta
**Mục đích.** Danh sách phiên bản.

**Phương thức, đường dẫn.** `GET /adapters/{adapterCode}/versions`.

**Quyền.** `PERM-05-read`.

**FR hiện thực.** FR-05-045.

**Tham số.** `adapterCode` (path, AdapterCode, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `AdapterVersionList`; trường bắt buộc: `items`; tiêu đề `ETag`.

**Lỗi.** `401` Thiếu token hoặc token hết hạn; `404` Không tìm thấy hoặc thuộc tenant khác (không phân biệt).

**Ghi chú.** Không.
:::

#### API-05-048 · Tạo phiên bản nháp mới

::: dac-ta
**Mục đích.** Tạo phiên bản nháp mới.

**Phương thức, đường dẫn.** `POST /adapters/{adapterCode}/versions`.

**Quyền.** `PERM-05-adapter`.

**FR hiện thực.** FR-05-045.

**Tham số.** `adapterCode` (path, AdapterCode, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `NewVersionRequest`; trường bắt buộc: `bump`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `AdapterVersion`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ; kèm `errors` theo trường (gồm ERR-05-038 thiếu lý do); `401` Thiếu token hoặc token hết hạn; `403` Không đủ quyền (gồm ERR-05-011 vi phạm bốn mắt, ERR-05-040 ghi đối tượng COMMON); `404` Không tìm thấy hoặc thuộc tenant khác (không phân biệt); `409` Trạng thái không cho phép; mã cụ thể trong `code` (ERR-05-002, 009, 010, 017, 018, 026, 036).

**Ghi chú.** Đã có bản nháp ERR-05-008 (BR-05-016). MAJOR khi đổi không tương thích; giao diện gợi ý theo khác biệt.
:::

#### API-05-049 · Chi tiết một phiên bản

::: dac-ta
**Mục đích.** Chi tiết một phiên bản.

**Phương thức, đường dẫn.** `GET /adapters/{adapterCode}/versions/{version}`.

**Quyền.** `PERM-05-read`.

**FR hiện thực.** FR-05-030.

**Tham số.** `adapterCode` (path, AdapterCode, bắt buộc); `version` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `AdapterVersion`; tiêu đề `ETag`.

**Lỗi.** `401` Thiếu token hoặc token hết hạn; `404` Không tìm thấy hoặc thuộc tenant khác (không phân biệt).

**Ghi chú.** Không.
:::

#### API-05-050 · Khai báo hoặc sửa thao tác

::: dac-ta
**Mục đích.** Khai báo hoặc sửa thao tác.

**Phương thức, đường dẫn.** `PUT /adapters/{adapterCode}/versions/{version}/operations/{operationCode}`.

**Quyền.** `PERM-05-adapter`.

**FR hiện thực.** FR-05-032, FR-05-033, FR-05-034, FR-05-035, FR-05-036, FR-05-037, FR-05-038, FR-05-039, FR-05-040, FR-05-041.

**Tham số.** `adapterCode` (path, AdapterCode, bắt buộc); `version` (path, string, bắt buộc); `operationCode` (path, OperationCode, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `Operation`; trường bắt buộc: `operationCode`, `title`, `direction`, `protocolSpec`, `requestFormat`, `responseFormat`, `timeoutMs`, `sideEffect`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `AdapterVersion`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ; kèm `errors` theo trường (gồm ERR-05-038 thiếu lý do); `401` Thiếu token hoặc token hết hạn; `403` Không đủ quyền (gồm ERR-05-011 vi phạm bốn mắt, ERR-05-040 ghi đối tượng COMMON); `404` Không tìm thấy hoặc thuộc tenant khác (không phân biệt); `409` Trạng thái không cho phép; mã cụ thể trong `code` (ERR-05-002, 009, 010, 017, 018, 026, 036); `412` ETag không khớp; kèm `currentEtag`; `413` Dữ liệu mẫu vượt 1 MiB hoặc tệp nhập quá lớn (ERR-05-024); `422` Lỗi nghiệp vụ dạng dữ liệu; mã cụ thể trong `code` (ERR-05-004…006, 013…016, 020…023, 025, 027, 030, 033, 034, 037, 039).

**Ghi chú.** Chỉ ở DRAFT. `sideEffect = WRITE` với kết nối READ ERR-05-017. Câu lệnh SQL ghép chuỗi, phương thức không hợp lệ, mã hóa VNI trả ERR-05-032; mẫu có mã độc ERR-05-034.
:::

#### API-05-051 · Xóa thao tác khỏi bản nháp

::: dac-ta
**Mục đích.** Xóa thao tác khỏi bản nháp.

**Phương thức, đường dẫn.** `DELETE /adapters/{adapterCode}/versions/{version}/operations/{operationCode}`.

**Quyền.** `PERM-05-adapter`.

**FR hiện thực.** FR-05-032.

**Tham số.** `adapterCode` (path, AdapterCode, bắt buộc); `version` (path, string, bắt buộc); `operationCode` (path, OperationCode, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `204` không có nội dung.

**Lỗi.** `401` Thiếu token hoặc token hết hạn; `403` Không đủ quyền (gồm ERR-05-011 vi phạm bốn mắt, ERR-05-040 ghi đối tượng COMMON); `404` Không tìm thấy hoặc thuộc tenant khác (không phân biệt); `409` Trạng thái không cho phép; mã cụ thể trong `code` (ERR-05-002, 009, 010, 017, 018, 026, 036); `412` ETag không khớp; kèm `currentEtag`.

**Ghi chú.** Không.
:::

#### API-05-052 · Chạy kiểm thử bộ điều hợp

::: dac-ta
**Mục đích.** Chạy kiểm thử bộ điều hợp.

**Phương thức, đường dẫn.** `POST /adapters/{adapterCode}/versions/{version}/tests`.

**Quyền.** `PERM-05-test`.

**FR hiện thực.** FR-05-043.

**Tham số.** `adapterCode` (path, AdapterCode, bắt buộc); `version` (path, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `AdapterTestRequest`; trường bắt buộc: `env`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `AdapterTest`; trường bắt buộc: `id`, `status`; tiêu đề `Location`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ; kèm `errors` theo trường (gồm ERR-05-038 thiếu lý do); `401` Thiếu token hoặc token hết hạn; `403` Không đủ quyền (gồm ERR-05-011 vi phạm bốn mắt, ERR-05-040 ghi đối tượng COMMON); `404` Không tìm thấy hoặc thuộc tenant khác (không phân biệt); `409` Trạng thái không cho phép; mã cụ thể trong `code` (ERR-05-002, 009, 010, 017, 018, 026, 036); `503` Phụ thuộc chưa sẵn sàng (gồm ERR-05-028 OpenBao).

**Ghi chú.** Chạy ở TEST hoặc STAGING, không bao giờ PROD; thao tác ghi cần `confirmWriteOnTest = true` (BR-05-030). Kết quả hiệu lực 24 giờ cho gửi duyệt.
:::

#### API-05-053 · Kết quả kiểm thử bộ điều hợp

::: dac-ta
**Mục đích.** Kết quả kiểm thử bộ điều hợp.

**Phương thức, đường dẫn.** `GET /adapters/{adapterCode}/tests/{testId}`.

**Quyền.** `PERM-05-read`.

**FR hiện thực.** FR-05-043.

**Tham số.** `adapterCode` (path, AdapterCode, bắt buộc); `testId` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `AdapterTest`; trường bắt buộc: `id`, `status`; tiêu đề `ETag`.

**Lỗi.** `401` Thiếu token hoặc token hết hạn; `404` Không tìm thấy hoặc thuộc tenant khác (không phân biệt).

**Ghi chú.** Không.
:::

#### API-05-054 · Chạy thử chuyển đổi định dạng với dữ liệu mẫu

::: dac-ta
**Mục đích.** Chạy thử chuyển đổi định dạng với dữ liệu mẫu.

**Phương thức, đường dẫn.** `POST /adapters/{adapterCode}/versions/{version}:preview-transform`.

**Quyền.** `PERM-05-test`.

**FR hiện thực.** FR-05-040, FR-05-041.

**Tham số.** `adapterCode` (path, AdapterCode, bắt buộc); `version` (path, string, bắt buộc).

**Thân yêu cầu.** application/json: `TransformPreviewRequest`; trường bắt buộc: `operationCode`, `sample`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `TransformPreview`; trường bắt buộc: `output`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ; kèm `errors` theo trường (gồm ERR-05-038 thiếu lý do); `401` Thiếu token hoặc token hết hạn; `403` Không đủ quyền (gồm ERR-05-011 vi phạm bốn mắt, ERR-05-040 ghi đối tượng COMMON); `404` Không tìm thấy hoặc thuộc tenant khác (không phân biệt); `413` Dữ liệu mẫu vượt 1 MiB hoặc tệp nhập quá lớn (ERR-05-024); `422` Lỗi nghiệp vụ dạng dữ liệu; mã cụ thể trong `code` (ERR-05-004…006, 013…016, 020…023, 025, 027, 030, 033, 034, 037, 039).

**Ghi chú.** Không gọi hệ đích; chạy chuyển đổi trên dữ liệu mẫu trong tiến trình cô lập, ≤ 2 giây.
:::

#### API-05-055 · Gửi duyệt phiên bản

::: dac-ta
**Mục đích.** Gửi duyệt phiên bản.

**Phương thức, đường dẫn.** `POST /adapters/{adapterCode}/versions/{version}:submit`.

**Quyền.** `PERM-05-adapter`.

**FR hiện thực.** FR-05-044.

**Tham số.** `adapterCode` (path, AdapterCode, bắt buộc); `version` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `SubmitRequest`; trường bắt buộc: `changeNote`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `AdapterVersion`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ; kèm `errors` theo trường (gồm ERR-05-038 thiếu lý do); `401` Thiếu token hoặc token hết hạn; `403` Không đủ quyền (gồm ERR-05-011 vi phạm bốn mắt, ERR-05-040 ghi đối tượng COMMON); `404` Không tìm thấy hoặc thuộc tenant khác (không phân biệt); `409` Trạng thái không cho phép; mã cụ thể trong `code` (ERR-05-002, 009, 010, 017, 018, 026, 036); `412` ETag không khớp; kèm `currentEtag`.

**Ghi chú.** Mọi thao tác có kiểm thử đạt 24 giờ trên đúng băm nội dung (ERR-05-009).
:::

#### API-05-056 · Duyệt phiên bản

::: dac-ta
**Mục đích.** Duyệt phiên bản.

**Phương thức, đường dẫn.** `POST /adapters/{adapterCode}/versions/{version}:approve`.

**Quyền.** `PERM-05-approve`.

**FR hiện thực.** FR-05-044.

**Tham số.** `adapterCode` (path, AdapterCode, bắt buộc); `version` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ApprovalDecision`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `AdapterVersion`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ; kèm `errors` theo trường (gồm ERR-05-038 thiếu lý do); `401` Thiếu token hoặc token hết hạn; `403` Không đủ quyền (gồm ERR-05-011 vi phạm bốn mắt, ERR-05-040 ghi đối tượng COMMON); `404` Không tìm thấy hoặc thuộc tenant khác (không phân biệt); `409` Trạng thái không cho phép; mã cụ thể trong `code` (ERR-05-002, 009, 010, 017, 018, 026, 036); `412` ETag không khớp; kèm `currentEtag`.

**Ghi chú.** Bốn mắt (ERR-05-011). Sinh Kamelet theo thao tác (FR-05-047), phát EVT-05-07, EVT-05-09; phiên bản trước SUPERSEDED.
:::

#### API-05-057 · Từ chối phiên bản

::: dac-ta
**Mục đích.** Từ chối phiên bản.

**Phương thức, đường dẫn.** `POST /adapters/{adapterCode}/versions/{version}:reject`.

**Quyền.** `PERM-05-approve`.

**FR hiện thực.** FR-05-044.

**Tham số.** `adapterCode` (path, AdapterCode, bắt buộc); `version` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `RejectRequest`; trường bắt buộc: `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `AdapterVersion`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ; kèm `errors` theo trường (gồm ERR-05-038 thiếu lý do); `401` Thiếu token hoặc token hết hạn; `403` Không đủ quyền (gồm ERR-05-011 vi phạm bốn mắt, ERR-05-040 ghi đối tượng COMMON); `404` Không tìm thấy hoặc thuộc tenant khác (không phân biệt); `409` Trạng thái không cho phép; mã cụ thể trong `code` (ERR-05-002, 009, 010, 017, 018, 026, 036); `412` ETag không khớp; kèm `currentEtag`.

**Ghi chú.** Không.
:::

#### API-05-058 · Tạm dừng bộ điều hợp

::: dac-ta
**Mục đích.** Tạm dừng bộ điều hợp.

**Phương thức, đường dẫn.** `POST /adapters/{adapterCode}:suspend`.

**Quyền.** `PERM-05-operate`.

**FR hiện thực.** FR-05-044.

**Tham số.** `adapterCode` (path, AdapterCode, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `StateChangeRequest`; trường bắt buộc: `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `AdapterDetail`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ; kèm `errors` theo trường (gồm ERR-05-038 thiếu lý do); `401` Thiếu token hoặc token hết hạn; `403` Không đủ quyền (gồm ERR-05-011 vi phạm bốn mắt, ERR-05-040 ghi đối tượng COMMON); `404` Không tìm thấy hoặc thuộc tenant khác (không phân biệt); `409` Trạng thái không cho phép; mã cụ thể trong `code` (ERR-05-002, 009, 010, 017, 018, 026, 036); `412` ETag không khớp; kèm `currentEtag`.

**Ghi chú.** Phát EVT-05-08.
:::

#### API-05-059 · Tiếp tục bộ điều hợp

::: dac-ta
**Mục đích.** Tiếp tục bộ điều hợp.

**Phương thức, đường dẫn.** `POST /adapters/{adapterCode}:resume`.

**Quyền.** `PERM-05-operate`.

**FR hiện thực.** FR-05-044.

**Tham số.** `adapterCode` (path, AdapterCode, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `StateChangeRequest`; trường bắt buộc: `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `AdapterDetail`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ; kèm `errors` theo trường (gồm ERR-05-038 thiếu lý do); `401` Thiếu token hoặc token hết hạn; `403` Không đủ quyền (gồm ERR-05-011 vi phạm bốn mắt, ERR-05-040 ghi đối tượng COMMON); `404` Không tìm thấy hoặc thuộc tenant khác (không phân biệt); `409` Trạng thái không cho phép; mã cụ thể trong `code` (ERR-05-002, 009, 010, 017, 018, 026, 036); `412` ETag không khớp; kèm `currentEtag`.

**Ghi chú.** Không.
:::

#### API-05-060 · Ngừng dùng bộ điều hợp

::: dac-ta
**Mục đích.** Ngừng dùng bộ điều hợp.

**Phương thức, đường dẫn.** `POST /adapters/{adapterCode}:retire`.

**Quyền.** `PERM-05-adapter`.

**FR hiện thực.** FR-05-044.

**Tham số.** `adapterCode` (path, AdapterCode, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `StateChangeRequest`; trường bắt buộc: `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `AdapterDetail`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ; kèm `errors` theo trường (gồm ERR-05-038 thiếu lý do); `401` Thiếu token hoặc token hết hạn; `403` Không đủ quyền (gồm ERR-05-011 vi phạm bốn mắt, ERR-05-040 ghi đối tượng COMMON); `404` Không tìm thấy hoặc thuộc tenant khác (không phân biệt); `409` Trạng thái không cho phép; mã cụ thể trong `code` (ERR-05-002, 009, 010, 017, 018, 026, 036); `412` ETag không khớp; kèm `currentEtag`.

**Ghi chú.** Còn nơi dùng ERR-05-010. Kamelet sinh chuyển DEPRECATED.
:::

#### API-05-062 · Nơi đang dùng bộ điều hợp

::: dac-ta
**Mục đích.** Nơi đang dùng bộ điều hợp.

**Phương thức, đường dẫn.** `GET /adapters/{adapterCode}/usages`.

**Quyền.** `PERM-05-read`.

**FR hiện thực.** FR-05-013.

**Tham số.** `adapterCode` (path, AdapterCode, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `UsageList`; trường bắt buộc: `items`; tiêu đề `ETag`.

**Lỗi.** `401` Thiếu token hoặc token hết hạn; `404` Không tìm thấy hoặc thuộc tenant khác (không phân biệt).

**Ghi chú.** Không.
:::

#### API-05-063 · Chạy so sánh phiên bản trên lưu lượng thật

::: dac-ta
**Mục đích.** Chạy so sánh phiên bản trên lưu lượng thật.

**Phương thức, đường dẫn.** `POST /adapters/{adapterCode}/versions/{version}:compare`.

**Quyền.** `PERM-05-operate`.

**FR hiện thực.** FR-05-045.

**Tham số.** `adapterCode` (path, AdapterCode, bắt buộc); `version` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `CompareRequest`; trường bắt buộc: `baseVersion`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `Comparison`; trường bắt buộc: `id`, `status`; tiêu đề `Location`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ; kèm `errors` theo trường (gồm ERR-05-038 thiếu lý do); `401` Thiếu token hoặc token hết hạn; `403` Không đủ quyền (gồm ERR-05-011 vi phạm bốn mắt, ERR-05-040 ghi đối tượng COMMON); `404` Không tìm thấy hoặc thuộc tenant khác (không phân biệt); `409` Trạng thái không cho phép; mã cụ thể trong `code` (ERR-05-002, 009, 010, 017, 018, 026, 036); `412` ETag không khớp; kèm `currentEtag`.

**Ghi chú.** Chế độ bóng: sao chép lượt gọi thật của phiên bản hiệu lực sang phiên bản ứng viên với thao tác `sideEffect = NONE`; thao tác ghi bị loại (cờ `adapter.compare.enabled`).
:::

#### API-05-064 · Kết quả so sánh phiên bản

::: dac-ta
**Mục đích.** Kết quả so sánh phiên bản.

**Phương thức, đường dẫn.** `GET /adapters/{adapterCode}/comparisons/{comparisonId}`.

**Quyền.** `PERM-05-read`.

**FR hiện thực.** FR-05-045.

**Tham số.** `adapterCode` (path, AdapterCode, bắt buộc); `comparisonId` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Comparison`; trường bắt buộc: `id`, `status`; tiêu đề `ETag`.

**Lỗi.** `401` Thiếu token hoặc token hết hạn; `404` Không tìm thấy hoặc thuộc tenant khác (không phân biệt).

**Ghi chú.** Không.
:::

#### API-05-065 · Sinh bộ điều hợp nháp từ OpenAPI hoặc WSDL

::: dac-ta
**Mục đích.** Sinh bộ điều hợp nháp từ OpenAPI hoặc WSDL.

**Phương thức, đường dẫn.** `POST /adapter-drafts:from-spec`.

**Quyền.** `PERM-05-adapter`.

**FR hiện thực.** FR-05-046.

**Tham số.** `If-Match` (header, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `FromSpecRequest`; trường bắt buộc: `adapterCode`, `name`, `systemCode`, `systemGroup`, `connectionCode`, `specKind`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `AdapterDetail`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ; kèm `errors` theo trường (gồm ERR-05-038 thiếu lý do); `401` Thiếu token hoặc token hết hạn; `403` Không đủ quyền (gồm ERR-05-011 vi phạm bốn mắt, ERR-05-040 ghi đối tượng COMMON); `409` Trạng thái không cho phép; mã cụ thể trong `code` (ERR-05-002, 009, 010, 017, 018, 026, 036); `412` ETag không khớp; kèm `currentEtag`; `413` Dữ liệu mẫu vượt 1 MiB hoặc tệp nhập quá lớn (ERR-05-024); `422` Lỗi nghiệp vụ dạng dữ liệu; mã cụ thể trong `code` (ERR-05-004…006, 013…016, 020…023, 025, 027, 030, 033, 034, 037, 039).

**Ghi chú.** Nhận `specUrl` (tải qua egress của tenant) hoặc multipart `file`. Không phân tích được ERR-05-023; tệp vượt 5 MiB (OpenAPI) hoặc 10 MiB (WSDL ZIP) ERR-05-024 với 413.
:::

#### API-05-066 · Lịch sử thay đổi bộ điều hợp

::: dac-ta
**Mục đích.** Lịch sử thay đổi bộ điều hợp.

**Phương thức, đường dẫn.** `GET /adapters/{adapterCode}/history`.

**Quyền.** `PERM-05-read`.

**FR hiện thực.** FR-05-016.

**Tham số.** `adapterCode` (path, AdapterCode, bắt buộc); `cursor` (query, string, tùy chọn); `limit` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `HistoryPage`; trường bắt buộc: `items`, `page`; tiêu đề `ETag`.

**Lỗi.** `401` Thiếu token hoặc token hết hạn; `404` Không tìm thấy hoặc thuộc tenant khác (không phân biệt); `503` Phụ thuộc chưa sẵn sàng (gồm ERR-05-028 OpenBao).

**Ghi chú.** Không.
:::

### CDC

#### API-05-067 · Cấu hình và trạng thái CDC

::: dac-ta
**Mục đích.** Cấu hình và trạng thái CDC.

**Phương thức, đường dẫn.** `GET /adapters/{adapterCode}/cdc`.

**Quyền.** `PERM-05-read`.

**FR hiện thực.** FR-05-052.

**Tham số.** `adapterCode` (path, AdapterCode, bắt buộc); `env` (query, Environment, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `CdcConfig`; tiêu đề `ETag`.

**Lỗi.** `401` Thiếu token hoặc token hết hạn; `404` Không tìm thấy hoặc thuộc tenant khác (không phân biệt).

**Ghi chú.** Không.
:::

#### API-05-068 · Khai báo cấu hình CDC

::: dac-ta
**Mục đích.** Khai báo cấu hình CDC.

**Phương thức, đường dẫn.** `PUT /adapters/{adapterCode}/cdc`.

**Quyền.** `PERM-05-adapter`.

**FR hiện thực.** FR-05-048.

**Tham số.** `adapterCode` (path, AdapterCode, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `CdcConfigUpdate`; trường bắt buộc: `env`, `engine`, `tables`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `CdcConfig`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ; kèm `errors` theo trường (gồm ERR-05-038 thiếu lý do); `401` Thiếu token hoặc token hết hạn; `403` Không đủ quyền (gồm ERR-05-011 vi phạm bốn mắt, ERR-05-040 ghi đối tượng COMMON); `404` Không tìm thấy hoặc thuộc tenant khác (không phân biệt); `409` Trạng thái không cho phép; mã cụ thể trong `code` (ERR-05-002, 009, 010, 017, 018, 026, 036); `412` ETag không khớp; kèm `currentEtag`; `422` Lỗi nghiệp vụ dạng dữ liệu; mã cụ thể trong `code` (ERR-05-004…006, 013…016, 020…023, 025, 027, 030, 033, 034, 037, 039); `503` Phụ thuộc chưa sẵn sàng (gồm ERR-05-028 OpenBao).

**Ghi chú.** Bảng ngoài `allowedSchemas` ERR-05-027; vượt `05.cdc.max-tables` ERR-05-030; PH-10 không khả dụng ERR-05-029. Chỉ sửa khi STOPPED.
:::

#### API-05-069 · Kiểm tra điều kiện CDC ở CSDL nguồn

::: dac-ta
**Mục đích.** Kiểm tra điều kiện CDC ở CSDL nguồn.

**Phương thức, đường dẫn.** `POST /adapters/{adapterCode}/cdc:check-prerequisites`.

**Quyền.** `PERM-05-test`.

**FR hiện thực.** FR-05-049.

**Tham số.** `adapterCode` (path, AdapterCode, bắt buộc); `env` (query, Environment, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ConnectionTest`; trường bắt buộc: `id`, `env`, `status`.

**Lỗi.** `401` Thiếu token hoặc token hết hạn; `403` Không đủ quyền (gồm ERR-05-011 vi phạm bốn mắt, ERR-05-040 ghi đối tượng COMMON); `404` Không tìm thấy hoặc thuộc tenant khác (không phân biệt); `503` Phụ thuộc chưa sẵn sàng (gồm ERR-05-028 OpenBao).

**Ghi chú.** Kết quả kiểm từng mục theo engine (FR-05-049).
:::

#### API-05-070 · Chạy CDC

::: dac-ta
**Mục đích.** Chạy CDC.

**Phương thức, đường dẫn.** `POST /adapters/{adapterCode}/cdc:start`.

**Quyền.** `PERM-05-operate`.

**FR hiện thực.** FR-05-050.

**Tham số.** `adapterCode` (path, AdapterCode, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `CdcAction`; trường bắt buộc: `env`, `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `CdcConfig`; tiêu đề `Location`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ; kèm `errors` theo trường (gồm ERR-05-038 thiếu lý do); `401` Thiếu token hoặc token hết hạn; `403` Không đủ quyền (gồm ERR-05-011 vi phạm bốn mắt, ERR-05-040 ghi đối tượng COMMON); `404` Không tìm thấy hoặc thuộc tenant khác (không phân biệt); `409` Trạng thái không cho phép; mã cụ thể trong `code` (ERR-05-002, 009, 010, 017, 018, 026, 036); `412` ETag không khớp; kèm `currentEtag`; `422` Lỗi nghiệp vụ dạng dữ liệu; mã cụ thể trong `code` (ERR-05-004…006, 013…016, 020…023, 025, 027, 030, 033, 034, 037, 039).

**Ghi chú.** Điều kiện chưa đạt 24 giờ ERR-05-025; chưa có phiên bản APPROVED ERR-05-008.
:::

#### API-05-071 · Tạm dừng CDC

::: dac-ta
**Mục đích.** Tạm dừng CDC.

**Phương thức, đường dẫn.** `POST /adapters/{adapterCode}/cdc:pause`.

**Quyền.** `PERM-05-operate`.

**FR hiện thực.** FR-05-050.

**Tham số.** `adapterCode` (path, AdapterCode, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `CdcAction`; trường bắt buộc: `env`, `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `CdcConfig`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ; kèm `errors` theo trường (gồm ERR-05-038 thiếu lý do); `401` Thiếu token hoặc token hết hạn; `403` Không đủ quyền (gồm ERR-05-011 vi phạm bốn mắt, ERR-05-040 ghi đối tượng COMMON); `404` Không tìm thấy hoặc thuộc tenant khác (không phân biệt); `409` Trạng thái không cho phép; mã cụ thể trong `code` (ERR-05-002, 009, 010, 017, 018, 026, 036); `412` ETag không khớp; kèm `currentEtag`.

**Ghi chú.** Không.
:::

#### API-05-072 · Tiếp tục CDC

::: dac-ta
**Mục đích.** Tiếp tục CDC.

**Phương thức, đường dẫn.** `POST /adapters/{adapterCode}/cdc:resume`.

**Quyền.** `PERM-05-operate`.

**FR hiện thực.** FR-05-050, FR-05-051.

**Tham số.** `adapterCode` (path, AdapterCode, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `CdcAction`; trường bắt buộc: `env`, `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `CdcConfig`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ; kèm `errors` theo trường (gồm ERR-05-038 thiếu lý do); `401` Thiếu token hoặc token hết hạn; `403` Không đủ quyền (gồm ERR-05-011 vi phạm bốn mắt, ERR-05-040 ghi đối tượng COMMON); `404` Không tìm thấy hoặc thuộc tenant khác (không phân biệt); `409` Trạng thái không cho phép; mã cụ thể trong `code` (ERR-05-002, 009, 010, 017, 018, 026, 036); `412` ETag không khớp; kèm `currentEtag`.

**Ghi chú.** Từ PAUSED_SCHEMA còn thay đổi chưa xử lý ERR-05-026.
:::

#### API-05-073 · Chụp ảnh lại dữ liệu nguồn

::: dac-ta
**Mục đích.** Chụp ảnh lại dữ liệu nguồn.

**Phương thức, đường dẫn.** `POST /adapters/{adapterCode}/cdc:resnapshot`.

**Quyền.** `PERM-05-operate`.

**FR hiện thực.** FR-05-053.

**Tham số.** `adapterCode` (path, AdapterCode, bắt buộc); `If-Match` (header, string, bắt buộc); `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `CdcAction`; trường bắt buộc: `env`, `reason`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `CdcConfig`; tiêu đề `Location`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ; kèm `errors` theo trường (gồm ERR-05-038 thiếu lý do); `401` Thiếu token hoặc token hết hạn; `403` Không đủ quyền (gồm ERR-05-011 vi phạm bốn mắt, ERR-05-040 ghi đối tượng COMMON); `404` Không tìm thấy hoặc thuộc tenant khác (không phân biệt); `409` Trạng thái không cho phép; mã cụ thể trong `code` (ERR-05-002, 009, 010, 017, 018, 026, 036); `412` ETag không khớp; kèm `currentEtag`.

**Ghi chú.** Từ FAILED hoặc theo yêu cầu; bảng đích nhận lại toàn bộ dữ liệu (phía tiêu thụ phải lũy đẳng theo khóa).
:::

#### API-05-074 · Thay đổi lược đồ chờ xử lý

::: dac-ta
**Mục đích.** Thay đổi lược đồ chờ xử lý.

**Phương thức, đường dẫn.** `GET /cdc/schema-changes`.

**Quyền.** `PERM-05-read`.

**FR hiện thực.** FR-05-051.

**Tham số.** `adapterCode` (query, AdapterCode, tùy chọn); `status` (query, array, tùy chọn); `severity` (query, array, tùy chọn); `cursor` (query, string, tùy chọn); `limit` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `SchemaChangePage`; trường bắt buộc: `items`, `page`; tiêu đề `ETag`.

**Lỗi.** `401` Thiếu token hoặc token hết hạn.

**Ghi chú.** Không.
:::

#### API-05-075 · Xử lý một thay đổi lược đồ

::: dac-ta
**Mục đích.** Xử lý một thay đổi lược đồ.

**Phương thức, đường dẫn.** `POST /cdc/schema-changes/{changeId}:resolve`.

**Quyền.** `PERM-05-adapter`.

**FR hiện thực.** FR-05-051.

**Tham số.** `changeId` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `SchemaResolve`; trường bắt buộc: `resolution`, `comment`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `SchemaChange`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ; kèm `errors` theo trường (gồm ERR-05-038 thiếu lý do); `401` Thiếu token hoặc token hết hạn; `403` Không đủ quyền (gồm ERR-05-011 vi phạm bốn mắt, ERR-05-040 ghi đối tượng COMMON); `404` Không tìm thấy hoặc thuộc tenant khác (không phân biệt); `409` Trạng thái không cho phép; mã cụ thể trong `code` (ERR-05-002, 009, 010, 017, 018, 026, 036); `412` ETag không khớp; kèm `currentEtag`; `422` Lỗi nghiệp vụ dạng dữ liệu; mã cụ thể trong `code` (ERR-05-004…006, 013…016, 020…023, 025, 027, 030, 033, 034, 037, 039).

**Ghi chú.** MAP_COLUMN cần `columnMap`; RESNAPSHOT xếp lịch chụp ảnh lại.
:::

### Kamelet

#### API-05-076 · Danh mục Kamelet

::: dac-ta
**Mục đích.** Danh mục Kamelet.

**Phương thức, đường dẫn.** `GET /kamelets`.

**Quyền.** `PERM-05-read`.

**FR hiện thực.** FR-05-054.

**Tham số.** `q` (query, string, tùy chọn); `scope` (query, array, tùy chọn); `type` (query, array, tùy chọn); `status` (query, array, tùy chọn); `group` (query, string, tùy chọn); `generated` (query, boolean, tùy chọn); `cursor` (query, string, tùy chọn); `limit` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `KameletPage`; trường bắt buộc: `items`, `page`; tiêu đề `ETag`.

**Lỗi.** `401` Thiếu token hoặc token hết hạn.

**Ghi chú.** Không.
:::

#### API-05-077 · Chi tiết Kamelet

::: dac-ta
**Mục đích.** Chi tiết Kamelet.

**Phương thức, đường dẫn.** `GET /kamelets/{kameletName}`.

**Quyền.** `PERM-05-read`.

**FR hiện thực.** FR-05-055.

**Tham số.** `kameletName` (path, KameletName, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `KameletDetail`; tiêu đề `ETag`.

**Lỗi.** `401` Thiếu token hoặc token hết hạn; `404` Không tìm thấy hoặc thuộc tenant khác (không phân biệt).

**Ghi chú.** Không.
:::

#### API-05-078 · Định nghĩa YAML một phiên bản

::: dac-ta
**Mục đích.** Định nghĩa YAML một phiên bản.

**Phương thức, đường dẫn.** `GET /kamelets/{kameletName}/versions/{version}`.

**Quyền.** `PERM-05-read`.

**FR hiện thực.** FR-05-055.

**Tham số.** `kameletName` (path, KameletName, bắt buộc); `version` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `KameletVersion`; tiêu đề `ETag`.

**Lỗi.** `401` Thiếu token hoặc token hết hạn; `404` Không tìm thấy hoặc thuộc tenant khác (không phân biệt).

**Ghi chú.** Với `Accept: application/yaml` trả YAML thô (runtime tải theo băm).
:::

#### API-05-079 · Tạo bản nháp Kamelet hoặc phiên bản mới

::: dac-ta
**Mục đích.** Tạo bản nháp Kamelet hoặc phiên bản mới.

**Phương thức, đường dẫn.** `POST /kamelets`.

**Quyền.** `PERM-05-kamelet-submit`.

**FR hiện thực.** FR-05-056.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `KameletCreate`; trường bắt buộc: `name`, `version`, `yaml`, `runtimeProfiles`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `KameletVersion`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ; kèm `errors` theo trường (gồm ERR-05-038 thiếu lý do); `401` Thiếu token hoặc token hết hạn; `403` Không đủ quyền (gồm ERR-05-011 vi phạm bốn mắt, ERR-05-040 ghi đối tượng COMMON); `409` Trạng thái không cho phép; mã cụ thể trong `code` (ERR-05-002, 009, 010, 017, 018, 026, 036); `422` Lỗi nghiệp vụ dạng dữ liệu; mã cụ thể trong `code` (ERR-05-004…006, 013…016, 020…023, 025, 027, 030, 033, 034, 037, 039).

**Ghi chú.** Tên trùng trên BASE ∪ COMMON ∪ TENANT ERR-05-002; tiền tố `dh-` dành riêng ERR-05-003; tỉnh tạo ở phạm vi COMMON ERR-05-040. Chạy kiểm tra tĩnh ngay, lưu kết quả.
:::

#### API-05-080 · Sửa bản nháp Kamelet

::: dac-ta
**Mục đích.** Sửa bản nháp Kamelet.

**Phương thức, đường dẫn.** `PUT /kamelets/{kameletName}/versions/{version}`.

**Quyền.** `PERM-05-kamelet-submit`.

**FR hiện thực.** FR-05-056.

**Tham số.** `kameletName` (path, KameletName, bắt buộc); `version` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `KameletDraftUpdate`; trường bắt buộc: `yaml`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `KameletVersion`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ; kèm `errors` theo trường (gồm ERR-05-038 thiếu lý do); `401` Thiếu token hoặc token hết hạn; `403` Không đủ quyền (gồm ERR-05-011 vi phạm bốn mắt, ERR-05-040 ghi đối tượng COMMON); `404` Không tìm thấy hoặc thuộc tenant khác (không phân biệt); `409` Trạng thái không cho phép; mã cụ thể trong `code` (ERR-05-002, 009, 010, 017, 018, 026, 036); `412` ETag không khớp; kèm `currentEtag`; `422` Lỗi nghiệp vụ dạng dữ liệu; mã cụ thể trong `code` (ERR-05-004…006, 013…016, 020…023, 025, 027, 030, 033, 034, 037, 039).

**Ghi chú.** Chỉ ở DRAFT.
:::

#### API-05-081 · Kiểm tra tĩnh Kamelet

::: dac-ta
**Mục đích.** Kiểm tra tĩnh Kamelet.

**Phương thức, đường dẫn.** `POST /kamelets/{kameletName}/versions/{version}:validate`.

**Quyền.** `PERM-05-kamelet-submit`.

**FR hiện thực.** FR-05-056.

**Tham số.** `kameletName` (path, KameletName, bắt buộc); `version` (path, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `StaticCheckResult`; trường bắt buộc: `passed`, `findings`.

**Lỗi.** `401` Thiếu token hoặc token hết hạn; `403` Không đủ quyền (gồm ERR-05-011 vi phạm bốn mắt, ERR-05-040 ghi đối tượng COMMON); `404` Không tìm thấy hoặc thuộc tenant khác (không phân biệt).

**Ghi chú.** Chạy KR-01…14 (SDD §4.9); không đổi trạng thái.
:::

#### API-05-082 · Gửi duyệt Kamelet

::: dac-ta
**Mục đích.** Gửi duyệt Kamelet.

**Phương thức, đường dẫn.** `POST /kamelets/{kameletName}/versions/{version}:submit`.

**Quyền.** `PERM-05-kamelet-submit`.

**FR hiện thực.** FR-05-056.

**Tham số.** `kameletName` (path, KameletName, bắt buộc); `version` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `KameletVersion`.

**Lỗi.** `401` Thiếu token hoặc token hết hạn; `403` Không đủ quyền (gồm ERR-05-011 vi phạm bốn mắt, ERR-05-040 ghi đối tượng COMMON); `404` Không tìm thấy hoặc thuộc tenant khác (không phân biệt); `409` Trạng thái không cho phép; mã cụ thể trong `code` (ERR-05-002, 009, 010, 017, 018, 026, 036); `412` ETag không khớp; kèm `currentEtag`; `422` Lỗi nghiệp vụ dạng dữ liệu; mã cụ thể trong `code` (ERR-05-004…006, 013…016, 020…023, 025, 027, 030, 033, 034, 037, 039).

**Ghi chú.** Kiểm tra tĩnh còn lỗi ERR-05-020…022.
:::

#### API-05-083 · Duyệt Kamelet

::: dac-ta
**Mục đích.** Duyệt Kamelet.

**Phương thức, đường dẫn.** `POST /kamelets/{kameletName}/versions/{version}:approve`.

**Quyền.** `PERM-05-kamelet-approve`.

**FR hiện thực.** FR-05-057.

**Tham số.** `kameletName` (path, KameletName, bắt buộc); `version` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `KameletDecision`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `KameletVersion`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ; kèm `errors` theo trường (gồm ERR-05-038 thiếu lý do); `401` Thiếu token hoặc token hết hạn; `403` Không đủ quyền (gồm ERR-05-011 vi phạm bốn mắt, ERR-05-040 ghi đối tượng COMMON); `404` Không tìm thấy hoặc thuộc tenant khác (không phân biệt); `409` Trạng thái không cho phép; mã cụ thể trong `code` (ERR-05-002, 009, 010, 017, 018, 026, 036); `412` ETag không khớp; kèm `currentEtag`.

**Ghi chú.** TENANT: IA; COMMON: PA kèm ý kiến SO (`soOpinion` bắt buộc). Bốn mắt (ERR-05-011). Phát EVT-05-09.
:::

#### API-05-084 · Từ chối Kamelet

::: dac-ta
**Mục đích.** Từ chối Kamelet.

**Phương thức, đường dẫn.** `POST /kamelets/{kameletName}/versions/{version}:reject`.

**Quyền.** `PERM-05-kamelet-approve`.

**FR hiện thực.** FR-05-057.

**Tham số.** `kameletName` (path, KameletName, bắt buộc); `version` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `RejectRequest`; trường bắt buộc: `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `KameletVersion`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ; kèm `errors` theo trường (gồm ERR-05-038 thiếu lý do); `401` Thiếu token hoặc token hết hạn; `403` Không đủ quyền (gồm ERR-05-011 vi phạm bốn mắt, ERR-05-040 ghi đối tượng COMMON); `404` Không tìm thấy hoặc thuộc tenant khác (không phân biệt); `409` Trạng thái không cho phép; mã cụ thể trong `code` (ERR-05-002, 009, 010, 017, 018, 026, 036); `412` ETag không khớp; kèm `currentEtag`.

**Ghi chú.** Không.
:::

#### API-05-085 · Đánh dấu ngừng khuyến nghị

::: dac-ta
**Mục đích.** Đánh dấu ngừng khuyến nghị.

**Phương thức, đường dẫn.** `POST /kamelets/{kameletName}/versions/{version}:deprecate`.

**Quyền.** `PERM-05-kamelet-approve`.

**FR hiện thực.** FR-05-058.

**Tham số.** `kameletName` (path, KameletName, bắt buộc); `version` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `StateChangeRequest`; trường bắt buộc: `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `KameletVersion`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ; kèm `errors` theo trường (gồm ERR-05-038 thiếu lý do); `401` Thiếu token hoặc token hết hạn; `403` Không đủ quyền (gồm ERR-05-011 vi phạm bốn mắt, ERR-05-040 ghi đối tượng COMMON); `404` Không tìm thấy hoặc thuộc tenant khác (không phân biệt); `409` Trạng thái không cho phép; mã cụ thể trong `code` (ERR-05-002, 009, 010, 017, 018, 026, 036); `412` ETag không khớp; kèm `currentEtag`.

**Ghi chú.** Phát EVT-05-10.
:::

#### API-05-086 · Thu hồi phiên bản Kamelet

::: dac-ta
**Mục đích.** Thu hồi phiên bản Kamelet.

**Phương thức, đường dẫn.** `POST /kamelets/{kameletName}/versions/{version}:withdraw`.

**Quyền.** `PERM-05-kamelet-approve`.

**FR hiện thực.** FR-05-058.

**Tham số.** `kameletName` (path, KameletName, bắt buộc); `version` (path, string, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `StateChangeRequest`; trường bắt buộc: `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `KameletVersion`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ; kèm `errors` theo trường (gồm ERR-05-038 thiếu lý do); `401` Thiếu token hoặc token hết hạn; `403` Không đủ quyền (gồm ERR-05-011 vi phạm bốn mắt, ERR-05-040 ghi đối tượng COMMON); `404` Không tìm thấy hoặc thuộc tenant khác (không phân biệt); `409` Trạng thái không cho phép; mã cụ thể trong `code` (ERR-05-002, 009, 010, 017, 018, 026, 036); `412` ETag không khớp; kèm `currentEtag`.

**Ghi chú.** Chặn ở lần phát hành luồng kế tiếp; cảnh báo cao cho mọi luồng đang dùng (BR-05-027).
:::

#### API-05-087 · Nơi đang dùng Kamelet

::: dac-ta
**Mục đích.** Nơi đang dùng Kamelet.

**Phương thức, đường dẫn.** `GET /kamelets/{kameletName}/usages`.

**Quyền.** `PERM-05-read`.

**FR hiện thực.** FR-05-055, FR-05-058.

**Tham số.** `kameletName` (path, KameletName, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `UsageList`; trường bắt buộc: `items`; tiêu đề `ETag`.

**Lỗi.** `401` Thiếu token hoặc token hết hạn; `404` Không tìm thấy hoặc thuộc tenant khác (không phân biệt).

**Ghi chú.** Không.
:::

#### API-05-088 · Đề xuất Kamelet tỉnh thành dùng chung

::: dac-ta
**Mục đích.** Đề xuất Kamelet tỉnh thành dùng chung.

**Phương thức, đường dẫn.** `POST /kamelets/{kameletName}:propose-common`.

**Quyền.** `PERM-05-kamelet-submit`.

**FR hiện thực.** FR-05-060.

**Tham số.** `kameletName` (path, KameletName, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ProposeCommon`; trường bắt buộc: `justification`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `KameletVersion`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ; kèm `errors` theo trường (gồm ERR-05-038 thiếu lý do); `401` Thiếu token hoặc token hết hạn; `403` Không đủ quyền (gồm ERR-05-011 vi phạm bốn mắt, ERR-05-040 ghi đối tượng COMMON); `404` Không tìm thấy hoặc thuộc tenant khác (không phân biệt); `409` Trạng thái không cho phép; mã cụ thể trong `code` (ERR-05-002, 009, 010, 017, 018, 026, 036); `412` ETag không khớp; kèm `currentEtag`.

**Ghi chú.** Chỉ Kamelet TENANT đã APPROVED; tạo bản sao ở COMMON trạng thái SUBMITTED cho PA (cờ `adapter.kamelet.common-proposal`).
:::

### Tham số và báo cáo

#### API-05-090 · Tham số phân hệ của tenant

::: dac-ta
**Mục đích.** Tham số phân hệ của tenant.

**Phương thức, đường dẫn.** `GET /settings`.

**Quyền.** `PERM-05-read`.

**FR hiện thực.** FR-05-061.

**Tham số.** Không.

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Settings`; trường bắt buộc: `params`, `connectionTypes`; tiêu đề `ETag`.

**Lỗi.** `401` Thiếu token hoặc token hết hạn.

**Ghi chú.** Chỉ đọc; sửa tham số qua PH-18.
:::

#### API-05-091 · Bật, tắt loại kết nối và trần tham số

::: dac-ta
**Mục đích.** Bật, tắt loại kết nối và trần tham số.

**Phương thức, đường dẫn.** `PUT /settings/connection-types/{typeCode}`.

**Quyền.** `PERM-05-admin`.

**FR hiện thực.** FR-05-061.

**Tham số.** `typeCode` (path, TypeCode, bắt buộc); `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ConnectionTypeSetting`; trường bắt buộc: `enabled`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ConnectionType`; trường bắt buộc: `typeCode`, `title`, `group`, `secretKeys`.

**Lỗi.** `400` Dữ liệu không hợp lệ theo lược đồ; kèm `errors` theo trường (gồm ERR-05-038 thiếu lý do); `401` Thiếu token hoặc token hết hạn; `403` Không đủ quyền (gồm ERR-05-011 vi phạm bốn mắt, ERR-05-040 ghi đối tượng COMMON); `404` Không tìm thấy hoặc thuộc tenant khác (không phân biệt); `409` Trạng thái không cho phép; mã cụ thể trong `code` (ERR-05-002, 009, 010, 017, 018, 026, 036); `412` ETag không khớp; kèm `currentEtag`; `422` Lỗi nghiệp vụ dạng dữ liệu; mã cụ thể trong `code` (ERR-05-004…006, 013…016, 020…023, 025, 027, 030, 033, 034, 037, 039).

**Ghi chú.** Tắt loại còn kết nối ACTIVE ERR-05-010 trừ khi `blockNew`; trần chỉ thu hẹp (ERR-05-030).
:::

#### API-05-092 · Báo cáo sử dụng kết nối và bộ điều hợp

::: dac-ta
**Mục đích.** Báo cáo sử dụng kết nối và bộ điều hợp.

**Phương thức, đường dẫn.** `GET /reports/usage`.

**Quyền.** `PERM-05-read`.

**FR hiện thực.** FR-05-062.

**Tham số.** `month` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `UsageReport`; trường bắt buộc: `month`; tiêu đề `ETag`.

**Lỗi.** `401` Thiếu token hoặc token hết hạn.

**Ghi chú.** `Accept: text/csv` hoặc XLSX để xuất.
:::

<!-- gen:dac-ta-api:end -->

## Lịch sử phiên bản

| Phiên bản | Ngày | Nội dung | Người thực hiện |
|---|---|---|---|
| 0.1 | 26/11/2026 | Bản đầu theo khuôn K-API; OpenAPI, AsyncAPI sinh từ bảng mã, đã kiểm | Nhóm viết tài liệu (Claude) |
| 0.2 | 26/11/2026 | Nhóm viết tài liệu (Claude) | Áp quy chuẩn trình bày K-TRINH-BAY: chương Giới thiệu, chương 10 đặc tả từng endpoint (92 bảng 10 mục sinh từ OpenAPI bằng build/tools/sinh_dac_ta_api.py), chú thích mọi bảng |
| 0.3 | 27/11/2026 | Đồng bộ chéo cuối: sinh lại cột Quyền, mẫu type ERR-05-nnn, người nhận EVT-05-08 | Áp quy chuẩn trình bày K-TRINH-BAY: chương Giới thiệu, chương 10 đặc tả từng endpoint (92 bảng 10 mục sinh từ OpenAPI bằng build/tools/sinh_dac_ta_api.py), chú thích mọi bảng; chốt câu hỏi mở đợt đồng bộ: Q383 |
