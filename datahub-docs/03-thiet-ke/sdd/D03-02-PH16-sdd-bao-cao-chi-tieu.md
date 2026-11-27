---
ma_tai_lieu: D03-02-PH16
ten: Thiết kế chi tiết phần mềm phân hệ PH-16 Báo cáo chỉ tiêu và sổ kiến trúc
phien_ban: 0.3
ngay: 2026-11-26
trang_thai: Dự thảo
nguoi_doc: Kỹ sư dh-platform, kiến trúc sư, ATTT, SRE, kiểm thử viên, hội đồng thẩm định
phan_he: PH-16
mo_ta: Thiết kế chi tiết hiện thực 58 FR của PH-16 gồm hai mô-đun Modulith kpi và arch trong dh-platform với 14 thành phần có khối đặc tả 10 mục, bộ tính chỉ tiêu bằng CEL, tiếp nhận quan sát idempotent, tổng hợp kỳ fail-soft có nhãn PARTIAL, báo cáo bất biến ký số lưu WORM, sổ kiến trúc tự đăng ký, gửi gói quốc gia qua PH-14, bảy sơ đồ trình tự, bảo mật, quan sát, hiệu năng và năm ADR đề xuất.
tai_lieu_lien_quan: D02-03-PH16 FRS; D03-03-PH16 CSDL; D03-04-PH16 API; D03-06-PH16 Màn hình; D03-09 Hạ tầng triển khai; D03-10 Thiết kế đa tenant; D03-02-PH14; D03-02-PH08
---

# D03-02-PH16 · Thiết kế chi tiết Báo cáo chỉ tiêu và sổ kiến trúc

## Tóm tắt cho hội đồng thẩm định

Tài liệu mô tả cách hiện thực 58 FR của [D02-03-PH16](../../02-yeu-cau/frs/D02-03-PH16-frs-bao-cao-chi-tieu.md). Phân hệ làm hai việc: tự tính 24 chỉ tiêu chuyển đổi số (KPI-01…18 của BRD và sáu chỉ tiêu bổ sung) từ số liệu đã tổng hợp ở các phân hệ nguồn để lãnh đạo khỏi tổng hợp tay, và giữ một sổ kiến trúc tối thiểu (thành phần, phiên bản, phụ thuộc, mức tuân thủ) để tỉnh trả lời được hệ thống nào đang chạy và tuân thủ khung kiến trúc đến đâu. Hệ cũ không có chức năng này nên toàn bộ là thiết kế mới. Sáu quyết định chi phối thiết kế:

1. **Hai mô-đun Modulith nhỏ trong `dh-platform`, một schema.** Chỉ tiêu nằm ở `vn.datahub.platform.kpi`, sổ kiến trúc ở `vn.datahub.platform.arch`; cả hai ghi schema `ph16_kpi` của `pg-core` và chia sẻ hạ tầng outbox, inbox, kiểm toán qua `platform.shared`. Mô-đun `arch` không phụ thuộc `kpi`; chiều ngược lại chỉ đi qua `arch::api` (ADR 164).
2. **PH-16 đứng cuối dòng số liệu và không bịa số.** Chỉ nhận quan sát đã tổng hợp từ phân hệ nguồn (sự kiện, kéo API, API đẩy) hoặc số nhập tay có bằng chứng. Thiếu nguồn thì vẫn ra phần đã có, gắn `PARTIAL` hoặc `NO_DATA` kèm cờ; không nội suy, không điền số kỳ trước (BR-16-007). Báo cáo chính thức chặn khi thiếu chỉ tiêu bắt buộc.
3. **Công thức là cấu hình có phiên bản, chạy bằng CEL.** Mỗi chỉ tiêu là biểu thức CEL (Common Expression Language) trên biến quan sát, biên dịch một lần, chạy với giới hạn 50 ms và 10.000 bước, tính lại cho cùng kết quả (ADR 161, cùng họ ADR 085 của PH-08). Mỗi giá trị ghi dòng truy nguồn tới quan sát và phiên bản công thức đã dùng.
4. **Lưu trên PostgreSQL phân vùng, không dựng kho phân tích riêng.** Khối lượng nhỏ (khoảng 10 triệu quan sát mỗi tenant mỗi năm) nên bảng quan sát và giá trị phân vùng theo tháng của kỳ đủ đạt lần tổng hợp 5 phút (ADR 160).
5. **Báo cáo công bố bất biến và có bằng chứng.** Công bố là một giao dịch: chụp giá trị, dựng PDF theo thể thức NĐ 30/2020, ký số, tính băm SHA-256, lưu kho WORM (Object Lock) 10 năm; sửa chỉ bằng phiên bản đính chính (ADR 162). Bản công bố do người thứ hai duyệt (bốn mắt).
6. **Không gọi thẳng hệ quốc gia.** Gói báo cáo và gói sổ kiến trúc dựng theo mẫu cấu hình ngoài có phiên bản, kiểm lược đồ, idempotent theo mã, phiên bản và băm, rồi giao PH-14 qua outbox; nhật ký nộp chỉ thêm là bằng chứng (ADR 163).

Tập nêu năm ADR đề xuất (160 đến 164), mười câu hỏi mở Q16-20…29, ma trận thành phần với FR (§13.3) và phụ lục đề nghị đồng bộ gồm các điểm lệch giữa CSDL 0.1 và FRS (§13.6).

## 1. Phạm vi và cách đọc

### 1.1. Mục đích và phạm vi

Tài liệu là thiết kế phần mềm đủ để kỹ sư viết mã và kiểm thử viên viết ca kiểm thử mà không phải đoán: cấu trúc gói, lớp chính, thuật toán, giao dịch, khóa, tên chỉ số. Phạm vi gồm 14 thành phần của hai mô-đun `kpi` và `arch` cùng hồ sơ triển khai. Ngoài phạm vi: lược đồ bảng (D03-03-PH16), đặc tả API (D03-04-PH16), màn hình (D03-06-PH16), ca kiểm thử (D05-02-PH16). PH-16 không thay giám sát thời gian thực và nhật ký tập trung của PH-13, không thay danh mục API và SLA của PH-02, không chấm điểm chất lượng (PH-08), không kết nối hay ký gửi tới hệ quốc gia (PH-14), không dựng kho phân tích dài hạn hay BI tự do.

### 1.2. Người đọc

Kỹ sư `dh-platform` đọc chương 3, 4, 5, 8; kỹ sư tính toán đọc 4.6, 4.16; kiến trúc sư, ATTT đọc 2, 6, 7; SRE đọc 9 đến 11; kiểm thử viên đọc 8, 12; hội đồng đọc Tóm tắt và chương 13.

### 1.3. Quy ước trong tài liệu

Mã `FR-16-nnn`, `BR-16-nnn`, `NFR-16-nnn`, `ERR-16-nnn`, `EVT-16-nn`, `API-16-nnn` lấy từ FRS; tên bảng và cột lấy từ DDL `ph16_kpi.sql`. Enum theo Phụ lục A của FRS; chỗ CSDL lệch FRS thì SDD theo FRS và ghi lệch ở §13.6. Chỉ số quan sát có tiền tố `dh_kpi_`. Số liệu giả định ghi "giả định": tỉnh `T01` quy mô vừa theo GĐ-04 (khoảng 200 HTTT), 24 chỉ tiêu, 36 kỳ tháng lịch sử, tối đa 10 triệu quan sát mỗi tenant mỗi năm, tenant ví dụ `T68`.

### 1.4. Thuật ngữ và chữ viết tắt

Tập dùng nhiều thuật ngữ về tính chỉ tiêu và lưu bằng chứng; bảng dưới giải thích từng thuật ngữ kèm tên bảng khi có.

| Thuật ngữ | Giải thích |
|---|---|
| Chỉ tiêu (indicator) | Số đo thuộc một trong năm nhóm `KET_NOI`, `CHIA_SE`, `DU_LIEU`, `VAN_HANH`, `KIEN_TRUC`, có phiên bản định nghĩa (`kpi_indicator`, `kpi_indicator_version`) |
| Quan sát (observation) | Một số đã tổng hợp ở phân hệ nguồn, định danh bằng `metricCode` dạng `ph{nn}.{đối-tượng}.{chỉ-số}`, thuộc một kỳ (`kpi_observation`) |
| CEL | Common Expression Language, ngôn ngữ biểu thức không có tác dụng phụ, biên dịch trước, chạy bằng thư viện `cel-java` |
| Lần tổng hợp (aggregation run) | Một lần tính mọi chỉ tiêu `ACTIVE` của một kỳ (`kpi_aggregation_run`) |
| Fail-soft, `PARTIAL` | Thiếu nguồn vẫn ra số phần đã có, gắn nhãn `PARTIAL` hoặc `NO_DATA` kèm cờ, không bịa số |
| Dòng truy nguồn (lineage) | Danh sách quan sát, số nhập tay và phiên bản công thức đã dùng cho một giá trị (`kpi_value_lineage`) |
| Số trễ (late data) | Quan sát đến sau khi kỳ đã kết thúc; làm kỳ chưa chốt phải tính lại (`kpi_observation.late`) |
| Bốn mắt | Người duyệt hoặc xác nhận khác người lập, nhập hoặc gửi (ADR-046) |
| WORM | Lưu một lần, không sửa, không xóa trước hạn (Object Lock) cho bản công bố (ADR-031) |
| Sổ kiến trúc | Danh sách thành phần kiến trúc, phiên bản, phụ thuộc, mức tuân thủ (`kpi_arch_component` và bảng liên quan) |
| Gói quốc gia | Tệp JSON dựng theo mẫu cấu hình để gửi hệ quốc gia qua PH-14 (`kpi_national_submission`) |
| VW, TA, TO, SO, DS, AU, PA, PO, PU | Các vai trò của D02-08 dùng ở PH-16: lãnh đạo xem, quản trị tỉnh, cán bộ tổng hợp, an toàn thông tin, cán bộ dữ liệu, kiểm toán, quản trị nền tảng, vận hành nền tảng, kiểm toán nền tảng |

: Thuật ngữ và chữ viết tắt

### 1.5. Cấu trúc tài liệu

Chương 2, 3: vị trí và cấu trúc mã; 4: mô hình miền, 14 thành phần, thuật toán; 5: bảy sơ đồ trình tự; 6 đến 11: đa tenant, bảo mật, trạng thái và lỗi, cấu hình, quan sát, hiệu năng và triển khai; 12: kiểm thử; 13: lộ trình, rủi ro, ADR, câu hỏi mở, đề nghị đồng bộ.

### 1.6. Tài liệu liên quan và quyết định kiến trúc

Thiết kế dựa trên FRS, thiết kế CSDL, kiến trúc tổng thể và các quyết định kiến trúc đã có; bảng dưới ghi từng tài liệu và phần nội dung mà tập này lấy từ đó.

| Tài liệu hoặc ADR | Nội dung dùng ở tập này |
|---|---|
| D02-03-PH16 FRS 0.2 | 58 FR, 35 BR, 22 NFR, 25 tham số, 14 sự kiện, mã lỗi, Phụ lục A enum |
| D03-03-PH16 CSDL 0.1 | Schema `ph16_kpi`: 36 bảng, RLS, phân vùng tháng, DDL chạy thử |
| D03-02-PH08 | Mẫu thành phần, họ ADR 085 (CEL), sự kiện KPI `EVT-08-14` |
| D03-02-PH14 | Kênh gửi quốc gia và nhận biên nhận |
| ADR-001, 003, 004, 006, 012, 031, 042, 046, 047, 057 | Spring Boot 4 và Modulith, RLS, Kafka, Keycloak và OPA, OpenBao, WORM, outbox và inbox, bốn mắt, lưu phân vùng, đồng bộ quốc gia |
| ADR đề xuất 160…164 | Mục 13.4 |

: Tài liệu liên quan và ADR

## 2. Vị trí trong kiến trúc

### 2.1. Đơn vị triển khai và vùng mạng

PH-16 là hai mô-đun của DU `dh-platform`, chạy cùng PH-13, PH-17, PH-18, PH-20 ở vùng ứng dụng nội bộ (giả định namespace `dh-control`, vùng Z3, theo D03-09 §4). Cùng một ảnh container chạy hai hồ sơ Spring: `api` (REST `/api/kpi/v1`, API đẩy `kpi.ingest`, `arch.register`, API đọc `kpi.read`) và `worker` (bộ tiêu thụ Kafka, lịch kéo, bộ tính, dựng PDF, xuất, gửi quốc gia). Tách hai Deployment để việc dựng PDF và tính kỳ lớn không làm chậm API; mỗi Deployment tối thiểu hai bản sao (NFR-16-008). Lưu lượng vào đi qua APISIX (Z2) với OIDC và OPA; sự kiện đi qua Kafka (Z5) bằng Debezium Outbox Event Router của nền tảng.

PH-16 không chạm dữ liệu nghiệp vụ nên `NetworkPolicy` chỉ cho đi ra PgBouncer của `pg-core`, Kafka, Valkey, OpenBao (ký số), kho đối tượng (Ceph RGW hoặc Garage), API chỉ số của các phân hệ nguồn trong cụm và PH-14; không ra Internet. Thông tin xác thực hệ quốc gia nằm ở PH-14 và OpenBao, không có trong `ph16_kpi` (NFR-16-018).

### 2.2. Sơ đồ thành phần

Sơ đồ dưới cho thấy 14 thành phần của hai mô-đun, hai đường vào (sự kiện và kéo API) và hai đường ra (sự kiện `{tenant}.kpi.*` và gói quốc gia qua PH-14).

```{.mermaid caption="Sơ đồ thành phần của PH-16 trong dh-platform và các hệ lân cận"}
flowchart TB
  subgraph SRC["Phân hệ nguồn"]
    P01["PH-01, 02, 04, 05"]
    P07["PH-07, 08, 10"]
    P13["PH-13, 19, 20"]
  end
  subgraph Z2["Z2 · Biên"]
    AX["APISIX<br/>OIDC, OPA"]
  end
  subgraph API["dh-platform · hồ sơ api"]
    CAT["catalog<br/>chỉ tiêu, nhóm"]
    MAN["manual<br/>số liệu tay"]
    DSH["dashboard<br/>đọc, thẻ, feed"]
    ADM["admin<br/>tham số, kiểm toán"]
    REG["arch registry<br/>sổ kiến trúc"]
    CMP["arch compliance<br/>tuân thủ"]
  end
  subgraph WRK["dh-platform · hồ sơ worker"]
    ING["ingest event<br/>inbox, chuẩn hóa"]
    PUL["ingest pull<br/>nguồn, kéo, độ tươi"]
    PER["period<br/>kỳ, điều phối"]
    ENG["engine<br/>CEL, trạng thái, điểm"]
    REP["report<br/>soạn, duyệt"]
    RND["render sign<br/>PDF, ký, WORM"]
    EXP["export dist<br/>xuất, phân phối"]
    NAT["national<br/>gói quốc gia"]
  end
  subgraph Z5["Z5 · Dữ liệu"]
    PG[("pg-core<br/>ph16_kpi")]
    K[("Kafka t68.kpi.*")]
    VK[("Valkey")]
    S3[("Ceph RGW<br/>WORM, bằng chứng")]
    BAO["OpenBao<br/>ký số"]
  end
  P14["PH-14 Kết nối quốc gia"]
  P13N["PH-13 thông báo, kiểm toán"]
  AX --> API
  SRC -->|"EVT"| K
  K --> ING
  PUL -->|"API chỉ số"| SRC
  ING --> PG
  PUL --> PG
  PER --> ENG
  ENG --> PG
  REP --> RND
  RND --> S3
  RND --> BAO
  EXP --> S3
  EXP --> P13N
  NAT --> P14
  REG --> PG
  CMP --> PG
  NAT -->|"đọc ảnh chụp"| REG
  ENG -->|"EVT-16"| K
  PUL -->|"chỉ số sổ kiến trúc"| REG
  ING --> VK
  ADM --> P13N
```

Hình cho thấy ba điểm tách: thu thập không biết công thức, `engine` không biết báo cáo, `report` chỉ đọc giá trị đã tính. Mũi tên từ `national` và `pull` sang `arch registry` là hai đường duy nhất `kpi` gọi `arch` (qua `arch::api`); không có chiều ngược lại.

### 2.3. Phụ thuộc với module và phân hệ khác

Bảng ghi phụ thuộc cứng hay mềm và ứng xử khi không khả dụng, theo nguyên tắc fail-soft cho số liệu, fail-closed cho công bố (FRS §12.1).

| Phụ thuộc | Loại | Dùng cho | Khi không khả dụng |
|---|---|---|---|
| PostgreSQL `pg-core` | Cứng | Mọi trạng thái | `readiness` sai, không phục vụ |
| Kafka | Cứng cho nguồn `EVENT` | Nhận quan sát, phát sự kiện | Outbox giữ sự kiện phát; nguồn `EVENT` thành `STALE`, đọc bù khi Kafka về |
| Ceph RGW (WORM, bằng chứng) | Cứng cho công bố | Bản công bố, bằng chứng, xuất | Công bố chặn (ERR-16-114), báo cáo giữ `APPROVED` |
| OpenBao (ký số) | Cứng khi `16.report.signing = true` | Ký PDF | ERR-16-031, thử lại sau |
| PH-13 | Mềm | Kiểm toán, thông báo, trạng thái vận hành, KPI-03, 04, 07, 15, 16 | Kiểm toán và thông báo xếp outbox; chỉ tiêu liên quan `PARTIAL` hoặc `NO_DATA`; `opsStatus = UNKNOWN` |
| PH-01, 02, 04, 05, 07, 08, 10, 19, 20 | Mềm | Quan sát, tự đăng ký kiến trúc | Chỉ tiêu liên quan `PARTIAL` hoặc `NO_DATA`; đọc bù khi trở lại |
| PH-14 | Mềm | Gửi quốc gia | Gói `FAILED`, tự gửi lại tới `16.national.retry-max` |
| PH-18 | Mềm | Hộp việc duyệt | Việc duyệt vẫn hiện ở UI-16-12 |
| Valkey | Mềm | Bộ đệm cấu hình, cửa sổ gom tính lại, giới hạn tốc độ | Rơi về bộ nhớ cục bộ và bảng CSDL, chậm hơn nhưng đúng |
| Keycloak, OPA | Cứng | Xác thực, phân quyền | Theo NFR-00 |

: Phụ thuộc của PH-16 và ứng xử khi không khả dụng

### 2.4. Hiện trạng mã và đường chuyển

Repo hiện chưa có mã nguồn của PH-16; SRS cũ (`docs/07-srs/SRS-PH-16-nas-kpi.md`) mô tả một "NAS" dùng Backstage cho sổ kiến trúc (ADR-006 cũ, đã thay) và ClickHouse cho chỉ tiêu. Thiết kế mới bỏ cả hai: sổ kiến trúc tự xây trên PostgreSQL (ADR 164), chỉ tiêu trên PostgreSQL phân vùng (ADR 160). Không có dữ liệu cũ cần chuyển; bộ chỉ tiêu mẫu `COMMON` nạp bằng seed của CSDL và tenant mới kế thừa khi khởi tạo (FR-16-008).

## 3. Cấu trúc mã nguồn

### 3.1. Cây package

Hai mô-đun theo khuôn `api / internal / events` của K-SDD; mỗi thành phần ở chương 4 là một gói con của `internal`. Chỉ `api` và `events` được mô-đun khác import. Hạ tầng dùng chung (outbox, inbox, kiểm toán, đọc tham số) nằm ở `vn.datahub.platform.shared` của DU.

```text
vn.datahub.platform.kpi
  api/            # DTO và interface công khai, ví dụ IndicatorReadApi, ReportReadApi
  events/         # lược đồ EVT-16-01…14, ghi qua outbox
  internal/
    catalog/      # chỉ tiêu, phiên bản, mục tiêu, ngưỡng, nhóm, kế thừa COMMON (FR-001…008)
    ingestevent/  # tiêu thụ Kafka, API đẩy, chuẩn hóa, bị loại (FR-010, 012, 016)
    ingestpull/   # nguồn, hợp đồng, kéo API, đọc bù, độ tươi (FR-009, 011, 013)
    manual/       # nhập tay, bằng chứng, xác nhận (FR-014, 015)
    engine/       # CEL, độ đầy đủ, trạng thái, điểm, xu hướng (FR-019…022)
    period/       # kỳ, điều phối tổng hợp, tính lại, chốt (FR-017, 018, 023, 024, 042)
    report/       # mẫu, bản nháp, thuyết minh, duyệt, đính chính (FR-025…028, 030…032)
    rendersign/   # PDF, ký số, WORM, bằng chứng công bố (FR-029, 036)
    exportdist/   # xuất, phân phối, API đọc cho hệ khác (FR-033…035)
    dashboard/    # bảng điều khiển, chi tiết, thẻ, so sánh (FR-037…041)
    national/     # mẫu gói, gói, nhật ký nộp, đối soát (FR-050…054)
    admin/        # tham số, kiểm toán, lưu giữ, chỉ số vận hành (FR-055…058)
vn.datahub.platform.arch
  api/            # ArchSnapshotApi, ArchMetricsApi, DTO thành phần
  events/         # EVT-16-10, EVT-16-11
  internal/
    registry/     # thành phần, phiên bản, phụ thuộc, tự đăng ký, đối chiếu (FR-043…046, 048, 049)
    compliance/   # tiêu chí, đánh giá, miễn trừ (FR-047)
vn.datahub.platform.shared   # OutboxWriter, InboxGuard, AuditWriter, TenantSettingReader, TenantSession
```

### 3.2. Quy tắc phụ thuộc

Quy tắc kiểm bằng ArchUnit và `ApplicationModules.verify()` của Spring Modulith (CC-MOD-01…05 ở D04-01). Sáu quy tắc đặc thù của PH-16:

1. `arch` không import `kpi`; `kpi` chỉ import `arch::api` và chỉ ở hai nơi: `national` (đọc ảnh chụp sổ để dựng gói) và `ingestpull` (đọc chỉ số `thanh-phan-da-danh-gia-tuan-thu` trong tiến trình). Điều này giữ đồ thị mô-đun không chu trình (ADR 164).
2. Chỉ `engine` được import biên dịch CEL; `catalog` gọi `engine` qua `FormulaValidator` khi thử tính (`:validate`, `:dry-run`) và không tự đánh giá công thức.
3. Chỉ `ingestevent`, `ingestpull` ghi `kpi_observation`, `kpi_ingest_log`; chỉ `engine` ghi `kpi_indicator_value`, `kpi_value_lineage`, `kpi_group_score`; chỉ `rendersign` ghi `kpi_report_signature` và đặt `content_hash`, `object_ref` của phiên bản báo cáo; chỉ `national` ghi `kpi_national_submission_log`. ArchUnit cấm `INSERT`, `UPDATE` vào các bảng đó ở gói khác.
4. `report` và `dashboard` chỉ có quyền đọc ở mức lớp `ValueReader`; không có hàm tính chỉ tiêu nào ngoài `engine`.
5. Chỉ `shared.OutboxWriter` ghi `outbox_event` và chỉ `shared.AuditWriter` gọi kiểm toán sang PH-13; mọi gói nghiệp vụ gọi qua interface, không ghi bảng trực tiếp.
6. Mã nguồn PH-16 không đọc bảng vật lý của phân hệ khác; chỉ dùng sự kiện, API chỉ số trong hợp đồng nguồn và `arch::api`.

### 3.3. Giao diện công bố

Gói `kpi::api` công bố cho mô-đun khác cùng DU: `IndicatorReadApi.latest` (giá trị và trạng thái gần nhất, cùng hiện thực với `GET /feed/indicator-values`, scope `kpi.read` cho PH-17 và cổng tỉnh), `ReportReadApi.published` và `KpiEventSchemas` (lược đồ Avro của EVT-16-01…13 đăng ký Apicurio). Gói `arch::api` công bố `ArchSnapshotApi.snapshot(tenant, asOf)` (sổ hiện hành cho gói quốc gia và xuất) và `ArchMetricsApi.assessedRatio` (tỷ lệ thành phần `ACTIVE` đã đánh giá, nguồn của chỉ tiêu `thanh-phan-da-danh-gia-tuan-thu`).

### 3.4. Danh sách thành phần được đặc tả

Bảng liệt kê 14 thành phần của chương 4 (mục 4.2 đến 4.15) và lớp chính; FR hiện thực nằm ở khối đặc tả từng mục và ma trận 13.3. Mục 4.1 là mô hình miền; 4.16 là các thuật toán.

| Mục | Thành phần | Lớp chính |
|---|---|---|
| 4.2 | `catalog` · kpi-catalog | `IndicatorService`, `VersionLifecycle`, `TargetThresholdService`, `GroupWeightService`, `CommonTemplateSync` |
| 4.3 | `ingestevent` · kpi-ingest-event | `EventObservationConsumer`, `PushIngestController`, `ObservationNormalizer`, `RejectedObservationService` |
| 4.4 | `ingestpull` · kpi-ingest-pull | `SourceService`, `PullScheduler`, `BackfillService`, `FreshnessWatcher`, `InternalMetricPuller` |
| 4.5 | `manual` · kpi-manual | `ManualValueService`, `EvidenceStore`, `ImportPreviewService`, `ManualConfirmationService` |
| 4.6 | `engine` · kpi-engine | `FormulaCompiler`, `ObservationAggregator`, `IndicatorEvaluator`, `CompletenessJudge`, `StatusEvaluator`, `ScoreCalculator` |
| 4.7 | `period` · kpi-period-scheduler | `PeriodGenerator`, `RunDispatcher`, `RunCoordinator`, `RecomputeDebouncer`, `PeriodCloser` |
| 4.8 | `report` · kpi-report | `ReportComposer`, `ExplanationService`, `ReportWorkflow`, `CorrectionService`, `TemplateService` |
| 4.9 | `rendersign` · kpi-render-sign | `ReportSnapshotter`, `PdfRenderer`, `SigningClient`, `WormStore`, `IntegrityVerifier` |
| 4.10 | `exportdist` · kpi-export-distribution | `ExportRunner`, `XlsxWriter`, `DistributionScheduler`, `DeliverySender`, `FeedController` |
| 4.11 | `dashboard` · kpi-dashboard-query | `DashboardQuery`, `SeriesQuery`, `CardProvider`, `CrossTenantComparer`, `OpsOverview` |
| 4.12 | `registry` · arch-registry | `ComponentService`, `AutoRegistrar`, `DependencyGraph`, `OpsStatusUpdater`, `ReconciliationJob` |
| 4.13 | `compliance` · arch-compliance | `CriteriaSetService`, `AssessmentService`, `LevelCalculator`, `WaiverService`, `WaiverExpiryJob` |
| 4.14 | `national` · national-submission | `NationalTemplateService`, `SubmissionBuilder`, `SchemaValidator`, `Pusher`, `ReceiptHandler`, `NationalReconciler` |
| 4.15 | `admin` · kpi-admin-audit | `SettingService`, `RetentionPurger`, `PartitionMaintenanceJob`, `OpsMetricsPublisher`, `AuditQuery` |

: Danh sách thành phần được đặc tả của PH-16

## 4. Thiết kế chi tiết từng thành phần

### 4.1. Mô hình miền

Mô hình miền có chín aggregate, mỗi aggregate có một lối ghi: `Indicator` (kèm phiên bản, mục tiêu, ngưỡng), `DataSource` (kèm hợp đồng), `ReportingPeriod` (kèm lần tổng hợp, giá trị, điểm nhóm), `ManualValue`, `Report` (kèm phiên bản, thuyết minh), `Distribution`, `ArchComponent` (kèm phiên bản, phụ thuộc, đánh giá, miễn trừ), `NationalSubmission` (kèm nhật ký) và `ExportJob`. Hình dưới là sơ đồ lớp rút gọn; bất biến (invariant) nằm ở bảng liền sau.

```{.mermaid caption="Sơ đồ lớp rút gọn của mô hình miền PH-16"}
classDiagram
  Indicator "1" --> "*" IndicatorVersion
  IndicatorVersion "1" --> "1" Target
  DataSource "1" --> "*" Observation
  ReportingPeriod "1" --> "*" AggregationRun
  AggregationRun "1" --> "*" IndicatorValue
  IndicatorValue ..> IndicatorVersion : ghim phiên bản
  IndicatorValue "1" --> "*" LineageEntry
  LineageEntry ..> Observation : tham chiếu
  LineageEntry ..> ManualValue : tham chiếu
  Report "1" --> "*" ReportVersion
  ReportVersion ..> AggregationRun : chụp lần chính thức
  ArchComponent "1" --> "*" ComponentVersion
  ArchComponent "1" --> "*" Assessment
  ArchComponent "1" --> "*" Waiver
  NationalSubmission "1" --> "*" SubmissionLog
  NationalSubmission ..> ReportVersion : nguồn gói
  NationalSubmission ..> ArchComponent : nguồn gói
```

Hình cho thấy `IndicatorValue` ghim phiên bản định nghĩa đã dùng và có dòng truy nguồn nên số quá khứ không đổi khi công thức đổi (BR-16-002, BR-16-033); `ReportVersion` chụp giá trị của lần tổng hợp chính thức nên bản công bố không phụ thuộc dữ liệu sống.

| Aggregate | Bất biến chính | Chỗ bảo đảm |
|---|---|---|
| `Indicator` | Tối đa một phiên bản `ACTIVE` và một bản nháp hoặc chờ duyệt (BR-16-002); chỉ tiêu `COMMON` không sửa ở tenant (BR-16-018); mã khớp `^[a-z][a-z0-9-]{2,62}$` | `VersionLifecycle`, chỉ mục duy nhất từng phần |
| `DataSource` | Một `sourceCode` duy nhất trong tenant; `idempotencyRef` duy nhất theo (`sourceId`, `periodStart`) (BR-16-012) | `SourceService`, `uq_kpi_observation_idem` |
| `ReportingPeriod` | Mã kỳ theo mẫu; một lần tổng hợp `QUEUED` hoặc `RUNNING` mỗi kỳ (BR-16-030); kỳ `CLOSED` không nhận giá trị mới | `RunCoordinator`, `uq_kpi_aggregation_run_active`, trigger chuyển trạng thái |
| `ManualValue` | Người xác nhận khác người nhập (BR-16-005); có bằng chứng khi bật (BR-16-006); một bản `ACCEPTED` mỗi (chỉ tiêu, kỳ) | `ManualConfirmationService`, ràng buộc CSDL |
| `Report` | Người duyệt, công bố khác người lập (BR-16-004); `PUBLISHED` bất biến (BR-16-009); chỉ tiêu `mandatory` có số mới gửi duyệt (BR-16-008) | `ReportWorkflow`, trigger `tg_kpi_report_version_frozen` |
| `Distribution` | Người nhận hợp lệ, chỉ báo cáo `PUBLISHED` ra ngoài (BR-16-026) | `DistributionScheduler` |
| `ArchComponent` | Không xóa, chỉ `RETIRED`; không `RETIRED` khi còn thành phần `ACTIVE` phụ thuộc; không phụ thuộc vòng (BR-16-025); trường nguồn quản lý chỉ nhận từ nguồn (BR-16-023) | `ComponentService`, `DependencyGraph` |
| `Assessment`, `Waiver` | Mức tuân thủ chỉ đổi khi `CONFIRMED` bởi người khác người lập; miễn trừ ≤ 180 ngày (BR-16-024) | `AssessmentService`, `WaiverService` |
| `NationalSubmission` | Chỉ từ báo cáo `PUBLISHED` hoặc sổ hiện hành; trùng (mã, phiên bản, băm) bị chặn (BR-16-021); nhật ký chỉ thêm (BR-16-022) | `SubmissionBuilder`, trigger chỉ thêm |

: Aggregate và bất biến của PH-16

### 4.2. Quản lý bộ chỉ tiêu (`catalog`)

::: dac-ta
**Mục đích.** Cho phép tỉnh định nghĩa chỉ tiêu một lần, có phiên bản và duyệt bốn mắt, rồi mọi kỳ tính theo đúng định nghĩa đã duyệt; kế thừa 24 chỉ tiêu mẫu `COMMON` và nhận cập nhật mẫu mà không bị ghi đè.

**Lớp chính.** `IndicatorService`, `VersionLifecycle`, `TargetThresholdService`, `GroupWeightService`, `CommonTemplateSync`, `FormulaValidator` (cổng sang `engine`).

**Đơn vị chạy.** `dh-platform` hồ sơ `api`.

**FR hiện thực.** FR-16-001…008; BR-16-002, 003, 015, 018, 033.

**Giao diện vào.** API-16-001…020 (chỉ tiêu, phiên bản, `:validate`, `:dry-run`, `:submit`, `:approve`, `:retire`, nhóm, `:adopt-common`, cập nhật mẫu); scope người dùng `PERM-16-read`, `PERM-16-admin`, `PERM-16-approve`.

**Phụ thuộc ra.** `engine` (thử tính), PH-20 (khởi tạo tenant kế thừa mẫu), PH-13 (kiểm toán qua `shared`).

**Dữ liệu.** `kpi_indicator_group`, `kpi_indicator`, `kpi_indicator_version`, `kpi_indicator_threshold`, `kpi_source_contract` (đọc để kiểm biến).

**Sự kiện.** EVT-16-01 khi phiên bản `ACTIVE`; EVT-16-02 khi ngừng hoặc thay thế.

**Lỗi và xử lý.** ERR-16-002, 003, 005, 007, 008, 009, 010, 011, 012, 013, 014, 054, 055.

**Quan sát.** `dh_kpi_indicators{group,state}`, `dh_kpi_indicator_version_total{result}`.
:::

Chi tiết thiết kế:

Một phiên bản định nghĩa là bất biến sau khi `ACTIVE`; sửa tức là tạo phiên bản mới. `VersionLifecycle` hiện thực máy trạng thái FRS §4.3 và kiểm ở máy chủ: gửi duyệt đòi hỏi thử tính đúng nội dung hiện tại (băm `formula` + mục tiêu + ngưỡng so với băm lúc thử, ERR-16-011), ngưỡng đơn điệu theo `direction` (ERR-16-010), mọi biến `obs("...")` có hợp đồng nguồn (ERR-16-009). Người duyệt khác người soạn và người gửi (BR-16-003, ERR-16-005). Khi duyệt, giao dịch đặt phiên bản cũ `SUPERSEDED`, phiên bản mới `ACTIVE` với `effectiveFrom`, ghi outbox EVT-16-01; nếu `effectiveFrom` rơi vào kỳ chưa chốt thì yêu cầu tính lại kỳ đó qua `RecomputeDebouncer` (FR-16-023).

`:dry-run` gọi `engine` tính phiên bản nháp trên quan sát của kỳ trước (hoặc kỳ chỉ định) nhưng không lưu giá trị; kết quả trả giá trị, trạng thái, biến thiếu và thời gian đánh giá để người soạn chỉnh. Chỉ tiêu `COMMON` ở tenant là bản kế thừa (`derivedFrom`); tùy biến là tạo phiên bản của tenant, ERR-16-014 cho sửa trực tiếp. `CommonTemplateSync` nhận mẫu `COMMON` có phiên bản mới, ghi gợi ý `common_update`; tenant chọn `ACCEPTED` thì tạo phiên bản nháp từ mẫu, đi qua duyệt bốn mắt như mọi phiên bản (BR-16-018), xung đột với tùy biến trả ERR-16-055. Trọng số nhóm lưu theo thang 0…1 trong CSDL; `GroupWeightService` kiểm tổng bằng 1 (hiển thị 100, ERR-16-012). Đổi mục tiêu, ngưỡng, trọng số không làm đổi kỳ đã chốt vì giá trị ghim phiên bản (BR-16-033).

### 4.3. Tiếp nhận quan sát từ sự kiện và API đẩy (`ingestevent`)

::: dac-ta
**Mục đích.** Nhận số đã tổng hợp từ sự kiện Kafka và API đẩy ngay khi phân hệ nguồn phát, chuẩn hóa thành quan sát, bảo đảm một sự kiện đến hai lần chỉ được ghi một lần và không mất quan sát khi PH-16 dừng.

**Lớp chính.** `EventObservationConsumer`, `PushIngestController`, `ObservationNormalizer`, `ContractChecker`, `LateDataMarker`, `RejectedObservationService`.

**Đơn vị chạy.** `dh-platform` hồ sơ `worker` (bộ tiêu thụ); hồ sơ `api` (API đẩy).

**FR hiện thực.** FR-16-010, 012, 016; BR-16-012, 013, 019, 028.

**Giao diện vào.** Kafka topic của nguồn `EVENT` (ví dụ `t68.dq.kpi.published.v1`, EVT-02-13, EVT-19-07); API-16-030 `POST /ingest/observations` (scope `kpi.ingest`); API-16-042…045 tra nhật ký, quan sát, quan sát bị loại, xử lý lại.

**Phụ thuộc ra.** PostgreSQL; `ingestpull` (đọc hợp đồng nguồn); Valkey (bộ đệm hợp đồng); `period` (đánh dấu kỳ cần tính lại).

**Dữ liệu.** `kpi_observation`, `kpi_ingest_log`, `inbox_event`.

**Sự kiện.** Không phát sự kiện riêng; đổi trạng thái nguồn do `ingestpull` phát EVT-16-03.

**Lỗi và xử lý.** ERR-16-101, 102, 103, 104, 105; API đẩy trả 400, 403, 409, 422 theo RFC 9457.

**Quan sát.** `dh_kpi_observations_total{source,result}`, `dh_kpi_ingest_lag_seconds`, `dh_kpi_ingest_rejected_total{reason}`.
:::

Chi tiết thiết kế:

Bộ tiêu thụ đăng ký một nhóm `kpi-ingest` trên các topic trong hợp đồng của từng tenant, tắt `enable.auto.commit` và chỉ chấp nhận offset sau khi giao dịch CSDL kết thúc. Mỗi bản tin xử lý trong một giao dịch: chèn `inbox_event (tenant, consumer, event_id)` bằng `ON CONFLICT DO NOTHING`; nếu không chèn được tức bản tin trùng, đếm `result = DUPLICATE` và bỏ qua. Nhờ vậy dừng PH-16 một giờ rồi bật lại không mất và không nhân đôi quan sát (NFR-16-012), vì Kafka giữ 7 ngày và `inbox` khử trùng.

`ObservationNormalizer` giải mã theo `schemaRef` và `schemaVersion` của hợp đồng, quy đơn vị về đơn vị của chỉ số, quy thời gian về `Asia/Ho_Chi_Minh` và xác định kỳ theo `periodEnd` (BR-16-013). `ContractChecker` kiểm `metricCode` thuộc hợp đồng của nguồn (ngoài: ERR-16-102), `tenantId` bản tin khớp tiền tố topic (lệch: ERR-16-101), `dimensions` không chứa khóa nghi định danh cá nhân (`cccd`, `hoTen`, `soDienThoai`, BR-16-028). Quan sát hợp lệ chèn bằng `INSERT … ON CONFLICT (tenant_id, source_id, idempotency_ref, period_start) DO NOTHING`; nếu trùng `idempotencyRef` mà khác giá trị thì không ghi đè mà chuyển sang bảng bị loại với ERR-16-103 (BR-16-012). Bản tin hỏng lược đồ vào bị loại với ERR-16-105 chứ không chặn partition.

`LateDataMarker` đặt `late = true` khi kỳ của quan sát đã `COLLECTING` và hết thời hạn nhận kỳ, hoặc `CLOSED` (ERR-16-104, chỉ lưu); với kỳ `COMPUTED` chưa chốt và `16.late-data.recompute = true`, nó gọi `RecomputeDebouncer.request(period)` (§4.7). API đẩy dùng cùng đường chuẩn hóa, xử lý theo lô 1…500 quan sát mỗi lệnh, trả phản hồi từng phần tử với `result` `ACCEPTED`, `DUPLICATE`, `REJECTED`; lô trả `202` khi mọi phần tử được nhận, `207` khi có phần tử lỗi, không thất bại cả lô. Xử lý lại quan sát bị loại (FR-16-016) chạy lại `ContractChecker` rồi chèn như thường; bản tin đạt chuyển `outcome` `REJECTED` → `REPROCESSED`, giữ mã lỗi cũ.

### 4.4. Nguồn số liệu, kéo API và độ tươi (`ingestpull`)

::: dac-ta
**Mục đích.** Quản lý danh sách nguồn và hợp đồng chỉ số; kéo API chỉ số của phân hệ chỉ có API thống kê, đọc bù số lỡ, và theo dõi độ tươi để nguồn lặng hoặc hỏng được đánh dấu và báo ngay.

**Lớp chính.** `SourceService`, `ContractService`, `PullScheduler`, `PullClient`, `BackfillService`, `FreshnessWatcher`, `InternalMetricPuller`.

**Đơn vị chạy.** `dh-platform` hồ sơ `api` (đăng ký, thử nguồn); hồ sơ `worker` (lịch kéo, bộ quét).

**FR hiện thực.** FR-16-009, 011, 013; BR-16-007, 012, 014.

**Giao diện vào.** API-16-021…029 (nguồn, `:test`, `:pause`, `:resume`, `:retire`, `:pull`); lịch `cron` của từng nguồn; bộ quét 10 phút.

**Phụ thuộc ra.** API chỉ số PH-02 (API-02-079, API-02-097), PH-05 (API-05-092), PH-08 (API-08-122, scope `dq.read`), PH-13; `arch::api.ArchMetricsApi`; OpenBao hoặc Keycloak (token máy theo scope); Valkey.

**Dữ liệu.** `kpi_data_source`, `kpi_source_contract`, `kpi_observation`, `kpi_ingest_log`.

**Sự kiện.** EVT-16-03 khi nguồn đổi trạng thái.

**Lỗi và xử lý.** ERR-16-015, 016, 017, 106, 107, 108; thông báo vận hành về PH-13 khi `STALE`, `FAILED`.

**Quan sát.** `dh_kpi_source_state{state}`, `dh_kpi_pull_duration_seconds{source}`, `dh_kpi_pull_failures_total{source}`.
:::

Chi tiết thiết kế:

`PullScheduler` chạy mỗi phút, chọn nguồn `PULL_API` tới lịch bằng `SELECT … FOR UPDATE SKIP LOCKED` theo từng tenant dưới khóa ShedLock `kpi-pull-{tenant}`. `PullClient` lấy token máy theo scope của nguồn, gọi API với tham số kỳ, thời gian chờ 30 giây, phân trang tới hết; `idempotencyRef = {sourceCode}:{metricCode}:{periodCode}:{dimensions-hash}` nên kéo lại cùng kỳ không nhân đôi (BR-16-012). Lỗi gọi (hết thời gian, 5xx) thử lại ba lần cách 1, 2, 4 phút; hết lượt thì tăng `failCount` (ERR-16-106) và đủ `16.source.fail-after` lần liên tiếp nguồn thành `FAILED` (ERR-16-108). Đọc bù (`BackfillService`) dùng `backfillEndpoint` của nguồn `EVENT` (ví dụ API-08-122) cho khoảng `from…to` tối đa 12 tháng (vượt: ERR-16-060), chạy khi kỳ chuyển `COLLECTING` mà biến chưa có quan sát hoặc khi người dùng bấm.

`FreshnessWatcher` quét 10 phút một lần: nguồn `ACTIVE` không có quan sát quá `16.source.stale-hours` (mặc định 26, ghi đè theo nguồn) thành `STALE` (ERR-16-107) và có thông báo ≤ 15 phút (NFR-16-014); có quan sát mới thì về `ACTIVE`. `PAUSED` không tính là lỗi. `InternalMetricPuller` gọi `ArchMetricsApi` trong tiến trình mỗi ngày để sinh quan sát `ph16.arch.assessed-ratio`; đây là nguồn nội bộ nên không qua Kafka (Q16-21). Nhiều nguồn cùng `metricCode` trong kỳ: `engine` chọn nguồn `priority` cao nhất có số (BR-16-014); `ingestpull` không tự chọn. Chặn ngừng nguồn là nguồn duy nhất của chỉ tiêu đang hiệu lực (ERR-16-017).

### 4.5. Số liệu nhập tay có bằng chứng (`manual`)

::: dac-ta
**Mục đích.** Cho chỉ tiêu không đo tự động được (KPI-02, 08, 17, 18, một phần KPI-01, 09) nhập số kèm bằng chứng và được người thứ hai xác nhận, để số tay cũng truy được và không tự khai.

**Lớp chính.** `ManualValueService`, `EvidenceStore`, `ImportPreviewService`, `ManualConfirmationService`, `ManualRangeValidator`.

**Đơn vị chạy.** `dh-platform` hồ sơ `api`.

**FR hiện thực.** FR-16-014, 015; BR-16-005, 006, 035.

**Giao diện vào.** API-16-031…041 (danh sách, tạo, sửa, bằng chứng, mẫu XLSX, `:import`, `:commit`, `:submit`, `:accept`, `:reject`); quyền `PERM-16-manual`.

**Phụ thuộc ra.** Ceph RGW bucket `kpi-evidence`; `period` (yêu cầu tính lại sau khi `ACCEPTED`); PH-18 (việc xác nhận).

**Dữ liệu.** `kpi_manual_value`, `kpi_manual_evidence`.

**Sự kiện.** EVT-16-04 khi `ACCEPTED` hoặc `REJECTED`.

**Lỗi và xử lý.** ERR-16-005, 006, 007, 018, 019, 020, 021, 053; ERR-16-112 (cờ `MANUAL_PENDING` khi tổng hợp).

**Quan sát.** `dh_kpi_manual_values{state}`, `dh_kpi_manual_confirm_seconds`.
:::

Chi tiết thiết kế:

Biểu mẫu và tệp XLSX cùng đi qua `ManualRangeValidator` (giá trị trong miền theo `kind` và `unit` của chỉ tiêu, ERR-16-019). Bằng chứng là tệp (≤ `16.manual.max-file-mb`, loại PDF, DOCX, XLSX, JPG, PNG, quét kiểm tra phần mở rộng và dấu hiệu tệp) hoặc số văn bản; khi `16.manual.evidence-required = true` thiếu cả hai trả ERR-16-018. Tệp lưu ở `kpi-evidence/{tenant}/{manualId}/{sha256}` với băm ghi vào hàng bằng chứng. Nhập hàng loạt hai pha: `:import` đọc tệp XLSX, kiểm từng dòng (`VALID`, `INVALID`) và lưu kết quả xem trước ở đối tượng tạm `kpi-evidence/imports/{importId}.json` hết hạn sau 24 giờ; `:commit` chỉ ghi các dòng `VALID` thành bản `DRAFT` (xem đề nghị lưu bảng ở §13.6).

Người nhập chỉ gửi xác nhận (`DRAFT → SUBMITTED`); người xác nhận phải khác người nhập (ERR-16-005) và thuộc `confirmerRoles` của chỉ tiêu (ERR-16-059). `ACCEPTED` ghi trong một giao dịch với outbox EVT-16-04 và yêu cầu tính lại kỳ; mỗi (chỉ tiêu, kỳ) chỉ có một bản `ACCEPTED` (ERR-16-021). Với chỉ tiêu `MIXED`, số tự động chỉ có hiệu lực khi có xác nhận tay cùng kỳ, còn số tay chỉ thay số tự động khi số tự động `NO_DATA` (BR-16-035); `engine` đọc hai nguồn và áp quy tắc này, `manual` chỉ cung cấp trạng thái xác nhận.

### 4.6. Bộ tính chỉ tiêu CEL (`engine`)

::: dac-ta
**Mục đích.** Tính từng giá trị chỉ tiêu theo đúng phiên bản công thức có hiệu lực, đánh giá độ đầy đủ, trạng thái so ngưỡng, điểm nhóm và xu hướng, ghi dòng truy nguồn; tái lập được và không bao giờ bịa số.

**Lớp chính.** `FormulaCompiler`, `FormulaCache`, `ObservationAggregator`, `IndicatorEvaluator`, `CompletenessJudge`, `StatusEvaluator`, `ScoreCalculator`, `TrendCalculator`, `LineageWriter`.

**Đơn vị chạy.** `dh-platform` hồ sơ `worker`; thử tính `:dry-run` chạy ở hồ sơ `api` bằng cùng lớp.

**FR hiện thực.** FR-16-003 (thử tính), 019, 020, 021, 022; BR-16-001, 002, 007, 014, 015, 016, 030, 033, 034.

**Giao diện vào.** Gọi từ `RunCoordinator` (tính một kỳ) và `FormulaValidator` (thử); không có endpoint riêng.

**Phụ thuộc ra.** PostgreSQL (đọc quan sát, số tay, giá trị tháng con); `cel-java`; Valkey (bộ đệm chương trình CEL đã biên dịch).

**Dữ liệu.** Đọc `kpi_observation`, `kpi_manual_value`, `kpi_indicator_version`, `kpi_indicator_threshold`; ghi `kpi_indicator_value`, `kpi_value_lineage`, `kpi_group_score`.

**Sự kiện.** EVT-16-06 khi trạng thái chỉ tiêu đổi (qua outbox của `RunCoordinator`).

**Lỗi và xử lý.** ERR-16-008, 109, 110, 111, 112; công thức lỗi cho giá trị `NO_DATA` kèm cờ `FORMULA_ERROR`, không làm hỏng cả lần tổng hợp.

**Quan sát.** `dh_kpi_formula_eval_seconds`, `dh_kpi_formula_errors_total{indicator}`, `dh_kpi_indicator_status{group,status}`, `dh_kpi_run_completeness`.
:::

Chi tiết thiết kế:

`FormulaCompiler` biên dịch biểu thức một lần khi lưu phiên bản (kiểm cú pháp và kiểu, ERR-16-008) và khi nạp bộ đệm; môi trường CEL chỉ có bốn hàm `obs`, `manual`, `prev` và bộ toán tử, hàm toán học chuẩn (`min`, `max`, `abs`, `round`); không có đọc tệp, mạng, thời gian hệ thống. Mỗi lần đánh giá có giới hạn 50 ms (`16.aggregate.formula-timeout-ms`) và 10.000 bước; vượt thì `NO_DATA` kèm `FORMULA_ERROR` (ERR-16-109). Hàm `obs` không gọi CSDL: `ObservationAggregator` đã nạp sẵn bảng giá trị theo (`metricCode`, chiều) cho cả kỳ nên đánh giá công thức thuần bộ nhớ, tái lập được (NFR-16-011). Chi tiết thuật toán ở §4.16.

Bốn lớp tính và ghi được tách để kiểm thử riêng: `IndicatorEvaluator` cho (giá trị, biến thiếu, nguồn dùng), `CompletenessJudge` cho `COMPLETE`, `PARTIAL`, `NO_DATA` cùng cờ, `StatusEvaluator` cho `ON_TRACK`, `AT_RISK`, `OFF_TRACK` theo ngưỡng, `ScoreCalculator` cho điểm nhóm và tổng. Kết quả ghi bằng một lô cho cả lần tổng hợp (không từng chỉ tiêu một giao dịch) để lần tính 24 chỉ tiêu dùng một giao dịch ghi; lần tổng hợp `FAILED` không đụng kết quả lần trước vì mỗi lần có `run_id` riêng và `is_current` chỉ chuyển ở bước cuối (BR-16-030).

### 4.7. Kỳ báo cáo và điều phối tổng hợp (`period`)

::: dac-ta
**Mục đích.** Sinh kỳ tháng, quý, năm đúng hạn, điều phối lần tổng hợp theo lịch hoặc thủ công, gom yêu cầu tính lại do số liệu trễ, chốt kỳ và mở lại có lý do, để mỗi kỳ có đúng một lần tổng hợp hoạt động và số chốt rõ ràng.

**Lớp chính.** `PeriodGenerator`, `PeriodStateAdvancer`, `RunDispatcher`, `RunCoordinator`, `RecomputeDebouncer`, `RunWatchdog`, `PeriodCloser`.

**Đơn vị chạy.** `dh-platform` hồ sơ `worker` (lịch và điều phối); hồ sơ `api` (lệnh tay).

**FR hiện thực.** FR-16-017, 018, 023, 024, 042; BR-16-011, 013, 030.

**Giao diện vào.** API-16-046…058 (kỳ, lần tổng hợp, `:recompute`, `:close`, `:reopen`, trạng thái đổi); API-16-093 tổng quan vận hành; lịch `16.aggregate.cron`; quyền `PERM-16-run`.

**Phụ thuộc ra.** `engine` (tính), `ingestpull` (đọc bù khi kỳ `COLLECTING`), `manual` (trạng thái xác nhận), PH-18 (nhắc chốt kỳ).

**Dữ liệu.** `kpi_reporting_period` (cột `recompute_requested_at`), `kpi_aggregation_run`, cộng `shedlock` (đề nghị §13.6).

**Sự kiện.** EVT-16-05 khi lần tổng hợp kết thúc; EVT-16-06 khi trạng thái chỉ tiêu đổi; EVT-16-14 khi kỳ `CLOSED` hoặc `REOPENED` (`PeriodCloser`, cùng giao dịch outbox).

**Lỗi và xử lý.** ERR-16-022, 023, 024, 025, 026, 110; ERR-16-125 khi phân vùng chưa tạo.

**Quan sát.** `dh_kpi_run_duration_seconds{trigger,state}`, `dh_kpi_run_queue_depth`, `dh_kpi_period_state{state}`, `dh_kpi_recompute_debounced_total`.
:::

Chi tiết thiết kế:

`PeriodGenerator` chạy hằng ngày, theo `16.period.types` tạo kỳ `OPEN` của tháng, quý, năm mới; `PeriodStateAdvancer` chuyển `OPEN → COLLECTING` khi qua `endDate` và đặt `close_due_date` bằng ngày `16.period.close-day` của tháng sau. `RunDispatcher` chạy theo `16.aggregate.cron` dưới ShedLock `kpi-run-dispatch`: với mỗi tenant `ACTIVE`, đặt `TenantContext` tường minh và tạo lần tổng hợp `SCHEDULE` cho kỳ chưa chốt; chỉ mục duy nhất từng phần `uq_kpi_aggregation_run_active` làm việc tạo lần thứ hai cho cùng kỳ thất bại (ERR-16-023) nên điều phối không cần khóa ứng dụng thêm.

`RunCoordinator` nhận việc bằng `SKIP LOCKED`, chuyển `QUEUED → RUNNING` bằng `UPDATE … WHERE state = 'QUEUED'`, gọi `engine`, rồi ghi kết quả và chuyển `SUCCEEDED` hoặc `PARTIAL` trong một giao dịch cùng outbox EVT-16-05, EVT-16-06. `RunWatchdog` hủy lần quá `16.aggregate.timeout-minutes` thành `FAILED` (ERR-16-110) và để lần trước còn hiệu lực. `RecomputeDebouncer` gom yêu cầu tính lại trong cửa sổ `16.late-data.debounce-minutes` (mặc định 5): yêu cầu đầu ghi `recompute_requested_at` của kỳ (đề nghị cột §13.6) và đặt khóa Valkey `{tenant}:kpi:recompute:{period}` với TTL cửa sổ; bộ quét mỗi phút chạy mọi kỳ có `recompute_requested_at` đã quá cửa sổ và tạo một lần `LATE_DATA`. Dùng cột CSDL làm nguồn sự thật nên mất Valkey chỉ làm thêm một lần quét chứ không mất yêu cầu. `PeriodCloser` kiểm kỳ đủ điều kiện chốt (có lần tổng hợp thành công, không còn `MANUAL_PENDING` cho chỉ tiêu `mandatory`, ERR-16-025); mở lại cần TA và lý do ≥ 50 ký tự (BR-16-011), và không mở khi còn báo cáo đang duyệt (ERR-16-026).

### 4.8. Soạn, duyệt và đính chính báo cáo (`report`)

::: dac-ta
**Mục đích.** Dựng bản nháp báo cáo từ kỳ đã tính, cho cán bộ viết thuyết minh cho chỉ tiêu chệch, rồi đi qua duyệt bốn mắt; sau công bố chỉ cho đính chính bằng phiên bản mới hoặc rút.

**Lớp chính.** `TemplateService`, `ReportComposer`, `ExplanationService`, `ReportWorkflow`, `MandatoryChecker`, `CorrectionService`, `WithdrawalService`.

**Đơn vị chạy.** `dh-platform` hồ sơ `api`.

**FR hiện thực.** FR-16-025, 026, 027, 028, 030, 031, 032; BR-16-004, 008, 009, 029.

**Giao diện vào.** API-16-059…078 (mẫu, báo cáo, thuyết minh, `:refresh`, `:submit`, `:approve`, `:request-changes`, `:correct`, `:withdraw`, hàng đợi duyệt); quyền `PERM-16-report`, `PERM-16-approve`.

**Phụ thuộc ra.** `rendersign` (công bố), `period` (kiểm kỳ chốt), PH-18 (việc duyệt).

**Dữ liệu.** `kpi_report_template`, `kpi_report`, `kpi_report_version`, `kpi_report_approval`.

**Sự kiện.** EVT-16-07 khi gửi duyệt; EVT-16-09 khi `CHANGES_REQUESTED`, `SUPERSEDED`, `WITHDRAWN`.

**Lỗi và xử lý.** ERR-16-005, 006, 007, 027, 028, 029, 030, 032, 033.

**Quan sát.** `dh_kpi_report_state{type,state}`, `dh_kpi_report_review_seconds`.
:::

Chi tiết thiết kế:

`ReportComposer` đọc giá trị và điểm nhóm của lần tổng hợp chính thức của kỳ (lần `SUCCEEDED` hoặc `PARTIAL` mới nhất của kỳ `CLOSED` cho báo cáo `PERIODIC` và `NATIONAL`; kỳ bất kỳ cho `AD_HOC`) và ghi vào cột `snapshot` của phiên bản `DRAFT`. `:refresh` làm mới ảnh chụp khi kỳ đã tính lại; bản nháp hiện dải "Số liệu kỳ đã được tính lại" (FR-16-023). Gửi duyệt qua `MandatoryChecker`: chỉ tiêu `mandatory` `NO_DATA` thì chặn (ERR-16-029); chỉ tiêu `OFF_TRACK` hoặc `mandatory` `PARTIAL` thiếu thuyết minh thì chặn (ERR-16-030, BR-16-029).

`ReportWorkflow` là một máy trạng thái bảng chuyển (§8.1) với mọi chuyển bằng `UPDATE … WHERE state = :expected`. Người duyệt, công bố, rút khác người lập và người gửi (ERR-16-005); riêng `16.report.four-eyes = false` chỉ áp cho báo cáo `AD_HOC` (BR-16-004). Sau `PUBLISHED` mọi lệnh sửa trả ERR-16-032 và trigger CSDL từ chối cập nhật cột nội dung (NFR-16-013). Đính chính tạo `report_version` mới với `correction_of_version_no` và lý do, đi lại vòng duyệt; khi bản mới `PUBLISHED`, bản cũ thành `SUPERSEDED` trong cùng giao dịch. Gửi duyệt báo cáo `PERIODIC`, `NATIONAL` cần `document_number` và `recipients_note` (ERR-16-061). Báo cáo `APPROVED` chưa công bố được trả về soạn qua API-16-073 (`APPROVED` → `CHANGES_REQUESTED`, phát EVT-16-09), dùng khi ký số lỗi kéo dài hoặc cần mở lại kỳ (ERR-16-026). Kỳ bị mở lại và chốt lại làm đổi số của báo cáo đã công bố thì `ReportWorkflow` gắn cờ cần đính chính (BR-16-011).

### 4.9. Dựng PDF, ký số, lưu WORM (`rendersign`)

::: dac-ta
**Mục đích.** Biến báo cáo đã duyệt thành bản công bố không thể sửa: chụp giá trị, dựng PDF theo thể thức NĐ 30/2020, ký số, tính băm, lưu kho WORM trong 10 năm, và kiểm băm định kỳ.

**Lớp chính.** `ReportSnapshotter`, `PdfRenderer`, `ChartRenderer`, `SigningClient`, `WormStore`, `PublishTransaction`, `IntegrityVerifier`.

**Đơn vị chạy.** `dh-platform` hồ sơ `worker` (dựng, ký); hồ sơ `api` nhận lệnh công bố và chờ kết quả.

**FR hiện thực.** FR-16-029, 036; BR-16-009, 010, 027; NFR-16-009, 013.

**Giao diện vào.** API-16-074 `POST /reports/{reportCode}:publish`; API-16-088 bằng chứng công bố; bộ quét hằng ngày của `IntegrityVerifier`.

**Phụ thuộc ra.** OpenHTMLtoPDF (dựng), OpenBao (ký, ADR-012), Ceph RGW bucket `kpi-reports` có Object Lock (ADR-031, ADR 162), `exportdist` (phân phối), `national` (nguồn gói).

**Dữ liệu.** `kpi_report_version` (`content_hash`, `object_ref`, `retain_until`), `kpi_report_signature`.

**Sự kiện.** EVT-16-08 khi `PUBLISHED`.

**Lỗi và xử lý.** ERR-16-005, 006, 031, 113, 114, 124.

**Quan sát.** `dh_kpi_publish_total{result}`, `dh_kpi_render_seconds`, `dh_kpi_sign_failures_total`, `dh_kpi_integrity_mismatch_total`.
:::

Chi tiết thiết kế:

`PublishTransaction` thực hiện công bố theo thứ tự có thể phục hồi: (1) kiểm người công bố khác người lập và báo cáo còn khớp lần tổng hợp chính thức; (2) tuần tự hóa ảnh chụp JSON chuẩn hóa (khóa sắp thứ tự, số đủ 6 chữ số) và tính SHA-256; (3) dựng PDF từ mẫu HTML (OpenHTMLtoPDF) với biểu đồ SVG; (4) tính SHA-256 của PDF; (5) gọi `SigningClient` ký PAdES qua dịch vụ ký nền tảng (khóa ở OpenBao), 20 giây, một lần thử lại; (6) ghi PDF ký và JSON vào kho WORM với `retain-until` bằng ngày công bố cộng `16.report.retention-years`; (7) trong một giao dịch CSDL ngắn, đặt `PUBLISHED`, ghi băm, `object_ref`, chữ ký, outbox EVT-16-08. Các bước 1 đến 6 không giữ giao dịch CSDL; nếu hỏng giữa chừng thì báo cáo vẫn `APPROVED` và đối tượng đã ghi ở WORM là mồ côi vô hại vì khóa đối tượng dựa trên `reportId` và `versionNo` nên lần thử lại ghi cùng khóa với cùng băm (ghi trùng cùng nội dung được chấp nhận, khác nội dung bị chặn). Lỗi ký là ERR-16-031 (503), lỗi lưu WORM là ERR-16-114; cả hai không làm đổi trạng thái.

Tính an toàn của bằng chứng: bản công bố mang `contentHash` của PDF và của JSON; `IntegrityVerifier` mỗi đêm đọc lại băm trên metadata đối tượng WORM và so với CSDL (toàn bộ báo cáo công bố trong năm hiện hành, mẫu ngẫu nhiên 5% các năm trước, Q16-27); lệch tăng `dh_kpi_integrity_mismatch_total` và báo ERR-16-124 sang PH-13. Dựng PDF 50 trang, ký và lưu WORM đặt mục tiêu ≤ 2 phút p95 (NFR-16-009); PDF dựng ở một luồng riêng có giới hạn bộ nhớ và hai việc đồng thời mỗi bản sao.

### 4.10. Xuất, phân phối và API đọc (`exportdist`)

::: dac-ta
**Mục đích.** Xuất báo cáo và bảng chỉ tiêu ra PDF, XLSX, CSV, JSON; gửi báo cáo đã công bố cho danh sách người nhận theo kỳ; cung cấp API đọc `kpi.read` cho PH-17 và hệ khác.

**Lớp chính.** `ExportRunner`, `XlsxWriter`, `CsvWriter`, `ExportLinkService`, `DistributionService`, `DistributionScheduler`, `DeliverySender`, `FeedController`.

**Đơn vị chạy.** `dh-platform` hồ sơ `worker` (xuất, gửi); hồ sơ `api` (API đọc, tải).

**FR hiện thực.** FR-16-033, 034, 035; BR-16-026.

**Giao diện vào.** API-16-079…085 (xuất, tải tệp, phân phối, nhật ký gửi), API-16-086, 087 (feed giá trị, báo cáo); sự kiện EVT-16-08 kích hoạt phân phối.

**Phụ thuộc ra.** Apache POI (XLSX), Ceph RGW bucket `kpi-exports`, PH-13 (kênh thông báo, thư điện tử công vụ).

**Dữ liệu.** `kpi_export_job`, `kpi_distribution`, `kpi_delivery`.

**Sự kiện.** EVT-16-13 khi xuất xong hoặc lỗi.

**Lỗi và xử lý.** ERR-16-034, 035, 036, 037, 115, 116.

**Quan sát.** `dh_kpi_export_total{format,result}`, `dh_kpi_export_seconds{format}`, `dh_kpi_delivery_total{result}`.
:::

Chi tiết thiết kế:

Xuất chạy bất đồng bộ: API trả `202` với `exportId`; `ExportRunner` nhận việc `QUEUED → RUNNING`, đọc theo con trỏ phân trang (không nạp cả tập), ghi XLSX bằng POI chế độ luồng (`SXSSFWorkbook`, cửa sổ 1.000 dòng) để 100.000 dòng đạt ≤ 3 phút và CSV ≤ 1 phút (NFR-16-010), vượt `16.export.max-rows` thì ERR-16-034. Tệp ghi vào `kpi-exports/{tenant}/{exportId}`, liên kết tải có chữ ký hết hạn sau `16.export.link-hours` (mặc định 24 giờ, `EXPIRED` sau đó, ERR-16-035) và tệp xóa sau 7 ngày (BR-16-031). Ô văn bản bắt đầu bằng `=`, `+`, `-`, `@` được thêm dấu `'` chống chèn công thức.

Chỉ báo cáo `PUBLISHED` ra khỏi phân hệ qua phân phối và feed (BR-16-026); người xem chỉ thấy báo cáo trong phạm vi quyền (ERR-16-037). `DistributionScheduler` nghe EVT-16-08, chọn danh sách phân phối khớp loại báo cáo và kỳ, tạo `delivery` `PENDING` và gửi qua kênh thông báo PH-13 với liên kết hoặc tệp PDF đính kèm (`LINK`, `PDF`); lỗi gửi ghi ERR-16-116 và thử lại theo chính sách §8.4. Feed `kpi.read` trả giá trị đã công bố hoặc của kỳ `CLOSED`, có `ETag` và giới hạn 50 lượt/giây mỗi tenant (NFR-16-006).

### 4.11. Truy vấn bảng điều khiển và so sánh (`dashboard`)

::: dac-ta
**Mục đích.** Trả số liệu cho bảng điều khiển lãnh đạo (năm nhóm), chi tiết chỉ tiêu với chuỗi thời gian và truy tới quan sát, thẻ cho trang Tổng quan và so sánh liên tenant ẩn danh, đủ nhanh để mở là thấy.

**Lớp chính.** `DashboardQuery`, `SeriesQuery`, `LineageQuery`, `CardProvider`, `CrossTenantComparer`, `OpsOverview`, `DashboardCache`.

**Đơn vị chạy.** `dh-platform` hồ sơ `api`.

**FR hiện thực.** FR-16-035 (đọc), 037, 038, 039, 040, 041, 042; BR-16-007, 020.

**Giao diện vào.** API-16-089…093 (`/cards`, `/dashboard`, `/indicators/{code}/series`, `/cross-tenant/comparison`, `/ops/overview`), API-16-053, 054 (giá trị, truy nguồn); quyền `PERM-16-read`, `PERM-16-compare`.

**Phụ thuộc ra.** PostgreSQL (vai đọc `ph16_readonly`, vai `ph16_compare` cho liên tenant); Valkey (bộ đệm).

**Dữ liệu.** Đọc `kpi_indicator_value`, `kpi_group_score`, `kpi_value_lineage`, `kpi_aggregation_run`, `kpi_data_source`.

**Sự kiện.** Không.

**Lỗi và xử lý.** ERR-16-037, 038, 057.

**Quan sát.** `dh_kpi_dashboard_query_seconds{endpoint}`, `dh_kpi_dashboard_cache_hit_ratio`.
:::

Chi tiết thiết kế:

Bảng điều khiển đọc thẳng `kpi_indicator_value` có `is_current = true` và `kpi_group_score` của kỳ chọn, không tính lại; kỳ `OPEN` hiện số tạm "đến hôm nay" lấy từ lần tổng hợp mới nhất và gắn nhãn tạm (FR-16-038). Với 24 chỉ tiêu và 13 kỳ, một câu truy vấn chỉ mục (tenant, kỳ, nhóm) cộng một câu chuỗi thời gian đủ để tải ≤ 2 giây p95 cho 200 người dùng đồng thời (NFR-16-005); kết quả đệm Valkey 60 giây, khóa theo (tenant, kỳ) và xóa khi nhận EVT-16-05. Trạng thái luôn hiển thị kèm chữ và biểu tượng chứ không chỉ màu, mọi biểu đồ có bảng số thay thế (NFR-16-021). Truy nguồn (`LineageQuery`) trả từ giá trị tới danh sách quan sát và số tay, quan sát chỉ gồm số tổng hợp (BR-16-001, BR-16-028).

`CrossTenantComparer` là đường duy nhất đọc qua nhiều tenant, dùng vai CSDL `ph16_compare` không có `app.tenant_id` và chỉ đọc khung nhìn tổng hợp; chỉ trả kết quả khi có ít nhất `16.compare.min-tenants` tenant dùng cùng phiên bản mẫu (ERR-16-038, BR-16-020), tenant khác ẩn danh bằng mã giả với PU. `OpsOverview` (FR-16-042) tổng hợp trạng thái nguồn, hàng đợi lần tổng hợp và lần gần nhất cho PO và TO.

### 4.12. Sổ kiến trúc: thành phần, tự đăng ký, đối chiếu (`registry`)

::: dac-ta
**Mục đích.** Giữ danh sách thành phần kiến trúc (HTTT, API, luồng, topic, bộ điều hợp, dịch vụ nền tảng, liên kết quốc gia) luôn khớp thực tế bằng tự đăng ký từ sự kiện phân hệ nguồn, cho phép khai thủ công phần còn lại và phát hiện thành phần bị sót hoặc mồ côi.

**Lớp chính.** `ComponentService`, `AutoRegistrar`, `EventMappingRegistry`, `DependencyGraph`, `OpsStatusUpdater`, `ReconciliationJob`, `ArchExporter`.

**Đơn vị chạy.** `dh-platform` hồ sơ `worker` (tự đăng ký, đối chiếu); hồ sơ `api` (khai tay, tra cứu, `arch.register`).

**FR hiện thực.** FR-16-043, 044, 045, 046, 048, 049; BR-16-023, 025; NFR-16-015.

**Giao diện vào.** API-16-094…101 (thành phần, phiên bản, phụ thuộc, vòng đời, `POST /ingest/arch-components` với scope `arch.register`), API-16-111…113 (đối chiếu); Kafka EVT-01-03, EVT-02-05, EVT-02-06, EVT-04-07, EVT-04-09, EVT-05-08, EVT-10-01, EVT-10-04, EVT-14-01; trạng thái vận hành từ PH-13.

**Phụ thuộc ra.** API liệt kê đối tượng của phân hệ nguồn (đối chiếu), PH-13 (trạng thái vận hành), Ceph RGW (xuất).

**Dữ liệu.** `kpi_arch_component`, `kpi_arch_component_version`, `kpi_arch_dependency`; đề nghị `kpi_arch_reconciliation` (§13.6).

**Sự kiện.** EVT-16-10 khi thành phần tạo, đổi vòng đời, phiên bản hoặc `opsStatus`.

**Lỗi và xử lý.** ERR-16-039, 040, 041, 042, 056, 119, 120, 121.

**Quan sát.** `dh_arch_components{type,lifecycle}`, `dh_arch_autoregister_total{source,result}`, `dh_arch_register_lag_seconds`, `dh_arch_orphans`.
:::

Chi tiết thiết kế:

`AutoRegistrar` có bảng ánh xạ loại sự kiện sang loại thành phần cấu hình trong `EventMappingRegistry` (ví dụ EVT-02-05 → `API`, EVT-04-07 → `FLOW`, EVT-10-01 → `TOPIC`), nên thêm phân hệ nguồn không cần đổi mã. Mỗi bản tin đi qua `InboxGuard`, rồi khử trùng nghiệp vụ theo (`componentCode`, `version`, `contentHash`). Chưa có thành phần thì tạo với `origin = AUTO`, `lifecycle` theo sự kiện, `complianceLevel = NOT_ASSESSED`; đã có thì cập nhật chỉ trường nguồn quản lý (tên, vòng đời, phiên bản) và không đụng trường bổ sung của người (BR-16-023, ERR-16-040 cho sửa tay trường nguồn). Thiếu trường bắt buộc hoặc tham chiếu cha không có thì đưa vào hàng đối chiếu với ERR-16-119 chứ không chặn. `dependsOn` thành phụ thuộc `AUTO`.

`DependencyGraph` kiểm không phụ thuộc vòng bằng duyệt sâu giới hạn trên đồ thị của tenant (tối đa 10.000 nút) trước khi chấp nhận cạnh (ERR-16-041) và chặn `RETIRED` khi còn thành phần `ACTIVE` phụ thuộc. Độ trễ từ sự kiện nguồn đến lúc thành phần xuất hiện đo bằng `dh_arch_register_lag_seconds` và đặt mục tiêu p95 ≤ 60 giây (NFR-16-015). `OpsStatusUpdater` nhận trạng thái từ PH-13, mất tin quá ngưỡng thì đặt `UNKNOWN` (ERR-16-121). `ReconciliationJob` chạy Chủ nhật 03:00: gọi API liệt kê của từng nguồn, so với thành phần `AUTO` theo `sourceRef` và ghi mục `MISSING`, `ORPHAN`, `MISMATCH` (ERR-16-120); người dùng xử lý từng mục (đăng ký bổ sung, chuyển `RETIRED`, cập nhật theo nguồn, bỏ qua kèm lý do).

### 4.13. Đánh giá tuân thủ kiến trúc (`compliance`)

::: dac-ta
**Mục đích.** Xác định từng thành phần tuân thủ khung kiến trúc đến đâu theo bộ tiêu chí có phiên bản, có bằng chứng và người thứ hai xác nhận; cho miễn trừ có hạn với thành phần chưa sửa kịp.

**Lớp chính.** `CriteriaSetService`, `AssessmentService`, `LevelCalculator`, `ConfirmationService`, `WaiverService`, `WaiverExpiryJob`.

**Đơn vị chạy.** `dh-platform` hồ sơ `api`; `WaiverExpiryJob` ở hồ sơ `worker`.

**FR hiện thực.** FR-16-047; BR-16-024.

**Giao diện vào.** API-16-102…110 (bộ tiêu chí, đánh giá, `:submit`, `:confirm`, `:reject`, miễn trừ); quyền `PERM-16-arch-assess`, `PERM-16-admin`.

**Phụ thuộc ra.** `registry` (cập nhật `complianceLevel` trong cùng mô-đun `arch`), PH-18 (việc xác nhận), Ceph RGW (bằng chứng).

**Dữ liệu.** `kpi_compliance_criterion`, `kpi_compliance_assessment`, `kpi_compliance_item`, `kpi_compliance_waiver`.

**Sự kiện.** EVT-16-11 khi đánh giá `CONFIRMED`, miễn trừ, hết hạn miễn trừ.

**Lỗi và xử lý.** ERR-16-005, 007, 043, 044, 045.

**Quan sát.** `dh_arch_compliance_level{level}`, `dh_arch_assessments{state}`, `dh_arch_waivers_expiring`.
:::

Chi tiết thiết kế:

Bộ tiêu chí là cấu hình có phiên bản (mẫu theo Khung kiến trúc CPĐT 3.0, tiêu chí theo dự thảo khung quốc gia đánh dấu "dự thảo"; Q16-11) nên đổi không cần phát hành. `LevelCalculator` tính mức đề xuất: mọi tiêu chí bắt buộc `PASS` cho `COMPLIANT`; có tiêu chí bắt buộc `FAIL` cho `NON_COMPLIANT`; còn lại `PARTIAL`; tiêu chí `NA` loại khỏi tính. Chỉ đánh giá `CONFIRMED` (người xác nhận khác người lập, ERR-16-005) mới đổi `complianceLevel` của thành phần, trong một giao dịch cùng outbox EVT-16-11. Miễn trừ cần lý do ≥ 50 ký tự và hạn ≤ `16.compliance.waiver-max-days` (ERR-16-044), cần người xác nhận khác người đề nghị; `WaiverExpiryJob` chạy hằng ngày, miễn trừ hết hạn thì mức quay về kết quả `CONFIRMED` gần nhất (hoặc `NOT_ASSESSED`) và phát EVT-16-11. Tỷ lệ thành phần `ACTIVE` đã đánh giá cung cấp cho `ArchMetricsApi` (chỉ tiêu `thanh-phan-da-danh-gia-tuan-thu`).

### 4.14. Gói quốc gia qua PH-14 (`national`)

::: dac-ta
**Mục đích.** Gửi báo cáo chỉ tiêu đã công bố và sổ kiến trúc lên hệ quốc gia đúng định dạng của mẫu, đúng một lần, có biên nhận, mà PH-16 không giữ thông tin xác thực quốc gia và không gọi thẳng hệ quốc gia.

**Lớp chính.** `NationalTemplateService`, `SubmissionBuilder`, `TemplateMapper`, `SchemaValidator`, `SubmissionService`, `Pusher`, `ReceiptHandler`, `RetryScheduler`, `NationalReconciler`.

**Đơn vị chạy.** `dh-platform` hồ sơ `api` (lập, gửi tay, nhận biên nhận); hồ sơ `worker` (đẩy, thử lại, lịch gửi sổ).

**FR hiện thực.** FR-16-050, 051, 052, 053, 054; BR-16-021, 022.

**Giao diện vào.** API-16-114…126 (mẫu, gói, `:send`, `:retry`, nhật ký, `POST /internal/national/receipts`, đối soát); lịch `16.national.arch-schedule`; quyền `PERM-16-national`.

**Phụ thuộc ra.** PH-14 (nhận gói qua outbox, trả biên nhận), `arch::api.ArchSnapshotApi`, `rendersign` (ảnh chụp báo cáo đã công bố).

**Dữ liệu.** `kpi_national_template`, `kpi_national_submission`, `kpi_national_submission_log`.

**Sự kiện.** EVT-16-12 khi gói đổi trạng thái.

**Lỗi và xử lý.** ERR-16-046, 047, 048, 049, 050, 052, 117, 118, 124.

**Quan sát.** `dh_kpi_national_submission_total{type,state}`, `dh_kpi_national_send_seconds`, `dh_kpi_national_retry_total`.
:::

Chi tiết thiết kế:

Mẫu gói (`KPI_REPORT`, `ARCH_REGISTRY`) là JSON Schema cộng ánh xạ trường, có phiên bản và `ACTIVE`, nằm ngoài mã (ADR 163) vì khung quốc gia chưa ban hành (CMP-LAW-11 dự thảo, Q16-02, Q16-03). `SubmissionBuilder` dựng gói từ ảnh chụp của phiên bản báo cáo `PUBLISHED` hoặc từ `ArchSnapshotApi` bằng `TemplateMapper`, kiểm lược đồ (ERR-16-048), tính `contentHash` và kiểm trùng theo (`reportCode`, `version`, `contentHash`) hoặc (`componentCode`, `version`, `contentHash`) bằng ràng buộc duy nhất (ERR-16-049). Gói `PENDING` hiện bản xem trước; khi TA bấm gửi, giao dịch đặt `SENDING` và ghi outbox một lệnh giao PH-14 mang `submissionId`, `contentHash`, tệp gói (không mang thông tin xác thực). PH-14 xác nhận `SENT` rồi hệ quốc gia trả biên nhận `ACKNOWLEDGED` hoặc `REJECTED` (ERR-16-117); biên nhận về qua API nội bộ hoặc sự kiện EVT-14-11, EVT-14-12 và `ReceiptHandler` kiểm băm biên nhận khớp gói (ERR-16-124).

`FAILED` (ERR-16-118) tự gửi lại tối đa `16.national.retry-max` lần với giãn cách 5, 15, 45, 120, 360 phút, sau đó chờ TA gửi lại tay. Mọi bước ghi một dòng `national_submission_log` chỉ thêm (BR-16-022) cùng thời điểm, phản hồi PH-14 và mã lỗi hệ quốc gia. Toàn bộ thành phần bị chặn khi `16.national.enabled = false` (ERR-16-046). Gói sổ kiến trúc có hai chế độ `FULL` và `DELTA` (đề nghị §13.6); gói 1.000 thành phần phải dựng và giao PH-14 ≤ 5 phút (NFR-16-016).

### 4.15. Tham số, lưu giữ, kiểm toán và vận hành (`admin`)

::: dac-ta
**Mục đích.** Cho phép chỉnh tham số `16.*` theo tenant trong miền cho phép, ghi kiểm toán thao tác sang PH-13 không mất, dọn dữ liệu theo hạn lưu, duy trì phân vùng và phát chỉ số vận hành của chính PH-16.

**Lớp chính.** `SettingService`, `SettingCache`, `RetentionPurger`, `PartitionMaintenanceJob`, `OpsMetricsPublisher`, `AuditQuery`, `OutboxRelayMonitor`.

**Đơn vị chạy.** `dh-platform` hồ sơ `api` (cài đặt, tra kiểm toán); hồ sơ `worker` (dọn, phân vùng, chỉ số).

**FR hiện thực.** FR-16-055, 056, 057, 058; BR-16-010, 031, 032; NFR-16-017, 019, 020.

**Giao diện vào.** API-16-127, 128 (tham số), API-16-129 (`/audit-events`); các lịch dọn và phân vùng; quyền `PERM-16-config`, `PERM-16-audit-read`.

**Phụ thuộc ra.** PH-13 (kiểm toán, chỉ số), Prometheus, `shared.TenantSettingReader` (hiện thực cho cả `arch`).

**Dữ liệu.** `kpi_tenant_setting`, `outbox_event`, `inbox_event`.

**Sự kiện.** Không riêng; chuyển tiếp kiểm toán qua outbox.

**Lỗi và xử lý.** ERR-16-051, 122, 123, 125.

**Quan sát.** `dh_kpi_outbox_lag_seconds`, `dh_kpi_audit_backlog`, `dh_kpi_retention_rows_purged_total`, `dh_kpi_partition_missing`.
:::

Chi tiết thiết kế:

`SettingService` kiểm miền và trần theo bảng tham số của FRS §8.2 (ERR-16-051), lưu ở `kpi_tenant_setting` và nạp vào bộ đệm có TTL 15 giây nên thay đổi có hiệu lực ≤ 60 giây (NFR-16-020). Kiểm toán thao tác ghi cùng giao dịch vào `outbox_event` với loại bản ghi kiểm toán và được relay sang PH-13 theo thứ tự theo khóa `aggregate_id`, không mất khi PH-16 khởi động lại (BR-16-032); tồn đọng lớn bị báo ERR-16-123. `RetentionPurger` chạy hằng đêm: quan sát quá `16.observation.retention-months` (36) bị loại bằng `DROP PARTITION` theo tháng (ADR-047); giá trị chỉ tiêu và lần tổng hợp chính thức giữ cùng báo cáo; tệp xuất xóa sau 7 ngày; báo cáo công bố không xóa trước hạn WORM (BR-16-010). `PartitionMaintenanceJob` chạy trước đầu tháng, tạo phân vùng 3 tháng tới cho `kpi_observation`, `kpi_ingest_log`, `kpi_indicator_value`, `kpi_value_lineage`; thiếu phân vùng làm ghi lỗi ERR-16-125 nên có cảnh báo `dh_kpi_partition_missing` trước đó 7 ngày. `OpsMetricsPublisher` phát bộ chỉ số `dh_kpi_*` của chương 10 cho PH-13 (FR-16-058).

### 4.16. Thuật toán

#### 4.16.1. Gộp quan sát và chọn nguồn

`ObservationAggregator` chạy một lần cho mỗi lần tổng hợp: nạp mọi quan sát của kỳ cho tập `metricCode` mà công thức `ACTIVE` của tenant dùng (không `late`, `period_end` trong kỳ). Với mỗi (`metricCode`, `dimensionsHash`), chọn theo thứ tự: (1) nguồn `ACTIVE` hoặc `STALE` có `priority` cao nhất mà có quan sát; (2) trong cùng nguồn, quan sát mới nhất theo `received_at`; (3) gộp theo `aggregation` của chỉ tiêu (`LAST`, `SUM`, `AVG`, `P95`, `MAX`, `MIN`) trên các quan sát con trong kỳ khi nguồn gửi nhiều lần (BR-16-014). Câu truy vấn dùng `DISTINCT ON (source_id, metric_code, dims_hash) … ORDER BY received_at DESC` trên chỉ mục `ix_kpi_observation_metric`, cắt phân vùng theo `period_start`, nên một lần quét cho cả 24 chỉ tiêu. Kết quả là bảng trong bộ nhớ khóa (`metricCode`, chiều) mà `obs()` tra cứu O(1).

#### 4.16.2. Đánh giá công thức và độ đầy đủ

Đánh giá chỉ tiêu theo thứ tự phụ thuộc (chỉ tiêu dẫn xuất `derivedFrom` sau chỉ tiêu nguồn) bằng sắp xếp tô-pô, phát hiện vòng thì phiên bản bị từ chối lúc thử tính. Quy tắc của `CompletenessJudge`, áp theo thứ tự:

| Điều kiện | `completeness` | Cờ, mã | Ghi chú |
|---|---|---|---|
| Mọi biến có quan sát từ nguồn `ACTIVE`, mọi chiều bắt buộc đủ, số tay (nếu cần) `ACCEPTED` | `COMPLETE` | Không | Giá trị tính bình thường |
| Có giá trị nhưng một biến lấy từ nguồn `STALE`, hoặc thiếu một phần chiều (ví dụ 2 trên 20 sở) | `PARTIAL` | `STALE_SOURCE` hoặc `MISSING_SOURCE`, ERR-16-111 | `missing_variables` liệt kê biến |
| Số tay cần cho `MIXED` hoặc `MANUAL` chưa `ACCEPTED` | `NO_DATA` | `MANUAL_PENDING`, ERR-16-112 | Không lấy số kỳ trước |
| Thiếu biến bắt buộc, chia cho 0, quá giới hạn thời gian hoặc bước | `NO_DATA` | `FORMULA_ERROR` hoặc `MISSING_SOURCE`, ERR-16-109 | Giá trị rỗng, không điền 0 |

: Quy tắc đánh giá độ đầy đủ của chỉ tiêu

Độ đầy đủ của lần tổng hợp bằng số chỉ tiêu `COMPLETE` chia tổng chỉ tiêu `ACTIVE` của kỳ (BR-16-030). Lần là `SUCCEEDED` chỉ khi mọi chỉ tiêu `COMPLETE`; có `PARTIAL` hoặc `NO_DATA` thì `PARTIAL`, kèm `flags[]` gộp. Ví dụ: 24 chỉ tiêu, 20 `COMPLETE`, 2 `PARTIAL`, 2 `NO_DATA` cho độ đầy đủ 20/24 = 0,8333 và lần `PARTIAL`.

#### 4.16.3. Trạng thái so ngưỡng

`StatusEvaluator` so giá trị chưa làm tròn (BR-16-034) với ngưỡng theo `direction`. Với `HIGHER_BETTER`: giá trị ≥ ngưỡng `GREEN` cho `ON_TRACK`; ≥ ngưỡng `AMBER` cho `AT_RISK`; còn lại `OFF_TRACK`. Với `LOWER_BETTER` đảo bất đẳng thức. Với `TARGET_RANGE`, `GREEN` là khoảng chấp nhận và `AMBER` là dải đệm hai bên. Ví dụ KPI-01 (mục tiêu ≥ 90%, `AMBER` ≥ 70%): 92,5 cho `ON_TRACK`, 75 cho `AT_RISK`, 40 cho `OFF_TRACK`. Với `targetMode = RELATIVE_TO_BASELINE` ngưỡng quy đổi từ giá trị nền trước khi so (KPI-02: mục tiêu giảm ≥ 80% so nền 150, tức ≤ 30). `NO_DATA` giữ `NO_DATA`. Trạng thái đổi so với lần trước của cùng kỳ (hoặc kỳ trước ở lần đầu) thì ghi thay đổi và phát EVT-16-06; không phát lại khi không đổi (BR-16-017).

#### 4.16.4. Điểm nhóm, xu hướng, chênh lệch

Điểm chỉ tiêu: `ON_TRACK` 100, `AT_RISK` 50, `OFF_TRACK` 0 (BR-16-016); `NO_DATA` bị loại khỏi mẫu số. Điểm nhóm là trung bình điểm chỉ tiêu trong nhóm; `coverage` là số chỉ tiêu có số trên tổng chỉ tiêu nhóm. Điểm tổng là trung bình có trọng số của điểm nhóm, trọng số của các nhóm có điểm được chuẩn hóa lại để tổng bằng 1 và `coverage` hiển thị cạnh điểm để lãnh đạo thấy điểm dựa trên bao nhiêu chỉ tiêu. Ví dụ nhóm `VAN_HANH` có sáu chỉ tiêu: 3 `ON_TRACK`, 1 `AT_RISK`, 1 `OFF_TRACK`, 1 `NO_DATA` cho điểm (300 + 50 + 0) / 5 = 70, `coverage` 5/6. `delta` là hiệu với kỳ trước cùng loại; `deltaYoY` với cùng kỳ năm trước; `trend` là `UP` hoặc `DOWN` khi |delta| ≥ 1% giá trị kỳ trước và theo chiều tốt, ngược lại `FLAT`.

#### 4.16.5. Gộp kỳ quý, năm

Kỳ quý và năm không đọc lại quan sát mà gộp giá trị tháng con theo `aggregation` của chỉ tiêu (`AVG` cho KPI-03, `AVG` có trọng số cho KPI-15, 16, `LAST` cho số API công bố); thiếu tháng con thì `PARTIAL`, không tháng nào thì `NO_DATA`. Trọng số lấy từ biến phụ khai trong công thức (Q16-24). Nhờ vậy quý và năm cùng tái lập từ giá trị tháng đã chốt.

## 5. Biểu đồ tuần tự

Bảy sơ đồ phủ các luồng nhiều bước hoặc nhiều thành phần của FRS; mỗi sơ đồ ghi FR liên quan và một đoạn nói điểm cần chú ý.

### 5.1. Tiếp nhận sự kiện idempotent và số trễ (FR-16-010, 012, 016)

Sơ đồ cho thấy một bản tin chỉ số từ lúc Kafka giao tới khi có quan sát, gồm khử trùng bằng inbox, chuẩn hóa, kiểm hợp đồng và nhánh số trễ.

```{.mermaid caption="Tiếp nhận sự kiện idempotent, chuẩn hóa và đánh dấu số trễ (FR-16-010, 012)"}
sequenceDiagram
  participant K as Kafka
  participant C as EventObservationConsumer
  participant PG as ph16_kpi
  participant N as ObservationNormalizer
  participant L as LateDataMarker
  participant D as RecomputeDebouncer
  K->>C: bản tin EVT-08-14 kèm eventId
  C->>PG: BEGIN, INSERT inbox_event ON CONFLICT DO NOTHING
  alt eventId đã có
    C->>PG: đếm DUPLICATE, COMMIT
    C->>K: commit offset
  else bản tin mới
    C->>N: giải mã theo schemaRef, quy đơn vị và múi giờ
    N->>PG: đọc hợp đồng nguồn từ bộ đệm
    alt sai lược đồ hoặc ngoài hợp đồng
      N->>PG: ghi quan sát bị loại, ERR-16-105 hoặc 102
    else hợp lệ
      N->>L: kỳ của quan sát ở trạng thái nào
      L->>PG: INSERT kpi_observation ON CONFLICT DO NOTHING
      L->>D: kỳ COMPUTED chưa chốt thì request(period)
    end
    C->>PG: ghi kpi_ingest_log, COMMIT
    C->>K: commit offset
  end
```

Điểm cần chú ý: inbox và quan sát cùng một giao dịch nên không có quan sát mà không có dấu khử trùng; offset chỉ commit sau khi giao dịch xong, nên dừng PH-16 không mất tin (NFR-16-012). Bản tin hỏng không chặn phân vùng topic mà vào bảng bị loại để xử lý lại.

### 5.2. Tổng hợp kỳ, fail-soft và nhãn PARTIAL (FR-16-018, 019, 020, 021, 022)

Sơ đồ cho thấy một lần tổng hợp theo lịch: điều phối, gộp quan sát, đánh giá từng chỉ tiêu, ghi một lô kết quả và phát sự kiện.

```{.mermaid caption="Tổng hợp kỳ có chỉ tiêu PARTIAL và phát sự kiện (FR-16-018 đến 022)"}
sequenceDiagram
  participant S as RunDispatcher
  participant R as RunCoordinator
  participant PG as ph16_kpi
  participant A as ObservationAggregator
  participant E as IndicatorEvaluator
  participant J as CompletenessJudge
  participant T as StatusEvaluator
  participant O as OutboxWriter
  S->>PG: ShedLock, tạo run SCHEDULE QUEUED cho kỳ chưa chốt
  R->>PG: SKIP LOCKED, UPDATE state RUNNING WHERE QUEUED
  R->>A: nạp quan sát cả kỳ cho các metric của công thức ACTIVE
  A->>PG: một câu DISTINCT ON theo nguồn và chiều
  A-->>R: bảng giá trị trong bộ nhớ và nguồn đã chọn
  loop từng chỉ tiêu theo thứ tự tô-pô
    R->>E: đánh giá CEL giới hạn 50 ms
    E-->>R: giá trị, biến thiếu, danh sách nguồn dùng
    R->>J: COMPLETE, PARTIAL hoặc NO_DATA kèm cờ
    R->>T: so ngưỡng, ON_TRACK, AT_RISK, OFF_TRACK
  end
  R->>R: điểm nhóm, delta, deltaYoY, xu hướng
  R->>PG: ghi lô giá trị, lineage, điểm nhóm, is_current
  R->>PG: UPDATE run PARTIAL hoặc SUCCEEDED, completeness, flags
  R->>O: EVT-16-05 và EVT-16-06 cho chỉ tiêu đổi trạng thái
  R->>PG: COMMIT
```

Điểm cần chú ý: thiếu nguồn không làm lần tổng hợp thất bại mà cho `PARTIAL` kèm cờ; kết quả chỉ trở thành hiện hành (`is_current`) ở bước ghi cuối nên lần `FAILED` không ghi đè lần trước; EVT-16-06 chỉ phát với chỉ tiêu đổi trạng thái.

### 5.3. Duyệt và công bố bốn mắt có ký số (FR-16-028, 029)

Sơ đồ cho thấy vòng gửi duyệt, duyệt bởi người thứ hai và giao dịch công bố từ chụp ảnh đến lưu WORM.

```{.mermaid caption="Duyệt bốn mắt, ký số và công bố báo cáo (FR-16-028, 029)"}
sequenceDiagram
  actor TO as Cán bộ lập
  actor TA as Quản trị duyệt
  participant W as ReportWorkflow
  participant PG as ph16_kpi
  participant P as PublishTransaction
  participant B as OpenBao ký số
  participant S as Kho WORM
  participant O as OutboxWriter
  TO->>W: gửi duyệt báo cáo
  W->>PG: kiểm chỉ tiêu bắt buộc và thuyết minh, IN_REVIEW
  W->>O: EVT-16-07 cho PH-18
  TA->>W: duyệt
  W->>PG: kiểm TA khác người lập, UPDATE APPROVED WHERE IN_REVIEW
  TA->>P: công bố
  P->>PG: kiểm người công bố khác người lập và lần tổng hợp còn khớp
  P->>P: chụp JSON chuẩn hóa, dựng PDF, tính hai SHA-256
  P->>B: ký PDF PAdES, 20 giây
  B-->>P: PDF đã ký
  P->>S: ghi PDF ký và JSON, retain-until 10 năm
  S-->>P: object_ref, xác nhận băm
  P->>PG: UPDATE PUBLISHED WHERE APPROVED, ghi băm và chữ ký
  P->>O: EVT-16-08 cùng giao dịch
  P-->>TA: 200 kèm contentHash
```

Điểm cần chú ý: các bước dựng, ký, lưu không giữ giao dịch CSDL; nếu ký hoặc lưu lỗi thì báo cáo còn `APPROVED` và có thể công bố lại (ERR-16-031, ERR-16-114); chuyển `PUBLISHED` chỉ khi đã có đối tượng WORM với băm khớp.

### 5.4. Tính lại do số liệu trễ (FR-16-010, 023)

Sơ đồ cho thấy số liệu đến muộn làm kỳ chưa chốt được tính lại đúng một lần nhờ cửa sổ gom, và báo cáo nháp được báo số đã đổi.

```{.mermaid caption="Tính lại kỳ chưa chốt khi có số liệu trễ và gom yêu cầu (FR-16-023)"}
sequenceDiagram
  participant I as ingestevent
  participant D as RecomputeDebouncer
  participant PG as ph16_kpi
  participant Q as Bộ quét mỗi phút
  participant R as RunCoordinator
  participant O as OutboxWriter
  participant P as ReportComposer
  I->>D: request kỳ M-2026-10 vì quan sát trễ
  D->>PG: UPDATE period SET recompute_requested_at nếu đang rỗng
  I->>D: request lần hai trong 5 phút
  D->>PG: không đổi, đếm debounced
  Q->>PG: chọn kỳ có recompute_requested_at quá cửa sổ
  Q->>PG: tạo run LATE_DATA QUEUED, xóa dấu yêu cầu
  alt đã có run QUEUED hoặc RUNNING
    PG-->>Q: vi phạm chỉ mục duy nhất, giữ dấu để quét lại
  else tạo được
    R->>PG: tính như luồng tổng hợp kỳ
    R->>O: EVT-16-05 trigger LATE_DATA
  end
  O-->>P: bản nháp báo cáo của kỳ hiện dải số liệu đã tính lại
```

Điểm cần chú ý: dấu yêu cầu nằm ở CSDL nên mất Valkey không mất yêu cầu; hai yêu cầu liên tiếp chỉ sinh một lần tính; kỳ `CLOSED` không bao giờ vào luồng này (ERR-16-104, ERR-16-022). Mục tiêu hiển thị giá trị mới ≤ 10 phút kể từ lúc nhận quan sát (NFR-16-002).

### 5.5. Gửi gói quốc gia qua PH-14 (FR-16-051, 053)

Sơ đồ cho thấy lập gói, kiểm lược đồ và trùng, gửi qua outbox tới PH-14 và nhận biên nhận, kể cả nhánh lỗi kênh tự gửi lại.

```{.mermaid caption="Lập gói, gửi qua PH-14, biên nhận và thử lại (FR-16-051, 053)"}
sequenceDiagram
  actor TA as Quản trị tỉnh
  participant S as SubmissionService
  participant B as SubmissionBuilder
  participant PG as ph16_kpi
  participant O as OutboxWriter
  participant H as PH-14
  participant Q as Hệ quốc gia
  TA->>S: lập gói KPI_REPORT cho bc-thang-2026-10 phiên bản 1
  S->>B: dựng theo mẫu ACTIVE từ ảnh chụp PUBLISHED
  B->>B: kiểm lược đồ mẫu, tính contentHash
  B->>PG: INSERT PENDING, ràng buộc duy nhất mã phiên bản băm
  S-->>TA: bản xem trước
  TA->>S: gửi
  S->>PG: UPDATE SENDING WHERE PENDING, ghi log
  S->>O: lệnh giao PH-14 và EVT-16-12
  O-->>H: gói kèm submissionId và contentHash
  H->>Q: gửi theo kênh quốc gia
  alt lỗi kênh
    H-->>S: lỗi kênh
    S->>PG: FAILED, log ERR-16-118
    S->>S: RetryScheduler gửi lại 5, 15, 45 phút
  else đã gửi
    H-->>S: SENT
    Q-->>H: biên nhận hoặc từ chối
    H-->>S: ACKNOWLEDGED hoặc REJECTED
    S->>PG: cập nhật trạng thái, log, kiểm băm biên nhận
    S->>O: EVT-16-12
  end
```

Điểm cần chú ý: PH-16 không giữ thông tin xác thực quốc gia và không gọi trực tiếp; trùng gói bị chặn bằng ràng buộc duy nhất nên bấm gửi hai lần không nộp hai lần (ERR-16-049); `REJECTED` là kết luận cuối, sửa nguồn rồi lập gói mới.

### 5.6. Tự đăng ký thành phần vào sổ kiến trúc (FR-16-044, 048)

Sơ đồ cho thấy một sự kiện từ phân hệ nguồn trở thành thành phần trong sổ, kèm nhánh thiếu trường và việc đối chiếu hằng tuần.

```{.mermaid caption="Tự đăng ký thành phần kiến trúc từ sự kiện và đối chiếu hằng tuần (FR-16-044, 048)"}
sequenceDiagram
  participant K as Kafka
  participant A as AutoRegistrar
  participant G as DependencyGraph
  participant PG as ph16_kpi
  participant O as OutboxWriter
  participant J as ReconciliationJob
  participant S as API liệt kê của phân hệ nguồn
  K->>A: EVT-02-05 API công bố
  A->>PG: inbox, khử trùng theo componentCode phiên bản băm
  A->>A: ánh xạ loại sự kiện sang loại thành phần
  alt thiếu trường hoặc cha chưa có
    A->>PG: hàng đối chiếu, ERR-16-119
  else đủ
    A->>PG: tạo AUTO hoặc cập nhật trường nguồn, thêm phiên bản
    A->>G: ghi dependsOn thành phụ thuộc AUTO
    G->>PG: kiểm không vòng và không tới thành phần RETIRED
    A->>O: EVT-16-10 cùng giao dịch
  end
  J->>S: Chủ nhật 03:00 liệt kê đối tượng theo loại
  S-->>J: danh sách
  J->>PG: so với thành phần AUTO theo sourceRef
  J->>PG: ghi mục MISSING, ORPHAN, MISMATCH
```

Điểm cần chú ý: tự đăng ký chỉ cập nhật trường do nguồn quản lý; trường người bổ sung không bị ghi đè (BR-16-023). Đối chiếu là lưới an toàn cho sự kiện mất, không thay tự đăng ký.

### 5.7. Nhập số liệu tay và xác nhận bốn mắt (FR-16-014, 015)

Sơ đồ cho thấy số tay đi từ nhập kèm bằng chứng tới xác nhận bởi người khác và kích hoạt tính lại kỳ.

```{.mermaid caption="Nhập số liệu tay kèm bằng chứng và xác nhận bốn mắt (FR-16-014, 015)"}
sequenceDiagram
  actor DS as Người nhập
  actor SO as Người xác nhận
  participant M as ManualValueService
  participant E as EvidenceStore
  participant PG as ph16_kpi
  participant C as ManualConfirmationService
  participant D as RecomputeDebouncer
  participant O as OutboxWriter
  DS->>M: nhập giá trị kỳ M-2026-10
  M->>M: kiểm miền theo kind và unit, ERR-16-019
  DS->>E: tải tệp bằng chứng
  E->>PG: lưu kpi-evidence theo băm, ghi manual_evidence
  DS->>M: gửi xác nhận
  M->>PG: DRAFT thành SUBMITTED, kiểm có bằng chứng ERR-16-018
  SO->>C: chấp nhận
  C->>PG: kiểm khác người nhập và thuộc confirmerRoles
  C->>PG: UPDATE ACCEPTED WHERE SUBMITTED, một bản ACCEPTED mỗi chỉ tiêu và kỳ
  C->>O: EVT-16-04 cùng giao dịch
  C->>D: request kỳ cần tính lại
```

Điểm cần chú ý: giao dịch chấp nhận kiểm người xác nhận khác người nhập ở máy chủ; sau `ACCEPTED`, số tay mới được `engine` tính và cờ `MANUAL_PENDING` biến mất ở lần tổng hợp kế tiếp.

## 6. Đa tenant trong mã nguồn

Mọi bảng của `ph16_kpi` có `tenant_id` và RLS theo `app.tenant_id` (ADR-003, D03-10). Bộ lọc Spring Security đọc tenant từ token, đặt `TenantContext`, và `TenantSession` chạy `SET LOCAL app.tenant_id` đầu mỗi giao dịch; mã nghiệp vụ không tự thêm điều kiện `tenant_id`. Năm điểm riêng của PH-16:

1. **Tác vụ nền** (`PeriodGenerator`, `RunDispatcher`, `PullScheduler`, `FreshnessWatcher`, `ReconciliationJob`, `WaiverExpiryJob`, `RetentionPurger`, `DistributionScheduler`) lặp qua từng tenant `ACTIVE`, đặt `TenantContext` tường minh và dùng khóa ShedLock có tên kèm tenant; ngoại lệ duy nhất là `PartitionMaintenanceJob` (chỉ gọi thủ tục DDL).
2. **Kafka**: topic có tiền tố tenant (`t68.kpi.…` và topic nguồn); ràng buộc `ck_outbox_event_prefix` và `ck_inbox_event_prefix` bảo đảm tiền tố khớp `tenant_id`; bộ tiêu thụ lấy tenant từ tiền tố topic và đối chiếu với `tenantId` bản tin, lệch thì loại với ERR-16-101.
3. **Khóa và bộ đệm**: khóa Valkey có dạng `{tenant}:kpi:*`, tên ShedLock, tên đối tượng ở kho (`kpi-evidence/{tenant}/…`) đều mang tenant; bộ đệm công thức khóa theo (tenant, chỉ tiêu, phiên bản).
4. **Tenant `COMMON`**: chỉ tiêu mẫu, mẫu gói quốc gia, bộ tiêu chí mẫu nằm ở `COMMON` và đọc được bởi mọi tenant, sao chép khi kế thừa (FR-16-008); tenant kiểm thử `T90…T99` không đưa số vào chỉ tiêu tenant thật (BR-16-019).
5. **So sánh liên tenant** là đường duy nhất vượt RLS: vai `ph16_compare` chỉ đọc khung nhìn tổng hợp, có kiểm nhóm ≥ `16.compare.min-tenants` và không trả khóa tenant thật cho PU (BR-16-020).

## 7. Bảo mật

Kiểm tra quyền ở máy chủ, độc lập với giao diện: APISIX xác minh token và gọi OPA thô; `dh-platform` kiểm lại `PERM-16-*` ở từng `Controller` qua OPA và kiểm phạm vi (VW chỉ thấy báo cáo đã công bố và bảng điều khiển). Bảng dưới liệt kê các kiểm soát và ràng buộc `SEC-*` đã có (không tạo mới).

| Kiểm soát | Hiện thực | SEC |
|---|---|---|
| Xác thực, ủy quyền | OIDC qua BFF cho người; `client_credentials` cho máy với scope `kpi.ingest`, `arch.register`, `kpi.read`; mTLS nội bộ (NFR-16-018) | SEC-21, 24, 26 |
| Phân quyền theo quyền | 14 quyền `PERM-16-*` kiểm ở `Controller`, không chỉ ẩn nút; quyền gọi đi `dq.read`, `catalog:metrics-read` cấp cho tài khoản máy của PH-16 | SEC-26 |
| Tách nhiệm vụ, bốn mắt | Cặp loại trừ: người lập báo cáo khác người duyệt, công bố; người nhập số tay khác người xác nhận; người soạn định nghĩa khác người duyệt; người lập đánh giá khác người xác nhận. Kiểm trong dịch vụ và ràng buộc CSDL | SEC-28, ADR-046 |
| Không nhận dữ liệu cá nhân | Quan sát chỉ có số tổng hợp; `ContractChecker` loại `dimensions` có khóa định danh (BR-16-028); log không in giá trị | SEC-31, 32, 34 |
| Công thức do người dùng viết | CEL không có tác dụng phụ, không I/O; giới hạn 50 ms và 10.000 bước; hàm cho phép là danh sách trắng | SEC-43 |
| Bất biến bản công bố | Trigger CSDL từ chối cập nhật cột nội dung; Object Lock; kiểm băm hằng đêm | SEC-39, ADR-031 |
| Bí mật và ký số | Khóa ký ở OpenBao; không có thông tin xác thực quốc gia trong `ph16_kpi`, log, cấu hình; quét gitleaks mỗi bản phát hành (NFR-16-018) | SEC-14 |
| Kiểm toán | `AuditWriter` ghi cùng giao dịch qua outbox, chuyển PH-13 theo thứ tự; không ghi được thì từ chối thao tác ghi | SEC-37, 39 |
| Xuất tệp | Chỉ báo cáo `PUBLISHED` ra ngoài; liên kết ký hết hạn 24 giờ; tiền tố `'` chống chèn công thức; tệp xóa sau 7 ngày | SEC-45 |

: Kiểm soát bảo mật của PH-16

Hai rủi ro riêng: PH-16 là nơi tập trung số liệu điều hành nên bản công bố giả mạo gây hậu quả lớn (giảm bằng ký số, băm, WORM, kiểm băm hằng đêm), và API đẩy `kpi.ingest` có thể bị lạm dụng để đẩy số giả (giảm bằng hợp đồng nguồn theo từng `metricCode`, ERR-16-102, mỗi nguồn một tài khoản máy, nhật ký tiếp nhận).

## 8. Máy trạng thái, xử lý lỗi, thử lại và tính nhất quán

### 8.1. Bảng chuyển trạng thái

FRS mô tả sáu máy trạng thái (4.3 đến 4.9, cộng đánh giá tuân thủ và gói quốc gia). Mỗi chuyển hiện thực bằng một câu `UPDATE … WHERE state = :expected` và trả số dòng; số dòng bằng 0 nghĩa là trạng thái đã đổi, dịch vụ trả ERR-16-006 hoặc thử lại tùy ngữ cảnh. Trigger CSDL `tg_transition` là lớp bảo vệ thứ hai.

| Đối tượng | Từ → đến | Điều kiện, bảo vệ | Chỗ kiểm tra |
|---|---|---|---|
| Phiên bản định nghĩa | `DRAFT` → `PENDING_APPROVAL` | Đã thử tính đúng nội dung hiện tại (ERR-16-011), ngưỡng đơn điệu (ERR-16-010) | `VersionLifecycle` |
| | `PENDING_APPROVAL` → `ACTIVE` | Người duyệt khác người soạn, gửi (ERR-16-005); cũ thành `SUPERSEDED` cùng giao dịch | `VersionLifecycle` |
| Nguồn | `ACTIVE` → `STALE` | Quá `16.source.stale-hours` không có quan sát | `FreshnessWatcher` |
| | `ACTIVE`, `STALE` → `FAILED` | Lỗi kéo liên tiếp `16.source.fail-after` | `PullScheduler` |
| Số liệu tay | `SUBMITTED` → `ACCEPTED` | Người xác nhận khác người nhập, đúng `confirmerRoles` | `ManualConfirmationService` |
| Kỳ | `OPEN` → `COLLECTING` | Qua `endDate` | `PeriodStateAdvancer` |
| | `COMPUTED` → `CLOSED` | Có lần thành công, mandatory không `MANUAL_PENDING` (ERR-16-025); phát EVT-16-14 | `PeriodCloser` |
| | `CLOSED` → `REOPENED` | TA, lý do ≥ 50 ký tự, không báo cáo đang duyệt (ERR-16-026); phát EVT-16-14 | `PeriodCloser` |
| Lần tổng hợp | `QUEUED` → `RUNNING` | `SKIP LOCKED`; tối đa một lần hoạt động mỗi kỳ | `RunCoordinator` |
| | `RUNNING` → `FAILED` | Lỗi hệ thống hoặc quá `16.aggregate.timeout-minutes` (ERR-16-110) | `RunWatchdog` |
| Báo cáo | `DRAFT` → `IN_REVIEW` | Mandatory có số (ERR-16-029), có thuyết minh (ERR-16-030), số ký hiệu và nơi nhận (ERR-16-061) | `ReportWorkflow` |
| | `IN_REVIEW` → `APPROVED` | Người duyệt khác người lập, gửi | `ReportWorkflow` |
| | `APPROVED` → `CHANGES_REQUESTED` | Trả về soạn trước công bố, ý kiến ≥ 20 ký tự | `ReportWorkflow` |
| | `APPROVED` → `PUBLISHED` | Khác người lập; ký và lưu WORM thành công; băm khớp | `PublishTransaction` |
| Đánh giá tuân thủ | `SUBMITTED` → `CONFIRMED` | Người xác nhận khác người lập (ERR-16-005) | `AssessmentService` |
| Gói quốc gia | `PENDING` → `SENDING` | `16.national.enabled`, không trùng (ERR-16-046, 049) | `SubmissionService` |
| | `FAILED` → `SENDING` | Tự gửi lại ≤ `16.national.retry-max`, hoặc TA gửi tay (ERR-16-050) | `RetryScheduler` |

: Bảng chuyển trạng thái và nơi kiểm tra ở máy chủ

### 8.2. Outbox

Mọi sự kiện EVT-16-01…14 và bản ghi kiểm toán ghi vào `outbox_event` cùng giao dịch với thay đổi nghiệp vụ (ADR-042), nên không có sự kiện "ma" hay thay đổi không sự kiện; thứ tự theo đối tượng giữ nhờ khóa thông điệp `aggregate_id`. Debezium Outbox Event Router đẩy lên Kafka; mục tiêu trễ p95 ≤ 5 giây (NFR-16-017). Sự kiện mang mã, trạng thái, số tổng hợp, không mang nội dung báo cáo hay bằng chứng. `trace_id` ghi vào outbox để nối vết sang PH-13 và PH-17.

### 8.3. Inbox và idempotency

Sự kiện nhận khử trùng bằng `inbox_event` (khóa `tenant`, `consumer`, `event_id`) cùng giao dịch với tác động của nó. Quan sát idempotent theo (`sourceCode`, `idempotencyRef`) nên đẩy lại hay kéo lại cùng kỳ không nhân đôi; cùng tham chiếu khác giá trị là xung đột không ghi đè (BR-16-012). Yêu cầu ghi của API dùng `Idempotency-Key` hai tầng (ADR-041): bộ đệm Valkey 24 giờ và ràng buộc duy nhất ở CSDL (`idempotency_ref` của lần tổng hợp, mã gói quốc gia theo băm); cùng khóa cùng thân trả lại phản hồi cũ. Công bố và gửi quốc gia idempotent theo khóa đối tượng WORM và theo (mã, phiên bản, băm).

### 8.4. Thời gian chờ, thử lại, ngắt mạch

Bảng ghi chính sách cho từng phụ thuộc; mọi thử lại có trần và có chỉ số, không có vòng thử lại vô hạn.

| Phụ thuộc, thao tác | Thời gian chờ | Thử lại | Ngắt mạch | Khi hết cách |
|---|---|---|---|---|
| API chỉ số phân hệ nguồn | 30 giây | 3 lần, cách 1, 2, 4 phút | Theo nguồn: mở sau `16.source.fail-after` lần lỗi | `failCount` tăng, nguồn `FAILED`, chỉ tiêu `PARTIAL` (ERR-16-106, 108) |
| Kafka tiêu thụ | Do nền tảng | Tự phát lại từ offset chưa commit | Do nền tảng | Nguồn `EVENT` thành `STALE`, đọc bù khi Kafka về |
| Dịch vụ ký số OpenBao | 20 giây | 1 lần | Mở sau 5 lỗi, nửa mở 30 giây | ERR-16-031, báo cáo giữ `APPROVED` |
| Ceph RGW (WORM, bằng chứng, xuất) | 30 giây mỗi đối tượng | 3 lần, cách 2, 5, 10 giây | Mở sau 5 lỗi | ERR-16-114 chặn công bố; ERR-16-115 xuất lỗi |
| PH-14 giao gói | Do outbox | Tối đa `16.national.retry-max` lần, cách 5, 15, 45, 120, 360 phút | Không | `FAILED` chờ TA gửi lại (ERR-16-118) |
| Kênh thông báo PH-13 (phân phối) | 10 giây | 3 lần cách 1, 5, 15 phút | Mở sau 10 lỗi | `delivery` `FAILED` (ERR-16-116) |
| Valkey | 50 ms | Không | Rơi về bộ nhớ cục bộ và CSDL | Chậm hơn nhưng đúng |
| Kiểm toán sang PH-13 | Qua outbox | Relay thử lại không giới hạn có lùi | Không | Tồn đọng, cảnh báo ERR-16-123 |

: Thời gian chờ, thử lại và ngắt mạch của PH-16

### 8.5. Ánh xạ lỗi

Lỗi trả theo RFC 9457 với `code`, `traceId`, `errors[]` (D03-04-PH16). Ngoại lệ miền (`DomainException`) mang đúng mã ERR-16-nnn của FRS; ngoại lệ hạ tầng được bắt ở ranh giới thành phần và đổi thành mã runtime: hết lượt gọi API chỉ số thành ERR-16-106; nguồn lặng thành ERR-16-107; công thức lỗi hoặc quá giới hạn thành ERR-16-109 (`NO_DATA`, không làm hỏng lần tổng hợp); lần tổng hợp quá thời gian thành ERR-16-110; không dựng được PDF thành ERR-16-113; lưu WORM lỗi thành ERR-16-114; ký lỗi thành ERR-16-031 (503). Lỗi runtime không có người nhìn trực tiếp hiện ở UI-16-06, UI-16-09, UI-16-17 và chuyển PH-13. Xung đột `If-Match` thành ERR-16-004 hoặc ERR-00-428; chuyển trạng thái sai thành ERR-16-006; kỳ đã chốt thành ERR-16-022.

## 9. Cấu hình và cờ tính năng theo tenant

### 9.1. Tham số theo tenant

Hai mươi bốn khóa `16.*` của FRS §8.2 chỉnh được ở FR-16-055, kiểm miền và trần bởi `SettingService`. Bảng dưới ghi những khóa mà thiết kế dựa vào, thành phần đọc và cách áp dụng thay đổi.

| Khóa | Mặc định | Thành phần đọc | Áp dụng thay đổi |
|---|---|---|---|
| `16.period.types`, `16.period.close-day`, `16.period.auto-close` | `MONTH,QUARTER,YEAR`; 5; `true` | `PeriodGenerator`, `PeriodCloser` | Kỳ sinh sau; ngày chốt kỳ đang mở áp lần sau |
| `16.aggregate.cron`, `16.aggregate.timeout-minutes` | `0 30 1 * * *`; 15 | `RunDispatcher`, `RunWatchdog` | Lần điều phối kế tiếp |
| `16.aggregate.formula-timeout-ms` | 50 | `IndicatorEvaluator` | Lần tổng hợp mới |
| `16.source.stale-hours`, `16.source.fail-after` | 26; 3 | `FreshnessWatcher`, `PullScheduler` | Ngay (đọc mỗi nhịp) |
| `16.late-data.recompute`, `16.late-data.debounce-minutes` | `true`; 5 | `LateDataMarker`, `RecomputeDebouncer` | Ngay |
| `16.manual.evidence-required`, `16.manual.max-file-mb` | `true`; 20 | `ManualValueService`, `EvidenceStore` | Ngay |
| `16.report.four-eyes`, `16.report.signing` | `true`; `true` | `ReportWorkflow`, `PublishTransaction` | Báo cáo mới công bố |
| `16.report.retention-years`, `16.observation.retention-months` | 10; 36 | `WormStore`, `RetentionPurger` | Báo cáo mới; đêm kế tiếp |
| `16.export.link-hours`, `16.export.max-rows` | 24; 100000 | `ExportLinkService`, `ExportRunner` | Việc xuất mới |
| `16.national.enabled`, `16.national.retry-max`, `16.national.arch-schedule` | `false`; 5; `0 0 3 1 * ?` | `SubmissionService`, `RetryScheduler` | Ngay |
| `16.compare.min-tenants`, `16.compliance.waiver-max-days` | 3; 180 | `CrossTenantComparer`, `WaiverService` | Ngay |

: Tham số theo tenant mà thiết kế dựa vào

### 9.2. Cờ tính năng và cấu hình triển khai

`16.national.enabled` là cờ chính, mặc định tắt vì khung quốc gia chưa ban hành; bật theo tenant sau khi mẫu gói `ACTIVE`. Cờ nền tảng `kpi.cross-tenant.enabled` (mặc định tắt, mức C) bật so sánh liên tenant. Cấu hình triển khai: hồ sơ Spring `api` hoặc `worker`, vai CSDL `ph16_app` cho `ph16_kpi`, `ph16_readonly` cho truy vấn bảng điều khiển, `ph16_compare` chỉ cho `CrossTenantComparer`; `securityContext` không root và `readOnlyRootFilesystem`; thư mục tạm riêng có giới hạn dung lượng cho dựng PDF và xuất; tài nguyên theo §11.1.

## 10. Quan sát

Chỉ số phát ra qua Micrometer sang Prometheus, tiền tố `dh_kpi_` và `dh_arch_` (đề nghị đổi NFR-16-019 từ `kpi_` sang `dh_kpi_`, §13.6). Nhãn có bậc số lượng nhỏ; tuyệt đối không dùng giá trị quan sát, tên người hay mã thành phần làm nhãn; nhãn `source` và `indicator` chỉ ở chỉ số có bậc nhỏ (tối đa vài chục).

| Nhóm | Chỉ số | Nhãn | Dùng cho |
|---|---|---|---|
| Tiếp nhận | `dh_kpi_observations_total`, `dh_kpi_ingest_lag_seconds`, `dh_kpi_ingest_rejected_total` | `source`, `result`, `reason` | NFR-16-003, 004, 012 |
| Nguồn | `dh_kpi_source_state`, `dh_kpi_pull_duration_seconds`, `dh_kpi_pull_failures_total` | `source`, `state` | NFR-16-014; cảnh báo PH-13 |
| Tính toán | `dh_kpi_run_duration_seconds`, `dh_kpi_run_completeness`, `dh_kpi_run_queue_depth`, `dh_kpi_formula_eval_seconds`, `dh_kpi_formula_errors_total` | `trigger`, `state`, `indicator` | NFR-16-001, 002, 011 |
| Chỉ tiêu | `dh_kpi_indicator_status`, `dh_kpi_period_state` | `group`, `status`, `state` | Bảng Grafana, cảnh báo chệch |
| Báo cáo | `dh_kpi_report_state`, `dh_kpi_publish_total`, `dh_kpi_render_seconds`, `dh_kpi_sign_failures_total`, `dh_kpi_integrity_mismatch_total` | `type`, `state`, `result` | NFR-16-009, 013 |
| Xuất, phân phối | `dh_kpi_export_total`, `dh_kpi_export_seconds`, `dh_kpi_delivery_total` | `format`, `result` | NFR-16-010 |
| Bảng điều khiển | `dh_kpi_dashboard_query_seconds`, `dh_kpi_dashboard_cache_hit_ratio` | `endpoint` | NFR-16-005, 006 |
| Sổ kiến trúc | `dh_arch_components`, `dh_arch_autoregister_total`, `dh_arch_register_lag_seconds`, `dh_arch_orphans`, `dh_arch_compliance_level` | `type`, `lifecycle`, `level`, `result` | NFR-16-015 |
| Quốc gia | `dh_kpi_national_submission_total`, `dh_kpi_national_send_seconds`, `dh_kpi_national_retry_total` | `type`, `state` | NFR-16-016 |
| Sự kiện, vận hành | `dh_kpi_outbox_lag_seconds`, `dh_kpi_audit_backlog`, `dh_kpi_retention_rows_purged_total`, `dh_kpi_partition_missing` | `object` | NFR-16-017 |

: Chỉ số quan sát của PH-16

**Log** là JSON có `traceId`, `tenant`, `module = kpi` hoặc `arch`, `period`, `runId`, `sourceCode`, `reportCode`, không bao giờ có giá trị quan sát hay nội dung bằng chứng. **Trace** (NFR-00-051): span `kpi.ingest`, `kpi.pull`, `kpi.run`, `kpi.formula`, `kpi.report.publish`, `kpi.render`, `kpi.sign`, `arch.register`, `kpi.national.send`; `traceparent` ghi vào `trace_id` của outbox và truyền sang PH-13, PH-14. **Cảnh báo vận hành** (chuyển PH-13): `dh_kpi_source_state{state="FAILED"}` > 0 quá 1 giờ; `dh_kpi_run_duration_seconds` p95 > 300 s; `dh_kpi_run_completeness` < 0,8 sau ngày chốt; `dh_kpi_outbox_lag_seconds` > 5 trong 10 phút; `dh_kpi_integrity_mismatch_total` > 0; `dh_kpi_sign_failures_total` tăng; `dh_kpi_partition_missing` > 0; `dh_arch_register_lag_seconds` p95 > 60.

## 11. Hiệu năng, dung lượng, mô hình triển khai

### 11.1. Mô hình triển khai

Hai Deployment cùng ảnh: `dh-platform-api` (hai bản sao, 4 vCPU và 8 GB mỗi bản, theo điều kiện đo NFR-16) và `dh-platform-worker` (hai bản sao, dùng chung node pool của PH-13; PDF và xuất chạy trong luồng riêng có giới hạn bộ nhớ). Lịch (`RunDispatcher`, `PullScheduler`, `FreshnessWatcher`, `ReconciliationJob`) chạy ở cả hai bản sao `worker` dưới ShedLock nên chỉ một bản chạy mỗi lần. Số bản sao tối thiểu hai đáp ứng sẵn sàng ≥ 99,5% mỗi tháng của API control (NFR-16-008); mất cả `worker` không ảnh hưởng chức năng phân hệ khác vì PH-16 ở cuối dòng số liệu.

### 11.2. Ngân sách hiệu năng

Bảng chia chỉ tiêu NFR thành ngân sách cho từng đoạn của đường xử lý; số đo thật chốt ở kiểm thử hiệu năng (D05-02-PH16).

| Luồng | Chỉ tiêu NFR | Ngân sách chia nhỏ (giả định) |
|---|---|---|
| Lần tổng hợp kỳ tháng, 24 chỉ tiêu, 10 triệu quan sát một phân vùng | ≤ 5 phút (NFR-16-001) | Gộp quan sát một câu DISTINCT ON ≤ 150 giây với 4 luồng song song; 24 công thức × 50 ms trần ≤ 2 giây; ghi lô giá trị và lineage ≤ 10 giây; dư cho điều phối |
| Tính lại khi có số trễ | Giá trị mới ≤ 10 phút (NFR-16-002) | Cửa sổ gom 5 phút + hàng đợi ≤ 1 phút + lần tính ≤ 3 phút với dữ liệu điển hình |
| API đẩy `kpi.ingest`, lô 100 | p95 ≤ 300 ms, ≥ 200 quan sát/giây (NFR-16-003) | Kiểm hợp đồng bộ đệm ≤ 20 ms; chèn lô một câu `INSERT … ON CONFLICT` ≤ 150 ms |
| Tiêu thụ sự kiện | Trễ p95 ≤ 60 giây tại 50 sự kiện/giây (NFR-16-004) | Hai luồng tiêu thụ mỗi bản sao, giao dịch một bản tin ≤ 20 ms |
| Bảng điều khiển UI-16-01 | Tải ≤ 2 giây p95, 200 người dùng đồng thời (NFR-16-005) | Hai câu chỉ mục ≤ 100 ms; bộ đệm 60 giây; tải tĩnh ≤ 1 giây |
| API đọc `kpi.read` | p99 ≤ 300 ms tại 50 lượt/giây (NFR-16-006) | Một câu chỉ mục ≤ 50 ms, `ETag` |
| Công bố báo cáo 50 trang | ≤ 2 phút p95 (NFR-16-009) | Dựng PDF ≤ 60 giây; ký ≤ 20 giây; ghi WORM ≤ 20 giây; giao dịch cuối ≤ 100 ms |
| Xuất 100.000 dòng | XLSX ≤ 3 phút, CSV ≤ 1 phút (NFR-16-010) | Đọc con trỏ và ghi luồng, không nạp cả tập |
| Gói sổ kiến trúc 1.000 thành phần | ≤ 5 phút (NFR-16-016) | Đọc ảnh chụp ≤ 10 giây; ánh xạ, kiểm lược đồ ≤ 30 giây; giao outbox |

: Ngân sách hiệu năng của PH-16

### 11.3. Dung lượng

Ước lượng theo giả định GĐ16-1 đến GĐ16-3 (CSDL 0.1 §1.5 chi tiết hơn): mỗi tenant tối đa 10 triệu quan sát mỗi năm, khoảng 0,8 triệu mỗi tháng (một dòng khoảng 250 byte kèm chỉ mục, khoảng 0,3 GB mỗi tháng); 36 tháng giữ khoảng 11 GB mỗi tenant, 34 tenant khoảng 370 GB, nằm trong phạm vi `pg-core`. Giá trị chỉ tiêu: 50 chỉ tiêu × 120 kỳ × 34 tenant ≈ 200.000 dòng, không đáng kể; dòng truy nguồn tăng gấp 5 đến 20 lần số giá trị và bị chặn theo quy tắc ở 4.16 và §13.6. Báo cáo công bố tối đa 30 mỗi tenant mỗi năm, mỗi báo cáo PDF ký khoảng 2 MB cộng JSON 1 MB, giữ 10 năm khoảng 0,9 GB mỗi tenant ở kho WORM. Sổ kiến trúc tối đa 10.000 thành phần mỗi tenant, vài chục MB. Ngưỡng xem lại ClickHouse: khi `kpi_observation` vượt 50 triệu dòng mỗi tháng (Q16-54 của CSDL).

### 11.4. Phục hồi sau sự cố và vận hành

PH-16 dừng không làm mất số vì Kafka giữ 7 ngày và `inbox` khử trùng; nếu dừng lâu hơn thì đọc bù bằng API (FR-16-011). Phục hồi CSDL theo RPO và RTO của `pg-core` (D03-09); bản công bố ở WORM độc lập với CSDL và có thể đối chiếu lại băm (ERR-16-124). Chạy lại cùng dữ liệu cho cùng kết quả (NFR-16-011) nên có thể tính lại kỳ sau khi phục hồi để đối chiếu. Sổ tay vận hành gồm: xử lý nguồn `FAILED`, thiếu phân vùng, khóa ShedLock kẹt, công bố lỗi giữa chừng, tồn đọng outbox, gửi lại gói quốc gia (D06-xx do luồng tài liệu vận hành lập).

## 12. Kiểm thử

Chiến lược chia theo lớp; chi tiết ca nằm ở D05-02-PH16.

| Lớp | Nội dung | Ví dụ ca |
|---|---|---|
| Đơn vị | `FormulaCompiler`, `CompletenessJudge`, `StatusEvaluator`, `ScoreCalculator`, `TrendCalculator`, `LevelCalculator`, `DependencyGraph`, `ObservationNormalizer`, `SubmissionBuilder` | KPI-01 = 92,5 là `ON_TRACK`, 75 là `AT_RISK`; nhóm 3/1/1/1 cho điểm 70 và `coverage` 5/6; chia cho 0 cho `NO_DATA` và `FORMULA_ERROR`; phụ thuộc vòng bị chặn |
| Tái lập | Hai lần tính cùng quan sát và phiên bản | Sai số 0 (NFR-16-011); lineage đủ để dựng lại số |
| Tích hợp (Testcontainers) | PostgreSQL có RLS và phân vùng, Kafka, OpenBao dev, MinIO có Object Lock, PH-14 giả | Bản tin trùng chỉ một quan sát; kỳ đóng nhận số trễ `late`; tenant A không thấy tenant B; công bố đủ bước và ghi băm |
| Đồng thời, chịu lỗi | Hai `worker`; tắt Kafka, OpenBao, Ceph, PH-14; dừng PH-16 một giờ | Một lần tổng hợp hoạt động mỗi kỳ; tắt OpenBao thì báo cáo giữ `APPROVED`; dừng một giờ không mất, không trùng quan sát (NFR-16-012); gửi hai lần cho một gói |
| Bất biến, bốn mắt | Kiểm thử âm theo từng BR | 0 lệnh sửa thành công trên `PUBLISHED` (NFR-16-013); người lập không tự duyệt; người nhập tay không tự xác nhận |
| Hợp đồng, bảo mật | Lược đồ sự kiện Apicurio; ArchUnit; quét bí mật | EVT-16 không có nội dung báo cáo; không đường ghi nào ngoài `engine` vào `kpi_indicator_value`; 0 thông tin xác thực quốc gia (NFR-16-018) |
| Hiệu năng | k6 và dữ liệu sinh | NFR-16-001, 003, 004, 005, 006, 009, 010 trên bộ 24 chỉ tiêu, 36 kỳ, 10 triệu quan sát |

: Chiến lược kiểm thử của PH-16

Dữ liệu kiểm thử là dữ liệu sinh ở tenant `T90` đến `T99`, có nhiễu: quan sát trùng, quan sát khác giá trị cùng tham chiếu, đơn vị khác nhau, nguồn lặng, số trễ, thiếu một phần chiều. Chỉ tiêu mẫu `COMMON` dùng công thức giả định cho tới khi khung quốc gia ban hành (Q16-05).

## 13. Lộ trình hiện thực, rủi ro và câu hỏi mở

### 13.1. Lộ trình

PH-16 thuộc đợt 3, 9 người-tháng. Thứ tự theo mức ưu tiên FR (M, S, C) và phụ thuộc: tính toán cần định nghĩa và quan sát, báo cáo cần tính toán, gói quốc gia cần báo cáo công bố và sổ kiến trúc.

| Mốc | Nội dung |
|---|---|
| M1 · Lõi chỉ tiêu | `catalog`, `ingestevent`, `ingestpull`, `manual`, `engine`, `period`, `admin`; đạt NFR-16-001, 003, 004, 011, 012 |
| M2 · Bảng điều khiển và báo cáo | `dashboard`, `report`, `rendersign`, `exportdist`; đạt NFR-16-005, 009, 010, 013 |
| M3 · Sổ kiến trúc | `registry`, `compliance`; tự đăng ký từ PH-01, 02, 04, 10; đạt NFR-16-015 |
| M4 · Quốc gia, hoàn thiện | `national`, so sánh liên tenant, đối soát, mẫu `COMMON` hoàn chỉnh khi có khung quốc gia (Q16-05) |

: Lộ trình hiện thực PH-16

### 13.2. Truy vết hệ cũ

Hệ cũ không có chức năng báo cáo chỉ tiêu và sổ kiến trúc; REQ-16 là năng lực mới và D00-03 không có LGC nào do PH-16 làm chính. Truy vết gián tiếp theo FRS: LGC-APIM-026, LGC-PAY-013, LGC-PAY-020, LGC-HUB-001…004, LGC-BUS-027, LGC-NGSP-004 (bảng thống kê rời mà PH-16 nâng thành chỉ tiêu định kỳ). Ánh xạ SRS cũ FR-16-001…022 sang FR mới ở FRS mục 11.3; Backstage (ADR-006 cũ) không còn dùng.

### 13.3. Ma trận thành phần với FR và rủi ro

Ma trận cho thấy mỗi thành phần phủ FR nào; đủ 58 FR đều có nơi hiện thực.

| Thành phần | FR hiện thực chính | Bảng ghi |
|---|---|---|
| `catalog` | 001 đến 008 | `kpi_indicator_group`, `kpi_indicator`, `kpi_indicator_version`, `kpi_indicator_threshold` |
| `ingestevent` | 010, 012, 016 | `kpi_observation`, `kpi_ingest_log`, `inbox_event` |
| `ingestpull` | 009, 011, 013 | `kpi_data_source`, `kpi_source_contract` |
| `manual` | 014, 015 | `kpi_manual_value`, `kpi_manual_evidence` |
| `engine` | 003 (thử), 019, 020, 021, 022 | `kpi_indicator_value`, `kpi_value_lineage`, `kpi_group_score` |
| `period` | 017, 018, 023, 024, 042 | `kpi_reporting_period`, `kpi_aggregation_run` |
| `report` | 025 đến 028, 030 đến 032 | `kpi_report_template`, `kpi_report`, `kpi_report_version`, `kpi_report_approval` |
| `rendersign` | 029, 036 | `kpi_report_signature` |
| `exportdist` | 033, 034, 035 | `kpi_export_job`, `kpi_distribution`, `kpi_delivery` |
| `dashboard` | 037 đến 041 | Đọc các bảng giá trị |
| `registry` | 043 đến 046, 048, 049 | `kpi_arch_component`, `kpi_arch_component_version`, `kpi_arch_dependency` |
| `compliance` | 047 | `kpi_compliance_criterion`, `kpi_compliance_assessment`, `kpi_compliance_item`, `kpi_compliance_waiver` |
| `national` | 050 đến 054 | `kpi_national_template`, `kpi_national_submission`, `kpi_national_submission_log` |
| `admin` | 055 đến 058 | `kpi_tenant_setting`, `outbox_event` |

: Ma trận thành phần với FR

Sáu rủi ro chính và cách giảm thiểu:

| Mã | Rủi ro | Giảm thiểu |
|---|---|---|
| R-01 | Khung quốc gia và công thức KPI chính thức chưa ban hành, chỉ tiêu đổi sau khi đã công bố | Công thức, ngưỡng, mẫu gói là cấu hình có phiên bản; kỳ chốt giữ phiên bản cũ; đính chính bằng phiên bản báo cáo (BR-16-002, 009) |
| R-02 | Phân hệ nguồn chưa cung cấp chỉ số theo hợp đồng (PH-13, PH-20 chưa có FRS) | Fail-soft `PARTIAL`; nhập tay có bằng chứng; kéo API hằng ngày; hợp đồng nguồn ghi ở đề nghị đồng bộ |
| R-03 | Số nhập tay sai hoặc không có căn cứ | Bằng chứng bắt buộc, bốn mắt, nhãn nguồn `MANUAL` trên báo cáo |
| R-04 | Công bố lỗi giữa chừng để lại đối tượng WORM không có hàng CSDL | Khóa đối tượng định danh theo `reportId` và `versionNo`, ghi lại cùng nội dung được chấp nhận; quét đối chiếu mồ côi hằng tuần |
| R-05 | Lineage phình to với chỉ tiêu `SUM` trên nhiều quan sát | Giới hạn 200 dòng mỗi giá trị kèm cờ cắt và tóm tắt bằng điều kiện chọn; đề nghị thêm cột ở CSDL (§13.6) |
| R-06 | Khung quốc gia đòi định dạng khác dự kiến cho gói | Mẫu gói ngoài mã, thêm mẫu không cần phát hành (NFR-16-020), `16.national.enabled = false` tới khi chốt |

: Rủi ro của thiết kế PH-16

### 13.4. Quyết định kiến trúc đề xuất

Dải ADR 160 đến 164 dành cho PH-16 (D00-04 §3.1); tập này tóm tắt năm quyết định, tệp ADR do luồng tài liệu chung lập. Ba quyết định nhỏ khác chốt ở SDD, không có tệp riêng.

| Số đề xuất | Tiêu đề | Bối cảnh, quyết định, hệ quả (tóm tắt) |
|---|---|---|
| ADR 160 | Lưu chỉ tiêu và quan sát trên PostgreSQL phân vùng, không ClickHouse | Khối lượng nhỏ (24 chỉ tiêu × 36 kỳ × 34 tenant, 10 triệu quan sát mỗi tenant mỗi năm). Phân vùng tháng của kỳ, `DROP PARTITION` để dọn. Hệ quả: một công nghệ ít hơn, RLS dùng được; xem xét lại khi vượt 50 triệu dòng mỗi tháng. Thay ghi chú "ClickHouse chờ ADR" ở nền giả định |
| ADR 161 | Công thức chỉ tiêu bằng CEL trên quan sát đã chuẩn hóa | Công thức là cấu hình có phiên bản chạy được an toàn. `cel-java`, hàm `obs`, `manual`, `prev`, giới hạn 50 ms và 10.000 bước, tái lập. Hệ quả: không có công thức tùy ý (SQL, script); cần thư viện hàm chuẩn. Cùng họ ADR 085 |
| ADR 162 | Báo cáo chính thức bất biến, ký số, lưu WORM | Ảnh chụp JSON và PDF ký PAdES, SHA-256, kho Object Lock 10 năm, sửa bằng phiên bản đính chính. Hệ quả: không xóa được dù sai (chỉ rút có lý do); cần kiểm băm hằng đêm |
| ADR 163 | Gói gửi quốc gia theo mẫu cấu hình ngoài, gửi qua PH-14 | Khung quốc gia chưa ban hành nên mẫu (JSON Schema và ánh xạ) có phiên bản ngoài mã; idempotent theo mã, phiên bản, băm; không giữ thông tin xác thực quốc gia. Hệ quả: đổi khuôn không cần phát hành; PH-14 cần loại nền tảng mới |
| ADR 164 | Sổ kiến trúc tự xây trong `dh-platform`, tự đăng ký, không dùng Backstage | Tự đăng ký từ sự kiện nguồn trên PostgreSQL; `arch` độc lập `kpi` (chỉ `kpi` gọi `arch::api`). Hệ quả: không phụ thuộc Backstage; PH-15 chỉ tiêu thụ EVT-16-10 (ADR 095 đề xuất) |
| Chốt ở SDD | Dấu yêu cầu tính lại ở CSDL, không chỉ ở Valkey | Bền hơn khi mất Valkey, thêm cột `recompute_requested_at` ở kỳ (§13.6) |
| Chốt ở SDD | Hạ tầng dùng chung `platform.shared` cho outbox, inbox, kiểm toán, tham số | Để `arch` không phụ thuộc `kpi`; ArchUnit kiểm |
| Chốt ở SDD | Công bố không giữ giao dịch CSDL qua các bước ngoài (ký, WORM) | Tránh khóa lâu; phục hồi bằng khóa đối tượng định danh (§4.9) |

: Quyết định kiến trúc đề xuất cho PH-16

### 13.5. Câu hỏi mở

Mười câu hỏi sau chưa có trả lời; thiết kế dùng phương án nêu ở mục tương ứng. Q16-01…19 thuộc FRS.

| Mã | Câu hỏi | Tạm dùng |
|---|---|---|
| Q16-20 | Lịch tổng hợp do bộ lập lịch nội bộ dưới ShedLock hay do PH-18 điều phối job (PH-18 chỉ kích hoạt thêm) | Nội bộ, PH-18 chỉ nhắc việc (§4.7) |
| Q16-21 | Chỉ số của sổ kiến trúc cho chỉ tiêu `thanh-phan-da-danh-gia-tuan-thu` lấy trong tiến trình qua `ArchMetricsApi` hay qua sự kiện nội bộ để mọi nguồn cùng một đường | Trong tiến trình, hằng ngày (§4.4) |
| Q16-22 | `cel-java` có hỗ trợ ngắt giữa chừng theo chi phí không, hay chỉ dựa vào đồng hồ và giới hạn cấu trúc (cùng nghi vấn Q08-24 của PH-08) | Đồng hồ 50 ms cộng giới hạn bước, kiểm ở M1 |
| Q16-23 | Nguồn đính chính số của chính kỳ đã gửi (cùng `idempotencyRef` khác giá trị) hiện là xung đột bị loại; có cần cơ chế `supersedes` để nguồn hiệu chỉnh hợp lệ | Loại và báo ERR-16-103, xử lý tay |
| Q16-24 | Chỉ tiêu gộp quý và năm bằng `AVG` có trọng số (KPI-15, 16) lấy trọng số từ đâu: biến phụ trong công thức hay cột riêng của phiên bản | Biến phụ trong công thức (§4.16.5) |
| Q16-25 | Ký PAdES bằng chứng thư cơ quan trên OpenBao có đủ giá trị pháp lý hay cần dấu thời gian TSA và mức PAdES-LT (cùng Q16-08) | Chứng thư cơ quan, bổ sung dấu thời gian khi có TSA |
| Q16-26 | Object Lock dùng chế độ tuân thủ hay quản trị; báo cáo `WITHDRAWN` giữ nguyên bản không (cùng Q08-27) | Chế độ tuân thủ, giữ nguyên |
| Q16-27 | Kiểm băm WORM hằng đêm đọc toàn bộ hay mẫu cho báo cáo nhiều năm | Toàn bộ năm hiện hành, mẫu 5% năm trước |
| Q16-28 | Phân hệ nguồn nào chưa có API liệt kê đối tượng để đối chiếu sổ kiến trúc | Đối chiếu bỏ qua nguồn không có API, chỉ đếm từ sự kiện |
| Q16-29 | Cùng một thành phần được đăng ký từ sự kiện và từ CI qua `arch.register`: nguồn nào thắng với trường nguồn quản lý | Nguồn sự kiện thắng, CI chỉ bổ sung phiên bản và phụ thuộc |

: Câu hỏi mở của SDD PH-16

### 13.6. Đề nghị đồng bộ

> **Đợt đồng bộ chéo cuối (27/11/2026).** Các đề nghị dưới đây đã được xét; kết luận từng dòng (đã sửa, đã khớp sẵn, câu hỏi mở, không làm) ghi ở [D00-03-01 Sổ đồng bộ chéo cuối](../../00-chung/D00-03-01-so-dong-bo-cuoi.md).

Bảng dưới gộp các điểm lệch giữa CSDL 0.1 và FRS (SDD theo FRS Phụ lục A) và các đề nghị với tài liệu khác. Mỗi đề nghị do chủ tài liệu tương ứng nhận ở bản kế tiếp; SDD không tự sửa tài liệu ngoài phạm vi. Ba dòng đầu và dòng FRS đã được FRS 0.2, CSDL 0.2 xử lý ở đợt đồng bộ 26/11/2026 (FRS Phụ lục C, HT-13…18); kết quả ghi cuối ô đề nghị.

| Tài liệu | Đề nghị | Mục SDD |
|---|---|---|
| D03-03-PH16 (enum lệch FRS) | `kpi_compliance_item.result` dùng `PASS, PARTIAL, FAIL, NOT_APPLICABLE` còn FRS `PASS, FAIL, NA`; `kpi_compliance_criterion.state` và `kpi_national_template.state` dùng `RETIRED` còn FRS `SUPERSEDED`; `kpi_export_job.subject` (`REPORT_VERSION, INDICATOR_TABLE, ARCH_REGISTRY`) lệch FRS (`REPORT, INDICATOR_VALUES, OBSERVATIONS, ARCH_REGISTRY, ARCH_GRAPH`); `kpi_indicator.status` (`ACTIVE, RETIRED`) thiếu `DRAFT` của `indicator.state`; `ingest.result` thêm `REPROCESSED` (CSDL dùng cột `reprocess`); `kpi_arch_dependency` có `type` (`CALLS, PUBLISHES, SUBSCRIBES, HOSTS, DEPENDS_ON`) cùng `origin` còn FRS chỉ `kind = AUTO, MANUAL`; `kpi_national_submission.mode` (`FULL, DELTA`) cần kiểm có cột. Đã hấp thụ (HT-14): CSDL 0.2 dùng đúng Phụ lục A, `kpi_indicator.state`, `outcome` `REPROCESSED` | §4.10, 4.13, 4.14 |
| D03-03-PH16 (giá trị lệch BR) | Trọng số nhóm lưu 0…1 (tổng 1) còn BR-16-016 và ERR-16-012 nói tổng 100: thống nhất thang; `reopen_reason` kiểm ≥ 20 ký tự còn BR-16-011 đòi ≥ 50. Đã hấp thụ (CSDL 0.2): trọng số thang 0…100, `reopen_reason` ≥ 50 ký tự | §4.2, 4.7 |
| D03-03-PH16 (bảng và cột thiếu) | Thêm `shedlock`; cột `recompute_requested_at` ở `kpi_reporting_period`; bảng `kpi_arch_reconciliation` và mục lệch (EN-16-33, FR-16-048 cần xử lý từng mục); bảng lưu xem trước nhập XLSX (EN-16-13) hoặc quy ước đối tượng tạm 24 giờ; `kpi_indicator_value.lineage_truncated`, `lineage_count` cho chỉ tiêu `SUM`; trọng số biến cho gộp quý, năm (Q16-24). Đã hấp thụ một phần (CSDL 0.2, HT-19): `recompute_requested_at`, `kpi_arch_reconciliation`, `kpi_arch_recon_item`, `kpi_manual_import`, `kpi_manual_import_row`; `shedlock`, `lineage_truncated`, trọng số biến còn mở | §4.4, 4.5, 4.7, 4.12, 4.16 |
| D02-03-PH16 FRS | NFR-16-019: đổi tiền tố chỉ số `kpi_` thành `dh_kpi_` và thêm `dh_arch_*`; ghi hạ tầng dùng chung `platform.shared`; ghi `16.national.enabled` là cờ chính; thêm hạn `16.late-data` khớp bảng tham số; nhận Q16-20…29. Kết quả FRS 0.2: nhận tiền tố `dh_kpi_`, `dh_arch_` (HT-13); không nhận `platform.shared`, cờ `16.national.enabled`, hạn `16.late-data`, Q16-20…29 (HT-15…18) | §10, 9 |
| D02-08 | 14 quyền `PERM-16-*` (đọc, quản trị, duyệt, nguồn, nhập tay, chạy, báo cáo, xuất, sổ kiến trúc, đánh giá, quốc gia, so sánh, cấu hình, đọc kiểm toán) và hai scope máy `kpi.ingest`, `arch.register`, `kpi.read`; scope gọi đi `dq.read`, `catalog:metrics-read` | §7 |
| D03-02-PH14, D02-03-PH14 | Loại nền tảng mới nhận gói báo cáo và gói sổ kiến trúc từ PH-16 qua outbox, trả biên nhận cho API-16-124 hoặc sự kiện; PH-16 không giữ thông tin xác thực | §4.14 |
| D03-02-PH13, PH-20 | Hợp đồng chỉ số theo kỳ: sẵn sàng tháng, MTTD, MTTR, tỷ lệ nhật ký đủ (PH-13); thời gian khởi tạo tenant (PH-20); API liệt kê đối tượng cho phân hệ có thành phần kiến trúc | §4.4, 4.12 |
| PH-01, 02, 04, 05, 10 (SDD) | Phát đủ trường cho tự đăng ký (`componentCode`, loại, phiên bản, vòng đời, `dependsOn`, `contentHash`); API liệt kê để đối chiếu | §4.12 |
| D03-09, D03-10, D04-01 | D03-09: hai Deployment `dh-platform-api`, `dh-platform-worker`, bucket `kpi-reports` (Object Lock), `kpi-evidence`, `kpi-exports`, định cỡ dựng PDF. D03-10: schema `ph16_kpi`, vai `ph16_compare`. D04-01: quy tắc ArchUnit §3.2 (arch không import kpi) | §2, 3.2 |
| D00-04 §2, §3.2 | Dòng PH-16: SDD 0.1; chạy lại `kiem_tra_ma.py --cap-nhat-so-tra-cuu` | Sổ tra cứu |

: Đề nghị đồng bộ của SDD PH-16

## Lịch sử phiên bản

| Phiên bản | Ngày | Người | Nội dung |
|---|---|---|---|
| 0.1 | 26/11/2026 | Nhóm viết tài liệu (Claude) | Bản đầu theo K-SDD và K-TRINH-BAY: hai mô-đun `kpi` và `arch` với 14 thành phần có khối đặc tả 10 mục, bộ tính CEL, tiếp nhận quan sát idempotent, tổng hợp fail-soft, công bố bốn mắt ký số WORM, sổ kiến trúc tự đăng ký, gói quốc gia qua PH-14, bảy sơ đồ trình tự, thuật toán độ đầy đủ, trạng thái, điểm nhóm, ngân sách hiệu năng, năm ADR đề xuất 160…164, mười câu hỏi mở Q16-20…29 và phụ lục đề nghị đồng bộ các điểm lệch CSDL 0.1 với FRS |
| 0.2 | 26/11/2026 | Nhóm viết tài liệu (Claude) | Đồng bộ với FRS 0.2, CSDL 0.2: EVT-16-14 ở `PeriodCloser`; ERR-16-059 khi xác nhận số tay; ERR-16-061 và chuyển `APPROVED` → `CHANGES_REQUESTED` của báo cáo; API đẩy trả `202`, `207`, lô 1…500; xử lý lại ghi `REPROCESSED`; ghi kết quả hấp thụ ở §13.6 |
| 0.3 | 27/11/2026 | Nhóm viết tài liệu (Claude) | Đồng bộ chéo cuối: ADR 095 |
