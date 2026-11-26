# language: vi
# Sinh tự động từ D05-02-PH17 bằng ph17/tools/gen_gherkin.py; không sửa tay.
@PH-17 @TS-17-28
Tính năng: TS-17-28 · Soạn, đánh giá và duyệt mẫu chỉ dẫn hệ thống có phiên bản

  @TC-17-091 @P1 @Dương
  Kịch bản: TC-17-091 Soạn phiên bản, đánh giá đạt, gửi duyệt, duyệt, kích hoạt
    # Truy vết: FR-17-049 · API-17-132, 134, 135, 136, 154 · BR-17-064 · EVT-17-20 · UI-17-12
    # Mục đích: Chứng minh vòng đời `DRAFT` đến `ACTIVE` và bản cũ thành `SUPERSEDED`.
    Biết T90; mẫu `PT-SEARCH` có v1 `ACTIVE`; U-T90-SO (soạn), U-T90-TA1 (duyệt); bộ đánh giá `ES-SEARCH-1` và 66 ca đỏ; LLM-MOCK đạt.
    Khi SO `POST /prompt-templates/{id}/versions` soạn v2.
    Và SO chạy `POST /eval-runs` và `POST /redteam-runs` cho v2.
    Và SO `POST /prompt-versions/{v2}:submit`.
    Và TA1 `POST /prompt-versions/{v2}:approve`.
    Và `GET /prompt-templates/{id}`.
    Thì bước 1 `DRAFT`. Bước 2 điểm đạt, 66/66 chặn. Bước 3 `PENDING_APPROVAL`. Bước 4 `200` `ACTIVE`, KT: có, EVT: `assist.prompt.state-changed`. Bước 5 v1 `SUPERSEDED`, đúng một bản `ACTIVE` mỗi (mẫu, năng lực), cấu hình hiệu lực trong ≤ 60 giây.

  @TC-17-092 @P1 @Âm @Bảo_mật
  Kịch bản: TC-17-092 Chỉ dẫn chứa nội dung cấm, chưa đạt cổng, người duyệt trùng người soạn
    # Truy vết: FR-17-049 · API-17-134, 135, 136 · BR-17-064, 065 · ERR-17-005, 071, 072
    # Mục đích: Chứng minh ERR-17-071, 072, 005.
    Biết U-T90-SO, U-T90-TA1; v3 chứa địa chỉ `10.0.0.5` và chuỗi "mat-khau=thu"; v4 chưa chạy đánh giá.
    Khi SO lưu v3.
    Và SO gửi duyệt v4 khi chưa đánh giá.
    Và SO soạn v5 đạt cổng, gửi duyệt rồi SO `:approve` v5.
    Và TA1 `:reject` v5 kèm lý do.
    Thì bước 1 `422` ERR-17-071 nêu lý do (địa chỉ nội bộ, bí mật). Bước 2 `409` ERR-17-072 nêu chưa đạt cổng phát hành. Bước 3 `403` ERR-17-005. Bước 4 `200` `REJECTED`.

  @TC-17-093 @P1 @Âm @Bảo_mật
  Kịch bản: TC-17-093 Ca đỏ lọt chặn kích hoạt chỉ dẫn
    # Truy vết: FR-17-049, 051 · API-17-136, 154, 152 · BR-17-064, 067 · ERR-17-072, 073
    # Mục đích: Chứng minh cổng phát hành đỏ khi một ca đỏ lọt.
    Biết v6 làm LLM-MOCK lọt một ca đỏ (`RT-31`).
    Khi SO chạy `POST /redteam-runs` cho v6, gửi duyệt.
    Và TA1 `:approve` v6.
    Thì bước 1 kết quả 65/66 chặn, cổng đỏ. Bước 2 `409` ERR-17-073 hoặc ERR-17-072 nêu "Ca đỏ RT-31 chưa bị chặn nên không phát hành được", v6 không `ACTIVE`.

  @TC-17-094 @P3 @Dương
  Kịch bản: TC-17-094 So sánh khác biệt hai phiên bản và quay về bản cũ
    # Truy vết: FR-17-049 · API-17-133, 138 · UI-17-12 · EVT-17-20
    # Mục đích: Chứng minh hiển thị khác biệt (UI-17-12) và ngừng phiên bản.
    Biết mẫu `PT-SEARCH` có v1 `SUPERSEDED`, v2 `ACTIVE`; U-T90-SO, U-T90-TA1.
    Khi SO mở UI-17-12, chọn so sánh v1 với v2.
    Và TA1 `POST /prompt-versions/{v2}:retire` rồi kích hoạt lại v1 qua đề nghị mới.
    Thì bước 1 hiển thị khác biệt từng dòng. Bước 2 v2 `RETIRED`; v1 chỉ `ACTIVE` khi qua đánh giá, ca đỏ và duyệt bốn mắt như phiên bản mới.
