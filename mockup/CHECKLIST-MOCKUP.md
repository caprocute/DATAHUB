# Checklist dựng mockup — Giai đoạn 6 (đợt hoàn thiện)

> **Mục đích**: chia việc dựng 63 màn còn lại thành **11 gói độc lập**, mỗi gói giao cho một agent chạy song song.
> **Nguyên tắc**: mỗi gói = đúng **một tệp HTML**, không gói nào sửa tệp của gói khác → chạy song song không xung đột.
> Đặc tả nguồn: mục **M6** của SRS tương ứng trong `docs/07-srs/`.

**Trạng thái**: **11/11 gói đã xong** · 124/124 màn đã dựng. Còn lại: phần D (việc chung chạm tệp dùng chung).

---

## A. Quy tắc chung — mọi agent PHẢI đọc trước khi bắt đầu

### A.1. Ranh giới tệp (điều kiện để chạy song song)

| Được phép | Không được phép |
|---|---|
| Sửa **duy nhất** tệp HTML của gói mình | Sửa `js/app.js`, `css/app.css`, `js/theme.js` |
| Đọc bất kỳ tệp nào để tham khảo | Sửa tệp HTML của gói khác |
| Thêm `<style>` cục bộ trong tệp mình **nếu thật sự cần** | Thêm thư viện ngoài, CDN, ảnh nhị phân |

**Vì sao cấm sửa `app.js` / `app.css`**: đây là tệp dùng chung, nhiều agent sửa cùng lúc sẽ xung đột. Sidebar đã có đủ mục cho mọi phân hệ trong đợt này — không cần đụng vào. Nếu thiếu class CSS, dùng `<style>` cục bộ và **ghi lại vào phần Ghi chú của gói** để gộp vào design system sau.

### A.2. Bộ khung bắt buộc của mỗi trang

Sao chép nguyên khối này, chỉ đổi phần in đậm:

```html
<!DOCTYPE html>
<html lang="vi">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>TIÊU ĐỀ — LGSP</title>
<link rel="stylesheet" href="../css/app.css">
<script src="../js/theme.js"></script>
<script>window.LGSP_PAGE = { id: 'ID_TRANG', title: 'TIÊU ĐỀ', crumbs: [
  { text: 'Trang chủ', href: 'index.html' }, { text: 'TIÊU ĐỀ' }] };</script>
</head>
<body>
<!-- nội dung -->
<script src="../js/app.js"></script>
</body>
</html>
```

`ID_TRANG` phải **khớp đúng** `id` trong mảng `NAV` của `js/app.js` để mục sidebar sáng lên đúng chỗ. ID của từng gói ghi trong bảng bên dưới.

### A.3. Khối chú thích đầu trang

Ngay sau `<body>`, đặt khối `mock-note` liệt kê các màn UI mà trang hiện thực + liên kết chéo sang trang liên quan:

```html
<div class="mock-note">
  <strong>PH-XX — Tên phân hệ.</strong>
  Minh họa các màn <span class="tag-ph">UI-XX-01</span> tên màn,
  <span class="tag-ph">UI-XX-02</span> tên màn — đặc tả tại mục M6 của
  <a href="../../docs/07-srs/SRS-PH-XX-ten.md">SRS PH-XX</a>.
  Liên kết chéo: <a href="trang-lien-quan.html">Tên trang</a>.
</div>
```

### A.4. Cấu trúc nhiều màn trong một trang

SRS đã chỉ định sẵn màn nào là tab nào (xem cột "Vị trí" của từng gói). Dùng đúng cơ chế tab của khung:

```html
<div class="card mb-6">
  <div class="tabs" data-tabs-group="main" style="margin:0;padding:0 var(--sp-5)">
    <button class="tab is-active" data-tab="tab1">Nhãn 1</button>
    <button class="tab" data-tab="tab2">Nhãn 2 <span class="tab__count">12</span></button>
  </div>
  <div class="card__body" data-tab-panel="tab1" data-tabs-group="main">…</div>
  <div class="card__body hidden" data-tab-panel="tab2" data-tabs-group="main">…</div>
</div>
```

`initTabs()` trong `app.js` tự gắn sự kiện — không cần viết JS riêng. Trang có thể mở sẵn một tab qua neo URL (`trang.html#tab2`) nhờ `initTabHash()`.

### A.5. Lớp CSS có sẵn — dùng lại, đừng tự chế

| Nhóm | Lớp |
|---|---|
| Bố cục | `.grid` `.grid--2` `.grid--3` `.grid--4` `.grid--main` `.grid--sidebar` `.row` `.row--between` `.row--wrap` `.col` |
| Thẻ / khối | `.card` `.card__head` `.card__title` `.card__sub` `.card__body` `.card__foot` `.card__actions` `.panel` `.panel__head` `.panel__body` |
| Bảng | `.table` `.table-wrap` `.table-wrap--wide` `.table__actions` `.table__num` |
| Chỉ số | `.stat` `.stat__label` `.stat__value` `.stat__delta` (`--up` `--down` `--flat`) `.stat__meta` |
| Nhãn trạng thái | `.badge` (`--ok` `--warn` `--err` `--info` `--muted` `--plain`) `.tag-ph` |
| Thông báo | `.alert` (`--ok` `--warn` `--err` `--info`) `.alert__icon` `.alert__title` |
| Biểu mẫu | `.field` `.field__label` `.field__hint` `.field__err` `.field__req` `.input` `.input--mono` `.select` `.textarea` `.check` `.search` `.input-group` |
| Nút | `.btn` (`--primary` `--danger` `--ghost` `--sm` `--block`) `.btn-group` |
| Tiến trình | `.bar` `.bar__fill` (`--ok` `--warn` `--err`) `.steps` `.step` `.step__num` `.step__bar` `.step__label` |
| Dòng thời gian | `.timeline` `.tl-item` (`--ok` `--warn` `--err`) `.tl-time` `.tl-title` `.tl-desc` |
| Sơ đồ luồng | `.flow` `.flow__node` (`--start` `--end` `--err`) `.flow__arrow` `.flow__node-icon` `.flow__node-label` `.flow__node-sub` |
| Thác thời gian | `.wf` `.wf__name` `.wf__track` `.wf__bar` (`--warn` `--err`) `.wf__ms` |
| Phát hiện lỗi | `.finding` `.finding__mark` (`--warn` `--err`) `.finding__title` `.finding__text` `.finding__meta` |
| So sánh | `.diff` `.diff__col-label` `.dl` `.divider` `.code` |
| Chữ | `.t-muted` `.t-small` `.t-mono` `.t-primary` `.text-right` `.mb-0` `.mt-0` |

Khoảng cách dùng biến `var(--sp-1…10)`, màu dùng biến token — **không hardcode mã màu hex**, vì trang phải chạy đúng ở cả chế độ sáng và tối.

### A.6. Chất lượng nội dung

- **Dữ liệu mẫu phải thật đúng ngữ cảnh Việt Nam**: tên cơ quan (Sở TT&TT, Văn phòng UBND tỉnh, Sở Tư pháp…), mã hệ thống kiểu `HE_THONG_MOT_CUA`, số liệu hợp lý. Không dùng "Lorem ipsum", không dùng "Foo/Bar".
- **Mỗi màn phải có trạng thái rỗng hoặc lỗi ở đâu đó** nếu đặc tả M6 nêu — mockup chỉ có "trạng thái đẹp" thì không kiểm chứng được thiết kế.
- **Nút bấm demo**: gắn `data-demo="Mô tả hành động"` — `initDemoActions()` sẽ hiện thông báo thay vì không làm gì.
- **Bảng dài**: bọc trong `.table-wrap` để cuộn ngang được trên màn hẹp.
- Số lượng bản ghi mẫu mỗi bảng: **5–12 dòng** là đủ; nhiều hơn chỉ làm nặng tệp.

### A.7. Tiêu chí hoàn thành một gói

1. Mọi mã `UI-XX-nn` trong bảng của gói đều có phần tương ứng, đánh dấu bằng comment `<!-- ===== UI-XX-nn: tên màn ===== -->`.
2. Mở tệp bằng trình duyệt: sidebar sáng đúng mục, breadcrumb đúng, chuyển tab hoạt động.
3. Thử **cả chế độ sáng và tối** (nút chuyển ở đầu trang) — không có chữ chìm vào nền.
4. Thu hẹp cửa sổ còn ~900px: không có tràn ngang ngoài `.table-wrap`.
5. Mọi liên kết trong trang trỏ tới tệp có thật.

---

## B. Danh sách gói

> Cột **Vị trí** lấy nguyên từ mục M6 của SRS — không tự đổi cấu trúc tab.

### Gói 1 — PH-03 Cổng tiếp nhận · `pages/gateway.html` · id `gateway`

SRS: [SRS-PH-03-gateway.md](../docs/07-srs/SRS-PH-03-gateway.md) — đặc tả chi tiết ở §6.2, §6.3, §6.4.

| Màn | Tên | Vị trí |
|---|---|---|
| UI-03-01 | Tổng quan lưu lượng | Tab mặc định |
| UI-03-02 | Cấu hình route Gateway | Tab *Route* |
| UI-03-03 | Hạn mức và hạn ngạch | Tab *Hạn mức* |
| UI-03-04 | Nhật ký WAF và ngoại lệ | Tab *Bảo vệ* |
| UI-03-05 | Sức khỏe hạ nguồn | Tab *Hạ nguồn* |

Liên kết chéo: `catalog.html` (dịch vụ sau gateway), `monitoring.html` (chỉ số chi tiết).
Gợi ý: dùng `.stat` cho RPS/độ trễ/tỷ lệ 4xx-5xx, `.wf` cho phân bố độ trễ, `.badge--err` cho route bị chặn.

### Gói 2 — PH-05 Adapter kết nối · `pages/adapters.html` · id `adapters`

SRS: [SRS-PH-05-adapter.md](../docs/07-srs/SRS-PH-05-adapter.md) — chi tiết §6.2–6.5.

| Màn | Tên | Vị trí |
|---|---|---|
| UI-05-01 | Danh sách adapter và sức khỏe kết nối | Tab mặc định |
| UI-05-02 | Đăng ký và cấu hình adapter | Tab *Cấu hình* |
| UI-05-03 | Kiểm thử kết nối | Tab *Kiểm thử* |
| UI-05-04 | Trình ánh xạ trường | Tab *Ánh xạ* |
| UI-05-05 | Giám sát CDC | Tab *CDC* |
| UI-05-06 | Thư viện Kamelet | Tab *Kamelet* |

Liên kết chéo: `routes.html` (luồng dùng adapter), `events.html` (CDC đẩy vào Kafka).
Gợi ý: UI-05-04 dùng bố cục hai cột `.diff` (trường nguồn ↔ trường đích).

### Gói 3 — PH-07 Danh mục dùng chung · `pages/reference.html` · id `reference`

SRS: [SRS-PH-07-rdm.md](../docs/07-srs/SRS-PH-07-rdm.md) — chi tiết §6.2–6.6.

| Màn | Tên | Vị trí |
|---|---|---|
| UI-07-01 | Danh sách danh mục dùng chung | Tab mặc định |
| UI-07-02 | Quản lý mục và phiên bản | Tab *Mục* |
| UI-07-03 | So sánh phiên bản và đánh giá tác động | Tab *So sánh* |
| UI-07-04 | Đồng bộ danh mục quốc gia | Tab *Đồng bộ* |
| UI-07-05 | Trình ánh xạ từ điển quốc gia | Tab *Ánh xạ* |
| UI-07-06 | Báo cáo độ phủ ánh xạ | Tab *Độ phủ* |

Liên kết chéo: `national.html` (nguồn danh mục QG), `mdm.html` (dữ liệu chủ dùng danh mục).
Dữ liệu mẫu nên dùng danh mục có thật: đơn vị hành chính, dân tộc, tôn giáo, nghề nghiệp.

### Gói 4 — PH-08 Chất lượng dữ liệu · `pages/dq.html` · id `dq`

SRS: [SRS-PH-08-dq.md](../docs/07-srs/SRS-PH-08-dq.md) — chi tiết §6.2–6.6.

| Màn | Tên | Vị trí |
|---|---|---|
| UI-08-01 | Tổng quan chất lượng theo miền | Tab mặc định |
| UI-08-02 | Quản lý luật kiểm tra | Tab *Luật* |
| UI-08-03 | Trọng số và ngưỡng | Tab *Trọng số* |
| UI-08-04 | Job quét & tiến độ | Tab *Quét* |
| UI-08-05 | Bản ghi lỗi (findings) | Tab *Lỗi* |
| UI-08-06 | Báo cáo & so kỳ | Tab *Báo cáo* |
| UI-08-07 | Ticket khắc phục | Tab *Khắc phục* |

Liên kết chéo: `mdm.html`, `reference.html`.
Sáu chiều chất lượng (đầy đủ, chính xác, nhất quán, hợp lệ, duy nhất, kịp thời) nên hiện bằng `.bar` có `.bar__fill--warn/--err` theo ngưỡng.

### Gói 5 — PH-10 Truyền thông sự kiện · `pages/events.html` · id `events`

SRS: [SRS-PH-10-event.md](../docs/07-srs/SRS-PH-10-event.md).

| Màn | Tên | Vị trí |
|---|---|---|
| UI-10-01 | Tổng quan cụm sự kiện | Tab mặc định |
| UI-10-02 | Quản lý chủ đề | Tab *Chủ đề* |
| UI-10-03 | Theo dõi độ trễ tiêu thụ | Tab *Độ trễ* |
| UI-10-04 | Quản lý lược đồ sự kiện | Tab *Lược đồ* |
| UI-10-05 | Giám sát CDC | Tab *CDC* |
| UI-10-06 | Phát lại sự kiện | Tab *Phát lại* |

Liên kết chéo: `dlq.html` (bản tin lỗi), `adapters.html` (nguồn CDC).
Chủ đề đặt tên theo quy ước `{miền}.{thực thể}.{phiên bản}` — xem [SRS-00 §6](../docs/07-srs/SRS-00-data-dictionary.md#6-quy-ước-đặt-tên).

### Gói 6 — PH-11 Quy trình nghiệp vụ · `pages/bpm.html` · id `bpm`

SRS: [SRS-PH-11-bpm.md](../docs/07-srs/SRS-PH-11-bpm.md).

| Màn | Tên | Vị trí |
|---|---|---|
| UI-11-01 | Danh sách định nghĩa & phiên bản BPMN | Tab mặc định |
| UI-11-02 | Đăng ký ánh xạ service task & bù trừ | Tab *Ánh xạ* |
| UI-11-03 | Danh sách user task (hàng đợi việc) | Tab *Việc của tôi* |
| UI-11-04 | Chi tiết task & form hoàn thành | Trong tab *Việc của tôi* (khối chi tiết) |
| UI-11-05 | Sơ đồ tiến độ instance | Tab *Tiến độ* |
| UI-11-06 | Giám sát tắc nghẽn & nhật ký Saga | Tab *Giám sát* |

Liên kết chéo: `routes.html` (Camel gọi service task), `dlq.html` (lỗi bù trừ).
Sidebar đã có mục "Quy trình nghiệp vụ" với `badge: 8` — nên có 8 việc chờ trong UI-11-03 cho khớp.
UI-11-05 dùng `.flow` để vẽ tiến độ các chặng BPMN.

### Gói 7 — PH-12 + SRS-19 Định danh & phân quyền · `pages/iam.html` · id `iam`

SRS: [SRS-PH-12-iam.md](../docs/07-srs/SRS-PH-12-iam.md) và [SRS-19-rbac-matrix.md](../docs/07-srs/SRS-19-rbac-matrix.md) §6.1–6.4.

**Gói lớn nhất — 10 màn.** Nếu cần chia đôi, tách theo ranh giới: agent A làm 6 tab PH-12, agent B làm 4 tab SRS-19; **nhưng hai agent không được sửa cùng lúc**, phải làm tuần tự.

| Màn | Tên | Vị trí |
|---|---|---|
| UI-12-02 | Quản lý người dùng | Tab *Người dùng* (mặc định) |
| UI-12-03 | Quản lý danh tính hệ thống | Tab *Hệ thống* |
| UI-12-04 | Vai trò và phạm vi quyền | Tab *Vai trò* |
| UI-12-05 | Soạn thảo và duyệt chính sách | Tab *Chính sách* |
| UI-12-06 | Tra cứu nhật ký quyết định | Tab *Nhật ký* |
| UI-12-07 | Cảnh báo an ninh | Tab *Cảnh báo* |
| UI-19-01 | Ma trận phân quyền Role × Permission × PH | Tab *Ma trận* |
| UI-19-02 | So lệch SRS ↔ runtime | Tab *So lệch* |
| UI-19-03 | Catalog vai trò / permission | Tab *Catalog RBAC* |
| UI-19-04 | Lịch sử phiên bản ma trận | Tab *Phiên bản ma trận* |

Vai trò dùng **đúng mã chuẩn** trong SRS-19 — `INTEGRATION_REVIEWER` (không dùng alias `INTEGRATION_APPROVER`).
UI-19-01 là bảng ma trận rộng → bắt buộc `.table-wrap--wide`; ô giao dùng `.badge--ok` (có quyền) / `.badge--muted` (không) / `.badge--warn` (kế thừa).
UI-12-01 (đăng nhập) **đã có** tại `login.html` — không dựng lại, chỉ liên kết tới.

### Gói 8 — PH-14 Kết nối quốc gia · `pages/national.html` · id `national`

SRS: [SRS-PH-14-national.md](../docs/07-srs/SRS-PH-14-national.md).

| Màn | Tên | Vị trí |
|---|---|---|
| UI-14-01 | Tổng quan kết nối quốc gia | Tab mặc định |
| UI-14-02 | Cấu hình định tuyến NDXP/NDOP | Tab *Định tuyến* |
| UI-14-03 | Theo dõi hạn mức truy vấn | Tab *Hạn mức* |
| UI-14-04 | Quản lý chứng thư số | Tab *Chứng thư* |
| UI-14-05 | Tra cứu và đối soát giao dịch | Tab *Giao dịch* |
| UI-14-06 | Trạng thái đồng bộ danh mục | Tab *Đồng bộ* |

Liên kết chéo: `reference.html` (danh mục đồng bộ về), `monitoring.html`.
Nền tảng QG mẫu: NDXP, NDOP, CSDLQG về dân cư, CSDLQG đăng ký doanh nghiệp, CSDL bảo hiểm.
UI-14-04 phải có cảnh báo chứng thư sắp hết hạn (`.alert--warn`).

### Gói 9 — PH-15 Cổng nhà phát triển · `pages/portal.html` · id `portal`

SRS: [SRS-PH-15-portal.md](../docs/07-srs/SRS-PH-15-portal.md).

| Màn | Tên | Vị trí |
|---|---|---|
| UI-15-01 | Trang chủ cổng nhà phát triển | Đầu trang (không phải tab) |
| UI-15-02 | Danh mục dịch vụ / catalog | Tab *Catalog* |
| UI-15-03 | Chi tiết dịch vụ + OpenAPI | Khối chi tiết trong tab *Catalog* |
| UI-15-04 | Try-it console | Tab *Thử API* |
| UI-15-05 | TechDocs reader | Tab *Tài liệu* |
| UI-15-06 | Nộp hồ sơ kết nạp F-01 | Liên kết sang `onboarding.html` |
| UI-15-07 | Nộp / theo dõi công bố F-02 | Tab *Công bố* |
| UI-15-08 | Tìm kiếm toàn văn | Ô `.search` ở đầu trang |
| UI-15-09 | Bảng điều khiển cá nhân | Tab *Của tôi* |

Liên kết chéo: `catalog.html` (danh mục quản trị — phân biệt rõ: portal là góc nhìn **người dùng**, catalog là góc nhìn **quản trị**), `onboarding.html`.
UI-15-04 dùng `.input--mono` + `.code` cho phần yêu cầu/phản hồi.

### Gói 10 — PH-13 bổ sung 4 tab · `pages/monitoring.html` · id `monitoring`

SRS: [SRS-PH-13-observability.md](../docs/07-srs/SRS-PH-13-observability.md).

**Trang đã có 3 tab** (Tổng quan `UI-13-01`, Tra cứu trace `UI-13-02`, Cảnh báo `UI-13-03`). **Giữ nguyên phần đã có**, chỉ thêm:

| Màn | Tên | Vị trí |
|---|---|---|
| UI-13-04 | Dashboard hoạt động nghiệp vụ | Tab *Nghiệp vụ* (mới) |
| UI-13-05 | Tra cứu nhật ký kiểm toán | Tab *Kiểm toán* (mới) |
| UI-13-06 | Cảnh báo an ninh | Tab *An ninh* (mới) |
| UI-13-07 | Quản lý luật cảnh báo và runbook | Tab *Luật* (mới) |
| UI-04-06 | Trạng thái ngắt mạch (thuộc PH-04) | Khối trong tab *Tổng quan* |

Cập nhật khối `mock-note` đầu trang cho đủ mã màn, và **xóa dòng ghi chú "SRS PH-13 chưa xong"** nếu còn.
UI-13-05 hiển thị bản ghi kiểm toán theo `DD-05` — [SRS-00](../docs/07-srs/SRS-00-data-dictionary.md#dd-05--ban_ghi_kiem_toan-bản-ghi-kiểm-toán): actor, action, resource, subject_id, purpose, decision.

### Gói 11 — PH-01 bổ sung màn bàn giao · `pages/handover.html` (tệp mới) · id `onboarding`

SRS: [SRS-PH-01-onboarding.md](../docs/07-srs/SRS-PH-01-onboarding.md) — `UI-01-07`.

| Màn | Tên | Vị trí |
|---|---|---|
| UI-01-07 | Bàn giao thông tin kết nối | Trang riêng, **không** thêm vào sidebar |

M6 ghi rõ "Trang riêng, không nằm trong menu" → tạo tệp mới `pages/handover.html`, đặt `id: 'onboarding'` để sidebar sáng ở mục Kết nạp.
Nội dung: endpoint được cấp, `clientId`, hướng dẫn lấy secret qua kênh an toàn (**không hiển thị secret trên màn**), chứng thư, hạn mức, đầu mối hỗ trợ, nút tải hồ sơ bàn giao.
Sau khi xong, **báo lại** để thêm liên kết từ `onboarding.html` — tệp đó thuộc phạm vi đã dựng, agent gói 11 không tự sửa.

---

## C. Bảng theo dõi

| Gói | Tệp | Phân hệ | Số màn | Trạng thái | Ngày |
|---|---|---|:-:|:-:|---|
| 1 | `pages/gateway.html` | PH-03 | 5 | `[x]` | 04/08/2026 |
| 2 | `pages/adapters.html` | PH-05 | 6 | `[x]` | 04/08/2026 |
| 3 | `pages/reference.html` | PH-07 | 6 | `[x]` | 04/08/2026 |
| 4 | `pages/dq.html` | PH-08 | 7 | `[x]` | 04/08/2026 |
| 5 | `pages/events.html` | PH-10 | 6 | `[x]` | 04/08/2026 |
| 6 | `pages/bpm.html` | PH-11 | 6 | `[x]` | 2026-08-03 |
| 7 | `pages/iam.html` | PH-12 + SRS-19 | 10 | `[x]` | 2026-08-03 |
| 8 | `pages/national.html` | PH-14 | 6 | `[x]` | 2026-08-03 |
| 9 | `pages/portal.html` | PH-15 | 9 | `[x]` | 2026-08-03 |
| 10 | `pages/monitoring.html` | PH-13 + PH-04 | 5 | `[x]` | 2026-08-03 |
| 11 | `pages/handover.html` | PH-01 | 1 | `[x]` | 2026-08-03 |
| | | **Tổng** | **67** | | |

> 67 = 63 màn chưa dựng + 4 màn đã có của `monitoring.html` được giữ nguyên khi mở rộng.

---

## D. Việc chung — làm SAU khi mọi gói xong

Những việc này **chạm tệp dùng chung**, phải làm tuần tự bởi một người/agent duy nhất:

- [ ] Thêm liên kết từ `onboarding.html` sang `handover.html` (gói 11)
- [ ] Gộp các `<style>` cục bộ mà agent đã thêm vào `css/app.css` nếu dùng lại được
  - [ ] `.finding__mark--ok` — dùng lại ở 3 trang (`adapters.html`, `reference.html`, `events.html`), nên đưa thẳng vào `app.css`
  - [ ] `.kanban*` (`dq.html`) — cân nhắc nếu phân hệ khác cũng cần bảng trạng thái dạng cột
- [ ] Sửa mẫu ở mục A.2/A.4 cho khớp `js/app.js`: `data-panel` / `data-panel-group` (không phải `data-tab-panel` / `data-tabs-group`)
- [ ] Cân nhắc bổ sung tiện ích `.mb-1` vào `app.css` (hiện lề bắt đầu từ `.mb-2`)
- [ ] Cập nhật `index.html` — bảng điều khiển nên trỏ tới các trang mới dựng
- [ ] Chạy lại bộ kiểm liên kết toàn kho
- [ ] Cập nhật `docs/07-srs/CHECKLIST.md` Giai đoạn 6 và mục T-2 của [báo cáo GĐ7](../docs/07-srs/REVIEW-GIAI-DOAN-7.md)
- [ ] Kiểm chứng lần cuối trên trình duyệt: cả chế độ sáng/tối, độ rộng 900px và 1440px

---

## E. Ghi chú của agent

> Mỗi agent ghi lại vào đây: class CSS tự thêm, chỗ đặc tả M6 mơ hồ, quyết định tự ý.

| Gói | Ghi chú |
|---|---|
| 1 | Không thêm class cục bộ. **Lưu ý chung**: mục A.2/A.4 của checklist ghi thuộc tính tab là `data-tab-panel` / `data-tabs-group`, nhưng `js/app.js` (`initTabs`) thực tế đọc `data-panel` / `data-panel-group` — đã dựng theo mã thật. Nên sửa lại mẫu ở A.4 cho khớp. Ngoài ra `app.css` **không có** lớp `.mb-1` (tiện ích lề bắt đầu từ `.mb-2`). |
| 2 | Thêm cục bộ `.finding__mark--ok` (app.css chỉ có `--err`/`--warn`) — dùng cho cột trường CDM đã ánh xạ ở UI-05-04. Gộp vào app.css ở phần D. |
| 3 | Thêm cục bộ `.finding__mark--ok` (như gói 2) cho UI-07-05. Dữ liệu mẫu dùng danh mục có thật: đơn vị hành chính, dân tộc, tôn giáo, nghề nghiệp. |
| 4 | Thêm cục bộ `.kanban*` (bảng trạng thái dạng cột cho UI-08-07) và `.radar6`. **Quyết định tự ý**: M6 nêu "biểu đồ radar 6 chiều" — mockup thay bằng lưới 6 thanh `.bar` vì radar thuần CSS khó đọc và khó bảo đảm tương phản ở cả 2 chế độ; ngữ nghĩa (điểm/ngưỡng/trọng số từng chiều) giữ nguyên. |
| 5 | Thêm cục bộ `.finding__mark--ok` cho UI-10-04. Chủ đề đặt đúng quy ước `{miền}.{thực thể}.{phiên bản}` theo SRS-00 §6. Tab CDC (UI-10-05) làm góc nhìn *từ phía Kafka* và trỏ sang PH-05 để tránh trùng lặp với UI-05-05. |
| 6 | UI-11-04 master-detail trong tab Việc của tôi; compensating node dùng border token (chưa có class riêng) |
| 7 | INTEGRATION_REVIEWER chuẩn; Catalog RBAC có sub-tab; không style cục bộ |
| 8–11 | Theo SRS M6; không đụng app.js/css |
| 11 | Liên kết từ onboarding.html → handover.html để phần D |
