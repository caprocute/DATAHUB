--liquibase formatted sql
-- Nguồn: ddl/ph18_ops.sql · 18-0095-seed.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph18:ph18-0950-seed-common splitStatements:false context:seed
-- Dữ liệu nền tảng (tenant COMMON): không gian tên, lược đồ khóa 18.*, nguồn DLQ, đối tượng sao lưu D03-09 §8.2, lịch quốc gia mặc định.
SET app.tenant_id = 'COMMON';
INSERT INTO ph18_ops.param_namespace (id, tenant_id, code, owner_module, title, approval_owner, created_by, updated_by)
SELECT md5('ph18-ns:' || s.c)::uuid, 'COMMON', s.c, s.m, s.t, s.a, 'system:seed', 'system:seed' FROM (VALUES
  ('00', 'PH-00', 'Tham số chung nền tảng', 'PH-18'),
  ('onboarding', 'PH-01', 'Kết nạp HTTT', 'PH-18'),
  ('02', 'PH-02', 'Danh mục dịch vụ', 'PH-18'),
  ('04', 'PH-04', 'Tích hợp', 'PH-18'),
  ('05', 'PH-05', 'Bộ điều hợp', 'PH-18'),
  ('06', 'PH-06', 'Dữ liệu chủ', 'PH-18'),
  ('07.rdm', 'PH-07', 'Danh mục dùng chung', 'PH-18'),
  ('08', 'PH-08', 'Chất lượng dữ liệu', 'PH-18'),
  ('09', 'PH-09', 'Quyền riêng tư', 'PH-18'),
  ('10', 'PH-10', 'Sự kiện', 'PH-18'),
  ('11', 'PH-11', 'Quy trình', 'PH-18'),
  ('12', 'PH-12', 'Định danh và phân quyền', 'PH-18'),
  ('13', 'PH-13', 'Giám sát và kiểm toán', 'PH-18'),
  ('14', 'PH-14', 'Kết nối quốc gia', 'PH-14'),
  ('15', 'PH-15', 'Cổng nhà phát triển', 'PH-18'),
  ('16', 'PH-16', 'Báo cáo chỉ tiêu', 'PH-18'),
  ('17', 'PH-17', 'Trợ lý AI', 'PH-17'),
  ('18', 'PH-18', 'Vận hành và xử lý lỗi', 'PH-18'),
  ('20', 'PH-20', 'Quản trị tenant', 'PH-18'),
  ('ff', 'PH-18', 'Cờ tính năng', 'PH-18')
) AS s(c, m, t, a)
ON CONFLICT (tenant_id, code) DO NOTHING;
INSERT INTO ph18_ops.param_definition (id, tenant_id, namespace_code, param_key, value_type, default_value, min_value, max_value, unit, level, secure, display_group, display_order, label, allowed_values, created_by, updated_by)
SELECT md5('ph18-def:' || s.k)::uuid, 'COMMON', '18', s.k, s.t, s.d::jsonb, s.lo, s.hi, s.u, s.l, s.f, s.g, s.o, s.lab, s.av::jsonb, 'system:seed', 'system:seed' FROM (VALUES
  ('18.param.cache-ttl-seconds', 'INT', '60', 10, 60, 's', 'PLATFORM', false, 'param', 10, 'Thời hạn bộ đệm tham số phía dh-ops-client', NULL::text),
  ('18.param.reason-min-length', 'INT', '10', 10, 200, NULL::text, 'TENANT', false, 'param', 20, 'Độ dài tối thiểu của lý do đổi tham số', NULL::text),
  ('18.param.history-retention-days', 'INT', '1825', 365, 3650, 'd', 'PLATFORM', false, 'param', 30, 'Thời gian giữ phiên bản tham số', NULL::text),
  ('18.param.change-request-ttl-hours', 'INT', '72', 1, 720, 'h', 'TENANT', false, 'param', 40, 'Đề nghị đổi khóa ★ chưa duyệt quá hạn thì tự hết hiệu lực', NULL::text),
  ('18.ff.retire-warning-days', 'INT', '14', 1, 90, 'd', 'TENANT', false, 'ff', 50, 'Số ngày trước ngày gỡ cờ thì nhắc chủ sở hữu', NULL::text),
  ('18.egress.allowlist', 'LIST<HOST>', '[]', NULL::numeric, NULL::numeric, NULL::text, 'TENANT', false, 'egress', 60, 'Danh sách đích egress cho phép (FR-18-010)', NULL::text),
  ('18.egress.max-entries', 'INT', '200', 1, 1000, 'item', 'PLATFORM', false, 'egress', 70, 'Số mục egress tối đa mỗi tenant', NULL::text),
  ('18.dlq.payload.inline-max-kb', 'INT', '256', 64, 256, 'KB', 'PLATFORM', false, 'dlq', 80, 'Ngưỡng payload lưu nội tuyến, lớn hơn lưu Garage', NULL::text),
  ('18.dlq.payload.max-mb', 'INT', '20', 1, 100, 'MB', 'PLATFORM', false, 'dlq', 90, 'Kích thước payload tối đa nhận vào DLQ', NULL::text),
  ('18.dlq.retention.closed-days', 'INT', '90', 30, 365, 'd', 'TENANT', false, 'dlq', 100, 'Thời gian giữ payload của mục đã đóng', NULL::text),
  ('18.dlq.retention.metadata-days', 'INT', '365', 90, 1825, 'd', 'TENANT', false, 'dlq', 110, 'Thời gian giữ siêu dữ liệu của mục EXPIRED', NULL::text),
  ('18.dlq.audit.retention-months', 'INT', '60', 12, 120, 'month', 'PLATFORM', false, 'dlq', 120, 'Thời gian giữ bản sao nhật ký thao tác DLQ (dlq_audit); bản chính thức ở PH-13', NULL::text),
  ('18.dlq.dedup-window-days', 'INT', '7', 1, 30, 'd', 'PLATFORM', false, 'dlq', 130, 'Cửa sổ khử trùng của inbox tiêu thụ DLQ', NULL::text),
  ('18.dlq.retention.open-max-days', 'INT', '365', 90, 1825, 'd', 'TENANT', false, 'dlq', 140, 'Tuổi mục mở thì nhắc và phát sự kiện AGE', NULL::text),
  ('18.dlq.reveal.ttl-minutes', 'INT', '15', 5, 60, 'min', 'TENANT', true, 'dlq', 150, 'Hạn phiếu xem payload', NULL::text),
  ('18.dlq.replay.batch-max', 'INT', '10000', 100, 50000, 'item', 'TENANT', false, 'dlq', 160, 'Số mục tối đa một lượt phát lại', NULL::text),
  ('18.dlq.replay.approval-threshold', 'INT', '500', 10, 10000, 'item', 'TENANT', true, 'dlq', 170, 'Lượt vượt số mục này cần bốn mắt', NULL::text),
  ('18.dlq.replay.rate-per-second', 'INT', '10', 1, 100, 'item/s', 'TENANT', false, 'dlq', 180, 'Tốc độ phát lại mặc định', NULL::text),
  ('18.dlq.replay.result-timeout-minutes', 'INT', '30', 1, 1440, 'min', 'TENANT', false, 'dlq', 190, 'Thời gian chờ kết quả phát lại', NULL::text),
  ('18.dlq.threshold.depth', 'INT', '1000', 10, 1000000, NULL::text, 'TENANT', false, 'dlq', 200, 'Ngưỡng số mục chưa xử lý để phát EVT-18-08', NULL::text),
  ('18.dlq.threshold.age-hours', 'INT', '24', 1, 720, 'h', 'TENANT', false, 'dlq', 210, 'Ngưỡng tuổi mục cũ nhất chưa xử lý', NULL::text),
  ('18.dlq.threshold.poison-per-hour', 'INT', '10', 1, 10000, 'item/h', 'TENANT', false, 'dlq', 220, 'Ngưỡng số mục POISON mỗi giờ', NULL::text),
  ('18.dlq.threshold.replay-failure-percent', 'INT', '20', 1, 100, '%', 'TENANT', false, 'dlq', 230, 'Tỷ lệ lỗi làm lượt phát lại tự dừng', NULL::text),
  ('18.dlq.group.window-hours', 'INT', '24', 1, 168, 'h', 'TENANT', false, 'dlq', 240, 'Cửa sổ gom nhóm dấu hiệu lỗi', NULL::text),
  ('18.dlq.reconcile.cron', 'CRON', '"0 30 2 * * *"', NULL::numeric, NULL::numeric, NULL::text, 'PLATFORM', false, 'dlq', 250, 'Lịch đối soát chỉ mục với Kafka', NULL::text),
  ('18.dlq.diagnostics.timeout-ms', 'INT', '3000', 500, 5000, 'ms', 'PLATFORM', false, 'dlq', 260, 'Thời gian chờ ngữ cảnh chẩn đoán từ PH-13', NULL::text),
  ('18.notify.quiet-hours', 'STRING', '"22:00-06:00"', NULL::numeric, NULL::numeric, NULL::text, 'TENANT', false, 'notify', 270, 'Giờ yên lặng mặc định của tenant', NULL::text),
  ('18.notify.retry.max-attempts', 'INT', '5', 1, 10, NULL::text, 'PLATFORM', false, 'notify', 280, 'Số lần thử gửi tối đa', NULL::text),
  ('18.notify.retry.window-hours', 'INT', '24', 1, 72, 'h', 'PLATFORM', false, 'notify', 290, 'Khoảng thời gian thử gửi tối đa', NULL::text),
  ('18.notify.sync.timeout-ms', 'INT', '3000', 1000, 10000, 'ms', 'PLATFORM', false, 'notify', 300, 'Thời gian chờ ở chế độ gửi đồng bộ', NULL::text),
  ('18.notify.bounce.soft-limit', 'INT', '3', 1, 10, NULL::text, 'TENANT', false, 'notify', 310, 'Số lần trả lại mềm trong 30 ngày thì chặn', NULL::text),
  ('18.notify.log-retention-days', 'INT', '180', 30, 730, 'd', 'TENANT', false, 'notify', 320, 'Thời gian giữ nhật ký gửi', NULL::text),
  ('18.notify.sms.enabled', 'BOOL', 'false', NULL::numeric, NULL::numeric, NULL::text, 'TENANT', false, 'notify', 330, 'Bật kênh SMS cho tenant', NULL::text),
  ('18.notify.sender-name', 'STRING', '"Datahub {tỉnh}"', NULL::numeric, NULL::numeric, NULL::text, 'TENANT', false, 'notify', 340, 'Tên người gửi hiển thị trên thư', NULL::text),
  ('18.task.reminder.before-hours', 'INT', '24', 1, 168, 'h', 'TENANT', false, 'task', 350, 'Nhắc trước hạn việc', NULL::text),
  ('18.task.overdue.escalate-hours', 'INT', '48', 1, 336, 'h', 'TENANT', false, 'task', 360, 'Quá hạn bao lâu thì leo thang', NULL::text),
  ('18.task.retention-days', 'INT', '365', 30, 1825, 'd', 'TENANT', false, 'task', 370, 'Thời gian giữ việc đã đóng', NULL::text),
  ('18.calendar.weekend-days', 'LIST<STRING>', '["SAT", "SUN"]', NULL::numeric, NULL::numeric, NULL::text, 'TENANT', false, 'calendar', 380, 'Ngày nghỉ cuối tuần', NULL::text),
  ('18.calendar.timezone', 'STRING', '"Asia/Ho_Chi_Minh"', NULL::numeric, NULL::numeric, NULL::text, 'PLATFORM', false, 'calendar', 390, 'Múi giờ tính ngày làm việc', NULL::text),
  ('18.maintenance.notice-hours', 'INT', '72', 1, 336, 'h', 'TENANT', false, 'maintenance', 400, 'Báo trước bảo trì bao nhiêu giờ', NULL::text),
  ('18.freeze.default-envs', 'LIST<STRING>', '["PROD"]', NULL::numeric, NULL::numeric, NULL::text, 'TENANT', false, 'freeze', 410, 'Môi trường mặc định của cửa sổ đóng băng', '["DEV", "TEST", "STAGING", "PROD"]'),
  ('18.incident.sev1-ack-minutes', 'INT', '15', 5, 60, 'min', 'TENANT', false, 'incident', 420, 'Thời hạn nhận sự cố SEV1 trước khi leo thang', NULL::text),
  ('18.incident.sev2-ack-minutes', 'INT', '60', 15, 240, 'min', 'TENANT', false, 'incident', 430, 'Thời hạn nhận sự cố SEV2', NULL::text),
  ('18.incident.retention-years', 'INT', '5', 3, 10, 'y', 'PLATFORM', false, 'incident', 440, 'Thời gian giữ hồ sơ sự cố đã đóng', NULL::text),
  ('18.backup.stale-hours', 'INT', '26', 2, 72, 'h', 'PLATFORM', false, 'backup', 450, 'Bản sao lưu hằng ngày quá số giờ này là trễ', NULL::text),
  ('18.backup.freshness-max-minutes', 'INT', '15', 5, 60, 'min', 'PLATFORM', false, 'backup', 460, 'Độ trễ tối đa của trạng thái thu thập', NULL::text),
  ('18.backup.verification-interval-days', 'INT', '1', 1, 90, 'd', 'PLATFORM', false, 'backup', 470, 'Chu kỳ kiểm tra khôi phục tự động mỗi đối tượng', NULL::text),
  ('18.restore.max-duration-hours', 'INT', '4', 1, 24, 'h', 'PLATFORM', false, 'restore', 480, 'Chỉ tiêu thời gian khôi phục, vượt thì cảnh báo', NULL::text),
  ('18.restore.approval-required', 'BOOL', 'true', NULL::numeric, NULL::numeric, NULL::text, 'PLATFORM', true, 'restore', 490, 'Khôi phục tenant bắt buộc bốn mắt (không tắt được)', '[true]'),
  ('18.export.link-ttl-hours', 'INT', '24', 1, 72, 'h', 'PLATFORM', false, 'export', 500, 'Hạn liên kết tải gói xuất', NULL::text),
  ('18.export.retention-days', 'INT', '30', 7, 90, 'd', 'PLATFORM', false, 'export', 510, 'Thời gian giữ gói xuất', NULL::text),
  ('18.migration.dry-run-valid-days', 'INT', '7', 1, 30, 'd', 'TENANT', false, 'migration', 520, 'Hạn hiệu lực của lần chạy thử', NULL::text),
  ('18.migration.batch-size', 'INT', '500', 50, 5000, NULL::text, 'TENANT', false, 'migration', 530, 'Kích thước lô đọc và nhập', NULL::text),
  ('18.migration.parallel.match-threshold-percent', 'DECIMAL', '99.5', 90, 100, '%', 'TENANT', false, 'migration', 540, 'Ngưỡng tỷ lệ khớp để sang SHADOW_OK', NULL::text),
  ('18.migration.shadow.sample-percent', 'INT', '5', 1, 100, '%', 'TENANT', false, 'migration', 550, 'Tỷ lệ lưu lượng nhân bản', NULL::text),
  ('18.migration.shadow.sample-retention-days', 'INT', '90', 7, 365, 'd', 'TENANT', false, 'migration', 560, 'Thời gian giữ mẫu so sánh chạy bóng (chỉ tổng kiểm tra)', NULL::text),
  ('18.migration.rollback-window-minutes', 'INT', '15', 5, 120, 'min', 'PLATFORM', false, 'migration', 570, 'Cửa sổ quay lui sau cắt chuyển', NULL::text),
  ('18.report.schedule', 'ENUM', '"MONTHLY"', NULL::numeric, NULL::numeric, NULL::text, 'TENANT', false, 'report', 580, 'Kỳ báo cáo vận hành tự động', '["MONTHLY", "QUARTERLY"]'),
  ('18.report.retention-months', 'INT', '24', 12, 120, 'month', 'TENANT', false, 'report', 590, 'Thời gian giữ báo cáo vận hành', NULL::text),
  ('18.degraded.read-only', 'BOOL', 'false', NULL::numeric, NULL::numeric, NULL::text, 'PLATFORM', false, 'degraded', 600, 'Chế độ chỉ đọc của PH-18', NULL::text),
  ('18.outbox.retention-days', 'INT', '3', 1, 30, 'd', 'PLATFORM', false, 'outbox', 610, 'Thời gian giữ bản ghi outbox đã gửi', NULL::text)
) AS s(k, t, d, lo, hi, u, l, f, g, o, lab, av)
ON CONFLICT (tenant_id, param_key) DO NOTHING;
INSERT INTO ph18_ops.dlq_source (id, tenant_id, source_code, source_module, ingest_channel, replay_mode, replay_endpoint, payload_viewable, created_by, updated_by)
SELECT md5('ph18-src:' || s.c)::uuid, 'COMMON', s.c, s.m, s.ch, s.p, s.e, s.v, 'system:seed', 'system:seed' FROM (VALUES
  ('ph04-runtime', 'PH-04', 'KAFKA', 'KAFKA_TOPIC', '/integration/internal/v1/replays', true),
  ('ph10-event', 'PH-10', 'FEDERATED', 'EVENT_LAYER', '/event/internal/v1/replays', false),
  ('ph01-inbox', 'PH-01', 'API', 'HTTP_PORT', '/onboarding/internal/v1/replays', true),
  ('ph06-mdm-job', 'PH-06', 'API', 'HTTP_PORT', '/mdm/internal/v1/replays', true),
  ('ph08-dq', 'PH-08', 'API', 'HTTP_PORT', '/dq/internal/v1/replays', true),
  ('ph19-inbox', 'PH-19', 'API', 'HTTP_PORT', '/payment/internal/v1/replays', true)
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
