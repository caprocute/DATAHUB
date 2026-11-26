--liquibase formatted sql
-- Nguồn: ddl/ph09_privacy.sql · 09-0001-functions.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph09:ph09-0010-fn-touch splitStatements:false
CREATE OR REPLACE FUNCTION ph09_privacy.tg_touch() RETURNS trigger
  LANGUAGE plpgsql AS $f$
BEGIN
  NEW.updated_at := now();
  IF NEW.version IS NOT DISTINCT FROM OLD.version THEN
    NEW.version := OLD.version + 1;
  END IF;
  RETURN NEW;
END
$f$;
COMMENT ON FUNCTION ph09_privacy.tg_touch() IS 'Cập nhật updated_at, tăng version (khóa lạc quan, ETag).';
--rollback DROP FUNCTION IF EXISTS ph09_privacy.tg_touch();

--changeset ph09:ph09-0011-fn-immutable splitStatements:false
CREATE OR REPLACE FUNCTION ph09_privacy.tg_immutable() RETURNS trigger
  LANGUAGE plpgsql AS $f$
DECLARE
  c text;
BEGIN
  FOREACH c IN ARRAY TG_ARGV LOOP
    IF (to_jsonb(NEW) -> c) IS DISTINCT FROM (to_jsonb(OLD) -> c) THEN
      RAISE EXCEPTION 'Cột %.% bất biến', TG_TABLE_NAME, c USING ERRCODE = '55000';
    END IF;
  END LOOP;
  RETURN NEW;
END
$f$;
COMMENT ON FUNCTION ph09_privacy.tg_immutable() IS 'Chặn sửa các cột truyền qua tham số trigger: mã nghiệp vụ, khóa tham chiếu, bằng chứng đã chốt.';
--rollback DROP FUNCTION IF EXISTS ph09_privacy.tg_immutable();

--changeset ph09:ph09-0012-fn-append-only splitStatements:false
CREATE OR REPLACE FUNCTION ph09_privacy.tg_append_only() RETURNS trigger
  LANGUAGE plpgsql AS $f$
BEGIN
  RAISE EXCEPTION 'Bảng % chỉ thêm, không sửa, xóa dòng (nhật ký kiểm toán)', TG_TABLE_NAME USING ERRCODE = '55000';
END
$f$;
COMMENT ON FUNCTION ph09_privacy.tg_append_only() IS 'Chặn UPDATE, DELETE dòng của bảng chỉ thêm (privacy_audit_event). Dọn bằng DETACH, DROP phân vùng dưới ph09_owner.';
--rollback DROP FUNCTION IF EXISTS ph09_privacy.tg_append_only();

--changeset ph09:ph09-0013-fn-frozen splitStatements:false
-- Phiên bản ACTIVE hoặc SUPERSEDED bất biến nội dung (BR-09-011): chặn sửa cột nội dung (đối số).
CREATE OR REPLACE FUNCTION ph09_privacy.tg_frozen() RETURNS trigger
  LANGUAGE plpgsql AS $f$
DECLARE
  c text;
BEGIN
  IF OLD.status IN ('ACTIVE', 'SUPERSEDED', 'SUBMITTED_A05') THEN
    FOREACH c IN ARRAY TG_ARGV LOOP
      IF (to_jsonb(NEW) -> c) IS DISTINCT FROM (to_jsonb(OLD) -> c) THEN
        RAISE EXCEPTION 'Phiên bản % không sửa được cột % (BR-09-011)', OLD.status, c USING ERRCODE = '55000';
      END IF;
    END LOOP;
  END IF;
  RETURN NEW;
END
$f$;
COMMENT ON FUNCTION ph09_privacy.tg_frozen() IS 'Hoạt động, chính sách che, lịch lưu giữ, mẫu đồng ý, DPIA, cấu hình ẩn danh đã ACTIVE không đổi nội dung; thay đổi cần phiên bản mới.';
--rollback DROP FUNCTION IF EXISTS ph09_privacy.tg_frozen();

--changeset ph09:ph09-0014-fn-child-frozen splitStatements:false
-- Bảng con của đối tượng có phiên bản (liên kết, quy tắc che, dòng lịch lưu): chỉ ghi khi cha là DRAFT hoặc REJECTED.
-- Đối số: tên bảng cha, tên cột khóa ngoại tới cha.
CREATE OR REPLACE FUNCTION ph09_privacy.tg_child_frozen() RETURNS trigger
  LANGUAGE plpgsql AS $f$
DECLARE
  parent text := TG_ARGV[0];
  fkcol text := TG_ARGV[1];
  st text;
  rec jsonb;
BEGIN
  IF TG_OP = 'DELETE' THEN rec := to_jsonb(OLD); ELSE rec := to_jsonb(NEW); END IF;
  EXECUTE format('SELECT status FROM ph09_privacy.%I WHERE tenant_id = $1 AND id = $2::uuid', parent)
    INTO st USING rec ->> 'tenant_id', rec ->> fkcol;
  IF st IN ('ACTIVE', 'SUPERSEDED', 'PENDING_APPROVAL', 'RETIRED') THEN
    RAISE EXCEPTION 'Không sửa dòng con của % khi cha là % (BR-09-011)', parent, st USING ERRCODE = '55000';
  END IF;
  IF TG_OP = 'DELETE' THEN RETURN OLD; END IF;
  RETURN NEW;
END
$f$;
COMMENT ON FUNCTION ph09_privacy.tg_child_frozen() IS 'Chặn thêm, sửa, xóa dòng con khi phiên bản cha đã gửi duyệt, ACTIVE, SUPERSEDED hoặc RETIRED (BR-09-011).';
--rollback DROP FUNCTION IF EXISTS ph09_privacy.tg_child_frozen();

--changeset ph09:ph09-0015-fn-class-rank splitStatements:false
CREATE OR REPLACE FUNCTION ph09_privacy.class_rank(p_class text) RETURNS smallint
  LANGUAGE sql IMMUTABLE PARALLEL SAFE AS $f$
  SELECT CASE p_class WHEN 'PUBLIC' THEN 1 WHEN 'INTERNAL' THEN 2 WHEN 'RESTRICTED' THEN 3 WHEN 'SENSITIVE' THEN 4 END::smallint
$f$;
COMMENT ON FUNCTION ph09_privacy.class_rank(text) IS 'Thứ hạng DataClass 1 đến 4 (DD-08) dùng trong CHECK hạ mức (BR-09-002).';
--rollback DROP FUNCTION IF EXISTS ph09_privacy.class_rank(text);

--changeset ph09:ph09-0016-fn-rls splitStatements:false
-- Một mẫu cho mọi bảng nghiệp vụ: chỉ thấy, ghi dòng của tenant phiên; tenant_id đúng dạng Tnn (không có dòng COMMON).
CREATE OR REPLACE PROCEDURE ph09_privacy.p_enable_rls(p_table regclass)
  LANGUAGE plpgsql AS $p$
DECLARE
  t text := p_table::text;
  n text := split_part(p_table::text, '.', 2);
  w text := $w$(tenant_id = current_setting('app.tenant_id', false) AND tenant_id ~ '^T[0-9]{2}$')$w$;
BEGIN
  EXECUTE format('ALTER TABLE %s ENABLE ROW LEVEL SECURITY', t);
  EXECUTE format('ALTER TABLE %s FORCE ROW LEVEL SECURITY', t);
  EXECUTE format('CREATE POLICY rls_%s_select ON %s FOR SELECT USING %s', n, t, w);
  EXECUTE format('CREATE POLICY rls_%s_insert ON %s FOR INSERT WITH CHECK %s', n, t, w);
  EXECUTE format('CREATE POLICY rls_%s_update ON %s FOR UPDATE USING %s WITH CHECK %s', n, t, w, w);
  EXECUTE format('CREATE POLICY rls_%s_delete ON %s FOR DELETE USING %s', n, t, w);
END
$p$;
COMMENT ON PROCEDURE ph09_privacy.p_enable_rls(regclass) IS 'Bật FORCE RLS và 4 chính sách theo tenant (D03-10 §4, ADR-003, BR-09-060).';
--rollback DROP PROCEDURE IF EXISTS ph09_privacy.p_enable_rls(regclass);

--changeset ph09:ph09-0017-fn-partitions splitStatements:false
CREATE OR REPLACE PROCEDURE ph09_privacy.p_ensure_partitions(p_table regclass, p_from date, p_count integer)
  LANGUAGE plpgsql AS $p$
DECLARE
  d timestamptz := date_trunc('month', p_from::timestamptz);
  i integer;
  part text;
BEGIN
  FOR i IN 0 .. p_count - 1 LOOP
    part := format('%s_%s', p_table::text, to_char(d + interval '1 month' * i, 'YYYYMM'));
    IF to_regclass(part) IS NULL THEN
      EXECUTE format('CREATE TABLE %s PARTITION OF %s FOR VALUES FROM (%L) TO (%L)',
                     part, p_table, d + interval '1 month' * i, d + interval '1 month' * (i + 1));
    END IF;
  END LOOP;
END
$p$;
COMMENT ON PROCEDURE ph09_privacy.p_ensure_partitions(regclass, date, integer) IS 'Tạo trước phân vùng tháng cho usage_counter, privacy_audit_event. PartitionMaintenanceJob gọi hằng ngày; dọn bằng DETACH, DROP dưới ph09_owner.';
--rollback DROP PROCEDURE IF EXISTS ph09_privacy.p_ensure_partitions(regclass, date, integer);

--changeset ph09:ph09-0018-fn-seed-tenant splitStatements:false
-- Khởi tạo tenant (PH-20): danh mục nạp sẵn, tham số 09.*, lịch lưu giữ của PH-09. Chạy lại không nhân bản.
CREATE OR REPLACE PROCEDURE ph09_privacy.p_seed_tenant(p_tenant text)
  LANGUAGE plpgsql AS $p$
BEGIN
  PERFORM set_config('app.tenant_id', p_tenant, true);
  INSERT INTO ph09_privacy.data_class (id, tenant_id, code, rank, name, log_policy, display_policy, encrypt_at_app, created_by, updated_by)
  SELECT md5('ph09-class:' || p_tenant || ':' || s.c)::uuid, p_tenant, s.c, s.r, s.n, s.l, s.d, s.e, 'system:seed', 'system:seed'
  FROM (VALUES ('PUBLIC', 1, 'Công khai', 'FULL', 'FULL', false), ('INTERNAL', 2, 'Nội bộ', 'FULL', 'FULL', false), ('RESTRICTED', 3, 'Hạn chế', 'PARTIAL_MASK', 'MASK_BY_ROLE', false), ('SENSITIVE', 4, 'Nhạy cảm', 'NO_VALUE', 'MASK_DEFAULT', true)) AS s(c, r, n, l, d, e)
  ON CONFLICT (tenant_id, code) DO NOTHING;
  INSERT INTO ph09_privacy.personal_data_category (id, tenant_id, code, name, personal_data_type, legal_ref, default_class, default_mask_pattern, identifiability, builtin, created_by, updated_by)
  SELECT md5('ph09-cat:' || p_tenant || ':' || s.c)::uuid, p_tenant, s.c, s.n, s.t, s.l, s.k, s.m, s.i, true, 'system:seed', 'system:seed'
  FROM (VALUES ('FULL_NAME', 'Họ và tên', 'BASIC', 'CMP-LAW-05', 'RESTRICTED', 'KEEP_FIRST_TOKEN', 'DIRECT'), ('DATE_OF_BIRTH', 'Ngày tháng năm sinh', 'BASIC', 'CMP-LAW-05', 'RESTRICTED', 'YEAR_ONLY', 'QUASI'), ('GENDER', 'Giới tính', 'BASIC', 'CMP-LAW-05', 'INTERNAL', NULL::varchar, 'QUASI'), ('NATIONAL_ID', 'Số định danh cá nhân', 'BASIC', 'CMP-LAW-05', 'RESTRICTED', 'KEEP_LAST_N', 'DIRECT'), ('PHONE', 'Số điện thoại', 'BASIC', 'CMP-LAW-05', 'RESTRICTED', 'KEEP_LAST_N', 'DIRECT'), ('EMAIL', 'Thư điện tử', 'BASIC', 'CMP-LAW-05', 'RESTRICTED', 'KEEP_DOMAIN', 'DIRECT'), ('ADDRESS', 'Địa chỉ', 'BASIC', 'CMP-LAW-05', 'RESTRICTED', 'ADMIN_LEVEL', 'QUASI'), ('TAX_ID', 'Mã số thuế cá nhân', 'BASIC', 'CMP-LAW-05', 'RESTRICTED', 'KEEP_LAST_N', 'DIRECT'), ('SOCIAL_INSURANCE_ID', 'Số bảo hiểm xã hội', 'BASIC', 'CMP-LAW-05', 'RESTRICTED', 'KEEP_LAST_N', 'DIRECT'), ('HEALTH', 'Tình trạng sức khỏe', 'SENSITIVE', 'CMP-LAW-05', 'SENSITIVE', NULL::varchar, 'SENSITIVE_ATTR'), ('BIOMETRIC', 'Đặc điểm sinh trắc học', 'SENSITIVE', 'CMP-LAW-05', 'SENSITIVE', NULL::varchar, 'DIRECT'), ('GENETIC', 'Dữ liệu di truyền', 'SENSITIVE', 'CMP-LAW-05', 'SENSITIVE', NULL::varchar, 'SENSITIVE_ATTR'), ('POLITICAL_RELIGIOUS', 'Quan điểm chính trị, tôn giáo', 'SENSITIVE', 'CMP-LAW-05', 'SENSITIVE', NULL::varchar, 'SENSITIVE_ATTR'), ('CRIMINAL_RECORD', 'Tiền án, tiền sự', 'SENSITIVE', 'CMP-LAW-05', 'SENSITIVE', NULL::varchar, 'SENSITIVE_ATTR'), ('FINANCIAL_ACCOUNT', 'Tài khoản, thông tin tài chính', 'SENSITIVE', 'CMP-LAW-05', 'SENSITIVE', 'KEEP_LAST_N', 'DIRECT'), ('LOCATION_TRACKING', 'Vị trí, lịch sử di chuyển', 'SENSITIVE', 'CMP-LAW-05', 'SENSITIVE', NULL::varchar, 'SENSITIVE_ATTR'), ('MINOR', 'Dữ liệu của trẻ em', 'SENSITIVE', 'CMP-LAW-05', 'SENSITIVE', NULL::varchar, 'SENSITIVE_ATTR'), ('ETHNICITY', 'Nguồn gốc dân tộc, chủng tộc', 'SENSITIVE', 'CMP-LAW-05', 'SENSITIVE', NULL::varchar, 'SENSITIVE_ATTR')) AS s(c, n, t, l, k, m, i)
  ON CONFLICT (tenant_id, code) DO NOTHING;
  INSERT INTO ph09_privacy.detector_rule (id, tenant_id, detector_code, name, pattern, has_checksum, builtin, created_by, updated_by)
  SELECT md5('ph09-det:' || p_tenant || ':' || s.c)::uuid, p_tenant, s.c, s.n, s.p, s.k, true, 'system:seed', 'system:seed'
  FROM (VALUES ('NATIONAL_ID_12', 'Số định danh 12 chữ số', '^[0-9]{12}$', true), ('TAX_ID_10_13', 'Mã số thuế 10 hoặc 13 chữ số', '^[0-9]{10}(-[0-9]{3})?$', true), ('BANK_CARD_LUHN', 'Số thẻ ngân hàng (Luhn)', '^[0-9]{13,19}$', true), ('PHONE_VN', 'Số điện thoại Việt Nam', '^(\+84|0)[0-9]{9}$', false), ('EMAIL', 'Thư điện tử', '^[^@\s]+@[^@\s]+\.[^@\s]+$', false), ('SOCIAL_INSURANCE_10', 'Số bảo hiểm xã hội 10 chữ số', '^[0-9]{10}$', true), ('FIELD_NAME_HINT', 'Gợi ý theo tên trường', '(?i)(cccd|cmnd|dienthoai|phone|email|diachi|hoten|ngaysinh|mst|bhxh|sdt)', false)) AS s(c, n, p, k)
  ON CONFLICT (tenant_id, detector_code) DO NOTHING;
  INSERT INTO ph09_privacy.legal_basis (id, tenant_id, code, basis_type, name, mandatory, rule, created_by, updated_by)
  SELECT md5('ph09-basis:' || p_tenant || ':' || s.c)::uuid, p_tenant, s.c, s.c, s.n, s.m, s.r, 'system:seed', 'system:seed'
  FROM (VALUES ('CONSENT', 'Sự đồng ý', false, 'Chỉ cho tiện ích không bắt buộc; không là điều kiện của thủ tục hành chính (BR-09-049).'), ('STATE_TASK', 'Nhiệm vụ của cơ quan nhà nước', false, 'Cơ sở chính của cơ quan nhà nước (BR-09-009).'), ('LEGAL_OBLIGATION', 'Nghĩa vụ pháp lý', true, 'Có điều khoản pháp luật quy định bắt buộc.'), ('CONTRACT', 'Thực hiện hợp đồng', false, 'Cần cho việc thực hiện hợp đồng với chủ thể.'), ('VITAL_INTEREST', 'Bảo vệ lợi ích sống còn', false, 'Bảo vệ tính mạng, sức khỏe của chủ thể hoặc người khác.'), ('EMERGENCY_PUBLIC_INTEREST', 'Tình huống khẩn cấp, lợi ích công cộng', false, 'Theo quyết định của cơ quan có thẩm quyền.'), ('STATISTICS_RESEARCH', 'Thống kê, nghiên cứu', false, 'Dữ liệu đã giả danh hóa hoặc ẩn danh hóa.')) AS s(c, n, m, r)
  ON CONFLICT (tenant_id, code) DO NOTHING;
  INSERT INTO ph09_privacy.mask_type (id, tenant_id, code, mask_type, pattern_kind, name, default_params, reversible, builtin, created_by, updated_by)
  SELECT md5('ph09-mask:' || p_tenant || ':' || s.c)::uuid, p_tenant, s.c, s.t, s.p, s.n, s.d::jsonb, s.r, true, 'system:seed', 'system:seed'
  FROM (VALUES ('NONE', 'NONE', NULL::varchar, 'Giữ nguyên', '{}', false), ('PARTIAL.KEEP_FIRST_N', 'PARTIAL', 'KEEP_FIRST_N', 'Giữ n ký tự đầu', '{"n": 3, "char": "*"}', false), ('PARTIAL.KEEP_LAST_N', 'PARTIAL', 'KEEP_LAST_N', 'Giữ n ký tự cuối', '{"n": 4, "char": "*"}', false), ('PARTIAL.KEEP_FIRST_LAST', 'PARTIAL', 'KEEP_FIRST_LAST', 'Giữ n ký tự đầu và m ký tự cuối', '{"n": 2, "m": 2, "char": "*"}', false), ('PARTIAL.KEEP_FIRST_TOKEN', 'PARTIAL', 'KEEP_FIRST_TOKEN', 'Giữ từ đầu của họ tên', '{"char": "*"}', false), ('PARTIAL.KEEP_DOMAIN', 'PARTIAL', 'KEEP_DOMAIN', 'Giữ tên miền thư điện tử', '{"char": "*"}', false), ('REPLACE', 'REPLACE', NULL::varchar, 'Thay bằng chuỗi cố định', '{"value": "[REDACTED]"}', false), ('KEYED_HASH', 'KEYED_HASH', NULL::varchar, 'Băm có khóa HMAC-SHA256', '{}', false), ('TOKENIZE', 'TOKENIZE', NULL::varchar, 'Token hóa đảo ngược qua transit', '{}', true), ('GENERALIZE.YEAR_ONLY', 'GENERALIZE', 'YEAR_ONLY', 'Chỉ giữ năm', '{}', false), ('GENERALIZE.ADMIN_LEVEL', 'GENERALIZE', 'ADMIN_LEVEL', 'Tổng quát hóa đến cấp hành chính', '{"level": "PROVINCE"}', false), ('DROP', 'DROP', NULL::varchar, 'Bỏ trường', '{}', false)) AS s(c, t, p, n, d, r)
  ON CONFLICT (tenant_id, code) DO NOTHING;
  INSERT INTO ph09_privacy.tenant_setting (id, tenant_id, setting_key, value, floor_value, ceiling_value, created_by, updated_by)
  SELECT md5('ph09-setting:' || p_tenant || ':' || s.k)::uuid, p_tenant, s.k, s.v::jsonb, s.lo::jsonb, s.hi::jsonb, 'system:seed', 'system:seed'
  FROM (VALUES ('09.scan.sample-rows', '10000', '1000', '100000'), ('09.scan.schedule-cron', '"0 2 * * 0"', NULL::text, NULL::text), ('09.scan.confidence', '0.8', '0.5', '0.99'), ('09.request.sla-days', '10', '3', '30'), ('09.grant.max-days', '365', '30', '730'), ('09.grant.renew-max', '3', '0', '10'), ('09.grant.expiring-notice-days', '30', '7', '90'), ('09.grant.require-restricted', 'false', NULL::text, NULL::text), ('09.bundle.debounce-seconds', '10', '1', '60'), ('09.bundle.valid-minutes', '60', '15', '240'), ('09.plan.cache-seconds', '300', '60', '300'), ('09.consent.cache-seconds', '60', '0', '60'), ('09.decision.cache-seconds', '15', '0', '15'), ('09.feature.dsr-ph11', 'false', NULL::text, NULL::text), ('09.feature.l-diversity', 'false', NULL::text, NULL::text), ('09.feature.auto-confirm-mvp', 'false', NULL::text, NULL::text), ('09.api.rate-user-per-min', '300', '60', '1200'), ('09.api.rate-du-per-sec', '2000', '500', '5000'), ('09.anomaly.quota-warn-percent', '80', '50', '95'), ('09.anomaly.bulk-threshold', '1000', '100', '100000'), ('09.anomaly.auto-suspend', 'false', NULL::text, NULL::text), ('09.mask.reveal-seconds', '60', '30', '60'), ('09.mask.reveal-max-per-hour', '20', '1', '50'), ('09.mask.reveal-alert-per-hour', '10', '1', '50'), ('09.log.scan-cron', '"0 3 * * *"', NULL::text, NULL::text), ('09.pseudo.key-rotate-days', '365', '90', '730'), ('09.pseudo.min-rotate-days', '30', '7', '90'), ('09.pseudo.destroy-delay-days', '30', '7', '90'), ('09.reid.approval-ttl-hours', '24', '1', '72'), ('09.reid.exec-window-minutes', '30', '5', '120'), ('09.anon.k-min', '10', '10', '100'), ('09.anon.risk-medium-above', '0.05', '0.01', '0.1'), ('09.anon.risk-high-above', '0.1', '0.05', '0.2'), ('09.ai.allow-restricted', 'false', NULL::text, NULL::text), ('09.retention.run-cron', '"0 1 * * *"', NULL::text, NULL::text), ('09.retention.overdue-days', '7', '1', '30'), ('09.shred.delay-days', '30', '7', '90'), ('09.dsr.sla-days', '10', '5', '30'), ('09.dsr.remind-days', '3', '1', '7'), ('09.breach.alert-hours', '[24, 48, 60]', NULL::text, NULL::text), ('09.dpia.review-months', '12', '3', '12'), ('09.audit.query-max-days', '90', '7', '366'), ('09.report.schedule-cron', '"0 6 1 * *"', NULL::text, NULL::text)) AS s(k, v, lo, hi)
  ON CONFLICT (tenant_id, setting_key) DO NOTHING;
  INSERT INTO ph09_privacy.log_mask_config (id, tenant_id, patterns, created_by, updated_by)
  VALUES (md5('ph09-logmask:' || p_tenant)::uuid, p_tenant, ARRAY['NATIONAL_ID_12', 'PHONE_VN', 'BANK_CARD_LUHN', 'EMAIL'], 'system:seed', 'system:seed')
  ON CONFLICT (tenant_id) DO NOTHING;
  -- Lịch lưu giữ của chính PH-09: tạo DRAFT, thêm dòng, rồi kích hoạt (người duyệt khác người soạn).
  INSERT INTO ph09_privacy.retention_schedule (id, tenant_id, schedule_code, version_no, status, description, created_by, updated_by)
  VALUES (md5('ph09-ret:' || p_tenant)::uuid, p_tenant, 'PH09-OWN', 1, 'DRAFT', 'Lịch lưu giữ của chính PH-09 (chương 7 D03-03-PH09)', 'system:seed', 'system:seed')
  ON CONFLICT DO NOTHING;
  INSERT INTO ph09_privacy.retention_schedule_line (id, tenant_id, schedule_id, entity, category, retain_days, action, owner, created_by, updated_by)
  SELECT md5('ph09-retline:' || p_tenant || ':' || s.e)::uuid, p_tenant, md5('ph09-ret:' || p_tenant)::uuid, s.e, s.c, s.d, s.a, s.o, 'system:seed', 'system:seed'
  FROM (VALUES ('subject_request', NULL::varchar, 1825, 'ARCHIVE', 'SO'), ('subject_verification', NULL::varchar, 1825, 'ARCHIVE', 'SO'), ('subject_task', NULL::varchar, 1825, 'ARCHIVE', 'SO'), ('consent_record', NULL::varchar, 1825, 'ARCHIVE', 'SO'), ('breach_case', NULL::varchar, 3650, 'ARCHIVE', 'SO'), ('breach_notification', NULL::varchar, 3650, 'ARCHIVE', 'SO'), ('reveal_grant', NULL::varchar, 365, 'DELETE', 'TA'), ('usage_counter', NULL::varchar, 400, 'DELETE', 'TA'), ('usage_anomaly', NULL::varchar, 730, 'ARCHIVE', 'SO'), ('scan_run', NULL::varchar, 365, 'DELETE', 'TA'), ('scan_finding', NULL::varchar, 365, 'DELETE', 'TA'), ('leak_finding', NULL::varchar, 365, 'DELETE', 'TA'), ('mask_simulation', NULL::varchar, 180, 'DELETE', 'TA'), ('privacy_audit_event', NULL::varchar, 395, 'ARCHIVE', 'SO'), ('policy_bundle', NULL::varchar, 90, 'DELETE', 'TA'), ('outbox_event', NULL::varchar, 3, 'DELETE', 'TA'), ('inbox_event', NULL::varchar, 7, 'DELETE', 'TA')) AS s(e, c, d, a, o)
  WHERE EXISTS (SELECT 1 FROM ph09_privacy.retention_schedule WHERE id = md5('ph09-ret:' || p_tenant)::uuid AND status = 'DRAFT')
  ON CONFLICT DO NOTHING;
  UPDATE ph09_privacy.retention_schedule SET status = 'ACTIVE', decided_by = 'system:policy', decided_at = now(), activated_at = now(), submitted_by = 'system:seed'
  WHERE id = md5('ph09-ret:' || p_tenant)::uuid AND status = 'DRAFT';
END
$p$;
COMMENT ON PROCEDURE ph09_privacy.p_seed_tenant(text) IS 'Gọi khi khởi tạo tenant: 4 mức, 18 loại DLCN, 7 mẫu phát hiện, 7 cơ sở pháp lý, 12 kiểu che, 36 tham số 09.*, cấu hình log, lịch lưu giữ PH09-OWN.';
--rollback DROP PROCEDURE IF EXISTS ph09_privacy.p_seed_tenant(text);
