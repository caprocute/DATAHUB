# language: vi
# Sinh tự động từ D05-02-PH02 bằng ph02/tools/gen_gherkin.py; không sửa tay.
@PH-02 @TS-02-19
Tính năng: TS-02-19 · Đồng bộ danh mục lên Nền tảng quốc gia

  @TC-02-060 @P1 @Dương @Âm
  Kịch bản: TC-02-060 Đồng bộ ngay, theo dõi, thử lại bản ghi bị từ chối
    # Truy vết: FR-02-053, 054 · API-02-069, 070, 071, 072 · UI-02-12 · UC-02-29, 30 · BR-02-009 · ERR-02-044, 035, 034, 014 · EVT-02-14.
    Biết A-DATDAI `NATIONAL` đã `PUBLISHED`, API `TENANT`; M-NSP; U-T68-TO, U-T68-SV1.
    Khi `POST /national-sync/runs`; chạy lần hai khi lần một chưa xong; SV1 chạy.
    Và M-NSP trả `422` cho một bản ghi; `GET /national-sync/records`; `:resend` sau khi sửa.
    Và đồng bộ API `TENANT`.
    Thì `202`, lần hai `409` ERR-02-035, SV1 403-PQ; bản ghi `REJECTED` hiện lý do, gửi lại thành `SYNCED`; API `TENANT` `409` ERR-02-044.

  @TC-02-061 @P2 @Biên
  Kịch bản: TC-02-061 Quá `02.sync.overdue-days` phát cảnh báo tuân thủ
    # Truy vết: FR-02-054, 053 · API-02-070 · UI-02-12 · BR-02-009 · NFR-02-014, 019.
    Biết M-NSP ngừng; `02.sync.overdue-days` = 7.
    Khi đẩy đồng hồ 7 ngày rồi 8 ngày; `GET /national-sync/summary`.
    Thì ngày 7 chưa cảnh báo; ngày 8 `catalog_national_sync_overdue_total` tăng, thẻ "Quá hạn" ở UI-02-12.

  @TC-02-131 @P1 @Âm
  Kịch bản: TC-02-131 Đồng bộ quốc gia: API chưa đủ điều kiện, đang chạy, Nền tảng quốc gia sự cố, sai quyền
    # Truy vết: FR-02-053, 054 · API-02-069, 071 · UI-02-12 · UC-02-29, 30 · BR-02-009 · ERR-02-044, 035, 034, 014.
    Biết A-DRAFT (chưa công bố); A-DATDAI `NATIONAL`; bản ghi đồng bộ `SY-1` ở trạng thái `REJECTED`; M-NSP; U-T68-TO, U-T68-SV1.
    Khi U-T68-TO `POST /national-sync/runs` với phạm vi gồm A-DRAFT.
    Và gọi `runs` hai lần liền nhau; rồi `POST /national-sync/records/SY-1:resend` khi lần chạy còn đang chạy.
    Và đặt M-NSP không phản hồi rồi `runs`.
    Và U-T68-SV1 gọi `runs`.
    Thì bước 1: `409` ERR-02-044 nêu API chưa đủ điều kiện. Bước 2: `202` rồi `409` ERR-02-035 cho cả lệnh chạy thứ hai và lệnh gửi lại. Bước 3: `503` ERR-02-034 khi PH-14 không nhận lệnh; các bản ghi đang chờ chuyển `RETRY` theo lịch và không bao giờ bị đánh dấu "đã đồng bộ". Bước 4: `403` ERR-02-014.

  @TC-02-132 @P2 @Âm @Dương
  Kịch bản: TC-02-132 Bản ghi đồng bộ: lọc, cách ly tenant, gửi lại bản ghi của tenant khác
    # Truy vết: FR-02-054 · API-02-070, 071, 072 · UI-02-12 · UC-02-30 · BR-02-033 · ERR-02-003, 001, 014.
    Biết 30 bản ghi đồng bộ ở T68 (ba trạng thái), 5 ở T01; U-T68-VW, U-T68-TO.
    Khi `GET /national-sync/records?status=REJECTED&size=10`, rồi `status=KHONG-CO`.
    Và `GET /national-sync/summary`; đối chiếu số trên UI-02-12.
    Và U-T68-TO `:resend` bản ghi của T01; U-T68-VW `:resend` bản ghi của T68.
    Thì bước 1: lọc đúng; giá trị sai `400` ERR-02-003. Bước 2: tổng khớp UI. Bước 3: `404` ERR-02-001 cùng thân với mã không tồn tại; VW `403` ERR-02-014.
