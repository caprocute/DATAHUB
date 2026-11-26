---
ma_tai_lieu: D00-04-K-GOI
ten: Khuôn gói đặc tả máy đọc cho một phân hệ
phien_ban: 0.1
ngay: 2026-11-26
trang_thai: Dự thảo
nguoi_doc: Người chuyển tài liệu phân hệ thành đặc tả cho tác nhân viết mã; người dựng harness
---

# K-GOI-DAC-TA · Khuôn gói đặc tả máy đọc cho một phân hệ

## 1. Mục đích

Bộ bảy tập tài liệu một phân hệ (FRS, UC, SDD, CSDL, API, màn hình, TC) dài 1–2 MB, viết cho hội đồng thẩm định. Tác nhân viết mã không đọc hết được và nếu đọc hết thì làm kém đi. Gói đặc tả máy đọc là lớp **sinh từ** bộ tài liệu, không thay nó, gồm: hợp đồng đã lint, DDL đã chạy thật, danh sách tính năng có cờ `passes`, Gherkin chạy được, tóm tắt ≤ 300 dòng và chỉ dẫn ngắn cho tác nhân. Mẫu đầu tiên: `datahub/spec/PH07/` (lát cắt F-07-010, 26/11/2026).

Gói tuân theo mức *spec-anchored*: tài liệu nguồn vẫn là nguồn sự thật; gói chỉ được thắng nguồn ở các quyết định sẵn sàng `SS-nn-nn` có ghi lý do, và các quyết định này được chép về nguồn ở đợt đồng bộ cuối.

## 2. Cấu trúc thư mục [BB]

```text
datahub/spec/PHnn/
├── goi.yaml                # bản kê: nguồn, vá, lát cắt, kiểm DDL (§3)
├── AGENTS.md               # ≤ 150 dòng: chỉ điều khác thường của phân hệ
├── tom-tat.md              # ≤ 300 dòng: vị trí, khái niệm, tenant, quy ước API, quyền, lỗi, sự kiện, BR chính, bản đồ tính năng
├── san-sang.md             # kết quả kiểm bằng máy + bảng quyết định SS-nn-nn + câu hỏi mở
├── va-openapi.yaml         # vá hợp đồng chờ đồng bộ (set/remove/add theo con trỏ JSON)
├── features.json           # sinh: một FR một tính năng, cờ passes
├── lat-cat/F-nn-nnn.openapi.yaml   # sinh: lát cắt tự chứa của một tính năng
├── gherkin/F-nn-nnn.feature        # tiêu chí nghiệm thu chạy được (# language: vi)
├── ddl-kiem/NN-*.sql       # kiểm DDL và RLS trên PostgreSQL thật
├── tien-do.md              # nhật ký phiên viết mã (tác nhân ghi)
└── hang-cho.md             # câu hỏi cho người khi đặc tả sai hoặc thiếu (tác nhân ghi)
```

Gốc `datahub/AGENTS.md` (hiến chương chung ≤ 150 dòng) và công cụ `datahub/tools/` dùng chung mọi phân hệ.

## 3. Bản kê `goi.yaml` [BB]

| Khóa | Nội dung | Ví dụ PH-07 |
|---|---|---|
| `phan_he`, `ten`, `du`, `module`, `package`, `schema` | Định danh | `PH-07`, `dh-data`, `rdm`, `vn.datahub.data.rdm`, `ph07_rdm` |
| `nguon.*` | Đường dẫn tập nguồn: `frs`, `sdd`, `api_md`, `openapi`, `asyncapi`, `ddl`, `seed[]`, `man_hinh`, `hifi`, `tc` | xem `datahub/spec/PH07/goi.yaml` |
| `openapi.va`, `openapi.sua_trung_khoa` | Tệp vá; có bỏ qua khóa trùng của nguồn không | `true` khi nguồn còn lỗi SS-07-02 |
| `postgres_image` | Ảnh PostgreSQL đích | `postgres:18` |
| `ddl_kiem[]` | Tệp SQL kiểm chạy sau DDL + seed | `10-rls-catalog-group.sql` |
| `lat_cat.F-nn-nnn` | `operations[]`, `openapi`, `gherkin` | 4 operation của F-07-010 |

## 4. Cách dựng một gói (thứ tự) [BB]

1. **Sinh `features.json`**: `python3 datahub/tools/sinh_features.py --ph nn --frs … --openapi … --ddl … --tc … --ra datahub/spec/PHnn/features.json`. Kiểm số tính năng thiếu API, thiếu TC mà công cụ in ra; tính năng thiếu TC là lỗ hổng phải ghi vào `san-sang.md`.
2. **Chạy lint toàn hợp đồng** (cổng G1 bước 2). Mỗi lỗi: sửa bằng một mục vá có mã `SS-nn-nn`, không sửa nguồn trong luồng này.
3. **Chạy DDL + seed trên PostgreSQL thật** rồi viết `ddl-kiem/` cho bảng của các tính năng sắp làm: tenant thấy dòng của mình và `COMMON`, không sửa `COMMON`, không thấy tenant khác, không chèn giả tenant.
4. **Kiểm sẵn sàng** cho tính năng sắp làm: đặt cạnh nhau khối FR, operation trong OpenAPI, `CREATE TABLE`, TC, dòng D02-08; ghi mọi chỗ lệch vào bảng quyết định (cột: mã, mâu thuẫn, nguồn A, nguồn B, quyết định, áp ở). Quyết định chọn theo thứ tự ưu tiên: D02-08 cho quyền → DDL cho dữ liệu → FRS cho nghiệp vụ → TC cho hành vi quan sát được → OpenAPI. Không quyết được thì ghi câu hỏi mở và chọn phương án an toàn hơn.
5. **Cắt lát OpenAPI**: `python3 datahub/tools/cat_lat_openapi.py NGUON RA --va … [--sua-trung-khoa] opId…`. Lát cắt tự chứa, bỏ ví dụ của response dùng chung; không sửa tay.
6. **Viết Gherkin chạy được** từ TC của FR: mỗi TC một kịch bản, bước cụ thể (đường dẫn, thân JSON, mã phản hồi, mã lỗi, header, dòng kiểm toán), khối "Quy ước bước" ở đầu tệp định nghĩa nghĩa của từng mẫu bước. Thêm kịch bản `@bo-sung` cho an toàn bắt buộc của D04-01: rò rỉ chéo tenant (CC-TEST-03), thiếu quyền (CC-TEST-04), không token, ETag, Idempotency-Key.
7. **Viết `tom-tat.md` và `AGENTS.md`**: mỗi dòng phải trả lời được câu "bỏ dòng này tác nhân có làm sai không?". Không chép tổng quan; trỏ mục nguồn thay vì chép.
8. **Chạy G1** tới khi xanh rồi commit gói trước khi giao tác nhân viết mã.

## 5. Cổng chất lượng [BB]

| Cổng | Lệnh | Chặn khi |
|---|---|---|
| G1 Đặc tả | `python3 datahub/tools/g1_dac_ta.py datahub/spec/PHnn/goi.yaml` | Redocly lỗi (gồm luật riêng `dh-ma-api`, `dh-truy-vet-fr`), lát cắt cũ so với bản sinh lại, `features.json` sai lược đồ hoặc lệch FRS, Gherkin không phân tích được, DDL/seed/kiểm RLS lỗi, tóm tắt > 300 dòng |
| G2 Build, đơn vị | `mvn verify`; `npm run check` | Biên dịch, test đỏ, JaCoCo < 80% (backend), Vitest < 70% |
| G3 Kiến trúc | trong G2: Modulith `verify()`, ArchUnit D04-01 CC-MOD-05, ESLint ranh giới | Vi phạm ranh giới module, controller ngoài `internal.web`, endpoint thiếu quyền |
| G4 Hợp đồng, E2E | Cucumber trên ứng dụng thật + PostgreSQL thật; Playwright + axe | Kịch bản Gherkin đỏ; luồng giao diện đỏ; axe có vi phạm A/AA |
| G5 Bảo mật | `datahub/tools/g5_bao_mat.sh`, Trivy, gitleaks | Semgrep có phát hiện, lỗ hổng HIGH/CRITICAL |
| G6 Người | Duyệt PR | Mọi thay đổi `spec/`, test, hợp đồng, DDL, thư viện chung, cấu hình bảo mật |

CI: `.github/workflows/datahub-code.yml`, chạy khi đổi `datahub/**`.

## 6. Quy trình một tính năng (harness)

1. **Phiên khởi tạo** (một lần mỗi phân hệ, hoặc khi tính năng chưa có lát cắt): bước 4–8 của §4 cho tính năng đó.
2. **Phiên viết** (ngữ cảnh mới, một tính năng): đọc theo `datahub/AGENTS.md` §1; viết test trước, mã sau; chạy G1–G5 cục bộ; ghi `tien-do.md`; không lật `passes`, không sửa `spec/`.
3. **Phiên đánh giá** (ngữ cảnh mới, prompt nghi ngờ, không đọc báo cáo của phiên viết trước khi tự chạy): chạy lại mọi cổng từ đầu, đối chiếu từng kịch bản và từng dòng `san-sang.md` với mã, thử ít nhất ba ca phá hoại ngoài Gherkin (tenant khác, quyền thiếu, đầu vào biên), kiểm test có thật sự khẳng định điều cần khẳng định. Đạt thì lật `passes = true` và ghi `danh_gia` (ngày, người/phiên, cổng, phát hiện); trượt thì ghi lỗi vào `tien-do.md` và trả về phiên viết. Ba lần trượt cùng tính năng thì dừng, chuyển vào `hang-cho.md`.
4. **G6** người duyệt PR.

## 7. Tự soát trước khi giao gói

- [ ] G1 xanh trên PostgreSQL đúng phiên bản đích.
- [ ] Mỗi tính năng sắp làm có lát cắt, Gherkin, ít nhất một tệp `ddl-kiem`.
- [ ] Mọi mâu thuẫn đã thấy có dòng SS; không có quyết định ngầm trong Gherkin mà thiếu SS.
- [ ] `tom-tat.md` ≤ 300 dòng, `AGENTS.md` ≤ 150 dòng, không chép đoạn tổng quan.
- [ ] Gói đã commit trước khi tác nhân viết mã bắt đầu (để so khác nếu tác nhân sửa trộm).

## 8. Số đo lát cắt mẫu

Xem `datahub/spec/PH07/so-do-lat-cat.md` (chi phí token, thời gian, lỗi phát hiện ở từng cổng, bài học).
