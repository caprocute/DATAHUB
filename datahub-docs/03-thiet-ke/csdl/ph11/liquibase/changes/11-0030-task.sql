--liquibase formatted sql
-- Nguồn: ddl/ph11_bpm.sql · 11-0030-task.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph11:ph11-0300-task-index
CREATE TABLE ph11_bpm.task_index (
  id                uuid NOT NULL,
  tenant_id         varchar(16) NOT NULL,
  engine_task_id    varchar(64) NOT NULL,
  instance_id       uuid NOT NULL,
  element_id        varchar(100) NOT NULL,
  task_kind         varchar(24) NOT NULL DEFAULT 'STANDARD',
  name              varchar(255) NOT NULL,
  status            varchar(12) NOT NULL DEFAULT 'UNASSIGNED',
  assignee          varchar(64),
  candidates        varchar(100)[] NOT NULL DEFAULT '{}',
  delegated_from    varchar(64),
  form_key          varchar(64),
  form_version      integer,
  priority          smallint NOT NULL DEFAULT 50,
  due_at            timestamptz,
  claimed_at        timestamptz,
  closed_at         timestamptz,
  draft             jsonb,
  decision          varchar(24),
  decision_comment  varchar(4000),
  completed_by      varchar(64),
  ai_assisted       boolean NOT NULL DEFAULT false,
  result_data       jsonb,
  result_enc        bytea,
  result_kid        varchar(64),
  inbox_item_id     uuid,
  trace_id          char(32) NOT NULL,
  created_at        timestamptz NOT NULL DEFAULT now(),
  created_by        varchar(64) NOT NULL,
  updated_at        timestamptz NOT NULL DEFAULT now(),
  updated_by        varchar(64) NOT NULL,
  version           integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_task_index PRIMARY KEY (id),
  CONSTRAINT uq_task_index_tid UNIQUE (tenant_id, id),
  CONSTRAINT uq_task_index_engine UNIQUE (tenant_id, engine_task_id),
  CONSTRAINT ck_task_index_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_task_index_instance FOREIGN KEY (tenant_id, instance_id) REFERENCES ph11_bpm.instance_index (tenant_id, id),
  CONSTRAINT ck_task_index_kind CHECK (task_kind IN ('STANDARD', 'APPROVAL', 'PUBLISH_REVIEW', 'MANUAL_COMPENSATION', 'INCIDENT_HANDLING')),
  CONSTRAINT ck_task_index_status CHECK (status IN ('UNASSIGNED', 'ASSIGNED', 'DELEGATED', 'COMPLETED', 'CANCELLED')),
  CONSTRAINT ck_task_index_assignee CHECK ((status = 'UNASSIGNED') = (assignee IS NULL) OR status IN ('COMPLETED', 'CANCELLED')),
  CONSTRAINT ck_task_index_candidates CHECK (status <> 'UNASSIGNED' OR cardinality(candidates) > 0),
  CONSTRAINT ck_task_index_delegated CHECK (status <> 'DELEGATED' OR (delegated_from IS NOT NULL AND delegated_from <> assignee)),
  CONSTRAINT ck_task_index_closed CHECK ((status IN ('COMPLETED', 'CANCELLED')) = (closed_at IS NOT NULL)),
  CONSTRAINT ck_task_index_decision CHECK (decision IS NULL OR decision IN ('APPROVE', 'REJECT', 'RETURN', 'REQUEST_SUPPLEMENT', 'COMPLETE')),
  CONSTRAINT ck_task_index_completed CHECK (status <> 'COMPLETED' OR (decision IS NOT NULL AND completed_by IS NOT NULL)),
  CONSTRAINT ck_task_index_comment CHECK (decision IS NULL OR decision IN ('APPROVE', 'COMPLETE') OR char_length(decision_comment) >= 20),
  CONSTRAINT ck_task_index_priority CHECK (priority BETWEEN 0 AND 100),
  CONSTRAINT ck_task_index_form CHECK ((form_key IS NULL) = (form_version IS NULL)),
  CONSTRAINT ck_task_index_enc CHECK (result_enc IS NULL OR (result_kid IS NOT NULL AND octet_length(result_enc) BETWEEN 29 AND 1048576)),
  CONSTRAINT ck_task_index_trace CHECK (trace_id ~ '^[0-9a-f]{32}$')
);
CREATE INDEX ix_task_index_assignee ON ph11_bpm.task_index (tenant_id, assignee, status, due_at) WHERE status IN ('ASSIGNED', 'DELEGATED');
CREATE INDEX ix_task_index_candidates ON ph11_bpm.task_index USING gin (candidates) WHERE status = 'UNASSIGNED';
CREATE INDEX ix_task_index_instance ON ph11_bpm.task_index (tenant_id, instance_id);
CREATE INDEX ix_task_index_due ON ph11_bpm.task_index (tenant_id, due_at) WHERE closed_at IS NULL AND due_at IS NOT NULL;
CREATE TRIGGER tg_task_index_touch BEFORE UPDATE ON ph11_bpm.task_index FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_touch();
CREATE TRIGGER tg_task_index_immutable BEFORE UPDATE ON ph11_bpm.task_index FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_immutable('engine_task_id', 'instance_id', 'element_id', 'task_kind', 'tenant_id');
CALL ph11_bpm.p_enable_rls('ph11_bpm.task_index', 'P');
COMMENT ON TABLE ph11_bpm.task_index IS 'EN-11-09 Bản chiếu việc người dùng cho hộp "Việc của tôi" (FR-11-034…044, FR-00-070). Nguồn sự thật là engine (engine_task_id). Việc giao qua ủy quyền giữ người gốc ở delegated_from. Từ chối, trả về, yêu cầu bổ sung bắt buộc ý kiến từ 20 ký tự (BR-11-033). Kết quả biểu mẫu: phần không nhạy cảm ở result_data, phần SENSITIVE chỉ ở result_enc (mã hóa envelope).';
COMMENT ON COLUMN ph11_bpm.task_index.task_kind IS 'TaskKind: STANDARD, APPROVAL, PUBLISH_REVIEW (duyệt phát hành, publish_request), MANUAL_COMPENSATION (xử lý bù trừ thủ công, saga_step), INCIDENT_HANDLING (xử lý sự cố).';
COMMENT ON COLUMN ph11_bpm.task_index.candidates IS 'Ứng viên nhận việc: mã người dùng, hoặc nhóm dạng group:{mã nhóm}; đơn vị được khai triển thành thành viên tại lúc tạo việc và chỉ chụp lại một lần (BR-11-037). Việc UNASSIGNED hiện cho các ứng viên; GIN phục vụ hộp việc.';
COMMENT ON COLUMN ph11_bpm.task_index.delegated_from IS 'Người được giao gốc khi việc DELEGATED (ủy quyền, FR-11-041); assignee là người đang xử lý.';
COMMENT ON COLUMN ph11_bpm.task_index.form_version IS 'Phiên bản biểu mẫu đã gắn lúc tạo việc, để hiển thị đúng bản dù biểu mẫu có phiên bản mới.';
COMMENT ON COLUMN ph11_bpm.task_index.draft IS 'Bản nháp kết quả (FR-11-039), chỉ trường không nhạy cảm; trường SENSITIVE không lưu nháp.';
COMMENT ON COLUMN ph11_bpm.task_index.decision IS 'Quyết định khi hoàn thành (Decision): APPROVE, REJECT, RETURN, REQUEST_SUPPLEMENT, COMPLETE.';
COMMENT ON COLUMN ph11_bpm.task_index.completed_by IS 'Người hoàn thành thực tế (người nhận hoặc người được ủy quyền, BR-11-016).';
COMMENT ON COLUMN ph11_bpm.task_index.ai_assisted IS 'Có dùng gợi ý AI của PH-17 khi xử lý (BR-11-029, FR-11-066).';
COMMENT ON COLUMN ph11_bpm.task_index.result_enc IS 'Phần SENSITIVE của kết quả, mã hóa envelope (OpenBao transit); result_kid ghi khóa.';
COMMENT ON COLUMN ph11_bpm.task_index.inbox_item_id IS 'Mã mục trong hộp việc chung (FR-00-070), tham chiếu logic.';
--rollback DROP TABLE IF EXISTS ph11_bpm.task_index CASCADE;

--changeset ph11:ph11-0310-task-comment
CREATE TABLE ph11_bpm.task_comment (
  id          uuid NOT NULL,
  tenant_id   varchar(16) NOT NULL,
  task_id     uuid NOT NULL,
  instance_id uuid NOT NULL,
  author      varchar(64) NOT NULL,
  kind        varchar(8) NOT NULL DEFAULT 'COMMENT',
  text        varchar(4000) NOT NULL,
  mentions    varchar(64)[] NOT NULL DEFAULT '{}',
  created_at  timestamptz NOT NULL DEFAULT now(),
  created_by  varchar(64) NOT NULL,
  CONSTRAINT pk_task_comment PRIMARY KEY (id),
  CONSTRAINT ck_task_comment_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_task_comment_task FOREIGN KEY (tenant_id, task_id) REFERENCES ph11_bpm.task_index (tenant_id, id),
  CONSTRAINT fk_task_comment_instance FOREIGN KEY (tenant_id, instance_id) REFERENCES ph11_bpm.instance_index (tenant_id, id),
  CONSTRAINT ck_task_comment_kind CHECK (kind IN ('COMMENT', 'OPINION', 'SYSTEM')),
  CONSTRAINT ck_task_comment_text CHECK (char_length(btrim(text)) >= 1)
);
CREATE INDEX ix_task_comment_task ON ph11_bpm.task_comment (tenant_id, task_id, created_at);
CREATE INDEX ix_task_comment_instance ON ph11_bpm.task_comment (tenant_id, instance_id, created_at);
CREATE TRIGGER tg_task_comment_append_only BEFORE UPDATE OR DELETE ON ph11_bpm.task_comment FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_append_only();
CALL ph11_bpm.p_enable_rls('ph11_bpm.task_comment', 'P');
COMMENT ON TABLE ph11_bpm.task_comment IS 'EN-11-10 Ý kiến, trao đổi trên việc (FR-11-043, 038). Chỉ thêm, không sửa, xóa (trigger, quyền): ý kiến là một phần của hồ sơ xử lý. kind OPINION là ý kiến chính thức khi hoàn thành việc, SYSTEM là ghi chú tự sinh (giao lại, trả về).';
COMMENT ON COLUMN ph11_bpm.task_comment.text IS 'Nội dung ý kiến, 1…4.000 ký tự (FR-11-043); không chứa giá trị biến SENSITIVE.';
COMMENT ON COLUMN ph11_bpm.task_comment.mentions IS 'Mã người dùng được nhắc tên (API mentions).';
COMMENT ON COLUMN ph11_bpm.task_comment.instance_id IS 'Phiên của việc (khử chuẩn để xem toàn bộ trao đổi theo hồ sơ).';
--rollback DROP TABLE IF EXISTS ph11_bpm.task_comment CASCADE;

--changeset ph11:ph11-0320-task-attachment
CREATE TABLE ph11_bpm.task_attachment (
  id            uuid NOT NULL,
  tenant_id     varchar(16) NOT NULL,
  task_id       uuid NOT NULL,
  instance_id   uuid NOT NULL,
  file_name     varchar(255) NOT NULL,
  content_type  varchar(127) NOT NULL,
  size          bigint NOT NULL,
  checksum      bytea NOT NULL,
  object_ref    varchar(512) NOT NULL,
  data_class    varchar(16) NOT NULL DEFAULT 'INTERNAL',
  scan_status   varchar(8) NOT NULL DEFAULT 'PENDING',
  removed_at    timestamptz,
  removed_by    varchar(64),
  created_at    timestamptz NOT NULL DEFAULT now(),
  created_by    varchar(64) NOT NULL,
  updated_at    timestamptz NOT NULL DEFAULT now(),
  updated_by    varchar(64) NOT NULL,
  version       integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_task_attachment PRIMARY KEY (id),
  CONSTRAINT uq_task_attachment_ref UNIQUE (tenant_id, object_ref),
  CONSTRAINT ck_task_attachment_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_task_attachment_task FOREIGN KEY (tenant_id, task_id) REFERENCES ph11_bpm.task_index (tenant_id, id),
  CONSTRAINT fk_task_attachment_instance FOREIGN KEY (tenant_id, instance_id) REFERENCES ph11_bpm.instance_index (tenant_id, id),
  CONSTRAINT ck_task_attachment_size CHECK (size BETWEEN 1 AND 52428800),
  CONSTRAINT ck_task_attachment_checksum CHECK (octet_length(checksum) = 32),
  CONSTRAINT ck_task_attachment_class CHECK (data_class IN ('PUBLIC', 'INTERNAL', 'RESTRICTED', 'SENSITIVE')),
  CONSTRAINT ck_task_attachment_scan CHECK (scan_status IN ('PENDING', 'CLEAN', 'INFECTED')),
  CONSTRAINT ck_task_attachment_removed CHECK ((removed_at IS NULL) = (removed_by IS NULL))
);
CREATE INDEX ix_task_attachment_task ON ph11_bpm.task_attachment (tenant_id, task_id) WHERE removed_at IS NULL;
CREATE INDEX ix_task_attachment_instance ON ph11_bpm.task_attachment (tenant_id, instance_id);
CREATE TRIGGER tg_task_attachment_touch BEFORE UPDATE ON ph11_bpm.task_attachment FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_touch();
CREATE TRIGGER tg_task_attachment_immutable BEFORE UPDATE ON ph11_bpm.task_attachment FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_immutable('task_id', 'file_name', 'size', 'checksum', 'object_ref', 'data_class', 'tenant_id');
CALL ph11_bpm.p_enable_rls('ph11_bpm.task_attachment', 'P');
COMMENT ON TABLE ph11_bpm.task_attachment IS 'EN-11-11 Tệp đính kèm việc (FR-11-043). Nội dung tệp ở Ceph RGW (object_ref, mã hóa phía máy chủ), bảng chỉ giữ siêu dữ liệu và SHA-256; tối đa 50 MiB mỗi tệp (trần của 11.task.attachmentMaxMb); chỉ tệp CLEAN sau quét mới tải được. Gỡ tệp là đánh dấu removed_at, không xóa dòng.';
COMMENT ON COLUMN ph11_bpm.task_attachment.size IS 'Kích thước tệp tính bằng byte (API size).';
COMMENT ON COLUMN ph11_bpm.task_attachment.checksum IS 'SHA-256 nội dung tệp (32 byte).';
COMMENT ON COLUMN ph11_bpm.task_attachment.object_ref IS 'Khóa đối tượng trên Ceph RGW: bpm/{tenant}/{instanceId}/{attachmentId}.';
COMMENT ON COLUMN ph11_bpm.task_attachment.data_class IS 'Phân loại dữ liệu do người tải khai (DataClass); tệp SENSITIVE chỉ người có quyền xem rõ mới tải được.';
COMMENT ON COLUMN ph11_bpm.task_attachment.scan_status IS 'Kết quả quét mã độc: PENDING, CLEAN, INFECTED (INFECTED bị chặn tải, báo người dùng).';
--rollback DROP TABLE IF EXISTS ph11_bpm.task_attachment CASCADE;

--changeset ph11:ph11-0330-delegation
CREATE TABLE ph11_bpm.delegation (
  id               uuid NOT NULL,
  tenant_id        varchar(16) NOT NULL,
  from_user        varchar(64) NOT NULL,
  to_user          varchar(64) NOT NULL,
  valid_from       timestamptz NOT NULL,
  valid_to         timestamptz NOT NULL,
  scope            jsonb NOT NULL DEFAULT '{"all": true}',
  scope_key        varchar(512) GENERATED ALWAYS AS (CASE WHEN scope ? 'processKeys' THEN scope ->> 'processKeys' ELSE '*' END) STORED,
  include_existing boolean NOT NULL DEFAULT false,
  status           varchar(12) NOT NULL DEFAULT 'SCHEDULED',
  reason           varchar(2000),
  revoked_at       timestamptz,
  revoked_by       varchar(64),
  created_at       timestamptz NOT NULL DEFAULT now(),
  created_by       varchar(64) NOT NULL,
  updated_at       timestamptz NOT NULL DEFAULT now(),
  updated_by       varchar(64) NOT NULL,
  version          integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_delegation PRIMARY KEY (id),
  CONSTRAINT ck_delegation_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_delegation_status CHECK (status IN ('SCHEDULED', 'ACTIVE', 'EXPIRED', 'REVOKED')),
  CONSTRAINT ck_delegation_distinct CHECK (from_user <> to_user),
  CONSTRAINT ck_delegation_period CHECK (valid_to > valid_from AND valid_to <= valid_from + interval '90 days'),
  CONSTRAINT ck_delegation_scope CHECK (jsonb_typeof(scope) = 'object' AND (scope ? 'all' OR scope ? 'processKeys')),
  CONSTRAINT ck_delegation_revoked CHECK ((status = 'REVOKED') = (revoked_at IS NOT NULL AND revoked_by IS NOT NULL)),
  CONSTRAINT ex_delegation_overlap EXCLUDE USING gist (tenant_id WITH =, from_user WITH =, scope_key WITH =, tstzrange(valid_from, valid_to) WITH &&) WHERE (status IN ('SCHEDULED', 'ACTIVE'))
);
CREATE INDEX ix_delegation_to_user ON ph11_bpm.delegation (tenant_id, to_user, valid_from, valid_to) WHERE status IN ('SCHEDULED', 'ACTIVE');
CREATE TRIGGER tg_delegation_touch BEFORE UPDATE ON ph11_bpm.delegation FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_touch();
CREATE TRIGGER tg_delegation_immutable BEFORE UPDATE ON ph11_bpm.delegation FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_immutable('from_user', 'to_user', 'scope', 'valid_from', 'tenant_id');
CALL ph11_bpm.p_enable_rls('ph11_bpm.delegation', 'P');
COMMENT ON TABLE ph11_bpm.delegation IS 'EN-11-12 Ủy quyền xử lý việc khi vắng mặt (FR-11-041). Người ủy quyền giao toàn bộ việc (scope {"all": true}) hoặc việc của một số mô hình (scope {"processKeys": [...]}) cho người nhận trong khoảng thời gian tối đa 90 ngày (trần của 11.delegation.maxDays); hai ủy quyền SCHEDULED hoặc ACTIVE của cùng người, cùng phạm vi không chồng thời gian (EXCLUDE). Hết hạn do tác vụ nền; thu hồi sớm ghi revoked_*.';
COMMENT ON COLUMN ph11_bpm.delegation.from_user IS 'Mã người dùng ủy quyền (PH-12).';
COMMENT ON COLUMN ph11_bpm.delegation.to_user IS 'Mã người dùng nhận ủy quyền, cùng tenant (BR-11-020).';
COMMENT ON COLUMN ph11_bpm.delegation.scope IS 'Phạm vi (API scope): {"all": true} mọi mô hình, hoặc {"processKeys": [mã mô hình...]}.';
COMMENT ON COLUMN ph11_bpm.delegation.scope_key IS 'Cột sinh từ scope để so phạm vi trong ràng buộc loại trừ chồng thời gian: * hoặc chuỗi processKeys.';
COMMENT ON COLUMN ph11_bpm.delegation.include_existing IS 'Chuyển cả việc đang giữ sang người nhận khi ủy quyền có hiệu lực.';
COMMENT ON COLUMN ph11_bpm.delegation.valid_to IS 'Hết hiệu lực; không quá 90 ngày sau valid_from. Tham số 11.delegation.maxDays của tenant có thể chặt hơn, kiểm ở dịch vụ.';
--rollback DROP TABLE IF EXISTS ph11_bpm.delegation CASCADE;
