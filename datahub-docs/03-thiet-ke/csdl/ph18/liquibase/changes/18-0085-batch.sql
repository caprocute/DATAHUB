--liquibase formatted sql
-- Nguồn: ddl/ph18_ops.sql · 18-0085-batch.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph18:ph18-0850-batch-schema splitStatements:false
-- Kho lần chạy Spring Batch (JobRepository) của dh-migrate, dh-tenant-restore, dh-tenant-export (ADR-183, SDD §13.5 điểm 9): schema riêng
-- ph18_batch theo lược đồ chuẩn schema-postgresql.sql của Spring Batch 5, không RLS (dữ liệu kỹ thuật, tham số Job mang mã tenant, không
-- dữ liệu nghiệp vụ); chỉ ph18_worker đọc ghi, ph18_app và ph18_readonly không có quyền. Trạng thái nghiệp vụ vẫn ở ph18_ops.
CREATE SCHEMA IF NOT EXISTS ph18_batch AUTHORIZATION ph18_owner;
COMMENT ON SCHEMA ph18_batch IS 'PH-18 kho lần chạy Spring Batch (JobRepository) của dh-ops-worker; khởi động lại Job từ bước dừng. Không RLS, chỉ ph18_worker.';
REVOKE ALL ON SCHEMA ph18_batch FROM PUBLIC;
GRANT USAGE ON SCHEMA ph18_batch TO ph18_worker;
CREATE TABLE IF NOT EXISTS ph18_batch.batch_job_instance (job_instance_id bigint NOT NULL PRIMARY KEY, version bigint, job_name varchar(100) NOT NULL,
  job_key varchar(32) NOT NULL, CONSTRAINT job_inst_un UNIQUE (job_name, job_key));
CREATE TABLE IF NOT EXISTS ph18_batch.batch_job_execution (job_execution_id bigint NOT NULL PRIMARY KEY, version bigint, job_instance_id bigint NOT NULL,
  create_time timestamp NOT NULL, start_time timestamp, end_time timestamp, status varchar(10), exit_code varchar(2500), exit_message varchar(2500),
  last_updated timestamp, CONSTRAINT job_inst_exec_fk FOREIGN KEY (job_instance_id) REFERENCES ph18_batch.batch_job_instance (job_instance_id));
CREATE TABLE IF NOT EXISTS ph18_batch.batch_job_execution_params (job_execution_id bigint NOT NULL, parameter_name varchar(100) NOT NULL,
  parameter_type varchar(100) NOT NULL, parameter_value varchar(2500), identifying char(1) NOT NULL,
  CONSTRAINT job_exec_params_fk FOREIGN KEY (job_execution_id) REFERENCES ph18_batch.batch_job_execution (job_execution_id));
CREATE TABLE IF NOT EXISTS ph18_batch.batch_step_execution (step_execution_id bigint NOT NULL PRIMARY KEY, version bigint NOT NULL, step_name varchar(100) NOT NULL,
  job_execution_id bigint NOT NULL, create_time timestamp NOT NULL, start_time timestamp, end_time timestamp, status varchar(10), commit_count bigint,
  read_count bigint, filter_count bigint, write_count bigint, read_skip_count bigint, write_skip_count bigint, process_skip_count bigint, rollback_count bigint,
  exit_code varchar(2500), exit_message varchar(2500), last_updated timestamp,
  CONSTRAINT job_exec_step_fk FOREIGN KEY (job_execution_id) REFERENCES ph18_batch.batch_job_execution (job_execution_id));
CREATE TABLE IF NOT EXISTS ph18_batch.batch_step_execution_context (step_execution_id bigint NOT NULL PRIMARY KEY, short_context varchar(2500) NOT NULL,
  serialized_context text, CONSTRAINT step_exec_ctx_fk FOREIGN KEY (step_execution_id) REFERENCES ph18_batch.batch_step_execution (step_execution_id));
CREATE TABLE IF NOT EXISTS ph18_batch.batch_job_execution_context (job_execution_id bigint NOT NULL PRIMARY KEY, short_context varchar(2500) NOT NULL,
  serialized_context text, CONSTRAINT job_exec_ctx_fk FOREIGN KEY (job_execution_id) REFERENCES ph18_batch.batch_job_execution (job_execution_id));
CREATE SEQUENCE IF NOT EXISTS ph18_batch.batch_step_execution_seq MAXVALUE 9223372036854775807 NO CYCLE;
CREATE SEQUENCE IF NOT EXISTS ph18_batch.batch_job_execution_seq MAXVALUE 9223372036854775807 NO CYCLE;
CREATE SEQUENCE IF NOT EXISTS ph18_batch.batch_job_seq MAXVALUE 9223372036854775807 NO CYCLE;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA ph18_batch TO ph18_worker;
GRANT USAGE, SELECT, UPDATE ON ALL SEQUENCES IN SCHEMA ph18_batch TO ph18_worker;
--rollback DROP SCHEMA IF EXISTS ph18_batch CASCADE;
