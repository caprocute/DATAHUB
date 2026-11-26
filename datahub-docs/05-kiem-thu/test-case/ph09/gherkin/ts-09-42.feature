# language: vi
# Sinh tự động từ D05-02-PH09 bằng ph09/tools/gen_gherkin.py; không sửa tay.
@PH-09 @TS-09-42
Tính năng: TS-09-42 · Tương đương hệ cũ và chức năng cũ của SRS repo

  @TC-09-147 @P1 @Dương
  Kịch bản: TC-09-147 Bốn chế độ cũ none, mask, pseudonymize, anonymize và quy tắc che cũ còn đạt được
    # Truy vết: LGC-TOOL-012 · FR-09-023, 024, 028, 032, 036 · API-09-091, 229 · UI-09-10
    # Mục đích: Chứng minh chính sách tập trung tái tạo được kết quả của bước che cấu hình tay từng luồng (hệ cũ) và có thêm kiểu mới.
    Biết T90; F-MSG; quy tắc che cũ của SRS (số định danh giữ 4 đầu 4 cuối, họ tên che tên, điện thoại giữ 3 đầu 2 cuối).
    Khi cấu hình mẫu `KEEP_FIRST_LAST` n = 4 cho số định danh; `none` thành `NONE`, `mask` thành `PARTIAL`, `pseudonymize` thành `KEYED_HASH` hoặc `TOKENIZE`, `anonymize` thành job ARX.
    Và `messages:apply` F-MSG cho từng kiểu.
    Thì CCCD `001090000101` cho `00100101`; mỗi chế độ cũ có kết quả tương đương; thêm `GENERALIZE`, `DROP`, `REPLACE` (nâng cấp); một chính sách thay cấu hình riêng từng luồng, có phiên bản.

  @TC-09-148 @P1 @Dương @Âm
  Kịch bản: TC-09-148 Tra cứu hộ gia đình giữ nguyên kết quả, thêm kiểm soát mục đích và ghi vết
    # Truy vết: LGC-NGSP-003 · FR-09-014, 015, 016, 019, 020 · API-09-227, 237 · ERR-09-102
    # Mục đích: Chứng minh chức năng tra cứu của PH-14 không đổi kết quả và PH-09 chỉ thêm kiểm soát (FRS 11.1).
    Biết T90; PH-14 giả lập trả kết quả tra BHXH; HTTT-BH có chấp thuận `MD-TRACUU-HGD`; HTTT-TK không có.
    Khi HTTT-BH tra mã BHXH hộ gia đình qua PH-14 khi có chấp thuận.
    Và HTTT-TK tra cùng mã.
    Và thu hồi chấp thuận của HTTT-BH; tra lại.
    Thì bước 1 kết quả giống trước khi có PH-09, trường được phép đúng điều kiện chấp thuận, lượt khai thác được đếm. Bước 2 và 3 `403` ERR-09-102, ghi vết và báo lượt.

  @TC-09-149 @P2 @Dương @Âm
  Kịch bản: TC-09-149 Đối chiếu FR-09-001…009 của SRS cũ với hành vi mới
    # Truy vết: FR-09-004, 007, 029, 033, 034, 035, 036, 037, 038 · BR-09-001, 032, 035 · ERR-09-053, 054 · LGC-TOOL-012
    # Mục đích: Chứng minh từng điểm của SRS cũ có chỗ xử lý, và các khác biệt chủ ý của FRS được kiểm đúng hành vi mới.
    Biết T90, T96; bảng so sánh SRS cũ (FR-09-001…009) và FRS 0.1.
    Khi trường chưa phân loại: SRS cũ coi là mức mật và chặn; chạy `classification:check` với trường chưa phân loại.
    Và khôi phục hàng loạt: SRS cũ yêu cầu duyệt riêng khi hơn 10 bí danh; thử 11 và 101 token.
    Và ẩn danh hóa AI: SRS cũ yêu cầu k cao hơn thông thường; thử k = 10 và k = 20 cho `AI_TRAINING`.
    Và ẩn danh hóa còn dưới 30 % bản ghi: SRS cũ cảnh báo; chạy F-ANON-S.
    Thì bước 1 FRS mới xử lý như `SENSITIVE` (BR-09-001) và không chặn bản tin, khác SRS cũ (ĐN-TC-05). Bước 2 11 token vẫn cần chuỗi duyệt ba người, 101 token `422` ERR-09-049. Bước 3 k = 10 được chấp nhận, không có ngưỡng k riêng cho AI (ĐN-TC-06). Bước 4 từ chối `422` ERR-09-054, chặt hơn cảnh báo cũ.
