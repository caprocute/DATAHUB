-- =============================================================================
-- D03-03-PH02 · Tệp 60: dữ liệu khởi tạo (bộ luật kiểm tra) và quyền
-- Chạy sau ph02_50_platform.sql (cùng phiên, đang SET ROLE ph02_owner).
-- Seed chạy dưới app.tenant_id = 'PLATFORM', lũy đẳng (ON CONFLICT DO UPDATE).
-- =============================================================================

-- @file 02-0800-seed.sql
-- @changeset ph02-0800-seed-lint-rule runOnChange:true splitStatements:false
SET app.tenant_id = 'PLATFORM';
INSERT INTO ph02_catalog.lint_rule (id, tenant_id, rule_id, layer, default_severity, adjust_policy, title, hint, pattern, created_by, updated_by)
SELECT md5('ph02:lint:' || k.rule_id)::uuid, 'COMMON', k.rule_id, k.layer, k.sev, k.policy, k.title, k.hint, k.pattern, 'system:seed', 'system:seed'
FROM (VALUES
  ('LINT-02-01', 'CONVENTION', 'ERROR',   'NONE',       'Mọi thao tác có operationId duy nhất, dạng camelCase, bắt đầu bằng động từ', 'Đặt operationId như getCivilRecord, createDossier.', NULL),
  ('LINT-02-02', 'CONVENTION', 'ERROR',   'LOWER_LANG', 'Mọi thao tác có summary và description bằng tiếng Việt có dấu', 'Viết mô tả tiếng Việt có dấu; tỷ lệ ký tự có dấu quá thấp chỉ cảnh báo (BR-02-002).', NULL),
  ('LINT-02-03', 'CONVENTION', 'ERROR',   'NONE',       'Khai báo đủ mã lỗi 401, 403, 429, 500 cho mọi thao tác; thêm 400 khi có đầu vào, 404 khi đường dẫn có tham số', 'Thêm các phản hồi lỗi còn thiếu vào thao tác.', NULL),
  ('LINT-02-04', 'CONVENTION', 'ERROR',   'NONE',       'Phản hồi lỗi dùng application/problem+json theo RFC 9457', 'Khai lược đồ có type, title, status, detail, traceId.', NULL),
  ('LINT-02-05', 'CONVENTION', 'WARNING', 'RAISE',      'Mọi tham số và thuộc tính của lược đồ có description', 'Thêm description tiếng Việt cho tham số, thuộc tính.', NULL),
  ('LINT-02-06', 'CONVENTION', 'WARNING', 'RAISE',      'Mọi yêu cầu và phản hồi thành công có example hoặc examples', 'Thêm ví dụ giả, không dùng dữ liệu thật (BR-02-015).', NULL),
  ('LINT-02-07', 'CONVENTION', 'ERROR',   'NONE',       'Đường dẫn chữ thường, gạch ngang, danh từ số nhiều, không động từ, không kết thúc bằng /', 'Đổi /layHoSo/ thành /ho-so.', NULL),
  ('LINT-02-08', 'CONVENTION', 'ERROR',   'NONE',       'Mọi thao tác khai security và phạm vi cần thiết; kiểu xác thực phù hợp mức phân loại; thao tác công khai chỉ với API PUBLIC', 'Khai securitySchemes và scope theo BR-02-016.', NULL),
  ('LINT-02-09', 'CONVENTION', 'ERROR',   'NONE',       'Thao tác trả danh sách có tham số page, size (tối đa 200) và trả totalElements', 'Thêm phân trang chuẩn theo D00-01.', NULL),
  ('LINT-02-10', 'CONVENTION', 'WARNING', 'RAISE',      'Dùng kiểu chuẩn: date-time, date, tiền VND integer int64; tên trường khớp từ điển dữ liệu', 'Đổi sang kiểu chuẩn T-TS, T-DATE, T-MONEY.', NULL),
  ('LINT-02-11', 'CONVENTION', 'ERROR',   'NONE',       'Thao tác POST khai tiêu đề Idempotency-Key; thao tác ghi khai 412, 409 khi có ETag', 'Khai Idempotency-Key và các phản hồi 409, 412.', NULL),
  ('LINT-02-12', 'CONVENTION', 'WARNING', 'RAISE',      'info.contact có đầu mối kỹ thuật; info.version khớp số phiên bản của API', 'Điền info.contact và info.version.', NULL),
  ('LINT-02-13', 'CONVENTION', 'ERROR',   'NONE',       'servers không chứa địa chỉ IP, localhost, tên miền nội bộ hay đường dẫn kiểm thử', 'Xóa servers nội bộ; địa chỉ công bố do nền tảng cấp (SEC-16).', NULL),
  ('LINT-02-14', 'CONVENTION', 'ERROR',   'NONE',       'Số chính trong đường dẫn (/v2) khớp số chính của phiên bản', 'Sửa đường dẫn hoặc số phiên bản (BR-02-003).', NULL),
  ('LINT-02-15', 'CONVENTION', 'WARNING', 'RAISE',      'Trường dữ liệu mức Hạn chế hoặc Nhạy cảm có x-dh-classification', 'Gắn x-dh-classification cho trường nhạy cảm.', NULL),
  ('SCAN-02-01', 'SECRET', 'ERROR', 'NONE', 'Khóa riêng dạng PEM', 'Xóa khối PEM; dùng khóa giả hoặc bỏ ví dụ.', $re$-----BEGIN [A-Z ]*PRIVATE KEY-----[\s\S]+?-----END [A-Z ]*PRIVATE KEY-----$re$),
  ('SCAN-02-02', 'SECRET', 'ERROR', 'NONE', 'JWT thật: ba đoạn base64url, đoạn đầu giải được thành JSON có alg', 'Thay bằng giá trị giữ chỗ.', $re$\beyJ[A-Za-z0-9_-]{8,}\.eyJ[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}\b$re$),
  ('SCAN-02-03', 'SECRET', 'ERROR', 'NONE', 'Khóa truy cập đám mây và nền tảng phổ biến (AKIA…, ghp_…, xox…)', 'Thu hồi khóa đã lộ và thay bằng giữ chỗ.', $re$\b(AKIA[0-9A-Z]{16}|ghp_[A-Za-z0-9]{36}|xox[abprs]-[A-Za-z0-9-]{10,})\b$re$),
  ('SCAN-02-04', 'SECRET', 'ERROR', 'NONE', 'Tiêu đề Authorization Bearer hoặc Basic kèm giá trị dài hơn 20 ký tự không phải giữ chỗ', 'Dùng <token> làm giữ chỗ.', $re$(?i)\bauthorization\s*:\s*(bearer|basic)\s+[A-Za-z0-9._~+/=-]{21,}$re$),
  ('SCAN-02-05', 'SECRET', 'ERROR', 'NONE', 'Mật khẩu hoặc khóa trong URL hoặc tham số truy vấn', 'Bỏ thông tin xác thực khỏi URL.', $re$(?i)[a-z][a-z0-9+.-]*://[^/\s:@]+:[^/\s@]+@|[?&](api_?key|token|access_token)=[^&\s]{8,}$re$),
  ('SCAN-02-06', 'SECRET', 'ERROR', 'NONE', 'Trường password, secret, apiKey, clientSecret có giá trị không phải giữ chỗ', 'Dùng giá trị giữ chỗ như "string".', $re$(?i)"(password|secret|api_?key|client_?secret)"\s*:\s*"[^"]{4,}"$re$),
  ('SCAN-02-07', 'SECRET', 'ERROR', 'NONE', 'Số định danh cá nhân 12 chữ số hợp lệ cấu trúc (CCCD)', 'Dùng số giả theo dải dành cho ví dụ.', $re$(?<![0-9])[0-9]{12}(?![0-9])$re$),
  ('SCAN-02-08', 'SECRET', 'ERROR', 'NONE', 'Số điện thoại di động Việt Nam hợp lệ', 'Dùng số giả theo dải dành cho ví dụ.', $re$(?<![0-9])(\+84|0)(3|5|7|8|9)[0-9]{8}(?![0-9])$re$),
  ('SCAN-02-09', 'SECRET', 'ERROR', 'NONE', 'Địa chỉ thư điện tử không thuộc miền ví dụ cho phép', 'Dùng miền example.gov.vn.', $re$[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$re$)
) AS k(rule_id, layer, sev, policy, title, hint, pattern)
ON CONFLICT (rule_id) DO UPDATE SET title = EXCLUDED.title, hint = EXCLUDED.hint, default_severity = EXCLUDED.default_severity,
  adjust_policy = EXCLUDED.adjust_policy, pattern = EXCLUDED.pattern, updated_by = 'system:seed';
-- @rollback DELETE FROM ph02_catalog.lint_rule WHERE tenant_id = 'COMMON';

-- @file 02-0900-grants.sql
-- @changeset ph02-0990-grants runAlways:true splitStatements:false
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA ph02_catalog TO ph02_app;
-- Bảng bằng chứng: chỉ thêm (đã có trigger tg_append_only, thu quyền là lớp thứ hai)
REVOKE UPDATE, DELETE ON ph02_catalog.api_spec, ph02_catalog.code_registry, ph02_catalog.api_owner_transfer,
  ph02_catalog.subscription_state_history, ph02_catalog.version_state_history, ph02_catalog.review_decision,
  ph02_catalog.sla_commitment, ph02_catalog.legacy_id_map FROM ph02_app;
-- Hộp gửi: chỉ thêm, chỉ đánh dấu đã phát, xóa khi dọn
REVOKE UPDATE ON ph02_catalog.outbox_event FROM ph02_app;
GRANT UPDATE (published_at) ON ph02_catalog.outbox_event TO ph02_app;
-- Phân vùng chỉ truy cập qua bảng cha (RLS của bảng cha áp dụng); không cấp quyền trực tiếp lên phân vùng
DO $g$
DECLARE r record;
BEGIN
  FOR r IN SELECT c.oid::regclass AS part
             FROM pg_inherits i JOIN pg_class c ON c.oid = i.inhrelid
             JOIN pg_namespace n ON n.oid = c.relnamespace AND n.nspname = 'ph02_catalog'
            WHERE c.relkind IN ('r', 'p')
  LOOP
    EXECUTE format('REVOKE ALL ON %s FROM ph02_app, ph02_readonly', r.part);
  END LOOP;
END
$g$;
GRANT SELECT ON ALL TABLES IN SCHEMA ph02_catalog TO ph02_readonly;
REVOKE SELECT ON ph02_catalog.idempotency_record, ph02_catalog.pending_command, ph02_catalog.import_session FROM ph02_readonly;
-- Phân vùng của bảng phân vùng: REVOKE ở trên chạy sau GRANT; chạy lại không đổi kết quả
-- @rollback -- Không thu hồi tự động.

RESET ROLE;
