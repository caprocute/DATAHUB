# language: vi
# Sinh tự động từ D02-02/D02-03-PH17 bằng backlog/tools/sinh_backlog.py; không sửa tay.
@PH-17
Tính năng: PH-17 · Trợ lý AI và quản trị AI

  # ---- EP-17-A · Bật tắt và chính sách AI theo tenant

  @US-17-001 @FR-17-001 @M
  Kịch bản: US-17-001 dương · Bật, tắt trợ lý cho tenant có quyết định và kiểm toán
    Biết có ít nhất một phiên bản mô hình hội thoại và một phiên bản mô hình nhúng `APPROVED` cho tenant (FR-17-009, 010); điều khoản dùng AI có phiên bản công bố (FR-17-005)
    Khi TA bấm "Đề nghị bật trợ lý" ở UI-17-06 tab Cấu hình; người xác nhận mở việc trong "Việc của tôi"
    Thì hệ thống trả `201` với `PolicyChange` (`changeId`, `state`); duyệt: `200`, kèm `TenantPolicy` mới và `ETag`
    Và `TenantPolicy.state = ENABLED`; chưa có chỉ mục nào cho tới khi khai báo nguồn tri thức (FR-17-015); tắt thì dữ liệu cũ giữ nguyên
    Và sự kiện được phát: EVT-17-04, EVT-17-02, EVT-17-01
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-17-001 @FR-17-001 @M @âm
  Kịch bản: US-17-001 âm 1 · Thiếu số quyết định hoặc lý do
    Biết có ít nhất một phiên bản mô hình hội thoại và một phiên bản mô hình nhúng `APPROVED` cho tenant (FR-17-009, 010); điều khoản dùng AI có phiên bản công bố (FR-17-005)
    Khi thiếu số quyết định hoặc lý do
    Thì hệ thống từ chối với ERR-17-014 (422)
    Và người dùng thấy thông báo "Bật trợ lý cần số quyết định của lãnh đạo tỉnh và lý do."

  @US-17-001 @FR-17-001 @M @âm
  Kịch bản: US-17-001 âm 2 · Người duyệt trùng người đề nghị
    Biết có ít nhất một phiên bản mô hình hội thoại và một phiên bản mô hình nhúng `APPROVED` cho tenant (FR-17-009, 010); điều khoản dùng AI có phiên bản công bố (FR-17-005)
    Khi người duyệt trùng người đề nghị
    Thì hệ thống từ chối với ERR-17-005 (403)
    Và người dùng thấy thông báo "Bạn là người đề nghị hoặc đã quyết định ở bước trước nên không được duyệt bước này."

  @US-17-002 @FR-17-002 @M
  Kịch bản: US-17-002 dương · Bật, tắt từng năng lực và theo nhóm vai trò
    Biết trợ lý ở trạng thái `ENABLED` (FR-17-001)
    Khi TA đổi công tắc ở UI-17-06 tab Cấu hình, mục "Năng lực và vai trò"
    Thì hệ thống trả `200`; chính sách năng lực hiện hành, `ETag`
    Và `CapabilityPolicy` mới có hiệu lực ≤ 60 giây
    Và sự kiện được phát: EVT-17-01
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-17-002 @FR-17-002 @M @âm
  Kịch bản: US-17-002 âm 1 · Người dùng gọi năng lực chưa bật cho vai trò
    Biết trợ lý ở trạng thái `ENABLED` (FR-17-001)
    Khi người dùng gọi năng lực chưa bật cho vai trò
    Thì hệ thống từ chối với ERR-17-011 (403)
    Và người dùng thấy thông báo "Năng lực {tên} chưa được bật cho vai trò của bạn."

  @US-17-002 @FR-17-002 @M @âm
  Kịch bản: US-17-002 âm 2 · Không chọn năng lực hoặc nhóm
    Biết trợ lý ở trạng thái `ENABLED` (FR-17-001)
    Khi không chọn năng lực hoặc nhóm
    Thì hệ thống từ chối với ERR-17-015 (422)
    Và người dùng thấy thông báo "Chọn ít nhất một năng lực và một nhóm vai trò."

  @US-17-003 @FR-17-003 @M
  Kịch bản: US-17-003 dương · Chính sách dùng mô hình ngoài
    Biết có nhà cung cấp `EXTERNAL` ở `ACTIVE` với cam kết còn hiệu lực (FR-17-007); trợ lý đã bật
    Khi TA mở UI-17-06 mục "Mô hình ngoài" hoặc UI-17-07, bấm "Đề nghị cho phép mô hình ngoài"
    Thì hệ thống trả `201` đề nghị; duyệt `200` kèm danh sách trắng hiện hành
    Và có hoặc không có đường gọi mô hình ngoài, đúng bằng trạng thái đã duyệt; không có đường nào khác
    Và sự kiện được phát: EVT-17-04, EVT-17-01, EVT-17-08
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-17-003 @FR-17-003 @M @âm
  Kịch bản: US-17-003 âm 1 · Nhà cung cấp chưa có cam kết hợp lệ
    Biết có nhà cung cấp `EXTERNAL` ở `ACTIVE` với cam kết còn hiệu lực (FR-17-007); trợ lý đã bật
    Khi nhà cung cấp chưa có cam kết hợp lệ
    Thì hệ thống từ chối với ERR-17-016 (422)
    Và người dùng thấy thông báo "Mô hình ngoài chỉ dùng được khi nhà cung cấp có cam kết lưu dữ liệu trong nước và không huấn luyện còn hiệu lực."

  @US-17-003 @FR-17-003 @M @âm
  Kịch bản: US-17-003 âm 2 · Dùng nhà cung cấp chưa trong danh sách trắng
    Biết có nhà cung cấp `EXTERNAL` ở `ACTIVE` với cam kết còn hiệu lực (FR-17-007); trợ lý đã bật
    Khi dùng nhà cung cấp chưa trong danh sách trắng
    Thì hệ thống từ chối với ERR-17-017 (409)
    Và người dùng thấy thông báo "Nhà cung cấp {tên} chưa nằm trong danh sách trắng của tỉnh."

  @US-17-004 @FR-17-004 @M
  Kịch bản: US-17-004 dương · Hạn mức theo người dùng và tenant, độ dài đầu vào và đầu ra
    Biết trợ lý bật; tham số `17.quota.*`, `17.input.max-chars`, `17.output.max-tokens` có giá trị hoặc dùng mặc định
    Khi TA lưu hạn mức ở UI-17-06; hoặc mỗi lượt hỏi của người dùng kích hoạt kiểm tra
    Thì hệ thống trả `200`; hạn mức hiện hành
    Và `QuotaUsage` đúng với lượt và token thực dùng; đặt lại lúc 00:00 giờ Việt Nam
    Và sự kiện được phát: EVT-17-01; EVT-17-12
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-17-004 @FR-17-004 @M @âm
  Kịch bản: US-17-004 âm 1 · Hết lượt trong ngày
    Biết trợ lý bật; tham số `17.quota.*`, `17.input.max-chars`, `17.output.max-tokens` có giá trị hoặc dùng mặc định
    Khi hết lượt trong ngày
    Thì hệ thống từ chối với ERR-17-021 (429)
    Và người dùng thấy thông báo "Bạn đã dùng hết {n} lượt hôm nay. Thử lại sau {thời điểm}."

  @US-17-004 @FR-17-004 @M @âm
  Kịch bản: US-17-004 âm 2 · Gửi quá nhanh
    Biết trợ lý bật; tham số `17.quota.*`, `17.input.max-chars`, `17.output.max-tokens` có giá trị hoặc dùng mặc định
    Khi gửi quá nhanh
    Thì hệ thống từ chối với ERR-17-023 (429)
    Và người dùng thấy thông báo "Bạn gửi quá nhanh. Thử lại sau {n} giây."

  @US-17-005 @FR-17-005 @S
  Kịch bản: US-17-005 dương · Thông báo minh bạch và điều khoản dùng AI, người dùng xác nhận
    Biết trợ lý bật và có một phiên bản điều khoản đã công bố
    Khi người dùng mở bảng bên lần đầu, hoặc khi phiên bản điều khoản đổi, hoặc quá `17.notice.reaccept-days` ngày
    Thì hệ thống trả `200` cho điều khoản hiện hành và trạng thái xác nhận; `201` khi công bố phiên bản; `204` khi xác nhận
    Và `NoticeAcceptance` được ghi; nếu có phiên bản mới thì chưa ai được coi là đã xác nhận
    Và sự kiện được phát: EVT-17-05
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-17-005 @FR-17-005 @S @âm
  Kịch bản: US-17-005 âm 1 · Chưa xác nhận mà gửi câu hỏi
    Biết trợ lý bật và có một phiên bản điều khoản đã công bố
    Khi chưa xác nhận mà gửi câu hỏi
    Thì hệ thống từ chối với ERR-17-020 (403)
    Và người dùng thấy thông báo "Bạn cần xác nhận điều khoản dùng AI trước khi sử dụng trợ lý."

  @US-17-006 @FR-17-006 @M
  Kịch bản: US-17-006 dương · Tắt khẩn cấp toàn tenant hoặc toàn nền tảng trong ≤ 60 giây
    Biết trợ lý bật (tenant) hoặc bất kỳ (nền tảng)
    Khi TA, SO bấm "Tắt khẩn cấp" ở UI-17-06; hoặc PA bấm ở UI-17-19; hoặc cảnh báo tự động ở FR-17-046 (đề xuất, người quyết định)
    Thì hệ thống trả `200` với `KillSwitchRecord` (`recordId`, `scope`, `activatedAt`); gỡ: `200` trạng thái `PENDING_RELEASE` rồi `RELEASED`
    Và sự kiện được phát: EVT-17-03; EVT-17-01; EVT-17-02
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-17-006 @FR-17-006 @M @âm
  Kịch bản: US-17-006 âm 1 · Thiếu lý do
    Biết trợ lý bật (tenant) hoặc bất kỳ (nền tảng)
    Khi thiếu lý do
    Thì hệ thống từ chối với ERR-17-007 (422)
    Và người dùng thấy thông báo "Nhập lý do tối thiểu 20 ký tự."

  @US-17-006 @FR-17-006 @M @âm
  Kịch bản: US-17-006 âm 2 · Người gỡ trùng người kích hoạt
    Biết trợ lý bật (tenant) hoặc bất kỳ (nền tảng)
    Khi người gỡ trùng người kích hoạt
    Thì hệ thống từ chối với ERR-17-005 (403)
    Và người dùng thấy thông báo "Bạn là người đề nghị hoặc đã quyết định ở bước trước nên không được duyệt bước này."

  # ---- EP-17-B · Cổng mô hình và sổ mô hình

  @US-17-007 @FR-17-007 @M
  Kịch bản: US-17-007 dương · Khai báo nhà cung cấp mô hình
    Biết với `EXTERNAL`: có hồ sơ cam kết (số văn bản, tệp)
    Khi PA hoặc TA bấm "Thêm nhà cung cấp" ở UI-17-19 (nền tảng) hoặc UI-17-07 (tenant)
    Thì hệ thống trả `201`; nhà cung cấp (`providerId`, `status`), không có bí mật; `ETag`
    Và nhà cung cấp `ACTIVE` chỉ được dùng khi có mô hình đã duyệt và tuyến đã đồng bộ
    Và sự kiện được phát: EVT-17-06; EVT-17-08
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-17-007 @FR-17-007 @M @âm
  Kịch bản: US-17-007 âm 1 · Điểm cuối không hợp lệ
    Biết với `EXTERNAL`: có hồ sơ cam kết (số văn bản, tệp)
    Khi điểm cuối không hợp lệ
    Thì hệ thống từ chối với ERR-17-025 (422)
    Và người dùng thấy thông báo "Điểm cuối phải là địa chỉ HTTPS theo tên miền trong nước đã khai báo."

  @US-17-007 @FR-17-007 @M @âm
  Kịch bản: US-17-007 âm 2 · Thiếu cam kết
    Biết với `EXTERNAL`: có hồ sơ cam kết (số văn bản, tệp)
    Khi thiếu cam kết
    Thì hệ thống từ chối với ERR-17-026 (422)
    Và người dùng thấy thông báo "Thiếu hồ sơ cam kết lưu dữ liệu trong nước và không huấn luyện."

  @US-17-008 @FR-17-008 @M
  Kịch bản: US-17-008 dương · Khai báo mô hình và phiên bản
    Biết nhà cung cấp đã khai báo (FR-17-007)
    Khi người dùng bấm "Thêm mô hình" hoặc "Thêm phiên bản" ở UI-17-19, UI-17-20
    Thì hệ thống trả `201`; `modelId`, `versionId`, `status = DRAFT`
    Và `ModelVersion` ở `DRAFT`
    Và sự kiện được phát: EVT-17-07
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-17-008 @FR-17-008 @M @âm
  Kịch bản: US-17-008 âm 1 · Mã trùng
    Biết nhà cung cấp đã khai báo (FR-17-007)
    Khi mã trùng
    Thì hệ thống từ chối với ERR-17-002 (409)
    Và người dùng thấy thông báo "Mã {mã} đã được dùng. Chọn mã khác."

  @US-17-008 @FR-17-008 @M @âm
  Kịch bản: US-17-008 âm 2 · Năng lực không phù hợp loại
    Biết nhà cung cấp đã khai báo (FR-17-007)
    Khi năng lực không phù hợp loại
    Thì hệ thống từ chối với ERR-17-031 (422)
    Và người dùng thấy thông báo "Mô hình {tên} không hỗ trợ năng lực {năng lực}."

  @US-17-009 @FR-17-009 @M
  Kịch bản: US-17-009 dương · Vòng đời phiên bản mô hình, duyệt bốn mắt
    Biết phiên bản ở `DRAFT`; có bộ đánh giá và bộ ca đỏ cho các năng lực mô hình hỗ trợ (FR-17-050, 051)
    Khi người đề nghị bấm "Gửi đánh giá" ở UI-17-20; người duyệt bấm "Duyệt" hoặc "Từ chối"
    Thì hệ thống trả `200`; phiên bản với `status`, `releaseGate` (danh sách điều kiện và kết quả), `ETag`
    Và `ModelVersion.status` đổi đúng một bước hợp lệ theo sơ đồ 4.3
    Và sự kiện được phát: EVT-17-07; EVT-17-21; EVT-17-22; EVT-17-08
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-17-009 @FR-17-009 @M @âm
  Kịch bản: US-17-009 âm 1 · Chưa đạt điều kiện duyệt
    Biết phiên bản ở `DRAFT`; có bộ đánh giá và bộ ca đỏ cho các năng lực mô hình hỗ trợ (FR-17-050, 051)
    Khi chưa đạt điều kiện duyệt
    Thì hệ thống từ chối với ERR-17-029 (409)
    Và người dùng thấy thông báo "Phiên bản mô hình chưa đạt điều kiện duyệt: {điều kiện}."

  @US-17-009 @FR-17-009 @M @âm
  Kịch bản: US-17-009 âm 2 · Có ca đỏ lọt
    Biết phiên bản ở `DRAFT`; có bộ đánh giá và bộ ca đỏ cho các năng lực mô hình hỗ trợ (FR-17-050, 051)
    Khi có ca đỏ lọt
    Thì hệ thống từ chối với ERR-17-073 (409)
    Và người dùng thấy thông báo "Ca đỏ {mã} chưa bị chặn nên không phát hành được."

  @US-17-010 @FR-17-010 @M
  Kịch bản: US-17-010 dương · Định tuyến lời gọi tới mô hình theo năng lực và chính sách tenant
    Biết tenant đã bật phiên bản `APPROVED` và chọn mặc định theo loại (FR-17-009)
    Khi mỗi lượt hỏi, mỗi lần nhúng, mỗi lời gọi data plane cần mô hình
    Thì nội bộ: phiên bản chọn, tuyến, cờ `fallbackUsed`; `GET /tenant-models`: danh sách và mặc định; `PUT /tenant-models/defaults`: `200`
    Và sự kiện được phát: EVT-17-01 (khi đổi mặc định)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-17-010 @FR-17-010 @M @âm
  Kịch bản: US-17-010 âm 1 · Chưa có mô hình mặc định
    Biết tenant đã bật phiên bản `APPROVED` và chọn mặc định theo loại (FR-17-009)
    Khi chưa có mô hình mặc định
    Thì hệ thống từ chối với ERR-17-033 (409)
    Và người dùng thấy thông báo "Chưa có mô hình mặc định loại {loại} được duyệt cho tỉnh."

  @US-17-010 @FR-17-010 @M @âm
  Kịch bản: US-17-010 âm 2 · Dự phòng không hợp lệ
    Biết tenant đã bật phiên bản `APPROVED` và chọn mặc định theo loại (FR-17-009)
    Khi dự phòng không hợp lệ
    Thì hệ thống từ chối với ERR-17-034 (409)
    Và người dùng thấy thông báo "Mô hình dự phòng phải cùng loại, đã duyệt, và không chuyển từ mô hình nội bộ sang mô hình ngoài."

  @US-17-011 @FR-17-011 @M
  Kịch bản: US-17-011 dương · Đồng bộ cấu hình tuyến egress APISIX ai-proxy qua PH-03
    Biết có ít nhất một nhà cung cấp `ACTIVE` và một phiên bản `APPROVED` cần tuyến
    Khi tự động khi nhà cung cấp, phiên bản, danh sách trắng, hoặc giới hạn đổi; hoặc người dùng bấm "Đồng bộ tuyến" ở UI-17-19
    Thì hệ thống trả `202` với `runId`; `GET /routes/sync-runs/{runId}`: `status` (`PENDING`, `APPLIED`, `REJECTED`, `TIMEOUT`), thời gian
    Và trạng thái tuyến khớp với phản hồi của PH-03
    Và sự kiện được phát: EVT-17-08 (phát); EVT-17-09 (nhận từ PH-03 và phát lại kết quả nội bộ)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-17-011 @FR-17-011 @M @âm
  Kịch bản: US-17-011 âm 1 · PH-03 từ chối cấu hình
    Biết có ít nhất một nhà cung cấp `ACTIVE` và một phiên bản `APPROVED` cần tuyến
    Khi PH-03 từ chối cấu hình
    Thì hệ thống từ chối với ERR-17-035 (503)
    Và người dùng thấy thông báo "Chưa đồng bộ được tuyến mô hình sang cổng API. Thử lại sau."

  @US-17-011 @FR-17-011 @M @âm
  Kịch bản: US-17-011 âm 2 · Đích ngoài danh sách egress
    Biết có ít nhất một nhà cung cấp `ACTIVE` và một phiên bản `APPROVED` cần tuyến
    Khi đích ngoài danh sách egress
    Thì hệ thống từ chối với ERR-17-039 (422)
    Và người dùng thấy thông báo "Đích {tên miền} không nằm trong danh sách egress được phép."

  @US-17-012 @FR-17-012 @M
  Kịch bản: US-17-012 dương · Giới hạn tần suất và bảo vệ tải ở cổng mô hình, cầu dao
    Biết có tuyến `ACTIVE`
    Khi mỗi lời gọi tới mô hình; quản trị đổi giới hạn ở UI-17-19
    Thì hệ thống trả `200`; giới hạn hiện hành, `ETag`; danh sách cầu dao với `state` (`CLOSED`, `OPEN`, `HALF_OPEN`)
    Và trạng thái cầu dao phản ánh đúng tỷ lệ lỗi gần nhất
    Và sự kiện được phát: EVT-17-11; EVT-17-01
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-17-012 @FR-17-012 @M @âm
  Kịch bản: US-17-012 âm 1 · Vượt giới hạn tần suất
    Biết có tuyến `ACTIVE`
    Khi vượt giới hạn tần suất
    Thì hệ thống từ chối với ERR-17-037 (429)
    Và người dùng thấy thông báo "Cổng mô hình đang giới hạn tần suất. Thử lại sau {n} giây."

  @US-17-012 @FR-17-012 @M @âm
  Kịch bản: US-17-012 âm 2 · Cầu dao mở
    Biết có tuyến `ACTIVE`
    Khi cầu dao mở
    Thì hệ thống từ chối với ERR-17-036 (503)
    Và người dùng thấy thông báo "Mô hình đang quá tải hoặc tạm ngắt. Thử lại sau ít phút."

  @US-17-013 @FR-17-013 @M
  Kịch bản: US-17-013 dương · Ghi vết mỗi lời gọi mô hình, không lưu nội dung thô
    Biết có lời gọi tới mô hình (thành công hay lỗi)
    Khi sau mỗi lời gọi mô hình, kể cả bị cầu dao chặn
    Thì hệ thống trả `200`; danh sách `items[]` kèm các trường trên; `GET /invocations/stats`: tổng hợp theo mô hình, năng lực, kết quả, p50 và p95 độ trễ
    Và `InvocationLog` bất biến sau khi ghi

  @US-17-013 @FR-17-013 @M @âm
  Kịch bản: US-17-013 âm 1 · Không ghi được vết (data plane)
    Biết có lời gọi tới mô hình (thành công hay lỗi)
    Khi không ghi được vết (data plane)
    Thì hệ thống từ chối với ERR-17-118 (503)
    Và người dùng thấy thông báo "Không ghi được vết lời gọi nên yêu cầu bị từ chối."

  @US-17-013 @FR-17-013 @M @âm
  Kịch bản: US-17-013 âm 2 · Không tìm thấy bản ghi
    Biết có lời gọi tới mô hình (thành công hay lỗi)
    Khi không tìm thấy bản ghi
    Thì hệ thống từ chối với ERR-17-001 (404)
    Và người dùng thấy thông báo "Không tìm thấy lời gọi {mã}."

  @US-17-014 @FR-17-014 @S
  Kịch bản: US-17-014 dương · Kiểm tra sức khỏe và trạng thái mô hình
    Biết có tuyến đã đồng bộ
    Khi tác vụ nền mỗi 30 giây cho phiên bản đang được tenant dùng; người dùng bấm "Thăm dò ngay"
    Thì hệ thống trả `200`; `state` (`UP`, `DEGRADED`, `DOWN`), `latencyMs`, `lastProbeAt`; lịch sử 24 giờ
    Và trạng thái sức khỏe cập nhật; cầu dao đồng bộ
    Và sự kiện được phát: EVT-17-10; EVT-17-11

  @US-17-014 @FR-17-014 @S @âm
  Kịch bản: US-17-014 âm 1 · Không kết nối được nhà cung cấp
    Biết có tuyến đã đồng bộ
    Khi không kết nối được nhà cung cấp
    Thì hệ thống từ chối với ERR-17-009 (503)
    Và người dùng thấy thông báo "Chưa kết nối được {tên dịch vụ}. Thử lại sau ít phút."

  # ---- EP-17-C · Kho tri thức và lập chỉ mục

  @US-17-015 @FR-17-015 @M
  Kịch bản: US-17-015 dương · Khai báo nguồn tri thức
    Biết trợ lý bật; có mô hình nhúng mặc định đã duyệt (ERR-17-048 nếu thiếu)
    Khi TA, DS bấm "Thêm nguồn" ở UI-17-08
    Thì hệ thống trả `201`; nguồn (`sourceId`, `status`, `docCount`), `ETag`
    Và có `KnowledgeSource`; chưa có đoạn nào cho tới khi lập chỉ mục xong
    Và sự kiện được phát: EVT-17-13
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-17-015 @FR-17-015 @M @âm
  Kịch bản: US-17-015 âm 1 · Loại không hợp lệ
    Biết trợ lý bật; có mô hình nhúng mặc định đã duyệt (ERR-17-048 nếu thiếu)
    Khi loại không hợp lệ
    Thì hệ thống từ chối với ERR-17-041 (422)
    Và người dùng thấy thông báo "Loại nguồn {loại} không hợp lệ hoặc chưa hỗ trợ."

  @US-17-015 @FR-17-015 @M @âm
  Kịch bản: US-17-015 âm 2 · Mã trùng
    Biết trợ lý bật; có mô hình nhúng mặc định đã duyệt (ERR-17-048 nếu thiếu)
    Khi mã trùng
    Thì hệ thống từ chối với ERR-17-042 (409)
    Và người dùng thấy thông báo "Nguồn tri thức {mã} đã được khai báo."

  @US-17-016 @FR-17-016 @M
  Kịch bản: US-17-016 dương · Kiểm mức phân loại trước khi lập chỉ mục
    Biết PH-09 có phân loại cho đối tượng (hợp đồng API, topic, luồng, danh mục)
    Khi trước mỗi lần lập chỉ mục một tài liệu hoặc đối tượng (FR-17-017); hoặc người dùng bấm "Kiểm tra mức" ở UI-17-08
    Thì hệ thống trả `200`; `result` (`ALLOWED`, `SKIPPED`), `classLevel`, `reason`
    Và tài liệu có `class_level` hoặc trạng thái `SKIPPED_CLASS`
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-17-016 @FR-17-016 @M @âm
  Kịch bản: US-17-016 âm 1 · Mức không được phép
    Biết PH-09 có phân loại cho đối tượng (hợp đồng API, topic, luồng, danh mục)
    Khi mức không được phép
    Thì hệ thống từ chối với ERR-17-043 (422)
    Và người dùng thấy thông báo "Dữ liệu mức {mức} không được lập chỉ mục. Chỉ nhận dữ liệu Công khai và Nội bộ."

  @US-17-016 @FR-17-016 @M @âm
  Kịch bản: US-17-016 âm 2 · Không xác nhận được mức
    Biết PH-09 có phân loại cho đối tượng (hợp đồng API, topic, luồng, danh mục)
    Khi không xác nhận được mức
    Thì hệ thống từ chối với ERR-17-049 (422)
    Và người dùng thấy thông báo "Không xác nhận được mức phân loại của {đối tượng} nên bỏ qua lập chỉ mục."

  @US-17-017 @FR-17-017 @M
  Kịch bản: US-17-017 dương · Lập chỉ mục theo sự kiện và lập lại toàn bộ theo lịch
    Biết nguồn `ACTIVE`; mô hình nhúng đã duyệt
    Khi sự kiện nguồn (bảng 9.3b); lịch `17.index.full-cron`; người dùng bấm "Lập lại chỉ mục"
    Thì hệ thống trả `202` với `jobId`; `GET /knowledge/index-jobs/{jobId}`: `status`, `added`, `removed`, `skipped`, `failed`
    Và đoạn khớp với phiên bản nguồn; lượt kết thúc ở `COMPLETED` hoặc `FAILED`
    Và sự kiện được phát: EVT-17-14; EVT-17-15
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-17-017 @FR-17-017 @M @âm
  Kịch bản: US-17-017 âm 1 · Đang có lượt cho nguồn
    Biết nguồn `ACTIVE`; mô hình nhúng đã duyệt
    Khi đang có lượt cho nguồn
    Thì hệ thống từ chối với ERR-17-044 (409)
    Và người dùng thấy thông báo "Đang có lượt lập chỉ mục cho nguồn này. Chờ lượt hiện tại xong."

  @US-17-017 @FR-17-017 @M @âm
  Kịch bản: US-17-017 âm 2 · Không có mô hình nhúng
    Biết nguồn `ACTIVE`; mô hình nhúng đã duyệt
    Khi không có mô hình nhúng
    Thì hệ thống từ chối với ERR-17-048 (409)
    Và người dùng thấy thông báo "Chưa có mô hình nhúng được duyệt nên chưa lập chỉ mục được."

  @US-17-018 @FR-17-018 @M
  Kịch bản: US-17-018 dương · Cắt đoạn, nhúng, lưu vector có tenant_id và phạm vi quyền đọc
    Biết tài liệu qua kiểm mức (FR-17-016)
    Khi bước 3 của FR-17-017, hoặc "Lập lại chỉ mục một tài liệu"
    Thì hệ thống trả `GET /knowledge/documents/{id}`: `chunkCount`, `classLevel`, `embedModelVersion`, danh sách đoạn (không hiện vector); `202` khi lập lại
    Và chỉ mục có đoạn mới; không có đoạn của hai phiên bản nhúng trong cùng thế hệ
    Và sự kiện được phát: EVT-17-14 (gom theo lượt)

  @US-17-018 @FR-17-018 @M @âm
  Kịch bản: US-17-018 âm 1 · Dấu hiệu DLCN trong đoạn
    Biết tài liệu qua kiểm mức (FR-17-016)
    Khi dấu hiệu DLCN trong đoạn
    Thì hệ thống từ chối với ERR-17-046 (422)
    Và người dùng thấy thông báo "Tệp có dấu hiệu chứa dữ liệu cá nhân hoặc mã độc nên không được nhận."

  @US-17-018 @FR-17-018 @M @âm
  Kịch bản: US-17-018 âm 2 · Tài liệu đang lập chỉ mục
    Biết tài liệu qua kiểm mức (FR-17-016)
    Khi tài liệu đang lập chỉ mục
    Thì hệ thống từ chối với ERR-17-047 (409)
    Và người dùng thấy thông báo "Tài liệu đang được lập chỉ mục. Thử lại sau."

  @US-17-019 @FR-17-019 @M
  Kịch bản: US-17-019 dương · Xóa lan truyền khi nguồn bị xóa, thu hồi, đổi mức phân loại
    Biết có đoạn thuộc đối tượng bị tác động
    Khi sự kiện xóa hoặc ngừng (`catalog.api.deleted`, `rdm.catalog.retired`, `integration.flow.retired`, `event.publication.state-changed`); EVT-09-01, EVT-09-03 làm mức khác `PUBLIC`, `INTERNAL`; ngừng nguồn; xóa thủ công
    Thì hệ thống trả `204`; hoặc `202` với `jobId`; `GET /knowledge/deletions`: danh sách đã xóa
    Và sự kiện được phát: EVT-17-16
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-17-019 @FR-17-019 @M @âm
  Kịch bản: US-17-019 âm 1 · Không tìm thấy tài liệu
    Biết có đoạn thuộc đối tượng bị tác động
    Khi không tìm thấy tài liệu
    Thì hệ thống từ chối với ERR-17-001 (404)
    Và người dùng thấy thông báo "Không tìm thấy tài liệu {mã}."

  @US-17-019 @FR-17-019 @M @âm
  Kịch bản: US-17-019 âm 2 · Tài liệu đang lập chỉ mục
    Biết có đoạn thuộc đối tượng bị tác động
    Khi tài liệu đang lập chỉ mục
    Thì hệ thống từ chối với ERR-17-047 (409)
    Và người dùng thấy thông báo "Tài liệu đang được lập chỉ mục. Thử lại sau."

  @US-17-020 @FR-17-020 @S
  Kịch bản: US-17-020 dương · Tải lên tài liệu hướng dẫn nội bộ làm nguồn tri thức, có duyệt
    Biết có nguồn loại `UPLOAD` (FR-17-015)
    Khi DS bấm "Tải tài liệu lên" ở UI-17-09
    Thì hệ thống trả `201` với `uploadId`, `status`; duyệt: `200`
    Và tài liệu `APPROVED` đã lập chỉ mục hoặc ở trạng thái bị từ chối
    Và sự kiện được phát: EVT-17-17; EVT-17-14
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-17-020 @FR-17-020 @S @âm
  Kịch bản: US-17-020 âm 1 · Sai định dạng hoặc quá cỡ
    Biết có nguồn loại `UPLOAD` (FR-17-015)
    Khi sai định dạng hoặc quá cỡ
    Thì hệ thống từ chối với ERR-17-045 (422)
    Và người dùng thấy thông báo "Tệp {tên} không đúng định dạng cho phép hoặc vượt {n} MB."

  @US-17-021 @FR-17-021 @S
  Kịch bản: US-17-021 dương · Theo dõi trạng thái chỉ mục
    Biết có nguồn khai báo
    Khi mở UI-17-08; hoặc cảnh báo tự động
    Thì hệ thống trả `200`; `sources[]` với `docs`, `chunks`, `freshnessSeconds`, `failed`, `stale`

  @US-17-021 @FR-17-021 @S @âm
  Kịch bản: US-17-021 âm 1 · Không tìm thấy nguồn
    Biết có nguồn khai báo
    Khi không tìm thấy nguồn
    Thì hệ thống từ chối với ERR-17-001 (404)
    Và người dùng thấy thông báo "Không tìm thấy nguồn {mã}."

  # ---- EP-17-D · Hội thoại và tìm dịch vụ

  @US-17-022 @FR-17-022 @M
  Kịch bản: US-17-022 dương · Mở bảng bên trợ lý, phiên hội thoại, ngữ cảnh màn hình
    Biết trợ lý bật, người dùng có ít nhất một năng lực khả dụng, đã xác nhận điều khoản (FR-17-005)
    Khi bấm nút "Trợ lý" trên thanh trên; hoặc nút "Giải thích lỗi này" cạnh mã lỗi trong `CMP-Alert`; hoặc từ CommandPalette (FR-17-029)
    Thì hệ thống trả `201` với `conversationId`, `capabilities[]`, `suggestedQuestions[]`, `quota`
    Và có `Conversation` của người dùng; chưa có tin nhắn

  @US-17-022 @FR-17-022 @M @âm
  Kịch bản: US-17-022 âm 1 · Trợ lý chưa bật
    Biết trợ lý bật, người dùng có ít nhất một năng lực khả dụng, đã xác nhận điều khoản (FR-17-005)
    Khi trợ lý chưa bật
    Thì hệ thống từ chối với ERR-17-008 (403)
    Và người dùng thấy thông báo "Trợ lý AI chưa được bật cho tỉnh của bạn."

  @US-17-022 @FR-17-022 @M @âm
  Kịch bản: US-17-022 âm 2 · Ngữ cảnh không hợp lệ
    Biết trợ lý bật, người dùng có ít nhất một năng lực khả dụng, đã xác nhận điều khoản (FR-17-005)
    Khi ngữ cảnh không hợp lệ
    Thì hệ thống từ chối với ERR-17-052 (422)
    Và người dùng thấy thông báo "Ngữ cảnh màn hình không hợp lệ."

  @US-17-023 @FR-17-023 @M
  Kịch bản: US-17-023 dương · Hỏi đáp tìm dịch vụ bằng ngôn ngữ tự nhiên, truy hồi lai
    Biết năng lực `SEARCH` khả dụng; chỉ mục có đoạn; hạn mức còn
    Khi người dùng gõ câu hỏi và gửi ở UI-17-01
    Thì hệ thống trả `200` hoặc luồng SSE (FR-17-026); `answer` (Markdown), `citations[]`, `outcome` (`ANSWERED`, `NOT_FOUND`), `messageId`
    Và có hai `Message` (hỏi, đáp) và `Citation`; hạn mức đã trừ

  @US-17-023 @FR-17-023 @M @âm
  Kịch bản: US-17-023 âm 1 · Hết hạn mức người dùng theo ngày
    Biết năng lực `SEARCH` khả dụng; chỉ mục có đoạn; hạn mức còn
    Khi hết hạn mức người dùng theo ngày
    Thì hệ thống từ chối với ERR-17-021 (429)
    Và người dùng thấy thông báo "Bạn đã dùng hết {n} lượt hôm nay. Thử lại sau {thời điểm}."

  @US-17-023 @FR-17-023 @M @âm
  Kịch bản: US-17-023 âm 2 · Hết hạn mức tenant theo ngày
    Biết năng lực `SEARCH` khả dụng; chỉ mục có đoạn; hạn mức còn
    Khi hết hạn mức tenant theo ngày
    Thì hệ thống từ chối với ERR-17-022 (429)
    Và người dùng thấy thông báo "Tỉnh đã dùng hết hạn mức hôm nay. Liên hệ quản trị tỉnh."

  @US-17-024 @FR-17-024 @M
  Kịch bản: US-17-024 dương · Lọc kết quả theo quyền của người hỏi
    Biết có tập đoạn ứng viên từ truy hồi (FR-17-023)
    Khi mỗi lượt truy hồi, ngay sau bước lấy top-k
    Thì danh sách đoạn đã lọc; vết có `filteredOut` (số)

  @US-17-024 @FR-17-024 @M @âm
  Kịch bản: US-17-024 âm 1 · Phân hệ nguồn không khả dụng
    Biết có tập đoạn ứng viên từ truy hồi (FR-17-023)
    Khi phân hệ nguồn không khả dụng
    Thì hệ thống từ chối với ERR-17-009 (503)
    Và người dùng thấy thông báo "Chưa kết nối được {tên dịch vụ}. Thử lại sau ít phút."

  @US-17-024 @FR-17-024 @M @âm
  Kịch bản: US-17-024 âm 2 · Token người dùng hết hạn khi xác minh
    Biết có tập đoạn ứng viên từ truy hồi (FR-17-023)
    Khi token người dùng hết hạn khi xác minh
    Thì hệ thống từ chối với ERR-17-064 (503)
    Và người dùng thấy thông báo "Chưa lấy được quyền truy cập thay mặt bạn. Đăng nhập lại và thử lại."

  @US-17-025 @FR-17-025 @M
  Kịch bản: US-17-025 dương · Trích dẫn nguồn, liên kết tới màn đối tượng, nói "không tìm thấy" thay vì bịa
    Biết có tập đoạn đã lọc quyền (FR-17-024) hoặc tập rỗng
    Khi bước dựng câu trả lời của mỗi lượt
    Thì hệ thống trả `answer`, `citations[]`, `outcome`, `label`
    Và `Citation` gắn `Message`; chỉ số "tỷ lệ có trích dẫn", "tỷ lệ không tìm thấy" tính được (FR-17-053)
    Và sự kiện được phát: EVT-17-19 khi đầu ra bị chặn

  @US-17-025 @FR-17-025 @M @âm
  Kịch bản: US-17-025 âm 1 · Câu trả lời bị chặn ở bộ lọc đầu ra
    Biết có tập đoạn đã lọc quyền (FR-17-024) hoặc tập rỗng
    Khi câu trả lời bị chặn ở bộ lọc đầu ra
    Thì hệ thống từ chối với ERR-17-067 (422)
    Và người dùng thấy thông báo "Câu trả lời bị chặn vì có thể lộ dữ liệu nhạy cảm."

  @US-17-025 @FR-17-025 @M @âm
  Kịch bản: US-17-025 âm 2 · Mô hình lỗi
    Biết có tập đoạn đã lọc quyền (FR-17-024) hoặc tập rỗng
    Khi mô hình lỗi
    Thì hệ thống từ chối với ERR-17-036 (503)
    Và người dùng thấy thông báo "Mô hình đang quá tải hoặc tạm ngắt. Thử lại sau ít phút."

  @US-17-026 @FR-17-026 @S
  Kịch bản: US-17-026 dương · Phát trực tuyến câu trả lời (SSE), hủy giữa chừng
    Biết như FR-17-023
    Khi gửi câu hỏi tới `messages:stream`; bấm "Dừng" khi đang phát
    Thì hệ thống trả `200` luồng SSE; hủy: `204`
    Và tin nhắn ở `COMPLETED`, `CANCELLED` hoặc `BLOCKED`
    Và sự kiện được phát: EVT-17-19 khi bị chặn

  @US-17-026 @FR-17-026 @S @âm
  Kịch bản: US-17-026 âm 1 · Hủy câu đã hoàn tất
    Biết như FR-17-023
    Khi hủy câu đã hoàn tất
    Thì hệ thống từ chối với ERR-17-053 (409)
    Và người dùng thấy thông báo "Câu trả lời đã hoàn tất hoặc đã bị hủy."

  @US-17-027 @FR-17-027 @M
  Kịch bản: US-17-027 dương · Lịch sử hội thoại của tôi, xóa hội thoại, hết hạn
    Biết có hội thoại
    Khi mở "Lịch sử" ở UI-17-05; bấm "Xóa"
    Thì hệ thống trả `200` danh sách phân trang (`items[]`: `conversationId`, `title`, `lastAt`, `messageCount`); xóa: `204`
    Và hội thoại bị xóa không hiện ở lịch sử; nhật ký đã che giữ tới hết hạn
    Và sự kiện được phát: EVT-17-27 (tác vụ hết hạn)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-17-027 @FR-17-027 @M @âm
  Kịch bản: US-17-027 âm 1 · Không tìm thấy hoặc hết hạn
    Biết có hội thoại
    Khi không tìm thấy hoặc hết hạn
    Thì hệ thống từ chối với ERR-17-001
    Và người dùng thấy thông báo "Không tìm thấy hội thoại {mã}."

  @US-17-027 @FR-17-027 @M @âm
  Kịch bản: US-17-027 âm 2 · Tiếp tục hội thoại đầy
    Biết có hội thoại
    Khi tiếp tục hội thoại đầy
    Thì hệ thống từ chối với ERR-17-050 (409)
    Và người dùng thấy thông báo "Hội thoại đã đạt giới hạn {n} lượt. Mở hội thoại mới."

  @US-17-028 @FR-17-028 @C
  Kịch bản: US-17-028 dương · Gợi ý câu hỏi theo màn và theo vai trò
    Biết có ít nhất một năng lực khả dụng
    Khi mở bảng bên; đổi màn hình
    Thì hệ thống trả `200`; `questions[]` (`id`, `text`, `capability`)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-17-028 @FR-17-028 @C @âm
  Kịch bản: US-17-028 âm 1 · Dữ liệu không hợp lệ
    Biết có ít nhất một năng lực khả dụng
    Khi dữ liệu không hợp lệ
    Thì hệ thống từ chối với ERR-17-003 (400)
    Và người dùng thấy thông báo "Dữ liệu không hợp lệ: {chi tiết}."

  @US-17-029 @FR-17-029 @S
  Kịch bản: US-17-029 dương · Hỏi từ CommandPalette
    Biết trợ lý bật; người dùng đã xác nhận điều khoản
    Khi người dùng mở CommandPalette (Ctrl+K) và gõ; mục "Hỏi trợ lý AI: {chữ vừa gõ}" xuất hiện cuối danh sách
    Thì bảng bên mở sẵn câu hỏi, người dùng chỉ cần xác nhận gửi
    Và chưa có tin nhắn nào cho tới khi người dùng gửi

  @US-17-029 @FR-17-029 @S @âm
  Kịch bản: US-17-029 âm 1 · Trợ lý chưa bật (gọi trực tiếp)
    Biết trợ lý bật; người dùng đã xác nhận điều khoản
    Khi trợ lý chưa bật (gọi trực tiếp)
    Thì hệ thống từ chối với ERR-17-008 (403)
    Và người dùng thấy thông báo "Trợ lý AI chưa được bật cho tỉnh của bạn."

  # ---- EP-17-E · Gợi ý ánh xạ dữ liệu

  @US-17-030 @FR-17-030 @M
  Kịch bản: US-17-030 dương · Gợi ý ánh xạ trường nguồn sang đích, sinh biểu thức JQ đề xuất
    Biết năng lực `MAPPING` khả dụng; người dùng đang ở trình ánh xạ PH-04 có lược đồ nguồn và đích
    Khi bấm "Gợi ý ánh xạ" ở trình ánh xạ hoặc trong thẻ ở bảng bên (UI-17-02)
    Thì hệ thống trả `200`; `suggestions[]`: `suggestionId`, `sourcePath`, `targetPath`, `expression`, `confidence`, `reason`, `expiresAt`
    Và có `Suggestion` ở `PROPOSED`; chưa có thay đổi nào ở PH-04

  @US-17-030 @FR-17-030 @M @âm
  Kịch bản: US-17-030 âm 1 · Hết hạn mức người dùng theo ngày
    Biết năng lực `MAPPING` khả dụng; người dùng đang ở trình ánh xạ PH-04 có lược đồ nguồn và đích
    Khi hết hạn mức người dùng theo ngày
    Thì hệ thống từ chối với ERR-17-021 (429)
    Và người dùng thấy thông báo "Bạn đã dùng hết {n} lượt hôm nay. Thử lại sau {thời điểm}."

  @US-17-030 @FR-17-030 @M @âm
  Kịch bản: US-17-030 âm 2 · Hết hạn mức tenant theo ngày
    Biết năng lực `MAPPING` khả dụng; người dùng đang ở trình ánh xạ PH-04 có lược đồ nguồn và đích
    Khi hết hạn mức tenant theo ngày
    Thì hệ thống từ chối với ERR-17-022 (429)
    Và người dùng thấy thông báo "Tỉnh đã dùng hết hạn mức hôm nay. Liên hệ quản trị tỉnh."

  @US-17-031 @FR-17-031 @S
  Kịch bản: US-17-031 dương · Gợi ý ánh xạ mã danh mục cục bộ sang danh mục chuẩn PH-07
    Biết có danh mục chuẩn `PUBLISHED` ở PH-07 và tập mã cục bộ (tên, mô tả)
    Khi bấm "Gợi ý ánh xạ mã" ở màn ánh xạ danh mục của PH-07 hoặc trong bảng bên
    Thì hệ thống trả `200`; `suggestions[]`: `localCode`, `standardCode`, `confidence`, `reason`
    Và có `Suggestion` ở `PROPOSED`

  @US-17-031 @FR-17-031 @S @âm
  Kịch bản: US-17-031 âm 1 · Mã không có trong danh mục chuẩn
    Biết có danh mục chuẩn `PUBLISHED` ở PH-07 và tập mã cục bộ (tên, mô tả)
    Khi mã không có trong danh mục chuẩn
    Thì hệ thống từ chối với ERR-17-058 (422)
    Và người dùng thấy thông báo "Mã {mã} không có trong danh mục chuẩn {danh mục}."

  @US-17-032 @FR-17-032 @M
  Kịch bản: US-17-032 dương · Điểm tin cậy và giải thích lý do cho từng gợi ý
    Biết có `Suggestion` ở `PROPOSED`
    Khi hiển thị thẻ đề xuất; mở chi tiết gợi ý
    Thì hệ thống trả `200`; `confidence` (0 đến 1), `confidenceBand` (`LOW`, `REVIEW`, `HIGH`), `reason`, `signals[]`, `alternatives[]`

  @US-17-032 @FR-17-032 @M @âm
  Kịch bản: US-17-032 âm 1 · Không tìm thấy gợi ý
    Biết có `Suggestion` ở `PROPOSED`
    Khi không tìm thấy gợi ý
    Thì hệ thống từ chối với ERR-17-001 (404)
    Và người dùng thấy thông báo "Không tìm thấy gợi ý {mã}."

  @US-17-032 @FR-17-032 @M @âm
  Kịch bản: US-17-032 âm 2 · Gợi ý đã hết hạn
    Biết có `Suggestion` ở `PROPOSED`
    Khi gợi ý đã hết hạn
    Thì hệ thống từ chối với ERR-17-056 (409)
    Và người dùng thấy thông báo "Gợi ý đã hết hạn hoặc bản nháp đã thay đổi. Tạo gợi ý mới."

  @US-17-033 @FR-17-033 @M
  Kịch bản: US-17-033 dương · Áp dụng gợi ý qua thẻ đề xuất, ghi bản nháp bằng quyền người dùng
    Biết `Suggestion` ở `PROPOSED`, chưa hết hạn; bản nháp ở phân hệ chủ chưa đổi
    Khi người dùng bấm "Xem trước" rồi "Áp dụng vào bản nháp" ở thẻ đề xuất (UI-17-02)
    Thì hệ thống trả `200`; `suggestionId`, `status`, `draftRef`, `draftEtag` mới
    Và bản nháp đổi bởi người dùng; `Suggestion` ở `ACCEPTED` hoặc `EDITED`
    Và sự kiện được phát: EVT-17-18
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-17-033 @FR-17-033 @M @âm
  Kịch bản: US-17-033 âm 1 · Bản nháp đã đổi hoặc gợi ý hết hạn
    Biết `Suggestion` ở `PROPOSED`, chưa hết hạn; bản nháp ở phân hệ chủ chưa đổi
    Khi bản nháp đã đổi hoặc gợi ý hết hạn
    Thì hệ thống từ chối với ERR-17-056 (409)
    Và người dùng thấy thông báo "Gợi ý đã hết hạn hoặc bản nháp đã thay đổi. Tạo gợi ý mới."

  @US-17-033 @FR-17-033 @M @âm
  Kịch bản: US-17-033 âm 2 · Không có quyền sửa
    Biết `Suggestion` ở `PROPOSED`, chưa hết hạn; bản nháp ở phân hệ chủ chưa đổi
    Khi không có quyền sửa
    Thì hệ thống từ chối với ERR-17-057 (403)
    Và người dùng thấy thông báo "Bạn không có quyền sửa bản nháp này ở {tên phân hệ}."

  @US-17-034 @FR-17-034 @M
  Kịch bản: US-17-034 dương · Không đưa giá trị dữ liệu thật vào prompt, chỉ lược đồ và mẫu đã che
    Biết có yêu cầu gợi ý ánh xạ (FR-17-030, 031)
    Khi trước mỗi lần dựng prompt ánh xạ
    Thì kết quả của FR-17-030, 031; không có API riêng
    Và prompt không chứa giá trị dữ liệu thật
    Và sự kiện được phát: EVT-17-19 khi bộ quét chặn mẫu có DLCN
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-17-034 @FR-17-034 @M @âm
  Kịch bản: US-17-034 âm 1 · Mẫu chứa giá trị chưa che
    Biết có yêu cầu gợi ý ánh xạ (FR-17-030, 031)
    Khi mẫu chứa giá trị chưa che
    Thì hệ thống từ chối với ERR-17-059 (422)
    Và người dùng thấy thông báo "Dữ liệu mẫu chứa giá trị chưa che. Che dữ liệu rồi gửi lại."

  @US-17-034 @FR-17-034 @M @âm
  Kịch bản: US-17-034 âm 2 · Bộ che PH-09 không khả dụng
    Biết có yêu cầu gợi ý ánh xạ (FR-17-030, 031)
    Khi bộ che PH-09 không khả dụng
    Thì hệ thống từ chối với ERR-17-059

  @US-17-035 @FR-17-035 @S
  Kịch bản: US-17-035 dương · Ghi nhận chấp nhận, sửa, từ chối gợi ý để đo chất lượng
    Biết có `Suggestion`
    Khi người dùng bấm "Áp dụng", "Sửa rồi áp dụng" hoặc "Từ chối" trên thẻ đề xuất
    Thì hệ thống trả `200`; trạng thái mới của `Suggestion`
    Và `Suggestion` ở trạng thái cuối
    Và sự kiện được phát: EVT-17-18

  @US-17-035 @FR-17-035 @S @âm
  Kịch bản: US-17-035 âm 1 · Gợi ý đã được xử lý
    Biết có `Suggestion`
    Khi gợi ý đã được xử lý
    Thì hệ thống từ chối với ERR-17-006 (409)
    Và người dùng thấy thông báo "Đối tượng đang ở trạng thái ACCEPTED, không thực hiện được thao tác này."

  # ---- EP-17-F · Giải thích sự cố

  @US-17-036 @FR-17-036 @M
  Kịch bản: US-17-036 dương · Giải thích mã lỗi (ERR) đang hiển thị
    Biết mã lỗi hiển thị trên màn hình; nguồn `ERR_CATALOG` đã lập chỉ mục
    Khi bấm "Giải thích lỗi này" cạnh mã lỗi trong `CMP-Alert` (UI-17-03)
    Thì hệ thống trả `200`; `explanationId`, `answer`, `citations[]`, `checklistOffered`
    Và có `Message` và `Citation`

  @US-17-036 @FR-17-036 @M @âm
  Kịch bản: US-17-036 âm 1 · Hết hạn mức người dùng theo ngày
    Biết mã lỗi hiển thị trên màn hình; nguồn `ERR_CATALOG` đã lập chỉ mục
    Khi hết hạn mức người dùng theo ngày
    Thì hệ thống từ chối với ERR-17-021 (429)
    Và người dùng thấy thông báo "Bạn đã dùng hết {n} lượt hôm nay. Thử lại sau {thời điểm}."

  @US-17-036 @FR-17-036 @M @âm
  Kịch bản: US-17-036 âm 2 · Hết hạn mức tenant theo ngày
    Biết mã lỗi hiển thị trên màn hình; nguồn `ERR_CATALOG` đã lập chỉ mục
    Khi hết hạn mức tenant theo ngày
    Thì hệ thống từ chối với ERR-17-022 (429)
    Và người dùng thấy thông báo "Tỉnh đã dùng hết hạn mức hôm nay. Liên hệ quản trị tỉnh."

  @US-17-037 @FR-17-037 @M
  Kịch bản: US-17-037 dương · Giải thích lỗi theo trace_id, tổng hợp log và vết bằng quyền người dùng
    Biết có `trace_id` hợp lệ (đề xuất theo W3C Trace Context, 32 ký tự thập lục phân; PH-13 xác nhận ở Q17-27) trong thời hạn lưu của PH-13; người dùng có quyền xem log và vết đó
    Khi người dùng dán `trace_id` hoặc bấm "Giải thích" từ màn vết (PTN-11)
    Thì hệ thống trả `200`; `explanationId`, `findings[]` (dịch vụ, mô tả, mức chắc chắn), `citations[]`
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-17-037 @FR-17-037 @M @âm
  Kịch bản: US-17-037 âm 1 · Không có quyền xem log, vết
    Biết có `trace_id` hợp lệ (đề xuất theo W3C Trace Context, 32 ký tự thập lục phân; PH-13 xác nhận ở Q17-27) trong thời hạn lưu của PH-13; người dùng có quyền xem log và vết đó
    Khi không có quyền xem log, vết
    Thì hệ thống từ chối với ERR-17-060 (403)
    Và người dùng thấy thông báo "Bạn không có quyền xem dữ liệu này nên trợ lý không giải thích được."

  @US-17-037 @FR-17-037 @M @âm
  Kịch bản: US-17-037 âm 2 · `trace_id` sai dạng
    Biết có `trace_id` hợp lệ (đề xuất theo W3C Trace Context, 32 ký tự thập lục phân; PH-13 xác nhận ở Q17-27) trong thời hạn lưu của PH-13; người dùng có quyền xem log và vết đó
    Khi `trace_id` sai dạng
    Thì hệ thống từ chối với ERR-17-061 (422)
    Và người dùng thấy thông báo "Mã vết {mã} không đúng định dạng."

  @US-17-038 @FR-17-038 @S
  Kịch bản: US-17-038 dương · Giải thích bản tin DLQ PH-18 và đề xuất hướng xử lý
    Biết có bản tin DLQ người dùng được phép xem
    Khi bấm "Giải thích" ở màn xem bản tin DLQ của PH-18
    Thì hệ thống trả `200`; `explanationId`, `cause`, `recommendations[]`, `citations[]`
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-17-038 @FR-17-038 @S @âm
  Kịch bản: US-17-038 âm 1 · Không có quyền xem bản tin
    Biết có bản tin DLQ người dùng được phép xem
    Khi không có quyền xem bản tin
    Thì hệ thống từ chối với ERR-17-060 (403)
    Và người dùng thấy thông báo "Bạn không có quyền xem dữ liệu này nên trợ lý không giải thích được."

  @US-17-039 @FR-17-039 @M
  Kịch bản: US-17-039 dương · Gợi ý bước khắc phục dạng danh sách kiểm, không tự thực hiện
    Biết có một lần giải thích (FR-17-036, 037, 038)
    Khi bấm "Tạo danh sách kiểm" ở kết quả giải thích
    Thì hệ thống trả `200`; `checklist[]`: `step`, `kind`, `link`, `expected`
    Và có `Suggestion` loại `REMEDIATION`; không thay đổi hệ thống

  @US-17-039 @FR-17-039 @M @âm
  Kịch bản: US-17-039 âm 1 · Không tìm thấy lần giải thích
    Biết có một lần giải thích (FR-17-036, 037, 038)
    Khi không tìm thấy lần giải thích
    Thì hệ thống từ chối với ERR-17-001 (404)
    Và người dùng thấy thông báo "Không tìm thấy lần giải thích {mã}."

  @US-17-039 @FR-17-039 @M @âm
  Kịch bản: US-17-039 âm 2 · Bộ lọc loại hết bước
    Biết có một lần giải thích (FR-17-036, 037, 038)
    Khi bộ lọc loại hết bước
    Thì hệ thống từ chối với ERR-17-067 (422)
    Và người dùng thấy thông báo "Câu trả lời bị chặn vì có thể lộ dữ liệu nhạy cảm."

  @US-17-040 @FR-17-040 @S
  Kịch bản: US-17-040 dương · Tóm tắt sự cố cho báo cáo
    Biết có một hoặc nhiều lần giải thích, hoặc mục (vết, DLQ) người dùng chọn và được phép xem
    Khi bấm "Tóm tắt sự cố" ở bảng bên (UI-17-03)
    Thì hệ thống trả `200`; `summary` (Markdown), `sections[]`, `label`
    Và có `Suggestion` loại `INCIDENT_SUMMARY`; không đổi dữ liệu nguồn

  @US-17-040 @FR-17-040 @S @âm
  Kịch bản: US-17-040 âm 1 · Không có mục nào được phép
    Biết có một hoặc nhiều lần giải thích, hoặc mục (vết, DLQ) người dùng chọn và được phép xem
    Khi không có mục nào được phép
    Thì hệ thống từ chối với ERR-17-060 (403)
    Và người dùng thấy thông báo "Bạn không có quyền xem dữ liệu này nên trợ lý không giải thích được."

  @US-17-041 @FR-17-041 @M
  Kịch bản: US-17-041 dương · Che dữ liệu cá nhân trong log trước khi đưa vào prompt
    Biết có nội dung log, vết hoặc DLQ đã lấy (FR-17-037, 038)
    Khi ngay sau khi lấy dữ liệu và trước khi dựng prompt; hoặc người dùng bấm "Xem trước nội dung gửi" (`redaction:preview`)
    Thì hệ thống trả `200` (xem trước): `redactedText`, `counts` (số vị trí đã che theo loại); không trả dữ liệu gốc
    Và prompt và nhật ký chỉ có dữ liệu đã che

  @US-17-041 @FR-17-041 @M @âm
  Kịch bản: US-17-041 âm 1 · Không đủ an toàn để đưa vào prompt
    Biết có nội dung log, vết hoặc DLQ đã lấy (FR-17-037, 038)
    Khi không đủ an toàn để đưa vào prompt
    Thì hệ thống từ chối với ERR-17-062 (422)
    Và người dùng thấy thông báo "Chọn không quá {n} dòng log hoặc khoảng thời gian không quá {m} phút."

  @US-17-041 @FR-17-041 @M @âm
  Kịch bản: US-17-041 âm 2 · Bộ che lỗi nội bộ
    Biết có nội dung log, vết hoặc DLQ đã lấy (FR-17-037, 038)
    Khi bộ che lỗi nội bộ
    Thì hệ thống từ chối với ERR-17-009 (503)
    Và người dùng thấy thông báo "Chưa kết nối được bộ che dữ liệu. Thử lại sau ít phút."

  # ---- EP-17-G · Công cụ và an toàn

  @US-17-042 @FR-17-042 @M
  Kịch bản: US-17-042 dương · Danh mục công cụ chỉ đọc, bật tắt theo tenant
    Biết trợ lý bật
    Khi người dùng bật hoặc tắt công cụ ở UI-17-10
    Thì hệ thống trả `200`; danh mục `tools[]` (`toolCode`, `targetApi`, `scope`, `enabled`)
    Và cấu hình công cụ mới có hiệu lực ≤ 60 giây
    Và sự kiện được phát: EVT-17-01
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-17-042 @FR-17-042 @M @âm
  Kịch bản: US-17-042 âm 1 · Công cụ chưa bật
    Biết trợ lý bật
    Khi công cụ chưa bật
    Thì hệ thống từ chối với ERR-17-063 (403)
    Và người dùng thấy thông báo "Công cụ {mã} chưa được bật cho tỉnh."

  @US-17-042 @FR-17-042 @M @âm
  Kịch bản: US-17-042 âm 2 · Không tìm thấy công cụ
    Biết trợ lý bật
    Khi không tìm thấy công cụ
    Thì hệ thống từ chối với ERR-17-001 (404)
    Và người dùng thấy thông báo "Không tìm thấy công cụ {mã}."

  @US-17-043 @FR-17-043 @M
  Kịch bản: US-17-043 dương · Chạy công cụ bằng token người dùng, không quyền riêng
    Biết công cụ bật (FR-17-042); người dùng có token hợp lệ
    Khi mô hình yêu cầu gọi công cụ trong một lượt
    Thì kết quả công cụ (nội bộ); `GET /tools/calls`: danh sách `ToolCall` đã che
    Và có `ToolCall`; không có quyền hay token nào còn tồn tại sau lượt

  @US-17-043 @FR-17-043 @M @âm
  Kịch bản: US-17-043 âm 1 · Không đổi được token
    Biết công cụ bật (FR-17-042); người dùng có token hợp lệ
    Khi không đổi được token
    Thì hệ thống từ chối với ERR-17-064 (503)
    Và người dùng thấy thông báo "Chưa lấy được quyền truy cập thay mặt bạn. Đăng nhập lại và thử lại."

  @US-17-043 @FR-17-043 @M @âm
  Kịch bản: US-17-043 âm 2 · Người dùng không có quyền
    Biết công cụ bật (FR-17-042); người dùng có token hợp lệ
    Khi người dùng không có quyền
    Thì hệ thống từ chối với ERR-17-060 (403)
    Và người dùng thấy thông báo "Bạn không có quyền xem dữ liệu này nên trợ lý không giải thích được."

  @US-17-044 @FR-17-044 @M
  Kịch bản: US-17-044 dương · Bọc nội dung truy hồi như dữ liệu không tin cậy, tách kênh chỉ dẫn
    Biết có nội dung bên ngoài cần đưa vào prompt (đoạn truy hồi, kết quả công cụ, log)
    Khi bước dựng prompt của mỗi lượt
    Thì prompt đã dựng (nội bộ); vết có `untrustedBlocks`, `sanitizedCount`
    Và sự kiện được phát: EVT-17-19 khi phát hiện nội dung nghi ngờ nặng
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-17-044 @FR-17-044 @M @âm
  Kịch bản: US-17-044 âm 1 · Mô hình yêu cầu công cụ ngoài danh sách
    Biết có nội dung bên ngoài cần đưa vào prompt (đoạn truy hồi, kết quả công cụ, log)
    Khi mô hình yêu cầu công cụ ngoài danh sách
    Thì hệ thống từ chối với ERR-17-063 (403)
    Và người dùng thấy thông báo "Công cụ {mã} chưa được bật cho tỉnh."

  @US-17-044 @FR-17-044 @M @âm
  Kịch bản: US-17-044 âm 2 · Phát hiện nội dung bên ngoài chứa lệnh nghi ngờ nặng
    Biết có nội dung bên ngoài cần đưa vào prompt (đoạn truy hồi, kết quả công cụ, log)
    Khi phát hiện nội dung bên ngoài chứa lệnh nghi ngờ nặng
    Thì hệ thống từ chối với ERR-17-065, ERR-17-065 (422)
    Và người dùng thấy thông báo "Câu hỏi bị từ chối vì có dấu hiệu tiêm lệnh hoặc nội dung không được phép."

  @US-17-045 @FR-17-045 @M
  Kịch bản: US-17-045 dương · Bộ lọc đầu vào: tiêm lệnh, nội dung cấm, DLCN tự dán
    Biết có câu hỏi vào
    Khi mỗi lượt hỏi, trước truy hồi
    Thì lượt tiếp tục hoặc `422`; `GET /guardrails`: danh sách quy tắc
    Và sự kiện được phát: EVT-17-19; EVT-17-01 khi đổi quy tắc
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-17-045 @FR-17-045 @M @âm
  Kịch bản: US-17-045 âm 1 · Tiêm lệnh, nội dung cấm
    Biết có câu hỏi vào
    Khi tiêm lệnh, nội dung cấm
    Thì hệ thống từ chối với ERR-17-065 (422)
    Và người dùng thấy thông báo "Câu hỏi bị từ chối vì có dấu hiệu tiêm lệnh hoặc nội dung không được phép."

  @US-17-045 @FR-17-045 @M @âm
  Kịch bản: US-17-045 âm 2 · DLCN nhạy cảm
    Biết có câu hỏi vào
    Khi DLCN nhạy cảm
    Thì hệ thống từ chối với ERR-17-066 (422)
    Và người dùng thấy thông báo "Câu hỏi chứa dữ liệu cá nhân nhạy cảm. Bỏ dữ liệu đó rồi hỏi lại."

  @US-17-046 @FR-17-046 @M
  Kịch bản: US-17-046 dương · Bộ lọc đầu ra: che mẫu DLCN, chặn bí mật, chặn liên kết ngoài
    Biết có đầu ra mô hình (toàn bộ hoặc theo cửa sổ khi phát trực tuyến)
    Khi mỗi cửa sổ đầu ra, trước khi phát cho người dùng
    Thì câu trả lời đã lọc; vết có `maskedCount`, `blockedLinks`, `blocked`
    Và đầu ra đã phát đã qua lọc; sự kiện chặn có bản ghi
    Và sự kiện được phát: EVT-17-19
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-17-046 @FR-17-046 @M @âm
  Kịch bản: US-17-046 âm 1 · Đầu ra bị chặn
    Biết có đầu ra mô hình (toàn bộ hoặc theo cửa sổ khi phát trực tuyến)
    Khi đầu ra bị chặn
    Thì hệ thống từ chối với ERR-17-067 (422)
    Và người dùng thấy thông báo "Câu trả lời bị chặn vì có thể lộ dữ liệu nhạy cảm."

  @US-17-046 @FR-17-046 @M @âm
  Kịch bản: US-17-046 âm 2 · Danh sách trắng liên kết không hợp lệ
    Biết có đầu ra mô hình (toàn bộ hoặc theo cửa sổ khi phát trực tuyến)
    Khi danh sách trắng liên kết không hợp lệ
    Thì hệ thống từ chối với ERR-17-003 (400)
    Và người dùng thấy thông báo "Dữ liệu không hợp lệ: {chi tiết}."

  @US-17-047 @FR-17-047 @M
  Kịch bản: US-17-047 dương · Giới hạn số lần gọi công cụ mỗi lượt, thời gian chờ, độ sâu
    Biết có lượt hỏi dùng công cụ
    Khi mỗi lần mô hình yêu cầu công cụ
    Thì hệ thống trả `200`; giới hạn hiện hành; lượt có `partial = true` khi bị dừng
    Và số lần gọi, thời gian mỗi lượt trong giới hạn
    Và sự kiện được phát: EVT-17-01 khi đổi giới hạn
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-17-047 @FR-17-047 @M @âm
  Kịch bản: US-17-047 âm 1 · Vượt số lần gọi
    Biết có lượt hỏi dùng công cụ
    Khi vượt số lần gọi
    Thì hệ thống từ chối với ERR-17-069 (422)
    Và người dùng thấy thông báo "Công cụ vượt giới hạn {n} lần gọi mỗi lượt."

  @US-17-047 @FR-17-047 @M @âm
  Kịch bản: US-17-047 âm 2 · Lượt quá thời gian
    Biết có lượt hỏi dùng công cụ
    Khi lượt quá thời gian
    Thì hệ thống từ chối với ERR-17-068 (504)
    Và người dùng thấy thông báo "Lượt hỏi vượt thời gian tối đa {n} giây. Thử lại với câu hỏi ngắn hơn."

  @US-17-048 @FR-17-048 @M
  Kịch bản: US-17-048 dương · Nhãn "Nội dung do AI tạo" và không có hành động ghi tự động
    Biết có nội dung do trợ lý tạo
    Khi hiển thị mọi câu trả lời, thẻ đề xuất, danh sách kiểm, tóm tắt; mọi lần sao chép hoặc xuất
    Thì trường `label` trong mọi phản hồi sinh văn bản

  @US-17-048 @FR-17-048 @M @âm
  Kịch bản: US-17-048 âm 1 · Cố gọi công cụ ghi
    Biết có nội dung do trợ lý tạo
    Khi cố gọi công cụ ghi
    Thì hệ thống từ chối với ERR-17-070 (403)
    Và người dùng thấy thông báo "Trợ lý chỉ đọc. Thao tác ghi phải do bạn xác nhận trên thẻ đề xuất."

  @US-17-048 @FR-17-048 @M @âm
  Kịch bản: US-17-048 âm 2 · Cố bật tự áp dụng qua tham số
    Biết có nội dung do trợ lý tạo
    Khi cố bật tự áp dụng qua tham số
    Thì hệ thống từ chối với ERR-17-084 (422)
    Và người dùng thấy thông báo "Khóa tham số {khóa} không tồn tại."

  # ---- EP-17-H · Quản trị AI, đánh giá và chất lượng

  @US-17-049 @FR-17-049 @M
  Kịch bản: US-17-049 dương · Quản lý mẫu chỉ dẫn hệ thống có phiên bản, duyệt bốn mắt
    Biết có bộ đánh giá và bộ ca đỏ cho năng lực (FR-17-050, 051)
    Khi TA bấm "Soạn phiên bản mới" ở UI-17-12
    Thì hệ thống trả `201` phiên bản; duyệt `200` kèm `releaseGate`
    Và mỗi (mẫu, năng lực) có đúng một phiên bản `ACTIVE`
    Và sự kiện được phát: EVT-17-20
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-17-049 @FR-17-049 @M @âm
  Kịch bản: US-17-049 âm 1 · Nội dung không được phép
    Biết có bộ đánh giá và bộ ca đỏ cho năng lực (FR-17-050, 051)
    Khi nội dung không được phép
    Thì hệ thống từ chối với ERR-17-071 (422)
    Và người dùng thấy thông báo "Chỉ dẫn hệ thống chứa nội dung không được phép: {lý do}."

  @US-17-049 @FR-17-049 @M @âm
  Kịch bản: US-17-049 âm 2 · Chưa đạt cổng phát hành
    Biết có bộ đánh giá và bộ ca đỏ cho năng lực (FR-17-050, 051)
    Khi chưa đạt cổng phát hành
    Thì hệ thống từ chối với ERR-17-072 (409)
    Và người dùng thấy thông báo "Chưa đạt cổng phát hành: {lý do}."

  @US-17-050 @FR-17-050 @M
  Kịch bản: US-17-050 dương · Bộ đánh giá chuẩn theo năng lực, chạy khi đổi mô hình hoặc prompt
    Biết có bộ đánh giá có tối thiểu 30 ca cho năng lực
    Khi đổi mô hình, mô hình nhúng, prompt, tham số truy hồi; hoặc bấm "Chạy đánh giá" ở UI-17-11
    Thì hệ thống trả `202` với `runId`; kết quả: `score`, `metrics{}`, `regression`, `status` (`PASSED`, `FAILED`)
    Và `EvalRun` hoàn tất; cổng phát hành cập nhật
    Và sự kiện được phát: EVT-17-21
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-17-050 @FR-17-050 @M @âm
  Kịch bản: US-17-050 âm 1 · Bộ quá ít ca
    Biết có bộ đánh giá có tối thiểu 30 ca cho năng lực
    Khi bộ quá ít ca
    Thì hệ thống từ chối với ERR-17-074 (422)
    Và người dùng thấy thông báo "Bộ đánh giá cần tối thiểu {n} ca."

  @US-17-050 @FR-17-050 @M @âm
  Kịch bản: US-17-050 âm 2 · Đang có lượt đánh giá
    Biết có bộ đánh giá có tối thiểu 30 ca cho năng lực
    Khi đang có lượt đánh giá
    Thì hệ thống từ chối với ERR-17-076 (409)
    Và người dùng thấy thông báo "Đang có lượt đánh giá chạy cho đối tượng này."

  @US-17-051 @FR-17-051 @M
  Kịch bản: US-17-051 dương · Bộ ca đỏ tiêm lệnh, cổng phát hành chặn khi có ca lọt
    Biết bộ ca đỏ có tối thiểu 50 ca đang hoạt động
    Khi đổi mã bộ lọc, công cụ, prompt (CI); gửi duyệt phiên bản mô hình hoặc prompt; SO bấm "Chạy bộ ca đỏ" ở UI-17-11
    Thì hệ thống trả `202` với `runId`; kết quả: `total`, `blocked`, `leaked`, `cases[]`
    Và `EvalRun` loại ca đỏ lưu cùng phiên bản đối tượng
    Và sự kiện được phát: EVT-17-22
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-17-051 @FR-17-051 @M @âm
  Kịch bản: US-17-051 âm 1 · Bộ ca dưới 50
    Biết bộ ca đỏ có tối thiểu 50 ca đang hoạt động
    Khi bộ ca dưới 50
    Thì hệ thống từ chối với ERR-17-075 (422)
    Và người dùng thấy thông báo "Bộ ca đỏ cần tối thiểu 50 ca đang hoạt động."

  @US-17-051 @FR-17-051 @M @âm
  Kịch bản: US-17-051 âm 2 · Có ca lọt
    Biết bộ ca đỏ có tối thiểu 50 ca đang hoạt động
    Khi có ca lọt
    Thì hệ thống từ chối với ERR-17-073 (409)
    Và người dùng thấy thông báo "Ca đỏ {mã} chưa bị chặn nên không phát hành được."

  @US-17-052 @FR-17-052 @M
  Kịch bản: US-17-052 dương · Phản hồi của người dùng và hàng xử lý phản hồi
    Biết có câu trả lời của trợ lý
    Khi bấm "Hữu ích", "Không hữu ích" hoặc "Báo sai" dưới câu trả lời (UI-17-01)
    Thì hệ thống trả `201` với `feedbackId`; xử lý: `200`
    Và `Feedback` được tạo; số liệu chất lượng cập nhật
    Và sự kiện được phát: EVT-17-23
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-17-052 @FR-17-052 @M @âm
  Kịch bản: US-17-052 âm 1 · Phản hồi trùng
    Biết có câu trả lời của trợ lý
    Khi phản hồi trùng
    Thì hệ thống từ chối với ERR-17-077 (409)
    Và người dùng thấy thông báo "Bạn đã gửi phản hồi cho câu trả lời này."

  @US-17-052 @FR-17-052 @M @âm
  Kịch bản: US-17-052 âm 2 · Sửa quá 10 phút hoặc phản hồi đã được phân loại
    Biết có câu trả lời của trợ lý
    Khi sửa quá 10 phút hoặc phản hồi đã được phân loại
    Thì hệ thống từ chối với ERR-17-006 (409)
    Và người dùng thấy thông báo "Đối tượng đang ở trạng thái {trạng thái}, không thực hiện được thao tác này."

  @US-17-053 @FR-17-053 @S
  Kịch bản: US-17-053 dương · Chỉ số chất lượng và cảnh báo suy giảm
    Biết có dữ liệu lượt hỏi
    Khi mở UI-17-13; tác vụ tính hằng đêm
    Thì hệ thống trả `200`; `metrics[]` (theo ngày), `alerts[]`
    Và chỉ số cập nhật hằng đêm
    Và sự kiện được phát: EVT-17-24
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-17-053 @FR-17-053 @S @âm
  Kịch bản: US-17-053 âm 1 · Ngưỡng ngoài miền
    Biết có dữ liệu lượt hỏi
    Khi ngưỡng ngoài miền
    Thì hệ thống từ chối với ERR-17-082 (422)
    Và người dùng thấy thông báo "Giá trị tham số {khóa} nằm ngoài miền {miền}."

  @US-17-054 @FR-17-054 @S
  Kịch bản: US-17-054 dương · Sổ đăng ký hệ thống AI của tenant
    Biết trợ lý đã từng bật
    Khi TA mở UI-17-18; hoặc tự cập nhật khi đổi cấu hình
    Thì hệ thống trả `200`; hồ sơ kèm lịch sử, `nextReviewAt`
    Và hồ sơ có phiên bản mới mỗi khi đổi
    Và sự kiện được phát: EVT-17-01 (khi lưu)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-17-054 @FR-17-054 @S @âm
  Kịch bản: US-17-054 âm 1 · Thiếu mục
    Biết trợ lý đã từng bật
    Khi thiếu mục
    Thì hệ thống từ chối với ERR-17-078 (422)
    Và người dùng thấy thông báo "Hồ sơ hệ thống AI thiếu mục: {mục}."

  # ---- EP-17-I · Nhật ký, kiểm toán, báo cáo, cấu hình

  @US-17-055 @FR-17-055 @M
  Kịch bản: US-17-055 dương · Nhật ký hội thoại đã che, lưu 90 ngày
    Biết có lượt hỏi đáp
    Khi mỗi lượt, sau khi hoàn tất, hủy hoặc bị chặn
    Thì hệ thống trả `GET /logs/retention`: `retentionDays`, `oldestAt`, `lastPurgeAt`, `purgedCount`
    Và sự kiện được phát: EVT-17-27
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-17-055 @FR-17-055 @M @âm
  Kịch bản: US-17-055 âm 1 · Không ghi được nhật ký
    Biết có lượt hỏi đáp
    Khi không ghi được nhật ký
    Thì hệ thống từ chối với ERR-17-009 (503)
    Và người dùng thấy thông báo "Chưa kết nối được kho nhật ký. Thử lại sau ít phút."

  @US-17-055 @FR-17-055 @M @âm
  Kịch bản: US-17-055 âm 2 · Đặt hạn lưu dưới 90 ngày
    Biết có lượt hỏi đáp
    Khi đặt hạn lưu dưới 90 ngày
    Thì hệ thống từ chối với ERR-17-083 (422)
    Và người dùng thấy thông báo "Thời hạn lưu nhật ký không được thấp hơn 90 ngày."

  @US-17-056 @FR-17-056 @M
  Kịch bản: US-17-056 dương · Tra cứu nhật ký cho SO, AUDITOR có lý do truy cập
    Biết người dùng có `PERM-17-log-read`
    Khi mở UI-17-15, chọn hội thoại, bấm "Xem nội dung" (UI-17-16)
    Thì hệ thống trả `200`; danh sách siêu dữ liệu; `201` phiếu (`grantId`, `expiresAt`); nội dung hội thoại đã che
    Và có `LogAccessGrant` và bản ghi kiểm toán
    Và sự kiện được phát: EVT-17-25
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-17-056 @FR-17-056 @M @âm
  Kịch bản: US-17-056 âm 1 · Chưa có phiếu
    Biết người dùng có `PERM-17-log-read`
    Khi chưa có phiếu
    Thì hệ thống từ chối với ERR-17-080 (403)
    Và người dùng thấy thông báo "Chưa có phiếu truy cập nhật ký còn hiệu lực. Khai báo lý do để xem."

  @US-17-056 @FR-17-056 @M @âm
  Kịch bản: US-17-056 âm 2 · Thiếu lý do
    Biết người dùng có `PERM-17-log-read`
    Khi thiếu lý do
    Thì hệ thống từ chối với ERR-17-007 (422)
    Và người dùng thấy thông báo "Nhập lý do tối thiểu 20 ký tự."

  @US-17-057 @FR-17-057 @S
  Kịch bản: US-17-057 dương · Xuất bằng chứng tuân thủ
    Biết có cấu hình và ít nhất một lượt đánh giá
    Khi bấm "Tạo gói bằng chứng" ở UI-17-17
    Thì hệ thống trả `202` với `exportId`; `GET` trạng thái; tải: `200` tệp ZIP gồm PDF tóm tắt, JSON số liệu, `manifest` băm, chữ ký
    Và có `ComplianceExport` và bản ghi kiểm toán
    Và sự kiện được phát: EVT-17-26
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-17-057 @FR-17-057 @S @âm
  Kịch bản: US-17-057 âm 1 · Gói hết hạn tải
    Biết có cấu hình và ít nhất một lượt đánh giá
    Khi gói hết hạn tải
    Thì hệ thống từ chối với ERR-17-081 (410)
    Và người dùng thấy thông báo "Gói bằng chứng đã hết hạn tải. Tạo lại gói mới."

  @US-17-058 @FR-17-058 @S
  Kịch bản: US-17-058 dương · Báo cáo sử dụng
    Biết có dữ liệu vết lời gọi
    Khi mở UI-17-17; PH-16 gọi định kỳ
    Thì hệ thống trả `200`; `rows[]` theo nhóm, `totals`; xuất: `202` với `exportId`
    Và sự kiện được phát: EVT-17-26 (khi xuất xong)

  @US-17-058 @FR-17-058 @S @âm
  Kịch bản: US-17-058 âm 1 · Khoảng thời gian quá rộng
    Biết có dữ liệu vết lời gọi
    Khi khoảng thời gian quá rộng
    Thì hệ thống từ chối với ERR-17-079 (422)
    Và người dùng thấy thông báo "Chọn khoảng thời gian tối đa {n} ngày."

  @US-17-059 @FR-17-059 @M
  Kịch bản: US-17-059 dương · Tham số 17.* và giá trị mặc định
    Biết PH-18 phục vụ bản ghi tham số tenant
    Khi TA sửa tham số ở UI-17-06; `dh-assist` đọc tham số mỗi 30 giây
    Thì hệ thống trả `200`; tham số, `ETag`; `GET /settings/schema`: khóa, miền, mặc định, trần, sàn
    Và giá trị mới có hiệu lực ≤ 60 giây
    Và sự kiện được phát: EVT-17-01; EVT-17-04 (với tham số nhạy)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-17-059 @FR-17-059 @M @âm
  Kịch bản: US-17-059 âm 1 · Khóa không tồn tại
    Biết PH-18 phục vụ bản ghi tham số tenant
    Khi khóa không tồn tại
    Thì hệ thống từ chối với ERR-17-084 (422)
    Và người dùng thấy thông báo "Khóa tham số {khóa} không tồn tại."

  @US-17-059 @FR-17-059 @M @âm
  Kịch bản: US-17-059 âm 2 · Ngoài miền
    Biết PH-18 phục vụ bản ghi tham số tenant
    Khi ngoài miền
    Thì hệ thống từ chối với ERR-17-082 (422)
    Và người dùng thấy thông báo "Giá trị tham số {khóa} nằm ngoài miền {miền}."

  # ---- EP-17-J · Dịch vụ AI cho phân hệ khác

  @US-17-060 @FR-17-060 @S
  Kịch bản: US-17-060 dương · API suy luận nội bộ cho bước luồng PH-04
    Biết trợ lý bật cho tenant; có mô hình hội thoại mặc định đã duyệt; PH-04 có token dịch vụ scope `assist:infer`
    Khi bước luồng PH-04 gọi `POST /assist/v1/inference/classify` hoặc `extract`
    Thì hệ thống trả `200`; `result` (nhãn hoặc trường đã trích), `confidence`, `modelVersionId`, `invocationId`
    Và có `InvocationLog`; PH-17 không lưu văn bản đầu vào

  @US-17-060 @FR-17-060 @S @âm
  Kịch bản: US-17-060 âm 1 · Thiếu quyền
    Biết trợ lý bật cho tenant; có mô hình hội thoại mặc định đã duyệt; PH-04 có token dịch vụ scope `assist:infer`
    Khi thiếu quyền
    Thì hệ thống từ chối với ERR-17-101 (403)
    Và người dùng thấy thông báo "Dịch vụ gọi chưa có quyền suy luận (assist:infer)."

  @US-17-061 @FR-17-061 @C
  Kịch bản: US-17-061 dương · Gợi ý cho bước quy trình PH-11, luôn có người quyết định cuối
    Biết như FR-17-060; PH-11 khai báo loại bước hỗ trợ (Q17-22)
    Khi user task PH-11 gọi `POST /assist/v1/process-suggestions`
    Thì hệ thống trả `200`; `suggestionId`, `option`, `reason`, `confidence`, `humanDecisionRequired = true`
    Và `Suggestion` loại `PROCESS_STEP`; hồ sơ không đổi trạng thái do PH-17
    Và sự kiện được phát: EVT-17-28
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-17-061 @FR-17-061 @C @âm
  Kịch bản: US-17-061 âm 1 · Yêu cầu tự quyết
    Biết như FR-17-060; PH-11 khai báo loại bước hỗ trợ (Q17-22)
    Khi yêu cầu tự quyết
    Thì hệ thống từ chối với ERR-17-114 (403)
    Và người dùng thấy thông báo "Gợi ý quy trình luôn cần người quyết định; yêu cầu tự quyết bị từ chối."

  @US-17-062 @FR-17-062 @C
  Kịch bản: US-17-062 dương · Dùng tập dữ liệu đã ẩn danh PH-09 cho đánh giá
    Biết PH-09 có tập ở trạng thái `RELEASED` cho mục đích đánh giá (EVT-09-18), `k ≥ 10`
    Khi người dùng bấm "Gắn tập dữ liệu" ở UI-17-11
    Thì hệ thống trả `201` với `linkId`; danh sách `GET /eval-datasets`
    Và có liên kết tập; tập hết hạn thì kết quả liên quan bị xóa
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-17-062 @FR-17-062 @C @âm
  Kịch bản: US-17-062 âm 1 · `purpose` khác `EVALUATION`, ví dụ huấn luyện hoặc tinh chỉnh mô hình (PH-17 không có đường này)
    Biết PH-09 có tập ở trạng thái `RELEASED` cho mục đích đánh giá (EVT-09-18), `k ≥ 10`
    Khi `purpose` khác `EVALUATION`, ví dụ huấn luyện hoặc tinh chỉnh mô hình (PH-17 không có đường này)
    Thì hệ thống từ chối với ERR-17-003 (400)
    Và người dùng thấy thông báo "Dữ liệu không hợp lệ: {chi tiết}."
