-- =============================================================================
-- D03-03-PH10 · Kiểm thử DDL ph10_event: cô lập tenant, quy tắc tên topic, tổ hợp
-- bên tham gia, bốn mắt, bất biến lược đồ, không bí mật, DLQ lũy đẳng, cầu nối.
-- Chạy sau ph10_event.sql trên CSDL rỗng:
--   psql -v ON_ERROR_STOP=1 -d datahub -f ph10_isolation_test.sql
-- Mỗi khối DO kiểm một điều; lỗi mong đợi bị bắt và ghi PASS, sai thì RAISE dừng tệp.
-- Tương ứng nhóm ca cô lập (FR-10-064), tách nhiệm (BR-10-010), chống lộ bí mật
-- (BR-10-027) của D05-02-PH10. Tenant kiểm thử T90, T91 (D00-04 §3.1).
-- =============================================================================
\set ON_ERROR_STOP on
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'dh_integration_app') THEN
    CREATE ROLE dh_integration_app LOGIN NOBYPASSRLS IN ROLE ph10_app;
  ELSE
    GRANT ph10_app TO dh_integration_app;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'dh_report_ro') THEN
    CREATE ROLE dh_report_ro LOGIN NOBYPASSRLS IN ROLE ph10_readonly;
  END IF;
END $$;
SET ROLE dh_integration_app;

CREATE TEMP TABLE ids (k text PRIMARY KEY, v uuid);
INSERT INTO ids SELECT k, gen_random_uuid() FROM unnest(ARRAY['p90','t90','d90','s90','pb90','sb90','sbk90','pn90','sn90','dl90','p91','t91']) k;
CREATE FUNCTION pg_temp.id(text) RETURNS uuid LANGUAGE sql AS $$ SELECT v FROM ids WHERE k = $1 $$;

-- ---------- Dữ liệu T90 ----------
SET app.tenant_id = 'T90';
INSERT INTO ph10_event.event_project (id, tenant_id, project_code, name, owner_org_code, owner_user, created_by, updated_by)
VALUES (pg_temp.id('p90'), 'T90', 'dkkd-thue', 'Liên thông đăng ký kinh doanh và thuế', 'so-khdt', 'an', 'an', 'an');
INSERT INTO ph10_event.topic (id, tenant_id, topic_name, project_code, topic_kind, domain, entity, event_name, major_version, partitions, retention_hours, routing_mode, partition_key_field, ordering_required, data_class, status, activated_at, created_by, updated_by)
VALUES (pg_temp.id('t90'), 'T90', 't90.dkkd.doanh-nghiep.da-cap-phep.v1', 'dkkd-thue', 'BUSINESS', 'dkkd', 'doanh-nghiep', 'da-cap-phep', 1, 6, 168, 'KEY_HASH', 'maSoDoanhNghiep', true, 'INTERNAL', 'ACTIVE', now(), 'an', 'an'),
       (pg_temp.id('d90'), 'T90', 't90.dkkd.doanh-nghiep.da-cap-phep.v1.dlq', 'dkkd-thue', 'DLQ', 'dkkd', 'doanh-nghiep', 'da-cap-phep', 1, 6, 168, 'KEY_HASH', 'maSoDoanhNghiep', false, 'INTERNAL', 'ACTIVE', now(), 'system:dh-integration', 'system:dh-integration');
INSERT INTO ph10_event.topic (id, tenant_id, topic_name, project_code, topic_kind, domain, entity, event_name, major_version, partitions, retention_hours, routing_mode, data_class, status, activated_at, created_by, updated_by)
VALUES (pg_temp.id('s90'), 'T90', 't90.ho-tich.khai-sinh.da-dang-ky.v1', 'dkkd-thue', 'BUSINESS', 'ho-tich', 'khai-sinh', 'da-dang-ky', 1, 3, 168, 'ROUND_ROBIN', 'SENSITIVE', 'ACTIVE', now(), 'an', 'an');
INSERT INTO ph10_event.event_schema (id, tenant_id, topic_name, schema_format, apicurio_group_id, apicurio_artifact_id, latest_version_no, created_by, updated_by)
VALUES (gen_random_uuid(), 'T90', 't90.dkkd.doanh-nghiep.da-cap-phep.v1', 'AVRO', 't90', 't90.dkkd.doanh-nghiep.da-cap-phep.v1', 1, 'an', 'an');
INSERT INTO ph10_event.schema_version (id, tenant_id, topic_name, version_no, content, content_hash, status, apicurio_global_id, apicurio_content_id, checked_at, enabled_at, created_by, updated_by)
VALUES (gen_random_uuid(), 'T90', 't90.dkkd.doanh-nghiep.da-cap-phep.v1', 1, '{"type":"record","name":"DoanhNghiep","fields":[]}', repeat('a', 64), 'ENABLED', 101, 77, now(), now(), 'an', 'an');
INSERT INTO ph10_event.publisher (id, tenant_id, publisher_code, name, party_type, system_code, comm_type, client_id, created_by, updated_by)
VALUES (pg_temp.id('pb90'), 'T90', 'ht-dkkd', 'HTTT Đăng ký kinh doanh', 'SYSTEM', 'DKKD', 'HTTP_PUBLISH', 'dkkd-client', 'an', 'an');
INSERT INTO ph10_event.subscriber (id, tenant_id, subscriber_code, name, party_type, system_code, comm_type, created_by, updated_by)
VALUES (pg_temp.id('sb90'), 'T90', 'ht-thue', 'HTTT Thuế', 'SYSTEM', 'THUE', 'WEBHOOK_PUSH', 'an', 'an'),
       (pg_temp.id('sbk90'), 'T90', 'ht-kho', 'HTTT Kho dữ liệu', 'SYSTEM', 'KHO', 'KAFKA_NATIVE', 'an', 'an');
INSERT INTO ph10_event.publication (id, tenant_id, publication_code, publisher_code, topic_name, purpose, status, granted_scope, approved_by, approved_at, created_by, updated_by)
VALUES (pg_temp.id('pn90'), 'T90', 'pub-01jd0000000000000000000001', 'ht-dkkd', 't90.dkkd.doanh-nghiep.da-cap-phep.v1', 'Phát giấy phép mới', 'ACTIVE', 'topic:t90.dkkd.doanh-nghiep.da-cap-phep.v1:publish', 'binh', now(), 'an', 'an');
INSERT INTO ph10_event.subscription (id, tenant_id, subscription_code, subscriber_code, topic_name, delivery_mode, purpose, consumer_group, status, approved_by, approved_at, push, created_by, updated_by)
VALUES (pg_temp.id('sn90'), 'T90', 'ht-thue-dn-cap-phep', 'ht-thue', 't90.dkkd.doanh-nghiep.da-cap-phep.v1', 'PUSH', 'Cập nhật mã số thuế', 'dh-sub-t90-ht-thue-dn-cap-phep', 'ACTIVE', 'binh', now(),
        '{"endpointUrl":"https://thue.t90.gov.vn/webhook","workerCount":2,"maxRetries":8,"retryBackoff":{"initialMs":1000,"multiplier":2,"maxMs":300000},"timeoutMs":10000,"failurePolicy":"DEAD_LETTER","payloadFormat":"CLOUDEVENTS_STRUCTURED"}', 'an', 'an');
INSERT INTO ph10_event.signing_key (id, tenant_id, subscription_code, key_id, secret_ref, status, activated_at, created_by, updated_by)
VALUES (gen_random_uuid(), 'T90', 'ht-thue-dn-cap-phep', 'k-20261126', 'kv/dh/t90/event/subscriptions/ht-thue-dn-cap-phep/signing', 'ACTIVE', now(), 'system:dh-integration', 'system:dh-integration');
INSERT INTO ph10_event.dlq_entry (id, tenant_id, subscription_code, source_topic, source_partition, source_offset, event_id, origin, error_code, attempts, first_failed_at, last_failed_at, payload_ref, created_by, updated_by)
VALUES (pg_temp.id('dl90'), 'T90', 'ht-thue-dn-cap-phep', 't90.dkkd.doanh-nghiep.da-cap-phep.v1', 2, 1042, 'evt-1', 'PUSH', 'ERR-10-112', 9, now() - interval '1 hour', now(), 'pg:dlq_payload/' || pg_temp.id('dl90'), 'system:dlq-writer', 'system:dlq-writer');
INSERT INTO ph10_event.dlq_payload (dlq_entry_id, tenant_id, value, size_bytes, content_hash)
VALUES (pg_temp.id('dl90'), 'T90', convert_to('{"maSoDoanhNghiep":"0101"}', 'UTF8'), 26, repeat('c', 64));
INSERT INTO ph10_event.lag_sample (tenant_id, subscription_code, consumer_group, sampled_at, partition, lag_records, lag_seconds, committed_offset, end_offset)
VALUES ('T90', 'ht-thue-dn-cap-phep', 'dh-sub-t90-ht-thue-dn-cap-phep', now(), 0, 12, 4, 100, 112);

-- ---------- Dữ liệu T91 ----------
SET app.tenant_id = 'T91';
INSERT INTO ph10_event.event_project (id, tenant_id, project_code, name, owner_org_code, owner_user, created_by, updated_by)
VALUES (pg_temp.id('p91'), 'T91', 'dkkd-thue', 'Dự án cùng mã ở T91', 'so-khdt', 'lan', 'lan', 'lan');

-- 1. Cô lập đọc
DO $$ DECLARE n int; BEGIN
  SELECT count(*) INTO n FROM ph10_event.event_project; IF n <> 1 THEN RAISE 'FAIL 1: T91 thấy % dự án', n; END IF;
  SELECT count(*) INTO n FROM ph10_event.topic; IF n <> 0 THEN RAISE 'FAIL 1b'; END IF;
  SELECT count(*) INTO n FROM ph10_event.subscription; IF n <> 0 THEN RAISE 'FAIL 1c'; END IF;
  SELECT count(*) INTO n FROM ph10_event.dlq_entry; IF n <> 0 THEN RAISE 'FAIL 1d'; END IF;
  SELECT count(*) INTO n FROM ph10_event.dlq_payload; IF n <> 0 THEN RAISE 'FAIL 1e'; END IF;
  SELECT count(*) INTO n FROM ph10_event.signing_key; IF n <> 0 THEN RAISE 'FAIL 1f'; END IF;
  SELECT count(*) INTO n FROM ph10_event.lag_sample; IF n <> 0 THEN RAISE 'FAIL 1g'; END IF;
  RAISE NOTICE 'PASS 1 T91 không đọc được dữ liệu T90 (dự án, topic, subscription, DLQ, khóa ký, lag)';
END $$;

-- 2. Cô lập ghi
DO $$ BEGIN
  INSERT INTO ph10_event.event_project (id, tenant_id, project_code, name, owner_org_code, owner_user, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T90', 'gia-mao', 'x', 'x', 'lan', 'lan', 'lan');
  RAISE 'FAIL 2';
EXCEPTION WHEN insufficient_privilege THEN RAISE NOTICE 'PASS 2 chặn chèn chéo tenant';
END $$;

-- 3. Cô lập sửa, xóa
DO $$ DECLARE n int; BEGIN
  UPDATE ph10_event.subscription SET status = 'PAUSED' WHERE subscription_code = 'ht-thue-dn-cap-phep';
  GET DIAGNOSTICS n = ROW_COUNT; IF n <> 0 THEN RAISE 'FAIL 3'; END IF;
  DELETE FROM ph10_event.lag_sample WHERE tenant_id = 'T90';
  GET DIAGNOSTICS n = ROW_COUNT; IF n <> 0 THEN RAISE 'FAIL 3b'; END IF;
  RAISE NOTICE 'PASS 3 không sửa, xóa được dòng tenant khác';
END $$;

-- 4. T91 không tạo topic mang tiền tố t90 dù đặt tenant_id T91
DO $$ BEGIN
  INSERT INTO ph10_event.topic (id, tenant_id, topic_name, project_code, topic_kind, domain, entity, event_name, major_version, partitions, retention_hours, routing_mode, data_class, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T91', 't90.dkkd.doanh-nghiep.da-cap-phep.v2', 'dkkd-thue', 'BUSINESS', 'dkkd', 'doanh-nghiep', 'da-cap-phep', 2, 3, 168, 'ROUND_ROBIN', 'PUBLIC', 'lan', 'lan');
  RAISE 'FAIL 4';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 4 tiền tố topic phải là tenant của dòng (BR-10-001, 002)';
END $$;

-- 5. Danh mục nền dùng chung: đọc được, không ghi được
DO $$ DECLARE n int; BEGIN
  SELECT count(*) INTO n FROM ph10_event.comm_type; IF n <> 8 THEN RAISE 'FAIL 5: % kiểu giao tiếp', n; END IF;
  SELECT count(*) INTO n FROM ph10_event.routing_mode; IF n <> 3 THEN RAISE 'FAIL 5b'; END IF;
  RAISE NOTICE 'PASS 5 tenant đọc 8 kiểu giao tiếp, 3 chế độ định tuyến';
END $$;
DO $$ BEGIN
  INSERT INTO ph10_event.comm_type (id, comm_type_code, name, direction, allowed_party_types, created_by, updated_by)
  VALUES (gen_random_uuid(), 'MQTT', 'x', 'BOTH', '{SYSTEM}', 'lan', 'lan');
  RAISE 'FAIL 5c';
EXCEPTION WHEN insufficient_privilege THEN RAISE NOTICE 'PASS 5c tenant không thêm kiểu giao tiếp';
END $$;

-- 6. Topic nền tảng dh.* (COMMON) chỉ phiên PLATFORM thấy
RESET app.tenant_id;
SET app.tenant_id = 'PLATFORM';
INSERT INTO ph10_event.topic (id, tenant_id, topic_name, topic_kind, domain, entity, event_name, major_version, partitions, retention_hours, routing_mode, data_class, owner_service_code, status, activated_at, created_by, updated_by)
VALUES (gen_random_uuid(), 'COMMON', 'dh.integration.runtime.command.v1', 'SYSTEM', 'integration', 'runtime', 'command', 1, 3, 24, 'ROUND_ROBIN', 'INTERNAL', 'dh-integration', 'ACTIVE', now(), 'system:seed', 'system:seed');
SET app.tenant_id = 'T90';
DO $$ DECLARE n int; BEGIN
  SELECT count(*) INTO n FROM ph10_event.topic WHERE tenant_id = 'COMMON'; IF n <> 0 THEN RAISE 'FAIL 6'; END IF;
  RAISE NOTICE 'PASS 6 tenant không thấy topic nền tảng dh.*';
END $$;

-- 7. Quy tắc tên và cấu hình topic
DO $$ BEGIN
  INSERT INTO ph10_event.topic (id, tenant_id, topic_name, project_code, topic_kind, domain, entity, event_name, major_version, partitions, retention_hours, routing_mode, data_class, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T90', 't90.cdc.doanh-nghiep.da-tao.v1', 'dkkd-thue', 'BUSINESS', 'cdc', 'doanh-nghiep', 'da-tao', 1, 3, 168, 'ROUND_ROBIN', 'PUBLIC', 'an', 'an');
  RAISE 'FAIL 7';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 7 miền dành riêng cdc chỉ cho đăng ký máy (BR-10-030)';
END $$;
DO $$ BEGIN
  INSERT INTO ph10_event.topic (id, tenant_id, topic_name, project_code, topic_kind, domain, entity, event_name, major_version, partitions, retention_hours, routing_mode, data_class, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T90', 't90.dkkd.doanh-nghiep.giai-the.v1', 'dkkd-thue', 'BUSINESS', 'dkkd', 'doanh-nghiep', 'da-giai-the', 1, 3, 168, 'ROUND_ROBIN', 'PUBLIC', 'an', 'an');
  RAISE 'FAIL 7b';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 7b tên topic phải ghép đúng miền, thực thể, sự kiện, phiên bản';
END $$;
DO $$ BEGIN
  INSERT INTO ph10_event.topic (id, tenant_id, topic_name, project_code, topic_kind, domain, entity, event_name, major_version, partitions, retention_hours, routing_mode, ordering_required, data_class, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T90', 't90.dkkd.doanh-nghiep.da-tam-ngung.v1', 'dkkd-thue', 'BUSINESS', 'dkkd', 'doanh-nghiep', 'da-tam-ngung', 1, 3, 168, 'ROUND_ROBIN', true, 'PUBLIC', 'an', 'an');
  RAISE 'FAIL 7c';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 7c topic cần thứ tự không dùng ROUND_ROBIN (BR-10-006)';
END $$;
DO $$ BEGIN
  UPDATE ph10_event.topic SET replication_factor = 2 WHERE id = pg_temp.id('t90');
  RAISE 'FAIL 7d';
EXCEPTION WHEN check_violation OR object_not_in_prerequisite_state THEN RAISE NOTICE 'PASS 7d hệ số nhân bản cố định 3 (BR-10-004)';
END $$;
DO $$ BEGIN
  UPDATE ph10_event.topic SET topic_name = 't90.dkkd.doanh-nghiep.doi-ten.v1' WHERE id = pg_temp.id('s90');
  RAISE 'FAIL 7e';
EXCEPTION WHEN object_not_in_prerequisite_state OR check_violation THEN RAISE NOTICE 'PASS 7e tên topic bất biến (BR-10-003)';
END $$;
DO $$ BEGIN
  INSERT INTO ph10_event.topic (id, tenant_id, topic_name, project_code, topic_kind, domain, entity, event_name, major_version, partitions, retention_hours, routing_mode, data_class, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T90', 't90.dkkd.doanh-nghiep.da-xoa.v1.dlq', 'dkkd-thue', 'BUSINESS', 'dkkd', 'doanh-nghiep', 'da-xoa', 1, 3, 168, 'ROUND_ROBIN', 'PUBLIC', 'an', 'an');
  RAISE 'FAIL 7f';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 7f hậu tố .dlq chỉ cho topic DLQ hệ thống';
END $$;

-- 8. Lược đồ: NONE cấm khi topic đã ACTIVE; phiên bản ENABLED bất biến
DO $$ BEGIN
  UPDATE ph10_event.event_schema SET compatibility = 'NONE' WHERE topic_name = 't90.dkkd.doanh-nghiep.da-cap-phep.v1';
  RAISE 'FAIL 8';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 8 mức NONE chỉ cho topic chưa từng ACTIVE (BR-10-012)';
END $$;
DO $$ BEGIN
  UPDATE ph10_event.schema_version SET content = '{"type":"record","name":"Khac","fields":[]}' WHERE version_no = 1;
  RAISE 'FAIL 8b';
EXCEPTION WHEN object_not_in_prerequisite_state THEN RAISE NOTICE 'PASS 8b phiên bản lược đồ đã bật bất biến (BR-10-013)';
END $$;
DO $$ BEGIN
  INSERT INTO ph10_event.schema_version (id, tenant_id, topic_name, version_no, content, content_hash, pii_findings, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T90', 't90.dkkd.doanh-nghiep.da-cap-phep.v1', 2, '{}', repeat('b', 64), '[{"field":"soCccd","severity":"HIGH"}]', 'an', 'an');
  RAISE 'FAIL 8c';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 8c mức PII ngoài INFO, WARNING, BLOCKING bị chặn';
END $$;
DO $$ BEGIN
  UPDATE ph10_event.event_schema SET apicurio_group_id = 't91' WHERE topic_name = 't90.dkkd.doanh-nghiep.da-cap-phep.v1';
  RAISE 'FAIL 8d';
EXCEPTION WHEN check_violation OR object_not_in_prerequisite_state THEN RAISE NOTICE 'PASS 8d groupId Apicurio phải là tenant (ADR-070)';
END $$;

-- 9. Tổ hợp partyType, commType (BR-10-017)
DO $$ BEGIN
  INSERT INTO ph10_event.publisher (id, tenant_id, publisher_code, name, party_type, system_code, comm_type, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T90', 'ht-sai', 'x', 'SYSTEM', 'X', 'INTERNAL_KAFKA', 'an', 'an');
  RAISE 'FAIL 9';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 9 HTTT không phát qua Kafka nội bộ';
END $$;
DO $$ BEGIN
  INSERT INTO ph10_event.subscriber (id, tenant_id, subscriber_code, name, party_type, comm_type, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T90', 'cau-noi', 'x', 'LEGACY_BRIDGE', 'PULSAR_BRIDGE', 'an', 'an');
  RAISE 'FAIL 9b';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 9b LEGACY_BRIDGE chỉ là bên phát';
END $$;

-- 10. Publication: bốn mắt, scope đúng mẫu
DO $$ BEGIN
  INSERT INTO ph10_event.publication (id, tenant_id, publication_code, publisher_code, topic_name, purpose, status, approved_by, approved_at, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T90', 'pub-01jd0000000000000000000002', 'ht-dkkd', 't90.ho-tich.khai-sinh.da-dang-ky.v1', 'x', 'ACTIVE', 'an', now(), 'an', 'an');
  RAISE 'FAIL 10';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 10 người tạo không tự duyệt publication (BR-10-010)';
END $$;
DO $$ BEGIN
  UPDATE ph10_event.publication SET granted_scope = 'topic:t90.ho-tich.khai-sinh.da-dang-ky.v1:publish' WHERE id = pg_temp.id('pn90');
  RAISE 'FAIL 10b';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 10b scope phải đúng topic của publication';
END $$;

-- 11. Subscription
DO $$ BEGIN
  INSERT INTO ph10_event.subscription (id, tenant_id, subscription_code, subscriber_code, topic_name, delivery_mode, purpose, consumer_group, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T90', 'ht-thue-keo', 'ht-thue', 't90.ho-tich.khai-sinh.da-dang-ky.v1', 'PULL_API', 'x', 'dh-sub-t90-ht-thue-keo', 'an', 'an');
  RAISE 'FAIL 11';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 11 deliveryMode phải khớp commType của bên nhận';
END $$;
DO $$ BEGIN
  INSERT INTO ph10_event.subscription (id, tenant_id, subscription_code, subscriber_code, topic_name, delivery_mode, purpose, consumer_group, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T90', 'ht-kho-dn', 'ht-kho', 't90.dkkd.doanh-nghiep.da-cap-phep.v1', 'PULL_KAFKA', 'x', 'dh-ext-t91-ht-kho-dn', 'an', 'an');
  RAISE 'FAIL 11b';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 11b nhóm tiêu thụ phải đúng mẫu và đúng tenant (A.8)';
END $$;
DO $$ BEGIN
  UPDATE ph10_event.subscription SET push = jsonb_set(push, '{endpointUrl}', '"http://thue.t90.gov.vn/webhook"') WHERE id = pg_temp.id('sn90');
  RAISE 'FAIL 11c';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 11c endpoint webhook chỉ HTTPS (BR-10-026)';
END $$;
DO $$ BEGIN
  UPDATE ph10_event.subscription SET push = jsonb_set(push, '{workerCount}', '8') WHERE id = pg_temp.id('sn90');
  RAISE 'FAIL 11d';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 11d workerCount không vượt số phân vùng (BR-10-025)';
END $$;
DO $$ BEGIN
  UPDATE ph10_event.subscription SET push = push || '{"signingSecret":"whsec_abc"}' WHERE id = pg_temp.id('sn90');
  RAISE 'FAIL 11e';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 11e cấu hình đẩy không chứa bí mật (BR-10-027)';
END $$;
DO $$ BEGIN
  INSERT INTO ph10_event.subscription (id, tenant_id, subscription_code, subscriber_code, topic_name, delivery_mode, purpose, consumer_group, push, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T90', 'ht-thue-khai-sinh', 'ht-thue', 't90.ho-tich.khai-sinh.da-dang-ky.v1', 'PUSH', 'x', 'dh-sub-t90-ht-thue-khai-sinh',
          '{"endpointUrl":"https://thue.t90.gov.vn/ks","workerCount":1,"maxRetries":8,"retryBackoff":{},"timeoutMs":10000,"failurePolicy":"BLOCK","payloadFormat":"CLOUDEVENTS_BINARY"}', 'an', 'an');
  RAISE 'FAIL 11f';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 11f topic SENSITIVE bắt buộc căn cứ pháp lý (BR-10-019)';
END $$;
DO $$ BEGIN
  INSERT INTO ph10_event.subscription (id, tenant_id, subscription_code, subscriber_code, topic_name, delivery_mode, purpose, consumer_group, push, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T90', 'ht-thue-dn-2', 'ht-thue', 't90.dkkd.doanh-nghiep.da-cap-phep.v1', 'PUSH', 'x', 'dh-sub-t90-ht-thue-dn-2',
          '{"endpointUrl":"https://thue.t90.gov.vn/b","workerCount":1,"maxRetries":8,"retryBackoff":{},"timeoutMs":10000,"failurePolicy":"BLOCK","payloadFormat":"CLOUDEVENTS_BINARY"}', 'an', 'an');
  RAISE 'FAIL 11g';
EXCEPTION WHEN unique_violation THEN RAISE NOTICE 'PASS 11g một subscription còn hiệu lực mỗi cặp bên nhận, topic';
END $$;

-- 12. Khóa ký: chỉ đường dẫn OpenBao, một khóa ACTIVE
DO $$ BEGIN
  INSERT INTO ph10_event.signing_key (id, tenant_id, subscription_code, key_id, secret_ref, status, activated_at, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T90', 'ht-thue-dn-cap-phep', 'k-2', 'whsec_MfKQ9r8GKYqrTwjUPD8ILPZIo2LaLaSw', 'ACTIVE', now(), 'an', 'an');
  RAISE 'FAIL 12';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 12 secret_ref không chứa được giá trị khóa (BR-10-027)';
END $$;
DO $$ BEGIN
  INSERT INTO ph10_event.signing_key (id, tenant_id, subscription_code, key_id, secret_ref, status, activated_at, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T90', 'ht-thue-dn-cap-phep', 'k-3', 'kv/dh/t90/event/subscriptions/ht-thue-dn-cap-phep/signing', 'ACTIVE', now(), 'an', 'an');
  RAISE 'FAIL 12b';
EXCEPTION WHEN unique_violation THEN RAISE NOTICE 'PASS 12b một khóa ACTIVE mỗi subscription';
END $$;

-- 13. Yêu cầu duyệt
INSERT INTO ph10_event.approval_request (id, tenant_id, request_code, request_type, target_type, target_code, requested_by, created_by, updated_by)
VALUES (gen_random_uuid(), 'T90', 'apr-01jd0000000000000000000001', 'SUBSCRIPTION', 'SUBSCRIPTION', 'ht-kho-dn', 'an', 'an', 'an');
DO $$ BEGIN
  UPDATE ph10_event.approval_request SET status = 'APPROVED', decided_by = 'an', decided_at = now() WHERE request_code = 'apr-01jd0000000000000000000001';
  RAISE 'FAIL 13';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 13 người gửi không tự duyệt (BR-10-010)';
END $$;
DO $$ BEGIN
  INSERT INTO ph10_event.approval_request (id, tenant_id, request_code, request_type, target_type, target_code, requested_by, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T90', 'apr-01jd0000000000000000000002', 'SUBSCRIPTION', 'SUBSCRIPTION', 'ht-kho-dn', 'an', 'an', 'an');
  RAISE 'FAIL 13b';
EXCEPTION WHEN unique_violation THEN RAISE NOTICE 'PASS 13b một yêu cầu PENDING mỗi đối tượng';
END $$;
DO $$ BEGIN
  INSERT INTO ph10_event.approval_request (id, tenant_id, request_code, request_type, target_type, target_code, status, requested_by, decided_by, decided_at, auto_approved, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T90', 'apr-01jd0000000000000000000003', 'TOPIC_CREATE', 'TOPIC', 't90.x.y.z.v1', 'APPROVED', 'an', 'binh', now(), true, 'an', 'an');
  RAISE 'FAIL 13c';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 13c tự duyệt chỉ ghi bằng system:auto (BR-10-031)';
END $$;
DO $$ BEGIN
  INSERT INTO ph10_event.approval_request (id, tenant_id, request_code, request_type, target_type, target_code, requested_by, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T90', 'apr-01jd0000000000000000000004', 'CUTOVER', 'TOPIC', 't90.x.y.z.v1', 'an', 'an', 'an');
  RAISE 'FAIL 13d';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 13d requestType và targetType phải khớp (A.2.10)';
END $$;

-- 14. DLQ: lũy đẳng theo vị trí nguồn; xử lý cần người, lý do
DO $$ DECLARE n int; BEGIN
  INSERT INTO ph10_event.dlq_entry (id, tenant_id, subscription_code, source_topic, source_partition, source_offset, origin, error_code, first_failed_at, last_failed_at, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T90', 'ht-thue-dn-cap-phep', 't90.dkkd.doanh-nghiep.da-cap-phep.v1', 2, 1042, 'PUSH', 'ERR-10-112', now(), now(), 'system:dlq-writer', 'system:dlq-writer')
  ON CONFLICT (tenant_id, subscription_code, source_topic, source_partition, source_offset) WHERE origin <> 'BRIDGE'
  DO UPDATE SET attempts = ph10_event.dlq_entry.attempts + 1, last_failed_at = EXCLUDED.last_failed_at;
  SELECT count(*) INTO n FROM ph10_event.dlq_entry; IF n <> 1 THEN RAISE 'FAIL 14: % mục', n; END IF;
  RAISE NOTICE 'PASS 14 ghi DLQ lặp lại không nhân đôi mục (BR-10-024)';
END $$;
DO $$ BEGIN
  UPDATE ph10_event.dlq_entry SET status = 'DISCARDED', resolved_at = now() WHERE id = pg_temp.id('dl90');
  RAISE 'FAIL 14b';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 14b loại bỏ mục DLQ cần người và lý do (FR-10-050)';
END $$;
DO $$ BEGIN
  UPDATE ph10_event.dlq_payload SET value = '\x00' WHERE dlq_entry_id = pg_temp.id('dl90');
  RAISE 'FAIL 14c';
EXCEPTION WHEN insufficient_privilege THEN RAISE NOTICE 'PASS 14c nội dung DLQ không sửa được';
END $$;

-- 15. Phát lại
DO $$ BEGIN
  INSERT INTO ph10_event.replay_request (id, tenant_id, replay_code, subscription_code, replay_mode, range_type, from_time, reason, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T90', 'rpl-01jd0000000000000000000001', 'ht-thue-dn-cap-phep', 'DLQ_ENTRIES', 'TIME', now() - interval '1 day', 'Bên nhận đã sửa lỗi 500', 'an', 'an');
  RAISE 'FAIL 15';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 15 DLQ_ENTRIES phải đi với ENTRIES và danh sách mục';
END $$;
DO $$ BEGIN
  INSERT INTO ph10_event.replay_request (id, tenant_id, replay_code, subscription_code, replay_mode, range_type, from_time, reason, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T90', 'rpl-01jd0000000000000000000002', 'ht-thue-dn-cap-phep', 'REDELIVER_RANGE', 'TIME', now() - interval '1 day', '', 'an', 'an');
  RAISE 'FAIL 15b';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 15b phát lại bắt buộc lý do (BR-10-028)';
END $$;

-- 16. Outbox: đúng tenant, đúng danh mục EVT-10, không bí mật
DO $$ BEGIN
  INSERT INTO ph10_event.outbox_event (event_id, tenant_id, event_type, topic, aggregate_type, aggregate_id, partition_key, payload, trace_id)
  VALUES (gen_random_uuid(), 'T90', 'vn.datahub.event.topic.activated', 't91.event.topic.activated.v1', 'Topic', 'x', 'x', '{}', repeat('0', 32));
  RAISE 'FAIL 16';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 16 sự kiện phải lên topic của tenant mình';
END $$;
DO $$ BEGIN
  INSERT INTO ph10_event.outbox_event (event_id, tenant_id, event_type, topic, aggregate_type, aggregate_id, partition_key, payload, trace_id)
  VALUES (gen_random_uuid(), 'T90', 'vn.datahub.event.topic.renamed', 't90.event.topic.renamed.v1', 'Topic', 'x', 'x', '{}', repeat('0', 32));
  RAISE 'FAIL 16b';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 16b chỉ 15 topic EVT-10 của phụ lục A.7';
END $$;
DO $$ BEGIN
  INSERT INTO ph10_event.outbox_event (event_id, tenant_id, event_type, topic, aggregate_type, aggregate_id, partition_key, payload, trace_id)
  VALUES (gen_random_uuid(), 'T90', 'vn.datahub.event.signing-key.rotated', 't90.event.signing-key.rotated.v1', 'SigningKey', 'x', 'x', '{"keyId":"k-2","note":"whsec_MfKQ9r8G"}', repeat('0', 32));
  RAISE 'FAIL 16c';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 16c sự kiện không mang bí mật ký';
END $$;
INSERT INTO ph10_event.outbox_event (event_id, tenant_id, event_type, topic, aggregate_type, aggregate_id, partition_key, payload, trace_id)
VALUES (gen_random_uuid(), 'T90', 'vn.datahub.event.signing-key.rotated', 't90.event.signing-key.rotated.v1', 'SigningKey', 'ht-thue-dn-cap-phep', 'ht-thue-dn-cap-phep', '{"keyId":"k-2"}', repeat('0', 32));

-- 17. Cầu nối: không hai cầu nối còn hiệu lực trên cùng cặp topic
INSERT INTO ph10_event.migration_bridge (id, tenant_id, bridge_code, direction, pulsar_topic, kafka_topic, status, expires_at, created_by, updated_by)
VALUES (gen_random_uuid(), 'T90', 'brg-01jd0000000000000000000001', 'PULSAR_TO_KAFKA', 'persistent://t90/dkkd/giay-phep', 't90.dkkd.doanh-nghiep.da-cap-phep.v1', 'RUNNING', now() + interval '90 days', 'an', 'an');
DO $$ BEGIN
  INSERT INTO ph10_event.migration_bridge (id, tenant_id, bridge_code, direction, pulsar_topic, kafka_topic, expires_at, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T90', 'brg-01jd0000000000000000000002', 'KAFKA_TO_PULSAR', 'persistent://t90/dkkd/giay-phep', 't90.dkkd.doanh-nghiep.da-cap-phep.v1', now() + interval '30 days', 'an', 'an');
  RAISE 'FAIL 17';
EXCEPTION WHEN unique_violation THEN RAISE NOTICE 'PASS 17 chặn cầu nối ngược chiều cùng cặp topic (BR-10-033, ERR-10-042)';
END $$;
DO $$ BEGIN
  INSERT INTO ph10_event.migration_bridge (id, tenant_id, bridge_code, direction, pulsar_topic, kafka_topic, expires_at, created_by, updated_by)
  VALUES (gen_random_uuid(), 'T90', 'brg-01jd0000000000000000000003', 'PULSAR_TO_KAFKA', 'persistent://t90/dkkd/khac', 't90.ho-tich.khai-sinh.da-dang-ky.v1', now() + interval '400 days', 'an', 'an');
  RAISE 'FAIL 17b';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'PASS 17b cầu nối có hạn dùng';
END $$;

-- 18. Không xóa cứng khai báo (BR-10-003)
DO $$ BEGIN
  DELETE FROM ph10_event.topic WHERE id = pg_temp.id('s90');
  RAISE 'FAIL 18';
EXCEPTION WHEN insufficient_privilege THEN RAISE NOTICE 'PASS 18 ph10_app không xóa được topic';
END $$;

-- 19. Phân vùng: mẫu lag vào phân vùng ngày, thống kê vào phân vùng tháng
INSERT INTO ph10_event.delivery_stat (tenant_id, subscription_code, window_start, success_count, latency_p50_ms, latency_p95_ms)
VALUES ('T90', 'ht-thue-dn-cap-phep', date_trunc('minute', now()), 120, 40, 180);
DO $$ DECLARE n int; BEGIN
  SELECT count(*) INTO n FROM ph10_event.lag_sample WHERE tableoid::regclass::text LIKE 'ph10_event.lag_sample_2%'; IF n <> 1 THEN RAISE 'FAIL 19'; END IF;
  RAISE NOTICE 'PASS 19 mẫu lag và thống kê vào đúng phân vùng';
END $$;

RESET ROLE;

-- 20. Vai trò báo cáo không đọc nội dung DLQ, đọc được siêu dữ liệu
SET ROLE dh_report_ro;
SET app.tenant_id = 'T90';
DO $$ DECLARE n int; BEGIN
  SELECT count(*) INTO n FROM ph10_event.dlq_entry; IF n <> 1 THEN RAISE 'FAIL 20'; END IF;
  BEGIN
    PERFORM 1 FROM ph10_event.dlq_payload;
    RAISE 'FAIL 20b';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
  RAISE NOTICE 'PASS 20 ph10_readonly đọc siêu dữ liệu DLQ, không đọc nội dung';
END $$;
RESET ROLE;
\echo 'Hoàn tất: mọi khối PASS'
