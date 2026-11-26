# language: vi
# Sinh tự động từ D05-02-PH14 bằng ph14/tools/gen_gherkin.py; không sửa tay.
@PH-14 @TS-14-12
Tính năng: TS-14-12 · Bộ điều hợp tư pháp: lý lịch tư pháp, hộ tịch

  @TC-14-032 @P1 @Dương
  Kịch bản: TC-14-032 Lý lịch tư pháp: danh sách, trạng thái, đánh dấu thành công
    # Truy vết: FR-14-017 · API-14-075 · UC-14-11 · LGC-NGSP-001 · UI-14-04.
    Biết S-HT-MC; `sim-ndxp` có 3 hồ sơ LLTP.
    Khi gọi các thao tác `listDossiers`, `getCatalog`, `getStatus`.
    Và gọi `markSuccess` cho một hồ sơ, rồi `getStatusList`.
    Thì dữ liệu đúng cấu trúc JSON chuẩn tương đương hệ cũ; `markSuccess` là thao tác ghi có `Idempotency-Key`; mọi bản tin ký (BR-14-001).

  @TC-14-033 @P1 @Dương @Âm
  Kịch bản: TC-14-033 Hộ tịch: đăng ký, trạng thái, kết quả; hồ sơ không tồn tại
    # Truy vết: FR-14-018 · API-14-075, 076 · ERR-14-102, 108 · LGC-NGSP-002 · UC-14-11.
    Biết S-HT-MC; V-HT, V-HT-DK.
    Khi đăng ký hộ tịch qua `async-invocations`; tra trạng thái, kết quả.
    Và tra hồ sơ `HT-KHONG-CO` (`BIZ404`).
    Và gọi thao tác không có trong bộ điều hợp.
    Thì bước 1 thành công; bước 2 `404` ERR-14-102; bước 3 `422` ERR-14-108.

  @TC-14-105 @P1 @Âm
  Kịch bản: TC-14-105 Lý lịch tư pháp: khoảng quá rộng, không tìm thấy, ghi thiếu khóa
    # Truy vết: FR-14-017 · API-14-075, 076 · ERR-14-003, 102, 104, 108 · BR-14-030 · LGC-NGSP-001.
    Biết S-HT-MC; V-LLTP; `sim-ndxp` `BIZ404` ở bước 2 và `SLOW` rồi mất kết nối ở bước 4; hạn mức nền tảng đặt về 0 ở bước 5.
    Khi `listDossiers` với `from` đến `to` dài 40 ngày.
    Và `getDossierStatus` hồ sơ `LLTP-KHONG-CO` khi `BIZ404`.
    Và `markDossierSuccess` không có `Idempotency-Key`.
    Và `markDossierSuccess` có khóa nhưng quốc gia nhận rồi không phản hồi.
    Và `listDossiers` hợp lệ khi hạn mức hết.
    Thì bước 1 `422` ERR-14-108 "Khoảng thời gian tra tối đa 31 ngày mỗi lượt." Bước 2 `404` ERR-14-102 "Không tìm thấy hồ sơ lý lịch tư pháp LLTP-KHONG-CO.", `retryable = false`. Bước 3 `400` ERR-14-003. Bước 4 giao dịch `UNKNOWN_RESULT`, gửi một lần, người gọi thấy "Chưa xác nhận được hồ sơ đã gửi, hệ thống đang đối soát. Không gửi lại." Bước 5 `429` ERR-14-104 kèm `resetAt`. Không bước nào đệm dữ liệu lý lịch tư pháp.

  @TC-14-106 @P1 @Dương @Biên
  Kịch bản: TC-14-106 Hộ tịch: đăng ký chống trùng, cùng khóa cùng nội dung trả lại kết quả đầu
    # Truy vết: FR-14-018 · API-14-076, 077 · UC-14-11 · BR-14-030 · LGC-NGSP-002 · EVT-14-11.
    Biết S-HT-MC; V-HT-DK; `sim-ndxp` `OK`; sự kiện khai sinh mẫu `tc-ks-001`.
    Khi `POST /async-invocations` `registerEvent` loại `BIRTH`, `Idempotency-Key = K1`, `caseCode = tc-ks-001`.
    Và gửi lại đúng yêu cầu đó với cùng `K1`.
    Và `GET /async-invocations/{requestId}` đến khi xong; tra `getRegistrationResult`.
    Thì bước 1 `202` có `requestId`; bước 2 trả lại kết quả của lần đầu, cùng `requestId`, `sim-ndxp` chỉ nhận đúng một yêu cầu đăng ký. Bước 3 `item` có mã hồ sơ, số đăng ký, trạng thái; dữ liệu hộ tịch không vào đệm; đúng một giao dịch ghi thành công cho sự kiện.

  @TC-14-107 @P1 @Âm
  Kịch bản: TC-14-107 Hộ tịch: sự kiện sai loại, trùng khóa khác nội dung, trung ương từ chối
    # Truy vết: FR-14-018 · API-14-076 · ERR-14-102, 108, 116 · BR-14-030 · LGC-NGSP-002.
    Biết S-HT-MC; V-HT-DK; `sim-ndxp` `OK`, sau đó `BIZ404` trả từ chối nghiệp vụ.
    Khi `registerEvent` với `eventType = KHONG_HOP_LE`.
    Và `registerEvent` loại `BIRTH` thiếu `subjects[]`.
    Và gửi `Idempotency-Key = K2` với nội dung A, rồi lại `K2` với nội dung B cùng `caseCode`.
    Và `registerEvent` hợp lệ khi `sim-ndxp` từ chối nghiệp vụ.
    Thì bước 1 và 2 `422` ERR-14-108 "Dữ liệu đăng ký hộ tịch thiếu hoặc sai: {danh sách trường}.", không gửi ra quốc gia. Bước 3 lần hai `409` ERR-14-116 "Khóa chống trùng đã dùng cho yêu cầu khác nội dung." Bước 4 `422` ERR-14-102 "Nền tảng quốc gia từ chối hồ sơ: {lý do đã che}.", không thử lại. Thân lỗi không có nội dung kỹ thuật của trung ương.
