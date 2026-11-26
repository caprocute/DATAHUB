"""Nguồn chuẩn danh mục PH-03 Cổng API: operation (API-03-nnn), mã lỗi (ERR-03-nnn), sự kiện (EVT-03-nn).

Mỗi operation: (mã, phương thức, đường dẫn, mục đích, FR, quyền, chống trùng, mã thành công, nhóm).
Danh mục khớp D02-03-PH03 §9.4. Sinh OpenAPI (gen_openapi.py), AsyncAPI (gen_asyncapi.py) và bảng Markdown (gen_md.py)
từ đây; không sửa tay bảng sinh ra.
"""

BASE = "/api/gateway/v1"

# quyền: tên sau PERM-03-; "sync", "revoke" là scope dịch vụ gateway:{tên}
OPS = [
    # Route và upstream
    ("001", "GET", "/routes", "Danh sách route", "028", "read", "", "200", "route"),
    ("002", "GET", "/routes/{routeCode}", "Chi tiết route", "009, 017, 028, 033, 034, 035", "read", "", "200", "route"),
    ("003", "POST", "/routes/{routeCode}:stop", "Dừng API", "036", "operate", "", "200", "route"),
    ("004", "POST", "/routes/{routeCode}:start", "Mở API", "036", "operate", "", "200", "route"),
    ("005", "GET", "/upstreams", "Danh sách upstream", "029", "read", "", "200", "route"),
    ("006", "GET", "/upstreams/{upstreamCode}", "Chi tiết upstream", "029, 030", "read", "", "200", "route"),
    ("007", "GET", "/routes/{routeCode}/versions", "Các phiên bản API song song của route", "035", "read", "", "200", "route"),
    ("008", "PUT", "/routes/{routeCode}/exposure", "Đặt cửa vào của route (EXT cần bốn mắt)", "038", "admin", "", "200", "route"),
    ("009", "PUT", "/routes/{routeCode}/request-limits", "Đặt giới hạn kích thước và cấu trúc yêu cầu", "009", "admin", "", "200", "route"),
    ("010", "PUT", "/routes/{routeCode}/timeouts", "Đặt thời hạn chờ của route", "031", "admin", "", "200", "route"),
    # Consumer
    ("011", "GET", "/consumers", "Danh sách consumer", "046", "read", "", "200", "consumer"),
    ("012", "GET", "/consumers/{consumerCode}", "Chi tiết consumer", "014, 016, 046", "read", "", "200", "consumer"),
    ("013", "PUT", "/consumers/{consumerCode}", "Tạo hoặc cập nhật consumer", "046", "sync", "x", "200", "consumer"),
    ("014", "PUT", "/consumers/{consumerCode}/credentials", "Cập nhật thông tin xác thực công khai của consumer", "046", "sync", "x", "200", "consumer"),
    ("015", "DELETE", "/consumers/{consumerCode}", "Gỡ consumer", "046", "sync", "x", "204", "consumer"),
    ("016", "GET", "/consumers/{consumerCode}/credentials", "Thông tin xác thực công khai của consumer", "002, 014", "read", "", "200", "consumer"),
    # Tạm ngừng khẩn cấp
    ("017", "POST", "/consumers/{consumerCode}:suspend", "Tạm ngừng khẩn cấp consumer", "047", "operate", "", "200", "emergency"),
    ("018", "POST", "/consumers/{consumerCode}:resume", "Mở lại consumer", "047", "operate", "", "200", "emergency"),
    ("019", "POST", "/routes/{routeCode}:suspend", "Tạm ngừng khẩn cấp route", "047", "operate", "", "200", "emergency"),
    ("020", "POST", "/routes/{routeCode}:resume", "Mở lại route", "047", "operate", "", "200", "emergency"),
    # Chính sách chiếu từ gói
    ("021", "GET", "/plan-policies", "Danh sách chính sách chiếu từ gói", "015, 016, 020, 021", "read", "", "200", "policy"),
    ("022", "GET", "/plan-policies/{policyCode}", "Chi tiết chính sách chiếu từ gói", "015, 017, 020, 021", "read", "", "200", "policy"),
    # Hạn mức và hạn ngạch
    ("023", "GET", "/tenant-limits", "Hạn mức toàn tenant", "023", "read", "", "200", "limit"),
    ("024", "PUT", "/tenant-limits", "Đặt hạn mức toàn tenant (hạ cần bốn mắt)", "023", "limit", "", "200", "limit"),
    ("025", "GET", "/rate-limit-overrides", "Danh sách ghi đè hạn mức", "024, 025", "read", "", "200", "limit"),
    ("026", "POST", "/rate-limit-overrides", "Tạo ghi đè hạn mức", "024", "limit", "x", "201", "limit"),
    ("027", "PUT", "/rate-limit-overrides/{overrideId}", "Sửa ghi đè hạn mức", "024", "limit", "", "200", "limit"),
    ("028", "DELETE", "/rate-limit-overrides/{overrideId}", "Xóa ghi đè hạn mức", "024", "limit", "", "204", "limit"),
    ("029", "GET", "/consumers/{consumerCode}/usage", "Mức dùng hạn mức, hạn ngạch của consumer", "021, 022, 027", "read", "", "200", "limit"),
    ("030", "GET", "/quota-alerts", "Cảnh báo ngưỡng hạn ngạch", "022", "read", "", "200", "limit"),
    # Lớp biên
    ("031", "GET", "/edge/tls-profile", "Hồ sơ TLS đang áp dụng ở hai cửa vào", "001", "read", "", "200", "edge"),
    ("032", "GET", "/tls-exceptions", "Danh sách ngoại lệ TLS 1.2", "001", "read", "", "200", "edge"),
    ("033", "POST", "/tls-exceptions", "Tạo ngoại lệ TLS 1.2 có thời hạn", "001", "admin", "x", "201", "edge"),
    ("034", "POST", "/tls-exceptions/{exceptionId}:revoke", "Thu hồi ngoại lệ TLS 1.2", "001", "admin", "", "200", "edge"),
    ("035", "GET", "/edge/client-ca-bundles", "Bộ CA tin cậy cho chứng thư khách mTLS", "002, 049", "read", "", "200", "edge"),
    ("036", "GET", "/ip-blocks", "Danh sách địa chỉ đang bị chặn", "003, 004", "read", "", "200", "ipblock"),
    ("037", "POST", "/ip-blocks", "Chặn địa chỉ nguồn thủ công", "004", "waf", "x", "201", "ipblock"),
    ("038", "DELETE", "/ip-blocks/{blockId}", "Bỏ chặn địa chỉ nguồn", "004", "waf", "", "204", "ipblock"),
    # WAF
    ("039", "GET", "/waf/events", "Sự kiện chặn của WAF", "005", "waf-request", "", "200", "waf"),
    ("040", "GET", "/waf/mode", "Chế độ WAF và điều kiện chuyển sang chặn", "006", "read", "", "200", "waf"),
    ("041", "PUT", "/waf/mode", "Đổi chế độ WAF (cần bốn mắt)", "006", "waf", "", "200", "waf"),
    ("042", "GET", "/waf/exceptions", "Danh sách ngoại lệ luật WAF", "007", "waf-request", "", "200", "waf"),
    ("043", "POST", "/waf/exceptions", "Đề nghị ngoại lệ luật WAF", "007", "waf-request", "x", "201", "waf"),
    ("044", "POST", "/waf/exceptions/{exceptionId}:approve", "Duyệt ngoại lệ luật WAF", "007", "waf-approve", "", "200", "waf"),
    ("045", "POST", "/waf/exceptions/{exceptionId}:reject", "Từ chối ngoại lệ luật WAF", "007", "waf-approve", "", "200", "waf"),
    ("046", "POST", "/waf/exceptions/{exceptionId}:revoke", "Thu hồi ngoại lệ luật WAF", "007", "waf", "", "200", "waf"),
    ("047", "GET", "/waf/virtual-patches", "Danh sách luật vá ảo", "008", "waf-request", "", "200", "waf"),
    ("048", "POST", "/waf/virtual-patches", "Tạo luật vá ảo khẩn cấp", "008", "waf", "x", "201", "waf"),
    ("049", "POST", "/waf/virtual-patches/{patchId}:retire", "Gỡ luật vá ảo", "008", "waf", "", "200", "waf"),
    # CORS
    ("050", "GET", "/cors-policies", "Danh sách chính sách CORS theo route", "010", "read", "", "200", "cors"),
    ("051", "PUT", "/cors-policies/{routeCode}", "Đặt chính sách CORS của route", "010", "admin", "", "200", "cors"),
    # Xác thực, thu hồi, ủy quyền
    ("052", "GET", "/auth/jwks-status", "Trạng thái bộ đệm JWKS của các nút", "012", "read", "", "200", "auth"),
    ("053", "POST", "/revocations", "Thu hồi token (danh sách chặn)", "018", "revoke", "x", "201", "auth"),
    ("054", "GET", "/revocations", "Danh sách thu hồi token còn hiệu lực", "018", "read", "", "200", "auth"),
    ("055", "GET", "/authorization-bindings", "Chính sách OPA gắn với từng route", "019", "read", "", "200", "auth"),
    # Ảnh chụp cấu hình
    ("056", "GET", "/snapshots", "Danh sách ảnh chụp cấu hình", "039, 044", "read", "", "200", "snapshot"),
    ("057", "GET", "/snapshots/{version}", "Chi tiết ảnh chụp cấu hình", "039, 041", "read", "", "200", "snapshot"),
    ("058", "POST", "/snapshots:validate", "Kiểm tra hợp lệ cấu hình tổng hợp thử", "040", "publish", "", "200", "snapshot"),
    ("059", "POST", "/snapshots:build", "Tổng hợp, kiểm tra và ký ảnh chụp cấu hình", "039, 040, 041", "publish", "x", "201", "snapshot"),
    ("060", "POST", "/snapshots/{version}:publish", "Phát ảnh chụp cấu hình tới Git và bucket", "042", "publish", "x", "200", "snapshot"),
    ("061", "POST", "/snapshots/{version}:rollback", "Quay lui bằng ảnh chụp mới mang nội dung bản cũ", "044", "operate", "x", "201", "snapshot"),
    ("062", "GET", "/snapshots/{version}/diff", "So sánh ảnh chụp với bản đang chạy", "044", "read", "", "200", "snapshot"),
    # Nút
    ("063", "GET", "/nodes", "Danh sách nút gateway và trạng thái đồng bộ", "043, 045", "read", "", "200", "node"),
    ("064", "GET", "/nodes/{nodeId}", "Chi tiết nút gateway", "043, 045", "read", "", "200", "node"),
    # Mẫu chính sách
    ("065", "GET", "/policy-templates", "Danh mục mẫu chính sách được duyệt", "020, 048", "read", "", "200", "template"),
    ("066", "GET", "/policy-templates/{templateCode}", "Chi tiết mẫu chính sách", "015, 048", "read", "", "200", "template"),
    ("067", "PUT", "/policy-templates/{templateCode}/enablement", "Bật, tắt mẫu chính sách cho tenant", "048", "admin", "", "200", "template"),
    # Chứng thư biên
    ("068", "GET", "/certificates", "Danh sách chứng thư biên", "049", "read", "", "200", "cert"),
    ("069", "GET", "/certificates/{certCode}", "Chi tiết chứng thư biên", "049", "read", "", "200", "cert"),
    ("070", "POST", "/certificates/{certCode}:renew", "Gia hạn chứng thư biên thủ công", "049", "operate", "", "202", "cert"),
    # Yêu cầu thay đổi bốn mắt
    ("071", "GET", "/change-requests", "Danh sách yêu cầu thay đổi chờ duyệt", "006, 023, 038", "read", "", "200", "changereq"),
    ("072", "POST", "/change-requests/{requestId}:approve", "Duyệt yêu cầu thay đổi", "006, 023, 038", "approve", "", "200", "changereq"),
    ("073", "POST", "/change-requests/{requestId}:reject", "Từ chối yêu cầu thay đổi", "006, 023, 038", "approve", "", "200", "changereq"),
    # Nhật ký lượt gọi
    ("074", "GET", "/access-logs", "Tra cứu nhật ký lượt gọi", "050, 051", "log-read", "", "200", "accesslog"),
    ("075", "GET", "/access-logs/{logId}", "Chi tiết một lượt gọi", "051", "log-read", "", "200", "accesslog"),
    ("076", "POST", "/access-logs:export", "Xuất nhật ký lượt gọi", "051", "log-read", "x", "202", "accesslog"),
    # Tổng quan
    ("077", "GET", "/overview", "Tổng quan lưu lượng và sức khỏe gateway", "026, 052, 055", "read", "", "200", "overview"),
    ("078", "GET", "/overview/top-consumers", "HTTT gọi nhiều nhất", "055", "read", "", "200", "overview"),
    ("079", "GET", "/overview/top-routes", "Route nhiều lượt gọi hoặc nhiều lỗi nhất", "055", "read", "", "200", "overview"),
    # Kiểm tra tổng hợp
    ("080", "GET", "/synthetic-checks", "Danh sách kiểm tra tổng hợp", "053", "read", "", "200", "synthetic"),
    ("081", "POST", "/synthetic-checks", "Tạo kiểm tra tổng hợp", "053", "admin", "x", "201", "synthetic"),
    ("082", "PUT", "/synthetic-checks/{checkId}", "Sửa kiểm tra tổng hợp", "053", "admin", "", "200", "synthetic"),
    ("083", "DELETE", "/synthetic-checks/{checkId}", "Xóa kiểm tra tổng hợp", "053", "admin", "", "204", "synthetic"),
    # Cảnh báo an ninh
    ("084", "GET", "/security-alerts", "Danh sách cảnh báo an ninh của gateway", "054", "read", "", "200", "alert"),
    ("085", "POST", "/security-alerts/{alertId}:acknowledge", "Xác nhận đã xử lý cảnh báo", "054", "operate", "", "200", "alert"),
    # Tham số
    ("086", "GET", "/settings", "Tham số gateway của tenant", "003, 011, 056", "read", "", "200", "settings"),
    ("087", "PUT", "/settings", "Đổi tham số gateway của tenant", "003, 011, 056", "admin", "", "200", "settings"),
    # Chạy thử
    ("088", "POST", "/simulations", "Chạy thử chính sách bằng mô phỏng", "057", "admin", "", "200", "simulate"),
    # Báo cáo
    ("089", "GET", "/reports/usage", "Báo cáo sử dụng API theo HTTT, route, gói", "058", "read", "", "200", "report"),
    ("090", "POST", "/reports/usage:export", "Xuất báo cáo sử dụng", "058", "log-read", "x", "202", "report"),
    # Nhập từ gateway cũ
    ("091", "POST", "/migrations/legacy-gateway:import", "Tải gói cấu hình gateway cũ để phân tích", "059", "admin", "x", "202", "migration"),
    ("092", "GET", "/migrations/legacy-gateway/{importId}", "Kết quả phân tích gói gateway cũ", "059", "admin", "", "200", "migration"),
    ("093", "POST", "/migrations/legacy-gateway/{importId}:apply", "Áp đề xuất nhập thành cấu hình nháp", "059", "admin", "", "200", "migration"),
    # Chuyển tiếp tenant sáp nhập
    ("094", "GET", "/tenant-redirects", "Danh sách chuyển tiếp tenant sáp nhập", "037", "read", "", "200", "redirect"),
    ("095", "POST", "/tenant-redirects", "Tạo chuyển tiếp tenant sáp nhập", "037", "admin", "x", "201", "redirect"),
    ("096", "POST", "/tenant-redirects/{redirectId}:end", "Kết thúc chuyển tiếp tenant sáp nhập", "037", "admin", "", "200", "redirect"),
]

TAGS = {
    "route": "Route và upstream", "consumer": "Consumer", "emergency": "Tạm ngừng khẩn cấp", "policy": "Chính sách chiếu từ gói",
    "limit": "Hạn mức và hạn ngạch", "edge": "Lớp biên và TLS", "ipblock": "Chặn địa chỉ nguồn", "waf": "WAF", "cors": "CORS",
    "auth": "Xác thực, thu hồi, ủy quyền", "snapshot": "Ảnh chụp cấu hình", "node": "Nút gateway", "template": "Mẫu chính sách",
    "cert": "Chứng thư biên", "changereq": "Yêu cầu thay đổi bốn mắt", "accesslog": "Nhật ký lượt gọi", "overview": "Tổng quan",
    "synthetic": "Kiểm tra tổng hợp", "alert": "Cảnh báo an ninh", "settings": "Tham số", "simulate": "Chạy thử chính sách",
    "report": "Báo cáo sử dụng", "migration": "Nhập từ gateway cũ", "redirect": "Chuyển tiếp tenant sáp nhập",
}

SERVICE_SCOPE = {"sync": "gateway:sync", "revoke": "gateway:revoke"}

# Mã lỗi control plane: mã -> (HTTP, tiêu đề ngắn, ý nghĩa). Khớp D02-03-PH03 §9.1.
ERR_CP = {
    "001": (404, "Không tìm thấy", "Không tìm thấy đối tượng hoặc đối tượng thuộc tenant khác (không phân biệt hai trường hợp)"),
    "002": (409, "Mã đã tồn tại", "Mã đã tồn tại, kể cả đối tượng đã gỡ"),
    "003": (400, "Dữ liệu không hợp lệ", "Dữ liệu không hợp lệ theo lược đồ, kèm danh sách lỗi theo trường; cũng là mã khi cùng `Idempotency-Key` nhưng khác thân và khi thân chứa trường dạng bí mật"),
    "004": (412, "Xung đột phiên bản bản ghi", "`If-Match` không khớp `ETag` hiện tại"),
    "005": (422, "Cấu hình không hợp lệ", "Cấu hình không hợp lệ theo kiểm tra tĩnh, kèm danh sách lỗi `findings`"),
    "006": (409, "Đang có tổng hợp hoặc phát khác", "Đang có lần tổng hợp, ký hoặc phát khác; hoặc tenant đang bị giữ sau quay lui"),
    "007": (422, "Không quay lui được", "Phiên bản đích tham chiếu đối tượng không còn hợp lệ"),
    "008": (403, "Người duyệt trùng người đề nghị", "Người duyệt trùng người đề nghị (bốn mắt)"),
    "009": (422, "Ngoại lệ WAF không hợp lệ", "Ngoại lệ hoặc luật vá WAF sai: thiếu lý do, quá hạn tối đa, mã luật không có"),
    "010": (409, "Đã có ngoại lệ WAF", "Đã có ngoại lệ WAF còn hiệu lực cho cặp route và mã luật"),
    "011": (422, "Route chưa đủ điều kiện ra cửa Internet", "Route chưa đủ điều kiện hoặc chưa được duyệt để mở ra cửa Internet"),
    "012": (422, "Route thiếu lược đồ hoặc chính sách", "Route thiếu lược đồ OpenAPI đã duyệt hoặc chính sách ủy quyền"),
    "013": (422, "Plugin hoặc mẫu ngoài danh mục", "Plugin hoặc mẫu chính sách ngoài danh mục được duyệt"),
    "014": (502, "Không ghi được ảnh chụp", "Không ghi được ảnh chụp tới Git hoặc bucket"),
    "015": (503, "Dịch vụ ký không khả dụng", "OpenBao, PKI hoặc dịch vụ ký không khả dụng"),
    "016": (422, "Chứng thư không hợp lệ", "Chứng thư không hợp lệ (chuỗi, hạn, khóa, host)"),
    "017": (409, "Consumer còn đăng ký hiệu lực", "Consumer còn đăng ký sử dụng đang hiệu lực"),
    "018": (422, "Vượt trần hoặc dưới mức tối thiểu", "Hạn mức hoặc tham số vượt trần hợp đồng hoặc dưới mức tối thiểu"),
    "019": (409, "Đối tượng đã ở trạng thái đích", "Đối tượng đã ở trạng thái đích hoặc đang được dùng (đã dừng, đã tạm ngừng, mẫu đang dùng)"),
    "020": (422, "Gói nhập không đọc được", "Gói nhập từ gateway cũ không đọc được, thiếu trường hoặc bị bộ quét từ chối"),
    "021": (400, "Khoảng truy vấn vượt giới hạn", "Khoảng thời gian truy vấn, báo cáo hoặc số dòng xuất vượt giới hạn"),
    "022": (403, "Không đủ quyền", "Thiếu quyền (`PERM`) hoặc thiếu scope dịch vụ"),
    "023": (409, "Route không ở trạng thái cho phép", "Route không ở trạng thái cho phép thao tác"),
    "024": (422, "Địa chỉ không được chặn", "Địa chỉ thuộc danh sách tin cậy hoặc hạ tầng, không được chặn"),
    "025": (409, "Chuyển tiếp tenant xung đột", "Tenant nguồn chưa `MERGED` hoặc đã có chuyển tiếp"),
    "026": (503, "Không đọc được số liệu PH-13", "Không đọc được số liệu từ PH-13"),
    "027": (422, "Chưa đủ điều kiện chuyển WAF sang chặn", "Chưa chạy phát hiện đủ 14 ngày hoặc còn quá nhiều cảnh báo giả chưa xử lý"),
}

# Mã lỗi gateway trả cho bên gọi: mã -> (HTTP, tiêu đề, ý nghĩa, bên gọi nên làm, retryable). Khớp D02-03-PH03 §9.1.
ERR_GW = {
    "101": ("400", "Yêu cầu không hợp lệ", "Yêu cầu sai cú pháp, lược đồ, kiểu nội dung hoặc vượt giới hạn cấu trúc", "Sửa yêu cầu theo `errors[]`", False),
    "102": ("401", "Thiếu thông tin xác thực", "Thiếu thông tin xác thực", "Gửi token trong `Authorization`", False),
    "103": ("401", "Token hoặc khóa API không hợp lệ", "Token hoặc khóa API không hợp lệ (chữ ký, `kid`, `iss`, `aud`)", "Lấy token mới", False),
    "104": ("401", "Token đã hết hạn", "Token đã hết hạn", "Lấy token mới rồi gọi lại", False),
    "105": ("401", "Token đã bị thu hồi", "Token đã bị thu hồi", "Liên hệ quản trị Datahub", False),
    "106": ("401", "Sai tenant", "Tenant của token không khớp realm hoặc tenant của API", "Dùng token của đúng tỉnh", False),
    "107": ("403", "Thiếu phạm vi quyền", "Thiếu phạm vi quyền (scope)", "Xin cấp thêm phạm vi", False),
    "108": ("403", "Chứng thư khách không hợp lệ", "Chứng thư khách không hợp lệ hoặc không khớp token", "Dùng đúng chứng thư đã đăng ký", False),
    "109": ("403", "Bị WAF chặn", "Bị WAF chặn", "Gửi `traceId` cho quản trị nếu nhầm", False),
    "110": ("403", "Địa chỉ nguồn bị chặn", "Địa chỉ nguồn bị chặn", "Liên hệ quản trị", False),
    "111": ("403", "Chưa đăng ký sử dụng", "HTTT chưa đăng ký sử dụng API hoặc đăng ký hết hiệu lực", "Liên hệ chủ dịch vụ", False),
    "112": ("403", "OPA từ chối", "OPA từ chối theo chính sách truy cập", "Xem lý do; liên hệ chủ quản dữ liệu", False),
    "113": ("403", "Đường dẫn bị chặn", "Đường dẫn bị chặn hoặc ngoài phạm vi gói", "Gọi đúng đường dẫn của gói", False),
    "114": ("404, 405", "Không có route khớp", "Không có route khớp; host không thuộc tenant nào; phương thức không được phép", "Kiểm tra địa chỉ, phương thức", False),
    "115": ("413", "Thân yêu cầu quá lớn", "Thân yêu cầu quá lớn", "Giảm kích thước hoặc dùng kênh tải tệp", False),
    "116": ("429", "Vượt tần suất của HTTT", "Vượt tần suất của HTTT (hoặc bị điều tiết, hoặc quá số kết nối WebSocket)", "Chờ `Retry-After` rồi thử lại", True),
    "117": ("429", "Vượt hạn ngạch", "Vượt hạn ngạch theo chu kỳ", "Chờ tới thời điểm đặt lại", True),
    "118": ("429", "Vượt hạn mức toàn tenant", "Vượt hạn mức toàn tenant", "Chờ giây lát, thử lại", True),
    "119": ("429", "Vượt giới hạn theo địa chỉ nguồn", "Vượt giới hạn tốc độ hoặc kết nối theo địa chỉ nguồn", "Giảm tốc độ, thử lại", True),
    "120": ("503", "Không có backend khỏe", "Không có backend khỏe hoặc mạch đang mở", "Chờ `Retry-After`", True),
    "121": ("504", "Backend quá hạn chờ", "Backend quá hạn chờ", "Thử lại; báo nếu lặp lại", True),
    "122": ("502", "Backend phản hồi không hợp lệ", "Backend phản hồi không hợp lệ", "Báo vận hành kèm `traceId`", False),
    "123": ("503", "API đang dừng", "API đang dừng hoặc route bị tạm ngừng", "Thử lại sau", True),
    "124": ("503", "Định danh hoặc ủy quyền tạm không khả dụng", "Dịch vụ định danh hoặc ủy quyền tạm không khả dụng (JWKS hết hạn đệm, OPA không phản hồi)", "Thử lại sau", True),
    "125": ("501", "Không hỗ trợ chuyển đổi giao thức", "Không hỗ trợ kiểu chuyển đổi giao thức", "Dùng giao thức được hỗ trợ", False),
    "126": ("410", "Phiên bản API đã hết hạn", "Phiên bản API đã hết hạn phục vụ", "Chuyển sang phiên bản mới", False),
    "127": ("403", "HTTT bị tạm ngừng truy cập", "HTTT đang bị tạm ngừng truy cập", "Liên hệ quản trị Datahub", False),
    "128": ("421", "Sai SNI hoặc Host", "SNI hoặc `Host` không khớp dịch vụ nào", "Kiểm tra địa chỉ truy cập", False),
    "129": ("500", "Lỗi nội bộ gateway", "Lỗi nội bộ gateway", "Báo vận hành kèm `traceId`", False),
    "130": ("403", "Sai phương thức xác thực", "Phương thức xác thực không đúng với gói của API", "Dùng phương thức của gói", False),
}

# Sự kiện: khóa, mã, địa chỉ topic, lược đồ payload, tóm tắt, ngày giữ, phân vùng, bên phát, khóa phân vùng, bên nhận
EVENTS = [
    ("snapshotPublished", "EVT-03-01", "{tenant}.gateway.snapshot.published.v1", "SnapshotPublished", "Ảnh chụp cấu hình được phát (FR-03-042).", 7, 3, "dh-connect", "`scope` (mã tenant hoặc `COMMON`)", "PH-02, PH-13"),
    ("snapshotRolledBack", "EVT-03-02", "{tenant}.gateway.snapshot.rolled-back.v1", "SnapshotRolledBack", "Quay lui cấu hình bằng ảnh chụp mới (FR-03-044).", 7, 3, "dh-connect", "`scope`", "PH-02, PH-13"),
    ("routeStateChanged", "EVT-03-03", "{tenant}.gateway.route.state-changed.v1", "RouteStateChanged", "Route dừng, mở, tạm ngừng, SUNSET, RETIRED hoặc đổi cửa vào (FR-03-035, 036, 038, 047).", 7, 3, "dh-connect", "`{routeCode}`", "PH-02, PH-13, PH-15"),
    ("consumerStateChanged", "EVT-03-04", "{tenant}.gateway.consumer.state-changed.v1", "ConsumerStateChanged", "Consumer tạo, đổi, tạm ngừng, gỡ (FR-03-046, 047).", 7, 3, "dh-connect", "`{consumerCode}`", "PH-01, PH-13"),
    ("wafExceptionChanged", "EVT-03-05", "{tenant}.gateway.waf-exception.changed.v1", "WafExceptionChanged", "Ngoại lệ WAF được đề nghị, duyệt, từ chối, thu hồi, hết hạn (FR-03-007).", 7, 3, "dh-connect", "`{exceptionId}`", "PH-13, thông báo SO"),
    ("wafExceptionExpiring", "EVT-03-06", "{tenant}.gateway.waf-exception.expiring.v1", "WafExceptionExpiring", "Ngoại lệ WAF còn 7 ngày hết hạn (FR-03-007).", 7, 3, "dh-connect", "`{exceptionId}`", "Thông báo SO, TA"),
    ("quotaThresholdReached", "EVT-03-07", "{tenant}.gateway.quota.threshold-reached.v1", "QuotaThresholdReached", "HTTT đạt 80% hoặc 100% hạn ngạch; tenant sắp chạm hạn mức (FR-03-022, 023).", 7, 3, "dh-connect (đọc luồng sự kiện hạn ngạch ở Valkey)", "`{consumerCode}` hoặc `TENANT`", "PH-02, thông báo đầu mối HTTT, TA"),
    ("certificateExpiring", "EVT-03-08", "{tenant}.gateway.certificate.expiring.v1", "CertificateExpiring", "Chứng thư biên còn dưới 30 ngày (FR-03-049).", 7, 3, "dh-connect", "`{certCode}`", "PH-13, PA"),
    ("securityAlertRaised", "EVT-03-09", "{tenant}.gateway.security.alert-raised.v1", "SecurityAlertRaised", "Sự kiện an ninh, vận hành của gateway (FR-03-004, 005, 006, 013, 014, 026, 027, 031, 047, 053, 054). Hai nguồn phát: APISIX qua `kafka-logger` và `dh-connect` qua outbox.", 7, 3, "apisix (kafka-logger), dh-connect", "`routeCode`, nếu không gắn route thì `node`", "PH-13 (SIEM)"),
    ("tenantRedirectChanged", "EVT-03-10", "{tenant}.gateway.tenant-redirect.changed.v1", "TenantRedirectChanged", "Chuyển tiếp tenant sáp nhập bắt đầu, kết thúc (FR-03-037).", 7, 3, "dh-connect", "`fromTenant`", "PH-20, PH-13"),
    ("limitChanged", "EVT-03-11", "{tenant}.gateway.limit.changed.v1", "LimitChanged", "Hạn mức toàn tenant, ghi đè hạn mức hoặc tham số hạn mức đổi (FR-03-023, 024, 056).", 7, 3, "dh-connect", "`scopeKey` (mã đối tượng hoặc khóa `gw.*`)", "PH-13, PH-20"),
    ("snapshotRejected", "EVT-03-12", "{tenant}.gateway.snapshot.rejected.v1", "SnapshotRejected", "Ảnh chụp bị từ chối khi kiểm tra hợp lệ, kèm danh sách lỗi (FR-03-040).", 7, 3, "dh-connect", "`scope`", "PH-02, thông báo người phát hành"),
]
