# language: vi
# Sinh tự động từ D05-02-PH14 bằng ph14/tools/gen_gherkin.py; không sửa tay.
@PH-14 @TS-14-33
Tính năng: TS-14-33 · Cách ly tenant và RLS

  @TC-14-083 @P1 @Bảo @mật
  Kịch bản: TC-14-083 Bộ ca rò rỉ chéo tenant cho mọi API đọc và ghi
    # Truy vết: NFR-14-024 · BR-14-029 · ERR-14-001 · API-14-001, 003, 010, 012, 024, 029, 031, 041, 044, 048, 053, 055, 061, 062, 065, 067.
    Biết T01 có đối tượng trùng mã với T68; token T68 và T01.
    Khi với mỗi API đọc theo mã ở danh sách, dùng token T68 gọi mã chỉ có ở T01.
    Và dùng truy vấn danh sách, đếm số dòng của T01 lẫn vào.
    Và kết nối CSDL bằng vai trò ứng dụng T68, `SELECT` bảng của T01.
    Thì `404` ERR-14-001 như đối tượng không tồn tại; 0 dòng T01 trong danh sách; RLS trả 0 dòng, `INSERT` chéo bị từ chối.

  @TC-14-084 @P1 @Bảo @mật
  Kịch bản: TC-14-084 Khóa đệm, bộ đếm, đường dẫn OpenBao, topic Kafka có tiền tố tenant
    # Truy vết: NFR-14-024 · BR-14-015, 027 · API-14-084 · ERR-14-119.
    Biết T68 và T01 cùng gọi `hotich-tra-cuu`; điểm cuối chiều vào của T01.
    Khi liệt kê khóa Valkey, đường dẫn OpenBao, topic Kafka sau khi cả hai tenant chạy.
    Và gọi điểm cuối chiều vào của T01 bằng chứng thư nguồn của T68.
    Thì mọi khóa có tiền tố `t68.` hoặc `t01.`; bộ đếm hạn mức tách; bước 2 `403` ERR-14-119, tenant chỉ xác định từ điểm cuối đã đăng ký.

  @TC-14-085 @P1 @Bảo @mật
  Kịch bản: TC-14-085 Chỉ đi ra qua hồ sơ `national-gateway`, TLS và danh sách egress
    # Truy vết: BR-14-006 · NFR-14-014 · FR-14-010 · SEC-10, SEC-11.
    Biết `national-gateway` 3 bản sao; danh sách egress chỉ có địa chỉ `sim-ndxp`; pod `dh-runtime` hồ sơ khác.
    Khi từ pod hồ sơ khác và từ pod `national-gateway` thử kết nối tới địa chỉ ngoài danh sách.
    Và quét phiên bản TLS của kết nối tới `sim-ndxp` và NDOP; ép TLS 1.1.
    Thì chỉ `national-gateway` kết nối được đích trong danh sách; mọi đường khác bị chính sách mạng chặn (0 kết nối ngoài danh sách); TLS 1.3 ưu tiên, tối thiểu 1.2, mTLS khi nền tảng hỗ trợ; TLS 1.1 bị từ chối.
