# language: vi
# Sinh tự động từ D05-02-PH06 bằng ph06/tools/gen_gherkin.py; không sửa tay.
@PH-06 @TS-06-31
Tính năng: TS-06-31 · Kiểm toán, mã hóa số định danh và an toàn dữ liệu

  @TC-06-129 @P1 @Bảo @mật
  Kịch bản: TC-06-129 Quét giá trị SENSITIVE dạng rõ ở mọi nơi lưu
    # Truy vết: NFR-06-016 · BR-06-012, 016 · FR-06-004, 034
    # Mục đích: Chứng minh tiêu chí chấp nhận 7: 100 % thuộc tính `SENSITIVE` mã hóa envelope (ADR-032) khi lưu.
    Biết T90 nạp 2.000 ứng viên có canary `DH-CANARY-sec` và CC-xx giả trong thuộc tính `SENSITIVE`.
    Khi quét `ph06_mdm.*` (ứng viên, `golden`, `golden_history`, `match_result`, staging, outbox).
    Và quét log 5 phút, vết OTel, topic `t90.mdm.*`, tệp xuất, bản sao lưu logic.
    Và quét phản hồi API bằng vai không có `PERM-09-unmask`.
    Thì không thấy canary, CCCD giả rõ ở nơi nào; cột nhạy cảm ở dạng bản mã có `key_id`; khóa gom nhóm, staging chỉ HMAC.
    # Hậu điều kiện: Báo cáo quét đính kèm.

  @TC-06-130 @P1 @Âm @Chịu @lỗi
  Kịch bản: TC-06-130 Không giải mã được và xoay khóa
    # Truy vết: ERR-06-113 · NFR-06-016 · FR-06-056
    # Mục đích: Chứng minh lỗi giải mã không lộ dữ liệu và job `REENCRYPT` xoay khóa không gián đoạn.
    Biết T95; OpenBao giả lập khóa mất, rồi khóa mới.
    Khi gỡ khóa của một bản ghi, `GET` bản ghi.
    Và chạy `REENCRYPT` với khóa mới trong lúc k6 đọc 50 lượt mỗi giây.
    Thì bước 1 thuộc tính lỗi bị bỏ, ERR-06-113 ở nhật ký, cảnh báo vận hành, các thuộc tính khác vẫn trả. Bước 2 job `SUCCEEDED`, 0 lỗi đọc, mọi bản mã mang `key_id` mới.
    # Hậu điều kiện: Khóa cũ nghỉ hưu.

  @TC-06-131 @P1 @Bảo @mật
  Kịch bản: TC-06-131 Số access_log khớp số lượt ở cổng
    # Truy vết: NFR-06-015 · BR-06-010 · FR-06-057
    # Mục đích: Chứng minh 100 % lượt trả dữ liệu có đúng một dòng `access_log`.
    Biết T97; 10.000 lượt hỗn hợp `lookup`, `resolve`, `search`, chi tiết, xuất, so sánh.
    Khi chạy tải, thu số lượt `2xx` ở APISIX.
    Và đếm `access_log` cùng khoảng.
    Thì hai số bằng nhau, không dòng thiếu hoặc thừa; mỗi dòng có người hoặc HTTT, mục đích, số bản ghi, `traceId`.
    # Hậu điều kiện: Không đổi.

  @TC-06-132 @P1 @Bảo @mật
  Kịch bản: TC-06-132 Kiểm toán thay đổi đủ trường, không chứa DLCN
    # Truy vết: FR-06-002, 006, 030, 036, 037, 038, 039, 049, 053 · BR-06-008, 012
    # Mục đích: Chứng minh mọi thao tác thay đổi có kiểm toán PH-13 đủ trường FR-00-041 và không chứa giá trị DLCN.
    Biết các thao tác đã chạy ở TS-06-02…25 với canary.
    Khi đối chiếu danh sách thao tác với bản ghi kiểm toán.
    Và quét nội dung kiểm toán tìm canary.
    Thì số thao tác bằng số bản ghi; có người, thời điểm, đối tượng, lý do, trước và sau chỉ ở dạng tên thuộc tính; Mồi sạch.
    # Hậu điều kiện: Không đổi.

  @TC-06-133 @P2 @Bảo @mật
  Kịch bản: TC-06-133 Quét ZAP API và chống tiêm, ReDoS
    # Truy vết: API-06-001…096 · FR-06-003, 048
    # Mục đích: Chứng minh không cảnh báo High ở `/api/mdm/v1` (ASVS 5.0 mức 2).
    Biết STAGING, token thử đủ quyền.
    Khi ZAP API scan theo OpenAPI có xác thực.
    Và tiêm SQL, `REGEX` ReDoS, thân quá lớn vào `search`, `identifier-rules:test`, tệp nạp.
    Thì 0 cảnh báo High; Medium đã phân loại; mọi tiêm bị từ chối `400`, `422`, `413`, không treo.
    # Hậu điều kiện: Báo cáo ZAP.
