"""Liệt kê và lược đồ dùng chung, tenant, saga, cấu hình, hạn mức, phân hệ (PH-20)."""
from dsl import enum, obj, page, SCH, EX, T0, SHA0

# ---------------------------------------------------------------- liệt kê (FRS Phụ lục A và bổ sung theo CSDL)
enum('TenantStatus', 'Trạng thái tenant (DD-01).', 'ACTIVE', 'PROVISIONING', 'SUSPENDED', 'MERGING', 'MERGED', 'DECOMMISSIONED', 'FAILED')
enum('IsolationMode', 'Chế độ cách ly.', 'SHARED', 'DEDICATED_DB', 'DEDICATED_CLUSTER')
enum('TenantKind', 'Loại tenant.', 'PROVINCE', 'PLATFORM', 'COMMON')
enum('ProvisioningRunStatus', 'Trạng thái lần chạy saga.', 'RUNNING', 'PENDING', 'WAITING', 'FAILED', 'COMPENSATING', 'COMPENSATED', 'SUCCEEDED', 'CANCELLED')
enum('ProvisioningStepStatus', 'Trạng thái bước saga.', 'SUCCEEDED', 'PENDING', 'RUNNING', 'WAITING_REPORT', 'FAILED', 'SKIPPED', 'COMPENSATING', 'COMPENSATED')
enum('RunKind', 'Loại lần chạy saga.', 'INITIAL', 'SUPPLEMENT', 'ISOLATION_CHANGE')
enum('LifecycleRequestType', 'Loại đề nghị có duyệt.', 'SUSPEND', 'RESUME', 'TERMINATE', 'ISOLATION_CHANGE', 'QUOTA_DECREASE')
enum('RequestStatus', 'Trạng thái đề nghị có duyệt.', 'PENDING_APPROVAL', 'DRAFT', 'APPROVED', 'REJECTED', 'EXECUTING', 'DONE', 'CANCELLED')
enum('SuspendReason', 'Lý do tạm ngừng.', 'MANAGEMENT_DECISION', 'SECURITY_INCIDENT', 'CONTRACT_EXPIRED', 'TENANT_REQUEST', 'OTHER')
enum('QuotaResource', 'Tài nguyên có hạn mức.', 'API_RPS', 'ACTIVE_FLOWS', 'KAFKA_PRODUCE_MBPS', 'KAFKA_CONSUME_MBPS', 'OBJECT_STORAGE_GB', 'DATABASE_GB',
     'USERS', 'MEMBER_SYSTEMS', 'PUBLISHED_APIS', 'TOPICS', 'RUNTIME_CPU', 'RUNTIME_MEMORY_GB')
enum('QuotaAlertLevel', 'Mức cảnh báo hạn mức.', 'WARN_80', 'LIMIT_100')
enum('ModuleState', 'Trạng thái phân hệ theo tenant.', 'ENABLED', 'DISABLED', 'ENABLING', 'DISABLING', 'SUSPENDED', 'FAILED')
enum('MergeStatus', 'Trạng thái kế hoạch sáp nhập.', 'DRAFT', 'PENDING_APPROVAL', 'APPROVED', 'DRY_RUN', 'TRANSFERRING', 'CONFLICT_REVIEW', 'IDENTITY_TRANSFER',
     'CUTOVER', 'TRANSITION', 'COMPLETED', 'CANCELLED', 'FAILED')
enum('MergeMappingType', 'Loại ánh xạ sáp nhập.', 'ORGANIZATION', 'MEMBER_SYSTEM', 'CATALOG_CODE', 'API_CONTEXT_PATH', 'USER', 'TOPIC')
enum('MergeMappingAction', 'Hành động của dòng ánh xạ.', 'MAP', 'CREATE', 'SKIP')
enum('ConflictResolution', 'Cách giải quyết xung đột sáp nhập.', 'KEEP_TARGET', 'KEEP_SOURCE', 'RENAME_SOURCE', 'MERGE_ITEMS', 'SKIP')
enum('OrgType', 'Loại tổ chức (DD-02).', 'DEPARTMENT', 'PROVINCE_PC', 'COMMUNE_PC', 'PUBLIC_UNIT', 'OTHER')
enum('OrgStatus', 'Trạng thái tổ chức.', 'ACTIVE', 'INACTIVE', 'DISSOLVED', 'MERGED')
enum('ReleaseChannel', 'Kênh phát hành.', 'STABLE', 'PREVIEW')
enum('ReleaseStatus', 'Trạng thái phiên bản sản phẩm.', 'STABLE', 'DRAFT', 'PREVIEW', 'DEPRECATED', 'WITHDRAWN')
enum('UpgradePlanStatus', 'Trạng thái kế hoạch nâng cấp.', 'SCHEDULED', 'DRAFT', 'RUNNING', 'PAUSED', 'COMPLETED', 'ROLLED_BACK', 'CANCELLED')
enum('TenantUpgradeStatus', 'Trạng thái nâng cấp một tenant.', 'DONE', 'PENDING', 'IN_WINDOW', 'UPGRADING', 'VERIFYING', 'FAILED', 'ROLLED_BACK', 'SKIPPED')
enum('ExportPackageStatus', 'Trạng thái gói bàn giao dữ liệu.', 'READY', 'REQUESTED', 'COLLECTING', 'DELIVERED', 'EXPIRED', 'FAILED')
enum('DriftStatus', 'Trạng thái lệch cấu hình.', 'IN_SYNC', 'DRIFTED', 'RECONCILING', 'UNKNOWN')
# bổ sung theo CSDL và FRS (không nằm ở Phụ lục A)
enum('ScaleProfile', 'Hồ sơ quy mô.', 'QM-VUA', 'QM-NHO', 'QM-LON', 'QM-CHUNG')
enum('DeploymentProfile', 'Hồ sơ triển khai.', 'HT-B', 'HT-A')
enum('ContactRole', 'Vai của đầu mối tenant.', 'TENANT_ADMIN', 'LEADER', 'TECHNICAL', 'SECURITY')
enum('ServiceLevel', 'Mức dịch vụ của hợp đồng.', 'STANDARD', 'PREMIUM')
enum('ContractStatus', 'Trạng thái hợp đồng.', 'ACTIVE', 'DRAFT', 'EXPIRED', 'TERMINATED')
enum('TemplateState', 'Trạng thái phiên bản mẫu khởi tạo.', 'PUBLISHED', 'DRAFT', 'RETIRED')
enum('TemplateActivation', 'Cách kích hoạt sau khởi tạo.', 'AUTO', 'MANUAL')
enum('SmokeCheck', 'Ca kiểm tra khói.', 'LOGIN_ADMIN', 'API_SAMPLE', 'EVENT_SAMPLE', 'CROSS_TENANT_LEAK')
enum('SmokeResultValue', 'Kết quả một ca kiểm tra.', 'PASS', 'FAIL', 'SKIPPED')
enum('ReadinessCheck', 'Mục kiểm tra sẵn sàng.', 'CODE_UNIQUE', 'ADMIN_UNIT', 'CAPACITY', 'CLUSTER_RESOURCES', 'TEMPLATE', 'CONTACTS', 'HOST_PREFIX',
     'DEPENDENCIES', 'CLUSTER_TARGET', 'CONTRACT')
enum('ReadinessLevel', 'Mức của mục kiểm tra sẵn sàng.', 'PASS', 'WARN', 'BLOCKER')
enum('StepCode', 'Mã bước saga khởi tạo.', 'S01_RECORD', 'S02_CONFIG_REPO', 'S03_REALM', 'S04_SECRETS', 'S05_BUCKETS', 'S06_EVENTING', 'S07_DATABASE',
     'S08_OBSERVABILITY', 'S09_GATEWAY', 'S10_INTEGRATION', 'S11_SEED_RDM', 'S12_SEED_MDM', 'S13_ORG_SEED', 'S14_KPI', 'S15_MODULES', 'S16_SMOKE', 'S17_ACTIVATE')
enum('StepMode', 'Chế độ bước saga.', 'SYNC', 'ASYNC')
enum('StepReportStatus', 'Kết quả bên thực hiện báo cho bước bất đồng bộ.', 'SUCCEEDED', 'FAILED')
enum('ClusterState', 'Trạng thái cụm đích.', 'VERIFIED', 'REGISTERED', 'FAILED')
enum('ConfigScope', 'Phạm vi một phiên bản cấu hình.', 'PLATFORM_CONFIG', 'SETTINGS', 'QUOTA', 'MODULES', 'ALL')
enum('ChangeSource', 'Nguồn thay đổi cấu hình.', 'API', 'SAGA', 'RESTORE', 'DRIFT_FIX')
enum('ApplyStatus', 'Kết quả áp cấu hình xuống nơi thực thi.', 'APPLIED', 'PENDING', 'FAILED')
enum('SyncStatus', 'Trạng thái đồng bộ Argo CD.', 'SYNCED', 'PENDING', 'OUT_OF_SYNC', 'FAILED')
enum('DriftAction', 'Cách xử lý một lệch.', 'REAPPLY', 'ACCEPT')
enum('DriftResolution', 'Kết quả xử lý lệch.', 'RECONCILED', 'ACCEPTED', 'IGNORED')
enum('DetectedBy', 'Nguồn phát hiện lệch.', 'PERIODIC', 'ARGOCD')
enum('RuntimeNamespaceMode', 'Chế độ không gian tên runtime.', 'SHARED_NS', 'DEDICATED_NS')
enum('QuotaSource', 'Nguồn của giá trị hạn mức hiệu lực.', 'CONTRACT', 'TEMPLATE', 'OVERRIDE')
enum('PushStatus', 'Trạng thái đẩy hạn mức xuống nơi thực thi.', 'PUSHED', 'PENDING', 'FAILED')
enum('OverrideStatus', 'Trạng thái ghi đè hạn mức.', 'ACTIVE', 'EXPIRED', 'REVOKED')
enum('AlertState', 'Trạng thái cảnh báo hạn mức.', 'OPEN', 'ACKNOWLEDGED', 'RESOLVED')
enum('UsageGranularity', 'Độ mịn chuỗi sử dụng.', 'DAY', 'HOUR', 'MONTH')
enum('UsageQuality', 'Chất lượng điểm số liệu.', 'MEASURED', 'ESTIMATED', 'MISSING')
enum('ReportFormat', 'Định dạng báo cáo sử dụng.', 'XLSX', 'CSV', 'PDF')
enum('UsageReportStatus', 'Trạng thái báo cáo sử dụng.', 'READY', 'REQUESTED', 'GENERATING', 'FAILED', 'EXPIRED')
enum('ModuleStatus', 'Trạng thái phân hệ trong danh mục nền tảng.', 'AVAILABLE', 'PLANNED', 'DEPRECATED')
enum('DependencyType', 'Loại phụ thuộc giữa phân hệ.', 'REQUIRED', 'OPTIONAL')
enum('ExportFormat', 'Định dạng gói bàn giao.', 'JSONL', 'CSV')
enum('ExportItemStatus', 'Trạng thái phần dữ liệu của một phân hệ trong gói.', 'DONE', 'PENDING', 'COLLECTING', 'FAILED')
enum('MappingStatus', 'Trạng thái dòng ánh xạ.', 'CONFIRMED', 'PROPOSED', 'CONFLICT', 'APPLIED')
enum('ParticipantPhase', 'Pha chuyển dữ liệu của một phân hệ.', 'TRANSFER', 'DRY_RUN', 'IDENTITY', 'CUTOVER', 'VERIFY')
enum('ParticipantStatus', 'Trạng thái lần chuyển của một phân hệ.', 'SUCCEEDED', 'PENDING', 'RUNNING', 'FAILED', 'SKIPPED')
enum('ConflictKind', 'Loại xung đột sáp nhập.', 'DUPLICATE_CODE', 'DUPLICATE_PATH', 'DUPLICATE_USER', 'OTHER')
enum('ConflictState', 'Trạng thái xung đột.', 'OPEN', 'RESOLVED')
enum('ParallelCredentialStatus', 'Trạng thái thông tin xác thực song song của HTTT.', 'ACTIVE_PARALLEL', 'PENDING', 'OLD_REVOKED')
enum('ImportMode', 'Chế độ nhập tổ chức.', 'CREATE_ONLY', 'UPSERT')
enum('ImportStatus', 'Trạng thái lô nhập tổ chức.', 'PREVIEWED', 'UPLOADED', 'APPLYING', 'DONE', 'FAILED', 'CANCELLED')
enum('ImportAction', 'Hành động dự kiến của một dòng nhập.', 'CREATE', 'UPDATE', 'SKIP', 'ERROR')
enum('ProposalDecision', 'Quyết định về đề xuất đồng bộ tổ chức.', 'APPLY', 'DISMISS')
enum('ProposalState', 'Trạng thái đề xuất đồng bộ tổ chức.', 'PENDING', 'APPLIED', 'DISMISSED')
enum('SchemaChangeKind', 'Loại thay đổi lược đồ CSDL của phiên bản.', 'EXPAND', 'CONTRACT')
enum('ReleaseEnvironment', 'Môi trường của đăng ký kênh.', 'PROD', 'STAGING')
enum('WaveStatus', 'Trạng thái một sóng nâng cấp.', 'RUNNING', 'PENDING', 'PAUSED', 'DONE', 'STOPPED')
enum('Audience', 'Đối tượng nhận thông báo phát hành.', 'TA', 'ALL_USERS')
enum('LeakTrigger', 'Cách khởi chạy kiểm thử rò rỉ.', 'MANUAL', 'SCHEDULE', 'PRE_ACTIVATION')
enum('LeakStatus', 'Trạng thái lần kiểm thử rò rỉ.', 'PASSED', 'RUNNING', 'FAILED', 'ERROR')
enum('AccessKind', 'Loại truy cập liên tenant.', 'READ', 'WRITE')
enum('BannerType', 'Loại dải thông báo.', 'INFO', 'WARNING', 'CRITICAL')
enum('HandoverDelivery', 'Kết quả gửi thông báo bàn giao.', 'SENT', 'FAILED')
enum('NotificationStatus', 'Trạng thái thông báo đổi trạng thái tenant.', 'SENT', 'PENDING', 'FAILED')
enum('MappingOrigin', 'Nguồn của dòng ánh xạ.', 'AUTO', 'MANUAL')
enum('OrgHistoryAction', 'Hành động trong lịch sử tổ chức.', 'CREATED', 'UPDATED', 'DEACTIVATED', 'REACTIVATED', 'DISSOLVED', 'MERGED')

# ---------------------------------------------------------------- lỗi và dùng chung
obj('FieldError', 'Lỗi theo trường.', 'field!:str', 'message!:str', ('code:str', 'ERR-20-004'),
    ex={'field': 'tenantCode', 'message': 'Mã tenant chưa hợp lệ: cần dạng T và hai chữ số.'})
obj('Problem', 'Thân lỗi RFC 9457 (`application/problem+json`).',
    ('type!:url', 'https://datahub.example.vn/errors/ERR-20-004'), ('title!:str', 'Dữ liệu sai định dạng'), 'status!:int',
    ('detail:str', 'Mã tenant chưa hợp lệ: cần dạng T và hai chữ số.'), ('instance:str', '/api/platform/v1/tenants'),
    ('code!:str', 'ERR-20-004', {'pattern': '^ERR-(00|20)-[0-9]{3}$'}), 'traceId!:str', 'errors:R:FieldError[]', ex={'status': 400})
obj('ReasonTicket', 'Lý do và mã phiếu của thao tác thay đổi tenant (BR-20-009, `20.lifecycle.reason-min-length`).',
    ('reason!:str', None, {'minLength': 20, 'maxLength': 1000}), ('ticketRef!:str', None, {'maxLength': 32}))
obj('ReasonRequest', 'Lý do của thao tác (mã phiếu tùy chọn).', ('reason!:str', None, {'minLength': 20, 'maxLength': 1000}), ('ticketRef:str', None, {'maxLength': 32}))
obj('DecisionRequest', 'Ý kiến của người duyệt.', ('comment:str', None, {'maxLength': 1000}))
obj('RejectRequest', 'Từ chối kèm lý do.', ('comment!:str', 'Hồ sơ chưa đủ căn cứ pháp lý, đề nghị bổ sung văn bản.', {'minLength': 20, 'maxLength': 1000}))
obj('DiffEntry', 'Một khác biệt giữa hai phiên bản.', 'field!:str', ('from:str', '15'), ('to:str', '20'), ex={'field': 'sessionIdleMinutes'})
obj('AuditAck', 'Phản hồi gọn của thao tác đã nhận.', 'accepted!:bool', ('message:str', 'Đã nhận yêu cầu.'))

# ---------------------------------------------------------------- tenant
AUD = ('createdAt:ts', 'createdBy:str', 'updatedAt:ts', 'updatedBy:str')
obj('ReadinessItem', 'Một mục kiểm tra sẵn sàng (FR-20-007).', 'checkCode!:E:ReadinessCheck', 'result!:E:ReadinessLevel', ('message!:str', 'Mã T68 chưa dùng.'),
    ('errorCode:str', 'ERR-20-003', {'pattern': '^ERR-20-[0-9]{3}$'}), ('hint:str', 'Chọn mã khác nếu bị trùng.'), ex={'result': 'PASS'})
obj('ReadinessResult', 'Kết quả kiểm tra sẵn sàng.', 'ready!:bool', 'checkedAt!:ts', 'items!:R:ReadinessItem[]')
obj('RunBrief', 'Tóm tắt lần chạy saga gần nhất.', 'runId!:uuid', 'status!:E:ProvisioningRunStatus', ('failedStep:E:StepCode', 'S06_EVENTING'), ex={'status': 'SUCCEEDED'})
obj('ContactCreate', 'Thêm đầu mối của tenant (FR-20-005).', 'role!:E:ContactRole', 'fullName!:str', 'position:str', 'officialEmail!:email', 'phone:str', ('orgCode:ocode', 'SO-KHCN'),
    ('reason:str', None, {'minLength': 20}), ('ticketRef:str',))
obj('ContactUpdate', 'Sửa, ngừng đầu mối.', 'fullName:str', 'position:str', 'officialEmail:email', 'phone:str', ('orgCode:ocode', 'SO-KHCN'), 'active:bool',
    ('reason!:str', None, {'minLength': 20}), 'ticketRef!:str')
obj('Contact', 'Đầu mối của tenant (EN-20-03).', 'contactId!:uuid', 'role!:E:ContactRole', 'fullName!:str', 'position:str', 'officialEmail!:email', 'phone:str',
    ('orgCode:ocode', 'SO-KHCN'), 'active!:bool', *AUD, ex={'role': 'TENANT_ADMIN'})
obj('ContractCreate', 'Thêm hợp đồng dịch vụ.', 'contractNo!:str', 'title:str', 'serviceLevel:E:ServiceLevel', ('signedDate:date', '2026-09-15'), ('validFrom!:date', '2026-10-01'),
    ('validTo!:date', '2027-09-30'), ('parties:str[]', ['Văn phòng UBND tỉnh T68', 'Trung tâm vận hành Datahub']), 'fileId:uuid', ('committedQuota:map:num', {'API_RPS': 500}),
    ('reason!:str', None, {'minLength': 20}), 'ticketRef!:str')
obj('ContractUpdate', 'Sửa, gia hạn hợp đồng.', 'title:str', 'serviceLevel:E:ServiceLevel', ('validTo:date', '2028-09-30'), 'status:E:ContractStatus', 'fileId:uuid',
    ('committedQuota:map:num', {'API_RPS': 800}), ('reason!:str', None, {'minLength': 20}), 'ticketRef!:str')
obj('Contract', 'Hợp đồng dịch vụ (EN-20-04).', 'contractId!:uuid', 'contractNo!:str', 'title:str', 'serviceLevel:E:ServiceLevel', 'status!:E:ContractStatus',
    ('signedDate:date', '2026-09-15'), ('validFrom!:date', '2026-10-01'), ('validTo!:date', '2027-09-30'), ('parties:str[]', ['Văn phòng UBND tỉnh T68']), 'fileId:uuid',
    ('committedQuota:map:num', {'API_RPS': 500}), *AUD, ex={'status': 'ACTIVE'})

TENANT_FIELDS = ['tenantCode!:tc', 'name!:str', ('shortName:str', 'Tỉnh Lâm Viên'), 'kind!:E:TenantKind', 'status!:E:TenantStatus', 'isolationMode!:E:IsolationMode',
                 'scaleProfile:E:ScaleProfile', 'deploymentProfile:E:DeploymentProfile', 'adminUnitId:uuid', 'realm:str', 'templateCode:code', ('templateVersion:int', 3),
                 'clusterCode:str', ('mergedInto:tc', 'T90'), 'statusReason:str', 'currentVersion:ver', 'channel:E:ReleaseChannel', ('testTenant:bool', False),
                 ('declaredAt:ts', '2026-11-20T08:00:00+07:00'), ('activatedAt:ts', '2026-11-21T10:00:00+07:00'), 'suspendedAt:ts', 'mergedAt:ts', 'decommissionedAt:ts', 'note:str']
TEN_EX = {'kind': 'PROVINCE', 'status': 'ACTIVE', 'isolationMode': 'SHARED', 'channel': 'STABLE', 'suspendedAt': None, 'mergedAt': None, 'decommissionedAt': None,
          'mergedInto': None, 'clusterCode': None, 'statusReason': None}
obj('Tenant', 'Bản ghi tenant (EN-20-01, DD-01).', *TENANT_FIELDS, 'readiness:R:ReadinessResult', *AUD, ex={**TEN_EX})
obj('TenantCreate', 'Hồ sơ khai báo tenant mới (FR-20-001).', 'tenantCode!:tc', ('name!:str', None, {'minLength': 1, 'maxLength': 255}), 'adminUnitId:uuid',
    'isolationMode!:E:IsolationMode', 'scaleProfile!:E:ScaleProfile', 'deploymentProfile!:E:DeploymentProfile', 'clusterCode:str', 'templateCode!:code',
    ('templateVersion!:int', 3, {'minimum': 1}), ('modulesExcluded:mod[]', ['PH-17']), 'contacts!:R:ContactCreate[]', 'contractRef:str', ('testTenant:bool', False),
    ('note:str', None, {'maxLength': 2000}), ex={'clusterCode': 'cl-t68-onprem', 'isolationMode': 'SHARED', 'contacts': [
        {'role': 'TENANT_ADMIN', 'fullName': 'Nguyễn Thị Lan', 'position': 'Giám đốc Sở Khoa học và Công nghệ', 'officialEmail': 'nguyen.thi.lan@t68.example.vn', 'phone': '0912345678', 'orgCode': 'SO-KHCN'},
        {'role': 'TECHNICAL', 'fullName': 'Trần Văn Nam', 'position': 'Chuyên viên công nghệ thông tin', 'officialEmail': 'tran.van.nam@t68.example.vn', 'phone': '0987654321', 'orgCode': 'SO-KHCN'}]})
obj('TenantUpdate', 'Sửa hồ sơ hành chính (FR-20-004); không đổi mã, realm, loại.', 'name:str', 'scaleProfile:E:ScaleProfile', 'note:str', 'adminUnitId:uuid',
    ('reason!:str', None, {'minLength': 20}), 'ticketRef!:str')
obj('TenantSummary', 'Dòng tenant trong danh sách (FR-20-002).', 'tenantCode!:tc', 'name!:str', 'kind!:E:TenantKind', 'status!:E:TenantStatus', 'isolationMode!:E:IsolationMode',
    'scaleProfile:E:ScaleProfile', 'deploymentProfile:E:DeploymentProfile', 'currentVersion:ver', 'channel:E:ReleaseChannel', 'lastRun:R:RunBrief', ('openAlerts:int', 0),
    ('activatedAt:ts', '2026-11-21T10:00:00+07:00'), ex={'kind': 'PROVINCE', 'status': 'ACTIVE', 'isolationMode': 'SHARED', 'channel': 'STABLE'})
obj('TenantFacets', 'Đếm theo nhóm cho bộ lọc.', ('byStatus:map:int', {'ACTIVE': 31, 'PROVISIONING': 1, 'SUSPENDED': 1}), ('byIsolationMode:map:int', {'SHARED': 30, 'DEDICATED_DB': 3}),
    ('byChannel:map:int', {'STABLE': 30, 'PREVIEW': 3}))
page('TenantSummary', 'TenantPage', 'facets:R:TenantFacets')
obj('TenantDetail', 'Chi tiết tenant kèm các khối chọn bằng `include` (FR-20-003).', *TENANT_FIELDS, 'config:R:PlatformConfig', 'contacts:R:Contact[]', 'modules:R:TenantModule[]',
    'quotas:R:QuotaItem[]', 'lastRun:R:RunBrief', ('allowedActions:str[]', ['edit', 'suspend', 'check-readiness']), *AUD, ex={**TEN_EX})
page('Contact'); page('Contract')

# ---------------------------------------------------------------- saga
obj('ProvisioningStep', 'Một bước của saga (EN-20-11).', 'stepCode!:E:StepCode', ('order!:int', 3), ('executor!:str', 'PH-12'), 'mode!:E:StepMode', 'status!:E:ProvisioningStepStatus',
    'attempt!:int', 'durationSeconds:int', ('errorCode:str', None, {'pattern': '^ERR-20-[0-9]{3}$'}), 'errorDetail:str', 'outputRef:str', 'startedAt:ts', 'finishedAt:ts', 'timeoutAt:ts',
    ex={'stepCode': 'S03_REALM', 'mode': 'SYNC', 'status': 'SUCCEEDED', 'errorCode': None, 'errorDetail': None, 'timeoutAt': None})
obj('SmokeResult', 'Kết quả một ca kiểm tra khói (EN-20-12).', ('case!:E:SmokeCheck',), 'result!:E:SmokeResultValue', 'durationMs:int', ('evidence:str', 'Đăng nhập quản trị tỉnh thành công'))
obj('ProvisioningRun', 'Lần chạy saga (EN-20-10).', 'runId!:uuid', 'tenantCode!:tc', 'runKind!:E:RunKind', 'status!:E:ProvisioningRunStatus', 'templateCode:code', ('templateVersion:int', 3),
    'isolationMode:E:IsolationMode', 'attempt!:int', ('currentStep:E:StepCode', 'S06_EVENTING'), 'startedAt:ts', 'finishedAt:ts', ('elapsedSeconds:int', 1260), ('etaSeconds:int', 900),
    ('durationSeconds:int', 2640), ('errorCode:str', None, {'pattern': '^ERR-20-[0-9]{3}$'}), 'errorMessage:str', 'requestedBy:str', 'traceId:str', 'steps!:R:ProvisioningStep[]',
    'smokeResults:R:SmokeResult[]', ex={'runKind': 'INITIAL', 'status': 'RUNNING', 'errorCode': None, 'errorMessage': None, 'finishedAt': None, 'isolationMode': 'SHARED'})
obj('ProvisioningRunSummary', 'Dòng lần chạy trong danh sách.', 'runId!:uuid', 'tenantCode!:tc', 'runKind!:E:RunKind', 'status!:E:ProvisioningRunStatus', 'attempt!:int',
    'startedAt:ts', 'finishedAt:ts', ('durationSeconds:int', 2640), ('failedStep:E:StepCode', 'S06_EVENTING'), ex={'status': 'SUCCEEDED'})
page('ProvisioningRunSummary', 'ProvisioningRunPage')
obj('RunCreate', 'Yêu cầu chạy saga (FR-20-008, 016).', ('runKind:E:RunKind', 'INITIAL'), ('steps:E:StepCode[]', ['S15_MODULES']), ('modules:mod[]', ['PH-19']),
    ('reason:str', None, {'minLength': 20}), 'ticketRef:str')
obj('StepAction', 'Thử lại một bước hoặc cả lần chạy.', ('reason:str', 'Bên thực hiện đã khắc phục sự cố, thử lại.', {'minLength': 20}))
obj('SkipStepRequest', 'Bỏ qua bước không bắt buộc (FR-20-010).', ('reason!:str', 'Phân hệ PH-06 chưa bật cho tỉnh nên bỏ qua gieo dữ liệu chủ.', {'minLength': 20}), 'ticketRef!:str')
obj('CompensateRequest', 'Bù trừ hoặc hủy khởi tạo (FR-20-011).', ('reason!:str', None, {'minLength': 20}), 'ticketRef!:str', 'confirmTenantCode!:tc')
obj('SmokeRun', 'Lần chạy lại kiểm tra khói.', 'runId!:uuid', 'tenantCode!:tc', ('status!:str', 'RUNNING', {'enum': ['RUNNING', 'DONE']}), 'startedAt!:ts', 'results:R:SmokeResult[]')
obj('ActivateRequest', 'Kích hoạt tenant (FR-20-013).', ('activateAt:ts', '2026-11-28T08:00:00+07:00'), ('reason:str', None, {'minLength': 20}), 'ticketRef:str')
obj('TenantActivation', 'Kết quả kích hoạt.', 'tenantCode!:tc', 'status!:E:TenantStatus', 'activatedAt!:ts', 'handoverDelivery!:E:HandoverDelivery', ex={'status': 'ACTIVE', 'handoverDelivery': 'SENT'})
obj('ProvisionMetric', 'Thời gian khởi tạo một tenant.', 'tenantCode!:tc', ('provisionMinutes!:num', 47.5), ('leadTimeWorkingHours!:num', 6.5), ('slowestStep:E:StepCode', 'S06_EVENTING'), ('attempts:int', 1))
obj('ProvisioningMetrics', 'Số đo khởi tạo (KPI-12).', 'items!:R:ProvisionMetric[]', ('median!:num', 52.0), ('p95!:num', 118.0), 'page!:int', 'size!:int', 'totalElements!:int')

# mẫu khởi tạo
obj('OrgSeedItem', 'Tổ chức gieo khi khởi tạo.', 'orgCode!:ocode', 'name!:str', 'orgType!:E:OrgType', ('parentCode:ocode', 'UBND-TINH'),
    ex={'name': 'Sở Khoa học và Công nghệ', 'orgType': 'DEPARTMENT'})
TPL_BODY = [('modules!:mod[]', ['PH-01', 'PH-02', 'PH-03', 'PH-04', 'PH-05', 'PH-07', 'PH-10', 'PH-12', 'PH-13', 'PH-14', 'PH-18', 'PH-20'], {'minItems': 1}),
            ('quotaByScale!:obj', {'QM-VUA': {'API_RPS': 500, 'ACTIVE_FLOWS': 1000}}), 'rdmPackageVersion!:str', 'orgSeed!:R:OrgSeedItem[]', 'kpiSetVersion:str',
            ('featureFlags:map:bool', {'ph04.sql-direct': False}), 'activation!:E:TemplateActivation', 'releaseChannel!:E:ReleaseChannel']
obj('TemplateCreate', 'Tạo mẫu khởi tạo, phiên bản 1 `DRAFT` (FR-20-015).', 'templateCode!:code', ('name!:str', 'Tỉnh chuẩn Đợt 1', {'minLength': 1, 'maxLength': 255}), 'description:str', *TPL_BODY)
obj('TemplateVersion', 'Một phiên bản mẫu khởi tạo (EN-20-09).', 'templateCode!:code', ('version!:int', 3), 'state!:E:TemplateState', ('name:str', 'Tỉnh chuẩn Đợt 1'), 'description:str', *TPL_BODY,
    'contentHash:sha', 'changeNote:str', 'publishedAt:ts', 'diff:R:DiffEntry[]', *AUD, ex={'state': 'PUBLISHED', 'activation': 'AUTO', 'releaseChannel': 'STABLE'})
obj('TemplateVersionBrief', 'Tóm tắt phiên bản mẫu.', ('version!:int', 3), 'state!:E:TemplateState', 'publishedAt:ts', 'contentHash:sha', ex={'state': 'PUBLISHED'})
obj('ProvisioningTemplate', 'Mẫu khởi tạo (mức mẫu).', 'templateCode!:code', ('name!:str', 'Tỉnh chuẩn Đợt 1'), 'description:str', ('latestVersion!:int', 3), ('publishedVersion:int', 3), *AUD)
page('ProvisioningTemplate', 'TemplatePage')
obj('TemplateDetail', 'Chi tiết mẫu và các phiên bản.', 'templateCode!:code', ('name!:str', 'Tỉnh chuẩn Đợt 1'), 'description:str', ('latestVersion!:int', 3), ('publishedVersion:int', 3),
    'versions!:R:TemplateVersionBrief[]', *AUD)
obj('TemplateNewVersion', 'Mở phiên bản mới từ bản đang dùng.', ('fromVersion:int', 3), ('changeNote!:str', 'Bổ sung phân hệ PH-19 vào mẫu.', {'minLength': 10}))
obj('TemplateVersionUpdate', 'Sửa phiên bản `DRAFT`.', ('modules:mod[]', ['PH-01', 'PH-02', 'PH-03', 'PH-19']), ('quotaByScale:obj', {'QM-VUA': {'API_RPS': 600}}), 'rdmPackageVersion:str',
    'orgSeed:R:OrgSeedItem[]', 'kpiSetVersion:str', ('featureFlags:map:bool', {'ph04.sql-direct': False}), 'activation:E:TemplateActivation', 'releaseChannel:E:ReleaseChannel',
    ('changeNote:str', 'Tăng hạn mức API_RPS cho quy mô vừa.'))

# khởi tạo bổ sung
obj('SupplementRequest', 'Khởi tạo bổ sung hàng loạt (FR-20-016).', ('steps:E:StepCode[]', ['S15_MODULES']), ('modules:mod[]', ['PH-19']), ('tenantCodes:tc[]', ['T68']),
    ('waveSize:int', 3, {'minimum': 1, 'maximum': 10}), ('reason!:str', None, {'minLength': 20}), 'ticketRef!:str')
obj('SupplementCandidate', 'Tenant cần bổ sung.', 'tenantCode!:tc', ('missingSteps:E:StepCode[]', ['S15_MODULES']), ('currentVersion:ver', '2.3.1'))
obj('SupplementExcluded', 'Tenant bị loại khỏi đợt bổ sung.', 'tenantCode!:tc', ('reason!:str', 'Tenant đang có lần chạy khác.'), ('errorCode:str', 'ERR-20-016'))
obj('SupplementPreview', 'Xem trước đợt bổ sung.', 'candidates!:R:SupplementCandidate[]', 'excluded!:R:SupplementExcluded[]')
obj('SupplementPlan', 'Đợt bổ sung đã lập.', 'planId!:uuid', ('status!:str', 'RUNNING'), ('tenantCount!:int', 1), ('runIds!:uuid[]', ['0193c2a0-1a2b-7c3d-8e4f-5a6b7c8d9e01']), ('waveSize:int', 3))

# cụm riêng
obj('ClusterCreate', 'Đăng ký cụm đích `DEDICATED_CLUSTER` (FR-20-017); `secretRef` là đường dẫn OpenBao, không bao giờ là giá trị bí mật.', ('clusterCode!:str', 'cl-t68-onprem'),
    'name!:str', 'apiEndpoint!:url', 'argoCdEndpoint!:url', 'ownerTenant:tc', ('capabilities:str[]', ['cnpg', 'ceph-rgw', 'argocd']), 'secretRef!:str', ex={'name': 'Cụm riêng tỉnh T68'})
obj('Cluster', 'Cụm đích.', 'clusterCode!:str', 'name!:str', 'apiEndpoint!:url', 'argoCdEndpoint!:url', 'ownerTenant:tc', ('capabilities:str[]', ['cnpg', 'ceph-rgw', 'argocd']),
    'secretRef:str', 'state!:E:ClusterState', 'verifiedAt:ts', *AUD, ex={'name': 'Cụm riêng tỉnh T68', 'state': 'VERIFIED'})
page('Cluster')
obj('ClusterVerification', 'Kết quả kiểm cụm.', 'clusterCode!:str', 'state!:E:ClusterState', 'checks!:R:ReadinessItem[]', 'verifiedAt:ts', ex={'state': 'VERIFIED'})
obj('DedicatedBundle', 'Gói cấu hình cho cụm riêng.', 'bundleId!:uuid', ('status!:str', 'READY'), 'downloadUrl:url', 'expiresAt:ts', 'sha256:sha')

# ---------------------------------------------------------------- cấu hình
obj('PlatformConfig', 'Cấu hình nền tảng của tenant (EN-20-05).', 'realm!:str', 'publicHost!:str', 'apiPathPrefix!:str', 'deploymentProfile!:E:DeploymentProfile', 'drRegion:str',
    ('runtimeNamespaceMode!:E:RuntimeNamespaceMode', 'SHARED_NS'), 'clusterCode:str', ('kafkaPrefix:str', 't68.'), ('bucketPrefix:str', 'dh-t68-'), ('configVersionNo!:int', 7),
    'commitSha:str', 'syncStatus!:E:SyncStatus', 'driftStatus:E:DriftStatus', 'appliedAt:ts', *AUD, ex={'clusterCode': None, 'syncStatus': 'SYNCED', 'driftStatus': 'IN_SYNC'})
obj('PlatformConfigUpdate', 'Sửa cấu hình nền tảng (FR-20-019).', 'publicHost:str', 'apiPathPrefix:str', 'deploymentProfile:E:DeploymentProfile', 'drRegion:str',
    'runtimeNamespaceMode:E:RuntimeNamespaceMode', ('reason!:str', None, {'minLength': 20}), 'ticketRef!:str')
obj('ConfigVersion', 'Phiên bản cấu hình, bản chiếu commit Git (EN-20-07).', ('versionNo!:int', 7), 'scope!:E:ConfigScope', 'commitSha!:str', 'commitMessage:str', 'contentHash:sha',
    'changeSource!:E:ChangeSource', 'reason:str', 'applyStatus!:E:ApplyStatus', 'appliedAt:ts', ('changedBy:str', 'nguyen.thi.lan'), 'changedAt!:ts', 'snapshot:obj', 'diff:R:DiffEntry[]',
    ex={'scope': 'PLATFORM_CONFIG', 'changeSource': 'API', 'applyStatus': 'APPLIED', 'snapshot': {'publicHost': 'api.t68.datahub.example.vn'}})
page('ConfigVersion')
obj('ConfigDrift', 'Lệch cấu hình (EN-20-08).', 'driftId!:uuid', 'status!:E:DriftStatus', 'detectedAt!:ts', 'detectedBy!:E:DetectedBy', ('desiredVersionNo:int', 7), 'differences!:R:DiffEntry[]',
    'resolution:E:DriftResolution', 'resolvedBy:str', 'resolvedAt:ts', ex={'status': 'DRIFTED', 'detectedBy': 'PERIODIC', 'resolution': None, 'resolvedBy': None, 'resolvedAt': None})
page('ConfigDrift')
obj('DriftResolveRequest', 'Xử lý một lệch (FR-20-022).', 'action!:E:DriftAction', ('reason!:str', None, {'minLength': 20}), 'ticketRef!:str')
obj('ReconcileResult', 'Lần đối chiếu cấu hình.', 'reconcileId!:uuid', 'status!:E:DriftStatus', 'startedAt!:ts', ex={'status': 'RECONCILING'})
obj('IsolationChangeCreate', 'Đề nghị chuyển chế độ cách ly (FR-20-025).', 'targetMode!:E:IsolationMode', ('scheduledAt:ts', '2026-12-05T22:00:00+07:00'), 'clusterCode:str',
    ('reason!:str', None, {'minLength': 20}), 'ticketRef!:str', 'decisionDocNo!:str', ex={'targetMode': 'DEDICATED_DB', 'clusterCode': None})

# ---------------------------------------------------------------- hạn mức, sử dụng
obj('QuotaItem', 'Một dòng hạn mức hiệu lực (EN-20-13).', 'resource!:E:QuotaResource', 'unit:str', ('contractValue:num', 500), ('platformCeiling:num', 2000), ('overrideValue:num', 800),
    ('effectiveValue!:num', 800), ('lastUsage:num', 312), ('source:E:QuotaSource', 'OVERRIDE'), ('pushStatus:E:PushStatus', 'PUSHED'))
obj('QuotaValueInput', 'Giá trị hạn mức hợp đồng của một tài nguyên.', 'resource!:E:QuotaResource', ('contractValue!:num', 500, {'minimum': 0}))
obj('QuotaNewValue', 'Giá trị đề nghị mới của một tài nguyên.', 'resource!:E:QuotaResource', ('newValue!:num', 800, {'minimum': 0}))
obj('QuotaOverride', 'Ghi đè hạn mức tạm thời (EN-20-15).', 'overrideId!:uuid', 'tenantCode!:tc', 'resource!:E:QuotaResource', ('value!:num', 800), 'validFrom!:ts',
    ('validTo!:ts', '2026-12-20T00:00:00+07:00'), 'status!:E:OverrideStatus', 'reason:str', 'ticketRef:str', 'requestedBy:str', 'approvedBy:str', 'revokedAt:ts', ex={'status': 'ACTIVE', 'revokedAt': None})
obj('TenantQuotas', 'Hạn mức hợp đồng, ghi đè, hiệu lực của tenant.', 'tenantCode!:tc', 'items!:R:QuotaItem[]', 'overrides:R:QuotaOverride[]', 'contractId:uuid', 'effectiveFrom:ts')
obj('QuotaSetRequest', 'Đặt hạn mức hợp đồng ban đầu hoặc tăng trong trần (FR-20-026).', ('items!:R:QuotaValueInput[]', None, {'minItems': 1}), 'contractId:uuid',
    ('reason!:str', None, {'minLength': 20}), 'ticketRef!:str')
obj('QuotaChangeCreate', 'Đề nghị đổi hạn mức có duyệt (FR-20-027).', ('items!:R:QuotaNewValue[]', None, {'minItems': 1}), ('effectiveAt:ts', '2026-12-01T00:00:00+07:00'),
    ('reason!:str', None, {'minLength': 20}), 'ticketRef!:str', 'contractId:uuid')
obj('AppliedTarget', 'Nơi thực thi đã xác nhận hạn mức.', ('target!:str', 'APISIX'), 'confirmedAt!:ts')
obj('QuotaChangeRequest', 'Đề nghị đổi hạn mức (EN-20-14).', 'requestId!:uuid', 'tenantCode!:tc', 'status!:E:RequestStatus', 'items!:R:QuotaNewValue[]', 'effectiveAt:ts', 'reason:str',
    'ticketRef:str', ('fourEyes:bool', True), 'requestedBy!:str', 'requestedAt!:ts', 'approvedBy:str', 'approvedAt:ts', 'decisionNote:str', 'appliedTargets:R:AppliedTarget[]',
    ex={'status': 'PENDING_APPROVAL', 'approvedBy': None, 'approvedAt': None, 'decisionNote': None, 'appliedTargets': []})
page('QuotaChangeRequest')
obj('OverrideCreate', 'Ghi đè hạn mức tạm thời (FR-20-032).', 'resource!:E:QuotaResource', ('value!:num', 800, {'minimum': 0}), 'validFrom!:ts', ('validTo!:ts', '2026-12-20T00:00:00+07:00'),
    ('reason!:str', None, {'minLength': 20}), 'ticketRef!:str')
obj('UsagePoint', 'Một điểm số liệu sử dụng.', ('t!:ts', '2026-11-27T09:00:00+07:00'), ('value!:num', 312), ('peak:num', 365), ('limit:num', 500), ('percent:num', 62.4), 'quality:E:UsageQuality', ex={'quality': 'MEASURED'})
obj('UsageSeriesItem', 'Chuỗi sử dụng của một tài nguyên.', 'resource!:E:QuotaResource', 'unit:str', 'points!:R:UsagePoint[]')
obj('UsageRankItem', 'Xếp hạng tenant theo mức sử dụng.', 'tenantCode!:tc', 'resource!:E:QuotaResource', ('percent!:num', 62.4), ('used:num', 312), ('limit:num', 500))
obj('UsageResponse', 'Sử dụng tài nguyên (FR-20-030).', 'from!:ts', 'to!:ts', 'granularity!:E:UsageGranularity', 'series!:R:UsageSeriesItem[]', 'ranking:R:UsageRankItem[]', ex={'granularity': 'HOUR'})
obj('QuotaAlert', 'Cảnh báo hạn mức (EN-20-17).', 'alertId!:uuid', 'tenantCode!:tc', 'resource!:E:QuotaResource', 'alertLevel!:E:QuotaAlertLevel', 'state!:E:AlertState',
    ('used:num', 412), ('limit:num', 500), ('percent:num', 82.4), 'raisedAt!:ts', 'acknowledgedBy:str', 'acknowledgedAt:ts', 'resolvedAt:ts',
    ex={'alertLevel': 'WARN_80', 'state': 'OPEN', 'acknowledgedBy': None, 'acknowledgedAt': None, 'resolvedAt': None})
page('QuotaAlert')
obj('AcknowledgeRequest', 'Xác nhận đã xử lý cảnh báo.', ('comment:str', 'Đã liên hệ tỉnh, đề nghị tăng hạn mức.'))
obj('UsageReportCreate', 'Lập báo cáo sử dụng theo kỳ (FR-20-031); `scope` là `PLATFORM` hoặc mã tenant.', ('scope!:str', 'PLATFORM'), 'period!:period', 'format!:E:ReportFormat', ex={'format': 'XLSX'})
obj('UsageReport', 'Báo cáo sử dụng (EN-20-37).', 'reportId!:uuid', 'scope!:str', 'period!:period', 'format!:E:ReportFormat', 'status!:E:UsageReportStatus', 'rowCount:int',
    ('fileName:str', 'su-dung-M-2026-10.xlsx'), 'expiresAt:ts', 'requestedBy:str', 'requestedAt:ts', 'errorMessage:str', ex={'format': 'XLSX', 'status': 'REQUESTED', 'errorMessage': None, 'rowCount': None, 'expiresAt': None})
page('UsageReport')

# ---------------------------------------------------------------- phân hệ, cờ
obj('ModuleDependency', 'Phụ thuộc của một phân hệ.', 'moduleCode!:mod', 'type!:E:DependencyType', ex={'moduleCode': 'PH-03', 'type': 'REQUIRED'})
obj('PlatformModule', 'Phân hệ của nền tảng (EN-20-18).', 'moduleCode!:mod', ('name!:str', 'Trợ lý AI'), ('core!:bool', False), ('wave:int', 3), ('duCode:str', 'dh-ai'), ('asyncProvision:bool', True),
    ('mergeParticipant:bool', False), ('exportParticipant:bool', False), 'status:E:ModuleStatus', 'dependsOn:R:ModuleDependency[]', ('featureFlags:str[]', ['ph17.enabled']),
    ('tenantCounts:map:int', {'ENABLED': 3, 'DISABLED': 31}), ex={'status': 'AVAILABLE'})
page('PlatformModule', 'ModulePage')
obj('TenantModule', 'Phân hệ của một tenant (EN-20-20).', 'moduleCode!:mod', ('name:str', 'Trợ lý AI'), 'state!:E:ModuleState', ('core:bool', False), 'enabledAt:ts', 'disabledAt:ts', 'stateReason:str',
    'runId:uuid', 'lastReportAt:ts', ex={'state': 'ENABLING', 'enabledAt': None, 'disabledAt': None, 'stateReason': None})
page('TenantModule', 'TenantModulePage')
obj('FeatureFlag', 'Cờ tính năng của tenant (EN-20-21).', 'flagCode!:str', 'moduleCode:mod', 'enabled!:bool', ('rolloutPercent:num', 100), 'validFrom:ts', 'validTo:ts', 'description:str', *AUD, ex={'moduleCode': 'PH-04', 'validTo': None})
page('FeatureFlag', 'FeatureFlagPage')
obj('FlagSetRequest', 'Đặt cờ tính năng (FR-20-036).', 'enabled!:bool', ('validTo:ts', '2027-01-31T00:00:00+07:00'), ('reason!:str', None, {'minLength': 20}), 'ticketRef!:str')

enum('ListFormat', 'Định dạng danh sách.', 'json', 'csv')
enum('TenantInclude', 'Khối trả kèm của chi tiết tenant.', 'summary', 'config', 'contacts', 'modules', 'quotas', 'lastRun')
enum('OrgView', 'Cách hiển thị danh mục tổ chức.', 'TABLE', 'TREE')
enum('OrgExportFormat', 'Định dạng tệp xuất tổ chức.', 'XLSX', 'CSV')
