"""Nguồn chuẩn danh mục operation PH-10 (API-10-nnn).

Mỗi dòng: (mã, phương thức, đường dẫn, mục đích, FR, quyền, idem, mã thành công, nhóm, mã lỗi riêng).
- Đường dẫn tương đối với gốc của mặt phẳng: nhóm `data` dùng `/event/v1` (cổng sự kiện `dh-runtime`),
  mọi nhóm khác dùng `/api/event/v1` (`dh-integration`).
- Quyền: tên động từ PERM-10-{x}; `svc:{scope}` cho tài khoản dịch vụ; `topic:publish`, `topic:subscribe`
  cho scope HTTT `topic:{topicName}:publish|subscribe`. Tổ hợp nhiều quyền ghi ở gen_openapi.ANY_PERM.
- idem: "x" bắt buộc Idempotency-Key; "o" tùy chọn (API phát dùng `id` CloudEvents khi thiếu).
- Mã lỗi riêng: số ERR-10 (ba chữ số) cách nhau bởi dấu cách, ngoài các mã chung 053, 054 (xác thực, quyền ở control plane; data plane dùng 101, 102),
  001 (đường dẫn có tham số), 003 (có thân), 007 (có If-Match).
Mã API-10-001…091 giữ đúng FRS §8.3; API-10-092…119 tách từ dòng gộp của FRS (bảng SPLIT); API-10-120, 121 cấp mới. FRS 0.3 §8.3 liệt kê đủ 001…121.
Sinh OpenAPI (gen_openapi.py) và bảng Markdown (gen_md.py) từ đây; không sửa tay bảng sinh ra.
"""

BASE = "/api/event/v1"
DATA_BASE = "/event/v1"

OPS = [
    # A. Dự án tích hợp
    ("001", "GET", "/projects", "Danh sách, tìm kiếm, lọc dự án", "001", "read", "", "200", "project", "049"),
    ("002", "POST", "/projects", "Tạo dự án tích hợp", "003", "create", "x", "201", "project", "002 011 037 039"),
    ("003", "GET", "/projects/{projectCode}", "Chi tiết dự án", "002", "read", "", "200", "project", "044"),
    ("004", "PATCH", "/projects/{projectCode}", "Sửa dự án", "004", "update", "", "200", "project", "006 044"),
    ("005", "POST", "/projects/{projectCode}:archive", "Lưu trữ dự án", "005", "update", "", "200", "project", "006 009 010"),
    ("006", "POST", "/projects/{projectCode}:restore", "Khôi phục dự án đã lưu trữ", "005", "update", "", "200", "project", "006"),
    ("007", "GET", "/graph", "Sơ đồ kết nối bên phát, topic, bên nhận", "058", "read", "", "200", "monitor", "049"),
    # B. Topic
    ("008", "GET", "/topics", "Danh sách topic; tra cứu topic dùng được cho luồng", "006, 069", "read", "", "200", "topic", "049"),
    ("009", "POST", "/topics", "Tạo topic (người) hoặc đăng ký topic CDC, SYSTEM (máy)", "008, 066, 067", "create", "x", "201", "topic",
     "002 004 005 006 011 012 015 017 018 020 029 037 039 046 048"),
    ("010", "GET", "/topics/{topicName}", "Chi tiết topic", "007", "read", "", "200", "topic", ""),
    ("011", "PATCH", "/topics/{topicName}", "Sửa mô tả; sửa cấu hình khi còn DRAFT", "008, 014", "update", "", "200", "topic", "006 012 045 046 048"),
    ("012", "POST", "/topics/{topicName}:submit", "Gửi duyệt tạo topic", "008", "create", "", "200", "topic", "006 011 015 017 018"),
    ("013", "POST", "/topics/{topicName}:retry-provisioning", "Thử lại cấp phát topic FAILED", "010", "update", "", "202", "topic", "006 029 038"),
    ("014", "POST", "/topics/{topicName}:cancel-provisioning", "Hủy cấp phát, đưa topic về DRAFT", "010", "update", "", "200", "topic", "006 038"),
    ("015", "POST", "/topics/{topicName}/change-requests", "Đề nghị đổi phân vùng, lưu giữ, dọn, định tuyến, mức tương thích", "011, 012, 013, 021", "update", "x", "201", "topic",
     "006 011 012 013 014 019 045 046 047 048"),
    ("016", "POST", "/topics/{topicName}:deprecate", "Ngừng khuyến nghị topic", "014", "update", "", "200", "topic", "006 009 045"),
    ("017", "POST", "/topics/{topicName}:retire", "Đề nghị ngừng dùng topic", "014", "update", "", "200", "topic", "006 009 010 045"),
    ("018", "POST", "/topics/{topicName}:new-major-version", "Tạo phiên bản chính mới của topic", "015, 068", "create", "x", "201", "topic",
     "006 011 015 017 018 029 045 047"),
    ("019", "GET", "/topics/{topicName}/migration-status", "Tiến độ chuyển bên nhận sang topic kế nhiệm", "016", "read", "", "200", "topic", ""),
    ("020", "GET", "/topics/{topicName}/connection-info", "Thông tin kết nối và cấu hình mẫu cho bên phát, bên nhận", "007, 024, 034", "read", "", "200", "topic", ""),
    # C. Lược đồ
    ("021", "GET", "/topics/{topicName}/schema", "Lược đồ của topic (định dạng, mức tương thích)", "020", "read", "", "200", "schema", ""),
    ("022", "GET", "/topics/{topicName}/schema/versions", "Danh sách phiên bản lược đồ", "020", "read", "", "200", "schema", "049"),
    ("023", "POST", "/topics/{topicName}/schema/versions", "Tạo phiên bản lược đồ nháp (người) hoặc đăng ký phiên bản CDC (máy)", "017, 068", "create", "x", "201", "schema",
     "006 015 016 017 018 020 029 037 045"),
    ("024", "GET", "/topics/{topicName}/schema/versions/{versionNo}", "Chi tiết một phiên bản lược đồ", "020", "read", "", "200", "schema", ""),
    ("025", "PUT", "/topics/{topicName}/schema/versions/{versionNo}", "Sửa nội dung phiên bản nháp", "017", "update", "", "200", "schema", "006 015 017 018 020"),
    ("026", "POST", "/topics/{topicName}/schema/versions/{versionNo}:check", "Kiểm tra cú pháp, tương thích, dữ liệu cá nhân", "017, 018", "create", "", "200", "schema", "015 029"),
    ("027", "POST", "/topics/{topicName}/schema/versions/{versionNo}:submit", "Gửi duyệt phiên bản lược đồ", "019", "create", "", "200", "schema", "006 015 016 017 018"),
    ("028", "POST", "/topics/{topicName}/schema/versions/{versionNo}:deprecate", "Ngừng khuyến nghị phiên bản lược đồ", "022", "update", "", "200", "schema", "006 009"),
    ("029", "POST", "/topics/{topicName}/schema/versions/{versionNo}:disable", "Vô hiệu phiên bản lược đồ", "022", "update", "", "200", "schema", "006 009"),
    ("030", "GET", "/topics/{topicName}/schema/diff", "So sánh hai phiên bản lược đồ", "020", "read", "", "200", "schema", "049"),
    ("031", "GET", "/topics/{topicName}/compliance", "Tuân thủ lược đồ của bên phát Kafka trực tiếp", "023", "read", "", "200", "schema", "049"),
    # D. Bên phát, bên nhận
    ("032", "GET", "/publishers", "Danh sách bên phát", "025", "read", "", "200", "party", "049"),
    ("033", "POST", "/publishers", "Đăng ký bên phát", "026", "create", "x", "201", "party", "002 021 022 023 024 037 044"),
    ("034", "GET", "/publishers/{publisherCode}", "Chi tiết bên phát", "025", "read", "", "200", "party", "044"),
    ("035", "PATCH", "/publishers/{publisherCode}", "Sửa bên phát", "028", "update", "", "200", "party", "006 044"),
    ("036", "POST", "/publishers/{publisherCode}:suspend", "Tạm ngừng bên phát", "028", "operate", "", "200", "party", "006 009"),
    ("092", "POST", "/publishers/{publisherCode}:resume", "Tiếp tục bên phát", "028", "operate", "", "200", "party", "006 009"),
    ("093", "POST", "/publishers/{publisherCode}:retire", "Ngừng dùng bên phát", "028", "update", "", "200", "party", "006 009"),
    ("037", "GET", "/subscribers", "Danh sách bên nhận", "025", "read", "", "200", "party", "049"),
    ("038", "POST", "/subscribers", "Đăng ký bên nhận", "027", "create", "x", "201", "party", "002 021 022 023 024 037 044"),
    ("039", "GET", "/subscribers/{subscriberCode}", "Chi tiết bên nhận", "025", "read", "", "200", "party", "044"),
    ("040", "PATCH", "/subscribers/{subscriberCode}", "Sửa bên nhận", "028", "update", "", "200", "party", "006 044"),
    ("041", "POST", "/subscribers/{subscriberCode}:suspend", "Tạm ngừng bên nhận", "028", "operate", "", "200", "party", "006 009"),
    ("094", "POST", "/subscribers/{subscriberCode}:resume", "Tiếp tục bên nhận", "028", "operate", "", "200", "party", "006 009"),
    ("095", "POST", "/subscribers/{subscriberCode}:retire", "Ngừng dùng bên nhận", "028", "update", "", "200", "party", "006 009"),
    # E. Publication
    ("042", "GET", "/publications", "Danh sách publication", "030", "read", "", "200", "publication", "049"),
    ("043", "POST", "/publications", "Đề nghị publication", "030", "create", "x", "201", "publication", "011 024 025 037 044 051"),
    ("044", "GET", "/publications/{publicationCode}", "Chi tiết publication", "030", "read", "", "200", "publication", ""),
    ("045", "POST", "/publications/{publicationCode}:suspend", "Tạm ngừng publication", "032", "operate", "", "200", "publication", "006 009"),
    ("096", "POST", "/publications/{publicationCode}:resume", "Tiếp tục publication", "032", "operate", "", "200", "publication", "006 009 025"),
    ("097", "POST", "/publications/{publicationCode}:revoke", "Thu hồi publication", "032", "update", "", "200", "publication", "006 009"),
    # F. Subscription
    ("046", "GET", "/subscriptions", "Danh sách subscription", "035", "read", "", "200", "subscription", "049"),
    ("047", "POST", "/subscriptions", "Đề nghị subscription", "035", "subscribe", "x", "201", "subscription",
     "011 024 025 026 027 028 030 031 037 044 051"),
    ("048", "GET", "/subscriptions/{subscriptionCode}", "Chi tiết subscription", "035, 056", "read", "", "200", "subscription", "044"),
    ("049", "PATCH", "/subscriptions/{subscriptionCode}", "Sửa tham số subscription", "046", "subscribe", "", "200", "subscription", "006 012 026 027 030 044"),
    ("050", "POST", "/subscriptions/{subscriptionCode}:pause", "Tạm dừng subscription", "041", "operate", "", "200", "subscription", "006 009 052"),
    ("098", "POST", "/subscriptions/{subscriptionCode}:resume", "Tiếp tục subscription", "041", "operate", "", "200", "subscription", "006 009 052"),
    ("099", "POST", "/subscriptions/{subscriptionCode}:revoke", "Thu hồi subscription", "047", "subscribe", "", "200", "subscription", "006 009 044"),
    ("051", "POST", "/endpoint-verifications", "Xác minh endpoint webhook", "036", "subscribe", "", "200", "subscription", "026 027"),
    ("091", "POST", "/subscriptions/{subscriptionCode}/endpoint-verification:waive", "Ngoại lệ xác minh endpoint có thời hạn", "036", "admin", "", "200", "subscription", "006 009 012"),
    ("052", "GET", "/subscriptions/{subscriptionCode}/stats", "Thống kê giao nhận theo thời gian", "056", "read", "", "200", "subscription", "049"),
    ("053", "GET", "/subscriptions/{subscriptionCode}/failures", "Lượt giao lỗi gần đây", "056", "read", "", "200", "subscription", "049"),
    ("054", "POST", "/subscriptions/{subscriptionCode}/signing-keys:rotate", "Xoay khóa ký webhook", "042", "operate", "x", "200", "subscription", "006 029"),
    ("100", "POST", "/subscriptions/{subscriptionCode}/signing-keys:revoke", "Thu hồi khẩn khóa ký, sinh khóa mới", "042", "operate", "x", "200", "subscription", "006 009 029"),
    ("120", "POST", "/subscriptions/{subscriptionCode}/signing-keys:claim", "Nhận khóa ký đầu tiên một lần sau khi duyệt", "037, 042", "subscribe", "", "200", "subscription", "006 029 044"),
    ("055", "GET", "/subscriptions/{subscriptionCode}/lag", "Độ trễ tiêu thụ theo phân vùng", "054", "read", "", "200", "subscription", "049"),
    ("056", "POST", "/subscriptions/{subscriptionCode}/lag-alerts:acknowledge", "Xác nhận cảnh báo lag", "055", "operate", "", "200", "subscription", "006"),
    # Yêu cầu duyệt
    ("057", "GET", "/approval-requests", "Danh sách yêu cầu duyệt", "009, 011, 012, 013, 014, 019, 021, 022, 031, 037, 051, 073, 075", "read", "", "200", "approval", "049"),
    ("058", "GET", "/approval-requests/{requestCode}", "Chi tiết yêu cầu duyệt", "009, 011, 012, 013, 014, 019, 021, 022, 031, 037, 051, 073, 075", "read", "", "200", "approval", ""),
    ("059", "POST", "/approval-requests/{requestCode}:approve", "Duyệt yêu cầu", "009, 011, 012, 013, 014, 019, 021, 022, 031, 037, 051, 073, 075", "approve", "", "200", "approval",
     "006 008 009 011 016 029 038 051"),
    ("101", "POST", "/approval-requests/{requestCode}:reject", "Từ chối yêu cầu", "009, 011, 012, 013, 014, 019, 021, 022, 031, 037, 051, 073, 075", "approve", "", "200", "approval", "006 008 009"),
    ("102", "POST", "/approval-requests/{requestCode}:withdraw", "Rút yêu cầu đã gửi", "009, 011, 012, 013, 014, 019, 021, 022, 031, 037, 051, 073, 075", "requester", "", "200", "approval", "006 009"),
    # G. DLQ, phát lại
    ("060", "GET", "/dlq-entries", "Danh sách mục DLQ (siêu dữ liệu)", "050", "read", "", "200", "dlq", "049"),
    ("061", "GET", "/dlq-entries/{dlqEntryId}", "Siêu dữ liệu một mục DLQ", "050", "read", "", "200", "dlq", ""),
    ("103", "GET", "/dlq-entries/{dlqEntryId}/payload", "Nội dung một mục DLQ", "050", "operate", "", "200", "dlq", "009 029"),
    ("062", "POST", "/dlq-entries:discard", "Loại bỏ mục DLQ", "050", "operate", "x", "200", "dlq", "009 036"),
    ("063", "GET", "/replays", "Danh sách lượt phát lại", "052", "read", "", "200", "dlq", "049"),
    ("104", "GET", "/replays/{replayCode}", "Chi tiết, tiến độ lượt phát lại", "052", "read", "", "200", "dlq", ""),
    ("064", "POST", "/replays", "Đề nghị phát lại theo khoảng, đặt lại offset, mục DLQ", "051, 053", "operate", "x", "201", "dlq",
     "006 009 026 027 032 033 034 035 036"),
    ("065", "POST", "/replays/{replayCode}:cancel", "Hủy lượt phát lại", "052", "operate", "", "200", "dlq", "006 009"),
    # H. Giám sát
    ("066", "GET", "/dashboard", "Dashboard sự kiện của tenant", "057", "read", "", "200", "monitor", "049"),
    # I. Danh mục, hạn mức, tham số
    ("067", "GET", "/comm-types", "Danh mục kiểu giao tiếp", "060", "read", "", "200", "config", ""),
    ("105", "PATCH", "/comm-types/{commTypeCode}", "Bật, tắt kiểu giao tiếp cho tenant", "060", "admin", "", "200", "config", "009 043"),
    ("068", "GET", "/routing-modes", "Danh mục chế độ định tuyến", "061", "read", "", "200", "config", ""),
    ("106", "PATCH", "/routing-modes/{routingModeCode}", "Bật, tắt chế độ định tuyến cho tenant", "061", "admin", "", "200", "config", "009 043"),
    ("069", "GET", "/quota", "Hạn mức sự kiện của tenant và mức dùng", "062", "read", "", "200", "config", ""),
    ("107", "PUT", "/quota", "Đặt trần (PA) hoặc phân bổ hạn mức (TA)", "062", "admin", "", "200", "config", "009 011 012"),
    ("070", "GET", "/settings", "Tham số 10.* hiệu lực của tenant", "063", "read", "", "200", "config", ""),
    ("108", "PATCH", "/settings", "Sửa tham số 10.* trong miền cho phép", "063", "admin", "", "200", "config", "009 012"),
    # J. Máy với máy
    ("071", "POST", "/permissions:check", "Kiểm tra quyền phát, nhận của luồng PH-04", "069", "svc:event:permission-check", "", "200", "machine", "029"),
    ("072", "POST", "/flows/{flowCode}:ensure-party", "Tạo bên tham gia FLOW và đề nghị quan hệ cho luồng", "069", "svc:event:permission-check", "x", "200", "machine",
     "022 024 025 029"),
    ("109", "GET", "/flows/{flowCode}/dependencies", "Publication, subscription của luồng (cho API-04-016)", "069", "svc:event:permission-check", "", "200", "machine", ""),
    ("073", "GET", "/runtime/subscriptions", "Cấu hình runtime: topic, subscription, lượt phát lại", "038, 043", "svc:event:runtime-config", "", "200", "runtime", ""),
    # K. Xuất nhập, di trú
    ("074", "POST", "/exports", "Xuất khai báo EventManifest", "070", "read", "", "200", "migration", "049"),
    ("075", "POST", "/imports", "Tải tệp khai báo hoặc kiểm kê Pulsar để kiểm tra", "071, 072", "create", "x", "202", "migration", "040 050"),
    ("110", "GET", "/imports/{jobCode}", "Trạng thái, xem trước tác vụ nhập", "071, 072", "read", "", "200", "migration", ""),
    ("111", "POST", "/imports/{jobCode}:apply", "Áp dụng tác vụ nhập (tạo đối tượng ở trạng thái đầu)", "071, 072", "create", "x", "202", "migration", "006 040 041 050"),
    ("121", "POST", "/imports/{jobCode}:cancel", "Hủy tác vụ nhập ở `VALIDATING`, `PREVIEW` (người tạo)", "071", "create", "", "200", "migration", "006 008"),
    ("076", "GET", "/migrations/mappings", "Danh sách ánh xạ di trú Pulsar", "072", "read", "", "200", "migration", "049"),
    ("112", "PATCH", "/migrations/mappings/{mappingId}", "Sửa đích hoặc bỏ qua một ánh xạ", "072", "admin", "", "200", "migration", "006 041"),
    ("077", "GET", "/migrations/bridges", "Danh sách cầu nối di trú", "073, 074", "read", "", "200", "migration", "049"),
    ("113", "POST", "/migrations/bridges", "Đề nghị cầu nối Pulsar sang Kafka hoặc ngược lại", "073, 074", "admin", "x", "201", "migration", "012 025 041 042"),
    ("114", "POST", "/migrations/bridges/{bridgeCode}:stop", "Dừng cầu nối", "073, 074", "admin", "", "200", "migration", "006 009"),
    ("115", "POST", "/migrations/bridges/{bridgeCode}:resume", "Chạy lại cầu nối đã dừng", "073, 074", "admin", "", "200", "migration", "006 009 042"),
    ("078", "POST", "/migrations/mappings/{mappingId}:cut-over", "Đề nghị chuyển hẳn một ánh xạ", "075", "admin", "", "200", "migration", "006 009 041"),
    ("116", "POST", "/migrations/mappings/{mappingId}:rollback", "Quay lui một ánh xạ đã chuyển hẳn", "075", "admin", "", "200", "migration", "006 009 042"),
    ("117", "GET", "/migrations/reconciliations", "Kết quả đối chiếu Pulsar và Kafka", "075", "read", "", "200", "migration", "049"),
    ("118", "GET", "/migrations/progress", "Báo cáo tiến độ di trú", "076", "read", "", "200", "migration", ""),
    # Data plane (cổng sự kiện dh-runtime, gốc /event/v1)
    ("079", "POST", "/topics/{topicName}/events", "Phát một sự kiện hoặc một lô sự kiện", "033", "topic:publish", "o", "202", "data",
     "103 104 105 106 107 108 121"),
    ("080", "GET", "/subscriptions/{subscriptionCode}/events", "Kéo lô sự kiện (lease, chờ dài)", "043", "topic:subscribe", "", "200", "data", "107 110 121"),
    ("081", "POST", "/subscriptions/{subscriptionCode}/events:ack", "Xác nhận lô đã kéo", "043", "topic:subscribe", "", "204", "data", "109 110 121"),
    ("082", "POST", "/subscriptions/{subscriptionCode}/events:nack", "Báo sự kiện xử lý lỗi, đưa vào DLQ", "043", "topic:subscribe", "", "204", "data", "109 110 121"),
    ("083", "POST", "/subscriptions/{subscriptionCode}/dead-letters", "Bên nhận Kafka ngoài báo bản tin lỗi vào DLQ", "044", "topic:subscribe", "o", "202", "data", "106 107 110"),
    ("084", "GET", "/registry/{registryPath}", "Tra cứu lược đồ chỉ đọc (Apicurio v3, ccompat/v7)", "024", "topic:any", "", "200", "data", "103"),
    # API nội bộ cho dh-runtime (gốc /api/event/v1, qua apisix-int, mTLS và token máy)
    ("085", "POST", "/runtime/delivery-reports", "Báo cáo giao nhận theo phút", "056", "svc:event:runtime-config", "", "204", "runtime", ""),
    ("086", "POST", "/runtime/subscriptions/{subscriptionCode}:suspend", "Tạm ngừng do ngắt mạch hoặc failurePolicy BLOCK", "039", "svc:event:runtime-config", "", "200", "runtime", "006"),
    ("119", "POST", "/runtime/subscriptions/{subscriptionCode}:resume", "Tự tiếp tục sau ngắt mạch (chỉ CIRCUIT_BREAKER)", "039", "svc:event:runtime-config", "", "200", "runtime", "006"),
    ("087", "POST", "/runtime/replays/{replayCode}:start", "Nhận chạy lượt phát lại APPROVED", "052", "svc:event:replay", "", "200", "runtime", "006"),
    ("088", "POST", "/runtime/replays/{replayCode}/results", "Báo tiến độ, kết quả từng mục DLQ, kết thúc lượt phát lại", "052, 053", "svc:event:replay", "", "200", "runtime", "006"),
    ("089", "POST", "/runtime/dlq-entries:fetch-payloads", "Lấy nội dung mục DLQ theo lô ≤ 100", "053", "svc:event:replay", "", "200", "runtime", "029"),
    ("090", "POST", "/runtime/bridges/{bridgeCode}/status", "Báo trạng thái, số bản tin, lag của cầu nối", "073, 074", "svc:event:runtime-config", "", "204", "runtime", "006"),
]

# Dòng gộp ở FRS §8.3 → mã cấp mới (giữ mã FRS cho hành động đầu tiên).
SPLIT = {
    "036": ["092", "093"], "041": ["094", "095"], "045": ["096", "097"], "050": ["098", "099"],
    "054": ["100"], "059": ["101", "102"], "061": ["103"], "063": ["104"], "067": ["105"], "068": ["106"],
    "069": ["107"], "070": ["108"], "072": ["109"], "075": ["110", "111"], "076": ["112"],
    "077": ["113", "114", "115"], "078": ["116", "117", "118"], "086": ["119"],
}
