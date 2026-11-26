# language: vi
# Sinh tự động từ D05-02-PH13 bằng ph13/tools/gen_gherkin.py; không sửa tay.
@PH-13 @TS-13-02
Tính năng: TS-13-02 · Che dữ liệu Nhạy cảm và quét phát hiện lọt

  @TC-13-006 @P1 @Dương @Bảo @mật
  Kịch bản: TC-13-006 Che số định danh, số điện thoại, thư điện tử trong log trước khi lưu
    # Truy vết: FR-13-005 · BR-13-011 · NFR-13-021
    Biết F-LOG-CAN; U-T68-IE.
    Khi phát F-LOG-CAN qua collector.
    Và tìm trong Loki các mẫu CCCD giả, số điện thoại giả, thư điện tử giả và `DH-CANARY-redact`.
    Thì 0 kết quả cho giá trị gốc; dòng log còn lại có dấu che `*`; trường không nhạy cảm giữ nguyên.

  @TC-13-007 @P1 @Âm
  Kịch bản: TC-13-007 Quét hằng ngày phát hiện mẫu lọt, báo nguồn, không lưu giá trị
    # Truy vết: FR-13-005, 040 · ERR-13-112 · BR-13-011 · UC-13-02 · API-13-016 · UI-13-06 · EVT-13-04
    Biết tắt bộ che cho một DU thử; F-LOG-CAN; U-T68-SO.
    Khi DU thử ghi 20 dòng chứa mẫu CCCD giả.
    Và chạy bộ quét; U-T68-SO mở UI-13-06, mục kết quả quét; gọi `GET /dashboards/security`.
    Thì kết quả quét nêu DU, số dòng, loại mẫu, khoảng thời gian; không có giá trị gốc; cảnh báo nguồn DU; ERR-13-112; EVT: `security-alert.raised`.

  @TC-13-008 @P1 @Âm @Bảo @mật
  Kịch bản: TC-13-008 Bản ghi kiểm toán chứa giá trị Nhạy cảm chưa che bị cách ly
    # Truy vết: FR-13-005, 010 · BR-13-035 · NFR-13-024 · ERR-13-105
    Biết F-AUD-PII; S-DU.
    Khi gửi bản ghi có `after.password = DH-CANARY-pii`.
    Và tra chuỗi T68 theo `id`.
    Thì bản ghi vào bảng cách ly, không vào chuỗi, `seq` không nhảy; ERR-13-105; cảnh báo `WARNING` cho DU nguồn; mồi sạch ở mọi nơi trừ bảng cách ly đã che.
