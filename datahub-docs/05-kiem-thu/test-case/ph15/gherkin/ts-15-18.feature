# language: vi
# Sinh tự động từ D05-02-PH15 bằng ph15/tools/gen_gherkin.py; không sửa tay.
@PH-15 @TS-15-18
Tính năng: TS-15-18 · Thử API ở sandbox MOCK

  @TC-15-105 @P1 @Dương
  Kịch bản: TC-15-105 Thử một thao tác ở chế độ MOCK
    # Truy vết: FR-15-035, 036 · UC-15-19 · API-15-072, 073 · UI-15-06 · EVT-15-11 · BR-15-017, 026 · NFR-15-005 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết U-T68-DEV-AN; `app-tra-cuu-ho-tich` có credential; hồ sơ MOCK `FIRST` của `tra-cuu-ho-tich`.
    Khi `POST /try/requests` {appCode, apiCode, versionNo `1.0.0`, operation `getHoTich`, params `{id: "000123456789"}`}.
    Và `GET /try/requests/{tryId}`.
    Và lặp với tiêu đề `X-DH-Mock-Status: 404`.
    Thì `200`, phản hồi sinh từ ví dụ đầu của đặc tả, tiêu đề `X-DH-Sandbox: mock`, `X-DH-Try-Id`, `traceparent`; bước 3 trả phản hồi mẫu 404; EVT-15-11 `env = SANDBOX`, `result = OK`, không có thân; KT: có (`TRY_API`); gateway không gọi hệ thống nào (đếm WireMock bằng 0).

  @TC-15-106 @P2 @Dương
  Kịch bản: TC-15-106 Sinh từ lược đồ khi thiếu ví dụ
    # Truy vết: FR-15-036 · API-15-072 · BR-15-017 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết thao tác `listHoTich` có lược đồ (enum, định dạng ngày) nhưng không có ví dụ; `examplePolicy = RANDOM`.
    Khi gọi hai lần liên tiếp.
    Thì phản hồi hợp lệ theo lược đồ (kiểu, enum, định dạng); hai lần có thể khác nhau; dữ liệu sinh thuộc dải giả (xem TC-15-117).

  @TC-15-107 @P1 @Âm
  Kịch bản: TC-15-107 Không sinh được, không khớp đặc tả, phiên bản không cho thử
    # Truy vết: FR-15-035, 036 · UC-15-19 · API-15-071, 072 · ERR-15-107, 110, 122 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết thao tác `exportHoTich` không có ví dụ lẫn lược đồ; thiếu tham số bắt buộc `id`; phiên bản SUSPENDED.
    Khi thử `exportHoTich`.
    Và thử `getHoTich` thiếu `id`; gọi `POST /try/requests:validate`.
    Và thử phiên bản SUSPENDED.
    Thì `422` ERR-15-110; `422` ERR-15-107 nêu chi tiết tham số, `validate` báo cùng lỗi và không tính hạn mức; `403` ERR-15-122.

  @TC-15-108 @P1 @Âm
  Kịch bản: TC-15-108 Ứng dụng, thành viên, điều khoản
    # Truy vết: FR-15-035 · UC-15-19 · API-15-072 · ERR-15-005, 010, 102 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết ứng dụng SUSPENDED; ứng dụng không credential; ứng dụng của An (Cự không thuộc); Bi chưa chấp nhận điều khoản; VIEWER.
    Khi mỗi trường hợp gọi `POST /try/requests`.
    Thì `403` ERR-15-102 (hai ứng dụng đầu); `403` ERR-15-005 (Cự, VIEWER); `409` ERR-15-010 (Bi); không lượt thử nào được tính hạn mức.

  @TC-15-109 @P1 @Âm
  Kịch bản: TC-15-109 Tiêu đề cấm, phương thức cấm, cổng sandbox hỏng
    # Truy vết: FR-15-035 · API-15-072 · ERR-15-111, 116, 121 · BR-15-026 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết U-T68-DEV-AN; yêu cầu thử có `Authorization`, `Cookie`, `Host`; phương thức `TRACE`; ngắt APISIX sandbox.
    Khi gửi từng tiêu đề cấm.
    Và thử `TRACE`.
    Và thử hợp lệ khi gateway ngắt.
    Thì `422` ERR-15-121 "Tiêu đề Authorization không được phép gửi."; `422` ERR-15-116; `503` ERR-15-111 "Cổng thử đang bảo trì. Thử lại sau."

  @TC-15-110 @P1 @Dương
  Kịch bản: TC-15-110 Gọi trực tiếp qua tên miền sandbox dùng chung hạn mức
    # Truy vết: FR-15-035, 039 · API-15-082 · ERR-15-103 · BR-15-025 · LGC-IAM-006.
    Biết `15.try.rate-per-user-min = 5`; U-T68-DEV-AN; token client `sbx-t68-…-1`.
    Khi 3 lượt thử qua cổng.
    Và 3 lượt gọi trực tiếp `https://sandbox-api.t68.datahub.gov.vn/...` với token.
    Thì lượt thứ 6 nhận `429` (cùng bộ đếm); lời gọi hợp lệ `200` có `X-DH-Sandbox: mock`.

  @TC-15-111 @P2 @Biên
  Kịch bản: TC-15-111 MOCK cảnh báo (không chặn) dữ liệu giống DLCN
    # Truy vết: FR-15-036, 038 · API-15-071, 072 · BR-15-016 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết thân giống số căn cước `079123456789`.
    Khi `POST /try/requests` chế độ MOCK.
    Thì `200` kèm `warnings[]` về PII-15-01; giá trị khớp không có ở bản ghi lượt thử, log, vết (tìm `079123456789` = 0).
