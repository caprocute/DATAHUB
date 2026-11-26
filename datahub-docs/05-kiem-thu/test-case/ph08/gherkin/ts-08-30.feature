# language: vi
# Sinh tự động từ D05-02-PH08 bằng ph08/tools/gen_gherkin.py; không sửa tay.
@PH-08 @TS-08-30
Tính năng: TS-08-30 · Bản ghi lỗi: dấu vân tay, che giá trị và không lộ dữ liệu Nhạy cảm

  @TC-08-137 @P1 @Dương
  Kịch bản: TC-08-137 Dấu vân tay ổn định qua kỳ và phiên bản quy tắc
    # Truy vết: FR-08-036 · API-08-073, 074 · BR-08-013
    Biết `mdm-citizen` có lỗi `R-CCCD-NN` cho khóa `001099000001` (và biến thể có khoảng trắng đầu cuối); `RS-CITIZEN` v5 rồi v6 giữ `ruleCode`; v7 đổi `ruleCode`.
    Khi đo với v5
    Và đo với v6 trên cùng dữ liệu
    Và đo với v7 (quy tắc đổi `ruleCode`)
    Và `GET /findings/{id}`
    Thì khóa ` 001099000001 ` và `001099000001` cho cùng dấu vân tay `SHA-256(T90, mdm-citizen, R-CCCD-NN, 001099000001)`. v5 → v6: cùng lỗi, `occurrences = 2`, `firstSeenScanId` giữ. v7: dấu vân tay mới, lỗi cũ `RESOLVED` lý do `RULE_RETIRED`, cảnh báo ở bản so sánh.

  @TC-08-138 @P1 @Dương @Biên
  Kịch bản: TC-08-138 Vòng đời lỗi mới, còn, hết, mở lại và phạm vi lấy mẫu
    # Truy vết: FR-08-036 · FR-08-029 · API-08-065, 073 · BR-08-034 · EVT-08-06
    Biết kỳ 1 có 100 lỗi; kỳ 2 còn 60, hết 40, mới 15; một lỗi đã `RESOLVED` tái xuất; một bản ghi bị xóa ở nguồn; một lỗi `WAIVED`.
    Khi đo `FULL` kỳ 1
    Và đo `FULL` kỳ 2
    Và đo `SAMPLE` kỳ 3 (mẫu không chứa 20 lỗi cũ)
    Và `GET /scans/{id}/score`
    Thì kỳ 2: `findingsNew = 15`, `findingsPersisting = 60`, `findingsResolved = 40` (`CLEARED`); lỗi tái xuất về `OPEN`, `reopenCount + 1`; bản ghi xóa `RESOLVED` lý do `RECORD_REMOVED`; lỗi `WAIVED` còn thấy vẫn `WAIVED`. Kỳ 3 chỉ giải quyết lỗi nằm trong mẫu, 20 lỗi ngoài mẫu giữ nguyên. EVT-08-06 một lần mỗi lần đo.

  @TC-08-139 @P1 @Bảo @mật
  Kịch bản: TC-08-139 Che giá trị theo phân loại và leak scan
    # Truy vết: FR-08-036 · FR-08-005 · API-08-073 · BR-08-012 · NFR-08-016
    Biết `nationalId` `SENSITIVE` (`HASH`), `fullName` và `phone` `RESTRICTED` (`PARTIAL`), `note` `PUBLIC` (`NONE`); canary `DH-CANARY-leak` đặt ở `nationalId`; CCCD giả dải `0010990xxxxx`.
    Khi chạy hồ sơ, chạy thử, đo lô, mở phiếu, xuất lỗi, sinh báo cáo
    Và đọc `maskedValue` mỗi trường
    Và quét `ph08_dq`, log 5 phút, vết OTel, outbox, Kafka, tệp xuất, báo cáo tìm canary và mẫu CCCD, MST, SĐT dạng rõ
    Thì `nationalId` lưu HMAC-SHA-256 khóa tenant (64 ký tự hex); `phone` dạng `0978`; `note` tối đa 255 ký tự; khóa bản ghi là CCCD lưu `recordKeyHash`, hiển thị bản che; quét 0 kết quả (Mồi sạch).

  @TC-08-140 @P1 @Âm @Bảo @mật
  Kịch bản: TC-08-140 Cố hạ che, cố đọc giá trị gốc, phân loại chưa xác nhận
    # Truy vết: FR-08-036 · FR-08-005 · FR-08-038 · API-08-014, 015, 074 · BR-08-012 · ERR-08-047
    Biết lỗi cũ của `fullName` che `PARTIAL`; PH-09 nâng `fullName` lên `SENSITIVE`; CDE `email` chưa xác nhận.
    Khi `POST /assets/mdm-citizen/fields:sync-classification`
    Và đọc lại các lỗi cũ của `fullName`
    Và tìm API trả giá trị gốc (mọi `GET` ở `/findings`, `/profile-runs`, `/scans`)
    Và kích hoạt đối tượng có CDE `email` `PROPOSED`
    Thì job nền che lại lỗi cũ thành `HASH`. Không API nào trả giá trị gốc; người có `PERM-09-unmask` đọc lại nguồn qua PH-09 (Q08-07). Trường chưa xác nhận che như `SENSITIVE` kèm cảnh báo ERR-08-047.
