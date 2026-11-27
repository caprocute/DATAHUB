---
ma_tai_lieu: D03-02-PH08
ten: Thiết kế chi tiết phần mềm phân hệ PH-08 Chất lượng dữ liệu
phien_ban: 0.3
ngay: 2026-11-27
trang_thai: Dự thảo
nguoi_doc: Kỹ sư dh-data, kỹ sư dữ liệu, kiến trúc sư, ATTT, SRE, hội đồng thẩm định
phan_he: PH-08
mo_ta: Thiết kế chi tiết hiện thực 61 FR của PH-08 gồm module Modulith dq với 14 thành phần có khối đặc tả 10 mục, trình biên dịch quy tắc sang SQL đẩy xuống và CEL, hồ sơ DataSketches, điều phối đo phân mảnh với ShedLock, thuật toán chấm điểm, lấy mẫu có seed, dấu vân tay lỗi, năm sơ đồ trình tự, mô hình triển khai, hiệu năng, bảo mật, quan sát và ba ADR đề xuất.
tai_lieu_lien_quan: D02-03-PH08 FRS; D03-03-PH08 CSDL; D03-04-PH08 API; D03-06-PH08 Màn hình; D03-09 Hạ tầng triển khai; D03-10 Thiết kế đa tenant
---

# D03-02-PH08 · Thiết kế chi tiết Chất lượng dữ liệu

## Tóm tắt cho hội đồng thẩm định

Tài liệu mô tả cách hiện thực 61 FR của [D02-03-PH08](../../02-yeu-cau/frs/D02-03-PH08-frs-chat-luong-du-lieu.md). Phân hệ giúp sở ngành tự đo chất lượng dữ liệu của mình theo sáu chiều (đầy đủ, chính xác, nhất quán, kịp thời, duy nhất, hợp lệ), chỉ ra bản ghi nào sai, giao chủ quản sửa ở nguồn, đo lại để kiểm chứng và lập báo cáo định kỳ, báo cáo năm cho lãnh đạo. Hệ cũ không có chức năng này nên toàn bộ là thiết kế mới. Sáu quyết định chi phối thiết kế:

1. **Một module Modulith, một kho quy tắc, hai chế độ đo.** Phân hệ là module `dq` của `dh-data` (Spring Boot 4, Spring Modulith, package `vn.datahub.data.dq`), lưu ở schema `ph08_dq` của `pg-core`. Đo lô và kiểm tra trực tuyến dùng chung một bộ quy tắc có phiên bản; lô chạy ở bộ thực thi mở rộng ngang, trực tuyến chạy trong bộ nhớ bản sao API với ngân sách 40 ms.
2. **Đẩy phép đo xuống nơi có dữ liệu, giữ một stack Java.** Quy tắc tập hợp dịch sang một câu `SELECT` đẩy xuống (pushdown) có danh sách cho phép; quy tắc mức bản ghi chạy bằng CEL (Common Expression Language, thư viện `cel-java`); hồ sơ dữ liệu dùng Apache DataSketches. Không dùng Great Expectations hay Soda (Python) (ADR 085).
3. **Điểm chỉ tính một lần, sau khi mọi tác vụ kết thúc, và không bao giờ được bịa.** Công thức điểm công khai, ảnh chụp điểm bất biến; thiếu chiều thì gắn cờ `INCOMPLETE_DIMENSIONS`, đổi trọng số thì `WEIGHTS_CHANGED`, vượt trần lưu lỗi thì `TRUNCATED`. Báo cáo năm chỉ dùng ảnh chụp đủ sáu chiều từ lần đo `FULL`.
4. **Bản ghi lỗi nhận dạng bằng dấu vân tay HMAC, không giữ giá trị Nhạy cảm.** Nhờ dấu vân tay, một lỗi được biết là mới, còn hay đã hết qua các kỳ mà không phụ thuộc phiên bản quy tắc; giá trị Nhạy cảm chỉ tồn tại ở dạng HMAC, bảng lỗi phân vùng theo tháng và lưu 13 tháng (ADR 086).
5. **Chỉ đọc dữ liệu được đo, qua đường có kiểm soát.** Bản ghi vàng qua khung nhìn hợp đồng PH-06, danh mục qua API PH-07, bảng HTTT qua kết nối PH-05 chỉ đọc (Q359, ADR-067); cấm đọc CSDL control (ADR 087). PH-08 không sửa dữ liệu nguồn.
6. **Vòng khép kín từ lỗi đến kiểm chứng.** Nhóm lỗi thành phiếu có SLA, chủ quản sửa ở nguồn, lần đo `VERIFY` xác nhận; sự kiện đi qua outbox cùng giao dịch và không mang giá trị dữ liệu; chuyển trạng thái bằng `UPDATE … WHERE status = :expected`.

Tập nêu ba ADR đề xuất ở dạng tóm tắt (085 đến 087, kèm hai quyết định chốt ở SDD thuộc 088 và 089), chín câu hỏi mở Q08-21…29 (Q08-20 đã chốt ở FRS 0.2), ma trận thành phần với FR (§13.3) và các đề nghị đồng bộ còn lại (§13.6).

## 1. Phạm vi và cách đọc

### 1.1. Mục đích và phạm vi

Tài liệu là thiết kế phần mềm đủ để kỹ sư viết mã và kiểm thử viên viết ca kiểm thử mà không phải đoán: cấu trúc gói, lớp chính, thuật toán, giao dịch, khóa, tên chỉ số. Phạm vi gồm 14 thành phần của module `dq` và hồ sơ triển khai của bộ thực thi. Ngoài phạm vi: lược đồ bảng (D03-03-PH08), API (D03-04-PH08), màn hình (D03-06-PH08), phân loại và che (PH-09), bản ghi vàng (PH-06), bảng mã (PH-07), gửi thông báo (PH-13), KPI tổng hợp (PH-16).

### 1.2. Người đọc

Kỹ sư `dh-data` đọc chương 3, 4, 5, 8; kỹ sư dữ liệu đọc 4.5, 4.7, 4.16; kiến trúc sư, ATTT đọc 2, 6, 7; SRE đọc 9 đến 11; hội đồng đọc Tóm tắt và chương 13.

### 1.3. Quy ước trong tài liệu

Mã `FR-08-nnn`, `BR-08-nnn`, `NFR-08-nnn`, `ERR-08-nnn`, `EVT-08-nn`, `API-08-nnn` lấy từ FRS; tên bảng và cột lấy từ DDL `ph08_dq.sql`. Chỉ số quan sát có tiền tố `dq_` (NFR-08-015). Số liệu giả định ghi "giả định": tỉnh `T01` quy mô vừa, 200 HTTT, khoảng 60 đối tượng đo năm đầu và 200 sau ba năm, đối tượng lớn nhất khoảng 1,5 triệu bản ghi (GĐ-06, GĐ-07 của FRS).

### 1.4. Thuật ngữ và chữ viết tắt

Tập thiết kế dùng nhiều thuật ngữ kỹ thuật như pushdown, CEL và dấu vân tay; bảng dưới giải thích từng thuật ngữ, kèm tên bảng dữ liệu khi có.

| Thuật ngữ | Giải thích |
|---|---|
| Đối tượng đo (asset) | Tập dữ liệu được đo, một trong bốn loại `MDM_DOMAIN`, `RDM_CATALOG`, `SOURCE_DATASET`, `FLOW_MESSAGE` (`dq_asset`) |
| CDE | Phần tử dữ liệu trọng yếu (critical data element), trường bắt buộc có quy tắc phủ (`dq_asset_field`) |
| Pushdown | Dịch quy tắc thành câu SQL chạy ngay ở CSDL nguồn để chỉ nhận lại số đếm, không kéo dữ liệu về |
| CEL | Common Expression Language, ngôn ngữ biểu thức không có tác dụng phụ, biên dịch trước, chạy bằng thư viện `cel-java` |
| DataSketches | Thư viện phác thảo thống kê: HLL ước lượng số giá trị khác nhau, KLL ước lượng phân vị |
| Lần đo (scan job) | Một lần áp bộ quy tắc `ACTIVE` lên một đối tượng, gồm nhiều tác vụ phân mảnh (`dq_scan_job`, `dq_scan_task`) |
| Dấu vân tay (fingerprint) | HMAC-SHA256 của đối tượng, mã quy tắc, khóa bản ghi, định danh một lỗi qua các kỳ (`dq_finding.fingerprint`) |
| FAIL_OPEN, FAIL_CLOSED | Khi phụ thuộc lỗi lúc kiểm tra trực tuyến: cho qua kèm cờ `degraded`, hoặc từ chối bằng 503 hoặc 504 |
| VERIFY | Loại kích hoạt lần đo chỉ để kiểm chứng phiếu đã sửa (`scan_trigger = VERIFY`) |
| DS, DA, DO, TA, TO, PA | Cán bộ dữ liệu, quản trị dữ liệu, tổ chức chủ quản, quản trị tenant, vận hành tenant, quản trị nền tảng (D02-08) |

: Thuật ngữ và chữ viết tắt

### 1.5. Cấu trúc tài liệu

Chương 2, 3: vị trí và cấu trúc mã; 4: mô hình miền, 14 thành phần, thuật toán; 5: năm sơ đồ trình tự; 6 đến 11: đa tenant, bảo mật, trạng thái và lỗi, cấu hình, quan sát, hiệu năng, triển khai; 12: kiểm thử; 13: lộ trình, rủi ro, ADR, câu hỏi mở, đề nghị đồng bộ.

### 1.6. Tài liệu liên quan và quyết định kiến trúc

Thiết kế dựa trên FRS, thiết kế CSDL, kiến trúc tổng thể và các quyết định kiến trúc; bảng dưới ghi từng tài liệu và phần nội dung mà tập này lấy từ đó.

| Tài liệu hoặc ADR | Nội dung dùng ở tập này |
|---|---|
| D02-03-PH08 FRS 0.2 | 61 FR, 35 BR, 20 NFR, 43 tham số, 132 API, mã lỗi, sự kiện, Phụ lục A enum |
| D03-03-PH08 CSDL 0.2 | Schema `ph08_dq`: 35 bảng, RLS, phân vùng tháng, `shedlock` |
| D03-09 | Namespace `dh-control`, định cỡ `QM-VUA`, KEDA |
| ADR-067, Q359 | Truy cập CSDL trực tiếp có kiểm soát, tài khoản chỉ đọc |
| ADR đề xuất 085…089 | Mục 13.4 |

: Tài liệu liên quan và ADR

## 2. Vị trí trong kiến trúc

### 2.1. Đơn vị triển khai và vùng mạng

`dq` là một module của DU `dh-data`, chạy ở namespace `dh-control` (vùng Z3) cùng PH-06, PH-07, PH-09 (D03-09 §4). Cùng một ảnh container chạy ba hồ sơ Spring: `api` (REST `/api/dq/v1`, kiểm tra trực tuyến, bộ lập lịch), `worker` (bộ thực thi lô, hồ sơ dữ liệu, sinh báo cáo) và hồ sơ chung của `dh-data`. Hai Deployment riêng cho phép mở rộng bộ thực thi độc lập với API mà không nhân đôi ảnh. Lưu lượng vào đi qua APISIX (Z2) với OIDC và OPA (SEC-21, 26); sự kiện đi qua Kafka (Z5) bằng Debezium Outbox Event Router của nền tảng.

Bộ thực thi là thành phần duy nhất mở kết nối tới dữ liệu được đo. `NetworkPolicy` chỉ cho đi ra PgBouncer của `pg-core`, bản sao đọc cho khung nhìn PH-06, Valkey, OpenBao, Kafka và các điểm kết nối HTTT do PH-05 cấp; không ra Internet. Tài khoản trên bản sao là vai `dq_reader` chỉ có `SELECT` trên `ph06_mdm.v_dq_{domain}` (ADR 087, Q08-08).

### 2.2. Sơ đồ thành phần

Sơ đồ dưới cho thấy các thành phần của module `dq` trong `dh-data`, bộ thực thi, và các hệ lân cận như PH-04, PH-05, PH-06, PH-07, PH-09, PH-13, PH-16 và kho đối tượng.

```{.mermaid caption="Sơ đồ thành phần của PH-08 trong dh-data và các hệ lân cận"}
flowchart TB
  subgraph Z2["Z2 · Biên"]
    AX["APISIX<br/>OIDC, OPA"]
  end
  subgraph API["dh-data · hồ sơ api (module dq)"]
    CAT["catalog<br/>đối tượng đo, CDE"]
    RUL["rule<br/>kho quy tắc, duyệt"]
    CMP["compile<br/>SQL pushdown, CEL"]
    SCN["scan<br/>lịch, điều phối"]
    INL["inline<br/>kiểm tra trực tuyến"]
    SCO["score<br/>điểm, so kỳ"]
    REM["remediation<br/>phiếu, SLA"]
    ALT["alert"]
    EVT["events, ops<br/>outbox, inbox, KPI"]
  end
  subgraph WRK["dh-data · hồ sơ worker"]
    WKR["worker<br/>thực thi lô"]
    PRF["profile<br/>DataSketches"]
    FND["finding<br/>dấu vân tay, che"]
    RPT["report<br/>PDF, XLSX, ký"]
    RDG["rdm<br/>cổng PH-07"]
  end
  subgraph Z5["Z5 · Dữ liệu"]
    PG[("pg-core<br/>ph08_dq")]
    REP[("Bản sao đọc<br/>v_dq_domain PH-06")]
    K[("Kafka t68.dq.*")]
    VK[("Valkey")]
    S3[("Garage, Ceph RGW")]
    BAO["OpenBao"]
  end
  SRC[("CSDL HTTT<br/>kết nối PH-05")]
  P04["PH-04 Kamelet dh-dq-check"]
  P06["PH-06"]
  P07["PH-07"]
  P09["PH-09"]
  P13["PH-13"]
  P16["PH-16"]
  AX --> CAT
  AX --> RUL
  AX --> INL
  AX --> REM
  P04 -->|"checks:evaluate"| AX
  P06 -->|"QualityGatePort"| INL
  RUL --> CMP
  INL --> CMP
  SCN --> WKR
  WKR --> CMP
  WKR --> FND
  WKR --> RDG
  WKR --> REP
  WKR --> SRC
  PRF --> REP
  PRF --> SRC
  SCN --> SCO
  SCO --> PG
  FND --> PG
  FND --> BAO
  RDG --> P07
  RDG --> VK
  CAT --> P09
  REM --> P06
  RPT --> S3
  EVT -->|"outbox"| PG
  PG -->|"Debezium"| K
  K --> P13
  K --> P16
  K --> SCN
```

Sơ đồ cho thấy ba đường. Đường đo lô: `scan` giao tác vụ cho `worker`, bộ thực thi lấy SQL và biểu thức đã biên dịch từ `compile`, đọc dữ liệu qua bản sao hoặc kết nối PH-05, ghi lỗi qua `finding`, rồi `score` gộp số đếm thành điểm. Đường trực tuyến: PH-04 qua APISIX (hoặc PH-06 qua cổng trong tiến trình) tới `inline`, chỉ dùng quy tắc đã biên dịch trong bộ nhớ và bộ đệm danh mục. Đường sự kiện: `events` qua outbox, Debezium, Kafka tới PH-13 và PH-16; `scan` cũng nghe Kafka để đo tăng dần.

### 2.3. Phụ thuộc với module và phân hệ khác

PH-08 gọi hoặc tiêu thụ sự kiện từ các phân hệ khác; bảng dưới ghi cách phụ thuộc vào từng phân hệ và hành vi khi phân hệ đó không khả dụng (khớp FRS §12.1).

| Phân hệ, hệ thống | Chiều | Cách phụ thuộc | Khi không khả dụng |
|---|---|---|---|
| PH-06 Dữ liệu chủ | `dq` đọc, nghe, gọi | Khung nhìn `v_dq_{domain}`, EVT-06-01…04, 10; `StewardIntakeApi` (FR-08-046) | Lần đo `FAILED` (ERR-08-105), không bịa điểm |
| PH-07 Danh mục | `dq` gọi | `RdmLookupApi` (module cùng DU), ảnh chụp ADR-053, bộ đệm Valkey | Quy tắc `SKIPPED` (ERR-08-108), trực tuyến theo `onDependencyFailure` |
| PH-05 Kết nối | `dq` gọi | API nội bộ thuê kết nối chỉ đọc, khám phá lược đồ, nhận chỉ số hồ sơ API-08-024 | Lần đo `FAILED`, chạy thử báo ERR-08-105 |
| PH-09 Quyền riêng tư | `dq` gọi | `ClassificationLookupApi` tra phân loại trường (PH-09 SDD §3.3), đệm thường tối đa 60 giây và xóa đệm khi nhận EVT-09-01; khi PH-09 không đáp ứng thì dùng bản đệm tối đa 5 phút | Coi trường chưa phân loại là `SENSITIVE` |
| PH-04 Tích hợp | gọi `dq` | `POST /checks:evaluate` qua Kamelet `dh-dq-check` | Luồng áp `onUnavailable`, đo lô không ảnh hưởng |
| PH-13, PH-16, PH-18 | `dq` phát, nhận | Sự kiện EVT-08-02…14; KPI; lịch Quartz tùy chọn | Outbox giữ và phát lại; lịch nội bộ vẫn chạy |
| PH-12 Keycloak, OPA | `dq` gọi | Xác thực, quyền, scope `dq.check`, `dq.read`, `dq.ingest` | Từ chối |
| OpenBao, Valkey, Garage, Ceph RGW | `dq` gọi | Khóa HMAC theo tenant, bộ đệm, tệp xuất, báo cáo công bố | Xem §8.4 |

: Phụ thuộc của PH-08

### 2.4. Hiện trạng mã và đường chuyển

Repo có SRS cũ (16 FR) nhưng chưa có mã `dq` và không có dữ liệu cần di trú. PH-08 thuộc đợt 3, sau PH-06, PH-07 và PH-09 vì đo bản ghi vàng cần khung nhìn của PH-06, chiều hợp lệ cần PH-07, và che giá trị cần PH-09.

## 3. Cấu trúc mã nguồn

### 3.1. Cây package

Module `dq` theo khuôn `api / internal / events` của K-SDD; mỗi thành phần ở chương 4 là một gói con của `internal`. Chỉ `api` và `events` được module khác import.

```text
vn.datahub.data.dq
  api/         # DTO và interface công khai, ví dụ InlineCheckApi, ScoreReadApi
  events/        # lược đồ sự kiện EVT-08-*, ghi qua outbox
  internal/
    catalog/     # miền, đối tượng đo, trường, CDE (FR-001…007)
    profile/     # hồ sơ dữ liệu, DataSketches (FR-008…011)
    rule/      # bộ quy tắc, phiên bản, duyệt, trọng số (FR-012…022)
    compile/     # dịch SQL pushdown, biên dịch CEL, kiểm danh sách cho phép
    scan/      # lịch, điều phối, phân mảnh, tăng dần (FR-023…025, 030)
    worker/      # thực thi tác vụ, hàng đợi tác vụ (FR-026, 031)
    rdm/       # cổng đối chiếu PH-07, bộ đệm Valkey (FR-027)
    inline/      # kiểm tra trực tuyến, bộ đệm quy tắc (FR-032…035)
    score/       # chấm điểm, so kỳ, thẻ điểm (FR-028, 029, 050, 051)
    finding/     # lỗi, dấu vân tay, che, ngoại lệ (FR-036…040)
    remediation/   # phiếu, SLA, leo thang, chuyển steward (FR-041…046)
    alert/       # quy tắc và cảnh báo (FR-047…049)
    report/      # báo cáo, PDF, XLSX, ký số (FR-052…056)
    ops/       # tham số, lưu giữ, kiểm toán, so sánh liên tenant (FR-058…061)
    outbox/      # ghi outbox, nghe inbox, đẩy KPI (FR-057)
```

### 3.2. Quy tắc phụ thuộc

Quy tắc kiểm bằng ArchUnit và `ApplicationModules.verify()` của Spring Modulith (CC-MOD-01…05 ở D04-01). Năm quy tắc đặc thù của `dq`:

1. `worker` và `inline` là hai nơi duy nhất được import `compile`; `rule` chỉ gọi `compile` qua `RuleValidator` khi lưu quy tắc.
2. Chỉ `worker` và `profile` được mở kết nối tới dữ liệu được đo (lớp `SourceReader`); `inline`, `score`, `report` không có `DataSource` nào ngoài `ph08_dq`.
3. Chỉ `finding` ghi bảng `dq_finding`; chỉ `score` ghi `dq_score_snapshot` và `dq_score_dimension`; chỉ `outbox` ghi `outbox_event`. ArchUnit cấm câu `INSERT` hay `UPDATE` vào các bảng đó ở gói khác.
4. Không có chu trình giữa `dq` và `mdm`. PH-06 gọi cổng chất lượng qua interface `QualityGatePort` do `mdm::api` định nghĩa và `dq::internal.inline` hiện thực (đảo phụ thuộc); `dq` gọi hàng đợi steward qua `mdm::api.StewardIntakeApi`. Cả hai mũi tên đều hướng từ `dq` sang `mdm`.
5. `dq` không đọc bảng vật lý của `rdm`, `mdm`, `privacy`; chỉ dùng `RdmLookupApi`, `ClassificationLookupApi`, `MaskPlanApi` (tên giao diện công bố của PH-06, PH-09) và khung nhìn hợp đồng (BR-08-004, BR-08-005).

### 3.3. Giao diện công bố

Gói `api` công bố ba interface cho module khác trong cùng DU: `InlineCheckApi.evaluate` (kiểm tra trực tuyến, cùng hiện thực với `POST /checks:evaluate`), `ScoreReadApi.latest` (điểm và kết luận gần nhất, scope `dq.read`) và `AssetLookupApi.findByCode`; cộng `DqEventSchemas` (lược đồ Avro của EVT-08-01…14 đăng ký Apicurio). Chiều ngược lại, `QualityGatePort` là SPI do `mdm::api` định nghĩa và `dq` hiện thực (FR-08-035).

### 3.4. Danh sách thành phần được đặc tả

Bảng liệt kê 14 thành phần của chương 4 (mục 4.2 đến 4.15) và lớp chính; FR hiện thực nằm ở khối đặc tả từng mục và ma trận 13.3. Mục 4.1 là mô hình miền; 4.16 là các thuật toán.

| Mục | Thành phần | Lớp chính |
|---|---|---|
| 4.2 | `catalog` · Quản lý đối tượng đo | `DomainService`, `AssetService`, `FieldService`, `SourceDiscoveryService` |
| 4.3 | `profile` · Hồ sơ dữ liệu | `ProfileRunner`, `SketchAccumulator`, `RuleSuggester`, `ExternalMetricsReceiver` |
| 4.4 | `rule` · Kho quy tắc và vòng duyệt | `RuleSetService`, `VersionLifecycle`, `ApprovalService`, `WeightConfigService`, `TemplateLibrary` |
| 4.5 | `compile` · Trình biên dịch quy tắc | `RuleCompiler`, `PushdownTranslator`, `CelCompiler`, `SqlAllowlistValidator`, `DialectAdapter` |
| 4.6 | `scan` · Lập lịch và điều phối | `ScheduleDispatcher`, `ScanPlanner`, `TaskSharder`, `ScanCoordinator`, `IncrementalCollector` |
| 4.7 | `worker` · Bộ thực thi lô | `TaskRunner`, `AggregateExecutor`, `RecordStreamExecutor`, `SourceReader`, `Sampler` |
| 4.8 | `rdm` · Cổng đối chiếu PH-07 | `CatalogSnapshotCache`, `RdmGateway`, `RdmBreaker` |
| 4.9 | `inline` · Kiểm tra trực tuyến | `InlineEvaluator`, `RuleCacheManager`, `InlineStatAggregator`, `QualityGateAdapter` |
| 4.10 | `score` · Chấm điểm và so kỳ | `ScoreCalculator`, `SnapshotWriter`, `TrendComparator`, `ScorecardService`, `DashboardQuery` |
| 4.11 | `finding` · Kho bản ghi lỗi | `FindingWriter`, `FingerprintService`, `ValueMasker`, `FindingResolver`, `WaiverService`, `FindingExporter` |
| 4.12 | `remediation` · Khắc phục và SLA | `IssueService`, `SlaClock`, `EscalationJob`, `VerifyScanTrigger`, `StewardHandoff` |
| 4.13 | `alert` · Cảnh báo | `AlertRuleEngine`, `AlertStateMachine`, `AlertPublisher` |
| 4.14 | `report` · Báo cáo | `ReportComposer`, `AnnualReadinessChecker`, `PdfRenderer`, `XlsxWriter`, `SigningClient`, `ReportDistributor` |
| 4.15 | `outbox`, `ops` · Sự kiện, tích hợp, vận hành | `OutboxWriter`, `InboxConsumer`, `KpiPublisher`, `TenantSettingService`, `RetentionPurger`, `AuditWriter`, `BenchmarkService` |

: Danh sách thành phần được đặc tả của PH-08

## 4. Thiết kế chi tiết từng thành phần

### 4.1. Mô hình miền

Mô hình miền có chín aggregate, mỗi aggregate có một lối ghi: `QualityDomain` và `Asset` (kèm trường, CDE), `RuleSet` (kèm phiên bản và quy tắc), `WeightConfig`, `ScanJob` (kèm tác vụ, kết quả quy tắc, ảnh chụp điểm), `Finding`, `Waiver`, `Issue` (kèm hoạt động), `Report` và `AlertRule`. Hình dưới là sơ đồ lớp rút gọn; bất biến (invariant) nằm ở bảng liền sau.

```{.mermaid caption="Sơ đồ lớp rút gọn của mô hình miền PH-08"}
classDiagram
  QualityDomain "1" --> "*" Asset
  Asset "1" --> "*" RuleSet
  RuleSet "1" --> "*" RuleSetVersion
  RuleSetVersion "1" --> "*" Rule
  Asset "1" --> "*" ScanJob
  ScanJob "1" --> "*" ScanTask
  ScanJob "1" --> "0..1" ScoreSnapshot
  ScanJob ..> RuleSetVersion : ghim phiên bản
  ScanJob ..> WeightConfig : ghim trọng số
  Rule "1" --> "*" Finding
  Finding "*" --> "0..1" Waiver
  Finding "*" --> "0..1" Issue
  Report "*" --> "*" ScoreSnapshot : đại diện
```

Hình cho thấy `ScanJob` là trục giữa: nó ghim phiên bản quy tắc và trọng số đã dùng nên điểm quá khứ không đổi (BR-08-008); `Finding` nối với `Rule` chứ không với phiên bản quy tắc nên dấu vân tay bền qua các phiên bản (BR-08-013).

| Aggregate | Bất biến chính | Chỗ bảo đảm |
|---|---|---|
| `Asset` | Có ít nhất một CDE mới `ACTIVE` (BR-08-031); không là schema `ph{nn}_*` (BR-08-005); mã duy nhất trong tenant | `AssetService`, ràng buộc `uq_` ở DDL |
| `RuleSet` | Tối đa một phiên bản `ACTIVE` và một bản nháp (BR-08-006); sửa nháp xóa dấu chạy thử | `VersionLifecycle`, chỉ mục duy nhất từng phần |
| `WeightConfig` | Tổng trọng số bằng 1 dung sai 0,001, mỗi trọng số trong 0…1 (BR-08-002) | `WeightConfigService`, `CHECK` ở DDL |
| `ScanJob` | Mỗi đối tượng tối đa một lần `QUEUED` hoặc `RUNNING` (BR-08-020); ghim `rule_set_version_id`, `weight_config_id`; `sample_seed` 64 bit khi lấy mẫu | `ScanPlanner` trong giao dịch có khóa tư vấn theo đối tượng |
| `ScoreSnapshot` | Bất biến sau khi ghi (BR-08-009); `official` chỉ khi `FULL`, đủ sáu chiều | `SnapshotWriter`, trigger không cho `UPDATE` |
| `Finding` | Một dòng mỗi dấu vân tay còn tồn tại; `SENSITIVE` không có giá trị rõ, không khóa rõ (BR-08-012) | `FindingWriter`, `ck_dq_finding_no_raw` |
| `Waiver` | Hạn ≤ 180 ngày, phạm vi không rỗng, bốn mắt (BR-08-021, 007) | `WaiverService`, `ApprovalService` |
| `Issue` | Chủ quản không tự xác nhận; `VERIFIED` chỉ do lần đo `VERIFY` sạch hoặc DS (BR-08-014) | `IssueService`, `VerifyScanTrigger` |
| `Report` | `PUBLISHED` bất biến, sửa bằng thu hồi và thay thế; năm chỉ công bố khi đủ điều kiện (BR-08-009, 010) | `ReportComposer`, `ck_dq_report_annual_full` |

: Aggregate và bất biến của PH-08

### 4.2. Quản lý đối tượng đo (`catalog`)

::: dac-ta
**Mục đích.** Khai báo ai chịu trách nhiệm (miền, chủ quản DO, cán bộ DS), đo cái gì (đối tượng đo bốn loại) và trường nào trọng yếu (CDE), để mọi lần đo và phiếu khắc phục có chủ rõ ràng.

**Lớp chính.** `DomainService`, `AssetService`, `FieldService`, `AssetActivationGuard`, `SourceDiscoveryService`, `ClassificationSync`.

**Đơn vị chạy.** `dh-data` hồ sơ `api`, mọi bản sao.

**FR hiện thực.** FR-08-001…007; BR-08-004, 005, 026, 031.

**Giao diện vào.** API-08-001…018 (ngoài ra API-08-024 nhận chỉ số hồ sơ của PH-05 với scope máy `dq.ingest`); `AssetLookupApi`; Kafka nghe EVT-06-10 để so lược đồ `MDM_DOMAIN`.

**Phụ thuộc ra.** PH-06 (danh sách domain và khung nhìn), PH-07 (danh sách danh mục), PH-05 (khám phá lược đồ), PH-09 (phân loại trường).

**Dữ liệu.** `dq_domain`, `dq_asset`, `dq_asset_field`, `dq_tenant_setting`.

**Sự kiện.** Không phát sự kiện riêng; thay đổi đối tượng đo ghi kiểm toán. Tiêu thụ EVT-06-10, EVT-07-03.

**Lỗi và xử lý.** ERR-08-001, 002, 008, 009, 010, 011, 012, 014, 047, 050; ERR-08-116 khi lược đồ nguồn đổi.

**Quan sát.** `dq_assets{type,status}`, `dq_asset_activation_total{result}`.
:::

Chi tiết thiết kế:

Đăng ký đối tượng đi qua `AssetActivationGuard` với kiểm tra theo loại. `MDM_DOMAIN`: domain PH-06 `ACTIVE` và có khung nhìn `ph06_mdm.v_dq_{domain}` (ERR-08-009). `RDM_CATALOG`: danh mục đã phát hành (ERR-08-010). `SOURCE_DATASET`: kết nối PH-05 `ACTIVE`, chỉ đọc, đã cấp cho `dq` (ERR-08-011), bảng không thuộc schema `ph{nn}_*` (ERR-08-012, BR-08-005); `SourceDiscoveryService` gọi API PH-05 chỉ để lấy tên cột, kiểu, khóa chính. `FLOW_MESSAGE`: lược đồ lấy từ luồng PH-04, chỉ kiểm tra trực tuyến (Q08-13), nên hồ sơ và đo lô trả ERR-08-050.

Kích hoạt đòi hỏi ít nhất một CDE (BR-08-031). `ClassificationSync` gọi PH-09 ghi `data_class` và `value_mode` (`MASKED`, `HASH_ONLY`, `PLAIN`) cho từng trường; trường chưa phân loại xác nhận được coi là `SENSITIVE` và cảnh báo ERR-08-047; chế độ che không được lỏng hơn phân loại (ERR-08-003). Nhận EVT-06-10, `catalog` so lược đồ domain mới với danh sách trường và đánh dấu trường không còn, để quy tắc liên quan báo ERR-08-116 thay vì chạy sai. Ngừng đối tượng hủy lần đo `QUEUED` và tắt lịch, lỗi đang mở giữ nguyên.

### 4.3. Hồ sơ dữ liệu (`profile`)

::: dac-ta
**Mục đích.** Cho biết dữ liệu thực tế trông thế nào trước khi viết quy tắc (tỷ lệ rỗng, số giá trị khác nhau, phân vị, mẫu phổ biến) và gợi ý quy tắc, mà không lưu giá trị gốc trường Nhạy cảm.

**Lớp chính.** `ProfileRunner`, `SketchAccumulator`, `ColumnStatsCollector`, `RuleSuggester`, `ExternalMetricsReceiver`, `ProfileValueGuard`.

**Đơn vị chạy.** `dh-data` hồ sơ `worker`; nhận chỉ số ngoài ở hồ sơ `api`.

**FR hiện thực.** FR-08-008…011; BR-08-012, 025.

**Giao diện vào.** API-08-019…024; lần hồ sơ tự chạy khi kích hoạt đối tượng (`08.profile.on-activate`).

**Phụ thuộc ra.** Bản sao PH-06, kết nối PH-05, `compile` (kiểm tra quy tắc gợi ý), PH-09.

**Dữ liệu.** `dq_profile_run`, `dq_profile_column`.

**Sự kiện.** Không.

**Lỗi và xử lý.** ERR-08-028 (đã có lần hồ sơ chạy), ERR-08-111 (lần hồ sơ thất bại), ERR-08-118 (lô chỉ số sai định dạng), ERR-08-105.

**Quan sát.** `dq_profile_runs_total{status,mode}`, `dq_profile_duration_seconds`.
:::

Chi tiết thiết kế:

`ProfileRunner` đọc một lần theo con trỏ; mỗi cột giữ một `SketchAccumulator`: `HllSketch` (lgK 14, sai số khoảng 1%, đạt NFR-08-013 ≤ 2%) cho số giá trị khác nhau, `KllDoublesSketch` (k = 200) cho phân vị 5, 25, 50, 75, 95, bộ đếm rỗng và độ dài, `ItemsSketch` cho tối đa 20 giá trị phổ biến. Với 50 cột bộ nhớ sketch dưới 50 MB, nên một lần hồ sơ chạy trong một luồng; 1 triệu dòng trong 15 phút chỉ cần khoảng 1.100 dòng mỗi giây, nên điểm nghẽn là mạng và nguồn.

`ProfileValueGuard` chặn mọi đường lộ giá trị (BR-08-012): cột `SENSITIVE` bỏ `ItemsSketch`, giá trị nhỏ nhất và lớn nhất; cột `RESTRICTED` chỉ lưu giá trị phổ biến dạng che một phần; chỉ số số học vẫn lưu vì không nhận diện được cá nhân. Chế độ `SAMPLE` dùng bộ lấy mẫu ở §4.16.2; chế độ `EXTERNAL` nhận chỉ số do PH-05 tính (FR-08-011) và kiểm định dạng (ERR-08-118). `RuleSuggester` gợi ý từ thống kê (cột không rỗng 100% gợi ý `NOT_NULL`, độ dài cố định gợi ý `LENGTH`, số giá trị khác nhau bằng số dòng gợi ý `UNIQUE_IN_ASSET`); gợi ý chỉ tạo quy tắc nguồn `SUGGESTED` ở bản nháp và phải qua chạy thử.

### 4.4. Kho quy tắc và vòng duyệt (`rule`)

::: dac-ta
**Mục đích.** Lưu bộ quy tắc có phiên bản, kiểm soát thay đổi bằng vòng nháp, chạy thử, duyệt bốn mắt, kích hoạt, và quản lý trọng số, ngưỡng, thư viện quy tắc mẫu.

**Lớp chính.** `RuleSetService`, `VersionLifecycle`, `RuleEditor`, `DryRunService`, `ApprovalService`, `VersionDiffService`, `RuleImportExport`, `WeightConfigService`, `TemplateLibrary`.

**Đơn vị chạy.** `dh-data` hồ sơ `api`; chạy thử ủy quyền cho `worker` qua hàng đợi tác vụ.

**FR hiện thực.** FR-08-012, 013, 015, 017…022; BR-08-002, 003, 006, 007, 008, 032.

**Giao diện vào.** API-08-025…053, 132 (xem trước điểm theo trọng số: `ScorePreviewService` tính lại từ ảnh chụp đầy đủ gần nhất của `score`, chỉ đọc).

**Phụ thuộc ra.** `compile` (kiểm tính hợp lệ), `catalog` (trường, CDE), `rdm` (tồn tại danh mục), `outbox`.

**Dữ liệu.** `dq_rule_set`, `dq_rule_set_version`, `dq_rule`, `dq_rule_template`, `dq_weight_config`.

**Sự kiện.** EVT-08-01 `ruleset.activated` khi phiên bản thành `ACTIVE`.

**Lỗi và xử lý.** ERR-08-002, 004, 005, 006, 015…026, 053; ERR-08-023 (trọng số), 024 (ngưỡng).

**Quan sát.** `dq_ruleset_versions{status}`, `dq_ruleset_activation_total`, `dq_dryrun_duration_seconds`.
:::

Chi tiết thiết kế:

Mọi thay đổi đi qua phiên bản mới (BR-08-006). `RuleEditor` chỉ sửa được phiên bản `DRAFT`; mỗi lần sửa, `content_hash` đổi và dấu "đã chạy thử" (băm lúc chạy thử, cột `dry_run_content_hash`) mất hiệu lực, nên gửi duyệt phải khớp hai băm, nếu không trả ERR-08-053. Khi lưu quy tắc, `RuleValidator` của `compile` kiểm: trường thuộc lược đồ (ERR-08-014), toán tử hợp chiều (ERR-08-015), tham số đúng kiểu và `exec_mode` hợp toán tử, tức `UNIQUE_*`, `CROSS_ENTITY`, `EQ_SOURCE`, `SQL_PREDICATE` chỉ `BATCH` (ERR-08-016), `IN_RDM` trỏ danh mục có thật và không tự liệt kê mã (BR-08-003, ERR-08-017), `EQ_SOURCE` có nguồn đối chiếu (ERR-08-018), CEL biên dịch được (ERR-08-019), vị từ SQL qua danh sách cho phép (ERR-08-020).

`ApprovalService` kiểm bốn mắt ở máy chủ: người duyệt khác người gửi và người soạn (ERR-08-005), theo cặp loại trừ DS và DA của D02-08. Kích hoạt trong một giao dịch: khóa `FOR UPDATE` bộ quy tắc, phiên bản `ACTIVE` cũ thành `SUPERSEDED`, bản mới thành `ACTIVE`, ghi outbox EVT-08-01; chỉ mục duy nhất từng phần `WHERE status = 'ACTIVE'` là lớp bảo vệ cuối. Phiên bản `APPROVED` hẹn giờ do `ScheduleDispatcher` kích hoạt khi tới `effective_from`. Lần đo đang chạy giữ phiên bản đã ghim lúc xếp hàng.

`WeightConfigService` kiểm `|Σ − 1| ≤ 0,001` bằng `BigDecimal`, ngưỡng `0 ≤ warn ≤ pass ≤ 100`; cấu hình phạm vi `ASSET` thắng `DOMAIN` thắng `TENANT`; mặc định 0,20/0,20/0,15/0,10/0,15/0,20 sinh sẵn khi khởi tạo tenant. Mẫu `COMMON` do PA soạn; tenant sao chép vào bộ của mình và giữ `template_code` kèm phiên bản mẫu (BR-08-032).

### 4.5. Trình biên dịch quy tắc sang SQL pushdown và CEL (`compile`)

::: dac-ta
**Mục đích.** Biến mỗi quy tắc đã lưu thành dạng chạy được và an toàn: câu SQL đẩy xuống cho quy tắc tập hợp, biểu thức CEL đã biên dịch cho quy tắc mức bản ghi, và kiểm từ chối mọi thứ ngoài danh sách cho phép.

**Lớp chính.** `RuleCompiler`, `PushdownTranslator`, `CelCompilerFacade`, `SqlAllowlistValidator`, `DialectAdapter` (`PostgresDialect`, `AnsiDialect`), `CompiledRuleSet`, `RuleValidator`.

**Đơn vị chạy.** Thư viện trong tiến trình, dùng ở `api` (xác thực, trực tuyến) và `worker` (thực thi).

**FR hiện thực.** FR-08-013, 014, 016, 026; BR-08-017, 025; ADR 085.

**Giao diện vào.** Gọi hàm từ `rule`, `worker`, `inline`; API-08-034 `rules:validate-expression`.

**Phụ thuộc ra.** `cel-java`, JSqlParser, RE2/J. Không truy cập mạng hay CSDL.

**Dữ liệu.** Không có bảng riêng; đọc `dq_rule`, `dq_asset_field`.

**Sự kiện.** Không.

**Lỗi và xử lý.** ERR-08-016, 019, 020, 107 (quy tắc lỗi khi chạy).

**Quan sát.** `dq_compile_duration_seconds{kind}`, `dq_compile_failed_total{reason}`.
:::

Chi tiết thiết kế:

`RuleCompiler.compile(version)` phân quy tắc vào hai nhóm: nhóm **A đẩy xuống** (toán tử đánh dấu đẩy xuống được, `UNIQUE_*`, `SQL_PREDICATE`) và nhóm **B mức bản ghi** (`CEL_EXPRESSION`, `CHECKSUM`, `IN_RDM`, `IN_RDM_VERSION`, `REQUIRED_IF` phức tạp, `EQ_SOURCE`, `CROSS_ENTITY`). Quy tắc `UNIQUE_*`, `CROSS_ENTITY`, `EQ_SOURCE`, `SQL_PREDICATE` chỉ chạy lô (BR-08-017), nên `RuleValidator` ép `exec_mode = BATCH` cho chúng.

**Dịch SQL.** `PushdownTranslator` dựng một câu cho mỗi tác vụ: `SELECT SUM(CASE WHEN <vi_phạm_r1> THEN 1 ELSE 0 END) AS f1, …, COUNT(*) AS n FROM <đối tượng> WHERE <khóa> >= :from AND <khóa> < :to [AND <điều kiện mẫu>]`. Dạng `SUM(CASE …)` là ANSI nên chạy ở mọi động cơ. Điều kiện vi phạm theo toán tử: `NOT_NULL` là `c IS NULL`; `NOT_EMPTY` là `c IS NULL OR TRIM(c) = ''`; `RANGE` là `c < :min OR c > :max`; `LENGTH` là `LENGTH(c) NOT BETWEEN :a AND :b`; `MAX_AGE_DAYS` là `c < :now − :n ngày`; `REGEX` dùng toán tử của động cơ; `UNIQUE_IN_ASSET` là `c IN (SELECT c FROM t GROUP BY c HAVING COUNT(*) > 1)` và chạy ở tác vụ toàn tập. Tham số luôn ràng buộc bằng `PreparedStatement`; tên cột chỉ lấy từ `dq_asset_field` đã kiểm, bao bằng dấu nháy định danh.

**Danh sách cho phép cho `SQL_PREDICATE`.** `SqlAllowlistValidator` phân tích bằng JSqlParser và chỉ chấp nhận một biểu thức boolean tham chiếu cột của chính đối tượng, hàm trong danh sách (`LENGTH`, `UPPER`, `LOWER`, `TRIM`, `SUBSTR`, `COALESCE`, `ABS`, `DATE_PART`, `CAST` kiểu cơ bản), không truy vấn con, `;`, chú thích hay hàm tự định nghĩa. Tính năng tắt mặc định (`08.rule.sql-predicate-enabled`); câu chạy trong giao dịch `READ ONLY` với `statement_timeout` 15 phút; tài khoản chỉ `SELECT` là lớp bảo vệ cuối.

**Biên dịch CEL.** `CelCompilerFacade` khai báo biến `record` kiểu `map<string, dyn>` và hàm mở rộng `matches` (RE2/J), `daysBetween`, `isIn(catalog, code)` (tra `rdm`), `checksumMst`, `checksumCccd`; biên dịch một lần mỗi phiên bản thành `CelRuntime.Program` lưu trong `CompiledRuleSet`. Giới hạn chi phí (ERR-08-019): biểu thức ≤ 2.000 ký tự, độ sâu cú pháp ≤ 32, vòng lặp macro ≤ 1.000, không lồng quá hai tầng; trực tuyến có thêm đồng hồ cứng theo `08.inline.timeout-ms` (Q08-24).

**Chạy thử (FR-08-016).** `DryRunService` chạy bộ quy tắc nháp trên mẫu tối đa `08.dryrun.max-rows` (10.000) bằng đúng `TaskRunner` ở chế độ không ghi lỗi, trả số đạt, số vi phạm và tối đa 20 ví dụ đã che; dùng chung mã với đo thật nên là bằng chứng cho phiên bản gửi duyệt.

### 4.6. Lập lịch và điều phối lần đo (`scan`)

::: dac-ta
**Mục đích.** Đưa lần đo đến đúng lúc, đúng một lần, chia thành tác vụ phân mảnh cho bộ thực thi, theo dõi tiến độ và khép lại bằng điểm; hỗ trợ đo theo lịch, theo yêu cầu, tăng dần theo sự kiện và kiểm chứng.

**Lớp chính.** `ScheduleDispatcher`, `ScanPlanner`, `TaskSharder`, `TaskQueue`, `ScanCoordinator`, `ScanWatchdog`, `IncrementalCollector`, `ScanController`.

**Đơn vị chạy.** `dh-data` hồ sơ `api`; các job định kỳ khóa bằng ShedLock; hàng đợi tác vụ trong PostgreSQL.

**FR hiện thực.** FR-08-023, 024, 025, 030, 031 (một phần); BR-08-001, 019, 020, 033.

**Giao diện vào.** API-08-054…067, 130, 131; Kafka nghe EVT-06-01…04, 10 và EVT-07-03, 05, 10; API lịch của PH-18 (tùy chọn).

**Phụ thuộc ra.** `worker` (qua bảng `dq_scan_task`), `score`, `rule` (phiên bản `ACTIVE`, trọng số hiệu lực), `outbox`.

**Dữ liệu.** `dq_schedule`, `dq_scan_job`, `dq_scan_task`, `inbox_event`, `shedlock`.

**Sự kiện.** EVT-08-02 `scan.completed`, EVT-08-03 `scan.failed` (qua `score` và `outbox`).

**Lỗi và xử lý.** ERR-08-027, 028, 029, 030, 049, 052, 106, 118, 119.

**Quan sát.** `dq_scan_jobs_total{asset_type,status,trigger}`, `dq_scan_duration_seconds`, `dq_scan_queue_depth`, `dq_scan_tasks_queued`, `dq_scan_missed_schedule_total`.
:::

Chi tiết thiết kế:

**Lập lịch.** Nguồn chân lý của lịch là `dq_schedule` (cron Quartz, múi giờ, `next_run_at`). `ScheduleDispatcher` là job `@Scheduled` mỗi phút bọc `@SchedulerLock(name = "dq-dispatch", lockAtMostFor = "50s")` để đúng một bản sao chạy mỗi nhịp; với mỗi lịch tới hạn, trong một giao dịch ngắn nó tính `next_run_at` mới và tạo `dq_scan_job` `QUEUED` qua `ScanPlanner`. Tự lập lịch có khóa thay vì chờ PH-18 (phụ thuộc mềm) để lịch tháng vẫn chạy khi PH-18 chưa sẵn sàng; PH-18 nếu có chỉ gọi `POST /scans` như bên kích hoạt thêm (Q08-20). Lịch lỡ do cả cụm ngừng được bù đúng một lần, ghi `dq_scan_missed_schedule_total`.

**Xếp hàng.** `ScanPlanner.enqueue` kiểm: đối tượng `ACTIVE` (ERR-08-050), có phiên bản quy tắc `ACTIVE` và trọng số hiệu lực (ERR-08-027), hạn mức theo yêu cầu `08.scan.manual-per-hour` bằng bộ đếm Valkey (ERR-08-052); rồi theo BR-08-020, dưới khóa `pg_advisory_xact_lock(hash(tenant, asset))` đếm lần đo `QUEUED`, `RUNNING` và theo `08.scan.duplicate-policy` xếp sau hoặc từ chối ERR-08-028. `Idempotency-Key` ghi vào `idempotency_key` (duy nhất theo tenant). Lần đo `ANNUAL` ép `FULL` (ERR-08-030); `POST /scans` chỉ nhận `scanTrigger` `MANUAL` hoặc `ANNUAL`, còn `SCHEDULE`, `EVENT`, `VERIFY` do hệ thống tạo. Thứ tự lấy khỏi hàng: `ANNUAL`, `VERIFY` trước, rồi `MANUAL`, `SCHEDULE`, `EVENT`.

**Phân mảnh và hàng đợi tác vụ.** `ScanCoordinator` (job `@SchedulerLock("dq-coordinate")` mỗi 10 giây) chọn lần đo bằng `FOR UPDATE SKIP LOCKED`, kiểm cửa sổ giờ `08.scan.window`, chuyển `RUNNING` và gọi `TaskSharder` (§4.16.4) tạo các dòng `dq_scan_task`. Hàng đợi tác vụ chính là bảng này: bộ thực thi nhận bằng `UPDATE … WHERE id = (SELECT t.id FROM dq_scan_task t JOIN dq_scan_job j ON j.id = t.scan_job_id WHERE t.status = 'QUEUED' AND t.not_before <= now() ORDER BY <ưu tiên theo scan_trigger>, t.shard_no FOR UPDATE OF t SKIP LOCKED LIMIT 1) RETURNING *`. Chọn bảng thay vì Kafka vì cần ưu tiên theo loại kích hoạt, hủy tức thời và đếm tiến độ bằng một truy vấn; thông lượng chỉ vài chục tác vụ mỗi giây. Tác vụ cập nhật `heartbeat_at` 30 giây một lần; `ScanWatchdog` trả tác vụ mất nhịp tim quá 3 phút về `QUEUED` (tối đa ba lần), hủy lần đo quá `08.scan.max-duration-hours` (ERR-08-106) hoặc chờ quá `08.scan.queue-timeout-hours` (ERR-08-119).

**Khép lần đo.** Khi `task_done = task_total`, bản sao nhận tác vụ cuối gọi `ScoreCalculator` dưới khóa dòng `dq_scan_job`; điểm chỉ tính một lần nhờ điều kiện `status = 'RUNNING'` ở câu cập nhật cuối. Hủy đặt cờ; bộ thực thi kiểm cờ giữa các lô 1.000 dòng. `etaSeconds` suy từ tốc độ xử lý của các tác vụ đã xong, rỗng khi chưa có. Chạy lại tạo lần đo mới với `rerun_of`.

**Đo tăng dần (FR-08-025).** `IncrementalCollector` nghe EVT-06-01…04 ở nhóm Kafka `dq-incremental`, khử trùng bằng `inbox_event`, gom khóa `goldenId` theo đối tượng vào bảng đệm `dq_incremental_buffer` (EN-08-31); chỉ đối tượng đã bật đo tăng dần được thu gom (API-08-130, tắt bằng API-08-131); mỗi `08.incremental.batch-window-minutes` (15) một job khóa ShedLock theo tenant và đối tượng tạo lần đo `INCREMENTAL`, `scan_trigger = EVENT` trên tập khóa. Vượt 100.000 khóa thì đánh dấu chờ lần `FULL` kế tiếp (BR-08-033). EVT-07-05, 10 tạo lần đo `INCREMENTAL` cho mọi đối tượng có quy tắc `IN_RDM` trỏ danh mục đó.

### 4.7. Bộ thực thi lô (`worker`)

::: dac-ta
**Mục đích.** Chạy từng tác vụ của lần đo: gửi câu SQL tập hợp, đọc dòng cho quy tắc mức bản ghi, tra danh mục, đánh giá, ghi lỗi và kết quả quy tắc, bảo đảm không làm nặng nguồn.

**Lớp chính.** `TaskRunner`, `AggregateExecutor`, `RecordStreamExecutor`, `SourceReader`, `ConnectionLease`, `Sampler`, `RuleResultWriter`, `SourceThrottle`.

**Đơn vị chạy.** `dh-data` hồ sơ `worker`, mở rộng ngang 2 đến 8 bản sao bằng KEDA.

**FR hiện thực.** FR-08-026, 031; BR-08-004, 019, 025.

**Giao diện vào.** Hàng đợi `dq_scan_task`; lệnh hủy qua cờ lần đo.

**Phụ thuộc ra.** Bản sao đọc PH-06, kết nối PH-05, `rdm`, `finding`, `compile`, OpenBao (khóa HMAC).

**Dữ liệu.** `dq_scan_task`, `dq_rule_result` (phân vùng tháng), đọc `dq_rule`.

**Sự kiện.** Không trực tiếp; kết quả gộp ở `scan` và `score`.

**Lỗi và xử lý.** ERR-08-105, 107, 109, 110, 116; thử lại ở §8.4.

**Quan sát.** `dq_task_duration_seconds{kind}`, `dq_rows_scanned_total{asset_type}`, `dq_source_query_seconds{kind}`, `dq_source_throttle_wait_seconds`, `dq_worker_busy`.
:::

Chi tiết thiết kế:

`TaskRunner` chạy một tác vụ qua sáu bước. (1) Lấy `ConnectionLease`: khung nhìn PH-06 dùng nhóm kết nối tới bản sao với vai `dq_reader`; `SOURCE_DATASET` xin PH-05 thuê kết nối chỉ đọc có hạn; `SourceThrottle` là bộ đếm Valkey theo `connectionCode` giữ giới hạn `08.scan.max-concurrent-per-connection` (2) toàn cụm. (2) Đặt `statement_timeout` và `default_transaction_read_only = on`. (3) `AggregateExecutor` chạy câu SQL tập hợp nhóm A, rồi với quy tắc có `failCount > 0` chạy câu lấy khóa vi phạm có `LIMIT 08.finding.max-per-rule-task`. (4) `RecordStreamExecutor` đọc dòng theo con trỏ `fetchSize` 5.000 các cột nhóm B và đánh giá từng dòng; bản ghi thiếu khóa tạo lỗi `CRITICAL` cấu trúc và bỏ qua quy tắc còn lại trên dòng đó (ERR-08-109). (5) Chuyển lô 1.000 lỗi cho `FindingWriter`. (6) `RuleResultWriter` ghi một dòng `dq_rule_result` mỗi quy tắc mỗi tác vụ rồi đặt tác vụ `SUCCEEDED`.

Gộp mọi quy tắc đẩy xuống vào một câu nên chi phí lên nguồn xấp xỉ một lần quét dải khóa cộng vài câu lấy khóa nhỏ. Quy tắc `IN_RDM` xử lý theo lô: `RdmGateway.prepare` nạp ảnh chụp tập mã vào bộ nhớ trước khi đọc dòng, đánh giá là tra tập băm, không gọi mạng từng dòng. `Sampler` chỉ áp khi `SAMPLE` (§4.16.2). Lỗi kết nối hoặc `statement_timeout` làm tác vụ về `QUEUED` với `attempt + 1` và `not_before` theo lùi 30 giây, 2 phút, 5 phút (§8.4); sau ba lần tác vụ `FAILED`, quy tắc của nó ghi `ERROR` (ERR-08-107). Tác vụ idempotent: kết quả ghi theo `(scan_task_id, rule_id)`, lỗi ghi theo dấu vân tay, nên chạy lại không nhân đôi.

### 4.8. Cổng đối chiếu PH-07 có bộ đệm Valkey (`rdm`)

::: dac-ta
**Mục đích.** Cho chiều hợp lệ đối chiếu danh mục PH-07 nhanh và chịu lỗi, không nhân bản bảng mã, và cho biết rõ khi không đối chiếu được để đánh dấu `SKIPPED` thay vì sai điểm.

**Lớp chính.** `RdmGateway`, `CatalogSnapshotCache` (L1 Caffeine, L2 Valkey), `BatchLookupClient`, `RdmBreaker`, `CatalogVersionResolver`.

**Đơn vị chạy.** Thư viện trong tiến trình `worker` và `api`.

**FR hiện thực.** FR-08-027, 031; BR-08-003; NFR-08-006.

**Giao diện vào.** Gọi hàm từ `worker`, `inline`, `rule`.

**Phụ thuộc ra.** `RdmLookupApi` của PH-07 (FR-07-026, 027, 028), Valkey.

**Dữ liệu.** Không có bảng; khóa Valkey `{tenant}:dq:rdm:{catalog}:{version}`.

**Sự kiện.** Tiêu thụ EVT-07-03, 05, 10 để làm mất hiệu lực bộ đệm.

**Lỗi và xử lý.** ERR-08-108 (PH-07 không khả dụng), ERR-08-010.

**Quan sát.** `dq_rdm_lookup_duration_seconds`, `dq_rdm_cache_hit_ratio{tier}`, `dq_rdm_breaker_state`, `dq_rdm_skipped_total{catalog}`.
:::

Chi tiết thiết kế:

Hai chế độ tra. Danh mục nhỏ hơn `08.rdm.snapshot-max-items` (200.000 mục) dùng **ảnh chụp**: tải một lần toàn bộ mã hiệu lực của phiên bản (ADR-053, FR-07-028), giữ ở L1 dạng `Set<String>` đã chuẩn hóa và ở L2 Valkey nén theo khóa có phiên bản, để các bộ thực thi và bản sao `api` chia sẻ. Danh mục lớn hơn dùng **tra lô** tối đa 500 mã mỗi lần (FR-07-027), mục tiêu 100 ms p95 (NFR-08-006). `IN_RDM` tra phiên bản hiệu lực lúc đo; `IN_RDM_VERSION` tra đúng phiên bản hay ngày hiệu lực chỉ định (FR-07-026).

`RdmBreaker` (Resilience4j) mở sau 5 lỗi liên tiếp, nửa mở sau 30 giây. Khi bộ ngắt mở hoặc hết thời gian, `RdmGateway` ném `RdmUnavailableException`: ở lô, mọi quy tắc `IN_RDM*` của tác vụ thành `SKIPPED` kèm ERR-08-108 và chiều `VALIDITY` rỗng (cờ `INCOMPLETE_DIMENSIONS`) nếu không còn quy tắc nào chạy được; ở trực tuyến, áp `onDependencyFailure`. Không có nhánh nào đoán kết quả. EVT-07-05 xóa khóa L1, L2 của danh mục; EVT-07-03 (ngừng) tạo cảnh báo cho quy tắc trỏ đến.

### 4.9. Dịch vụ kiểm tra trực tuyến p95 ≤ 50 ms (`inline`)

::: dac-ta
**Mục đích.** Cho PH-04 (luồng) và PH-06 (cổng đầu vào) kiểm một bản ghi theo bộ quy tắc của đối tượng trong ngân sách thời gian chặt, trả kết luận và danh sách vi phạm không chứa giá trị, kèm thống kê theo phút.

**Lớp chính.** `InlineCheckController`, `InlineEvaluator`, `RuleCacheManager`, `InlineDecision`, `InlineStatAggregator`, `QualityGateAdapter`, `InlineConfigService`.

**Đơn vị chạy.** `dh-data` hồ sơ `api`, mọi bản sao; không dùng worker.

**FR hiện thực.** FR-08-032…035; BR-08-016, 017, 018; NFR-08-001, 002, 005; ADR 088.

**Giao diện vào.** `POST /api/dq/v1/checks:evaluate` (API-08-068), `:evaluate-batch` (API-08-069), API-08-070…072; `QualityGatePort`.

**Phụ thuộc ra.** `compile` (chương trình đã biên dịch), `rdm` (bộ đệm), Kafka (làm mới bộ đệm), PostgreSQL (nạp bộ đệm, ghi thống kê).

**Dữ liệu.** `dq_inline_stat` (phân vùng tháng), đọc `dq_rule`, `dq_asset`.

**Sự kiện.** EVT-08-13 `check.failed` gộp theo phút.

**Lỗi và xử lý.** ERR-08-101, 102, 103, 104; ERR-00-403 (scope).

**Quan sát.** `dq_check_total{result,mode}`, `dq_check_duration_seconds`, `dq_inline_rule_cache_hit_ratio`, `dq_check_degraded_total{reason}`, `dq_inline_timeout_total`.
:::

Chi tiết thiết kế:

**Đường nóng.** Yêu cầu qua APISIX (xác thực token) tới `InlineCheckController`, kiểm scope `dq.check` trên claim đã xác minh (không gọi lại Keycloak), phân tích JSON ≤ 64 KB, lấy `CompiledInlineRuleSet` từ `RuleCacheManager` (Caffeine, khóa `(tenant, assetCode)`), đánh giá quy tắc rẻ trước đắt (null, độ dài, regex RE2/J, rồi CEL, rồi `IN_RDM` từ bộ đệm), trong luồng ảo của yêu cầu. Khi bộ đệm nóng không có truy vấn CSDL nào.

**Bộ đệm quy tắc.** Nạp lười khi trượt, làm mới ngay khi có EVT-08-01: mỗi bản sao `api` nghe topic bằng nhóm tiêu thụ riêng theo tên pod (phát tới mọi bản sao). Lớp thứ hai là vòng kiểm mỗi 15 giây phiên bản `ACTIVE` của các đối tượng trong bộ đệm; hai lớp giữ độ trễ làm mới ≤ 30 giây (NFR-08-005) kể cả khi mất sự kiện. Biên dịch CEL xảy ra khi nạp, không bao giờ trên đường nóng.

**Ngân sách độ trễ (giả định, đo khi nghiệm thu NFR-08-001).** Với ≤ 50 quy tắc không `UNIQUE_*`: kiểm scope 1 ms, phân tích JSON 1 ms, quy tắc gốc 8 ms, CEL 12 ms, `IN_RDM` từ bộ đệm 3 ms, quyết định và bộ đếm 1 ms, tuần tự hóa 1 ms; tổng khoảng 27 ms, đủ dư để p95 ≤ 50 ms. Ngân sách cứng `08.inline.timeout-ms` mặc định 40 ms: `InlineEvaluator` kiểm đồng hồ giữa các quy tắc và CEL chạy dưới `Future` có hạn; hết hạn thì áp `onDependencyFailure` (BR-08-018).

**Quyết định.** `STRICT`: lỗi `CRITICAL` hoặc `MAJOR` cho `FAIL`, chỉ `MINOR` cho `WARN`; `ADVISORY` không bao giờ `FAIL`: có vi phạm ở mức nào cũng `WARN` kèm `violations[]`, không có thì `PASS`. Lô (API-08-069) tối đa 100 bản ghi, 101 bị từ chối cả lô bằng ERR-08-101. `FAIL_OPEN` (mặc định) trả `PASS` với `degraded = true` và lý do; `FAIL_CLOSED` trả ERR-08-103 (504) hoặc ERR-08-104 (503). Phản hồi chỉ có mã quy tắc, đường dẫn trường và thông báo mẫu, không có giá trị bản ghi.

**Thống kê phút.** `InlineStatAggregator` giữ `LongAdder` theo `(đối tượng, bên gọi, chế độ, phút)` và mỗi 60 giây ghi `INSERT … ON CONFLICT DO UPDATE` cộng dồn vào `dq_inline_stat`; p50, p95 lấy từ `HdrHistogram` mỗi bản sao và khi gộp thì lấy giá trị lớn hơn (bảo thủ). Bản sao chết giữa phút mất tối đa 60 giây số đếm của nó (chấp nhận, thống kê không phải bằng chứng pháp lý). EVT-08-13 phát mỗi `(đối tượng, bên gọi)` mỗi phút có `FAIL`.

**Cổng PH-06 và Kamelet.** `QualityGateAdapter` hiện thực `QualityGatePort` bằng gọi thẳng `InlineEvaluator` trong tiến trình và ánh xạ `FAIL` thành lý do từ chối `DQ_GATE` ở PH-06 (FR-08-035). Kamelet `dh-dq-check` gọi API-08-068, đặt tiêu đề `dh-dq-verdict`, `dh-dq-violations` và áp `onFail`, `onUnavailable` của luồng (FR-08-033). Hai đường dùng chung hiện thực nên không lệch kết quả.

### 4.10. Bộ chấm điểm và so kỳ (`score`)

::: dac-ta
**Mục đích.** Quy hàng triệu phép kiểm về điểm từng chiều và điểm tổng theo công thức công khai, tái lập được; so với kỳ trước để biết xu hướng; dựng thẻ điểm và bảng điều khiển.

**Lớp chính.** `ScoreCalculator`, `DimensionScorer`, `SnapshotWriter`, `TrendComparator`, `ScorecardService`, `DashboardQuery`, `CurrentScoreMerger`.

**Đơn vị chạy.** `dh-data` hồ sơ `api` (gọi từ bản sao nhận tác vụ cuối); đọc bảng điều khiển ở mọi bản sao.

**FR hiện thực.** FR-08-028, 029, 050, 051; BR-08-008, 009, 021, 022, 023, 024.

**Giao diện vào.** Gọi hàm từ `scan`; API-08-065, 066, 104, 105, 106.

**Phụ thuộc ra.** `rule` (trọng số hiệu lực), `finding` (số ngoại lệ), `outbox`.

**Dữ liệu.** `dq_score_snapshot`, `dq_score_dimension`, `dq_rule_result`.

**Sự kiện.** EVT-08-02, 04 `score.degraded`, 05 `score.threshold-breached`, 14 `kpi.published`.

**Lỗi và xử lý.** ERR-08-108 (chiều thiếu), ERR-08-027; ERR-08-110 (cờ `TRUNCATED`).

**Quan sát.** `dq_score_gauge{asset,dimension}`, `dq_score_computed_total{verdict}`, `dq_score_flag_total{flag}`, `dq_dashboard_query_seconds`.
:::

Chi tiết thiết kế:

`ScoreCalculator` chạy một lần mỗi lần đo trong một giao dịch theo §4.16.1; lỗi giữa chừng hủy toàn bộ (không có ảnh chụp dở dang) và lần đo ở lại `RUNNING` để `ScanWatchdog` khép lại. `SnapshotWriter` chèn một dòng `dq_score_snapshot` và sáu dòng `dq_score_dimension` (chiều không có điểm vẫn có dòng điểm rỗng để người đọc thấy chiều bị bỏ), cùng outbox EVT-08-02 và nếu cần EVT-08-04, 05, 14. Trigger `tg_immutable` ở DDL cấm sửa ảnh chụp (BR-08-009).

`TrendComparator` lấy ảnh chụp đầy đủ liền trước của đối tượng (chỉ `FULL`), tính Δ, gán `trend` theo dải `08.trend.stable-band` (±1,0), `BASELINE` khi chưa có kỳ trước, bật `WEIGHTS_CHANGED` khi `weight_config_id` khác; Δ ≤ −5,0 phát EVT-08-04. EVT-08-05 chỉ phát khi kết luận xấu đi, không lặp ở các kỳ sau.

Lần đo `INCREMENTAL` không tạo ảnh chụp chính thức: `CurrentScoreMerger` lấy ảnh chụp đầy đủ gần nhất, thay số đếm của khóa đã đo lại và lưu "điểm hiện hành" ở `dq_score_current` (EN-08-32); báo cáo năm chỉ thấy ảnh chụp `official`. Thẻ điểm miền và tổ chức là trung bình có trọng số theo `row_count`. `DashboardQuery` trả radar sáu chiều của kỳ này và kỳ trước (`dimensions`, `dimensionsPrev`) và đọc ảnh chụp gần nhất mỗi đối tượng qua chỉ mục `(tenant_id, asset_id, measured_at DESC)` và đệm Valkey 60 giây để đạt NFR-08-010.

### 4.11. Kho bản ghi lỗi, dấu vân tay, che theo PH-09 (`finding`)

::: dac-ta
**Mục đích.** Lưu mỗi vi phạm đủ để chủ quản tìm đúng bản ghi cần sửa và theo dõi qua các kỳ, nhưng không lưu giá trị Nhạy cảm; quản lý ngoại lệ chấp nhận và xuất lỗi có kiểm soát.

**Lớp chính.** `FindingWriter`, `FingerprintService`, `ValueMasker`, `TenantKeyProvider`, `FindingResolver`, `FindingQueryService`, `WaiverService`, `FindingExporter`.

**Đơn vị chạy.** Ghi ở `worker`; tra cứu, ngoại lệ, xuất ở `api`.

**FR hiện thực.** FR-08-036…040; BR-08-012, 013, 021, 027, 034; ADR 086.

**Giao diện vào.** Gọi hàm từ `worker`, `scan`; API-08-073…083, 129 (`POST /findings:search` tra theo khóa bản ghi cá nhân, khóa chuẩn hóa rồi băm HMAC, không vào đường dẫn hay nhật ký).

**Phụ thuộc ra.** OpenBao (khóa HMAC theo tenant), PH-09 (chính sách che), Garage (tệp xuất), `outbox`.

**Dữ liệu.** `dq_finding` (phân vùng tháng theo `last_seen_at`), `dq_waiver`, `dq_export_request`.

**Sự kiện.** EVT-08-06 `finding.opened` một lần mỗi lần đo; EVT-08-10 `waiver.approved`.

**Lỗi và xử lý.** ERR-08-032, 033, 034, 041, 110; ERR-08-003 (che lỏng hơn phân loại).

**Quan sát.** `dq_findings_total{dimension,severity,status}`, `dq_finding_write_duration_seconds`, `dq_finding_truncated_total`, `dq_finding_sensitive_plain_violations`, `dq_waiver_active`.
:::

Chi tiết thiết kế:

**Ghi lỗi.** `FindingWriter` nhận lô tối đa 1.000 vi phạm. `FingerprintService` tính dấu vân tay (§4.16.3); `ValueMasker` chọn dạng lưu theo phân loại PH-09 (BR-08-012): `SENSITIVE` chỉ lưu `value_hash` và `record_key_hash`, `value_mode = HASH_ONLY`; `RESTRICTED` lưu giá trị che một phần (`MASKED`, giữ hai ký tự đầu và cuối); `PUBLIC`, `INTERNAL` lưu đến 255 ký tự (`PLAIN`). Chế độ che của FRS (`HASH`, `PARTIAL`, `NONE`) ánh xạ sang `HASH_ONLY`, `MASKED`, `PLAIN` của DDL; `ck_dq_finding_no_raw` là lớp chặn cuối. Độ chặt luôn là `max(người dùng đặt, PH-09)`.

**Đối chiếu dấu vân tay.** Chỉ mục duy nhất không đặt được trên `(tenant_id, fingerprint)` vì bảng phân vùng theo `last_seen_at`; thay vào đó BR-08-020 (một lần đo hoạt động mỗi đối tượng) bảo đảm một người ghi, nên `FindingWriter` tra dấu vân tay của lô bằng `ix_dq_finding_fp` rồi: chưa có thì chèn `OPEN`; đã `OPEN`, `IN_REMEDIATION`, `WAIVED` thì cập nhật `last_scan_job_id`, `last_seen_at`, `seen_count + 1`; đã `RESOLVED` thì mở lại `OPEN`. Cập nhật `last_seen_at` chuyển dòng sang phân vùng tháng mới (PostgreSQL di chuyển dòng khi đổi khóa phân vùng); đó là chủ ý: lỗi còn tồn tại luôn ở phân vùng gần nhất, và `DROP PARTITION` sau 13 tháng chỉ xóa lỗi đã không còn thấy từ 13 tháng. Vượt `08.finding.max-per-scan` thì chỉ lưu theo thứ tự mức nghiêm trọng (bộ đếm Valkey `INCR` chung các bộ thực thi), đặt cờ `TRUNCATED` và ERR-08-110; điểm vẫn đủ vì tính từ `dq_rule_result`.

**Giải quyết lỗi (`FindingResolver`).** Sau lần đo, lỗi trong phạm vi mà không còn thấy chuyển `RESOLVED`, lý do `CLEARED` (BR-08-034). `FULL`: một câu `UPDATE` hàng loạt cho lỗi có `last_scan_job_id <> :scan` và `rule_id` thuộc quy tắc đã chạy thành công (`SKIPPED`, `ERROR` không giải quyết lỗi). `SAMPLE`, `INCREMENTAL`, `VERIFY`: bộ thực thi tính HMAC khóa của mọi bản ghi đã đánh giá và chỉ giải quyết lỗi có `record_key_hash` trong tập đó. Bản ghi bị xóa ở nguồn (có ở lần trước, không ở lần `FULL` này, hoặc EVT-06-03) chuyển `RESOLVED` lý do `RECORD_REMOVED`.

**Ngoại lệ.** `WaiverService` nhận đề nghị có phạm vi (`FINDINGS`, `RULE_FILTER`), hạn ≤ `08.waiver.max-days` (ERR-08-033), DA duyệt bốn mắt. Khi `ACTIVE`, lỗi trong phạm vi chuyển `WAIVED`; `ExpiryJob` (ShedLock, mỗi giờ) chuyển ngoại lệ quá hạn sang `EXPIRED` và trả lỗi về `OPEN`. **Xuất lỗi.** `dq_export_request` có `contains_restricted` khi lọc chạm trường Nhạy cảm và cần DO chấp thuận (BR-08-027, ERR-08-041); tệp chỉ giá trị đã che, mã hóa ở Garage, có `watermark_id`, băm SHA-256, hạn tải 24 giờ, ô bắt đầu `=`, `+`, `-`, `@` thêm tiền tố `'` (SEC-45).

### 4.12. Khắc phục, SLA và chuyển steward (`remediation`)

::: dac-ta
**Mục đích.** Biến nhóm lỗi thành việc có chủ, có hạn: phiếu giao tổ chức chủ quản, theo dõi SLA, leo thang khi quá hạn, đo lại để xác nhận đã sửa, và chuyển lỗi bản ghi vàng sang hàng đợi steward của PH-06.

**Lớp chính.** `IssueService`, `IssueStateMachine`, `SlaClock`, `EscalationJob`, `AutoOpenJob`, `VerifyScanTrigger`, `StewardHandoff`, `IssueActivityService`.

**Đơn vị chạy.** `dh-data` hồ sơ `api`; job định kỳ khóa ShedLock.

**FR hiện thực.** FR-08-041…046; BR-08-014, 015, 026, 035.

**Giao diện vào.** API-08-078, 084…097 (danh sách phiếu API-08-085 kèm `facets` số phiếu theo thẻ hộp việc); EVT-08-06 nội bộ cho tự mở phiếu.

**Phụ thuộc ra.** `finding` (gắn lỗi vào phiếu), `scan` (lần đo `VERIFY`), `mdm::api.StewardIntakeApi`, lịch ngày làm việc của PH-13.

**Dữ liệu.** `dq_issue`, `dq_issue_activity`, `dq_finding.issue_id`.

**Sự kiện.** EVT-08-07 `issue.created`, EVT-08-08 `issue.status-changed`, EVT-08-09 `issue.verified`.

**Lỗi và xử lý.** ERR-08-005, 006, 007, 034, 035, 036, 051, 115.

**Quan sát.** `dq_issues_open{severity}`, `dq_issues_overdue`, `dq_issue_sla_met_ratio`, `dq_verify_scans_total{result}`, `dq_issue_escalation_total{level}`.
:::

Chi tiết thiết kế:

**Mở phiếu.** `IssueService.openFromGroup` nhóm lỗi `OPEN` theo `(asset, rule, owner_org)`, kiểm lỗi chưa thuộc phiếu mở khác (ERR-08-034), tạo phiếu `OPEN` và đặt `issue_id`, `IN_REMEDIATION` cho lỗi trong cùng giao dịch. `AutoOpenJob` sau mỗi lần đo: kết luận `FAIL` và số lỗi `CRITICAL` mới vượt `08.issue.auto-open-critical` (100) thì tự mở phiếu gộp theo đối tượng và quy tắc (BR-08-035).

**SLA và leo thang.** `SlaClock` tính `sla_due_at` bằng cộng ngày làm việc (CRITICAL 5, MAJOR 15, MINOR 30, giả định theo Q08-04) trên lịch tenant lấy từ PH-13 (lịch lỗi hoặc chưa có thì dùng thứ hai đến thứ sáu và cảnh báo; nguồn lịch dồn PH-13). Quá hạn là cờ tính từ `sla_due_at`, không phải trạng thái. `EscalationJob` mỗi giờ (ShedLock): quá hạn `08.issue.escalate-after-overdue-days` (5) thì leo thang cấp 1, gấp đôi thì cấp 2, mỗi lần phát EVT-08-08.

**Tách vai.** DO làm `ASSIGNED → IN_PROGRESS → FIXED`; chỉ lần đo `VERIFY` hoặc DS đưa phiếu tới `VERIFIED` hay `REOPENED` (BR-08-014); DO tự xác nhận bị ERR-08-035. Mọi chuyển trạng thái đi bằng `UPDATE dq_issue SET status = :to WHERE id = :id AND status = :from AND version = :v`.

**Kiểm chứng.** `VerifyScanTrigger.onFixed` (gọi từ API-08-090, không qua `POST /scans`, vốn chỉ nhận `MANUAL`, `ANNUAL`) tạo lần đo `VERIFY` ưu tiên cao trên tập khóa của phiếu (≤ 100.000, quá thì `FULL` cho đối tượng); với `MDM_DOMAIN` đặt `not_before` bằng `08.verify.wait-mdm-minutes` (60), với `SOURCE_DATASET` bằng `08.verify.wait-source-minutes` (0, theo độ trễ bản sao chỉ đọc). DS đo lại hoặc xác nhận thủ công bằng API-08-091 (`mode = SCAN` hoặc `MANUAL`, lý do thủ công ≥ 50 ký tự). Mã phiếu `DQ-yyyy-nnnnnn` cấp tuần tự theo tenant và năm. Khi lần đo xong, `onVerifyCompleted`: mọi lỗi `RESOLVED` thì `VERIFIED` và ghi Δ điểm, còn lỗi thì `REOPENED`; lần đo `FAILED` kỹ thuật giữ phiếu `FIXED` (ERR-08-115), thử lại sau 1 giờ tối đa 3 lần rồi giao DS. **Chuyển steward.** `StewardHandoff` chỉ nhận lỗi của `MDM_DOMAIN` (ERR-08-051; PH-06 từ chối chuyển thì phiếu về DS), gọi `StewardIntakeApi.createItem(domain, goldenId, DQ_FINDING)` với khóa idempotent `issueCode`, lưu `steward_item_ref`; chỉ chuyển mã quy tắc và `goldenId`, không giá trị trường. PH-08 không sửa bản ghi vàng (BR-08-004).

### 4.13. Cảnh báo (`alert`)

::: dac-ta
**Mục đích.** Báo cho người có trách nhiệm khi chất lượng xấu đi hoặc quy trình trục trặc (điểm thấp, giảm mạnh, lần đo hỏng, phiếu quá hạn, tỷ lệ `FAIL` trực tuyến cao), không tự gửi thông báo mà giao cho PH-13.

**Lớp chính.** `AlertRuleEngine`, `AlertStateMachine`, `AlertDeduplicator`, `AlertPublisher`, `SilenceService`.

**Đơn vị chạy.** `dh-data` hồ sơ `api`.

**FR hiện thực.** FR-08-047…049; BR-08-029.

**Giao diện vào.** API-08-098…103; gọi hàm từ `score`, `scan`, `remediation`, `inline` (tỷ lệ `FAIL`).

**Phụ thuộc ra.** `outbox`; PH-13 nhận qua sự kiện.

**Dữ liệu.** `dq_alert_rule`, `dq_alert`.

**Sự kiện.** EVT-08-12 `alert.fired` (`FIRING`, `RESOLVED`).

**Lỗi và xử lý.** ERR-08-037, 114 (PH-13 không nhận).

**Quan sát.** `dq_alerts_firing{severity}`, `dq_alert_fired_total{condition}`, `dq_alert_publish_lag_seconds`.
:::

Chi tiết thiết kế:

Điều kiện cảnh báo (`alert.condition` ở Phụ lục A FRS) được đánh giá theo sự kiện nội bộ chứ không quét định kỳ: `score` gọi `AlertRuleEngine.onSnapshot` sau khi ghi ảnh chụp, `scan` gọi khi lần đo `FAILED`, `remediation` gọi khi quá hạn, `inline` gọi mỗi phút cho `INLINE_FAIL_RATE` (so `fail_count / check_count` với ngưỡng và số mẫu tối thiểu). `AlertDeduplicator` bảo đảm mỗi cặp `(alert_rule, asset)` chỉ có một cảnh báo chưa `RESOLVED` (BR-08-029) bằng chỉ mục duy nhất từng phần; điều kiện còn đúng ở kỳ sau thì chỉ nhắc lại sau `08.alert.repeat-hours` (4 giờ). Tắt tiếng tối đa 7 ngày (quá thì ERR-08-042) và bắt buộc lý do ≥ 20 ký tự (ERR-08-007); hết hạn tự quay về `FIRING` nếu điều kiện còn. Cảnh báo tự `RESOLVED` khi điều kiện hết ở lần đánh giá kế. Việc gửi tới người nhận (email, trong ứng dụng) thuộc PH-13: `AlertPublisher` chỉ ghi EVT-08-12 qua outbox; PH-13 không nhận được trong 24 giờ thì ERR-08-114 hiện ở bảng giám sát.

### 4.14. Báo cáo: sinh PDF, XLSX, ký số, Ceph RGW (`report`)

::: dac-ta
**Mục đích.** Lập báo cáo kỳ (tháng) và báo cáo chính thức hằng năm từ ảnh chụp điểm, trình duyệt bốn mắt, công bố bất biến, xuất PDF hoặc XLSX, ký số tùy chọn và phân phối cho người đăng ký.

**Lớp chính.** `ReportComposer`, `AnnualReadinessChecker`, `ReportWorkflow`, `PdfRenderer` (OpenHTMLtoPDF), `ChartRenderer` (ECharts dựng SVG phía máy chủ), `XlsxWriter` (Apache POI), `SigningClient`, `ObjectStoreWriter`, `ReportDistributor`.

**Đơn vị chạy.** Soạn và duyệt ở `api`; dựng tệp ở `worker` (tác vụ nền khi dự kiến > 3 giây).

**FR hiện thực.** FR-08-052…056; BR-08-009, 010, 011; ADR 089.

**Giao diện vào.** API-08-107…121.

**Phụ thuộc ra.** `score`, `finding`, `remediation` (số liệu), Garage (nháp, bản xuất), Ceph RGW (bản công bố), dịch vụ ký số của nền tảng, PH-13 (phân phối).

**Dữ liệu.** `dq_report`, `dq_report_subscription`.

**Sự kiện.** EVT-08-11 `report.published`, EVT-08-14 `kpi.published`.

**Lỗi và xử lý.** ERR-08-005, 038, 039, 040, 048, 112.

**Quan sát.** `dq_reports_total{type,status}`, `dq_report_render_seconds{format}`, `dq_report_sign_failures_total`, `dq_annual_readiness_missing_assets`.
:::

Chi tiết thiết kế:

**Soạn.** `ReportComposer` đọc ảnh chụp theo phạm vi và chốt vào `summary` (JSON) toàn bộ số liệu cần in: điểm theo đối tượng, miền, tổ chức; xu hướng 12 tháng; lỗi `CRITICAL` còn mở; số phiếu và tỷ lệ đạt SLA; Δ điểm nhờ khắc phục; ngoại lệ; khuyến nghị. Tệp PDF, XLSX dựng chỉ từ `summary`, không đọc lại bảng sống, nên bản in khớp nội dung đã duyệt. Báo cáo gửi duyệt phải có khuyến nghị (BR-08-011, ERR-08-039).

**Báo cáo năm.** `AnnualReadinessChecker` chạy lúc tạo và lúc gửi duyệt: mỗi đối tượng phải có ảnh chụp `official` của năm theo `08.annual.snapshot-method` (`FULL_DECEMBER`, `LATEST_FULL`, `WEIGHTED_AVERAGE` theo `row_count`), loại ảnh chụp có `INCOMPLETE_DIMENSIONS` hoặc từ `SAMPLE`, `INCREMENTAL` (BR-08-010). Thiếu thì ERR-08-038 kèm danh sách và người soạn tạo lần đo `ANNUAL`. `ck_dq_report_annual_full` ở DDL là lớp chặn cuối.

**Duyệt, công bố.** `DRAFT → IN_REVIEW → PUBLISHED`; người duyệt khác người gửi (ERR-08-005, `ck_dq_report_four_eyes`). Công bố trong một giao dịch: chuyển `PUBLISHED`, ghi `content_sha256`, outbox EVT-08-11 và EVT-08-14. Báo cáo `PUBLISHED` bất biến (ERR-08-040); sửa bằng thu hồi `WITHDRAWN` kèm lý do và báo cáo thay thế.

**Dựng tệp, ký, lưu.** `PdfRenderer` render mẫu HTML bằng OpenHTMLtoPDF; biểu đồ radar sáu chiều và xu hướng dựng SVG bằng ECharts chạy phía máy chủ; chân trang có `reportCode` (`BC-DQ-yyyy-kỳ-Ttt`, thêm hậu tố `-Rn` cho báo cáo thay thế sau thu hồi) và `contentHash`. `XlsxWriter` ghi luồng `SXSSFWorkbook`. Tính trước `summary` giúp PDF 100 trang trong 2 phút (NFR-08-012); chọn OpenHTMLtoPDF thay vì trình duyệt không đầu để không thêm Chromium vào ảnh (ADR 089). `SigningClient` gửi băm PDF tới dịch vụ ký số nền tảng (PAdES, chứng thư cơ quan, Q08-06); ký lỗi (ERR-08-048) không chặn công bố, báo cáo giữ trạng thái chưa ký. Bản nháp và tệp xuất ở Garage có hạn tải; khi công bố, `ObjectStoreWriter` chép PDF, XLSX và `summary` sang bucket Ceph RGW `dq-reports` có Object Lock theo `08.report.official-retention-years` (10 năm), đối chiếu `content_sha256`. `ReportDistributor` đọc `dq_report_subscription` và phát sự kiện tới PH-13 kèm đường dẫn có hạn, không đính kèm tệp.

### 4.15. Outbox, inbox, tích hợp PH-16, PH-13 và vận hành (`outbox`, `ops`)

::: dac-ta
**Mục đích.** Phát sự kiện đáng tin cậy, nhận sự kiện từ PH-06, PH-07 không xử lý hai lần, đẩy KPI sang PH-16, xuất chỉ số vận hành cho PH-13, và lo các việc quản trị: tham số tenant, lưu giữ, kiểm toán, so sánh liên tenant.

**Lớp chính.** `OutboxWriter`, `InboxConsumer`, `KpiPublisher`, `KpiReplayController`, `TenantSettingService`, `RetentionPurger`, `PartitionMaintenanceJob`, `AuditWriter`, `BenchmarkService`, `MetricsBinder`.

**Đơn vị chạy.** `dh-data` hồ sơ `api`; job định kỳ khóa ShedLock theo tên có tenant.

**FR hiện thực.** FR-08-057…061, 011; BR-08-028, 030; NFR-08-015, 018.

**Giao diện vào.** API-08-122…128; Kafka (inbox).

**Phụ thuộc ra.** Debezium và Kafka (qua outbox), PH-16, PH-13, `pg-core`.

**Dữ liệu.** `outbox_event`, `inbox_event`, `shedlock`, `dq_tenant_setting`, `dq_retention_policy`.

**Sự kiện.** EVT-08-14 `kpi.published`; ghi hộ mọi EVT-08-01…13 của các thành phần khác.

**Lỗi và xử lý.** ERR-08-042, 043, 044, 054, 113, 117, 118.

**Quan sát.** `dq_outbox_lag_seconds`, `dq_outbox_pending`, `dq_inbox_dlq_total`, `dq_retention_rows_purged_total{object}`, `dq_audit_write_failure_total`.
:::

Chi tiết thiết kế:

**Outbox, inbox.** `OutboxWriter.append` chỉ chạy trong giao dịch đang mở, ghi `outbox_event` kèm `trace_id`; `ck_outbox_event_prefix` bảo đảm tiền tố topic khớp tenant và `ck_outbox_event_no_value` từ chối khóa `value`, `maskedValue`, `recordKey` trong payload, nên sự kiện không thể mang giá trị dữ liệu. Debezium Outbox Event Router phát tới Kafka với khóa thông điệp `aggregate_id` để giữ thứ tự (trễ p95 ≤ 5 giây, NFR-08-018). `InboxConsumer` ghi `inbox_event(tenant, consumer, event_id)` cùng giao dịch với tác động của sự kiện; lỗi lược đồ chuyển `{topic}.dlq` và ERR-08-118.

**KPI.** `KpiPublisher` ghi EVT-08-14 trong giao dịch tạo ảnh chụp hoặc công bố báo cáo, khóa idempotent `snapshotId` hoặc `reportCode`; chỉ số phiếu hằng ngày do job 01:00 phát; không giao được quá 24 giờ thì ERR-08-113. Lược đồ có `kpiSchemaVersion`, đổi thì phát song song hai phiên bản 90 ngày; PH-16 lỡ sự kiện đọc lại qua API-08-122. Chỉ số vận hành đi qua Prometheus cho PH-13, không qua sự kiện.

**Tham số, lưu giữ, kiểm toán.** `TenantSettingService` kiểm 43 khóa `08.*` theo miền và trần của PA (ERR-08-042), khóa lưu giữ không dưới sàn (ERR-08-043). `RetentionPurger` (ShedLock, đêm) dọn theo `dq_retention_policy`: lỗi 13 tháng, kết quả quy tắc 24 tháng, thống kê phút 90 ngày bằng `DETACH PARTITION` rồi `DROP` dưới vai `ph08_owner`; phiếu 5 năm sau đóng; ảnh chụp 5 năm; báo cáo công bố 10 năm. `PartitionMaintenanceJob` gọi `p_ensure_partitions` hằng ngày giữ ba tháng phân vùng chuẩn bị. `AuditWriter` ghi đồng bộ cùng giao dịch; không ghi được thì từ chối ERR-08-054. **So sánh liên tenant.** `BenchmarkService` chỉ cho PA, đọc điểm của tenant có `08.benchmark.opt-in`, trả trung vị và tứ phân vị, từ chối khi nhóm dưới `08.benchmark.min-group` (5, ERR-08-044), không nêu tên tenant (BR-08-030); dùng vai CSDL riêng đọc khung nhìn tổng hợp vì RLS cấm đọc chéo.

### 4.16. Thuật toán

#### 4.16.1. Chấm điểm

Ba mức tính: điểm chiều, điểm tổng, kết luận. Với mỗi quy tắc r của lần đo, `pass_r`, `fail_r` là số bản ghi đạt và vi phạm, `waived_r` là số vi phạm thuộc ngoại lệ `ACTIVE` lúc đo, quy tắc `SKIPPED` hay `ERROR` không có số đếm.

1. Mẫu số của quy tắc: `n_r = pass_r + (fail_r − waived_r)`; vi phạm được ngoại lệ không tính vào tử số lẫn mẫu số (BR-08-021, 022).
2. Điểm chiều d, phương pháp `POOLED` (mặc định): `score_d = 100 × Σ pass_r / Σ n_r` trên các quy tắc của chiều d có kết quả `PASSED` hoặc `FAILED`. Phương pháp `RULE_AVERAGE`: `score_d = Σ(w_r × 100 × pass_r / n_r) / Σ w_r`. Chiều không có quy tắc nào chạy được, hoặc `Σ n_r = 0`, có điểm rỗng (`NULL`), không phải 0 hay 100.
3. Điểm tổng: `score = Σ(w_d × score_d) / Σ w_d` chỉ trên các chiều có điểm; khi đủ sáu chiều thì `Σ w_d = 1` và công thức thành tổng có trọng số thuần. Nếu có chiều rỗng, trọng số các chiều còn lại được chuẩn hóa lại và cờ `INCOMPLETE_DIMENSIONS` bật. Nếu không chiều nào có điểm thì `score = NULL`, không có `verdict`, cờ bật và ERR-08-108.
4. Kết luận: `PASS` nếu `score ≥ pass_threshold` (mặc định 80), `WARN` nếu `≥ warn_threshold` (70), còn lại `FAIL`.
5. Cờ: `INCOMPLETE_DIMENSIONS` ở bước 3; `WEIGHTS_CHANGED` khi `weight_config_id` khác ảnh chụp liền trước; `TRUNCATED` khi lần đo vượt trần lưu lỗi (chỉ ảnh hưởng danh sách lỗi, điểm vẫn đủ); `INCREMENTAL` cho điểm hiện hành.

Tính bằng `BigDecimal` với 6 chữ số thập phân, làm tròn `HALF_UP` về 2 chữ số khi ghi `numeric(5,2)`; số đếm là `long`, cộng theo tác vụ nên không phụ thuộc thứ tự tác vụ, nhờ đó hai lần chạy cùng dữ liệu cho cùng điểm (NFR-08-007, sai số ≤ 0,01 chỉ còn do làm tròn). Ví dụ của FRS: sáu điểm 91,2; 88,0; 79,5; 72,0; 96,0; 85,0 với trọng số mặc định cho 86,37 (FRS ghi 86,89, tính lại ra 86,37; đề nghị sửa ở §13.6), kết luận `PASS`. Nếu `VALIDITY` rỗng vì PH-07 lỗi, điểm tổng là `(91,2×0,20 + 88,0×0,20 + 79,5×0,15 + 72,0×0,10 + 96,0×0,15) / 0,80 = 86,71` (làm tròn), cờ `INCOMPLETE_DIMENSIONS` bật và báo cáo năm không dùng ảnh chụp đó.

#### 4.16.2. Lấy mẫu có seed

Lấy mẫu phải tái lập (BR-08-019, NFR-08-008). `ScanPlanner` sinh `sample_seed` 64 bit từ `SecureRandom` và lưu lên lần đo. Với cỡ mẫu k trên N bản ghi, tỷ lệ chọn `p = k / N`; một bản ghi thuộc mẫu khi `h(seed, recordKey) mod 10.000 < round(p × 10.000)`. Với nguồn PostgreSQL, `h` là `hashtextextended(recordKey::text, seed)` đẩy xuống ở mệnh đề `WHERE`, nên chỉ mẫu được đọc về. Với động cơ khác, `Sampler` đọc cột khóa (chỉ cột khóa, qua chỉ mục), tính `xxHash64(seed, key)` trong Java, rồi đọc các dòng được chọn theo lô khóa; hàm băm khác nhau giữa hai nhánh nên "cùng seed cho cùng mẫu" chỉ bảo đảm trong một động cơ (Q08-25). Cỡ mẫu thực là xấp xỉ k (độ lệch chuẩn khoảng `√(k(1−p))`), và `sample_size` ghi số bản ghi thực đã đánh giá. `SAMPLE` chỉ giải quyết lỗi thuộc bản ghi trong mẫu (BR-08-034) và không bao giờ dùng cho báo cáo năm.

#### 4.16.3. Dấu vân tay và khóa tenant

`fingerprint = HMAC-SHA256(K_tenant, tenantId ‖ 0x1F ‖ assetCode ‖ 0x1F ‖ ruleCode ‖ 0x1F ‖ recordKeyChuẩnHóa)`, 32 byte. Khóa bản ghi chuẩn hóa bằng cắt khoảng trắng, Unicode NFC, nối các cột khóa bằng `0x1F`. Không có phiên bản quy tắc trong đầu vào nên lỗi nối tiếp qua các phiên bản (BR-08-013). FRS ghi `SHA-256` trần; thiết kế dùng HMAC khóa theo tenant theo ADR 086 và DDL vì SHA-256 trần của khóa như số CCCD dò ngược được bằng từ điển (đề nghị sửa FRS, §13.6). `TenantKeyProvider` lấy khóa từ OpenBao (ADR-032), giữ trong bộ nhớ tiến trình tối đa một giờ, không ghi đĩa, không đưa vào log. Đổi khóa làm mọi dấu vân tay cũ không khớp, nên cần quy trình đổi khóa có băm kèm phiên bản khóa (Q08-26). `record_key_hash` và `value_hash` dùng cùng khóa với nhãn miền khác nhau (`"key"`, `"val"`) để không dùng chéo.

#### 4.16.4. Phân mảnh tác vụ

`TaskSharder` chia theo khóa chính để các tác vụ không giao nhau và không cần phối hợp. Với khóa có chỉ mục, một truy vấn quét chỉ mục lấy ranh giới: `SELECT key FROM (SELECT key, row_number() OVER (ORDER BY key) AS rn FROM t) x WHERE rn % :taskSize = 1`, cho `shard_count = ⌈N / 08.scan.task-size⌉` dải `[key_from, key_to)`; khóa ghép so sánh bằng bộ giá trị. Khi không có chỉ mục khóa hoặc nguồn không hỗ trợ cửa sổ, lần đo chạy một tác vụ duy nhất bằng con trỏ và cảnh báo hiệu năng. `UNIQUE_*` và `CROSS_ENTITY` cần toàn tập nên có tác vụ phụ riêng không theo dải; các tác vụ này vẫn ghi lỗi theo khóa của bản ghi vi phạm. Số tác vụ ảnh hưởng thông lượng: 1 triệu bản ghi với cỡ 200.000 là 5 tác vụ, đủ cho 4 bộ thực thi chạy gần song song (NFR-08-003, 019).

## 5. Biểu đồ tuần tự

Năm sơ đồ phủ các luồng nhiều bước hoặc nhiều thành phần của FRS; mỗi sơ đồ ghi FR liên quan và một đoạn nói điểm cần chú ý.

### 5.1. Đo theo lô phân mảnh, chấm điểm và phát sự kiện (FR-08-023, 026, 027, 028, 029, 031, 036)

Sơ đồ cho thấy một lần đo theo lịch từ lúc bộ lập lịch tới hạn đến khi có ảnh chụp điểm và sự kiện: xếp hàng, phân mảnh, bộ thực thi chạy tác vụ, ghi lỗi, gộp và chấm điểm.

```{.mermaid caption="Đo theo lô phân mảnh đến ảnh chụp điểm và sự kiện (FR-08-023, 026, 027, 028, 029, 036)"}
sequenceDiagram
  participant L as ScheduleDispatcher
  participant C as ScanCoordinator
  participant PG as ph08_dq
  participant W as TaskRunner
  participant S as Nguồn đo
  participant R as RdmGateway
  participant F as FindingWriter
  participant K as ScoreCalculator
  L->>PG: ShedLock dq-dispatch, lịch tới hạn, tạo lần đo QUEUED
  C->>PG: SKIP LOCKED chọn lần đo, RUNNING, tạo dq_scan_task
  W->>PG: nhận tác vụ, ghim phiên bản quy tắc và trọng số
  W->>S: SUM CASE WHEN cho quy tắc đẩy xuống
  S-->>W: số đếm theo quy tắc
  W->>R: nạp ảnh chụp danh mục cho IN_RDM
  R-->>W: tập mã hiệu lực hoặc ERR-08-108
  W->>S: đọc dòng theo con trỏ cho quy tắc CEL
  W->>F: lô 1.000 lỗi, dấu vân tay, che
  F->>PG: chèn hoặc cập nhật dq_finding
  W->>PG: dq_rule_result, tác vụ SUCCEEDED
  W->>K: tác vụ cuối xong thì khép lần đo
  K->>PG: ghi ảnh chụp, điểm chiều, so kỳ, outbox EVT-08-02
  K->>PG: giải quyết lỗi không còn thấy, COMMIT
```

Điểm cần chú ý: mỗi tác vụ chạm nguồn hai lần nên tải dự báo được; điểm tính đúng một lần ở tác vụ cuối trong một giao dịch; nếu PH-07 lỗi thì chỉ quy tắc `IN_RDM*` bị `SKIPPED` và lần đo kết thúc `PARTIAL`.

### 5.2. Kiểm tra trực tuyến có phụ thuộc lỗi (FR-08-032, 033, 034, 035)

Sơ đồ cho thấy luồng PH-04 gọi kiểm tra một bản ghi, nhánh bộ đệm trúng, nhánh PH-07 lỗi với hai chính sách `FAIL_OPEN` và `FAIL_CLOSED`, và việc gộp thống kê theo phút ngoài đường nóng.

```{.mermaid caption="Kiểm tra trực tuyến một bản ghi và nhánh phụ thuộc lỗi (FR-08-032, 033, 034)"}
sequenceDiagram
  participant P as Kamelet dh-dq-check
  participant A as APISIX
  participant I as InlineEvaluator
  participant C as RuleCacheManager
  participant R as RdmGateway
  participant G as InlineStatAggregator
  participant D as outbox
  P->>A: POST checks:evaluate, token scope dq.check
  A->>I: chuyển yêu cầu đã xác thực
  I->>C: lấy quy tắc đã biên dịch của đối tượng
  C-->>I: CompiledInlineRuleSet từ bộ nhớ
  I->>I: đánh giá quy tắc gốc và CEL trong 40 ms
  I->>R: IN_RDM từ ảnh chụp trong bộ đệm
  alt PH-07 hoặc bộ đệm lỗi
    R-->>I: RdmUnavailableException
    I->>I: áp onDependencyFailure
    I-->>A: FAIL_OPEN PASS degraded hoặc FAIL_CLOSED 503
  else bình thường
    R-->>I: kết quả tra
    I-->>A: 200 verdict và violations không có giá trị
  end
  A-->>P: phản hồi, áp onFail của luồng
  I->>G: cộng bộ đếm phút trong bộ nhớ
  G->>D: mỗi 60 giây upsert dq_inline_stat và EVT-08-13 khi có FAIL
```

Điểm cần chú ý: đường nóng không có truy vấn CSDL khi bộ đệm nóng; `FAIL_OPEN` hay `FAIL_CLOSED` thuộc cấu hình từng đối tượng; thống kê ghi ngoài đường nóng nên không cộng vào độ trễ.

### 5.3. Đo tăng dần theo sự kiện PH-06, PH-07 (FR-08-025)

Sơ đồ cho thấy sự kiện bản ghi vàng đổi được gom theo cửa sổ 15 phút thành lần đo `INCREMENTAL` chỉ trên khóa đổi, và điểm hiện hành được cập nhật mà không tạo ảnh chụp chính thức.

```{.mermaid caption="Đo tăng dần từ sự kiện bản ghi vàng đổi (FR-08-025)"}
sequenceDiagram
  participant K as Kafka sự kiện PH-06
  participant I as IncrementalCollector
  participant PG as ph08_dq
  participant J as Job gom cửa sổ
  participant P as ScanPlanner
  participant W as TaskRunner
  participant M as CurrentScoreMerger
  K->>I: EVT-06-01, 02, 03, 04
  I->>PG: inbox_event khử trùng, thêm goldenId vào bộ đệm khóa
  Note over J: mỗi 15 phút, ShedLock theo tenant và đối tượng
  J->>PG: đọc tập khóa của đối tượng
  alt hơn 100.000 khóa
    J->>PG: đánh dấu chờ lần FULL kế tiếp
  else trong trần
    J->>P: lần đo INCREMENTAL, trigger EVENT, tập khóa
    P->>W: tác vụ theo tập khóa
    W->>PG: lỗi mới, giải quyết lỗi của khóa đã sửa
    W->>M: số đếm của khóa đo lại
    M->>PG: cập nhật điểm hiện hành, không ảnh chụp chính thức
  end
```

Điểm cần chú ý: lần đo tăng dần chỉ đổi trạng thái lỗi của các khóa đã đo và không thay ảnh chụp đầy đủ (BR-08-033); `UNIQUE_*` vẫn đối chiếu toàn tập cho khóa đổi.

### 5.4. Vòng khắc phục và đo lại kiểm chứng (FR-08-041, 042, 044, 046)

Sơ đồ cho thấy từ nhóm lỗi đến phiếu, chủ quản sửa ở nguồn, lần đo `VERIFY` và hai kết cục `VERIFIED` hay `REOPENED`; nhánh chuyển steward dành cho lỗi bản ghi vàng.

```{.mermaid caption="Phiếu khắc phục đến đo lại kiểm chứng (FR-08-041, 042, 044, 046)"}
sequenceDiagram
  participant S as DS
  participant R as IssueService
  participant O as DO chủ quản
  participant V as VerifyScanTrigger
  participant W as TaskRunner
  participant M as PH-06 steward
  participant D as outbox
  S->>R: mở phiếu từ nhóm lỗi
  R->>R: gắn lỗi, tính SLA ngày làm việc, ASSIGNED
  R->>D: EVT-08-07 issue.created
  opt lỗi thuộc bản ghi vàng
    R->>M: StewardIntakeApi tạo mục DQ_FINDING
  end
  O->>R: nhận việc, sửa ở nguồn, báo FIXED kèm ghi chú
  R->>V: onFixed, tập khóa của phiếu
  V->>W: lần đo VERIFY ưu tiên cao, chờ PH-06 nếu MDM_DOMAIN
  W->>R: kết quả đo lại các khóa
  alt mọi lỗi RESOLVED
    R->>R: VERIFIED, ghi Δ điểm
    R->>D: EVT-08-09 issue.verified
  else còn lỗi
    R->>R: REOPENED, thông báo DO
    R->>D: EVT-08-08 status-changed
  end
```

Điểm cần chú ý: chủ quản chỉ báo đã sửa; chỉ lần đo `VERIFY` sạch hoặc DS mới đưa phiếu tới `VERIFIED` (BR-08-014); `VERIFY` hỏng kỹ thuật thì phiếu ở lại `FIXED` và được thử lại.

### 5.5. Soạn, duyệt, công bố báo cáo năm (FR-08-053, 054, 055, 057)

Sơ đồ cho thấy kiểm sẵn sàng báo cáo năm, bốn mắt, dựng PDF, ký số tùy chọn, lưu bản công bố ở kho bất biến và đẩy KPI sang PH-16.

```{.mermaid caption="Báo cáo năm từ kiểm sẵn sàng đến công bố và đẩy KPI (FR-08-053, 054, 055, 057)"}
sequenceDiagram
  participant A as Người soạn DS
  participant R as ReportComposer
  participant C as AnnualReadinessChecker
  participant V as DA duyệt
  participant P as PdfRenderer
  participant G as SigningClient
  participant S as Ceph RGW
  participant D as outbox
  A->>R: tạo báo cáo ANNUAL năm N
  R->>C: kiểm mỗi đối tượng có ảnh chụp FULL đủ chiều
  C-->>R: đủ, hoặc ERR-08-038 kèm danh sách thiếu
  R->>R: chốt summary, thêm khuyến nghị
  A->>R: gửi duyệt, kiểm lại sẵn sàng
  V->>R: duyệt, khác người gửi
  R->>P: dựng PDF và XLSX từ summary
  P-->>R: tệp và băm nội dung
  opt ký số
    R->>G: ký PAdES bằng chứng thư cơ quan
    G-->>R: PDF đã ký, signatureRef
  end
  R->>S: chép tệp vào bucket Object Lock, đối chiếu băm
  R->>D: PUBLISHED, EVT-08-11 và EVT-08-14 cùng giao dịch
```

Điểm cần chú ý: kiểm sẵn sàng chạy hai lần vì ảnh chụp có thể đổi giữa hai thời điểm; tệp dựng từ `summary` đã chốt; ký số lỗi (ERR-08-048) không chặn công bố.

## 6. Đa tenant trong mã nguồn

Mọi bảng của `ph08_dq` có `tenant_id` và RLS theo `app.tenant_id` (ADR-003, D03-10). Bộ lọc Spring Security đọc tenant từ token, đặt `TenantContext`, và `TenantSession` chạy `SET LOCAL app.tenant_id` đầu mỗi giao dịch; mã nghiệp vụ không tự thêm điều kiện `tenant_id`. Năm điểm riêng của PH-08:

1. **Tác vụ nền** (`ScheduleDispatcher`, `ScanWatchdog`, `EscalationJob`, `RetentionPurger`, `ExpiryJob`) lặp qua từng tenant `ACTIVE`, đặt `TenantContext` tường minh và dùng khóa ShedLock có tên kèm tenant; ngoại lệ duy nhất là `PartitionMaintenanceJob` (chỉ gọi thủ tục DDL).
2. **Bộ thực thi** đặt `TenantContext` theo `tenant_id` của dòng `dq_scan_task`; kết nối tới dữ liệu được đo là kết nối PH-05 thuê riêng theo tenant, không dùng chung nhóm kết nối giữa tenant.
3. **Kafka**: topic có tiền tố tenant (`t68.dq.…`), ràng buộc `ck_outbox_event_prefix` bảo đảm tiền tố khớp `tenant_id`; bộ nghe EVT-06 và EVT-07 lấy tenant từ tiền tố topic và đối chiếu với `inbox_event.tenant_id`, lệch thì bỏ và cảnh báo. EVT-07-10 của `COMMON` tạo lần đo cho từng tenant có đối tượng liên quan.
4. **Khóa và bộ đệm**: khóa HMAC riêng từng tenant; khóa Valkey, khóa tư vấn, tên bucket, tên khóa ShedLock đều mang tenant. Bộ đệm quy tắc trực tuyến khóa theo `(tenant, assetCode)` nên không lẫn.
5. **Tenant `COMMON` và so sánh liên tenant.** Quy tắc mẫu của `COMMON` đọc qua `TemplateLibrary` với quyền chỉ đọc cho mọi tenant, sao chép vào tenant khi dùng. So sánh liên tenant (PLATFORM) đọc qua khung nhìn tổng hợp dưới vai CSDL riêng không có `app.tenant_id`; đây là đường duy nhất vượt RLS, có kiểm tra nhóm ≥ 5 và không trả khóa tenant.

## 7. Bảo mật

Kiểm tra quyền ở máy chủ, độc lập với giao diện: APISIX xác minh token và gọi OPA thô (SEC-26); `dh-data` kiểm lại `PERM-08-*` và phạm vi tổ chức ở từng `Controller` qua OPA (DO chỉ thấy tổ chức mình, VW chỉ thấy số tổng hợp, BR-08-026). Bảng dưới liệt kê các kiểm soát và ràng buộc `SEC-*` đã có (không tạo mới).

| Kiểm soát | Hiện thực | SEC |
|---|---|---|
| Xác thực, ủy quyền | OIDC qua BFF cho người; `client_credentials` cho máy; scope `dq.check` (PH-04, PH-06), `dq.read` (PH-16, HTTT) và `dq.ingest` (PH-05, chỉ gọi API-08-024); mTLS nội bộ (NFR-08-017) | SEC-21, 24, 26 |
| Tài khoản đọc dữ liệu đo | Vai `dq_reader` chỉ `SELECT` trên `v_dq_{domain}`; kết nối PH-05 chỉ đọc (Q359, ADR-067); `statement_timeout` 15 phút; cấm đọc `ph{nn}_*` (BR-08-005) | SEC-14, 31 |
| Không lưu giá trị Nhạy cảm | `ValueMasker`, `ProfileValueGuard`, `ck_dq_finding_no_raw`, `ck_outbox_event_no_value`; log không in giá trị; quét CCCD, MST, SĐT mỗi bản phát hành (NFR-08-016) | SEC-31, 32, 34 |
| Che theo PH-09 | Chế độ che không lỏng hơn phân loại; trường chưa phân loại coi là `SENSITIVE` | SEC-32 |
| Tách nhiệm vụ, bốn mắt | Duyệt bộ quy tắc, trọng số, ngoại lệ, báo cáo, xuất lỗi Nhạy cảm: người soạn, người gửi không duyệt (ERR-08-005); cặp loại trừ DS và DA; ràng buộc DDL cho báo cáo và xuất | SEC-28, ADR-046 |
| Vị từ SQL và CEL do người dùng viết | Tính năng `SQL_PREDICATE` tắt mặc định; danh sách cho phép bằng trình phân tích cú pháp; CEL có giới hạn chi phí; tài khoản chỉ `SELECT` là lớp bảo vệ cuối | SEC-43 |
| Kiểm toán | `AuditWriter` đồng bộ trong giao dịch (ai, làm gì, trước và sau); không ghi được thì từ chối (ERR-08-054) | SEC-37, 39 |
| Xuất tệp | Chỉ giá trị đã che, mã hóa, thủy vân, hạn 24 giờ, tiền tố `'` chống chèn công thức; báo cáo công bố ở Ceph RGW Object Lock | SEC-45 |

: Kiểm soát bảo mật của PH-08

Hai rủi ro riêng: truy vấn lên CSDL của HTTT gây tải (giảm thiểu bằng cửa sổ giờ, hai truy vấn đồng thời, `statement_timeout`, không bao giờ chạy DDL hay `LOCK`), và bản ghi lỗi thành bản sao dữ liệu cá nhân thứ cấp (mặc định lưu băm hoặc giá trị che; DO sửa trong HTTT của mình chứ không đọc giá trị gốc từ PH-08, Q08-07).

## 8. Máy trạng thái, xử lý lỗi, thử lại và tính nhất quán

### 8.1. Bảng chuyển trạng thái

FRS mô tả bảy máy trạng thái (4.3 đến 4.7, cộng tác vụ và xuất lỗi). Mỗi chuyển trạng thái hiện thực bằng một câu `UPDATE … WHERE status = :expected` (so sánh và hoán đổi) và trả số dòng; số dòng bằng 0 nghĩa là trạng thái đã đổi, dịch vụ trả ERR-08-006 hoặc thử lại tùy ngữ cảnh. Bảng dưới ghi các chuyển có điều kiện đáng kể và nơi kiểm tra ở máy chủ.

| Đối tượng | Từ → đến | Điều kiện, bảo vệ | Chỗ kiểm tra |
|---|---|---|---|
| Phiên bản bộ quy tắc | `DRAFT` → `PENDING_APPROVAL` | Đã chạy thử đúng nội dung hiện tại (ERR-08-053), có quy tắc bật (ERR-08-021) | `VersionLifecycle` |
| | `PENDING_APPROVAL` → `ACTIVE` hoặc `APPROVED` | DA khác người soạn, người gửi (ERR-08-005) | `ApprovalService` |
| Lần đo | `QUEUED` → `RUNNING` | Trong cửa sổ giờ; `SKIP LOCKED` | `ScanCoordinator` |
| | `RUNNING` → `FAILED` | Nguồn không khả dụng, độ phủ < `08.scan.min-coverage`, quá hạn (ERR-08-105, 106) | `ScanCoordinator`, `ScanWatchdog` |
| Bản ghi lỗi | `OPEN` → `IN_REMEDIATION` | Có phiếu (`ck_dq_finding_remediation`) | `IssueService` |
| | `OPEN`, `IN_REMEDIATION` → `RESOLVED` | Lần đo có phủ quy tắc và bản ghi, không còn lỗi (BR-08-034) | `FindingResolver` |
| Phiếu | `OPEN` → `ASSIGNED` | Tổ chức chủ quản hợp lệ (ERR-08-008) | `IssueService` |
| | `IN_PROGRESS` → `FIXED` | Ghi chú ≥ 20 ký tự (ERR-08-036) | `IssueStateMachine` |
| | `FIXED` → `VERIFIED` hoặc `REOPENED` | Chỉ lần đo `VERIFY` hoặc DS; DO không (ERR-08-035) | `IssueService.onVerifyCompleted` |
| Báo cáo | `DRAFT` → `IN_REVIEW` | Có khuyến nghị (ERR-08-039), báo cáo năm đủ điều kiện (ERR-08-038) | `ReportWorkflow` |
| | `IN_REVIEW` → `PUBLISHED` | DA khác người gửi; giao dịch ghi băm, sự kiện | `ReportWorkflow` |

: Bảng chuyển trạng thái và nơi kiểm tra ở máy chủ

### 8.2. Outbox

Mọi sự kiện EVT-08-01…14 ghi vào `outbox_event` cùng giao dịch với thay đổi nghiệp vụ (§4.15), nên không có sự kiện "ma" hay thay đổi không sự kiện; thứ tự theo đối tượng giữ nhờ khóa thông điệp `aggregate_id`. Sự kiện tổng hợp theo thiết kế: EVT-08-06 một lần mỗi lần đo, EVT-08-13 một lần mỗi phút mỗi `(đối tượng, bên gọi)`.

### 8.3. Inbox và idempotency

Sự kiện nhận khử trùng bằng `inbox_event` cùng giao dịch với tác động của nó. Yêu cầu ghi dùng `Idempotency-Key` hai tầng (ADR-041): bộ đệm Valkey 24 giờ và ràng buộc duy nhất ở CSDL (`idempotency_key` của lần đo, `issueCode` khi chuyển steward); khóa lưu kèm băm thân yêu cầu, cùng khóa cùng thân trả lại phản hồi cũ, cùng khóa khác thân trả ERR-08-055 (409). Thao tác của bộ thực thi idempotent theo `(scan_task_id, rule_id)` và dấu vân tay nên chạy lại tác vụ không nhân đôi.

### 8.4. Thời gian chờ, thử lại, ngắt mạch

Bảng ghi chính sách cho từng phụ thuộc; mọi thử lại có trần và có chỉ số, và không có vòng thử lại vô hạn.

| Phụ thuộc, thao tác | Thời gian chờ | Thử lại | Ngắt mạch | Khi hết cách |
|---|---|---|---|---|
| Truy vấn nguồn (tập hợp, đọc dòng) | `statement_timeout` 15 phút | 3 lần, lùi 30 giây, 2 phút, 5 phút, ở mức tác vụ | Theo kết nối PH-05: mở sau 5 tác vụ lỗi liên tiếp | Tác vụ `FAILED`, quy tắc `ERROR` (ERR-08-107), lần đo `PARTIAL` hoặc `FAILED` |
| Khung nhìn PH-06 (bản sao) | 15 phút như trên | Như trên | Như trên | ERR-08-105 |
| PH-07 ảnh chụp, tra lô | 2 giây mỗi lô 500 mã, 40 ms ở trực tuyến | 1 lần ở lô, không ở trực tuyến | Mở sau 5 lỗi, nửa mở 30 giây (NFR-08-006) | `SKIPPED` (lô) hoặc `onDependencyFailure` (trực tuyến) |
| PH-09 tra phân loại | 500 ms | 2 lần | Mở sau 5 lỗi | Dùng bộ đệm 5 phút, không có thì coi `SENSITIVE` |
| OpenBao (khóa HMAC) | 2 giây | 3 lần, lùi 1 giây nhân đôi | Mở sau 5 lỗi | Tác vụ ghi lỗi tạm dừng, thử lại; khóa đã đệm vẫn dùng đến hết hạn |
| Valkey | 50 ms | Không | Lùi về bộ đệm bộ nhớ L1, bỏ qua bộ đếm hạn mức (ghi cảnh báo) | Chậm hơn nhưng đúng; hạn mức nguồn rơi về bộ đếm cục bộ mỗi bản sao |
| PH-05 thuê kết nối | 5 giây | 3 lần | Mở sau 5 lỗi | Lần đo `FAILED` (ERR-08-105) |
| Garage, Ceph RGW | 30 giây mỗi đối tượng | 3 lần, có tiền tố băm đối chiếu | Không | ERR-08-112, báo cáo ở lại chưa công bố |
| Dịch vụ ký số | 20 giây | 1 lần | Không | ERR-08-048, công bố chưa ký |
| Kafka qua Debezium | Do nền tảng | Debezium tự phát lại | Do nền tảng | Outbox giữ, cảnh báo khi `dq_outbox_lag_seconds` > 60 |
| Kiểm toán PH-13 | Đồng bộ cùng giao dịch | Không | Không | Từ chối thao tác (ERR-08-054) |

: Thời gian chờ, thử lại và ngắt mạch của PH-08

### 8.5. Ánh xạ lỗi

Lỗi trả theo RFC 9457 với `code`, `traceId`, `errors[]` (D03-04-PH08). Ngoại lệ miền (`DomainException`) mang đúng mã ERR-08-nnn của FRS; ngoại lệ hạ tầng được bắt ở ranh giới thành phần và đổi thành mã runtime: `TransientSourceException` hết lượt thành ERR-08-105, `RdmUnavailableException` thành ERR-08-108 (quy tắc `SKIPPED`), hết ngân sách trực tuyến thành ERR-08-103 hoặc ERR-08-104 theo `onDependencyFailure`, vượt trần lỗi thành cờ `TRUNCATED` với ERR-08-110, không ghi được kiểm toán, hoặc dịch vụ phụ thuộc không khả dụng ở lệnh ghi, thành ERR-08-054 (503 chung); lô kiểm tra trực tuyến quá 100 bản ghi thành ERR-08-101; xung đột phiên bản `If-Match` thành ERR-08-004 hoặc ERR-00-428, chuyển trạng thái sai thành ERR-08-006; kỳ báo cáo không có lần đo thành công thành ERR-08-056, chưa có bộ quy tắc hoặc trọng số hiệu lực thành ERR-08-027.

## 9. Cấu hình và cờ tính năng theo tenant

### 9.1. Tham số theo tenant

Bốn mươi ba khóa `08.*` của FRS §8.2 chỉnh được ở FR-08-058, kiểm miền và trần bởi `TenantSettingService`. Bảng dưới ghi những khóa mà thiết kế dựa vào, thành phần đọc chúng và cách áp dụng thay đổi.

| Khóa | Mặc định | Thành phần đọc | Áp dụng thay đổi |
|---|---|---|---|
| `08.scan.default-cron`, `08.scan.timezone` | `0 0 2 1 * ?`, `Asia/Ho_Chi_Minh` | `catalog` (tạo lịch lúc kích hoạt) | Chỉ lịch tạo sau; lịch cũ giữ |
| `08.scan.task-size` | 200.000 | `TaskSharder` | Lần đo mới |
| `08.scan.max-concurrent-per-connection` | 2 | `SourceThrottle` | Ngay (đọc Valkey mỗi tác vụ) |
| `08.rdm.snapshot-max-items` | 200.000 | `RdmGateway` | Ngay (làm mới bộ đệm) |
| `08.finding.max-per-scan`, `08.finding.max-per-rule-task` | 1.000.000, 50.000 | `FindingWriter`, `TaskRunner` | Lần đo mới |
| `08.inline.timeout-ms` | 40 | `InlineEvaluator` | Ngay, đọc từ bộ đệm cấu hình 15 giây |
| `08.inline.default-mode`, `08.inline.on-dependency-failure` | `ADVISORY`, `FAIL_OPEN` | `InlineConfigService` | Đối tượng chưa đặt riêng |
| `08.issue.sla-days`, `08.issue.auto-open-critical` | 5, 15, 30; 100 | `SlaClock`, `AutoOpenJob` | Phiếu mới, không đổi hạn phiếu cũ |
| `08.finding.retention-months` | 13 | `RetentionPurger` | Đêm kế tiếp |
| `08.scan.heartbeat-timeout-seconds`, `08.scan.task-max-attempts` | 180, 3 | `ScanWatchdog` | Ngay (đọc mỗi nhịp) |
| `08.verify.wait-mdm-minutes`, `08.verify.wait-source-minutes` | 60, 0 | `VerifyScanTrigger` | Phiếu mới `FIXED` |

: Tham số theo tenant mà thiết kế dựa vào

### 9.2. Cờ tính năng và cấu hình triển khai

Có bốn cờ: `dq.inline.enabled` (tenant, tắt khẩn cấp: `checks:evaluate` trả `PASS` kèm `degraded` mà không đánh giá), `dq.incremental.enabled` (tenant, mặc định tắt), `dq.report.sign.enabled` (tenant, mặc định tắt) và `dq.benchmark.enabled` (nền tảng, mặc định tắt, mức C). Cấu hình triển khai của bộ thực thi: hồ sơ Spring `worker,dq`, vai CSDL `ph08_app` cho `ph08_dq` và `dq_reader` cho khung nhìn PH-06, `statement_timeout` 15 phút, song song 2 tác vụ mỗi bản sao, `securityContext` không root và `readOnlyRootFilesystem`, tài nguyên theo §11.1.

## 10. Quan sát

Chỉ số phát ra qua Micrometer sang Prometheus, tiền tố `dq_` theo NFR-08-005 và NFR-08-015 (nếu chuẩn chung đòi `datahub_` thì đổi đồng loạt). Nhãn có bậc số lượng nhỏ; tuyệt đối không dùng khóa bản ghi, giá trị, tên người làm nhãn (SEC-32); nhãn `asset` chỉ có ở chỉ số điểm và lần đo.

| Nhóm | Chỉ số | Nhãn | Dùng cho |
|---|---|---|---|
| Lần đo | `dq_scan_jobs_total`, `dq_scan_duration_seconds`, `dq_scan_queue_depth`, `dq_scan_tasks_queued`, `dq_scan_missed_schedule_total` | `asset`, `status`, `trigger` | NFR-08-003, 019; KEDA |
| Bộ thực thi | `dq_task_duration_seconds`, `dq_rows_scanned_total`, `dq_source_query_seconds`, `dq_source_throttle_wait_seconds` | `kind`, `asset_type` | Tải lên nguồn |
| Điểm | `dq_score_gauge`, `dq_score_computed_total`, `dq_score_flag_total` | `asset`, `dimension`, `verdict`, `flag` | Bảng Grafana điểm |
| Lỗi | `dq_findings_total`, `dq_finding_write_duration_seconds`, `dq_finding_truncated_total`, `dq_finding_sensitive_plain_violations` | `dimension`, `severity`, `status` | Top quy tắc vi phạm; NFR-08-016 |
| Trực tuyến | `dq_check_total`, `dq_check_duration_seconds`, `dq_inline_rule_cache_hit_ratio`, `dq_check_degraded_total`, `dq_inline_timeout_total` | `result`, `mode`, `reason` | NFR-08-001, 002, 005 |
| Danh mục | `dq_rdm_lookup_duration_seconds`, `dq_rdm_cache_hit_ratio`, `dq_rdm_breaker_state`, `dq_rdm_skipped_total` | `tier`, `catalog` | NFR-08-006 |
| Khắc phục | `dq_issues_open`, `dq_issues_overdue`, `dq_issue_sla_met_ratio`, `dq_verify_scans_total` | `severity`, `result` | KPI cho PH-16 |
| Cảnh báo, báo cáo | `dq_alerts_firing`, `dq_reports_total`, `dq_report_render_seconds`, `dq_report_sign_failures_total` | `severity`, `type`, `format` | NFR-08-012 |
| Sự kiện, vận hành | `dq_outbox_lag_seconds`, `dq_outbox_pending`, `dq_inbox_dlq_total`, `dq_retention_rows_purged_total`, `dq_audit_write_failure_total` | `object` | NFR-08-018 |

: Chỉ số quan sát của PH-08

**Log** là JSON có `traceId`, `tenant`, `module = dq`, `assetCode`, `scanId`, `taskId`, không bao giờ có giá trị trường hay khóa bản ghi rõ. **Trace** (NFR-08-020): span `dq.scan`, `dq.task`, `dq.source.query`, `dq.rdm.lookup`, `dq.finding.write`, `dq.score`, `dq.inline.evaluate`, `dq.report.render`; `traceparent` ghi vào `trace_id` của outbox và truyền sang PH-05, PH-06, PH-07. **Cảnh báo vận hành** (chuyển PH-13): `dq_scan_jobs_total{status="FAILED"}` tăng; `dq_scan_queue_depth` > 50 quá 2 giờ; `dq_outbox_lag_seconds` > 60; p95 `dq_check_duration_seconds` > 50 ms trong 10 phút; `dq_inline_rule_cache_hit_ratio` < 0,95; `dq_rdm_breaker_state` mở quá 5 phút; `dq_finding_sensitive_plain_violations` > 0; `dq_audit_write_failure_total` > 0.

## 11. Hiệu năng, dung lượng, mô hình triển khai

### 11.1. Mô hình triển khai

PH-08 chạy ở namespace `dh-control` (D03-09 §4), hai Deployment cùng ảnh. Theo hồ sơ `QM-VUA` của D03-09, `dh-data` baseline là 2 bản sao × (1 vCPU yêu cầu, 2 giới hạn; 3 GiB); phần riêng của PH-08 dưới đây là giả định đề nghị bổ sung vào D03-09 (§13.6).

| Thành phần | Bản sao | Tài nguyên mỗi bản sao | Tự co giãn | Ghi chú |
|---|---|---|---|---|
| `dh-data` hồ sơ `api` (dùng chung PH-06…09) | 2, tối đa 4 | 1/2 vCPU, 3 GiB | HPA theo CPU 65% | REST, trực tuyến, bộ lập lịch; thêm khoảng 0,5 GiB cho bộ đệm quy tắc |
| `dh-data-dq-worker` (hồ sơ `worker`) | 2 nghỉ, 4 giai đoạn 1, tối đa 8 | 1/2 vCPU, 3 GiB | KEDA theo `dq_scan_tasks_queued` (thêm khi > 2 tác vụ chờ mỗi bản sao) | Gần tuyến tính đến 8 (NFR-08-019); `terminationGracePeriodSeconds` 330 |
| Bucket Ceph RGW `dq-reports` | Theo nền tảng | Khoảng 50 MB mỗi năm | Không | Object Lock, lưu 10 năm |

: Mô hình triển khai PH-08 theo QM-VUA (giả định)

Mọi Deployment có `PodDisruptionBudget minAvailable: 1`, `topologySpreadConstraints` qua ba vùng lỗi và `NetworkPolicy` như §2.1. Bộ thực thi nhận `SIGTERM` thì ngừng nhận tác vụ mới, hoàn tất lô đang chạy rồi trả tác vụ dở về `QUEUED`. Cấu hình nghiệm thu NFR (hai bản sao 4 vCPU 8 GB, bốn bộ thực thi) lớn hơn baseline `QM-VUA`; baseline là điểm xuất phát và sẽ chỉnh theo kết quả đo ở UAT.

### 11.2. Ngân sách hiệu năng

**Trực tuyến (NFR-08-001, 002).** Ngân sách ở §4.9 là khoảng 27 ms đồng hồ cho 50 quy tắc, trong đó CPU thuần khoảng một nửa. Thông lượng 2.000 bản ghi mỗi giây trên hai bản sao là 1.000 mỗi giây mỗi bản sao: với 12 ms CPU (50 quy tắc) cần khoảng 12 vCPU mỗi bản sao, vượt cả cấu hình nghiệm thu 4 vCPU; với 10 quy tắc (giả định 2 ms CPU) cần khoảng 2 vCPU và đạt được. Chỉ tiêu thông lượng vì vậy chỉ đạt khi đối tượng trực tuyến có ít quy tắc (giả định 5 đến 15): rủi ro R-04 (§13.3) và Q08-29.

**Đo `FULL` (NFR-08-003: 1 triệu bản ghi, 30 quy tắc, ≤ 60 phút với bốn bộ thực thi).** Mức sàn tương ứng khoảng 280 bản ghi mỗi giây cho cả cụm, thấp có chủ ý vì gồm quy tắc đọc dòng; với quy tắc đẩy xuống thuần, một câu tập hợp quét 200.000 dòng trên nguồn có chỉ mục dự kiến xong trong vài giây đến vài chục giây (giả định, đo ở UAT).

**Tải tổng hợp theo GĐ.** Phân bố giả định cho `T01`: năm đầu 60 đối tượng (5 đối tượng 1,5 triệu bản ghi, 15 đối tượng 500 nghìn, 40 đối tượng 50 nghìn), tổng khoảng 17 triệu bản ghi mỗi tháng; năm thứ ba 200 đối tượng (5, 30 và 165 đối tượng ở ba cỡ đó), khoảng 31 triệu. Ở mức sàn NFR-08-003, bốn bộ thực thi đo năm đầu trong khoảng 17 giờ (hai đêm trong cửa sổ 22:00 đến 05:00); tám bộ thực thi đo năm thứ ba trong khoảng 19 giờ (ba đêm). Lịch mặc định đặt cả tháng vào ngày 1, 02:00 nên `ScanPlanner` xếp đối tượng lớn trước, đối tượng nhỏ chạy các đêm sau; BR-08-001 chỉ đòi mỗi tháng một lần.

### 11.3. Dung lượng

Các bảng tăng nhanh nhất với tenant `T01`, theo giả định của FRS.

| Dữ liệu | Công thức giả định | Dung lượng |
|---|---|---|
| `dq_finding` (13 tháng) | ≤ 10 triệu dòng, khoảng 0,35 KB mỗi dòng gồm chỉ mục (60 đối tượng × 30 quy tắc × lỗi 5%) | Khoảng 3,5 GB, tăng khoảng 3 GB mỗi tháng phân vùng |
| `dq_inline_stat` (90 ngày) | 20 đối tượng trực tuyến × 3 bên gọi × 1.440 phút × 90 ngày | Khoảng 7,8 triệu dòng, 3 GB |
| Ảnh chụp, kết quả quy tắc, báo cáo | Hàng nghìn dòng mỗi năm, báo cáo vài MB | Dưới 0,5 GB |
| Bộ đệm quy tắc trực tuyến | 200 đối tượng × 30 quy tắc đã biên dịch × 50 KB | Dưới 300 MB |

: Dung lượng giả định của PH-08 cho tenant T01

Tổng dữ liệu ở `pg-core` dưới 15 GB sau 13 tháng, nhỏ so với hạn mức 200 GB mỗi tenant (D03-10 §5.3). Truy vấn lỗi theo đối tượng và trạng thái dùng `ix_dq_finding_asset` nên đạt NFR-08-011 (≤ 1,5 giây p95 với 10 triệu dòng). Tải đo theo lô lên bản sao đọc bị giới hạn bằng cửa sổ giờ và `SourceThrottle`.

### 11.4. Phục hồi sau sự cố và vận hành

PH-08 không giữ trạng thái ngoài `pg-core`, Kafka và kho đối tượng, nên RPO ≤ 15 phút, RTO ≤ 30 phút theo hạ tầng (ADR-034). Sau chuyển site: Debezium phát lại outbox; `ScanWatchdog` thu hồi lần đo `RUNNING` và chạy lại từng tác vụ; lịch lỡ bù một lần.

## 12. Kiểm thử

Chiến lược chia theo lớp; chi tiết ca nằm ở D05-02-PH08.

| Lớp | Nội dung | Ví dụ ca |
|---|---|---|
| Đơn vị | `DimensionScorer`, `FingerprintService`, `ValueMasker`, `SlaClock`, `PushdownTranslator`, `SqlAllowlistValidator`, `Sampler`, `TaskSharder` | Ví dụ FRS cho 86,37; thiếu `VALIDITY` cho 86,71 kèm cờ; khác phiên bản quy tắc vẫn cùng dấu vân tay; `pg_sleep` bị chặn; SLA qua cuối tuần |
| Tương đương SQL và CEL | Cùng quy tắc chạy bằng pushdown và CEL phải cùng số vi phạm | 10.000 dòng biên: rỗng, khoảng trắng, Unicode, số lớn; regex RE2 so với PostgreSQL |
| Tích hợp (Testcontainers) | PostgreSQL có RLS và phân vùng, Kafka, OpenBao dev, nguồn giả, WireMock PH-07 | Đo 100.000 dòng có lỗi gieo trước, kiểm số đếm, dấu vân tay, `RESOLVED` kỳ sau; tenant A không thấy tenant B |
| Đồng thời, chịu lỗi | Nhiều bộ thực thi; tắt PH-07, Valkey, OpenBao; nguồn rớt giữa chừng | Một lần đo hoạt động mỗi đối tượng; mất nhịp tim không nhân đôi lỗi; PH-07 tắt cho `PARTIAL`; độ phủ dưới 95% cho `FAILED` |
| Tái lập, hợp đồng | Hai lần đo cùng dữ liệu và seed; lược đồ sự kiện Apicurio | Điểm sai số ≤ 0,01, cùng tập `recordKey`; sự kiện không có khóa `value`, `recordKey` |
| Hiệu năng, bảo mật | k6 cho trực tuyến; dữ liệu sinh 1 triệu dòng; ArchUnit; quét CCCD ở CSDL và log | NFR-08-001…004, 012, 013, 019; không đường ghi nào ngoài `FindingWriter` vào `dq_finding`; 0 giá trị `SENSITIVE` rõ |

: Chiến lược kiểm thử của PH-08

Dữ liệu kiểm thử là dữ liệu sinh (SEC-38) ở tenant T90 đến T99, có nhiễu: trường rỗng, khoảng trắng, mã danh mục cũ, ngày ngoài khoảng, trùng khóa, định dạng sai.

## 13. Lộ trình hiện thực, rủi ro và câu hỏi mở

### 13.1. Lộ trình

PH-08 thuộc đợt 3. Thứ tự theo mức ưu tiên FR (M, S, C) và phụ thuộc: đo lô cần khung nhìn PH-06 và API PH-07, trực tuyến cần quy tắc đã duyệt.

| Mốc | Nội dung |
|---|---|
| M1 · Lõi đo lô | `catalog`, `rule`, `compile` (SQL, regex), `scan`, `worker`, `rdm`, `score`, `finding`; đạt NFR-08-003, 007 |
| M2 · Vòng khép kín | `remediation`, `report`, `outbox`, bảng điều khiển, `ops`; KPI sang PH-16 |
| M3 · Trực tuyến, nguồn HTTT | `inline`, Kamelet, cổng PH-06, nguồn qua PH-05, CEL; đạt NFR-08-001, 002, 005 |
| M4 · Hoàn thiện | `profile`, tăng dần, cảnh báo, ngoại lệ, chuyển steward, ký số, so sánh liên tenant |

: Lộ trình hiện thực PH-08

### 13.2. Truy vết hệ cũ

Hệ cũ không có chức năng chất lượng dữ liệu; REQ-08 là năng lực mới. Truy vết gián tiếp theo FRS: LGC-DMDC-006, 007, 008 (PH-08 đo danh mục sau nhập qua `RDM_CATALOG`), LGC-BUS-027 (tương ứng thống kê trực tuyến ở `inline`), LGC-NGSP-003, 005 (nguồn đối chiếu cho `EQ_SOURCE`). Không có LGC nào do PH-08 làm chính.

### 13.3. Ma trận thành phần với FR và rủi ro

Ma trận cho thấy mỗi thành phần phủ FR nào; đủ 61 FR đều có nơi hiện thực.

| Thành phần | FR hiện thực chính | Bảng ghi |
|---|---|---|
| `catalog` | 001 đến 007 | `dq_domain`, `dq_asset`, `dq_asset_field` |
| `profile` | 008 đến 011 | `dq_profile_run`, `dq_profile_column` |
| `rule` | 012, 013, 015, 016, 017 đến 022 | `dq_rule_set`, `dq_rule_set_version`, `dq_rule`, `dq_rule_template`, `dq_weight_config` |
| `compile` | 013, 014, 016, 026 | Không |
| `scan` | 023, 024, 025, 030, 031 | `dq_schedule`, `dq_scan_job`, `dq_scan_task` |
| `worker`, `rdm` | 026, 027, 031 | `dq_rule_result` |
| `inline` | 032 đến 035 | `dq_inline_stat` |
| `score` | 028, 029, 050, 051 | `dq_score_snapshot`, `dq_score_dimension` |
| `finding` | 036 đến 040 | `dq_finding`, `dq_waiver`, `dq_export_request` |
| `remediation` | 041 đến 046 | `dq_issue`, `dq_issue_activity` |
| `alert` | 047 đến 049 | `dq_alert_rule`, `dq_alert` |
| `report` | 052 đến 056 | `dq_report`, `dq_report_subscription` |
| `outbox`, `ops` | 057 đến 061 | `outbox_event`, `inbox_event`, `dq_tenant_setting`, `dq_retention_policy`, `shedlock` |

: Ma trận thành phần với FR

Năm rủi ro chính và cách giảm thiểu:

| Mã | Rủi ro | Giảm thiểu |
|---|---|---|
| R-01 | Truy vấn đo làm chậm CSDL của HTTT | Cửa sổ giờ, hai truy vấn đồng thời, `statement_timeout`, chỉ `SELECT`, đo trên bản sao khi có |
| R-02 | Lệch kết quả giữa SQL đẩy xuống và CEL, giữa regex RE2 và regex động cơ | Ca tương đương bắt buộc (§12); Q08-23 |
| R-03 | Đổi khóa HMAC làm mọi lỗi tưởng là mới | Quy trình đổi khóa có phiên bản (Q08-26); cảnh báo khi tỷ lệ lỗi mới tăng đột biến |
| R-04 | Thông lượng trực tuyến 2.000 bản ghi mỗi giây vượt baseline CPU | Giới hạn số quy tắc mỗi đối tượng, đo sớm ở M3, mở rộng `api` |
| R-05 | Bản ghi lỗi thành kho dữ liệu cá nhân thứ cấp | Che theo PH-09, `ck_dq_finding_no_raw`, quét tự động mỗi bản phát hành, lưu 13 tháng |

: Rủi ro của thiết kế PH-08

### 13.4. Quyết định kiến trúc đề xuất

Dải ADR 085 đến 089 dành cho PH-08 (D00-04 §3.1); tập này tóm tắt ba quyết định chính, tệp ADR do luồng tài liệu chung lập.

| Số đề xuất | Tiêu đề | Bối cảnh, quyết định, hệ quả (tóm tắt) |
|---|---|---|
| ADR 085 | Thực thi quy tắc bằng SQL pushdown, CEL và DataSketches | Đo hàng triệu bản ghi mà không kéo dữ liệu về, giữ một stack Java. Quy tắc tập hợp dịch thành một câu `SUM(CASE …)` có danh sách cho phép; mức bản ghi chạy bằng `cel-java` đã biên dịch; hồ sơ bằng DataSketches. Hệ quả: không thêm dịch vụ Python nhưng phải giữ lớp dịch động cơ. Phương án khác: Great Expectations, Soda |
| ADR 086 | Bản ghi lỗi có dấu vân tay HMAC, che theo PH-09, phân vùng tháng | Biết lỗi mới, còn, hết qua các kỳ mà không giữ dữ liệu cá nhân. HMAC-SHA256 khóa theo tenant (không có phiên bản quy tắc), `SENSITIVE` chỉ lưu băm, phân vùng theo `last_seen_at`, lưu 13 tháng. Hệ quả: dọn bằng `DROP PARTITION`; đổi khóa cần quy trình riêng. Phương án khác: SHA-256 trần |
| ADR 087 | Truy cập dữ liệu đo qua khung nhìn hợp đồng PH-06 và kết nối PH-05 chỉ đọc | Đo dữ liệu của PH khác và HTTT mà không phá ranh giới schema. `ph06_mdm.v_dq_{domain}` trên bản sao với vai `dq_reader`; bảng HTTT qua PH-05 chỉ đọc (Q359, ADR-067); cấm đọc schema `ph{nn}_*`. Hệ quả: PH-06 giữ khung nhìn ổn định, PH-05 cấp kết nối. Phương án khác: đọc bảng vật lý |
| ADR 088, 089 | Trực tuyến trong `dh-data` với bộ đệm quy tắc trong bộ nhớ (§4.9); PDF bằng OpenHTMLtoPDF, ký PAdES qua dịch vụ nền tảng (§4.14) | Đã nêu ở FRS, chốt ở SDD, không có tệp riêng |

: Quyết định kiến trúc đề xuất cho PH-08

### 13.5. Câu hỏi mở

> **Đã chốt Q08-20:** FRS 0.2 ghi lịch do bộ lập lịch nội bộ dưới ShedLock, PH-18 chỉ kích hoạt thêm qua `POST /scans` (phụ thuộc mềm); nguồn chân lý của lịch là `dq_schedule`.

Chín câu hỏi sau chưa có trả lời; thiết kế dùng phương án nêu ở mục tương ứng.

| Mã | Câu hỏi |
|---|---|
| Q08-21 | Bộ thực thi mở kết nối trực tiếp tới CSDL HTTT bằng thông tin thuê từ PH-05 hay mọi truy vấn đi qua proxy hoặc `probe-jvm` của PH-05 (ADR-067) |
| Q08-22 | Động cơ `SOURCE_DATASET` nào ngoài PostgreSQL được hỗ trợ đầu tiên, và `DialectAdapter` cho `REGEX`, hàm ngày, hàm băm lấy mẫu |
| Q08-23 | `REGEX` RE2 dịch sang cú pháp động cơ nguồn khi đẩy xuống hay luôn đánh giá ở Java cho cùng nghĩa với trực tuyến |
| Q08-24 | `cel-java` được chọn có giới hạn chi phí và ngắt giữa chừng không, hay dựa vào đồng hồ và giới hạn cấu trúc (§4.5) |
| Q08-25 | Tái lập mẫu khi đổi động cơ nguồn: hàm băm lấy mẫu thống nhất hay chỉ "cùng seed cùng mẫu" trong một động cơ |
| Q08-26 | Đổi khóa HMAC theo tenant: lưu số hiệu phiên bản khóa cạnh `fingerprint` hay chấp nhận một kỳ lỗi "mới" |
| Q08-27 | Object Lock của Ceph RGW cho báo cáo công bố dùng chế độ tuân thủ hay quản trị; báo cáo `WITHDRAWN` có giữ nguyên bản không |
| Q08-28 | Bộ thực thi có cần node pool `batch`, `ResourceQuota`, `PriorityClass` thấp hơn API trực tuyến khi chạy tám bản sao (D03-09) |
| Q08-29 | p95 ≤ 50 ms (NFR-08-001) đo tại máy chủ (không tính APISIX) hay tại bên gọi; nếu tại bên gọi thì giảm số quy tắc tối đa mỗi đối tượng |

: Câu hỏi mở của SDD PH-08

### 13.6. Đề nghị đồng bộ

> **Đợt đồng bộ chéo cuối (27/11/2026).** Các đề nghị dưới đây đã được xét; kết luận từng dòng (đã sửa, đã khớp sẵn, câu hỏi mở, không làm) ghi ở [D00-03-01 Sổ đồng bộ chéo cuối](../../00-chung/D00-03-01-so-dong-bo-cuoi.md).

Các đề nghị của bản 0.1 về FRS và CSDL (HMAC, ví dụ 86,37, PH-18 phụ thuộc mềm, cột và bảng mới, `failFast`, `Idempotency-Key`) đã được FRS 0.2 và CSDL 0.2 hấp thụ (FRS chương 15, ĐN-SDD-01…12). Bảng dưới là phần dồn đợt đồng bộ cuối.

| Tài liệu | Đề nghị | Mục SDD |
|---|---|---|
| D02-03-PH06, D03-02-PH06 | `QualityGatePort` và `StewardIntakeApi` ở `mdm::api` (đảo phụ thuộc); khung nhìn `v_dq_{domain}` ổn định; lý do hàng đợi `DQ_FINDING` | §4.2, 4.12; Q08-08 |
| D02-03-PH05, D03-02-PH05 | API thuê kết nối chỉ đọc có hạn cho `dq`; khám phá lược đồ; Kamelet `dh-dq-check` với tiêu đề `dh-dq-verdict`, `dh-dq-violations`; scope `dq.ingest` | §4.2, 4.7; Q08-09, Q08-21 |
| D03-02-PH07 | `RdmLookupApi` trả ảnh chụp tập mã theo phiên bản dạng luồng; EVT-07-05 mang phiên bản mới; quyền khai thác danh mục hạn chế cho tài khoản PH-08 | §4.8 |
| PH-09, PH-13 | PH-09: `ClassificationLookupApi` p95 ≤ 100 ms, sự kiện đổi phân loại. PH-13: API lịch ngày làm việc và ngày lễ theo tenant cho `SlaClock`, tiêu thụ EVT-08-02…14 | §4.2, 4.12 |
| D03-09, D03-10, D04-01 | D03-09: hàng `dh-data-dq-worker` (4 bản sao ở `QM-VUA`, tối đa 8), `ScaledObject` KEDA, bucket Ceph `dq-reports`. D03-10: ngoại lệ RLS duy nhất cho so sánh liên tenant. D04-01: năm quy tắc ArchUnit của `dq` (§3.2) | §11.1, 6, 3.2 |
| D00-04 §2, §3.2 | Dòng PH-08: SDD 0.2; chạy lại `kiem_tra_ma.py --cap-nhat-so-tra-cuu` | Sổ tra cứu |

: Đề nghị đồng bộ còn lại

## Lịch sử phiên bản

| Phiên bản | Ngày | Người | Nội dung |
|---|---|---|---|
| 0.1 | 26/11/2026 | Nhóm viết tài liệu (Claude) | Bản đầu theo K-SDD và K-TRINH-BAY: module `dq` với 14 thành phần có khối đặc tả 10 mục, trình biên dịch SQL pushdown và CEL, điều phối đo phân mảnh với ShedLock, thuật toán chấm điểm, lấy mẫu có seed, dấu vân tay HMAC, năm sơ đồ trình tự, mô hình triển khai và dung lượng giả định, ma trận thành phần với FR, ADR đề xuất 085 đến 087, câu hỏi mở Q08-20…29, đề nghị đồng bộ |
| 0.2 | 26/11/2026 | Nhóm viết tài liệu (Claude) | Đồng bộ với FRS 0.2 và CSDL 0.2: 35 bảng, 43 tham số, 132 API (thêm API-08-129 tìm lỗi theo khóa, 130 và 131 bật, tắt đo tăng dần, 132 xem trước trọng số), ERR-08-055, ERR-08-056, scope `dq.ingest`, `value_mode`, mã phiếu và mã báo cáo, `scanTrigger` của `POST /scans`, `ADVISORY` trả `WARN` khi có vi phạm, lô tối đa 100 bản ghi, `VERIFY` do hệ thống tạo; Q08-20 đã chốt; §13.6 chỉ còn đề nghị dồn đợt cuối |
| 0.3 | 27/11/2026 | Nhóm viết tài liệu (Claude) | Đồng bộ chéo cuối: bucket báo cáo `dq-reports`; đổi tên giao diện gọi PH-09 thành `ClassificationLookupApi`, `MaskPlanApi`; đệm phân loại tối đa 60 giây |
