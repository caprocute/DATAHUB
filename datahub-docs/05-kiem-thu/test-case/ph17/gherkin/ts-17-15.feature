# language: vi
# Sinh tự động từ D05-02-PH17 bằng ph17/tools/gen_gherkin.py; không sửa tay.
@PH-17 @TS-17-15
Tính năng: TS-17-15 · Tải lên tài liệu hướng dẫn nội bộ và duyệt trước khi lập chỉ mục

  @TC-17-047 @P1 @Dương
  Kịch bản: TC-17-047 Tải lên PDF, gửi duyệt, duyệt bốn mắt, lập chỉ mục
    # Truy vết: FR-17-020 · API-17-081, 083, 084, 085 · BR-17-030 · EVT-17-17 · UI-17-09
    # Mục đích: Chứng minh luồng `UPLOADED` đến `APPROVED` và đoạn chỉ xuất hiện sau duyệt.
    Biết T90; PDF 2 MB hướng dẫn vận hành tổng hợp (không DLCN), `dataClass` khai `INTERNAL`; U-T90-DS (tải), U-T90-TA1 (duyệt).
    Khi DS `POST /knowledge/uploads` với tệp và mức khai.
    Và IE `POST /search` hỏi nội dung tệp.
    Và DS `:submit`.
    Và TA1 `:approve`.
    Và IE `POST /search` lại sau 120 giây.
    Thì bước 1 `201` `UPLOADED`, tệp lưu ở kho (DD-12). Bước 2 không có kết quả. Bước 3 `PENDING_APPROVAL`, EVT: `assist.upload.state-changed`. Bước 4 `APPROVED`, bắt đầu lập chỉ mục, KT: có. Bước 5 có đoạn với trích dẫn tới tài liệu.

  @TC-17-048 @P1 @Âm @Bảo_mật
  Kịch bản: TC-17-048 Sai định dạng, vượt dung lượng, có mã độc hoặc DLCN, người duyệt trùng
    # Truy vết: FR-17-020 · API-17-081, 085, 086 · BR-17-030 · ERR-17-045, 046, 047, 005
    # Mục đích: Chứng minh các từ chối ở bước nhận tệp và duyệt.
    Biết T90 `17.upload.max-mb = 20`; tệp `.exe`; PDF 25 MB; tệp EICAR thử; DOCX có 5 số CCCD giả đúng kiểm tổng.
    Khi DS tải tệp `.exe`.
    Và DS tải PDF 25 MB.
    Và DS tải tệp EICAR.
    Và DS tải DOCX có CCCD giả.
    Và DS tải tệp hợp lệ, `:submit`, rồi DS `:approve` chính tài liệu mình tải.
    Và TA1 `:reject` không và có lý do.
    Và DS gọi `:reindex` khi tài liệu đang lập chỉ mục.
    Thì bước 1 và 2 `422` ERR-17-045. Bước 3 và 4 `422` ERR-17-046, không lưu tệp. Bước 5 `403` ERR-17-005. Bước 6 lần đầu `422` ERR-17-007, lần sau `REJECTED`. Bước 7 `409` ERR-17-047.

  @TC-17-049 @P2 @Dương
  Kịch bản: TC-17-049 Ngừng tài liệu đã duyệt xóa khỏi chỉ mục
    # Truy vết: FR-17-020, 019 · API-17-087 · BR-17-029, 030 · EVT-17-17, 16
    # Mục đích: Chứng minh `:retire` xóa đoạn và truy hồi không còn trả tài liệu.
    Biết tài liệu đã `APPROVED` và chỉ mục xong; U-T90-DS.
    Khi DS `POST /knowledge/uploads/{id}:retire`.
    Và IE `POST /search` hỏi nội dung tài liệu.
    Thì bước 1 `200` `STOPPED`, đoạn xóa ≤ 5 phút, EVT cả hai. Bước 2 không còn trích dẫn tài liệu.
