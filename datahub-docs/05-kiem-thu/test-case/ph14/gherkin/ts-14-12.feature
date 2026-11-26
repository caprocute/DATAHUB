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
