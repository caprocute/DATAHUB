# language: vi
# Sinh tự động từ D05-02-PH17 bằng ph17/tools/gen_gherkin.py; không sửa tay.
@PH-17 @TS-17-08
Tính năng: TS-17-08 · Chọn mô hình mặc định, định tuyến lời gọi và dự phòng

  @TC-17-024 @P1 @Dương
  Kịch bản: TC-17-024 Chọn mô hình mặc định và định tuyến theo năng lực
    # Truy vết: FR-17-010 · API-17-044, 045, 046 · BR-17-017 · EVT-17-01
    # Mục đích: Chứng minh mỗi tenant có một mô hình mặc định mỗi loại và lời gọi đi đúng mô hình theo loại.
    Biết T90; `MV-CHAT-1`, `MV-CHAT-2` đều `APPROVED` (nội bộ), `MV-EMB-1`; U-T90-TA1.
    Khi TA1 `POST /tenant-models/{MV-CHAT-1}:enable` và `{MV-EMB-1}:enable`.
    Và TA1 `PUT /tenant-models/defaults` `chat = MV-CHAT-1`, `embed = MV-EMB-1`.
    Và TA1 `PUT /tenant-models/defaults` đổi `chat = MV-CHAT-2`.
    Và IE gửi câu hỏi và xem `GET /invocations` (qua U-T90-SO).
    Thì bước 2 `200`, KT: có. Bước 3 chỉ còn một mặc định loại `CHAT`. Bước 4 lời gọi sinh văn bản ghi `MV-CHAT-2`, lời gọi nhúng ghi `MV-EMB-1`.

  @TC-17-025 @P1 @Âm @Biên
  Kịch bản: TC-17-025 Thiếu mô hình mặc định, sai năng lực, vượt giới hạn ngữ cảnh
    # Truy vết: FR-17-010, 008 · API-17-045, 095 · ERR-17-031, 032, 033
    # Mục đích: Chứng minh các từ chối đúng mã khi cấu hình hoặc đầu vào không hợp lệ.
    Biết T93 không có mô hình mặc định; `MV-EMB-1` không có năng lực `CHAT`; `MV-CHAT-S` giới hạn ngữ cảnh 2.000 token.
    Khi TA `PUT /tenant-models/defaults` đặt `chat = MV-EMB-1`.
    Và TA đặt `chat = MV-CHAT-S`; IE gửi câu hỏi cùng 12 đoạn truy hồi vượt 2.000 token.
    Và T93 gửi câu hỏi khi chưa có mô hình hội thoại mặc định (đã bật bằng cấu hình thử).
    Thì bước 1 `422` ERR-17-031. Bước 2 hệ thống cắt bớt đoạn tới khi vừa giới hạn; nếu bản thân câu hỏi vượt thì `422` ERR-17-032. Bước 3 `409` ERR-17-033.

  @TC-17-026 @P1 @Dương @Âm @Bảo_mật
  Kịch bản: TC-17-026 Dự phòng sang mô hình cùng loại đã duyệt, cấm từ nội bộ sang ngoài
    # Truy vết: FR-17-010, 003 · API-17-045 · BR-17-018 · NFR-17-019 · ERR-17-034 · ERR-17-036
    # Mục đích: Chứng minh dự phòng hợp lệ trong ≤ 2 giây và không bao giờ chuyển từ nội bộ sang ngoài khi tenant chưa cho phép.
    Biết T90 có `MV-CHAT-1` mặc định, `MV-CHAT-2` dự phòng (nội bộ), `MV-EXT-1` (ngoài, đã duyệt, T90 chưa bật `external-allowed`); `17.model.fallback-enabled = true`.
    Khi TA `PUT /tenant-models/defaults` đặt dự phòng `chat = MV-EXT-1`.
    Và làm `MV-CHAT-1` trả lỗi liên tục; IE gửi câu hỏi; đo thời gian chuyển.
    Và làm cả `MV-CHAT-1` và `MV-CHAT-2` lỗi; IE gửi câu hỏi.
    Và đặt `17.model.fallback-enabled = false` rồi làm `MV-CHAT-1` lỗi.
    Thì bước 1 `409` ERR-17-034. Bước 2 câu trả lời `200` từ `MV-CHAT-2`, vết `FALLBACK`, độ trễ chuyển ≤ 2 giây. Bước 3 `503` ERR-17-036, không có lời gọi nào tới `MV-EXT-1` (không có gói tin ra egress). Bước 4 `503` ERR-17-036, không dự phòng.
