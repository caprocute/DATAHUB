# language: vi
# Sinh tự động từ D05-02-PH02 bằng ph02/tools/gen_gherkin.py; không sửa tay.
@PH-02 @TS-02-11
Tính năng: TS-02-11 · Gửi duyệt, duyệt bốn mắt và công bố API

  @TC-02-038 @P1 @Âm
  Kịch bản: TC-02-038 Gửi duyệt thiếu điều kiện
    # Truy vết: FR-02-034 · API-02-042 · BR-02-001, 015, 024 · ERR-02-012, 021, 008, 041.
    Biết ba phiên bản nháp: không gói, không backend, đặc tả lỗi; `02.submit.require-test-deploy` = true, chưa thử TEST.
    Khi gửi duyệt từng phiên bản; gửi duyệt phiên bản chưa thử TEST.
    Thì `409` ERR-02-012 kèm danh sách điều kiện còn thiếu, hoặc `422` ERR-02-021, ERR-02-008; phiên bản vẫn `DRAFT`.

  @TC-02-039 @P1 @Dương
  Kịch bản: TC-02-039 Gửi duyệt, rút lại, duyệt và công bố ra gateway
    # Truy vết: FR-02-034, 035, 036 · API-02-042, 043, 044, 045, 047, 082 · UI-02-02, 10 · UC-02-15, 16 · EVT-02-04, 05 · KT: có (version.publish) · LGC-APIM-004; 006.
    Biết A-DRAFT đủ điều kiện, đã thử TEST; U-T68-SV1, U-T68-CA; M-GW.
    Khi gửi duyệt, rút lại, gửi lại; thử sửa khi `PENDING`.
    Và U-T68-CA `GET /review-requests`, `:approve`.
    Và M-GW xác nhận qua `POST /internal/gateway/apply-acks`.
    Thì sửa khi chờ duyệt `409` ERR-02-038. Duyệt xong phiên bản `PUBLISHED`, EVT: `version.published`, GW: nạp route trong ≤ 30 giây, API xuất hiện trong danh mục.

  @TC-02-040 @P1 @Âm @Bảo @mật
  Kịch bản: TC-02-040 Bốn mắt: người duyệt trùng người gửi hoặc người sửa gần nhất; API `SENSITIVE`
    # Truy vết: FR-02-035 · API-02-045, 046 · BR-02-008 · ERR-02-013, 014.
    Biết U-T68-SV-CA sửa gần nhất đặc tả; API `SENSITIVE` chờ duyệt; U-T68-CA, U-T68-CA2, U-T68-TA.
    Khi U-T68-SV-CA duyệt yêu cầu mình gửi và yêu cầu do mình sửa.
    Và U-T68-CA duyệt API `SENSITIVE` một mình.
    Và bổ sung xác nhận của U-T68-TA khác U-T68-CA; U-T68-CA2 từ chối kèm ý kiến.
    Thì bước 1: `403` ERR-02-013. Bước 2: chưa công bố, thiếu xác nhận TA. Bước 3: công bố được; từ chối có lý do, trả về `DRAFT`.

  @TC-02-041 @P1 @Âm @Biên
  Kịch bản: TC-02-041 Gateway không nhận cấu hình: công bố không hoàn tất
    # Truy vết: FR-02-036 · API-02-047, 082 · BR-02-014 · ERR-02-033, 034.
    Biết M-GW không trả xác nhận quá 60 giây; phiên bản đã được duyệt.
    Khi thực hiện công bố; chờ quá hạn.
    Và bật lại M-GW, thử lại.
    Thì bước 1: `503` ERR-02-033, phiên bản chưa `PUBLISHED`, danh mục không hiển thị, không mất đặc tả. Bước 2: công bố thành công, một lần duy nhất.

  @TC-02-111 @P1 @Âm
  Kịch bản: TC-02-111 Gửi duyệt phiên bản: chặn do đặc tả, phá vỡ giữ số chính, số hiệu không tăng
    # Truy vết: FR-02-034 · API-02-042 · UI-02-02, 04 · UC-02-15 · BR-02-001, 003, 015 · ERR-02-006, 007, 017, 018, 008.
    Biết năm phiên bản nháp có backend, gói đủ: đặc tả F-SPEC-L1; F-SPEC-L2 (lỗi nghiêm trọng); đặc tả đổi kiểu trường nhưng giữ `1.x.x`; số hiệu bằng số hiệu trước; F-SPEC-SECRET.
    Khi `POST …:submit` lần lượt cho từng phiên bản.
    Và lặp lại sau khi sửa đúng từng lỗi.
    Thì bước 1: `422` ERR-02-006 (lớp 1), ERR-02-007 (lớp 2), `409` ERR-02-017 kèm `suggestedVersion`, `422` ERR-02-018, `422` ERR-02-008 (`findings[]` chỉ `ruleId`, `location`, `message`, giá trị bí mật không lặp lại). Không phiên bản nào sang `PENDING`. Bước 2: `202` cho từng phiên bản đã sửa.

  @TC-02-112 @P1 @Âm @Dương
  Kịch bản: TC-02-112 Từ chối yêu cầu duyệt phiên bản và gửi lại
    # Truy vết: FR-02-035 · API-02-042, 044, 046 · UI-02-10 · UC-02-16 · BR-02-008, 028 · ERR-02-041, 011.
    Biết A-DRAFT đủ điều kiện; U-T68-SV1, U-T68-CA, U-T68-CA2, U-T68-VW.
    Khi SV gửi duyệt; U-T68-VW gọi `GET /review-requests`; CA gọi cùng lệnh.
    Và CA gọi `:reject` không lý do; rồi có lý do.
    Và SV `:withdraw` yêu cầu đã bị từ chối.
    Và SV sửa, gửi lại; CA2 duyệt.
    Thì bước 1: danh sách của VW không chứa yêu cầu nào (chỉ người có quyền duyệt thấy yêu cầu chờ mình), danh sách của CA có yêu cầu. Bước 2: `400` ERR-02-041, rồi `200`, phiên bản về `DRAFT`. Bước 3: `409` ERR-02-011. Bước 4: `202` rồi `200`, kiểm toán ghi đủ lượt gửi, từ chối, gửi lại.

  @TC-02-113 @P2 @Biên @Dương
  Kịch bản: TC-02-113 Yêu cầu duyệt quá `02.review.overdue-days` và nhắc
    # Truy vết: FR-02-035 · API-02-044 · UI-02-10 · UC-02-16 · BR-02-028 · EVT-02-16 · NFR-02-015.
    Biết yêu cầu duyệt `RV-1` gửi cách đây 4 ngày 23 giờ, `RV-2` cách đây 5 ngày 1 giờ (đồng hồ giả); `02.review.overdue-days` = 5, `02.review.reminder-days` đặt theo bảng tham số.
    Khi chạy bộ nhắc duyệt.
    Và `GET /review-requests?overdue=true` bằng U-T68-CA.
    Và CA duyệt `RV-2`; chạy lại bộ nhắc.
    Thì `RV-1` chưa gắn nhãn quá hạn; `RV-2` có cảnh báo gửi tới CA và TA đúng một lần và phát đúng một sự kiện EVT-02-16 (`{tenant}.catalog.review.overdue.v1`, khóa phân vùng `reviewRequestId`), UI-02-10 hiện chỉ báo "quá hạn". Sau khi duyệt, không còn nhắc và không phát thêm sự kiện.

  @TC-02-114 @P1 @Biên @Dương
  Kịch bản: TC-02-114 Công bố: lặp lệnh, xác nhận nạp cấu hình bị gửi lại
    # Truy vết: FR-02-036, 059 · API-02-047, 082 · UC-02-16, 35 · BR-02-028 · ERR-02-042.
    Biết yêu cầu duyệt đã duyệt, chờ công bố; S-GW-ACK (scope `catalog:gateway-ack`); M-GW.
    Khi `POST …:publish` hai lần cùng `Idempotency-Key`, cùng thân.
    Và `POST …:publish` cùng khóa, khác thân.
    Và S-GW-ACK gửi `POST /internal/gateway/apply-acks` hai lần cho cùng bản cấu hình.
    Thì bước 1: lần hai trả lại phản hồi cũ, chỉ một lần đẩy cấu hình sang M-GW, một sự kiện công bố. Bước 2: `422` ERR-02-042. Bước 3: cả hai `204`, trạng thái phiên bản `PUBLISHED` một lần, không phát hai thông báo.

  @TC-02-164 @P1 @Âm
  Kịch bản: TC-02-164 Phiên bản đang chờ duyệt bị khóa: mọi lệnh sửa trả `409`
    # Truy vết: FR-02-014, 022, 027, 028, 029, 034, 036 · API-02-016, 018, 027, 028, 029, 034, 035, 036 · UI-02-02 · UC-02-15 · BR-02-008 · ERR-02-038.
    Biết phiên bản A-DRAFT đã `:submit` (trạng thái `PENDING`), có một backend và một gói; U-T68-SV1.
    Khi lần lượt gọi từng operation sửa trên phiên bản: đồng bộ lại đặc tả, sửa API, thêm, sửa, xóa backend, tạo gói, sửa gói, đổi chính sách truy cập.
    Và `:withdraw` rồi gọi lại bộ lệnh trên.
    Thì bước 1: mọi lệnh `409` ERR-02-038, dữ liệu không đổi, không có dòng kiểm toán. Bước 2: sau rút lại phiên bản về `DRAFT`, mọi lệnh sửa thành công.

  @TC-02-167 @P2 @Dương @Âm
  Kịch bản: TC-02-167 Chi tiết yêu cầu duyệt: điều kiện, lịch sử và ETag dùng cho quyết định
    # Truy vết: FR-02-035, 047 · API-02-098, 045 · UI-02-10 · UC-02-16, 24 · BR-02-008 · ERR-02-001, 015.
    Biết yêu cầu duyệt `RV-1` loại `VERSION_PUBLISH` của A-DRAFT đang `PENDING`, có một lần hỏi thêm và một lần trả lời; yêu cầu `RV-T01` của tenant T01; người dùng U-T68-CA, U-T68-SV1, U-T68-VW.
    Khi U-T68-CA gọi `GET /review-requests/{RV-1}`.
    Và U-T68-CA gọi `POST /review-requests/{RV-1}:approve` với `If-Match` lấy từ bước 1.
    Và U-T68-CA gọi lại API-02-098 cho `RV-1` bằng `If-Match` cũ ở lệnh duyệt thứ hai (giả lập người duyệt thứ hai tải chậm).
    Và U-T68-CA gọi API-02-098 với mã của `RV-T01` và với mã không tồn tại.
    Và U-T68-VW gọi API-02-098 cho `RV-1`.
    Thì bước 1: `200`, `request.status = PENDING`, `conditions[]` mỗi điều kiện có `met`, `history[]` đủ gửi, hỏi thêm, trả lời theo thứ tự thời gian, tiêu đề `ETag`. Bước 2: `200`. Bước 3: `412` ERR-02-015 vì `etag` đã đổi. Bước 4: cả hai đều `404` ERR-02-001, thân giống nhau trừ `traceId`. Bước 5: `200` (VW có `PERM-02-read`) nhưng `request.canDecide = false`; UI-02-10 khóa nút "Duyệt".
