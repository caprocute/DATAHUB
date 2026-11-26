# language: vi
# Sinh tự động từ D05-02-PH06 bằng ph06/tools/gen_gherkin.py; không sửa tay.
@PH-06 @TS-06-06
Tính năng: TS-06-06 · Nạp tệp lô có xem trước

  @TC-06-025 @P1 @Dương
  Kịch bản: TC-06-025 Nạp tệp 2.000 dòng có xem trước và xác nhận
    # Truy vết: FR-06-013 · API-06-023, 024, 025 · UI-06-11 · PERM-06-ingest
    # Mục đích: Chứng minh pha 1 báo cáo lỗi theo dòng, pha 2 chỉ ghi sau xác nhận, theo FR-06-013.
    Biết F-FILE `ung-vien-2000.xlsx` (50 dòng lỗi); DS1; nguồn `FILE-NHAP`.
    Khi `POST /domains/CITIZEN/candidate-files` tải tệp; chờ pha 1.
    Và `GET /candidate-files/{id}`: xem báo cáo và 50 dòng đầu.
    Và chọn "Chỉ nạp dòng hợp lệ", `:confirm`.
    Thì pha 1 báo cáo 50 dòng lỗi theo dòng, cột; chưa có ứng viên nào. Sau `:confirm` job `FILE_INGEST` `SUCCEEDED`, 1.950 ứng viên kênh `FILE`, `sourceKey = fileId:dòng`. Tệp tạm ở Garage mã hóa, xóa sau xử lý. KT: có (file-confirm).
    # Hậu điều kiện: 1.950 ứng viên của `FILE-NHAP`.

  @TC-06-026 @P1 @Âm
  Kịch bản: TC-06-026 Tệp có công thức, quá lớn, tất cả hoặc không
    # Truy vết: FR-06-013 · API-06-023, 024 · ERR-06-018, 019
    # Mục đích: Chứng minh tệp sai khuôn bị chặn và mặc định "tất cả hoặc không", theo FR-06-013.
    Biết F-FILE `ung-vien-cong-thuc.xlsx`, `ung-vien-lon.csv`, `ung-vien-2000.xlsx`.
    Khi tải tệp có công thức `=HYPERLINK(...)`.
    Và tải tệp vượt giới hạn.
    Và tải tệp 2.000 dòng có 50 dòng lỗi, `:confirm` mặc định.
    Thì bước 1 `422` ERR-06-019, không có ứng viên. Bước 2 `413` ERR-06-018. Bước 3 từ chối nạp, 0 ứng viên mới.
    # Hậu điều kiện: Không ứng viên.
