#!/usr/bin/env python3
"""Sinh openapi-portal.yaml (OpenAPI 3.1) cho PH-15 từ bảng §9.3 của FRS (mã, phương thức, đường dẫn, FR) và bảng bổ sung X ở dưới.
Chạy: python3 gen_openapi.py   (từ thư mục tools; ghi ../openapi-portal.yaml). Các tệp nhóm public/portal/try/admin/internal do gop tách bằng --tach."""
import os, re, sys, yaml
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import schemas15 as S

HERE = os.path.dirname(os.path.abspath(__file__))
FRS = os.path.join(HERE, '..', '..', '..', '..', '02-yeu-cau', 'frs', 'D02-03-PH15-frs-cong-nha-phat-trien.md')
frs = open(FRS, encoding='utf-8').read()
ROWS = re.findall(r'^\| (API-15-\d{3}) \| (GET|POST|PUT|PATCH|DELETE) \| `([^`]+)` \| ([0-9, ]+) \|$', frs, re.M)
ERRS = {c: (int(h), t.strip()) for c, h, t in re.findall(r'^\| (ERR-15-\d{3}) \| (\d{3}) \| ([^|]+?) \|', frs, re.M)}
assert len(ROWS) == 137, len(ROWS)

# ---- tham số
PATHP = {'ApiCode': ('apiCode', '#ApiCode'), 'VersionNo': ('versionNo', '#SemVer'), 'TopicCode': ('topicCode', '#TopicCode'), 'PageCode': ('pageCode', '#PageCode'),
         'PageVersionNo': ('versionNo', {'type': 'integer', 'minimum': 1}), 'SourceId': ('sourceId', '#Uuid'), 'SessionId': ('sessionId', '#Uuid'), 'TeamCode': ('teamCode', '#TeamCode'),
         'InvitationId': ('invitationId', '#Uuid'), 'UserId': ('userId', '#Uuid'), 'AppCode': ('appCode', '#AppCode'), 'CredentialId': ('credentialId', '#Uuid'),
         'TryId': ('tryId', 's'), 'CollectionId': ('collectionId', '#Uuid'), 'SubscriptionId': ('subscriptionId', '#Uuid'), 'ApplicationId': ('applicationId', '#Uuid'),
         'PublicationId': ('publicationId', '#Uuid'), 'MessageId': ('messageId', '#Uuid'), 'TicketCode': ('ticketCode', '#TicketCode'), 'MigrationId': ('migrationId', '#Uuid'),
         'LogId': ('logId', 's')}
PATH_FOR = {}  # tên tham số đường dẫn -> khóa PATHP (theo thứ tự xuất hiện không đủ, nên map theo tên)
for k, (n, _) in PATHP.items():
    PATH_FOR.setdefault(n, k)
# 'versionNo' xuất hiện ở hai nghĩa: SemVer (đặc tả) và số nguyên (trang); chọn theo đường dẫn
QUERY = {  # tên -> (lược đồ, mô tả)
    'q': ('s', 'Từ khóa tìm kiếm tiếng Việt, 1…200 ký tự.'),
    'trang': ({'type': 'integer', 'minimum': 1, 'default': 1}, 'Số trang, từ 1.'),
    'co': ({'type': 'integer', 'enum': [10, 20, 50, 100], 'default': 20}, 'Cỡ trang.'),
    'sap-xep': ('s', 'Khóa sắp xếp, tiền tố `-` là giảm dần.'),
    'phien-ban': ('#SemVer', 'Phiên bản API; mặc định phiên bản `PUBLISHED` mới nhất.'),
    'linh-vuc': ('s', 'Lọc theo lĩnh vực.'), 'chu-quan': ('s', 'Lọc theo cơ quan chủ quản.'),
    'xac-thuc': ('#AuthKind', 'Lọc theo kiểu xác thực.'), 'loai': ('s', 'Lọc theo loại.'),
    'trang-thai': ('s', 'Lọc theo trạng thái.'), 'da-ngung': ('b', 'Gồm cả dịch vụ đã ngừng.'),
    'tu': ('ts', 'Từ thời điểm (RFC 3339).'), 'den': ('ts', 'Đến thời điểm (RFC 3339).'),
    'khoang': (['24h', '7d', '30d'], 'Khoảng thống kê.'), 'lang': ('#Lang', 'Ngôn ngữ nội dung.'),
    'api': ('#ApiCode', 'Lọc theo mã API.'), 'ung-dung': ('#AppCode', 'Lọc theo mã ứng dụng.'), 'ket-qua': ('s', 'Lọc theo kết quả.'),
    'he-thong': ('s', 'Lọc theo mã HTTT.'), 'trace': ('#TraceId', 'Lọc theo traceId.'), 'da-doc': ('b', 'Lọc theo đã đọc.'),
    'hanh-dong': ('s', 'Hành động kiểm toán (Phụ lục A.8).'), 'nguoi-dung': ('s', 'Tên đăng nhập người thực hiện.'),
    'thao-tac': ('s', 'Neo theo `operationId`.'), 'format': ('s', 'Định dạng.'), 'lang_s': (['curl', 'java', 'python', 'javascript', 'csharp', 'go'], 'Ngôn ngữ mẫu mã.'),
    'env': ('#TryEnv', 'Môi trường mẫu.'), 'authKind': ('#AuthKind', 'Kiểu xác thực của mẫu.'), 'operationId': ('s', '`operationId` trong đặc tả.'),
    'base': ('#SemVer', 'Phiên bản cơ sở để so sánh.'), 'target': ('#SemVer', 'Phiên bản đích; mặc định phiên bản mới nhất.'),
    'appCode': ('#AppCode', 'Mã ứng dụng.'), 'versionNo': ('#SemVer', 'Phiên bản API.'), 'apiCode': ('#ApiCode', 'Mã API.'),
    'collectionId': ('#Uuid', 'Mã bộ sưu tập.'),
}

# ---- bảng bổ sung: id -> (tóm tắt, quyền, tham số, thân yêu cầu, thành công, lỗi, mô tả, cờ)
# quyền: pub | login | mesh | PERM-...; tham số: tên đường dẫn đã có trong PATHP/QUERY, hoặc 'name!' (bắt buộc)
# thân yêu cầu: None | 'Schema' | ('Schema', [ví dụ...]) | ('multipart', 'Schema'); thành công: (mã, 'Schema', [ví dụ...] | None)
X = {}


def x(n, summary, perm, params='', req=None, ok=(200, None), errs='', desc='', **fl):
    X[n] = dict(summary=summary, perm=perm, params=params.split() if params else [], req=req, ok=ok, errs=errs.split(), desc=desc, fl=fl)


FIL = 'q linh-vuc chu-quan xac-thuc loai trang-thai da-ngung sap-xep trang co'
x(1, 'Trang chủ cổng cho khách ẩn danh', 'pub', '', None, (200, 'HomeView', ['HomeViewPublic']), '008 007', 'Chỉ trả nội dung `PUBLIC`; `Cache-Control: public, max-age=300`; tắt khi tham số công khai của tenant tắt (FR-15-057).')
x(2, 'Trang chủ cổng cho người dùng đã đăng nhập', 'login', '', None, (200, 'HomeView'), '008', 'Kèm `myWork` (ứng dụng, lượt thử, thông báo chưa đọc, thông tin xác thực sắp hết hạn).')
x(3, 'Danh mục dịch vụ công khai', 'pub', FIL, None, (200, 'CatalogItemPage'), '003 007', 'Chỉ mục `visibility=PUBLIC`; dữ liệu rút gọn; hỗ trợ `If-None-Match` và `304`.')
x(4, 'Chi tiết dịch vụ công khai', 'pub', 'ApiCode phien-ban', None, (200, 'CatalogItemDetail', ['CatalogItemDetailPublic']), '001 038 007', 'Mục ngoài tầm nhìn trả `404` như không tồn tại (BR-15-002).')
x(5, 'Duyệt, lọc, sắp xếp danh mục dịch vụ', 'login', FIL, None, (200, 'CatalogItemPage'), '003 008', 'Áp mức hiển thị theo hạng người xem (`TENANT`, `NATIONAL`, `PUBLIC`); `facets` ở API-15-006.')
x(6, 'Giá trị bộ lọc (facets) của danh mục', 'login', 'q linh-vuc chu-quan xac-thuc loai', None, (200, 'CatalogFacets'), '003 008', '')
x(7, 'Chi tiết dịch vụ: phiên bản, gói, SLA', 'login', 'ApiCode phien-ban', None, (200, 'CatalogItemDetail'), '001 038 008', 'Ngoài tầm nhìn: `404`. Phiên bản `RETIRED` trả `410` (ERR-15-038).')
x(8, 'Đường dẫn sử dụng của dịch vụ', 'login', 'ApiCode phien-ban', None, (200, 'UsageInfo'), '001 038', 'Địa chỉ gọi, địa chỉ lấy token, scope, mẫu (LGC-APIM-017); lấy từ API-02-006 của PH-02.')
x(9, 'Trạng thái đồng bộ danh mục', 'PERM-15-portal-admin', '', None, (200, 'SyncStatus'), '008 009', 'Trạng thái `IDLE`, `RUNNING`, `FAILED`, `STALE` và độ trễ so với PH-02.')
x(10, 'Tìm kiếm toàn văn công khai', 'pub', 'q! loai trang co', None, (200, 'SearchResultPage'), '003 007', 'Chỉ trả mục công khai; kết quả được kiểm lại hiển thị lần hai (BR-15-002).')
x(11, 'Tìm kiếm toàn văn theo quyền xem', 'login', 'q! loai trang co', None, (200, 'SearchResultPage'), '003 007', 'OpenSearch, dự phòng PostgreSQL FTS với `unaccent` (QĐ-15-04).')
x(12, 'Gợi ý tìm kiếm', 'login', 'q!', None, (200, 'Suggestions'), '003 007', 'Tối đa 10 gợi ý; chịu bộ lọc hiển thị như tìm kiếm.')
x(13, 'Danh sách dịch vụ sự kiện (topic)', 'login', 'q linh-vuc chu-quan trang co', None, (200, 'TopicPage'), '003', 'Topic của PH-10 theo mức hiển thị; không có dữ liệu sự kiện.')
x(14, 'Chi tiết dịch vụ sự kiện', 'login', 'TopicCode', None, (200, 'TopicDetail'), '001 009', '')
x(15, 'Danh sách phiên bản API', 'login', 'ApiCode', None, (200, 'VersionList'), '001', 'Gồm phiên bản `DEPRECATED` kèm `sunsetAt`.')
x(16, 'Tải đặc tả của một phiên bản', 'login', 'ApiCode VersionNo format', None, (200, 'SpecDocument', None, 'yaml'), '001 003 009 038', '`format=yaml` trả `application/yaml`; ghi kiểm toán `DOWNLOAD_SPEC`.')
x(17, 'Các thao tác của đặc tả OpenAPI', 'login', 'ApiCode VersionNo thao-tac trang co', None, (200, 'OperationPage'), '009 038', 'Phân trang theo thao tác để dựng 300 thao tác dưới 2 giây (NFR-15-003).')
x(18, 'Kênh, thông điệp của dịch vụ sự kiện (AsyncAPI)', 'login', 'TopicCode phien-ban', None, (200, 'TopicEvents'), '001 009', '')
x(19, 'Mẫu mã gọi API', 'login', 'ApiCode operationId! lang_s env authKind phien-ban', None, (200, 'SampleList'), '001 003', 'Bí mật luôn là chỗ giữ `<ACCESS_TOKEN>`, `<API_KEY>` (BR-15-011).')
x(20, 'So sánh hai phiên bản API', 'login', 'ApiCode base! target', None, (200, 'SpecDiff'), '001 003 038', 'Phân loại thay đổi phá vỡ và không phá vỡ (`breaking`).')
x(21, 'Changelog và lộ trình ngừng dùng', 'login', 'ApiCode phien-ban', None, (200, 'Changelog'), '001', 'Ghép từ EVT-02-12 và lộ trình của phiên bản `DEPRECATED`.')
x(22, 'Danh sách trang nội dung (soạn thảo)', 'PERM-15-content-write', 'q loai trang-thai lang trang co sap-xep', None, (200, 'PageList'), '003', '')
x(23, 'Tạo trang nội dung Markdown', 'PERM-15-content-write', '', 'PageInput', (201, 'PageDetail', ['PageDetailNew']), '002 003 021 024', 'Markdown qua bộ lọc (BR-15-013); trang ≤ 200 KB; trả `ETag`.')
x(24, 'Chi tiết trang nội dung (soạn thảo)', 'PERM-15-content-write', 'PageCode', None, (200, 'PageDetail'), '001', '')
x(25, 'Sửa trang nội dung', 'PERM-15-content-write', 'PageCode', 'PageEdit', (200, 'PageDetail'), '003 006 021 024', 'Sửa trang đang đăng tạo phiên bản nháp mới; bản đang đăng vẫn hiển thị.')
x(26, 'Gửi duyệt trang nội dung', 'PERM-15-content-write', 'PageCode', 'PageSubmit', (200, 'PageDetail'), '003 022', 'Ghi `submittedBy` để kiểm bốn mắt (BR-15-012).')
x(27, 'Duyệt và đăng trang', 'PERM-15-content-publish', 'PageCode', 'PageDecision', (200, 'PageDetail'), '003 022 023', 'Người duyệt khác người soạn, người sửa và người gửi; phát EVT-15-08.')
x(28, 'Từ chối duyệt trang', 'PERM-15-content-publish', 'PageCode', ('PageDecision', ['PageDecisionReject']), (200, 'PageDetail'), '003 022 023', '`comment` bắt buộc khi từ chối.')
x(29, 'Gỡ đăng trang', 'PERM-15-content-publish', 'PageCode', 'PageUnpublish', (200, 'PageDetail'), '001 022', 'Phát EVT-15-09.')
x(30, 'Danh sách phiên bản của trang', 'PERM-15-content-write', 'PageCode', None, (200, 'PageVersionList'), '001', '')
x(31, 'Chi tiết một phiên bản trang', 'PERM-15-content-write', 'PageCode PageVersionNo', None, (200, 'PageVersion'), '001', '')
x(32, 'Khôi phục phiên bản trang thành bản nháp', 'PERM-15-content-write', 'PageCode PageVersionNo', None, (200, 'PageDetail'), '001 022', 'Tạo phiên bản `DRAFT` mới từ nội dung phiên bản cũ; không đăng tự động.')
x(33, 'Tải ảnh đính kèm cho trang', 'PERM-15-content-write', '', ('multipart', 'AttachmentUpload'), (201, 'AttachmentUploaded'), '003 024', 'PNG, JPEG, WebP ≤ 5 MB, không SVG; quét ClamAV, kiểm kiểu theo nội dung (SEC-45).')
x(34, 'Danh sách trang công khai', 'pub', 'q loai lang trang co', None, (200, 'PageList'), '003 007', 'Chỉ trang `audience=PUBLIC`, trạng thái `PUBLISHED`.')
x(35, 'Xem trang công khai', 'pub', 'PageCode lang', None, (200, 'PublicPage'), '001 007', 'Trả HTML đã làm sạch kèm mục lục.')
x(36, 'Danh sách trang theo quyền xem', 'login', 'q loai lang trang co', None, (200, 'PageList'), '003', 'Gồm trang `LOGGED_IN`, và `TENANT` nếu cùng tenant.')
x(37, 'Xem trang theo quyền xem', 'login', 'PageCode lang', None, (200, 'PublicPage'), '001', '')
x(38, 'Danh sách nguồn Git nhập nội dung', 'PERM-15-content-write', '', None, (200, 'GitSourceList'), '025', '')
x(39, 'Khai báo nguồn Git', 'PERM-15-content-write', '', 'GitSourceInput', (201, 'GitSource'), '003 025 026', 'Chỉ HTTPS thuộc allowlist egress; mã truy cập ghi một chiều vào OpenBao.')
x(40, 'Đồng bộ nội dung từ kho Git', 'PERM-15-content-write', 'SourceId', None, (202, 'RunAccepted', ['GitSyncAccepted']), '001 025 026 035', 'Tạo `DRAFT` cho tệp đổi, không bao giờ tự đăng (BR-15-012).')
x(41, 'Hồ sơ người dùng hiện tại', 'login', '', None, (200, 'Me'), '011 014', 'Kèm `viewerClass` và `termsUpToDate`.')
x(42, 'Sửa hồ sơ cá nhân', 'login', '', 'MeUpdate', (200, 'Me'), '003 006', '')
x(43, 'Danh sách phiên đăng nhập', 'login', '', None, (200, 'SessionList'), '', '')
x(44, 'Đăng xuất một phiên', 'login', 'SessionId', None, (204, None), '001', '')
x(45, 'Tự đăng ký tài khoản dh-dev', 'pub', '', 'DevRegistrationInput', (202, 'RegistrationAccepted'), '003 012 037', 'Không có mật khẩu trong thân: người dùng đặt ở Keycloak sau khi xác minh thư; có xác minh chống tự động.')
x(46, 'Xác minh thư điện tử đăng ký', 'pub', '', 'VerifyEmailInput', (200, 'RegistrationState'), '003 013 037', 'Trong 24 giờ; thành công chuyển `PENDING_APPROVAL`; phát EVT-15-06.')
x(47, 'Điều khoản sử dụng hiện hành', 'login', '', None, (200, 'Terms'), '', '')
x(48, 'Chấp nhận điều khoản sử dụng', 'login', '', 'TermsAcceptInput', (200, 'TermsAcceptance'), '003 010', '')
x(49, 'Danh sách nhóm phát triển', 'PERM-15-app', '', None, (200, 'TeamList'), '', '')
x(50, 'Tạo nhóm phát triển', 'PERM-15-app', '', 'TeamInput', (201, 'Team'), '002 003', 'Người tạo là `OWNER` đầu tiên.')
x(51, 'Mời thành viên vào nhóm', 'PERM-15-app', 'TeamCode', 'InvitationInput', (201, 'Invitation'), '003 027', 'Chỉ `OWNER` của nhóm; lời mời hết hạn sau 7 ngày (giả định).')
x(52, 'Phản hồi lời mời vào nhóm', 'login', 'InvitationId', 'InvitationRespond', (200, 'Invitation', ['InvitationAccepted']), '001 027', '')
x(53, 'Gỡ thành viên khỏi nhóm', 'PERM-15-app', 'TeamCode UserId', None, (204, None), '001 028', 'Không gỡ được chủ sở hữu duy nhất (ERR-15-028).')
x(54, 'Yêu cầu xóa tài khoản', 'login', '', 'ErasureInput', (202, 'ErasureAccepted'), '003 028', 'Xóa bằng ẩn danh hóa (BR-15-029); yêu cầu xác thực lại.')
x(55, 'Danh sách ứng dụng của tôi', 'PERM-15-app', 'q trang-thai trang co', None, (200, 'AppPage'), '003', '')
x(56, 'Tạo ứng dụng sandbox', 'PERM-15-app', '', 'AppInput', (201, 'AppDetail'), '002 003 010 015 032', 'Trả `Location`, `ETag`; chủ `TEAM` cần là thành viên nhóm.')
x(57, 'Chi tiết ứng dụng', 'PERM-15-app', 'AppCode', None, (200, 'AppDetail'), '001', '')
x(58, 'Sửa ứng dụng', 'PERM-15-app', 'AppCode', 'AppPatch', (200, 'AppDetail'), '003 006 017', '`appCode` bất biến (BR-15-007).')
x(59, 'Lưu trữ ứng dụng', 'PERM-15-app', 'AppCode', None, (200, 'AppDetail', ['AppDetailArchived']), '006 017', 'Thu hồi mọi thông tin xác thực; khôi phục được trong 30 ngày; phát EVT-15-02, EVT-15-05.')
x(60, 'Khôi phục ứng dụng đã lưu trữ', 'PERM-15-app', 'AppCode', None, (200, 'AppDetail'), '015 017', 'Không khôi phục bí mật; người dùng cấp mới.')
x(61, 'Danh sách thông tin xác thực của ứng dụng', 'PERM-15-app', 'AppCode', None, (200, 'CredentialList'), '001', 'Không có bí mật, chỉ tiền tố.')
x(62, 'Cấp thông tin xác thực sandbox (client_credentials hoặc API key)', 'PERM-15-app', 'AppCode', ('CredentialIssueInput', ['CredentialIssueInput', 'CredentialIssueInputKey']),
  (201, 'CredentialIssued', ['CredentialIssued', 'CredentialIssuedKey']), '003 016 017 019 020', '`Cache-Control: no-store`; bí mật hiện đúng một lần (FR-15-029); `Idempotency-Key` lặp trả bản ghi không có bí mật (ERR-15-019).')
x(63, 'Xoay vòng thông tin xác thực', 'PERM-15-app', 'AppCode CredentialId', 'RotateInput', (201, 'RotateResult'), '003 016 018 020', 'Bản cũ `ROTATING` tối đa 72 giờ; bản mới trả bí mật một lần.')
x(64, 'Thu hồi thông tin xác thực', 'PERM-15-app', 'AppCode CredentialId', 'RevokeInput', (200, 'Credential', ['CredentialRevoked']), '018 020', 'Hiệu lực ≤ 5 giây ở `forward-auth` (NFR-15-007); phát EVT-15-05.')
x(65, 'Tham chiếu thông tin xác thực production của ứng dụng', 'PERM-15-app', 'AppCode', None, (200, 'ProdCredentialRefList'), '001 031', 'Chỉ đọc từ PH-01, không bao giờ có bí mật (BR-15-015).')
x(66, 'Danh sách thành viên ứng dụng', 'PERM-15-app', 'AppCode', None, (200, 'MemberList'), '001', '')
x(67, 'Giao hoặc đổi vai trò thành viên ứng dụng', 'PERM-15-app', 'AppCode UserId', 'MemberInput', (200, 'Member'), '003 027 028', 'Chỉ `OWNER` của ứng dụng; phát EVT-15-13.')
x(68, 'Gỡ thành viên khỏi ứng dụng', 'PERM-15-app', 'AppCode UserId', None, (204, None), '001 028', '')
x(69, 'Xem hồ sơ sandbox của dịch vụ', 'PERM-15-portal-admin', 'ApiCode phien-ban', None, (200, 'SandboxProfile'), '001', 'Do TA hoặc đầu mối SV của tổ chức chủ dịch vụ (○) xem và khai báo.')
x(70, 'Khai báo hồ sơ sandbox của dịch vụ', 'PERM-15-portal-admin', 'ApiCode', 'SandboxProfileInput', (200, 'SandboxProfile', ['SandboxProfileBackend']), '003 006 040 110 119 120', 'Kiểm backend thử theo allowlist egress, HTTPS (BR-15-018).')
x(71, 'Kiểm tra yêu cầu thử trước khi gửi', 'PERM-15-try', '', 'TryRequestInput', (200, 'TryValidation'), '003 105 106 107 121', 'Không gọi hệ thống nào; trả cảnh báo dữ liệu cá nhân giống thật (PII-15).')
x(72, 'Thử API (sandbox hoặc production)', 'PERM-15-try', '', ('TryRequestInput', ['TryRequestInput', 'TryRequestMock', 'TryRequestProd']),
  (200, 'TryResponse', ['TryResponse', 'TryResponseProd']), '010 102 103 104 105 106 107 108 109 110 111 112 113 114 115 116 117 118 119 120 121 122 123',
  'Thứ tự kiểm tra cố định (SDD §4.10); production chỉ `GET`, `HEAD`, `dataClass` `PUBLIC` hoặc `INTERNAL`, ghi kiểm toán đồng bộ trước khi gọi (BR-15-023); thân không vào lịch sử (BR-15-024).')
x(73, 'Xem một lượt thử', 'PERM-15-try', 'TryId', None, (200, 'TryRecord'), '001', 'Chỉ siêu dữ liệu, không có thân.')
x(74, 'Hạn mức thử còn lại', 'PERM-15-try', 'appCode', None, (200, 'TryQuota'), '005', '')
x(75, 'Lịch sử thử của tôi', 'PERM-15-try', 'tu den api ung-dung ket-qua trang co', None, (200, 'TryRecordPage'), '003', '')
x(76, 'Xóa lịch sử thử của tôi', 'PERM-15-try', 'tu den', None, (200, 'HistoryDeleted'), '003', 'Xóa mềm.')
x(77, 'Danh sách bộ sưu tập yêu cầu', 'PERM-15-try', '', None, (200, 'CollectionList'), '', '')
x(78, 'Tạo bộ sưu tập yêu cầu', 'PERM-15-try', '', 'CollectionInput', (201, 'Collection'), '003', '≤ 50 bộ, mỗi bộ ≤ 100 yêu cầu, mỗi yêu cầu ≤ 16 KB.')
x(79, 'Sửa bộ sưu tập yêu cầu', 'PERM-15-try', 'CollectionId', 'CollectionInput', (200, 'Collection'), '001 003 006', '')
x(80, 'Xóa bộ sưu tập yêu cầu', 'PERM-15-try', 'CollectionId', None, (204, None), '001 006', '')
x(81, 'Xuất bộ sưu tập (Postman, Bruno, HTTP)', 'PERM-15-try', 'CollectionId format! apiCode versionNo', None, (200, 'ExportFile'), '001 003', 'Không chứa bí mật; tiêu đề xác thực là chỗ giữ.')
x(82, 'forward-auth: kiểm tra ứng dụng và hạn mức của lời gọi sandbox', 'mesh', 'X-Forwarded-Method! X-Forwarded-Uri! X-Forwarded-Host! X-DH-Try-Id', None, (200, 'AuthorizeDecision'), '001 004 005 101 102 103 104 111 122',
  'Chỉ APISIX gọi, danh tính SPIFFE, cổng 8081; thời gian chờ 300 ms, `allow_degradation: false`; trả `X-DH-App`, `X-DH-Tenant`, `X-DH-Sandbox-Mode`, `X-DH-Profile-Ver`, `X-RateLimit-*`.')
x(83, 'Danh sách trạng thái thử production theo dịch vụ', 'PERM-15-portal-admin', 'trang-thai trang co', None, (200, 'TryProdPage'), '003', '')
x(84, 'Đề xuất bật thử production cho dịch vụ', 'PERM-15-portal-admin', 'ApiCode', 'TryProdInput', (202, 'TryProdItem', ['TryProdPending']), '003 006 023 040', 'Chờ người khác duyệt (BR-15-021); `validDays` ≤ `15.try.prod-max-days`.')
x(85, 'Duyệt bật thử production', 'PERM-15-portal-admin', 'ApiCode', 'TryProdDecision', (200, 'TryProdItem'), '006 023 040', 'Người duyệt khác người đề xuất; phát EVT-15-10.')
x(86, 'Tắt thử production', 'PERM-15-portal-admin', 'ApiCode', 'TryProdDisable', (200, 'TryProdItem', ['TryProdOff']), '003 006', 'Chỉ cần một người có quyền; hiệu lực ngay.')
x(87, 'Gửi đăng ký sử dụng API production', 'PERM-02-subscribe', '', 'SubscriptionInput', (201, 'Subscription'), '003 030 032', 'Ủy thác PH-02 (FR-02-046) theo danh tính người dùng; cổng không tự duyệt (BR-15-014).')
x(88, 'Danh sách đăng ký sử dụng của tổ chức', 'PERM-02-subscribe', 'trang-thai api he-thong trang co', None, (200, 'SubscriptionPage'), '030', 'Đọc từ PH-02.')
x(89, 'Chi tiết và dòng thời gian đăng ký sử dụng', 'PERM-02-subscribe', 'SubscriptionId', None, (200, 'SubscriptionDetail'), '001 030', '')
x(90, 'Hủy đăng ký sử dụng', 'PERM-02-subscribe', 'SubscriptionId', 'SubscriptionCancelInput', (200, 'Subscription', ['SubscriptionCancelled']), '001 030', 'Ủy thác PH-02; chỉ khi đăng ký còn hủy được theo PH-02.')
x(91, 'Gửi hồ sơ kết nạp HTTT (F-01)', 'PERM-01-submit', '', 'OnboardingInput', (201, 'Onboarding'), '003 031 032', 'Ủy thác PH-01; lược đồ biểu mẫu nạp từ PH-01.')
x(92, 'Danh sách hồ sơ kết nạp của tôi', 'PERM-01-submit', 'trang co', None, (200, 'OnboardingPage'), '031', '')
x(93, 'Chi tiết hồ sơ kết nạp', 'PERM-01-submit', 'ApplicationId', None, (200, 'Onboarding'), '001 031', '')
x(94, 'Gửi công bố API (F-02)', 'PERM-02-create', '', 'PublicationInput', (202, 'Publication'), '003 005 030', 'Ủy thác PH-02 đăng ký API; trả kết quả lint đặc tả.')
x(95, 'Danh sách công bố API của tôi', 'PERM-02-create', 'trang co', None, (200, 'PublicationPage'), '030', '')
x(96, 'Chi tiết công bố API', 'PERM-02-create', 'PublicationId', None, (200, 'Publication'), '001 030', '')
x(97, 'Bảng điều khiển cá nhân', 'login', '', None, (200, 'Dashboard'), '030 039', 'Thẻ lỗi một phần trả `partial[]` thay vì hỏng cả trang.')
x(98, 'Thống kê lượt gọi và lỗi của ứng dụng', 'PERM-15-app', 'AppCode khoang api', None, (200, 'AppStats'), '005 039', 'Đọc PH-13 (`metrics:portal-read`); bộ lọc `app_code` cố định ở máy chủ.')
x(99, 'Nhật ký gọi của ứng dụng (đã che dữ liệu)', 'PERM-15-app', 'AppCode tu den api trang-thai trace trang co', None, (200, 'AppLogPage'), '005 039', 'Không có thân, chỉ giữ 30 ngày (BR-15-024).')
x(100, 'Chi tiết một bản ghi nhật ký gọi', 'PERM-15-app', 'AppCode LogId', None, (200, 'AppLog'), '001 005 039', '')
x(101, 'Danh sách theo dõi thông báo thay đổi API', 'login', '', None, (200, 'NotifSubList'), '', '')
x(102, 'Đăng ký hoặc sửa theo dõi thông báo của một API', 'login', 'ApiCode', 'NotifSubInput', (200, 'NotifSub'), '001 003', 'Loại bắt buộc (BR-15-027) không tắt được.')
x(103, 'Bỏ theo dõi thông báo của một API', 'login', 'ApiCode', None, (204, None), '001', '')
x(104, 'Hộp thông báo', 'login', 'loai da-doc trang co', None, (200, 'InboxPage'), '003', 'Giữ 90 ngày.')
x(105, 'Đánh dấu một thông báo đã đọc', 'login', 'MessageId', None, (200, 'InboxMessage'), '001', '')
x(106, 'Đánh dấu tất cả thông báo đã đọc', 'login', '', None, (200, 'ReadAllResult'), '', '')
x(107, 'Danh sách hỏi đáp của một API', 'login', 'ApiCode trang co', None, (200, 'QuestionPage'), '001 003', '')
x(108, 'Gửi câu hỏi hoặc báo lỗi tài liệu của một API', 'login', 'ApiCode', 'QuestionInput', (201, 'Question'), '001 003 037', 'Văn bản thuần ≤ 2.000 ký tự; chuyển đầu mối chủ dịch vụ.')
x(109, 'Gửi đánh giá trang hoặc phản hồi', 'login', '', 'FeedbackInput', (201, 'FeedbackAck'), '003 037', '')
x(110, 'Tạo phiếu hỗ trợ', 'login', '', 'TicketInput', (201, 'Ticket'), '001 003 037', 'Phiếu ≤ 4.000 ký tự; phát EVT-15-12.')
x(111, 'Danh sách phiếu hỗ trợ của tôi', 'login', 'trang-thai loai trang co', None, (200, 'TicketPage'), '003', '')
x(112, 'Chi tiết phiếu hỗ trợ', 'login', 'TicketCode', None, (200, 'TicketDetail'), '001', 'Tin nhắn nội bộ của người xử lý bị ẩn với người gửi.')
x(113, 'Nhắn thêm vào phiếu hỗ trợ', 'login', 'TicketCode', 'TicketMessageInput', (201, 'TicketMessage'), '001 003 029 037', 'Phiếu `CLOSED` trả `409` (ERR-15-029).')
x(114, 'Danh sách phiếu hỗ trợ cần xử lý', 'PERM-15-support', 'trang-thai api trang co', None, (200, 'TicketPage'), '003', 'SV (○) chỉ thấy phiếu của API tổ chức mình.')
x(115, 'Chuyển trạng thái, trả lời phiếu hỗ trợ', 'PERM-15-support', 'TicketCode', 'TicketTransition', (200, 'Ticket', ['TicketAnswered']), '001 003 029', 'Trả lời hiện cho người gửi; ghi chú nội bộ thì không.')
x(116, 'Xem cấu hình nhận diện cổng', 'PERM-15-portal-admin', '', None, (200, 'Branding'), '', '')
x(117, 'Sửa cấu hình nhận diện cổng', 'PERM-15-portal-admin', '', 'BrandingInput', (200, 'Branding'), '003 006 033', 'Ghi kiểm toán `CHANGE_SETTING`.')
x(118, 'Tải logo cổng', 'PERM-15-portal-admin', '', ('multipart', 'LogoUpload'), (201, 'LogoUploaded'), '024 033', 'PNG hoặc WebP ≤ 512 KB, từ 128 px.')
x(119, 'Xem tham số cổng', 'PERM-15-portal-admin', '', None, (200, 'Settings'), '', '')
x(120, 'Sửa tham số cổng', 'PERM-15-portal-admin', '', 'SettingsInput', (200, 'Settings'), '003 006 034', 'Không vượt trần do PA đặt; ghi kiểm toán `CHANGE_SETTING`.')
x(121, 'Danh sách tài khoản dh-dev', 'PERM-15-dev-approve', 'q trang-thai trang co', None, (200, 'DevAccountPage'), '003', '')
x(122, 'Duyệt tài khoản dh-dev', 'PERM-15-dev-approve', 'UserId', 'ApproveInput', (200, 'DevAccount', ['DevAccountApproved']), '003 020 022', 'Cấp `tenantGrants`; tạo người dùng ở realm `dh-dev`; phát EVT-15-07.')
x(123, 'Từ chối tài khoản dh-dev', 'PERM-15-dev-approve', 'UserId', 'RejectInput', (200, 'DevAccount', ['DevAccountRejected']), '003 022', '')
x(124, 'Khóa tài khoản dh-dev', 'PERM-15-dev-approve', 'UserId', 'LockInput', (200, 'DevAccount', ['DevAccountLocked']), '003 022', 'Ghi kiểm toán `LOCK_ACCOUNT`; phiên bị thu hồi.')
x(125, 'Mở khóa tài khoản dh-dev', 'PERM-15-dev-approve', 'UserId', 'UnlockInput', (200, 'DevAccount', ['DevAccountUnlocked']), '003 022', 'Ghi kiểm toán `UNLOCK_ACCOUNT`.')
x(126, 'Tạm khóa ứng dụng sandbox', 'PERM-15-dev-approve', 'AppCode', 'LockInput', (200, 'AppDetail', ['AppDetailSuspended']), '003 017 022', 'Ứng dụng không thử được, không cấp thông tin xác thực mới; phát EVT-15-02.')
x(127, 'Mở khóa ứng dụng sandbox', 'PERM-15-dev-approve', 'AppCode', 'UnlockInput', (200, 'AppDetail'), '003 017', '')
x(128, 'Nhật ký truy cập và thử API của cổng', 'PERM-15-audit-read', 'tu den hanh-dong nguoi-dung api ung-dung ket-qua trang co', None, (200, 'AuditPage'), '003 005 039', 'Đọc PH-13; việc xem cũng ghi `VIEW_AUDIT`.')
x(129, 'Báo cáo sử dụng cổng', 'PERM-15-audit-read', 'tu den', None, (200, 'UsageReport'), '003 039', '')
x(130, 'Xuất nhật ký kiểm toán của cổng', 'PERM-15-audit-read', '', 'AuditExportInput', (202, 'ExportAccepted'), '003 039', 'Xuất nền; ghi `EXPORT_AUDIT`.')
x(131, 'Chạy đồng bộ danh mục với PH-02', 'PERM-15-portal-admin', '', 'SyncRunInput', (202, 'SyncRun'), '003 030 035', 'Một lần chạy tại một thời điểm (ERR-15-035).')
x(132, 'Lịch sử các lần đồng bộ', 'PERM-15-portal-admin', 'trang co', None, (200, 'SyncRunPage'), '003', '')
x(133, 'Chạy đối soát danh mục với PH-02', 'PERM-15-portal-admin', '', 'ReconcileInput', (202, 'ReconcileReport', ['ReconcileAccepted']), '030 035', '`fix=true` sửa bản sao theo PH-02; không bao giờ sửa PH-02.')
x(134, 'Báo cáo đối soát gần nhất', 'PERM-15-portal-admin', '', None, (200, 'ReconcileReport'), '001', '')
x(135, 'Tải gói di trú nội dung portal hệ cũ', 'PERM-15-portal-admin', '', ('multipart', 'MigrationUpload'), (202, 'Migration'), '024 026 035', 'ZIP ≤ 50 MB, quét ClamAV, giải nén an toàn; chỉ lập báo cáo xem trước.')
x(136, 'Xem tiến độ và báo cáo xem trước di trú', 'PERM-15-portal-admin', 'MigrationId', None, (200, 'Migration'), '001', '')
x(137, 'Xác nhận áp dụng gói di trú', 'PERM-15-portal-admin', 'MigrationId', 'MigrationConfirm', (200, 'Migration', ['MigrationConfirmed']), '022 026 035', 'Chỉ ghi `DRAFT` sau xác nhận (BR-15-012).')

assert sorted(X) == list(range(1, 138)), [i for i in range(1, 138) if i not in X]

TAGS = [(1, 14, 'Trang chủ, danh mục, tìm kiếm'), (15, 21, 'Tài liệu API'), (22, 40, 'Nội dung và hướng dẫn'), (41, 54, 'Tài khoản nhà phát triển'),
        (55, 68, 'Ứng dụng và thông tin xác thực'), (69, 81, 'Sandbox và thử API'), (82, 82, 'Nội bộ gateway sandbox'), (83, 86, 'Thử production (quản trị)'),
        (87, 96, 'Đăng ký và điểm vào nghiệp vụ'), (97, 106, 'Theo dõi của nhà phát triển'), (107, 115, 'Hỗ trợ và phản hồi'), (116, 137, 'Quản trị cổng')]


def tag_of(n):
    return next(t for a, b, t in TAGS if a <= n <= b)


def group_of(path, n):
    if path.startswith('/internal/'):
        return 'internal'
    if path.startswith('/public/'):
        return 'public'
    if path.startswith('/try/') or n in (69, 70):
        return 'try'
    if path.startswith('/admin/'):
        return 'admin'
    return 'portal'


def ref(kind, name):
    return {'$ref': '#/components/%s/%s' % (kind, name)}


def schema_of(name):
    if name is None:
        return None
    return ref('schemas', name)


def ex_block(names, default):
    names = names or [default]
    return {('vi-du' if i == 0 else 'vi-du-%d' % (i + 1)): ref('examples', n) for i, n in enumerate(names)}


HTTP_NAME = {400: 'BadRequest', 401: 'Unauthorized', 403: 'Forbidden', 404: 'NotFound', 409: 'Conflict', 410: 'Gone', 412: 'PreconditionFailed', 413: 'PayloadTooLarge',
             422: 'Unprocessable', 429: 'TooManyRequests', 502: 'BadGateway', 503: 'ServiceUnavailable', 504: 'GatewayTimeout'}
NO_IM = {44, 46, 52, 53, 68, 40, 54, 105, 106, 130, 131, 133, 137, 103, 76, 90}
NO_IDEM = {71, 82, 105, 106}


def build():
    paths = {}
    for aid, meth, path, frs_ in ROWS:
        n = int(aid[-3:])
        e = X[n]
        m = meth.lower()
        fr = ['FR-15-' + f.strip() for f in frs_.split(',')]
        perm = e['perm']
        anon = perm == 'pub'
        mesh = perm == 'mesh'
        errs = ['ERR-15-' + c for c in e['errs']]
        # lỗi chung (401, 403, 36) có ở responses nhưng không lặp trong x-datahub-errors; quy ước nêu ở D03-04-PH15 §1
        generic = {'ERR-15-004', 'ERR-15-005', 'ERR-15-036'}
        errs = [c for c in errs if c not in generic]
        extra = []
        if not anon and not mesh:
            extra.append('ERR-15-004')
        if perm.startswith('PERM-15') or perm.startswith('PERM-0'):
            extra.append('ERR-15-005')
        if path.startswith('/admin/'):
            extra.append('ERR-15-036')
        shown = errs or list(extra)
        op = {'tags': [tag_of(n)], 'operationId': 'api15%03d' % n, 'summary': e['summary'], 'x-datahub-id': aid, 'x-datahub-fr': fr}
        op['x-datahub-permission'] = {'permission': {'pub': 'Ẩn danh (khách chưa đăng nhập)', 'login': 'Người dùng đã đăng nhập', 'mesh': 'Danh tính dịch vụ APISIX (SPIFFE, mTLS mesh)'}.get(perm, perm)}
        op['security'] = [] if anon else ([{'mtlsMesh': []}] if mesh else [{'oauth2User': []}])
        if e['desc']:
            dd = e['desc'] if n in (16, 62, 72, 82, 63, 64) else e['desc'].split('. ')[0].rstrip('.') + '.'
            op['description'] = dd
        # tham số
        ps = []
        for tok in e['params']:
            req = tok.endswith('!')
            nm = tok.rstrip('!')
            if nm.startswith('X-'):
                ps.append({'name': nm, 'in': 'header', 'required': req, 'schema': {'type': 'string'}, 'description': 'Tiêu đề gốc APISIX chuyển cho `forward-auth`.' if nm != 'X-DH-Try-Id' else 'Mã lượt thử, do cổng sinh.'})
                continue
            if nm in PATHP:
                pn, sc = PATHP[nm]
                ps.append({'name': pn, 'in': 'path', 'required': True, 'schema': S.T(sc)})
                continue
            sc, ds = QUERY[nm]
            if nm in ('trang', 'co', 'sap-xep', 'q'):
                p = {'$ref': '#/components/parameters/' + {'trang': 'Trang', 'co': 'Co', 'sap-xep': 'SapXep', 'q': 'Q'}[nm]}
                if nm == 'q' and req:
                    p = {'name': 'q', 'in': 'query', 'required': True, 'schema': {'type': 'string', 'minLength': 1, 'maxLength': 200}, 'description': ds}
                ps.append(p)
                continue
            pn = 'lang' if nm == 'lang_s' else nm
            ps.append({'name': pn, 'in': 'query', 'required': req, 'schema': S.T(sc), 'description': ds})
        # ví dụ `format` cho 16, 81
        for p in ps:
            if p.get('name') == 'format':
                p['schema'] = {'type': 'string', 'enum': ['yaml', 'json'] if n == 16 else ['postman', 'bruno', 'http']}
        if m != 'get' and m != 'delete' or n in (76,):
            pass
        if m in ('put', 'patch', 'delete') or (m == 'post' and re.search(r':[a-z-]+$', path)):
            if n not in NO_IM:
                ps.append(ref('parameters', 'IfMatch'))
                if 'ERR-15-006' not in errs and m != 'delete' or (n in (80, 59) and 'ERR-15-006' not in errs):
                    errs.append('ERR-15-006')
        if m == 'post' and n not in NO_IDEM:
            ps.append(ref('parameters', 'IdempotencyKey'))
            op['x-datahub-idempotent'] = 'required'
        if anon and m == 'get':
            ps.append(ref('parameters', 'IfNoneMatch'))
        ps += [ref('parameters', 'Traceparent'), ref('parameters', 'AcceptLanguage')]
        op['parameters'] = ps
        # thân yêu cầu
        rq = e['req']
        if rq:
            if isinstance(rq, tuple) and rq[0] == 'multipart':
                sch, exs = rq[1], [rq[1]]
                op['requestBody'] = {'required': True, 'content': {'multipart/form-data': {'schema': schema_of(sch), 'examples': ex_block(exs, sch)}}}
            else:
                sch, exs = (rq, [rq]) if isinstance(rq, str) else rq
                op['requestBody'] = {'required': True, 'content': {'application/json': {'schema': schema_of(sch), 'examples': ex_block(exs, sch)}}}
        # phản hồi
        code, sch, *rest = e['ok']
        exs = rest[0] if rest and rest[0] else None
        yaml_ct = len(rest) > 1 and rest[1] == 'yaml'
        resp = {}
        if sch is None:
            resp[str(code)] = {'description': 'Thành công, không có nội dung.'}
        else:
            cont = {'application/json': {'schema': schema_of(sch), 'examples': ex_block(exs, sch)}}
            if yaml_ct:
                cont['application/yaml'] = {'schema': {'type': 'string'}, 'example': 'openapi: 3.1.0\ninfo:\n  title: Tra cứu hộ tịch\n  version: 1.0.0\n'}
            r = {'description': {200: 'Thành công.', 201: 'Đã tạo.', 202: 'Đã nhận, xử lý bất đồng bộ hoặc chờ duyệt.'}[code], 'content': cont}
            hd = {}
            if code == 201 and path.endswith(('/apps', '/pages', '/teams')):
                hd['Location'] = {'schema': {'type': 'string'}}
            if m in ('post', 'put', 'patch') and code in (200, 201) and n in (23, 25, 56, 58, 117):
                hd['ETag'] = {'schema': {'type': 'string'}}
            if n in (62, 63):
                hd['Cache-Control'] = {'schema': {'type': 'string', 'const': 'no-store'}}
            if n == 16 or n == 81:
                hd['Content-Disposition'] = {'schema': {'type': 'string'}}
            if n == 82:
                for h in ('X-DH-App', 'X-DH-Tenant', 'X-DH-Sandbox-Mode', 'X-DH-Profile-Ver', 'X-RateLimit-Remaining'):
                    hd[h] = {'schema': {'type': 'string'}}
            if hd:
                r['headers'] = hd
            resp[str(code)] = r
        if anon and m == 'get':
            resp['304'] = {'description': 'Không đổi (`If-None-Match` khớp `ETag`).'}
        for c in errs + extra:
            if c not in ERRS:
                raise SystemExit('Mã lỗi không có ở FRS: %s (API-15-%03d)' % (c, n))
            st = ERRS[c][0]
            resp.setdefault(str(st), ref('responses', HTTP_NAME[st]))
        op['responses'] = dict(sorted(resp.items()))
        op['x-datahub-errors'] = shown
        if n == 82:
            op['servers'] = [{'url': 'http://dh-connect-portal.dh-connect.svc:8081', 'description': 'Cổng nội bộ vai trò `api` (mTLS mesh); không qua BFF.'}]
        paths.setdefault(path, {})[m] = op
    return paths


def components():
    C = {}
    C['securitySchemes'] = {
        'oauth2User': {'type': 'oauth2', 'description': 'Người dùng đăng nhập Keycloak (realm tenant hoặc `dh-dev`), Authorization Code + PKCE qua BFF `dh-portal`; trình duyệt chỉ giữ cookie phiên, BFF gắn token (SEC-21). Hạng người xem suy từ phiên.',
                       'flows': {'authorizationCode': {'authorizationUrl': 'https://sso.datahub.example.vn/realms/dh-t68/protocol/openid-connect/auth',
                                                       'tokenUrl': 'https://sso.datahub.example.vn/realms/dh-t68/protocol/openid-connect/token', 'scopes': {}}}},
        'mtlsMesh': {'type': 'mutualTLS', 'description': 'Chứng thư SPIFFE của APISIX trong mesh; chỉ dùng cho API-15-082.'}}
    C['parameters'] = {
        'Q': {'name': 'q', 'in': 'query', 'schema': {'type': 'string', 'maxLength': 200}, 'description': 'Từ khóa tìm kiếm.'},
        'Trang': {'name': 'trang', 'in': 'query', 'schema': {'type': 'integer', 'minimum': 1, 'default': 1}, 'description': 'Số trang, từ 1.'},
        'Co': {'name': 'co', 'in': 'query', 'schema': {'type': 'integer', 'enum': [10, 20, 50, 100], 'default': 20}, 'description': 'Cỡ trang.'},
        'SapXep': {'name': 'sap-xep', 'in': 'query', 'schema': {'type': 'string'}, 'description': 'Khóa sắp xếp; tiền tố `-` là giảm dần.'},
        'IdempotencyKey': {'name': 'Idempotency-Key', 'in': 'header', 'required': True, 'schema': {'type': 'string', 'format': 'uuid'}, 'description': 'Khóa chống trùng (ADR-041, BR-15-034); lưu 24 giờ.'},
        'IfMatch': {'name': 'If-Match', 'in': 'header', 'required': True, 'schema': {'type': 'string'}, 'description': '`ETag` của đối tượng; lệch trả `412` (ERR-15-006).'},
        'IfNoneMatch': {'name': 'If-None-Match', 'in': 'header', 'schema': {'type': 'string'}, 'description': 'Trả `304` nếu nội dung không đổi.'},
        'Traceparent': {'name': 'traceparent', 'in': 'header', 'schema': {'type': 'string', 'pattern': '^00-[0-9a-f]{32}-[0-9a-f]{16}-[0-9a-f]{2}$'}, 'description': 'W3C Trace Context.'},
        'AcceptLanguage': {'name': 'Accept-Language', 'in': 'header', 'schema': {'type': 'string', 'enum': ['vi', 'en']}, 'description': 'Ngôn ngữ thông báo lỗi.'}}
    resp = {}
    for st, name in HTTP_NAME.items():
        exs = {}
        for c, (h, t) in ERRS.items():
            if h == st:
                exs[c.replace('-', '_')] = {'summary': t, 'value': {'type': 'https://datahub.gov.vn/errors/' + c, 'title': t, 'status': st, 'code': c, 'traceId': S.TRACE}}
        r = {'description': 'Lỗi %d (RFC 9457): %s.' % (st, ', '.join(sorted(c for c, (h, _) in ERRS.items() if h == st))),
             'content': {'application/problem+json': {'schema': schema_of('ProblemDetails'), 'examples': exs}}}
        if st == 429:
            r['headers'] = {'Retry-After': {'schema': {'type': 'integer'}, 'description': 'Số giây nên đợi.'}}
        resp[name] = r
    C['responses'] = resp
    C['examples'] = {k: {'value': v} for k, v in S.EX.items()}
    C['schemas'] = S.SCH
    return C


def doc():
    return {
        'openapi': '3.1.0',
        'info': {'title': 'Datahub · PH-15 Cổng nhà phát triển API', 'version': '1.0.0-draft',
                 'summary': 'Danh mục và tìm kiếm, tài liệu API, nội dung, tài khoản nhà phát triển, ứng dụng và thông tin xác thực sandbox, thử API, ủy thác đăng ký, theo dõi, hỗ trợ, quản trị cổng.',
                 'description': ('Module `portal` của `dh-connect` (package `vn.datahub.connect.portal`), gốc `/api/portal/v1` qua BFF của `dh-portal`; phần ẩn danh `/public`, thử API `/try`, quản trị `/admin`, '
                                 'nội bộ gateway sandbox `/internal/v1` (cổng 8081, chỉ APISIX).\n\nQuy ước (D03-04-PH15 §1): tenant lấy từ phiên/host, không nhận từ tham số; tạo nhận `Idempotency-Key`; sửa và hành động nhận `If-Match`; '
                                 'hậu tố `:{hành-động}`; phân trang `trang`, `co` (10, 20, 50, 100), `sap-xep`; lỗi RFC 9457 mã `ERR-15-nnn`. Cổng không giữ bí mật ứng dụng; bí mật sandbox chỉ hiện một lần. '
                                 'Mọi tên miền, dữ liệu là giả lập.\n\nTệp sinh bởi `tools/gen_openapi.py`; không sửa tay.'),
                 'contact': {'name': 'Nhóm phân hệ PH-15'}, 'license': {'name': 'Tài liệu nội bộ dự án Datahub (dự thảo)', 'identifier': 'LicenseRef-Datahub-Internal'},
                 'x-datahub-document': 'D03-04-PH15', 'x-datahub-phase': 'PH-15'},
        'servers': [{'url': 'https://developer.{tenantHost}.datahub.example.vn/api/portal/v1', 'description': 'Qua BFF `dh-portal` của tenant (giả lập)',
                     'variables': {'tenantHost': {'default': 't68', 'description': 'Ví dụ `t68` (giả lập).'}}},
                    {'url': 'http://dh-connect-portal.dh-connect.svc:8080/api/portal/v1', 'description': 'Trong cụm (vai trò `api`)'},
                    {'url': 'http://localhost:8082/api/portal/v1', 'description': 'Phát triển cục bộ'}],
        'security': [{'oauth2User': []}],
        'tags': [{'name': t, 'description': 'Nhóm %s; bảng mã ở D03-04-PH15 §3.' % t} for _, _, t in TAGS],
        'paths': build(), 'components': components()}


def main():
    d = doc()
    out = os.path.join(HERE, '..', 'openapi-portal.yaml')
    head = '# D03-04-PH15 · OpenAPI PH-15 (module portal của dh-connect). SINH TỰ ĐỘNG bởi tools/gen_openapi.py, không sửa tay.\n'
    open(out, 'w', encoding='utf-8').write(head + yaml.safe_dump(d, allow_unicode=True, sort_keys=False, width=160))
    print('ghi', out, len(d['paths']), 'đường dẫn')


if __name__ == '__main__':
    main()
