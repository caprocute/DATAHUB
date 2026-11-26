# language: vi
# Sinh tự động từ D05-02-PH01 bằng ph01/tools/gen_gherkin.py; không sửa tay.
@PH-01 @TS-01-21
Tính năng: TS-01-21 · Chấm dứt tư cách thành viên

  @TC-01-083 @P1 @Dương
  Kịch bản: TC-01-083 Đề nghị và duyệt chấm dứt, giữ hồ sơ
    # Truy vết: FR-01-031 · UC-01-21 · API-01-053, 059 · UI-01-11 · BR-01-011, 018, 023 · EVT-01-03, 07, 11.
    Biết `HT-TUPHAP` ACTIVE; `terminate.drainMinutes = 5`; TA1 đề nghị, TA2 duyệt, đều có MFA mới.
    Khi TA1 `POST …:terminate` kèm lý do và xác nhận tác động.
    Và TA2 `POST /change-requests/{changeRequestId}:decide` duyệt.
    Và sau 5 phút chờ, kiểm trạng thái, định danh, hồ sơ.
    Thì bước 1: `201`. Bước 2 và 3: `TERMINATED`; mọi định danh `REVOKED`; cổng từ chối ≤ 60 giây sau khi hết thời gian chờ; trần phạm vi thu hồi (`EVT-01-11`); hồ sơ, lịch sử giữ; mã `HT-TUPHAP` vẫn giữ. KT: có.

  @TC-01-084 @P1 @Âm @Bảomật
  Kịch bản: TC-01-084 Chấm dứt sai điều kiện
    # Truy vết: FR-01-031 · API-01-053, 059 · BR-01-017 · ERR-01-017, 033, 034.
    Biết `HT-TUPHAP`; TA1, TA2.
    Khi TA1 đề nghị không lý do; rồi khi chưa xác nhận tác động.
    Và TA1 đề nghị hợp lệ rồi tự duyệt qua `:decide`.
    Thì `400` ERR-01-033; `409` ERR-01-034; `403` ERR-01-017 (người đề nghị không duyệt); HTTT vẫn `ACTIVE`.

  @TC-01-085 @P3 @Biên
  Kịch bản: TC-01-085 Chấm dứt HTTT chưa kích hoạt
    # Truy vết: FR-01-031 · API-01-053, 059 · UC-01-21 · EVT-01-03.
    Biết `HT-HOTICH-SB` APPROVED quá hạn kiểm thử.
    Khi đề nghị và duyệt chấm dứt như ca trước.
    Thì `APPROVED → TERMINATED`; định danh SANDBOX thu hồi; không có phụ thuộc cần phân tích.
