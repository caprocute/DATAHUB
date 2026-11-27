---
ma_tai_lieu: D03-02-PH18
ten: Thiết kế chi tiết phần mềm phân hệ PH-18 Vận hành và xử lý lỗi
phien_ban: 0.3
ngay: 2026-11-27
trang_thai: Dự thảo
nguoi_doc: Kỹ sư dh-platform, kỹ sư tích hợp các phân hệ dùng tham số, DLQ, thông báo và hộp việc, DBA, vận hành nền tảng, ATTT, kiểm thử viên, kiến trúc sư, hội đồng thẩm định
phan_he: PH-18
mo_ta: Thiết kế chi tiết hiện thực 72 FR của PH-18 gồm cấu trúc package vn.datahub.platform.ops tám module, thư viện khách dh-ops-client, 25 thành phần với khối đặc tả 10 mục, worker dh-ops-worker trong dh-batch, mười lăm sơ đồ trình tự, máy trạng thái, outbox và lũy đẳng, đa tenant RLS, bảo mật, quan sát, triển khai và kiểm thử.
tai_lieu_lien_quan: D02-03-PH18 FRS; D02-04-PH18 Use case; D03-03-PH18 CSDL; D03-04-PH18 API; D03-06-PH18 Màn hình; D03-01 SAD; D03-07 ATTT; D03-09 Hạ tầng và DR; D03-10 Thiết kế đa tenant; ADR-180 đến ADR-184
---

# D03-02-PH18 · Thiết kế chi tiết Vận hành và xử lý lỗi

## Tóm tắt cho hội đồng thẩm định

Tài liệu mô tả cách hiện thực 72 FR của [D02-03-PH18](../../02-yeu-cau/frs/D02-03-PH18-frs-van-hanh.md). PH-18 là phân hệ "hậu cần" của Datahub: giữ tham số theo tenant cho mọi phân hệ, gom mọi bản tin lỗi về một hàng đợi lỗi (DLQ) chung để người vận hành tìm, sửa có kiểm soát, phát lại hoặc bỏ qua có lý do, gửi thư và SMS, cấp "Việc của tôi" và lịch ngày làm việc, mở hồ sơ sự cố, theo dõi sao lưu, khôi phục một tỉnh mà không ảnh hưởng tỉnh khác, và chạy công cụ di trú từ hệ cũ sang Datahub. Hệ cũ chỉ có màn DLQ thô và API lấy, cập nhật tham số (SRS cũ FR-18-001…020); các năng lực còn lại là thiết kế mới. Bảy quyết định chi phối thiết kế:

1. **Một module Modulith trong `dh-platform`, việc nặng ra Job.** PH-18 là module `vn.datahub.platform.ops` gồm tám module con (`param`, `dlq`, `notify`, `task`, `incident`, `backup`, `migration`, `report`) cộng lõi chung `common`. Tác vụ nặng (khôi phục tenant, xuất tenant, chuyển sáp nhập, di trú) chạy thành Job Kubernetes trong namespace `dh-batch` bằng một ảnh `dh-ops-worker` có ba công cụ `dh-tenant-restore`, `dh-tenant-export`, `dh-migrate`, nên không tranh tài nguyên với màn hình và API.
2. **Kho tham số trên `ph18_ops`, đọc qua thư viện khách có bộ đệm** (ADR-180). Phân hệ khác không gọi PH-18 mỗi lần đọc: thư viện `dh-ops-client` giữ ảnh chụp theo không gian tên trong Caffeine tối đa 60 giây, làm mới ngay khi nhận EVT-18-01, và khi PH-18 vắng thì dùng bản cũ rồi mặc định đóng gói (fail-soft, BR-18-007).
3. **DLQ hợp nhất, payload gốc bất biến** (ADR-181). Bản tin lỗi vào qua topic `{tenant}.ops.dlq.v1` hoặc API ghi; PH-18 chỉ commit offset sau khi chỉ mục bền, nên ngừng hay lỗi CSDL không làm mất bản tin. Thiếu ngữ cảnh thì vào `POISON`; payload lớn hơn 256 KB vào Garage `dh-{tenant}-ops`; DLQ tầng sự kiện của PH-10 chỉ được liên thông siêu dữ liệu.
4. **Phát lại luôn qua lối vào của nguồn** (ADR-182). Mỗi nguồn khai báo một cổng phát lại (`ReplayPort`); PH-18 không bao giờ gọi thẳng hệ đích. Khóa lũy đẳng `dlqId:revision`, tốc độ giới hạn bằng thùng token trên Valkey, loạt vượt ngưỡng cần người thứ hai duyệt.
5. **Thông báo qua outbox, mẫu Mustache không logic** (ADR-184). Phân hệ gọi chỉ đưa `recipientRef`; PH-18 tự phân giải địa chỉ, áp tùy chọn nhận, giờ yên lặng và danh sách chặn; mẫu chứa trường mức Hạn chế hoặc Nhạy cảm bị từ chối ngay khi duyệt.
6. **Khôi phục tenant tám bước theo RBK-04.** Một máy trạng thái ở `dh-platform` điều khiển Job `dh-tenant-restore`; dữ liệu trích trên cụm tạm cô lập mạng (vai có `BYPASSRLS` chỉ tồn tại ở cụm tạm), thay trên cụm thật trong giao dịch có `SET LOCAL app.tenant_id` nên RLS chặn mọi lỗi chạm tỉnh khác.
7. **Di trú bằng Spring Batch, ghi qua API nhập của phân hệ đích** (ADR-183). Bộ chuyển theo từng loại đối tượng, chạy thử không ghi rồi chạy thật có bốn mắt, đối chiếu số lượng và tổng kiểm tra; chạy song song có đối soát bóng từ lưu lượng nhân bản, cắt chuyển theo nhóm dịch vụ và quay lui trong 15 phút.

Số liệu hiệu năng ở chương 11 là ước lượng theo hồ sơ tỉnh vừa (GĐ-07, tỉnh T01, 200 HTTT) và đánh dấu "giả định". Tập ghi mười câu hỏi mở Q18-20…29 và mười điểm lệch giữa FRS, CSDL, ADR, SAD ở mục 13.5, kèm đề nghị đồng bộ ở mục 13.6.

## 1. Phạm vi và cách đọc

Chương này nói tài liệu dùng để làm gì, ai đọc phần nào, quy ước viết và các tài liệu nguồn. Người đọc lần đầu nên xem mục 1.5 để biết chương nào trả lời câu hỏi nào.

### 1.1. Mục đích và phạm vi

Tập này là thiết kế chi tiết cấp mã nguồn của PH-18: cấu trúc package, thư viện khách, thành phần, thuật toán (khử trùng, gom nhóm, giới hạn tốc độ, thứ tự phụ thuộc di trú), trình tự, máy trạng thái, lỗi, cấu hình, quan sát, triển khai và kiểm thử. Phạm vi gồm 72 FR (FR-18-001…072) chạy ở module `ops` của DU `dh-platform` và ở ảnh worker `dh-ops-worker`.

Không thuộc phạm vi: lược đồ bảng (D03-03-PH18), đặc tả endpoint (D03-04-PH18 và `api/ph18/openapi-ops.yaml`), nội dung màn hình (D03-06-PH18), luật cảnh báo và lịch trực (PH-13), thử lại và `errorHandler` của luồng (PH-04), DLQ tầng sự kiện và duyệt phát lại sự kiện (PH-10), vòng đời tenant và điều phối sáp nhập (PH-20), quyền (PH-12), đồng hồ 72 giờ của sự cố dữ liệu cá nhân (PH-09), tham số `19.*` (PH-19) và Helm values không theo tenant.

### 1.2. Người đọc

Kỹ sư `dh-platform` đọc chương 3, 4, 8, 9. Kỹ sư các phân hệ dùng tham số, DLQ, thông báo, hộp việc đọc §3.3, §4.4, §4.6, §4.11, §4.14, §4.16 và sơ đồ §5.1, §5.2, §5.7. DBA và vận hành nền tảng đọc §4.19 đến §4.22, chương 6 và 11. ATTT đọc chương 7 và §4.9, §4.20. Kiểm thử viên đọc chương 8 và 12. Hội đồng thẩm định đọc phần tóm tắt, chương 2, 11 và 13.

### 1.3. Quy ước trong tài liệu

Tên lớp, package, trường, khóa tham số dùng dấu `` ` ``. Mã FR, BR, NFR, ERR, EVT, API, EN, UI lấy nguyên từ FRS; `SEC-*` lấy từ D03-07; `PERM-18-*` lấy từ D02-08; không tạo mã phần tử mới. Thành phần được gọi bằng tên lớp chính và số mục của tập này. Tenant ví dụ là `T68` (topic chữ thường `t68.`), tenant kiểm thử `T90…T99`. Số liệu chưa đo ghi "giả định" kèm cơ sở: hồ sơ tỉnh vừa GĐ-07, 1 triệu mục DLQ tồn mỗi tenant, 200 người dùng vận hành đồng thời, 34 tenant trên một cụm `pg-core` (giả định theo D03-09 §8.5).

### 1.4. Thuật ngữ và chữ viết tắt

Bảng ghi các thuật ngữ dùng xuyên suốt tập; thuật ngữ nghiệp vụ đầy đủ ở FRS §1.4 và §4.1.

| Thuật ngữ | Nghĩa trong tài liệu |
|---|---|
| DLQ | Dead Letter Queue, hàng đợi bản tin lỗi: chỉ mục `dlq_message` của PH-18 cộng topic `{tenant}.ops.dlq.v1` |
| Hợp đồng ngữ cảnh | Bộ header bắt buộc đi kèm bản tin lỗi (`dh-tenant`, `dh-source-ph`, `dh-dlq-reason`, `dh-dlq-error-code`, `dh-dlq-stage`, `dh-dlq-attempts`, `dh-flow`, `dh-version`, `traceparent`), FRS bảng 4.1b |
| `dlqKey` | Khóa khử trùng `sourceCode:flow:messageId:stage` (BR-18-015) |
| `POISON` | Mục thiếu ngữ cảnh bắt buộc hoặc không giải mã được, chỉ sửa hoặc bỏ qua |
| `ReplayPort` | Cổng phát lại do nguồn khai báo: `KAFKA_TOPIC`, `HTTP_PORT`, `EVENT_LAYER` (qua PH-10), `NONE` |
| Bốn mắt | Thao tác cần người thứ hai khác người đề nghị duyệt (FR-00-071) |
| Fail-soft | Khi PH-18 vắng, bên đọc vẫn chạy bằng bản đệm hoặc mặc định, không chặn đường chính |
| Outbox, inbox | Bảng `outbox_event` ghi cùng giao dịch nghiệp vụ rồi được chuyển lên Kafka (ADR-042); bảng `inbox_event` khử trùng sự kiện tiêu thụ |
| ShedLock | Khóa trên PostgreSQL để tác vụ định kỳ chỉ chạy ở một bản sao |
| Khóa tư vấn | `pg_advisory_xact_lock` của PostgreSQL, giữ đến hết giao dịch |
| Tác vụ nặng | Khôi phục, xuất, di trú thật, chuyển sáp nhập; mỗi tenant tối đa một (BR-18-039) |
| Cụm tạm | Cụm PostgreSQL dựng bằng PITR trong namespace cô lập để trích dữ liệu một tenant |
| Đối soát bóng | So phản hồi của hệ cũ và Datahub trên lưu lượng do APISIX nhân bản (shadow compare) |
| Cắt chuyển | Chuyển lưu lượng một nhóm dịch vụ từ hệ cũ sang Datahub, có cửa sổ quay lui |
| GĐ | Giả định có cơ sở, ghi ở chỗ dùng |

: Thuật ngữ và chữ viết tắt

### 1.5. Cấu trúc tài liệu

Chương 2 và 3 nói vị trí trong kiến trúc, cấu trúc mã, giao diện công bố và ánh xạ FR sang thành phần. Chương 4 là mô hình miền và 25 thành phần, mỗi thành phần mở bằng khối đặc tả 10 mục (mục đích, lớp chính, đơn vị chạy, FR hiện thực, giao diện vào, phụ thuộc ra, dữ liệu, sự kiện, lỗi và xử lý, quan sát). Chương 5 là mười lăm sơ đồ trình tự. Chương 6 đến 12 nói đa tenant, bảo mật, máy trạng thái và lỗi, cấu hình, quan sát, hiệu năng và triển khai, kiểm thử. Chương 13 là lộ trình, truy vết, rủi ro, ADR, điểm lệch, đề nghị đồng bộ và câu hỏi mở.

### 1.6. Tài liệu liên quan và quyết định kiến trúc

Bảng dưới ghi từng tài liệu hoặc ADR và phần nội dung tập này lấy từ đó.

| Tài liệu hoặc ADR | Nội dung dùng ở tập này |
|---|---|
| D02-03-PH18 FRS 0.1 | 72 FR, 50 BR, 22 NFR, 61 tham số `18.*`, ERR-18-001…072 và 101…124, EVT-18-01…29, API-18-001…180, EN-18-01…55, UI-18-01…24 |
| D02-04-PH18 UC 0.1 | 40 use case, các sơ đồ trình tự mức nghiệp vụ |
| D03-03-PH18 CSDL 0.1 | Schema `ph18_ops`, 57 bảng, bốn vai, RLS, bốn bảng phân vùng, kho ngoài PostgreSQL |
| D03-04-PH18 API | `openapi-ops.yaml` (`/api/ops/v1`, `/ops/internal/v1`), `asyncapi-ops.yaml`. Đã hấp thụ ở 0.2: API-18-188; API-18-029 có `304` không thân; trường `occurrences` ở `DlqMessage` |
| D03-01 SAD §4 | `dh-platform` Z3, `TPH-1`; nhóm `dh-batch` |
| D03-07 ATTT | SEC-15, SEC-16, SEC-24, SEC-26, SEC-28, SEC-31, SEC-32, SEC-33, SEC-60, SEC-70, SEC-71, SEC-74, SEC-80, SEC-81, SEC-82, SEC-85, SEC-87 |
| D03-09 §8 | Bảng đối tượng sao lưu §8.2, PITR §8.3, RBK-04 khôi phục một tenant §8.5, priority class `dh-batch` |
| D03-10 | `TenantContext`, `SET LOCAL app.tenant_id`, chế độ nền tảng |
| ADR-001, 003, 004, 012 | Spring Boot 4 và Modulith, PostgreSQL RLS, Kafka, OpenBao |
| ADR-041, 042, 046 | Idempotency, outbox và inbox, bốn mắt |
| ADR-180…184 | Năm quyết định của PH-18 (mục 13.4) |

: Tài liệu liên quan và ADR

## 2. Vị trí trong kiến trúc

Chương này đặt PH-18 vào kiến trúc chung: chạy ở đâu, gồm những khối nào, phụ thuộc phân hệ nào và suy giảm thế nào khi phụ thuộc lỗi. Ý chính là PH-18 nằm ở control plane và là phụ thuộc mềm của mọi phân hệ: nó vắng thì không có giao dịch HTTT nào hỏng (NFR-18-018).

### 2.1. Đơn vị triển khai và vùng mạng

PH-18 là module `ops` của DU `dh-platform` (Spring Boot 4, Spring Modulith, Java 21), chạy ở vùng Z3 trong namespace `dh-control`, tầng phục hồi `TPH-1`, cùng tiến trình với PH-11, PH-12 phần quản trị, PH-13, PH-16, PH-20 (SAD §4.3). Một ảnh `dh-platform` chạy hai hồ sơ: `profile=api` phục vụ REST `/api/ops/v1` qua APISIX và nội bộ `/ops/internal/v1` qua mTLS; `profile=worker` chạy bộ tiêu thụ Kafka (DLQ, sự kiện quy tắc thông báo, sự kiện PH-20), bộ gửi thông báo, bộ điều phối phát lại và tác vụ định kỳ. Hai hồ sơ tách để tải tiếp nhận DLQ hay gửi thư hàng loạt không làm chậm màn hình (đề nghị đồng bộ D03-09 ở mục 13.6).

Tác vụ nặng chạy thành Job Kubernetes trong namespace `dh-batch` (priority class `dh-batch`, không chiếm chỗ pod khác) bằng ảnh `dh-ops-worker`, một ảnh Spring Boot không có web, có ba lệnh: `dh-tenant-restore`, `dh-tenant-export` (dùng cho xuất tenant và chuyển sáp nhập) và `dh-migrate` (Spring Batch). Job đọc ghi `ph18_ops` bằng vai `ph18_worker` và báo tiến độ về `dh-platform` qua bảng trạng thái của mình. Dữ liệu ở schema `ph18_ops` của `pg-core`; payload lớn và tệp báo cáo ở Garage bucket `dh-{tenant}-ops`; bí mật ở OpenBao Z6, PH-18 chỉ giữ tham chiếu `kv/dh/{tenant}/...` (BR-18-048).

### 2.2. Sơ đồ thành phần

Sơ đồ C4 mức 3 dưới cho thấy các thành phần của PH-18 trong `dh-platform`, Job trong `dh-batch` và các hệ lân cận. Mũi tên ghi kênh chính; chi tiết từng kênh ở chương 4.

```{.mermaid caption="Sơ đồ thành phần C4 mức 3 của PH-18 trong dh-platform và dh-batch"}
flowchart TB
  CON["dh-console<br/>/van-hanh/*, /viec-cua-toi"]
  PHX["DU phân hệ khác<br/>dh-ops-client, mTLS"]
  P20["PH-20 Quản trị tenant"]
  subgraph Z2["Z2 · dh-gateway"]
    AX["APISIX<br/>/api/ops/v1, proxy-mirror"]
  end
  subgraph Z3["Z3 · dh-platform module ops"]
    WEB["Web và nội bộ<br/>Controller, ProblemMapper"]
    PRM["param<br/>registry, write, read, flag, seed"]
    DLQ["dlq<br/>ingest, triage, payload, replay, lifecycle"]
    NTF["notify<br/>template, dispatch, rule, bounce"]
    TSK["task<br/>inbox, calendar"]
    INC["incident"]
    BAK["backup<br/>status, restore, export, merge"]
    MIG["migration<br/>plan, run, parallel"]
    RPT["report<br/>báo cáo, sức khỏe"]
    CMN["common<br/>FourEyes, HeavyTaskLock, audit, outbox, inbox"]
  end
  subgraph BAT["dh-batch · Job dh-ops-worker"]
    RST["dh-tenant-restore"]
    EXP["dh-tenant-export"]
    MGR["dh-migrate<br/>Spring Batch"]
  end
  subgraph Z5["Z5 · Dữ liệu"]
    PG[("pg-core<br/>ph18_ops")]
    KF[("Kafka<br/>{tenant}.ops.*")]
    GR[("Garage<br/>dh-{tenant}-ops")]
    VK[("Valkey")]
  end
  OB["OpenBao"]
  MAIL["Máy chủ thư, SMS gateway<br/>IF-09"]
  LEG[("CSDL hệ cũ<br/>JDBC chỉ đọc IF-07")]
  NB["PH-03, 04, 09, 10, 12, 13<br/>API nội bộ"]
  CON --> AX --> WEB
  PHX -->|"/ops/internal/v1"| WEB
  P20 -->|"merge-transfers, seed"| WEB
  WEB --> PRM
  WEB --> DLQ
  WEB --> NTF
  WEB --> TSK
  WEB --> INC
  WEB --> BAK
  WEB --> MIG
  WEB --> RPT
  PRM --> CMN
  DLQ --> CMN
  BAK --> CMN
  MIG --> CMN
  CMN --> PG
  CMN -->|outbox| KF
  KF -->|"{tenant}.ops.dlq.v1"| DLQ
  KF -->|"EVT-18-01"| PHX
  DLQ --> GR
  DLQ --> VK
  DLQ -->|"ReplayPort"| NB
  NTF --> MAIL
  NTF --> NB
  BAK -->|"Job API K8s"| RST
  BAK --> EXP
  MIG --> MGR
  MGR --> LEG
  MGR -->|"API nhập"| NB
  RST --> PG
  EXP --> PG
  RST --> OB
  MGR --> OB
  AX -->|"mẫu bóng đã băm"| MIG
```

Hình cho thấy ba ranh giới. Thứ nhất, mọi thay đổi trạng thái đi qua lõi `common` (bốn mắt, khóa tác vụ nặng, kiểm toán, outbox) nên không module con nào tự ghi Kafka hay tự bỏ qua kiểm toán. Thứ hai, `dlq` chỉ trả bản tin về phân hệ nguồn qua `ReplayPort`, không có mũi tên tới HTTT đích. Thứ ba, chỉ Job trong `dh-batch` chạm dữ liệu khối lớn (cụm tạm, bản trích, CSDL hệ cũ); `dh-platform` chỉ tạo Job, theo dõi bước và ghi kết quả, nên một lần khôi phục 200 GB không ảnh hưởng độ trễ màn hình.

### 2.3. Phụ thuộc với module và phân hệ khác

Bảng ghi PH-18 gọi gì, bằng danh tính nào và suy giảm thế nào khi phụ thuộc lỗi. Chiều ngược (phân hệ khác gọi PH-18) ở §3.3.

| Phụ thuộc | PH-18 dùng để | Danh tính, kênh | Khi lỗi |
|---|---|---|---|
| `pg-core` (`ph18_ops`) | Mọi trạng thái, chỉ mục, lịch sử | Tài khoản động OpenBao của vai `ph18_app`, `ph18_worker` | Tiếp nhận DLQ tạm dừng phân vùng, không commit offset; API ghi trả `503` |
| Kafka | Tiêu thụ `{tenant}.ops.dlq.v1` và sự kiện quy tắc; phát `{tenant}.ops.*.v1` | mTLS, `KafkaUser` `svc-ops` | Outbox giữ sự kiện chờ; bản tin DLQ nằm ở topic chờ đọc lại (BR-18-011) |
| Garage | Payload lớn hơn 256 KB, bản sửa lớn, gói tham số, tệp báo cáo, gói xuất | Khóa truy cập theo bucket, lấy từ OpenBao | Tiếp nhận tạm dừng phân vùng (ERR-18-104); xem payload trả ERR-18-104 |
| Valkey | Thùng token tốc độ phát lại, khóa loạt, phiếu xem payload | mTLS | Tốc độ dùng hạn mức cục bộ chia số bản sao; phiếu xem cấp lại |
| OpenBao | Tài khoản CSDL động, SMTP, SMS gateway, thông tin kết nối hệ cũ | Kubernetes auth theo service account | Không gửi được thư (ERR-18-110); Job di trú không khởi động (ERR-18-062) |
| PH-04 runtime | Cổng phát lại `KAFKA_TOPIC` | Topic `{tenant}.ops.replay.requested.v1` | Mục chờ kết quả, quá hạn thành ERR-18-109 |
| PH-09 | Mức phân loại trường khi duyệt mẫu và sửa payload; nhận sự cố có dữ liệu cá nhân | `dh-privacy-client`, scope dịch vụ | Mẫu không duyệt được (đóng an toàn); sự cố thử lại mỗi 5 phút (ERR-18-054) |
| PH-10 | Siêu dữ liệu DLQ tầng sự kiện, phát lại sự kiện, cầu nối di trú | `event:dlq-read`, `event:replay` (API-10-060, 061, 063, 064) | Màn DLQ hiện phần PH-18, báo ERR-18-035 cho phần PH-10 |
| PH-12 | JWT, quyền, phân giải người, nhóm, vai trò cho người nhận và hộp việc | JWKS; scope dịch vụ đọc người dùng | Phân giải người nhận lỗi thì thông báo chờ thử lại |
| PH-13 | Kiểm toán (`dh-audit`), ngữ cảnh chẩn đoán API-13-069 | Thư viện `dh-audit` qua outbox; mTLS | Thao tác cần kiểm toán đồng bộ trả ERR-18-008; chẩn đoán fail-soft ERR-18-106 |
| PH-20 | Danh sách tenant `ACTIVE`, chuyển `SUSPENDED` và `ACTIVE` khi khôi phục, báo tiến độ sáp nhập | `tenant:registry-read`; API nội bộ `/internal/tenant/v1` | Tác vụ nền dùng danh sách đệm 10 phút; khôi phục dừng ở bước 4 |
| PH-03 | Đổi tuyến khi cắt chuyển, nhân bản lưu lượng chạy bóng | Sự kiện EVT-18-27 và API nội bộ PH-03 (Q18-26) | Không cắt chuyển được; quay lui dùng đường dự phòng §4.23 |
| Máy chủ thư, SMS gateway | Gửi thư, SMS (IF-09) | SMTP STARTTLS, REST mTLS hoặc TLS | Thử lại theo `18.notify.retry.*`, sau đó `FAILED` và EVT-18-13 |
| Kubernetes API | Tạo, theo dõi, hủy Job trong `dh-batch` | Service account `dh-platform-ops-jobs`, RBAC chỉ `batch/jobs` ở `dh-batch` | Yêu cầu giữ `APPROVED`, thử tạo lại mỗi phút |

: Phụ thuộc của PH-18

### 2.4. Hiện trạng mã và đường chuyển

Repo hiện có `apps/control` (package `vn.lgsp.control`, 65 tệp Java) với các module `catalog`, `onboarding`, `routes`; chưa có mã PH-18. Kế hoạch W2 đã có topic DLQ và header lỗi chuẩn phía Camel (`seda:dlq`, `LgspErrorCode`, `LgspStage`) nhưng chưa có giao diện PH-18; WP-40 (W4) giao "PROC skeleton + PH-18 DLQ API". SRS cũ `docs/07-srs/SRS-PH-18-ops.md` (FR-18-001…020 cũ, chỉ DLQ) đã được FRS ánh xạ sang FR mới ở FRS §11.3. Toàn bộ `vn.datahub.platform.ops.*`, thư viện `libs/dh-ops-client` và ảnh `dh-ops-worker` là mã mới; tên header Camel cũ được ánh xạ ở bộ chuẩn hóa ngữ cảnh (§4.6) trong thời gian PH-04 đổi tên (đề nghị đồng bộ PH-04, D04-01 CC-CAMEL-05).

## 3. Cấu trúc mã nguồn

Chương này nói mã của PH-18 nằm ở đâu, chia module thế nào, module nào được gọi module nào, phân hệ khác dùng giao diện nào, và mỗi FR do thành phần nào hiện thực. Đây là chương kỹ sư đọc trước khi tạo package đầu tiên.

### 3.1. Cây package

Module nằm ở `apps/platform/src/main/java/vn/datahub/platform/ops`, theo CC-MOD-01…05 của D04-01. `ops` là module Modulith cha; tám module con lồng nhau là tám package con trực tiếp, mỗi module con có ba gói `api`, `internal`, `events`; `common` là module mở (`@ApplicationModule(type = OPEN)`) chứa phần dùng chung trong `ops`. Mỗi gói con của `internal` ứng với một thành phần ở chương 4.

```text
vn/datahub/platform/ops/
|-- common/        (mở, dùng chung trong ops)  FourEyesGuard, HeavyTaskLock, OpsAuditRecorder,
|                  OutboxWriter, InboxGuard, TenantFanout, ProblemMapper, OpsClock, Reason
|-- param/         (nhóm A, FR-18-001…011, 069)
|   |-- api/        ParameterApi, FeatureFlagApi, EgressAllowlistApi, ParamSchemaRegistrationApi
|   |-- events/     ParamChanged (EVT-18-01), ParamApprovalRequested (02), FeatureFlagChanged (03), EgressChanged (04)
|   |-- internal/   registry/ (ParamSchemaRegistry, SchemaCompatibilityChecker)
|                   write/ (ParamWriteService, ParamValidator, ParamChangeApprovalService, ParamHistoryService)
|                   read/ (ParamReadService, EffectiveValueResolver, NamespaceSnapshotController)
|                   flag/, egress/, bundle/ (ParamBundleService), seed/ (TenantDefaultSeeder)
|-- dlq/           (nhóm B, C, D, FR-18-012…034)
|   |-- api/        DlqWriteApi, DlqReadApi, ReplayPort (SPI), ReplayResultApi
|   |-- events/     DlqReceived (05), PoisonDetected (06), DlqStateChanged (07), ThresholdCrossed (08),
|                   ReplayRequested (09), ReplayJobStateChanged (10), ErrorGuideChanged (11)
|   |-- internal/   ingest/ (DlqTopicConsumer, DlqIngestService, ContextContractValidator, DlqKeyDeduplicator,
|                   |        PayloadStore, HeaderNormalizer)
|                   federation/ (EventLayerDlqClient, EventDlqListener), reconcile/ (DlqReconciler)
|                   triage/ (DlqQueryService, SignatureGrouper, AssignmentService, DiagnosticsClient)
|                   payload/ (PayloadRevealService, RevealTicketStore), revision/ (RevisionService, PayloadPatcher)
|                   guide/ (ErrorGuideService), replay/ (ReplayJobService, ReplayDispatcher, ReplayPortRegistry,
|                   |        KafkaTopicReplayPort, HttpReplayPort, EventLayerReplayPort, ReplayRateLimiter,
|                   |        ReplayResultHandler, ReplayTimeoutSweeper)
|                   lifecycle/ (DiscardService, RetentionJob), stats/ (DlqStatsService, ThresholdEvaluator)
|-- notify/        (nhóm E, FR-18-035…041)
|   |-- api/        NotificationApi, RecipientRef, NotificationPriority
|   |-- events/     NotificationBounced (12), NotificationFailed (13)
|   |-- internal/   template/ (TemplateService, LogiclessTemplateValidator, ForbiddenFieldChecker)
|                   dispatch/ (NotificationService, DeliveryWorker, RecipientResolver, QuietHoursPolicy)
|                   channel/ (MailChannel, SmsChannel, InAppChannel), rule/ (NotificationRuleConsumer)
|                   pref/ (PreferenceService), bounce/ (BounceHandler, SuppressionService)
|-- task/          (nhóm F, FR-18-042…046)
|   |-- api/        TaskInboxApi, WorkingCalendarApi, FreezeStatusApi
|   |-- events/     TaskStateChanged (14), CalendarChanged (15), MaintenanceWindowChanged (16)
|   |-- internal/   inbox/ (TaskTypeRegistry, TaskService, MyTasksQuery, ReminderJob)
|                   calendar/ (WorkingCalendarService, MaintenanceWindowService)
|-- incident/      (nhóm G, FR-18-047…051)
|   |-- api/        IncidentApi;  events/ IncidentOpened (17), IncidentStateChanged (18)
|   |-- internal/   IncidentService, IncidentEventConsumer, PrivacyHandoffService, AckEscalationJob
|-- backup/        (nhóm H, FR-18-052…058)
|   |-- api/        TenantExportApi, MergeTransferApi
|   |-- events/     BackupFailed (19), RestoreVerificationCompleted (20), TenantRestoreStateChanged (21),
|                   TenantRestored (22), TenantExportCompleted (23), MergeTransferStateChanged (24)
|   |-- internal/   status/ (BackupRunIngestService, BackupFreshnessJob, DrDrillService)
|                   restore/ (TenantRestoreService, RestoreStateMachine, RestoreJobLauncher, RestoreStepTracker)
|                   export/ (TenantExportService), merge/ (MergeTransferService, Ph20ProgressReporter)
|                   jobs/ (K8sJobGateway, JobSpecFactory, JobWatcher)
|-- migration/     (nhóm I, FR-18-059…068)
|   |-- api/        MigrationImportContract (DTO lô nhập cho phân hệ đích)
|   |-- events/     MigrationRunCompleted (25), CredentialReissueRequired (26), CutoverStateChanged (27)
|   |-- internal/   source/ (LegacySourceService, ReadOnlyProbe), plan/ (MigrationPlanService, DependencyOrderer)
|                   run/ (MigrationRunService, ReconciliationService, ErrorRecordService)
|                   parallel/ (ShadowSampleIngestService, ShadowComparator, CutoverChecklistEvaluator,
|                              CutoverService, RollbackWatchdog)
|-- report/        (nhóm J, FR-18-070…072)
    |-- api/        OpsHealthApi;  events/ ReportPublished (28), HealthChanged (29)
    |-- internal/   OpsReportJob, AuditLogQuery, HealthAggregator, DegradedModeGuard

apps/ops-worker/src/main/java/vn/datahub/opsworker/
|-- restore/   TenantRestoreCommand, step/ (Step1Approval … Step8VerifyAndReopen), TempClusterProvisioner
|-- export/    TenantExportCommand, MergeLoadCommand, CopyStreamer, ManifestWriter
|-- migrate/   MigrateCommand, BatchConfig, reader/, convert/ (ObjectConverter theo loại), writer/ (ImportApiWriter)
|-- common/    WorkerContext, ProgressReporter, CheckpointStore, WorkerTenantSession

libs/dh-ops-client/   OpsParams, ParamKey, SnapshotCache, ParamChangeSubscriber, OpsNotifications,
                      OpsTasks, OpsCalendar, OpsDlqWriter, FailSoftPolicy, autoconfig/ (Spring Boot), quarkus/
```

Thư viện `dh-ops-client` là giao diện duy nhất phân hệ khác nhúng: lõi Java thuần (HTTP client JDK, Caffeine, Kafka client) và hai lớp kết dính, `autoconfig` cho Spring Boot 4 và `quarkus` cho `dh-runtime` Camel Quarkus (Q18-28). Không phân hệ nào được import `vn.datahub.platform.ops.*` ngoài các module cùng DU `dh-platform`.

### 3.2. Quy tắc phụ thuộc

Quy tắc phụ thuộc được kiểm bằng `ApplicationModules.verify()` của Spring Modulith và ArchUnit trong CI (cổng CI-3). Bảng ghi ai được gọi ai.

| Module | Được dùng | Không được dùng |
|---|---|---|
| `param` | `common` | Mọi module con khác (là nền, không phụ thuộc ai) |
| `dlq` | `common`, `param::api`, `task::api`, `notify::api` | `backup`, `migration` |
| `notify` | `common`, `param::api`, `task::api` (giờ làm việc) | `dlq`, `backup`, `migration` |
| `task` | `common`, `param::api`, `notify::api` (nhắc việc) | `dlq`, `backup`, `migration` |
| `incident` | `common`, `notify::api`, `task::api`, `dlq::events`, `backup::events` | Gọi đồng bộ `dlq::internal`, `backup::internal` |
| `backup` | `common`, `param::api`, `task::api`, `notify::api` | `migration::internal` |
| `migration` | `common`, `param::api`, `task::api`, `notify::api`, `dlq::api` (kiểm DLQ rỗng khi cắt chuyển) | `backup::internal` |
| `report` | `common`, sự kiện `events` của mọi module, `*::api` chỉ đọc | Ghi vào bảng của module khác |
| Module khác của `dh-platform` (PH-13, PH-20) | `ops::*::api`, `ops::*::events` | `ops::*::internal`, bảng `ph18_ops` |

: Quy tắc phụ thuộc giữa các module của PH-18

Bốn luật ArchUnit bổ sung: (1) chỉ `common.OutboxWriter` được ghi `outbox_event` và không lớp nào trong `ops` dùng `KafkaTemplate.send` trực tiếp, trừ `DlqTopicConsumer` (đọc) và `KafkaTopicReplayPort` qua outbox; (2) lớp `*Controller` không gọi `*Repository`, chỉ gọi service; (3) mọi phương thức service đổi trạng thái có `@Transactional` và gọi `OpsAuditRecorder`; (4) gói `vn.datahub.opsworker` không phụ thuộc `vn.datahub.platform.ops.*.internal`, chỉ phụ thuộc hợp đồng bảng và DTO trong `ops::*::api`.

### 3.3. Giao diện công bố

Các giao diện dưới đây là toàn bộ bề mặt phân hệ khác dùng. Giao diện Java chỉ có ở module cùng DU; phân hệ ở DU khác dùng cùng ngữ nghĩa qua `dh-ops-client`, vốn gọi API nội bộ tương ứng.

```java
package vn.datahub.platform.ops.param.api;

public interface ParameterApi {
  /** FR-18-002. Giá trị hiệu lực đã kẹp trần; không có thì mặc định của lược đồ. */
  <T> T get(TenantId tenant, ParamKey<T> key);
  /** FR-18-002. Ảnh chụp cả không gian tên kèm ETag, cho bộ đệm phía khách. */
  NamespaceSnapshot snapshot(TenantId tenant, String ns, Optional<String> ifNoneMatch);
}

public interface ParamSchemaRegistrationApi {
  /** FR-18-001. Lũy đẳng theo băm lược đồ; xung đột với giá trị đang dùng trả ERR-18-016. */
  RegistrationResult register(String ns, ParamSchema schema, ModuleIdentity caller);
}

package vn.datahub.platform.ops.notify.api;

public interface NotificationApi {
  /** FR-18-036. Bất đồng bộ qua outbox, lũy đẳng theo idempotencyKey trong 24 giờ. */
  NotificationReceipt submit(TenantId tenant, NotificationRequest request, String idempotencyKey);
  /** FR-18-036, Q01-52. Chờ máy chủ thư nhận, tối đa 18.notify.sync.timeout-ms. */
  NotificationReceipt sendSync(TenantId tenant, NotificationRequest request, String idempotencyKey);
}

package vn.datahub.platform.ops.task.api;

public interface TaskInboxApi {
  /** FR-18-043. Tạo hoặc cập nhật theo (type, sourceRef); phân hệ nguồn là chủ trạng thái. */
  TaskView upsert(TenantId tenant, String typeCode, String sourceRef, TaskUpsert body);
  TaskView close(TenantId tenant, String typeCode, String sourceRef, TaskOutcome outcome);
}

public interface WorkingCalendarApi {
  /** FR-18-045. Thiếu lịch tenant thì dùng COMMON, thiếu cả hai thì chỉ bỏ cuối tuần, cờ calendarMissing. */
  DueDate addWorkingDays(TenantId tenant, LocalDate from, int days);
  WorkingDays between(TenantId tenant, LocalDate from, LocalDate to);
}

package vn.datahub.platform.ops.dlq.api;

/** SPI cổng phát lại (ADR-182). Mỗi replayMode một hiện thực; không hiện thực nào gọi HTTT đích. */
public interface ReplayPort {
  ReplayMode mode();
  DispatchOutcome dispatch(ReplayRequest request);   // request mang dlqId, revision, idempotencyKey, payloadRef
}
```

Bảng gom giao diện theo kênh và bên dùng.

| Giao diện | Bên dùng | Kênh | Mã |
|---|---|---|---|
| Đọc tham số, cờ, egress | Mọi DU qua `dh-ops-client` | `POST /ops/internal/v1/params:batch-get`, `GET /ops/internal/v1/params/{tenant}/{ns}` | API-18-028, 029 |
| Đăng ký lược đồ khóa | Mọi DU khi khởi động, PH-20 cho `20.*` | `PUT /ops/internal/v1/param-namespaces/{ns}/schema` | API-18-027 |
| Ghi mặc định tenant | PH-20 | `POST /ops/internal/v1/tenants/{tenant}/params:seed-defaults` và `platform.tenant.created.v1` | API-18-030 |
| Ghi DLQ | PH-01, PH-06, PH-08, PH-19 | `POST /ops/internal/v1/dlq/messages`, `:batch`; topic `{tenant}.ops.dlq.v1` | API-18-035, 036 |
| Đăng ký nguồn và cổng phát lại | Nguồn khi khởi động | `POST /ops/internal/v1/dlq-sources:register` | API-18-034 |
| Báo kết quả phát lại | Nguồn | `POST /ops/internal/v1/replay-results` | API-18-076 |
| Đọc DLQ, sổ tay | PH-17, PH-13 | `GET /ops/internal/v1/dlq/messages`, `error-guides:feed` | API-18-060, 061, 062 |
| Gửi thông báo | Mọi DU, PH-13, PH-20 | `POST /ops/internal/v1/notifications`, `:send-sync` | API-18-091, 092 |
| Hộp việc | Mọi DU có việc duyệt | `POST /ops/internal/v1/task-types`, `PUT /ops/internal/v1/tasks/{sourceRef}`, `:close` | API-18-107, 109, 110 |
| Lịch, đóng băng | PH-01, 02, 04, 09, 12, 16 | `GET …calendar/{tenant}:working-days`, `POST …:add-working-days`, `GET …freeze-status/{tenant}` | API-18-116, 117, 122 |
| Mở sự cố | PH-13, PH-09 | `POST /ops/internal/v1/incidents` | API-18-132 |
| Báo sao lưu | CronJob thu trạng thái, Job kiểm tra khôi phục | `POST /ops/internal/v1/backup/runs`, `backup/verifications` | API-18-135, 137 |
| Chuyển sáp nhập | PH-20 | `POST /api/ops/v1/merge-transfers`, `:cancel` | API-18-150, 153 |
| Mẫu bóng | Bộ so sánh bên APISIX | `POST /ops/internal/v1/shadow-samples` | API-18-176 |
| Sự kiện | Mọi DU, PH-13, PH-16, PH-20 | `{tenant}.ops.*.v1` qua outbox | EVT-18-01…29 |

: Giao diện công bố của PH-18

### 3.4. Danh sách thành phần được đặc tả

Chương 4 đặc tả 25 thành phần (mục 4.2 đến 4.26); mỗi mục mở bằng khối đặc tả 10 mục. Mục 4.1 là mô hình miền dùng chung. Thành phần 4.4 là thư viện nhúng ở DU khác, 4.26 là khung chung của ảnh worker.

| Mục | Thành phần | Lớp chính | Package |
|---|---|---|---|
| 4.2 | Đăng ký lược đồ và ghi giá trị tham số | `ParamSchemaRegistry`, `ParamWriteService`, `ParamValidator`, `ParamChangeApprovalService` | `param.registry`, `param.write` |
| 4.3 | Đọc tham số và phát sự kiện đổi | `ParamReadService`, `EffectiveValueResolver`, `NamespaceSnapshotController` | `param.read` |
| 4.4 | Thư viện khách `dh-ops-client` | `OpsParams`, `SnapshotCache`, `ParamChangeSubscriber`, `FailSoftPolicy` | `libs/dh-ops-client` |
| 4.5 | Cờ tính năng, egress, gói tham số, mặc định tenant | `FeatureFlagService`, `EgressAllowlistService`, `ParamBundleService`, `TenantDefaultSeeder` | `param.flag`, `egress`, `bundle`, `seed` |
| 4.6 | Tiếp nhận DLQ | `DlqTopicConsumer`, `DlqIngestService`, `ContextContractValidator`, `DlqKeyDeduplicator`, `PayloadStore` | `dlq.ingest` |
| 4.7 | Liên thông PH-10 và đối soát | `EventLayerDlqClient`, `EventDlqListener`, `DlqReconciler` | `dlq.federation`, `dlq.reconcile` |
| 4.8 | Tra cứu, gom nhóm, phân loại | `DlqQueryService`, `SignatureGrouper`, `AssignmentService`, `DiagnosticsClient` | `dlq.triage` |
| 4.9 | Xem và sửa payload | `PayloadRevealService`, `RevealTicketStore`, `RevisionService`, `PayloadPatcher` | `dlq.payload`, `dlq.revision` |
| 4.10 | Sổ tay xử lý theo mã lỗi | `ErrorGuideService` | `dlq.guide` |
| 4.11 | Phát lại qua `ReplayPort` | `ReplayJobService`, `ReplayDispatcher`, `ReplayRateLimiter`, `ReplayResultHandler` | `dlq.replay` |
| 4.12 | Bỏ qua, lưu giữ, thống kê, ngưỡng | `DiscardService`, `RetentionJob`, `DlqStatsService`, `ThresholdEvaluator` | `dlq.lifecycle`, `dlq.stats` |
| 4.13 | Mẫu thông báo | `TemplateService`, `LogiclessTemplateValidator`, `ForbiddenFieldChecker` | `notify.template` |
| 4.14 | Gửi thông báo | `NotificationService`, `DeliveryWorker`, `RecipientResolver`, `QuietHoursPolicy`, `MailChannel`, `SmsChannel` | `notify.dispatch`, `notify.channel` |
| 4.15 | Quy tắc sự kiện, tùy chọn nhận, thư trả lại | `NotificationRuleConsumer`, `PreferenceService`, `BounceHandler`, `SuppressionService` | `notify.rule`, `pref`, `bounce` |
| 4.16 | Hộp việc | `TaskTypeRegistry`, `TaskService`, `MyTasksQuery`, `ReminderJob` | `task.inbox` |
| 4.17 | Lịch, cửa sổ bảo trì, đóng băng | `WorkingCalendarService`, `MaintenanceWindowService` | `task.calendar` |
| 4.18 | Sự cố vận hành | `IncidentService`, `IncidentEventConsumer`, `PrivacyHandoffService`, `AckEscalationJob` | `incident` |
| 4.19 | Bộ thu trạng thái sao lưu | `BackupRunIngestService`, `BackupFreshnessJob`, `DrDrillService`, CronJob `dh-backup-reporter` | `backup.status` |
| 4.20 | Khôi phục tenant tám bước | `TenantRestoreService`, `RestoreStateMachine`, `RestoreJobLauncher`, công cụ `dh-tenant-restore` | `backup.restore`, `opsworker.restore` |
| 4.21 | Xuất tenant và chuyển sáp nhập | `TenantExportService`, `MergeTransferService`, `Ph20ProgressReporter`, công cụ `dh-tenant-export` | `backup.export`, `backup.merge`, `opsworker.export` |
| 4.22 | Di trú: nguồn, kế hoạch, lần chạy | `LegacySourceService`, `DependencyOrderer`, `MigrationRunService`, công cụ `dh-migrate` | `migration.source`, `plan`, `run`, `opsworker.migrate` |
| 4.23 | Chạy song song, đối soát bóng, cắt chuyển | `ShadowSampleIngestService`, `ShadowComparator`, `CutoverChecklistEvaluator`, `CutoverService`, `RollbackWatchdog` | `migration.parallel` |
| 4.24 | Báo cáo, nhật ký thao tác, sức khỏe | `OpsReportJob`, `AuditLogQuery`, `HealthAggregator`, `DegradedModeGuard` | `report` |
| 4.25 | Lõi chung | `FourEyesGuard`, `HeavyTaskLock`, `OpsAuditRecorder`, `OutboxWriter`, `InboxGuard`, `TenantFanout` | `common` |
| 4.26 | Khung worker `dh-ops-worker` | `WorkerContext`, `ProgressReporter`, `CheckpointStore`, `WorkerTenantSession` | `opsworker.common` |

: Danh sách 25 thành phần được đặc tả của PH-18

### 3.5. Ánh xạ FR sang thành phần

Bảng liệt kê đủ 72 FR, thành phần chính và mục của tập này hiện thực chức năng đó. Thành phần phụ ghi sau dấu cộng. Đây cũng là bảng truy vết FR sang thành phần mà chương 13 dẫn lại.

| FR | Chức năng (rút gọn) | Thành phần | Mục |
|---|---|---|---|
| FR-18-001 | Đăng ký không gian tên, lược đồ khóa | `ParamSchemaRegistry`, `SchemaCompatibilityChecker` | 4.2 |
| FR-18-002 | Đọc tham số có bộ đệm | `ParamReadService`, `NamespaceSnapshotController` + `dh-ops-client` | 4.3, 4.4 |
| FR-18-003 | Ghi giá trị có kiểm miền, trần, lý do | `ParamWriteService`, `ParamValidator` | 4.2 |
| FR-18-004 | Bốn mắt tham số ★ | `ParamChangeApprovalService` + `FourEyesGuard`, `TaskService` | 4.2, 4.25, 4.16 |
| FR-18-005 | Lịch sử, so sánh, khôi phục phiên bản | `ParamHistoryService` | 4.2 |
| FR-18-006 | Sự kiện đổi, làm mới đệm | `OutboxWriter` (EVT-18-01) + `ParamChangeSubscriber` | 4.3, 4.4 |
| FR-18-007 | Màn tham số chung nhúng | `ParamReadService` (theo `ns`, `nhom`) | 4.3 |
| FR-18-008 | Xuất, nhập gói tham số | `ParamBundleService` | 4.5 |
| FR-18-009 | Cờ tính năng | `FeatureFlagService` | 4.5 |
| FR-18-010 | Danh sách egress | `EgressAllowlistService`, `EgressHostValidator` | 4.5 |
| FR-18-011 | Mặc định khi khởi tạo tenant | `TenantDefaultSeeder` | 4.5 |
| FR-18-012 | Đăng ký nguồn DLQ và cổng | `DlqSourceService`, `ReplayPortRegistry` | 4.6, 4.11 |
| FR-18-013 | Tiêu thụ topic DLQ | `DlqTopicConsumer`, `DlqIngestService` | 4.6 |
| FR-18-014 | API ghi DLQ | `DlqWriteController`, `DlqIngestService` | 4.6 |
| FR-18-015 | Kiểm ngữ cảnh, POISON | `ContextContractValidator`, `HeaderNormalizer` | 4.6 |
| FR-18-016 | Payload lớn ở Garage, khử trùng | `PayloadStore`, `DlqKeyDeduplicator` | 4.6 |
| FR-18-017 | Liên thông DLQ PH-10 | `EventLayerDlqClient`, `EventDlqListener` | 4.7 |
| FR-18-018 | Đối soát chỉ mục với Kafka | `DlqReconciler` | 4.7 |
| FR-18-019 | Liệt kê, lọc, tìm | `DlqQueryService` | 4.8 |
| FR-18-020 | Gom nhóm dấu hiệu lỗi | `SignatureGrouper` | 4.8 |
| FR-18-021 | Chi tiết, ngữ cảnh chẩn đoán | `DlqQueryService`, `DiagnosticsClient` | 4.8 |
| FR-18-022 | Xem payload có lý do | `PayloadRevealService`, `RevealTicketStore` | 4.9 |
| FR-18-023 | Phân loại, ưu tiên, gán | `AssignmentService` | 4.8 |
| FR-18-024 | Sửa payload có kiểm soát | `RevisionService`, `PayloadPatcher` + `FourEyesGuard` | 4.9, 4.25 |
| FR-18-025 | Sổ tay xử lý | `ErrorGuideService` | 4.10 |
| FR-18-026 | API đọc cho PH-17, PH-13 | `DlqReadController` (chỉ đọc) + `ErrorGuideService` | 4.8, 4.10 |
| FR-18-027 | Phát lại một mục | `ReplayJobService` (lượt một mục), `ReplayDispatcher` | 4.11 |
| FR-18-028 | Phát lại loạt | `ReplayJobService` + `FourEyesGuard` | 4.11, 4.25 |
| FR-18-029 | Tốc độ, tạm dừng, hủy | `ReplayDispatcher`, `ReplayRateLimiter` | 4.11 |
| FR-18-030 | Kết quả phát lại, lũy đẳng | `ReplayResultHandler`, `ReplayTimeoutSweeper` | 4.11 |
| FR-18-031 | Bỏ qua có lý do | `DiscardService` | 4.12 |
| FR-18-032 | Mở lại | `DiscardService` | 4.12 |
| FR-18-033 | Lưu giữ, dọn | `RetentionJob`, `PartitionMaintenanceJob` | 4.12 |
| FR-18-034 | Thống kê, chỉ số, vượt ngưỡng | `DlqStatsService`, `ThresholdEvaluator`, `DlqMetricsBinder` | 4.12 |
| FR-18-035 | Mẫu có phiên bản, kiểm trường cấm | `TemplateService`, `LogiclessTemplateValidator`, `ForbiddenFieldChecker` | 4.13 |
| FR-18-036 | Gửi qua NotificationApi | `NotificationService`, `DeliveryWorker` | 4.14 |
| FR-18-037 | Phân giải người nhận | `RecipientResolver` | 4.14 |
| FR-18-038 | Tùy chọn nhận, giờ yên lặng | `PreferenceService`, `QuietHoursPolicy` | 4.15, 4.14 |
| FR-18-039 | Quy tắc theo sự kiện | `NotificationRuleConsumer` | 4.15 |
| FR-18-040 | Thử lại, thư trả lại, danh sách chặn | `DeliveryWorker` (thử lại), `BounceHandler`, `SuppressionService` | 4.14, 4.15 |
| FR-18-041 | Nhật ký gửi, kênh cho PH-13 | `DeliveryLogQuery` | 4.14 |
| FR-18-042 | Đăng ký loại việc | `TaskTypeRegistry` | 4.16 |
| FR-18-043 | Tạo, cập nhật, đóng việc lũy đẳng | `TaskService` | 4.16 |
| FR-18-044 | Việc của tôi, nhắc, quá hạn | `MyTasksQuery`, `ReminderJob` | 4.16 |
| FR-18-045 | Lịch ngày làm việc | `WorkingCalendarService` | 4.17 |
| FR-18-046 | Cửa sổ bảo trì, đóng băng | `MaintenanceWindowService` | 4.17 |
| FR-18-047 | Mở sự cố từ sự kiện | `IncidentEventConsumer`, `IncidentService` | 4.18 |
| FR-18-048 | Tạo tay, phân mức, gán | `IncidentService`, `AckEscalationJob` | 4.18 |
| FR-18-049 | Mốc thời gian, liên kết | `IncidentService` (timeline chỉ thêm) | 4.18 |
| FR-18-050 | Chuyển PH-09 | `PrivacyHandoffService` | 4.18 |
| FR-18-051 | Đóng có nguyên nhân, bài học | `IncidentService` | 4.18 |
| FR-18-052 | Theo dõi sao lưu, cảnh báo lỗi | `BackupRunIngestService`, `BackupFreshnessJob`, `dh-backup-reporter` | 4.19 |
| FR-18-053 | Kết quả kiểm tra khôi phục | `BackupRunIngestService` (verification) | 4.19 |
| FR-18-054 | Yêu cầu khôi phục tenant | `TenantRestoreService` + `HeavyTaskLock` | 4.20, 4.25 |
| FR-18-055 | Duyệt, chạy khôi phục tám bước | `RestoreStateMachine`, `RestoreJobLauncher`, `dh-tenant-restore` | 4.20, 4.26 |
| FR-18-056 | Xuất dữ liệu tenant | `TenantExportService`, `dh-tenant-export` | 4.21 |
| FR-18-057 | Chuyển dữ liệu khi sáp nhập | `MergeTransferService`, `Ph20ProgressReporter`, `dh-tenant-export` | 4.21 |
| FR-18-058 | Ghi nhận diễn tập DR, PITR | `DrDrillService` | 4.19 |
| FR-18-059 | Khai báo nguồn hệ cũ | `LegacySourceService`, `ReadOnlyProbe` | 4.22 |
| FR-18-060 | Kế hoạch di trú, thứ tự phụ thuộc | `MigrationPlanService`, `DependencyOrderer` | 4.22 |
| FR-18-061 | Chạy thử | `MigrationRunService`, `dh-migrate` (chế độ `DRY_RUN`) | 4.22 |
| FR-18-062 | Chạy thật bốn mắt | `MigrationRunService` + `FourEyesGuard`, `dh-migrate` | 4.22, 4.25 |
| FR-18-063 | Bản ghi lỗi, chạy lại | `ErrorRecordService` | 4.22 |
| FR-18-064 | Đối chiếu số lượng, tổng kiểm tra | `ReconciliationService` | 4.22 |
| FR-18-065 | Dấu cấp lại xác thực | `CredentialStripper` (trong `dh-migrate`), `MigrationRunService` | 4.22 |
| FR-18-066 | Theo dõi chạy song song, cầu nối PH-10 | `ParallelGroupService` (tiêu thụ EVT-10-15, 16) | 4.23 |
| FR-18-067 | Đối soát bóng | `ShadowSampleIngestService`, `ShadowComparator` | 4.23 |
| FR-18-068 | Cắt chuyển, quay lui | `CutoverChecklistEvaluator`, `CutoverService`, `RollbackWatchdog` | 4.23 |
| FR-18-069 | Tham số `18.*` | `ParamWriteService` (không gian tên `18`) | 4.2 |
| FR-18-070 | Nhật ký thao tác | `OpsAuditRecorder`, `AuditLogQuery` | 4.25, 4.24 |
| FR-18-071 | Báo cáo vận hành định kỳ | `OpsReportJob` | 4.24 |
| FR-18-072 | Sức khỏe, chế độ suy giảm | `HealthAggregator`, `DegradedModeGuard` | 4.24 |

: Ánh xạ 72 FR sang thành phần

## 4. Thiết kế chi tiết từng thành phần

Chương này là phần kỹ sư dùng để viết mã. Mục 4.1 nêu mô hình miền và bất biến chung; mục 4.2 đến 4.26 đặc tả từng thành phần bằng khối 10 mục, sau đó là thuật toán, quy tắc và ví dụ cần để hiện thực đúng. Tên bảng khớp DDL `ph18_ops` của D03-03-PH18; thực thể logic EN-18-01…55 ở FRS §4.2.

### 4.1. Mô hình miền

Mô hình miền có mười bốn aggregate, mỗi aggregate một service sở hữu ghi để tránh hai đường ghi cùng một dòng: `ParamDefinition` (kèm `ParamValue`, `ParamValueVersion`, `ParamChangeRequest`), `FeatureFlag`, `DlqSource`, `DlqMessage` (kèm `DlqPayloadRef`, `DlqRevision`, `DlqAssignment`), `DlqGroup`, `ReplayJob` (kèm `ReplayItem`), `NotificationTemplate` (kèm phiên bản), `NotificationMessage` (kèm `NotificationDelivery`), `TaskItem`, `WorkCalendar` (kèm ngày lễ), `Incident` (kèm mốc, liên kết), `TenantRestoreRequest` (kèm bước), `MigrationRun` (kèm kết quả mục, bản ghi lỗi, đối chiếu), `ParallelRunGroup` (kèm danh sách kiểm tra, sổ cắt chuyển, mẫu bóng). Sơ đồ chỉ nêu quan hệ chính.

```{.mermaid caption="Mô hình miền cốt lõi của PH-18"}
classDiagram
  class ParamDefinition {
    key
    valueType
    level
    securityFlag
    approvalOwner
  }
  class ParamValue {
    tenantId
    versionNo
    etag
  }
  class ParamChangeRequest {
    status
    requestedBy
    expiresAt
  }
  class DlqSource {
    sourceCode
    replayMode
    rateCap
    status
  }
  class DlqMessage {
    dlqKey
    status
    errorClass
    payloadLocation
    currentRevisionNo
  }
  class DlqRevision {
    revisionNo
    status
    touchesRestricted
  }
  class ReplayJob {
    status
    ratePerSecond
    total
    succeeded
    failed
  }
  class ReplayItem {
    idempotencyKey
    result
  }
  class NotificationMessage {
    templateCode
    priority
    status
    idempotencyKey
  }
  class TaskItem {
    typeCode
    taskKey
    status
    dueAt
  }
  class Incident {
    severity
    status
    sourceRef
  }
  class TenantRestoreRequest {
    pointInTime
    scope
    status
    currentStep
  }
  class MigrationRun {
    runMode
    status
    itemsTotal
  }
  class ParallelRunGroup {
    status
    matchRate
    rollbackDeadlineAt
  }
  ParamDefinition "1" --> "*" ParamValue
  ParamValue "1" --> "*" ParamChangeRequest
  DlqSource "1" --> "*" DlqMessage
  DlqMessage "1" --> "*" DlqRevision
  ReplayJob "1" --> "*" ReplayItem
  ReplayItem "*" --> "1" DlqMessage : phát lại
  Incident "*" --> "*" DlqMessage : liên kết
  MigrationRun "*" --> "1" ParallelRunGroup : thuộc kế hoạch
```

Tám bất biến xuyên suốt, kiểm ở service rồi được CSDL chặn lần hai bằng CHECK, chỉ mục duy nhất có điều kiện và trigger (D03-03-PH18 §1.4): (1) mỗi khóa có tối đa một phiên bản `ACTIVE` và một đề nghị `PENDING_APPROVAL` mỗi tenant (BR-18-005); (2) payload gốc của mục DLQ không bao giờ đổi, chỉ có thể đặt `PURGED` khi dọn (BR-18-012); (3) mỗi `dlqKey` có tối đa một mục chưa đóng mỗi tenant (BR-18-015, cưỡng chế ở service vì bảng phân vùng, §4.6); (4) mỗi khóa lũy đẳng `dlqId:revision` có tối đa một kết quả cuối (BR-18-020); (5) người duyệt khác người đề nghị ở mọi thao tác bốn mắt (`ck_*_four_eyes`); (6) mỗi tenant có tối đa một tác vụ nặng chạy (BR-18-039, §4.25); (7) chuyển trạng thái chỉ theo bảng §8.1 (20 trigger `tg_*_fsm_status`); (8) không bảng, sự kiện hay log nào mang bí mật hay địa chỉ thư, số điện thoại rõ (BR-18-048, BR-18-050).

### 4.2. Đăng ký lược đồ và ghi giá trị tham số (`param.registry`, `param.write`)

::: dac-ta
**Mục đích.** Nhận lược đồ khóa do phân hệ chủ đăng ký và ghi giá trị theo tenant có kiểm kiểu, miền, trần nền tảng, lý do, `If-Match`, phiên bản bất biến, bốn mắt cho khóa ★ và khôi phục phiên bản cũ.

**Lớp chính.** `ParamSchemaRegistry`, `SchemaCompatibilityChecker`, `ParamWriteService`, `ParamValidator`, `ParamChangeApprovalService`, `ParamHistoryService`, `ParamDefinitionRepository`, `ParamValueRepository`, `ParamController`, `ParamInternalController`.

**Đơn vị chạy.** `dh-platform` hồ sơ `api`; `ChangeRequestExpiryJob` ở hồ sơ `worker` (ShedLock, mỗi 15 phút).

**FR hiện thực.** FR-18-001, 003, 004, 005, 069; BR-18-001…005, BR-18-049.

**Giao diện vào.** `ParamSchemaRegistrationApi`; API-18-001…003, 006…016, 027.

**Phụ thuộc ra.** `common` (`FourEyesGuard`, `OpsAuditRecorder`, `OutboxWriter`), `TaskInboxApi` (việc `ph18.approve-param`), PH-12 (quyền theo không gian tên).

**Dữ liệu.** `param_namespace`, `param_definition` (chỉ dòng `COMMON`), `param_value`, `param_value_version`, `param_change_request`.

**Sự kiện.** EVT-18-01 sau mỗi phiên bản `ACTIVE`; EVT-18-02 khi tạo đề nghị ★.

**Lỗi và xử lý.** ERR-18-003, 004, 005, 007, 011…019, 023, 071; vi phạm CHECK của CSDL (SQLSTATE 23514, 23505, 55000) ánh xạ về cùng mã ở `ProblemMapper`.

**Quan sát.** `dh_ops_param_write_total{result}`, `dh_ops_param_change_request_pending`, `dh_ops_param_schema_registration_total{result}`, `dh_ops_param_write_seconds`.
:::

**Đăng ký lược đồ.** Phân hệ đặt tệp `ops/param-schema/{ns}.yaml` trong ảnh của mình; `dh-ops-client` gửi tệp này qua API-18-027 khi khởi động, kèm băm SHA-256 của nội dung chuẩn tắc. `ParamSchemaRegistry` so băm với bản đang lưu: trùng thì trả `200` không đổi gì (lũy đẳng, nhiều bản sao khởi động cùng lúc không tạo phiên bản thừa nhờ khóa tư vấn theo `ns`). Khác băm thì `SchemaCompatibilityChecker` chạy bốn kiểm tra: không gian tên thuộc danh tính SPIFFE của bên gọi (ERR-18-017, BR-18-001), `19` bị từ chối; khóa mới mang tiền tố `ns`; khóa bị đổi kiểu hoặc thu hẹp miền thì quét `param_value` của mọi tenant, có giá trị ngoài miền mới thì từ chối ERR-18-016 kèm danh sách tenant; khóa bị bỏ thì chỉ đánh dấu `DEPRECATED`, không xóa giá trị. Mặc định của lược đồ phải nằm trong miền và trần (trigger `tg_param_definition_check`).

**Kiểm giá trị.** `ParamValidator.validate(definition, raw, tenantLevel)` chạy theo thứ tự, dừng ở lỗi đầu: khóa đã đăng ký (ERR-18-011); khóa mức `PLATFORM` thì người ghi phải là PA trong phiên `COMMON` (ERR-18-015); đúng kiểu (`INT`, `DECIMAL`, `BOOL`, `STRING`, `ENUM`, `CRON`, `DURATION`, `LIST<STRING>`, `LIST<HOST>`; ERR-18-012); trong miền (ERR-18-013); không vượt trần nền tảng hiện hành (ERR-18-014); lý do dài tối thiểu `18.param.reason-min-length` (ERR-18-007). Kiểu `CRON` kiểm bằng `CronExpression.parse` của Spring; `LIST<HOST>` dùng cùng bộ kiểm của egress (§4.5).

**Ghi và phiên bản.** `ParamWriteService.write` chạy trong một giao dịch: `SET LOCAL app.tenant_id`; đọc `param_value` `FOR UPDATE`; so `If-Match` với `version` (ERR-18-004); kiểm `DegradedModeGuard` (ERR-18-071); khóa không ★ thì thêm `param_value_version` mới `ACTIVE`, chuyển bản cũ sang `SUPERSEDED`, cập nhật `param_value`, ghi kiểm toán và outbox EVT-18-01 cùng giao dịch (BR-18-006 yêu cầu phát ≤ 5 giây sau commit, nhờ bộ chuyển outbox chạy liên tục). Khóa ★ thì đi nhánh bốn mắt.

**Bốn mắt khóa ★.** `ParamChangeApprovalService` tạo `param_change_request` `PENDING_APPROVAL` (đã có đề nghị: ERR-18-018), hạn `18.param.change-request-ttl-hours`, rồi mở việc `ph18.approve-param` qua `TaskInboxApi` cho người có `PERM-18-approve`. Khóa có `approvalOwner` khác PH-18 (PH-14, PH-17) thì từ chối đề nghị qua màn chung (ERR-18-019) và chỉ nhận ghi từ danh tính dịch vụ của phân hệ đó kèm `approvalRef` (BR-18-004). Duyệt chạy lại toàn bộ `ParamValidator` trên giá trị đề nghị (trần có thể đã đổi trong lúc chờ), kiểm người duyệt khác người đề nghị bằng `FourEyesGuard` (ERR-18-005), rồi ghi phiên bản như nhánh thường. Sự kiện EVT-18-01 của khóa ★ không mang giá trị.

**Lịch sử và khôi phục.** `ParamHistoryService` trả danh sách phiên bản, so sánh hai phiên bản bất kỳ (khác biệt dạng trường), và khôi phục bằng cách tạo phiên bản mới mang giá trị cũ sau khi kiểm lại với lược đồ hiện hành (không hợp lệ: ERR-18-023). Không bao giờ xóa phiên bản trung gian (BR-18-005).

### 4.3. Đọc tham số và phát sự kiện đổi (`param.read`)

::: dac-ta
**Mục đích.** Trả giá trị hiệu lực của tenant cho màn tham số chung và cho phân hệ khác, theo lô hoặc theo ảnh chụp cả không gian tên có `ETag`, đủ nhanh để `304` gần như không tốn tài nguyên.

**Lớp chính.** `ParamReadService`, `EffectiveValueResolver`, `NamespaceSnapshotController`, `SnapshotEtagCache`, `ParamListQuery`.

**Đơn vị chạy.** `dh-platform` hồ sơ `api`.

**FR hiện thực.** FR-18-002, 006, 007; BR-18-006, BR-18-007.

**Giao diện vào.** `ParameterApi`; API-18-004, 005, 028, 029.

**Phụ thuộc ra.** `ph18_ops` (khung nhìn `config_param` cho bên đọc DD-14 cũ), bộ nhớ trong.

**Dữ liệu.** `param_definition`, `param_value` (dòng tenant và dòng `COMMON`), `feature_flag`, `egress_allowlist_entry`.

**Sự kiện.** Không phát; EVT-18-01 do 4.2 phát qua outbox.

**Lỗi và xử lý.** ERR-18-001, 010 (vượt 500 yêu cầu mỗi giây mỗi DU gọi), ERR-00-403 khi tenant trong đường dẫn khác tenant của danh tính gọi.

**Quan sát.** `dh_ops_param_read_total{mode,result}` (`mode` = `batch`, `snapshot`; `result` = `200`, `304`), `dh_ops_param_read_seconds`.
:::

**Giá trị hiệu lực.** `EffectiveValueResolver` lấy theo thứ tự: giá trị tenant nếu có, giá trị nền tảng (`COMMON`) nếu có, mặc định của lược đồ; kết quả luôn kẹp bởi trần nền tảng. Kết quả kèm `source` (`TENANT`, `PLATFORM`, `DEFAULT`) để màn chung hiển thị nguồn.

**ETag của ảnh chụp.** ETag của (tenant, ns) là `"{ns}:{maxVersion}:{schemaHash8}"`, trong đó `maxVersion` là `max(param_value.version)` của tenant và `COMMON` trong `ns`. `SnapshotEtagCache` giữ ETag hiện hành trong bộ nhớ, bị xóa khi chính bản sao nhận EVT-18-01; `If-None-Match` trùng thì trả `304` mà không chạm CSDL (NFR-18-004 yêu cầu p95 ≤ 20 ms). Lô API-18-028 nhận tới 100 khóa, cờ và mục egress trong một yêu cầu, tính ETag gộp theo các `ns` liên quan.

### 4.4. Thư viện khách `dh-ops-client`

::: dac-ta
**Mục đích.** Cho mọi DU đọc tham số, cờ tính năng và danh sách egress không quá 60 giây cũ, không phụ thuộc cứng vào PH-18, và cung cấp lớp gọi gọn cho DLQ, thông báo, hộp việc, lịch.

**Lớp chính.** `OpsParams`, `ParamKey<T>`, `SnapshotCache`, `SnapshotLoader`, `ParamChangeSubscriber`, `FailSoftPolicy`, `PackagedDefaults`, `SchemaRegistrar`, `OpsDlqWriter`, `OpsNotifications`, `OpsTasks`, `OpsCalendar`, `OpsClientAutoConfiguration`.

**Đơn vị chạy.** Nhúng trong tiến trình của DU gọi (`dh-connect`, `dh-integration`, `dh-data`, `dh-platform`, `dh-assist`, `dh-portal` BFF, `dh-runtime` qua bản Quarkus).

**FR hiện thực.** FR-18-001 (phía khách), 002, 006; NFR-18-005, NFR-18-018; BR-18-006, 007.

**Giao diện vào.** API Java `OpsParams.get(tenant, key)`, `flag(tenant, flagKey)`, `egress(tenant)`; thuộc tính `datahub.ops.client.*`.

**Phụ thuộc ra.** API-18-027, 028, 029 qua mTLS; topic `{tenant}.ops.param.changed.v1`, `{tenant}.ops.feature-flag.changed.v1`, `{tenant}.ops.egress.changed.v1`.

**Dữ liệu.** Caffeine trong bộ nhớ, khóa (tenant, ns); tệp lược đồ `ops/param-schema/{ns}.yaml` đóng gói trong ảnh.

**Sự kiện.** Tiêu thụ EVT-18-01, 03, 04; không phát.

**Lỗi và xử lý.** PH-18 vắng thì giữ bản cũ tới `stale-max` rồi mặc định đóng gói; không ném lỗi cho mã nghiệp vụ trừ khóa chưa khai báo trong lược đồ đóng gói (lỗi lập trình, phát hiện ở kiểm thử).

**Quan sát.** `dh_ops_client_cache_age_seconds{ns}`, `dh_ops_client_param_version{ns}`, `dh_ops_client_refresh_total{result}`, `dh_ops_client_fallback_total{level}` (`level` = `stale`, `packaged`).
:::

**Bộ đệm.** `SnapshotCache` là Caffeine `AsyncLoadingCache<(TenantId, String), NamespaceSnapshot>` với `expireAfterWrite` bằng `18.param.cache-ttl-seconds` (đọc từ chính ảnh chụp `18`, mặc định 60, trần 60) và `refreshAfterWrite` bằng một nửa giá trị đó; tải lại gửi `If-None-Match` nên phần lớn lượt làm mới chỉ nhận `304`. Kích thước tối đa 5.000 mục (34 tenant nhân khoảng 15 không gian tên còn dư nhiều). Mã nghiệp vụ gọi `get` không bao giờ chờ mạng khi đã có bản trong đệm: Caffeine trả bản cũ trong lúc làm mới nền.

**Làm mới theo sự kiện.** `ParamChangeSubscriber` đăng ký theo mẫu `^[a-z0-9]+\.ops\.(param|feature-flag|egress)\.changed\.v1$` với nhóm tiêu thụ riêng cho mỗi bản sao (`dhopsc-{du}-{podUid}`, `auto.offset.reset=latest`, không commit), để mọi bản sao đều nhận mọi sự kiện. Nhận EVT-18-01 thì vô hiệu mục (tenant, ns) và tải lại bất đồng bộ; sự kiện đến trước khi commit được đọc lại không xảy ra vì outbox chỉ phát sau commit. Sự kiện bị lỡ (bản sao khởi động lại, Kafka gián đoạn) được bù bằng `refreshAfterWrite`, nên trần độ cũ vẫn là 60 giây (NFR-18-005).

**Fail-soft.** `FailSoftPolicy` có ba mức. Mức 1: làm mới lỗi thì giữ bản cũ, tăng `dh_ops_client_fallback_total{level="stale"}`, thử lại với lùi lũy thừa tới 30 giây. Mức 2: bản cũ quá `datahub.ops.client.stale-max` (mặc định 24 giờ) vẫn dùng nhưng ghi cảnh báo mỗi 5 phút. Mức 3: khởi động lạnh mà PH-18 vắng thì dùng mặc định trong tệp lược đồ đóng gói (`PackagedDefaults`), đúng nghĩa "mặc định đóng gói" của BR-18-007; khóa ★ mặc định luôn là giá trị an toàn hơn (ví dụ `18.restore.approval-required = true`). Không mức nào chặn khởi động DU.

**Ví dụ dùng.**

```java
static final ParamKey<Integer> REVIEW_SLA = ParamKey.ofInt("onboarding.review.slaWorkingDays");

int sla = opsParams.get(tenant, REVIEW_SLA);          // không chặn, ≤ 60 giây cũ
boolean on = opsParams.flag(tenant, "ff.rdm.bulk-import");
```

Lớp phụ `OpsDlqWriter`, `OpsNotifications`, `OpsTasks`, `OpsCalendar` chỉ là lớp gọi API nội bộ có `Idempotency-Key` sinh từ khóa nghiệp vụ của bên gọi, thử lại ba lần với lùi lũy thừa cho `503` và lỗi mạng; khi hết lượt thì trả lỗi cho bên gọi tự quyết (thông báo thường thì bỏ qua và ghi log, việc duyệt thì để outbox của bên gọi thử lại).

### 4.5. Cờ tính năng, egress, gói tham số, mặc định tenant (`param.flag`, `param.egress`, `param.bundle`, `param.seed`)

::: dac-ta
**Mục đích.** Quản cờ tính năng có chủ sở hữu và ngày gỡ, danh sách đích egress cho phép theo tenant, xuất nhập gói tham số giữa môi trường, và ghi mặc định khi PH-20 khởi tạo tenant.

**Lớp chính.** `FeatureFlagService`, `FlagRetireReminderJob`, `EgressAllowlistService`, `EgressHostValidator`, `ParamBundleService`, `BundleSigner`, `TenantDefaultSeeder`, `TenantCreatedListener`.

**Đơn vị chạy.** `dh-platform` hồ sơ `api` (thao tác người dùng, API-18-030); hồ sơ `worker` (`TenantCreatedListener`, `FlagRetireReminderJob` 07:00 hằng ngày).

**FR hiện thực.** FR-18-008, 009, 010, 011; BR-18-008, 009, 010.

**Giao diện vào.** API-18-017…026, 030; sự kiện `platform.tenant.created.v1`.

**Phụ thuộc ra.** `ParamWriteService` (gói và mặc định đi qua đúng đường ghi của 4.2), Garage (tệp gói), `NotificationApi` (nhắc gỡ cờ), DNS nội bộ (kiểm tên miền egress).

**Dữ liệu.** `feature_flag`, `egress_allowlist_entry`, `param_bundle`, `inbox_event`.

**Sự kiện.** EVT-18-03, EVT-18-04, EVT-18-01 (gộp một sự kiện cho mỗi `ns` khi nhập gói hoặc ghi mặc định).

**Lỗi và xử lý.** ERR-18-002, 013, 020, 021, 022, 071; ERR-18-124 khi xử lý sự kiện PH-20 lỗi quá ba lần.

**Quan sát.** `dh_ops_flag_overdue{module}`, `dh_ops_egress_entries`, `dh_ops_seed_total{result}`, `dh_ops_bundle_import_total{result,dry_run}`.
:::

**Cờ tính năng.** Khóa theo mẫu `ff.{module}.{tính-năng}`; khai báo bắt buộc `owner` và `retireBy` ≤ 365 ngày (ERR-18-021); quá `retireBy` trừ `18.ff.retire-warning-days` thì gửi nhắc chủ sở hữu, không tự tắt (BR-18-008). Cờ là một khóa tham số kiểu `BOOL` nên đọc chung đường `dh-ops-client`.

**Egress.** `EgressHostValidator` chấp nhận FQDN công khai, cổng 443, ký tự đại diện tối đa một cấp đầu (`*.example.gov.vn`), từ chối IP literal, tên không có dấu chấm, hậu tố `.svc`, `.cluster.local`, `.internal` và tên phân giải ra dải nội bộ RFC 1918, RFC 6598, liên kết cục bộ (ERR-18-022, BR-18-009). Mỗi mục có `expiresAt`; số mục ≤ `18.egress.max-entries`. EVT-18-04 cho PH-13 cập nhật chính sách egress của Cilium và `dh-runtime`.

**Gói tham số.** Xuất: JSON chuẩn tắc (RFC 8785) gồm khóa, giá trị không ★, phiên bản lược đồ; ký bằng khóa transit OpenBao `dh-common-bundle`, lưu Garage `param-bundle/`. Khóa ★ chỉ xuất tên khóa, không xuất giá trị. Nhập: kiểm chữ ký và SHA-256 (ERR-18-020), so khớp với lược đồ đích, mặc định `dryRun = true` trả danh sách khác biệt; nhập thật cần bốn mắt và đi qua `ParamWriteService` từng khóa.

**Mặc định khi khởi tạo tenant.** `TenantDefaultSeeder.seed(tenant)` chèn `param_value` cho các khóa chưa có (`INSERT … ON CONFLICT DO NOTHING`), tạo lịch năm hiện hành từ lịch `COMMON`, sao mẫu thông báo mặc định; chạy lại không đổi gì (BR-18-010). Hai đường vào cùng một hàm: API-18-030 (PH-20 gọi đồng bộ trong saga khởi tạo) và `platform.tenant.created.v1` (đường dự phòng, inbox khử trùng theo `eventId`).

### 4.6. Tiếp nhận DLQ (`dlq.ingest`)

::: dac-ta
**Mục đích.** Đưa mọi bản tin lỗi từ topic `{tenant}.ops.dlq.v1` và từ API ghi vào chỉ mục bền, kiểm hợp đồng ngữ cảnh, đánh dấu `POISON`, đẩy payload lớn ra Garage, khử trùng theo `dlqKey`, và chỉ commit offset khi chỉ mục đã bền.

**Lớp chính.** `DlqTopicConsumer`, `DlqWriteController`, `DlqIngestService`, `HeaderNormalizer`, `ContextContractValidator`, `DlqKeyDeduplicator`, `PayloadStore`, `DlqIdFactory`, `DlqReceivedAggregator`, `DlqSourceService`.

**Đơn vị chạy.** `dh-platform` hồ sơ `worker` (bộ tiêu thụ); hồ sơ `api` (API-18-034…036).

**FR hiện thực.** FR-18-012, 013, 014, 015, 016; BR-18-011, 013, 014, 015; NFR-18-001, 002.

**Giao diện vào.** Topic `^[a-z0-9]+\.ops\.dlq\.v1$`, nhóm `ph18-dlq-ingest`; `DlqWriteApi`; API-18-031…036.

**Phụ thuộc ra.** Garage `dh-{tenant}-ops`, `ph18_ops`, `common` (outbox, inbox).

**Dữ liệu.** `dlq_message` (phân vùng tháng `received_at`), `dlq_payload_ref`, `dlq_source`, `dlq_group` (cập nhật đếm), `inbox_event`.

**Sự kiện.** EVT-18-05 (gộp theo phút), EVT-18-06 (mỗi mục `POISON`).

**Lỗi và xử lý.** ERR-18-024, 025, 026 (API); ERR-18-101…105 (bộ tiêu thụ, ghi vào mục, không trả HTTP).

**Quan sát.** `dh_ops_dlq_ingest_total{tenant,source,result}`, `dh_ops_dlq_ingest_lag_seconds`, `dh_ops_dlq_consumer_lag{partition}`, `dh_ops_dlq_payload_bytes`, `dh_ops_dlq_poison_total{source}`, `dh_ops_dlq_dedup_hits_total`, `dh_ops_dlq_partition_paused`.
:::

**Bộ tiêu thụ.** `DlqTopicConsumer` là bộ nghe Spring Kafka theo lô (`max.poll.records = 500`, `enable.auto.commit = false`, `AckMode.MANUAL`), đồng thời 3 luồng mỗi bản sao, tối đa 6 phân vùng mỗi topic tenant (NFR-18-001 tính 200 bản tin mỗi giây mỗi phân vùng). Giải mã bằng `ErrorHandlingDeserializer`: bản ghi không giải mã được vẫn đi tiếp dạng byte thô với cờ `undecodable` (ERR-18-101), không làm kẹt phân vùng. Với mỗi bản ghi của lô, bộ tiêu thụ gọi `DlqIngestService.ingest` trong một giao dịch riêng; lô chỉ được `acknowledge` khi mọi bản ghi đã commit. Lỗi hạ tầng (CSDL, Garage) làm bộ tiêu thụ `pause` phân vùng, lùi 5, 10, 30, 60 giây rồi `resume` và đọc lại từ offset chưa commit, nên không bản tin nào mất (NFR-18-002, BR-18-011).

**Chuẩn hóa header.** `HeaderNormalizer` đổi tên header về bộ chuẩn của FRS bảng 4.1b trước khi kiểm: `dh-error-code` thành `dh-dlq-error-code`, `dh-attempts` thành `dh-dlq-attempts`, `dhtenant` thành `dh-tenant`, `routeId` thành `dh-flow`, và rút `traceparent` thành `trace_id` 32 ký tự hex. PH-18 là chủ topic DLQ chung; PH-04 và D04-01 CC-CAMEL-05 đã đổi sang `{tenant}.ops.dlq.v1` và bộ header chuẩn, nên bảng đổi tên chỉ còn là cấu hình tương thích nguồn cũ, tắt mặc định và gỡ khi hết nguồn cũ (mục 13.6). Header `authorization`, `cookie` và các header xác thực khác bị loại trước khi lưu (`ck_dlq_message_headers`).

**Kiểm ngữ cảnh.** `ContextContractValidator` kiểm theo thứ tự: tenant ở header khớp tiền tố topic (lệch: lưu dưới tenant của topic với trạng thái `POISON`, `missing_context = {dh-tenant}`, ERR-18-103); nguồn đã đăng ký và `ACTIVE` (chưa đăng ký: vẫn lưu `POISON` để không mất, tạo nguồn tạm `UNREGISTERED`); đủ trường bắt buộc, trong đó `dh-flow`, `dh-version` chỉ bắt buộc với nguồn `KAFKA_TOPIC` (thiếu: `POISON`, ERR-18-102). Qua API thì cùng bộ kiểm nhưng thiếu trường trả ERR-18-024 (422) cho bên gọi sửa, vì bên gọi API có mặt để sửa còn bản tin trên topic thì không (FR-18-014). Mỗi mục `POISON` phát EVT-18-06; số mục `POISON` mỗi giờ đưa vào `ThresholdEvaluator` (§4.12).

**Mã mục lũy đẳng.** `DlqIdFactory` dựng `dlqId` dạng UUID v7 với 48 bit thời gian lấy từ timestamp của bản ghi Kafka và phần còn lại lấy từ SHA-256 của `topic:partition:offset`; với API thì lấy từ `Idempotency-Key` và tên nguồn. Nhờ vậy đọc lại cùng bản ghi sau sự cố sinh đúng `dlqId` cũ, khóa đối tượng Garage không đổi, và `inbox_event` chặn chèn lần hai.

**Payload lớn.** Payload ≤ `18.dlq.payload.inline-max-kb` và là JSON thì lưu nội tuyến (`payload_inline jsonb`); lớn hơn, hoặc không phải JSON (XML, nhị phân, bản tin không giải mã được), thì `PayloadStore` ghi Garage trước giao dịch CSDL với khóa `dlq/{yyyy}/{mm}/{dlqId}/0.bin`, mã hóa phía máy chủ, kèm SHA-256 và kích thước; ghi lại cùng khóa là lũy đẳng. Vượt `18.dlq.payload.max-mb` thì API trả ERR-18-025; trên topic thì không xảy ra vì `message.max.bytes` của topic nhỏ hơn trần. Đối tượng Garage mồ côi (ghi xong nhưng giao dịch CSDL lỗi vĩnh viễn) được `DlqReconciler` dọn sau 24 giờ.

**Khử trùng.** Vì `dlq_message` phân vùng theo `received_at` nên không đặt được chỉ mục duy nhất trên `dlqKey`. `DlqKeyDeduplicator` dùng hai lớp: (1) `inbox_event` khóa `dlq:{topic}:{partition}:{offset}` (hoặc khóa API) chặn đọc lại cùng bản ghi trong cửa sổ `18.dlq.dedup-window-days`; (2) trong giao dịch, lấy `pg_advisory_xact_lock(hashtextextended(tenant || ':' || dlqKey, 0))` rồi tìm mục chưa đóng cùng `dlqKey` qua `ix_dlq_message_key`; có thì chỉ tăng bộ đếm lần gặp, cập nhật lần gặp cuối và ghi `dlq_audit` loại `DUPLICATE_SEEN` (ERR-18-105), không thì chèn mục `NEW`. Bảng `dlq_message` hiện chưa có cột đếm lần gặp; mục 13.5 ghi đề nghị thêm cột cho CSDL.

**Giao dịch một bản ghi.** `SET LOCAL app.tenant_id`; ghi `inbox_event`; khóa tư vấn `dlqKey`; chèn hoặc cập nhật `dlq_message`, `dlq_payload_ref`; cập nhật `dlq_group` nếu đã gom được (§4.8); outbox EVT-18-06 nếu `POISON`; commit. EVT-18-05 không phát theo từng bản ghi: `DlqReceivedAggregator` đếm trong bộ nhớ theo (tenant, nguồn) và ghi một sự kiện mỗi phút mỗi bản sao qua outbox.

### 4.7. Liên thông PH-10 và đối soát (`dlq.federation`, `dlq.reconcile`)

::: dac-ta
**Mục đích.** Hiển thị DLQ tầng sự kiện của PH-10 trên cùng màn mà không sao chép nội dung, và bảo đảm chỉ mục DLQ không thiếu bản tin so với topic.

**Lớp chính.** `EventLayerDlqClient`, `EventDlqListener`, `FederatedDlqMapper`, `DlqReconciler`, `OrphanPayloadSweeper`.

**Đơn vị chạy.** `dh-platform` hồ sơ `worker` (bộ nghe EVT-10-11, đối soát theo `18.dlq.reconcile.cron`, ShedLock); hồ sơ `api` (API-18-039 gọi PH-10 khi người dùng mở).

**FR hiện thực.** FR-18-017, 018; BR-18-016; NFR-18-021.

**Giao diện vào.** EVT-10-11, EVT-10-12; API-18-037…040.

**Phụ thuộc ra.** API-10-060, 061 (`event:dlq-read`), API-10-063, 064 (`event:replay`, dùng ở 4.11); Kafka Admin API (offset đầu, cuối của phân vùng).

**Dữ liệu.** `dlq_message` với `payload_location = FEDERATED`, `source_module = PH10`, `external_ref`; `dlq_audit`.

**Sự kiện.** EVT-18-08 loại `RECONCILE_MISSING`.

**Lỗi và xử lý.** ERR-18-035 (PH-10 không phản hồi, cầu dao Resilience4j mở sau 50% lỗi trong 20 lượt); ERR-18-006 (đối soát đang chạy).

**Quan sát.** `dh_ops_dlq_federated_total`, `dh_ops_ph10_call_seconds`, `dh_ops_dlq_reconcile_missing_total`, `dh_ops_dlq_reconcile_seconds`.
:::

**Liên thông.** Nhận EVT-10-11, `EventDlqListener` tạo một dòng `dlq_message` chỉ có siêu dữ liệu (mã sự kiện PH-10 ở `external_ref`, topic gốc, mã lỗi, thời điểm), `payload_location = FEDERATED`, không có payload. Màn chi tiết gọi API-10-061 lúc mở để lấy phần PH-10 hiển thị, không lưu lại. Phát lại mục `FEDERATED` đi qua `EventLayerReplayPort` (§4.11); kết quả về qua EVT-10-12. Mục bị PH-10 đóng (EVT-10-12 kết quả cuối hoặc bị PH-10 dọn) thì chuyển `RESOLVED` hoặc `EXPIRED` theo PH-10.

**Đối soát.** `DlqReconciler` chạy cho từng tenant `ACTIVE` (danh sách từ registry PH-20): lấy offset đầu và cuối của từng phân vùng topic DLQ trong 24 giờ gần nhất, đếm số offset có trong `inbox_event` và `dlq_message.dlq_offset`, tính khoảng thiếu. Có khoảng thiếu thì mở một bộ tiêu thụ tạm (`assign` và `seek` đúng khoảng, không commit nhóm) đọc lại và gọi cùng `DlqIngestService`; cuối lượt phát EVT-18-08 loại `RECONCILE_MISSING` nếu số thiếu trước khi bù khác 0. Cùng tác vụ, `OrphanPayloadSweeper` xóa đối tượng Garage dưới `dlq/` không có dòng chỉ mục và cũ hơn 24 giờ.

### 4.8. Tra cứu, gom nhóm, phân loại (`dlq.triage`)

::: dac-ta
**Mục đích.** Cho người vận hành lọc, tìm, gom nhóm mục DLQ theo dấu hiệu lỗi, xem chi tiết kèm ngữ cảnh chẩn đoán, phân loại, đặt ưu tiên và gán người xử lý, đơn lẻ và hàng loạt.

**Lớp chính.** `DlqQueryService`, `DlqFilterSpec`, `FacetQuery`, `SignatureGrouper`, `MessageNormalizer`, `AssignmentService`, `DiagnosticsClient`, `DlqController`, `DlqReadController`, `DlqCsvExporter`.

**Đơn vị chạy.** `dh-platform` hồ sơ `api`; `SignatureGrouper` chạy cả trong giao dịch tiếp nhận (hồ sơ `worker`).

**FR hiện thực.** FR-18-019, 020, 021, 023, 026; BR-18-016, BR-18-017 (phần siêu dữ liệu).

**Giao diện vào.** `DlqReadApi`; API-18-041…046, 049…051, 060, 061, 063.

**Phụ thuộc ra.** API-13-069 (ngữ cảnh chẩn đoán theo `trace_id`), `TaskInboxApi` (việc khi gán người).

**Dữ liệu.** `dlq_message`, `dlq_group`, `dlq_assignment`, `dlq_audit`.

**Sự kiện.** EVT-18-07 khi đổi trạng thái `NEW` sang `TRIAGED`.

**Lỗi và xử lý.** ERR-18-003, 004, 006, 010; ERR-18-106 (chẩn đoán quá `18.dlq.diagnostics.timeout-ms`, màn vẫn hiện phần còn lại).

**Quan sát.** `dh_ops_dlq_query_seconds{facets}`, `dh_ops_dlq_groups_open`, `dh_ops_dlq_diagnostics_total{result}`.
:::

**Truy vấn danh sách.** `DlqQueryService` dựng truy vấn theo `DlqFilterSpec` (nguồn, luồng, mã lỗi, lớp lỗi, trạng thái, tuổi, người xử lý, nhóm, khoảng thời gian), luôn có điều kiện khoảng `received_at` để PostgreSQL chỉ quét phân vùng cần (mặc định 30 ngày, mục mở cũ hơn được tìm qua `ix_dlq_message_status`). Phân trang bằng con trỏ keyset (`received_at`, `id`), không dùng `OFFSET`. Bộ đếm theo nhóm (`facets`) chạy truy vấn thứ hai `GROUP BY GROUPING SETS ((source_code), (error_class), (status))` giới hạn 10.000 dòng gần nhất của bộ lọc, ghi rõ "ước tính" khi chạm giới hạn; như vậy trang 50 dòng có `facets` đạt p95 ≤ 1,5 giây trên 1 triệu mục (NFR-18-003, giả định đo ở đợt kiểm thử tải). Xuất CSV chỉ siêu dữ liệu, tối đa 50.000 dòng, chạy luồng trả về dạng streaming.

**Gom nhóm.** Dấu hiệu lỗi là `SHA-256(source_code | flow_code | error_code | normalize(error_message))`, trong đó `MessageNormalizer` thay chuỗi số bằng `#`, UUID và chuỗi hex dài bằng `*`, địa chỉ URL bằng máy chủ, cắt 300 ký tự. Mục mới tìm `dlq_group` cùng dấu hiệu còn mở trong `18.dlq.group.window-hours`; có thì gắn `group_id`, tăng `open_count`, `total_count`; không thì tạo nhóm. Màn gom nhóm (UI-18-02) đọc `dlq_group` nên không phải tính lại khi mở.

**Chi tiết và chẩn đoán.** Chi tiết đọc mục, lịch sử thao tác, bản sửa, lượt phát lại trong một truy vấn có `JOIN` theo (`tenant_id`, `id`, `received_at`). `DiagnosticsClient` gọi song song API-13-069 với `trace_id` của mục, thời gian chờ `18.dlq.diagnostics.timeout-ms` (mặc định 3 giây), kết quả đệm 5 phút theo `trace_id`; quá hạn thì trả phần chi tiết kèm cờ `diagnosticsUnavailable` (fail-soft).

**Phân loại và gán.** `AssignmentService` đổi lớp lỗi, ưu tiên `P1…P4`, người xử lý với `If-Match`; hàng loạt tới 1.000 mục chạy theo lô 100 mục mỗi giao dịch, mỗi mục kiểm `version` riêng và trả kết quả từng mục. Gán người tạo việc `ph18.dlq-assigned` để mục hiện ở "Việc của tôi". API đọc cho PH-17, PH-13 (`ops:dlq-read`) dùng token đổi từ người dùng nên chịu cùng RLS và quyền của người dùng; không có điểm cuối ghi nào nhận scope này (BR-18-016).

### 4.9. Xem và sửa payload (`dlq.payload`, `dlq.revision`)

::: dac-ta
**Mục đích.** Cho người có quyền xem nội dung bản tin lỗi khi có lý do và sửa nội dung có kiểm soát bằng bản sửa riêng, không đụng bản gốc, với bốn mắt khi chạm trường mức Hạn chế hoặc Nhạy cảm.

**Lớp chính.** `PayloadRevealService`, `RevealTicketStore`, `PayloadMasker`, `SkeletonExtractor`, `RevisionService`, `PayloadPatcher`, `SchemaValidator`, `RestrictedFieldDetector`, `RevisionDiffService`.

**Đơn vị chạy.** `dh-platform` hồ sơ `api`.

**FR hiện thực.** FR-18-022, 024; BR-18-012, 017, 018.

**Giao diện vào.** API-18-047, 048, 052…056.

**Phụ thuộc ra.** Garage (đọc payload, ghi bản sửa lớn), `dh-privacy-client` của PH-09 (mức phân loại trường), Apicurio (lược đồ theo `schema_ref`), `OpsAuditRecorder` đồng bộ, `FourEyesGuard`, `TaskInboxApi`.

**Dữ liệu.** `dlq_message`, `dlq_payload_ref`, `dlq_revision`, `dlq_audit`; Valkey `ops:{tenant}:reveal:{ticketId}`.

**Sự kiện.** EVT-18-07 khi bản sửa được duyệt làm mục từ `POISON` sang `TRIAGED`.

**Lỗi và xử lý.** ERR-18-005, 007, 008, 027, 029, 030; ERR-18-104 (tổng kiểm tra Garage lệch).

**Quan sát.** `dh_ops_dlq_reveal_total{result}`, `dh_ops_dlq_revision_total{status}`, `dh_ops_dlq_revision_pending`.
:::

**Xem có lý do.** `PayloadRevealService.reveal(dlqId, reason)` kiểm `PERM-18-dlq-payload` và lý do ≥ 10 ký tự (ERR-18-007); ghi kiểm toán đồng bộ trước khi đọc nội dung (BR-18-017; ghi lỗi thì ERR-18-008, không trả nội dung); đọc nội tuyến hoặc Garage, so SHA-256 (lệch: ERR-18-104); qua `PayloadMasker` giữ nguyên dạng mã hóa của các trường nguồn đã mã hóa bằng transit `dh-{tenant}-pii` (PH-18 không giải mã) và che các trường PH-09 phân loại Nhạy cảm; trả kèm phiếu xem hạn `18.dlq.reveal.ttl-minutes`. Trong hạn phiếu, các lần xem lại cùng mục không cần nhập lý do lại nhưng vẫn ghi kiểm toán. Payload đã `PURGED` trả ERR-18-027. Không có quyền payload thì chỉ xem khung cấu trúc (API-18-048) do `SkeletonExtractor` dựng từ tên trường và kiểu, không có giá trị.

**Sửa payload.** Bản sửa nhận nội dung mới hoặc JSON Patch RFC 6902; `PayloadPatcher` áp lên bản gốc (hoặc bản sửa `APPROVED` mới nhất) để có nội dung đầy đủ, `SchemaValidator` kiểm theo `schema_ref` của mục (ERR-18-029). `RestrictedFieldDetector` lấy tập đường dẫn trường bị đổi, hỏi PH-09 mức phân loại theo lược đồ dữ liệu của luồng; có trường Hạn chế hoặc Nhạy cảm, hoặc PH-09 không trả lời được, thì bản sửa `PENDING_APPROVAL` và mở việc `ph18.approve-revision` (đóng an toàn); không thì `APPROVED` ngay. Mỗi mục chỉ có một bản sửa chờ duyệt (ERR-18-030). Bản sửa lớn hơn 256 KB lưu Garage `dlq/{yyyy}/{mm}/{dlqId}/{revision}.bin`. Bản gốc không bao giờ bị ghi đè (trigger `tg_dlq_payload_guard`). Mục `POISON` có bản sửa được duyệt thì chuyển `TRIAGED`, từ đó mới phát lại được.

### 4.10. Sổ tay xử lý theo mã lỗi (`dlq.guide`)

::: dac-ta
**Mục đích.** Giữ hướng dẫn xử lý theo mã ERR của mọi phân hệ, hiện cạnh mục DLQ cùng mã, và làm nguồn tri thức cho PH-17.

**Lớp chính.** `ErrorGuideService`, `ErrorGuideController`, `ErrorGuideFeedController`, `GuideContentSanitizer`.

**Đơn vị chạy.** `dh-platform` hồ sơ `api`.

**FR hiện thực.** FR-18-025, 026 (phần sổ tay); BR-18-050.

**Giao diện vào.** API-18-057, 058, 059, 062.

**Phụ thuộc ra.** `OutboxWriter`.

**Dữ liệu.** `error_guide` (dòng `COMMON` do PA soạn, dòng tenant bổ sung).

**Sự kiện.** EVT-18-11 mỗi lần đổi phiên bản hướng dẫn (giải Q17-63 phía PH-18).

**Lỗi và xử lý.** ERR-18-003, 004.

**Quan sát.** `dh_ops_error_guide_total`, `dh_ops_error_guide_coverage_ratio` (tỷ lệ mã ERR xuất hiện trong DLQ 30 ngày có hướng dẫn).
:::

Nội dung là Markdown giới hạn (không HTML, không ảnh nhúng, liên kết chỉ tới route nội bộ hoặc tài liệu D06), được `GuideContentSanitizer` làm sạch và kiểm không chứa mẫu số định danh, số điện thoại, địa chỉ thư (BR-18-050). Hướng dẫn dòng tenant ghi đè dòng `COMMON` cùng mã khi hiển thị cho tenant đó. Nguồn cho PH-17 (API-18-062) trả theo `updatedSince`, phân trang con trỏ.

### 4.11. Phát lại qua `ReplayPort` (`dlq.replay`)

::: dac-ta
**Mục đích.** Đưa mục DLQ (bản gốc hoặc bản sửa đã duyệt) về lối vào của nguồn, đơn lẻ hoặc theo loạt, với tốc độ giới hạn, bốn mắt cho loạt lớn, tạm dừng, tiếp tục, hủy, và nhận kết quả lũy đẳng.

**Lớp chính.** `ReplayJobService`, `ReplayItemSnapshotter`, `ReplayDispatcher`, `ReplayPortRegistry`, `KafkaTopicReplayPort`, `HttpReplayPort`, `EventLayerReplayPort`, `NoReplayPort`, `ReplayRateLimiter`, `ReplayResultHandler`, `ReplayTimeoutSweeper`, `ReplayFailureGuard`, `ReplayController`, `ReplayResultController`.

**Đơn vị chạy.** `dh-platform` hồ sơ `api` (tạo, gửi, duyệt, điều khiển, API-18-076); hồ sơ `worker` (`ReplayDispatcher` mỗi giây, `ReplayTimeoutSweeper` mỗi phút).

**FR hiện thực.** FR-18-027, 028, 029, 030; BR-18-019…022; NFR-18-006.

**Giao diện vào.** `ReplayResultApi`; API-18-064…076; EVT-10-12; kết quả của nguồn `KAFKA_TOPIC` qua API-18-076.

**Phụ thuộc ra.** `ReplayPort` theo `replayMode` của nguồn: topic `{tenant}.ops.replay.requested.v1` (EVT-18-09) qua outbox, API nội bộ của nguồn qua mTLS, API-10-063, 064; Valkey (thùng token, khóa loạt); `FourEyesGuard`, `TaskInboxApi`, `DegradedModeGuard`.

**Dữ liệu.** `replay_job`, `replay_item`, `dlq_message`, `dlq_audit`; Valkey `ops:replay:{jobId}:rate`, `ops:replay:{jobId}:lease`.

**Sự kiện.** EVT-18-09, EVT-18-10, EVT-18-07; EVT-18-08 loại `REPLAY_FAILURE_RATE`.

**Lỗi và xử lý.** ERR-18-005, 028, 031, 032, 033, 036, 037, 038; ERR-18-107, 108, 109 ghi vào `replay_item`.

**Quan sát.** `dh_ops_replay_dispatch_total{mode,result}`, `dh_ops_replay_rate_actual{job}`, `dh_ops_replay_jobs{status}`, `dh_ops_replay_result_seconds`, `dh_ops_replay_timeout_total`.
:::

**Cổng theo loại nguồn.** `ReplayPortRegistry` chọn hiện thực theo `dlq_source.replayMode` (FRS §4.1):

| `replayMode` | Hiện thực | Cách gửi | Kết quả về |
|---|---|---|---|
| `KAFKA_TOPIC` | `KafkaTopicReplayPort` | Ghi outbox EVT-18-09 khóa `sourceCode`, mang `dlqId`, `revision`, `idempotencyKey`, `payloadRef`; nguồn (PH-04 runtime, PH-05, PH-06, PH-07, PH-08) đọc rồi lấy nội dung theo `payloadRef` | Callback API-18-076 |
| `HTTP_PORT` | `HttpReplayPort` | `POST` tới URL nội bộ đã đăng ký (`/…/internal/v1`), thân mang nội dung và `Idempotency-Key = dlqId:revision`; thời gian chờ 10 giây, thử lại hai lần với lỗi mạng hoặc `503`, cầu dao theo nguồn | Đồng bộ trong phản hồi, hoặc callback nếu nguồn trả `202` |
| `EVENT_LAYER` | `EventLayerReplayPort` | API-10-063 (đề nghị phát lại) và API-10-064 (theo dõi) bằng scope `event:replay`; PH-10 giữ duyệt phía sự kiện | EVT-10-12 |
| `NONE` | `NoReplayPort` | Không gửi; từ chối ERR-18-033 | Không |

: Hiện thực ReplayPort theo loại nguồn

Không hiện thực nào nhận địa chỉ HTTT đích; URL của `HTTP_PORT` bị kiểm lúc đăng ký phải là tên dịch vụ trong cụm của DU nguồn (FR-18-012). Nguồn `KAFKA_TOPIC` lấy nội dung theo `payloadRef` qua API-18-188 `GET /ops/internal/v1/replay-payloads/{dlqId}/{revision}` scope `ops:replay-callback` (FRS 0.2), chỉ trả cho đúng nguồn của mục (ERR-18-038) trong hạn `18.dlq.replay.result-timeout-minutes`.

**Tạo và chốt danh sách.** Lượt một mục (FR-18-027) là lượt loạt có một mục, đi cùng đường để chỉ có một bộ máy trạng thái. `ReplayJobService.create` nhận bộ lọc hoặc danh sách, `ReplayItemSnapshotter` chốt danh sách ngay lúc tạo vào `replay_item` (BR-18-021) và loại mục `POISON`, mục đang trong lượt khác, mục của nguồn `NONE`; kết quả rỗng thì ERR-18-036, quá `18.dlq.replay.batch-max` thì ERR-18-032. Khóa lũy đẳng mỗi mục là `dlqId:revision` với `revision` là bản sửa `APPROVED` mới nhất hoặc `0`. Gửi lượt: số mục ≤ `18.dlq.replay.approval-threshold` thì `APPROVED` ngay; lớn hơn thì `PENDING_APPROVAL` và mở việc `ph18.approve-replay`. Duyệt kiểm lại từng mục (mục đã đóng hoặc đã vào lượt khác bị đánh dấu `SKIPPED`), kiểm người duyệt khác người tạo (ERR-18-005).

**Điều phối và giới hạn tốc độ.** `ReplayDispatcher` chạy mỗi giây ở mọi bản sao `worker`. Mỗi vòng, bản sao giành lượt `RUNNING` bằng khóa thuê Valkey `ops:replay:{jobId}:lease` (30 giây, gia hạn mỗi vòng) để một lượt chỉ một bản sao gửi; lấy tối đa `n` mục chưa gửi bằng `SELECT … FOR UPDATE SKIP LOCKED LIMIT n` với `n` bằng số token lấy được từ `ReplayRateLimiter`. Thùng token dùng script Lua trên Valkey, tốc độ là `min(replay_job.rate_per_second, dlq_source.rate_cap)` và không vượt trần nguồn (ERR-18-037 khi người dùng đặt cao hơn). Valkey vắng thì dùng hạn mức cục bộ bằng tốc độ chia số bản sao `worker`, đánh dấu chỉ số `dh_ops_replay_rate_actual` để thấy chế độ dự phòng. Ở tốc độ mặc định 10 mục mỗi giây, 10.000 mục mất khoảng 17 phút, trong chỉ tiêu 20 phút (NFR-18-006).

**Gửi một mục.** Trong một giao dịch ngắn: mục DLQ từ `NEW`, `TRIAGED` hoặc `REPLAY_FAILED` sang `REPLAY_PENDING` rồi `REPLAYING`, `replay_item.dispatched_at`, tăng `replayCount`, ghi `dlq_audit`; với `KAFKA_TOPIC` thì outbox EVT-18-09 cùng giao dịch. Với `HTTP_PORT` và `EVENT_LAYER` thì lời gọi mạng nằm ngoài giao dịch, kết quả được ghi bằng giao dịch thứ hai; bản sao chết giữa hai giao dịch để lại mục `REPLAYING` mà `ReplayTimeoutSweeper` xử lý. Nguồn tự chống trùng theo khóa lũy đẳng và giữ khóa ≥ 30 ngày (BR-18-020), nên gửi lại sau sự cố là an toàn.

**Nhận kết quả.** `ReplayResultHandler.accept(result)` (API-18-076, EVT-10-12, phản hồi đồng bộ của `HTTP_PORT`) kiểm danh tính SPIFFE của bên báo khớp nguồn của mục (ERR-18-038), rồi `UPDATE replay_item SET result = … WHERE idempotency_key = ? AND result IS NULL`; không dòng nào đổi thì là báo trùng, trả `200` không làm gì. Thành công thì mục sang `RESOLVED`; thất bại thì `REPLAY_FAILED` kèm mã lỗi của nguồn (ERR-18-107). Cập nhật bộ đếm lượt bằng `UPDATE … SET succeeded = succeeded + 1` để không mất đếm khi nhiều kết quả về cùng lúc. Lượt hết mục chưa có kết quả thì kết thúc: tất cả thành công `COMPLETED`, có thành công có thất bại `PARTIAL`, không thành công nào `FAILED`.

**Tự dừng, tạm dừng, hủy.** `ReplayFailureGuard` tính tỷ lệ lỗi trên cửa sổ 50 kết quả gần nhất; vượt `18.dlq.threshold.replay-failure-percent` thì lượt sang `PAUSED`, phát EVT-18-08 loại `REPLAY_FAILURE_RATE` (BR-18-022). Tạm dừng, tiếp tục, đổi tốc độ (`If-Match`) và hủy là thao tác của người dùng; hủy chỉ dừng mục chưa gửi, mục đã gửi vẫn chờ kết quả. Hủy và tạm dừng được ghi kiểm toán trễ qua outbox (BR-18-046) để luôn thực hiện được khi PH-13 chậm. `ReplayTimeoutSweeper` chuyển mục không có kết quả sau `18.dlq.replay.result-timeout-minutes` sang `REPLAY_FAILED` với ERR-18-109.

### 4.12. Bỏ qua, lưu giữ, thống kê, ngưỡng (`dlq.lifecycle`, `dlq.stats`)

::: dac-ta
**Mục đích.** Đóng mục có lý do, mở lại trong hạn, dọn theo hạn lưu giữ, tính thống kê và phát chỉ số, sự kiện vượt ngưỡng để PH-13 cảnh báo.

**Lớp chính.** `DiscardService`, `ReopenService`, `RetentionJob`, `PartitionMaintenanceJob`, `DlqStatsService`, `ThresholdEvaluator`, `DlqMetricsBinder`.

**Đơn vị chạy.** `dh-platform` hồ sơ `api` (bỏ qua, mở lại, thống kê); hồ sơ `worker` (`RetentionJob` 02:00, `PartitionMaintenanceJob` 01:30, `ThresholdEvaluator` mỗi phút, `DlqMetricsBinder` mỗi 30 giây; ShedLock).

**FR hiện thực.** FR-18-031, 032, 033, 034; BR-18-023…026.

**Giao diện vào.** API-18-077…081.

**Phụ thuộc ra.** Garage (xóa payload), `OutboxWriter`, thủ tục `p_ensure_partitions`, `p_drop_partitions_before`.

**Dữ liệu.** `dlq_message`, `dlq_payload_ref`, `dlq_revision`, `dlq_audit`, `dlq_group`, `incident_link` (giữ pháp lý).

**Sự kiện.** EVT-18-07, EVT-18-08 (`DEPTH`, `AGE`, `POISON_RATE`).

**Lỗi và xử lý.** ERR-18-006, 007, 034; ERR-18-104 khi xóa Garage lỗi (thử lại hôm sau, không đặt `PURGED`).

**Quan sát.** `dh_ops_dlq_open{tenant,source,class}`, `dh_ops_dlq_open_oldest_seconds{tenant,source}`, `dh_ops_dlq_poison_rate`, `dh_ops_dlq_threshold_crossed_total{type}`, `dh_ops_dlq_purged_total`.
:::

**Bỏ qua và mở lại.** Bỏ qua cần mã lý do và mô tả ≥ 10 ký tự (ERR-18-007, BR-18-023); hàng loạt tới 1.000 mục chung một lý do. Mục `DISCARDED` mở lại được về `TRIAGED` tới khi `EXPIRED` (ERR-18-034, BR-18-024).

**Lưu giữ.** `RetentionJob` lặp tenant, chọn mục đã đóng có `closed_at` quá `18.dlq.retention.closed-days` và không có liên kết sự cố mở hay lệnh giữ pháp lý (BR-18-025), xóa đối tượng Garage trước rồi mới đặt `payload_location = PURGED`, `status = EXPIRED` (thứ tự này để không bao giờ có dòng `PURGED` mà đối tượng còn). Mục mở quá `18.dlq.retention.open-max-days` không bị dọn mà phát EVT-18-08 loại `AGE`. `PartitionMaintenanceJob` giữ hai tháng phân vùng phía trước và tách, xóa phân vùng khi không còn mục mở và quá `18.dlq.retention.metadata-days` (D03-03-PH18 §3.58).

**Bảng phân vùng và dọn lưu giữ của phân hệ khác.** `PartitionMaintenanceJob` còn gọi hằng ngày `ph20_tenant.p_ensure_partitions('ph20_tenant.usage_snapshot', ngày, 3)` để tạo trước ba tháng phân vùng (thủ tục của PH-20, danh tính dịch vụ của job được PH-20 cấp `EXECUTE`; danh sách bảng ngoài PH-18 là cấu hình `PartitionTarget`). `DETACH` và `DROP` phân vùng cũ vẫn do `ph20_owner` chạy theo `20.usage.retention-months`. Việc dọn `outbox`, `inbox_event`, `idempotency_key`, `file_object`, `usage_report`, `org_import_*` của PH-20 và dọn lưu giữ của PH-01 do từng phân hệ chạy trong tác vụ nền của mình bằng vai chủ schema đó; PH-18 không ghi vào schema phân hệ khác, ngoài lời gọi thủ tục này và công cụ chuyển sáp nhập (FR-18-057).

**Ngưỡng và chỉ số.** `ThresholdEvaluator` mỗi phút tính theo (tenant, nguồn): số mục chưa xử lý so `18.dlq.threshold.depth`, tuổi mục cũ nhất so `18.dlq.threshold.age-hours`, số `POISON` một giờ so `18.dlq.threshold.poison-per-hour`. Vượt thì phát EVT-18-08 một lần khi chuyển từ dưới lên trên ngưỡng (có độ trễ 10% để không dao động), không phát lại mỗi phút. PH-18 không tự làm luật cảnh báo (BR-18-026); `DlqMetricsBinder` đẩy cùng các số đo thành chỉ số Prometheus để PH-13 đặt luật (§10). Thống kê API-18-081 đọc bảng tổng hợp theo giờ do `DlqStatsService` cập nhật cùng tác vụ, không quét bảng gốc.

### 4.13. Mẫu thông báo (`notify.template`)

::: dac-ta
**Mục đích.** Quản mẫu thư, SMS, thông báo trong ứng dụng có phiên bản và duyệt hai người, từ chối mẫu có logic hoặc dùng trường mức Hạn chế, Nhạy cảm hoặc chưa xác định mức.

**Lớp chính.** `TemplateService`, `TemplateVersionLifecycle`, `LogiclessTemplateValidator`, `ForbiddenFieldChecker`, `TemplateRenderer`, `TemplatePreviewService`.

**Đơn vị chạy.** `dh-platform` hồ sơ `api`.

**FR hiện thực.** FR-18-035; BR-18-027; FR-00-062.

**Giao diện vào.** API-18-082…090.

**Phụ thuộc ra.** `dh-privacy-client` (mức phân loại của biến theo lược đồ dữ liệu sự kiện, nguồn PH-09), `FourEyesGuard`, `TaskInboxApi`.

**Dữ liệu.** `notification_template`, `notification_template_version` (dòng `COMMON` do PA soạn, dòng tenant tùy biến).

**Sự kiện.** Không phát sự kiện riêng; kiểm toán mỗi lần chuyển trạng thái.

**Lỗi và xử lý.** ERR-18-005, 039, 040, 041.

**Quan sát.** `dh_ops_template_versions{status}`, `dh_ops_template_rejected_total{reason}`.
:::

**Mustache không logic.** `LogiclessTemplateValidator` phân tích mẫu bằng trình phân tích của JMustache rồi duyệt cây: chỉ chấp nhận văn bản và biến `{{ten}}` đã khai báo trong `variables` của phiên bản (ERR-18-040 kèm dòng); từ chối khối điều kiện, vòng lặp, partial, lambda và biến ba ngoặc không thoát. Liên kết trong mẫu chỉ là đường dẫn nội bộ ghép với gốc của tenant (`ck_notification_message_link`), không nhận URL tuyệt đối do bên gọi truyền.

**Kiểm trường cấm.** Mỗi biến khai báo nguồn (`event:EVT-02-04.serviceName` hoặc `caller`). `ForbiddenFieldChecker` hỏi PH-09 mức của từng trường; mức Hạn chế, Nhạy cảm hoặc không trả lời được đều bị từ chối ERR-18-039 (đóng an toàn, BR-18-027). Biến nguồn `caller` chỉ nhận tập tên cố định (`ten_nguoi_nhan`, `ma_doi_tuong`, `duong_dan`, `han_xu_ly`, `ten_tinh`) có kiểu và độ dài; ở lúc gửi, giá trị vẫn được kiểm lại không khớp mẫu số định danh, số điện thoại (§4.14). Duyệt phiên bản (`IN_REVIEW` sang `ACTIVE`) cần người khác người soạn; mỗi mẫu có đúng một phiên bản `ACTIVE`, phiên bản cũ `RETIRED` khi phiên bản mới kích hoạt.

### 4.14. Gửi thông báo (`notify.dispatch`, `notify.channel`)

::: dac-ta
**Mục đích.** Nhận yêu cầu gửi từ phân hệ, lưu vào outbox thông báo, phân giải người nhận, áp tùy chọn và giờ yên lặng, dựng nội dung theo mẫu, gửi qua thư, SMS, trong ứng dụng với thử lại, và cho tra nhật ký gửi.

**Lớp chính.** `NotificationService`, `IdempotencyStore`, `DeliveryWorker`, `UrgentDeliveryWorker`, `RecipientResolver`, `QuietHoursPolicy`, `SuppressionFilter`, `ParamValueGuard`, `MailChannel`, `SmsChannel`, `InAppChannel`, `RetryScheduler`, `DeliveryLogQuery`, `NotificationInternalController`.

**Đơn vị chạy.** `dh-platform` hồ sơ `api` (nhận yêu cầu, gửi đồng bộ, tra cứu); hồ sơ `worker` (`DeliveryWorker` hai làn thường và khẩn).

**FR hiện thực.** FR-18-036, 037, 040 (thử lại), 041; BR-18-028, 029, 030; NFR-18-007, 008.

**Giao diện vào.** `NotificationApi`; API-18-091…094, 097, 098, 102, 103.

**Phụ thuộc ra.** PH-12 (người, nhóm, vai trò, liên hệ), PH-01 (đầu mối HTTT), máy chủ thư qua SMTP STARTTLS (Spring Mail `JavaMailSender`), SMS gateway REST (IF-09), OpenBao `kv/dh/common/notify/smtp` và `kv/dh/common/notify/sms`, `WorkingCalendarApi` (múi giờ).

**Dữ liệu.** `notification_message` (outbox thông báo), `notification_delivery` (phân vùng `queued_at`), `user_notification_pref`, `suppression_entry`.

**Sự kiện.** EVT-18-13 khi hết lượt thử; EVT-18-12 do 4.15 phát.

**Lỗi và xử lý.** ERR-18-009, 039, 041, 042, 043, 044; ERR-18-110, 111, 113 ghi vào lần gửi.

**Quan sát.** `dh_ops_notify_submitted_total{caller,priority}`, `dh_ops_notify_delivery_total{channel,result}`, `dh_ops_notify_queue_depth{lane}`, `dh_ops_notify_end_to_end_seconds{priority}`, `dh_ops_notify_suppressed_total{reason}`.
:::

**Nhận yêu cầu.** `NotificationService.submit` kiểm `Idempotency-Key` trong 24 giờ (trùng khóa khác thân: ERR-18-009, BR-18-028), mẫu có phiên bản `ACTIVE` (ERR-18-041), `ParamValueGuard` kiểm từng biến đúng tập khai báo và không khớp mẫu số định danh 12 chữ số, số điện thoại, địa chỉ thư (ERR-18-039), rồi chèn `notification_message` `QUEUED` với `recipientRef` chưa phân giải. Bên gọi nhận `202` kèm `messageId`; phân hệ gọi không bao giờ nhận địa chỉ (BR-18-029).

**Hai làn gửi.** `DeliveryWorker` lấy thông báo `QUEUED` thường bằng `FOR UPDATE SKIP LOCKED` theo lô 100; `UrgentDeliveryWorker` chỉ lấy mức `URGENT`, chạy luồng riêng, vòng 1 giây, nên hàng đợi thường tồn 5.000 thông báo vẫn đạt p95 ≤ 30 giây cho thông báo khẩn (NFR-18-008). Mỗi thông báo: `RecipientResolver` đổi `recipientRef` (`USER`, `GROUP`, `ROLE`, `SYSTEM_CONTACT`, `EVENT_FIELD`, `ON_CALL`) thành danh sách người nhận có kênh, đệm kết quả nhóm và vai trò 5 phút (không phân giải được: ERR-18-042); với mỗi người nhận và kênh, `SuppressionFilter` loại địa chỉ trong danh sách chặn (ERR-18-113), `QuietHoursPolicy` hoãn tới hết giờ yên lặng (tối đa 12 giờ) hoặc đánh dấu `SUPPRESSED` theo tùy chọn người dùng, trừ thông báo bắt buộc và `URGENT` (BR-18-030); `TemplateRenderer` dựng nội dung, kênh gửi, ghi `notification_delivery`. Địa chỉ lưu ở `notification_delivery` chỉ dạng che và băm SHA-256 có muối theo tenant.

**Kênh.** `MailChannel` dùng `JavaMailSender` qua SMTP STARTTLS cổng 587, tên người gửi `18.notify.sender-name`, mỗi thư có `Message-ID` chứa mã lần gửi để ghép thư trả lại; không đính kèm tệp. `SmsChannel` gọi REST của gateway qua mTLS hoặc TLS có khóa API lấy từ OpenBao lúc khởi động và làm mới khi OpenBao báo xoay; chỉ bật khi `18.notify.sms.enabled`. `InAppChannel` ghi lần gửi kênh `IN_APP`, `dh-console` đọc qua khung nhìn `notification`. Mỗi kênh có cầu dao riêng; lỗi tạm thì `RetryScheduler` lùi lũy thừa 1, 5, 15, 60 phút trong `18.notify.retry.window-hours`, tối đa `18.notify.retry.max-attempts`, sau đó `FAILED` và EVT-18-13.

**Gửi đồng bộ.** `sendSync` (API-18-092) chạy cùng đường nhưng trong luồng yêu cầu, chỉ kênh thư, chờ máy chủ thư nhận (`250` của SMTP) tối đa `18.notify.sync.timeout-ms`; quá hạn hoặc kênh lỗi thì ERR-18-044 và thông báo không được xếp hàng lại (bên gọi tự quyết), đúng nhu cầu thư mang liên kết một lần của PH-01 (Q01-52).

### 4.15. Quy tắc sự kiện, tùy chọn nhận, thư trả lại (`notify.rule`, `notify.pref`, `notify.bounce`)

::: dac-ta
**Mục đích.** Biến sự kiện của các phân hệ thành thông báo hoặc việc theo quy tắc do tỉnh cấu hình, giữ tùy chọn nhận và giờ yên lặng của người dùng, xử lý thư trả lại và báo nhận để giữ danh sách chặn.

**Lớp chính.** `NotificationRuleConsumer`, `RuleMatcher`, `RuleService`, `PreferenceService`, `BounceHandler`, `DsnParser`, `SuppressionService`.

**Đơn vị chạy.** `dh-platform` hồ sơ `worker` (bộ tiêu thụ sự kiện); hồ sơ `api` (quy tắc, tùy chọn, API-18-106).

**FR hiện thực.** FR-18-038, 039, 040; BR-18-028, 030, 031.

**Giao diện vào.** Sự kiện ở FRS bảng 9.3b; API-18-095, 096, 099…101, 104…106.

**Phụ thuộc ra.** `NotificationService` (4.14), `TaskInboxApi` (quy tắc có `create_task_type`), `OutboxWriter`.

**Dữ liệu.** `notification_rule`, `user_notification_pref`, `suppression_entry`, `inbox_event`.

**Sự kiện.** EVT-18-12 khi một địa chỉ vào danh sách chặn.

**Lỗi và xử lý.** ERR-18-003, 045, 046; ERR-18-112; ERR-18-124 khi xử lý một sự kiện lỗi quá ba lần (sự kiện đó được ghi vào chính DLQ của PH-18 với nguồn `PH18`).

**Quan sát.** `dh_ops_rule_events_total{source_ph,result}`, `dh_ops_rule_lag_seconds`, `dh_ops_bounce_total{type}`, `dh_ops_suppressions`.
:::

**Quy tắc theo sự kiện.** `NotificationRuleConsumer` tiêu thụ theo mẫu topic của các sự kiện ở FRS bảng 9.3b (nhóm `ph18-notify-rules`), inbox khử trùng theo `eventId`. `RuleMatcher` chọn quy tắc `enabled` cùng `event_type` của tenant và `COMMON`, đánh giá `condition` (biểu thức bằng nhau trên trường của phong bì CloudEvents, không cho biểu thức tùy ý), rồi gọi `NotificationService.submit` với khóa lũy đẳng `eventId:ruleId` (BR-18-028) hoặc `TaskInboxApi.upsert` khi quy tắc có `create_task_type`. Quy tắc chỉ được tạo cho sự kiện PH-18 đang tiêu thụ (ERR-18-045).

**Tùy chọn nhận.** Người dùng bật, tắt theo nhóm thông báo và kênh, đặt giờ yên lặng riêng (mặc định `18.notify.quiet-hours`); nhóm bắt buộc không tắt được (ERR-18-046). Tùy chọn ghi với `If-Match`.

**Thư trả lại và báo nhận.** Máy chủ thư của tỉnh chuyển thư DSN (RFC 3464) về hộp nhận nội bộ; một bộ chuyển nhỏ cạnh máy chủ thư gọi API-18-106 với nội dung DSN đã rút gọn; SMS gateway gọi cùng API với báo nhận (Q18-27). `BounceHandler` ghép theo `Message-ID` hoặc mã lần gửi, đặt lần gửi `BOUNCED` hoặc `DELIVERED`. Trả lại cứng, hoặc trả lại mềm quá `18.notify.bounce.soft-limit` lần trong 30 ngày, thì `SuppressionService` thêm `suppression_entry` (băm địa chỉ) và phát EVT-18-12 cho PH-12, PH-01 đánh dấu liên hệ (BR-18-031). Gỡ chặn cần quyền `PERM-18-template` và lý do.

### 4.16. Hộp việc (`task.inbox`)

::: dac-ta
**Mục đích.** Cho phân hệ đăng ký loại việc và tạo, cập nhật, đóng việc lũy đẳng; cấp "Việc của tôi" theo quyền, hạn, quá hạn, nhắc và leo thang.

**Lớp chính.** `TaskTypeRegistry`, `TaskService`, `TaskVisibilityFilter`, `MyTasksQuery`, `TaskSummaryCache`, `ReminderJob`, `EscalationJob`, `TaskController`, `TaskInternalController`.

**Đơn vị chạy.** `dh-platform` hồ sơ `api`; `ReminderJob`, `EscalationJob` ở hồ sơ `worker` mỗi 5 phút (ShedLock).

**FR hiện thực.** FR-18-042, 043, 044; BR-18-032; NFR-18-009; FR-00-070…072.

**Giao diện vào.** `TaskInboxApi`; API-18-107…112.

**Phụ thuộc ra.** PH-12 (quyền xem `required_permission`, thành viên nhóm, vai trò), `NotificationApi` (nhắc), `WorkingCalendarApi` (hạn theo ngày làm việc).

**Dữ liệu.** `task_type`, `task_item`, `task_reminder`.

**Sự kiện.** EVT-18-14.

**Lỗi và xử lý.** ERR-18-017 (loại việc ngoài tiền tố phân hệ), ERR-18-047, 048, ERR-18-005 (việc bốn mắt không giao cho chính người đề nghị).

**Quan sát.** `dh_ops_task_open{type}`, `dh_ops_task_overdue{type}`, `dh_ops_task_upsert_total{result}`, `dh_ops_my_tasks_seconds`.
:::

**Lũy đẳng.** Việc được định danh bằng (`type_code`, `task_key`) với `task_key` là `sourceRef` của phân hệ nguồn; `PUT /tasks/{sourceRef}` là `INSERT … ON CONFLICT (tenant_id, type_code, task_key) DO UPDATE` chỉ khi việc chưa đóng (đã đóng: ERR-18-048, trừ khi thân giống hệt thì trả `200`). Phân hệ nguồn là chủ trạng thái và là bên đóng việc (BR-18-032); người dùng bấm vào việc thì được đưa tới màn của phân hệ nguồn theo `link`, không duyệt ngay trên PH-18 (trừ việc của chính PH-18).

**Việc của tôi.** `MyTasksQuery` chọn việc mở giao cho người dùng (`USER`), cho nhóm hoặc vai trò người dùng thuộc về (lấy từ token, không gọi PH-12 mỗi lần), rồi `TaskVisibilityFilter` loại việc người dùng không còn `required_permission` và việc bốn mắt do chính người dùng đề nghị. Thẻ trang chủ (`?summary=true`) đọc `TaskSummaryCache` đệm 30 giây theo người dùng. Việc mới hiện trong ≤ 10 giây vì đọc trực tiếp bảng, đệm tóm tắt bị xóa khi có EVT-18-14 cho người đó (NFR-18-009).

**Nhắc và leo thang.** `ReminderJob` tạo `task_reminder` và thông báo trước hạn `18.task.reminder.before-hours`; `EscalationJob` gửi cho người quản lý theo nhóm khi quá hạn `18.task.overdue.escalate-hours`; việc quá hạn quá lâu theo cấu hình loại việc chuyển `EXPIRED`.

### 4.17. Lịch, cửa sổ bảo trì, đóng băng (`task.calendar`)

::: dac-ta
**Mục đích.** Giữ lịch ngày làm việc và ngày lễ theo tenant, tính hạn theo ngày làm việc cho phân hệ khác, và quản cửa sổ bảo trì, cửa sổ đóng băng thay đổi.

**Lớp chính.** `WorkingCalendarService`, `WorkingDayCalculator`, `CalendarCache`, `MaintenanceWindowService`, `FreezeStatusService`, `MaintenanceNoticeJob`.

**Đơn vị chạy.** `dh-platform` hồ sơ `api`; `MaintenanceNoticeJob` ở hồ sơ `worker` mỗi giờ.

**FR hiện thực.** FR-18-045, 046; BR-18-033, 034, 035.

**Giao diện vào.** `WorkingCalendarApi`, `FreezeStatusApi`; API-18-113…122; sự kiện `platform.release.published.v1`, `platform.tenant.upgrade-changed.v1`.

**Phụ thuộc ra.** `NotificationApi` (báo trước bảo trì `18.maintenance.notice-hours`), `FourEyesGuard` (cửa sổ đóng băng).

**Dữ liệu.** `work_calendar`, `calendar_holiday`, `maintenance_window`.

**Sự kiện.** EVT-18-15, EVT-18-16.

**Lỗi và xử lý.** ERR-18-049, 050.

**Quan sát.** `dh_ops_calendar_missing_total{tenant}`, `dh_ops_freeze_active{tenant,env}`.
:::

`WorkingDayCalculator` dùng múi giờ `18.calendar.timezone`, cuối tuần `18.calendar.weekend-days`, ngày lễ, nghỉ bù và làm bù của lịch năm; thiếu lịch tenant thì dùng `COMMON`, thiếu cả hai thì chỉ bỏ cuối tuần và trả cờ `calendarMissing` (BR-18-034). Lịch năm được đệm trong bộ nhớ theo (tenant, năm), xóa khi có EVT-18-15. Cửa sổ chồng lấn cùng loại cùng môi trường bị từ chối (ERR-18-050). `FreezeStatusApi` chỉ trả trạng thái; phân hệ chủ quyết định chặn, và khi PH-18 vắng thì phân hệ coi là không đóng băng kèm cảnh báo (BR-18-035). `04.freeze.windows` của PH-04 chưa hợp nhất (mục 13.6).

### 4.18. Sự cố vận hành (`incident`)

::: dac-ta
**Mục đích.** Mở hồ sơ sự cố từ sự kiện hoặc tạo tay, phân mức, gán người, ghi mốc thời gian chỉ thêm, liên kết đối tượng, chuyển PH-09 khi có dữ liệu cá nhân, và đóng có nguyên nhân gốc, bài học.

**Lớp chính.** `IncidentService`, `IncidentEventConsumer`, `IncidentStateMachine`, `TimelineWriter`, `IncidentLinkService`, `PrivacyHandoffService`, `AckEscalationJob`.

**Đơn vị chạy.** `dh-platform` hồ sơ `api`; `IncidentEventConsumer`, `PrivacyHandoffService` (thử lại mỗi 5 phút), `AckEscalationJob` mỗi phút ở hồ sơ `worker`.

**FR hiện thực.** FR-18-047…051; BR-18-036, 037.

**Giao diện vào.** `IncidentApi`; API-18-123…132; EVT-13-04, EVT-13-05, EVT-18-08, EVT-18-19, EVT-09-13, EVT-09-14.

**Phụ thuộc ra.** API nhận sự cố của PH-09 (nguồn `INCIDENT_PH18`), `NotificationApi`, `TaskInboxApi`.

**Dữ liệu.** `incident`, `incident_timeline` (chỉ thêm), `incident_link`.

**Sự kiện.** EVT-18-17, EVT-18-18.

**Lỗi và xử lý.** ERR-18-006, 052, 053, 054.

**Quan sát.** `dh_ops_incident_open{severity}`, `dh_ops_incident_ack_seconds{severity}`, `dh_ops_incident_handoff_pending`.
:::

**Mở từ sự kiện.** `IncidentEventConsumer` ánh xạ sự kiện sang `sourceRef` (ví dụ `EVT-18-08:t68:ph04-runtime:DEPTH`); mỗi `sourceRef` có tối đa một sự cố mở (BR-18-036, chỉ mục duy nhất có điều kiện), sự kiện lặp chỉ thêm mốc thời gian. Mức mặc định theo bảng ánh xạ cấu hình (EVT-13-04 `SEV2`, sao lưu lỗi đối tượng `TPH-0` `SEV1`). `AckEscalationJob` leo thang khi quá `18.incident.sev1-ack-minutes`, `18.incident.sev2-ack-minutes` chưa có người nhận. PH-13 vẫn là nơi giữ luật cảnh báo và lịch trực; PH-18 chỉ giữ hồ sơ.

**Chuyển PH-09.** Sự cố có `hasPersonalData` cần loại dữ liệu, số người ước tính và thời điểm phát hiện (ERR-18-053); `PrivacyHandoffService` ghi outbox lệnh chuyển rồi gọi PH-09, lỗi thì thử lại mỗi 5 phút và sau 1 giờ báo SO (ERR-18-054). Đồng hồ 72 giờ do PH-09 giữ. Đóng sự cố cần nguyên nhân gốc và bài học, mỗi phần ≥ 30 ký tự (ERR-18-052, BR-18-037).

### 4.19. Bộ thu trạng thái sao lưu (`backup.status`)

::: dac-ta
**Mục đích.** Thu trạng thái từng đối tượng sao lưu của D03-09 §8.2, kết quả kiểm tra khôi phục tự động và diễn tập DR về một bảng điều khiển, phát hiện bản sao lưu lỗi hoặc trễ.

**Lớp chính.** `BackupRunIngestService`, `BackupRunController` (nội bộ), `BackupObjectCatalog`, `BackupFreshnessJob`, `RestoreVerificationIngestService`, `DrDrillService`; CronJob `dh-backup-reporter` với các bộ đọc `CnpgBackupReader`, `VeleroBackupReader`, `RcloneLogReader`, `OpenBaoSnapshotReader`, `TenantExportReader`.

**Đơn vị chạy.** `dh-platform` hồ sơ `api` (nhận báo), hồ sơ `worker` (`BackupFreshnessJob` mỗi 5 phút); CronJob `dh-backup-reporter` trong `dh-batch` mỗi 5 phút, ảnh `dh-ops-worker` lệnh `backup-report`.

**FR hiện thực.** FR-18-052, 053, 058; BR-18-048; NFR-18-012.

**Giao diện vào.** API-18-135 (`POST /ops/internal/v1/backup/runs`), API-18-137 (`backup/verifications`), scope `ops:backup-report`; API-18-133, 134, 136, 154, 155 cho màn.

**Phụ thuộc ra.** Kubernetes API chỉ đọc (CR `Backup`, `ScheduledBackup` của CNPG, `Backup` của Velero), nhật ký rclone ở Garage, API trạng thái snapshot của OpenBao; `OutboxWriter`.

**Dữ liệu.** `backup_object`, `backup_run`, `restore_verification` (chỉ thêm), `dr_drill`; dòng nền tảng `COMMON` cho đối tượng cấp cụm, dòng tenant cho xuất logic theo tenant.

**Sự kiện.** EVT-18-19, EVT-18-20.

**Lỗi và xử lý.** ERR-18-055 (màn), ERR-18-122 (một bộ đọc lỗi, các bộ khác vẫn báo).

**Quan sát.** `dh_ops_backup_last_success_timestamp{object,tool}`, `dh_ops_backup_stale{object}`, `dh_ops_backup_report_lag_seconds`, `dh_ops_restore_verification_result{object}`.
:::

**Mô hình đẩy.** `dh-platform` không có quyền đọc tài nguyên Kubernetes ngoài `dh-batch`; thay vào đó `dh-backup-reporter` chạy trong `dh-batch` với service account chỉ có quyền `get`, `list` trên CR sao lưu ở namespace `dh-db` và `velero`, đọc trạng thái từng công cụ, chuẩn hóa thành bản ghi `BackupRunReport` (đối tượng, công cụ, bắt đầu, kết thúc, kết quả, kích thước, nơi lưu, tổng kiểm tra nếu có) rồi gửi API-18-135 bằng mTLS và scope `ops:backup-report`. Bản ghi lũy đẳng theo (`object_code`, `tool_run_id`). Job kiểm tra khôi phục tự động (cụm tạm ở `dh-batch` theo D03-09 §8.2) gửi API-18-137 khi xong. Chọn mô hình đẩy để không mở RBAC chéo namespace cho DU control plane (Q18-22).

**Phát hiện trễ.** `BackupFreshnessJob` so lần thành công cuối của mỗi đối tượng với lịch: đối tượng hằng ngày quá `18.backup.stale-hours`, đối tượng liên tục (WAL) quá 15 phút, hoặc lượt chạy cuối lỗi, thì đánh dấu `STALE` hoặc `FAILED` và phát EVT-18-19 một lần mỗi lần chuyển. Kiểm tra khôi phục quá `18.backup.verification-interval-days` chưa có kết quả cũng tính là lỗi của điều kiện "0 lỗi" 3-2-1-1-0. Diễn tập DR và PITR toàn cụm do PA thực hiện ngoài ứng dụng; `DrDrillService` chỉ ghi nhận biên bản (thời điểm, RPO, RTO đạt được, tệp biên bản có SHA-256).

### 4.20. Khôi phục tenant tám bước (`backup.restore`, `opsworker.restore`)

::: dac-ta
**Mục đích.** Đưa dữ liệu của một tenant về thời điểm quá khứ theo RBK-04 (D03-09 §8.5) mà không chạm dữ liệu tenant khác: TA tạo, PA duyệt, Job chạy tám bước có điểm dừng, quay lui được khi lỗi từ bước 5.

**Lớp chính.** `TenantRestoreService`, `RestoreEstimator`, `RestoreStateMachine`, `RestoreJobLauncher`, `RestoreStepTracker`, `RestoreRollbackService`; trong worker `TenantRestoreCommand`, `Step1Approval` … `Step8VerifyAndReopen`, `TempClusterProvisioner`, `ForeignKeyOrderer`, `TenantCopyExtractor`, `TenantReplacer`, `ObjectStoreRestorer`, `VaultKvRestorer`, `SmokeTestRunner`.

**Đơn vị chạy.** `dh-platform` hồ sơ `api` (yêu cầu, duyệt, theo dõi), hồ sơ `worker` (`RestoreStepTracker`, `JobWatcher`); Job `dh-tenant-restore` trong `dh-batch`.

**FR hiện thực.** FR-18-054, 055; BR-18-038, 039, 047; NFR-18-010, NFR-18-017.

**Giao diện vào.** API-18-138…146.

**Phụ thuộc ra.** Kubernetes API (`K8sJobGateway`), CNPG (CR `Cluster` của cụm tạm), kho sao lưu Barman, PH-20 (`/internal/tenant/v1/tenants/{tenant}:suspend`, `:activate`), Garage, OpenBao (KV phiên bản 2, kho bí mật động CSDL), `HeavyTaskLock`, `FourEyesGuard`, `NotificationApi`.

**Dữ liệu.** `tenant_restore_request`, `tenant_restore_step`; bản trích ở bucket nền tảng `dh-common-restore` (mã hóa, giữ 7 ngày).

**Sự kiện.** EVT-18-21 mỗi lần chuyển bước hoặc trạng thái; EVT-18-22 một lần khi thay dữ liệu xong.

**Lỗi và xử lý.** ERR-18-005, 056, 057, 058; ERR-18-114, 115 ghi vào bước.

**Quan sát.** `dh_ops_restore_step_seconds{step}`, `dh_ops_restore_duration_seconds`, `dh_ops_restore_rows_replaced_total{schema}`, `dh_ops_restore_active`.
:::

**Yêu cầu và duyệt.** `TenantRestoreService.create` kiểm thời điểm đích nằm trong cửa sổ PITR 30 ngày (ERR-18-056), phạm vi `FULL_TENANT` hoặc danh sách schema hợp lệ, không chứa schema kiểm toán của PH-13 (ERR-18-058), và tenant không có tác vụ nặng khác (ERR-18-057); `RestoreEstimator` ước tính thời gian từ kích thước bản xuất logic gần nhất của tenant. Gửi duyệt mở việc `ph18.approve-restore` cho PA. Duyệt chạy `FourEyesGuard` (ERR-18-005; `18.restore.approval-required` không tắt được), kiểm lại điều kiện, giành `HeavyTaskLock`, ghi bước 1 `APPROVAL`, rồi `RestoreJobLauncher` tạo Job; yêu cầu sang `RUNNING`.

**Tám bước của Job.**

| Bước | `step_code` | Việc của `dh-tenant-restore` | Dữ liệu thật bị đổi | Lỗi thì |
|---|---|---|---|---|
| 1 | `APPROVAL` | Do `dh-platform` ghi khi duyệt | Không | Không áp dụng |
| 2 | `BUILD_TEMP_CLUSTER` | Tạo namespace `dh-restore-{tenant}-{mã ngắn}` có NetworkPolicy từ chối mọi kết nối trừ pod của Job và kho sao lưu; tạo CR `Cluster` của CNPG với `bootstrap.recovery` từ kho Barman và `recoveryTarget.targetTime`; chờ sẵn sàng (45 phút đến 3 giờ) | Không | `FAILED`, xóa cụm tạm |
| 3 | `EXTRACT_TENANT` | Trên cụm tạm, vai `restore_extractor` có `BYPASSRLS` (tạo bằng `postInitSQL` của chính cụm tạm, không tồn tại ở cụm thật) chạy `COPY (SELECT … WHERE tenant_id = $1) TO STDOUT (FORMAT binary)` theo thứ tự khóa ngoại; đồng thời trích dữ liệu hiện tại của tenant trên cụm thật để quay lui | Không | `FAILED`, xóa cụm tạm |
| 4 | `SUSPEND_TENANT` | Gọi PH-20 chuyển tenant `SUSPENDED` (cho phép API thiết yếu chỉ đọc); các DU dừng luồng và bộ chuyển outbox của tenant khi nhận `platform.tenant.status-changed.v1` | Trạng thái tenant | PH-20 trả `ACTIVE`, `FAILED` |
| 5 | `REPLACE_DATA` | Mỗi schema một giao dịch, vai `dh_tenant_restorer` (`NOBYPASSRLS`), `SET LOCAL app.tenant_id`, `SET LOCAL app.restore_mode = on`: xóa dòng của tenant theo thứ tự khóa ngoại ngược, `COPY FROM` bản trích theo thứ tự xuôi; ghi số dòng mỗi bảng | Có | Quay lui từ bản trích hiện tại |
| 6 | `RESTORE_OTHER_STORES` | Theo phạm vi: rclone đưa bucket `dh-{tenant}-*` về phiên bản tại thời điểm đích; `kv/dh/{tenant}/` về phiên bản cũ nhờ KV phiên bản 2; realm Keycloak chỉ khi phạm vi gồm PH-12 (theo runbook, bước có thể `SKIPPED`); tính offset tiêu thụ cần đặt lại | Có | Quay lui bước 5, kho khác theo runbook |
| 7 | `AUDIT_RECORD` | Ghi tổng hợp số dòng thay mỗi bảng, thời gian từng bước; `dh-platform` (`RestoreStepTracker`) ghi bản kiểm toán khôi phục; nhật ký kiểm toán không bao giờ bị khôi phục | Không | Thử lại |
| 8 | `VERIFY_AND_REOPEN` | Chạy bộ kiểm tra khói của tenant (D03-10 §5.2), đối chiếu số dòng với bản trích (lệch: ERR-18-115), gọi PH-20 chuyển `ACTIVE`, xóa cụm tạm và namespace | Trạng thái tenant | Lệch số dòng: tenant giữ `SUSPENDED` chờ PA |

: Tám bước của dh-tenant-restore và cách xử lý lỗi

**Phạm vi bảng.** `ForeignKeyOrderer` đọc `pg_constraint` của các schema trong phạm vi và sắp xếp tô pô; vòng khóa ngoại (hiếm) được xử lý bằng ràng buộc `DEFERRABLE` hoặc báo lỗi ở bước 3 trước khi chạm dữ liệu thật. Không bao giờ thay: schema kiểm toán của PH-13, bảng `outbox_event` và `inbox_event` của mọi schema (thay outbox sẽ làm bộ chuyển phát lại hàng loạt sự kiện cũ; thay inbox làm mất khử trùng), và bảng khôi phục của chính PH-18 (`tenant_restore_request`, `tenant_restore_step`). Danh sách loại trừ cần các phân hệ xác nhận (Q18-23).

**Vì sao RLS vẫn bảo vệ ở bước 5.** Vai `dh_tenant_restorer` không có `BYPASSRLS`; mọi câu `DELETE` và `COPY FROM` chạy sau `SET LOCAL app.tenant_id = '{tenant}'`, nên chính sách RLS của từng bảng chặn mọi dòng của tenant khác dù mã của công cụ có lỗi (NFR-18-017). Trigger chặn xóa, chặn sửa lịch sử (`tg_no_delete`, `tg_immutable`) của các phân hệ phải cho phép khi `app.restore_mode = on` và `current_user` là `dh_tenant_restorer`; đây là thay đổi cần ở DDL các phân hệ (mục 13.6). Tài khoản của vai này do kho bí mật động CSDL của OpenBao cấp, sống bằng thời gian tối đa của lần khôi phục, cấp khi duyệt và thu hồi khi xong (SEC-28). Vai này cũng cần quyền DML trên schema của các phân hệ trong phạm vi, khác với `ph18_worker` chỉ có quyền trên `ph18_ops` (Q18-24).

**Máy trạng thái và tiến độ.** Job không ghi sự kiện, không gọi kiểm toán: nó chỉ cập nhật `tenant_restore_step` và nhịp sống 30 giây. `RestoreStepTracker` của `dh-platform` đọc thay đổi mỗi 10 giây, chuyển trạng thái yêu cầu theo bảng §8.1, ghi kiểm toán và outbox EVT-18-21, EVT-18-22. Job có `backoffLimit: 0` để Kubernetes không tự chạy lại một bước đã đổi dữ liệu; `JobWatcher` thấy Job thất bại hoặc mất nhịp sống quá 5 phút thì đánh dấu bước đang chạy `FAILED` và kích hoạt quay lui khi bước ≥ 5. Quay lui tự động dùng bản trích hiện tại ở bước 3, cùng cơ chế giao dịch của bước 5; tự động thất bại thì PA bấm "Quay lui" (API-18-146), yêu cầu thành `ROLLED_BACK`.

### 4.21. Xuất tenant và chuyển sáp nhập (`backup.export`, `backup.merge`, `opsworker.export`)

::: dac-ta
**Mục đích.** Xuất toàn bộ dữ liệu của một tenant thành gói có tổng kiểm tra (bàn giao khi `DECOMMISSIONED`, chuyển ô, bản xuất logic hằng ngày), và chuyển dữ liệu từng phân hệ từ tenant nguồn sang tenant đích khi PH-20 điều phối sáp nhập.

**Lớp chính.** `TenantExportService`, `ExportPurposePolicy`, `MergeTransferService`, `MappingRefResolver`, `Ph20ProgressReporter`; trong worker `TenantExportCommand`, `MergeLoadCommand`, `CopyStreamer`, `ManifestWriter`, `OriginTenantRewriter`.

**Đơn vị chạy.** `dh-platform` hồ sơ `api` (API), hồ sơ `worker` (`Ph20ProgressReporter` mỗi 30 giây); Job `dh-tenant-export` trong `dh-batch`.

**FR hiện thực.** FR-18-056, 057; BR-18-039, 045, 048; NFR-18-011, NFR-18-022.

**Giao diện vào.** `TenantExportApi`, `MergeTransferApi`; API-18-147…153; sự kiện `platform.tenant.merge-started.v1`, `platform.tenant.export-ready.v1`.

**Phụ thuộc ra.** PH-20 `POST /internal/tenant/v1/merge-plans/{id}/participants/{module}:report`, registry tenant; Garage; khóa transit OpenBao ký manifest; `HeavyTaskLock`.

**Dữ liệu.** `tenant_export_job`, `merge_transfer` (dòng thuộc tenant đích).

**Sự kiện.** EVT-18-23, EVT-18-24.

**Lỗi và xử lý.** ERR-18-057, 059, 060, 061; ERR-18-116, 123.

**Quan sát.** `dh_ops_export_bytes_total`, `dh_ops_export_seconds`, `dh_ops_merge_rows_total{module,result}`, `dh_ops_merge_report_failures_total`.
:::

**Xuất.** `ExportPurposePolicy` kiểm trạng thái tenant khớp mục đích (bàn giao chỉ khi `DECOMMISSIONED` hoặc đang ngừng, chuyển ô chỉ khi `SUSPENDED`; sai: ERR-18-059). Job đọc từng bảng bằng vai chỉ đọc `NOBYPASSRLS` với `SET LOCAL app.tenant_id`, `COPY … TO STDOUT (FORMAT binary)` theo luồng thẳng lên Garage (multipart), không qua đĩa tạm; `ManifestWriter` ghi danh sách tệp, số dòng, SHA-256 từng tệp và chữ ký transit (BR-18-048). Liên kết tải có hạn `18.export.link-ttl-hours`, gói giữ `18.export.retention-days`. Ở 200 GB, luồng song song 8 bảng với tốc độ giả định 40 MB/giây mỗi luồng cho thời gian khoảng 1 giờ, trong chỉ tiêu 2 giờ (NFR-18-011, giả định đo ở đợt kiểm thử tải).

**Chuyển sáp nhập.** PH-20 gọi API-18-150 bằng tài khoản máy (client credentials qua `apisix-int`, scope `ops:merge-transfer`) với `mergePlanId`, `module`, `sourceTenant`, `targetTenant`, `mappingRef`, `dryRun`. `MergeTransferService` lũy đẳng theo `mergePlanId:module:mode` (`mode` là `FULL` mặc định hoặc `DELTA` cho lượt bù cuối trước cutover, chỉ trích dòng có `updated_at` từ `since`; thân khác: ERR-18-061), kiểm hai tenant đang trong kế hoạch sáp nhập ở registry PH-20 và không có tác vụ nặng khác ở cả hai (ERR-18-057, ERR-18-060), tạo dòng `merge_transfer` thuộc tenant đích rồi tạo Job `dh-tenant-export merge-load`. Job đọc dòng của tenant nguồn trong các schema của phân hệ (phiên `app.tenant_id` = nguồn), `OriginTenantRewriter` đổi `tenant_id` thành đích, giữ `id` gốc, ghi `origin_tenant_id` = nguồn, áp bảng ánh xạ mã từ `mappingRef` cho khóa nghiệp vụ trùng, rồi ghi bằng phiên `app.tenant_id` = đích (RLS chặn ghi nhầm tenant khác). Chạy thử chỉ đếm và kiểm xung đột khóa. `Ph20ProgressReporter` đọc tiến độ từ `merge_transfer` và báo PH-20 với khóa lũy đẳng `transferId:sequence`, lỗi thì thử lại và đặt `report_status = REPORT_FAILED` (ERR-18-123). Chuyển sáp nhập ghi thẳng schema phân hệ đích, khác nguyên tắc "ghi qua API nhập" của di trú hệ cũ (ADR-183); lý do và câu hỏi ở Q18-29.

### 4.22. Di trú: nguồn, kế hoạch, lần chạy (`migration.source`, `migration.plan`, `migration.run`, `opsworker.migrate`)

::: dac-ta
**Mục đích.** Khai báo nguồn hệ cũ chỉ đọc, lập kế hoạch theo loại đối tượng và thứ tự phụ thuộc, chạy thử không ghi, chạy thật có bốn mắt, lũy đẳng, ghi bản ghi lỗi, đối chiếu số lượng và tổng kiểm tra, đánh dấu thông tin xác thực cần cấp lại.

**Lớp chính.** `LegacySourceService`, `ReadOnlyProbe`, `MigrationPlanService`, `DependencyOrderer`, `MigrationRunService`, `ReconciliationService`, `ErrorRecordService`; trong worker `MigrateCommand`, `MigrationJobFactory`, `LegacyItemReader`, `ObjectConverter` và các hiện thực theo loại, `CredentialStripper`, `ImportApiWriter`, `DryRunWriter`, `ChecksumAccumulator`.

**Đơn vị chạy.** `dh-platform` hồ sơ `api`; Job `dh-migrate` (Spring Batch) trong `dh-batch`.

**FR hiện thực.** FR-18-059…065; BR-18-040…043; NFR-18-013, 014; FR-00-090…093.

**Giao diện vào.** API-18-156…172.

**Phụ thuộc ra.** CSDL hệ cũ qua JDBC (IF-07), OpenBao `kv/dh/{tenant}/migration/{nguồn}`, API nhập của phân hệ đích (scope `ops:migration-import`), `FourEyesGuard`, `HeavyTaskLock`, `FreezeStatusApi`.

**Dữ liệu.** `legacy_source`, `migration_plan`, `migration_plan_item`, `migration_run`, `migration_run_item_result`, `migration_error_record`, `migration_reconciliation` (chỉ thêm), `credential_reissue_marker`; bảng kho lần chạy của Spring Batch (mục 13.5).

**Sự kiện.** EVT-18-25, EVT-18-26.

**Lỗi và xử lý.** ERR-18-005, 051, 057, 062…065, 069, 070; ERR-18-117…120 ghi vào kết quả mục và bản ghi lỗi.

**Quan sát.** `dh_ops_migration_records_total{object_type,result}`, `dh_ops_migration_throughput`, `dh_ops_migration_reconcile_mismatch_total`, `dh_ops_migration_run_seconds`.
:::

**Nguồn chỉ đọc.** Thông tin kết nối chỉ là tham chiếu OpenBao (ERR-18-070); URL JDBC không kèm thông tin đăng nhập (`ck_legacy_source_jdbc`). `ReadOnlyProbe` mở kết nối, đặt giao dịch chỉ đọc và kiểm quyền của tài khoản theo loại CSDL (PostgreSQL `has_table_privilege`, Oracle `USER_TAB_PRIVS`, SQL Server `fn_my_permissions`); có quyền ghi bất kỳ thì từ chối ERR-18-062 (BR-18-040).

**Kế hoạch và thứ tự.** Mỗi mục kế hoạch là một loại đối tượng với bộ chuyển và phân hệ đích. `DependencyOrderer` sắp xếp tô pô bằng thuật toán Kahn trên quan hệ "cần có trước" của bộ chuyển; còn nút chưa xếp thì có vòng hoặc thiếu tiền đề (ERR-18-063).

| Loại đối tượng (hệ cũ) | Bộ chuyển | Phân hệ đích, API nhập | Cần có trước |
|---|---|---|---|
| Danh mục Aita | `AitaCatalogConverter` | PH-07 | Không |
| HTTT, application của Hub | `HubApplicationConverter` | PH-01 (API-01-080…082) | Danh mục đơn vị |
| API, plan, subscription của APIM | `ApimApiConverter`, `ApimPlanConverter`, `ApimSubscriptionConverter` | PH-02, PH-03 | HTTT |
| Topic, publisher, subscriber của Hub | `HubTopicConverter`, `HubSubscriptionConverter` | PH-10 | HTTT |
| Luồng Camel XML của Bus | `CamelXmlRouteConverter` (thành bản nháp YAML) | PH-04 | HTTT, API |
| Giao dịch PayGov | `PayGovTransactionConverter` | PH-19 (FR-19-065…068) | HTTT |

: Bộ chuyển theo loại đối tượng và thứ tự phụ thuộc

**Lần chạy.** Mỗi lần chạy là một Job Spring Batch, mỗi mục kế hoạch là một bước theo thứ tự trên, xử lý theo khối `18.migration.batch-size`: `LegacyItemReader` (`JdbcPagingItemReader` sắp theo khóa hệ cũ, bền khi chạy lại), `ObjectConverter` (hàm thuần, không gọi mạng), `CredentialStripper` (loại trường mật khẩu, khóa, chứng thư theo danh sách của từng bộ chuyển và ghi `credential_reissue_marker`, BR-18-042), rồi `ImportApiWriter` gửi lô tới API nhập của đích với khóa lũy đẳng `legacySystem:objectType:legacyKey` (BR-18-041) và tiêu đề `X-Datahub-Migration: true` để đích không phát sự kiện nghiệp vụ hàng loạt (BR-18-043). Chạy thử thay `ImportApiWriter` bằng `DryRunWriter` gọi API nhập ở chế độ kiểm (`dryRun = true`) và không ghi. Bản ghi chuyển đổi lỗi (ERR-18-118) hoặc bị đích từ chối (ERR-18-119) đi vào `migration_error_record` với ảnh chụp đã che, không dừng bước; đích không nhận lô (`503`, ERR-18-069) thì dừng Job ở trạng thái khởi động lại được.

**Chạy thật.** Đề nghị chạy thật kiểm có lần chạy thử `SUCCEEDED` hoặc `SUCCEEDED_WITH_ERRORS` trong `18.migration.dry-run-valid-days` (ERR-18-064), kế hoạch `READY` (ERR-18-065), không trong cửa sổ đóng băng (ERR-18-051), không có tác vụ nặng (ERR-18-057); sang `PENDING_APPROVAL`, người thứ hai duyệt rồi mới `QUEUED` (`ck_migration_run_real`). Chạy lại sau khi sửa (FR-18-063) tạo lần chạy mới chỉ với bản ghi lỗi của lần trước; lũy đẳng ở đích bảo đảm không bản trùng (NFR-18-014).

**Đối chiếu.** `ChecksumAccumulator` tính cho mỗi loại đối tượng: số bản ghi đọc, chuyển được, ghi được, bị từ chối, bỏ qua, và tổng kiểm tra không phụ thuộc thứ tự bằng tổng theo mô-đun 2^64 của 64 bit đầu SHA-256 trên dạng chuẩn tắc RFC 8785 của trường nghiệp vụ. API nhập của đích trả băm chuẩn tắc của từng bản ghi đã ghi để `ReconciliationService` tính phía đích; lệch thì ERR-18-120 và mục đối chiếu `MISMATCH` cần giải trình trước khi cắt chuyển (BR-18-041). Báo cáo xuất PDF, CSV (API-18-171). Thông lượng ≥ 300 bản ghi mỗi giây phụ thuộc API nhập của đích (NFR-18-013); `dh-migrate` chạy song song tối đa 4 khối khi bộ chuyển khai báo độc lập thứ tự.

### 4.23. Chạy song song, đối soát bóng, cắt chuyển (`migration.parallel`)

::: dac-ta
**Mục đích.** Theo dõi từng nhóm dịch vụ chạy song song hệ cũ và Datahub, đo tỷ lệ khớp phản hồi trên lưu lượng nhân bản, đánh giá danh sách kiểm tra, cắt chuyển một phần hoặc toàn phần có bốn mắt và quay lui trong 15 phút.

**Lớp chính.** `ParallelGroupService`, `BridgeEventListener`, `ShadowSampleIngestService`, `ShadowComparator`, `MatchRateWindow`, `CutoverChecklistEvaluator`, `CutoverService`, `TrafficSwitchClient`, `RollbackWatchdog`.

**Đơn vị chạy.** `dh-platform` hồ sơ `api` (API, nhận mẫu bóng); hồ sơ `worker` (`BridgeEventListener`, `RollbackWatchdog` mỗi 10 giây).

**FR hiện thực.** FR-18-066, 067, 068; BR-18-044; NFR-18-015.

**Giao diện vào.** API-18-173…176; EVT-10-15, EVT-10-16.

**Phụ thuộc ra.** PH-03 (đổi trọng số tuyến, nhân bản lưu lượng), PH-10 (cầu nối Pulsar sang Kafka), `DlqReadApi` (đếm mục mở của luồng trong nhóm), `MigrationRunService` (đối chiếu đã giải trình), `credential_reissue_marker`, `FourEyesGuard`, `FreezeStatusApi`.

**Dữ liệu.** `parallel_run_group`, `shadow_comparison_sample` (phân vùng `sampled_at`, chỉ băm), `cutover_checklist`, `cutover_log` (chỉ thêm).

**Sự kiện.** EVT-18-27.

**Lỗi và xử lý.** ERR-18-005, 051, 066, 067, 068; ERR-18-121 cho mẫu lệch.

**Quan sát.** `dh_ops_shadow_samples_total{group,result}`, `dh_ops_shadow_match_ratio{group}`, `dh_ops_cutover_state{group}`, `dh_ops_rollback_seconds{group}`.
:::

**Lấy mẫu bóng.** Trong giai đoạn `PARALLEL`, hệ cũ phục vụ thật; PH-03 bật `proxy-mirror` của APISIX cho các tuyến của nhóm với tỷ lệ `18.migration.shadow.sample-percent`, chỉ phương thức lũy đẳng (`GET`, và `POST` của luồng có chế độ bóng không gọi đích thật). Một bộ chạm nhỏ ở APISIX tính băm SHA-256 của phản hồi hệ cũ sau khi chuẩn hóa (JSON chuẩn tắc, bỏ các đường dẫn biến động khai báo ở nhóm như thời điểm, mã yêu cầu) và tuyến bóng phía Datahub tính băm tương tự; cả hai gửi về API-18-176 theo mã yêu cầu, scope `ops:shadow-ingest`. Chủ sở hữu bộ chạm và bộ so sánh chưa chốt (Q18-25). PH-18 chỉ lưu băm, mã trạng thái HTTP, độ trễ và kết quả khớp, không lưu nội dung.

**Tỷ lệ khớp.** `ShadowComparator` ghép cặp theo mã yêu cầu trong cửa sổ 5 phút; thiếu một nửa thì tính `UNPAIRED`, không tính vào mẫu số. `MatchRateWindow` tính tỷ lệ trên 1.000 cặp gần nhất (giả định, đủ để sai số dưới 0,5 điểm phần trăm ở mức 99,5%); đạt `18.migration.parallel.match-threshold-percent` liên tục 24 giờ thì nhóm sang `SHADOW_OK`, rơi dưới ngưỡng thì về `PARALLEL` (`ck_parallel_run_group_shadow_ok`).

**Danh sách kiểm tra và cắt chuyển.** `CutoverChecklistEvaluator` đánh giá bốn mục: DLQ của các luồng trong nhóm không còn mục mở; tỷ lệ khớp ≥ ngưỡng; không còn `credential_reissue_marker` mở cho HTTT trong nhóm; mọi đối chiếu `MISMATCH` đã giải trình (BR-18-044). Chưa đạt: ERR-18-067. Cắt chuyển một phần (`PARTIAL_CUTOVER`, trọng số theo phần trăm) hoặc toàn phần (`CUT_OVER`) cần bốn mắt và không trong cửa sổ đóng băng. `CutoverService` ghi `cutover_log`, gọi `TrafficSwitchClient` đổi trọng số tuyến ở PH-03 (đồng bộ, chờ xác nhận áp dụng), báo PH-10 cắt chuyển cầu nối, đặt `rollback_deadline_at = now + 18.migration.rollback-window-minutes` và phát EVT-18-27.

**Quay lui.** Quay lui chỉ cần một người có quyền, vì giảm rủi ro và cần nhanh; quá hạn cửa sổ thì ERR-18-068. `CutoverService.rollback` trả trọng số về hệ cũ, trả cầu nối PH-10, ghi `cutover_log`, nhóm sang `ROLLED_BACK` rồi `PARALLEL`. `RollbackWatchdog` đo từ lúc bấm đến khi PH-03 xác nhận 100% lưu lượng về hệ cũ; quá 5 phút chưa xác nhận thì mở sự cố `SEV1` và nhắc runbook đổi tuyến bằng GitOps, để tổng thời gian vẫn ≤ 15 phút (NFR-18-015).

### 4.24. Báo cáo, nhật ký thao tác, sức khỏe (`report`)

::: dac-ta
**Mục đích.** Lập báo cáo vận hành định kỳ cho PH-16, cho tra nhật ký thao tác của PH-18, và theo dõi sức khỏe từng phần của PH-18 kèm chế độ chỉ đọc.

**Lớp chính.** `OpsReportJob`, `ReportAssembler`, `AuditLogQuery`, `HealthAggregator`, `HealthProbe` (mỗi phần một hiện thực), `DegradedModeGuard`.

**Đơn vị chạy.** `dh-platform` hồ sơ `worker` (`OpsReportJob` 03:00 ngày đầu kỳ, `HealthAggregator` mỗi 15 giây); hồ sơ `api` (tra cứu, `GET /health`).

**FR hiện thực.** FR-18-070, 071, 072; BR-18-007, 050; NFR-18-016, 018, 019.

**Giao diện vào.** `OpsHealthApi`; API-18-177…180, API-18-186, API-18-187.

**Phụ thuộc ra.** API tra kiểm toán của PH-13 (lọc theo `module = ops`), Garage `report/`, `OutboxWriter`.

**Dữ liệu.** `ops_report` (bất biến), bảng tổng hợp theo giờ của DLQ (§4.12).

**Sự kiện.** EVT-18-28, EVT-18-29.

**Lỗi và xử lý.** ERR-18-071, 072.

**Quan sát.** `dh_ops_health{component}`, `dh_ops_read_only`, `dh_ops_report_total{kind,result}`.
:::

**Báo cáo.** `OpsReportJob` lập theo `18.report.schedule` một báo cáo mỗi loại `DLQ`, `BACKUP`, `MIGRATION`, `INCIDENT`, `PARAMETER` và một `SUMMARY`, chỉ số đếm và tỷ lệ, không payload hay dữ liệu cá nhân (BR-18-050); lưu dòng `ops_report` và tệp PDF ở Garage, phát EVT-18-28 cho PH-16.

**Sức khỏe và suy giảm.** `HealthAggregator` gom trạng thái các phần: độ trễ tiêu thụ DLQ, độ trễ outbox, bộ gửi thông báo, bộ điều phối phát lại, Kafka, Garage, Valkey, máy chủ thư, Kubernetes API; mỗi phần `UP`, `DEGRADED`, `DOWN`, phát EVT-18-29 khi đổi. `DegradedModeGuard` đặt chế độ chỉ đọc khi `18.degraded.read-only = true` hoặc tự động khi ghi CSDL lỗi liên tục 60 giây; khi chỉ đọc, mọi API ghi trả ERR-18-071 trừ API-18-187 (`POST /degraded-mode`, `PERM-18-admin`) để PA tắt được chế độ này, API đọc và tiếp nhận DLQ vẫn chạy; danh sách inbox `FAILED` cho UI-18-24 qua API-18-186 (tiếp nhận tự tạm dừng nếu CSDL không ghi được, bản tin chờ ở Kafka). Phân hệ khác không bị chặn vì đọc tham số qua bộ đệm và gửi thông báo, việc qua outbox của chính chúng (NFR-18-018).

### 4.25. Lõi chung (`common`)

::: dac-ta
**Mục đích.** Gom các cơ chế mọi module con đều cần và phải giống nhau: bốn mắt, khóa tác vụ nặng theo tenant, kiểm toán, outbox, inbox, lặp tác vụ nền theo tenant, ánh xạ lỗi RFC 9457.

**Lớp chính.** `FourEyesGuard`, `ApprovalRecord`, `HeavyTaskLock`, `OpsAuditRecorder`, `OutboxWriter`, `InboxGuard`, `TenantFanout`, `TenantRegistryClient`, `ProblemMapper`, `IdempotencyFilter`, `IfMatchFilter`, `Reason`.

**Đơn vị chạy.** Trong tiến trình `dh-platform`, cả hai hồ sơ.

**FR hiện thực.** FR-18-070 (ghi); BR-18-039, 046, 047, 049; FR-00-071.

**Giao diện vào.** Gọi nội bộ từ các module con; không có API riêng.

**Phụ thuộc ra.** Thư viện `dh-audit` của PH-13 (bản ghi kiểm toán qua outbox), registry tenant PH-20 (`tenant:registry-read`), PH-12 (quyền người duyệt).

**Dữ liệu.** `outbox_event`, `inbox_event`; cột người duyệt, thời điểm duyệt của các bảng có bốn mắt; khóa tư vấn PostgreSQL.

**Sự kiện.** Phát mọi EVT-18 thay cho module con, phong bì CloudEvents.

**Lỗi và xử lý.** ERR-18-005, 008, 009, 057; ERR-00-401, ERR-00-403, ERR-00-428; ERR-18-124 cho inbox.

**Quan sát.** `dh_ops_outbox_pending`, `dh_ops_outbox_lag_seconds`, `dh_ops_inbox_duplicates_total{topic}`, `dh_ops_audit_write_failures_total`, `dh_ops_heavy_task_rejected_total{kind}`.
:::

**Bốn mắt.** `FourEyesGuard.approve(subject, approver)` kiểm người duyệt khác người đề nghị (ERR-18-005), có `PERM-18-approve` hoặc quyền duyệt riêng của đối tượng, còn trong hạn duyệt, và ghi `approved_by`, `approved_at` trong cùng giao dịch với chuyển trạng thái; ràng buộc `ck_*_four_eyes` của CSDL chặn lần hai. Đề nghị bốn mắt luôn mở một việc `ph18.approve-*` cho nhóm người duyệt; việc bị đóng khi đề nghị được duyệt, từ chối, rút hoặc hết hạn.

**Khóa tác vụ nặng.** CSDL chưa có ràng buộc "một tác vụ nặng mỗi tenant" vì bốn loại nằm ở bốn bảng. `HeavyTaskLock.acquire(tenant, kind)` chạy trong giao dịch chuyển sang trạng thái chạy: lấy `pg_advisory_xact_lock(hashtextextended('ops-heavy:' || tenant, 0))`, rồi kiểm không có `tenant_restore_request` ở `APPROVED` hoặc `RUNNING`, `tenant_export_job` đang chạy, `migration_run` thật ở `QUEUED` hoặc `RUNNING`, `merge_transfer` ở `QUEUED` hoặc `RUNNING` mà tenant là nguồn hoặc đích (ERR-18-057, BR-18-039). Khóa tư vấn bảo đảm hai yêu cầu đồng thời không cùng lọt qua bước kiểm.

**Kiểm toán.** `OpsAuditRecorder` gọi `dh-audit`, ghi bản ghi kiểm toán vào outbox trong cùng giao dịch nghiệp vụ, nên nghiệp vụ và kiểm toán cùng commit hoặc cùng hủy (NFR-18-019). Thao tác mà FRS yêu cầu "kiểm toán trước khi có hiệu lực" (xem payload, duyệt ★, duyệt khôi phục) dùng chế độ đồng bộ: nếu `dh-audit` báo kho kiểm toán đang từ chối (hàng chờ vượt ngưỡng, PH-13 báo lỗi chuỗi) thì thao tác bị từ chối ERR-18-008 (BR-18-046). Hủy, tạm dừng, quay lui khẩn dùng chế độ trễ, luôn thực hiện được.

**Outbox và inbox.** `OutboxWriter.append(event)` chèn `outbox_event` với `id` là mã sự kiện, topic theo tenant, khóa phân vùng theo cột "Khóa" của FRS bảng 9.3a; CHECK `ck_outbox_event_no_content` chặn sự kiện mang payload DLQ, giá trị tham số hay địa chỉ. Bộ chuyển outbox dùng chung của `dh-platform` (ADR-042) đẩy lên Kafka, bản ghi đã gửi giữ `18.outbox.retention-days`. `InboxGuard.firstTime(eventId, topic)` là `INSERT … ON CONFLICT DO NOTHING` trong giao dịch xử lý; sự kiện xử lý lỗi ba lần (lùi 1, 10, 60 giây) thì được ghi vào DLQ của chính PH-18 với nguồn `PH18` và ERR-18-124, để người vận hành phát lại từ cùng màn.

**Lặp theo tenant.** `TenantFanout.forEachActive(task)` lấy danh sách tenant `ACTIVE` từ registry PH-20 (đệm 10 phút; PH-20 vắng thì dùng bản cuối), chạy từng tenant trong `TenantContext.runAs`, mỗi tenant một giao dịch, lỗi một tenant không dừng tenant khác; tenant `SUSPENDED` chỉ chạy các tác vụ dọn và lưu giữ.

### 4.26. Khung worker `dh-ops-worker` (`opsworker.common`)

::: dac-ta
**Mục đích.** Cho ba công cụ nặng một khung chạy chung trong Job Kubernetes: nhận tham số, đặt ngữ cảnh tenant an toàn, báo tiến độ và nhịp sống, lưu điểm dừng, dừng êm khi bị hủy.

**Lớp chính.** `OpsWorkerApplication`, `WorkerContext`, `WorkerTenantSession`, `ProgressReporter`, `HeartbeatTicker`, `CheckpointStore`, `GracefulShutdownHook`, `WorkerSecretLoader`; phía `dh-platform`: `K8sJobGateway`, `JobSpecFactory`, `JobWatcher`.

**Đơn vị chạy.** Ảnh `dh-ops-worker` (Spring Boot 4 không web, `spring.main.web-application-type=none`), Job trong `dh-batch`; `K8sJobGateway` và `JobWatcher` ở `dh-platform` hồ sơ `worker`.

**FR hiện thực.** FR-18-055, 056, 057, 061, 062 (phần chạy); BR-18-047.

**Giao diện vào.** Tham số dòng lệnh `--command`, `--tenant`, `--request-id` (hoặc `--run-id`, `--transfer-id`); không mở cổng mạng vào.

**Phụ thuộc ra.** `pg-core` (vai `ph18_worker`, và `dh_tenant_restorer` khi khôi phục), OpenBao (Kubernetes auth theo service account riêng mỗi công cụ), Garage, Kubernetes API (chỉ `dh-tenant-restore`, để tạo cụm tạm).

**Dữ liệu.** Bảng trạng thái của từng công cụ (`tenant_restore_step`, `tenant_export_job`, `merge_transfer`, `migration_run`, `migration_run_item_result`).

**Sự kiện.** Không phát trực tiếp; `dh-platform` phát thay sau khi đọc tiến độ.

**Lỗi và xử lý.** ERR-18-114…120 ghi vào bảng trạng thái; mã thoát khác 0 khi lỗi.

**Quan sát.** Chỉ số đẩy qua OTLP tới bộ thu (Job ngắn không chờ Prometheus quét): `dh_ops_worker_runs_total{command,result}`, `dh_ops_worker_seconds{command}`, `dh_ops_worker_heartbeat_timestamp`.
:::

**Tạo Job.** `JobSpecFactory` dựng Job với ảnh ghim theo digest, nhãn `datahub.vn/tenant`, `datahub.vn/command`, `datahub.vn/request`, tên `dh-{command}-{tenant}-{8 ký tự mã}`, `backoffLimit: 0`, `activeDeadlineSeconds` theo loại (khôi phục: `18.restore.max-duration-hours` cộng 2 giờ; xuất: 4 giờ; di trú: 24 giờ), `ttlSecondsAfterFinished: 86400`, priority class `dh-batch`, service account riêng mỗi công cụ, `securityContext` không root, hệ thống tệp gốc chỉ đọc, thư mục tạm `emptyDir`. `K8sJobGateway` dùng service account `dh-platform-ops-jobs` chỉ có quyền `create`, `get`, `list`, `watch`, `delete` trên `batch/jobs` và `get` trên `pods/log` trong `dh-batch`. Tạo Job lũy đẳng theo tên: Job cùng tên đã có thì không tạo lại.

**Ngữ cảnh tenant.** `WorkerTenantSession.inTenant(tenant, work)` mở giao dịch và chạy `SET LOCAL app.tenant_id` trước mọi câu lệnh; không có đường nào chạy SQL trên `pg-core` mà không qua hàm này (luật ArchUnit của ảnh worker). Kết nối dùng tài khoản động OpenBao, thời hạn bằng `activeDeadlineSeconds`.

**Tiến độ, điểm dừng, dừng êm.** `ProgressReporter` cập nhật bảng trạng thái sau mỗi bước hoặc mỗi khối; `HeartbeatTicker` ghi nhịp sống 30 giây; `CheckpointStore` ghi điểm dừng (bước, bảng, khóa cuối) để lần chạy lại tiếp tục được với bước chưa đổi dữ liệu thật và với `dh-migrate` (Spring Batch khởi động lại theo `JobRepository`). Khi `dh-platform` hủy (xóa Job), pod nhận `SIGTERM`, `GracefulShutdownHook` cho 60 giây để kết thúc khối đang chạy, ghi trạng thái `CANCELLED` rồi thoát; khôi phục đang ở bước 5 đến 8 thì không dừng giữa giao dịch mà hoàn tất giao dịch hiện tại rồi quay lui.

## 5. Biểu đồ tuần tự

Chương này vẽ trình tự của các luồng có từ ba thành phần trở lên, có bốn mắt hoặc có tác vụ nền. Mỗi sơ đồ ghi FR hiện thực ở tiêu đề mục và có một đoạn thuyết minh điều người đọc cần thấy. Sơ đồ mức nghiệp vụ của cùng luồng ở D02-04-PH18; ở đây là mức thành phần.

### 5.1. Đổi tham số ★ và lan truyền tới bộ đệm các DU (FR-18-003, 004, 006, 002)

Luồng này đi từ lúc quản trị tỉnh đề nghị đổi một khóa bảo mật tới lúc mọi bản sao của các DU dùng giá trị mới; thành phần tham gia là `ParamWriteService`, `ParamChangeApprovalService`, hộp việc, outbox và `dh-ops-client`.

```{.mermaid caption="Trình tự đổi tham số bảo mật có bốn mắt và lan truyền tới bộ đệm"}
sequenceDiagram
  actor TA as TA đề nghị
  actor SO as SO duyệt
  participant W as ParamWriteService
  participant A as ParamChangeApprovalService
  participant T as TaskService
  participant DB as ph18_ops
  participant K as Kafka ops.param.changed
  participant C as dh-ops-client ở DU khác
  TA->>W: PUT params key kèm If-Match và lý do
  W->>W: ParamValidator kiểm kiểu, miền, trần
  W->>A: Khóa có cờ bảo mật nên tạo đề nghị
  A->>DB: param_change_request PENDING_APPROVAL, outbox EVT-18-02
  A->>T: Mở việc ph18.approve-param
  W-->>TA: 202 đề nghị chờ duyệt
  SO->>A: Duyệt đề nghị
  A->>A: FourEyesGuard và kiểm lại miền, trần
  A->>DB: Phiên bản mới ACTIVE, bản cũ SUPERSEDED, kiểm toán, outbox EVT-18-01
  DB-->>K: Bộ chuyển outbox phát EVT-18-01 không mang giá trị
  K-->>C: ParamChangeSubscriber nhận sự kiện
  C->>C: Vô hiệu mục tenant và ns trong Caffeine
  C->>W: GET params tenant ns kèm If-None-Match
  W-->>C: 200 ảnh chụp mới kèm ETag
```

Hình cho thấy giá trị mới chỉ có hiệu lực sau khi người thứ hai duyệt và chỉ một giao dịch ghi cả phiên bản, kiểm toán và sự kiện. Bên đọc không nhận giá trị qua Kafka mà tự tải lại qua API có `ETag`; nếu sự kiện bị lỡ thì `refreshAfterWrite` vẫn giữ độ cũ ≤ 60 giây.

### 5.2. Tiếp nhận bản tin lỗi từ topic và qua API (FR-18-013, 014, 015, 016)

Luồng này cho thấy hai đường vào của bản tin lỗi, topic chung và API ghi, cùng đi qua `DlqIngestService` để có một bộ kiểm và một cách khử trùng.

```{.mermaid caption="Trình tự tiếp nhận bản tin lỗi từ topic DLQ và qua API ghi"}
sequenceDiagram
  participant R as dh-runtime-t68
  participant K as Kafka t68.ops.dlq.v1
  participant C as DlqTopicConsumer
  participant S as DlqIngestService
  participant G as Garage dh-t68-ops
  participant DB as ph18_ops
  participant P as PH-19 qua API
  R->>K: Bản tin lỗi kèm header ngữ cảnh
  C->>K: poll lô tới 500 bản ghi
  C->>S: ingest từng bản ghi
  S->>S: HeaderNormalizer rồi ContextContractValidator
  S->>S: DlqIdFactory dựng dlqId từ offset
  alt Payload lớn hơn 256 KB hoặc không phải JSON
    S->>G: PUT dlq yyyy mm dlqId 0.bin kèm SHA-256
  end
  S->>DB: inbox, khóa tư vấn dlqKey, chèn NEW hoặc POISON hoặc tăng đếm, outbox
  DB-->>S: Commit
  C->>K: Commit offset của lô
  P->>S: POST ops internal dlq messages
  S->>S: Cùng bộ kiểm, thiếu trường thì ERR-18-024
  S->>DB: Cùng giao dịch như trên
  S-->>P: 201 dlqId hoặc 200 khi trùng
```

Hình cho thấy offset chỉ được commit sau khi chỉ mục đã bền, và cả hai đường vào dùng chung `DlqIngestService`. Khác biệt duy nhất là thiếu ngữ cảnh: trên topic thì lưu `POISON` để không mất bản tin, qua API thì trả `422` để bên gọi sửa.

### 5.3. Xem payload có lý do (FR-18-022)

Luồng này là đường duy nhất trả nội dung bản tin lỗi cho người dùng, nên thứ tự kiểm quyền, kiểm toán và che dữ liệu là quan trọng.

```{.mermaid caption="Trình tự xem nội dung bản tin lỗi có lý do và kiểm toán trước"}
sequenceDiagram
  actor SO as SO
  participant API as PayloadRevealService
  participant AU as OpsAuditRecorder
  participant DB as ph18_ops
  participant G as Garage
  participant V as Valkey
  SO->>API: POST payload reveal kèm lý do
  API->>API: Kiểm PERM-18-dlq-payload và lý do tối thiểu 10 ký tự
  API->>AU: Ghi kiểm toán đồng bộ
  AU->>DB: Bản ghi kiểm toán vào outbox
  alt Kho kiểm toán đang từ chối
    API-->>SO: 503 ERR-18-008, không trả nội dung
  end
  API->>G: Đọc payload và so SHA-256
  API->>API: PayloadMasker giữ trường đã mã hóa, che trường Nhạy cảm
  API->>V: Lưu phiếu xem 15 phút
  API-->>SO: 200 nội dung đã che kèm phiếu
```

Hình cho thấy kiểm toán đi trước việc đọc nội dung, nên không có lần xem nào không để lại dấu vết; trường do nguồn mã hóa không bao giờ được giải mã ở PH-18.

### 5.4. Sửa payload chạm trường Hạn chế và duyệt (FR-18-024)

Luồng này tạo bản sửa payload riêng và chỉ yêu cầu người thứ hai duyệt khi bản sửa chạm trường mức Hạn chế hoặc Nhạy cảm theo PH-09.

```{.mermaid caption="Trình tự sửa payload có kiểm soát và duyệt bốn mắt"}
sequenceDiagram
  actor IE as IE sửa
  actor TA as TA duyệt
  participant R as RevisionService
  participant SV as SchemaValidator
  participant P9 as PH-09 phân loại
  participant DB as ph18_ops
  participant T as TaskService
  IE->>R: POST revisions kèm JSON Patch và lý do
  R->>R: PayloadPatcher áp lên bản gốc
  R->>SV: Kiểm theo schema_ref
  R->>P9: Mức phân loại của các trường bị đổi
  alt Có trường Hạn chế hoặc Nhạy cảm
    R->>DB: dlq_revision PENDING_APPROVAL
    R->>T: Mở việc ph18.approve-revision
    TA->>R: Duyệt bản sửa
    R->>R: FourEyesGuard
  end
  R->>DB: dlq_revision APPROVED, mục POISON sang TRIAGED, outbox EVT-18-07
  R-->>IE: Bản sửa sẵn sàng để phát lại
```

Hình cho thấy bản gốc không bao giờ bị ghi; bản sửa là dòng riêng và chỉ bản `APPROVED` mới được dùng khi phát lại. PH-09 không trả lời được thì nhánh duyệt được chọn (đóng an toàn).

### 5.5. Phát lại loạt có bốn mắt và giới hạn tốc độ (FR-18-028, 029, 030)

Luồng này đi từ lúc tạo lượt phát lại loạt lớn qua bốn mắt, bộ điều phối có giới hạn tốc độ, cổng `KAFKA_TOPIC` của PH-04, tới lúc nhận kết quả lũy đẳng.

```{.mermaid caption="Trình tự phát lại loạt vượt ngưỡng qua ReplayPort có giới hạn tốc độ"}
sequenceDiagram
  actor TO as TO tạo lượt
  actor TA as TA duyệt
  participant J as ReplayJobService
  participant D as ReplayDispatcher
  participant L as Valkey thùng token
  participant DB as ph18_ops
  participant P as KafkaTopicReplayPort
  participant SRC as PH-04 runtime
  participant H as ReplayResultHandler
  TO->>J: Tạo lượt theo bộ lọc
  J->>DB: Chốt danh sách vào replay_item, DRAFT
  TO->>J: Gửi lượt 3.200 mục
  J->>DB: Vượt ngưỡng 500 nên PENDING_APPROVAL, mở việc
  TA->>J: Duyệt
  J->>DB: Kiểm lại mục, APPROVED rồi RUNNING
  loop Mỗi giây
    D->>L: Lấy token theo min tốc độ lượt và trần nguồn
    D->>DB: SELECT FOR UPDATE SKIP LOCKED n mục
    D->>P: dispatch từng mục
    P->>DB: Mục REPLAYING, outbox EVT-18-09 khóa dlqId revision
  end
  SRC->>SRC: Chạy lại luồng, chống trùng theo khóa
  SRC->>H: POST replay-results
  H->>DB: Ghi kết quả một lần, mục RESOLVED hoặc REPLAY_FAILED
  H->>DB: Hết mục thì lượt COMPLETED hoặc PARTIAL, outbox EVT-18-10
```

Hình cho thấy ba lớp an toàn: danh sách được chốt khi tạo và kiểm lại khi duyệt; tốc độ không vượt trần của nguồn nhờ thùng token; kết quả của một khóa lũy đẳng chỉ ghi một lần dù nguồn báo nhiều lần.

### 5.6. Phát lại mục DLQ tầng sự kiện của PH-10 (FR-18-017, 027)

Luồng này áp cho mục DLQ tầng sự kiện do PH-10 giữ: PH-18 chỉ có siêu dữ liệu và đề nghị phát lại qua API của PH-10.

```{.mermaid caption="Trình tự liên thông và phát lại DLQ tầng sự kiện qua PH-10"}
sequenceDiagram
  participant E as PH-10
  participant L as EventDlqListener
  participant DB as ph18_ops
  actor TO as TO
  participant Q as DlqQueryService
  participant P as EventLayerReplayPort
  E->>L: EVT-10-11 mục DLQ sự kiện mới
  L->>DB: dlq_message FEDERATED chỉ siêu dữ liệu
  TO->>Q: Mở chi tiết mục
  Q->>E: API-10-061 lấy phần chi tiết, không lưu
  Q-->>TO: Chi tiết hợp nhất
  TO->>P: Phát lại
  P->>E: API-10-063 đề nghị phát lại bằng event replay
  E-->>P: 202 đã nhận, PH-10 tự duyệt phía sự kiện
  E->>L: EVT-10-12 kết quả phát lại
  L->>DB: Mục RESOLVED hoặc REPLAY_FAILED
```

Hình cho thấy PH-18 không giữ bản sao nội dung của DLQ sự kiện và không thay PH-10 duyệt phát lại sự kiện (BR-18-016).

### 5.7. Gửi thông báo bất đồng bộ, giờ yên lặng và thư trả lại (FR-18-036, 037, 038, 040)

Luồng này đi từ lúc một phân hệ gọi `NotificationApi` tới lúc thư được máy chủ thư nhận, kèm nhánh giờ yên lặng và nhánh thư trả lại.

```{.mermaid caption="Trình tự gửi thông báo qua outbox, giờ yên lặng và xử lý thư trả lại"}
sequenceDiagram
  participant PH as PH-01 qua dh-ops-client
  participant N as NotificationService
  participant DB as ph18_ops
  participant W as DeliveryWorker
  participant R as RecipientResolver
  participant M as Máy chủ thư
  participant B as BounceHandler
  PH->>N: POST notifications kèm Idempotency-Key
  N->>N: Kiểm mẫu ACTIVE và biến không chứa dữ liệu cấm
  N->>DB: notification_message QUEUED
  N-->>PH: 202 messageId
  W->>DB: Lấy lô QUEUED bằng SKIP LOCKED
  W->>R: Phân giải recipientRef
  R-->>W: Người nhận và kênh, không trả cho bên gọi
  W->>W: Lọc danh sách chặn, áp tùy chọn và giờ yên lặng
  alt Đang giờ yên lặng và không bắt buộc
    W->>DB: Hoãn tới hết giờ yên lặng, tối đa 12 giờ
  else Gửi được
    W->>M: SMTP STARTTLS kèm Message-ID
    M-->>W: 250 đã nhận
    W->>DB: notification_delivery SENT
  end
  M->>B: DSN thư trả lại cứng qua API-18-106
  B->>DB: BOUNCED, thêm suppression_entry, outbox EVT-18-12
```

Hình cho thấy phân hệ gọi không bao giờ thấy địa chỉ người nhận, và thư trả lại cứng làm địa chỉ bị chặn cho mọi lần gửi sau, kể cả từ phân hệ khác.

### 5.8. Tạo, xử lý và đóng việc (FR-18-042, 043, 044)

Luồng này cho thấy phân chia vai trò giữa phân hệ nguồn (chủ nghiệp vụ, tạo và đóng việc) và PH-18 (giữ và hiển thị hộp việc).

```{.mermaid caption="Trình tự phân hệ tạo việc, người dùng xử lý và phân hệ đóng việc"}
sequenceDiagram
  participant PH as PH-02
  participant T as TaskService
  participant DB as ph18_ops
  participant C as dh-console
  actor U as Người duyệt
  participant Q as MyTasksQuery
  PH->>T: POST task-types khi khởi động
  PH->>T: PUT tasks sourceRef loại ph02.approve-version
  T->>DB: INSERT ON CONFLICT DO UPDATE, outbox EVT-18-14
  C->>Q: GET me tasks summary
  Q-->>C: Số việc mở, quá hạn
  U->>C: Mở việc, đi tới màn PH-02 theo link
  U->>PH: Duyệt phiên bản ở PH-02
  PH->>T: POST tasks sourceRef close DONE
  T->>DB: Việc DONE, outbox EVT-18-14
```

Hình cho thấy PH-18 chỉ giữ hộp việc: quyết định nghiệp vụ nằm ở phân hệ nguồn, và phân hệ nguồn là bên đóng việc (BR-18-032).

### 5.9. Mở sự cố từ sự kiện và chuyển PH-09 (FR-18-047, 050)

Luồng này mở hồ sơ sự cố từ cảnh báo của PH-13 rồi chuyển sang PH-09 khi cán bộ ATTT xác định có dữ liệu cá nhân liên quan.

```{.mermaid caption="Trình tự mở sự cố từ sự kiện và chuyển sự cố có dữ liệu cá nhân sang PH-09"}
sequenceDiagram
  participant M as PH-13
  participant IC as IncidentEventConsumer
  participant I as IncidentService
  participant DB as ph18_ops
  actor SO as SO
  participant H as PrivacyHandoffService
  participant P9 as PH-09
  M->>IC: EVT-13-04 cảnh báo nghiêm trọng
  IC->>I: Mở theo sourceRef
  I->>DB: Có sự cố mở cùng sourceRef thì chỉ thêm mốc, không thì tạo OPEN
  I->>DB: Outbox EVT-18-17
  SO->>I: Đánh dấu có dữ liệu cá nhân kèm loại, số người, thời điểm
  I->>H: Chuyển PH-09
  H->>DB: Outbox lệnh chuyển
  H->>P9: Nhận sự cố nguồn INCIDENT_PH18
  alt PH-09 không phản hồi
    H->>H: Thử lại mỗi 5 phút, sau 1 giờ báo SO
  end
  P9-->>H: Đã nhận, PH-09 giữ đồng hồ 72 giờ
```

Hình cho thấy mỗi `sourceRef` chỉ có một hồ sơ mở nên cảnh báo lặp không sinh hồ sơ trùng, và đồng hồ 72 giờ không do PH-18 giữ.

### 5.10. Thu trạng thái sao lưu và phát hiện lỗi (FR-18-052, 053)

Luồng này cho thấy bộ thu trạng thái chạy ở `dh-batch` đẩy kết quả sao lưu về PH-18 và tác vụ kiểm độ tươi phát hiện bản sao lưu trễ hoặc lỗi.

```{.mermaid caption="Trình tự bộ thu trạng thái sao lưu đẩy về PH-18 và phát hiện bản sao lưu trễ"}
sequenceDiagram
  participant CJ as CronJob dh-backup-reporter
  participant K8 as Kubernetes API
  participant OB as OpenBao
  participant B as BackupRunIngestService
  participant DB as ph18_ops
  participant F as BackupFreshnessJob
  participant M as PH-13
  CJ->>K8: Đọc CR Backup của CNPG và Velero
  CJ->>OB: Đọc trạng thái snapshot Raft
  CJ->>CJ: Chuẩn hóa thành BackupRunReport
  CJ->>B: POST backup runs với scope ops backup-report
  B->>DB: backup_run lũy đẳng theo object và tool run
  F->>DB: So lần thành công cuối với lịch mỗi 5 phút
  alt Quá 18.backup.stale-hours hoặc lượt cuối lỗi
    F->>DB: Đối tượng STALE hoặc FAILED, outbox EVT-18-19
    DB-->>M: EVT-18-19 để PH-13 cảnh báo
  end
```

Hình cho thấy `dh-platform` không cần quyền đọc tài nguyên của namespace khác: bộ thu chạy ở `dh-batch` với quyền chỉ đọc hẹp và đẩy kết quả về.

### 5.11. Khôi phục tenant tám bước (FR-18-055)

Luồng này hiện thực tám bước RBK-04 sau khi PA duyệt, với Job `dh-tenant-restore`, cụm tạm CNPG, PH-20 và cụm `pg-core` thật.

```{.mermaid caption="Trình tự khôi phục một tenant tám bước với cụm tạm cô lập"}
sequenceDiagram
  actor PA as PA duyệt
  participant S as TenantRestoreService
  participant JG as K8sJobGateway
  participant J as Job dh-tenant-restore
  participant TC as Cụm tạm CNPG
  participant T as PH-20
  participant DB as pg-core cụm thật
  participant TR as RestoreStepTracker
  PA->>S: Duyệt yêu cầu
  S->>S: FourEyesGuard và HeavyTaskLock
  S->>JG: Tạo Job trong dh-batch
  J->>TC: Bước 2 dựng cụm tạm bằng PITR, NetworkPolicy chặn
  J->>TC: Bước 3 COPY dòng của tenant bằng vai BYPASSRLS chỉ ở cụm tạm
  J->>DB: Bước 3 trích dữ liệu hiện tại để quay lui
  J->>T: Bước 4 chuyển tenant SUSPENDED
  J->>DB: Bước 5 mỗi schema một giao dịch với SET LOCAL app.tenant_id
  J->>J: Bước 6 Garage, OpenBao KV theo phạm vi
  J->>DB: Bước 7 ghi tổng hợp số dòng
  J->>J: Bước 8 kiểm tra khói, đối chiếu số dòng
  J->>T: Chuyển tenant ACTIVE
  J->>TC: Xóa cụm tạm
  TR->>DB: Đọc bước, ghi kiểm toán, outbox EVT-18-21 và EVT-18-22
```

Hình cho thấy dữ liệu thật chỉ bị đổi ở bước 5 và 6, khi tenant đã tạm ngừng; vai có `BYPASSRLS` chỉ tồn tại trên cụm tạm, còn trên cụm thật RLS luôn áp. Job không phát sự kiện, `RestoreStepTracker` của `dh-platform` phát thay.

### 5.12. Chuyển dữ liệu một phân hệ khi sáp nhập tenant (FR-18-057)

Luồng này theo hợp đồng với PH-20: PH-20 gọi chạy thử rồi chạy thật cho từng phân hệ, PH-18 chạy Job và báo tiến độ về.

```{.mermaid caption="Trình tự PH-20 yêu cầu PH-18 chuyển dữ liệu một phân hệ khi sáp nhập"}
sequenceDiagram
  participant T as PH-20 điều phối
  participant M as MergeTransferService
  participant JG as K8sJobGateway
  participant J as Job dh-tenant-export merge-load
  participant DB as pg-core
  participant R as Ph20ProgressReporter
  T->>M: POST merge-transfers mergePlanId module dryRun true
  M->>M: Lũy đẳng mergePlanId module, HeavyTaskLock hai tenant
  M->>JG: Tạo Job chạy thử
  J->>DB: Đọc tenant nguồn, đếm, kiểm xung đột khóa
  R->>T: participants module report kết quả chạy thử
  T->>M: POST merge-transfers dryRun false
  M->>JG: Tạo Job nạp
  J->>DB: Đọc phiên nguồn, ghi phiên đích, giữ id gốc, origin_tenant_id
  R->>T: Báo tiến độ và kết quả, outbox EVT-18-24
```

Hình cho thấy PH-20 giữ quyết định ở mọi bước; PH-18 chỉ thực hiện chuyển cho từng phân hệ và báo lại, mỗi phiên đọc và ghi chỉ thấy đúng một tenant.

### 5.13. Chạy thật di trú có bốn mắt và đối chiếu (FR-18-061, 062, 064, 065)

Luồng này đi từ đề nghị chạy thật, qua duyệt bốn mắt, tới Job `dh-migrate` đọc hệ cũ theo khối và ghi qua API nhập của phân hệ đích.

```{.mermaid caption="Trình tự chạy thật di trú qua API nhập của phân hệ đích"}
sequenceDiagram
  actor TA as TA đề nghị
  actor PA as PA duyệt
  participant R as MigrationRunService
  participant JG as K8sJobGateway
  participant J as Job dh-migrate
  participant L as CSDL hệ cũ
  participant D as API nhập PH-07
  participant DB as ph18_ops
  TA->>R: Đề nghị chạy thật
  R->>R: Kiểm chạy thử gần đây, đóng băng, tác vụ nặng
  PA->>R: Duyệt
  R->>JG: Tạo Job, lần chạy QUEUED
  loop Mỗi khối 500 bản ghi theo thứ tự phụ thuộc
    J->>L: Đọc trang JDBC chỉ đọc
    J->>J: ObjectConverter và CredentialStripper
    J->>D: POST lô nhập kèm khóa lũy đẳng và cờ migration
    D-->>J: Kết quả từng bản ghi kèm băm chuẩn tắc
    J->>DB: Kết quả mục, bản ghi lỗi, dấu cấp lại
  end
  J->>DB: Đối chiếu số lượng và tổng kiểm tra
  R->>DB: Outbox EVT-18-25 và EVT-18-26
```

Hình cho thấy `dh-migrate` không ghi thẳng schema của phân hệ đích; mọi bản ghi đi qua kiểm tra nghiệp vụ của đích, và tổng kiểm tra phía đích lấy từ băm do chính đích trả.

### 5.14. Đối soát bóng từ lưu lượng nhân bản (FR-18-067)

Luồng này cho thấy cách lấy mẫu so sánh phản hồi của hệ cũ và Datahub khi APISIX nhân bản lưu lượng trong giai đoạn chạy song song.

```{.mermaid caption="Trình tự lấy mẫu bóng và tính tỷ lệ khớp của nhóm dịch vụ"}
sequenceDiagram
  participant U as HTTT gọi
  participant AX as APISIX
  participant OLD as Hệ cũ
  participant NEW as Datahub tuyến bóng
  participant S as ShadowSampleIngestService
  participant C as ShadowComparator
  participant DB as ph18_ops
  U->>AX: Yêu cầu thật
  AX->>OLD: Chuyển tới hệ cũ
  OLD-->>AX: Phản hồi thật
  AX-->>U: Trả phản hồi của hệ cũ
  AX->>S: Băm phản hồi hệ cũ theo mã yêu cầu
  AX->>NEW: Nhân bản 5 phần trăm yêu cầu
  NEW->>S: Băm phản hồi Datahub theo mã yêu cầu
  S->>C: Ghép cặp trong cửa sổ 5 phút
  C->>DB: shadow_comparison_sample chỉ băm và kết quả
  C->>DB: Cập nhật tỷ lệ khớp, đạt ngưỡng 24 giờ thì SHADOW_OK
```

Hình cho thấy người dùng luôn nhận phản hồi của hệ cũ trong giai đoạn song song; Datahub chỉ chạy trên bản nhân bản và PH-18 chỉ thấy băm.

### 5.15. Cắt chuyển và quay lui (FR-18-068)

Luồng này gồm cắt chuyển toàn phần một nhóm dịch vụ có bốn mắt và quay lui trong cửa sổ, kèm đường giám sát thời gian quay lui.

```{.mermaid caption="Trình tự cắt chuyển nhóm dịch vụ có bốn mắt và quay lui trong cửa sổ"}
sequenceDiagram
  actor TA as TA đề nghị
  actor AP as TA khác duyệt
  participant CS as CutoverService
  participant CL as CutoverChecklistEvaluator
  participant G as PH-03 APISIX
  participant E as PH-10 cầu nối
  participant W as RollbackWatchdog
  TA->>CL: Đánh giá danh sách kiểm tra
  CL-->>TA: Bốn mục đạt
  TA->>CS: Đề nghị CUT_OVER
  AP->>CS: Duyệt
  CS->>G: Đổi trọng số tuyến sang Datahub, chờ xác nhận
  CS->>E: Cắt chuyển cầu nối
  CS->>CS: CUT_OVER, hạn quay lui 15 phút, outbox EVT-18-27
  TA->>CS: Quay lui trong cửa sổ
  CS->>G: Trả trọng số về hệ cũ
  CS->>E: Trả cầu nối
  W->>G: Theo dõi xác nhận 100 phần trăm về hệ cũ
  alt Quá 5 phút chưa xác nhận
    W->>W: Mở sự cố SEV1, nhắc runbook GitOps
  end
```

Hình cho thấy cắt chuyển cần hai người còn quay lui chỉ cần một, và quay lui có một đường giám sát riêng để giữ chỉ tiêu 15 phút ngay cả khi PH-03 phản hồi chậm.

## 6. Đa tenant trong mã nguồn

Mọi bảng của `ph18_ops` có `tenant_id` và RLS bắt buộc (`ENABLE` và `FORCE ROW LEVEL SECURITY`) theo biến phiên `app.tenant_id`; thiếu biến thì truy vấn lỗi chứ không trả rỗng (D03-03-PH18 §1.2, SEC-81, BR-18-047). Bộ lọc Spring Security đọc tenant từ token người dùng hoặc từ danh tính SPIFFE của DU gọi, đặt `TenantContext`; `TenantSession` chạy `SET LOCAL app.tenant_id` ở đầu mỗi giao dịch (D03-10 §3). Mã nghiệp vụ không tự thêm điều kiện `tenant_id`. Sáu điểm riêng của PH-18:

1. **Dòng `COMMON`.** Lược đồ khóa, giá trị nền tảng, nguồn DLQ chung, sổ tay lỗi, mẫu và quy tắc thông báo mặc định, loại việc, lịch `COMMON` mang `tenant_id = COMMON`; mọi tenant đọc được, chỉ phiên `COMMON` của PA ghi được (`PlatformModeGuard` kiểm quyền PA và lý do, SEC-85). Sự cố, sao lưu cấp cụm, diễn tập DR, báo cáo nền tảng là dòng nền tảng chỉ phiên `COMMON` thấy.
2. **Nội bộ máy với máy.** API `/ops/internal/v1/{tenant}/…` có tenant trong đường dẫn; `TenantPathGuard` từ chối ERR-00-403 khi tenant đường dẫn khác tenant của danh tính gọi, trừ danh tính nền tảng được cấp scope liên tenant (PH-20 khi khởi tạo, `dh-backup-reporter` cho dòng `COMMON`).
3. **Kafka.** Topic có tiền tố tenant; bộ tiêu thụ lấy tenant từ tiền tố topic và đối chiếu header `dh-tenant` (lệch: `POISON`, §4.6) hoặc trường `tenant` của phong bì; CHECK ở `outbox_event` bảo đảm topic khớp `tenant_id` của dòng.
4. **Kho ngoài.** Garage dùng bucket riêng mỗi tenant `dh-{tenant}-ops` (`ck_dlq_payload_ref_bucket`); khóa Valkey bắt đầu `ops:{tenant}:` hoặc `ops:replay:{jobId}` với `jobId` thuộc tenant; tham chiếu OpenBao nằm dưới `kv/dh/{tenant}/` (SEC-82).
5. **Tác vụ nền.** Mọi tác vụ định kỳ chạy qua `TenantFanout` (§4.25), mỗi tenant một giao dịch có `SET LOCAL`; không tác vụ nào chạy truy vấn liên tenant trên bảng nghiệp vụ.
6. **Worker.** Ba công cụ nặng chỉ chạy SQL qua `WorkerTenantSession`; chuyển sáp nhập dùng hai phiên tách biệt (đọc nguồn, ghi đích); khôi phục dùng vai `NOBYPASSRLS` trên cụm thật, chỉ cụm tạm có vai `BYPASSRLS` (§4.20).

Kiểm thử cô lập chạy trên PostgreSQL có RLS trong CI (SEC-87, NFR-18-017): với hai tenant `T91`, `T92` dựng sẵn dữ liệu ở mọi bảng, mọi API đọc của tenant này phải trả 0 dòng của tenant kia; khôi phục và chuyển sáp nhập trên `T92` không đổi một dòng nào của `T91` (so băm từng bảng trước và sau). Bộ kiểm `ph18/test/ph18_isolation_test.sql` của D03-03-PH18 chạy ở cùng cổng.

## 7. Bảo mật

Kiểm tra quyền luôn ở máy chủ, độc lập với giao diện: APISIX xác minh JWT và gọi OPA (SEC-26); `dh-platform` kiểm lại `PERM-18-*` ở từng `Controller` bằng `@PreAuthorize`, rồi service kiểm tách nhiệm vụ (bốn mắt) và phạm vi tenant. Tập này không tạo biện pháp mới mà hiện thực các biện pháp đã có của D03-07; bảng dưới ghi biện pháp và chỗ hiện thực.

| Biện pháp D03-07 | Hiện thực ở PH-18 | Mục |
|---|---|---|
| SEC-15 mTLS trong cụm, ủy quyền dịch vụ | `/ops/internal/v1` chỉ nhận mTLS SPIFFE; scope máy cấp khi triển khai: `ops:param-read`, `ops:param-register`, `ops:param-write`, `ops:dlq-write`, `ops:dlq-read`, `ops:replay-callback`, `ops:notify`, `ops:task`, `ops:calendar-read`, `ops:incident-write`, `ops:migration-import`, `ops:backup-report`, `ops:merge-transfer`, `ops:shadow-ingest`; không cấp cho người | 3.3 |
| SEC-16 kiểm soát egress | Danh sách egress theo tenant, kiểm FQDN, cấm IP và dải nội bộ; `HttpReplayPort` chỉ gọi tên dịch vụ trong cụm | 4.5, 4.11 |
| SEC-24 xác thực máy với máy | Tài khoản dịch vụ `svc-ops` cho Kafka; Kubernetes auth với OpenBao theo service account riêng của `dh-platform`, từng công cụ worker, `dh-backup-reporter` | 4.26 |
| SEC-26 ủy quyền OPA | Quyền `PERM-18-read`, `dlq`, `dlq-payload`, `approve`, `config`, `template`, `incident`, `backup`, `calendar`, `migration`, `admin` | 7 |
| SEC-28 đặc quyền, truy cập khẩn | Vai `dh_tenant_restorer` cấp động khi duyệt khôi phục, thu hồi khi xong; chế độ nền tảng có lý do | 4.20, 6 |
| SEC-31 mã hóa trường Nhạy cảm | Payload DLQ đã được nguồn mã hóa trường nhạy cảm bằng transit `dh-{tenant}-pii`; PH-18 không giải mã | 4.9 |
| SEC-32 che dữ liệu | `PayloadMasker`, địa chỉ người nhận chỉ lưu dạng che và băm, log không có payload | 4.9, 4.14, 10 |
| SEC-33 quản lý bí mật | Không cột nào giữ bí mật; mọi thông tin SMTP, SMS, kết nối hệ cũ là tham chiếu `kv/dh/{tenant}/...` hoặc `kv/dh/common/...` (BR-18-048, ERR-18-070) | 4.14, 4.22 |
| SEC-60 nhật ký kiểm toán ứng dụng | `OpsAuditRecorder` qua `dh-audit`, cùng giao dịch nghiệp vụ, chế độ đồng bộ cho thao tác nhạy cảm | 4.25 |
| SEC-70, SEC-71 sao lưu, khôi phục | Bảng điều khiển sao lưu, kiểm tra khôi phục, RBK-04 | 4.19, 4.20 |
| SEC-74 báo cáo sự cố DLCN | Chuyển PH-09 với `INCIDENT_PH18` | 4.18 |
| SEC-80, SEC-81 tenant từ token, RLS | Chương 6 | 6 |
| SEC-82 cách ly kho | Bucket, khóa Valkey, đường OpenBao theo tenant | 6 |
| SEC-85 truy cập liên tenant có kiểm soát | Phiên `COMMON` của PA, PO có lý do và kiểm toán | 6 |
| SEC-87 kiểm thử rò rỉ chéo tenant | Bộ kiểm cô lập trong CI | 6, 12 |

: Biện pháp bảo mật D03-07 và chỗ hiện thực ở PH-18

Năm điểm cần lưu ý khi viết mã. (1) Xem payload, xem khác biệt bản sửa và tải bản ghi lỗi di trú là ba đường duy nhất trả nội dung nghiệp vụ; cả ba đi qua kiểm toán đồng bộ và `PayloadMasker`. (2) `ph18_readonly` không có quyền trên cột payload, header ngữ cảnh, biến mẫu, người nhận, ảnh chụp bản ghi lỗi (D03-03-PH18 §1.1), nên báo cáo và PH-16 không đọc được nội dung. (3) Header `authorization`, `cookie` và tiêu đề khóa API bị loại trước khi lưu mục DLQ. (4) URL `HTTP_PORT` và URL JDBC được kiểm lúc khai báo để chặn SSRF: không IP literal, không giao thức khác `https` hoặc `jdbc`, máy chủ thuộc danh sách cho phép. (5) Job worker chạy không root, hệ thống tệp chỉ đọc, NetworkPolicy chỉ cho phép tới `pg-core`, OpenBao, Garage, Kubernetes API (khôi phục) và CSDL hệ cũ đã khai báo (di trú).

## 8. Máy trạng thái, xử lý lỗi, thử lại và tính nhất quán

Chương này gom các máy trạng thái, nơi kiểm chuyển trạng thái, cơ chế outbox, inbox, lũy đẳng, đồng thời, thời gian chờ, thử lại và ánh xạ lỗi. Mọi chuyển trạng thái được kiểm hai lớp: service kiểm theo bảng dưới và trả ERR-18-006 khi không hợp lệ; trigger `tg_*_fsm_status` của CSDL chặn lần hai (SQLSTATE 55000).

### 8.1. Bảng chuyển trạng thái

Bảng ghi máy trạng thái, các chuyển hợp lệ và lớp kiểm ở máy chủ.

| Đối tượng | Chuyển hợp lệ | Kiểm ở |
|---|---|---|
| Mục DLQ | `NEW`→`TRIAGED`, `NEW`/`TRIAGED`/`REPLAY_FAILED`→`REPLAY_PENDING`→`REPLAYING`→`RESOLVED`/`REPLAY_FAILED`; `NEW`/`TRIAGED`/`REPLAY_FAILED`/`POISON`→`DISCARDED`; `DISCARDED`→`TRIAGED` (trong hạn); `POISON`→`TRIAGED` (bản sửa duyệt); `RESOLVED`/`DISCARDED`→`EXPIRED` | `DlqStateMachine` |
| Lượt phát lại | `DRAFT`→`PENDING_APPROVAL`/`APPROVED`; `PENDING_APPROVAL`→`APPROVED`/`REJECTED`; `APPROVED`→`RUNNING`; `RUNNING`⇄`PAUSED`; `RUNNING`→`COMPLETED`/`PARTIAL`/`FAILED`; `DRAFT`/`PENDING_APPROVAL`/`APPROVED`/`RUNNING`/`PAUSED`→`CANCELLED` | `ReplayJobService` |
| Giá trị tham số | `PENDING_APPROVAL`→`ACTIVE`/`REJECTED`; `ACTIVE`→`SUPERSEDED` | `ParamWriteService` |
| Mẫu thông báo | `DRAFT`→`IN_REVIEW`→`ACTIVE`→`RETIRED`; `IN_REVIEW`→`DRAFT` (từ chối) | `TemplateVersionLifecycle` |
| Thông báo gửi | `QUEUED`→`SENT`→`DELIVERED`/`BOUNCED`; `QUEUED`→`FAILED`/`SUPPRESSED` | `DeliveryWorker`, `BounceHandler` |
| Việc | `OPEN`→`IN_PROGRESS`→`DONE`/`CANCELLED`; `OPEN`/`IN_PROGRESS`→`EXPIRED` | `TaskService` |
| Sự cố | `OPEN`→`INVESTIGATING`→`MITIGATED`→`RESOLVED`→`CLOSED`; `RESOLVED`→`INVESTIGATING` (mở lại) | `IncidentStateMachine` |
| Yêu cầu khôi phục | `DRAFT`→`PENDING_APPROVAL`→`APPROVED`→`RUNNING`→`SUCCEEDED`/`FAILED`/`ROLLED_BACK`; `PENDING_APPROVAL`→`REJECTED`; `DRAFT`/`PENDING_APPROVAL`/`APPROVED`→`CANCELLED` | `RestoreStateMachine` |
| Lần chạy di trú | `DRY_RUN`: `QUEUED`→`RUNNING`→`SUCCEEDED`/`SUCCEEDED_WITH_ERRORS`/`FAILED`/`CANCELLED`; `REAL`: `PENDING_APPROVAL`→`QUEUED`→ như trên | `MigrationRunService` |
| Nhóm chạy song song | `PARALLEL`⇄`SHADOW_OK`→`PARTIAL_CUTOVER`→`CUT_OVER`; `PARTIAL_CUTOVER`/`CUT_OVER`→`ROLLED_BACK`→`PARALLEL` | `CutoverService` |
| Chuyển sáp nhập | `QUEUED`→`RUNNING`→`SUCCEEDED`/`SUCCEEDED_WITH_ERRORS`/`FAILED`; `QUEUED`/`RUNNING`→`CANCELLED` | `MergeTransferService` |

: Máy trạng thái của PH-18 và lớp kiểm ở máy chủ

Bốn máy trạng thái có rủi ro cao nhất được vẽ dưới đây.

```{.mermaid caption="Máy trạng thái của mục DLQ"}
stateDiagram-v2
  [*] --> NEW
  [*] --> POISON
  NEW --> TRIAGED
  NEW --> REPLAY_PENDING
  TRIAGED --> REPLAY_PENDING
  REPLAY_PENDING --> REPLAYING
  REPLAYING --> RESOLVED
  REPLAYING --> REPLAY_FAILED
  REPLAY_FAILED --> REPLAY_PENDING
  NEW --> DISCARDED
  TRIAGED --> DISCARDED
  REPLAY_FAILED --> DISCARDED
  POISON --> DISCARDED
  POISON --> TRIAGED : bản sửa được duyệt
  DISCARDED --> TRIAGED : mở lại trong hạn
  RESOLVED --> EXPIRED
  DISCARDED --> EXPIRED
  EXPIRED --> [*]
```

Hình cho thấy mục `POISON` không có đường tới `REPLAY_PENDING`; muốn phát lại phải qua bản sửa được duyệt. `EXPIRED` là trạng thái cuối, chỉ còn siêu dữ liệu.

```{.mermaid caption="Máy trạng thái của lượt phát lại"}
stateDiagram-v2
  [*] --> DRAFT
  DRAFT --> APPROVED : dưới ngưỡng
  DRAFT --> PENDING_APPROVAL : vượt ngưỡng
  PENDING_APPROVAL --> APPROVED
  PENDING_APPROVAL --> REJECTED
  APPROVED --> RUNNING
  RUNNING --> PAUSED
  PAUSED --> RUNNING
  RUNNING --> COMPLETED
  RUNNING --> PARTIAL
  RUNNING --> FAILED
  RUNNING --> CANCELLED
  PAUSED --> CANCELLED
  COMPLETED --> [*]
  PARTIAL --> [*]
  FAILED --> [*]
```

Hình cho thấy tự dừng do tỷ lệ lỗi đưa lượt về `PAUSED`, không về `FAILED`, để người vận hành xem nguyên nhân rồi tiếp tục hoặc hủy.

```{.mermaid caption="Máy trạng thái của yêu cầu khôi phục tenant"}
stateDiagram-v2
  [*] --> DRAFT
  DRAFT --> PENDING_APPROVAL
  PENDING_APPROVAL --> APPROVED
  PENDING_APPROVAL --> REJECTED
  DRAFT --> CANCELLED
  PENDING_APPROVAL --> CANCELLED
  APPROVED --> RUNNING
  RUNNING --> SUCCEEDED
  RUNNING --> FAILED : lỗi bước 2 đến 4
  RUNNING --> ROLLED_BACK : lỗi bước 5 đến 8
  SUCCEEDED --> [*]
  FAILED --> [*]
  ROLLED_BACK --> [*]
```

Hình cho thấy lỗi trước bước 5 kết thúc `FAILED` vì dữ liệu thật chưa đổi, lỗi từ bước 5 luôn đi qua quay lui.

```{.mermaid caption="Máy trạng thái của nhóm chạy song song và cắt chuyển"}
stateDiagram-v2
  [*] --> PARALLEL
  PARALLEL --> SHADOW_OK : tỷ lệ khớp đạt 24 giờ
  SHADOW_OK --> PARALLEL : tỷ lệ rơi dưới ngưỡng
  SHADOW_OK --> PARTIAL_CUTOVER : bốn mắt
  SHADOW_OK --> CUT_OVER : bốn mắt
  PARTIAL_CUTOVER --> CUT_OVER : bốn mắt
  PARTIAL_CUTOVER --> ROLLED_BACK
  CUT_OVER --> ROLLED_BACK : trong cửa sổ quay lui
  ROLLED_BACK --> PARALLEL
```

Hình cho thấy chỉ từ `SHADOW_OK` mới cắt chuyển được, và quay lui luôn đưa nhóm về `PARALLEL` để đo lại trước lần cắt chuyển sau.

### 8.2. Outbox và giao dịch

Mọi sự kiện EVT-18 được ghi vào `outbox_event` trong cùng giao dịch với thay đổi nghiệp vụ và kiểm toán (§4.25), nên không có trạng thái "đã đổi mà chưa phát" hay "đã phát mà chưa đổi". Giao dịch luôn ngắn: không giữ giao dịch qua lời gọi mạng (PH-09, PH-10, PH-13, cổng phát lại, máy chủ thư, Kubernetes API). Mẫu chung là hai giao dịch: giao dịch 1 ghi ý định (`REPLAYING`, `QUEUED`, `APPROVED`), lời gọi mạng không khóa, giao dịch 2 ghi kết quả; bản sao chết giữa hai giao dịch thì tác vụ quét (`ReplayTimeoutSweeper`, `JobWatcher`, `DeliveryWorker` với `locked_until`) nhận lại. Thông báo có outbox riêng là bảng `notification_message`, vì mỗi thông báo cần trạng thái gửi theo người nhận, khác sự kiện Kafka.

### 8.3. Inbox, idempotency và khóa lũy đẳng

Bảng ghi khóa lũy đẳng ở từng đường vào và cửa sổ giữ khóa.

| Đường vào | Khóa | Cửa sổ | Trùng thì |
|---|---|---|---|
| Bản tin DLQ trên topic | `dlq:{topic}:{partition}:{offset}` ở `inbox_event`, rồi `dlqKey` mục mở | `18.dlq.dedup-window-days`, mục mở thì đến khi đóng | Bỏ qua, hoặc tăng đếm lần gặp |
| API ghi DLQ | `Idempotency-Key` của bên gọi | 24 giờ | Trả kết quả cũ |
| Phát lại | `dlqId:revision` ở `replay_item`, nguồn giữ ≥ 30 ngày | Theo mục | Kết quả chỉ ghi một lần |
| Thông báo | `Idempotency-Key`, quy tắc sự kiện `eventId:ruleId` | 24 giờ | Trả `messageId` cũ; thân khác thì ERR-18-009 |
| Việc | (`type_code`, `task_key`) | Suốt vòng đời việc | Cập nhật, hoặc `200` khi giống |
| Sự cố | `sourceRef` | Khi còn mở | Thêm mốc thời gian |
| Sao lưu | (`object_code`, `tool_run_id`) | Theo hạn giữ | Cập nhật bản ghi |
| Di trú | `legacySystem:objectType:legacyKey` ở đích | Suốt dự án | Đích trả bản ghi đã có |
| Chuyển sáp nhập | `mergePlanId:module:mode` | Suốt kế hoạch | Trả chuyển đã có; thân khác thì ERR-18-061 |
| Sự kiện tiêu thụ | `eventId` ở `inbox_event` | 7 ngày | Bỏ qua |
| `POST` người dùng | `Idempotency-Key` (`IdempotencyFilter`) | 24 giờ | Trả phản hồi cũ |

: Khóa lũy đẳng theo đường vào

### 8.4. Đồng thời

Ba cơ chế tránh tranh chấp. **ETag và `If-Match`**: mọi `PUT`, `PATCH` và chuyển trạng thái do người dùng gửi kèm `If-Match` bằng `version` của dòng (trigger `tg_touch` tăng khi sửa); thiếu thì ERR-00-428, lệch thì ERR-18-004 (BR-18-049). **Khóa tư vấn**: `pg_advisory_xact_lock` theo `ns` khi đăng ký lược đồ, theo `dlqKey` khi tiếp nhận, theo tenant cho tác vụ nặng; khóa tự nhả khi giao dịch kết thúc nên không có khóa treo. **ShedLock**: mọi tác vụ định kỳ (`RetentionJob`, `PartitionMaintenanceJob`, `DlqReconciler`, `ThresholdEvaluator`, `BackupFreshnessJob`, `OpsReportJob`, `ReminderJob`, `ChangeRequestExpiryJob`, `AckEscalationJob`, `FlagRetireReminderJob`) chỉ chạy ở một bản sao, `lockAtMostFor` bằng hai lần thời gian chạy dự kiến. Tác vụ chia việc theo dòng (bộ gửi thông báo, bộ điều phối phát lại, hàng loạt) dùng `FOR UPDATE SKIP LOCKED` thay vì ShedLock để mọi bản sao cùng làm.

### 8.5. Thời gian chờ, thử lại, cầu dao

Bảng ghi thời gian chờ, thử lại và cầu dao (Resilience4j) cho từng phụ thuộc ra.

| Phụ thuộc | Thời gian chờ | Thử lại | Cầu dao | Khi mở |
|---|---|---|---|---|
| PH-13 API-13-069 | `18.dlq.diagnostics.timeout-ms` (3 giây) | Không | 50% lỗi trên 20 lượt, mở 30 giây | Bỏ phần chẩn đoán |
| PH-10 API-10-060…064 | 5 giây | 2 lần, lùi 200 ms | Như trên | ERR-18-035 |
| PH-09 phân loại | 2 giây | 1 lần | Như trên | Đóng an toàn (từ chối mẫu, bắt bốn mắt bản sửa) |
| Cổng `HTTP_PORT` | 10 giây | 2 lần với lỗi mạng, `503` | Theo nguồn | Lượt tạm dừng phần của nguồn đó |
| Máy chủ thư | 10 giây kết nối, 30 giây gửi | Theo `18.notify.retry.*` | Theo kênh | Thông báo chờ trong hàng |
| SMS gateway | 5 giây | Theo `18.notify.retry.*` | Theo kênh | Như trên |
| PH-20 registry, chuyển trạng thái tenant | 5 giây | 3 lần, lùi lũy thừa | Có | Dùng danh sách đệm; khôi phục dừng ở bước 4 |
| Garage | 30 giây mỗi đối tượng | 3 lần | Có | Tiếp nhận tạm dừng phân vùng |
| API nhập phân hệ đích (di trú) | 60 giây mỗi lô | 3 lần với `503` | Theo đích | Lần chạy dừng ở trạng thái khởi động lại được (ERR-18-069) |
| Kubernetes API | 10 giây | 3 lần | Không | Yêu cầu giữ `APPROVED`, thử tạo Job lại mỗi phút |

: Thời gian chờ, thử lại và cầu dao theo phụ thuộc

### 8.6. Ánh xạ lỗi

`ProblemMapper` trả RFC 9457 với `type`, `title`, `status`, `detail`, `code`, `traceId`. Ngoại lệ miền mang mã ERR-18; vi phạm ràng buộc CSDL được dịch theo tên ràng buộc: `ck_param_*` thành ERR-18-012, 013 hoặc 014 theo phần lỗi; `uq_param_change_request_pending` thành ERR-18-018; `ck_*_four_eyes` thành ERR-18-005; `tg_*_fsm_status` (55000) thành ERR-18-006; `ck_dlq_message_discard` thành ERR-18-007; `OptimisticLock` thành ERR-18-004. Lỗi không ánh xạ được trả `500` với `code = ERR-00-500` và được ghi log có `traceId`. Mã ERR-18-101…124 không trả qua HTTP mà ghi vào trường lỗi của đối tượng (mục DLQ, lần gửi, bước, kết quả mục) và hiện ở màn tương ứng.

## 9. Cấu hình và cờ tính năng theo tenant

PH-18 có hai lớp cấu hình. Thuộc tính triển khai (Helm values, không theo tenant) quyết định kết nối, tài nguyên, số luồng; tham số `18.*` (theo tenant hoặc nền tảng, đổi được lúc chạy) quyết định hành vi nghiệp vụ. Một quy tắc: không thuộc tính triển khai nào được trùng nghĩa với một khóa `18.*`.

### 9.1. Thuộc tính triển khai

Khối dưới là phần `application.yaml` của module `ops`; giá trị bí mật không bao giờ nằm trong tệp mà được nạp từ OpenBao qua Spring Cloud Vault theo đường dẫn ghi ở cột tham chiếu.

```yaml
datahub:
  ops:
    profile: api                    # api | worker
    dlq:
      topic-pattern: "^[a-z0-9]+\\.ops\\.dlq\\.v1$"
      consumer-group: ph18-dlq-ingest
      concurrency: 3
      max-poll-records: 500
      pause-backoff: [5s, 10s, 30s, 60s]
    replay:
      dispatcher-interval: 1s
      lease-ttl: 30s
      http-timeout: 10s
    notify:
      mail:
        host-ref: kv/dh/common/notify/smtp      # tham chiếu, không chứa giá trị
        port: 587
        starttls: required
      sms:
        endpoint-ref: kv/dh/common/notify/sms
      worker-batch: 100
      urgent-interval: 1s
    jobs:
      namespace: dh-batch
      worker-image: harbor.datahub.local/dh/dh-ops-worker   # ghim digest ở Helm
      service-account: dh-platform-ops-jobs
    tenant-registry:
      cache-ttl: 10m
  ops.client:                       # cho dh-ops-client ở mọi DU
    base-url: https://dh-platform.dh-control.svc:8443/ops/internal/v1
    stale-max: 24h
    refresh-subscribe: true
```

### 9.2. Tham số theo tenant mà thành phần đọc

Bảng ghi nhóm khóa `18.*` (FRS §8.2) theo thành phần đọc; mọi khóa đọc qua `ParameterApi` trong cùng DU nên cũng chịu độ cũ ≤ 60 giây.

| Thành phần | Khóa `18.*` |
|---|---|
| 4.2, 4.3, 4.4 | `18.param.cache-ttl-seconds`, `18.param.reason-min-length`, `18.param.history-retention-days`, `18.param.change-request-ttl-hours` |
| 4.5 | `18.ff.retire-warning-days`, `18.egress.allowlist`, `18.egress.max-entries` |
| 4.6, 4.7 | `18.dlq.payload.inline-max-kb`, `18.dlq.payload.max-mb`, `18.dlq.dedup-window-days`, `18.dlq.reconcile.cron` |
| 4.8, 4.9 | `18.dlq.group.window-hours`, `18.dlq.diagnostics.timeout-ms`, `18.dlq.reveal.ttl-minutes` ★ |
| 4.11 | `18.dlq.replay.batch-max`, `18.dlq.replay.approval-threshold` ★, `18.dlq.replay.rate-per-second`, `18.dlq.replay.result-timeout-minutes`, `18.dlq.threshold.replay-failure-percent` |
| 4.12 | `18.dlq.retention.closed-days`, `18.dlq.retention.metadata-days`, `18.dlq.retention.open-max-days`, `18.dlq.audit.retention-months`, `18.dlq.threshold.depth`, `18.dlq.threshold.age-hours`, `18.dlq.threshold.poison-per-hour` |
| 4.14, 4.15 | `18.notify.quiet-hours`, `18.notify.retry.max-attempts`, `18.notify.retry.window-hours`, `18.notify.sync.timeout-ms`, `18.notify.bounce.soft-limit`, `18.notify.log-retention-days`, `18.notify.sms.enabled`, `18.notify.sender-name` |
| 4.16, 4.17 | `18.task.reminder.before-hours`, `18.task.overdue.escalate-hours`, `18.task.retention-days`, `18.calendar.weekend-days`, `18.calendar.timezone`, `18.maintenance.notice-hours`, `18.freeze.default-envs` |
| 4.18 | `18.incident.sev1-ack-minutes`, `18.incident.sev2-ack-minutes`, `18.incident.retention-years` |
| 4.19, 4.20, 4.21 | `18.backup.stale-hours`, `18.backup.freshness-max-minutes`, `18.backup.verification-interval-days`, `18.restore.max-duration-hours`, `18.restore.approval-required` ★, `18.export.link-ttl-hours`, `18.export.retention-days` |
| 4.22, 4.23 | `18.migration.dry-run-valid-days`, `18.migration.batch-size`, `18.migration.parallel.match-threshold-percent`, `18.migration.shadow.sample-percent`, `18.migration.shadow.sample-retention-days`, `18.migration.rollback-window-minutes` |
| 4.24, 4.25 | `18.report.schedule`, `18.report.retention-months`, `18.degraded.read-only`, `18.outbox.retention-days` |

: Khóa 18.* theo thành phần đọc

Khóa `18.*` có giá trị dùng ngay trong vòng lặp nóng (`18.dlq.replay.rate-per-second`, `18.dlq.payload.inline-max-kb`) được đọc một lần mỗi lô, không mỗi bản ghi. Đổi `18.dlq.reconcile.cron` có hiệu lực ở lần lập lịch kế tiếp vì bộ lập lịch đọc lại biểu thức sau mỗi lần chạy.

### 9.3. Bộ nhớ đệm

Bảng ghi các bộ đệm của PH-18 và cách vô hiệu.

| Bộ đệm | Nơi | Hạn | Vô hiệu khi |
|---|---|---|---|
| Ảnh chụp tham số phía khách | Caffeine trong DU gọi | ≤ 60 giây | EVT-18-01, 03, 04 |
| ETag ảnh chụp phía máy chủ | Bộ nhớ `dh-platform` | Đến khi đổi | EVT-18-01 nhận ở chính bản sao |
| Lịch năm | Bộ nhớ | 1 giờ | EVT-18-15 |
| Người nhận theo nhóm, vai trò | Bộ nhớ | 5 phút | Không (chấp nhận trễ 5 phút) |
| Tóm tắt Việc của tôi | Bộ nhớ, theo người dùng | 30 giây | EVT-18-14 của người đó |
| Ngữ cảnh chẩn đoán | Bộ nhớ, theo `trace_id` | 5 phút | Không |
| Danh sách tenant `ACTIVE` | Bộ nhớ | 10 phút | `platform.tenant.status-changed.v1` |
| Phiếu xem payload | Valkey | `18.dlq.reveal.ttl-minutes` | Hết hạn |

: Bộ nhớ đệm của PH-18

### 9.4. Cờ tính năng

PH-18 dùng ba cờ theo chuẩn `ff.{module}.{tính-năng}`, khai báo trong chính kho tham số, có chủ sở hữu và ngày gỡ: `ff.ops.shadow-compare` (bật đối soát bóng theo tenant khi PH-03 sẵn sàng bộ chạm, Q18-25), `ff.ops.sms-channel` (bật kênh SMS mức nền tảng trước khi tỉnh bật `18.notify.sms.enabled`), `ff.ops.merge-transfer` (bật chuyển sáp nhập khi PH-20 lên đợt 2). Cờ tắt thì API tương ứng trả ERR-18-006 với chi tiết "chức năng chưa bật".

## 10. Quan sát

Chỉ số phát qua Micrometer, tiền tố `dh_ops_`, nhãn có bậc số lượng nhỏ (`tenant`, `source`, `mode`, `result`, `status`, `channel`, `kind`, `step`); không dùng `dlqId`, mã người dùng, địa chỉ, mã yêu cầu làm nhãn (SEC-32). Chỉ số cho PH-13 đặt luật cảnh báo; PH-18 không tự làm luật (BR-18-026).

| Nhóm | Chỉ số | Nhãn |
|---|---|---|
| Tham số | `dh_ops_param_write_total`, `dh_ops_param_write_seconds`, `dh_ops_param_read_total`, `dh_ops_param_read_seconds`, `dh_ops_param_change_request_pending`, `dh_ops_param_schema_registration_total` | `mode`, `result`, `ns` |
| Thư viện khách | `dh_ops_client_cache_age_seconds`, `dh_ops_client_param_version`, `dh_ops_client_refresh_total`, `dh_ops_client_fallback_total` | `du`, `ns`, `level` |
| Tiếp nhận DLQ | `dh_ops_dlq_ingest_total`, `dh_ops_dlq_ingest_lag_seconds`, `dh_ops_dlq_consumer_lag`, `dh_ops_dlq_payload_bytes`, `dh_ops_dlq_poison_total`, `dh_ops_dlq_dedup_hits_total`, `dh_ops_dlq_partition_paused` | `tenant`, `source`, `result` |
| Tồn DLQ | `dh_ops_dlq_open`, `dh_ops_dlq_open_oldest_seconds`, `dh_ops_dlq_poison_rate`, `dh_ops_dlq_groups_open`, `dh_ops_dlq_threshold_crossed_total`, `dh_ops_dlq_purged_total`, `dh_ops_dlq_reconcile_missing_total` | `tenant`, `source`, `class`, `type` |
| Phát lại | `dh_ops_replay_dispatch_total`, `dh_ops_replay_rate_actual`, `dh_ops_replay_jobs`, `dh_ops_replay_result_seconds`, `dh_ops_replay_timeout_total` | `mode`, `result`, `status` |
| Thông báo | `dh_ops_notify_submitted_total`, `dh_ops_notify_delivery_total`, `dh_ops_notify_queue_depth`, `dh_ops_notify_end_to_end_seconds`, `dh_ops_notify_suppressed_total`, `dh_ops_bounce_total` | `channel`, `priority`, `lane`, `result`, `reason` |
| Việc, lịch, sự cố | `dh_ops_task_open`, `dh_ops_task_overdue`, `dh_ops_my_tasks_seconds`, `dh_ops_calendar_missing_total`, `dh_ops_freeze_active`, `dh_ops_incident_open`, `dh_ops_incident_ack_seconds` | `type`, `severity`, `env` |
| Sao lưu, khôi phục | `dh_ops_backup_last_success_timestamp`, `dh_ops_backup_stale`, `dh_ops_restore_verification_result`, `dh_ops_restore_step_seconds`, `dh_ops_restore_duration_seconds`, `dh_ops_restore_active`, `dh_ops_export_seconds` | `object`, `tool`, `step` |
| Di trú | `dh_ops_migration_records_total`, `dh_ops_migration_throughput`, `dh_ops_migration_reconcile_mismatch_total`, `dh_ops_shadow_match_ratio`, `dh_ops_cutover_state`, `dh_ops_rollback_seconds` | `object_type`, `result`, `group` |
| Hệ thống | `dh_ops_outbox_pending`, `dh_ops_outbox_lag_seconds`, `dh_ops_inbox_duplicates_total`, `dh_ops_audit_write_failures_total`, `dh_ops_heavy_task_rejected_total`, `dh_ops_health`, `dh_ops_read_only`, `dh_ops_worker_runs_total`, `dh_ops_worker_heartbeat_timestamp` | `component`, `command`, `result` |

: Chỉ số quan sát của PH-18

**Log.** JSON qua `LogMasker` dùng chung, có `traceId`, `tenant`, `module = ops`, `submodule`, `operationId`, `dlqId` hoặc mã đối tượng (trong thân log, không làm nhãn). Log không bao giờ có payload DLQ, nội dung bản sửa, giá trị khóa ★, địa chỉ người nhận rõ, nội dung thư, URL JDBC có tham số, hay giá trị lấy từ OpenBao.

**Trace.** OpenTelemetry với span `ops.param.write`, `ops.param.snapshot`, `ops.dlq.ingest`, `ops.dlq.reveal`, `ops.replay.dispatch`, `ops.replay.result`, `ops.notify.deliver`, `ops.task.upsert`, `ops.restore.step`, `ops.migrate.chunk`, `ops.shadow.compare`, `ops.cutover`. Bản tin DLQ mang `traceparent` của lần lỗi gốc; khi phát lại, PH-18 tạo span mới có liên kết (`span link`) tới trace gốc để PH-13 nối hai lần chạy. Job worker gửi span qua OTLP với `service.name = dh-ops-worker`.

**Đề xuất luật cho PH-13.** Bảng ghi luật PH-13 nên đặt trên chỉ số của PH-18 (PH-13 quyết định cuối cùng).

| Luật | Biểu thức gợi ý | Mức |
|---|---|---|
| Tiếp nhận DLQ chậm | `dh_ops_dlq_ingest_lag_seconds` p95 > 5 giây trong 10 phút | SEV-3 |
| Bộ tiêu thụ DLQ kẹt | `dh_ops_dlq_partition_paused` > 0 trong 5 phút | SEV-2 |
| Outbox ứ | `dh_ops_outbox_lag_seconds` > 60 giây trong 5 phút | SEV-2 |
| Thư khẩn chậm | `dh_ops_notify_end_to_end_seconds{priority="URGENT"}` p95 > 30 giây | SEV-2 |
| Sao lưu trễ | `dh_ops_backup_stale` > 0 | SEV-2, SEV-1 với đối tượng `TPH-0` |
| Khôi phục quá chỉ tiêu | `dh_ops_restore_duration_seconds` > `18.restore.max-duration-hours` | SEV-2 |
| Quay lui chậm | `dh_ops_rollback_seconds` > 300 | SEV-1 |
| Bộ đệm khách quá cũ | `dh_ops_client_cache_age_seconds` > 300 ở bất kỳ DU | SEV-3 |

: Luật cảnh báo đề xuất cho PH-13 trên chỉ số của PH-18

## 11. Hiệu năng và vận hành

Chương này ước lượng tải, ngân sách độ trễ và tài nguyên, rồi nêu cấu hình triển khai và việc vận hành thường nhật. Số liệu theo NFR-18-001…022 và hồ sơ tỉnh vừa; mọi con số chưa đo đều ghi "giả định" và sẽ đo ở đợt kiểm thử tải trước nghiệm thu MVP.

### 11.1. Ngân sách độ trễ

Bảng chia ngân sách p95 của các NFR có độ trễ theo bước; con số từng bước là giả định thiết kế.

| NFR | Chỉ tiêu | Phân bổ (giả định) |
|---|---|---|
| NFR-18-001 tiếp nhận | ≤ 5 giây từ topic tới màn | Kafka tới bộ tiêu thụ 1 giây; Garage khi cần 1 giây; giao dịch 100 ms; commit lô 500 bản ghi tối đa 2 giây; màn đọc 1 giây |
| NFR-18-003 danh sách | ≤ 1,5 giây | Truy vấn trang 300 ms; `facets` 800 ms; dựng JSON và mạng 400 ms |
| NFR-18-004 đọc lô | ≤ 50 ms, `304` ≤ 20 ms | `304` không chạm CSDL; `200` một truy vấn theo chỉ mục `(tenant_id, key)` 15 ms |
| NFR-18-005 lan truyền | ≤ 60 giây | Bộ chuyển outbox ≤ 5 giây; Kafka 1 giây; tải lại 100 ms; trường hợp lỡ sự kiện thì `refreshAfterWrite` 30 giây cộng `expireAfterWrite` 60 giây là trần |
| NFR-18-007 thông báo | ≤ 60 giây bất đồng bộ, ≤ 3 giây đồng bộ | Hàng đợi 5 giây; phân giải người nhận 200 ms; SMTP 1 giây |
| NFR-18-009 Việc của tôi | ≤ 800 ms | Truy vấn theo `(tenant_id, assignee_ref, status)` 100 ms; lọc quyền trong bộ nhớ |

: Ngân sách độ trễ theo NFR

### 11.2. Thông lượng và dung lượng

Hồ sơ tỉnh vừa theo D03-03-PH18 §1.6 (giả định GĐ-01, 2 triệu bản tin mỗi ngày qua PH-04, tỷ lệ lỗi 0,1%): khoảng 2.000 mục DLQ mới mỗi ngày mỗi tenant, đỉnh khi một HTTT đích sập có thể 50.000 mục trong một giờ (giả định), tức khoảng 14 bản tin mỗi giây, nhỏ hơn nhiều so với 200 bản tin mỗi giây mỗi phân vùng của NFR-18-001; chỉ tiêu này đặt cho trường hợp xấu khi cả cụm 34 tenant cùng lỗi. Đọc tham số: 15 DU nhân 2 bản sao nhân 34 tenant nhân khoảng 15 không gian tên, làm mới mỗi 30 giây, cho khoảng 500 yêu cầu mỗi giây, gần hết là `304` (khớp điều kiện đo NFR-18-004). Thông báo: 10.000 mỗi giờ là khoảng 3 mỗi giây, một bản sao `worker` thừa sức. Tác vụ nặng: tối đa một mỗi tenant, giả định tối đa 3 Job đồng thời trên cụm (giới hạn bằng `ResourceQuota` của `dh-batch`).

### 11.3. Triển khai

PH-18 không có Helm chart riêng: nó là một phần của chart `dh-platform` (hai Deployment theo hồ sơ) cộng chart con `dh-ops-worker` (mẫu Job, CronJob `dh-backup-reporter`, service account, Role, NetworkPolicy). Bảng ghi tài nguyên đề xuất cho hồ sơ `QM-VUA` (giả định, cần hiệu chỉnh sau kiểm thử tải).

| Đơn vị | Bản sao | CPU yêu cầu, giới hạn | Bộ nhớ yêu cầu, giới hạn | Co giãn |
|---|---|---|---|---|
| `dh-platform` hồ sơ `api` | 2 (SAD), tối đa 4 | 1, 2 | 2 Gi, 3 Gi | HPA theo CPU 70% và `http_server_requests` p95 |
| `dh-platform` hồ sơ `worker` | 2, tối đa 6 | 1, 2 | 2 Gi, 3 Gi | HPA theo `dh_ops_dlq_consumer_lag` và `dh_ops_notify_queue_depth` (KEDA, ngưỡng 5.000 bản ghi lag, 2.000 thông báo); không quá số phân vùng DLQ chia 3 |
| Job `dh-tenant-restore` | 1 mỗi yêu cầu | 2, 4 | 4 Gi, 8 Gi | Không |
| Job `dh-tenant-export` | 1 mỗi lệnh | 2, 4 | 2 Gi, 4 Gi | Không |
| Job `dh-migrate` | 1 mỗi lần chạy | 2, 4 | 3 Gi, 6 Gi | Không |
| CronJob `dh-backup-reporter` | 1 mỗi 5 phút | 0,1, 0,5 | 256 Mi, 512 Mi | Không |
| Cụm tạm khôi phục (CNPG) | 1 instance | 4, 8 | 16 Gi, 16 Gi | Không; đĩa bằng 1,5 lần kích thước ô CSDL nguồn |

: Tài nguyên và co giãn của PH-18 theo hồ sơ QM-VUA

Ba điều kiện triển khai. (1) Hai hồ sơ có `PodDisruptionBudget` `minAvailable: 1` và dàn trải theo vùng. (2) Bản phát hành mới của module `ops` khởi động lại hồ sơ `worker` theo `RollingUpdate` `maxUnavailable: 0`; bộ tiêu thụ DLQ dùng `CooperativeStickyAssignor` để tái cân bằng không dừng toàn nhóm. (3) Liquibase của `ph18_ops` chạy bằng Job `dh_data_migrator` trước khi hồ sơ `api` lên phiên bản mới (D03-03-PH18 §4.3).

### 11.4. Vận hành thường nhật

Bảng ghi các tác vụ định kỳ, lịch, cơ chế chạy một bản sao và việc người vận hành cần làm khi tác vụ lỗi.

| Tác vụ | Lịch | Cơ chế | Khi lỗi |
|---|---|---|---|
| `PartitionMaintenanceJob` | 01:30 hằng ngày | ShedLock | Còn sẵn hai tháng phân vùng phía trước nên có 30 ngày để sửa |
| `RetentionJob` | 02:00 hằng ngày | ShedLock, `TenantFanout` | Chạy lại hôm sau, không mất dữ liệu |
| `DlqReconciler` | `18.dlq.reconcile.cron` (02:30) | ShedLock | Xem `dh_ops_dlq_reconcile_missing_total`, chạy tay API-18-038 |
| `ThresholdEvaluator` | Mỗi phút | ShedLock | Mất cảnh báo ngưỡng trong thời gian lỗi; PH-13 vẫn có chỉ số |
| `BackupFreshnessJob` | Mỗi 5 phút | ShedLock | `dh_ops_backup_report_lag_seconds` tăng |
| `OpsReportJob` | 03:00 ngày đầu kỳ | ShedLock | Chạy tay API-18-179 |
| `ReminderJob`, `EscalationJob` | Mỗi 5 phút | ShedLock | Nhắc trễ |
| `ChangeRequestExpiryJob` | Mỗi 15 phút | ShedLock | Đề nghị quá hạn chưa đóng, vẫn không duyệt được vì kiểm hạn khi duyệt |
| `ReplayDispatcher`, `ReplayTimeoutSweeper` | 1 giây, 1 phút | Khóa thuê Valkey, `SKIP LOCKED` | Lượt chậm lại |
| `DeliveryWorker`, `UrgentDeliveryWorker` | Liên tục | `SKIP LOCKED` | Hàng đợi tăng, xem `dh_ops_notify_queue_depth` |
| CronJob `dh-backup-reporter` | Mỗi 5 phút | `concurrencyPolicy: Forbid` | Trạng thái sao lưu trễ, ERR-18-122 |

: Tác vụ định kỳ của PH-18

### 11.5. Sao lưu và khôi phục của chính PH-18

Schema `ph18_ops` được sao lưu cùng `pg-core` (CNPG Barman, PITR 30 ngày) và xuất logic theo tenant bằng `dh-tenant-export`. Khi khôi phục một tenant có phạm vi gồm PH-18, các bảng khôi phục của chính PH-18 bị loại (§4.20); payload DLQ ở Garage được khôi phục theo bucket cùng bước 6. Kafka không sao lưu nội dung: sau khôi phục toàn cụm, bộ tiêu thụ DLQ bắt đầu từ offset đã commit cuối và `DlqReconciler` bù các khoảng thiếu trong thời hạn giữ topic.

## 12. Kiểm thử

Bảng ghi nội dung và ví dụ ca theo từng lớp kiểm thử; ca chi tiết ở D05-02-PH18. Dữ liệu kiểm thử là dữ liệu tổng hợp ở tenant `T90…T99`.

| Lớp | Nội dung | Ví dụ ca |
|---|---|---|
| Đơn vị | Hàm thuần và bộ chuyển trạng thái: `ParamValidator`, `EffectiveValueResolver`, `EgressHostValidator`, `HeaderNormalizer`, `ContextContractValidator`, `DlqIdFactory`, `MessageNormalizer`, `PayloadPatcher`, `LogiclessTemplateValidator`, `QuietHoursPolicy`, `WorkingDayCalculator`, `DependencyOrderer`, `ChecksumAccumulator`, `MatchRateWindow`, các `StateMachine` | Giá trị 61 cho `18.param.cache-ttl-seconds` bị ERR-18-014. Mẫu có khối điều kiện bị ERR-18-040. Kế hoạch có vòng bị ERR-18-063. Cùng tập bản ghi xáo thứ tự cho cùng tổng kiểm tra |
| Tích hợp (Testcontainers) | PostgreSQL có RLS với DDL `ph18_ops`, Kafka, Valkey, MinIO giả lập API S3 thay Garage, MailHog giả lập SMTP, WireMock cho PH-09, PH-10, PH-13, PH-20, cổng `HTTP_PORT` | Ngắt CSDL 60 giây giữa lúc nạp 100.000 bản tin: 0 mất, 0 trùng (NFR-18-002). Báo kết quả phát lại ba lần cho cùng khóa chỉ ghi một lần. Thư trả lại cứng đưa địa chỉ vào danh sách chặn và phát EVT-18-12 |
| Hợp đồng | OpenAPI `openapi-ops.yaml`, AsyncAPI `asyncapi-ops.yaml` qua Apicurio; kiểm hợp đồng hướng bên tiêu dùng cho `dh-ops-client` | Sự kiện EVT-18-01 của khóa ★ không có trường `value`. Phản hồi `304` của API-18-029 không có thân. Thân lỗi đúng RFC 9457 có `code` |
| Kiến trúc (ArchUnit, Modulith) | `ApplicationModules.verify()`, bốn luật ở §3.2, luật `WorkerTenantSession` của ảnh worker | Không lớp nào ngoài `OutboxWriter` ghi `outbox_event`. `dlq` không phụ thuộc `backup` |
| Cô lập tenant | Bộ kiểm chéo `T91`, `T92` ở mọi API đọc, ở khôi phục và chuyển sáp nhập (SEC-87) | 0 dòng của tenant khác (NFR-18-017). Băm bảng của `T91` không đổi sau khôi phục `T92` |
| Khôi phục, xuất | Chạy `dh-tenant-restore` trên cụm kind có CNPG với 5 GB dữ liệu tổng hợp; chèn lỗi ở bước 3 và bước 5 | Lỗi bước 3 kết thúc `FAILED`, tenant `ACTIVE`. Lỗi bước 5 tự quay lui, số dòng bằng trước khôi phục |
| Di trú | CSDL hệ cũ giả lập (PostgreSQL với lược đồ Aita, Hub mẫu), API nhập giả của PH-07, PH-01 | Chạy lại ba lần liên tiếp 0 bản trùng (NFR-18-014). Tài khoản nguồn có quyền `INSERT` bị ERR-18-062 |
| Phi chức năng | k6 tại APISIX theo hồ sơ tỉnh vừa; kiểm thử chaos | NFR-18-001, 003, 004, 006, 007, 008, 009; tắt `dh-platform` 30 phút trong tải data plane: 0 lỗi data plane (NFR-18-018) |
| Bảo mật | gitleaks, quét log tìm mẫu địa chỉ và số định danh, ZAP cho `/api/ops/v1`, kiểm SSRF cho URL `HTTP_PORT`, JDBC | 0 bí mật, 0 địa chỉ rõ trong log. URL `HTTP_PORT` trỏ IP literal bị từ chối |
| Khả năng tiếp cận | axe và duyệt tay các màn UI-18-01…24 | WCAG 2.2 AA (NFR-18-020) |

: Chiến lược kiểm thử của PH-18

Kiểm thử dùng MinIO thay Garage trong Testcontainers chỉ vì cùng giao diện S3; một bộ ca nhỏ chạy với Garage thật ở môi trường TEST để bắt khác biệt về mã hóa phía máy chủ và đánh phiên bản đối tượng.

## 13. Lộ trình hiện thực, rủi ro và câu hỏi mở

Chương cuối nói thứ tự làm, cách truy vết về hệ cũ, rủi ro, quyết định kiến trúc, các điểm lệch phát hiện khi đối chiếu FRS, CSDL, ADR và SAD, đề nghị đồng bộ cho tài liệu khác và câu hỏi mở. Bảng truy vết FR sang thành phần đầy đủ ở §3.5.

### 13.1. Lộ trình

Lộ trình đề xuất theo kế hoạch W0 đến W6 (`docs/08-implementation/04-ke-hoach-phat-trien.md`); thứ tự ưu tiên phần mà phân hệ MVP khác phụ thuộc trước.

| Tuần | Phần của PH-18 | Lý do thứ tự |
|---|---|---|
| W2 | Chốt hợp đồng ngữ cảnh DLQ và topic `{tenant}.ops.dlq.v1` với PH-04; `common` (outbox, inbox, kiểm toán); `dh-ops-client` bản đọc tham số và đăng ký lược đồ; §4.2, §4.3 | Mọi phân hệ MVP cần đọc tham số; PH-04 đang ghi DLQ ở W2 |
| W3 | Thông báo (§4.13 đến §4.15), hộp việc và lịch (§4.16, §4.17), cờ tính năng và mặc định tenant (§4.5) | PH-01, PH-02 cần thư, việc duyệt, hạn theo ngày làm việc |
| W4 | DLQ đầy đủ (§4.6 đến §4.12), màn `/van-hanh/dlq` | Cổng W4 "DLQ replay được" (WP-40, WP-44) |
| W5 | Sự cố (§4.18), bảng điều khiển sao lưu (§4.19), khôi phục và xuất tenant (§4.20, §4.21), khung worker (§4.26) | Cần trước diễn tập DR và nghiệm thu ATTT |
| W6 | Di trú, chạy song song, cắt chuyển (§4.22, §4.23), báo cáo, sức khỏe (§4.24) | Phục vụ thí điểm thay dần hệ cũ |
| Đợt 2 | Chuyển sáp nhập (§4.21 phần `merge`), chuyển PH-09, egress, API đọc cho PH-17 | Phụ thuộc PH-20, PH-09, PH-17 đợt 2 |

: Lộ trình hiện thực PH-18

### 13.2. Truy vết hệ cũ

Bảng nối nghiệp vụ hệ cũ (kiểm kê LGC ở D00-03) với thành phần của tập này; chi tiết từng mã LGC ở FRS §11.

| Nghiệp vụ hệ cũ | Thành phần | Ghi chú |
|---|---|---|
| LGC-BUS-031 cấu hình hệ thống | 4.2 đến 4.5 | Thay API lấy, cập nhật thô bằng kho có lược đồ, phiên bản, bốn mắt |
| LGC-BUS-037 xử lý lỗi, thực hiện lại hoặc bỏ qua | 4.6 đến 4.12 | Thêm hợp đồng ngữ cảnh, sửa có kiểm soát, phát lại qua nguồn |
| LGC-NFR-004 giám sát, sự cố để trống ở hệ cũ | 4.18, 4.24 | Hồ sơ sự cố mới; giám sát thuộc PH-13 |
| Nhóm LGC-HUB, LGC-PAY, LGC-DMDC, LGC-APIM | 4.22, 4.23 | Là đối tượng di trú, không phải chức năng PH-18 giữ lại |
| SRS cũ FR-18-001…020 (chỉ DLQ) | 4.6 đến 4.12 | Bảng ánh xạ ở FRS §11.3 |

: Truy vết nghiệp vụ hệ cũ sang thành phần

### 13.3. Rủi ro

Bảng ghi rủi ro kỹ thuật, ảnh hưởng và cách giảm.

| Rủi ro | Ảnh hưởng | Cách giảm |
|---|---|---|
| PH-18 thành phụ thuộc cứng của mọi phân hệ nếu thư viện khách dùng sai | Sự cố PH-18 lan sang data plane | `dh-ops-client` fail-soft ba mức, kiểm thử NFR-18-018 trong CI tải; luật ArchUnit cấm gọi API tham số đồng bộ trong đường nóng |
| Khôi phục tenant thay dữ liệu sai phạm vi | Mất dữ liệu một tỉnh | Bốn mắt, cụm tạm, bản trích hiện tại để quay lui, RLS ở cụm thật, đối chiếu số dòng, diễn tập hằng quý trên `T9x` |
| Trigger của các phân hệ chặn xóa làm bước 5 thất bại | Khôi phục không chạy được | Thống nhất cờ `app.restore_mode` ở mọi DDL trước W5 (Q18-24) |
| Bảng phân vùng không có chỉ mục duy nhất trên `dlqKey` | Mục trùng khi tải đồng thời cao | Khóa tư vấn theo `dlqKey` trong giao dịch, kiểm thử chaos NFR-18-002 |
| Thông lượng di trú phụ thuộc API nhập của đích | Trễ lịch cắt chuyển | Đo sớm ở W6 với PH-07, PH-01; cho phép khối song song khi bộ chuyển độc lập |
| Đối soát bóng cần bộ chạm ở APISIX chưa có chủ | Không đạt `SHADOW_OK`, không cắt chuyển được | Cờ `ff.ops.shadow-compare`, chốt chủ ở Q18-25 trước W6; phương án dự phòng là so mẫu theo lô từ log của hai hệ |
| Bộ tiêu thụ theo mẫu topic của 34 tenant làm nhiều nhóm tiêu thụ tạm ở `dh-ops-client` | Tải metadata Kafka | Một nhóm mỗi bản sao, không commit, `offsets.retention` ngắn; theo dõi số nhóm ở PH-13 (Q18-28) |

: Rủi ro kỹ thuật của PH-18

### 13.4. Quyết định kiến trúc

Năm ADR đề xuất của PH-18 đã có tệp ở `00-chung/adr/`; bảng ghi cách tập này hiện thực từng quyết định.

| ADR | Quyết định | Hiện thực ở tập này |
|---|---|---|
| ADR-180 | Kho tham số tập trung trên `ph18_ops`, lược đồ do phân hệ đăng ký, làm mới bằng sự kiện | §4.2 đến §4.5; Caffeine ≤ 60 giây, `ETag`, fail-soft |
| ADR-181 | DLQ hợp nhất, payload gốc bất biến, payload lớn ở Garage, liên thông PH-10 | §4.6 đến §4.9, §4.12. Đã hấp thụ ở 0.2: ADR-181 dùng tham số `18.dlq.dedup-window-days`, giữ topic 14 ngày như FRS |
| ADR-182 | Phát lại qua lối vào của nguồn, khóa `dlqId:revision`, bốn mắt loạt lớn | §4.11, SPI `ReplayPort` |
| ADR-183 | Khung di trú `dh-migrate`, đọc JDBC chỉ đọc, ghi qua API nhập | §4.22, §4.23 |
| ADR-184 | Thông báo qua outbox, SMTP/TLS, SMS REST, mẫu Mustache không logic | §4.13 đến §4.15 |

: ADR của PH-18 và chỗ hiện thực

Tập không đề xuất ADR mới. Hai lựa chọn thiết kế có thể cần nâng thành ADR nếu hội đồng muốn: mô hình đẩy cho bộ thu trạng thái sao lưu (§4.19, Q18-22) và cờ `app.restore_mode` dùng chung cho trigger của mọi phân hệ (§4.20, Q18-24).

### 13.5. Điểm lệch giữa FRS, CSDL, ADR và SAD

Khi đối chiếu, tập này phát hiện mười điểm lệch. FRS là nguồn chuẩn khi lệch (brief PH-18 §8); tập này thiết kế theo cột "Theo" và ghi đề nghị sửa ở §13.6. Ở lượt đồng bộ 0.2, chín điểm nội bộ PH-18 (1 đến 9) đã hấp thụ ở FRS 0.2, CSDL 0.2, API 0.2 và ADR-181; điểm 10 liên quan D03-09, D03-10 và DDL của phân hệ khác nên giữ cho đợt đồng bộ cuối.

| Số | Điểm lệch | Nguồn A | Nguồn B | Theo |
|---|---|---|---|---|
| 1 | Loại cổng phát lại | FRS §4.1, FR-18-012: trường `replayMode` ∈ `KAFKA_TOPIC`, `HTTP_PORT`, `EVENT_LAYER`, `NONE` | CSDL `dlq_source.replay_port` CHECK `PH04_RUNTIME`, `PH10_EVENT`, `REPLAY_PORT`, `NONE` | FRS; CSDL đổi tên cột và giá trị. Đã hấp thụ ở 0.2: CSDL cột `replay_mode` |
| 2 | Bộ đếm lần gặp khi khử trùng | BR-18-015, ERR-18-105 "tăng số lần gặp" | `dlq_message` không có cột đếm, lần gặp cuối | FRS; CSDL thêm `occurrence_count`, `last_seen_at`. Đã hấp thụ ở 0.2: CSDL `occurrence_count`, `last_seen_at` |
| 3 | Payload không phải JSON | ERR-18-101 "lưu dạng nhị phân" | `payload_inline jsonb` chỉ nhận JSON | Payload không phải JSON luôn vào Garage (§4.6); CSDL ghi rõ. Đã hấp thụ ở 0.2: chú thích cột `payload_location` ở CSDL |
| 4 | Tên khóa tham số | FRS `18.notify.log-retention-days`, `18.param.history-retention-days` | CSDL §3.58, §7 `18.notify.delivery-retention-days`, `18.param.history-retention-years` | FRS (thuộc 11 khóa lệch đã biết). Đã hấp thụ ở 0.2: CSDL sinh 61 khóa từ FRS §8.2 |
| 5 | Cửa sổ khử trùng của inbox DLQ | FRS `18.dlq.dedup-window-days` mặc định 7, miền 1…30 | CSDL §7 và ADR-181 ghi 30 ngày | FRS; mục mở vẫn được khử trùng theo `dlqKey` không phụ thuộc cửa sổ. Đã hấp thụ ở 0.2: CSDL và ADR-181 theo tham số, mặc định 7 ngày |
| 6 | Thời hạn giữ topic DLQ | FRS NFR-18-016: 7 ngày | ADR-181: Kafka giữ 14 ngày | Chờ Q18-21; thiết kế không phụ thuộc giá trị nhờ đối soát. Đã hấp thụ ở 0.2: chọn 14 ngày theo ADR-181, FRS NFR-18-016 và FR-18-018 sửa; Q18-21 đóng |
| 7 | Số bản sao `dh-platform` | FRS §8.1 điều kiện đo: 3 bản sao | SAD §4.3: 2 bản sao `QM-VUA` | SAD cho triển khai (2, HPA tới 4); FRS ghi rõ điều kiện đo là 3. Đã hấp thụ ở 0.2: FRS §8.1 ghi 2 bản sao theo SAD, HPA tới 4 |
| 8 | Nguồn `KAFKA_TOPIC` lấy nội dung phát lại | EVT-18-09 mang `payloadRef` | FRS §9.4 và OpenAPI không có API lấy nội dung theo `payloadRef` | Đề xuất `GET /ops/internal/v1/replay-payloads/{dlqId}/{revision}`, scope `ops:replay-callback`. Đã hấp thụ ở 0.2: API-18-188 |
| 9 | Kho lần chạy Spring Batch | ADR-183 chọn Spring Batch, cần `JobRepository` để khởi động lại | CSDL 57 bảng không có bảng `BATCH_*` | Thêm bảng kho của Spring Batch vào `ph18_ops` (không RLS, chỉ `ph18_worker`) hoặc schema `ph18_batch`. Đã hấp thụ ở 0.2: CSDL schema `ph18_batch` (D03-03-PH18 §4.4) |
| 10 | Khôi phục tenant ở cụm thật | D03-09 §8.5 nói "tắt trigger ghi outbox" và không nêu bảng loại trừ | CSDL không có vai ghi liên schema, trigger chặn xóa của các phân hệ không có ngoại lệ | Vai `dh_tenant_restorer`, cờ `app.restore_mode`, loại trừ bảng outbox, inbox, kiểm toán (§4.20). Giữ cho đợt cuối (liên PH) |

: Điểm lệch phát hiện và hướng thiết kế đã theo

Ngoài mười điểm trên, `merge_transfer` cùng hướng chuyển sáp nhập ghi thẳng schema phân hệ đích (theo hợp đồng PH-20, brief §7), khác nguyên tắc ghi qua API nhập của di trú hệ cũ (ADR-183); đây không phải lệch tài liệu vì ADR-183 chỉ nói về di trú, nhưng cần chốt (Q18-29). CSDL cũng chưa có ràng buộc "một tác vụ nặng mỗi tenant" (BR-18-039); tập này cưỡng chế bằng khóa tư vấn ở §4.25 và không đề nghị thêm bảng.

### 13.6. Đề nghị đồng bộ

> **Đợt đồng bộ chéo cuối (27/11/2026).** Các đề nghị dưới đây đã được xét; kết luận từng dòng (đã sửa, đã khớp sẵn, câu hỏi mở, không làm) ghi ở [D00-03-01 Sổ đồng bộ chéo cuối](../../00-chung/D00-03-01-so-dong-bo-cuoi.md).

Bảng ghi việc cần sửa ở tài liệu chung và phân hệ khác, vì tập này không tự sửa các tài liệu đó. Bốn dòng đầu (D03-03-PH18, D02-03-PH18, D03-04-PH18, ADR-181) là đồng bộ nội bộ PH-18 và đã hấp thụ ở 0.2; các dòng còn lại liên phân hệ, giữ cho đợt đồng bộ cuối.

| Tài liệu | Đề nghị |
|---|---|
| D03-03-PH18 CSDL | (1) Đổi `dlq_source.replay_port` thành `replay_mode` với giá trị của FRS. (2) Thêm `dlq_message.occurrence_count`, `last_seen_at` cho phép cập nhật (không nằm trong `tg_immutable`). (3) Ghi rõ payload không phải JSON luôn ở Garage. (4) Sửa hai tên khóa tham số theo FRS. (5) Cửa sổ khử trùng inbox DLQ theo `18.dlq.dedup-window-days`. (6) Bảng kho lần chạy Spring Batch. (7) Cho phép `ph18_worker` cập nhật nhịp sống và điểm dừng ở bảng trạng thái của worker. Đã hấp thụ ở 0.2: cả bảy việc (cột `replay_mode`, `occurrence_count`, ghi chú payload không phải JSON, tên khóa, cửa sổ khử trùng, schema `ph18_batch`, cột `heartbeat_at`, `checkpoint` cho vai worker) |
| D02-03-PH18 FRS | (1) Thêm API lấy nội dung phát lại theo `payloadRef` (§4.11) vào §9.4. (2) Ghi tiêu đề `X-Datahub-Migration` và yêu cầu API nhập của đích trả băm chuẩn tắc (FR-18-064). (3) Thống nhất thời hạn giữ topic DLQ với ADR-181 (Q18-21). (4) Ghi ba cờ `ff.ops.*` của §9.4. Đã hấp thụ ở 0.2: API-18-188, FR-18-062 và 064, NFR-18-016 14 ngày, ba cờ ở FRS §8.2 |
| D03-04-PH18 API | Thêm điểm cuối `replay-payloads` ở `openapi-ops.yaml`; mô tả `304` không thân của API-18-029; thêm trường `occurrenceCount` ở chi tiết mục DLQ |
| ADR-181 | Sửa "Kafka giữ 14 ngày" cho khớp FRS hoặc sửa FRS theo ADR sau khi chốt Q18-21; sửa cửa sổ inbox 30 ngày thành tham số |
| D03-01 SAD §4.3 | Bổ sung hai hồ sơ chạy `api`, `worker` của `dh-platform`; ảnh `dh-ops-worker` và CronJob `dh-backup-reporter` ở `dh-batch`; phụ thuộc Valkey của PH-18 |
| D03-09 | (1) §8.5: vai `dh_tenant_restorer` cấp động, danh sách bảng loại trừ, bucket `dh-common-restore`, namespace `dh-restore-*` và NetworkPolicy. (2) `ResourceQuota` của `dh-batch` cho tối đa 3 Job nặng. (3) Service account và Role của `dh-platform-ops-jobs`, `dh-backup-reporter`, từng công cụ worker |
| D03-10 | Thêm cờ phiên `app.restore_mode` vào quy ước biến phiên; quy tắc trigger nghiệp vụ phải cho phép khi cờ bật và người dùng là `dh_tenant_restorer` |
| DDL các phân hệ | Trigger chặn xóa, chặn sửa lịch sử nhận ngoại lệ `app.restore_mode` (Q18-24); bảng nhận chuyển sáp nhập có cột `origin_tenant_id` (Q18-29) |
| Phân hệ đích của di trú (PH-01, 02, 03, 04, 07, 10, 19) | API nhập nhận `dryRun`, `X-Datahub-Migration: true`, khóa lũy đẳng `legacySystem:objectType:legacyKey`, trả băm chuẩn tắc từng bản ghi |
| PH-04, D04-01 CC-CAMEL-05 | Đổi topic `{tenant}.integration.dlq.v1` thành `{tenant}.ops.dlq.v1` và header theo FRS bảng 4.1b; sau đó gỡ bảng đổi tên của `HeaderNormalizer` |
| PH-07, PH-10 | Bỏ bộ đệm 5 phút, dùng `dh-ops-client` làm mới theo sự kiện (≤ 60 giây) |
| PH-03 | Bộ chạm băm phản hồi và tuyến bóng (Q18-25); API đổi trọng số tuyến đồng bộ có xác nhận áp dụng cho cắt chuyển và quay lui (Q18-26) |
| PH-13 | Xem xét luật cảnh báo đề xuất ở §10; nhận `ops.*` vào bảng điều khiển |
| PH-20 | Điểm cuối nội bộ chuyển tenant `SUSPENDED` và `ACTIVE` cho khôi phục, có cờ cho API thiết yếu chỉ đọc; hai phiên đọc và ghi khi chuyển sáp nhập |
| D03-06-00 | Route `/van-hanh/thong-bao`, `/van-hanh/su-co`, `/van-hanh/lich` (brief PH-18 §1) |

: Đề nghị đồng bộ cho tài liệu và phân hệ khác

### 13.7. Câu hỏi mở

Mười câu hỏi dưới đánh số Q18-20…29 theo dải của tập SDD.

> **Câu hỏi mở Q18-20:** Spring Modulith bản dùng với Spring Boot 4 có hỗ trợ module lồng nhau đủ ổn định để `ops` là module cha của tám module con không; nếu không, có chấp nhận tám module phẳng `ops-param`, `ops-dlq`… cùng quy tắc phụ thuộc ở §3.2 không.

> **Câu hỏi mở Q18-21:** Thời hạn giữ topic `{tenant}.ops.dlq.v1` là 7 ngày (FRS NFR-18-016 bản 0.1) hay 14 ngày (ADR-181); con số này quyết định PH-18 được vắng tối đa bao lâu mà không mất bản tin lỗi. Đã chốt ở lượt đồng bộ 0.2: 14 ngày, FRS 0.2 NFR-18-016 đã sửa theo ADR-181.

> **Câu hỏi mở Q18-22:** CronJob `dh-backup-reporter` (mô hình đẩy, quyền chỉ đọc CR sao lưu ở `dh-db` và `velero`) do nhóm PH-18 hay nhóm hạ tầng sở hữu và phát hành; nhóm hạ tầng có đồng ý cấp quyền đọc chéo namespace cho service account này không.

> **Câu hỏi mở Q18-23:** Danh sách bảng không thay khi khôi phục tenant gồm `outbox_event`, `inbox_event` của mọi schema, schema kiểm toán PH-13, bảng khôi phục của PH-18; còn cần loại thêm bảng nào (bảng ShedLock, bảng engine Flowable của PH-11, bảng chỉ mục vector của PH-17) và ai xác nhận cho từng phân hệ.

> **Câu hỏi mở Q18-24:** Có chấp nhận một vai `dh_tenant_restorer` có DML trên schema của mọi phân hệ (cấp động, chỉ trong cửa sổ khôi phục) và cờ phiên `app.restore_mode` làm ngoại lệ cho trigger chặn xóa, chặn sửa lịch sử của mọi phân hệ không; nếu không, mỗi phân hệ phải cung cấp thủ tục `SECURITY DEFINER` thay dữ liệu của tenant.

> **Câu hỏi mở Q18-25:** Bộ chạm tính băm phản hồi hệ cũ ở APISIX và tuyến bóng phía Datahub thuộc PH-03 hay PH-18; phương thức không lũy đẳng (`POST` tạo hồ sơ) có được nhân bản khi luồng đích chưa có chế độ bóng không gọi HTTT thật không.

> **Câu hỏi mở Q18-26:** PH-03 cung cấp API nội bộ nào (mã API-03) để đổi trọng số tuyến và xác nhận đã áp dụng trong vài giây; nếu đổi tuyến chỉ đi qua GitOps thì chỉ tiêu quay lui 15 phút (NFR-18-015) có còn đạt không.

> **Câu hỏi mở Q18-27:** Máy chủ thư của tỉnh chuyển thư DSN về PH-18 bằng cách nào (hộp nhận nội bộ đọc bằng IMAP, hay bộ chuyển gọi API-18-106); SMS gateway của tỉnh có báo nhận theo REST không và định dạng nào.

> **Câu hỏi mở Q18-28:** `dh-runtime` (Camel Quarkus) cần bản `dh-ops-client` không phụ thuộc Spring; nhóm PH-04 nhận bảo trì lớp kết dính Quarkus hay PH-18 giữ; và mỗi bản sao giữ một nhóm tiêu thụ riêng cho sự kiện tham số có chấp nhận được về tải metadata Kafka ở quy mô 34 tenant không.

> **Câu hỏi mở Q18-29:** Chuyển sáp nhập ghi thẳng schema phân hệ đích bằng hai phiên tenant (theo hợp đồng PH-20) hay phải đi qua API nhập như di trú hệ cũ; nếu ghi thẳng thì phân hệ nào chưa có cột `origin_tenant_id` và ai thêm.

## Lịch sử phiên bản

| Phiên bản | Ngày | Người | Nội dung |
|---|---|---|---|
| 0.3 | 27/11/2026 | Nhóm viết tài liệu (Claude) | Đồng bộ chéo cuối: PH-18 là chủ topic DLQ, merge-transfers qua apisix-int và lượt bù DELTA, route `/viec-cua-toi`, phân vùng và dọn lưu giữ của phân hệ khác |
| 0.2 | 27/11/2026 | Nhóm viết tài liệu (Claude) | Đồng bộ nội bộ PH-18: đánh dấu chín điểm lệch §13.5 và bốn dòng đề nghị §13.6 đã hấp thụ ở FRS, CSDL, API 0.2 và ADR-181; dùng API-18-188 cho nguồn `KAFKA_TOPIC`; Q18-21 chốt 14 ngày |
| 0.1 | 27/11/2026 | Nhóm viết tài liệu (Claude) | Bản đầu theo K-SDD và K-TRINH-BAY: cấu trúc package `vn.datahub.platform.ops` tám module và `common`, thư viện `dh-ops-client`, mô hình miền, 25 thành phần với khối đặc tả 10 mục, worker `dh-ops-worker` ba công cụ, mười lăm sơ đồ trình tự, bốn sơ đồ trạng thái, outbox và lũy đẳng, đa tenant, bảo mật, quan sát `dh_ops_*`, triển khai, kiểm thử, mười điểm lệch, đề nghị đồng bộ, câu hỏi mở Q18-20…29 |

: Lịch sử phiên bản
