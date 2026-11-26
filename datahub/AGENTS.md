# datahub/ · Hiến chương cho tác nhân viết mã

Cây `datahub/` là mã nguồn Datahub thế hệ mới (gói `vn.datahub`, Q350). Nó KHÔNG dùng
`apps/`, `libs/`, `docs/` của thiết kế LGSP cũ (gói `vn.lgsp`) và không sửa `datahub-docs/`.
Mỗi dòng dưới đây có vì thiếu nó thì tác nhân sẽ làm sai.

## 1. Đọc gì, theo thứ tự

1. Tệp này.
2. `spec/PHnn/AGENTS.md` và `spec/PHnn/tom-tat.md` của phân hệ đang làm.
3. `spec/PHnn/san-sang.md`: quyết định SS-nn-nn THẮNG mọi tài liệu khác.
4. Mục của tính năng trong `spec/PHnn/features.json`, rồi `lat_cat` (OpenAPI) và `gherkin`.
5. Mã mẫu đã có (lát cắt F-07-010) — bắt chước cấu trúc của nó trước khi nghĩ cách khác.
6. Chỉ khi thiếu chi tiết: mục được trỏ trong `datahub-docs/` (đường dẫn ở `goi.yaml`).
   Không đọc nguyên một tập tài liệu.

## 2. Cấm tuyệt đối

- Sửa tệp trong `spec/` (trừ cờ `passes` và `danh_gia` trong `features.json`, chỉ phiên
  đánh giá được lật). Hợp đồng sai thì ghi vào `spec/PHnn/hang-cho.md` và dừng tính năng.
- Sửa hoặc xóa test, kịch bản Gherkin, hoặc nới ngưỡng cổng để cho xanh.
- `@Disabled`, `@Ignore`, `.skip`, `test.fixme`, `|| true` trong lệnh kiểm.
- Bí mật, mật khẩu, khóa riêng thật trong mã (khóa thử sinh lúc chạy test).
- SQL ghép chuỗi; `nativeQuery` không lý do; vai trò CSDL có BYPASSRLS cho ứng dụng.
- Gọi `fetch`/`axios` trực tiếp trong thành phần React; màu, `px` viết cứng; `style={{}}`
  mang giá trị trình bày; token trong `localStorage`.

## 3. Stack chốt (đừng đổi phiên bản trong một tính năng)

| Tầng | Chốt |
|---|---|
| Java | 21, Spring Boot 4.0.10, Spring Modulith 2.0.10 (nâng bản vá khi Trivy báo, không hạ), Spring Security resource server (JWT RS256) |
| CSDL | PostgreSQL 18, JPA/Hibernate, schema theo phân hệ, RLS; DDL lấy NGUYÊN từ `datahub-docs/.../ddl` (không viết DDL riêng) |
| Test Java | JUnit 5, AssertJ, Testcontainers (`postgres:18`), Cucumber-JVM 7 (Gherkin `# language: vi`), ArchUnit, JaCoCo |
| Web | Node 22, npm workspaces, React 19, TypeScript 5 strict, Vite, antd 6, TanStack Query 5, React Router 7, openapi-typescript + openapi-fetch |
| Test web | Vitest + Testing Library + MSW; Playwright + `@axe-core/playwright` |

## 4. Bố cục

```text
datahub/
├── AGENTS.md                  # tệp này
├── spec/PHnn/                 # gói đặc tả máy đọc (K-GOI-DAC-TA), chỉ đọc với tác nhân viết
├── services/dh-data/          # DU dh-data: vn.datahub.data.{shared,rdm,...}
├── web/                       # npm workspaces
│   ├── packages/ui/           # @datahub/ui: theme antd từ token D03-05-02, thành phần dùng chung
│   ├── packages/api-client/   # @datahub/api-client: kiểu sinh từ lát cắt OpenAPI
│   ├── packages/i18n/         # @datahub/i18n: chuỗi vi-VN
│   └── apps/console/          # dh-console: features/{module}/{api,components,pages}
└── tools/                     # cổng G1…G5, công cụ gói đặc tả
```

Backend theo D04-01 §3.2: `vn.datahub.data.rdm.{api,events,internal}`; controller ở
`internal.web`; `shared.{security,web,persistence,audit}` là nhân của DU.

## 5. Quy tắc cốt lõi (mã D04-01 để tra khi cần)

| Mã | Quy tắc |
|---|---|
| CC-GEN-02 | Hợp đồng trước: endpoint, trường, mã lỗi đúng lát cắt OpenAPI, không thêm bớt |
| CC-GEN-03, CC-SEC-08 | Mọi endpoint kiểm quyền tường minh; mặc định từ chối |
| CC-TX-02 | Đầu mỗi giao dịch `set_config('app.tenant_id', tenant, true)`; tenant chỉ từ JWT |
| CC-TX-04 | Khóa lạc quan bằng cột `version`; ETag `W/"{version}"` |
| CC-TX-05/06 | `Idempotency-Key` cho lệnh tạo, lưu bảng `idempotency_key` của phân hệ |
| CC-ERR-01…04 | Một `@RestControllerAdvice`; ngoại lệ nghiệp vụ mang mã `ERR-nn-nnn`; không lộ stack trace |
| CC-JAVA-04/05 | DTO là `record`; không trả entity ra ngoài |
| CC-VAL-01/03 | Jakarta Validation ở biên; chuẩn hóa (NFC, chữ hoa mã) trước khi kiểm |
| CC-LOG-01/04 | Log JSON, không ghi token, dữ liệu nhạy cảm |
| CC-TEST-03/04 | Mỗi API có test rò rỉ chéo tenant và test thiếu quyền |
| CC-FE-05/07/08 | Gọi API qua client sinh; gửi `If-Match`, `Idempotency-Key`; lỗi hiển thị theo `code` |
| CC-FE-10/11 | Chuỗi qua i18n; WCAG 2.2 AA (axe 0 lỗi) |
| CC-FE-12/13/14 | Dùng `@datahub/ui`; chỉ token `--dh-*`; màn khóa chiều cao, cuộn trong khung |

Liquid Glass (ADR-020): glass chỉ cho lớp điều hướng và lớp nổi (thanh bên, đầu trang,
hộp thoại, ngăn kéo); vùng nội dung dày (bảng, cây, biểu mẫu) dùng nền đặc.

## 6. Lệnh

| Việc | Lệnh (chạy từ gốc repo) |
|---|---|
| G1 đặc tả | `python3 datahub/tools/g1_dac_ta.py datahub/spec/PH07/goi.yaml` (cần PG*) |
| G2+G3+G4 API | `mvn -B -f datahub/services/dh-data/pom.xml verify` (cần Docker) |
| G2 web | `npm --prefix datahub/web ci && npm --prefix datahub/web run check` |
| G4 E2E | `npm --prefix datahub/web run e2e` |
| G5 bảo mật | `datahub/tools/g5_bao_mat.sh` |
| Tất cả | `datahub/tools/cong.sh` |

## 7. Một phiên làm một tính năng

1. Đọc theo §1; chạy cổng một lần để biết trạng thái xuất phát.
2. Viết test trước (step definition cho Gherkin, test đơn vị cho quy tắc), thấy đỏ.
3. Viết mã tới khi xanh; chạy lại chỉ test đỏ khi sửa, cả bộ một lần cuối.
4. Commit nhỏ theo tầng. Ghi `spec/PHnn/tien-do.md`: đã làm gì, lệnh đã chạy, còn gì.
5. Không lật `passes`. Báo xong khi mọi cổng tự động xanh; phiên đánh giá quyết định.
