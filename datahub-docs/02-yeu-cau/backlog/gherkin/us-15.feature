# language: vi
# Sinh tự động từ D02-02/D02-03-PH15 bằng backlog/tools/sinh_backlog.py; không sửa tay.
@PH-15
Tính năng: PH-15 · Cổng nhà phát triển

  # ---- EP-15-A · Danh mục, tìm kiếm và truy cập

  @US-15-001 @FR-15-001 @M
  Kịch bản: US-15-001 dương · Đồng bộ danh mục dịch vụ từ PH-02
    Biết PH-02 khả dụng; tài khoản dịch vụ của `portal-catalog` đã được cấp scope khi triển khai
    Khi nhận EVT-02-01, 02, 03, 05, 06, 08, 10 hoặc 12; đến lịch kéo bù mỗi `15.sync.interval-seconds`; khởi động lần đầu; quản trị bấm "Đồng bộ lại" (FR-15-061)
    Thì nội bộ; API-15-009 trả `state`, `lastSyncAt`, `lagSeconds`, `itemCount`
    Và bản sao khớp `sourceVersion` mới nhất của PH-02; chỉ mục tìm kiếm cập nhật
    Và sự kiện được phát: EVT-15-14 khi trạng thái đồng bộ đổi

  @US-15-001 @FR-15-001 @M @âm
  Kịch bản: US-15-001 âm 1 · PH-02 lỗi `5xx` hoặc quá thời gian
    Biết PH-02 khả dụng; tài khoản dịch vụ của `portal-catalog` đã được cấp scope khi triển khai
    Khi PH-02 lỗi `5xx` hoặc quá thời gian
    Thì giữ bản sao, thử lại lùi mũ 5, 30, 120 giây; quá `15.sync.stale-seconds` thì trạng thái `STALE` và hiện banner thông báo
    Và người dùng thấy thông báo "Danh mục có thể chưa phản ánh thay đổi mới nhất."

  @US-15-001 @FR-15-001 @M @âm
  Kịch bản: US-15-001 âm 2 · Chưa từng nạp xong
    Biết PH-02 khả dụng; tài khoản dịch vụ của `portal-catalog` đã được cấp scope khi triển khai
    Khi chưa từng nạp xong
    Thì hệ thống từ chối với ERR-15-008 (503)
    Và người dùng thấy thông báo "Danh mục dịch vụ chưa sẵn sàng. Thử lại sau ít phút."

  @US-15-002 @FR-15-002 @M
  Kịch bản: US-15-002 dương · Áp mức hiển thị theo người xem
    Biết bản sao danh mục đã nạp (FR-15-001)
    Khi mọi truy vấn danh mục, tìm kiếm, tài liệu, thử
    Thì tập mục danh mục đã lọc; `404` cho mục ngoài tầm

  @US-15-002 @FR-15-002 @M @âm
  Kịch bản: US-15-002 âm 1 · API ngoài tầm nhìn
    Biết bản sao danh mục đã nạp (FR-15-001)
    Khi API ngoài tầm nhìn
    Thì hệ thống từ chối với ERR-15-001 (404)
    Và người dùng thấy thông báo "Không tìm thấy nội dung yêu cầu."

  @US-15-002 @FR-15-002 @M @âm
  Kịch bản: US-15-002 âm 2 · Tenant chưa bật chế độ công khai mà khách ẩn danh vào trang danh mục
    Biết bản sao danh mục đã nạp (FR-15-001)
    Khi tenant chưa bật chế độ công khai mà khách ẩn danh vào trang danh mục
    Thì chuyển tới trang đăng nhập, không hiện lỗi

  @US-15-003 @FR-15-003 @M
  Kịch bản: US-15-003 dương · Trang chủ cổng
    Biết người dùng đã đăng nhập với vai trò nhà phát triển
    Khi người dùng mở `/`
    Thì hệ thống trả `200`; `featured[]`, `quickstart`, `announcements[]`, `myWork` (nếu đăng nhập); `Cache-Control: public, max-age=300` cho khách ẩn danh

  @US-15-003 @FR-15-003 @M @âm
  Kịch bản: US-15-003 âm 1 · Bản sao danh mục chưa sẵn sàng
    Biết người dùng đã đăng nhập với vai trò nhà phát triển
    Khi bản sao danh mục chưa sẵn sàng
    Thì hệ thống từ chối với ERR-15-008 (503)
    Và người dùng thấy thông báo "Danh mục dịch vụ chưa sẵn sàng. Thử lại sau ít phút."

  @US-15-004 @FR-15-004 @M
  Kịch bản: US-15-004 dương · Duyệt, lọc, sắp xếp danh mục dịch vụ
    Biết bản sao danh mục đã nạp
    Khi người dùng mở `/dich-vu` hoặc đổi bộ lọc
    Thì hệ thống trả `200`; `items[]`, `facets`, `page`, `size`, `totalElements`

  @US-15-004 @FR-15-004 @M @âm
  Kịch bản: US-15-004 âm 1 · Giá trị lọc sai miền
    Biết bản sao danh mục đã nạp
    Khi giá trị lọc sai miền
    Thì hệ thống từ chối với ERR-15-003 (400)
    Và người dùng thấy thông báo "Dữ liệu chưa hợp lệ. Kiểm tra các trường được đánh dấu."

  @US-15-004 @FR-15-004 @M @âm
  Kịch bản: US-15-004 âm 2 · Không có kết quả
    Biết bản sao danh mục đã nạp
    Khi không có kết quả
    Thì không phải lỗi; thông báo
    Và người dùng thấy thông báo "Không có dịch vụ nào khớp. Thử bỏ bớt bộ lọc."

  @US-15-005 @FR-15-005 @M
  Kịch bản: US-15-005 dương · Tìm kiếm toàn văn tiếng Việt và gợi ý
    Biết chỉ mục đã dựng (hoặc dự phòng PostgreSQL)
    Khi người dùng gõ vào ô tìm (gợi ý) hoặc nhấn Enter, `Ctrl+K`
    Thì hệ thống trả `200`; `results[]` (loại, mã, tiêu đề, đoạn trích), `page`, `size`, `totalElements`; gợi ý: `suggestions[]`

  @US-15-005 @FR-15-005 @M @âm
  Kịch bản: US-15-005 âm 1 · `q` dài quá 200 ký tự hoặc rỗng khi `Enter`
    Biết chỉ mục đã dựng (hoặc dự phòng PostgreSQL)
    Khi `q` dài quá 200 ký tự hoặc rỗng khi `Enter`
    Thì hệ thống từ chối với ERR-15-003 (400)
    Và người dùng thấy thông báo "Dữ liệu chưa hợp lệ. Kiểm tra các trường được đánh dấu."

  @US-15-005 @FR-15-005 @M @âm
  Kịch bản: US-15-005 âm 2 · Vượt tần suất
    Biết chỉ mục đã dựng (hoặc dự phòng PostgreSQL)
    Khi vượt tần suất
    Thì hệ thống từ chối với ERR-15-007 (429)
    Và người dùng thấy thông báo "Thao tác quá nhanh. Thử lại sau {n} giây."

  @US-15-006 @FR-15-006 @M
  Kịch bản: US-15-006 dương · Trang chi tiết dịch vụ, đường dẫn sử dụng và SLA
    Biết API nằm trong tập người xem được phép thấy
    Khi người dùng mở `/dich-vu/{ma-api}`
    Thì hệ thống trả `200`; mục chi tiết, `versions[]`, `plans[]`, `sla`, `usage` (`baseUrl`, `tokenUrl`, `scopes[]`, `samples[]`)

  @US-15-006 @FR-15-006 @M @âm
  Kịch bản: US-15-006 âm 1 · Không thấy hoặc ngoài tầm
    Biết API nằm trong tập người xem được phép thấy
    Khi không thấy hoặc ngoài tầm
    Thì hệ thống từ chối với ERR-15-001 (404)
    Và người dùng thấy thông báo "Không tìm thấy nội dung yêu cầu."

  @US-15-006 @FR-15-006 @M @âm
  Kịch bản: US-15-006 âm 2 · Phiên bản đã ngừng hẳn
    Biết API nằm trong tập người xem được phép thấy
    Khi phiên bản đã ngừng hẳn
    Thì hệ thống từ chối với ERR-15-038 (410)
    Và người dùng thấy thông báo "Phiên bản này đã ngừng cung cấp."

  @US-15-007 @FR-15-007 @S
  Kịch bản: US-15-007 dương · Hiển thị dịch vụ sự kiện
    Biết PH-02 đã đưa mục loại `EVENT` vào danh mục (từ EVT-10-01)
    Khi người dùng chọn "Dịch vụ sự kiện" ở `/dich-vu` hoặc mở `/su-kien/{ma-topic}`
    Thì hệ thống trả `200`; mục sự kiện gồm `topicName`, mô tả, `dataClass`, HTTT phát, liên kết PH-10

  @US-15-007 @FR-15-007 @S @âm
  Kịch bản: US-15-007 âm 1 · Topic ngoài tầm
    Biết PH-02 đã đưa mục loại `EVENT` vào danh mục (từ EVT-10-01)
    Khi topic ngoài tầm
    Thì hệ thống từ chối với ERR-15-001 (404)
    Và người dùng thấy thông báo "Không tìm thấy nội dung yêu cầu."

  @US-15-008 @FR-15-008 @M
  Kịch bản: US-15-008 dương · Truy cập ẩn danh cổng công khai
    Biết `15.public.enabled = true`; API có `visibility = PUBLIC`, `dataClass = PUBLIC`, `portalPublished = true`
    Khi truy cập `/public/...` hoặc trang cổng khi chưa đăng nhập
    Thì hệ thống trả `200` hoặc `304`; như FR-15-004, FR-15-006 nhưng rút gọn

  @US-15-008 @FR-15-008 @M @âm
  Kịch bản: US-15-008 âm 1 · Vượt tần suất
    Biết `15.public.enabled = true`; API có `visibility = PUBLIC`, `dataClass = PUBLIC`, `portalPublished = true`
    Khi vượt tần suất
    Thì hệ thống từ chối với ERR-15-007 (429)
    Và người dùng thấy thông báo "Thao tác quá nhanh. Thử lại sau {n} giây."

  @US-15-008 @FR-15-008 @M @âm
  Kịch bản: US-15-008 âm 2 · API không `PUBLIC`
    Biết `15.public.enabled = true`; API có `visibility = PUBLIC`, `dataClass = PUBLIC`, `portalPublished = true`
    Khi API không `PUBLIC`
    Thì hệ thống từ chối với ERR-15-001 (404)
    Và người dùng thấy thông báo "Không tìm thấy nội dung yêu cầu."

  # ---- EP-15-B · Tài liệu API

  @US-15-009 @FR-15-009 @M
  Kịch bản: US-15-009 dương · Hiển thị tài liệu OpenAPI 3.1
    Biết phiên bản `PUBLISHED`, `DEPRECATED` hoặc `SUSPENDED` có đặc tả đã nạp
    Khi người dùng mở `/dich-vu/{ma-api}/tai-lieu`
    Thì hệ thống trả `200`; `operations[]`, `schemas`, `servers`, `hash`, `syncedAt`

  @US-15-009 @FR-15-009 @M @âm
  Kịch bản: US-15-009 âm 1 · Chưa có đặc tả đã nạp hoặc không phân tích được
    Biết phiên bản `PUBLISHED`, `DEPRECATED` hoặc `SUSPENDED` có đặc tả đã nạp
    Khi chưa có đặc tả đã nạp hoặc không phân tích được
    Thì hệ thống từ chối với ERR-15-009 (422)
    Và người dùng thấy thông báo "Đặc tả của dịch vụ này chưa đọc được. Liên hệ đầu mối của dịch vụ."

  @US-15-009 @FR-15-009 @M @âm
  Kịch bản: US-15-009 âm 2 · Thao tác không có trong đặc tả
    Biết phiên bản `PUBLISHED`, `DEPRECATED` hoặc `SUSPENDED` có đặc tả đã nạp
    Khi thao tác không có trong đặc tả
    Thì bỏ neo, hiển thị đầu trang

  @US-15-010 @FR-15-010 @S
  Kịch bản: US-15-010 dương · Hiển thị tài liệu AsyncAPI 3.0
    Biết mục `EVENT` có lược đồ AsyncAPI 3.0 đã nạp
    Khi mở `/su-kien/{ma-topic}` hoặc tài liệu của API có phần sự kiện
    Thì hệ thống trả `200`; `channels[]`, `messages[]`, `schemas`

  @US-15-010 @FR-15-010 @S @âm
  Kịch bản: US-15-010 âm 1 · Lược đồ không phân tích được
    Biết mục `EVENT` có lược đồ AsyncAPI 3.0 đã nạp
    Khi lược đồ không phân tích được
    Thì hệ thống từ chối với ERR-15-009 (422)
    Và người dùng thấy thông báo "Đặc tả của dịch vụ này chưa đọc được. Liên hệ đầu mối của dịch vụ."

  @US-15-011 @FR-15-011 @M
  Kịch bản: US-15-011 dương · Chọn phiên bản, tải đặc tả, so sánh phiên bản
    Biết API có ít nhất một phiên bản `PUBLISHED` hoặc `DEPRECATED`
    Khi người dùng đổi bộ chọn phiên bản, bấm "Tải đặc tả" hoặc "So sánh"
    Thì hệ thống trả `200`; tệp đặc tả với `Content-Disposition`; hoặc `diff` gồm `added[]`, `removed[]`, `changed[]`
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-15-011 @FR-15-011 @M @âm
  Kịch bản: US-15-011 âm 1 · Phiên bản không tồn tại hoặc ngoài tầm
    Biết API có ít nhất một phiên bản `PUBLISHED` hoặc `DEPRECATED`
    Khi phiên bản không tồn tại hoặc ngoài tầm
    Thì hệ thống từ chối với ERR-15-001 (404)
    Và người dùng thấy thông báo "Không tìm thấy nội dung yêu cầu."

  @US-15-011 @FR-15-011 @M @âm
  Kịch bản: US-15-011 âm 2 · Phiên bản đã ngừng hẳn
    Biết API có ít nhất một phiên bản `PUBLISHED` hoặc `DEPRECATED`
    Khi phiên bản đã ngừng hẳn
    Thì hệ thống từ chối với ERR-15-038 (410)
    Và người dùng thấy thông báo "Phiên bản này đã ngừng cung cấp."

  @US-15-012 @FR-15-012 @M
  Kịch bản: US-15-012 dương · Sinh mẫu mã gọi API
    Biết phiên bản có đặc tả đã nạp
    Khi người dùng chọn ngôn ngữ ở thao tác của trang tài liệu hoặc khung thử
    Thì hệ thống trả `200`; `samples[]` (`lang`, `title`, `code`)

  @US-15-012 @FR-15-012 @M @âm
  Kịch bản: US-15-012 âm 1 · Ngôn ngữ không hỗ trợ
    Biết phiên bản có đặc tả đã nạp
    Khi ngôn ngữ không hỗ trợ
    Thì hệ thống từ chối với ERR-15-003 (400)
    Và người dùng thấy thông báo "Dữ liệu chưa hợp lệ. Kiểm tra các trường được đánh dấu."

  @US-15-012 @FR-15-012 @M @âm
  Kịch bản: US-15-012 âm 2 · Thao tác không có
    Biết phiên bản có đặc tả đã nạp
    Khi thao tác không có
    Thì hệ thống từ chối với ERR-15-001 (404)

  @US-15-013 @FR-15-013 @M
  Kịch bản: US-15-013 dương · Changelog, lộ trình ngừng dùng và banner DEPRECATED
    Biết có phiên bản `DEPRECATED` hoặc có lịch sử phiên bản
    Khi mở `/dich-vu/{ma-api}/thay-doi`, hoặc mở tài liệu của phiên bản `DEPRECATED`
    Thì hệ thống trả `200`; `timeline[]` (loại, ngày, mô tả, liên kết)

  @US-15-013 @FR-15-013 @M @âm
  Kịch bản: US-15-013 âm 1 · API không có lịch sử
    Biết có phiên bản `DEPRECATED` hoặc có lịch sử phiên bản
    Khi API không có lịch sử
    Thì hệ thống từ chối thao tác
    Và người dùng thấy thông báo "Chưa có thay đổi nào được ghi nhận."

  @US-15-013 @FR-15-013 @M @âm
  Kịch bản: US-15-013 âm 2 · Ngoài tầm
    Biết có phiên bản `DEPRECATED` hoặc có lịch sử phiên bản
    Khi ngoài tầm
    Thì hệ thống từ chối với ERR-15-001 (404)

  # ---- EP-15-C · Hướng dẫn và nội dung

  @US-15-014 @FR-15-014 @M
  Kịch bản: US-15-014 dương · Soạn trang nội dung Markdown
    Biết người dùng đã chấp nhận điều khoản nội bộ (nếu có); với trang gắn API, API thuộc tổ chức của người soạn (SV)
    Khi ở UI-15-22 bấm "+ Trang mới": hộp nhập mã trang (đúng mẫu `pageCode`) rồi mở `/quan-tri-cong/noi-dung/{ma-trang}`, không có đường dẫn `/moi`; hoặc "Sửa" một trang có sẵn; hoặc "Tạo từ mẫu"
    Thì hệ thống trả `201` (tạo) hoặc `200` (sửa), `ETag`; trang với `versionNo`, `status`
    Và phiên bản `DRAFT` được lưu, chưa hiển thị cho người đọc
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-15-014 @FR-15-014 @M @âm
  Kịch bản: US-15-014 âm 1 · Mã đã dùng
    Biết người dùng đã chấp nhận điều khoản nội bộ (nếu có); với trang gắn API, API thuộc tổ chức của người soạn (SV)
    Khi mã đã dùng
    Thì hệ thống từ chối với ERR-15-002 (409)
    Và người dùng thấy thông báo "Mã {mã} đã được dùng. Chọn mã khác."

  @US-15-014 @FR-15-014 @M @âm
  Kịch bản: US-15-014 âm 2 · Nội dung không hợp lệ
    Biết người dùng đã chấp nhận điều khoản nội bộ (nếu có); với trang gắn API, API thuộc tổ chức của người soạn (SV)
    Khi nội dung không hợp lệ
    Thì hệ thống từ chối với ERR-15-021 (422)
    Và người dùng thấy thông báo "Nội dung có phần không được phép: {chi tiết}."

  @US-15-015 @FR-15-015 @M
  Kịch bản: US-15-015 dương · Gửi duyệt, duyệt và đăng trang
    Biết phiên bản `DRAFT` đạt kiểm tra nội dung
    Khi người soạn bấm "Gửi duyệt"; người duyệt mở yêu cầu từ "Việc của tôi"
    Thì hệ thống trả `200`; trang với `status`, `publishedVersionNo`
    Và một phiên bản `PUBLISHED` duy nhất mỗi trang
    Và sự kiện được phát: EVT-15-08 (`content.published`)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-15-015 @FR-15-015 @M @âm
  Kịch bản: US-15-015 âm 1 · Người duyệt là người soạn hoặc gửi
    Biết phiên bản `DRAFT` đạt kiểm tra nội dung
    Khi người duyệt là người soạn hoặc gửi
    Thì hệ thống từ chối với ERR-15-023 (403)
    Và người dùng thấy thông báo "Người duyệt phải khác người soạn và người gửi duyệt."

  @US-15-015 @FR-15-015 @M @âm
  Kịch bản: US-15-015 âm 2 · Trang không ở `IN_REVIEW`
    Biết phiên bản `DRAFT` đạt kiểm tra nội dung
    Khi trang không ở `IN_REVIEW`
    Thì hệ thống từ chối với ERR-15-022 (409)
    Và người dùng thấy thông báo "Đối tượng đang {trạng thái} nên không thực hiện được thao tác này."

  @US-15-016 @FR-15-016 @S
  Kịch bản: US-15-016 dương · Phiên bản trang, so sánh, khôi phục, gỡ đăng
    Biết trang có từ một phiên bản trở lên
    Khi mở tab "Lịch sử" của trang ở UI-15-22
    Thì hệ thống trả `200`; danh sách phiên bản hoặc trang sau khi đổi trạng thái
    Và phiên bản cũ giữ vĩnh viễn; trang `UNPUBLISHED` không hiển thị
    Và sự kiện được phát: EVT-15-09 (`content.unpublished`) khi gỡ
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-15-016 @FR-15-016 @S @âm
  Kịch bản: US-15-016 âm 1 · Phiên bản không có
    Biết trang có từ một phiên bản trở lên
    Khi phiên bản không có
    Thì hệ thống từ chối với ERR-15-001 (404)

  @US-15-017 @FR-15-017 @M
  Kịch bản: US-15-017 dương · Hiển thị trang nội dung
    Biết trang `PUBLISHED`
    Khi mở `/huong-dan`, `/huong-dan/{ma-trang}`, `/hoi-dap`, `/thong-bao`
    Thì hệ thống trả `200`; `html`, `toc[]`, `updatedAt`, `versionNo`

  @US-15-017 @FR-15-017 @M @âm
  Kịch bản: US-15-017 âm 1 · Trang không có hoặc ngoài tầm
    Biết trang `PUBLISHED`
    Khi trang không có hoặc ngoài tầm
    Thì hệ thống từ chối với ERR-15-001 (404)
    Và người dùng thấy thông báo "Không tìm thấy nội dung yêu cầu."

  @US-15-017 @FR-15-017 @M @âm
  Kịch bản: US-15-017 âm 2 · Ảnh hết hạn chữ ký
    Biết trang `PUBLISHED`
    Khi ảnh hết hạn chữ ký
    Thì tải lại trang tự cấp chữ ký mới; không hiện lỗi

  @US-15-018 @FR-15-018 @S
  Kịch bản: US-15-018 dương · Nhập nội dung từ kho Git
    Biết kho Git thuộc danh sách egress cho phép; có mã truy cập chỉ đọc
    Khi khai báo nguồn Git ở UI-15-21; đến lịch `15.git.sync-interval-minutes`; bấm "Đồng bộ ngay"
    Thì hệ thống trả `202`; `runId`, số tệp mới, đổi, bị bỏ qua
    Và các phiên bản nháp mới; mốc `commit` đã xử lý
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-15-018 @FR-15-018 @S @âm
  Kịch bản: US-15-018 âm 1 · Kho không đọc được
    Biết kho Git thuộc danh sách egress cho phép; có mã truy cập chỉ đọc
    Khi kho không đọc được
    Thì hệ thống từ chối với ERR-15-025 (502)
    Và người dùng thấy thông báo "Chưa kết nối được kho Git. Thử lại sau."

  # ---- EP-15-D · Tài khoản nhà phát triển

  @US-15-019 @FR-15-019 @M
  Kịch bản: US-15-019 dương · Đăng nhập SSO realm tenant
    Biết Keycloak khả dụng; tài khoản không bị khóa
    Khi bấm "Đăng nhập" hoặc mở trang cần đăng nhập
    Thì chuyển hướng `302`; cookie phiên; hồ sơ `GET /me` (API-15-041)
    Và phiên BFF tồn tại; `lastLoginAt` cập nhật
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-15-019 @FR-15-019 @M @âm
  Kịch bản: US-15-019 âm 1 · Keycloak lỗi
    Biết Keycloak khả dụng; tài khoản không bị khóa
    Khi Keycloak lỗi
    Thì hệ thống từ chối với ERR-15-020 (503)
    Và người dùng thấy thông báo "Dịch vụ định danh tạm thời chưa phản hồi. Thử lại sau."

  @US-15-019 @FR-15-019 @M @âm
  Kịch bản: US-15-019 âm 2 · Tài khoản `dh-dev` chưa xác minh hoặc chưa duyệt
    Biết Keycloak khả dụng; tài khoản không bị khóa
    Khi tài khoản `dh-dev` chưa xác minh hoặc chưa duyệt
    Thì hệ thống từ chối với ERR-15-011 (422)
    Và người dùng thấy thông báo "Tài khoản chưa được xác minh hoặc chưa được duyệt."

  @US-15-020 @FR-15-020 @M
  Kịch bản: US-15-020 dương · Tự đăng ký tài khoản dh-dev
    Biết `15.dev.signup-enabled = true`
    Khi bấm "Đăng ký tài khoản nhà thầu" ở UI-15-08
    Thì hệ thống trả `202`; `registrationId`, `status = PENDING_EMAIL`
    Và tài khoản `PENDING_EMAIL` rồi `PENDING_APPROVAL`; người dùng realm chưa bật
    Và sự kiện được phát: EVT-15-06 (`devaccount.registered`) khi xác minh thư xong
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-15-020 @FR-15-020 @M @âm
  Kịch bản: US-15-020 âm 1 · Thư đã đăng ký
    Biết `15.dev.signup-enabled = true`
    Khi thư đã đăng ký
    Thì hệ thống từ chối với ERR-15-012 (409)
    Và người dùng thấy thông báo "Thư điện tử này đã được đăng ký."

  @US-15-020 @FR-15-020 @M @âm
  Kịch bản: US-15-020 âm 2 · Mã sai hoặc hết hạn
    Biết `15.dev.signup-enabled = true`
    Khi mã sai hoặc hết hạn
    Thì hệ thống từ chối với ERR-15-013 (400)
    Và người dùng thấy thông báo "Mã xác minh không đúng hoặc đã hết hạn."

  @US-15-021 @FR-15-021 @M
  Kịch bản: US-15-021 dương · Hồ sơ cá nhân và phiên đăng nhập
    Biết đã đăng nhập
    Khi mở `/tai-khoan`
    Thì hệ thống trả `200`, `ETag`; hồ sơ; danh sách phiên
    Và hồ sơ mới; phiên đã thu hồi bị hủy
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-15-021 @FR-15-021 @M @âm
  Kịch bản: US-15-021 âm 1 · Hồ sơ bị sửa bởi nơi khác
    Biết đã đăng nhập
    Khi hồ sơ bị sửa bởi nơi khác
    Thì hệ thống từ chối với ERR-15-006 (412)
    Và người dùng thấy thông báo "Nội dung đã được người khác thay đổi. Tải lại rồi sửa tiếp."

  @US-15-021 @FR-15-021 @M @âm
  Kịch bản: US-15-021 âm 2 · Giá trị sai
    Biết đã đăng nhập
    Khi giá trị sai
    Thì hệ thống từ chối với ERR-15-003 (400)

  @US-15-022 @FR-15-022 @S
  Kịch bản: US-15-022 dương · Nhóm phát triển
    Biết đã đăng nhập, đã chấp nhận điều khoản
    Khi tạo nhóm ở UI-15-09 hoặc mời thành viên
    Thì hệ thống trả `201` hoặc `200`; nhóm, thành viên, lời mời
    Và quan hệ thành viên cập nhật; quyền trên ứng dụng của nhóm thay đổi theo
    Và sự kiện được phát: EVT-15-13 (`team.member-changed`)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-15-022 @FR-15-022 @S @âm
  Kịch bản: US-15-022 âm 1 · Mã nhóm trùng
    Biết đã đăng nhập, đã chấp nhận điều khoản
    Khi mã nhóm trùng
    Thì hệ thống từ chối với ERR-15-002 (409)
    Và người dùng thấy thông báo "Mã {mã} đã được dùng. Chọn mã khác."

  @US-15-023 @FR-15-023 @M
  Kịch bản: US-15-023 dương · Chấp nhận điều khoản sử dụng có phiên bản
    Biết có trang `TERMS` đang đăng (FR-15-015)
    Khi lần đầu tạo ứng dụng, thử API; hoặc khi điều khoản có phiên bản mới
    Thì hệ thống trả `200`; `termsVersion`, `acceptedAt`
    Và bản ghi chấp nhận gắn người dùng và phiên bản
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-15-023 @FR-15-023 @M @âm
  Kịch bản: US-15-023 âm 1 · Chưa chấp nhận khi thao tác
    Biết có trang `TERMS` đang đăng (FR-15-015)
    Khi chưa chấp nhận khi thao tác
    Thì hệ thống từ chối với ERR-15-010 (409)
    Và người dùng thấy thông báo "Cần chấp nhận điều khoản sử dụng hiện hành trước khi tiếp tục."

  @US-15-023 @FR-15-023 @M @âm
  Kịch bản: US-15-023 âm 2 · Phiên bản gửi lên không phải hiện hành
    Biết có trang `TERMS` đang đăng (FR-15-015)
    Khi phiên bản gửi lên không phải hiện hành
    Thì hệ thống từ chối với ERR-15-003 (400)

  @US-15-024 @FR-15-024 @S
  Kịch bản: US-15-024 dương · Vô hiệu hóa không hoạt động và xóa tài khoản
    Biết tài khoản `dh-dev`
    Khi tác vụ hằng ngày; người dùng bấm "Xóa tài khoản"
    Thì hệ thống trả `202`; `status = ERASED`
    Và sự kiện được phát: EVT-15-07 (`devaccount.state-changed`)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-15-024 @FR-15-024 @S @âm
  Kịch bản: US-15-024 âm 1 · Xác nhận xóa sai
    Biết tài khoản `dh-dev`
    Khi xác nhận xóa sai
    Thì hệ thống từ chối với ERR-15-003 (400)
    Và người dùng thấy thông báo "Dữ liệu chưa hợp lệ. Kiểm tra các trường được đánh dấu."

  # ---- EP-15-E · Ứng dụng sandbox và thông tin xác thực

  @US-15-025 @FR-15-025 @M
  Kịch bản: US-15-025 dương · Tạo ứng dụng sandbox
    Biết đã đăng nhập, tài khoản `ACTIVE`, đã chấp nhận điều khoản (FR-15-023)
    Khi bấm "+ Ứng dụng mới" ở UI-15-10
    Thì hệ thống trả `201`, `Location`, `ETag`; ứng dụng với `appCode`, `status`, `ownerType`
    Và ứng dụng `ACTIVE`, chưa có thông tin xác thực
    Và sự kiện được phát: EVT-15-01 (`app.created`)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-15-025 @FR-15-025 @M @âm
  Kịch bản: US-15-025 âm 1 · Mã đã dùng
    Biết đã đăng nhập, tài khoản `ACTIVE`, đã chấp nhận điều khoản (FR-15-023)
    Khi mã đã dùng
    Thì hệ thống từ chối với ERR-15-002 (409)
    Và người dùng thấy thông báo "Mã {mã} đã được dùng. Chọn mã khác."

  @US-15-025 @FR-15-025 @M @âm
  Kịch bản: US-15-025 âm 2 · Vượt giới hạn
    Biết đã đăng nhập, tài khoản `ACTIVE`, đã chấp nhận điều khoản (FR-15-023)
    Khi vượt giới hạn
    Thì hệ thống từ chối với ERR-15-015 (422)
    Và người dùng thấy thông báo "Đã đạt số ứng dụng tối đa ({n}). Lưu trữ ứng dụng không dùng để tạo mới."

  @US-15-026 @FR-15-026 @M
  Kịch bản: US-15-026 dương · Xem, sửa, lưu trữ, khôi phục ứng dụng
    Biết người dùng là thành viên của ứng dụng
    Khi mở `/ung-dung` hoặc `/ung-dung/{ma-ung-dung}`
    Thì hệ thống trả `200`, `ETag`; danh sách, chi tiết
    Và trạng thái ứng dụng cập nhật; lưu trữ kéo theo thu hồi thông tin xác thực
    Và sự kiện được phát: EVT-15-02 (`app.state-changed`)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-15-026 @FR-15-026 @M @âm
  Kịch bản: US-15-026 âm 1 · Không phải thành viên hoặc không đủ vai trò
    Biết người dùng là thành viên của ứng dụng
    Khi không phải thành viên hoặc không đủ vai trò
    Thì hệ thống từ chối với ERR-15-005 (403)
    Và người dùng thấy thông báo "Bạn không có quyền thực hiện thao tác này."

  @US-15-026 @FR-15-026 @M @âm
  Kịch bản: US-15-026 âm 2 · Ứng dụng không ở trạng thái cho phép
    Biết người dùng là thành viên của ứng dụng
    Khi ứng dụng không ở trạng thái cho phép
    Thì hệ thống từ chối với ERR-15-017 (409)
    Và người dùng thấy thông báo "Ứng dụng đang {trạng thái} nên không thực hiện được thao tác này."

  @US-15-027 @FR-15-027 @M
  Kịch bản: US-15-027 dương · Cấp thông tin xác thực client_credentials sandbox
    Biết ứng dụng `ACTIVE`; chưa đạt giới hạn thông tin xác thực
    Khi bấm "Cấp client_credentials" ở UI-15-13
    Thì hệ thống trả `201`, `Cache-Control: no-store`; `credentialId`, `clientId`, `clientSecret` (chỉ lần này), `tokenUrl`, `expiresAt`
    Và bản ghi `ACTIVE`; client tồn tại ở realm `dh-dev`
    Và sự kiện được phát: EVT-15-03 (`credential.issued`)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-15-027 @FR-15-027 @M @âm
  Kịch bản: US-15-027 âm 1 · Vượt giới hạn
    Biết ứng dụng `ACTIVE`; chưa đạt giới hạn thông tin xác thực
    Khi vượt giới hạn
    Thì hệ thống từ chối với ERR-15-016 (422)
    Và người dùng thấy thông báo "Ứng dụng đã đạt số thông tin xác thực tối đa ({n})."

  @US-15-027 @FR-15-027 @M @âm
  Kịch bản: US-15-027 âm 2 · Ứng dụng không `ACTIVE`
    Biết ứng dụng `ACTIVE`; chưa đạt giới hạn thông tin xác thực
    Khi ứng dụng không `ACTIVE`
    Thì hệ thống từ chối với ERR-15-017 (409)

  @US-15-028 @FR-15-028 @M
  Kịch bản: US-15-028 dương · Cấp API key sandbox
    Biết như FR-15-027
    Khi bấm "Cấp API key" ở UI-15-13
    Thì hệ thống trả `201`, `Cache-Control: no-store`; `credentialId`, `apiKey` (chỉ lần này), `prefix`, `expiresAt`
    Và bản ghi `ACTIVE`, chỉ lưu băm
    Và sự kiện được phát: EVT-15-03
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-15-028 @FR-15-028 @M @âm
  Kịch bản: US-15-028 âm 1 · Vượt giới hạn
    Biết như FR-15-027
    Khi vượt giới hạn
    Thì hệ thống từ chối với ERR-15-016 (422)

  @US-15-028 @FR-15-028 @M @âm
  Kịch bản: US-15-028 âm 2 · Ứng dụng không `ACTIVE`
    Biết như FR-15-027
    Khi ứng dụng không `ACTIVE`
    Thì hệ thống từ chối với ERR-15-017 (409)

  @US-15-029 @FR-15-029 @M
  Kịch bản: US-15-029 dương · Hiển thị bí mật đúng một lần
    Biết vừa cấp (FR-15-027, 028) hoặc xoay (FR-15-030)
    Khi phản hồi cấp phát tới trình duyệt
    Thì như FR-15-027, 028
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-15-029 @FR-15-029 @M @âm
  Kịch bản: US-15-029 âm 1 · Phát lại yêu cầu cấp
    Biết vừa cấp (FR-15-027, 028) hoặc xoay (FR-15-030)
    Khi phát lại yêu cầu cấp
    Thì hệ thống từ chối với ERR-15-019 (410)
    Và người dùng thấy thông báo "Bí mật chỉ hiện một lần và không xem lại được. Tạo thông tin xác thực mới nếu đã mất."

  @US-15-030 @FR-15-030 @M
  Kịch bản: US-15-030 dương · Xoay vòng thông tin xác thực
    Biết thông tin xác thực `ACTIVE`; ứng dụng `ACTIVE`
    Khi bấm "Xoay vòng" ở UI-15-13
    Thì hệ thống trả `201`; bản mới (kèm bí mật một lần), bản cũ `ROTATING` kèm `rotatingUntil`
    Và một bản `ACTIVE` mới, bản cũ `ROTATING`
    Và sự kiện được phát: EVT-15-04 (`credential.rotated`)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-15-030 @FR-15-030 @M @âm
  Kịch bản: US-15-030 âm 1 · Thông tin xác thực không `ACTIVE`
    Biết thông tin xác thực `ACTIVE`; ứng dụng `ACTIVE`
    Khi thông tin xác thực không `ACTIVE`
    Thì hệ thống từ chối với ERR-15-018 (409)
    Và người dùng thấy thông báo "Thông tin xác thực đang {trạng thái} nên không thực hiện được thao tác này."

  @US-15-030 @FR-15-030 @M @âm
  Kịch bản: US-15-030 âm 2 · Keycloak lỗi
    Biết thông tin xác thực `ACTIVE`; ứng dụng `ACTIVE`
    Khi Keycloak lỗi
    Thì hệ thống từ chối với ERR-15-020 (503)

  @US-15-031 @FR-15-031 @M
  Kịch bản: US-15-031 dương · Thu hồi và hết hạn thông tin xác thực
    Biết thông tin xác thực `ACTIVE` hoặc `ROTATING`
    Khi bấm "Thu hồi"; lưu trữ ứng dụng; tác vụ hằng giờ khi tới `expiresAt`
    Thì hệ thống trả `200`; thông tin xác thực với `status`
    Và bản ghi `REVOKED` hoặc `EXPIRED`
    Và sự kiện được phát: EVT-15-05 (`credential.revoked`, gồm cả hết hạn)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-15-031 @FR-15-031 @M @âm
  Kịch bản: US-15-031 âm 1 · Đã thu hồi hoặc hết hạn
    Biết thông tin xác thực `ACTIVE` hoặc `ROTATING`
    Khi đã thu hồi hoặc hết hạn
    Thì hệ thống từ chối với ERR-15-018 (409)
    Và người dùng thấy thông báo "Thông tin xác thực đang {trạng thái} nên không thực hiện được thao tác này."

  @US-15-031 @FR-15-031 @M @âm
  Kịch bản: US-15-031 âm 2 · Keycloak lỗi khi thu hồi
    Biết thông tin xác thực `ACTIVE` hoặc `ROTATING`
    Khi Keycloak lỗi khi thu hồi
    Thì hệ thống từ chối với ERR-15-020 (503)

  @US-15-032 @FR-15-032 @M
  Kịch bản: US-15-032 dương · Xem tham chiếu thông tin xác thực production
    Biết ứng dụng có `systemCode`; HTTT thuộc tổ chức của người dùng
    Khi mở tab "Xác thực" của ứng dụng ở UI-15-13
    Thì hệ thống trả `200`; `items[]` (`clientId`, `method`, `certThumbprintPrefix`, `expiresAt`, `status`, `lastUsedAt`)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-15-032 @FR-15-032 @M @âm
  Kịch bản: US-15-032 âm 1 · Không thuộc tổ chức hoặc nhà thầu
    Biết ứng dụng có `systemCode`; HTTT thuộc tổ chức của người dùng
    Khi không thuộc tổ chức hoặc nhà thầu
    Thì hệ thống từ chối với ERR-15-005 (403)
    Và người dùng thấy thông báo "Bạn không có quyền thực hiện thao tác này."

  @US-15-032 @FR-15-032 @M @âm
  Kịch bản: US-15-032 âm 2 · PH-01 lỗi
    Biết ứng dụng có `systemCode`; HTTT thuộc tổ chức của người dùng
    Khi PH-01 lỗi
    Thì hệ thống từ chối với ERR-15-031 (502)
    Và người dùng thấy thông báo "Chưa kết nối được dịch vụ kết nạp. Thử lại sau."

  @US-15-033 @FR-15-033 @S
  Kịch bản: US-15-033 dương · Giao ứng dụng cho thành viên
    Biết ứng dụng `ACTIVE` hoặc `SUSPENDED`
    Khi mở tab "Thành viên" ở UI-15-12
    Thì hệ thống trả `200`; danh sách thành viên
    Và quan hệ thành viên cập nhật
    Và sự kiện được phát: EVT-15-13
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-15-033 @FR-15-033 @S @âm
  Kịch bản: US-15-033 âm 1 · Đã là thành viên
    Biết ứng dụng `ACTIVE` hoặc `SUSPENDED`
    Khi đã là thành viên
    Thì hệ thống từ chối với ERR-15-027 (409)
    Và người dùng thấy thông báo "Người này đã là thành viên hoặc đã có lời mời."

  # ---- EP-15-F · Sandbox và thử API

  @US-15-034 @FR-15-034 @M
  Kịch bản: US-15-034 dương · Khai báo sandbox của dịch vụ
    Biết API có phiên bản `PUBLISHED` hoặc `DEPRECATED` ở bản sao danh mục
    Khi mở UI-15-23 của API
    Thì hệ thống trả `200`, `ETag`; hồ sơ sandbox với `mode`, `lastHealthCheck`
    Và hồ sơ sandbox được lưu
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-15-034 @FR-15-034 @M @âm
  Kịch bản: US-15-034 âm 1 · Backend ngoài danh sách cho phép
    Biết API có phiên bản `PUBLISHED` hoặc `DEPRECATED` ở bản sao danh mục
    Khi backend ngoài danh sách cho phép
    Thì hệ thống từ chối với ERR-15-119 (422)
    Và người dùng thấy thông báo "Địa chỉ hệ thống thử không nằm trong danh sách cho phép."

  @US-15-034 @FR-15-034 @M @âm
  Kịch bản: US-15-034 âm 2 · Thiếu cấu hình cho chế độ
    Biết API có phiên bản `PUBLISHED` hoặc `DEPRECATED` ở bản sao danh mục
    Khi thiếu cấu hình cho chế độ
    Thì hệ thống từ chối với ERR-15-120 (409)
    Và người dùng thấy thông báo "Dịch vụ thiếu cấu hình cho chế độ {chế độ}."

  @US-15-035 @FR-15-035 @M
  Kịch bản: US-15-035 dương · Thử API trên sandbox
    Biết đã chấp nhận điều khoản; API có sandbox khác `OFF`; ứng dụng `ACTIVE`
    Khi bấm "Gửi" ở khung thử UI-15-06
    Thì hệ thống trả `200`; `tryId`, `status`, `latencyMs`, `headers`, `body` (đã che), `mode`, `warnings[]`
    Và bản ghi lượt thử; bộ đếm hạn mức cập nhật
    Và sự kiện được phát: EVT-15-11 (`try.executed`)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-15-035 @FR-15-035 @M @âm
  Kịch bản: US-15-035 âm 1 · Gateway sandbox lỗi
    Biết đã chấp nhận điều khoản; API có sandbox khác `OFF`; ứng dụng `ACTIVE`
    Khi gateway sandbox lỗi
    Thì hệ thống từ chối với ERR-15-111 (503)
    Và người dùng thấy thông báo "Cổng thử đang bảo trì. Thử lại sau."

  @US-15-035 @FR-15-035 @M @âm
  Kịch bản: US-15-035 âm 2 · Backend thử lỗi, quá hạn
    Biết đã chấp nhận điều khoản; API có sandbox khác `OFF`; ứng dụng `ACTIVE`
    Khi backend thử lỗi, quá hạn
    Thì hệ thống từ chối với ERR-15-109, ERR-15-108

  @US-15-036 @FR-15-036 @M
  Kịch bản: US-15-036 dương · Chế độ sandbox MOCK
    Biết hồ sơ sandbox `mode = MOCK`
    Khi lời gọi tới tuyến sandbox của thao tác ở chế độ `MOCK`
    Thì phản hồi mô phỏng, tiêu đề `X-DH-Sandbox: mock`
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-15-036 @FR-15-036 @M @âm
  Kịch bản: US-15-036 âm 1 · Không sinh được phản hồi
    Biết hồ sơ sandbox `mode = MOCK`
    Khi không sinh được phản hồi
    Thì hệ thống từ chối với ERR-15-110 (422)
    Và người dùng thấy thông báo "Chưa sinh được phản hồi mẫu. Dịch vụ thiếu ví dụ hoặc lược đồ."

  @US-15-036 @FR-15-036 @M @âm
  Kịch bản: US-15-036 âm 2 · Yêu cầu không khớp đặc tả
    Biết hồ sơ sandbox `mode = MOCK`
    Khi yêu cầu không khớp đặc tả
    Thì hệ thống từ chối với ERR-15-107 (422)
    Và người dùng thấy thông báo "Yêu cầu không khớp đặc tả: {chi tiết}."

  @US-15-037 @FR-15-037 @M
  Kịch bản: US-15-037 dương · Chế độ sandbox BACKEND
    Biết hồ sơ sandbox `mode = BACKEND`, backend sống
    Khi lời gọi tới tuyến sandbox của thao tác ở chế độ `BACKEND`
    Thì phản hồi của backend (đã che), tiêu đề `X-DH-Sandbox: backend`
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-15-037 @FR-15-037 @M @âm
  Kịch bản: US-15-037 âm 1 · Backend quá hạn
    Biết hồ sơ sandbox `mode = BACKEND`, backend sống
    Khi backend quá hạn
    Thì hệ thống từ chối với ERR-15-108 (504)
    Và người dùng thấy thông báo "Hệ thống thử không phản hồi trong {n} giây."

  @US-15-037 @FR-15-037 @M @âm
  Kịch bản: US-15-037 âm 2 · Backend không với tới
    Biết hồ sơ sandbox `mode = BACKEND`, backend sống
    Khi backend không với tới
    Thì hệ thống từ chối với ERR-15-109 (502)
    Và người dùng thấy thông báo "Hệ thống thử trả lỗi."

  @US-15-038 @FR-15-038 @M
  Kịch bản: US-15-038 dương · Dữ liệu mẫu tổng hợp và chặn dữ liệu cá nhân thật
    Biết yêu cầu thử đã qua kiểm tra khớp đặc tả
    Khi người dùng bấm "Điền dữ liệu mẫu" hoặc "Gửi"
    Thì cảnh báo `warnings[]` hoặc lỗi `422` kèm tên trường (không kèm giá trị)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-15-038 @FR-15-038 @M @âm
  Kịch bản: US-15-038 âm 1 · Có dữ liệu cá nhân thật
    Biết yêu cầu thử đã qua kiểm tra khớp đặc tả
    Khi có dữ liệu cá nhân thật
    Thì hệ thống từ chối với ERR-15-106 (422)
    Và người dùng thấy thông báo "Nội dung có vẻ chứa dữ liệu cá nhân thật. Chỉ dùng dữ liệu giả."

  @US-15-039 @FR-15-039 @M
  Kịch bản: US-15-039 dương · Hạn mức sandbox
    Biết người dùng đã đăng nhập với vai trò nhà phát triển
    Khi mọi lượt thử và mọi lời gọi tới tuyến sandbox
    Thì hệ thống trả `429` hoặc `413`; `Retry-After`; `GET /try/quota` trả số còn lại
    Và bộ đếm cập nhật

  @US-15-039 @FR-15-039 @M @âm
  Kịch bản: US-15-039 âm 1 · Vượt hạn mức người
    Biết người dùng đã đăng nhập với vai trò nhà phát triển
    Khi vượt hạn mức người
    Thì hệ thống từ chối với ERR-15-103 (429)
    Và người dùng thấy thông báo "Bạn đã vượt hạn mức thử mỗi phút. Thử lại sau {n} giây."

  @US-15-039 @FR-15-039 @M @âm
  Kịch bản: US-15-039 âm 2 · Vượt hạn mức ứng dụng
    Biết người dùng đã đăng nhập với vai trò nhà phát triển
    Khi vượt hạn mức ứng dụng
    Thì hệ thống từ chối với ERR-15-104 (429)
    Và người dùng thấy thông báo "Ứng dụng đã vượt hạn mức thử trong ngày."

  @US-15-040 @FR-15-040 @S
  Kịch bản: US-15-040 dương · Lịch sử thử và bộ sưu tập yêu cầu
    Biết đã đăng nhập
    Khi mở UI-15-14
    Thì hệ thống trả `200`; `items[]`, bộ sưu tập
    Và lịch sử quá hạn bị xóa tự động

  @US-15-040 @FR-15-040 @S @âm
  Kịch bản: US-15-040 âm 1 · Bộ sưu tập không phải của mình
    Biết đã đăng nhập
    Khi bộ sưu tập không phải của mình
    Thì hệ thống từ chối với ERR-15-001 (404)

  @US-15-041 @FR-15-041 @C
  Kịch bản: US-15-041 dương · Xuất Postman, Bruno, HTTP
    Biết có bộ sưu tập hoặc đang xem một API
    Khi bấm "Xuất" ở UI-15-14 hoặc trang tài liệu
    Thì hệ thống trả `200`; tệp với `Content-Disposition`

  @US-15-041 @FR-15-041 @C @âm
  Kịch bản: US-15-041 âm 1 · Định dạng không hỗ trợ
    Biết có bộ sưu tập hoặc đang xem một API
    Khi định dạng không hỗ trợ
    Thì hệ thống từ chối với ERR-15-003 (400)

  @US-15-042 @FR-15-042 @M
  Kịch bản: US-15-042 dương · Bật, tắt thử production theo dịch vụ
    Biết `15.try.prod-enabled = true` của tenant; API `PUBLISHED`; `dataClass` là `PUBLIC` hoặc `INTERNAL`
    Khi đề xuất ở UI-15-23; duyệt ở "Việc của tôi"
    Thì hệ thống trả `200` hoặc `202` khi chờ duyệt; trạng thái `OFF`, `PENDING`, `ENABLED`, `validUntil`
    Và bản ghi cho phép thử cập nhật
    Và sự kiện được phát: EVT-15-10 (`try.production-state-changed`)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-15-042 @FR-15-042 @M @âm
  Kịch bản: US-15-042 âm 1 · API `RESTRICTED`, `SENSITIVE` hoặc tenant tắt
    Biết `15.try.prod-enabled = true` của tenant; API `PUBLISHED`; `dataClass` là `PUBLIC` hoặc `INTERNAL`
    Khi API `RESTRICTED`, `SENSITIVE` hoặc tenant tắt
    Thì hệ thống từ chối với ERR-15-040 (422)
    Và người dùng thấy thông báo "Dịch vụ này chưa đủ điều kiện cho thao tác này."

  @US-15-042 @FR-15-042 @M @âm
  Kịch bản: US-15-042 âm 2 · Người duyệt là người đề xuất
    Biết `15.try.prod-enabled = true` của tenant; API `PUBLISHED`; `dataClass` là `PUBLIC` hoặc `INTERNAL`
    Khi người duyệt là người đề xuất
    Thì hệ thống từ chối với ERR-15-023 (403)
    Và người dùng thấy thông báo "Người duyệt phải khác người soạn và người gửi duyệt."

  @US-15-043 @FR-15-043 @M
  Kịch bản: US-15-043 dương · Thử API trên production
    Biết dịch vụ `ENABLED` ở FR-15-042; người dùng là cán bộ CQNN (không phải `dh-dev`)
    Khi người dùng chọn môi trường "Production" ở khung thử và xác nhận
    Thì hệ thống trả `200`; như FR-15-035, thêm `environment = PRODUCTION`
    Và bản ghi kiểm toán lượt thử; không lưu thân phản hồi
    Và sự kiện được phát: EVT-15-11
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-15-043 @FR-15-043 @M @âm
  Kịch bản: US-15-043 âm 1 · Dịch vụ chưa bật
    Biết dịch vụ `ENABLED` ở FR-15-042; người dùng là cán bộ CQNN (không phải `dh-dev`)
    Khi dịch vụ chưa bật
    Thì hệ thống từ chối với ERR-15-112 (403)
    Và người dùng thấy thông báo "Dịch vụ này chưa bật thử trên môi trường thật."

  @US-15-043 @FR-15-043 @M @âm
  Kịch bản: US-15-043 âm 2 · Không có đăng ký sử dụng
    Biết dịch vụ `ENABLED` ở FR-15-042; người dùng là cán bộ CQNN (không phải `dh-dev`)
    Khi không có đăng ký sử dụng
    Thì hệ thống từ chối với ERR-15-113 (403)
    Và người dùng thấy thông báo "Tổ chức của bạn chưa có đăng ký sử dụng đang hoạt động cho dịch vụ này."

  # ---- EP-15-G · Đăng ký sử dụng và điểm vào nghiệp vụ

  @US-15-044 @FR-15-044 @M
  Kịch bản: US-15-044 dương · Gửi đăng ký sử dụng API production
    Biết đã đăng nhập bằng tài khoản cán bộ; đơn vị có HTTT `ACTIVE` ở PH-01
    Khi bấm "Đăng ký sử dụng" ở UI-15-04 hoặc UI-15-15
    Thì hệ thống trả `201` hoặc mã của PH-02; đăng ký với `status`, `reviewRequestId`, `warnings[]`
    Và đăng ký tồn tại ở PH-02; cổng không giữ bản sao
    Và sự kiện được phát: EVT-02-09 do PH-02 phát; cổng không phát
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-15-044 @FR-15-044 @M @âm
  Kịch bản: US-15-044 âm 1 · Không có quyền đăng ký hoặc không có HTTT hoạt động
    Biết đã đăng nhập bằng tài khoản cán bộ; đơn vị có HTTT `ACTIVE` ở PH-01
    Khi không có quyền đăng ký hoặc không có HTTT hoạt động
    Thì hệ thống từ chối với ERR-15-032 (422)
    Và người dùng thấy thông báo "Chỉ cán bộ đầu mối có hệ thống thông tin đang hoạt động mới thực hiện được thao tác này."

  @US-15-044 @FR-15-044 @M @âm
  Kịch bản: US-15-044 âm 2 · PH-02 không khả dụng
    Biết đã đăng nhập bằng tài khoản cán bộ; đơn vị có HTTT `ACTIVE` ở PH-01
    Khi PH-02 không khả dụng
    Thì hệ thống từ chối với ERR-15-030 (502)
    Và người dùng thấy thông báo "Chưa kết nối được dịch vụ danh mục."

  @US-15-045 @FR-15-045 @M
  Kịch bản: US-15-045 dương · Theo dõi đăng ký sử dụng
    Biết có đăng ký của HTTT thuộc tổ chức người dùng
    Khi mở `/dang-ky-su-dung`
    Thì hệ thống trả `200`; `items[]`, chi tiết dòng thời gian
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-15-045 @FR-15-045 @M @âm
  Kịch bản: US-15-045 âm 1 · Đăng ký ngoài tổ chức
    Biết có đăng ký của HTTT thuộc tổ chức người dùng
    Khi đăng ký ngoài tổ chức
    Thì hệ thống từ chối với ERR-15-001 (404)

  @US-15-045 @FR-15-045 @M @âm
  Kịch bản: US-15-045 âm 2 · PH-02 lỗi
    Biết có đăng ký của HTTT thuộc tổ chức người dùng
    Khi PH-02 lỗi
    Thì hệ thống từ chối với ERR-15-030 (502)
    Và người dùng thấy thông báo "Chưa kết nối được dịch vụ danh mục."

  @US-15-046 @FR-15-046 @M
  Kịch bản: US-15-046 dương · Điểm vào kết nạp HTTT (F-01)
    Biết đã đăng nhập bằng tài khoản cán bộ
    Khi mở `/ket-nap`
    Thì hệ thống trả `201`; `applicationId`, `status`
    Và hồ sơ ở PH-01
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-15-046 @FR-15-046 @M @âm
  Kịch bản: US-15-046 âm 1 · PH-01 không khả dụng
    Biết đã đăng nhập bằng tài khoản cán bộ
    Khi PH-01 không khả dụng
    Thì hệ thống từ chối với ERR-15-031 (502)
    Và người dùng thấy thông báo "Chưa kết nối được dịch vụ kết nạp. Thử lại sau."

  @US-15-046 @FR-15-046 @M @âm
  Kịch bản: US-15-046 âm 2 · Không phải đầu mối
    Biết đã đăng nhập bằng tài khoản cán bộ
    Khi không phải đầu mối
    Thì hệ thống từ chối với ERR-15-032 (422)
    Và người dùng thấy thông báo "Chỉ cán bộ đầu mối có hệ thống thông tin đang hoạt động mới thực hiện được thao tác này."

  @US-15-047 @FR-15-047 @M
  Kịch bản: US-15-047 dương · Điểm vào công bố API (F-02)
    Biết người dùng là chủ dịch vụ của tổ chức; HTTT cung cấp `ACTIVE`
    Khi mở `/cong-bo/moi`
    Thì hệ thống trả `202`; `publicationId`, `status`, `lintResults[]`
    Và phiên bản ở PH-02
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-15-047 @FR-15-047 @M @âm
  Kịch bản: US-15-047 âm 1 · Không phải chủ dịch vụ
    Biết người dùng là chủ dịch vụ của tổ chức; HTTT cung cấp `ACTIVE`
    Khi không phải chủ dịch vụ
    Thì hệ thống từ chối với ERR-15-005 (403)
    Và người dùng thấy thông báo "Bạn không có quyền thực hiện thao tác này."

  @US-15-047 @FR-15-047 @M @âm
  Kịch bản: US-15-047 âm 2 · Đặc tả không hợp lệ
    Biết người dùng là chủ dịch vụ của tổ chức; HTTT cung cấp `ACTIVE`
    Khi đặc tả không hợp lệ
    Thì lỗi từng dòng của PH-02 hiển thị tại chỗ

  # ---- EP-15-H · Theo dõi của nhà phát triển

  @US-15-048 @FR-15-048 @S
  Kịch bản: US-15-048 dương · Bảng điều khiển cá nhân
    Biết đã đăng nhập
    Khi mở `/tong-quan`
    Thì hệ thống trả `200`; các thẻ `apps`, `credentialsExpiring`, `tries`, `subscriptions`, `followed`, `inbox`, `tickets`

  @US-15-048 @FR-15-048 @S @âm
  Kịch bản: US-15-048 âm 1 · Nguồn PH-02 hoặc PH-13 lỗi
    Biết đã đăng nhập
    Khi nguồn PH-02 hoặc PH-13 lỗi
    Thì hệ thống từ chối với ERR-15-030, ERR-15-039
    Và người dùng thấy thông báo "Chưa tải được."

  @US-15-049 @FR-15-049 @M
  Kịch bản: US-15-049 dương · Thống kê lượt gọi và lỗi theo ứng dụng
    Biết ứng dụng có hoạt động sandbox; PH-13 khả dụng
    Khi mở tab "Thống kê" ở UI-15-12
    Thì hệ thống trả `200`; `series[]`, `totals`, `byApi[]`

  @US-15-049 @FR-15-049 @M @âm
  Kịch bản: US-15-049 âm 1 · PH-13 lỗi
    Biết ứng dụng có hoạt động sandbox; PH-13 khả dụng
    Khi PH-13 lỗi
    Thì hệ thống từ chối với ERR-15-039 (502)
    Và người dùng thấy thông báo "Chưa tải được nhật ký hoặc số liệu. Thử lại sau."

  @US-15-049 @FR-15-049 @M @âm
  Kịch bản: US-15-049 âm 2 · Không phải thành viên
    Biết ứng dụng có hoạt động sandbox; PH-13 khả dụng
    Khi không phải thành viên
    Thì hệ thống từ chối với ERR-15-005 (403)
    Và người dùng thấy thông báo "Bạn không có quyền thực hiện thao tác này."

  @US-15-050 @FR-15-050 @S
  Kịch bản: US-15-050 dương · Nhật ký gọi của ứng dụng đã che dữ liệu
    Biết ứng dụng có lượt gọi trong 30 ngày
    Khi mở tab "Nhật ký" ở UI-15-12
    Thì hệ thống trả `200`; `items[]`, `page`, `size`; chi tiết bản ghi

  @US-15-050 @FR-15-050 @S @âm
  Kịch bản: US-15-050 âm 1 · PH-13 lỗi
    Biết ứng dụng có lượt gọi trong 30 ngày
    Khi PH-13 lỗi
    Thì hệ thống từ chối với ERR-15-039 (502)
    Và người dùng thấy thông báo "Chưa tải được nhật ký hoặc số liệu. Thử lại sau."

  @US-15-051 @FR-15-051 @M
  Kịch bản: US-15-051 dương · Đăng ký nhận thông báo thay đổi API
    Biết API nằm trong tập người dùng được thấy
    Khi bấm "Theo dõi" ở UI-15-04; hoặc EVT-02-12 tới
    Thì hệ thống trả `200`; cấu hình theo dõi
    Và bản ghi theo dõi cập nhật

  @US-15-051 @FR-15-051 @M @âm
  Kịch bản: US-15-051 âm 1 · API ngoài tầm
    Biết API nằm trong tập người dùng được thấy
    Khi API ngoài tầm
    Thì hệ thống từ chối với ERR-15-001 (404)

  @US-15-051 @FR-15-051 @M @âm
  Kịch bản: US-15-051 âm 2 · Tắt loại bắt buộc
    Biết API nằm trong tập người dùng được thấy
    Khi tắt loại bắt buộc
    Thì hệ thống từ chối với ERR-15-003 (400)
    Và người dùng thấy thông báo "Dữ liệu chưa hợp lệ. Kiểm tra các trường được đánh dấu."

  @US-15-052 @FR-15-052 @M
  Kịch bản: US-15-052 dương · Hộp thông báo
    Biết đã đăng nhập
    Khi bấm biểu tượng chuông; mở `/tai-khoan/thong-bao`
    Thì hệ thống trả `200`; `items[]`, `unreadCount`
    Và trạng thái đã đọc cập nhật

  @US-15-052 @FR-15-052 @M @âm
  Kịch bản: US-15-052 âm 1 · Thông báo không phải của mình
    Biết đã đăng nhập
    Khi thông báo không phải của mình
    Thì hệ thống từ chối với ERR-15-001 (404)

  # ---- EP-15-I · Hỗ trợ và phản hồi

  @US-15-053 @FR-15-053 @C
  Kịch bản: US-15-053 dương · Hỏi đáp, báo lỗi tài liệu, đánh giá trang
    Biết API hoặc trang nằm trong tầm nhìn của người dùng
    Khi bấm "Hỏi đáp", "Báo lỗi tài liệu" hoặc nút hữu ích ở UI-15-04, UI-15-07
    Thì hệ thống trả `201`; bài hỏi, phiếu hoặc đánh giá
    Và bài, phiếu hoặc đánh giá được lưu
    Và sự kiện được phát: EVT-15-12 khi tạo phiếu `DOC_ERROR`

  @US-15-053 @FR-15-053 @C @âm
  Kịch bản: US-15-053 âm 1 · Vượt tần suất
    Biết API hoặc trang nằm trong tầm nhìn của người dùng
    Khi vượt tần suất
    Thì hệ thống từ chối với ERR-15-037 (429)
    Và người dùng thấy thông báo "Bạn gửi quá nhiều. Thử lại sau {n} phút."

  @US-15-054 @FR-15-054 @M
  Kịch bản: US-15-054 dương · Gửi yêu cầu hỗ trợ cho chủ dịch vụ
    Biết đã đăng nhập
    Khi bấm "Hỗ trợ" hoặc "Nhờ đầu mối đăng ký"
    Thì hệ thống trả `201`; `ticketCode`, `status`
    Và phiếu `OPEN`
    Và sự kiện được phát: EVT-15-12 (`support.ticket-opened`)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-15-054 @FR-15-054 @M @âm
  Kịch bản: US-15-054 âm 1 · Phiếu đã đóng
    Biết đã đăng nhập
    Khi phiếu đã đóng
    Thì hệ thống từ chối với ERR-15-029 (409)
    Và người dùng thấy thông báo "Phiếu đã đóng. Tạo phiếu mới nếu cần."

  @US-15-054 @FR-15-054 @M @âm
  Kịch bản: US-15-054 âm 2 · Gửi quá nhiều
    Biết đã đăng nhập
    Khi gửi quá nhiều
    Thì hệ thống từ chối với ERR-15-037 (429)

  @US-15-055 @FR-15-055 @S
  Kịch bản: US-15-055 dương · Xử lý yêu cầu hỗ trợ
    Biết có phiếu gửi tới người xử lý
    Khi mở hộp xử lý ở UI-15-28
    Thì hệ thống trả `200`; phiếu cập nhật
    Và trạng thái phiếu cập nhật
    Và sự kiện được phát: EVT-15-12 khi đổi trạng thái (cùng chủ đề với lúc mở)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-15-055 @FR-15-055 @S @âm
  Kịch bản: US-15-055 âm 1 · Phiếu đã đóng
    Biết có phiếu gửi tới người xử lý
    Khi phiếu đã đóng
    Thì hệ thống từ chối với ERR-15-029 (409)

  # ---- EP-15-J · Quản trị cổng

  @US-15-056 @FR-15-056 @M
  Kịch bản: US-15-056 dương · Cấu hình nhận diện cổng theo tenant
    Biết đăng nhập khu quản trị có MFA
    Khi mở `/quan-tri-cong/nhan-dien`
    Thì hệ thống trả `200`, `ETag`; cấu hình
    Và cấu hình mới có hiệu lực sau ≤ 60 giây
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-15-056 @FR-15-056 @M @âm
  Kịch bản: US-15-056 âm 1 · Logo sai định dạng, quá cỡ
    Biết đăng nhập khu quản trị có MFA
    Khi logo sai định dạng, quá cỡ
    Thì hệ thống từ chối với ERR-15-033 (422)
    Và người dùng thấy thông báo "Thông tin nhận diện chưa hợp lệ."

  @US-15-056 @FR-15-056 @M @âm
  Kịch bản: US-15-056 âm 2 · Liên kết không HTTPS
    Biết đăng nhập khu quản trị có MFA
    Khi liên kết không HTTPS
    Thì hệ thống từ chối với ERR-15-033 (422)
    Và người dùng thấy thông báo "Thông tin nhận diện chưa hợp lệ."

  @US-15-057 @FR-15-057 @M
  Kịch bản: US-15-057 dương · Tham số cổng
    Biết đăng nhập khu quản trị có MFA
    Khi mở `/quan-tri-cong/tham-so`
    Thì hệ thống trả `200`; danh sách tham số
    Và giá trị mới hiệu lực trong 60 giây
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-15-057 @FR-15-057 @M @âm
  Kịch bản: US-15-057 âm 1 · Giá trị ngoài miền
    Biết đăng nhập khu quản trị có MFA
    Khi giá trị ngoài miền
    Thì hệ thống từ chối với ERR-15-034 (422)
    Và người dùng thấy thông báo "Giá trị của {khóa} phải trong khoảng {tối thiểu} đến {tối đa}."

  @US-15-057 @FR-15-057 @M @âm
  Kịch bản: US-15-057 âm 2 · Vượt trần của nền tảng
    Biết đăng nhập khu quản trị có MFA
    Khi vượt trần của nền tảng
    Thì hệ thống từ chối với ERR-15-034 (422)
    Và người dùng thấy thông báo "Giá trị của {khóa} phải trong khoảng {tối thiểu} đến {tối đa}."

  @US-15-058 @FR-15-058 @M
  Kịch bản: US-15-058 dương · Duyệt tài khoản dh-dev
    Biết tài khoản `PENDING_APPROVAL`
    Khi mở yêu cầu duyệt `DEV_ACCOUNT` ở "Việc của tôi" hoặc UI-15-24
    Thì hệ thống trả `200`; tài khoản với `status`
    Và tài khoản `ACTIVE` hoặc `REJECTED`
    Và sự kiện được phát: EVT-15-07 (`devaccount.state-changed`)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-15-058 @FR-15-058 @M @âm
  Kịch bản: US-15-058 âm 1 · Tài khoản không ở `PENDING_APPROVAL`
    Biết tài khoản `PENDING_APPROVAL`
    Khi tài khoản không ở `PENDING_APPROVAL`
    Thì hệ thống từ chối với ERR-15-022 (409)
    Và người dùng thấy thông báo "Đối tượng đang {trạng thái} nên không thực hiện được thao tác này."

  @US-15-058 @FR-15-058 @M @âm
  Kịch bản: US-15-058 âm 2 · Thiếu lý do khi từ chối
    Biết tài khoản `PENDING_APPROVAL`
    Khi thiếu lý do khi từ chối
    Thì hệ thống từ chối với ERR-15-003 (400)
    Và người dùng thấy thông báo "Dữ liệu chưa hợp lệ. Kiểm tra các trường được đánh dấu."

  @US-15-059 @FR-15-059 @M
  Kịch bản: US-15-059 dương · Khóa, mở khóa tài khoản và ứng dụng
    Biết tài khoản `ACTIVE` hoặc ứng dụng `ACTIVE`
    Khi bấm "Khóa" ở UI-15-24; hoặc nhận cảnh báo lạm dụng từ PH-13
    Thì hệ thống trả `200`; đối tượng với `status`
    Và đối tượng `LOCKED` hoặc `SUSPENDED`
    Và sự kiện được phát: EVT-15-02; EVT-15-07
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-15-059 @FR-15-059 @M @âm
  Kịch bản: US-15-059 âm 1 · Đối tượng không ở trạng thái cho phép
    Biết tài khoản `ACTIVE` hoặc ứng dụng `ACTIVE`
    Khi đối tượng không ở trạng thái cho phép
    Thì hệ thống từ chối với ERR-15-017, ERR-15-022 (409)
    Và người dùng thấy thông báo "Ứng dụng đang {trạng thái} nên không thực hiện được thao tác này."

  @US-15-059 @FR-15-059 @M @âm
  Kịch bản: US-15-059 âm 2 · Thiếu lý do
    Biết tài khoản `ACTIVE` hoặc ứng dụng `ACTIVE`
    Khi thiếu lý do
    Thì hệ thống từ chối với ERR-15-003 (400)

  @US-15-060 @FR-15-060 @M
  Kịch bản: US-15-060 dương · Nhật ký truy cập, thử và báo cáo sử dụng cổng
    Biết có bản ghi kiểm toán của cổng ở PH-13
    Khi mở `/quan-tri-cong/nhat-ky`
    Thì hệ thống trả `200`; `items[]`, `page`, `size`; `202` với xuất nền; báo cáo `summary`
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-15-060 @FR-15-060 @M @âm
  Kịch bản: US-15-060 âm 1 · PH-13 lỗi
    Biết có bản ghi kiểm toán của cổng ở PH-13
    Khi PH-13 lỗi
    Thì hệ thống từ chối với ERR-15-039 (502)
    Và người dùng thấy thông báo "Chưa tải được nhật ký hoặc số liệu. Thử lại sau."

  @US-15-060 @FR-15-060 @M @âm
  Kịch bản: US-15-060 âm 2 · Khoảng thời gian quá 12 tháng cho truy vấn trực tuyến
    Biết có bản ghi kiểm toán của cổng ở PH-13
    Khi khoảng thời gian quá 12 tháng cho truy vấn trực tuyến
    Thì hệ thống từ chối với ERR-15-003 (400)
    Và người dùng thấy thông báo "Dữ liệu chưa hợp lệ. Kiểm tra các trường được đánh dấu."

  @US-15-061 @FR-15-061 @S
  Kịch bản: US-15-061 dương · Đồng bộ lại và đối soát danh mục với PH-02
    Biết PH-02 khả dụng
    Khi bấm "Đồng bộ lại" hoặc "Đối soát" ở UI-15-27; lịch hằng tuần
    Thì hệ thống trả `202`; `runId`; báo cáo đối soát `missing[]`, `extra[]`, `stale[]`
    Và `SyncRun` hoàn tất
    Và sự kiện được phát: EVT-15-14
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-15-061 @FR-15-061 @S @âm
  Kịch bản: US-15-061 âm 1 · Đang đồng bộ
    Biết PH-02 khả dụng
    Khi đang đồng bộ
    Thì hệ thống từ chối với ERR-15-035 (409)
    Và người dùng thấy thông báo "Đang có lần chạy khác. Đợi hoàn tất rồi thử lại."

  @US-15-062 @FR-15-062 @S
  Kịch bản: US-15-062 dương · Di trú nội dung portal hệ cũ
    Biết có gói xuất nội dung từ portal Gravitee; PH-02 đã nhập danh mục API từ APIM cũ
    Khi tải gói ở UI-15-27
    Thì hệ thống trả `202`; `migrationId`, báo cáo xem trước, kết quả
    Và các phiên bản `DRAFT`; không trang nào được đăng tự động
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-15-062 @FR-15-062 @S @âm
  Kịch bản: US-15-062 âm 1 · Gói không hợp lệ
    Biết có gói xuất nội dung từ portal Gravitee; PH-02 đã nhập danh mục API từ APIM cũ
    Khi gói không hợp lệ
    Thì hệ thống từ chối với ERR-15-026 (422)
    Và người dùng thấy thông báo "Gói di trú sai cấu trúc hoặc có tệp không được phép."
