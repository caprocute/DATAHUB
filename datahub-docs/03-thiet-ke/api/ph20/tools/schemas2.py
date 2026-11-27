"""Lược đồ vòng đời, bàn giao, sáp nhập, tổ chức, phát hành, quản trị, API tenant và API nội bộ (PH-20)."""
from dsl import enum, obj, page, SCH, EX
from schemas1 import AUD

# ---------------------------------------------------------------- vòng đời
obj('LifecycleRequestCreate', 'Lập đề nghị vòng đời (FR-20-038, 039, 040); `requestType` chỉ nhận `SUSPEND`, `RESUME`, `TERMINATE`. `suspendReason` là trường `reason` kiểu `SuspendReason` của FRS, đổi tên để khỏi trùng `reason` văn bản.',
    'requestType!:E:LifecycleRequestType', 'suspendReason:E:SuspendReason', ('reasonText!:str', None, {'minLength': 20, 'maxLength': 1000}), 'ticketRef!:str', 'decisionDocNo:str', 'decisionDocDate:date',
    'decisionFileId:uuid', ('essentialApisAllowed:bool', False), ('scheduledAt:ts', '2026-12-01T08:00:00+07:00'), ('plannedAt:ts', '2027-01-15T08:00:00+07:00'), ('exportRequired:bool', True),
    ex={'requestType': 'SUSPEND', 'suspendReason': 'MANAGEMENT_DECISION'})
obj('LifecycleRequest', 'Đề nghị vòng đời có duyệt (EN-20-22).', 'requestId!:uuid', 'tenantCode!:tc', 'requestType!:E:LifecycleRequestType', 'status!:E:RequestStatus', 'suspendReason:E:SuspendReason',
    'reasonText:str', 'ticketRef:str', 'decisionDocNo:str', 'decisionDocDate:date', 'decisionFileId:uuid', 'essentialApisAllowed:bool', 'scheduledAt:ts', 'plannedAt:ts', 'coolingUntil:ts',
    'exportRequired:bool', 'targetIsolationMode:E:IsolationMode', 'requestedBy!:str', 'requestedAt!:ts', 'approvedBy:str', 'approvedAt:ts', 'decisionNote:str', 'executedAt:ts', 'runId:uuid',
    ('allowedActions:str[]', ['submit', 'cancel']),
    ex={'requestType': 'SUSPEND', 'status': 'DRAFT', 'suspendReason': 'MANAGEMENT_DECISION', 'coolingUntil': None, 'plannedAt': None, 'targetIsolationMode': None, 'approvedBy': None,
        'approvedAt': None, 'decisionNote': None, 'executedAt': None, 'runId': None, 'scheduledAt': None, 'decisionFileId': None})
page('LifecycleRequest')
obj('ExecuteLifecycleRequest', 'Thực hiện đề nghị đã duyệt (FR-20-042).', 'confirmTenantCode!:tc')
obj('ExportPackageCreate', 'Yêu cầu gói bàn giao dữ liệu (FR-20-041).', ('modules:mod[]', ['PH-01', 'PH-06']), ('format:E:ExportFormat', 'JSONL'), ('includeAudit:bool', True))
obj('ExportItem', 'Phần dữ liệu của một phân hệ trong gói (EN-20-24).', 'moduleCode!:mod', ('itemType:str', 'DATA'), 'status!:E:ExportItemStatus', ('rowCount:int', 125000), ('sizeBytes:int', 48213004),
    'sha256:sha', ex={'moduleCode': 'PH-01', 'status': 'DONE'})
obj('ExportPackage', 'Gói bàn giao dữ liệu tenant (EN-20-24).', 'packageId!:uuid', 'tenantCode!:tc', 'requestId:uuid', 'status!:E:ExportPackageStatus', ('format:E:ExportFormat', 'JSONL'),
    ('includeAudit:bool', True), 'items!:R:ExportItem[]', ('itemCount:int', 2), ('sizeBytes:int', 96426008), 'manifestSha256:sha', 'readyAt:ts', 'deliveredAt:ts', 'deliveredTo:str', 'expiresAt:ts',
    'requestedBy:str', ex={'status': 'COLLECTING', 'readyAt': None, 'deliveredAt': None, 'deliveredTo': None, 'expiresAt': None, 'manifestSha256': None, 'sizeBytes': None})
page('ExportPackage')
obj('IssueLinkRequest', 'Cấp liên kết tải có thời hạn (FR-20-041).', 'recipientEmail!:email', ('expiresHours:int', 48, {'minimum': 1, 'maximum': 72}))
obj('ExportDownloadLink', 'Liên kết tải gói bàn giao.', 'packageId!:uuid', 'downloadUrl!:url', 'expiresAt!:ts', 'recipientEmail!:email')
obj('ConfirmDeliveryRequest', 'Ghi nhận đã bàn giao (FR-20-041).', 'handoverDocFileId!:uuid', 'deliveredAt!:ts', 'deliveredTo:str')
obj('StatusCause', 'Nguyên nhân đổi trạng thái.', ('type!:str', 'LIFECYCLE_REQUEST'), 'id!:str', ex={'id': '0193c2a0-1a2b-7c3d-8e4f-5a6b7c8d9e02'})
obj('StatusHistoryEntry', 'Một dòng lịch sử trạng thái (EN-20-23).', ('from:E:TenantStatus', 'PROVISIONING'), 'to!:E:TenantStatus', ('at!:ts',), 'cause:R:StatusCause', 'actor:str',
    'decisionDocNo:str', 'reason:str', 'ticketRef:str', 'notificationStatus:E:NotificationStatus', ex={'to': 'ACTIVE', 'from': 'PROVISIONING', 'notificationStatus': 'SENT'})
page('StatusHistoryEntry', 'StatusHistoryPage')

# ---------------------------------------------------------------- sáp nhập
obj('MergePlanCreate', 'Lập kế hoạch sáp nhập (FR-20-045).', ('name:str', 'Sáp nhập T91 vào T90'), ('sourceTenants!:tc[]', ['T91'], {'minItems': 1, 'maxItems': 1}), ('targetTenant!:tc', 'T90'),
    ('decisionDocNo!:str', '1234/QĐ-TTg'), ('decisionDocDate!:date', '2026-10-15'), 'decisionFileId:uuid', ('effectiveDate!:date', '2026-12-15'), ('transitionMonths:int', 6, {'minimum': 1, 'maximum': 12}),
    ('modules:mod[]', ['PH-01', 'PH-03', 'PH-06']))
obj('MergePlanUpdate', 'Sửa kế hoạch `DRAFT`.', 'name:str', ('effectiveDate:date', '2026-12-20'), ('transitionMonths:int', 6, {'minimum': 1, 'maximum': 12}), ('modules:mod[]', ['PH-01', 'PH-03']),
    'decisionDocNo:str', 'decisionDocDate:date', 'decisionFileId:uuid')
obj('DryRunModule', 'Kết quả chạy thử của một phân hệ.', 'module!:mod', ('records!:int', 12500), ('conflicts!:int', 3), ('estimatedMinutes:int', 35))
obj('DryRunSummary', 'Kết quả chạy thử sáp nhập.', ('result!:str', 'PASSED', {'enum': ['PASSED', 'FAILED', 'RUNNING']}), 'modules!:R:DryRunModule[]', 'mappingHash:sha', 'ranAt:ts', ('stale:bool', False))
obj('MergeProgress', 'Tiến độ tổng của sáp nhập.', ('modulesTotal!:int', 3), ('modulesDone!:int', 1), ('conflictsOpen!:int', 2))
obj('MergePlan', 'Kế hoạch sáp nhập (EN-20-25).', 'mergePlanId!:str', 'name:str', 'status!:E:MergeStatus', ('sourceTenants!:tc[]', ['T91']), ('targetTenant!:tc', 'T90'), 'decisionDocNo:str',
    'decisionDocDate:date', 'effectiveDate:date', ('transitionMonths:int', 6), ('modules:mod[]', ['PH-01', 'PH-03', 'PH-06']), 'ticketRef:str', 'requestedBy:str', 'approvedBy:str', 'approvedAt:ts',
    'dryRun:R:DryRunSummary', 'progress:R:MergeProgress', 'startedAt:ts', 'cutoverAt:ts', 'transitionEndsAt:ts', 'completedAt:ts', ('allowedActions:str[]', ['submit', 'cancel']), *AUD,
    ex={'status': 'DRAFT', 'approvedBy': None, 'approvedAt': None, 'dryRun': None, 'progress': None, 'startedAt': None, 'cutoverAt': None, 'transitionEndsAt': None, 'completedAt': None, 'ticketRef': None})
page('MergePlan')
obj('MappingItem', 'Dòng ánh xạ sáp nhập (EN-20-26).', 'mappingId!:uuid', 'mappingType!:E:MergeMappingType', 'sourceCode!:str', 'targetCode:str', 'action!:E:MergeMappingAction',
    'status:E:MappingStatus', ('origin:E:MappingOrigin', 'AUTO'), ('required:bool', True), 'note:str', ex={'mappingType': 'MEMBER_SYSTEM', 'action': 'MAP', 'status': 'PROPOSED'})
obj('MappingPage', 'Bảng ánh xạ và thống kê theo loại.', 'items!:R:MappingItem[]', ('summary:map:int', {'MEMBER_SYSTEM': 40, 'ORGANIZATION': 25}), 'page!:int', 'size!:int', 'totalElements!:int')
obj('MappingUpdate', 'Sửa một dòng ánh xạ (FR-20-046).', 'targetCode:str', 'action!:E:MergeMappingAction', ('note:str', 'Ánh xạ theo văn bản hợp nhất đơn vị.'), ex={'action': 'MAP'})
obj('MappingSuggestResult', 'Kết quả sinh gợi ý ánh xạ.', ('created!:int', 65), ('summary:map:int', {'MEMBER_SYSTEM': 40, 'ORGANIZATION': 25}), ('conflicts:int', 3))
obj('DryRunRequest', 'Chạy thử sáp nhập (FR-20-047).', ('modules:mod[]', ['PH-01', 'PH-03']))
obj('MergeParticipantRun', 'Lần chuyển dữ liệu của một phân hệ (EN-20-27).', 'module!:mod', 'phase!:E:ParticipantPhase', 'status!:E:ParticipantStatus', ('attempt:int', 1),
    ('exportedCount:int', 12500), ('importedCount:int', 12500), ('verifiedCount:int', 12500), ('conflictCount:int', 3), 'transferRef:str', 'startedAt:ts', 'finishedAt:ts',
    ('errorCode:str', None, {'pattern': '^ERR-20-[0-9]{3}$'}), 'errorMessage:str', ex={'phase': 'TRANSFER', 'status': 'RUNNING', 'finishedAt': None, 'errorCode': None, 'errorMessage': None, 'transferRef': 'mt-2026-0007'})
page('MergeParticipantRun', 'ParticipantPage')
obj('MergeConflict', 'Xung đột sáp nhập (EN-20-28).', 'conflictId!:uuid', 'mappingType!:E:MergeMappingType', ('module:mod', 'PH-02'), 'sourceCode!:str', 'targetCode:str', 'conflictKind!:E:ConflictKind',
    'state!:E:ConflictState', 'resolution:E:ConflictResolution', 'resolvedBy:str', 'resolvedAt:ts', 'comment:str',
    ex={'mappingType': 'API_CONTEXT_PATH', 'sourceCode': '/ho-tich', 'targetCode': '/ho-tich', 'conflictKind': 'DUPLICATE_PATH', 'state': 'OPEN', 'resolution': None, 'resolvedBy': None, 'resolvedAt': None, 'comment': None})
page('MergeConflict', 'ConflictPage')
obj('ConflictResolveRequest', 'Quyết định một xung đột (FR-20-049).', 'resolution!:E:ConflictResolution', ('newCode:str', 'ho-tich-t91'), ('comment:str', 'Đổi tên đường dẫn nguồn để tránh trùng.'), ex={'resolution': 'RENAME_SOURCE'})
obj('BatchResolveRequest', 'Quyết định hàng loạt.', ('conflictIds!:uuid[]', ['0193c2a0-1a2b-7c3d-8e4f-5a6b7c8d9e0b'], {'minItems': 1, 'maxItems': 200}), 'resolution!:E:ConflictResolution', 'newCode:str', 'comment:str', ex={'resolution': 'KEEP_TARGET'})
obj('BatchFailure', 'Xung đột không quyết định được.', 'conflictId!:uuid', ('code!:str', 'ERR-20-044'))
obj('BatchResolveResult', 'Kết quả quyết định hàng loạt.', ('resolved!:int', 1), 'failed!:R:BatchFailure[]', ('openRemaining!:int', 1), ex={'failed': []})
obj('TransferIdentityRequest', 'Chuyển định danh (FR-20-050).', ('notifyUsers:bool', True))
obj('CredentialStatus', 'Thông tin xác thực song song của một HTTT (không chứa giá trị bí mật).', 'memberSystemCode!:str', 'newClientId!:str', 'status!:E:ParallelCredentialStatus', 'lastCallOld:ts', 'lastCallNew:ts', ex={'status': 'ACTIVE_PARALLEL'})
page('CredentialStatus', 'CredentialPage')
obj('CutoverRequest', 'Chuyển tiếp, nguồn sang `MERGED` (FR-20-051).', 'confirmCode!:str', ('reason!:str', None, {'minLength': 20}), 'ticketRef!:str')
obj('ExtendTransitionRequest', 'Gia hạn thời gian chuyển tiếp (FR-20-052).', ('extendMonths!:int', 3, {'minimum': 1, 'maximum': 12}), ('reason!:str', None, {'minLength': 20}), 'ticketRef!:str')
obj('CompleteMergeRequest', 'Kết thúc sáp nhập.', 'confirmCode!:str')

# ---------------------------------------------------------------- tổ chức
ORG = ['orgCode!:ocode', ('name!:str', 'Sở Khoa học và Công nghệ'), ('shortName:str', 'Sở KH&CN'), ('parentCode:ocode', 'UBND-TINH'), 'orgType!:E:OrgType', 'adminUnitId:uuid', 'electronicId:str',
       ('effectiveFrom!:date', '2025-07-01'), 'effectiveTo:date', 'sortOrder:int', 'note:str']
obj('OrganizationCreate', 'Tạo tổ chức (FR-20-053).', *[x if not (isinstance(x, str) and x.startswith('adminUnitId')) and not (isinstance(x, tuple) and x[0].startswith('adminUnitId')) else 'adminUnitId!:uuid' for x in ORG],
    ('isDataOwner:bool', False), ex={'orgType': 'DEPARTMENT', 'effectiveTo': None, 'sortOrder': 7})
obj('OrganizationUpdate', 'Sửa tổ chức (FR-20-053).', ('name:str', 'Sở Khoa học và Công nghệ'), 'shortName:str', ('parentCode:ocode', 'UBND-TINH'), 'orgType:E:OrgType', 'electronicId:str',
    'sortOrder:int', 'note:str', ('reason:str', None, {'minLength': 20}), ex={'orgType': 'DEPARTMENT'})
obj('Organization', 'Tổ chức (EN-20-02, DD-02).', *ORG, 'status!:E:OrgStatus', ('isDataOwner!:bool', False), ('dataDomains:str[]', ['ho-tich']), 'successorCode:ocode', 'externalCode:str', ('childCount:int', 4), *AUD,
    ex={'orgType': 'DEPARTMENT', 'status': 'ACTIVE', 'effectiveTo': None, 'successorCode': None, 'adminUnitId': '0193a000-1111-7000-8000-000000000068'})
obj('OrganizationNode', 'Nút của cây tổ chức.', 'orgCode!:ocode', 'name!:str', 'orgType!:E:OrgType', 'status!:E:OrgStatus', ('children:obj[]', []), ex={'orgType': 'DEPARTMENT', 'status': 'ACTIVE'})
obj('OrganizationPage', 'Danh mục tổ chức dạng bảng (`items`) hoặc cây (`tree`).', 'items!:R:Organization[]', 'tree:R:OrganizationNode[]', 'page!:int', 'size!:int', 'totalElements!:int')
obj('OrgDeactivateRequest', 'Ngừng tổ chức (FR-20-054).', ('effectiveTo:date', '2026-12-31'), ('reason!:str', None, {'minLength': 20}))
obj('OrgDissolveRequest', 'Giải thể tổ chức có tổ chức kế thừa.', ('effectiveTo!:date', '2026-12-31'), ('successorCode:ocode', 'SO-TTTT'), ('decisionDocNo:str', '45/QĐ-UBND'),
    ('decisionDocDate:date', '2026-11-20'), ('reason!:str', None, {'minLength': 20}))
obj('OrgMergeRequest', 'Sáp nhập nhiều tổ chức vào một tổ chức.', ('sourceCodes!:ocode[]', ['SO-KHCN', 'SO-TTTT'], {'minItems': 1}), ('targetCode!:ocode', 'SO-KHCN-MOI'), 'createTarget:R:OrganizationCreate',
    ('effectiveTo!:date', '2026-12-31'), ('decisionDocNo:str', '45/QĐ-UBND'), ('decisionDocDate:date', '2026-11-20'), ('reason!:str', None, {'minLength': 20}),
    ex={'createTarget': None})
obj('OrgMoved', 'Tổ chức con đã chuyển cấp trên.', 'orgCode!:ocode', ('newParentCode!:ocode', 'SO-KHCN-MOI'))
obj('OrgMergeResult', 'Kết quả sáp nhập tổ chức.', 'target!:R:Organization', ('mergedCodes!:ocode[]', ['SO-KHCN', 'SO-TTTT']), 'movedChildren!:R:OrgMoved[]', ('referencesRebound:int', 12))
obj('OrgHistoryEntry', 'Một dòng lịch sử tổ chức.', 'at!:ts', 'action!:E:OrgHistoryAction', ('from:E:OrgStatus', 'ACTIVE'), ('to:E:OrgStatus', 'DISSOLVED'), 'actor:str', 'successorCode:ocode', 'decisionDocNo:str',
    'reason:str', ex={'action': 'DISSOLVED', 'from': 'ACTIVE', 'to': 'DISSOLVED', 'successorCode': 'SO-TTTT'})
page('OrgHistoryEntry', 'OrgHistoryPage')
obj('DataOwnerRequest', 'Đánh dấu chủ quản dữ liệu (FR-20-058).', 'isDataOwner!:bool', ('dataDomains:str[]', ['ho-tich', 'dat-dai']), ('reason:str', None, {'minLength': 20}))
obj('OrgImportUpload', 'Tệp nhập tổ chức (multipart).', 'file!:bin', ('mode:E:ImportMode', 'UPSERT'), ex={'mode': 'UPSERT'})
obj('ImportRow', 'Một dòng của lô nhập.', ('rowNo!:int', 2), ('orgCode:ocode', 'SO-KHCN'), 'action!:E:ImportAction', 'errors:R:FieldError[]', ex={'action': 'CREATE', 'errors': []})
obj('OrgImportJob', 'Lô nhập tổ chức (EN-20-30), kèm các dòng của trang yêu cầu.', 'importId!:uuid', 'status!:E:ImportStatus', 'mode!:E:ImportMode', ('fileName:str', 'to-chuc.xlsx'),
    ('totalRows!:int', 120), ('validRows!:int', 118), ('errorRows!:int', 2), ('appliedRows:int', 0), 'previewExpiresAt:ts', 'appliedAt:ts', ('errorFileUrl:url',), 'rows:R:ImportRow[]',
    ('summary:map:int', {'CREATE': 100, 'UPDATE': 18, 'ERROR': 2}), ('page:int', 0), ('size:int', 50), ('totalElements:int', 120),
    ex={'status': 'PREVIEWED', 'mode': 'UPSERT', 'appliedAt': None})
obj('SyncProposal', 'Đề xuất đồng bộ tổ chức khi sắp xếp ĐVHC (FR-20-056).', 'proposalId!:uuid', 'state!:E:ProposalState', ('adminUnitOld:str', 'XA-0101'), ('adminUnitNew:str', 'XA-0105'),
    'effectiveDate:date', ('decisionDoc:str', '12/NQ-HĐND'), ('suggestedAction:str', 'Sáp nhập hai tổ chức cấp xã thành một'), ('orgCodes:ocode[]', ['UBND-XA-A', 'UBND-XA-B']),
    ('suggestedCode:ocode', 'UBND-XA-AB'), ('suggestedName:str', 'UBND xã A-B'), ex={'state': 'PENDING'})
page('SyncProposal', 'SyncProposalPage')
obj('DecideProposalRequest', 'Áp hoặc bỏ đề xuất đồng bộ.', 'decision!:E:ProposalDecision', ('name:str', 'UBND xã A-B'), ('orgCode:ocode', 'UBND-XA-AB'), ('reason:str', None, {'minLength': 20}), ex={'decision': 'APPLY'})

# ---------------------------------------------------------------- phát hành
obj('ReleaseComponent', 'Thành phần của phiên bản sản phẩm.', 'du!:str', 'image!:str', 'digest!:str', ('chartVersion:str', '2.4.0'), ('migrationRequired:bool', True))
obj('SchemaChange', 'Thay đổi lược đồ CSDL của phiên bản.', 'module!:mod', 'kind!:E:SchemaChangeKind', ex={'kind': 'EXPAND'})
obj('ReleaseCreate', 'Đăng ký phiên bản sản phẩm `DRAFT` (FR-20-059).', 'releaseVersion!:ver', ('name:str', 'Datahub 2.4 Đợt cuối năm 2026'), ('components!:R:ReleaseComponent[]', None, {'minItems': 1}), 'schemaChanges:R:SchemaChange[]',
    ('releaseNotes!:str', 'Bổ sung nâng cấp theo sóng, sửa lỗi lệch cấu hình.'), 'minFromVersion:ver', ('breakingChange:bool', False))
obj('Release', 'Phiên bản sản phẩm (EN-20-31).', 'releaseVersion!:ver', ('name:str', 'Datahub 2.4 Đợt cuối năm 2026'), 'status!:E:ReleaseStatus', 'releaseNotes:str', ('breakingChange!:bool', False), 'minFromVersion:ver',
    'components:R:ReleaseComponent[]', 'schemaChanges:R:SchemaChange[]', 'previewAt:ts', 'stableAt:ts', 'deprecatedAt:ts', 'withdrawnAt:ts', 'withdrawnReason:str', *AUD,
    ex={'status': 'PREVIEW', 'stableAt': None, 'deprecatedAt': None, 'withdrawnAt': None, 'withdrawnReason': None})
page('Release')
obj('TenantRunning', 'Tenant đang chạy một phiên bản.', 'tenantCode!:tc', 'channel!:E:ReleaseChannel', ('pilot:bool', True), ex={'channel': 'PREVIEW'})
obj('ReleaseDetail', 'Chi tiết phiên bản kèm tenant đang chạy.', 'releaseVersion!:ver', 'name:str', 'status!:E:ReleaseStatus', 'releaseNotes:str', ('breakingChange!:bool', False), 'minFromVersion:ver',
    'components:R:ReleaseComponent[]', 'schemaChanges:R:SchemaChange[]', 'previewAt:ts', 'stableAt:ts', ('soakDaysDone:int', 9), 'tenantsRunning:R:TenantRunning[]', *AUD, ex={'status': 'PREVIEW', 'stableAt': None})
obj('ReleaseUpdate', 'Sửa ghi chú phát hành (FR-20-059).', ('releaseNotes!:str', 'Bổ sung hướng dẫn quay lui và danh sách sửa lỗi.'), ('reason:str', None, {'minLength': 20}))
obj('SubscriptionSetRequest', 'Đổi kênh, môi trường đăng ký (FR-20-060).', 'channel!:E:ReleaseChannel', 'environment!:E:ReleaseEnvironment', ('reason!:str', None, {'minLength': 20}), ex={'channel': 'STABLE', 'environment': 'STAGING'})
obj('ReleaseSubscription', 'Đăng ký kênh của tenant (EN-20-32).', 'tenantCode!:tc', 'channel!:E:ReleaseChannel', 'environment!:E:ReleaseEnvironment', ('pinnedVersion:ver', '2.3.1'), 'currentVersion:ver',
    ('isPilot:bool', False), 'subscribedAt:ts', ex={'channel': 'STABLE', 'environment': 'PROD', 'pinnedVersion': None})
obj('WaveInput', 'Một sóng nâng cấp khi lập kế hoạch.', ('waveNo!:int', 1, {'minimum': 1}), ('tenantCodes!:tc[]', ['T90', 'T91'], {'minItems': 1}))
obj('UpgradePlanCreate', 'Lập kế hoạch nâng cấp theo sóng (FR-20-061).', ('waves!:R:WaveInput[]', None, {'minItems': 1}), ('soakHours:int', 48), ('startAfter:ts', '2026-12-05T22:00:00+07:00'),
    ('emergency:bool', False), ('errorThresholdPercent:num', 2.0), ('ticketRef:str',))
obj('UpgradePlanUpdate', 'Sửa kế hoạch `DRAFT`.', 'waves:R:WaveInput[]', ('soakHours:int', 48), ('startAfter:ts', '2026-12-05T22:00:00+07:00'), ('emergency:bool', False), ('errorThresholdPercent:num', 2.0))
obj('UpgradeWave', 'Sóng nâng cấp (EN-20-34).', ('waveNo!:int', 1), ('name:str', 'Sóng 1: tenant kiểm thử'), 'status!:E:WaveStatus', ('tenantCount!:int', 2), 'plannedStart:ts', 'startedAt:ts', 'finishedAt:ts',
    ('errorPercent:num', 0.0), ex={'status': 'PENDING', 'startedAt': None, 'finishedAt': None})
obj('UpgradeProgress', 'Tiến độ tổng của kế hoạch.', ('total!:int', 33), ('done!:int', 2), ('failed!:int', 0), ('pending!:int', 31))
obj('UpgradePlan', 'Kế hoạch nâng cấp (EN-20-34).', 'planId!:uuid', ('releaseVersion!:ver', '2.4.0'), 'channel!:E:ReleaseChannel', 'status!:E:UpgradePlanStatus', 'waves!:R:UpgradeWave[]', ('soakHours:int', 48),
    ('errorThresholdPercent:num', 2.0), ('emergency:bool', False), 'scheduledAt:ts', 'startedAt:ts', 'completedAt:ts', 'pauseReason:str', 'progress:R:UpgradeProgress', *AUD,
    ex={'channel': 'PREVIEW', 'status': 'DRAFT', 'scheduledAt': None, 'startedAt': None, 'completedAt': None, 'pauseReason': None, 'progress': None})
obj('RollbackRequest', 'Quay lui nâng cấp (FR-20-062).', ('tenantCodes!:tc[]', ['T90'], {'minItems': 1}), ('reason!:str', None, {'minLength': 20}), 'ticketRef!:str')
obj('TenantUpgrade', 'Nâng cấp theo tenant (EN-20-35).', 'tenantCode!:tc', ('waveNo:int', 1), 'status!:E:TenantUpgradeStatus', ('windowName:str', 'Thứ Bảy 22:00'), 'scheduledFor:ts', 'startedAt:ts', 'verifiedAt:ts',
    'finishedAt:ts', ('attempt:int', 1), ('errorCode:str', None, {'pattern': '^ERR-20-[0-9]{3}$'}), 'errorMessage:str', ('rollbackVersion:ver', '2.3.1'),
    ex={'status': 'PENDING', 'startedAt': None, 'verifiedAt': None, 'finishedAt': None, 'errorCode': None, 'errorMessage': None, 'rollbackVersion': None})
page('TenantUpgrade', 'TenantUpgradePage')
obj('AnnounceRequest', 'Gửi thông báo phát hành, lịch bảo trì (FR-20-063).', 'planId:uuid', 'audience!:E:Audience', ('message:str',), ex={'audience': 'TA'})
obj('AnnounceResult', 'Kết quả gửi thông báo.', 'announcementId!:uuid', ('recipients!:int', 33), ('status!:str', 'QUEUED'))

# ---------------------------------------------------------------- bảng điều khiển, kiểm toán, tham số, rò rỉ
obj('DashboardAlerts', 'Cảnh báo hạn mức đang mở.', ('warn!:int', 4), ('limit!:int', 1))
obj('DashboardUpgrades', 'Nâng cấp đang chạy.', ('running!:int', 2), ('failed!:int', 0))
obj('DashboardLeak', 'Lần kiểm thử rò rỉ gần nhất.', 'lastRunAt:ts', ('status:E:LeakStatus', 'PASSED'))
obj('DashboardCapacity', 'Sức chứa nền tảng (NFR-00-060).', ('provinceTenants!:int', 33), ('limit!:int', 40), ('percent!:num', 82.5))
obj('DashboardKpi12', 'Thời gian khởi tạo (KPI-12).', ('medianMinutes:num', 52.0), ('p95Minutes:num', 118.0))
obj('PlatformDashboard', 'Bảng điều khiển nền tảng đa tenant (FR-20-067).', 'generatedAt!:ts', 'environment!:str', ('tenantsByStatus!:map:int', {'ACTIVE': 31, 'PROVISIONING': 1, 'SUSPENDED': 1}),
    ('runsInProgress!:int', 1), 'openAlerts!:R:DashboardAlerts', ('driftedTenants!:int', 1), 'upgrades!:R:DashboardUpgrades', ('mergesInProgress!:int', 0), 'leakTest:R:DashboardLeak', 'capacity!:R:DashboardCapacity',
    'kpi12:R:DashboardKpi12', ex={'environment': 'PROD'})
obj('AuditEvent', 'Sự kiện kiểm toán thao tác PH-20.', 'eventId!:uuid', 'at!:ts', 'actor!:str', 'actorRole:str', 'action!:str', 'tenantCode:tc', 'objectType:str', 'objectId:str', 'reason:str', 'ticketRef:str',
    ('result:str', 'SUCCESS'), 'traceId:str')
page('AuditEvent', 'AuditEventPage')
obj('ParameterValue', 'Giá trị hiệu lực của tham số `20.*` (do PH-18 sở hữu).', ('paramName!:str', '20.quota.warn-percent'), ('effectiveValue!:str', '80'), ('defaultValue!:str', '80'), ('domain:str', '50…95'),
    ('usedBy:str', 'FR-20-029'), ex={})
page('ParameterValue', 'ParameterPage')
obj('LeakTestCreate', 'Chạy kiểm thử rò rỉ chéo tenant (FR-20-070).', ('sourceTenant!:tc', 'T90'), ('targetTenant!:tc', 'T91'), ('apiScope:str[]', ['ALL']))
obj('LeakCase', 'Một ca kiểm thử rò rỉ.', ('apiCode!:str', 'API-20-003'), 'method!:str', 'path!:str', ('result!:str', 'PASS', {'enum': ['PASS', 'FAIL']}), ('httpStatus:int', 404), 'detail:str')
obj('LeakTestRun', 'Lần kiểm thử rò rỉ chéo (EN-20-36).', 'testRunId!:uuid', 'triggerType!:E:LeakTrigger', 'status!:E:LeakStatus', ('sourceTenant!:tc', 'T90'), ('targetTenant!:tc', 'T91'),
    ('casesTotal!:int', 171), ('casesFailed!:int', 0), 'startedAt!:ts', 'finishedAt:ts', 'cases:R:LeakCase[]', ex={'triggerType': 'MANUAL', 'status': 'RUNNING', 'finishedAt': None, 'cases': []})
page('LeakTestRun', 'LeakTestPage')

# ---------------------------------------------------------------- API tenant (/api/tenant/v1)
obj('MaintenanceWindowPref', 'Cửa sổ bảo trì ưa thích.', 'rrule!:str', 'startTime!:str', ('durationHours!:int', 4, {'minimum': 2, 'maximum': 6}), 'timezone!:str')
SET = [('displayName!:str', 'Datahub tỉnh T68'), 'logoFileId:uuid', 'itOwnerOrgCode!:ocode', ('sessionIdleMinutes!:int', 15, {'minimum': 5, 'maximum': 15}), ('passwordMinLength!:int', 14, {'minimum': 14, 'maximum': 64}),
       ('mfaRequiredRoles!:str[]', ['ROLE-TENANT_ADMIN', 'ROLE-SECURITY_OFFICER']), 'maintenanceWindowPref!:R:MaintenanceWindowPref', 'supportContactEmail:email', 'hotline:str']
obj('TenantSettings', 'Cài đặt tỉnh (EN-20-06).', *SET, ('configVersionNo:int', 8), *AUD, ex={'maintenanceWindowPref': {'rrule': 'FREQ=WEEKLY;BYDAY=SA', 'startTime': '22:00', 'durationHours': 4, 'timezone': 'Asia/Ho_Chi_Minh'}})
obj('TenantSettingsUpdate', 'Sửa cài đặt tỉnh (FR-20-018), trong giới hạn nền tảng (ERR-20-023).', *SET, ex={'maintenanceWindowPref': {'rrule': 'FREQ=WEEKLY;BYDAY=SA', 'startTime': '22:00', 'durationHours': 4, 'timezone': 'Asia/Ho_Chi_Minh'}})
POL = [('allowRead!:bool', True), ('allowWrite!:bool', False), ('requirePriorApproval!:bool', True), ('maxHours!:int', 4, {'minimum': 1, 'maximum': 4}), ('notifyContacts:email[]', ['cong-vu@t68.example.vn']),
       ('blockedReasons:str[]', ['THUONG_MAI'])]
obj('CrossTenantPolicy', 'Chính sách tiếp nhận truy cập liên tenant (EN-20-29).', *POL, 'effectiveFrom:ts', *AUD)
obj('CrossTenantPolicyUpdate', 'Sửa chính sách tiếp nhận (FR-20-023).', *POL)
obj('CrossTenantAccess', 'Một lượt truy cập liên tenant vào tỉnh.', 'accessId!:uuid', 'at!:ts', ('actor!:str', 'cb.nen.tang'), ('actorTenant!:tc', 'T90'), ('reasonType:str', 'HO_TRO_VAN_HANH'), 'ticketRef:str',
    'access!:E:AccessKind', ('apiCode:str', 'API-20-003'), ('objectRef:str', 'tenant/T68'), ('result:str', 'SUCCESS'), ex={'accessId': '0193c2a0-1a2b-7c3d-8e4f-5a6b7c8d9e20', 'access': 'READ'})
page('CrossTenantAccess', 'CrossTenantAccessPage')
obj('QuotaView', 'Hạn mức hiệu lực và cảnh báo của tỉnh.', 'tenantCode!:tc', 'items!:R:QuotaItem[]', 'alerts!:R:QuotaAlert[]')
obj('TenantModuleState', 'Trạng thái một phân hệ cho giao diện.', 'moduleCode!:mod', 'state!:E:ModuleState', ex={'state': 'ENABLED'})
obj('Banner', 'Dải thông báo trên giao diện.', 'type!:E:BannerType', ('message!:str', 'Hệ thống sẽ bảo trì từ 22:00 thứ Bảy.'), 'until:ts', ('link:str', '/quan-tri/cai-dat-tinh'), ex={'type': 'INFO'})
obj('TenantContext', 'Trạng thái tenant cho `dh-console` (FR-20-037, 066).', 'tenantCode!:tc', 'name:str', 'status!:E:TenantStatus', ('readOnly!:bool', False), 'modules!:R:TenantModuleState[]',
    ('featureFlags:map:bool', {'ph04.sql-direct': False}), 'banner:R:Banner', 'currentVersion:ver', ex={'status': 'ACTIVE', 'modules': [{'moduleCode': 'PH-01', 'state': 'ENABLED'}]})
obj('MaintenanceSlot', 'Một lịch bảo trì sắp tới.', 'startsAt!:ts', 'endsAt!:ts', ('release:ver', '2.4.0'), 'note:str')
obj('TenantReleaseInfo', 'Phiên bản, ghi chú, lịch bảo trì của tỉnh (FR-20-064).', ('currentVersion!:ver', '2.3.1'), 'channel:E:ReleaseChannel', 'releaseNotes:str', 'releasedAt:ts',
    'nextMaintenance:R:MaintenanceSlot', 'maintenanceWindowPref:R:MaintenanceWindowPref', ex={'channel': 'STABLE', 'maintenanceWindowPref': {'rrule': 'FREQ=WEEKLY;BYDAY=SA', 'startTime': '22:00', 'durationHours': 4, 'timezone': 'Asia/Ho_Chi_Minh'}})
obj('MaintenanceWindowSet', 'Đặt cửa sổ bảo trì ưa thích (FR-20-018, 061).', ('dayOfWeek!:int', 6, {'minimum': 1, 'maximum': 7}), ('startTime!:str', '22:00', {'pattern': '^[0-2][0-9]:[0-5][0-9]$'}),
    ('durationHours!:int', 4, {'minimum': 2, 'maximum': 6}), ('timezone:str', 'Asia/Ho_Chi_Minh'))
obj('MaintenanceWindow', 'Cửa sổ bảo trì của tỉnh (EN-20-33).', ('dayOfWeek!:int', 6), ('startTime!:str', '22:00'), ('durationHours!:int', 4), 'timezone!:str', 'updatedAt:ts')

# ---------------------------------------------------------------- API nội bộ (/internal/tenant/v1)
obj('RegistryModule', 'Phân hệ đang bật của tenant trong registry.', 'moduleCode!:mod', 'state!:E:ModuleState', ex={'state': 'ENABLED'})
obj('RegistryTenant', 'Bản ghi registry tenant (FR-20-065).', 'tenantCode!:tc', 'tenantId!:uuid', 'status!:E:TenantStatus', 'kind:E:TenantKind', 'isolationMode!:E:IsolationMode', 'realm!:str',
    ('hosts!:str[]', ['api.t68.datahub.example.vn']), 'apiPrefix:str', 'modules:R:RegistryModule[]', ('configVersion:int', 8), 'updatedAt:ts',
    ex={'status': 'ACTIVE', 'kind': 'PROVINCE', 'isolationMode': 'SHARED', 'apiPrefix': '/t68', 'modules': [{'moduleCode': 'PH-01', 'state': 'ENABLED'}]})
page('RegistryTenant', 'RegistryPage')
obj('QuotaEnforcement', 'Hạn mức hiệu lực để thực thi.', 'resource!:E:QuotaResource', ('effectiveValue!:num', 800), 'unit:str')
obj('MergeRedirect', 'Ánh xạ chuyển tiếp khi tenant nguồn `MERGED`.', ('fromPrefix!:str', '/t91'), ('toTenant!:tc', 'T90'), ('toPrefix!:str', '/t90'), 'sunsetAt:ts')
obj('EnforcementConfig', 'Cấu hình thực thi cho PH-03, PH-04, PH-10 (FR-20-066).', 'tenantCode!:tc', 'status!:E:TenantStatus', ('hosts!:str[]', ['api.t68.datahub.example.vn']), 'apiPrefix:str',
    'quotas!:R:QuotaEnforcement[]', 'redirects:R:MergeRedirect[]', ('configVersion!:int', 8), ('essentialApisAllowed:bool', False), ex={'status': 'ACTIVE', 'apiPrefix': '/t68'})
obj('StepReport', 'Phân hệ báo kết quả bước saga bất đồng bộ (FR-20-008).', 'status!:E:StepReportStatus', ('attempt:int', 1), ('errorCode:str', None, {'pattern': '^[A-Za-z0-9-]{3,32}$'}), 'errorMessage:str',
    'outputRef:str', ('detail:obj', {'topicsCreated': 12}), ex={'status': 'SUCCEEDED', 'errorCode': None, 'errorMessage': None, 'outputRef': 'kv/dh/t68/eventing'})
obj('ReportAck', 'Xác nhận đã nhận báo cáo tiến độ.', 'accepted!:bool', ('stepStatus:str', 'SUCCEEDED'), ('runStatus:str', 'RUNNING'), ('message:str', 'Đã ghi tiến độ.'))
obj('ParticipantReport', 'Phân hệ hoặc PH-18 báo tiến độ chuyển sáp nhập (FR-20-048).', 'phase!:E:ParticipantPhase', 'status!:E:ParticipantStatus', ('exportedCount:int', 12500), ('importedCount:int', 12500),
    ('verifiedCount:int', 12500), ('conflictCount:int', 3), ('transferRef:str', 'mt-2026-0007'), ('errorCode:str', None, {'pattern': '^[A-Za-z0-9-]{3,32}$'}), 'errorMessage:str',
    ex={'phase': 'TRANSFER', 'status': 'SUCCEEDED', 'errorCode': None, 'errorMessage': None})
obj('ExportItemReport', 'Phân hệ báo đã xuất phần dữ liệu của mình (FR-20-041).', 'status!:E:ExportItemStatus', ('itemType:str', 'DATA'), ('rowCount:int', 125000), ('sizeBytes:int', 48213004), 'sha256:sha',
    'fileId:uuid', ('errorMessage:str', None), ex={'status': 'DONE', 'errorMessage': None})
obj('OrganizationRef', 'Tổ chức cho phân hệ đọc (FR-20-057), có tổ chức kế thừa đã giải.', 'orgCode!:ocode', 'name!:str', 'orgType!:E:OrgType', ('parentCode:ocode', 'UBND-TINH'), 'adminUnitId:uuid',
    'status!:E:OrgStatus', ('isDataOwner!:bool', False), ('effectiveFrom:date', '2025-07-01'), 'effectiveTo:date', 'successorCode:ocode', 'resolvedSuccessor:ocode',
    ex={'name': 'Sở Khoa học và Công nghệ', 'orgType': 'DEPARTMENT', 'status': 'ACTIVE', 'effectiveTo': None, 'successorCode': None, 'resolvedSuccessor': None})
page('OrganizationRef', 'OrganizationRefPage')
obj('OrgLookupRequest', 'Tra hàng loạt tổ chức (FR-20-057, 058).', ('codes!:ocode[]', ['SO-KHCN', 'UBND-TINH'], {'minItems': 1, 'maxItems': 500}), ('asOf:date', '2026-11-27'))
obj('OrgLookupResult', 'Kết quả tra hàng loạt.', 'items!:R:OrganizationRef[]', ('notFound!:ocode[]', []))
