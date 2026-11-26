# language: vi
# Sinh tự động từ D05-02-PH09 bằng ph09/tools/gen_gherkin.py; không sửa tay.
@PH-09 @TS-09-37
Tính năng: TS-09-37 · Không lộ dữ liệu cá nhân ở sự kiện, tệp xuất và bề mặt tấn công

  @TC-09-128 @P1 @Bảo @mật
  Kịch bản: TC-09-128 Sự kiện: tên topic, lược đồ và không có giá trị DLCN
    # Truy vết: EVT-09-01…32 · NFR-09-014 · BR-09-025, 058 · FR-09-018, 061
    # Mục đích: Chứng minh 32 sự kiện theo mẫu `{tenant}.privacy.{thực-thể}.{sự-kiện}.v1`, chỉ chứa mã, mức, số lượng.
    Biết T90; chạy toàn bộ mục 4 với canary `DH-CANARY-evt`; kcat đọc mọi `t90.privacy.*`.
    Khi thu mọi bản tin sau khi chạy mục 4.
    Và kiểm tên topic, lược đồ, và tìm canary, CCCD giả, số điện thoại giả.
    Thì mọi tên chữ thường đúng mẫu, đủ 32 loại có bản tin; 0 giá trị DLCN rõ (kể cả `EVT-09-17`, `EVT-09-30`).

  @TC-09-129 @P1 @Bảo @mật
  Kịch bản: TC-09-129 Mọi tệp xuất không có DLCN rõ: phân loại, sổ, khai thác, nhật ký, hồ sơ vi phạm
    # Truy vết: FR-09-008, 013, 021, 060, 061 · API-09-030, 052, 087, 214, 217 · NFR-09-014 · BR-09-056
    # Mục đích: Chứng minh tệp xuất chỉ chứa tên trường, mã, băm, số lượng.
    Biết T90; canary `DH-CANARY-export` trong trường `SENSITIVE` của các đối tượng nguồn.
    Khi tạo năm loại tệp xuất; tải về; tìm canary và CCCD giả.
    Thì 0 lần xuất hiện; tệp có thân "đã che"; KT: có cho từng lần xuất.

  @TC-09-130 @P1 @Bảo @mật
  Kịch bản: TC-09-130 ZAP ASVS 5.0 mức 2 trên control plane và data plane (mTLS, ReDoS, tiêm mẫu)
    # Truy vết: FR-09-005, 019, 027, 028 · API-09-026, 227, 229 · ERR-09-016, 111
    # Mục đích: Chứng minh bề mặt tấn công đạt ASVS và data plane chỉ nhận chứng chỉ DU.
    Biết STAGING; control plane qua APISIX; data plane nội bộ mTLS.
    Khi chạy ZAP active scan control plane có xác thực.
    Và gọi data plane không chứng chỉ, chứng chỉ hết hạn, chứng chỉ của tenant khác.
    Và gửi mẫu phát hiện ReDoS, thân JSON lồng sâu, mẫu che chứa mã.
    Thì không lỗi mức cao; bước 2 từ chối ở kênh TLS; bước 3 `422` ERR-09-016 hoặc `400`, dịch vụ không tăng độ trễ.
