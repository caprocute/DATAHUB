# language: vi
# Sinh tự động từ D05-02-PH09 bằng ph09/tools/gen_gherkin.py; không sửa tay.
@PH-09 @TS-09-17
Tính năng: TS-09-17 · Mô phỏng, duyệt và phát hành chính sách che

  @TC-09-057 @P1 @Dương
  Kịch bản: TC-09-057 Mô phỏng che trên mẫu F-SIM theo vai trò, mục đích, kênh
    # Truy vết: FR-09-025 · API-09-101 · UI-09-11 · BR-09-025 · LGC-TOOL-012
    # Mục đích: Chứng minh kết quả xem trước đúng mẫu che và dữ liệu mẫu không bị ghi lại.
    Biết T90; F-SIM 1.000 dòng (CCCD `001090000101`, điện thoại `0912345678`, thư `an.nguyen@example.test`, sinh `1990-03-12`); chính sách nháp của ca mask-policy-create.
    Khi DS1 `POST /mask-simulations` vai `ROLE-DATA_STEWARD`, mục đích `MD-TRACUU-HGD`, kênh `UI`.
    Và gọi lại với kênh `EXPORT` và vai `ROLE-VIEWER`.
    Thì bước 1 CCCD `*101`, điện thoại `091*78`, thư `a*@example.test`, ngày sinh `1990`, họ tên giữ họ. Bước 2 theo quy tắc kênh `EXPORT` chặt hơn. Mồi sạch với dữ liệu mẫu trong log và bảng `ph09_privacy.*` sau khi xong; 1.000 dòng ≤ 5 giây (NFR-09-023).

  @TC-09-058 @P1 @Âm
  Kịch bản: TC-09-058 Mẫu quá 1.000 dòng, gửi duyệt khi chưa mô phỏng đạt
    # Truy vết: FR-09-025, 026 · API-09-101, 096 · ERR-09-039, 040, 080 · BR-09-023
    # Mục đích: Chứng minh giới hạn mẫu và điều kiện mô phỏng đạt (BR-09-023).
    Biết T90; U-T90-DS1; tệp 1.001 dòng.
    Khi DS1 `POST /mask-simulations` với 1.001 dòng.
    Và DS1 `:submit` phiên bản chưa có mô phỏng đạt.
    Và DS1 gửi mẫu có số định danh đúng kiểm tổng ngoài miền giả (giá trị lấy từ kho dữ liệu thử, không ghi trong tài liệu).
    Thì bước 1 `413` ERR-09-039. Bước 2 `422` ERR-09-040. Bước 3 `422` ERR-09-080 "Dữ liệu mẫu có dấu hiệu là dữ liệu cá nhân thật. Chỉ dùng dữ liệu giả."

  @TC-09-059 @P1 @Dương @Âm
  Kịch bản: TC-09-059 Duyệt bốn mắt, kích hoạt, so sánh và quay lại phiên bản
    # Truy vết: FR-09-026 · API-09-097, 098, 099, 100 · ERR-09-005 · EVT-09-12 · BR-09-023
    # Mục đích: Chứng minh người soạn không duyệt dù có đủ quyền và phát hành đổi kế hoạch che.
    Biết T90; phiên bản 2 đã mô phỏng đạt; U-T90-DS1 (soạn), U-T90-DA1; TA có cả `PERM-09-policy` và `PERM-09-policy-approve`.
    Khi DS1 `:submit` rồi tự `:approve`; TA là người soạn cũng tự `:approve`.
    Và DA1 `:approve`.
    Và `GET .../versions/2/diff`; DA1 `POST /mask-policies/{id}:rollback`.
    Thì bước 1 `403` ERR-09-005 cho cả hai. Bước 2 `ACTIVE`, bản 1 `SUPERSEDED`, EVT: `mask-policy.activated`, KT: có (mask-policy-approve). Bước 3 diff liệt kê quy tắc đổi; quay lại tạo bản 3 giống bản 1, EVT: `mask-policy.activated`.
