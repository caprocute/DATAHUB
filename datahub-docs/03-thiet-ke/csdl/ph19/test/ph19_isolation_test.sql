-- =============================================================================
-- D03-03-PH19 · Kiểm thử DDL ph19_payment: cô lập tenant, bất biến, tách nhiệm, ràng buộc nghiệp vụ.
-- Chạy sau ph19_payment.sql trên CSDL rỗng:
--   psql -v ON_ERROR_STOP=1 -d datahub -f ph19_isolation_test.sql
-- Mỗi khối DO kiểm một điều; lỗi mong đợi bị bắt và ghi PASS, sai thì RAISE làm dừng tệp.
-- Tương ứng TS-19-31 (cô lập), TS-19-33 (tách nhiệm), TS-19-34 (bất biến) của D05-02-PH19.
-- =============================================================================
\set ON_ERROR_STOP on
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'dh_payment_app') THEN
    CREATE ROLE dh_payment_app LOGIN NOBYPASSRLS IN ROLE ph19_app;
  END IF;
END $$;
SET ROLE dh_payment_app;

CREATE TEMP TABLE ids (k text PRIMARY KEY, v uuid);
INSERT INTO ids SELECT k, gen_random_uuid() FROM unnest(ARRAY['prov68','grp68','svc68','par68','txn68','prov01','grp01','svc01','par01','txn01','sess68','appr68','disc68','job68']) k;
CREATE FUNCTION pg_temp.id(text) RETURNS uuid LANGUAGE sql AS $$ SELECT v FROM ids WHERE k = $1 $$;

-- ---------- Dữ liệu T68 ----------
SET app.tenant_id = 'T68';
INSERT INTO ph19_payment.payment_provider (id, tenant_id, code, name, adapter_type, connection_key_hash, created_by, updated_by)
VALUES (pg_temp.id('prov68'), 'T68', 'PAYGOV', 'Nền tảng thanh toán quốc gia', 'PAYGOV', repeat('a', 64), 'u1', 'u1');
SELECT ph19_payment.seed_paygov_mapping(pg_temp.id('prov68'), 'u1') AS seeded_rows;
INSERT INTO ph19_payment.payment_service_group (id, tenant_id, code, name, created_by, updated_by) VALUES (pg_temp.id('grp68'), 'T68', 'HO_TICH', 'Hộ tịch', 'u1', 'u1');
INSERT INTO ph19_payment.payment_service (id, tenant_id, code, name, group_id, provider_id, fee_type_code, collecting_agency_code, min_amount, max_amount, created_by, updated_by)
VALUES (pg_temp.id('svc68'), 'T68', 'LE_PHI_KHAI_SINH', 'Lệ phí đăng ký khai sinh', pg_temp.id('grp68'), pg_temp.id('prov68'), 'LE_PHI', 'STP68', 1000, 5000000, 'u1', 'u1');
INSERT INTO ph19_payment.payment_partner (id, tenant_id, code, name, agency_code, created_by, updated_by) VALUES (pg_temp.id('par68'), 'T68', 'MCDT', 'Hệ thống thông tin giải quyết TTHC', 'VP-UBND', 'u1', 'u1');
INSERT INTO ph19_payment.transaction_code_index VALUES (pg_temp.id('txn68'), 'T68', 'T68261126ABCDEFGHJK', '2026-11-26 03:00Z');
INSERT INTO ph19_payment.payment_transaction (id, tenant_id, transaction_code, partner_id, service_id, provider_id, partner_order_id, amount, description, return_url, expires_at, trace_id, created_at)
VALUES (pg_temp.id('txn68'), 'T68', 'T68261126ABCDEFGHJK', pg_temp.id('par68'), pg_temp.id('svc68'), pg_temp.id('prov68'), 'HS-0001', 50000, 'Lệ phí khai sinh', 'https://dvc.t68.gov.vn/ket-qua', '2026-11-26 03:15Z', repeat('0', 32), '2026-11-26 03:00Z');
INSERT INTO ph19_payment.transaction_order_guard VALUES ('T68', pg_temp.id('par68'), 'HS-0001', pg_temp.id('txn68'));
INSERT INTO ph19_payment.transaction_event (id, tenant_id, transaction_id, sequence, to_status, source, trace_id)
VALUES (gen_random_uuid(), 'T68', pg_temp.id('txn68'), 1, 'CREATED', 'PARTNER_API', repeat('0', 32));

INSERT INTO ph19_payment.callback_route (connection_key_hash, tenant_id, provider_id, adapter_type) VALUES (repeat('a', 64), 'T68', pg_temp.id('prov68'), 'PAYGOV');

-- ---------- Dữ liệu T01 ----------
SET app.tenant_id = 'T01';
INSERT INTO ph19_payment.payment_provider (id, tenant_id, code, name, adapter_type, connection_key_hash, created_by, updated_by)
VALUES (pg_temp.id('prov01'), 'T01', 'PAYGOV', 'PayGov T01', 'PAYGOV', repeat('b', 64), 'u9', 'u9');

-- 1. Mỗi tenant chỉ thấy dữ liệu của mình
DO $$ DECLARE n int; BEGIN
  SELECT count(*) INTO n FROM ph19_payment.payment_provider;
  IF n <> 1 THEN RAISE EXCEPTION 'FAIL 1: T01 thấy % NCC', n; END IF;
  SELECT count(*) INTO n FROM ph19_payment.payment_transaction;
  IF n <> 0 THEN RAISE EXCEPTION 'FAIL 1: T01 thấy giao dịch của T68'; END IF;
  SELECT count(*) INTO n FROM ph19_payment.provider_result_mapping;
  IF n <> 0 THEN RAISE EXCEPTION 'FAIL 1: T01 thấy ánh xạ của T68'; END IF;
  RAISE NOTICE 'PASS 1 cô lập đọc';
END $$;

-- 2. WITH CHECK: không ghi được dòng mang tenant khác
DO $$ BEGIN
  INSERT INTO ph19_payment.payment_service_group (id, tenant_id, code, name, created_by, updated_by) VALUES (gen_random_uuid(), 'T68', 'X1', 'x', 'u9', 'u9');
  RAISE EXCEPTION 'FAIL 2: ghi chéo tenant được chấp nhận';
EXCEPTION WHEN insufficient_privilege THEN RAISE NOTICE 'PASS 2 chặn ghi chéo tenant';
END $$;

-- 3. Không cập nhật được dòng tenant khác (0 dòng)
DO $$ DECLARE n int; BEGIN
  UPDATE ph19_payment.payment_transaction SET description = 'x' WHERE transaction_code = 'T68261126ABCDEFGHJK';
  GET DIAGNOSTICS n = ROW_COUNT;
  IF n <> 0 THEN RAISE EXCEPTION 'FAIL 3'; END IF;
  RAISE NOTICE 'PASS 3 không sửa được dòng tenant khác';
END $$;

-- 4. Khóa ngoại kép không trỏ được sang bản ghi tenant khác
DO $$ BEGIN
  INSERT INTO ph19_payment.payment_service_group (id, tenant_id, code, name, created_by, updated_by) VALUES (pg_temp.id('grp01'), 'T01', 'HO_TICH', 'Hộ tịch', 'u9', 'u9');
  INSERT INTO ph19_payment.payment_service (id, tenant_id, code, name, group_id, provider_id, fee_type_code, collecting_agency_code, min_amount, max_amount, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T01', 'S1', 's', pg_temp.id('grp01'), pg_temp.id('prov68'), 'LE_PHI', 'X', 1000, 2000, 'u9', 'u9');
  RAISE EXCEPTION 'FAIL 4';
EXCEPTION WHEN foreign_key_violation THEN RAISE NOTICE 'PASS 4 FK kép chặn tham chiếu chéo tenant';
END $$;

-- 5. Thiếu app.tenant_id: lỗi (phiên mới) hoặc thấy 0 dòng (biến đã về rỗng sau SET LOCAL), không bao giờ lộ dữ liệu
RESET app.tenant_id;
DO $$ DECLARE n int; BEGIN
  SELECT count(*) INTO n FROM ph19_payment.payment_provider;
  IF n <> 0 THEN RAISE EXCEPTION 'FAIL 5: thấy % dòng khi không có tenant', n; END IF;
  RAISE NOTICE 'PASS 5 không có tenant thì không thấy dòng nào';
EXCEPTION WHEN undefined_object THEN RAISE NOTICE 'PASS 5 thiếu app.tenant_id thì lỗi';
END $$;

SET app.tenant_id = 'T68';
-- 6. transaction_event bất biến
DO $$ BEGIN
  UPDATE ph19_payment.transaction_event SET reason = 'sửa' WHERE transaction_id = pg_temp.id('txn68');
  RAISE EXCEPTION 'FAIL 6';
EXCEPTION WHEN insufficient_privilege OR sqlstate 'P1930' THEN RAISE NOTICE 'PASS 6 lịch sử trạng thái bất biến';
END $$;

-- 7. callback_inbox: phần nguyên văn bất biến, phần xử lý cập nhật được
INSERT INTO ph19_payment.callback_inbox (id, tenant_id, provider_id, callback_type, source_ip, raw_headers, raw_body, raw_hash, verification_result, processing_status, trace_id, received_at)
VALUES ('00000000-0000-7000-8000-000000000001', 'T68', pg_temp.id('prov68'), 'PAYMENT', '10.20.0.5', '{}', '{"code":"00"}', repeat('c', 64), 'VERIFIED', 'RECEIVED', repeat('0', 32), '2026-11-26 03:05Z');
UPDATE ph19_payment.callback_inbox SET processing_status = 'PROCESSED', processed_at = now() WHERE id = '00000000-0000-7000-8000-000000000001';
DO $$ BEGIN
  UPDATE ph19_payment.callback_inbox SET raw_body = '{"code":"02"}' WHERE id = '00000000-0000-7000-8000-000000000001';
  RAISE EXCEPTION 'FAIL 7';
EXCEPTION WHEN sqlstate 'P1930' THEN RAISE NOTICE 'PASS 7 nguyên văn IPN bất biến';
END $$;

-- 8. BR-19-007: một mã hồ sơ chỉ một giao dịch đang hiệu lực
DO $$ BEGIN
  INSERT INTO ph19_payment.transaction_order_guard VALUES ('T68', pg_temp.id('par68'), 'HS-0001', pg_temp.id('txn68'));
  RAISE EXCEPTION 'FAIL 8';
EXCEPTION WHEN unique_violation THEN RAISE NOTICE 'PASS 8 chống trùng mã hồ sơ';
END $$;

-- 9. Tách nhiệm: người duyệt không là người lập
INSERT INTO ph19_payment.approval_request (id, tenant_id, approval_type, target_type, target_id, payload, required_approvals, requested_by, expires_at)
VALUES (pg_temp.id('appr68'), 'T68', 'REFUND', 'REFUND', gen_random_uuid(), '{"amount":50000}', 2, 'ketoan1', now() + interval '7 days');
DO $$ BEGIN
  UPDATE ph19_payment.approval_request SET first_approver_id = 'ketoan1', first_decided_at = now() WHERE id = pg_temp.id('appr68');
  RAISE EXCEPTION 'FAIL 9a';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 9a người lập không tự duyệt';
END $$;
UPDATE ph19_payment.approval_request SET first_approver_id = 'truongphong', first_decided_at = now() WHERE id = pg_temp.id('appr68');
DO $$ BEGIN
  UPDATE ph19_payment.approval_request SET second_approver_id = 'truongphong', second_decided_at = now() WHERE id = pg_temp.id('appr68');
  RAISE EXCEPTION 'FAIL 9b';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 9b cấp 2 khác cấp 1';
END $$;
DO $$ BEGIN
  UPDATE ph19_payment.approval_request SET status = 'APPROVED' WHERE id = pg_temp.id('appr68');
  RAISE EXCEPTION 'FAIL 9c';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 9c chưa đủ hai cấp thì không APPROVED';
END $$;
-- 9d. Một đề nghị PENDING cho mỗi đối tượng, loại
DO $$ DECLARE t uuid; BEGIN
  SELECT target_id INTO t FROM ph19_payment.approval_request WHERE id = pg_temp.id('appr68');
  INSERT INTO ph19_payment.approval_request (id, tenant_id, approval_type, target_type, target_id, payload, requested_by, expires_at)
  VALUES (gen_random_uuid(), 'T68', 'REFUND', 'REFUND', t, '{}', 'ketoan2', now() + interval '7 days');
  RAISE EXCEPTION 'FAIL 9d';
EXCEPTION WHEN unique_violation THEN RAISE NOTICE 'PASS 9d một đề nghị chờ cho mỗi đối tượng';
END $$;

-- 10. BR-19-022: một yêu cầu hoàn chưa kết thúc mỗi giao dịch; số tiền hoàn không vượt số tiền gốc
INSERT INTO ph19_payment.refund_request (id, tenant_id, refund_code, transaction_id, partner_id, requested_by_type, requested_by, amount, mode, reason_code, trace_id)
VALUES (gen_random_uuid(), 'T68', 'RABCDEFGHJK0001', pg_temp.id('txn68'), pg_temp.id('par68'), 'USER', 'ketoan1', 20000, 'MANUAL', 'THU_THUA', repeat('0', 32));
DO $$ BEGIN
  INSERT INTO ph19_payment.refund_request (id, tenant_id, refund_code, transaction_id, partner_id, requested_by_type, requested_by, amount, mode, reason_code, trace_id)
  VALUES (gen_random_uuid(), 'T68', 'RABCDEFGHJK0002', pg_temp.id('txn68'), pg_temp.id('par68'), 'USER', 'ketoan1', 10000, 'MANUAL', 'THU_THUA', repeat('0', 32));
  RAISE EXCEPTION 'FAIL 10a';
EXCEPTION WHEN unique_violation THEN RAISE NOTICE 'PASS 10a một yêu cầu hoàn đang mở';
END $$;
DO $$ BEGIN
  UPDATE ph19_payment.payment_transaction SET status = 'SUCCEEDED', paid_at = now(), refunded_amount = 60000 WHERE id = pg_temp.id('txn68');
  RAISE EXCEPTION 'FAIL 10b';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 10b hoàn không vượt số tiền';
END $$;
DO $$ BEGIN
  UPDATE ph19_payment.payment_transaction SET status = 'SUCCEEDED' WHERE id = pg_temp.id('txn68');
  RAISE EXCEPTION 'FAIL 10c';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 10c SUCCEEDED phải có paid_at';
END $$;
UPDATE ph19_payment.payment_transaction SET status = 'SUCCEEDED', paid_at = now(), version = version + 1 WHERE id = pg_temp.id('txn68');

-- 11. Ghi chú chênh lệch chỉ nối thêm
INSERT INTO ph19_payment.reconciliation_session (id, tenant_id, provider_id, business_date) VALUES (pg_temp.id('sess68'), 'T68', pg_temp.id('prov68'), '2026-11-26');
INSERT INTO ph19_payment.discrepancy (id, tenant_id, discrepancy_code, session_id, type, transaction_id, due_at)
VALUES (pg_temp.id('disc68'), 'T68', 'CL-20261126-0001', pg_temp.id('sess68'), 'MISSING_AT_PROVIDER', pg_temp.id('txn68'), now() + interval '3 days');
SELECT ph19_payment.append_discrepancy_note(pg_temp.id('disc68'), 'ketoan1', 'Đã gửi yêu cầu hỗ trợ tới NCC') AS notes_after_1;
SELECT ph19_payment.append_discrepancy_note(pg_temp.id('disc68'), 'ketoan1', 'NCC xác nhận đã nhận tiền') AS notes_after_2;
DO $$ BEGIN
  UPDATE ph19_payment.discrepancy SET notes = '[]' WHERE id = pg_temp.id('disc68');
  RAISE EXCEPTION 'FAIL 11a';
EXCEPTION WHEN sqlstate 'P1930' THEN RAISE NOTICE 'PASS 11a không xóa ghi chú';
END $$;
DO $$ BEGIN
  UPDATE ph19_payment.discrepancy SET notes = jsonb_set(notes, '{0,text}', '"đã sửa"') WHERE id = pg_temp.id('disc68');
  RAISE EXCEPTION 'FAIL 11b';
EXCEPTION WHEN sqlstate 'P1930' THEN RAISE NOTICE 'PASS 11b không sửa ghi chú cũ';
END $$;
DO $$ BEGIN
  UPDATE ph19_payment.discrepancy SET status = 'RESOLVED', resolution_type = 'NO_ACTION', resolved_at = now() WHERE id = pg_temp.id('disc68');
  RAISE EXCEPTION 'FAIL 11c';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 11c NO_ACTION phải có lý do';
END $$;

-- 12. Ánh xạ mã: phiên bản đang dùng không sửa được; SUCCEEDED phải là kết cục cuối
DO $$ BEGIN
  UPDATE ph19_payment.provider_result_mapping SET outcome = 'FAILED' WHERE provider_code = '00' AND operation = 'IPN';
  RAISE EXCEPTION 'FAIL 12a';
EXCEPTION WHEN sqlstate 'P1930' THEN RAISE NOTICE 'PASS 12a ánh xạ đang dùng bất biến';
END $$;
DO $$ BEGIN
  INSERT INTO ph19_payment.provider_result_mapping (id, tenant_id, provider_id, mapping_version, operation, provider_code, outcome, is_final, message_vi, created_by)
  VALUES (gen_random_uuid(), 'T68', pg_temp.id('prov68'), 2, 'IPN', '00', 'SUCCEEDED', false, 'x', 'u1');
  RAISE EXCEPTION 'FAIL 12b';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 12b SUCCEEDED luôn là kết cục cuối';
END $$;

-- 13. Quyền: ứng dụng không xóa được giao dịch; tài khoản chỉ đọc không đọc được tham chiếu bí mật
DO $$ BEGIN
  DELETE FROM ph19_payment.payment_transaction WHERE id = pg_temp.id('txn68');
  RAISE EXCEPTION 'FAIL 13a';
EXCEPTION WHEN insufficient_privilege THEN RAISE NOTICE 'PASS 13a ứng dụng không xóa giao dịch';
END $$;
RESET ROLE;
DO $$ BEGIN
  IF has_table_privilege('ph19_readonly', 'ph19_payment.provider_credential', 'SELECT') THEN RAISE EXCEPTION 'FAIL 13b'; END IF;
  IF has_table_privilege('ph19_app', 'ph19_payment.tenant_payment_config', 'UPDATE') THEN RAISE EXCEPTION 'FAIL 13c'; END IF;
  RAISE NOTICE 'PASS 13b/c quyền chỉ đọc và cấu hình bất biến';
END $$;

-- 15. callback_route: tra được trước khi biết tenant, không trỏ được NCC của tenant khác
SET ROLE dh_payment_app;
RESET app.tenant_id;
DO $$ DECLARE t text; BEGIN
  SELECT tenant_id INTO t FROM ph19_payment.callback_route WHERE connection_key_hash = repeat('a', 64);
  IF t IS DISTINCT FROM 'T68' THEN RAISE EXCEPTION 'FAIL 15a'; END IF;
  RAISE NOTICE 'PASS 15a định tuyến callback không cần tenant';
END $$;
DO $$ BEGIN
  INSERT INTO ph19_payment.callback_route (connection_key_hash, tenant_id, provider_id, adapter_type) VALUES (repeat('d', 64), 'T01', pg_temp.id('prov68'), 'PAYGOV');
  RAISE EXCEPTION 'FAIL 15b';
EXCEPTION WHEN foreign_key_violation THEN RAISE NOTICE 'PASS 15b định tuyến không trỏ chéo tenant';
END $$;
RESET ROLE;

-- 14. Bảng có tenant_id đều bật FORCE RLS (trừ callback_route có chủ đích)
DO $$ DECLARE r record; n int := 0; BEGIN
  FOR r IN SELECT c.relname, c.relrowsecurity, c.relforcerowsecurity FROM pg_class c JOIN pg_namespace s ON s.oid = c.relnamespace
           WHERE s.nspname = 'ph19_payment' AND c.relkind IN ('r', 'p') AND NOT c.relispartition
             AND c.relname <> 'callback_route'
             AND EXISTS (SELECT 1 FROM pg_attribute a WHERE a.attrelid = c.oid AND a.attname = 'tenant_id') LOOP
    n := n + 1;
    IF NOT (r.relrowsecurity AND r.relforcerowsecurity) THEN RAISE EXCEPTION 'FAIL 14: % chưa bật FORCE RLS', r.relname; END IF;
  END LOOP;
  RAISE NOTICE 'PASS 14 % bảng có tenant_id đều FORCE RLS', n;
END $$;
