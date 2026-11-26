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

  @TC-14-141 @P1 @Bảo @mật @Âm
  Kịch bản: TC-14-141 Chiều vào: tenant lấy từ điểm cuối, không từ nội dung bản tin
    # Truy vết: BR-14-027, 029 · FR-14-039, 040 · API-14-084 · ERR-14-119 · NFR-14-024.
    Biết S-NDXP-IN là nguồn của E-NDXP-IN (T68); `T01` có điểm cuối `ndxp-vao` cùng mã, nguồn khác; bản tin mang `tenant = T01` trong nội dung và tiêu đề.
    Khi S-NDXP-IN gửi bản tin tới E-NDXP-IN với nội dung nêu `tenant = T01`.
    Và S-NDXP-IN gửi bản tin tới điểm cuối `ndxp-vao` của T01.
    Và kiểm tra luồng PH-04, giao dịch, chủ đề Kafka.
    Thì bước 1 xử lý theo tenant T68 của điểm cuối, bỏ qua `tenant` trong nội dung; mọi dữ liệu ghi vào T68, chủ đề có tiền tố `T68`. Bước 2 `403` ERR-14-119 vì nguồn chưa đăng ký cho điểm cuối của T01; cảnh báo cho SO của T01. Không giao dịch, không sự kiện nào xuất hiện ở T01.

  @TC-14-142 @P1 @Bảo @mật @Biên
  Kịch bản: TC-14-142 Một tenant cạn hạn mức hoặc bị khóa nhịp không ảnh hưởng tenant khác
    # Truy vết: NFR-14-024, 006 · BR-14-012, 029 · ERR-14-104, 123 · FR-14-033.
    Biết `T68` và `T01` cùng nền tảng dùng chung `COMMON`; hạn mức riêng mỗi tenant; `14.inbound.rate-limit-per-second = 50`; tải 100 lượt/giây ở T01.
    Khi cho T68 dùng hết hạn mức; T01 vẫn gọi đều.
    Và gửi 200 yêu cầu chiều vào mỗi giây tới điểm cuối của T68.
    Và đo độ trễ và tỷ lệ lỗi của T01 trong thời gian đó.
    Thì T68 nhận `429` ERR-14-104, chiều vào vượt 50 yêu cầu/giây nhận `429` ERR-14-123 "Quá nhiều yêu cầu, thử lại sau." kèm `retryAfterSeconds`. T01 không có lượt lỗi, độ trễ không tăng; bộ đếm hạn mức, khóa đệm, giới hạn tần suất của hai tenant tách biệt.
