# language: vi
# Sinh tự động từ D05-02-PH08 bằng ph08/tools/gen_gherkin.py; không sửa tay.
@PH-08 @TS-08-17
Tính năng: TS-08-17 · Tra cứu, xem chi tiết và xuất bản ghi lỗi

  @TC-08-087 @P1 @Dương
  Kịch bản: TC-08-087 Tra cứu, lọc và nhóm bản ghi lỗi
    # Truy vết: FR-08-037 · API-08-073, 078 · UI-08-13 · BR-08-012 · PERM-08-finding-read
    Biết `mdm-citizen` có 200 lỗi `R-CCCD-NN` `OPEN`; U-T90-DS1.
    Khi `GET /findings?assetCode=mdm-citizen&severity=CRITICAL&status=OPEN&page=0&size=50`
    Và `GET /finding-groups?assetCode=mdm-citizen`
    Thì bước 1 `items[]` có `recordKeyMasked`, `ruleCode`, `dimension`, `severity`, `fieldPath`, `maskedValue`, `status`, `firstSeenAt`, `lastSeenAt`, `issueCode`; không có giá trị gốc. Bước 2 nhóm theo (đối tượng, quy tắc, chủ quản) có số đếm 200.

  @TC-08-088 @P1 @Âm @Bảo @mật
  Kịch bản: TC-08-088 DO ngoài tổ chức, VW, tenant khác, tìm theo khóa đầy đủ
    # Truy vết: FR-08-037 · API-08-073, 129 · BR-08-026 · ERR-00-403 · ERR-08-032, 001
    Biết lỗi của `mdm-org` (ORG-TC); U-T90-DO1 (ORG-CA); U-T90-VW; U-T91-DS1.
    Khi DO1 `GET /findings?assetCode=mdm-org`
    Và VW `GET /findings`
    Và U-T91-DS1 `GET /findings/{id của T90}`
    Và DS1 `POST /findings:search` với CCCD đầy đủ `001099000001`
    Thì bước 1 `403` ERR-08-032. Bước 2 `403` ERR-00-403. Bước 3 `404` ERR-08-001 (404-ẩn). Bước 4 trả lỗi khớp qua HMAC của khóa, nhật ký và URL không chứa CCCD.

  @TC-08-089 @P2 @Dương
  Kịch bản: TC-08-089 Chi tiết bản ghi lỗi và nguồn gốc
    # Truy vết: FR-08-038 · API-08-074 · UI-08-14 · PERM-08-finding-read
    Biết lỗi `FD-0102` của `mdm-citizen`; `mdm-sim` trả nguồn gốc "HTTT Hộ tịch, 12/10/2026"; DS1 có `PERM-06-read`.
    Khi `GET /findings/FD-0102`
    Và tắt `mdm-sim`, `GET /findings/FD-0102`
    Và `GET /findings/FD-9999`
    Thì bước 1 `200`, `rule`, `history[]`, `lineage`, `suggestedOwnerOrgId`. Bước 2 vẫn `200` với dòng "Chưa lấy được nguồn gốc từ PH-06, thử lại sau.", không mã lỗi. Bước 3 `404` ERR-08-001 ("Không tìm thấy bản ghi lỗi FD-9999.").

  @TC-08-090 @P1 @Dương @Bảo @mật
  Kịch bản: TC-08-090 Xuất có trường Nhạy cảm cần DO chấp thuận
    # Truy vết: FR-08-039 · API-08-075, 076, 077 · BR-08-007, 027 · PERM-08-export · ERR-08-041
    Biết 5.000 lỗi có cột `nationalId`; DS1 đề nghị; U-T90-DO1 chấp thuận.
    Khi DS1 `POST /findings:export` lý do 30 ký tự
    Và DS1 `GET /exports/{id}`
    Và DO1 `POST /exports/{id}:approve`
    Và DS1 `GET /exports/{id}` đến `READY`, tải tệp
    Và sau 25 giờ tải lại
    Thì bước 1 `202`, `containsSensitive = true`, `PENDING_APPROVAL`. Bước 2 `409` ERR-08-041. Bước 4 `200`, tệp chỉ giá trị băm hoặc che, quét canary sạch. Bước 5 `410` ERR-08-041 (hạn tải 24 giờ). KT: có (finding.export, export.approve).

  @TC-08-091 @P1 @Âm
  Kịch bản: TC-08-091 Tự chấp thuận xuất, thiếu mục đích
    # Truy vết: FR-08-039 · API-08-075, 076 · BR-08-007 · ERR-08-007
    Biết yêu cầu xuất chờ chấp thuận do DS1 đề nghị.
    Khi DS1 `POST /exports/{id}:approve`
    Và DS1 `POST /findings:export` lý do 10 ký tự
    Thì bước 1 `403` ERR-08-005 (câu "người đề nghị xuất"). Bước 2 `422` ERR-08-007.
