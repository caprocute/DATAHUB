# language: vi
# Sinh tự động từ D05-02-PH13 bằng ph13/tools/gen_gherkin.py; không sửa tay.
@PH-13 @TS-13-22
Tính năng: TS-13-22 · Hoạt động nghiệp vụ và bảng điều khiển an ninh

  @TC-13-064 @P1 @Dương
  Kịch bản: TC-13-064 Hoạt động nghiệp vụ và bảng an ninh đúng người xem
    # Truy vết: FR-13-039, 040 · UC-13-24 · API-13-015, 016 · UI-13-05, 06
    Biết F-SEC-EVT; U-T68-VW; U-T68-SO.
    Khi U-T68-VW mở UI-13-05; thử mở `/giam-sat/log` và UI-13-06.
    Và U-T68-SO mở UI-13-06.
    Thì VW xem được UI-13-05, không mở được log, kiểm toán; SO thấy đăng nhập thất bại, bị từ chối, kết quả quét; số liệu khớp F-SEC-EVT.

  @TC-13-065 @P1 @Âm @Bảo @mật
  Kịch bản: TC-13-065 VW không có quyền xem log và kiểm toán
    # Truy vết: FR-13-020, 026, 039, 040 · API-13-016, 019, 074 · ERR-13-009 · UC-13-24
    Biết U-T68-VW.
    Khi gọi `POST /logs:search`, `POST /records:search`.
    Thì cả hai 403-PQ; giao diện ẩn menu Log, Kiểm toán.
