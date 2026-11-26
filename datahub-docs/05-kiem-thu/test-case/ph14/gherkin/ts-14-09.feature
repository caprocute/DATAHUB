# language: vi
# Sinh tự động từ D05-02-PH14 bằng ph14/tools/gen_gherkin.py; không sửa tay.
@PH-14 @TS-14-09
Tính năng: TS-14-09 · Gọi dịch vụ quốc gia qua điểm gọi chung

  @TC-14-023 @P1 @Dương
  Kịch bản: TC-14-023 Gọi thành công, có mã giao dịch và nhật ký khai thác
    # Truy vết: FR-14-010, 014, 026, 027 · API-14-075 · UC-14-09 · BR-14-007, 020, 037 · NFR-14-013, 020.
    Biết S-HT-MC; V-LLTP đã cung cấp lại cho `HT-MOTCUA`; `sim-ndxp` `OK`.
    Khi `POST /internal/national/v1/invocations` `{serviceCode: lltp-tra-trang-thai, params: {dossierCode: LLTP-2026-000123}, purposeCode: GIAI_QUYET_TTHC}`; thân có thêm `systemCode: HT-KHAC`.
    Và tra giao dịch ở UI-14-12 theo `transactionCode`.
    Thì `200` JSON chuẩn, `transactionCode`, `traceId`; mã HTTT lấy từ `azp` (bỏ qua `systemCode` trong thân); bản tin gửi đi có chữ ký, phản hồi đã xác minh; giao dịch `SUCCEEDED`; có dòng nhật ký khai thác đủ HTTT, mục đích.

  @TC-14-024 @P1 @Âm
  Kịch bản: TC-14-024 Lỗi từ quốc gia được phân loại và che nội dung kỹ thuật
    # Truy vết: FR-14-015 · API-14-075 · ERR-14-101, 102, 115, 127, 128 · UI-14-12 · NFR-14-009.
    Biết S-HT-MC; `sim-ndxp` lần lượt `BIZ404`, `DOWN`, `SLOW` quá 15 giây, phản hồi sai cấu trúc; tiêm lỗi nội bộ bằng cờ kiểm thử.
    Khi gọi khi `BIZ404`.
    Và gọi khi `DOWN`; gọi khi trễ quá `14.timeout.default-ms`.
    Và gọi khi phản hồi thiếu trường bắt buộc.
    Và gọi khi bật cờ lỗi nội bộ.
    Thì bước 1 `404` hoặc `422` ERR-14-102, không có chuỗi lỗi của trung ương trong `detail`; bước 2 `502` ERR-14-101 và `504` ERR-14-115; bước 3 `502` ERR-14-128; bước 4 `500` ERR-14-127 kèm mã truy vết. Mọi giao dịch có trạng thái `FAILED` hoặc `TIMEOUT`.

  @TC-14-025 @P1 @Âm @Biên
  Kịch bản: TC-14-025 Thao tác ghi: Idempotency-Key và kết quả chưa rõ
    # Truy vết: FR-14-010 · API-14-075 · ERR-14-003, 116, 108, 105, 117 · BR-14-030, 031 · UC-14-09.
    Biết S-HT-MC; V-HT-DK; `sim-ndxp` `SLOW` rồi mất kết nối sau khi nhận; dịch vụ `tc-khong-luat` chưa có luật định tuyến.
    Khi `POST` ghi thiếu `Idempotency-Key`.
    Và `POST` cùng khóa hai lần, lần hai khác `params`.
    Và `POST` ghi khi quốc gia nhận nhưng không phản hồi; đếm số lần Datahub gửi.
    Và `POST` với `params` sai lược đồ; gọi `tc-khong-luat`.
    Thì bước 1 `400` ERR-14-003; bước 2 lần hai `409` ERR-14-116; bước 3 giao dịch `UNKNOWN_RESULT`, gửi đúng một lần, không thử lại tự động, chỉ đối soát trạng thái; bước 4 `422` ERR-14-108 và ERR-14-105.

  @TC-14-026 @P1 @Âm
  Kịch bản: TC-14-026 Bộ điều hợp và chuyển đổi từ chối đầu vào sai, không có luật, lỗi không thử lại
    # Truy vết: FR-14-012, 014, 017, 019, 020, 021, 022 · API-14-075 · ERR-14-102, 105, 108 · BR-14-037.
    Biết S-HT-MC; V-LLTP, V-BHXH, V-DVQHNS, V-DKKD, V-VBQPPL; `sim-ndxp` `BIZ404`; dịch vụ `tc-khong-luat`.
    Khi gọi từng dịch vụ với `params` sai kiểu hoặc thiếu trường bắt buộc.
    Và gọi `tc-khong-luat`.
    Và gọi V-LLTP khi `BIZ404`, xem trường `retryable`.
    Thì bước 1 `422` ERR-14-108 cho từng bộ điều hợp, không gọi ra quốc gia; bước 2 `422` ERR-14-105; bước 3 `404` ERR-14-102, `retryable = false`, không thử lại. Bộ điều hợp chỉ đổi giao thức, phong bì, lược đồ, không đổi ngữ nghĩa (BR-14-037).

  @TC-14-027 @P1 @Dương
  Kịch bản: TC-14-027 Phân loại lỗi có thể thử lại và thử lại thành công
    # Truy vết: FR-14-015, 038 · API-14-075 · BR-14-031 · UC-14-09.
    Biết S-HT-MC; V-HT; `sim-ndxp` trả `503` một lần rồi `OK`; `14.retry.max-attempts = 2`.
    Khi gọi thao tác đọc V-HT, đếm số lần gửi.
    Và xem giao dịch ở UI-14-12.
    Thì lỗi `503` của quốc gia phân loại `retryable = true`; thử lại một lần thì thành công, bên gọi nhận `200`; giao dịch ghi số lần thử và mã lỗi gốc đã che.

  @TC-14-100 @P2 @Dương
  Kịch bản: TC-14-100 Gọi bỏ qua đệm bằng `freshData` và kiểm tra đủ trường kết quả
    # Truy vết: FR-14-010 · API-14-075 · UC-14-09 · BR-14-020 · NFR-14-020.
    Biết S-HT-MC; V-HT (đệm 300 giây) đã có một mục đệm; `sim-ndxp` `OK`; hạn mức còn.
    Khi gọi V-HT lần một, rồi lần hai cùng tham số.
    Và gọi lần ba cùng tham số với `freshData = true`.
    Và đọc tiêu đề và trường `meta` của cả ba phản hồi.
    Thì cả ba `200`. Lần một `X-DH-Cache: MISS`; lần hai `X-DH-Cache: HIT` và `meta.fromCache = true`, `meta.cacheAgeSeconds` ≥ 0; lần ba `MISS`, gọi thật, trừ một lượt hạn mức. Mọi phản hồi có `transactionCode`, `platformCode`, `meta.signatureVerified`, `meta.dataTime`, `meta.durationMs` và tiêu đề `X-DH-Transaction`; giao dịch lần hai là `COMPLETED_CACHE`.

  @TC-14-101 @P1 @Âm
  Kịch bản: TC-14-101 Gọi sai điều kiện: dịch vụ không có, nền tảng ngừng, thiếu scope
    # Truy vết: FR-14-010 · API-14-075 · ERR-14-001, 117 · PERM-14-invoke · BR-14-007, 032.
    Biết S-HT-MC, S-HT-KHAC; dịch vụ `tc-dv-ngung` đã `RETIRED`; nền tảng `ndxp-moi` `SUSPENDED`; một token không có scope `national:invoke`.
    Khi gọi `serviceCode` không tồn tại.
    Và gọi `tc-dv-ngung`.
    Và gọi dịch vụ của nền tảng đang tạm ngừng.
    Và gọi bằng token thiếu scope `national:invoke`.
    Và gọi dịch vụ của tenant T01 bằng S-HT-MC.
    Thì bước 1 và 5 `404` ERR-14-001, thân giống nhau trừ `traceId`. Bước 2 và 3 `503` ERR-14-117 "Dịch vụ hoặc nền tảng đang ngừng hoặc tạm ngừng, chưa nhận lượt gọi mới." Bước 4 `403`. Không lượt nào chạm nền tảng quốc gia, không trừ hạn mức.

  @TC-14-102 @P1 @Âm @Chịu @lỗi
  Kịch bản: TC-14-102 Quá hạn chờ và không kết nối được nền tảng quốc gia
    # Truy vết: FR-14-010, 015 · API-14-075 · ERR-14-101, 115 · BR-14-030, 031 · NFR-14-009 · EVT-14-11.
    Biết S-HT-MC; V-HT (đọc) và V-HT-DK (ghi); `14.timeout.default-ms = 15000`, dịch vụ đặt `timeoutMs = 3000`; `sim-ndxp` `SLOW` (trễ 10 giây) rồi `DOWN`.
    Khi gọi V-HT thao tác đọc khi `sim-ndxp` `SLOW`.
    Và gọi V-HT khi `sim-ndxp` từ chối kết nối (`DOWN`).
    Và gọi V-HT-DK thao tác ghi khi `SLOW`; đếm số lần gửi.
    Thì bước 1 sau khoảng 3 giây `504` ERR-14-115 "Nền tảng quốc gia không trả lời trong 3 giây.", giao dịch `TIMEOUT`, thao tác đọc được thử lại tối đa `14.retry.max-attempts` lần. Bước 2 `502` ERR-14-101 "Không kết nối được nền tảng quốc gia. Hệ thống sẽ thử lại, hãy gọi lại sau ít phút." Bước 3 giao dịch `UNKNOWN_RESULT`, gửi đúng một lần. Thân lỗi có `transactionCode`, không lộ địa chỉ máy chủ.

  @TC-14-103 @P1 @Dương
  Kịch bản: TC-14-103 Chuyển đổi đúng giao thức và định dạng chuẩn: REST, SOAP, lọc trường
    # Truy vết: FR-14-014 · API-14-075 · UC-14-09 · BR-14-009, 037 · NFR-14-013.
    Biết S-HT-MC; V-LLTP (REST) và một dịch vụ SOAP `tc-soap-tra` có WSDL đã nạp; hợp đồng cung cấp lại có `responseFields` giới hạn; phản hồi `sim-ndxp` chứa trường thừa, ngày giờ khác múi giờ, trường rỗng, định danh dạng số.
    Khi gọi V-LLTP; ghi lại yêu cầu mà `sim-ndxp` nhận.
    Và gọi `tc-soap-tra`; ghi lại phong bì SOAP.
    Và đọc JSON trả về.
    Thì yêu cầu REST có tiêu đề `Service-code` bằng mã dịch vụ quốc gia, `Authorization: Bearer`, mã giao dịch và thời điểm; phong bì SOAP dựng từ WSDL. JSON trả về giữ định danh dạng chuỗi, ngày giờ ISO 8601 múi giờ +07:00, trường rỗng thành `null`, không còn trường ngoài `responseFields`. Cổng không đổi ngữ nghĩa hay mã danh mục.

  @TC-14-104 @P1 @Âm
  Kịch bản: TC-14-104 Chuyển đổi sai: lược đồ đầu vào, phản hồi sai cấu trúc, mất WSDL
    # Truy vết: FR-14-014 · API-14-075 · ERR-14-108, 128, 131 · BR-14-037.
    Biết S-HT-MC; V-LLTP và `tc-soap-tra`; `sim-ndxp` trả thân sai cấu trúc ở một ca; địa chỉ WSDL tải xa bị chặn.
    Khi gọi V-LLTP với `params` thiếu trường bắt buộc và sai kiểu hai trường.
    Và gọi V-LLTP khi `sim-ndxp` trả thân không đúng lược đồ đầu ra.
    Và xóa bộ đệm WSDL, chặn địa chỉ WSDL, gọi `tc-soap-tra`.
    Thì bước 1 `422` ERR-14-108 kèm `errors[]` nêu đủ trường sai, không gửi ra quốc gia. Bước 2 `502` ERR-14-128 "Phản hồi từ nền tảng quốc gia không đúng cấu trúc. Sự cố đã được ghi nhận.", không trả dữ liệu. Bước 3 dùng bản WSDL đã lưu nên vẫn gọi được, ghi cảnh báo ERR-14-131 cho IE; nếu chưa từng nạp thì `502` ERR-14-131.
