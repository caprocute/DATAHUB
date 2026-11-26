-- =============================================================================
-- D03-03-PH13 · Kiểm thử DDL ph13_audit và ph13_obs: cô lập tenant, chỉ thêm, chuỗi băm liền kề,
-- bao phủ đầu chuỗi, lưu trữ phân vùng, vòng đời cảnh báo, luật, an ninh, tham số.
-- Chạy sau ph13_audit.sql và ph13_obs.sql trên CSDL RỖNG (bảng kiểm toán chỉ thêm nên không chạy lại được):
--   psql -v ON_ERROR_STOP=1 -d datahub -f ph13_isolation_test.sql
-- Mỗi khối kiểm một điều; lỗi mong đợi bị bắt và ghi PASS, sai thì RAISE dừng tệp.
-- Tương ứng nhóm ca cô lập tenant, bất biến nhật ký, tách nhiệm của D05-02-PH13.
-- =============================================================================
\set ON_ERROR_STOP on

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'dh_platform_app') THEN
    CREATE ROLE dh_platform_app LOGIN NOBYPASSRLS IN ROLE ph13_app, ph13_obs_app;
  ELSE
    GRANT ph13_app, ph13_obs_app TO dh_platform_app;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'dh_platform_verify') THEN
    CREATE ROLE dh_platform_verify LOGIN NOBYPASSRLS IN ROLE ph13_verify;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'dh_platform_archive') THEN
    CREATE ROLE dh_platform_archive LOGIN NOBYPASSRLS IN ROLE ph13_archive;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'dh_platform_ro') THEN
    CREATE ROLE dh_platform_ro LOGIN NOBYPASSRLS IN ROLE ph13_readonly;
  END IF;
END $$;

-- ---------- Hàm trợ giúp (bảng tạm của phiên) ----------
CREATE FUNCTION pg_temp.expect_fail(p_name text, p_state text, VARIADIC p_sql text[]) RETURNS void LANGUAGE plpgsql AS $$
DECLARE s text;
BEGIN
  BEGIN
    FOREACH s IN ARRAY p_sql LOOP EXECUTE s; END LOOP;
  EXCEPTION WHEN OTHERS THEN
    IF SQLSTATE = p_state THEN RAISE NOTICE 'PASS %', p_name; RETURN; END IF;
    RAISE EXCEPTION 'FAIL %: mong % nhưng nhận % (%)', p_name, p_state, SQLSTATE, SQLERRM;
  END;
  RAISE EXCEPTION 'FAIL %: câu lệnh không lỗi', p_name;
END $$;

CREATE FUNCTION pg_temp.expect_ok(p_name text, VARIADIC p_sql text[]) RETURNS void LANGUAGE plpgsql AS $$
DECLARE s text;
BEGIN
  FOREACH s IN ARRAY p_sql LOOP EXECUTE s; END LOOP;
  RAISE NOTICE 'PASS %', p_name;
EXCEPTION WHEN OTHERS THEN
  RAISE EXCEPTION 'FAIL %: lỗi % (%)', p_name, SQLSTATE, SQLERRM;
END $$;

CREATE FUNCTION pg_temp.count_rows(p_sql text) RETURNS bigint LANGUAGE plpgsql AS $$
DECLARE n bigint;
BEGIN EXECUTE p_sql INTO n; RETURN n; END $$;

CREATE FUNCTION pg_temp.expect_count(p_name text, p_sql text, p_expected bigint) RETURNS void LANGUAGE plpgsql AS $$
DECLARE n bigint := pg_temp.count_rows(p_sql);
BEGIN
  IF n <> p_expected THEN RAISE EXCEPTION 'FAIL %: có % dòng, mong %', p_name, n, p_expected; END IF;
  RAISE NOTICE 'PASS %', p_name;
END $$;

-- Thêm n bản ghi liền kề vào chuỗi của tenant rồi (tuỳ chọn) nhích đầu chuỗi, như ChainWriter.
CREATE FUNCTION pg_temp.append_n(p_tenant text, p_n int, p_at timestamptz DEFAULT now(), p_advance boolean DEFAULT true,
                                 p_skip int DEFAULT 0, p_bad_prev boolean DEFAULT false) RETURNS void LANGUAGE plpgsql AS $$
DECLARE c record; prev text; sq bigint; h text; i int; rec timestamptz;
BEGIN
  SELECT * INTO c FROM ph13_audit.audit_chain WHERE tenant_id = p_tenant;
  prev := c.head_hash; sq := c.head_seq + p_skip; rec := greatest(p_at, coalesce(c.last_recorded_at, p_at));
  FOR i IN 1 .. p_n LOOP
    sq := sq + 1;
    IF p_bad_prev AND i = 1 THEN prev := repeat('a', 64); END IF;
    h := ph13_audit.fn_hash(prev, p_tenant || ':' || sq);
    INSERT INTO ph13_audit.audit_event (id, tenant_id, seq, occurred_at, recorded_at, actor_type, actor_id, actor_name, source_ip, user_agent,
                                        action, object_type, object_id, outcome, trace_id, source_du, prev_hash, hash)
    VALUES (gen_random_uuid(), p_tenant, sq, rec, rec, 'USER', 'u-' || p_tenant, 'Người dùng', '10.0.0.1', 'test',
            'CATALOG.PUBLISH', 'catalog', 'DM_X', 'SUCCESS', md5(p_tenant || sq), 'dh-data', prev, h);
    prev := h;
  END LOOP;
  IF p_advance THEN
    UPDATE ph13_audit.audit_chain SET head_seq = sq, head_hash = prev, last_recorded_at = rec WHERE tenant_id = p_tenant;
  END IF;
END $$;

-- ---------- Dữ liệu nền: khóa ký và chuỗi ----------
SET ROLE dh_platform_app;
SET app.tenant_id = 'PLATFORM';
INSERT INTO ph13_audit.audit_signing_key (id, key_version, public_key_pem, created_by, updated_by)
VALUES (gen_random_uuid(), 1, E'-----BEGIN PUBLIC KEY-----\nMFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEtest\n-----END PUBLIC KEY-----', 'system:test', 'system:test');
SELECT pg_temp.expect_ok('0 PLATFORM có chuỗi riêng',
  $s$INSERT INTO ph13_audit.audit_chain (id, tenant_id, genesis_hash, head_hash, created_by, updated_by)
     VALUES (gen_random_uuid(), 'PLATFORM', ph13_audit.fn_hash('genesis:', 'PLATFORM'), ph13_audit.fn_hash('genesis:', 'PLATFORM'), 'system:test', 'system:test')$s$);
DO $$ DECLARE t text; BEGIN
  FOREACH t IN ARRAY ARRAY['T68', 'T01', 'T92', 'T93'] LOOP
    PERFORM set_config('app.tenant_id', t, false);
    INSERT INTO ph13_audit.audit_chain (id, tenant_id, genesis_hash, head_hash, created_by, updated_by)
    VALUES (gen_random_uuid(), t, ph13_audit.fn_hash('genesis:', t), ph13_audit.fn_hash('genesis:', t), 'system:test', 'system:test');
  END LOOP;
END $$;

-- ========== A. Chuỗi kiểm toán ==========
SET app.tenant_id = 'T68';
-- 1. Nối 5 bản ghi liền kề, đầu chuỗi nhích
SELECT pg_temp.append_n('T68', 5);
SELECT pg_temp.expect_count('1 chuỗi T68 có head_seq = 5', $s$SELECT head_seq FROM ph13_audit.audit_chain WHERE tenant_id = 'T68'$s$, 5);
SELECT pg_temp.append_n('T68', 3);   -- lô thứ hai nối tiếp
SELECT pg_temp.expect_count('1b lô hai nối tiếp, head_seq = 8', $s$SELECT head_seq FROM ph13_audit.audit_chain WHERE tenant_id = 'T68'$s$, 8);

SET app.tenant_id = 'T01';
SELECT pg_temp.append_n('T01', 2);
-- 2. Cô lập đọc
SELECT pg_temp.expect_count('2 T01 chỉ thấy 2 bản ghi của mình', 'SELECT count(*) FROM ph13_audit.audit_event', 2);
SELECT pg_temp.expect_count('2b T01 chỉ thấy 1 chuỗi', 'SELECT count(*) FROM ph13_audit.audit_chain', 1);
SELECT pg_temp.expect_count('2c T01 không thấy neo, lô WORM của T68', 'SELECT count(*) FROM ph13_audit.audit_anchor', 0);
-- 3. Cô lập ghi
SELECT pg_temp.expect_fail('3 T01 không chèn được bản ghi mang tenant T68', '42501',
  $s$INSERT INTO ph13_audit.audit_event (id, tenant_id, seq, occurred_at, recorded_at, actor_type, actor_id, actor_name, source_ip, user_agent, action, object_type, object_id, outcome, trace_id, source_du, prev_hash, hash)
     VALUES (gen_random_uuid(), 'T68', 99, now(), now(), 'USER', 'x', 'x', '1.1.1.1', 'x', 'A.B', 'x', 'x', 'SUCCESS', repeat('0', 32), 'dh-data', repeat('a', 64), repeat('b', 64))$s$);
-- 4. Biến phiên rỗng thì không thấy gì
SET app.tenant_id = '';
SELECT pg_temp.expect_count('4 phiên không có tenant thì 0 dòng', 'SELECT count(*) FROM ph13_audit.audit_event', 0);
SET app.tenant_id = 'T68';

-- 5. Chỉ thêm: vai trò ứng dụng không có UPDATE, DELETE, TRUNCATE
SELECT pg_temp.expect_fail('5a ph13_app không UPDATE được audit_event', '42501', $s$UPDATE ph13_audit.audit_event SET actor_name = 'sửa' WHERE seq = 1$s$);
SELECT pg_temp.expect_fail('5b ph13_app không DELETE được audit_event', '42501', $s$DELETE FROM ph13_audit.audit_event WHERE seq = 1$s$);
SELECT pg_temp.expect_fail('5c ph13_app không TRUNCATE được', '42501', 'TRUNCATE ph13_audit.audit_event');
SELECT pg_temp.expect_fail('5d ph13_app không tắt được trigger (không là chủ bảng)', '42501', 'ALTER TABLE ph13_audit.audit_event DISABLE TRIGGER tg_audit_event_append');
SELECT pg_temp.expect_fail('5e ph13_app không đọc trực tiếp phân vùng', '42501', $s$SELECT count(*) FROM ph13_audit.audit_event_$s$ || to_char(now(), 'YYYYMM'));
-- 6. Ngay cả chủ bảng cũng bị trigger chặn
RESET ROLE; SET ROLE ph13_owner; SET app.tenant_id = 'T68';
SELECT pg_temp.expect_fail('6a chủ bảng UPDATE bị trigger chặn', '55000', $s$UPDATE ph13_audit.audit_event SET actor_name = 'sửa' WHERE seq = 1$s$);
SELECT pg_temp.expect_fail('6b chủ bảng DELETE bị trigger chặn', '55000', $s$DELETE FROM ph13_audit.audit_event WHERE seq = 1$s$);
SELECT pg_temp.expect_fail('6c chủ bảng TRUNCATE bị trigger chặn', '55000', 'TRUNCATE ph13_audit.audit_event');
RESET ROLE; SET ROLE dh_platform_app; SET app.tenant_id = 'T68';

-- 7. Chuỗi liền kề
SELECT pg_temp.expect_fail('7a khoảng trống seq bị chặn khi nhích đầu chuỗi', '23514', $s$SELECT pg_temp.append_n('T68', 2, now(), true, 1)$s$);
SELECT pg_temp.expect_fail('7b prev_hash sai bị chặn', '23514', $s$SELECT pg_temp.append_n('T68', 2, now(), true, 0, true)$s$);
SELECT pg_temp.expect_fail('7c bản ghi mồ côi (không nhích đầu chuỗi) bị chặn khi cam kết', '23514',
  $s$SELECT pg_temp.append_n('T68', 1, now(), false)$s$, 'SET CONSTRAINTS ALL IMMEDIATE');
SELECT pg_temp.expect_fail('7d head_seq không được giảm', '55000', $s$UPDATE ph13_audit.audit_chain SET head_seq = 3 WHERE tenant_id = 'T68'$s$);
SELECT pg_temp.expect_fail('7e đổi head_hash khi head_seq giữ nguyên bị chặn', '55000', $s$UPDATE ph13_audit.audit_chain SET head_hash = repeat('c', 64) WHERE tenant_id = 'T68'$s$);
SELECT pg_temp.expect_fail('7f đầu chuỗi không khớp băm bản ghi cuối bị chặn', '23514',
  $s$SELECT pg_temp.append_n('T68', 1, now(), false)$s$,
  $s$UPDATE ph13_audit.audit_chain SET head_seq = 9, head_hash = repeat('c', 64), last_recorded_at = now() WHERE tenant_id = 'T68'$s$);
SELECT pg_temp.expect_fail('7g không xóa được chuỗi', '42501', $s$DELETE FROM ph13_audit.audit_chain WHERE tenant_id = 'T68'$s$);
SELECT pg_temp.expect_fail('7h ph13_app không sửa được genesis_hash', '42501', $s$UPDATE ph13_audit.audit_chain SET genesis_hash = repeat('d', 64) WHERE tenant_id = 'T68'$s$);

-- 8. Chặn bí mật chưa che trong before, after (BR-13-035)
SELECT pg_temp.expect_fail('8a khóa password mang giá trị thật bị chặn', '23514',
  $s$INSERT INTO ph13_audit.audit_event (id, tenant_id, seq, occurred_at, recorded_at, actor_type, actor_id, actor_name, source_ip, user_agent, action, object_type, object_id, outcome, trace_id, source_du, after, prev_hash, hash)
     VALUES (gen_random_uuid(), 'T68', 9, now(), now(), 'USER', 'x', 'x', '1.1.1.1', 'x', 'A.B', 'x', 'x', 'SUCCESS', repeat('0', 32), 'dh-data', '{"password":"DH-CANARY-123"}', repeat('a', 64), repeat('b', 64))$s$);
SELECT pg_temp.expect_ok('8b giá trị đã che *** được chấp nhận ở CHECK',
  $s$SELECT 1 WHERE '{"password": "***", "tokenTtl": "abc"}'::jsonb::text !~* '"(password|secret|clientsecret|apikey|privatekey|passphrase|token)"\s*:\s*"(?!\*\*\*")'$s$);
SELECT pg_temp.expect_fail('8c action sai mẫu bị chặn', '23514',
  $s$INSERT INTO ph13_audit.audit_event (id, tenant_id, seq, occurred_at, recorded_at, actor_type, actor_id, actor_name, source_ip, user_agent, action, object_type, object_id, outcome, trace_id, source_du, prev_hash, hash)
     VALUES (gen_random_uuid(), 'T68', 9, now(), now(), 'USER', 'x', 'x', '1.1.1.1', 'x', 'sai mau', 'x', 'x', 'SUCCESS', repeat('0', 32), 'dh-data', repeat('a', 64), repeat('b', 64))$s$);

-- ========== B. Neo, lô WORM ==========
SELECT pg_temp.expect_ok('9 ghi neo hợp lệ',
  $s$INSERT INTO ph13_audit.audit_anchor (id, tenant_id, seq_last, hash_last, anchored_at, kind, key_version, payload_digest, signature, created_by)
     SELECT gen_random_uuid(), 'T68', head_seq, head_hash, now() - interval '1 hour', 'PERIODIC', 1, repeat('e', 64), repeat('s', 80), 'system:anchor' FROM ph13_audit.audit_chain WHERE tenant_id = 'T68'$s$);
SELECT pg_temp.expect_fail('10a neo vượt đầu chuỗi bị chặn', '23514',
  $s$INSERT INTO ph13_audit.audit_anchor (id, tenant_id, seq_last, hash_last, anchored_at, kind, key_version, payload_digest, signature, created_by)
     VALUES (gen_random_uuid(), 'T68', 999, repeat('1', 64), now(), 'PERIODIC', 1, repeat('e', 64), repeat('s', 80), 'system:anchor')$s$);
SELECT pg_temp.expect_fail('10b neo lùi seq_last bị chặn', '23514',
  $s$INSERT INTO ph13_audit.audit_anchor (id, tenant_id, seq_last, hash_last, anchored_at, kind, key_version, payload_digest, signature, created_by)
     VALUES (gen_random_uuid(), 'T68', 3, repeat('1', 64), now(), 'PERIODIC', 1, repeat('e', 64), repeat('s', 80), 'system:anchor')$s$);
SELECT pg_temp.expect_fail('10c neo dùng khóa chưa có bị chặn', '23503',
  $s$INSERT INTO ph13_audit.audit_anchor (id, tenant_id, seq_last, hash_last, anchored_at, kind, key_version, payload_digest, signature, created_by)
     VALUES (gen_random_uuid(), 'T68', 8, repeat('1', 64), now(), 'PERIODIC', 7, repeat('e', 64), repeat('s', 80), 'system:anchor')$s$);
SELECT pg_temp.expect_fail('10d neo không sửa được', '42501', $s$UPDATE ph13_audit.audit_anchor SET hash_last = repeat('f', 64) WHERE tenant_id = 'T68'$s$);
SELECT pg_temp.expect_fail('10e tenant không ghi được khóa ký (chỉ PLATFORM)', '42501',
  $s$INSERT INTO ph13_audit.audit_signing_key (id, key_version, public_key_pem, created_by, updated_by) VALUES (gen_random_uuid(), 2, '-----BEGIN PUBLIC KEY-----x', 'x', 'x')$s$);
SELECT pg_temp.expect_count('10f tenant đọc được khóa công khai nền tảng', 'SELECT count(*) FROM ph13_audit.audit_signing_key', 1);

SELECT pg_temp.expect_ok('11 ghi lô WORM đầu tiên seq 1..8',
  $s$INSERT INTO ph13_audit.audit_worm_batch (id, tenant_id, seq_from, seq_to, record_count, object_key, manifest_key, sha256, size_bytes, retain_until, created_by)
     VALUES (gen_random_uuid(), 'T68', 1, 8, 8, 'audit/T68/2026/11/26/1-8.jsonl.zst', 'audit/T68/2026/11/26/1-8.manifest.json', repeat('1', 64), 1000, now() + interval '5 years', 'system:worm')$s$);
SELECT pg_temp.expect_fail('12a lô WORM chồng dải bị chặn', '23514',
  $s$INSERT INTO ph13_audit.audit_worm_batch (id, tenant_id, seq_from, seq_to, record_count, object_key, manifest_key, sha256, prev_batch_sha256, size_bytes, retain_until, created_by)
     VALUES (gen_random_uuid(), 'T68', 5, 8, 4, 'audit/T68/2026/11/26/5-8.jsonl.zst', 'm', repeat('2', 64), repeat('1', 64), 1000, now() + interval '5 years', 'system:worm')$s$);
SELECT pg_temp.expect_fail('12b lô WORM vượt đầu chuỗi bị chặn', '23514',
  $s$INSERT INTO ph13_audit.audit_worm_batch (id, tenant_id, seq_from, seq_to, record_count, object_key, manifest_key, sha256, prev_batch_sha256, size_bytes, retain_until, created_by)
     VALUES (gen_random_uuid(), 'T68', 9, 12, 4, 'audit/T68/2026/11/26/9-12.jsonl.zst', 'm', repeat('2', 64), repeat('1', 64), 1000, now() + interval '5 years', 'system:worm')$s$);
SELECT pg_temp.expect_fail('12c retain_until không được rút ngắn', '55000',
  $s$UPDATE ph13_audit.audit_worm_batch SET retain_until = now() + interval '1 year' WHERE tenant_id = 'T68'$s$);
SELECT pg_temp.expect_ok('12d retain_until kéo dài được và đặt verified_at',
  $s$UPDATE ph13_audit.audit_worm_batch SET retain_until = retain_until + interval '1 year', verified_at = now() WHERE tenant_id = 'T68'$s$);
SELECT pg_temp.expect_fail('12e không đổi băm lô', '42501', $s$UPDATE ph13_audit.audit_worm_batch SET sha256 = repeat('9', 64) WHERE tenant_id = 'T68'$s$);

-- ========== C. Xác minh, xuất, đối chiếu ==========
SELECT pg_temp.expect_ok('13 mở lượt xác minh RUNNING',
  $s$INSERT INTO ph13_audit.audit_verification (id, tenant_id, scope, from_seq, to_seq, requested_by, created_by, updated_by) VALUES (gen_random_uuid(), 'T68', 'DAILY', 0, 8, 'system:verify', 'system:verify', 'system:verify')$s$);
SELECT pg_temp.expect_fail('14a lượt RUNNING thứ hai của tenant bị chặn', '23505',
  $s$INSERT INTO ph13_audit.audit_verification (id, tenant_id, scope, from_seq, to_seq, requested_by, created_by, updated_by) VALUES (gen_random_uuid(), 'T68', 'ON_DEMAND', 0, 8, 'u1', 'u1', 'u1')$s$);
SELECT pg_temp.expect_fail('14b FAILED thiếu vị trí đứt bị chặn', '23514',
  $s$UPDATE ph13_audit.audit_verification SET status = 'FAILED', finished_at = now() WHERE tenant_id = 'T68'$s$);
SELECT pg_temp.expect_ok('14c PASSED kèm kết quả đối chiếu WORM',
  $s$UPDATE ph13_audit.audit_verification SET status = 'PASSED', finished_at = now(), checked_count = 8, worm_check = 'SAMPLE' WHERE tenant_id = 'T68'$s$);
SELECT pg_temp.expect_fail('14d kết quả đã chốt không sửa', '55000', $s$UPDATE ph13_audit.audit_verification SET checked_count = 0 WHERE tenant_id = 'T68'$s$);
SELECT pg_temp.expect_fail('14e không xóa được lượt xác minh còn trong 5 năm', '55000', $s$DELETE FROM ph13_audit.audit_verification WHERE tenant_id = 'T68'$s$);

SELECT pg_temp.expect_ok('15 yêu cầu xuất bằng chứng',
  $s$INSERT INTO ph13_audit.audit_export (id, tenant_id, filter, scope_hash, reason, basis, reauth_at, requested_by, created_by, updated_by)
     VALUES (gen_random_uuid(), 'T68', '{"from":"2026-11-01"}', repeat('7', 64), 'Phục vụ thanh tra kế hoạch 12', 'Quyết định thanh tra 15/QĐ-TTr', now(), 'au1', 'au1', 'au1')$s$);
SELECT pg_temp.expect_fail('16a hai yêu cầu cùng phạm vi đang chạy bị chặn', '23505',
  $s$INSERT INTO ph13_audit.audit_export (id, tenant_id, filter, scope_hash, reason, basis, reauth_at, requested_by, created_by, updated_by)
     VALUES (gen_random_uuid(), 'T68', '{"from":"2026-11-01"}', repeat('7', 64), 'Lý do khác nhau hoàn toàn', 'Căn cứ khác nhau hoàn toàn', now(), 'au2', 'au2', 'au2')$s$);
SELECT pg_temp.expect_fail('16b lý do dưới 10 ký tự bị chặn', '23514',
  $s$INSERT INTO ph13_audit.audit_export (id, tenant_id, filter, scope_hash, reason, basis, reauth_at, requested_by, created_by, updated_by)
     VALUES (gen_random_uuid(), 'T68', '{}', repeat('8', 64), 'ngắn', 'Căn cứ đầy đủ ghi rõ', now(), 'au2', 'au2', 'au2')$s$);
SELECT pg_temp.expect_fail('16c REQUESTED không nhảy thẳng READY', '55000',
  $s$UPDATE ph13_audit.audit_export SET status = 'READY' WHERE tenant_id = 'T68'$s$);
SELECT pg_temp.expect_ok('16d REQUESTED sang RUNNING', $s$UPDATE ph13_audit.audit_export SET status = 'RUNNING', started_at = now() WHERE tenant_id = 'T68'$s$);
SELECT pg_temp.expect_fail('16e READY thiếu chữ ký bị chặn (BR-13-014)', '23514',
  $s$UPDATE ph13_audit.audit_export SET status = 'READY', record_count = 10, file_object = 'exports/T68/x.zip', file_hash = repeat('a', 64), key_version = 1, expires_at = now() + interval '7 days' WHERE tenant_id = 'T68'$s$);
SELECT pg_temp.expect_ok('16f READY khi đã ký đủ hai chữ ký',
  $s$UPDATE ph13_audit.audit_export SET status = 'READY', record_count = 10, file_object = 'exports/T68/x.zip', file_hash = repeat('a', 64), signature = 'sig1', manifest_signature = 'sig2', key_version = 1, expires_at = now() + interval '7 days', finished_at = now() WHERE tenant_id = 'T68'$s$);
SELECT pg_temp.expect_fail('16g READY không quay lại RUNNING', '55000', $s$UPDATE ph13_audit.audit_export SET status = 'RUNNING' WHERE tenant_id = 'T68'$s$);
SELECT pg_temp.expect_ok('16h READY sang EXPIRED', $s$UPDATE ph13_audit.audit_export SET status = 'EXPIRED' WHERE tenant_id = 'T68'$s$);

SELECT pg_temp.expect_ok('17 đối chiếu khớp',
  $s$INSERT INTO ph13_audit.audit_reconciliation (id, tenant_id, du_code, day, emitted, received, status, created_by, updated_by) VALUES (gen_random_uuid(), 'T68', 'dh-data', '2026-11-25', 100, 100, 'MATCH', 's', 's')$s$);
SELECT pg_temp.expect_fail('18a MATCH khi còn chênh lệch bị chặn (BR-13-001)', '23514',
  $s$INSERT INTO ph13_audit.audit_reconciliation (id, tenant_id, du_code, day, emitted, received, status, created_by, updated_by) VALUES (gen_random_uuid(), 'T68', 'dh-data', '2026-11-24', 100, 98, 'MATCH', 's', 's')$s$);
SELECT pg_temp.expect_ok('18b MISMATCH khi thiếu bản ghi',
  $s$INSERT INTO ph13_audit.audit_reconciliation (id, tenant_id, du_code, day, emitted, received, status, created_by, updated_by) VALUES (gen_random_uuid(), 'T68', 'dh-data', '2026-11-24', 100, 98, 'MISMATCH', 's', 's')$s$);
SELECT pg_temp.expect_ok('18c bản ghi cách ly được tính là đã nhận',
  $s$INSERT INTO ph13_audit.audit_reconciliation (id, tenant_id, du_code, day, emitted, received, quarantined, status, created_by, updated_by) VALUES (gen_random_uuid(), 'T68', 'dh-data', '2026-11-23', 100, 98, 2, 'MATCH', 's', 's')$s$);

-- ========== D. Cách ly, nguồn ==========
SELECT pg_temp.expect_ok('19 cách ly bản ghi chứa giá trị Nhạy cảm',
  $s$INSERT INTO ph13_audit.audit_quarantine (id, tenant_id, du_code, topic, record_id, reason, error_code, payload_sha256, raw_payload, created_by, updated_by)
     VALUES (gen_random_uuid(), 'T68', 'dh-data', 't68.obs.audit.recorded.v1', gen_random_uuid(), 'SENSITIVE_VALUE', 'ERR-13-105', repeat('a', 64), '\x7b7d', 's', 's')$s$);
SELECT pg_temp.expect_fail('20a không xóa bản cách ly trước hạn giữ', '55000', $s$DELETE FROM ph13_audit.audit_quarantine WHERE tenant_id = 'T68'$s$);
SELECT pg_temp.expect_fail('20b không sửa nguyên văn bản cách ly', '55000', $s$UPDATE ph13_audit.audit_quarantine SET raw_payload = '\x00' WHERE tenant_id = 'T68'$s$);
SELECT pg_temp.expect_ok('21 cấp nguồn cho cặp (DU, tenant)',
  $s$INSERT INTO ph13_audit.audit_source_grant (id, tenant_id, du_code, key_id, granted_by, created_by, updated_by) VALUES (gen_random_uuid(), 'T68', 'dh-data', 'dh-kid-1', 'pa1', 'pa1', 'pa1')$s$);
SELECT pg_temp.expect_fail('21b không xóa được cấp nguồn', '42501', $s$DELETE FROM ph13_audit.audit_source_grant WHERE tenant_id = 'T68'$s$);

-- ========== E. Đóng chuỗi ==========
SET app.tenant_id = 'T93';
SELECT pg_temp.append_n('T93', 2);
SELECT pg_temp.expect_ok('22 đóng chuỗi T93 (FINAL)',
  $s$UPDATE ph13_audit.audit_chain SET status = 'CLOSED', closed_at = now(), closed_reason = 'Tenant sáp nhập' WHERE tenant_id = 'T93'$s$);
SELECT pg_temp.expect_fail('22b chuỗi đóng không nhận bản ghi (ERR-13-043)', '55000', $s$SELECT pg_temp.append_n('T93', 1)$s$);
SELECT pg_temp.expect_fail('22c không mở lại chuỗi đã đóng', '55000', $s$UPDATE ph13_audit.audit_chain SET status = 'OPEN', closed_at = NULL, closed_reason = NULL WHERE tenant_id = 'T93'$s$);
SELECT pg_temp.expect_ok('22d chuỗi đóng vẫn đọc được', $s$SELECT 1 FROM ph13_audit.audit_event WHERE tenant_id = 'T93' LIMIT 1$s$);
SELECT pg_temp.expect_ok('22e đánh dấu nghi vấn khi đứt chuỗi (SUSPECT)',
  $s$UPDATE ph13_audit.audit_chain SET integrity = 'SUSPECT', suspect_from_seq = 2, suspect_since = now() WHERE tenant_id = 'T93'$s$);
SELECT pg_temp.expect_fail('22f SUSPECT thiếu vị trí bị chặn', '23514', $s$UPDATE ph13_audit.audit_chain SET integrity = 'SUSPECT', suspect_from_seq = NULL WHERE tenant_id = 'T93'$s$);

-- ========== F. Lưu trữ phân vùng ==========
RESET ROLE; SET ROLE dh_platform_app; SET app.tenant_id = 'T92';
SELECT pg_temp.append_n('T92', 3, date_trunc('month', now()) - interval '10 days');
SELECT pg_temp.expect_count('23 bản ghi tháng trước nằm ở phân vùng tháng trước',
  format('SELECT count(*) FROM ph13_audit.audit_event WHERE tenant_id = %L AND recorded_at < date_trunc(%L, now())', 'T92', 'month'), 3);
SET app.tenant_id = 'PLATFORM';
RESET ROLE; SET ROLE dh_platform_archive;
SELECT pg_temp.expect_fail('24a ph13_archive không DROP trực tiếp', '42501', 'DROP TABLE ph13_audit.audit_event_' || to_char(now() - interval '1 month', 'YYYYMM'));
SELECT pg_temp.expect_fail('24b ph13_archive không DELETE được dòng', '42501', 'DELETE FROM ph13_audit.audit_event');
SELECT pg_temp.expect_fail('24c chưa xác minh WORM thì không lưu trữ (ERR-13-125)', '23514',
  format('CALL ph13_audit.p_archive_partition(%L)', (date_trunc('month', now()) - interval '1 month')::date));
RESET ROLE; SET ROLE dh_platform_app; SET app.tenant_id = 'PLATFORM';
SELECT pg_temp.expect_fail('24d ph13_app không gọi được thủ tục lưu trữ', '42501',
  format('CALL ph13_audit.p_archive_partition(%L)', (date_trunc('month', now()) - interval '1 month')::date));
UPDATE ph13_audit.audit_partition SET worm_verified_at = now(), archive_after = current_date + 1
 WHERE month = (date_trunc('month', now()) - interval '1 month')::date;
RESET ROLE; SET ROLE dh_platform_archive;
SELECT pg_temp.expect_fail('24e chưa đến hạn lưu trữ thì không tách (archive_after)', '23514',
  format('CALL ph13_audit.p_archive_partition(%L)', (date_trunc('month', now()) - interval '1 month')::date));
RESET ROLE; SET ROLE dh_platform_app; SET app.tenant_id = 'PLATFORM';
UPDATE ph13_audit.audit_partition SET archive_after = current_date
 WHERE month = (date_trunc('month', now()) - interval '1 month')::date;
RESET ROLE; SET ROLE dh_platform_archive;
SELECT pg_temp.expect_fail('24f không lưu trữ phân vùng tháng hiện tại (OPEN)', '23514',
  format('CALL ph13_audit.p_archive_partition(%L)', date_trunc('month', now())::date));
SELECT pg_temp.expect_ok('25 lưu trữ phân vùng đã SEALED, đã xác minh, đã đến hạn',
  format('CALL ph13_audit.p_archive_partition(%L)', (date_trunc('month', now()) - interval '1 month')::date));
RESET ROLE; SET ROLE dh_platform_app; SET app.tenant_id = 'PLATFORM';
SELECT pg_temp.expect_count('25b phân vùng đã ARCHIVED trong sổ', $s$SELECT count(*) FROM ph13_audit.audit_partition WHERE status = 'ARCHIVED'$s$, 1);
SET app.tenant_id = 'T92';
SELECT pg_temp.expect_count('25c bản ghi tháng trước đã rời bảng trực tuyến', 'SELECT count(*) FROM ph13_audit.audit_event', 0);
SELECT pg_temp.expect_count('25d đầu chuỗi T92 giữ nguyên head_seq = 3', $s$SELECT head_seq FROM ph13_audit.audit_chain WHERE tenant_id = 'T92'$s$, 3);
SET app.tenant_id = 'PLATFORM';
SELECT pg_temp.expect_fail('25e phân vùng ARCHIVED không chuyển ngược', '55000', $s$UPDATE ph13_audit.audit_partition SET status = 'SEALED', archived_at = NULL WHERE status = 'ARCHIVED'$s$);
SELECT pg_temp.expect_ok('25f tạo thêm phân vùng bằng thủ tục DEFINER', $s$CALL ph13_audit.p_ensure_month_partitions(current_date, 8)$s$);

-- ========== G. Vai trò đọc ==========
RESET ROLE; SET ROLE dh_platform_verify; SET app.tenant_id = 'T68';
SELECT pg_temp.expect_count('26 ph13_verify đọc được 8 bản ghi T68', 'SELECT count(*) FROM ph13_audit.audit_event', 8);
SELECT pg_temp.expect_fail('26b ph13_verify không ghi được', '42501', $s$INSERT INTO ph13_audit.audit_chain (id, tenant_id, genesis_hash, head_hash, created_by, updated_by) VALUES (gen_random_uuid(), 'T68', repeat('a', 64), repeat('a', 64), 'x', 'x')$s$);
RESET ROLE; SET ROLE dh_platform_ro; SET app.tenant_id = 'T68';
SELECT pg_temp.expect_fail('27 ph13_readonly không đọc được audit_event', '42501', 'SELECT count(*) FROM ph13_audit.audit_event');
SELECT pg_temp.expect_fail('27b ph13_readonly không đọc được nguyên văn bản cách ly', '42501', 'SELECT raw_payload FROM ph13_audit.audit_quarantine');
SELECT pg_temp.expect_count('27c ph13_readonly đọc được siêu dữ liệu cách ly', 'SELECT count(*) FROM ph13_audit.audit_quarantine', 1);

-- ============================================================================
-- Nhóm ph13_obs
-- ============================================================================
RESET ROLE; SET ROLE dh_platform_app;

-- Nạp dữ liệu khởi tạo cho T68 và T01
SET app.tenant_id = 'T68';
CALL ph13_obs.p_seed_tenant('T68');
SET app.tenant_id = 'T01';
CALL ph13_obs.p_seed_tenant('T01');
SELECT pg_temp.expect_count('30 nạp đủ 27 luật phát hiện cho T01', 'SELECT count(*) FROM ph13_obs.detection_rule', 27);
SELECT pg_temp.expect_fail('30b p_seed_tenant từ chối khi biến phiên khác tenant', '42501', $s$CALL ph13_obs.p_seed_tenant('T68')$s$);
SET app.tenant_id = 'T68';
CALL ph13_obs.p_seed_tenant('T68');   -- gọi lại lũy đẳng
SELECT pg_temp.expect_count('30c nạp lại không nhân đôi (T68 vẫn 27 luật)', 'SELECT count(*) FROM ph13_obs.detection_rule', 27);

-- Runbook, luật cảnh báo
CREATE TEMP TABLE ids (k text PRIMARY KEY, v uuid);
INSERT INTO ids SELECT k, gen_random_uuid() FROM unnest(ARRAY['rb68', 'rb01', 'r68', 'r01', 'a68', 'ch68', 'sa68']) k;
CREATE FUNCTION pg_temp.id(text) RETURNS uuid LANGUAGE sql AS $$ SELECT v FROM ids WHERE k = $1 $$;

SELECT pg_temp.expect_fail('31a runbook thiếu một trong năm mục bị chặn (BR-13-008)', '23514',
  $s$INSERT INTO ph13_obs.runbook (id, tenant_id, runbook_code, title, meaning, first_checks, common_causes, remediation, escalation_when, created_by, updated_by)
     VALUES (gen_random_uuid(), 'T68', 'rb-thieu', 'Thiếu mục', 'Ý nghĩa', 'Kiểm tra', '   ', 'Xử lý', 'Báo cấp trên', 'ta', 'ta')$s$);
INSERT INTO ph13_obs.runbook (id, tenant_id, runbook_code, title, meaning, first_checks, common_causes, remediation, escalation_when, created_by, updated_by)
VALUES (pg_temp.id('rb68'), 'T68', 'api-5xx-cao', 'API lỗi 5xx cao', 'Tỷ lệ 5xx vượt ngưỡng', 'Xem bảng điều khiển API', 'Bản phát hành mới', 'Hoàn tác phát hành', 'Quá 15 phút chưa khắc phục', 'ta', 'ta');
SELECT pg_temp.expect_fail('31b luật không có runbook (khóa ngoại) bị chặn', '23503',
  $s$INSERT INTO ph13_obs.alert_rule (id, tenant_id, rule_code, name, expr, severity, symptom, runbook_id, owner, expr_hash, created_by, updated_by)
     VALUES (gen_random_uuid(), 'T68', 'khong-runbook', 'x', 'up == 0', 'WARNING', NULL, gen_random_uuid(), 'ta', repeat('a', 64), 'ta', 'ta')$s$);
SELECT pg_temp.expect_fail('31c CRITICAL thiếu triệu chứng bị chặn (BR-13-009)', '23514',
  format($s$INSERT INTO ph13_obs.alert_rule (id, tenant_id, rule_code, name, expr, severity, runbook_id, owner, expr_hash, created_by, updated_by)
     VALUES (gen_random_uuid(), 'T68', 'crit-khong-trieu-chung', 'x', 'up == 0', 'CRITICAL', %L, 'ta', repeat('a', 64), 'ta', 'ta')$s$, pg_temp.id('rb68')));
SELECT pg_temp.expect_fail('31d CRITICAL chỉ dựa tài nguyên thuần bị chặn', '23514',
  format($s$INSERT INTO ph13_obs.alert_rule (id, tenant_id, rule_code, name, expr, severity, symptom, resource_only, runbook_id, owner, expr_hash, created_by, updated_by)
     VALUES (gen_random_uuid(), 'T68', 'cpu-cao', 'x', 'node_cpu > 0.9', 'CRITICAL', 'Người dùng chậm', true, %L, 'ta', repeat('a', 64), 'ta', 'ta')$s$, pg_temp.id('rb68')));
INSERT INTO ph13_obs.alert_rule (id, tenant_id, rule_code, name, expr, severity, symptom, runbook_id, owner, expr_hash, created_by, updated_by)
VALUES (pg_temp.id('r68'), 'T68', 'api-5xx-cao', 'API 5xx cao', 'sum(rate(dh_http_requests_total{status_class="5xx"}[5m])) > 1', 'CRITICAL', 'Người dùng gặp lỗi khi gọi API', pg_temp.id('rb68'), 'ta', repeat('a', 64), 'ta', 'ta');
SELECT pg_temp.expect_fail('31e mã luật không dùng lại', '23505',
  format($s$INSERT INTO ph13_obs.alert_rule (id, tenant_id, rule_code, name, expr, severity, symptom, runbook_id, owner, expr_hash, created_by, updated_by)
     VALUES (gen_random_uuid(), 'T68', 'api-5xx-cao', 'x', 'up == 0', 'WARNING', NULL, %L, 'ta', repeat('a', 64), 'ta', 'ta')$s$, pg_temp.id('rb68')));
SELECT pg_temp.expect_fail('31f luật chuẩn nền tảng không do tenant ghi (ERR-13-019)', '55000',
  format($s$INSERT INTO ph13_obs.alert_rule (id, tenant_id, rule_code, name, scope, expr, severity, symptom, runbook_id, owner, source_revision, expr_hash, created_by, updated_by)
     VALUES (gen_random_uuid(), 'T68', 'slo-gia', 'x', 'PLATFORM', 'up == 0', 'WARNING', NULL, %L, 'ta', 'abc123', repeat('a', 64), 'ta', 'ta')$s$, pg_temp.id('rb68')));
SELECT pg_temp.expect_ok('31g StandardRuleCatalog (app.rule_catalog = on) nạp được luật chuẩn',
  $s$SELECT set_config('app.rule_catalog', 'on', false)$s$,
  format($s$INSERT INTO ph13_obs.alert_rule (id, tenant_id, rule_code, name, scope, expr, severity, symptom, runbook_id, owner, source_revision, expr_hash, created_by, updated_by)
     VALUES (gen_random_uuid(), 'T68', 'slo-data-plane-burn-fast', 'Đốt ngân sách lỗi nhanh', 'PLATFORM', 'up == 0', 'CRITICAL', 'Người dùng bị lỗi', %L, 'system:argocd', 'abc123', repeat('b', 64), 'system:argocd', 'system:argocd')$s$, pg_temp.id('rb68')),
  $s$SELECT set_config('app.rule_catalog', '', false)$s$);
SELECT pg_temp.expect_fail('31h tenant không tắt được luật chuẩn', '55000', $s$UPDATE ph13_obs.alert_rule SET status = 'DISABLED' WHERE rule_code = 'slo-data-plane-burn-fast'$s$);
SELECT pg_temp.expect_ok('31i tenant tắt, bật lại luật riêng', $s$UPDATE ph13_obs.alert_rule SET status = 'DISABLED' WHERE rule_code = 'api-5xx-cao'$s$,
  $s$UPDATE ph13_obs.alert_rule SET status = 'ACTIVE' WHERE rule_code = 'api-5xx-cao'$s$);
SELECT pg_temp.expect_fail('31j mã luật bất biến', '55000', $s$UPDATE ph13_obs.alert_rule SET rule_code = 'doi-ma' WHERE rule_code = 'api-5xx-cao'$s$);
SELECT pg_temp.expect_fail('31k không xóa được luật', '42501', $s$DELETE FROM ph13_obs.alert_rule WHERE rule_code = 'api-5xx-cao'$s$);
SELECT pg_temp.expect_fail('31l ngừng dùng luật thiếu lý do bị chặn', '23514', $s$UPDATE ph13_obs.alert_rule SET status = 'RETIRED', retired_at = now() WHERE rule_code = 'api-5xx-cao'$s$);

-- Cô lập obs
SET app.tenant_id = 'T01';
SELECT pg_temp.expect_count('32 T01 không thấy luật, runbook của T68', 'SELECT count(*) FROM ph13_obs.alert_rule', 0);
SELECT pg_temp.expect_count('32b T01 không thấy runbook của T68', 'SELECT count(*) FROM ph13_obs.runbook', 0);
SELECT pg_temp.expect_fail('32c T01 không chèn runbook mang tenant T68', '42501',
  $s$INSERT INTO ph13_obs.runbook (id, tenant_id, runbook_code, title, meaning, first_checks, common_causes, remediation, escalation_when, created_by, updated_by)
     VALUES (gen_random_uuid(), 'T68', 'chen-cheo', 'x', 'a', 'b', 'c', 'd', 'e', 'x', 'x')$s$);
SELECT pg_temp.expect_fail('32d T01 không tạo luật dùng runbook của T68 (khóa ngoại kèm tenant)', '23503',
  format($s$INSERT INTO ph13_obs.alert_rule (id, tenant_id, rule_code, name, expr, severity, runbook_id, owner, expr_hash, created_by, updated_by)
     VALUES (gen_random_uuid(), 'T01', 'dung-chung-runbook', 'x', 'up == 0', 'WARNING', %L, 'ta', repeat('a', 64), 'ta', 'ta')$s$, pg_temp.id('rb68')));
SET app.tenant_id = '';
SELECT pg_temp.expect_count('32e phiên không có tenant thấy 0 luật phát hiện', 'SELECT count(*) FROM ph13_obs.detection_rule', 0);
SET app.tenant_id = 'T68';

-- Cảnh báo: lũy đẳng, trạng thái, tạm ẩn, leo thang
INSERT INTO ph13_obs.alert (id, tenant_id, rule_code, fingerprint, severity, labels, summary, group_key, created_by, updated_by)
VALUES (pg_temp.id('a68'), 'T68', 'api-5xx-cao', '00000000000000a1', 'CRITICAL', '{"tenant":"t68","severity":"CRITICAL"}', 'API 5xx cao', 'api-5xx-cao|t68', 'system:alertmanager', 'system:alertmanager');
SELECT pg_temp.expect_fail('33a webhook gửi lặp không nhân đôi cảnh báo mở', '23505',
  $s$INSERT INTO ph13_obs.alert (id, tenant_id, rule_code, fingerprint, severity, labels, summary, group_key, created_by, updated_by)
     VALUES (gen_random_uuid(), 'T68', 'api-5xx-cao', '00000000000000a1', 'CRITICAL', '{"tenant":"t68"}', 'x', 'g', 's', 's')$s$);
SELECT pg_temp.expect_fail('33b nhãn tenant lệch tenant_id bị chặn (BR-13-027)', '23514',
  $s$INSERT INTO ph13_obs.alert (id, tenant_id, rule_code, fingerprint, severity, labels, summary, group_key, created_by, updated_by)
     VALUES (gen_random_uuid(), 'T68', 'api-5xx-cao', '1111111111111111', 'CRITICAL', '{"tenant":"t01"}', 'x', 'g', 's', 's')$s$);
SELECT pg_temp.expect_fail('33c cảnh báo của luật không tồn tại (khóa ngoại)', '23503',
  $s$INSERT INTO ph13_obs.alert (id, tenant_id, rule_code, fingerprint, severity, labels, summary, group_key, created_by, updated_by)
     VALUES (gen_random_uuid(), 'T68', 'khong-co-luat', '2222222222222222', 'WARNING', '{"tenant":"t68"}', 'x', 'g', 's', 's')$s$);
SELECT pg_temp.expect_fail('34a tạm ẩn cảnh báo CRITICAL quá 24 giờ bị chặn (BR-13-021)', '23514',
  $s$UPDATE ph13_obs.alert SET status = 'SILENCED', silence_until = now() + interval '48 hours', silence_reason = 'Bảo trì' WHERE rule_code = 'api-5xx-cao'$s$);
SELECT pg_temp.expect_fail('34b tạm ẩn thiếu lý do bị chặn', '23514',
  $s$UPDATE ph13_obs.alert SET status = 'SILENCED', silence_until = now() + interval '2 hours' WHERE rule_code = 'api-5xx-cao'$s$);
SELECT pg_temp.expect_ok('34c leo thang cấp 2 cho CRITICAL đang FIRING',
  $s$UPDATE ph13_obs.alert SET escalation_level = 2 WHERE rule_code = 'api-5xx-cao'$s$);
SELECT pg_temp.expect_fail('34d leo thang nhảy cấp bị chặn', '23514', $s$UPDATE ph13_obs.alert SET escalation_level = 1 WHERE rule_code = 'api-5xx-cao'$s$);
SELECT pg_temp.expect_ok('34e xác nhận cảnh báo',
  $s$UPDATE ph13_obs.alert SET status = 'ACKNOWLEDGED', acknowledged_by = 'trucvien1', acknowledged_at = now() WHERE rule_code = 'api-5xx-cao'$s$);
SELECT pg_temp.expect_ok('34f tạm ẩn CRITICAL 2 giờ sau khi xác nhận',
  $s$UPDATE ph13_obs.alert SET status = 'SILENCED', silence_until = now() + interval '2 hours', silence_reason = 'Chờ nhà cung cấp' WHERE rule_code = 'api-5xx-cao'$s$);
SELECT pg_temp.expect_ok('34g hết hạn tạm ẩn quay về FIRING',
  $s$UPDATE ph13_obs.alert SET status = 'FIRING', silence_until = NULL, silence_reason = NULL WHERE rule_code = 'api-5xx-cao'$s$);
SELECT pg_temp.expect_fail('34h đóng thủ công thiếu nguyên nhân, hành động, kết quả bị chặn (BR-13-023)', '23514',
  format($s$INSERT INTO ph13_obs.alert_action (id, tenant_id, alert_id, action, actor, created_by) VALUES (gen_random_uuid(), 'T68', %L, 'RESOLVE', 'trucvien1', 'trucvien1')$s$, pg_temp.id('a68')));
SELECT pg_temp.expect_ok('34i đóng thủ công đủ nguyên nhân, hành động, kết quả',
  format($s$INSERT INTO ph13_obs.alert_action (id, tenant_id, alert_id, action, actor, cause, measure, outcome, created_by) VALUES (gen_random_uuid(), 'T68', %L, 'RESOLVE', 'trucvien1', 'Bản phát hành lỗi', 'Hoàn tác', 'FIXED', 'trucvien1')$s$, pg_temp.id('a68')),
  $s$UPDATE ph13_obs.alert SET status = 'RESOLVED', resolution = 'MANUAL', ended_at = now() WHERE rule_code = 'api-5xx-cao'$s$);
SELECT pg_temp.expect_fail('34j cảnh báo đã đóng không mở lại (ERR-13-020)', '55000', $s$UPDATE ph13_obs.alert SET status = 'FIRING', resolution = NULL, ended_at = NULL WHERE rule_code = 'api-5xx-cao'$s$);
SELECT pg_temp.expect_ok('34k sau khi đóng, cùng fingerprint sinh được cảnh báo mới',
  $s$INSERT INTO ph13_obs.alert (id, tenant_id, rule_code, fingerprint, severity, labels, summary, group_key, created_by, updated_by)
     VALUES (gen_random_uuid(), 'T68', 'api-5xx-cao', '00000000000000a1', 'CRITICAL', '{"tenant":"t68"}', 'API 5xx cao lần hai', 'api-5xx-cao|t68', 's', 's')$s$);
SELECT pg_temp.expect_fail('34l không xóa được thao tác xử lý trong hạn lưu 2 năm', '55000', $s$DELETE FROM ph13_obs.alert_action WHERE tenant_id = 'T68'$s$);
SELECT pg_temp.expect_fail('34m không sửa được thao tác xử lý (chỉ thêm)', '42501', $s$UPDATE ph13_obs.alert_action SET cause = 'sửa' WHERE tenant_id = 'T68'$s$);
SELECT pg_temp.expect_fail('34n không xóa được cảnh báo trong hạn lưu', '55000', $s$DELETE FROM ph13_obs.alert WHERE tenant_id = 'T68'$s$);

-- Hạn tạm ẩn theo tham số tenant
SELECT pg_temp.expect_fail('35a tham số ngoài miền bị chặn (13.audit.worm-retention-years = 2)', '23514',
  $s$UPDATE ph13_obs.tenant_obs_config SET params = '{"13.audit.worm-retention-years": 2}' WHERE tenant_id = 'T68'$s$);
SELECT pg_temp.expect_fail('35b khóa tham số lạ bị chặn', '23514', $s$UPDATE ph13_obs.tenant_obs_config SET params = '{"13.khong.co": 1}' WHERE tenant_id = 'T68'$s$);
SELECT pg_temp.expect_fail('35c giá trị chuỗi cho tham số số bị chặn', '23514', $s$UPDATE ph13_obs.tenant_obs_config SET params = '{"13.alert.silence-max-days": "7"}' WHERE tenant_id = 'T68'$s$);
SELECT pg_temp.expect_ok('35d tham số hợp lệ được lưu',
  $s$UPDATE ph13_obs.tenant_obs_config SET params = '{"13.audit.worm-retention-years": 7, "13.alert.silence-max-days": 14, "13.alert.escalate-minutes": "10,20"}' WHERE tenant_id = 'T68'$s$);
SELECT pg_temp.expect_ok('35e cảnh báo WARNING tạm ẩn 10 ngày theo tham số 14 ngày',
  $s$INSERT INTO ph13_obs.alert (id, tenant_id, rule_code, fingerprint, severity, labels, summary, group_key, created_by, updated_by)
     VALUES (gen_random_uuid(), 'T68', 'slo-data-plane-burn-fast', 'aaaaaaaaaaaaaaaa', 'WARNING', '{"tenant":"t68"}', 'x', 'g', 's', 's')$s$,
  $s$UPDATE ph13_obs.alert SET status = 'SILENCED', silence_until = now() + interval '10 days', silence_reason = 'Đợt bảo trì dài' WHERE fingerprint = 'aaaaaaaaaaaaaaaa'$s$);
SELECT pg_temp.expect_fail('35f quá 14 ngày vẫn bị chặn', '23514',
  $s$UPDATE ph13_obs.alert SET silence_until = now() + interval '15 days' WHERE fingerprint = 'aaaaaaaaaaaaaaaa'$s$);

-- Luật phát hiện, cảnh báo an ninh
SELECT pg_temp.expect_fail('36a luật không tắt được (UC-SEC-20, BR-13-025)', '23514', $s$UPDATE ph13_obs.detection_rule SET enabled = false WHERE rule_code = 'UC-SEC-20'$s$);
SELECT pg_temp.expect_fail('36b nới ngưỡng quá 2 lần mặc định bị chặn', '23514',
  $s$UPDATE ph13_obs.detection_rule SET threshold = '{"failPerIp5m":41,"distinctAccountsPerIp5m":10}', tuned_by = 'so1', tuned_at = now() WHERE rule_code = 'UC-SEC-01'$s$);
SELECT pg_temp.expect_ok('36c siết, nới trong biên cho phép được ghi kèm người chỉnh',
  $s$UPDATE ph13_obs.detection_rule SET threshold = '{"failPerIp5m":30,"distinctAccountsPerIp5m":5}', tuned_by = 'so1', tuned_at = now() WHERE rule_code = 'UC-SEC-01'$s$);
SELECT pg_temp.expect_fail('36d đổi ngưỡng thiếu người chỉnh bị chặn', '23514',
  $s$UPDATE ph13_obs.detection_rule SET threshold = '{"failPerIp5m":25,"distinctAccountsPerIp5m":5}', tuned_by = NULL, tuned_at = NULL WHERE rule_code = 'UC-SEC-01'$s$);
SELECT pg_temp.expect_fail('36e ngưỡng mặc định bất biến', '55000', $s$UPDATE ph13_obs.detection_rule SET threshold_default = '{"failPerIp5m":99,"distinctAccountsPerIp5m":99}' WHERE rule_code = 'UC-SEC-01'$s$);
SELECT pg_temp.expect_fail('36f không xóa luật phát hiện', '42501', $s$DELETE FROM ph13_obs.detection_rule WHERE rule_code = 'UC-SEC-01'$s$);

INSERT INTO ph13_obs.security_alert (id, tenant_id, rule_code, severity, subject, evidence, created_by, updated_by)
VALUES (pg_temp.id('sa68'), 'T68', 'UC-SEC-11', 'WARNING', 'user-123', '{"auditIds": ["a","b"], "count": 25}', 'system:detect', 'system:detect');
SELECT pg_temp.expect_fail('37a cùng (luật, chủ thể) đang mở thì gom, không nhân đôi', '23505',
  $s$INSERT INTO ph13_obs.security_alert (id, tenant_id, rule_code, severity, subject, created_by, updated_by) VALUES (gen_random_uuid(), 'T68', 'UC-SEC-11', 'WARNING', 'user-123', 's', 's')$s$);
SELECT pg_temp.expect_fail('37b đóng thiếu kết luận bị chặn (ERR-13-023)', '23514', $s$UPDATE ph13_obs.security_alert SET status = 'CLOSED', closed_by = 'so1', closed_at = now() WHERE rule_code = 'UC-SEC-11'$s$);
SELECT pg_temp.expect_fail('37c chấp nhận rủi ro thiếu ghi chú bị chặn', '23514', $s$UPDATE ph13_obs.security_alert SET status = 'CLOSED', verdict = 'ACCEPTED_RISK', closed_by = 'so1', closed_at = now() WHERE rule_code = 'UC-SEC-11'$s$);
SELECT pg_temp.expect_ok('37d tiếp nhận rồi đóng với kết luận báo nhầm',
  $s$UPDATE ph13_obs.security_alert SET status = 'ACKNOWLEDGED', assignee = 'so1', acknowledged_at = now() WHERE rule_code = 'UC-SEC-11'$s$,
  $s$UPDATE ph13_obs.security_alert SET status = 'CLOSED', verdict = 'FALSE_POSITIVE', closed_by = 'so1', closed_at = now() WHERE rule_code = 'UC-SEC-11'$s$);
SELECT pg_temp.expect_fail('37e cảnh báo an ninh đã đóng không sửa', '55000', $s$UPDATE ph13_obs.security_alert SET verdict_note = 'sửa' WHERE rule_code = 'UC-SEC-11'$s$);
SELECT pg_temp.expect_fail('37f bằng chứng quá 100 audit_id bị chặn', '23514',
  $s$INSERT INTO ph13_obs.security_alert (id, tenant_id, rule_code, severity, subject, evidence, created_by, updated_by)
     VALUES (gen_random_uuid(), 'T68', 'UC-SEC-12', 'WARNING', 'user-9', jsonb_build_object('auditIds', (SELECT jsonb_agg(g) FROM generate_series(1, 101) g)), 's', 's')$s$);

-- Thông báo cho cảnh báo vận hành và cảnh báo an ninh
SELECT pg_temp.expect_ok('37g thông báo cho cảnh báo an ninh (security_alert_id)',
  format($s$INSERT INTO ph13_obs.alert_notification (id, tenant_id, security_alert_id, channel_id, channel_code, recipient, created_by, updated_by)
     SELECT gen_random_uuid(), 'T68', %L, id, channel_code, 'so1', 's', 's' FROM ph13_obs.notification_channel WHERE channel_code = 'inapp-default'$s$, pg_temp.id('sa68')));
SELECT pg_temp.expect_fail('37h thông báo trùng (cảnh báo, kênh, cấp, người nhận) bị chặn', '23505',
  format($s$INSERT INTO ph13_obs.alert_notification (id, tenant_id, security_alert_id, channel_id, channel_code, recipient, created_by, updated_by)
     SELECT gen_random_uuid(), 'T68', %L, id, channel_code, 'so1', 's', 's' FROM ph13_obs.notification_channel WHERE channel_code = 'inapp-default'$s$, pg_temp.id('sa68')));
SELECT pg_temp.expect_fail('37i thông báo không gắn cảnh báo nào bị chặn', '23514',
  $s$INSERT INTO ph13_obs.alert_notification (id, tenant_id, channel_id, channel_code, recipient, created_by, updated_by)
     SELECT gen_random_uuid(), 'T68', id, channel_code, 'so2', 's', 's' FROM ph13_obs.notification_channel WHERE channel_code = 'inapp-default'$s$);
SELECT pg_temp.expect_fail('37j thông báo gắn đồng thời hai loại cảnh báo bị chặn', '23514',
  format($s$INSERT INTO ph13_obs.alert_notification (id, tenant_id, alert_id, security_alert_id, channel_id, channel_code, recipient, created_by, updated_by)
     SELECT gen_random_uuid(), 'T68', %L, %L, id, channel_code, 'so2', 's', 's' FROM ph13_obs.notification_channel WHERE channel_code = 'inapp-default'$s$, pg_temp.id('a68'), pg_temp.id('sa68')));
SELECT pg_temp.expect_fail('37k người nhận là địa chỉ thư bị chặn (chỉ mã người dùng)', '23514',
  format($s$INSERT INTO ph13_obs.alert_notification (id, tenant_id, alert_id, channel_id, channel_code, recipient, created_by, updated_by)
     SELECT gen_random_uuid(), 'T68', %L, id, channel_code, 'nguoi@tinh.gov.vn', 's', 's' FROM ph13_obs.notification_channel WHERE channel_code = 'inapp-default'$s$, pg_temp.id('a68')));
SELECT pg_temp.expect_ok('37l thông báo cho cảnh báo vận hành, thất bại ghi mã lỗi',
  format($s$INSERT INTO ph13_obs.alert_notification (id, tenant_id, alert_id, channel_id, channel_code, recipient, status, attempt, error, created_by, updated_by)
     SELECT gen_random_uuid(), 'T68', %L, id, channel_code, 'trucvien1', 'FAILED', 3, 'ERR-13-120 hết thời gian chờ', 's', 's' FROM ph13_obs.notification_channel WHERE channel_code = 'inapp-default'$s$, pg_temp.id('a68')));

-- Kênh, SIEM, báo cáo sự cố, hộp thư đi
SELECT pg_temp.expect_fail('38a webhook không HTTPS bị chặn', '23514',
  $s$INSERT INTO ph13_obs.notification_channel (id, tenant_id, channel_code, name, kind, target, secret_ref, created_by, updated_by) VALUES (gen_random_uuid(), 'T68', 'wh-http', 'x', 'WEBHOOK', 'http://x.vn/hook', 'kv/dh/t68/obs/wh', 's', 's')$s$);
SELECT pg_temp.expect_fail('38b webhook thiếu bí mật bị chặn', '23514',
  $s$INSERT INTO ph13_obs.notification_channel (id, tenant_id, channel_code, name, kind, target, created_by, updated_by) VALUES (gen_random_uuid(), 'T68', 'wh-khong-khoa', 'x', 'WEBHOOK', 'https://x.vn/hook', 's', 's')$s$);
SELECT pg_temp.expect_fail('38c kênh SMS lưu số điện thoại cá nhân bị chặn', '23514',
  $s$INSERT INTO ph13_obs.notification_channel (id, tenant_id, channel_code, name, kind, target, created_by, updated_by) VALUES (gen_random_uuid(), 'T68', 'sms-ca-nhan', 'x', 'SMS', '0912345678', 's', 's')$s$);
SELECT pg_temp.expect_ok('38d kênh SMS theo mã nhóm, đánh dấu độc lập hạ tầng',
  $s$INSERT INTO ph13_obs.notification_channel (id, tenant_id, channel_code, name, kind, target, external, created_by, updated_by) VALUES (gen_random_uuid(), 'T68', 'sms-truc-van-hanh', 'SMS nhóm trực', 'SMS', 'nhom-truc-van-hanh', true, 's', 's')$s$);
SELECT pg_temp.expect_fail('38e đường dẫn bí mật ngoài kv/dh bị chặn', '23514',
  $s$INSERT INTO ph13_obs.notification_channel (id, tenant_id, channel_code, name, kind, target, secret_ref, created_by, updated_by) VALUES (gen_random_uuid(), 'T68', 'wh-khoa-la', 'x', 'WEBHOOK', 'https://x.vn/hook', 'secret/abc', 's', 's')$s$);
SELECT pg_temp.expect_fail('39a điểm xuất cho cơ quan chuyên trách bật thiếu căn cứ bị chặn (BR-13-034)', '23514',
  $s$INSERT INTO ph13_obs.siem_target (id, tenant_id, target_code, name, protocol, endpoint, purpose, created_by, updated_by) VALUES (gen_random_uuid(), 'T68', 'bo-cong-an', 'x', 'SYSLOG_TLS', 'siem.gov.vn:6514', 'AUTHORITY', 's', 's')$s$);
SELECT pg_temp.expect_ok('39b điểm xuất cơ quan chuyên trách tắt mặc định được tạo',
  $s$INSERT INTO ph13_obs.siem_target (id, tenant_id, target_code, name, protocol, endpoint, purpose, enabled, created_by, updated_by) VALUES (gen_random_uuid(), 'T68', 'bo-cong-an', 'Cơ quan chuyên trách', 'SYSLOG_TLS', 'siem.gov.vn:6514', 'AUTHORITY', false, 's', 's')$s$);
SELECT pg_temp.expect_fail('39c bật điểm xuất khi chưa có số hiệu văn bản bị chặn', '23514', $s$UPDATE ph13_obs.siem_target SET enabled = true WHERE target_code = 'bo-cong-an'$s$);
SELECT pg_temp.expect_ok('39d bật khi có số hiệu văn bản', $s$UPDATE ph13_obs.siem_target SET enabled = true, basis_ref = 'CV 123/A05 ngày 01/12/2026' WHERE target_code = 'bo-cong-an'$s$);
SELECT pg_temp.expect_fail('40a topic mang tenant khác bị chặn', '23514',
  $s$INSERT INTO ph13_obs.outbox (event_id, tenant_id, event_type, topic, aggregate_type, aggregate_id, payload, trace_id) VALUES (gen_random_uuid(), 'T68', 'EVT-13-01', 't01.obs.alert.fired.v1', 'alert', 'x', '{}', repeat('0', 32))$s$);
SELECT pg_temp.expect_fail('40b outbox chặn khóa bí mật trong payload', '23514',
  $s$INSERT INTO ph13_obs.outbox (event_id, tenant_id, event_type, topic, aggregate_type, aggregate_id, payload, trace_id) VALUES (gen_random_uuid(), 'T68', 'EVT-13-01', 't68.obs.alert.fired.v1', 'alert', 'x', '{"secret": "abc"}', repeat('0', 32))$s$);
SELECT pg_temp.expect_ok('40c outbox hợp lệ',
  $s$INSERT INTO ph13_obs.outbox (event_id, tenant_id, event_type, topic, aggregate_type, aggregate_id, payload, trace_id) VALUES (gen_random_uuid(), 'T68', 'EVT-13-01', 't68.obs.alert.fired.v1', 'alert', 'x', '{"ruleCode": "api-5xx-cao"}', repeat('0', 32))$s$);
SELECT pg_temp.expect_fail('41a báo cáo vi phạm DLCN thiếu hạn 72 giờ bị chặn', '23514',
  $s$INSERT INTO ph13_obs.incident_report (id, tenant_id, report_code, kind, template, detected_at, created_by, updated_by) VALUES (gen_random_uuid(), 'T68', 'bc-001', 'DLCN_BREACH', 'mau-dlcn-72h', now(), 's', 's')$s$);
SELECT pg_temp.expect_ok('41b báo cáo vi phạm DLCN có hạn 72 giờ',
  $s$INSERT INTO ph13_obs.incident_report (id, tenant_id, report_code, kind, template, detected_at, deadline_at, created_by, updated_by) VALUES (gen_random_uuid(), 'T68', 'bc-001', 'DLCN_BREACH', 'mau-dlcn-72h', now(), now() + interval '72 hours', 's', 's')$s$);
SELECT pg_temp.expect_ok('41c chốt báo cáo', $s$UPDATE ph13_obs.incident_report SET status = 'FINAL', finalized_at = now(), finalized_by = 'so1' WHERE report_code = 'bc-001'$s$);
SELECT pg_temp.expect_fail('41d báo cáo FINAL bất biến', '55000', $s$UPDATE ph13_obs.incident_report SET content = '{"a":1}' WHERE report_code = 'bc-001'$s$);
SELECT pg_temp.expect_fail('42 PII finding không xóa trong 12 tháng', '55000',
  $s$INSERT INTO ph13_obs.pii_finding (id, tenant_id, scan_date, du_code, logger, pattern_code, occurrences, created_by) VALUES (gen_random_uuid(), 'T68', current_date, 'dh-data', 'vn.datahub.Foo', 'EMAIL', 3, 's')$s$,
  $s$DELETE FROM ph13_obs.pii_finding WHERE tenant_id = 'T68'$s$);

-- Vai trò đọc báo cáo
RESET ROLE; SET ROLE dh_platform_ro; SET app.tenant_id = 'T68';
SELECT pg_temp.expect_count('43 ph13_readonly đọc được cảnh báo của T68', 'SELECT count(*) FROM ph13_obs.alert', 3);
SELECT pg_temp.expect_fail('43b ph13_readonly không đọc được đường dẫn bí mật kênh', '42501', 'SELECT secret_ref FROM ph13_obs.notification_channel');
SELECT pg_temp.expect_fail('43c ph13_readonly không đọc được nội dung báo cáo sự cố', '42501', 'SELECT content FROM ph13_obs.incident_report');
SELECT pg_temp.expect_count('43d ph13_readonly đọc được cột danh mục kênh', 'SELECT count(*) FROM (SELECT channel_code, kind FROM ph13_obs.notification_channel) x', 2);
SELECT pg_temp.expect_fail('43e ph13_readonly không ghi được', '42501', $s$UPDATE ph13_obs.alert SET summary = 'x'$s$);
RESET ROLE;
