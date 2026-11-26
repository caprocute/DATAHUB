# language: vi
# Sinh tự động từ D05-02-PH07 bằng ph07/tools/gen_gherkin.py; không sửa tay.
@PH-07 @TS-07-28
Tính năng: TS-07-28 · Bảo mật (ASVS)

  @TC-07-304 @P1 @Bảo @mật
  Kịch bản: TC-07-304 Tệp giả mạo đuôi
    # Truy vết: FR-07-021 · DD-12 · ERR-07-019 · ASVS V12
    Biết F-FAKE.
    Khi tải F-FAKE vào bản nháp CAT-LH.
    Thì tác vụ `FAILED` với `ERR-07-019` (kiểu nội dung theo chữ ký tệp không phải xlsx) hoặc `ERR-07-038` nếu bộ quét phát hiện trước; tệp bị xóa khỏi vùng tạm.

  @TC-07-305 @P1 @Bảo @mật
  Kịch bản: TC-07-305 Tệp chứa mẫu EICAR
    # Truy vết: DD-12 · ERR-07-038
    Biết F-EICAR.
    Khi tải F-EICAR.
    Thì tác vụ `SCANNING` → `FAILED`, `ERR-07-038`; không có dòng nào trong `import_row`; KT: có (sự kiện an ninh tệp nhiễm).

  @TC-07-306 @P1 @Bảo @mật
  Kịch bản: TC-07-306 Bom nén
    # Truy vết: FR-07-021 · ERR-07-019 · ASVS V12.1
    Biết F-ZIPBOMB.
    Khi tải F-ZIPBOMB.
    Thì bộ đọc dừng khi tỉ lệ nén vượt ngưỡng; `FAILED` `ERR-07-019`; bộ nhớ pod không tăng quá 200 MB.

  @TC-07-307 @P1 @Bảo @mật
  Kịch bản: TC-07-307 XXE trong xlsx
    # Truy vết: FR-07-021 · ASVS V5.5
    Biết F-XXE.
    Khi tải F-XXE.
    Thì thực thể ngoài không được phân giải; không có nội dung `/etc/passwd` trong dữ liệu xem trước hay nhật ký.

  @TC-07-308 @P1 @Bảo @mật
  Kịch bản: TC-07-308 Chèn công thức khi xuất (CSV injection)
    # Truy vết: FR-07-024 · ASVS V5.2
    Biết F-FORMULA đã nhập vào bản nháp thử.
    Khi xuất CSV và xlsx.
    Thì Ô bắt đầu bằng `=`, `+`, `-`, `@`, tab, CR được thêm dấu nháy đơn đầu ô; mở trong trình bảng tính không chạy công thức.

  @TC-07-309 @P1 @Bảo @mật
  Kịch bản: TC-07-309 Thao túng định danh đối tượng (IDOR) trong tenant
    # Truy vết: ASVS V4.2 · ERR-07-046
    Biết U-T68-DS-MT, tác vụ nhập của U-T68-DS-NV.
    Khi DS-MT xác nhận ghi (`commit`) tác vụ nhập của DS-NV.
    Thì `403` `ERR-07-046`.

  @TC-07-310 @P2 @Bảo @mật @Âm
  Kịch bản: TC-07-310 Thiếu If-Match và chống ghi đè mất dữ liệu
    # Truy vết: ERR-07-040 · ASVS V13
    Biết —.
    Khi gọi các API sửa (API-07-004, 014, 028) không có `If-Match`.
    Thì `400` `ERR-07-040`.

  @TC-07-311 @P2 @Bảo @mật
  Kịch bản: TC-07-311 Giới hạn tần suất và kích thước thân
    # Truy vết: ERR-07-042, 044 · `07.rdm.batch-rate-per-minute`
    Biết APP-T68-WRITE.
    Khi gửi 11 lô trong một phút.
    Và gửi thân 70 MB.
    Thì lô thứ 11 `429` `ERR-07-044` có `Retry-After`. Bước 2 `413` `ERR-07-042`.

  @TC-07-312 @P3 @Bảo @mật @Âm
  Kịch bản: TC-07-312 Kiểu nội dung không hỗ trợ
    # Truy vết: ERR-07-043
    Biết —.
    Khi gửi `POST /catalogs` với `Content-Type: application/xml`.
    Thì `415` `ERR-07-043`.

  @TC-07-313 @P2 @Bảo @mật
  Kịch bản: TC-07-313 Không lộ thông tin trong lỗi và tiêu đề bảo mật
    # Truy vết: ASVS V7, V14 · SEC-40…49
    Biết quét ZAP chủ động có xác thực với từng vai trò.
    Khi chạy quét trên `/api/rdm/v1` và các route console PH-07.
    Thì không cảnh báo mức Cao; phản hồi lỗi không có ngăn xếp, tên lớp, câu SQL; có `Strict-Transport-Security`, `Content-Security-Policy`, `X-Content-Type-Options`.

  @TC-07-314 @P1 @Bảo @mật
  Kịch bản: TC-07-314 Dữ liệu cá nhân không vào danh mục
    # Truy vết: BR-07-025 · ERR-07-036 · Luật 91/2025/QH15
    Biết —.
    Khi khai báo thuộc tính `so_cccd` không có `piiAcknowledged`.
    Và khai báo thuộc tính mức `SENSITIVE`.
    Thì bước 1 `422` `ERR-07-036` kèm từ khớp. Bước 2 `422` `ERR-07-036`.

  @TC-07-315 @P2 @Bảo @mật
  Kịch bản: TC-07-315 Nhật ký không chứa token và dữ liệu nhạy cảm
    # Truy vết: ASVS V7.1 · SEC-60…67
    Biết mức nhật ký INFO.
    Khi chạy toàn bộ TS-07-23 rồi tìm trong nhật ký chuỗi token, URL ký sẵn, giá trị bản ghi CAT-RES.
    Thì không tìm thấy; URL ký sẵn chỉ ghi phần đường dẫn không có chữ ký.
