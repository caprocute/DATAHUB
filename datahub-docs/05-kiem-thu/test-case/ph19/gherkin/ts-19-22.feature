# language: vi
# Sinh tự động từ D05-02-PH19 bằng ph19/tools/gen_gherkin.py; không sửa tay.
@PH-19 @TS-19-22
Tính năng: TS-19-22 · Tra cứu và xuất giao dịch

  @TC-19-526 @P1 @Dương
  Kịch bản: TC-19-526 Bảng tra cứu đủ chín cột hệ cũ, tìm theo mã
    # Truy vết: FR-19-049 · API-19-051 · UI-19-14 · LGC-PAY-014, 018 · NFR-19-029, 030
    Biết U-OPR1; 60 giao dịch trong 30 ngày.
    Khi mở UI-19-14.
    Và gõ mã TX-OK, nhấn `Enter`.
    Và xóa ô tìm; bấm "Trang sau".
    Thì bước 1: chín cột đúng thứ tự hệ cũ, 20 dòng, sắp giảm theo ngày phát sinh; người thanh toán đã che. Bước 2 mở thẳng UI-19-15. Bước 3: dòng 21–40; URL giữ bộ lọc.

  @TC-19-527 @P1 @Dương
  Kịch bản: TC-19-527 Tra cứu nâng cao kết hợp trạng thái, lĩnh vực, thời gian
    # Truy vết: FR-19-050 · API-19-051 · UI-19-14 · LGC-PAY-015, 016, 017
    Biết bộ dữ liệu có đủ trạng thái, hai nhóm dịch vụ.
    Khi lọc trạng thái `SUCCEEDED` + `PENDING`, nhóm G-TP, 7 ngày, số tiền 10.000–100.000 ₫.
    Và lọc người nộp theo họ tên đầy đủ đúng; rồi theo một phần họ tên.
    Thì bước 1: kết quả bằng truy vấn đối chứng SQL; dòng tổng chỉ cộng giao dịch thành công, ghi rõ. Bước 2: họ tên đầy đủ khớp; một phần không khớp (băm HMAC), có ghi chú dưới ô.

  @TC-19-528 @P2 @Âm
  Kịch bản: TC-19-528 Tham số tra cứu không hợp lệ
    # Truy vết: FR-19-049, 050 · API-19-051 · ERR-19-001, 046
    Biết U-OPR1; U-SEC1.
    Khi `q` 1 ký tự; `from` sau `to`; khoảng 400 ngày; `limit = 500`; `sort = name`.
    Và U-SEC1 gọi `GET /transactions`.
    Thì bước 1: mỗi trường hợp `400` ERR-19-001 chỉ đúng tham số. Bước 2: 403-PQ.

  @TC-19-529 @P2 @Dương
  Kịch bản: TC-19-529 Xuất danh sách giao dịch che dữ liệu cá nhân
    # Truy vết: FR-19-052 · BR-19-031 · API-19-083, 084 · UI-19-14
    Biết U-ACC1; bộ lọc 30 ngày.
    Khi xuất XLSX.
    Và U-ACC1 có `transaction-read-pii` xuất kèm "thông tin người nộp chưa che" với lý do.
    Và U-ACC2 mở đường tải của U-ACC1.
    Thì bước 1: tác vụ `QUEUED` → `SUCCEEDED`; tệp che dữ liệu cá nhân. Bước 2: tệp chưa che; KT: có (`TRANSACTION_EXPORT_PII` với lý do). Bước 3: 404-ẩn. Đường tải hết hạn sau 24 giờ. Phát hành Đ2b.

  @TC-19-530 @P2 @Âm
  Kịch bản: TC-19-530 Xuất vượt giới hạn, không có quyền
    # Truy vết: FR-19-052 · API-19-083 · ERR-19-047, 046
    Biết môi trường SIT hạ giới hạn xuất từ 1.000.000 xuống 1.000 dòng bằng tham số kiểm thử (giả định GĐ-TC-01, để không phải sinh 1 triệu dòng); bộ lọc trả 1.500 dòng; U-OPR1; U-ACC1 có `transaction-read-pii`.
    Khi U-ACC1 xuất.
    Và U-OPR1 xuất.
    Và U-ACC1 xuất với `includePii = true` mà không có lý do.
    Thì bước 1 trả `422` ERR-19-047. Bước 2: 403-PQ. Bước 3 trả `400` ERR-19-001 (thiếu lý do).
