--liquibase formatted sql
-- Nguồn: ddl/ph10_event.sql · 10-0800-seed.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph10:ph10-0900-seed-catalog
INSERT INTO ph10_event.comm_type (id, tenant_id, comm_type_code, name, direction, allowed_party_types, delivery_mode, legacy_code, created_by, updated_by)
SELECT md5('dh-comm-type:' || c.code)::uuid, 'COMMON', c.code, c.name, c.dir, c.parties::varchar(32)[], c.dm, c.legacy, 'system:seed', 'system:seed'
FROM (VALUES
  ('HTTP_PUBLISH',   'Phát qua API HTTP',  'PUBLISH',   '{SYSTEM}',                         NULL,         'REST'),
  ('KAFKA_NATIVE',   'Kafka trực tiếp',    'BOTH',      '{SYSTEM}',                         'PULL_KAFKA', 'PULSAR_CLIENT'),
  ('INTERNAL_KAFKA', 'Kafka nội bộ',       'BOTH',      '{FLOW,INTERNAL_SERVICE}',          'INTERNAL',   'ROUTE'),
  ('OUTBOX_CDC',     'Outbox của DU',      'PUBLISH',   '{INTERNAL_SERVICE}',               NULL,         NULL),
  ('DB_CDC',         'CDC CSDL (PH-05)',   'PUBLISH',   '{INTERNAL_SERVICE}',               NULL,         NULL),
  ('WEBHOOK_PUSH',   'Nhận đẩy webhook',   'SUBSCRIBE', '{SYSTEM}',                         'PUSH',       'HTTP_PUSH'),
  ('HTTP_PULL',      'Kéo qua API HTTP',   'SUBSCRIBE', '{SYSTEM}',                         'PULL_API',   NULL),
  ('PULSAR_BRIDGE',  'Cầu nối Pulsar',     'BOTH',      '{LEGACY_BRIDGE,INTERNAL_SERVICE}', 'INTERNAL',   NULL)
) AS c(code, name, dir, parties, dm, legacy)
ON CONFLICT (comm_type_code) DO UPDATE SET name = EXCLUDED.name, direction = EXCLUDED.direction,
  allowed_party_types = EXCLUDED.allowed_party_types, delivery_mode = EXCLUDED.delivery_mode,
  legacy_code = EXCLUDED.legacy_code, updated_by = 'system:seed';
INSERT INTO ph10_event.routing_mode (id, tenant_id, routing_mode_code, name, ordering, legacy_code, created_by, updated_by)
SELECT md5('dh-routing-mode:' || r.code)::uuid, 'COMMON', r.code, r.name, r.ord, r.legacy, 'system:seed', 'system:seed'
FROM (VALUES
  ('KEY_HASH',         'Theo khóa (băm)', 'PER_KEY',         'CustomPartition'),
  ('ROUND_ROBIN',      'Chia đều',        'NONE',            'RoundRobinPartition'),
  ('SINGLE_PARTITION', 'Một phân vùng',   'TOTAL',           'SinglePartition')
) AS r(code, name, ord, legacy)
ON CONFLICT (routing_mode_code) DO UPDATE SET name = EXCLUDED.name, ordering = EXCLUDED.ordering,
  legacy_code = EXCLUDED.legacy_code, updated_by = 'system:seed';
--rollback empty
