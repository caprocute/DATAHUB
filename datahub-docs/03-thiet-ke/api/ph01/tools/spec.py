"""Nguồn chuẩn danh mục operation PH-01 (API-01-nnn).

Mỗi dòng: (mã, phương thức, đường dẫn, mục đích, FR, quyền, idem, mã thành công, nhóm).
 - quyền: `read`, `create`… là PERM-01-{x}; `PERM-18-…` giữ nguyên; `service` là token dịch vụ;
   `base` là quyền cơ sở người dùng nội bộ tenant; `link` là người nhận liên kết một lần (đăng nhập, MFA).
 - mã thành công: "200|202" nghĩa là có hai mã thành công hợp lệ (mã đầu là mã thường gặp).
Sinh OpenAPI (gen_openapi.py), AsyncAPI và bảng Markdown (gen_md.py) từ đây; không sửa tay bảng sinh ra.
Mã API-01-001…086 theo FRS §9.4; 087, 088 do tập này thêm (callback saga, tra tác vụ nền).
"""

BASE = "/api/onboarding/v1"

OPS = [
    # Hồ sơ HTTT
    ("001", "GET", "/systems", "Danh sách, tìm kiếm, lọc HTTT thành viên", "001", "read", "", "200", "sys"),
    ("002", "GET", "/systems/{systemCode}", "Chi tiết HTTT thành viên", "002", "read", "", "200", "sys"),
    ("003", "GET", "/systems/{systemCode}/history", "Lịch sử trạng thái và thay đổi của HTTT", "002", "read", "", "200", "sys"),
    ("004", "POST", "/systems", "Tạo hồ sơ kết nạp nháp", "003", "create", "x", "201", "sys"),
    ("005", "PATCH", "/systems/{systemCode}", "Sửa hồ sơ nháp (tự lưu)", "004", "create", "", "200", "sys"),
    ("018", "DELETE", "/systems/{systemCode}", "Xóa hồ sơ nháp chưa từng nộp", "009", "submit", "", "204", "sys"),
    ("019", "POST", "/systems/{systemCode}:withdraw", "Rút hồ sơ đã nộp về nháp", "009", "submit", "", "200", "sys"),
    ("034", "GET", "/systems/{systemCode}/progress", "Theo dõi tiến độ hồ sơ", "019", "read", "", "200", "sys"),
    # Tài liệu và mẫu
    ("006", "GET", "/systems/{systemCode}/attachments", "Danh sách tài liệu đính kèm", "005", "read", "", "200", "attach"),
    ("007", "POST", "/systems/{systemCode}/attachments", "Tải tài liệu đính kèm", "005", "create", "x", "201", "attach"),
    ("008", "GET", "/systems/{systemCode}/attachments/{attachmentId}/content", "Tải nội dung tài liệu", "005", "read", "", "200", "attach"),
    ("009", "DELETE", "/systems/{systemCode}/attachments/{attachmentId}", "Xóa tài liệu đính kèm", "005", "create", "", "204", "attach"),
    ("020", "GET", "/templates", "Danh sách mẫu văn bản và hướng dẫn kết nạp", "010", "base", "", "200", "attach"),
    ("021", "GET", "/templates/{templateCode}/content", "Tải nội dung mẫu văn bản", "010", "base", "", "200", "attach"),
    # Hồ sơ kỹ thuật và nhu cầu
    ("010", "PUT", "/systems/{systemCode}/technical-profile", "Khai hồ sơ năng lực kỹ thuật", "006", "create", "", "200", "tech"),
    ("011", "GET", "/systems/{systemCode}/technical-profile", "Xem hồ sơ năng lực kỹ thuật và nhóm đề xuất", "006", "read", "", "200", "tech"),
    ("012", "PUT", "/systems/{systemCode}/data-demands", "Khai danh sách nhu cầu khai thác", "007", "create", "", "200", "tech"),
    ("013", "GET", "/systems/{systemCode}/data-demands", "Xem nhu cầu khai thác và trần phạm vi", "007", "read", "", "200", "tech"),
    # Đầu mối
    ("014", "GET", "/systems/{systemCode}/contacts", "Danh sách đầu mối của HTTT", "008", "read", "", "200", "contact"),
    ("015", "POST", "/systems/{systemCode}/contacts", "Thêm hoặc thay thế đầu mối", "008", "create", "x", "201", "contact"),
    ("016", "PATCH", "/systems/{systemCode}/contacts/{contactId}", "Sửa đầu mối", "008", "create", "", "200", "contact"),
    ("017", "DELETE", "/systems/{systemCode}/contacts/{contactId}", "Bỏ đầu mối", "008", "create", "", "204", "contact"),
    # Kiểm tra, nộp, thẩm định, phê duyệt
    ("022", "POST", "/systems/{systemCode}:validate", "Kiểm tra hợp lệ hồ sơ trước khi nộp", "011", "submit", "", "200", "review"),
    ("023", "POST", "/systems/{systemCode}:submit", "Nộp hồ sơ kết nạp", "012", "submit", "x", "200", "review"),
    ("024", "POST", "/systems/{systemCode}/reviews/technical", "Ghi kết luận thẩm định kỹ thuật", "013", "assigned", "", "200", "review"),
    ("025", "POST", "/systems/{systemCode}/reviews/{reviewKind}", "Ghi kết luận thẩm định pháp lý hoặc ATTT", "014", "assigned", "", "200", "review"),
    ("026", "POST", "/systems/{systemCode}/reviews/quota-impact", "Đánh giá tác động tới hạn mức dữ liệu quốc gia", "015", "assigned", "", "200", "review"),
    ("027", "GET", "/review-queue", "Hàng đợi thẩm định", "016", "read", "", "200", "review"),
    ("028", "POST", "/systems/{systemCode}/reviews:assign", "Phân công người thẩm định", "016", "approve", "", "200", "review"),
    ("029", "POST", "/systems/{systemCode}/reviews:consult", "Gửi tham vấn, tạm dừng đồng hồ hạn", "016", "assigned", "", "200", "review"),
    ("030", "POST", "/systems/{systemCode}/reviews:resume", "Kết thúc tham vấn, chạy lại đồng hồ hạn", "016", "assigned", "", "200", "review"),
    ("031", "POST", "/systems/{systemCode}:return", "Trả bổ sung hồ sơ", "017", "assigned", "", "200", "review"),
    ("032", "POST", "/systems/{systemCode}:approve", "Phê duyệt kết nạp", "018", "approve", "", "200", "review"),
    ("033", "POST", "/systems/{systemCode}:reject", "Từ chối kết nạp", "018", "approve", "", "200", "review"),
    # Định danh và bàn giao
    ("035", "POST", "/systems/{systemCode}/credentials:provision", "Thử lại cấp định danh SANDBOX", "020", "credential", "x", "202", "cred"),
    ("036", "GET", "/systems/{systemCode}/provisioning", "Tiến độ saga cấp định danh", "020", "read", "", "200", "cred"),
    ("037", "PUT", "/credentials/{credentialId}/public-key", "Đăng ký khóa công khai (JWKS) hoặc nộp CSR", "021", "credential", "", "200", "cred"),
    ("038", "POST", "/credentials/{credentialId}:sign-csr", "Ký chứng thư cho CSR đã nộp", "021", "credential", "", "200", "cred"),
    ("039", "POST", "/credentials/{credentialId}/handovers", "Tạo liên kết bàn giao một lần", "022", "credential", "x", "201", "cred"),
    ("040", "POST", "/handovers:open", "Mở liên kết bàn giao, nhận bí mật một lần", "022", "link", "", "200", "cred"),
    ("041", "POST", "/handovers/{handoverId}:reissue", "Tạo lại liên kết bàn giao", "022", "credential", "x", "201", "cred"),
    ("042", "POST", "/systems/{systemCode}/sandbox-tests", "Làm mới kết quả kiểm thử SANDBOX", "023", "read", "x", "200", "cred"),
    ("043", "GET", "/systems/{systemCode}/sandbox-tests", "Kết quả kiểm thử SANDBOX", "023", "read", "", "200", "cred"),
    ("045", "POST", "/credentials/{credentialId}:rotate", "Bắt đầu xoay vòng thông tin xác thực", "025", "credential", "x", "200", "cred"),
    ("046", "POST", "/credentials/{credentialId}:finish-rotation", "Kết thúc thời gian chuyển tiếp xoay vòng", "025", "credential", "", "200", "cred"),
    ("047", "POST", "/credentials/{credentialId}:revoke", "Thu hồi định danh ứng dụng", "026", "credential", "", "200", "cred"),
    ("048", "GET", "/credentials:expiring", "Định danh sắp hết hạn", "027", "read", "", "200", "cred"),
    ("049", "GET", "/systems/{systemCode}/credentials", "Danh sách định danh của HTTT", "028", "read", "", "200", "cred"),
    ("050", "GET", "/credentials/{credentialId}", "Chi tiết một định danh (không bí mật)", "028", "read", "", "200", "cred"),
    ("061", "POST", "/credentials/{credentialId}:enable", "Bật lại định danh tự vô hiệu", "036", "credential", "", "200", "cred"),
    # Vòng đời thành viên
    ("044", "POST", "/systems/{systemCode}:activate", "Kích hoạt môi trường thật (PRODUCTION)", "024", "approve", "", "200|202", "life"),
    ("051", "POST", "/systems/{systemCode}:suspend", "Tạm ngừng HTTT", "029", "suspend", "", "200", "life"),
    ("052", "POST", "/systems/{systemCode}:resume", "Khôi phục HTTT", "030", "suspend", "", "200", "life"),
    ("053", "POST", "/systems/{systemCode}:terminate", "Đề nghị chấm dứt tư cách thành viên", "031", "suspend", "x", "201", "life"),
    ("054", "POST", "/systems/{systemCode}:emergency-action", "Tạm ngừng hoặc thu hồi khẩn của Cán bộ ATTT", "032", "suspend", "x", "200", "life"),
    ("055", "POST", "/emergency-actions/{actionId}:confirm", "Xác nhận thao tác khẩn", "032", "approve", "", "200", "life"),
    ("056", "GET", "/systems/{systemCode}/impact", "Phân tích tác động phụ thuộc", "033", "read", "", "200", "life"),
    ("057", "POST", "/systems/{systemCode}/change-requests", "Đề nghị thay đổi hồ sơ HTTT đã kết nạp", "034", "create", "x", "200|202", "life"),
    ("058", "GET", "/systems/{systemCode}/change-requests", "Danh sách đề nghị thay đổi", "034", "read", "", "200", "life"),
    ("059", "POST", "/change-requests/{changeRequestId}:decide", "Duyệt hoặc từ chối đề nghị thay đổi, chấm dứt", "031, 034", "approve", "", "200", "life"),
    ("060", "POST", "/systems/{systemCode}/scope-expansions", "Đề nghị mở rộng trần phạm vi khai thác", "035", "create", "x", "202", "life"),
    # Nội bộ
    ("062", "POST", "/internal/reconciliations", "Chạy đối chiếu và phát ảnh chụp trạng thái", "037", "service", "", "202", "internal"),
    ("063", "GET", "/internal/systems", "Bản sao đọc danh sách HTTT cho phân hệ khác", "038", "service", "", "200", "internal"),
    ("064", "GET", "/internal/systems/{systemCode}", "Bản sao đọc một HTTT cho phân hệ khác", "038", "service", "", "200", "internal"),
    ("087", "POST", "/internal/provisioning-callbacks", "Nhận kết quả bất đồng bộ của bước saga", "020", "service", "", "200", "internal"),
    # Rà soát quyền
    ("065", "POST", "/access-reviews", "Mở kỳ rà soát quyền", "039", "suspend", "x", "201", "ar"),
    ("066", "GET", "/access-reviews", "Danh sách kỳ rà soát", "039", "read", "", "200", "ar"),
    ("067", "GET", "/access-reviews/{cycleCode}", "Chi tiết kỳ rà soát", "039", "read", "", "200", "ar"),
    ("068", "GET", "/access-reviews/{cycleCode}/items", "Mục rà soát và mức sử dụng", "040", "read", "", "200", "ar"),
    ("069", "POST", "/access-reviews/{cycleCode}:send-confirmations", "Gửi phiếu xác nhận cho đơn vị chủ quản", "041", "suspend", "x", "202", "ar"),
    ("070", "GET", "/access-review-confirmations/{token}", "Xem phiếu xác nhận của đơn vị", "041", "link", "", "200", "ar"),
    ("071", "POST", "/access-review-confirmations/{token}:respond", "Đơn vị trả lời phiếu xác nhận", "041", "link", "", "200", "ar"),
    ("072", "POST", "/access-reviews/{cycleCode}/items:decide", "Quyết định thu hẹp hoặc thu hồi phạm vi", "042", "suspend", "", "200", "ar"),
    ("073", "POST", "/scope-ceilings:mark-legal-expired", "Đánh dấu văn bản pháp lý hết hiệu lực", "043", "suspend", "", "200", "ar"),
    ("074", "GET", "/access-reviews/{cycleCode}/report", "Báo cáo rà soát quyền", "044", "read", "", "200", "ar"),
    ("075", "POST", "/access-reviews/{cycleCode}/report:export", "Xuất báo cáo rà soát quyền", "044", "read", "x", "202", "ar"),
    # Danh bạ đầu mối
    ("076", "GET", "/directory/contacts", "Tra cứu danh bạ đầu mối", "045", "base", "", "200", "dir"),
    ("077", "GET", "/directory/organizations/{orgId}/contacts", "Đầu mối của một tổ chức", "045", "base", "", "200", "dir"),
    ("078", "GET", "/directory/gaps", "Tổ chức thiếu đầu mối và đầu mối cần xác nhận", "046", "read", "", "200", "dir"),
    ("079", "POST", "/directory/contacts:export", "Xuất danh bạ đầu mối", "047", "read", "x", "200|202", "dir"),
    # Di trú, tham số, thống kê
    ("080", "POST", "/legacy-imports", "Tải tệp nhập HTTT từ hệ cũ", "048", "PERM-18-migration", "x", "201", "admin"),
    ("081", "GET", "/legacy-imports/{jobId}", "Kết quả xem trước và nhập hệ cũ", "048", "PERM-18-migration", "", "200", "admin"),
    ("082", "POST", "/legacy-imports/{jobId}:confirm", "Xác nhận tạo hồ sơ nháp từ tệp nhập", "048", "PERM-18-migration", "", "200", "admin"),
    ("083", "GET", "/settings", "Tham số `onboarding.*` của tenant", "049", "read", "", "200", "admin"),
    ("084", "PUT", "/settings/{key}", "Sửa một tham số của tenant", "049", "PERM-18-config", "", "200", "admin"),
    ("085", "POST", "/systems:export", "Xuất danh sách HTTT thành viên", "050", "read", "x", "200|202", "admin"),
    ("086", "GET", "/statistics", "Thống kê kết nạp và thời gian xử lý", "051", "read", "", "200", "admin"),
    ("088", "GET", "/jobs/{jobId}", "Tra tác vụ nền xuất tệp hoặc báo cáo", "044, 047, 050", "read", "", "200", "admin"),
]

# Thao tác chấp nhận nhiều quyền (OR). Mã → danh sách quyền.
ANY_PERM = {
    "030": ["PERM-01-approve", "PERM-01-read (được phân công)"],
    "031": ["PERM-01-approve", "PERM-01-read (được phân công)"],
    "045": ["PERM-01-credential", "PERM-01-suspend"],
    "047": ["PERM-01-credential", "PERM-01-suspend"],
}
# Scope token dịch vụ (client_credentials)
SERVICE_SCOPE = {"062": "onboarding:reconcile", "063": "onboarding:internal-read", "064": "onboarding:internal-read",
                 "087": "onboarding:provision-callback"}
# Thao tác không bắt buộc If-Match dù đổi trạng thái (khẩn cấp, không được chặn vì bản ghi cũ)
IF_MATCH_OPTIONAL = {"047", "051", "054"}
# Thao tác đổi trạng thái hoặc ghi nhưng không cần If-Match (không có ETag của đối tượng: tính toán, tạo con, mở một lần)
NO_IF_MATCH = {"022", "024", "025", "026", "028", "029", "030", "040", "055", "062", "071", "072", "073", "082", "087",
               "035", "038", "041", "046", "059", "075", "079", "085", "065", "069", "053", "060", "057"}
