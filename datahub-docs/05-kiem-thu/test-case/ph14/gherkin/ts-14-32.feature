# language: vi
# Sinh tự động từ D05-02-PH14 bằng ph14/tools/gen_gherkin.py; không sửa tay.
@PH-14 @TS-14-32
Tính năng: TS-14-32 · Không lộ bí mật và dữ liệu cá nhân

  @TC-14-081 @P1 @Bảo @mật
  Kịch bản: TC-14-081 Dò mồi `DH-CANARY` ở mọi nơi có thể rò
    # Truy vết: NFR-14-015 · BR-14-004, 005 · FR-14-025, 026, 050 · API-14-039, 063, 066 · ERR-14-127.
    Biết thông tin xác thực nền tảng, khóa chứng thư, hồ sơ BHXH đều mang mồi; chạy đủ TS-14-09…17, 28.
    Khi quét phản hồi mọi API, nhật ký ứng dụng, vết OpenTelemetry, tệp xuất, sự kiện Kafka, bảng PostgreSQL, ảnh bộ nhớ pod.
    Và gây lỗi nội bộ có ngăn xếp (`ERR-14-127`).
    Thì 0 mồi thông tin xác thực, khóa ở mọi nơi ngoài OpenBao; 0 mồi DLCN ngoài nội dung bản tin mã hóa; thân lỗi không có ngăn xếp.

  @TC-14-082 @P1 @Bảo @mật @Biên
  Kịch bản: TC-14-082 Nội dung bản tin mã hóa theo khóa tenant, thời hạn lưu
    # Truy vết: BR-14-021 · NFR-14-021 · FR-14-050 · SEC-33.
    Biết `14.txn.payload-retention-days` 30 rồi 0.
    Khi gọi dịch vụ, đọc bản ghi lưu nội dung ở CSDL.
    Và đặt 0, gọi lại; tiến đồng hồ 31 ngày.
    Thì nội dung là bản mã, giải bằng khóa tenant mới đọc được; đặt 0 thì không lưu; quá 30 ngày nội dung bị xóa, siêu dữ liệu giữ 5 năm.

  @TC-14-139 @P1 @Bảo @mật @Âm
  Kịch bản: TC-14-139 Khóa riêng không rời OpenBao: không xuất được, hồ sơ khác không gọi được
    # Truy vết: BR-14-004 · FR-14-026, 028 · NFR-14-015 · SEC-32 · ERR-14-020.
    Biết K-KY-01 với khóa `transit` của T68 (không cho xuất); hồ sơ OpenBao của `national-gateway` T68 và của T01; token dịch vụ `dh-integration`; mồi `DH-CANARY-KEY`.
    Khi bằng hồ sơ `national-gateway` T68, gọi `transit/export` và `transit/keys` đọc khóa riêng của K-KY-01.
    Và bằng hồ sơ `national-gateway` T01, gọi `transit/sign` với khóa của T68.
    Và bằng token `dh-integration`, gọi `transit/sign` với khóa của T68.
    Và nạp chứng thư mới có khóa không khớp khóa trong OpenBao.
    Và quét PostgreSQL, tệp xuất, nhật ký, đĩa bản sao cổng tìm khóa riêng.
    Thì bước 1 bị từ chối, không có khóa riêng trả về. Bước 2 và 3 bị OpenBao từ chối (chỉ hồ sơ `national-gateway` của đúng tenant được ký). Bước 4 `422` ERR-14-020. Bước 5 không tìm thấy khóa riêng; mọi lượt ký trong nhật ký OpenBao chỉ có giá trị băm.

  @TC-14-140 @P1 @Bảo @mật @Âm
  Kịch bản: TC-14-140 Thông báo lỗi không lộ nội dung kỹ thuật, địa chỉ, vết ngăn xếp, bí mật
    # Truy vết: FR-14-015 · BR-14-005 · NFR-14-015 · API-14-075 · ERR-14-101, 102, 109, 114, 127, 128.
    Biết S-HT-MC; `sim-ndxp` các chế độ `ERR5XX`, `BIZ404`, `BADSIG`, `AUTH401`; thân lỗi của trung ương chứa địa chỉ máy chủ nội bộ, vết ngăn xếp và `DH-CANARY-ERR`; một lỗi nội bộ gây ra bằng cách cố ý hỏng cấu hình.
    Khi gọi dịch vụ ở từng chế độ lỗi của `sim-ndxp`.
    Và gây lỗi nội bộ của PH-14.
    Và quét thân phản hồi, nhật ký ứng dụng, vết, giao dịch ở UI-14-12 tìm địa chỉ máy chủ, vết ngăn xếp, tên lớp, `Authorization`, `DH-CANARY-ERR`.
    Thì mọi thân lỗi dạng RFC 9457 chỉ có `code`, `detail` theo câu chuẩn, `category`, `retryable`, `upstreamCode`, `transactionCode`, `traceId`. Lỗi `BADSIG` chỉ có câu "Không thể tin cậy dữ liệu nhận được. Sự cố đã được ghi nhận và báo cán bộ an toàn thông tin." và không có dữ liệu. Lỗi nội bộ `500` ERR-14-127 "Hệ thống gặp lỗi. Sự cố đã được ghi nhận, hãy báo mã truy vết {mã} cho bộ phận hỗ trợ." Không nơi nào có nội dung kỹ thuật của trung ương hay mồi.
