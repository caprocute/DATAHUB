# language: vi
# Sinh tự động từ D05-02-PH16 bằng ph16/tools/gen_gherkin.py; không sửa tay.
@PH-16 @TS-16-33
Tính năng: TS-16-33 · Kiểm toán và quan sát vận hành

  @TC-16-112 @P1 @Bảo @mật @Chịu
  Kịch bản: TC-16-112 Mọi thao tác ghi có kiểm toán, không mất khi PH-13 ngừng
    # Truy vết: FR-16-056 · API-16-129 · ERR-16-123 · BR-16-032 · NFR-16-012
    Biết T95; `notif-sim` (PH-13) ngừng; tập 20 thao tác ghi đại diện (tạo chỉ tiêu, duyệt, nhập tay, chốt kỳ, công bố, xuất, đổi tham số…).
    Khi thực hiện 20 thao tác khi PH-13 ngừng
    Và khởi động lại `dh-platform`
    Và bật lại PH-13
    Và đối chiếu kiểm toán ở PH-13 với danh sách thao tác
    Thì bước 1 hệ thống báo ERR-16-123 "Kiểm toán PH-16 tồn 20 bản ghi chưa chuyển" ở PH-13 sau khi có lại. Bước 2 không mất bản ghi tồn. Bước 4 đủ 20 bản ghi theo đúng thứ tự, trường đủ (người, vai trò, hành động, đối tượng, trước, sau, `traceId`), không trùng.

  @TC-16-113 @P1 @Bảo @mật
  Kịch bản: TC-16-113 Không lộ định danh cá nhân và chuỗi mồi
    # Truy vết: FR-16-010, FR-16-012 · BR-16-028 · ERR-16-101 · NFR-16-018
    Biết T90; mồi `DH-CANARY-aud` và số giả `0010990123456` đặt ở `dimensions`, `reason`, `note`, `description`; nhật ký ứng dụng, vết OTel.
    Khi đẩy quan sát với `dimensions` chứa số giả
    Và đặt mồi vào `reason`, `note`, `description`, `comment` ở các API ghi
    Và chạy mọi ca ghi, xuất báo cáo, gói quốc gia
    Và `grep` mồi ở log 5 phút, vết OTel, kiểm toán, Kafka, tệp xuất, metric
    Thì bước 1 loại ERR-16-101. Mồi ở trường văn bản tự do chỉ nằm trong bản ghi của chính nó (`reason`, `note`), không ra log, vết, metric, sự kiện, tệp xuất của phân hệ khác. Số giả không có ở bất kỳ đâu. Mồi sạch.
