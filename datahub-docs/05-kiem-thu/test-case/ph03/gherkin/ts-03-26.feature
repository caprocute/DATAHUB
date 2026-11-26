# language: vi
# Sinh tự động từ D05-02-PH03 bằng ph03/tools/gen_gherkin.py; không sửa tay.
@PH-03 @TS-03-26
Tính năng: TS-03-26 · Không lộ dữ liệu, thông tin máy chủ và không có đường tắt tới backend

  @TC-03-105 @P1 @Bảo @mật
  Kịch bản: TC-03-105 Quét mồi `DH-CANARY` toàn hệ thống sau chuỗi lượt gọi hỗn hợp
    # Truy vết: FR-03-050, 052 · BR-03-007, 023 · NFR-03-014 · CMP-LAW-05 · SEC-32, 61.
    Biết `CANARY` riêng theo ca đặt ở thân, tiêu đề, tham số, `Cookie`, đường dẫn; 1.000 lượt hỗn hợp thành công, `4xx`, `429`, `5xx`, WAF chặn, mTLS lỗi.
    Khi chạy chuỗi lượt gọi hỗn hợp.
    Và quét nhật ký APISIX, nhật ký `dh-connect`, vết OTel, chỉ số, ClickHouse, Kafka, bảng `ph03_gateway.*`, tệp xuất, báo cáo.
    Thì 0 lần xuất hiện của mồi ở mọi nơi (mồi sạch); riêng đường dẫn chỉ xuất hiện phần đường dẫn đã chuẩn hóa, không có chuỗi truy vấn.

  @TC-03-106 @P1 @Dương @Bảo @mật
  Kịch bản: TC-03-106 Mọi phản hồi lỗi của gateway theo RFC 9457, đủ `code` và `X-Trace-Id`
    # Truy vết: FR-03-009, 012, 019, 021, 036 · BR-03-023 · NFR-03-015.
    Biết bảng 30 tình huống, mỗi tình huống gây đúng một mã `ERR-03-1nn` (tham số hóa theo ca của TS-03-01…19).
    Khi chạy từng tình huống.
    Và kiểm thân và tiêu đề từng phản hồi lỗi.
    Thì mỗi phản hồi có `Content-Type: application/problem+json`, các trường `type`, `title`, `status`, `detail`, `code = ERR-03-1nn` đúng mã, `instance`, `traceId`; có `X-Trace-Id`; mã HTTP khớp bảng ERR (kể cả `Retry-After` ở mã 116…120, 123, 124); không có vết ngăn xếp, tên máy, địa chỉ nội bộ, tên plugin hay phiên bản.

  @TC-03-107 @P1 @Bảo @mật
  Kịch bản: TC-03-107 Backend chỉ nhận lưu lượng từ APISIX, không có đường tắt
    # Truy vết: BR-03-001 · FR-03-001 · UC-03-01 · SEC-14, 15.
    Biết `SIM-BE-1` trong namespace `dh-backend`; một pod thử trong namespace khác.
    Khi từ pod thử gọi trực tiếp `SIM-BE-1` bằng IP pod và bằng Service.
    Và từ ngoài cụm gọi IP nút và cổng NodePort (nếu có).
    Và gọi qua gateway.
    Thì bước 1, 2 bị chính sách mạng chặn (hết thời gian hoặc bị từ chối kết nối). Bước 3 `200`. Chính sách mạng chỉ cho phép lưu lượng đến backend từ APISIX.
