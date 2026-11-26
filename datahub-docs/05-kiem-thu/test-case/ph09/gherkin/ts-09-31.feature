# language: vi
# Sinh tự động từ D05-02-PH09 bằng ph09/tools/gen_gherkin.py; không sửa tay.
@PH-09 @TS-09-31
Tính năng: TS-09-31 · Mẫu và bản ghi sự đồng ý

  @TC-09-106 @P1 @Dương @Âm
  Kịch bản: TC-09-106 Tạo mẫu, duyệt, sửa mẫu đã có người đồng ý phải tạo phiên bản mới
    # Truy vết: FR-09-052 · API-09-183, 185, 186, 184 · ERR-09-069, 070, 005 · BR-09-049
    # Mục đích: Chứng minh mẫu nêu mục đích cụ thể, dữ liệu, cách rút và không sửa tại chỗ.
    Biết T90; U-T90-SO (soạn), U-T90-DA1; mẫu `CNS-TIENICH` đã có 3 người đồng ý.
    Khi SO tạo mẫu thiếu cách rút lại.
    Và SO tạo mẫu đủ; gửi duyệt; tự duyệt; DA1 duyệt.
    Và SO `PUT /consent-templates/CNS-TIENICH/versions/1` khi đã có người đồng ý.
    Thì bước 1 `422` ERR-09-069. Bước 2 tự duyệt `403` ERR-09-005, DA1 `ACTIVE`. Bước 3 `409` ERR-09-070 "Mẫu đã có người đồng ý. Tạo phiên bản mới thay vì sửa."

  @TC-09-107 @P1 @Dương @Âm
  Kịch bản: TC-09-107 Ghi nhận đồng ý đủ bằng chứng, rút trong 60 giây, rút lần hai
    # Truy vết: FR-09-053, 054 · API-09-188, 189, 191, 234 · ERR-09-071, 072 · BR-09-050, 051 · EVT-09-27, 28
    # Mục đích: Chứng minh bằng chứng đủ trường và rút đồng ý hiệu lực ≤ 60 giây (đệm `09.consent.cache-seconds` tối đa 60).
    Biết T90; S-T90-CONSENT; mẫu `CNS-TIENICH` v1 `ACTIVE`; chủ thể CC-01 (băm).
    Khi S-T90-CONSENT `POST /consents` thiếu kênh hoặc phiên bản mẫu.
    Và gửi đủ (băm chủ thể, mẫu và phiên bản, băm nội dung hiển thị, thời điểm, kênh `WEB`, người ghi).
    Và `POST /privacy/v1/consents:check`; rút `:withdraw`; kiểm lại sau ≤ 60 giây; rút lần hai.
    Thì bước 1 `422` ERR-09-071. Bước 2 `201` `GIVEN`, EVT: `consent.given`. Bước 3 trạng thái `GIVEN` rồi `WITHDRAWN` ≤ 60 giây sau khi rút, EVT: `consent.withdrawn`; rút lần hai `409` ERR-09-072. Xử lý trước đó không bị vô hiệu.

  @TC-09-108 @P2 @Âm
  Kịch bản: TC-09-108 Đồng ý chỉ cho tiện ích không bắt buộc
    # Truy vết: FR-09-052, 054 · API-09-234 · BR-09-049 · ERR-09-024
    # Mục đích: Chứng minh không dùng đồng ý làm điều kiện thực hiện thủ tục hành chính.
    Biết T90; hoạt động bắt buộc theo luật; hoạt động tiện ích không bắt buộc.
    Khi gắn mẫu đồng ý vào hoạt động bắt buộc theo luật.
    Và tra `consents:check` cho tiện ích không bắt buộc khi chưa có đồng ý.
    Thì bước 1 `422` ERR-09-024. Bước 2 `GIVEN = false`; thủ tục chính vẫn thực hiện được.
