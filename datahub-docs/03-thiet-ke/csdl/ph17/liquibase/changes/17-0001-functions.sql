--liquibase formatted sql
-- Nguồn: ddl/ph17_assist.sql · 17-0001-functions.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph17:ph17-0010-fn-touch splitStatements:false
CREATE OR REPLACE FUNCTION ph17_assist.tg_touch() RETURNS trigger
  LANGUAGE plpgsql AS $f$
BEGIN
  NEW.updated_at := now();
  IF NEW.version IS NOT DISTINCT FROM OLD.version THEN
    NEW.version := OLD.version + 1;
  END IF;
  RETURN NEW;
END
$f$;
COMMENT ON FUNCTION ph17_assist.tg_touch() IS 'Cập nhật updated_at, tăng version (khóa lạc quan, ETag, BR-17-087).';
--rollback DROP FUNCTION IF EXISTS ph17_assist.tg_touch();

--changeset ph17:ph17-0011-fn-immutable splitStatements:false
CREATE OR REPLACE FUNCTION ph17_assist.tg_immutable() RETURNS trigger
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
COMMENT ON FUNCTION ph17_assist.tg_immutable() IS 'Chặn sửa các cột truyền qua tham số trigger: mã nghiệp vụ, khóa tham chiếu, bằng chứng đã chốt.';
--rollback DROP FUNCTION IF EXISTS ph17_assist.tg_immutable();

--changeset ph17:ph17-0012-fn-append-only splitStatements:false
CREATE OR REPLACE FUNCTION ph17_assist.tg_append_only() RETURNS trigger
  LANGUAGE plpgsql AS $f$
BEGIN
  RAISE EXCEPTION 'Bảng % chỉ thêm, không sửa, xóa dòng (nhật ký, vết)', TG_TABLE_NAME USING ERRCODE = '55000';
END
$f$;
COMMENT ON FUNCTION ph17_assist.tg_append_only() IS 'Chặn UPDATE, DELETE dòng của bảng chỉ thêm (invocation_log, model_health_probe, notice_acceptance, knowledge_deletion). Dọn bằng DETACH, DROP phân vùng dưới ph17_owner.';
--rollback DROP FUNCTION IF EXISTS ph17_assist.tg_append_only();

--changeset ph17:ph17-0013-fn-frozen splitStatements:false
-- Phiên bản ở trạng thái đã chốt không đổi nội dung: đối số đầu là danh sách trạng thái (ngăn cách bằng dấu phẩy), các đối số sau là tên cột.
CREATE OR REPLACE FUNCTION ph17_assist.tg_frozen() RETURNS trigger
  LANGUAGE plpgsql AS $f$
DECLARE
  st text[] := string_to_array(TG_ARGV[0], ',');
  i integer;
BEGIN
  IF (to_jsonb(OLD) ->> 'status') = ANY (st) THEN
    FOR i IN 1 .. array_length(TG_ARGV, 1) - 1 LOOP
      IF (to_jsonb(NEW) -> TG_ARGV[i]) IS DISTINCT FROM (to_jsonb(OLD) -> TG_ARGV[i]) THEN
        RAISE EXCEPTION 'Đối tượng ở trạng thái % không sửa được cột % (tạo phiên bản mới)', OLD.status, TG_ARGV[i] USING ERRCODE = '55000';
      END IF;
    END LOOP;
  END IF;
  RETURN NEW;
END
$f$;
COMMENT ON FUNCTION ph17_assist.tg_frozen() IS 'Điều khoản đã công bố, phiên bản mô hình từ EVALUATING, phiên bản prompt từ PENDING_APPROVAL không đổi nội dung (ERR-17-024, 040).';
--rollback DROP FUNCTION IF EXISTS ph17_assist.tg_frozen();

--changeset ph17:ph17-0014-fn-transition splitStatements:false
-- Chuyển trạng thái chỉ theo máy trạng thái của FRS 4.3 đến 4.7: đối số một là tên cột, đối số hai là danh sách 'TỪ>ĐẾN' ngăn cách bằng dấu phẩy.
CREATE OR REPLACE FUNCTION ph17_assist.tg_transition() RETURNS trigger
  LANGUAGE plpgsql AS $f$
DECLARE
  o text := to_jsonb(OLD) ->> TG_ARGV[0];
  n text := to_jsonb(NEW) ->> TG_ARGV[0];
BEGIN
  IF o IS DISTINCT FROM n AND NOT (COALESCE(o, '') || '>' || COALESCE(n, '')) = ANY (string_to_array(TG_ARGV[1], ',')) THEN
    RAISE EXCEPTION 'ERR-17-006: % không chuyển được từ % sang % (cột %)', TG_TABLE_NAME, o, n, TG_ARGV[0] USING ERRCODE = '55000';
  END IF;
  RETURN NEW;
END
$f$;
COMMENT ON FUNCTION ph17_assist.tg_transition() IS 'Cưỡng chế máy trạng thái: tenant_policy, model_version, model_provider, model_route, knowledge_document, suggestion, prompt_version, policy_change và các bảng có vòng đời.';
--rollback DROP FUNCTION IF EXISTS ph17_assist.tg_transition();

--changeset ph17:ph17-0015-fn-helpers splitStatements:false
CREATE OR REPLACE FUNCTION ph17_assist.fn_ctx_ok(p_ctx jsonb) RETURNS boolean
  LANGUAGE sql IMMUTABLE PARALLEL SAFE AS $f$
  SELECT jsonb_typeof(p_ctx) = 'object'
     AND NOT EXISTS (SELECT 1 FROM jsonb_object_keys(p_ctx) k WHERE k NOT IN ('route', 'objectId', 'errorCode', 'tab'))
$f$;
COMMENT ON FUNCTION ph17_assist.fn_ctx_ok(jsonb) IS 'Ngữ cảnh màn hình chỉ gồm route, objectId, errorCode, tab; không giá trị dữ liệu (BR-17-032).';

CREATE OR REPLACE FUNCTION ph17_assist.fn_log_grant_ok(p_conv uuid, p_created timestamptz) RETURNS boolean
  LANGUAGE plpgsql STABLE AS $f$
BEGIN
  RETURN EXISTS (SELECT 1 FROM ph17_assist.log_access_grant g
                 WHERE g.tenant_id = current_setting('app.tenant_id', true) AND g.grantee = current_setting('app.user_id', true)
                   AND g.state = 'ACTIVE' AND g.expires_at > now()
                   AND ((g.scope_kind = 'CONVERSATION' AND g.conversation_id = p_conv)
                     OR (g.scope_kind = 'RANGE' AND p_created >= g.range_from AND p_created < g.range_to)));
END
$f$;
COMMENT ON FUNCTION ph17_assist.fn_log_grant_ok(uuid, timestamptz) IS 'Người đang đăng nhập (app.user_id) có phiếu truy cập nhật ký còn hiệu lực cho hội thoại hoặc khoảng thời gian (BR-17-074); mở khóa RLS theo người dùng của conversation, message.';

CREATE OR REPLACE FUNCTION ph17_assist.fn_setting_num(p_tenant text, p_key text, p_default numeric) RETURNS numeric
  LANGUAGE plpgsql STABLE AS $f$
DECLARE
  v numeric;
BEGIN
  SELECT (value #>> '{}')::numeric INTO v FROM ph17_assist.tenant_setting WHERE tenant_id = p_tenant AND setting_key = p_key;
  RETURN COALESCE(v, p_default);
END
$f$;
COMMENT ON FUNCTION ph17_assist.fn_setting_num(text, text, numeric) IS 'Đọc tham số số 17.* của tenant từ bản chụp, thiếu thì dùng mặc định (BR-17-078).';
--rollback DROP FUNCTION IF EXISTS ph17_assist.fn_setting_num(text, text, numeric); DROP FUNCTION IF EXISTS ph17_assist.fn_log_grant_ok(uuid, timestamptz); DROP FUNCTION IF EXISTS ph17_assist.fn_ctx_ok(jsonb);

--changeset ph17:ph17-0016-fn-rls splitStatements:false
-- Ba mẫu RLS. Đọc: tenant của phiên (và COMMON với bảng dùng chung). Ghi: chỉ dòng của tenant Tnn; dòng COMMON chỉ vai ph17_platform khi phiên app.tenant_id = COMMON.
CREATE OR REPLACE PROCEDURE ph17_assist.p_enable_rls(p_table regclass)
  LANGUAGE plpgsql AS $p$
DECLARE
  t text := p_table::text;
  n text := split_part(p_table::text, '.', 2);
  r text := $w$(tenant_id = current_setting('app.tenant_id', false))$w$;
  w text := $w$(tenant_id = current_setting('app.tenant_id', false) AND tenant_id ~ '^T[0-9]{2}$')$w$;
BEGIN
  EXECUTE format('ALTER TABLE %s ENABLE ROW LEVEL SECURITY', t);
  EXECUTE format('ALTER TABLE %s FORCE ROW LEVEL SECURITY', t);
  EXECUTE format('CREATE POLICY rls_%s_select ON %s FOR SELECT USING %s', n, t, r);
  EXECUTE format('CREATE POLICY rls_%s_insert ON %s FOR INSERT WITH CHECK %s', n, t, w);
  EXECUTE format('CREATE POLICY rls_%s_update ON %s FOR UPDATE USING %s WITH CHECK %s', n, t, w, w);
  EXECUTE format('CREATE POLICY rls_%s_delete ON %s FOR DELETE USING %s', n, t, w);
END
$p$;
COMMENT ON PROCEDURE ph17_assist.p_enable_rls(regclass) IS 'Bật FORCE RLS và 4 chính sách theo tenant (D03-10 §4, ADR-003, BR-17-086).';

CREATE OR REPLACE PROCEDURE ph17_assist.p_enable_rls_common(p_table regclass)
  LANGUAGE plpgsql AS $p$
DECLARE
  t text := p_table::text;
  n text := split_part(p_table::text, '.', 2);
  r text := $w$(tenant_id = current_setting('app.tenant_id', false) OR tenant_id = 'COMMON')$w$;
  w text := $w$(tenant_id = current_setting('app.tenant_id', false) AND tenant_id ~ '^T[0-9]{2}$')$w$;
  c text := $w$(tenant_id = 'COMMON' AND current_setting('app.tenant_id', false) = 'COMMON')$w$;
BEGIN
  EXECUTE format('ALTER TABLE %s ENABLE ROW LEVEL SECURITY', t);
  EXECUTE format('ALTER TABLE %s FORCE ROW LEVEL SECURITY', t);
  EXECUTE format('CREATE POLICY rls_%s_select ON %s FOR SELECT USING %s', n, t, r);
  EXECUTE format('CREATE POLICY rls_%s_insert ON %s FOR INSERT WITH CHECK %s', n, t, w);
  EXECUTE format('CREATE POLICY rls_%s_update ON %s FOR UPDATE USING %s WITH CHECK %s', n, t, w, w);
  EXECUTE format('CREATE POLICY rls_%s_delete ON %s FOR DELETE USING %s', n, t, w);
  EXECUTE format('CREATE POLICY rls_%s_platform ON %s FOR ALL TO ph17_platform USING %s WITH CHECK %s', n, t, c, c);
END
$p$;
COMMENT ON PROCEDURE ph17_assist.p_enable_rls_common(regclass) IS 'Như p_enable_rls, thêm đọc dòng COMMON cho mọi tenant và chính sách ghi dòng COMMON riêng cho vai ph17_platform (PA khai báo nhà cung cấp, mô hình, ca đỏ, nguồn dùng chung).';

CREATE OR REPLACE PROCEDURE ph17_assist.p_enable_rls_user(p_table regclass, p_grant text, p_job_delete text)
  LANGUAGE plpgsql AS $p$
DECLARE
  t text := p_table::text;
  n text := split_part(p_table::text, '.', 2);
  w text := $w$(tenant_id = current_setting('app.tenant_id', false) AND tenant_id ~ '^T[0-9]{2}$')$w$;
  u text := $w$(user_id = current_setting('app.user_id', true))$w$;
BEGIN
  EXECUTE format('ALTER TABLE %s ENABLE ROW LEVEL SECURITY', t);
  EXECUTE format('ALTER TABLE %s FORCE ROW LEVEL SECURITY', t);
  EXECUTE format('CREATE POLICY rls_%s_select ON %s FOR SELECT USING (%s AND (%s OR %s))', n, t, w, u, p_grant);
  EXECUTE format('CREATE POLICY rls_%s_insert ON %s FOR INSERT WITH CHECK (%s AND %s)', n, t, w, u);
  EXECUTE format('CREATE POLICY rls_%s_update ON %s FOR UPDATE USING (%s AND %s) WITH CHECK (%s AND %s)', n, t, w, u, w, u);
  EXECUTE format('CREATE POLICY rls_%s_job_select ON %s FOR SELECT TO ph17_job USING %s', n, t, w);
  EXECUTE format('CREATE POLICY rls_%s_job_delete ON %s FOR DELETE TO ph17_job USING (%s AND (%s))', n, t, w, p_job_delete);
END
$p$;
COMMENT ON PROCEDURE ph17_assist.p_enable_rls_user(regclass, text, text) IS 'RLS theo tenant và người dùng (BR-17-033): chỉ chủ dòng đọc, ghi; người có phiếu truy cập còn hiệu lực đọc được; vai ph17_job đọc và xóa dòng hết hạn theo lịch lưu giữ.';
--rollback DROP PROCEDURE IF EXISTS ph17_assist.p_enable_rls_user(regclass, text, text); DROP PROCEDURE IF EXISTS ph17_assist.p_enable_rls_common(regclass); DROP PROCEDURE IF EXISTS ph17_assist.p_enable_rls(regclass);

--changeset ph17:ph17-0017-fn-partitions splitStatements:false
CREATE OR REPLACE PROCEDURE ph17_assist.p_ensure_partitions(p_table regclass, p_from date, p_count integer)
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
COMMENT ON PROCEDURE ph17_assist.p_ensure_partitions(regclass, date, integer) IS 'Tạo trước phân vùng tháng cho invocation_log, model_health_probe. PartitionMaintenanceJob gọi hằng ngày; dọn bằng DETACH, DROP dưới ph17_owner.';
--rollback DROP PROCEDURE IF EXISTS ph17_assist.p_ensure_partitions(regclass, date, integer);

--changeset ph17:ph17-0018-fn-release-gate splitStatements:false
-- Cổng phát hành (BR-17-015, 064, 066 đến 068): APPROVED hoặc ACTIVE chỉ khi lượt đánh giá chuẩn đạt, lượt ca đỏ không lọt và bộ ca đỏ có từ 50 ca đang hoạt động.
CREATE OR REPLACE FUNCTION ph17_assist.tg_release_gate() RETURNS trigger
  LANGUAGE plpgsql AS $f$
DECLARE
  ev record;
  rt record;
  n integer;
  min_score numeric;
BEGIN
  IF NEW.status IS NOT DISTINCT FROM OLD.status OR NEW.status NOT IN ('APPROVED', 'ACTIVE') THEN
    RETURN NEW;
  END IF;
  min_score := ph17_assist.fn_setting_num(NEW.tenant_id, '17.eval.min-score', 0.80);
  SELECT * INTO ev FROM ph17_assist.eval_run
   WHERE id = NEW.eval_run_id AND tenant_id = NEW.tenant_id AND run_kind = 'EVAL' AND subject_id = NEW.id;
  IF NOT FOUND OR ev.status <> 'PASSED' OR ev.cases_total < 30 OR ev.score < min_score THEN
    RAISE EXCEPTION 'ERR-17-072: chưa đạt cổng phát hành, đánh giá chuẩn chưa đạt ngưỡng %', min_score USING ERRCODE = '23514';
  END IF;
  SELECT * INTO rt FROM ph17_assist.eval_run
   WHERE id = NEW.redteam_run_id AND tenant_id = NEW.tenant_id AND run_kind = 'REDTEAM' AND subject_id = NEW.id;
  IF NOT FOUND OR rt.status <> 'PASSED' OR rt.cases_leaked <> 0 OR rt.pass_rate <> 100 THEN
    RAISE EXCEPTION 'ERR-17-073: ca đỏ chưa bị chặn hết nên không phát hành được' USING ERRCODE = '23514';
  END IF;
  SELECT count(*) INTO n FROM ph17_assist.redteam_case WHERE tenant_id IN (NEW.tenant_id, 'COMMON') AND status = 'ACTIVE';
  IF n < 50 THEN
    RAISE EXCEPTION 'ERR-17-075: bộ ca đỏ cần tối thiểu 50 ca đang hoạt động (hiện có %)', n USING ERRCODE = '23514';
  END IF;
  RETURN NEW;
END
$f$;
COMMENT ON FUNCTION ph17_assist.tg_release_gate() IS 'Cổng phát hành của phiên bản mô hình (APPROVED) và phiên bản prompt (ACTIVE).';
--rollback DROP FUNCTION IF EXISTS ph17_assist.tg_release_gate();

--changeset ph17:ph17-0019-fn-tenant-model splitStatements:false
-- Bật phiên bản cho tenant (BR-17-004, 017, 018): phiên bản APPROVED, mô hình ngoài cần chính sách cho phép, danh sách trắng và nhà cung cấp ACTIVE; dự phòng cùng loại, đã duyệt, không từ nội bộ sang ngoài.
CREATE OR REPLACE FUNCTION ph17_assist.tg_tenant_model_rules() RETURNS trigger
  LANGUAGE plpgsql AS $f$
DECLARE
  v_status text; v_kind text; v_pk text; v_pst text;
  f_status text; f_kind text; f_pk text;
BEGIN
  SELECT mv.status, m.model_kind, p.provider_kind, p.status INTO v_status, v_kind, v_pk, v_pst
    FROM ph17_assist.model_version mv JOIN ph17_assist.model m ON m.id = mv.model_id JOIN ph17_assist.model_provider p ON p.id = m.provider_id
   WHERE mv.id = NEW.version_id;
  IF NEW.enabled THEN
    IF v_status IS DISTINCT FROM 'APPROVED' THEN
      RAISE EXCEPTION 'ERR-17-030: phiên bản mô hình chưa được duyệt nên chưa dùng được' USING ERRCODE = '23514';
    END IF;
    IF v_kind <> NEW.model_kind THEN
      RAISE EXCEPTION 'ERR-17-003: model_kind không khớp loại của mô hình' USING ERRCODE = '23514';
    END IF;
    IF v_pk = 'EXTERNAL' THEN
      IF v_pst <> 'ACTIVE' OR NOT EXISTS (SELECT 1 FROM ph17_assist.tenant_policy WHERE tenant_id = NEW.tenant_id AND external_allowed) THEN
        RAISE EXCEPTION 'ERR-17-016: mô hình ngoài chưa được phép (chính sách tenant hoặc nhà cung cấp chưa đủ điều kiện)' USING ERRCODE = '23514';
      END IF;
      IF NOT EXISTS (SELECT 1 FROM ph17_assist.provider_grant g JOIN ph17_assist.model m ON m.provider_id = g.provider_id JOIN ph17_assist.model_version mv ON mv.model_id = m.id
                      WHERE g.tenant_id = NEW.tenant_id AND mv.id = NEW.version_id AND g.revoked_at IS NULL AND (g.effective_to IS NULL OR g.effective_to >= current_date)) THEN
        RAISE EXCEPTION 'ERR-17-017: nhà cung cấp chưa nằm trong danh sách trắng của tenant' USING ERRCODE = '23514';
      END IF;
    END IF;
  END IF;
  IF NEW.fallback_version_id IS NOT NULL THEN
    SELECT mv.status, m.model_kind, p.provider_kind INTO f_status, f_kind, f_pk
      FROM ph17_assist.model_version mv JOIN ph17_assist.model m ON m.id = mv.model_id JOIN ph17_assist.model_provider p ON p.id = m.provider_id
     WHERE mv.id = NEW.fallback_version_id;
    IF f_status IS DISTINCT FROM 'APPROVED' OR f_kind <> v_kind OR (v_pk = 'INTERNAL' AND f_pk = 'EXTERNAL') THEN
      RAISE EXCEPTION 'ERR-17-034: dự phòng phải cùng loại, đã duyệt và không chuyển từ nội bộ sang ngoài' USING ERRCODE = '23514';
    END IF;
  END IF;
  RETURN NEW;
END
$f$;
COMMENT ON FUNCTION ph17_assist.tg_tenant_model_rules() IS 'Quy tắc bật mô hình cho tenant và chọn dự phòng.';
--rollback DROP FUNCTION IF EXISTS ph17_assist.tg_tenant_model_rules();

--changeset ph17:ph17-0020-fn-chunk splitStatements:false
-- Đoạn chỉ vào chỉ mục khi tài liệu mức PUBLIC hoặc INTERNAL (BR-17-026); tài liệu bị bỏ, xóa hoặc đổi sang mức cao hơn thì xóa vật lý hết đoạn trong cùng giao dịch (BR-17-029).
CREATE OR REPLACE FUNCTION ph17_assist.tg_chunk_gate() RETURNS trigger
  LANGUAGE plpgsql AS $f$
DECLARE
  d_class text; d_status text;
BEGIN
  SELECT class_level, index_status INTO d_class, d_status FROM ph17_assist.knowledge_document WHERE tenant_id = NEW.tenant_id AND id = NEW.document_id;
  IF d_class IS NULL OR d_class NOT IN ('PUBLIC', 'INTERNAL') OR d_status IN ('DELETED', 'SKIPPED_CLASS') THEN
    RAISE EXCEPTION 'ERR-17-043: tài liệu mức % không được lập chỉ mục', COALESCE(d_class, 'chưa xác định') USING ERRCODE = '23514';
  END IF;
  IF NEW.class_level <> d_class THEN
    RAISE EXCEPTION 'ERR-17-043: class_level của đoạn phải bằng mức hiện hành của tài liệu (%)', d_class USING ERRCODE = '23514';
  END IF;
  RETURN NEW;
END
$f$;

CREATE OR REPLACE FUNCTION ph17_assist.tg_doc_purge_chunks() RETURNS trigger
  LANGUAGE plpgsql AS $f$
DECLARE
  n integer;
BEGIN
  IF NEW.index_status IN ('DELETED', 'SKIPPED_CLASS')
     OR (NEW.class_level IS DISTINCT FROM OLD.class_level AND (NEW.class_level IS NULL OR NEW.class_level NOT IN ('PUBLIC', 'INTERNAL'))) THEN
    DELETE FROM ph17_assist.knowledge_chunk WHERE tenant_id = OLD.tenant_id AND document_id = OLD.id;
    GET DIAGNOSTICS n = ROW_COUNT;
    NEW.chunk_count := 0;
    IF n > 0 THEN
      INSERT INTO ph17_assist.knowledge_deletion (id, tenant_id, source_id, document_id, reason, chunks_deleted, trigger_ref, created_by, updated_by)
      VALUES (gen_random_uuid(), OLD.tenant_id, OLD.source_id, OLD.id, COALESCE(NEW.delete_reason, 'CLASS_CHANGED'), n, 'db-trigger', NEW.updated_by, NEW.updated_by);
    END IF;
  END IF;
  RETURN NEW;
END
$f$;
COMMENT ON FUNCTION ph17_assist.tg_doc_purge_chunks() IS 'Xóa lan truyền ở mức CSDL: tài liệu DELETED, SKIPPED_CLASS hoặc mức không còn PUBLIC, INTERNAL thì không còn đoạn nào.';
--rollback DROP FUNCTION IF EXISTS ph17_assist.tg_doc_purge_chunks(); DROP FUNCTION IF EXISTS ph17_assist.tg_chunk_gate();

--changeset ph17:ph17-0021-fn-seed-tenant splitStatements:false
-- Khởi tạo tenant (PH-20): chính sách DISABLED, năng lực, công cụ, bộ lọc dựng sẵn, danh sách trắng liên kết, tham số 17.*, câu hỏi mẫu. Chạy lại không nhân bản.
CREATE OR REPLACE PROCEDURE ph17_assist.p_seed_tenant(p_tenant text)
  LANGUAGE plpgsql AS $p$
BEGIN
  PERFORM set_config('app.tenant_id', p_tenant, true);
  INSERT INTO ph17_assist.tenant_policy (id, tenant_id, created_by, updated_by) VALUES (md5('ph17-policy:' || p_tenant)::uuid, p_tenant, 'system:seed', 'system:seed')
  ON CONFLICT (tenant_id) DO NOTHING;
  INSERT INTO ph17_assist.capability_policy (id, tenant_id, capability, role_group, enabled, created_by, updated_by)
  SELECT md5('ph17-cap:' || p_tenant || ':' || c)::uuid, p_tenant, c, 'ALL_READERS', false, 'system:seed', 'system:seed' FROM unnest(ARRAY['SEARCH', 'MAPPING', 'EXPLAIN']) c
  ON CONFLICT (tenant_id, capability, role_group) DO NOTHING;
  INSERT INTO ph17_assist.tool_definition (id, tenant_id, tool_code, name, target_module, target_ref, scope, capabilities, created_by, updated_by)
  SELECT md5('ph17-tool:' || p_tenant || ':' || s.c)::uuid, p_tenant, s.c, s.n, s.m, s.r, s.s, s.k::varchar[], 'system:seed', 'system:seed'
  FROM (VALUES ('SEARCH_API', 'Tìm mô tả API trong danh mục dịch vụ', 'PH02', 'catalog.search-apis', 'catalog:read', '{SEARCH}'), ('LOOKUP_CATALOG', 'Tra danh mục dùng chung', 'PH07', 'rdm.lookup-catalog', 'rdm:read', '{SEARCH,MAPPING}'), ('VIEW_FLOW', 'Xem mô tả luồng tích hợp', 'PH04', 'integration.get-flow', 'integration:read', '{SEARCH,EXPLAIN}'), ('VIEW_MAPPING_SCHEMA', 'Xem lược đồ ánh xạ của luồng', 'PH04', 'integration.get-mapping-schema', 'integration:read', '{MAPPING}'), ('VIEW_TOPIC', 'Xem mô tả topic sự kiện đã công bố', 'PH10', 'event.get-topic', 'event:read', '{SEARCH}'), ('FETCH_LOGS', 'Lấy log theo phạm vi quyền người dùng', 'PH13', 'observability.query-logs', 'observability:read', '{EXPLAIN}'), ('FETCH_TRACE', 'Lấy vết theo trace_id', 'PH13', 'observability.get-trace', 'observability:read', '{EXPLAIN}'), ('VIEW_DLQ_MESSAGE', 'Xem bản tin hàng đợi lỗi', 'PH18', 'ops.get-dlq-message', 'ops:read', '{EXPLAIN}'), ('GET_FIELD_CLASS', 'Tra phân loại trường dữ liệu', 'PH09', 'privacy.get-field-classification', 'privacy:read', '{MAPPING,EXPLAIN}')) AS s(c, n, m, r, s, k)
  ON CONFLICT (tenant_id, tool_code) DO NOTHING;
  INSERT INTO ph17_assist.guardrail_rule (id, tenant_id, rule_code, guardrail_kind, action, category, pattern_kind, pattern, description, builtin, created_by, updated_by)
  SELECT md5('ph17-guard:' || p_tenant || ':' || s.c)::uuid, p_tenant, s.c, s.k, s.a, s.g, s.t, s.p, s.d, true, 'system:seed', 'system:seed'
  FROM (VALUES ('GR-IN-INJECT-001', 'INPUT', 'BLOCK', 'PROMPT_INJECTION', 'DETECTOR', 'injection-classifier', 'Bộ phân loại dấu hiệu tiêm lệnh và đòi bỏ chỉ dẫn hệ thống'), ('GR-IN-FORBID-001', 'INPUT', 'BLOCK', 'FORBIDDEN', 'KEYWORD', 'danh-sach-noi-dung-cam', 'Danh sách nội dung cấm theo chính sách tỉnh'), ('GR-IN-PII-ID12', 'INPUT', 'MASK', 'PII', 'REGEX', '\b[0-9]{12}\b', 'Che số định danh 12 chữ số người dùng tự dán'), ('GR-IN-PII-PHONE', 'INPUT', 'MASK', 'PII', 'REGEX', '(\+84|0)[0-9]{9}\b', 'Che số điện thoại Việt Nam'), ('GR-IN-PII-SENS', 'INPUT', 'BLOCK', 'FORBIDDEN', 'DETECTOR', 'sensitive-pii', 'Từ chối khi có DLCN nhạy cảm (ERR-17-066)'), ('GR-OUT-PII-ID12', 'OUTPUT', 'MASK', 'PII', 'REGEX', '\b[0-9]{12}\b', 'Che mẫu số định danh ở đầu ra'), ('GR-OUT-SECRET-PEM', 'OUTPUT', 'BLOCK', 'SECRET', 'REGEX', 'BEGIN [A-Z ]*PRIVATE KEY', 'Chặn dạng khóa riêng'), ('GR-OUT-SECRET-BEARER', 'OUTPUT', 'BLOCK', 'SECRET', 'REGEX', '(?i)bearer\s+[A-Za-z0-9._~+/=-]{20,}', 'Chặn chuỗi mang tiền tố Bearer'), ('GR-OUT-SECRET-CONN', 'OUTPUT', 'BLOCK', 'SECRET', 'REGEX', '(?i)(jdbc|postgres(ql)?|mongodb)://[^\s]*:[^\s@]*@', 'Chặn chuỗi kết nối có mật khẩu'), ('GR-OUT-LINK-EXT', 'OUTPUT', 'MASK', 'LINK', 'REGEX', 'https?://', 'Bỏ liên kết ngoài danh sách trắng route nội bộ (BR-17-037)')) AS s(c, k, a, g, t, p, d)
  ON CONFLICT (tenant_id, rule_code) DO NOTHING;
  INSERT INTO ph17_assist.link_allowlist (id, tenant_id, route_prefix, note, created_by, updated_by) VALUES (md5('ph17-link:' || p_tenant)::uuid, p_tenant, '/', 'Mọi route nội bộ của cổng Datahub', 'system:seed', 'system:seed')
  ON CONFLICT (tenant_id, route_prefix) DO NOTHING;
  INSERT INTO ph17_assist.tenant_setting (id, tenant_id, setting_key, value, floor_value, ceiling_value, four_eyes, created_by, updated_by)
  SELECT md5('ph17-setting:' || p_tenant || ':' || s.k)::uuid, p_tenant, s.k, s.v::jsonb, s.lo::jsonb, s.hi::jsonb, s.f, 'system:seed', 'system:seed'
  FROM (VALUES ('17.enabled', 'false', NULL::text, NULL::text, true), ('17.feature.search', 'false', NULL::text, NULL::text, false), ('17.feature.mapping', 'false', NULL::text, NULL::text, false), ('17.feature.explain', 'false', NULL::text, NULL::text, false), ('17.feature.roles', '"ALL_READERS"', NULL::text, NULL::text, false), ('17.model.external-allowed', 'false', NULL::text, NULL::text, true), ('17.model.default-chat', '""', NULL::text, NULL::text, false), ('17.model.default-embed', '""', NULL::text, NULL::text, false), ('17.model.default-rerank', '""', NULL::text, NULL::text, false), ('17.model.fallback-enabled', 'true', NULL::text, NULL::text, false), ('17.model.timeout-seconds', '60', '10', '120', false), ('17.model.first-token-timeout-seconds', '10', '3', '30', false), ('17.quota.user-turns-per-day', '200', '10', '1000', false), ('17.quota.user-turns-per-minute', '10', '2', '30', false), ('17.quota.tenant-tokens-per-day', '2000000', '100000', '50000000', false), ('17.quota.warn-percent', '80', '50', '95', false), ('17.quota.du-calls-per-minute', '120', '10', '1000', false), ('17.input.max-chars', '4000', '500', '8000', false), ('17.output.max-tokens', '1500', '200', '4000', false), ('17.context.max-messages', '20', '4', '50', false), ('17.conversation.max-per-user', '200', '20', '1000', false), ('17.rag.top-k', '8', '3', '20', false), ('17.rag.min-score', '0.55', '0.3', '0.9', false), ('17.rag.hybrid-weight-vector', '0.6', '0', '1', false), ('17.rag.chunk-tokens', '400', '150', '800', false), ('17.rag.chunk-overlap', '50', '0', '200', false), ('17.index.full-cron', '"0 3 * * 0"', NULL::text, NULL::text, false), ('17.index.stale-days', '7', '1', '30', false), ('17.index.pause-purge-days', '30', '7', '180', false), ('17.upload.max-mb', '20', '1', '50', false), ('17.tool.max-calls-per-turn', '5', '1', '10', false), ('17.tool.timeout-seconds', '10', '3', '30', false), ('17.tool.max-depth', '3', '1', '5', false), ('17.mapping.sample-rows', '3', '0', '10', false), ('17.suggestion.ttl-hours', '24', '1', '72', false), ('17.explain.log-lines-max', '200', '20', '500', false), ('17.explain.trace-window-minutes', '60', '5', '240', false), ('17.log.retention-days', '90', '90', '365', true), ('17.log.access-reason-min-chars', '20', '20', '200', false), ('17.log.export-max-days', '31', '1', '92', false), ('17.breaker.error-rate', '50', '20', '90', false), ('17.breaker.open-seconds', '30', '10', '300', false), ('17.eval.min-score', '0.8', '0.5', '0.99', false), ('17.eval.regression-tolerance', '0.03', '0', '0.1', false), ('17.redteam.min-pass-rate', '100', '100', '100', false), ('17.feedback.sla-days', '5', '1', '30', false), ('17.quality.alert-drop-percent', '10', '5', '50', false), ('17.notice.reaccept-days', '365', '30', '730', false), ('17.report.cost-per-1k-tokens', '0', '0', '1000', false)) AS s(k, v, lo, hi, f)
  ON CONFLICT (tenant_id, setting_key) DO NOTHING;
  INSERT INTO ph17_assist.suggested_question (id, tenant_id, question_text, route_pattern, capability, sort_no, created_by, updated_by)
  SELECT md5('ph17-q:' || p_tenant || ':' || s.q)::uuid, p_tenant, s.q, s.r, s.c, 100, 'system:seed', 'system:seed'
  FROM (VALUES ('Tìm API tra cứu danh mục hành chính', '/dich-vu', 'SEARCH'), ('Dịch vụ nào cung cấp dữ liệu dân cư', '/dich-vu', 'SEARCH'), ('Gợi ý ánh xạ trường nguồn sang đích', '/tich-hop/*', 'MAPPING'), ('Gợi ý ánh xạ mã địa phương sang danh mục chuẩn', '/danh-muc/*', 'MAPPING'), ('Giải thích mã lỗi đang hiển thị', '/*', 'EXPLAIN'), ('Vì sao bản tin này vào hàng đợi lỗi', '/van-hanh/*', 'EXPLAIN')) AS s(q, r, c)
  ON CONFLICT DO NOTHING;
END
$p$;
COMMENT ON PROCEDURE ph17_assist.p_seed_tenant(text) IS 'Gọi khi khởi tạo tenant: tenant_policy DISABLED, 3 năng lực, 9 công cụ chỉ đọc, 10 quy tắc lọc, 1 route trắng, 49 tham số 17.*, 6 câu hỏi mẫu.';
--rollback DROP PROCEDURE IF EXISTS ph17_assist.p_seed_tenant(text);
