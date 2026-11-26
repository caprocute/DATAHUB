# language: vi
# Sinh tự động từ D05-02-PH14 bằng ph14/tools/gen_gherkin.py; không sửa tay.
@PH-14 @TS-14-20
Tính năng: TS-14-20 · Sự cố chữ ký như sự cố an ninh

  @TC-14-051 @P1 @Dương @Bảo @mật
  Kịch bản: TC-14-051 Vượt ngưỡng vào SECURITY_HOLD, xử lý và giải trừ
    # Truy vết: FR-14-031 · API-14-037, 038 · UI-14-14 · UC-14-21 · BR-14-003 · ERR-14-109 · PERM-14-operate.
    Biết U-T68-SO; `14.signature.hold-threshold = 5`; `sim-ndxp` `BADSIG`.
    Khi gọi 5 lượt trong 10 phút.
    Và SO `POST /signature-incidents/{id}:transition` xác nhận, phân loại, kết thúc; giải trừ giữ.
    Thì nền tảng vào `SECURITY_HOLD`, lượt mới bị từ chối; SO giải trừ sau xác thực nhiều yếu tố, có lý do; kiểm toán đầy đủ; nền tảng trở về `ACTIVE`.

  @TC-14-052 @P2 @Âm @Bảo @mật
  Kịch bản: TC-14-052 Chuyển trạng thái sự cố sai hoặc không có quyền
    # Truy vết: FR-14-031 · API-14-037, 038 · ERR-14-004, 001.
    Biết sự cố `CLOSED`; U-T68-TA, U-T68-VW; sự cố của T01.
    Khi SO chuyển sự cố `CLOSED` về `OPEN`.
    Và U-T68-VW chuyển trạng thái.
    Và U-T68-SO `GET` sự cố của T01.
    Thì `409` ERR-14-004; `403`; `404` ERR-14-001.
