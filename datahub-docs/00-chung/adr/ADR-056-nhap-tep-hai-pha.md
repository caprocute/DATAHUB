---
ma_tai_lieu: ADR-056
ten: Nhập tệp danh mục bằng tác vụ nền hai pha, đọc luồng và quét mã độc trước khi phân tích
phien_ban: 0.1
ngay: 2026-11-21
trang_thai: Đề xuất
nguoi_doc: Kiến trúc sư, Trưởng nhóm PH-07, Nhóm bảo mật, Hội đồng thẩm định
---

# ADR-056 · Nhập tệp danh mục bằng tác vụ nền hai pha, đọc luồng và quét mã độc trước khi phân tích

## Bối cảnh

Nhập Excel và CSV là cách chính để cán bộ đưa danh mục vào hệ thống (FR-07-021, FR-07-022; LGC-DMDC-005…007). Tệp có thể tới 50 MB và 200.000 dòng; yêu cầu từ tải lên tới có xem trước ≤ 2 phút và commit ≤ 60 giây với 100.000 dòng (NFR-07-005), trong khi pod `dh-data` giới hạn 2 GB bộ nhớ (NFR-07-012). Người dùng cần xem trước kết quả và lỗi theo dòng trước khi ghi, và việc ghi phải là tất cả hoặc không (BR-07-015). Tệp từ người dùng là bề mặt tấn công: macro, mã độc nhúng, ZIP bomb trong xlsx, chèn công thức. Tệp hệ cũ Aita có khuôn riêng (ô A2 là tên danh mục, dòng 4 là tên thuộc tính, từ dòng 5 là bản ghi) và CSV xuất từ Aita thường mã hóa UTF-16.

## Các phương án

Bảng thứ nhất so sánh mô hình xử lý.

| Phương án | Ưu điểm | Nhược điểm |
|---|---|---|
| A. Đồng bộ trong một yêu cầu HTTP: tải lên, phân tích, ghi luôn | Đơn giản | Vượt thời gian chờ của gateway với tệp lớn; không có xem trước; lỗi giữa chừng khó phục hồi |
| B. Một pha nền: phân tích và ghi thẳng vào bản nháp | Không cần bảng tạm | Người dùng không xem trước được; muốn hủy phải hoàn tác bản nháp |
| C. **Hai pha nền: pha 1 tải lên kho đối tượng, quét mã độc, phân tích luồng vào bảng tạm `import_row`, kiểm tra hợp lệ, trả xem trước; pha 2 commit vào bản nháp trong một giao dịch** | Có xem trước; hủy rẻ; commit nhanh vì dữ liệu đã chuẩn hóa; chịu lỗi tốt (tác vụ tiếp tục được sau khi pod khởi động lại) | Cần bảng tạm và dọn dẹp; cần kiểm tra bản nháp không đổi giữa hai pha (BR-07-016) |

Bảng thứ hai so sánh thư viện đọc và ghi tệp.

| Thư viện | Ưu điểm | Nhược điểm |
|---|---|---|
| Apache POI `XSSFWorkbook` (DOM) | Đầy đủ tính năng | Nạp toàn bộ vào bộ nhớ, 100.000 dòng có thể tốn hàng GB |
| Apache POI SAX (`XSSFReader` + `XSSFSheetXMLHandler`) | Đọc luồng, bộ nhớ thấp, có `ZipSecureFile` chống ZIP bomb | API mức thấp, mã dài; phải tự xử lý shared strings, kiểu ngày |
| **FastExcel (`org.dhatim:fastexcel-reader` / `fastexcel`)** | Đọc và ghi luồng, nhanh hơn POI SAX nhiều lần, API gọn, bộ nhớ thấp | Ít tính năng định dạng; không đọc `.xls` cũ; kiểm soát ZIP bomb phải tự thêm |
| Apache Commons CSV | Chuẩn RFC 4180, đọc luồng | Không tự nhận mã hóa |
| ICU4J `CharsetDetector` / juniversalchardet | Nhận diện mã hóa theo thống kê | ICU4J nặng (~13 MB); juniversalchardet nhẹ nhưng yếu với UTF-16 không BOM |

## Quyết định

Chọn **mô hình C** cùng bộ thư viện sau.

Đọc xlsx bằng **FastExcel reader** làm mặc định vì tốc độ và API; trước khi mở, tệp được kiểm tra cấu trúc ZIP bằng bộ kiểm tra riêng (tổng kích thước giải nén ≤ 500 MB, tỉ lệ nén ≤ 100, số mục ZIP ≤ 10.000, từ chối `vbaProject.bin`, từ chối liên kết ngoài). Apache POI SAX được giữ làm phương án dự phòng sau cờ cấu hình `datahub.rdm.import.xlsx-reader=POI_SAX` cho trường hợp tệp FastExcel không đọc được (ví dụ tệp do phần mềm cũ sinh). Tệp `.xls` (BIFF) không hỗ trợ; người dùng được hướng dẫn lưu lại thành `.xlsx`. Ghi xlsx khi xuất bằng **FastExcel writer** (đọc ghi luồng, bộ nhớ ổn định); khuôn mẫu tải về có sheet ẩn và xác thực dữ liệu dùng POI `SXSSFWorkbook` vì cần định dạng phong phú hơn.

Đọc CSV bằng **Apache Commons CSV**. Nhận mã hóa theo thứ tự: BOM (UTF-8, UTF-16 LE, UTF-16 BE) quyết định ngay; không có BOM thì thử giải mã UTF-8 nghiêm ngặt trên 64 KB đầu; nếu thất bại, dùng phép thử mẫu byte rỗng xen kẽ để nhận UTF-16 không BOM; còn lại dùng **juniversalchardet** để gợi ý (Windows-1258, TCVN3 không được tự nhận và bị từ chối với ERR-07-019 kèm hướng dẫn). Không dùng ICU4J để giữ ảnh container nhỏ.

Quét mã độc bằng **ClamAV** (`clamd` qua giao thức INSTREAM) ngay sau khi tệp vào Garage; `file_object.scan_status` phải là `CLEAN` thì tác vụ mới chuyển từ `SCANNING` sang `PARSING` (DD-12). Kiểu nội dung kiểm tra bằng chữ ký (magic bytes), không tin phần mở rộng.

Phân tích ghi `import_row` theo lô 1.000 dòng bằng `JdbcTemplate.batchUpdate`, kiểm tra hợp lệ bằng bộ kiểm tra lược đồ chung (ADR-050). Kết quả xem trước hết hạn sau 24 giờ; `import_row` bị xóa sau 7 ngày. Commit kiểm tra `catalog_version.version` không đổi kể từ lúc phân tích, rồi ghi `catalog_item` bằng `INSERT … SELECT … ON CONFLICT` từ `import_row` trong một giao dịch.

Tác vụ nền chạy bằng hàng đợi trong CSDL (`import_job` với trạng thái và `FOR UPDATE SKIP LOCKED`), không thêm hệ thống hàng đợi mới; mỗi pod chạy tối đa 2 tác vụ nhập song song (cấu hình).

## Hệ quả

Tích cực: bộ nhớ ổn định với tệp lớn (ước tính dưới 150 MB cho tệp 200.000 dòng); có xem trước và báo cáo lỗi theo dòng; tệp độc hại bị chặn trước khi thư viện phân tích chạm vào; hỗ trợ khuôn Aita giúp di trú.

Tiêu cực: phụ thuộc thêm `clamd` (triển khai dạng dịch vụ dùng chung trong cụm, đã có trong danh mục hạ tầng của PH-13) và cơ sở dữ liệu chữ ký phải cập nhật; khi ClamAV ngừng, tác vụ nhập ở trạng thái `SCANNING` chờ và hết hạn sau 1 giờ (không bỏ qua quét). Duy trì hai trình đọc xlsx tăng chi phí kiểm thử.

## Trạng thái

Đề xuất.

## Truy vết

FR-07-020, FR-07-021, FR-07-022, FR-07-024, FR-07-025; BR-07-015, BR-07-016; NFR-07-005, NFR-07-006, NFR-07-012; ERR-07-019, ERR-07-020, ERR-07-021; DD-12; LGC-DMDC-005, LGC-DMDC-006, LGC-DMDC-007. Liên quan ADR-008 (Garage), ADR-050. Thiết kế chi tiết: D03-02-PH07 §4.7, §4.8, §7.
