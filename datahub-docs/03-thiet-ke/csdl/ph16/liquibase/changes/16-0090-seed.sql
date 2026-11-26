--liquibase formatted sql
-- Nguồn: ddl/ph16_kpi.sql · 16-0090-seed.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph16:ph16-0910-fn-seed-tenant splitStatements:false
-- Khởi tạo tenant: 18 tham số 16.*, năm nhóm chỉ tiêu, bộ tiêu chí tuân thủ tối thiểu và mẫu báo cáo mặc định, sao chép từ COMMON. Chỉ tiêu mẫu do người dùng kế thừa (FR-16-008), không seed.
CREATE OR REPLACE PROCEDURE ph16_kpi.p_seed_tenant(p_tenant text)
  LANGUAGE plpgsql AS $p$
BEGIN
  PERFORM set_config('app.tenant_id', p_tenant, true);
  INSERT INTO ph16_kpi.kpi_tenant_setting (id, tenant_id, param_code, value, created_by, updated_by)
  SELECT md5('ph16-setting:' || p_tenant || ':' || s.k)::uuid, p_tenant, s.k, s.v::jsonb, 'system:seed', 'system:seed'
  FROM (VALUES ('16.period.types', '"MONTH,QUARTER,YEAR"'), ('16.period.close-day', '5'), ('16.aggregate.cron', '"0 30 1 * * *"'), ('16.aggregate.timeout-minutes', '15'), ('16.source.stale-hours', '26'), ('16.source.fail-after', '3'), ('16.late-data.recompute', 'true'), ('16.manual.evidence-required', 'true'), ('16.report.four-eyes', 'true'), ('16.report.signing', 'true'), ('16.report.retention-years', '10'), ('16.observation.retention-months', '36'), ('16.export.link-hours', '24'), ('16.export.max-rows', '100000'), ('16.national.enabled', 'false'), ('16.national.retry-max', '5'), ('16.compare.min-tenants', '3'), ('16.compliance.waiver-max-days', '180')) AS s(k, v)
  ON CONFLICT (tenant_id, param_code) DO NOTHING;
  INSERT INTO ph16_kpi.kpi_indicator_group (id, tenant_id, group_code, name, description, weight, display_order, enabled, created_by, updated_by)
  SELECT md5('ph16-group:' || p_tenant || ':' || g.group_code)::uuid, p_tenant, g.group_code, g.name, g.description, g.weight, g.display_order, g.enabled, 'system:seed', 'system:seed'
  FROM ph16_kpi.kpi_indicator_group g WHERE g.tenant_id = 'COMMON'
  ON CONFLICT (tenant_id, group_code) DO NOTHING;
  INSERT INTO ph16_kpi.kpi_compliance_criterion (id, tenant_id, criterion_code, version_no, name, description, applies_to, mandatory, weight, framework_ref, state, activated_at, created_by, updated_by)
  SELECT md5('ph16-criterion:' || p_tenant || ':' || c.criterion_code || ':' || c.version_no)::uuid, p_tenant, c.criterion_code, c.version_no, c.name, c.description, c.applies_to,
         c.mandatory, c.weight, c.framework_ref, c.state, c.activated_at, 'system:seed', 'system:seed'
  FROM ph16_kpi.kpi_compliance_criterion c WHERE c.tenant_id = 'COMMON' AND c.state = 'ACTIVE'
  ON CONFLICT (tenant_id, criterion_code, version_no) DO NOTHING;
  INSERT INTO ph16_kpi.kpi_report_template (id, tenant_id, template_code, version_no, name, state, sections, formats, layout, description, activated_at, created_by, updated_by)
  SELECT md5('ph16-template:' || p_tenant || ':' || t.template_code || ':' || t.version_no)::uuid, p_tenant, t.template_code, t.version_no, t.name, t.state, t.sections, t.formats, t.layout,
         t.description, t.activated_at, 'system:seed', 'system:seed'
  FROM ph16_kpi.kpi_report_template t WHERE t.tenant_id = 'COMMON' AND t.state = 'ACTIVE'
  ON CONFLICT (tenant_id, template_code, version_no) DO NOTHING;
END
$p$;
COMMENT ON PROCEDURE ph16_kpi.p_seed_tenant(text) IS 'Gọi khi khởi tạo tenant (PH-20): 18 tham số 16.*, 5 nhóm chỉ tiêu, 6 tiêu chí tuân thủ, 1 mẫu báo cáo sao chép từ COMMON. Chạy lại không nhân bản.';
--rollback DROP PROCEDURE IF EXISTS ph16_kpi.p_seed_tenant(text);

--changeset ph16:ph16-0920-fn-seed-common splitStatements:false
-- Bộ chỉ tiêu mẫu toàn quốc (tenant COMMON): 5 nhóm, 24 chỉ tiêu (brief PH-16 mục 5), 6 tiêu chí tuân thủ tối thiểu, 1 mẫu báo cáo. Chạy dưới phiên PLATFORM.
-- Chỉ tiêu mẫu chưa có phiên bản định nghĩa: công thức chờ chốt hợp đồng chỉ số với phân hệ nguồn (Q16-51).
CREATE OR REPLACE PROCEDURE ph16_kpi.p_seed_common()
  LANGUAGE plpgsql AS $p$
BEGIN
  PERFORM set_config('app.tenant_id', 'PLATFORM', true);
  INSERT INTO ph16_kpi.kpi_indicator_group (id, tenant_id, group_code, name, description, weight, display_order, created_by, updated_by)
  SELECT md5('ph16-group:COMMON:' || g.c)::uuid, 'COMMON', g.c, g.n, g.d, 0.2000, g.o, 'system:seed', 'system:seed'
  FROM (VALUES ('KET_NOI', 'Kết nối, tích hợp', 'Mức độ HTTT kết nối, tốc độ kết nạp và xây luồng.', 1), ('CHIA_SE', 'Chia sẻ, khai thác dữ liệu', 'Số API công bố, lượt khai thác, nhật ký, đối soát.', 2), ('DU_LIEU', 'Chất lượng, danh mục dữ liệu', 'Điểm chất lượng, quản lý danh mục tập trung.', 3), ('VAN_HANH', 'Vận hành, an toàn', 'Sẵn sàng, độ trễ, sự cố, hồ sơ cấp độ, bí mật ngoài kho.', 4), ('KIEN_TRUC', 'Tuân thủ kiến trúc, triển khai', 'Khởi tạo tenant, giao diện quản trị, hài lòng người dùng, thành phần đã đánh giá.', 5)) AS g(c, n, d, o)
  ON CONFLICT (tenant_id, group_code) DO NOTHING;
  INSERT INTO ph16_kpi.kpi_indicator (id, tenant_id, indicator_code, group_code, name, kind, direction, measurement, unit, aggregation, scope, mandatory, brd_ref, display_order, created_by, updated_by)
  SELECT md5('ph16-indicator:COMMON:' || i.c)::uuid, 'COMMON', i.c, i.g, i.n, i.k, i.d, i.m, i.u, i.a, 'COMMON', i.mand, i.brd, i.o, 'system:seed', 'system:seed'
  FROM (VALUES ('httt-ket-noi-ty-le', 'KET_NOI', 'Tỷ lệ HTTT đã kết nối', 'RATIO', 'HIGHER_BETTER', 'AUTO', '%', 'LAST', true, 'KPI-01', 1), ('ket-noi-diem-diem-con-lai', 'KET_NOI', 'Số kết nối điểm-điểm còn lại', 'COUNT', 'LOWER_BETTER', 'MANUAL', 'kết nối', 'LAST', false, 'KPI-02', 2), ('san-sang-data-plane', 'VAN_HANH', 'Độ sẵn sàng của data plane', 'RATIO', 'HIGHER_BETTER', 'AUTO', '%', 'LAST', true, 'KPI-03', 3), ('tre-gateway-p95', 'VAN_HANH', 'Độ trễ cổng p95', 'DURATION', 'LOWER_BETTER', 'AUTO', 'ms', 'P95', true, 'KPI-04', 4), ('thoi-gian-ket-nap-httt', 'KET_NOI', 'Thời gian kết nạp HTTT', 'DURATION', 'LOWER_BETTER', 'AUTO', 'ngày', 'AVG', false, 'KPI-05', 5), ('thoi-gian-xay-luong', 'KET_NOI', 'Thời gian xây luồng', 'DURATION', 'LOWER_BETTER', 'AUTO', 'ngày', 'AVG', false, 'KPI-06', 6), ('nhat-ky-khai-thac-du', 'CHIA_SE', 'Tỷ lệ lượt khai thác có nhật ký đủ', 'RATIO', 'HIGHER_BETTER', 'AUTO', '%', 'LAST', true, 'KPI-07', 7), ('ho-so-cap-do-phe-duyet', 'VAN_HANH', 'Hồ sơ cấp độ ATTT được phê duyệt', 'BOOLEAN', 'HIGHER_BETTER', 'MANUAL', 'đạt/không đạt', 'LAST', false, 'KPI-08', 8), ('bi-mat-ngoai-kho', 'VAN_HANH', 'Số thông tin xác thực nằm ngoài kho bảo mật', 'COUNT', 'LOWER_BETTER', 'MIXED', 'mục', 'LAST', true, 'KPI-09', 9), ('danh-muc-quan-ly-tap-trung', 'DU_LIEU', 'Tỷ lệ danh mục quản lý tập trung', 'RATIO', 'HIGHER_BETTER', 'AUTO', '%', 'LAST', false, 'KPI-10', 10), ('tre-dong-bo-danh-muc-qg', 'DU_LIEU', 'Độ trễ đồng bộ danh mục quốc gia', 'DURATION', 'LOWER_BETTER', 'AUTO', 'giờ', 'AVG', false, 'KPI-11', 11), ('thoi-gian-khoi-tao-tenant', 'KIEN_TRUC', 'Thời gian khởi tạo tenant', 'DURATION', 'LOWER_BETTER', 'AUTO', 'ngày', 'MAX', false, 'KPI-12', 12), ('doi-soat-tu-dong-khop', 'CHIA_SE', 'Tỷ lệ đối soát tự động khớp', 'RATIO', 'HIGHER_BETTER', 'AUTO', '%', 'AVG', false, 'KPI-13', 13), ('thoi-gian-phat-hien-lech', 'CHIA_SE', 'Thời gian phát hiện chênh lệch', 'DURATION', 'LOWER_BETTER', 'AUTO', 'ngày', 'AVG', false, 'KPI-14', 14), ('mttd', 'VAN_HANH', 'Thời gian trung bình phát hiện sự cố', 'DURATION', 'LOWER_BETTER', 'AUTO', 'phút', 'AVG', false, 'KPI-15', 15), ('mttr-muc-1', 'VAN_HANH', 'Thời gian trung bình khắc phục sự cố mức 1', 'DURATION', 'LOWER_BETTER', 'AUTO', 'giờ', 'AVG', false, 'KPI-16', 16), ('so-giao-dien-quan-tri', 'KIEN_TRUC', 'Số giao diện quản trị', 'COUNT', 'TARGET_RANGE', 'MANUAL', 'giao diện', 'LAST', false, 'KPI-17', 17), ('diem-hai-long-sus', 'KIEN_TRUC', 'Điểm hài lòng người dùng (SUS)', 'SCORE', 'HIGHER_BETTER', 'MANUAL', 'điểm', 'LAST', false, 'KPI-18', 18), ('api-cong-bo', 'CHIA_SE', 'Số API đã công bố', 'COUNT', 'HIGHER_BETTER', 'AUTO', 'API', 'LAST', false, NULL::varchar, 19), ('luot-khai-thac-thang', 'CHIA_SE', 'Số lượt khai thác trong kỳ', 'COUNT', 'HIGHER_BETTER', 'AUTO', 'lượt', 'SUM', false, NULL::varchar, 20), ('api-dat-sla-ty-le', 'CHIA_SE', 'Tỷ lệ API đạt cam kết mức dịch vụ', 'RATIO', 'HIGHER_BETTER', 'AUTO', '%', 'AVG', false, NULL::varchar, 21), ('diem-chat-luong-du-lieu', 'DU_LIEU', 'Điểm chất lượng dữ liệu', 'SCORE', 'HIGHER_BETTER', 'AUTO', 'điểm', 'LAST', false, NULL::varchar, 22), ('giao-dich-thanh-toan-truc-tuyen', 'CHIA_SE', 'Số giao dịch thanh toán trực tuyến', 'COUNT', 'HIGHER_BETTER', 'AUTO', 'giao dịch', 'SUM', false, NULL::varchar, 23), ('thanh-phan-da-danh-gia-tuan-thu', 'KIEN_TRUC', 'Tỷ lệ thành phần đã đánh giá tuân thủ', 'RATIO', 'HIGHER_BETTER', 'AUTO', '%', 'LAST', false, NULL::varchar, 24)) AS i(c, g, n, k, d, m, u, a, mand, brd, o)
  ON CONFLICT (tenant_id, indicator_code) DO NOTHING;
  INSERT INTO ph16_kpi.kpi_compliance_criterion (id, tenant_id, criterion_code, version_no, name, description, applies_to, mandatory, weight, state, activated_at, created_by, updated_by)
  SELECT md5('ph16-criterion:COMMON:' || c.c || ':1')::uuid, 'COMMON', c.c, 1, c.n, c.d, c.t::text[], c.m, c.w, 'ACTIVE', now(), 'system:seed', 'system:seed'
  FROM (VALUES ('AR-REG-01', 'Đăng ký đủ mã, tên, loại và vòng đời', 'Thành phần có mã, tên, loại và vòng đời xác định trong sổ kiến trúc.', '{HTTT,API,FLOW,TOPIC,ADAPTER,PLATFORM_SERVICE,NATIONAL_LINK}', true, 1.0), ('AR-OWN-01', 'Có tổ chức chủ quản', 'Thành phần gắn tổ chức chủ quản (DO) và đầu mối liên hệ.', '{HTTT,API,FLOW,TOPIC,ADAPTER,PLATFORM_SERVICE}', true, 1.0), ('AR-DEP-01', 'Khai báo đủ phụ thuộc', 'Phụ thuộc với thành phần khác đã khai báo hoặc tự phát hiện.', '{HTTT,API,FLOW,TOPIC,ADAPTER,PLATFORM_SERVICE,NATIONAL_LINK}', false, 0.8), ('AR-OPS-01', 'Có trạng thái vận hành cập nhật', 'Trạng thái vận hành lấy từ PH-13, không quá hạn độ tươi.', '{HTTT,API,FLOW,TOPIC,ADAPTER,PLATFORM_SERVICE}', false, 0.6), ('AR-SEC-01', 'Đã phân loại và đánh giá ATTT', 'Có xác nhận của cán bộ ATTT về phân loại và hồ sơ cấp độ.', '{HTTT,API,PLATFORM_SERVICE,NATIONAL_LINK}', true, 1.0), ('AR-VER-01', 'Có phiên bản và tài liệu mô tả hiện hành', 'Có phiên bản đang ACTIVE kèm tham chiếu tài liệu mô tả.', '{HTTT,API,FLOW,ADAPTER,PLATFORM_SERVICE}', false, 0.6)) AS c(c, n, d, t, m, w)
  ON CONFLICT (tenant_id, criterion_code, version_no) DO NOTHING;
  INSERT INTO ph16_kpi.kpi_report_template (id, tenant_id, template_code, version_no, name, state, sections, formats, description, activated_at, created_by, updated_by)
  VALUES (md5('ph16-template:COMMON:bao-cao-chi-tieu-ky:1')::uuid, 'COMMON', 'bao-cao-chi-tieu-ky', 1, 'Báo cáo chỉ tiêu theo kỳ', 'ACTIVE',
          '{SUMMARY,GROUP,INDICATOR_TABLE,CHART,NARRATIVE,ANNEX}', '{PDF,XLSX}', 'Mẫu mặc định: tóm tắt, năm nhóm, bảng chỉ tiêu, biểu đồ, thuyết minh, phụ lục.', now(), 'system:seed', 'system:seed')
  ON CONFLICT (tenant_id, template_code, version_no) DO NOTHING;
END
$p$;
COMMENT ON PROCEDURE ph16_kpi.p_seed_common() IS 'Nạp bộ mẫu COMMON: 5 nhóm, 24 chỉ tiêu, 6 tiêu chí tuân thủ tối thiểu, 1 mẫu báo cáo. Chạy lại không nhân bản.';
--rollback DROP PROCEDURE IF EXISTS ph16_kpi.p_seed_common();

--changeset ph16:ph16-0930-seed-common-run
CALL ph16_kpi.p_seed_common();
--rollback DELETE FROM ph16_kpi.kpi_report_template WHERE tenant_id = 'COMMON'; DELETE FROM ph16_kpi.kpi_compliance_criterion WHERE tenant_id = 'COMMON'; DELETE FROM ph16_kpi.kpi_indicator WHERE tenant_id = 'COMMON'; DELETE FROM ph16_kpi.kpi_indicator_group WHERE tenant_id = 'COMMON';
