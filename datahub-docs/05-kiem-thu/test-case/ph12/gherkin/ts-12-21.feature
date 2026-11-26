# language: vi
# Sinh tự động từ D05-02-PH12 bằng ph12/tools/gen_gherkin.py; không sửa tay.
@PH-12 @TS-12-21
Tính năng: TS-12-21 · Cấp client OAuth và vòng đời client của HTTT

  @TC-12-062 @P1 @Dương
  Kịch bản: TC-12-062 Cấp client cho HTTT, xem danh sách và chi tiết
    # Truy vết: FR-12-030 · UC-12-21 · UI-12-10 · API-12-056, 057, 058 · LGC-APIM-020 · BR-12-023, BR-12-024
    Biết U-T68-TA1; HTTT `HT-A` mức Hạn chế `ACTIVE` ở PH-01.
    Khi `POST /clients` kèm hợp đồng, chứng thư mTLS; đọc `GET /clients`, `GET /clients/{id}`.
    Thì `201`, `clientId` theo tenant; không có bí mật trong thân; KT: có (client.create); SK: `client.created`.

  @TC-12-063 @P1 @Âm
  Kịch bản: TC-12-063 HTTT đã có client; phương thức không đạt mức hợp đồng
    # Truy vết: FR-12-030 · BR-12-024 · API-12-058 · ERR-12-018 · ERR-12-022
    Biết `HT-A` đã có client; `HT-N` mức Nhạy cảm.
    Khi `POST /clients` lần hai cho `HT-A`.
    Và `POST /clients` cho `HT-N` bằng `client_secret`; cho mức Hạn chế bằng `client_secret`.
    Thì bước 1 `409` ERR-12-018; bước 2 `422` ERR-12-022.

  @TC-12-064 @P1 @Dương @Âm
  Kịch bản: TC-12-064 Sửa, tạm ngừng, tiếp tục, thu hồi client
    # Truy vết: FR-12-031 · UC-12-23 · UI-12-10 · API-12-059, 060, 061, 062 · ERR-12-020 · BR-12-028
    Biết C-T68-B có token hiệu lực; U-T68-SO.
    Khi `:suspend`; gọi bằng token cũ; `:resume`.
    Và `:revoke` kèm lý do; `:resume` và `PATCH` sau thu hồi.
    Thì tạm ngừng chặn token ≤ 60 giây; tiếp tục dùng lại được; thu hồi là một chiều, các thao tác sau trả `409` ERR-12-020.

  @TC-12-065 @P2 @Dương
  Kịch bản: TC-12-065 Cấp client cho ứng dụng nhà phát triển ở sandbox
    # Truy vết: FR-12-032 · UC-12-21 · UI-12-10 · API-12-063 · LGC-IAM-006 · BR-12-024
    Biết yêu cầu từ PH-15; tenant sandbox.
    Khi `POST /dev-clients`; dùng C-DEV lấy token ở sandbox rồi ở T68 chính.
    Thì token sandbox dùng được ở sandbox, bị từ chối ở T68; scope chỉ dữ liệu giả lập.
