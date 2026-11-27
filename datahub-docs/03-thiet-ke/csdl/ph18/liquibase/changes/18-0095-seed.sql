--liquibase formatted sql
-- Nguồn: ddl/ph18_ops.sql · 18-0095-seed.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph18:ph18-0950-seed-common splitStatements:false context:seed
-- Dữ liệu nền tảng (tenant COMMON): không gian tên, lược đồ khóa 18.*, nguồn DLQ, đối tượng sao lưu D03-09 §8.2, lịch quốc gia mặc định.
SET app.tenant_id = 'COMMON';
INSERT INTO ph18_ops.param_namespace (id, tenant_id, code, owner_module, title, approval_owner, created_by, updated_by)
SELECT md5('ph18-ns:' || s.c)::uuid, 'COMMON', s.c, s.m, s.t, s.a, 'system:seed', 'system:seed' FROM (VALUES
  ('00', 'PH00', 'Tham số chung nền tảng', 'PH18'),
  ('onboarding', 'PH01', 'Kết nạp HTTT', 'PH18'),
  ('02', 'PH02', 'Danh mục dịch vụ', 'PH18'),
  ('04', 'PH04', 'Tích hợp', 'PH18'),
  ('05', 'PH05', 'Bộ điều hợp', 'PH18'),
  ('06', 'PH06', 'Dữ liệu chủ', 'PH18'),
  ('07.rdm', 'PH07', 'Danh mục dùng chung', 'PH18'),
  ('08', 'PH08', 'Chất lượng dữ liệu', 'PH18'),
  ('09', 'PH09', 'Quyền riêng tư', 'PH18'),
  ('10', 'PH10', 'Sự kiện', 'PH18'),
  ('11', 'PH11', 'Quy trình', 'PH18'),
  ('12', 'PH12', 'Định danh và phân quyền', 'PH18'),
  ('13', 'PH13', 'Giám sát và kiểm toán', 'PH18'),
  ('14', 'PH14', 'Kết nối quốc gia', 'PH14'),
  ('15', 'PH15', 'Cổng nhà phát triển', 'PH18'),
  ('16', 'PH16', 'Báo cáo chỉ tiêu', 'PH18'),
  ('17', 'PH17', 'Trợ lý AI', 'PH17'),
  ('18', 'PH18', 'Vận hành và xử lý lỗi', 'PH18'),
  ('20', 'PH20', 'Quản trị tenant', 'PH18'),
  ('ff', 'PH18', 'Cờ tính năng', 'PH18')
) AS s(c, m, t, a)
ON CONFLICT (tenant_id, code) DO NOTHING;
INSERT INTO ph18_ops.param_definition (id, tenant_id, namespace_code, param_key, value_type, default_value, min_value, max_value, unit, level, security_flag, display_group, display_order, label, created_by, updated_by)
SELECT md5('ph18-def:' || s.k)::uuid, 'COMMON', '18', s.k, s.t, s.d::jsonb, s.lo, s.hi, s.u, s.l, s.f, s.g, s.o, s.lab, 'system:seed', 'system:seed' FROM (VALUES
  ('18.param.cache-seconds', 'INTEGER', '60', 1, 60, 's', 'PLATFORM', false, 'param', 10, 'Thời gian đệm tham số ở PH đọc'),
  ('18.param.change-request-ttl-hours', 'INTEGER', '72', 1, 720, 'h', 'TENANT', false, 'param', 20, 'Hạn đề nghị đổi tham số chờ duyệt'),
  ('18.param.history-retention-years', 'INTEGER', '5', 1, 10, 'y', 'PLATFORM', false, 'param', 30, 'Thời gian giữ lịch sử tham số'),
  ('18.dlq.payload.inline-max-kb', 'INTEGER', '256', 16, 256, 'KB', 'PLATFORM', false, 'dlq', 40, 'Ngưỡng payload giữ trong CSDL'),
  ('18.dlq.dedup-window-days', 'INTEGER', '30', 1, 90, 'd', 'PLATFORM', false, 'dlq', 50, 'Cửa sổ khử trùng dlqKey'),
  ('18.dlq.retention.closed-days', 'INTEGER', '90', 30, 365, 'd', 'TENANT', true, 'dlq', 60, 'Thời gian giữ mục DLQ đã đóng'),
  ('18.dlq.retention.metadata-days', 'INTEGER', '365', 90, 1825, 'd', 'TENANT', false, 'dlq', 70, 'Thời gian giữ siêu dữ liệu mục hết hạn'),
  ('18.dlq.audit.retention-months', 'INTEGER', '60', 60, 120, 'month', 'PLATFORM', false, 'dlq', 80, 'Thời gian giữ nhật ký thao tác DLQ'),
  ('18.dlq.replay.batch-max', 'INTEGER', '1000', 1, 10000, 'item', 'TENANT', false, 'dlq', 90, 'Số mục tối đa một lượt phát lại'),
  ('18.dlq.replay.approval-threshold', 'INTEGER', '100', 1, 10000, 'item', 'TENANT', true, 'dlq', 100, 'Ngưỡng phát lại cần bốn mắt'),
  ('18.dlq.replay.rate-per-minute', 'INTEGER', '60', 1, 6000, 'item/min', 'TENANT', false, 'dlq', 110, 'Tốc độ phát lại mặc định'),
  ('18.dlq.threshold.open-count', 'INTEGER', '50', 1, 100000, 'item', 'TENANT', false, 'dlq', 120, 'Ngưỡng mục mở phát sự kiện vượt ngưỡng'),
  ('18.dlq.discard.reason-min-chars', 'INTEGER', '10', 10, 200, 'char', 'PLATFORM', false, 'dlq', 130, 'Độ dài tối thiểu lý do bỏ qua'),
  ('18.notify.delivery-retention-days', 'INTEGER', '180', 30, 730, 'd', 'TENANT', false, 'notify', 140, 'Thời gian giữ nhật ký gửi'),
  ('18.notify.retry.max-attempts', 'INTEGER', '5', 1, 20, 'lần', 'PLATFORM', false, 'notify', 150, 'Số lần thử gửi tối đa'),
  ('18.notify.quiet-hours', 'TIME_RANGE', '"22:00-06:00"', NULL::numeric, NULL::numeric, NULL::text, 'TENANT', false, 'notify', 160, 'Giờ yên lặng mặc định'),
  ('18.notify.sms.enabled', 'BOOLEAN', 'false', NULL::numeric, NULL::numeric, NULL::text, 'TENANT', false, 'notify', 170, 'Bật kênh SMS'),
  ('18.task.retention-days', 'INTEGER', '365', 90, 1825, 'd', 'TENANT', false, 'task', 180, 'Thời gian giữ việc đã đóng'),
  ('18.task.reminder-before-hours', 'INTEGER', '24', 1, 168, 'h', 'TENANT', false, 'task', 190, 'Nhắc trước hạn'),
  ('18.calendar.timezone', 'STRING', '"Asia/Ho_Chi_Minh"', NULL::numeric, NULL::numeric, NULL::text, 'PLATFORM', false, 'calendar', 200, 'Múi giờ lịch'),
  ('18.calendar.working-days', 'LIST_STRING', '["MON", "TUE", "WED", "THU", "FRI"]', NULL::numeric, NULL::numeric, NULL::text, 'TENANT', false, 'calendar', 210, 'Ngày làm việc trong tuần'),
  ('18.incident.retention-years', 'INTEGER', '5', 3, 10, 'y', 'PLATFORM', false, 'incident', 220, 'Thời gian giữ hồ sơ sự cố'),
  ('18.backup.verification-interval-days', 'INTEGER', '1', 1, 90, 'd', 'PLATFORM', false, 'backup', 230, 'Chu kỳ kiểm tra khôi phục'),
  ('18.restore.target-hours', 'INTEGER', '4', 1, 24, 'h', 'PLATFORM', false, 'backup', 240, 'Mục tiêu thời gian khôi phục tenant'),
  ('18.export.download-ttl-days', 'INTEGER', '7', 1, 30, 'd', 'TENANT', false, 'backup', 250, 'Hạn tải tệp xuất tenant'),
  ('18.migration.shadow.match-threshold-percent', 'DECIMAL', '99.5', 90, 100, '%', 'TENANT', true, 'migration', 260, 'Ngưỡng khớp chạy song song'),
  ('18.migration.shadow.sample-retention-days', 'INTEGER', '90', 7, 365, 'd', 'TENANT', false, 'migration', 270, 'Thời gian giữ mẫu so sánh'),
  ('18.migration.cutover.rollback-minutes', 'INTEGER', '15', 5, 120, 'min', 'PLATFORM', false, 'migration', 280, 'Cửa sổ quay lui sau cắt chuyển'),
  ('18.report.retention-months', 'INTEGER', '24', 12, 120, 'month', 'TENANT', false, 'report', 290, 'Thời gian giữ báo cáo vận hành'),
  ('18.outbox.retention-days', 'INTEGER', '3', 1, 30, 'd', 'PLATFORM', false, 'core', 300, 'Thời gian giữ outbox đã phát')
) AS s(k, t, d, lo, hi, u, l, f, g, o, lab)
ON CONFLICT (tenant_id, param_key) DO NOTHING;
INSERT INTO ph18_ops.dlq_source (id, tenant_id, source_code, source_module, ingest_channel, replay_port, replay_endpoint, payload_viewable, created_by, updated_by)
SELECT md5('ph18-src:' || s.c)::uuid, 'COMMON', s.c, s.m, s.ch, s.p, s.e, s.v, 'system:seed', 'system:seed' FROM (VALUES
  ('PH04-RUNTIME', 'PH04', 'KAFKA', 'PH04_RUNTIME', '/integration/internal/v1/replays', true),
  ('PH10-EVENT', 'PH10', 'FEDERATED', 'PH10_EVENT', '/event/internal/v1/replays', false),
  ('PH01-INBOX', 'PH01', 'API', 'REPLAY_PORT', '/onboarding/internal/v1/replays', true),
  ('PH06-MDM-JOB', 'PH06', 'API', 'REPLAY_PORT', '/mdm/internal/v1/replays', true),
  ('PH08-DQ', 'PH08', 'API', 'REPLAY_PORT', '/dq/internal/v1/replays', true),
  ('PH19-INBOX', 'PH19', 'API', 'REPLAY_PORT', '/payment/internal/v1/replays', true)
) AS s(c, m, ch, p, e, v)
ON CONFLICT (tenant_id, source_code) DO NOTHING;
INSERT INTO ph18_ops.backup_object (id, tenant_id, object_code, name, object_kind, tool, schedule, rpo_minutes, rto_minutes, retention_days, target_location, recovery_tier, verification_interval_days, created_by, updated_by)
SELECT md5('ph18-bk:' || s.c)::uuid, 'COMMON', s.c, s.n, s.k, s.t, s.s, s.rpo, s.rto, s.ret, s.loc, s.tier, s.ver, 'system:seed', 'system:seed' FROM (VALUES
  ('pg-base', 'PostgreSQL mọi cụm, bản sao cơ sở', 'POSTGRES_BASE', 'CNPG_BARMAN', '0 1 * * *', 1440, 240, 35, 'kho-sao-luu-bat-bien/pg', 'TPH-1', 1),
  ('pg-wal', 'PostgreSQL WAL', 'POSTGRES_WAL', 'CNPG_BARMAN', 'lien-tuc-60s', 1, 240, 35, 'kho-sao-luu-bat-bien/pg-wal', 'TPH-1', 7),
  ('pg-tenant-export', 'Xuất logic theo tenant pg-core', 'TENANT_EXPORT', 'DH_TENANT_EXPORT', '0 2 * * *', 1440, 240, 35, 'kho-sao-luu-bat-bien/tenant-export', 'TPH-2', 30),
  ('garage-files', 'Garage, tệp nghiệp vụ', 'OBJECT_STORE', 'RCLONE', '0 * * * *', 60, 480, 35, 'kho-sao-luu-bat-bien/garage', 'TPH-2', 7),
  ('openbao-raft', 'OpenBao Raft snapshot', 'SECRET_STORE', 'OPENBAO_RAFT', '*/15 * * * *', 15, 60, 35, 'site-dr/openbao', 'TPH-0', 1),
  ('unseal-shares', 'Khóa transit niêm phong, mảnh khôi phục', 'OFFLINE_SHARES', 'SHAMIR_OFFLINE', 'khi-tao-va-xoay', NULL::integer, NULL::integer, 0, 'ngoai-tuyen-hai-noi', 'TPH-0', 365),
  ('k8s-resources', 'Tài nguyên Kubernetes', 'K8S_RESOURCES', 'VELERO', '0 3 * * *', 1440, 480, 35, 'kho-sao-luu-bat-bien/velero', 'TPH-1', 90),
  ('k8s-volumes', 'Volume không tự nhân bản', 'VOLUME', 'VELERO_KOPIA', '0 3 * * *', 1440, 480, 35, 'kho-sao-luu-bat-bien/kopia', 'TPH-2', 90),
  ('git-config', 'Kho Git cấu hình', 'GIT', 'GIT_MIRROR', 'theo-commit', 0, 120, 0, 'git-dr', 'TPH-0', 30),
  ('harbor-images', 'Harbor, ảnh và chữ ký', 'REGISTRY', 'HARBOR_REPLICATION', 'theo-phat-hanh', NULL::integer, 240, 0, 'harbor-dr', 'TPH-1', NULL::integer),
  ('clickhouse', 'ClickHouse', 'CLICKHOUSE', 'CLICKHOUSE_BACKUP', '0 4 * * *', 1440, 720, 35, 'kho-sao-luu/clickhouse', 'TPH-3', 30),
  ('audit-worm', 'Nhật ký kiểm toán WORM (PH-13)', 'AUDIT_WORM', 'PH13_WORM', '0 * * * *', 60, NULL::integer, 1825, 'kho-worm/audit', 'TPH-1', 30)
) AS s(c, n, k, t, s, rpo, rto, ret, loc, tier, ver)
ON CONFLICT (tenant_id, object_code) DO NOTHING;
INSERT INTO ph18_ops.work_calendar (id, tenant_id, calendar_code, name, inherit_common, created_by, updated_by)
VALUES (md5('ph18-cal:COMMON')::uuid, 'COMMON', 'DEFAULT', 'Lịch làm việc quốc gia', false, 'system:seed', 'system:seed')
ON CONFLICT (tenant_id, calendar_code) DO NOTHING;
--rollback DELETE FROM ph18_ops.work_calendar WHERE created_by = 'system:seed'; DELETE FROM ph18_ops.backup_object WHERE created_by = 'system:seed'; DELETE FROM ph18_ops.dlq_source WHERE created_by = 'system:seed'; DELETE FROM ph18_ops.param_definition WHERE created_by = 'system:seed'; DELETE FROM ph18_ops.param_namespace WHERE created_by = 'system:seed';

--changeset ph18:ph18-0951-fn-seed-tenant splitStatements:false
-- Khởi tạo tenant (PH-20 platform.tenant.created.v1): lịch DEFAULT kế thừa lịch quốc gia. Tham số dùng mặc định của param_definition, không chép dòng; chạy lại không nhân bản.
CREATE OR REPLACE PROCEDURE ph18_ops.p_seed_tenant(p_tenant text)
  LANGUAGE plpgsql AS $p$
BEGIN
  IF p_tenant !~ '^T[0-9]{2}$' THEN
    RAISE EXCEPTION 'Mã tenant không hợp lệ: %', p_tenant USING ERRCODE = '22023';
  END IF;
  PERFORM set_config('app.tenant_id', p_tenant, true);
  INSERT INTO ph18_ops.work_calendar (id, tenant_id, calendar_code, name, created_by, updated_by)
  VALUES (md5('ph18-cal:' || p_tenant)::uuid, p_tenant, 'DEFAULT', 'Lịch làm việc ' || p_tenant, 'system:seed', 'system:seed')
  ON CONFLICT (tenant_id, calendar_code) DO NOTHING;
END
$p$;
COMMENT ON PROCEDURE ph18_ops.p_seed_tenant(text) IS 'Gọi khi PH-20 khởi tạo tenant: tạo lịch DEFAULT kế thừa COMMON; tham số đọc mặc định từ lược đồ khóa nên không chép.';
--rollback DROP PROCEDURE IF EXISTS ph18_ops.p_seed_tenant(text);
