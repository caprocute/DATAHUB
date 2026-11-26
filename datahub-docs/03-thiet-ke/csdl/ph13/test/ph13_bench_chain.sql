-- =============================================================================
-- D03-03-PH13 · Đo thử tốc độ ghi chuỗi: 400 lô × 500 bản ghi (200.000 bản ghi) vào chuỗi tenant T97
-- Chạy sau ph13_isolation_test.sql (cần vai trò dh_platform_app):  psql -v ON_ERROR_STOP=1 -d datahub -f ph13_bench_chain.sql
-- Mỗi lô gồm 500 INSERT vào audit_event (10 chỉ mục, RLS, CHECK, trigger chỉ-thêm) và một UPDATE audit_chain
-- (tg_audit_chain_guard kiểm liền kề). Số đo phụ thuộc máy; dùng để so sánh trước và sau khi đổi chỉ mục hoặc trigger.
-- =============================================================================
\set ON_ERROR_STOP on
SET ROLE dh_platform_app;
SET app.tenant_id = 'T97';
INSERT INTO ph13_audit.audit_chain (id, tenant_id, genesis_hash, head_hash, created_by, updated_by)
SELECT gen_random_uuid(), 'T97', ph13_audit.fn_hash('genesis:', 'T97'), ph13_audit.fn_hash('genesis:', 'T97'), 'system:bench', 'system:bench'
 WHERE NOT EXISTS (SELECT 1 FROM ph13_audit.audit_chain WHERE tenant_id = 'T97');
DO $$
DECLARE c record; prev text; sq bigint; h text; i int; b int; rec timestamptz; t0 timestamptz; t1 timestamptz; ms numeric[] := '{}';
BEGIN
  FOR b IN 1 .. 400 LOOP
    SELECT * INTO c FROM ph13_audit.audit_chain WHERE tenant_id = 'T97';
    prev := c.head_hash; sq := c.head_seq; rec := greatest(clock_timestamp(), coalesce(c.last_recorded_at, clock_timestamp()));
    t0 := clock_timestamp();
    FOR i IN 1 .. 500 LOOP
      sq := sq + 1;
      h := ph13_audit.fn_hash(prev, 'T97:' || sq);
      INSERT INTO ph13_audit.audit_event (id, tenant_id, seq, occurred_at, recorded_at, actor_type, actor_id, actor_name, source_ip, user_agent, action,
                                          object_type, object_id, outcome, trace_id, source_du, before, after, prev_hash, hash)
      VALUES (gen_random_uuid(), 'T97', sq, rec, rec, 'USER', 'u-' || (sq % 200), 'Người dùng', '10.0.0.1', 'Mozilla/5.0', 'CATALOG.PUBLISH', 'catalog',
              'DM_' || (sq % 5000), 'SUCCESS', md5(sq::text), 'dh-data', '{"status":"DRAFT"}', '{"status":"PUBLISHED","version":3}', prev, h);
      prev := h;
    END LOOP;
    UPDATE ph13_audit.audit_chain SET head_seq = sq, head_hash = prev, last_recorded_at = rec WHERE tenant_id = 'T97';
    t1 := clock_timestamp();
    ms := ms || (extract(epoch FROM t1 - t0) * 1000)::numeric;
  END LOOP;
  RAISE NOTICE 'lô 500 bản ghi: trung bình % ms, p95 % ms, tối đa % ms; tổng % ms', round((SELECT avg(x) FROM unnest(ms) x), 1),
    round((SELECT percentile_cont(0.95) WITHIN GROUP (ORDER BY x) FROM unnest(ms) x)::numeric, 1), round((SELECT max(x) FROM unnest(ms) x), 1), round((SELECT sum(x) FROM unnest(ms) x), 0);
END $$;
RESET ROLE;
