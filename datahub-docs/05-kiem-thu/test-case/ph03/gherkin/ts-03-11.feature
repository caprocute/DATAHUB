# language: vi
# Sinh tự động từ D05-02-PH03 bằng ph03/tools/gen_gherkin.py; không sửa tay.
@PH-03 @TS-03-11
Tính năng: TS-03-11 · Suy giảm có kiểm soát khi Valkey mất

  @TC-03-050 @P1 @Âm @Chịu @lỗi
  Kịch bản: TC-03-050 Valkey ngắt: hạn ngạch mở, tần suất đếm cục bộ
    # Truy vết: FR-03-026, 021, 022, 018 · API-03-077 · UI-03-01 · UC-03-08 · BR-03-025 · NFR-03-007.
    Biết 3 bản sao `apisix-int`; C-HTTT1 20 lượt/giây, `ht-mini` quota sắp hết; token đã thu hồi trước đó.
    Khi chaos Mesh ngắt toàn bộ Valkey 10 phút.
    Và `ht-mini` gọi vượt hạn ngạch; C-HTTT1 gửi 100 lượt/giây.
    Và gọi bằng token đã thu hồi trước khi ngắt.
    Và `GET /overview`.
    Thì bước 2 hạn ngạch mở (`200`) kèm cảnh báo `quota-degraded`; tần suất vẫn bị chặn nhờ đếm cục bộ (tổng cả ba bản sao ≈ 20 lượt/giây ± dung sai chia cho 3 bản sao). Bước 3 vẫn `401` mã 105 (dùng bộ đệm gần nhất). Bước 4 `degraded = true`, nguyên nhân `VALKEY_DOWN`. Không lượt gọi nào lỗi do mất Valkey.

  @TC-03-051 @P2 @Dương @Chịu @lỗi
  Kịch bản: TC-03-051 Valkey phục hồi: bộ đếm trở lại, không đếm đôi
    # Truy vết: FR-03-026 · API-03-077 · UI-03-01 · UC-03-08 · BR-03-025.
    Biết sau TC Valkey ngắt.
    Khi bật Valkey; chờ 60 giây.
    Và `ht-mini` gọi vượt hạn ngạch.
    Và `GET /overview`.
    Thì bước 2 `429` mã 117 trở lại (hạn ngạch đếm tiếp từ giá trị Valkey, không đặt lại về 0 một cách sai). Bước 3 `degraded = false`; cảnh báo tự đóng.
