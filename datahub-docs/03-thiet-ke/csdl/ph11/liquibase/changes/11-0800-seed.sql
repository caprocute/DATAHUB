--liquibase formatted sql
-- Nguồn: ddl/ph11_bpm.sql · 11-0800-seed.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph11:ph11-0800-fn-seed-tenant splitStatements:false
-- Khởi tạo tenant: 36 tham số 11.* mặc định theo FRS 8.2 (đúng khóa, kiểu, đơn vị), lịch làm việc mặc định cho năm hiện tại và năm sau
-- (thứ Hai đến thứ Sáu, 07:30 đến 17:00, nghỉ trưa 11:30 đến 13:30). Ngày nghỉ lễ do TA nhập hoặc nhập từ lịch quốc gia (FR-11-045).
CREATE OR REPLACE PROCEDURE ph11_bpm.p_seed_tenant(p_tenant text)
  LANGUAGE plpgsql AS $p$
DECLARE
  y integer := extract(year FROM now() AT TIME ZONE 'Asia/Ho_Chi_Minh');
BEGIN
  PERFORM set_config('app.tenant_id', p_tenant, true);
  INSERT INTO ph11_bpm.tenant_setting (id, tenant_id, key, value, created_by, updated_by)
  SELECT md5('ph11-setting:' || p_tenant || ':' || s.k)::uuid, p_tenant, s.k, s.v::jsonb, 'system:seed', 'system:seed'
  FROM (VALUES ('11.task.dueSoonHours', '8'), ('11.task.fallbackGroup', '"VAN_HANH_QUY_TRINH"'), ('11.task.bulkMax', '500'),
               ('11.task.attachmentMaxMb', '20'), ('11.delegation.maxDays', '30'), ('11.designer.lockMinutes', '30'),
               ('11.model.maxXmlKb', '2048'), ('11.timer.minSeconds', '60'), ('11.callActivity.maxDepth', '3'),
               ('11.service.defaultTimeoutMinutes', '2880'), ('11.outbox.maxAttempts', '20'), ('11.instance.startRatePerClient', '50'),
               ('11.instance.stuckHours', '72'), ('11.message.bufferMinutes', '60'), ('11.migration.batchSize', '100'),
               ('11.saga.maxRetries', '3'), ('11.saga.retryBackoffSeconds', '300'), ('11.saga.reconcileCron', '"0 0 2 * * *"'),
               ('11.due.scanMinutes', '1'), ('11.due.receiveAfterHoursRule', '"NEXT_WORKING_START"'), ('11.supplement.defaultDays', '15'),
               ('11.supplement.resetDue', 'false'), ('11.bottleneck.minSamples', '30'), ('11.bottleneck.factor', '2.0'),
               ('11.retention.instanceYears', '5'), ('11.retention.sagaYears', '5'), ('11.retention.progressEventYears', '2'),
               ('11.retention.engineHistoryMonths', '12'), ('11.retention.cleanupCron', '"0 0 1 * * *"'), ('11.test.retentionDays', '7'),
               ('11.ai.timeoutSeconds', '10'), ('11.progress.cacheSeconds', '30'), ('11.designer.autosaveSeconds', '30'),
               ('11.task.draftDebounceSeconds', '5'), ('11.task.unmaskSeconds', '60'), ('11.escalation.nextLevelHours', '4')) AS s(k, v)
  ON CONFLICT (tenant_id, key) DO NOTHING;
  INSERT INTO ph11_bpm.business_calendar (id, tenant_id, year, created_by, updated_by)
  SELECT md5('ph11-calendar:' || p_tenant || ':' || yy)::uuid, p_tenant, yy, 'system:seed', 'system:seed'
  FROM generate_series(y, y + 1) AS yy
  ON CONFLICT (tenant_id, year) DO NOTHING;
END
$p$;
COMMENT ON PROCEDURE ph11_bpm.p_seed_tenant(text) IS 'Gọi khi khởi tạo tenant (PH-20): 36 tham số 11.* mặc định theo FRS 8.2, lịch làm việc năm hiện tại và năm sau. Chạy lại không nhân bản.';
--rollback DROP PROCEDURE IF EXISTS ph11_bpm.p_seed_tenant(text);

--changeset ph11:ph11-0810-seed-common-template splitStatements:false
-- Mẫu nền tảng ở tenant COMMON (FR-11-015): duyệt một cấp, một việc người dùng. Ghi bằng phiên PLATFORM.
DO $seed$
DECLARE
  x text := '<?xml version="1.0" encoding="UTF-8"?><definitions xmlns="http://www.omg.org/spec/BPMN/20100524/MODEL" targetNamespace="https://datahub.vn/bpm/template"><process id="DUYET_MOT_CAP" name="Duyệt một cấp" isExecutable="true"><startEvent id="batDau"/><sequenceFlow id="f1" sourceRef="batDau" targetRef="duyet"/><userTask id="duyet" name="Duyệt hồ sơ"/><sequenceFlow id="f2" sourceRef="duyet" targetRef="ketThuc"/><endEvent id="ketThuc"/></process></definitions>';
BEGIN
  PERFORM set_config('app.tenant_id', 'PLATFORM', true);
  INSERT INTO ph11_bpm.process_template (id, tenant_id, template_code, version_no, name, description, group_code, status, source_xml, checksum, created_by, updated_by)
  VALUES (md5('ph11-template:COMMON:DUYET_MOT_CAP:1')::uuid, 'COMMON', 'DUYET_MOT_CAP', 1, 'Duyệt một cấp',
          'Mẫu tối thiểu: một việc duyệt giữa sự kiện bắt đầu và kết thúc; dùng làm điểm xuất phát khi tạo mô hình.', 'DUYET_NOI_BO', 'PUBLISHED',
          x, sha256(convert_to(x, 'UTF8')), 'system:seed', 'system:seed')
  ON CONFLICT (tenant_id, template_code, version_no) DO NOTHING;
END
$seed$;
--rollback DELETE FROM ph11_bpm.process_template WHERE tenant_id = 'COMMON' AND template_code = 'DUYET_MOT_CAP';
