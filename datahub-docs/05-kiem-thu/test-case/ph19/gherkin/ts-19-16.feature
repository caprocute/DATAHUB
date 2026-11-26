# language: vi
# Sinh tự động từ D05-02-PH19 bằng ph19/tools/gen_gherkin.py; không sửa tay.
@PH-19 @TS-19-16
Tính năng: TS-19-16 · Đồng bộ trạng thái và xử lý lại IPN

  @TC-19-376 @P1 @Dương
  Kịch bản: TC-19-376 Lịch truy vấn chủ động giãn dần
    # Truy vết: FR-19-036 · BR-19-016 · PendingQueryScheduler
    Biết giao dịch `PENDING` không có IPN; `PGSIM` luôn trả "chưa thanh toán"; đồng hồ giả.
    Khi tiến đồng hồ tới 72 giờ, ghi lại các thời điểm truy vấn.
    Và Ở lần thứ 6, `PGSIM` trả "thành công".
    Thì bước 1: các lần truy vấn ở 2, 5, 10, 15, 30 phút, 1, 2, 4 giờ, rồi mỗi 6 giờ (dung sai ±10 giây). Bước 2: ST: `PENDING` → `SUCCEEDED` nguồn `POLL`; các lần truy vấn sau dừng.

  @TC-19-377 @P2 @Dương
  Kịch bản: TC-19-377 Cán bộ đồng bộ thủ công
    # Truy vết: FR-19-037 · API-19-053 · UI-19-15
    Biết U-OPR1; TX-PEND; `PGSIM` trả "thành công".
    Khi bấm "Đồng bộ với NCC", nhập lý do.
    Thì `200` với `before = PENDING`, `after = SUCCEEDED`, `changed = true`, `nextAllowedAt`; ST: `PENDING` → `SUCCEEDED` nguồn `MANUAL_SYNC`. KT: có. Phát hành Đ2b.

  @TC-19-378 @P2 @Âm
  Kịch bản: TC-19-378 Đồng bộ quá tần suất, không có quyền
    # Truy vết: FR-19-037 · API-19-053 · ERR-19-023, 046
    Biết U-OPR1; U-ADM1.
    Khi đồng bộ cùng giao dịch hai lần trong 60 giây.
    Và đồng bộ 11 lần trong ngày (cách nhau > 60 giây).
    Và U-ADM1 đồng bộ.
    Thì bước 1 lần 2 trả `429` ERR-19-023 có `Retry-After`. Bước 2 lần 11 trả `429` ERR-19-023. Bước 3 trả 403-PQ.

  @TC-19-379 @P2 @Dương @Âm
  Kịch bản: TC-19-379 Xem và xử lý lại IPN cách ly
    # Truy vết: FR-19-032 · API-19-057, 058 · UI-19-16 · ERR-19-021
    Biết U-OPR1; IPN cách ly `UNMAPPED_CODE` từ TC-19-304 bước 4; bảng ánh xạ đã thêm mã `99` (v2); một IPN `BAD_SIGNATURE`.
    Khi mở ngăn kéo chi tiết IPN cách ly.
    Và bấm "Xử lý lại", nhập lý do.
    Và gọi `POST /callbacks/{id}/replays` cho IPN `BAD_SIGNATURE`.
    Thì bước 1: nguyên văn đã che, `rawHash`, các bước kiểm tra. Bước 2 trả `202`; IPN `PROCESSED` với `mappingVersion = 2`; giao dịch đổi trạng thái theo kết quả mới. Bước 3 trả `409` ERR-19-021; nút không hiện trên màn. Phần xử lý lại phát hành Đ2b; phần xem thuộc MVP.
