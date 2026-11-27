# language: vi
# Sinh tự động từ D02-02/D02-03-PH03 bằng backlog/tools/sinh_backlog.py; không sửa tay.
@PH-03
Tính năng: PH-03 · Cổng API

  # ---- EP-03-A · Lớp biên và bảo vệ truyền tải

  @US-03-001 @FR-03-001 @M
  Kịch bản: US-03-001 dương · Kết thúc TLS tại hai cửa vào
    Biết chứng thư biên của host đã được cấp và nạp (FR-03-049); ảnh chụp cấu hình đang chạy có phần `ssl` cho host đó
    Khi bên gọi mở kết nối TCP cổng 443 tới địa chỉ ảo của `apisix-ext` hoặc `apisix-int`
    Thì kết nối TLS được thiết lập; yêu cầu HTTP đã giải mã chuyển cho chuỗi plugin
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-03-001 @FR-03-001 @M @âm
  Kịch bản: US-03-001 âm 1 · Bên gọi chỉ hỗ trợ TLS dưới 1.2 hoặc bộ mã yếu
    Biết chứng thư biên của host đã được cấp và nạp (FR-03-049); ảnh chụp cấu hình đang chạy có phần `ssl` cho host đó
    Khi bên gọi chỉ hỗ trợ TLS dưới 1.2 hoặc bộ mã yếu
    Thì kết nối bị đóng ở bước bắt tay, bên gọi nhận cảnh báo TLS `protocol_version` hoặc `handshake_failure`; không có phản hồi HTTP. Chỉ số `dh_gateway_tls_handshake_total{result=thông báo}` tăng …
    Và người dùng thấy thông báo "rejected"

  @US-03-001 @FR-03-001 @M @âm
  Kịch bản: US-03-001 âm 2 · SNI không khớp host nào
    Biết chứng thư biên của host đã được cấp và nạp (FR-03-049); ảnh chụp cấu hình đang chạy có phần `ssl` cho host đó
    Khi SNI không khớp host nào
    Thì hệ thống từ chối với ERR-03-128 (421)
    Và người dùng thấy thông báo "Địa chỉ truy cập không thuộc dịch vụ nào của nền tảng."

  @US-03-002 @FR-03-002 @M
  Kịch bản: US-03-002 dương · Xác minh chứng thư khách mTLS
    Biết bộ CA khách đã nạp ở cấu hình `ssl.client.ca` của host; route đặt `requireMtls = true` hoặc consumer dùng phương thức `MTLS`; CRL hoặc OCSP của CA có thể đọc được
    Khi bên gọi xuất trình chứng thư trong bắt tay TLS tới host yêu cầu mTLS
    Thì ngữ cảnh yêu cầu có `client_cert_sha256` và `consumer` (nếu khớp); hoặc `403` theo ERR-03-108
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-03-002 @FR-03-002 @M @âm
  Kịch bản: US-03-002 âm 1 · Không xuất trình chứng thư ở route yêu cầu mTLS, hoặc chuỗi, hạn, thu hồi không đạt
    Biết bộ CA khách đã nạp ở cấu hình `ssl.client.ca` của host; route đặt `requireMtls = true` hoặc consumer dùng phương thức `MTLS`; CRL hoặc OCSP của CA có thể đọc được
    Khi không xuất trình chứng thư ở route yêu cầu mTLS, hoặc chuỗi, hạn, thu hồi không đạt
    Thì hệ thống từ chối với ERR-03-108 (403)
    Và người dùng thấy thông báo "Chứng thư của HTTT không hợp lệ hoặc không được phép. Kiểm tra chứng thư và liên hệ quản trị Datahub."

  @US-03-002 @FR-03-002 @M @âm
  Kịch bản: US-03-002 âm 2 · Không đọc được CRL quá 24 giờ
    Biết bộ CA khách đã nạp ở cấu hình `ssl.client.ca` của host; route đặt `requireMtls = true` hoặc consumer dùng phương thức `MTLS`; CRL hoặc OCSP của CA có thể đọc được
    Khi không đọc được CRL quá 24 giờ
    Thì hệ thống từ chối với ERR-03-108

  @US-03-003 @FR-03-003 @M
  Kịch bản: US-03-003 dương · Giới hạn kết nối và tốc độ theo địa chỉ nguồn
    Biết tham số `gw.ip.*` có trong ảnh chụp; bộ cân bằng tải truyền địa chỉ nguồn thật qua giao thức PROXY, APISIX tin tiêu đề chuyển tiếp chỉ từ dải của bộ cân bằng tải
    Khi mỗi kết nối mới và mỗi yêu cầu tới cửa vào
    Thì hệ thống trả `429` theo ERR-03-119 hoặc cho đi tiếp; chỉ số `dh_gateway_ip_limit_rejected_total{reason}`
    Và bộ đếm nằm ở bộ nhớ từng nút (độ chính xác theo nút là đủ cho lớp ngoài cùng); không ghi CSDL

  @US-03-003 @FR-03-003 @M @âm
  Kịch bản: US-03-003 âm 1 · Vượt kết nối hoặc tốc độ
    Biết tham số `gw.ip.*` có trong ảnh chụp; bộ cân bằng tải truyền địa chỉ nguồn thật qua giao thức PROXY, APISIX tin tiêu đề chuyển tiếp chỉ từ dải của bộ cân bằng tải
    Khi vượt kết nối hoặc tốc độ
    Thì hệ thống từ chối với ERR-03-119 (429)
    Và người dùng thấy thông báo "Quá nhiều yêu cầu từ địa chỉ của bạn trong thời gian ngắn. Thử lại sau {n} giây."

  @US-03-003 @FR-03-003 @M @âm
  Kịch bản: US-03-003 âm 2 · Đọc quá chậm
    Biết tham số `gw.ip.*` có trong ảnh chụp; bộ cân bằng tải truyền địa chỉ nguồn thật qua giao thức PROXY, APISIX tin tiêu đề chuyển tiếp chỉ từ dải của bộ cân bằng tải
    Khi đọc quá chậm
    Thì đóng kết nối, ghi chỉ số `dh_gateway_slow_client_total`; bên gọi không nhận phản hồi HTTP

  @US-03-004 @FR-03-004 @S
  Kịch bản: US-03-004 dương · Chặn tạm địa chỉ nguồn vi phạm liên tục
    Biết Valkey truy cập được (danh sách chặn nằm ở Valkey để mọi nút cùng thấy); tham số `gw.ip.autoBlock.*` có trong ảnh chụp
    Khi một địa chỉ vượt `gw.ip.autoBlock.threshold` lần bị từ chối ở FR-03-003 hoặc FR-03-005 trong 60 giây; hoặc SO bấm "Chặn địa chỉ" ở UI-03-15
    Thì hệ thống trả `201` cho chặn thủ công, thân gồm `blockId`, `cidr`, `expiresAt`; `204` khi bỏ chặn; phản hồi `403` ERR-03-110 cho địa chỉ bị chặn
    Và có bản ghi EN-03-14; khóa Valkey tương ứng
    Và sự kiện được phát: EVT-03-09 (cảnh báo an ninh) khi chặn tự động hoặc thủ công
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-03-004 @FR-03-004 @S @âm
  Kịch bản: US-03-004 âm 1 · Địa chỉ thuộc danh sách tin cậy hoặc hạ tầng
    Biết Valkey truy cập được (danh sách chặn nằm ở Valkey để mọi nút cùng thấy); tham số `gw.ip.autoBlock.*` có trong ảnh chụp
    Khi địa chỉ thuộc danh sách tin cậy hoặc hạ tầng
    Thì hệ thống từ chối với ERR-03-024 (422)
    Và người dùng thấy thông báo "Địa chỉ này thuộc danh sách tin cậy hoặc hạ tầng của nền tảng, không thể chặn."

  @US-03-005 @FR-03-005 @M
  Kịch bản: US-03-005 dương · WAF Coraza với bộ luật OWASP CRS
    Biết plugin proxy-wasm Coraza nạp ở cả hai cửa vào; bộ luật CRS 4.x trong ảnh APISIX; mức hoang tưởng và ngưỡng điểm bất thường có trong ảnh chụp
    Khi mỗi yêu cầu đã qua chốt kích thước thân (FR-03-009)
    Thì hệ thống trả `403` theo ERR-03-109 hoặc cho đi tiếp; bản ghi sự kiện WAF ở nhật ký an ninh
    Và sự kiện được phát: EVT-03-09 khi số sự kiện chặn tăng đột biến (FR-03-054)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-03-005 @FR-03-005 @M @âm
  Kịch bản: US-03-005 âm 1 · Bị chặn
    Biết plugin proxy-wasm Coraza nạp ở cả hai cửa vào; bộ luật CRS 4.x trong ảnh APISIX; mức hoang tưởng và ngưỡng điểm bất thường có trong ảnh chụp
    Khi bị chặn
    Thì hệ thống từ chối với ERR-03-109 (403)
    Và người dùng thấy thông báo "Yêu cầu bị từ chối bởi tường lửa ứng dụng. Nếu bạn cho rằng đây là nhầm lẫn, gửi mã truy vết {traceId} cho quản trị Datahub."

  @US-03-005 @FR-03-005 @M @âm
  Kịch bản: US-03-005 âm 2 · Cảnh báo giả
    Biết plugin proxy-wasm Coraza nạp ở cả hai cửa vào; bộ luật CRS 4.x trong ảnh APISIX; mức hoang tưởng và ngưỡng điểm bất thường có trong ảnh chụp
    Khi cảnh báo giả
    Thì vận hành đề nghị ngoại lệ ở FR-03-007

  @US-03-006 @FR-03-006 @M
  Kịch bản: US-03-006 dương · Chế độ phát hiện, chặn của WAF và tự hạ khi quá tải
    Biết WAF nạp ở cả hai cửa vào (FR-03-005)
    Khi SO bấm "Đổi chế độ WAF" ở UI-03-07; hoặc nút APISIX phát hiện WAF quá tải
    Thì hệ thống trả `202` với `requestId` của yêu cầu thay đổi; khi được duyệt, `snapshotVersion` mới
    Và chế độ WAF trong ảnh chụp đang chạy khớp quyết định; việc tự hạ ở nút không làm đổi cấu hình lưu
    Và sự kiện được phát: EVT-03-01 (ảnh chụp phát hành); EVT-03-09 khi tự hạ
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-03-006 @FR-03-006 @M @âm
  Kịch bản: US-03-006 âm 1 · Chưa đủ 14 ngày chạy phát hiện
    Biết WAF nạp ở cả hai cửa vào (FR-03-005)
    Khi chưa đủ 14 ngày chạy phát hiện
    Thì hệ thống từ chối với ERR-03-027 (422)
    Và người dùng thấy thông báo "Chưa thể chuyển sang chế độ chặn: cần chạy phát hiện tối thiểu 14 ngày (đã chạy {n} ngày)."

  @US-03-006 @FR-03-006 @M @âm
  Kịch bản: US-03-006 âm 2 · Người duyệt trùng người đề nghị
    Biết WAF nạp ở cả hai cửa vào (FR-03-005)
    Khi người duyệt trùng người đề nghị
    Thì hệ thống từ chối với ERR-03-008 (403)
    Và người dùng thấy thông báo "Bạn đã đề nghị thay đổi này nên không thể tự duyệt."

  @US-03-007 @FR-03-007 @M
  Kịch bản: US-03-007 dương · Ngoại lệ luật WAF có thời hạn
    Biết có sự kiện WAF chặn ở UI-03-07 làm căn cứ (chọn sự kiện để điền sẵn route và mã luật); người đề nghị có quyền ở tenant
    Khi người dùng bấm "Đề nghị ngoại lệ" trên một dòng sự kiện chặn
    Thì hệ thống trả `201`, chi tiết ngoại lệ `{exceptionId, state, expiresAt}`; `Location`, `ETag`
    Và EN-03-07 ở trạng thái mới; ảnh chụp cấu hình kế tiếp phản ánh danh sách ngoại lệ `ACTIVE`
    Và sự kiện được phát: EVT-03-05 (ngoại lệ đổi trạng thái); EVT-03-06 (sắp hết hạn)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-03-007 @FR-03-007 @M @âm
  Kịch bản: US-03-007 âm 1 · Thiếu lý do, quá 90 ngày hoặc mã luật không có
    Biết có sự kiện WAF chặn ở UI-03-07 làm căn cứ (chọn sự kiện để điền sẵn route và mã luật); người đề nghị có quyền ở tenant
    Khi thiếu lý do, quá 90 ngày hoặc mã luật không có
    Thì hệ thống từ chối với ERR-03-009 (422)
    Và người dùng thấy thông báo "Ngoại lệ cần có lý do, mã luật hợp lệ và thời hạn không quá 90 ngày."

  @US-03-007 @FR-03-007 @M @âm
  Kịch bản: US-03-007 âm 2 · Đã có ngoại lệ còn hiệu lực
    Biết có sự kiện WAF chặn ở UI-03-07 làm căn cứ (chọn sự kiện để điền sẵn route và mã luật); người đề nghị có quyền ở tenant
    Khi đã có ngoại lệ còn hiệu lực
    Thì hệ thống từ chối với ERR-03-010 (409)
    Và người dùng thấy thông báo "Route này đã có ngoại lệ cho luật {mã luật} đến {ngày}. Thu hồi ngoại lệ cũ hoặc chờ hết hạn."

  @US-03-008 @FR-03-008 @S
  Kịch bản: US-03-008 dương · Luật vá ảo khẩn cấp
    Biết chế độ WAF của phạm vi áp dụng là `BLOCK` hoặc `DETECT`; có thông tin lỗ hổng (CVE, cảnh báo của cơ quan chuyên trách)
    Khi SO bấm "Thêm luật vá ảo" ở UI-03-08
    Thì hệ thống trả `201`, `{patchId, state, expiresAt, dryRun: {sampleCount, wouldBlock}}`
    Và EN-03-08 `ACTIVE`; ảnh chụp mới chứa luật
    Và sự kiện được phát: EVT-03-01
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-03-008 @FR-03-008 @S @âm
  Kịch bản: US-03-008 âm 1 · Luật sai cú pháp hoặc chặn quá 1% mẫu sạch
    Biết chế độ WAF của phạm vi áp dụng là `BLOCK` hoặc `DETECT`; có thông tin lỗ hổng (CVE, cảnh báo của cơ quan chuyên trách)
    Khi luật sai cú pháp hoặc chặn quá 1% mẫu sạch
    Thì hệ thống từ chối với ERR-03-005 (422)
    Và người dùng thấy thông báo "Luật không hợp lệ hoặc chặn nhầm quá 1% yêu cầu mẫu. Xem chi tiết lỗi bên dưới."

  @US-03-009 @FR-03-009 @M
  Kịch bản: US-03-009 dương · Kiểm tra lược đồ và giới hạn kích thước yêu cầu
    Biết route có lược đồ OpenAPI đã duyệt ở PH-02 được đưa vào ảnh chụp (BR-03-014); tham số `gw.body.*` và `gw.json.*` có trong ảnh chụp
    Khi mỗi yêu cầu tới route, ở hai thời điểm: kiểm tra kích thước (chốt 3) và kiểm tra lược đồ (chốt 10, sau khi đã xác thực)
    Thì hệ thống trả `413` ERR-03-115 hoặc `400` ERR-03-101 theo RFC 9457 với `errors[]` (đường dẫn trường, quy tắc); hoặc cho đi tiếp

  @US-03-009 @FR-03-009 @M @âm
  Kịch bản: US-03-009 âm 1 · Thân quá lớn
    Biết route có lược đồ OpenAPI đã duyệt ở PH-02 được đưa vào ảnh chụp (BR-03-014); tham số `gw.body.*` và `gw.json.*` có trong ảnh chụp
    Khi thân quá lớn
    Thì hệ thống từ chối với ERR-03-115 (413)
    Và người dùng thấy thông báo "Nội dung gửi lên vượt giới hạn {n} MiB của API này. Giảm kích thước hoặc dùng kênh tải tệp."

  @US-03-009 @FR-03-009 @M @âm
  Kịch bản: US-03-009 âm 2 · Sai lược đồ, JSON quá sâu, XML bị cấm, `Content-Type` sai
    Biết route có lược đồ OpenAPI đã duyệt ở PH-02 được đưa vào ảnh chụp (BR-03-014); tham số `gw.body.*` và `gw.json.*` có trong ảnh chụp
    Khi sai lược đồ, JSON quá sâu, XML bị cấm, `Content-Type` sai
    Thì hệ thống từ chối với ERR-03-101 (400)
    Và người dùng thấy thông báo "Yêu cầu không đúng định dạng: {danh sách lỗi theo trường}."

  @US-03-010 @FR-03-010 @S
  Kịch bản: US-03-010 dương · Xử lý CORS
    Biết route có khai báo `corsPolicy` trong ảnh chụp; ở MVP giao diện `dh-console` và `dh-portal` cùng nguồn gốc với BFF nên không cần CORS
    Khi trình duyệt gửi yêu cầu kiểm tra trước (`OPTIONS`) hoặc yêu cầu có tiêu đề `Origin`
    Thì hệ thống trả `204` cho yêu cầu kiểm tra trước hợp lệ; tiêu đề CORS trên phản hồi
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-03-010 @FR-03-010 @S @âm
  Kịch bản: US-03-010 âm 1 · Cấu hình có ký tự đại diện hoặc nguồn gốc sai dạng
    Biết route có khai báo `corsPolicy` trong ảnh chụp; ở MVP giao diện `dh-console` và `dh-portal` cùng nguồn gốc với BFF nên không cần CORS
    Khi cấu hình có ký tự đại diện hoặc nguồn gốc sai dạng
    Thì hệ thống từ chối với ERR-03-005 (422)
    Và người dùng thấy thông báo "Không dùng ký tự đại diện cho nguồn gốc CORS. Nhập từng nguồn gốc đầy đủ, ví dụ https://qlvb.t68.gov.vn."

  @US-03-011 @FR-03-011 @M
  Kịch bản: US-03-011 dương · Tiêu đề bảo mật và che thông tin máy chủ
    Biết cấu hình tiêu đề mặc định có trong ảnh chụp
    Khi mỗi phản hồi gateway trả cho bên gọi, kể cả phản hồi lỗi do gateway sinh
    Thì phản hồi với tiêu đề đã làm sạch và bổ sung
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-03-011 @FR-03-011 @M @âm
  Kịch bản: US-03-011 âm 1 · Lỗi nội bộ gateway
    Biết cấu hình tiêu đề mặc định có trong ảnh chụp
    Khi lỗi nội bộ gateway
    Thì hệ thống từ chối với ERR-03-129 (500)
    Và người dùng thấy thông báo "Hệ thống gặp sự cố. Gửi mã truy vết {traceId} cho quản trị Datahub."

  # ---- EP-03-B · Xác thực và kiểm soát truy cập thô

  @US-03-012 @FR-03-012 @M
  Kịch bản: US-03-012 dương · Xác minh chữ ký JWT cục bộ
    Biết route yêu cầu token (không phải `KEYLESS`, FR-03-015); URL JWKS của realm tenant có trong ảnh chụp; bộ đệm JWKS đã nạp ít nhất một lần
    Khi yêu cầu có tiêu đề `Authorization: Bearer {token}` tới route yêu cầu xác thực
    Thì ngữ cảnh yêu cầu có `sub`, `client`, `scope`, `tenant`, `cnf`; hoặc `401`, `503` theo mã trên
    Và bộ đệm JWKS có thể được làm mới; không đổi dữ liệu khác
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-03-012 @FR-03-012 @M @âm
  Kịch bản: US-03-012 âm 1 · Thiếu tiêu đề hoặc sai lược đồ
    Biết route yêu cầu token (không phải `KEYLESS`, FR-03-015); URL JWKS của realm tenant có trong ảnh chụp; bộ đệm JWKS đã nạp ít nhất một lần
    Khi thiếu tiêu đề hoặc sai lược đồ
    Thì hệ thống từ chối với ERR-03-102 (401)
    Và người dùng thấy thông báo "datahub"

  @US-03-012 @FR-03-012 @M @âm
  Kịch bản: US-03-012 âm 2 · Chữ ký sai, `alg` cấm, `kid` lạ, `iss`, `aud` sai
    Biết route yêu cầu token (không phải `KEYLESS`, FR-03-015); URL JWKS của realm tenant có trong ảnh chụp; bộ đệm JWKS đã nạp ít nhất một lần
    Khi chữ ký sai, `alg` cấm, `kid` lạ, `iss`, `aud` sai
    Thì hệ thống từ chối với ERR-03-103 (401)
    Và người dùng thấy thông báo "Token không hợp lệ. Lấy token mới từ máy chủ định danh."

  @US-03-013 @FR-03-013 @M
  Kịch bản: US-03-013 dương · Xác định tenant của lượt gọi
    Biết token đã qua FR-03-012; route có `tenant` (hoặc là route dùng chung `COMMON`); bảng ánh xạ host với tenant có trong ảnh chụp
    Khi ngay sau khi xác minh chữ ký token
    Thì yêu cầu chuyển tiếp mang `X-DH-Tenant`, `X-DH-Client`, `X-DH-Consumer`; hoặc `401`
    Và sự kiện được phát: EVT-03-09 khi phát hiện truy cập chéo tenant (nghi tấn công)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-03-013 @FR-03-013 @M @âm
  Kịch bản: US-03-013 âm 1 · Tenant của token không khớp realm hoặc route
    Biết token đã qua FR-03-012; route có `tenant` (hoặc là route dùng chung `COMMON`); bảng ánh xạ host với tenant có trong ảnh chụp
    Khi tenant của token không khớp realm hoặc route
    Thì hệ thống từ chối với ERR-03-106 (401)
    Và người dùng thấy thông báo "Token không thuộc tỉnh của API này. Lấy token từ máy chủ định danh của đúng tỉnh."

  @US-03-013 @FR-03-013 @M @âm
  Kịch bản: US-03-013 âm 2 · Host không thuộc tenant nào
    Biết token đã qua FR-03-012; route có `tenant` (hoặc là route dùng chung `COMMON`); bảng ánh xạ host với tenant có trong ảnh chụp
    Khi host không thuộc tenant nào
    Thì hệ thống từ chối với ERR-03-114 (404)
    Và người dùng thấy thông báo "Không tìm thấy dịch vụ."

  @US-03-014 @FR-03-014 @M
  Kịch bản: US-03-014 dương · Ràng buộc token với chứng thư khách
    Biết token có claim `cnf.x5t#S256`; kết nối đã qua FR-03-002 và ngữ cảnh có `client_cert_sha256`; plan có `securityMode = MTLS` (hợp đồng mức Nhạy cảm bắt buộc, SEC-24)
    Khi sau FR-03-012 và FR-03-013, với route có `securityMode = MTLS` hoặc token có `cnf`
    Thì cho đi tiếp, hoặc `403` ERR-03-108
    Và sự kiện được phát: EVT-03-09 khi vân tay trong token không khớp chứng thư kết nối
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-03-014 @FR-03-014 @M @âm
  Kịch bản: US-03-014 âm 1 · Không khớp hoặc thiếu ràng buộc
    Biết token có claim `cnf.x5t#S256`; kết nối đã qua FR-03-002 và ngữ cảnh có `client_cert_sha256`; plan có `securityMode = MTLS` (hợp đồng mức Nhạy cảm bắt buộc, SEC-24)
    Khi không khớp hoặc thiếu ràng buộc
    Thì hệ thống từ chối với ERR-03-108 (403)
    Và người dùng thấy thông báo "Token không đi cùng chứng thư đã đăng ký của HTTT. Gọi lại bằng đúng chứng thư."

  @US-03-014 @FR-03-014 @M @âm
  Kịch bản: US-03-014 âm 2 · Chứng thư khách mới (đã xoay) chưa có trong EN-03-04
    Biết token có claim `cnf.x5t#S256`; kết nối đã qua FR-03-002 và ngữ cảnh có `client_cert_sha256`; plan có `securityMode = MTLS` (hợp đồng mức Nhạy cảm bắt buộc, SEC-24)
    Khi chứng thư khách mới (đã xoay) chưa có trong EN-03-04
    Thì hệ thống từ chối với ERR-03-108

  @US-03-015 @FR-03-015 @M
  Kịch bản: US-03-015 dương · Áp phương thức bảo mật theo gói sử dụng
    Biết mỗi route có gói (policy chiếu EN-03-05) với `securityMode` ∈ {`KEYLESS`, `API_KEY`, `OAUTH2`, `MTLS`}; ảnh chụp đã qua kiểm tra FR-03-040
    Khi mỗi lượt gọi tới route, ngay sau chốt TLS và địa chỉ nguồn
    Thì cho đi tiếp với danh tính consumer, hoặc `401`, `403` theo mã trên
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-03-015 @FR-03-015 @M @âm
  Kịch bản: US-03-015 âm 1 · Phương thức không đúng gói
    Biết mỗi route có gói (policy chiếu EN-03-05) với `securityMode` ∈ {`KEYLESS`, `API_KEY`, `OAUTH2`, `MTLS`}; ảnh chụp đã qua kiểm tra FR-03-040
    Khi phương thức không đúng gói
    Thì hệ thống từ chối với ERR-03-130 (403)
    Và người dùng thấy thông báo "API này yêu cầu xác thực bằng {OAuth 2.1 / chứng thư mTLS}. Phương thức bạn dùng không được chấp nhận."

  @US-03-015 @FR-03-015 @M @âm
  Kịch bản: US-03-015 âm 2 · Khóa API không tìm thấy hoặc hết hạn
    Biết mỗi route có gói (policy chiếu EN-03-05) với `securityMode` ∈ {`KEYLESS`, `API_KEY`, `OAUTH2`, `MTLS`}; ảnh chụp đã qua kiểm tra FR-03-040
    Khi khóa API không tìm thấy hoặc hết hạn
    Thì hệ thống từ chối với ERR-03-103 (401)
    Và người dùng thấy thông báo "Khóa API không hợp lệ hoặc đã hết hạn."

  @US-03-016 @FR-03-016 @M
  Kịch bản: US-03-016 dương · Kiểm tra đăng ký sử dụng và hiệu lực gói
    Biết consumer đã được nhận diện (token, chứng thư hoặc API key); ảnh chụp có danh sách đăng ký đang hiệu lực của consumer với route (plugin `consumer-restriction`)
    Khi sau khi nhận diện consumer, trước hạn mức
    Thì cho đi tiếp kèm chính sách của gói; hoặc `403`

  @US-03-016 @FR-03-016 @M @âm
  Kịch bản: US-03-016 âm 1 · Chưa đăng ký hoặc đăng ký hết hiệu lực
    Biết consumer đã được nhận diện (token, chứng thư hoặc API key); ảnh chụp có danh sách đăng ký đang hiệu lực của consumer với route (plugin `consumer-restriction`)
    Khi chưa đăng ký hoặc đăng ký hết hiệu lực
    Thì hệ thống từ chối với ERR-03-111 (403)
    Và người dùng thấy thông báo "HTTT của bạn chưa đăng ký sử dụng API này hoặc đăng ký đã hết hiệu lực. Liên hệ chủ dịch vụ hoặc quản trị Datahub."

  @US-03-016 @FR-03-016 @M @âm
  Kịch bản: US-03-016 âm 2 · HTTT đang bị tạm ngừng
    Biết consumer đã được nhận diện (token, chứng thư hoặc API key); ảnh chụp có danh sách đăng ký đang hiệu lực của consumer với route (plugin `consumer-restriction`)
    Khi HTTT đang bị tạm ngừng
    Thì hệ thống từ chối với ERR-03-127 (403)
    Và người dùng thấy thông báo "HTTT của bạn đang bị tạm ngừng truy cập. Liên hệ quản trị Datahub."

  @US-03-017 @FR-03-017 @M
  Kịch bản: US-03-017 dương · Kiểm tra phạm vi quyền thô
    Biết route khai báo `requiredScopes[]` (từ PH-02, có thể rỗng); token đã được xác minh (FR-03-012)
    Khi sau FR-03-016
    Thì cho đi tiếp, hoặc `403` ERR-03-107

  @US-03-017 @FR-03-017 @M @âm
  Kịch bản: US-03-017 âm 1 · Thiếu scope
    Biết route khai báo `requiredScopes[]` (từ PH-02, có thể rỗng); token đã được xác minh (FR-03-012)
    Khi thiếu scope
    Thì hệ thống từ chối với ERR-03-107 (403)
    Và người dùng thấy thông báo "Token thiếu phạm vi quyền {scope}. Xin cấp thêm phạm vi này cho HTTT của bạn."

  @US-03-018 @FR-03-018 @M
  Kịch bản: US-03-018 dương · Thu hồi token nhanh bằng danh sách chặn
    Biết Valkey truy cập được; plugin `dh-revocation` nạp ở mọi nút
    Khi PH-12 vô hiệu hóa một client hoặc người dùng ở Keycloak, hoặc thu hồi một token cụ thể, rồi gọi API-03-053
    Thì hệ thống trả `202` cho API-03-053, thân `{revocationId, effectiveBy}`; ở data plane: `401` ERR-03-105
    Và có khóa trong Valkey và bản ghi DB tới khi token hết hạn
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-03-018 @FR-03-018 @M @âm
  Kịch bản: US-03-018 âm 1 · Token trong danh sách chặn
    Biết Valkey truy cập được; plugin `dh-revocation` nạp ở mọi nút
    Khi token trong danh sách chặn
    Thì hệ thống từ chối với ERR-03-105 (401)
    Và người dùng thấy thông báo "Token đã bị thu hồi. Liên hệ quản trị Datahub nếu cần cấp lại."

  @US-03-018 @FR-03-018 @M @âm
  Kịch bản: US-03-018 âm 2 · Valkey không khả dụng
    Biết Valkey truy cập được; plugin `dh-revocation` nạp ở mọi nút
    Khi Valkey không khả dụng
    Thì nút dùng bộ đệm cục bộ gần nhất, cảnh báo ở FR-03-026 và FR-03-054; token đã thu hồi sau lúc mất Valkey chỉ có hiệu lực chặn khi Valkey trở lại hoặc khi token hết hạn (tối đa 5 phút)

  @US-03-019 @FR-03-019 @M
  Kịch bản: US-03-019 dương · Ủy quyền chi tiết bằng OPA tại gateway
    Biết OPA sidecar trong pod APISIX đã nạp gói chính sách ký và đã lưu bền (`persist`); mỗi route có `policyPackage` (BR-03-014)
    Khi sau khi qua hạn mức (chốt 8), trước khi định tuyến
    Thì cho đi tiếp kèm `X-DH-Obligations` (nếu có), hoặc `403`, `503`
    Và có bản ghi quyết định ở Loki; không đổi dữ liệu khác
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-03-019 @FR-03-019 @M @âm
  Kịch bản: US-03-019 âm 1 · OPA từ chối
    Biết OPA sidecar trong pod APISIX đã nạp gói chính sách ký và đã lưu bền (`persist`); mỗi route có `policyPackage` (BR-03-014)
    Khi OPA từ chối
    Thì hệ thống từ chối với ERR-03-112 (403)
    Và người dùng thấy thông báo "Yêu cầu không được phép theo chính sách truy cập. {lý do}. Liên hệ chủ quản dữ liệu nếu cần cấp quyền."

  @US-03-019 @FR-03-019 @M @âm
  Kịch bản: US-03-019 âm 2 · OPA không phản hồi trong 50 ms hoặc chưa có gói chính sách
    Biết OPA sidecar trong pod APISIX đã nạp gói chính sách ký và đã lưu bền (`persist`); mỗi route có `policyPackage` (BR-03-014)
    Khi OPA không phản hồi trong 50 ms hoặc chưa có gói chính sách
    Thì hệ thống từ chối với ERR-03-124 (503)
    Và người dùng thấy thông báo "Dịch vụ ủy quyền tạm thời không khả dụng. Thử lại sau."

  @US-03-020 @FR-03-020 @M
  Kịch bản: US-03-020 dương · Danh sách cho phép và chặn đường dẫn
    Biết gói của đăng ký có `pathAllow[]`, `pathDeny[]` (mẫu đường dẫn); route sinh ra gồm các mẫu này
    Khi sau FR-03-016, khi có chính sách của gói trong ngữ cảnh
    Thì cho đi tiếp, hoặc `403` ERR-03-113

  @US-03-020 @FR-03-020 @M @âm
  Kịch bản: US-03-020 âm 1 · Đường dẫn bị chặn hoặc không nằm trong danh sách cho phép
    Biết gói của đăng ký có `pathAllow[]`, `pathDeny[]` (mẫu đường dẫn); route sinh ra gồm các mẫu này
    Khi đường dẫn bị chặn hoặc không nằm trong danh sách cho phép
    Thì hệ thống từ chối với ERR-03-113 (403)
    Và người dùng thấy thông báo "Đường dẫn này không nằm trong phạm vi gói sử dụng của HTTT của bạn."

  @US-03-020 @FR-03-020 @M @âm
  Kịch bản: US-03-020 âm 2 · Mẫu đường dẫn sai cú pháp ở cấu hình
    Biết gói của đăng ký có `pathAllow[]`, `pathDeny[]` (mẫu đường dẫn); route sinh ra gồm các mẫu này
    Khi mẫu đường dẫn sai cú pháp ở cấu hình
    Thì hệ thống từ chối với ERR-03-005

  # ---- EP-03-C · Hạn mức và hạn ngạch

  @US-03-021 @FR-03-021 @M
  Kịch bản: US-03-021 dương · Giới hạn tần suất theo bên gọi
    Biết consumer và đăng ký đã được nhận diện (FR-03-016); gói có `rateLimits[]`; Valkey truy cập được (nếu không, FR-03-026)
    Khi mỗi lượt gọi tới route sau khi qua đăng ký sử dụng
    Thì cho đi tiếp kèm `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`; hoặc `429` ERR-03-116
    Và bộ đếm ở Valkey tự hết hạn theo cửa sổ; không ghi CSDL

  @US-03-021 @FR-03-021 @M @âm
  Kịch bản: US-03-021 âm 1 · Vượt tần suất
    Biết consumer và đăng ký đã được nhận diện (FR-03-016); gói có `rateLimits[]`; Valkey truy cập được (nếu không, FR-03-026)
    Khi vượt tần suất
    Thì hệ thống từ chối với ERR-03-116 (429)
    Và người dùng thấy thông báo "HTTT {mã} đã dùng hết {n} lượt trong {w} giây cho API {mã API}. Thử lại sau {s} giây."

  @US-03-021 @FR-03-021 @M @âm
  Kịch bản: US-03-021 âm 2 · Valkey không khả dụng
    Biết consumer và đăng ký đã được nhận diện (FR-03-016); gói có `rateLimits[]`; Valkey truy cập được (nếu không, FR-03-026)
    Khi Valkey không khả dụng
    Thì chuyển sang đếm cục bộ theo FR-03-026, không từ chối lượt gọi vì lý do này

  @US-03-022 @FR-03-022 @M
  Kịch bản: US-03-022 dương · Hạn ngạch theo chu kỳ và cảnh báo ngưỡng
    Biết gói có `quotas[]` (chu kỳ `HOUR`, `DAY`, `MONTH`, số lượt); Valkey truy cập được
    Khi mỗi lượt gọi, sau chốt tần suất; và tác vụ định kỳ 5 phút của `dh-connect` đọc mức dùng để cảnh báo
    Thì cho đi tiếp kèm `X-Quota-Remaining`; hoặc `429` ERR-03-117
    Và bộ đếm theo chu kỳ ở Valkey; bản tổng hợp theo ngày được PH-13 giữ từ siêu dữ liệu lượt gọi
    Và sự kiện được phát: EVT-03-07

  @US-03-022 @FR-03-022 @M @âm
  Kịch bản: US-03-022 âm 1 · Vượt hạn ngạch
    Biết gói có `quotas[]` (chu kỳ `HOUR`, `DAY`, `MONTH`, số lượt); Valkey truy cập được
    Khi vượt hạn ngạch
    Thì hệ thống từ chối với ERR-03-117 (429)
    Và người dùng thấy thông báo "HTTT {mã} đã dùng hết hạn ngạch {n} lượt/{ngày/tháng/giờ} cho API {mã API}. Hạn ngạch đặt lại lúc {thời điểm}."

  @US-03-022 @FR-03-022 @M @âm
  Kịch bản: US-03-022 âm 2 · Valkey không khả dụng
    Biết gói có `quotas[]` (chu kỳ `HOUR`, `DAY`, `MONTH`, số lượt); Valkey truy cập được
    Khi Valkey không khả dụng
    Thì hạn ngạch mở có cảnh báo (FR-03-026), không chặn lượt gọi vì lý do này

  @US-03-023 @FR-03-023 @M
  Kịch bản: US-03-023 dương · Hạn mức toàn tenant
    Biết hạn mức hợp đồng của tenant có ở PH-20 và được PH-03 nhận khi khởi tạo tenant; Valkey truy cập được
    Khi mỗi lượt gọi của tenant; và khi quản trị đổi hạn mức
    Thì hệ thống trả `200` với hạn mức hiệu lực `{limitPerSecond, burst, validTo, ceiling}` hoặc `202` khi chờ duyệt; ở data plane: `429` ERR-03-118
    Và hạn mức mới trong ảnh chụp đang chạy; bản ghi yêu cầu thay đổi (nếu hạ)
    Và sự kiện được phát: EVT-03-11 (hạn mức đổi); EVT-03-07 (sắp chạm)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-03-023 @FR-03-023 @M @âm
  Kịch bản: US-03-023 âm 1 · Vượt hạn mức tenant
    Biết hạn mức hợp đồng của tenant có ở PH-20 và được PH-03 nhận khi khởi tạo tenant; Valkey truy cập được
    Khi vượt hạn mức tenant
    Thì hệ thống từ chối với ERR-03-118 (429)
    Và người dùng thấy thông báo "Tỉnh {tenant} đang vượt hạn mức {n} lượt/giây của nền tảng. Thử lại sau giây lát."

  @US-03-023 @FR-03-023 @M @âm
  Kịch bản: US-03-023 âm 2 · Đặt vượt trần hợp đồng hoặc dưới mức tối thiểu 10
    Biết hạn mức hợp đồng của tenant có ở PH-20 và được PH-03 nhận khi khởi tạo tenant; Valkey truy cập được
    Khi đặt vượt trần hợp đồng hoặc dưới mức tối thiểu 10
    Thì hệ thống từ chối với ERR-03-018 (422)
    Và người dùng thấy thông báo "Hạn mức phải từ 10 đến {trần} lượt/giây theo hợp đồng của tỉnh."

  @US-03-024 @FR-03-024 @S
  Kịch bản: US-03-024 dương · Hạn mức theo route và thứ tự ưu tiên chính sách
    Biết route và consumer tồn tại; hạn mức hợp đồng tenant (FR-03-023) đã có
    Khi quản trị bấm "Thêm hạn mức" ở UI-03-06
    Thì hệ thống trả `201`, chi tiết `{overrideId, scope, limit, windowSeconds, burst, validTo}`
    Và EN-03-06 mới; ảnh chụp mới có hạn mức
    Và sự kiện được phát: EVT-03-11
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-03-024 @FR-03-024 @S @âm
  Kịch bản: US-03-024 âm 1 · Vượt trần hoặc sai miền
    Biết route và consumer tồn tại; hạn mức hợp đồng tenant (FR-03-023) đã có
    Khi vượt trần hoặc sai miền
    Thì hệ thống từ chối với ERR-03-018 (422)
    Và người dùng thấy thông báo "Hạn mức phải nằm trong trần của tỉnh ({trần} lượt/giây)."

  @US-03-025 @FR-03-025 @M
  Kịch bản: US-03-025 dương · Phản hồi vượt hạn mức và tiêu đề hạn mức
    Biết route có ít nhất một hạn mức hoặc hạn ngạch áp dụng
    Khi mỗi phản hồi của route có hạn mức, thành công hoặc bị từ chối
    Thì tiêu đề hạn mức trên phản hồi; `429` ERR-03-116…119 khi từ chối

  @US-03-025 @FR-03-025 @M @âm
  Kịch bản: US-03-025 âm 1 · Không tính được `Remaining` vì Valkey mất
    Biết route có ít nhất một hạn mức hoặc hạn ngạch áp dụng
    Khi không tính được `Remaining` vì Valkey mất
    Thì bỏ tiêu đề `X-RateLimit-Remaining`, giữ `Limit` và đặt `X-RateLimit-Degraded: true` (FR-03-026)

  @US-03-026 @FR-03-026 @M
  Kịch bản: US-03-026 dương · Suy giảm có kiểm soát khi Valkey mất
    Biết plugin `limit-count` cấu hình cho phép suy giảm; plugin `limit-req` cục bộ có trong chuỗi chốt
    Khi lệnh tới Valkey quá 50 ms hoặc lỗi kết nối
    Thì lượt gọi tiếp tục được phục vụ; tiêu đề `X-RateLimit-Degraded`
    Và bộ đếm có thể sai lệch trong chu kỳ đang chạy; không mất dữ liệu cấu hình
    Và sự kiện được phát: EVT-03-09 (cảnh báo an ninh vận hành) khi bắt đầu và kết thúc suy giảm

  @US-03-026 @FR-03-026 @M @âm
  Kịch bản: US-03-026 âm 1 · Valkey chậm nhưng không mất
    Biết plugin `limit-count` cấu hình cho phép suy giảm; plugin `limit-req` cục bộ có trong chuỗi chốt
    Khi Valkey chậm nhưng không mất
    Thì giữ chế độ thường, tăng chỉ số `dh_gateway_valkey_latency_seconds` và cảnh báo Cao khi p99 vượt 20 ms

  @US-03-026 @FR-03-026 @M @âm
  Kịch bản: US-03-026 âm 2 · Chế độ suy giảm kéo dài trên 15 phút
    Biết plugin `limit-count` cấu hình cho phép suy giảm; plugin `limit-req` cục bộ có trong chuỗi chốt
    Khi chế độ suy giảm kéo dài trên 15 phút
    Thì cảnh báo leo thang, đề nghị PA xem xét tăng bản sao Valkey

  @US-03-027 @FR-03-027 @S
  Kịch bản: US-03-027 dương · Điều tiết theo tình trạng backend
    Biết consumer có `priorityGroup` ∈ {`ESSENTIAL`, `NORMAL`, `LOW`} (mặc định `NORMAL`); chỉ số sức khỏe backend có sẵn từ FR-03-030
    Khi tỉ lệ lỗi hoặc độ trễ của upstream vượt ngưỡng trong 1 phút
    Thì hạn mức hiệu lực thay đổi theo thời gian; tiêu đề `X-DH-Throttled`
    Và hệ số điều tiết ở bộ nhớ nút, không lưu
    Và sự kiện được phát: EVT-03-09 khi bắt đầu điều tiết một route

  @US-03-027 @FR-03-027 @S @âm
  Kịch bản: US-03-027 âm 1 · Bị điều tiết
    Biết consumer có `priorityGroup` ∈ {`ESSENTIAL`, `NORMAL`, `LOW`} (mặc định `NORMAL`); chỉ số sức khỏe backend có sẵn từ FR-03-030
    Khi bị điều tiết
    Thì hệ thống từ chối với ERR-03-116 (429)
    Và người dùng thấy thông báo "Dịch vụ {mã API} đang quá tải nên hạn mức của HTTT bạn tạm giảm. Thử lại sau {s} giây."

  # ---- EP-03-D · Định tuyến và chuyển tiếp

  @US-03-028 @FR-03-028 @M
  Kịch bản: US-03-028 dương · Định tuyến theo host, đường dẫn, phương thức
    Biết route ở trạng thái `ACTIVE` trong ảnh chụp đang chạy; mỗi route có `hostPattern`, `pathPattern`, `methods[]`, `priority`
    Khi mỗi yêu cầu qua các chốt trước
    Thì yêu cầu chuyển cho FR-03-029; hoặc `404`, `405`

  @US-03-028 @FR-03-028 @M @âm
  Kịch bản: US-03-028 âm 1 · Không route khớp hoặc host không thuộc tenant nào
    Biết route ở trạng thái `ACTIVE` trong ảnh chụp đang chạy; mỗi route có `hostPattern`, `pathPattern`, `methods[]`, `priority`
    Khi không route khớp hoặc host không thuộc tenant nào
    Thì hệ thống từ chối với ERR-03-114 (404)
    Và người dùng thấy thông báo "Không tìm thấy dịch vụ hoặc đường dẫn."

  @US-03-028 @FR-03-028 @M @âm
  Kịch bản: US-03-028 âm 2 · Phương thức không được phép
    Biết route ở trạng thái `ACTIVE` trong ảnh chụp đang chạy; mỗi route có `hostPattern`, `pathPattern`, `methods[]`, `priority`
    Khi phương thức không được phép
    Thì hệ thống từ chối với ERR-03-114
    Và người dùng thấy thông báo "Phương thức không được phép cho đường dẫn này."

  @US-03-029 @FR-03-029 @M
  Kịch bản: US-03-029 dương · Cân bằng tải giữa các backend
    Biết upstream có một hoặc nhiều nút (`address`, `port`, `weight`); ít nhất một nút khỏe mạnh (FR-03-030)
    Khi sau khi chọn được route
    Thì phản hồi của backend; hoặc `503`, `502`

  @US-03-029 @FR-03-029 @M @âm
  Kịch bản: US-03-029 âm 1 · Không còn nút khỏe
    Biết upstream có một hoặc nhiều nút (`address`, `port`, `weight`); ít nhất một nút khỏe mạnh (FR-03-030)
    Khi không còn nút khỏe
    Thì hệ thống từ chối với ERR-03-120 (503)
    Và người dùng thấy thông báo "Dịch vụ tạm thời không khả dụng. Thử lại sau {s} giây."

  @US-03-029 @FR-03-029 @M @âm
  Kịch bản: US-03-029 âm 2 · Backend trả phản hồi không hợp lệ (đóng kết nối giữa chừng, không đúng giao thức)
    Biết upstream có một hoặc nhiều nút (`address`, `port`, `weight`); ít nhất một nút khỏe mạnh (FR-03-030)
    Khi backend trả phản hồi không hợp lệ (đóng kết nối giữa chừng, không đúng giao thức)
    Thì hệ thống từ chối với ERR-03-122 (502)
    Và người dùng thấy thông báo "Dịch vụ phía sau trả về phản hồi không hợp lệ."

  @US-03-030 @FR-03-030 @M
  Kịch bản: US-03-030 dương · Kiểm tra sức khỏe backend chủ động và thụ động
    Biết upstream khai báo kiểm tra sức khỏe: đường dẫn (mặc định `/readyz`), phương thức, mã trả về chấp nhận
    Khi bộ kiểm tra định kỳ mỗi `gw.upstream.healthcheck.intervalSeconds` (5); và mỗi phản hồi thực tế của nút
    Thì danh sách nút khả dụng của mỗi upstream; chỉ số sức khỏe
    Và trạng thái sức khỏe ở bộ nhớ từng nút; không lưu CSDL

  @US-03-030 @FR-03-030 @M @âm
  Kịch bản: US-03-030 âm 1 · Mọi nút không khỏe
    Biết upstream khai báo kiểm tra sức khỏe: đường dẫn (mặc định `/readyz`), phương thức, mã trả về chấp nhận
    Khi mọi nút không khỏe
    Thì hệ thống từ chối với ERR-03-120 (503)
    Và người dùng thấy thông báo "Dịch vụ tạm thời không khả dụng. Thử lại sau 5 giây."

  @US-03-030 @FR-03-030 @M @âm
  Kịch bản: US-03-030 âm 2 · Bộ kiểm tra không tới được nút do mạng gateway bị chặn
    Biết upstream khai báo kiểm tra sức khỏe: đường dẫn (mặc định `/readyz`), phương thức, mã trả về chấp nhận
    Khi bộ kiểm tra không tới được nút do mạng gateway bị chặn
    Thì nút bị coi không khỏe; cảnh báo cấu hình mạng

  @US-03-031 @FR-03-031 @M
  Kịch bản: US-03-031 dương · Thời hạn chờ, ngắt mạch và trả lỗi nhanh
    Biết route có `timeouts` (`connectMs` 3.000, `sendMs` 10.000, `readMs` 10.000, trần 30.000) và `breaker` (`api-breaker`)
    Khi mỗi lượt gọi tới backend; và khi số lỗi liên tiếp của upstream vượt ngưỡng
    Thì hệ thống trả `504` ERR-03-121 hoặc `503` ERR-03-120; hoặc phản hồi backend
    Và trạng thái mạch ở bộ nhớ nút
    Và sự kiện được phát: EVT-03-09 khi mạch mở lần đầu trong 10 phút

  @US-03-031 @FR-03-031 @M @âm
  Kịch bản: US-03-031 âm 1 · Quá hạn chờ
    Biết route có `timeouts` (`connectMs` 3.000, `sendMs` 10.000, `readMs` 10.000, trần 30.000) và `breaker` (`api-breaker`)
    Khi quá hạn chờ
    Thì hệ thống từ chối với ERR-03-121 (504)
    Và người dùng thấy thông báo "Dịch vụ phía sau không phản hồi kịp. Thử lại; nếu lặp lại, gửi mã truy vết {traceId} cho quản trị."

  @US-03-031 @FR-03-031 @M @âm
  Kịch bản: US-03-031 âm 2 · Mạch mở
    Biết route có `timeouts` (`connectMs` 3.000, `sendMs` 10.000, `readMs` 10.000, trần 30.000) và `breaker` (`api-breaker`)
    Khi mạch mở
    Thì hệ thống từ chối với ERR-03-120 (503)
    Và người dùng thấy thông báo "Dịch vụ đang được bảo vệ vì lỗi liên tiếp. Thử lại sau {s} giây."

  @US-03-032 @FR-03-032 @M
  Kịch bản: US-03-032 dương · Sinh và truyền định danh truy vết
    Biết plugin `opentelemetry` (hoặc `zipkin`) bật ở mọi route
    Khi mỗi yêu cầu vào gateway
    Thì tiêu đề `X-Trace-Id`; span OTLP

  @US-03-032 @FR-03-032 @M @âm
  Kịch bản: US-03-032 âm 1 · `traceparent` sai định dạng
    Biết plugin `opentelemetry` (hoặc `zipkin`) bật ở mọi route
    Khi `traceparent` sai định dạng
    Thì gateway sinh mới, không có lỗi trả bên gọi; chỉ số `dh_gateway_trace_invalid_total` tăng

  @US-03-032 @FR-03-032 @M @âm
  Kịch bản: US-03-032 âm 2 · Collector không khả dụng
    Biết plugin `opentelemetry` (hoặc `zipkin`) bật ở mọi route
    Khi collector không khả dụng
    Thì span đệm cục bộ có giới hạn, bỏ điểm cũ nhất khi đầy; không ảnh hưởng lượt gọi

  @US-03-033 @FR-03-033 @M
  Kịch bản: US-03-033 dương · Chuyển tiếp WebSocket và nén nội dung
    Biết route khai báo `protocols` gồm `ws`, `wss` (nếu dùng) và `compression`
    Khi yêu cầu nâng cấp kết nối `Upgrade: websocket`, hoặc yêu cầu có `Accept-Encoding`
    Thì kết nối WebSocket được chuyển tiếp; hoặc phản hồi nén

  @US-03-033 @FR-03-033 @M @âm
  Kịch bản: US-03-033 âm 1 · Vượt số kết nối WebSocket của HTTT
    Biết route khai báo `protocols` gồm `ws`, `wss` (nếu dùng) và `compression`
    Khi vượt số kết nối WebSocket của HTTT
    Thì hệ thống từ chối với ERR-03-116 (429)
    Và người dùng thấy thông báo "HTTT đang giữ quá {n} kết nối WebSocket cho API này. Đóng bớt kết nối rồi thử lại."

  @US-03-033 @FR-03-033 @M @âm
  Kịch bản: US-03-033 âm 2 · Route chưa bật WebSocket
    Biết route khai báo `protocols` gồm `ws`, `wss` (nếu dùng) và `compression`
    Khi route chưa bật WebSocket
    Thì hệ thống từ chối với ERR-03-101 (400)
    Và người dùng thấy thông báo "API này không hỗ trợ WebSocket."

  @US-03-034 @FR-03-034 @C
  Kịch bản: US-03-034 dương · Chuyển đổi gRPC và REST
    Biết có tệp mô tả `.proto` được duyệt ở PH-02 cho API; plugin `grpc-transcode` có trong danh mục (BR-03-017)
    Khi yêu cầu REST/JSON tới route có `transcode.grpc`
    Thì phản hồi JSON; hoặc `501`, `422`
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-03-034 @FR-03-034 @C @âm
  Kịch bản: US-03-034 âm 1 · Cặp chuyển đổi không hỗ trợ
    Biết có tệp mô tả `.proto` được duyệt ở PH-02 cho API; plugin `grpc-transcode` có trong danh mục (BR-03-017)
    Khi cặp chuyển đổi không hỗ trợ
    Thì hệ thống từ chối với ERR-03-125 (501)
    Và người dùng thấy thông báo "Gateway chưa hỗ trợ kiểu chuyển đổi giao thức này."

  @US-03-035 @FR-03-035 @S
  Kịch bản: US-03-035 dương · Phiên bản API song song và tiêu đề ngừng dùng
    Biết hai phiên bản của một API cùng `ACTIVE`; phiên bản cũ có `deprecatedAt` và `sunsetAt` ở PH-02 (hạn tối thiểu `gw.sunset.minDays` = 180 ngày kể từ `deprecatedAt`)
    Khi mỗi lượt gọi tới phiên bản đã đánh dấu ngừng dùng; và khi tới `sunsetAt`
    Thì tiêu đề `Deprecation`, `Sunset`, `Link`; hoặc `410`
    Và route đổi trạng thái theo mốc thời gian
    Và sự kiện được phát: EVT-03-03 (route đổi trạng thái)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-03-035 @FR-03-035 @S @âm
  Kịch bản: US-03-035 âm 1 · Phiên bản đã hết hạn
    Biết hai phiên bản của một API cùng `ACTIVE`; phiên bản cũ có `deprecatedAt` và `sunsetAt` ở PH-02 (hạn tối thiểu `gw.sunset.minDays` = 180 ngày kể từ `deprecatedAt`)
    Khi phiên bản đã hết hạn
    Thì hệ thống từ chối với ERR-03-126 (410)
    Và người dùng thấy thông báo "Phiên bản {v} của API {mã} đã ngừng phục vụ từ {ngày}. Chuyển sang phiên bản {v mới}."

  @US-03-036 @FR-03-036 @M
  Kịch bản: US-03-036 dương · Dừng và mở API tức thời
    Biết route `ACTIVE` (để dừng) hoặc `STOPPED` (để mở)
    Khi người vận hành bấm "Dừng API" hoặc "Mở API" ở UI-03-02 hoặc UI-03-03
    Thì hệ thống trả `202`, `{routeCode, state, snapshotVersion}`; ở data plane `503` ERR-03-123
    Và route ở trạng thái mới; ảnh chụp mới được phát
    Và sự kiện được phát: EVT-03-03
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-03-036 @FR-03-036 @M @âm
  Kịch bản: US-03-036 âm 1 · Route đã dừng (hoặc đã mở)
    Biết route `ACTIVE` (để dừng) hoặc `STOPPED` (để mở)
    Khi route đã dừng (hoặc đã mở)
    Thì hệ thống từ chối với ERR-03-019 (409)
    Và người dùng thấy thông báo "API đang ở trạng thái {trạng thái}."

  @US-03-036 @FR-03-036 @M @âm
  Kịch bản: US-03-036 âm 2 · Route không cho thao tác
    Biết route `ACTIVE` (để dừng) hoặc `STOPPED` (để mở)
    Khi route không cho thao tác
    Thì hệ thống từ chối với ERR-03-023 (409)
    Và người dùng thấy thông báo "Không thể dừng hoặc mở API ở trạng thái {trạng thái}."

  @US-03-037 @FR-03-037 @S
  Kịch bản: US-03-037 dương · Chuyển tiếp lượt gọi của tenant đã sáp nhập
    Biết tenant nguồn ở trạng thái `MERGED`; tenant đích `ACTIVE`; có bảng ánh xạ API nguồn sang API đích do PH-20 cung cấp
    Khi PA tạo chuyển tiếp ở UI-03-16 khi PH-20 chuyển tenant nguồn sang `MERGED`
    Thì hệ thống trả `201`, `{redirectId, state, endAt}`
    Và EN-03-13 `ACTIVE`; ảnh chụp mới có route chuyển tiếp
    Và sự kiện được phát: EVT-03-10
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-03-037 @FR-03-037 @S @âm
  Kịch bản: US-03-037 âm 1 · Tenant nguồn chưa `MERGED` hoặc đã có chuyển tiếp
    Biết tenant nguồn ở trạng thái `MERGED`; tenant đích `ACTIVE`; có bảng ánh xạ API nguồn sang API đích do PH-20 cung cấp
    Khi tenant nguồn chưa `MERGED` hoặc đã có chuyển tiếp
    Thì hệ thống từ chối với ERR-03-025 (409)
    Và người dùng thấy thông báo "Chỉ tạo được chuyển tiếp cho tỉnh đã sáp nhập và chưa có chuyển tiếp đang chạy."

  @US-03-038 @FR-03-038 @M
  Kịch bản: US-03-038 dương · Phân cửa vào Internet và mạng nội bộ
    Biết route đã `ACTIVE` ở cửa `INT`; có lý do nghiệp vụ
    Khi TA bấm "Mở ra Internet" ở UI-03-03
    Thì hệ thống trả `202`, `{requestId, state}`; khi được duyệt, `snapshotVersion`
    Và `exposure` của route đổi theo quyết định
    Và sự kiện được phát: EVT-03-03
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-03-038 @FR-03-038 @M @âm
  Kịch bản: US-03-038 âm 1 · Route chưa đủ điều kiện ra cửa ngoài
    Biết route đã `ACTIVE` ở cửa `INT`; có lý do nghiệp vụ
    Khi route chưa đủ điều kiện ra cửa ngoài
    Thì hệ thống từ chối với ERR-03-011 (422)
    Và người dùng thấy thông báo "Route chưa đủ điều kiện mở ra Internet: {lý do}."

  @US-03-038 @FR-03-038 @M @âm
  Kịch bản: US-03-038 âm 2 · Tự duyệt
    Biết route đã `ACTIVE` ở cửa `INT`; có lý do nghiệp vụ
    Khi tự duyệt
    Thì hệ thống từ chối với ERR-03-008 (403)

  # ---- EP-03-E · Đồng bộ cấu hình

  @US-03-039 @FR-03-039 @M
  Kịch bản: US-03-039 dương · Tổng hợp cấu hình gateway từ danh mục
    Biết các phân hệ nguồn trả được dữ liệu (nếu không, dùng bản đã lưu gần nhất, quá 24 giờ thì cảnh báo); mẫu chính sách đã bật cho tenant (FR-03-048)
    Khi (a) Sự kiện từ PH-02 (API công bố, ngừng, gói đổi, đăng ký đổi), PH-01 (HTTT đổi trạng thái), PH-12 (gói chính sách mới), PH-20 (hạn mức, host của tenant); (b) tác vụ đối chiếu định kỳ mỗi 5 phút để bắt sự kiện bị lỡ …
    Thì hệ thống trả `202`, `{buildId, snapshotVersion (khi xong), state: BUILT}`; ảnh chụp ở trạng thái `BUILT`
    Và có EN-03-09 `BUILT`; chưa có thay đổi nào ở gateway
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-03-039 @FR-03-039 @M @âm
  Kịch bản: US-03-039 âm 1 · Phân hệ nguồn không trả dữ liệu
    Biết các phân hệ nguồn trả được dữ liệu (nếu không, dùng bản đã lưu gần nhất, quá 24 giờ thì cảnh báo); mẫu chính sách đã bật cho tenant (FR-03-048)
    Khi phân hệ nguồn không trả dữ liệu
    Thì dùng bản chiếu gần nhất, ghi chỉ số `dh_gateway_source_stale_seconds{source}`, cảnh báo khi quá 24 giờ; không dừng tổng hợp các tenant khác

  @US-03-039 @FR-03-039 @M @âm
  Kịch bản: US-03-039 âm 2 · Hai người cùng bấm tổng hợp
    Biết các phân hệ nguồn trả được dữ liệu (nếu không, dùng bản đã lưu gần nhất, quá 24 giờ thì cảnh báo); mẫu chính sách đã bật cho tenant (FR-03-048)
    Khi hai người cùng bấm tổng hợp
    Thì hệ thống từ chối với ERR-03-006 (409)
    Và người dùng thấy thông báo "Đang có một lần tổng hợp cấu hình cho tỉnh này. Chờ lần đó hoàn tất."

  @US-03-040 @FR-03-040 @M
  Kịch bản: US-03-040 dương · Kiểm tra hợp lệ cấu hình trước khi phát
    Biết có ảnh chụp `BUILT` (FR-03-039), hoặc người dùng gửi cấu hình thử
    Khi ngay sau khi tổng hợp xong; hoặc người dùng gọi API-03-058 (chạy thử, không ghi)
    Thì hệ thống trả `200` (chạy thử) với `{valid, errors[], warnings[]}`; hoặc ảnh chụp `REJECTED` kèm danh sách lỗi
    Và ảnh chụp có kết quả kiểm tra; không đổi gateway
    Và sự kiện được phát: EVT-03-12 (ảnh chụp bị từ chối)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-03-040 @FR-03-040 @M @âm
  Kịch bản: US-03-040 âm 1 · Cấu hình không hợp lệ
    Biết có ảnh chụp `BUILT` (FR-03-039), hoặc người dùng gửi cấu hình thử
    Khi cấu hình không hợp lệ
    Thì hệ thống từ chối với ERR-03-005 (422)
    Và người dùng thấy thông báo "Cấu hình gateway không hợp lệ: {n} lỗi. Xem danh sách bên dưới."

  @US-03-040 @FR-03-040 @M @âm
  Kịch bản: US-03-040 âm 2 · Route thiếu lược đồ OpenAPI hoặc chính sách OPA
    Biết có ảnh chụp `BUILT` (FR-03-039), hoặc người dùng gửi cấu hình thử
    Khi route thiếu lược đồ OpenAPI hoặc chính sách OPA
    Thì hệ thống từ chối với ERR-03-012 (422)
    Và người dùng thấy thông báo "Route {mã} thiếu lược đồ OpenAPI đã duyệt hoặc chính sách ủy quyền nên chưa được phát."

  @US-03-041 @FR-03-041 @M
  Kịch bản: US-03-041 dương · Sinh ảnh chụp cấu hình có phiên bản và chữ ký
    Biết ảnh chụp đã qua kiểm tra hợp lệ (FR-03-040); khóa ký `transit/keys/dh-gateway-snapshot` ở OpenBao khả dụng
    Khi sau khi kiểm tra hợp lệ đạt
    Thì ảnh chụp `SIGNED` với `snapshotVersion`, `contentHash`, `signature`
    Và EN-03-09 `SIGNED`; bộ đếm phiên bản tăng
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-03-041 @FR-03-041 @M @âm
  Kịch bản: US-03-041 âm 1 · OpenBao hoặc dịch vụ ký không khả dụng
    Biết ảnh chụp đã qua kiểm tra hợp lệ (FR-03-040); khóa ký `transit/keys/dh-gateway-snapshot` ở OpenBao khả dụng
    Khi OpenBao hoặc dịch vụ ký không khả dụng
    Thì hệ thống từ chối với ERR-03-015 (503)
    Và người dùng thấy thông báo "Dịch vụ ký cấu hình tạm thời không khả dụng. Thử lại sau; cấu hình đang chạy không đổi."

  @US-03-041 @FR-03-041 @M @âm
  Kịch bản: US-03-041 âm 2 · Đang có lần ký khác của cùng site
    Biết ảnh chụp đã qua kiểm tra hợp lệ (FR-03-040); khóa ký `transit/keys/dh-gateway-snapshot` ở OpenBao khả dụng
    Khi đang có lần ký khác của cùng site
    Thì hệ thống từ chối với ERR-03-006 (409)

  @US-03-042 @FR-03-042 @M
  Kịch bản: US-03-042 dương · Phát ảnh chụp tới Git và bucket
    Biết ảnh chụp `SIGNED`; bucket và kho Git cấu hình truy cập được
    Khi ngay sau khi ký, hoặc người dùng bấm "Phát" cho một ảnh chụp đã ký
    Thì hệ thống trả `202` (bất đồng bộ), ảnh chụp `PUBLISHED` với `publishedAt`, `paths`
    Và ảnh chụp ở bucket và Git; con trỏ `current` đã chuyển
    Và sự kiện được phát: EVT-03-01
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-03-042 @FR-03-042 @M @âm
  Kịch bản: US-03-042 âm 1 · Cả bucket và Git đều không ghi được
    Biết ảnh chụp `SIGNED`; bucket và kho Git cấu hình truy cập được
    Khi cả bucket và Git đều không ghi được
    Thì hệ thống từ chối với ERR-03-014 (502)
    Và người dùng thấy thông báo "Không ghi được cấu hình tới nơi lưu. Cấu hình đang chạy không đổi; hệ thống sẽ thử lại."

  @US-03-042 @FR-03-042 @M @âm
  Kịch bản: US-03-042 âm 2 · Ảnh chụp mới hơn đã được phát trước (phát chen)
    Biết ảnh chụp `SIGNED`; bucket và kho Git cấu hình truy cập được
    Khi ảnh chụp mới hơn đã được phát trước (phát chen)
    Thì hệ thống từ chối với ERR-03-006 (409)

  @US-03-043 @FR-03-043 @M
  Kịch bản: US-03-043 dương · Nạp ảnh chụp ở nút gateway
    Biết bộ đồng bộ có khóa công khai của khóa ký (ConfigMap); có quyền đọc bucket và Secret chứng thư
    Khi con trỏ `current` ở bucket đổi (kiểm tra mỗi `gw.sync.pollSeconds` = 5 giây); hoặc ConfigMap đổi; hoặc pod khởi động
    Thì tệp `apisix.yaml` mới đang chạy; chỉ số phiên bản và kết quả
    Và nút chạy đúng một ảnh chụp; ảnh chụp cũ còn ở bộ nhớ để hoàn tất yêu cầu đang xử lý
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-03-043 @FR-03-043 @M @âm
  Kịch bản: US-03-043 âm 1 · Chữ ký sai hoặc hash sai
    Biết bộ đồng bộ có khóa công khai của khóa ký (ConfigMap); có quyền đọc bucket và Secret chứng thư
    Khi chữ ký sai hoặc hash sai
    Thì nút từ chối, giữ bản đang chạy, cảnh báo Nghiêm trọng thông báo ở FR-03-054
    Và người dùng thấy thông báo "nghi cấu hình giả mạo"

  @US-03-043 @FR-03-043 @M @âm
  Kịch bản: US-03-043 âm 2 · Cấu hình không qua bộ kiểm tra của APISIX
    Biết bộ đồng bộ có khóa công khai của khóa ký (ConfigMap); có quyền đọc bucket và Secret chứng thư
    Khi cấu hình không qua bộ kiểm tra của APISIX
    Thì nút từ chối, giữ bản cũ, cảnh báo Cao; `dh-connect` thấy nút `FAILED` ở FR-03-045

  @US-03-044 @FR-03-044 @M
  Kịch bản: US-03-044 dương · Quay lui về phiên bản cấu hình trước
    Biết có ít nhất một phiên bản trước đã `APPLIED` còn trong bucket hoặc Git
    Khi người vận hành chọn một phiên bản cũ ở UI-03-10 và bấm "Quay lui"
    Thì hệ thống trả `202`, `{newSnapshotVersion, restoredFrom, holdUntil}`
    Và gateway chạy nội dung phiên bản đích dưới số phiên bản mới; tenant ở trạng thái giữ
    Và sự kiện được phát: EVT-03-02; EVT-03-01
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-03-044 @FR-03-044 @M @âm
  Kịch bản: US-03-044 âm 1 · Phiên bản đích tham chiếu đối tượng đã bị xóa hoặc chứng thư hết hạn
    Biết có ít nhất một phiên bản trước đã `APPLIED` còn trong bucket hoặc Git
    Khi phiên bản đích tham chiếu đối tượng đã bị xóa hoặc chứng thư hết hạn
    Thì hệ thống từ chối với ERR-03-007 (422)
    Và người dùng thấy thông báo "Không thể quay lui về phiên bản {v}: {đối tượng} không còn hợp lệ."

  @US-03-044 @FR-03-044 @M @âm
  Kịch bản: US-03-044 âm 2 · Có lần phát đang chạy
    Biết có ít nhất một phiên bản trước đã `APPLIED` còn trong bucket hoặc Git
    Khi có lần phát đang chạy
    Thì hệ thống từ chối với ERR-03-006 (409)
    Và người dùng thấy thông báo "Đang có lần phát cấu hình khác. Chờ lần đó hoàn tất."

  @US-03-045 @FR-03-045 @M
  Kịch bản: US-03-045 dương · Theo dõi nút và trạng thái đồng bộ
    Biết các nút phát chỉ số Prometheus; PH-13 thu thập và truy vấn được
    Khi người dùng mở UI-03-11; hoặc tác vụ đánh giá trạng thái mỗi 30 giây
    Thì hệ thống trả `200`, danh sách nút `{nodeId, gate, site, runningVersion, desiredVersion, syncState, lastApplyResult, lagSeconds, …}` và tóm tắt `{inSync, lagging, failed, unknown}`

  @US-03-045 @FR-03-045 @M @âm
  Kịch bản: US-03-045 âm 1 · Không đọc được số liệu từ PH-13
    Biết các nút phát chỉ số Prometheus; PH-13 thu thập và truy vấn được
    Khi không đọc được số liệu từ PH-13
    Thì hệ thống từ chối với ERR-03-026 (503)
    Và người dùng thấy thông báo "Chưa lấy được số liệu nút gateway từ hệ thống giám sát. Thử lại sau."

  @US-03-045 @FR-03-045 @M @âm
  Kịch bản: US-03-045 âm 2 · Nút không tồn tại
    Biết các nút phát chỉ số Prometheus; PH-13 thu thập và truy vấn được
    Khi nút không tồn tại
    Thì hệ thống từ chối với ERR-03-001 (404)

  @US-03-046 @FR-03-046 @M
  Kịch bản: US-03-046 dương · Đồng bộ consumer và thông tin xác thực công khai
    Biết HTTT ở PH-01 đang kết nạp hoặc `ACTIVE`; client tương ứng đã (hoặc sắp) được PH-12 tạo ở Keycloak
    Khi bước "tạo consumer" của saga kết nạp; hoặc PH-01 đổi trạng thái HTTT; hoặc xoay chứng thư, khóa của client
    Thì hệ thống trả `202` với `{consumerCode, state, snapshotVersion?, effectiveBy}`; `Location`, `ETag`
    Và EN-03-03, EN-03-04 mới hoặc đổi; ảnh chụp mới có consumer
    Và sự kiện được phát: EVT-03-04
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-03-046 @FR-03-046 @M @âm
  Kịch bản: US-03-046 âm 1 · Mã consumer đã thuộc HTTT khác
    Biết HTTT ở PH-01 đang kết nạp hoặc `ACTIVE`; client tương ứng đã (hoặc sắp) được PH-12 tạo ở Keycloak
    Khi mã consumer đã thuộc HTTT khác
    Thì hệ thống từ chối với ERR-03-002 (409)
    Và người dùng thấy thông báo "Mã {mã} đã được dùng cho HTTT khác."

  @US-03-046 @FR-03-046 @M @âm
  Kịch bản: US-03-046 âm 2 · Dữ liệu có trường bí mật hoặc sai dạng
    Biết HTTT ở PH-01 đang kết nạp hoặc `ACTIVE`; client tương ứng đã (hoặc sắp) được PH-12 tạo ở Keycloak
    Khi dữ liệu có trường bí mật hoặc sai dạng
    Thì hệ thống từ chối với ERR-03-003 (400)
    Và người dùng thấy thông báo "Không gửi bí mật tới gateway. Chỉ gửi vân tay chứng thư hoặc băm khóa."

  @US-03-047 @FR-03-047 @M
  Kịch bản: US-03-047 dương · Tạm ngừng khẩn cấp route hoặc consumer
    Biết đối tượng tồn tại ở tenant; người thực hiện có quyền
    Khi người vận hành bấm "Tạm ngừng khẩn cấp" ở UI-03-02 hoặc UI-03-05
    Thì hệ thống trả `202`, `{blockId, targetType, targetCode, effectiveBy}`
    Và EN-03-12 `ACTIVE`; đối tượng ở trạng thái `SUSPENDED` trong ảnh chụp
    Và sự kiện được phát: EVT-03-03 (route), EVT-03-04 (consumer); EVT-03-09
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-03-047 @FR-03-047 @M @âm
  Kịch bản: US-03-047 âm 1 · Đối tượng đã tạm ngừng
    Biết đối tượng tồn tại ở tenant; người thực hiện có quyền
    Khi đối tượng đã tạm ngừng
    Thì hệ thống từ chối với ERR-03-019 (409)
    Và người dùng thấy thông báo "{Route/HTTT} {mã} đã đang bị tạm ngừng khẩn cấp từ {thời điểm}."

  @US-03-047 @FR-03-047 @M @âm
  Kịch bản: US-03-047 âm 2 · Không tìm thấy hoặc thuộc tenant khác
    Biết đối tượng tồn tại ở tenant; người thực hiện có quyền
    Khi không tìm thấy hoặc thuộc tenant khác
    Thì hệ thống từ chối với ERR-03-001 (404)

  @US-03-048 @FR-03-048 @M
  Kịch bản: US-03-048 dương · Bộ mẫu chính sách gateway được duyệt sẵn
    Biết bản phát hành nền tảng mang danh mục mẫu đã ký; mỗi mẫu có phiên bản
    Khi TA mở UI-03-13; hoặc PH-02 gán mẫu cho gói khi soạn API
    Thì hệ thống trả `200`, danh sách mẫu `{templateCode, version, plugins[], enabled, params[]}`
    Và trạng thái bật, tắt mẫu của tenant được lưu
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-03-048 @FR-03-048 @M @âm
  Kịch bản: US-03-048 âm 1 · Mẫu hoặc plugin ngoài danh mục
    Biết bản phát hành nền tảng mang danh mục mẫu đã ký; mỗi mẫu có phiên bản
    Khi mẫu hoặc plugin ngoài danh mục
    Thì hệ thống từ chối với ERR-03-013 (422)
    Và người dùng thấy thông báo "Mẫu chính sách hoặc plugin {tên} không có trong danh mục được duyệt."

  @US-03-048 @FR-03-048 @M @âm
  Kịch bản: US-03-048 âm 2 · Tham số ngoài miền cho phép
    Biết bản phát hành nền tảng mang danh mục mẫu đã ký; mỗi mẫu có phiên bản
    Khi tham số ngoài miền cho phép
    Thì hệ thống từ chối với ERR-03-003 (400)
    Và người dùng thấy thông báo "Tham số {tên} nằm ngoài miền cho phép của mẫu {mã}."

  @US-03-049 @FR-03-049 @M
  Kịch bản: US-03-049 dương · Quản lý chứng thư biên
    Biết cert-manager và nhà phát hành (OpenBao PKI cho host nội bộ; ACME hoặc CA do tỉnh cung cấp cho host Internet, theo hồ sơ triển khai) đã cấu hình; External Secrets đồng bộ Secret từ OpenBao
    Khi tác vụ định kỳ mỗi giờ quét chứng thư; chứng thư còn dưới `gw.cert.renewDays` (30) ngày; hoặc người dùng bấm "Gia hạn ngay"
    Thì hệ thống trả `200`, danh sách chứng thư `{certCode, subject, hosts[], notAfter, issuer, state}`; `202` khi gia hạn
    Và chứng thư mới ở Secret và nút; khóa riêng chỉ ở OpenBao
    Và sự kiện được phát: EVT-03-08
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-03-049 @FR-03-049 @M @âm
  Kịch bản: US-03-049 âm 1 · Chứng thư nhập sai chuỗi, hết hạn hoặc không khớp khóa
    Biết cert-manager và nhà phát hành (OpenBao PKI cho host nội bộ; ACME hoặc CA do tỉnh cung cấp cho host Internet, theo hồ sơ triển khai) đã cấu hình; External Secrets đồng bộ Secret từ OpenBao
    Khi chứng thư nhập sai chuỗi, hết hạn hoặc không khớp khóa
    Thì hệ thống từ chối với ERR-03-016 (422)
    Và người dùng thấy thông báo "Chứng thư không hợp lệ: {lý do}."

  @US-03-049 @FR-03-049 @M @âm
  Kịch bản: US-03-049 âm 2 · OpenBao hoặc nhà phát hành không khả dụng khi gia hạn
    Biết cert-manager và nhà phát hành (OpenBao PKI cho host nội bộ; ACME hoặc CA do tỉnh cung cấp cho host Internet, theo hồ sơ triển khai) đã cấu hình; External Secrets đồng bộ Secret từ OpenBao
    Khi OpenBao hoặc nhà phát hành không khả dụng khi gia hạn
    Thì hệ thống từ chối với ERR-03-015 (503)
    Và người dùng thấy thông báo "Dịch vụ cấp chứng thư tạm thời không khả dụng. Hệ thống sẽ thử lại; chứng thư hiện tại còn hiệu lực đến {ngày}."

  # ---- EP-03-F · Quan sát và nhật ký lượt gọi

  @US-03-050 @FR-03-050 @M
  Kịch bản: US-03-050 dương · Ghi siêu dữ liệu lượt gọi có che dữ liệu
    Biết plugin ghi nhật ký của APISIX bật ở mọi route; đường tới PH-13 (OTel Collector hoặc Kafka) truy cập được
    Khi sau mỗi lượt gọi, kể cả lượt bị từ chối ở bất kỳ chốt nào
    Thì bản ghi siêu dữ liệu ở PH-13; chỉ số `dh_gateway_accesslog_sent_total`
    Và bản ghi nằm ở kho của PH-13 theo thời hạn lưu của NFR-03-026

  @US-03-050 @FR-03-050 @M @âm
  Kịch bản: US-03-050 âm 1 · Bộ đệm đĩa đầy do PH-13 ngừng lâu
    Biết plugin ghi nhật ký của APISIX bật ở mọi route; đường tới PH-13 (OTel Collector hoặc Kafka) truy cập được
    Khi bộ đệm đĩa đầy do PH-13 ngừng lâu
    Thì bỏ bản ghi cũ nhất, cảnh báo Cao ở FR-03-054; không ảnh hưởng lượt gọi

  @US-03-050 @FR-03-050 @M @âm
  Kịch bản: US-03-050 âm 2 · Bản ghi chứa giá trị khớp mẫu dữ liệu nhạy cảm sau bước 4
    Biết plugin ghi nhật ký của APISIX bật ở mọi route; đường tới PH-13 (OTel Collector hoặc Kafka) truy cập được
    Khi bản ghi chứa giá trị khớp mẫu dữ liệu nhạy cảm sau bước 4
    Thì bộ quét mẫu của CI và kiểm thử chạy hằng ngày báo lỗi (NFR-03-014); không có ca ngoại lệ được chấp nhận

  @US-03-051 @FR-03-051 @M
  Kịch bản: US-03-051 dương · Tra cứu và xuất nhật ký lượt gọi
    Biết siêu dữ liệu đã có ở PH-13 (FR-03-050); người dùng đã chọn tenant (FR-00-004)
    Khi người dùng mở UI-03-09 hoặc tab "Nhật ký" ở UI-03-05; hoặc dán `traceId` vào ô tìm
    Thì hệ thống trả `200`, `items[]`, `page`, `size`, `totalElements`; `202` khi xuất, kèm `exportId` và đường tải khi xong
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-03-051 @FR-03-051 @M @âm
  Kịch bản: US-03-051 âm 1 · Khoảng thời gian quá rộng
    Biết siêu dữ liệu đã có ở PH-13 (FR-03-050); người dùng đã chọn tenant (FR-00-004)
    Khi khoảng thời gian quá rộng
    Thì hệ thống từ chối với ERR-03-021 (400)
    Và người dùng thấy thông báo "Chỉ tra cứu tối đa 31 ngày mỗi lần và trong vòng 12 tháng gần nhất."

  @US-03-051 @FR-03-051 @M @âm
  Kịch bản: US-03-051 âm 2 · Kho của PH-13 không khả dụng
    Biết siêu dữ liệu đã có ở PH-13 (FR-03-050); người dùng đã chọn tenant (FR-00-004)
    Khi kho của PH-13 không khả dụng
    Thì hệ thống từ chối với ERR-03-026 (503)
    Và người dùng thấy thông báo "Chưa truy vấn được nhật ký lượt gọi. Thử lại sau."

  @US-03-052 @FR-03-052 @M
  Kịch bản: US-03-052 dương · Phát chỉ số và vết OpenTelemetry
    Biết cổng quản lý (management port) của APISIX mở chỉ cho Prometheus của PH-13 (chính sách mạng, SEC-14); plugin `prometheus` và `opentelemetry` bật
    Khi Prometheus của PH-13 lấy mẫu mỗi 15 giây; mỗi lượt gọi phát span
    Thì chỉ số Prometheus; span OTLP; nhật ký JSON

  @US-03-052 @FR-03-052 @M @âm
  Kịch bản: US-03-052 âm 1 · Collector hoặc Prometheus không khả dụng
    Biết cổng quản lý (management port) của APISIX mở chỉ cho Prometheus của PH-13 (chính sách mạng, SEC-14); plugin `prometheus` và `opentelemetry` bật
    Khi collector hoặc Prometheus không khả dụng
    Thì gateway đệm vết cục bộ có giới hạn và bỏ điểm cũ nhất khi đầy; chỉ số là kéo (pull) nên không mất khi Prometheus quay lại, chỉ thiếu điểm lấy mẫu

  @US-03-052 @FR-03-052 @M @âm
  Kịch bản: US-03-052 âm 2 · Số chuỗi chỉ số vượt trần
    Biết cổng quản lý (management port) của APISIX mở chỉ cho Prometheus của PH-13 (chính sách mạng, SEC-14); plugin `prometheus` và `opentelemetry` bật
    Khi số chuỗi chỉ số vượt trần
    Thì nhãn `consumer` gộp `other`, cảnh báo Trung bình

  @US-03-053 @FR-03-053 @S
  Kịch bản: US-03-053 dương · Kiểm tra tổng hợp cho API quan trọng
    Biết API được PH-02 đánh dấu `critical`; có consumer kiểm tra `dh-synthetic-{tenant}` với phạm vi chỉ-đọc và gói riêng (hạn mức tách khỏi HTTT thật); bộ chạy kiểm tra (hồ sơ `probe` của `dh-runtime`) chạy ở data plane
    Khi bộ lập lịch của bộ chạy kiểm tra, mỗi 60 giây cho mỗi kiểm tra
    Thì chỉ số kết quả kiểm tra; `200` cho danh sách kiểm tra `{checkCode, state, lastOkAt, lastFailAt, p95Ms}`
    Và có lịch kiểm tra; không đổi dữ liệu nghiệp vụ
    Và sự kiện được phát: EVT-03-09 khi kiểm tra thất bại liên tiếp
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-03-053 @FR-03-053 @S @âm
  Kịch bản: US-03-053 âm 1 · Thiếu consumer kiểm tra hoặc gói
    Biết API được PH-02 đánh dấu `critical`; có consumer kiểm tra `dh-synthetic-{tenant}` với phạm vi chỉ-đọc và gói riêng (hạn mức tách khỏi HTTT thật); bộ chạy kiểm tra (hồ sơ `probe` của `dh-runtime`) chạy ở data plane
    Khi thiếu consumer kiểm tra hoặc gói
    Thì hệ thống từ chối với ERR-03-001 (404)
    Và người dùng thấy thông báo "Chưa có consumer kiểm tra cho tỉnh. Tạo consumer kiểm tra trước."

  @US-03-054 @FR-03-054 @M
  Kịch bản: US-03-054 dương · Cảnh báo sự kiện an ninh tại gateway
    Biết chỉ số và sự kiện an ninh của gateway đã về PH-13 (FR-03-050, 052); luật cảnh báo cài ở PH-13
    Khi luật cảnh báo của PH-13 khớp theo bảng "Luật cảnh báo của gateway" dưới đây
    Thì hệ thống trả `200`, danh sách cảnh báo `{alertId, severity, type, target, evidence, since, state}`; `200` khi xác nhận
    Và bản ghi cảnh báo ở PH-13
    Và sự kiện được phát: EVT-03-09
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-03-054 @FR-03-054 @M @âm
  Kịch bản: US-03-054 âm 1 · PH-13 không khả dụng
    Biết chỉ số và sự kiện an ninh của gateway đã về PH-13 (FR-03-050, 052); luật cảnh báo cài ở PH-13
    Khi PH-13 không khả dụng
    Thì hệ thống từ chối với ERR-03-026
    Và người dùng thấy thông báo "chưa có số liệu cảnh báo"

  @US-03-054 @FR-03-054 @M @âm
  Kịch bản: US-03-054 âm 2 · Cảnh báo trùng quá nhiều
    Biết chỉ số và sự kiện an ninh của gateway đã về PH-13 (FR-03-050, 052); luật cảnh báo cài ở PH-13
    Khi cảnh báo trùng quá nhiều
    Thì gộp theo loại và đối tượng, không gửi lặp

  @US-03-055 @FR-03-055 @M
  Kịch bản: US-03-055 dương · Bảng điều khiển lưu lượng gateway
    Biết chỉ số và siêu dữ liệu đã về PH-13; người dùng đã chọn tenant
    Khi người dùng mở UI-03-01
    Thì hệ thống trả `200`, `{cards, series, topConsumers, topRoutes, alerts, nodes}`

  @US-03-055 @FR-03-055 @M @âm
  Kịch bản: US-03-055 âm 1 · PH-13 không khả dụng
    Biết chỉ số và siêu dữ liệu đã về PH-13; người dùng đã chọn tenant
    Khi PH-13 không khả dụng
    Thì hệ thống từ chối với ERR-03-026 (503)
    Và người dùng thấy thông báo "Chưa lấy được số liệu lưu lượng. Thử lại sau."

  @US-03-055 @FR-03-055 @M @âm
  Kịch bản: US-03-055 âm 2 · Khoảng thời gian không hợp lệ
    Biết chỉ số và siêu dữ liệu đã về PH-13; người dùng đã chọn tenant
    Khi khoảng thời gian không hợp lệ
    Thì hệ thống từ chối với ERR-03-003 (400)

  # ---- EP-03-G · Quản trị

  @US-03-056 @FR-03-056 @M
  Kịch bản: US-03-056 dương · Tham số gateway theo tenant
    Biết có bảng tham số mặc định ở chương 8.2; tenant đang `ACTIVE`
    Khi quản trị mở UI-03-16 và bấm "Lưu"
    Thì hệ thống trả `200`, bộ tham số hiệu lực kèm `ETag`
    Và tham số mới trong ảnh chụp đang chạy
    Và sự kiện được phát: EVT-03-11 khi đổi tham số hạn mức; còn lại đi theo EVT-03-01
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-03-056 @FR-03-056 @M @âm
  Kịch bản: US-03-056 âm 1 · Giá trị sai kiểu hoặc ngoài miền
    Biết có bảng tham số mặc định ở chương 8.2; tenant đang `ACTIVE`
    Khi giá trị sai kiểu hoặc ngoài miền
    Thì hệ thống từ chối với ERR-03-003 (400)
    Và người dùng thấy thông báo "Giá trị của {khóa} phải thuộc {miền}."

  @US-03-056 @FR-03-056 @M @âm
  Kịch bản: US-03-056 âm 2 · Vượt trần nền tảng
    Biết có bảng tham số mặc định ở chương 8.2; tenant đang `ACTIVE`
    Khi vượt trần nền tảng
    Thì hệ thống từ chối với ERR-03-018 (422)
    Và người dùng thấy thông báo "{khóa} không được vượt {trần} theo hợp đồng của tỉnh."

  @US-03-057 @FR-03-057 @S
  Kịch bản: US-03-057 dương · Chạy thử chính sách bằng mô phỏng
    Biết có ảnh chụp đang chạy hoặc ảnh chụp `BUILT` để mô phỏng; gói chính sách OPA hiện hành
    Khi quản trị mở UI-03-14 và bấm "Chạy thử"
    Thì hệ thống trả `200`, `{matchedRoute, steps[], expectedStatus, effectivePolicies}`
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-03-057 @FR-03-057 @S @âm
  Kịch bản: US-03-057 âm 1 · Đầu vào có token hoặc khóa thật
    Biết có ảnh chụp đang chạy hoặc ảnh chụp `BUILT` để mô phỏng; gói chính sách OPA hiện hành
    Khi đầu vào có token hoặc khóa thật
    Thì hệ thống từ chối với ERR-03-003 (400)
    Và người dùng thấy thông báo "Không nhập token hoặc khóa thật. Chỉ nhập phạm vi (scope) và thông tin giả định."

  @US-03-058 @FR-03-058 @S
  Kịch bản: US-03-058 dương · Báo cáo sử dụng API theo HTTT và gói
    Biết bản tổng hợp theo ngày của siêu dữ liệu lượt gọi có ở PH-13
    Khi người dùng mở báo cáo ở UI-03-01 (tab "Báo cáo sử dụng") và chọn kỳ
    Thì hệ thống trả `200`, `items[]` theo nhóm, `totals`; `202` khi xuất kèm `exportId`
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-03-058 @FR-03-058 @S @âm
  Kịch bản: US-03-058 âm 1 · Khoảng thời gian quá 12 tháng
    Biết bản tổng hợp theo ngày của siêu dữ liệu lượt gọi có ở PH-13
    Khi khoảng thời gian quá 12 tháng
    Thì hệ thống từ chối với ERR-03-021 (400)
    Và người dùng thấy thông báo "Báo cáo chỉ gồm 12 tháng gần nhất."

  @US-03-059 @FR-03-059 @S
  Kịch bản: US-03-059 dương · Nhập cấu hình từ gateway cũ
    Biết có gói xuất cấu hình của hệ cũ (JSON) hoặc quyền đọc chỉ-đọc cấu hình gateway cũ qua cầu nối chuyển đổi; tenant đang ở giai đoạn chuyển đổi
    Khi quản trị tải gói ở UI-03-18 và bấm "Phân tích"
    Thì hệ thống trả `201`, `{importId, state, summary}`; báo cáo phân tích; sau áp dụng, danh sách đề xuất đã gửi
    Và bản ghi nhập và `legacyMap`; không đổi cấu hình gateway đang chạy
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-03-059 @FR-03-059 @S @âm
  Kịch bản: US-03-059 âm 1 · Gói không đọc được hoặc thiếu trường bắt buộc
    Biết có gói xuất cấu hình của hệ cũ (JSON) hoặc quyền đọc chỉ-đọc cấu hình gateway cũ qua cầu nối chuyển đổi; tenant đang ở giai đoạn chuyển đổi
    Khi gói không đọc được hoặc thiếu trường bắt buộc
    Thì hệ thống từ chối với ERR-03-020 (422)
    Và người dùng thấy thông báo "Gói cấu hình hệ cũ không đọc được: {lý do}."
