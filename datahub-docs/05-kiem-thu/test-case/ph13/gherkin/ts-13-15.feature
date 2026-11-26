# language: vi
# Sinh tự động từ D05-02-PH13 bằng ph13/tools/gen_gherkin.py; không sửa tay.
@PH-13 @TS-13-15
Tính năng: TS-13-15 · Tra log tập trung

  @TC-13-049 @P1 @Dương
  Kịch bản: TC-13-049 Tra log theo luồng, mức, thời gian, lưu truy vấn
    # Truy vết: FR-13-026 · UC-13-17 · API-13-019, 027, 028, 029 · UI-13-07 · NFR-13-005 · LGC-BUS-029
    Biết F-DU-SIM; U-T68-IE.
    Khi mở UI-13-07, lọc `level=ERROR`, luồng `luong-chung`, 1 giờ.
    Và lưu truy vấn; tải danh sách; xóa.
    Thì kết quả p95 ≤ 5 giây; `POST /saved-queries` `201`; xóa `204`; KT: có khi đổi truy vấn dùng chung.

  @TC-13-050 @P1 @Âm @Biên
  Kịch bản: TC-13-050 Log sai cú pháp, quá khoảng, trùng truy vấn lưu
    # Truy vết: FR-13-026 · API-13-019, 028 · ERR-13-006, 004, 005, 011, 002, 037
    Biết U-T68-IE.
    Khi truy vấn thiếu dấu đóng ngoặc.
    Và `from ≥ to`; khoảng 8 ngày.
    Và lưu truy vấn trùng tên; gửi lại `Idempotency-Key` khác nội dung.
    Thì ERR-13-006 kèm vị trí ký tự; ERR-13-004; ERR-13-005 (`maxDays = 7`); ERR-13-002; ERR-13-037.

  @TC-13-051 @P2 @Dương @Biên
  Kịch bản: TC-13-051 Ngữ cảnh quanh dòng log và theo dõi trực tiếp tự tắt
    # Truy vết: FR-13-027 · API-13-020, 021 · UI-13-07 · ERR-13-015
    Biết F-DU-SIM phát log liên tục; `13.live-tail.idle-minutes = 15`.
    Khi mở ngữ cảnh một dòng log; mở `GET /logs:tail`.
    Và không thao tác 15 phút.
    Thì ngữ cảnh gồm 50 dòng trước và sau; SSE nhận dòng mới ≤ 30 giây; tự đóng sau 15 phút.
