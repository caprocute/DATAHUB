#!/usr/bin/env python3
"""Lược đồ thành phần (components.schemas) của OpenAPI PH-18, viết bằng DSL ngắn của dsl18.py.

Tên trường theo FRS D02-03-PH18 (§6 "Đầu vào", "Đầu ra", bảng dữ liệu vào); khi FRS chưa nêu thì lấy camelCase của cột
DDL `ph18_ops.sql`. FRS thắng khi lệch DDL (các điểm lệch ghi ở D03-04-PH18 §10.1).
Không trường nào mang giá trị bí mật: thông tin kết nối là `credentialRef` (đường dẫn OpenBao `kv/dh/{tenant}/...`),
địa chỉ người nhận chỉ ở dạng đã che (`recipientMasked`), payload DLQ chỉ trả qua API-18-047 có lý do.
"""
from dsl18 import obj

CTX = 'id!:u, version!:i, createdAt:ts, createdBy:s, updatedAt:ts, updatedBy:s'

ENUMS = {
    'DlqStatus': ['NEW', 'TRIAGED', 'REPLAY_PENDING', 'REPLAYING', 'RESOLVED', 'REPLAY_FAILED', 'DISCARDED', 'POISON', 'EXPIRED'],
    'ErrorClass': ['TRANSIENT', 'BUSINESS', 'CONTRACT', 'POISON', 'UNKNOWN'],
    'Priority': ['P1', 'P2', 'P3', 'P4'],
    'ReplayJobStatus': ['DRAFT', 'PENDING_APPROVAL', 'APPROVED', 'RUNNING', 'PAUSED', 'COMPLETED', 'PARTIAL', 'FAILED', 'CANCELLED', 'REJECTED'],
    'ReplayItemStatus': ['PENDING', 'SENT', 'SUCCEEDED', 'FAILED', 'SKIPPED', 'SKIPPED_DUPLICATE', 'CANCELLED'],
    'ReplayMode': ['KAFKA_TOPIC', 'HTTP_PORT', 'EVENT_LAYER', 'NONE'],
    'UseRevision': ['LATEST_APPROVED', 'ORIGINAL'],
    'DiscardReasonCode': ['HANDLED_AT_SOURCE', 'TEST_MESSAGE', 'OBSOLETE', 'DUPLICATE', 'OTHER'],
    'Replayable': ['YES', 'AFTER_FIX', 'NO'],
    'RevisionStatus': ['PENDING_APPROVAL', 'APPROVED', 'REJECTED'],
    'ParamType': ['INT', 'DECIMAL', 'BOOL', 'STRING', 'ENUM', 'DURATION', 'CRON', 'LIST<STRING>', 'LIST<HOST>', 'JSON'],
    'ParamLevel': ['PLATFORM', 'TENANT'],
    'ParamVersionStatus': ['PENDING_APPROVAL', 'ACTIVE', 'SUPERSEDED', 'REJECTED'],
    'ChangeRequestStatus': ['PENDING_APPROVAL', 'APPROVED', 'REJECTED', 'CANCELLED', 'EXPIRED'],
    'BundleStatus': ['DRAFT', 'VALIDATED', 'PENDING_APPROVAL', 'APPLIED', 'FAILED', 'REJECTED'],
    'EgressPurpose': ['DEV_PORTAL_BACKEND', 'GIT_REPO', 'WEBHOOK', 'MODEL_PROVIDER', 'OTHER'],
    'Channel': ['EMAIL', 'SMS', 'IN_APP'],
    'ClassLevel': ['PUBLIC', 'INTERNAL', 'RESTRICTED', 'SENSITIVE'],
    'TemplateVersionStatus': ['DRAFT', 'IN_REVIEW', 'ACTIVE', 'RETIRED'],
    'DeliveryStatus': ['QUEUED', 'SENT', 'DELIVERED', 'BOUNCED', 'FAILED', 'SUPPRESSED'],
    'NotifyPriority': ['NORMAL', 'HIGH', 'URGENT'],
    'RecipientKind': ['USER', 'GROUP', 'ROLE', 'SYSTEM_CONTACT', 'ON_CALL'],
    'TaskStatus': ['OPEN', 'IN_PROGRESS', 'DONE', 'CANCELLED', 'EXPIRED'],
    'Weekday': ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'],
    'Environment': ['PROD', 'STAGING', 'TEST'],
    'Severity': ['SEV1', 'SEV2', 'SEV3', 'SEV4'],
    'IncidentCategory': ['AVAILABILITY', 'DATA_INTEGRITY', 'SECURITY', 'PERFORMANCE', 'OTHER'],
    'IncidentStatus': ['OPEN', 'INVESTIGATING', 'MITIGATED', 'RESOLVED', 'CLOSED'],
    'LinkTargetType': ['DLQ_MESSAGE', 'DLQ_GROUP', 'ALERT', 'REPLAY_JOB', 'BACKUP_RUN', 'PRIVACY_CASE'],
    'BackupTool': ['CNPG_BARMAN', 'DH_TENANT_EXPORT', 'RCLONE', 'OPENBAO_RAFT', 'VELERO', 'VELERO_KOPIA', 'GIT_MIRROR', 'HARBOR_REPLICATION',
                   'CLICKHOUSE_BACKUP', 'PH13_WORM', 'SHAMIR_OFFLINE'],
    'BackupResult': ['RUNNING', 'SUCCEEDED', 'PARTIAL', 'FAILED'],
    'Freshness': ['FRESH', 'STALE', 'FAILED', 'UNKNOWN'],
    'VerifyMethod': ['RESTORE_LATEST', 'PITR_RANDOM', 'TENANT_IMPORT', 'SAMPLE_FILES', 'HASH_CHAIN'],
    'RestoreStatus': ['DRAFT', 'PENDING_APPROVAL', 'APPROVED', 'RUNNING', 'SUCCEEDED', 'FAILED', 'ROLLED_BACK', 'REJECTED', 'CANCELLED'],
    'JobStatus': ['QUEUED', 'RUNNING', 'SUCCEEDED', 'SUCCEEDED_WITH_ERRORS', 'FAILED', 'CANCELLED'],
    'ObjectType': ['CATALOG', 'SYSTEM', 'API', 'PLAN', 'SUBSCRIPTION', 'TOPIC', 'PUBLISHER', 'SUBSCRIBER', 'FLOW', 'TRANSACTION'],
    'RunMode': ['DRY_RUN', 'REAL'],
    'MigrationRunStatus': ['PENDING_APPROVAL', 'QUEUED', 'RUNNING', 'SUCCEEDED', 'SUCCEEDED_WITH_ERRORS', 'FAILED', 'CANCELLED'],
    'MigrationErrorStatus': ['OPEN', 'FIXED_AT_SOURCE', 'RULE_ADDED', 'WONT_MIGRATE'],
    'CredentialKind': ['OAUTH_CLIENT', 'CLIENT_CERT', 'API_KEY_LEGACY', 'PASSWORD'],
    'CutoverStatus': ['PARALLEL', 'SHADOW_OK', 'PARTIAL_CUTOVER', 'CUT_OVER', 'ROLLED_BACK'],
    'ChecklistItemCode': ['DLQ_EMPTY', 'MATCH_RATE', 'RECONCILIATION_MATCHED', 'CREDENTIALS_REISSUED', 'BACKUP_VERIFIED', 'ROLLBACK_READY',
                          'STAKEHOLDER_SIGNOFF', 'FREEZE_WINDOW'],
    'LegacySystem': ['BUS', 'HUB', 'APIM', 'AITA', 'PAYGOV', 'OTHER'],
    'DlqAuditAction': ['INGEST', 'VIEW_PAYLOAD', 'TRIAGE', 'ASSIGN', 'REVISE', 'APPROVE_REVISION', 'REPLAY_REQUEST', 'REPLAY_APPROVE', 'REPLAY_RESULT',
                       'DISCARD', 'REOPEN', 'EXPIRE', 'PURGE', 'EXPORT'],
    'HealthState': ['UP', 'DEGRADED', 'DOWN'],
    'ExportPurpose': ['HANDOVER', 'CELL_MOVE', 'DEDICATED_DB', 'ARCHIVE'],
    'DrillKind': ['DR_SWITCHOVER', 'RBK_03', 'PITR_CLUSTER', 'TABLETOP'],
}

PATTERNS = {
    'ParamKey': ('^[a-z0-9][a-z0-9.-]{2,127}$', 'Khóa tham số có tiền tố không gian tên, ví dụ `18.dlq.replay.batch-max`.'),
    'FlagKey': ('^ff\\.[a-z0-9-]+\\.[a-z0-9-]+$', 'Cờ tính năng `ff.{module}.{tính-năng}` (FR-18-009).'),
    'SourceCode': ('^[a-z0-9-]{3,40}$', 'Mã nguồn DLQ (FR-18-012).'),
    'ModuleCode': ('^PH-[0-9]{2}$', 'Mã phân hệ, ví dụ `PH-04`.'),
    'TenantCode': ('^T[0-9]{2}$', 'Mã tenant, ví dụ `T68`.'),
    'ErrorCode': ('^ERR-[0-9]{2}-[0-9]{3}$', 'Mã lỗi của phân hệ nguồn hoặc của PH-18.'),
    'TemplateCode': ('^[a-z0-9.-]{3,80}$', 'Mã mẫu thông báo (FR-18-035).'),
    'TaskTypeCode': ('^ph[0-9]{2}\\.[a-z0-9.-]+$', 'Loại việc có tiền tố `ph{nn}.` (FR-18-042).'),
    'TraceId': ('^[0-9a-f]{32}$', 'Mã vết W3C 32 ký tự hex.'),
    'VaultRef': ('^kv/dh/[a-z0-9]+/[a-z0-9/_-]+$', 'Đường dẫn bí mật ở OpenBao, không chứa giá trị.'),
    'Sha256': ('^[0-9a-f]{64}$', 'Tổng kiểm tra SHA-256 dạng hex.'),
    'ReplayIdempotencyKey': ('^[0-9a-f-]{36}:[0-9]+$', 'Khóa lũy đẳng phát lại `dlqId:revision` (ADR-182).'),
}

FACET = 'value!:s, count!:i'

READ = {
    'InboxFailure': 'module!:s, consumer!:s, eventId!:s, sourceTopic!:s, eventType:s, attempts!:i, lastError!:s, lastAttemptAt!:ts, receivedAt!:ts',
    'NormalizationRuleSet': 'groupCode!:s, rules!:[#NormalizationRule], recomputedSamples:i, matchRate:n',
    'ParamNamespace': 'ns!:s, ownerPh!:ph, title!:s, description:s, approvalOwner:ph, cacheTtlSeconds:i, schemaVersion!:i, status!:e(ACTIVE|RETIRED), keyCount!:i, groups:[s]',
    'ParamDefinition': 'key!:pkey, ns!:s, type!:#ParamType, default:any, domain:#ParamDomain, level!:#ParamLevel, ceiling:#ParamDomain, secure!:b, approvalOwner!:ph, '
                       'group!:s, label!:s, description:s, unit:s, schemaVersion!:i, deprecatedAt:ts, removalDate:d',
    'ParamChangeRequest': 'key!:pkey, proposedValue:any, currentValue:any, reason!:s, status!:#ChangeRequestStatus, requestedBy!:s, requestedAt!:ts, decidedBy:s, decidedAt:ts, '
                          'comment:s, expiresAt:ts, approvalOwner!:ph',
    'ParamValueVersion': 'key!:pkey, versionNo!:i, value:any, previousValue:any, status!:#ParamVersionStatus, reason:s, changeRequestId:u, rollbackOfVersionNo:i, effectiveFrom:ts, supersededAt:ts',
    'ParamBundle': 'bundleCode!:s, direction!:e(EXPORT|IMPORT), namespaces!:[s], includeDefaults:b, targetTenant:tn, itemCount!:i, sha256:hash, status!:#BundleStatus, '
                   'diff:[#BundleDiffItem], applied:i, pendingApproval:i, downloadUrl:s, expiresAt:ts',
    'FeatureFlag': 'flagKey!:fkey, description!:s, ownerPh!:ph, ownerUser!:s, retireBy!:d, level!:#ParamLevel, defaultValue!:b, enabled!:b, status!:e(ACTIVE|RETIRED), retiredAt:ts',
    'EgressEntry': 'host!:s, port!:i, purpose!:#EgressPurpose, usedBy!:ph, expiresAt:d, reason:s, enabled!:b',
    'DlqSource': 'sourceCode!:scode, sourcePh!:ph, ingestChannel!:e(KAFKA|API|FEDERATED), replayMode!:#ReplayMode, replayTarget:s, maxRatePerSecond!:i, supportsRevision!:b, '
                 'owners:[s], status!:e(ACTIVE|PAUSED), description:s',
    'DlqMessage': 'dlqKey!:s, sourceCode!:scode, sourcePh!:ph, flow:s, flowVersion:s, stage!:s, reason!:s, errorCode!:err, errorClass!:#ErrorClass, errorMessage:s, attempts!:i, '
                  'occurrences!:i, traceId:trace, messageId:s, status!:#DlqStatus, priority:#Priority, groupId:u, assignee:s, missingFields:[s], firstFailedAt:ts, receivedAt!:ts, '
                  'ageMinutes!:i, retentionUntil:ts, storage!:e(INLINE|GARAGE|PURGED), payloadSizeBytes:i, contentType:s, currentRevisionNo!:i',
    'DlqGroup': 'signature!:hash, sourceCode!:scode, flow:s, errorCode!:err, errorClass!:#ErrorClass, sampleMessage:s, firstSeenAt!:ts, lastSeenAt!:ts, openCount!:i, totalCount!:i, '
                'assignee:s, priority:#Priority',
    'DlqRevision': 'dlqId!:u, revisionNo!:i, payloadSha256!:hash, storage!:e(INLINE|GARAGE), reason!:s, schemaRef:s, containsRestricted!:b, status!:#RevisionStatus, '
                   'diff:[#JsonDiffEntry], approvedBy:s, approvedAt:ts, rejectComment:s',
    'ErrorGuide': 'errCode!:err, ownerPh!:ph, locale!:s, title!:s, causes!:[s], steps!:[s], replayable!:#Replayable, defaultClass:#ErrorClass, links:[s], '
                  'status!:e(DRAFT|PUBLISHED|RETIRED), publishedAt:ts, publishedBy:s',
    'ReplayJob': 'jobCode!:s, mode!:e(BATCH_FILTER|BATCH_LIST), filter:#DlqFilter, dlqIds:[u], useRevision!:#UseRevision, ratePerSecond!:i, stopOnFailurePercent!:i, reason!:s, '
                 'total!:i, succeeded!:i, failed!:i, skipped!:i, excluded:[#ExcludedItem], approvalRequired!:b, status!:#ReplayJobStatus, requestedBy!:s, approvedBy:s, '
                 'approvedAt:ts, rejectComment:s, startedAt:ts, pausedAt:ts, finishedAt:ts, cancelReason:s',
    'NotificationTemplate': 'templateCode!:tcode, channel!:#Channel, ownerPh!:ph, title!:s, description:s, category!:e(TASK|JOB_RESULT|ALERT|INFO), mandatory!:b, urgent!:b, '
                            'variables!:[#TemplateVariable], status!:e(ACTIVE|RETIRED), activeVersionNo:i, retiredAt:ts, versions:[#TemplateVersion]',
    'TemplateVersion': 'templateCode!:tcode, versionNo!:i, locale!:s, subject:s, body!:s, status!:#TemplateVersionStatus, fieldCheck:#FieldCheckReport, submittedAt:ts, '
                       'reviewedBy:s, reviewedAt:ts, activatedAt:ts, rejectComment:s',
    'NotificationRule': 'ruleCode!:s, eventType!:s, condition:s, templateCode!:tcode, recipients!:[#RecipientRef], priority!:#NotifyPriority, createTask!:b, taskType:ttype, enabled!:b',
    'TaskType': 'taskType!:ttype, ownerPh!:ph, title!:s, viewPermission!:s, defaultDueWorkingDays:i, linkTemplate!:s, fourEyes!:b, enabled!:b',
    'TaskItem': 'taskType!:ttype, sourceRef!:s, ownerPh!:ph, summary!:s, assignees!:[#RecipientRef], status!:#TaskStatus, priority!:#NotifyPriority, dueAt:ts, overdue!:b, '
                'claimedBy:s, sourceVersion!:i, closedAt:ts, outcome:e(DONE|CANCELLED), link!:s',
    'WorkCalendar': 'year!:i, calendarScope!:e(COMMON|TENANT), timezone!:s, weekendDays!:[#Weekday], holidays!:[#CalendarHoliday]',
    'MaintenanceWindow': 'windowCode!:s, kind!:e(MAINTENANCE|FREEZE), scope!:e(PLATFORM|TENANT), environments!:[#Environment], startsAt!:ts, endsAt!:ts, reason!:s, notify!:b, '
                         'exemptions:[s], state!:e(PLANNED|ACTIVE|COMPLETED|CANCELLED), cancelReason:s',
    'Incident': 'incidentCode!:s, title!:s, description:s, severity!:#Severity, category!:#IncidentCategory, origin!:e(EVENT|MANUAL), sourceRef:s, sourceType:s, '
                'status!:#IncidentStatus, assignee:s, hasPersonalData:b, affectedSystems:[s], detectedAt!:ts, acknowledgedAt:ts, mitigatedAt:ts, resolvedAt:ts, closedAt:ts, '
                'privacyCaseRef:s, rootCause:s, lessonsLearned:s, actions:[#IncidentAction]',
    'BackupObject': 'objectCode!:s, name!:s, objectKind!:s, tool!:#BackupTool, schedule:s, rpoMinutes:i, rtoMinutes:i, retentionDays:i, freshness!:#Freshness, lastRunAt:ts, '
                    'lastResult:#BackupResult, lastSuccessAt:ts, lastVerifiedAt:ts, lastVerificationResult:e(PASSED|FAILED), enabled!:b',
    'BackupRun': 'objectCode!:s, tool!:#BackupTool, startedAt!:ts, finishedAt:ts, result!:#BackupResult, sizeBytes:i, location:s, tenant:tn, errorMessage:s, collectedAt!:ts',
    'RestoreVerification': 'objectCode!:s, method!:#VerifyMethod, result!:e(PASSED|FAILED), metrics:#VerifyMetrics, evidenceRef:s, verifiedAt!:ts, durationSec:i',
    'TenantRestore': 'requestNo!:s, targetTime!:ts, scope!:e(FULL_TENANT|MODULES), modules:[s], includeObjects!:b, includeIdentity!:b, includeSecrets!:b, reason!:s, '
                     'status!:#RestoreStatus, requestedBy!:s, approvedBy:s, approvedAt:ts, rejectComment:s, estimate:#RestoreEstimate, currentStep:i, jobName:s, '
                     'startedAt:ts, finishedAt:ts, rowsReplaced:i',
    'TenantExport': 'exportCode!:s, purpose!:#ExportPurpose, includeObjects!:b, format!:e(PG_COPY|PG_DUMP), recipientRef:#RecipientRef, status!:#JobStatus, sizeBytes:i, '
                    'manifestSha256:hash, expiresAt:ts, startedAt:ts, finishedAt:ts, errorMessage:s',
    'MergeTransfer': 'mergePlanId!:u, module!:s, sourceTenant!:tn, targetTenant!:tn, mappingRef!:s, dryRun!:b, status!:#JobStatus, progressPercent:n, rowsRead:i, rowsLoaded:i, '
                     'rowsConflicted:i, rowsFailed:i, startedAt:ts, finishedAt:ts, lastReportedAt:ts, reportStatus:e(PENDING|REPORTED|REPORT_FAILED), errorMessage:s',
    'DrDrill': 'drillCode!:s, kind!:#DrillKind, startedAt!:ts, finishedAt!:ts, rtoMeasuredMinutes:i, rpoMeasuredSeconds:i, result!:e(PASSED|PASSED_WITH_ISSUES|FAILED), '
               'issues:[s], evidenceRef:s, recordedBy!:s',
    'LegacySource': 'sourceCode!:s, name!:s, legacySystem!:#LegacySystem, jdbcUrl!:s, credentialRef!:vault, schemas!:[s], networkZone:s, status!:e(DRAFT|VERIFIED|DISABLED), '
                    'readOnlyVerified!:b, verifiedAt:ts, tables:i, estimatedRows:i',
    'MigrationPlan': 'planCode!:s, sourceCode!:s, title!:s, description:s, status!:e(DRAFT|READY), readyAt:ts, readyBy:s, targetCutoverDate:d, itemCount!:i',
    'MigrationRun': 'planCode!:s, runNo!:i, mode!:#RunMode, status!:#MigrationRunStatus, basedOnDryRun:u, retryOf:u, sampleLimit:i, reason:s, requestedBy!:s, approvedBy:s, '
                    'approvedAt:ts, rejectComment:s, startedAt:ts, finishedAt:ts, read!:i, written!:i, rejected!:i, skipped!:i, items!:[#MigrationRunItemResult]',
    'MigrationErrorRecord': 'runId!:u, objectType!:#ObjectType, sourceRecordRef!:s, reasonCode!:s, errorCode:err, message!:s, fieldPath:s, status!:#MigrationErrorStatus, fixedBy:s, fixedAt:ts',
    'CredentialReissue': 'systemCode!:s, applicationRef!:s, credentialKind!:#CredentialKind, targetPh!:ph, runId!:u, status!:e(PENDING|NOTIFIED|REISSUED|WAIVED), notifiedAt:ts, '
                         'reissuedAt:ts, waivedReason:s',
    'ParallelGroup': 'groupCode!:s, title!:s, planCode:s, routes!:[s], status!:#CutoverStatus, mirrorPercent!:n, matchThresholdPercent!:n, matchRate:n, samplesTotal!:i, '
                     'samplesMatched!:i, bridgeState:e(NONE|RUNNING|STOPPED), trafficPercent:i, cutoverAt:ts, rollbackUntil:ts, rolledBackAt:ts',
    'OpsReport': 'reportCode!:s, period!:e(MONTH|QUARTER), from!:d, to!:d, status!:#JobStatus, metrics:o, sha256:hash, generatedAt:ts, downloadUrl:s',
}
# bản ghi chi tiết = bản ghi gốc + trường thêm
DETAIL = {
    'DlqMessageDetail': ('DlqMessage', 'contextHeaders:o, schemaRef:s, originTopic:s, originPartition:i, originOffset:i, discardReasonCode:#DiscardReasonCode, discardReason:s, '
                                       'resolvedAt:ts, history!:[#DlqAuditEntry], revisions!:[#DlqRevision], replays!:[#ReplayItem], guide:#ErrorGuideSummary'),
    'IncidentDetail': ('Incident', 'timeline!:[#IncidentTimelineEntry], links!:[#IncidentLink]'),
    'MigrationPlanDetail': ('MigrationPlan', 'items!:[#MigrationPlanItem], computedOrder:[#ObjectType], runs:[#MigrationRunSummary]'),
    'ParallelGroupDetail': ('ParallelGroup', 'mismatchSamples!:[#ShadowSample], checklist!:[#CutoverChecklistItem], log!:[#CutoverLogEntry]'),
}

PLAIN = {
    'NormalizationRule': 'kind!:e(IGNORE_FIELD|DATE_FORMAT|NUMBER_FORMAT|SORT_ARRAY|TRIM), path!:s, description:s',
    'ReplayPayload': 'dlqId!:u, revision!:i, idempotencyKey!:ikey, contentType!:s, sizeBytes!:i, sha256!:hash, payload:any, downloadUrl:s, expiresAt:ts',
    'ParamDomain': 'min:n, max:n, enum:[s], pattern:s, maxItems:i',
    'ParamValue': 'key!:pkey, ns!:s, value:any, version!:i, source!:e(DEFAULT|TENANT|CEILING), level!:#ParamLevel, secure!:b, status!:e(ACTIVE|PENDING_APPROVAL), '
                  'pendingRequestId:u, effectiveFrom:ts, updatedAt:ts, updatedBy:s',
    'ParamValueLite': 'key!:pkey, value:any, version!:i, source!:e(DEFAULT|TENANT|CEILING)',
    'ParamValidateResult': 'valid!:b, results!:[#ParamValidateItemResult]',
    'ParamValidateItemResult': 'key!:pkey, valid!:b, errorCode:err, message:s',
    'ParamVersionCompare': 'key!:pkey, from!:i, to:i, compareToDefault!:b, diff!:[#JsonDiffEntry]',
    'JsonDiffEntry': 'path!:s, op!:e(ADD|REMOVE|REPLACE), before:any, after:any',
    'ParamChange': 'key!:pkey, ns!:s, versionNo!:i, changeType!:e(VALUE_CHANGED|SCHEMA_CHANGED|FLAG_CHANGED|EGRESS_CHANGED), source!:e(UI|API|SEED_TENANT|BUNDLE|ROLLBACK|REGISTER), '
                   'changedBy!:s, changedAt!:ts, reason:s, approvedBy:s',
    'BundleDiffItem': 'key!:pkey, change!:e(ADD|CHANGE|UNCHANGED|REJECT), secure!:b, errorCode:err',
    'NamespaceRegistration': 'ns!:s, schemaVersion!:i, added!:[pkey], changed!:[pkey], deprecated!:[pkey]',
    'ParamBatchResult': 'tenant!:tn, values!:[#ParamValueLite], unknown!:[s], flags:[#FlagValue], egress:[#EgressHost]',
    'FlagValue': 'flagKey!:fkey, enabled!:b',
    'EgressHost': 'host!:s, port!:i, purpose!:#EgressPurpose',
    'ParamSnapshot': 'tenant!:tn, ns!:s, schemaVersion!:i, generatedAt!:ts, values!:[#ParamValueLite]',
    'SeedResult': 'tenant!:tn, profile!:s, added!:i, kept!:i, namespaces!:[s]',
    'DlqIngestResult': 'dlqId!:u, status!:e(NEW|POISON), duplicate!:b, occurrences!:i, missingFields:[s], storage!:e(INLINE|GARAGE)',
    'DlqBatchResult': 'accepted!:i, rejected!:i, results!:[#DlqBatchItemResult]',
    'DlqBatchItemResult': 'index!:i, httpStatus!:i, dlqId:u, duplicate:b, errorCode:err',
    'DlqReconciliation': 'runId!:u, status!:e(RUNNING|COMPLETED|FAILED), from!:ts, to!:ts, startedAt!:ts, finishedAt:ts, missingTotal!:i, extraTotal!:i, partitions!:[#ReconPartition]',
    'ReconPartition': 'partition!:i, firstOffset!:i, lastOffset!:i, indexed!:i, missing!:i, extra!:i',
    'EventDeadLetter': 'entryRef!:s, subscriptionCode!:s, topic!:s, errorCode:s, reason:s, attempts!:i, firstFailedAt!:ts, lastFailedAt:ts, status!:s, origin:s, linkRoute:s',
    'EventReplayRequest': 'entryRef!:s, replayCode!:s, status!:e(REQUESTED|PENDING_APPROVAL), requestedAt!:ts',
    'DlqFacets': 'bySource!:[#FacetCount], byErrorClass!:[#FacetCount], byStatus!:[#FacetCount], byErrorCode!:[#FacetCount]',
    'FacetCount': FACET,
    'DlqDiagnostics': 'traceId:trace, partial!:b, unavailableReason:s, window!:s, spans!:[#DiagSpan], logs!:[#DiagLog], metrics!:[#DiagMetric]',
    'DiagSpan': 'service!:s, operation!:s, startedAt!:ts, durationMs!:i, status!:e(OK|ERROR)',
    'DiagLog': 'at!:ts, level!:e(ERROR|WARN|INFO|DEBUG), service!:s, message!:s',
    'DiagMetric': 'name!:s, value!:n, at!:ts',
    'PayloadReveal': 'dlqId!:u, revision!:i, content:any, contentType!:s, maskedFields!:[s], revealExpiresAt!:ts',
    'PayloadSkeleton': 'dlqId!:u, contentType!:s, fields!:[#SkeletonField]',
    'SkeletonField': 'path!:s, type!:e(STRING|NUMBER|BOOLEAN|OBJECT|ARRAY|NULL|BINARY), encrypted!:b',
    'RevisionDiff': 'dlqId!:u, revisionNo!:i, diff!:[#JsonDiffEntry], maskedPaths!:[s]',
    'BulkResult': 'requested!:i, succeeded!:i, failed!:i, results!:[#BulkItemResult]',
    'BulkItemResult': 'dlqId!:u, httpStatus!:i, errorCode:err',
    'ErrorGuideSummary': 'errCode!:err, title!:s, replayable!:#Replayable',
    'ErrorGuideFeed': 'items!:[#ErrorGuide], nextUpdatedSince!:ts',
    'DlqAuditEntry': 'action!:#DlqAuditAction, actor!:s, actorKind!:e(USER|SERVICE), reason:s, beforeStatus:#DlqStatus, afterStatus:#DlqStatus, replayJobId:u, occurredAt!:ts, traceId:trace',
    'ExcludedItem': 'dlqId!:u, reasonCode!:e(POISON|IN_OTHER_JOB|NO_REPLAY_PORT|EXPIRED|STATUS)',
    'ReplayItem': 'jobId:u, dlqId!:u, revision!:i, idempotencyKey!:ikey, status!:#ReplayItemStatus, replayTraceId:trace, dispatchedAt:ts, resultAt:ts, '
                  'result:e(SUCCEEDED|FAILED|DUPLICATE_IGNORED), resultErrorCode:s, resultMessage:s',
    'ReplayAccepted': 'dlqId!:u, status!:#DlqStatus, idempotencyKey!:ikey, revision!:i',
    'ReplayResultAck': 'dlqId!:u, status!:#DlqStatus, duplicate!:b',
    'DlqRetention': 'expiring7Days!:i, expiring30Days!:i, lastPurgeAt:ts, lastPurgeCount:i, garageBytes!:i, garageObjects!:i, closedRetentionDays!:i, openMaxDays!:i',
    'DlqStats': 'interval!:e(24h|7d|30d|90d), from!:ts, to!:ts, totals!:#DlqTotals, groups!:[#FacetCount], trend!:[#TrendPoint]',
    'DlqTotals': 'open!:i, newCount!:i, poison!:i, replayFailed!:i, resolved!:i, discarded!:i, oldestAgeMinutes:i',
    'TrendPoint': 'at!:ts, received!:i, resolved!:i, discarded!:i',
    'TemplateVariable': 'name!:s, classification!:#ClassLevel, example:s',
    'TemplatePreview': 'renderedSubject:s, renderedBody!:s, fieldCheck!:#FieldCheckReport',
    'FieldCheckReport': 'passed!:b, violations!:[#FieldViolation], syntaxErrors!:[#TemplateSyntaxError]',
    'FieldViolation': 'variable!:s, classification!:#ClassLevel, line:i',
    'TemplateSyntaxError': 'line!:i, message!:s',
    'RecipientRef': 'kind!:#RecipientKind, ref!:s',
    'NotificationAccepted': 'messageId!:u, status!:e(QUEUED|SUPPRESSED), duplicate!:b, recipients!:i',
    'NotificationSyncResult': 'messageId!:u, status!:#DeliveryStatus, deliveries!:[#DeliverySummary]',
    'DeliverySummary': 'channel!:#Channel, status!:#DeliveryStatus, recipientMasked:s, errorCode:s',
    'NotificationStatus': 'messageId!:u, type!:tcode, status!:#DeliveryStatus, requestedAt!:ts, deliveries!:[#DeliverySummary]',
    'RecipientResolveResult': 'counts!:#RecipientCounts, unresolved!:[s]',
    'RecipientCounts': 'users!:i, email!:i, sms!:i, inApp!:i, suppressed!:i',
    'NotificationPreferences': 'userId!:s, version!:i, prefs!:[#NotificationPref], quietHours!:s',
    'NotificationPref': 'typeGroup!:s, channel!:#Channel, enabled!:b, mandatory!:b',
    'MeNotification': 'notificationId!:u, title!:s, link:s, typeGroup!:s, priority!:#NotifyPriority, readAt:ts, createdAt!:ts',
    'ReadResult': 'updated!:i, unreadCount!:i',
    'NotificationDelivery': 'id!:u, messageId!:u, type!:tcode, channel!:#Channel, recipientMasked!:s, recipientUser:s, status!:#DeliveryStatus, attempts!:i, providerMessageId:s, '
                            'lastErrorCode:s, suppressedReason:s, callerPh!:ph, sourceRef:s, queuedAt!:ts, sentAt:ts, deliveredAt:ts, bouncedAt:ts',
    'Suppression': 'id!:u, channel!:e(EMAIL|SMS), addressMasked!:s, reason!:e(HARD_BOUNCE|COMPLAINT|INVALID|MANUAL), bounceCount!:i, firstBouncedAt:ts, lastBouncedAt:ts',
    'BounceAck': 'deliveryId:u, status!:#DeliveryStatus, suppressed!:b',
    'TaskSummary': 'open!:i, overdue!:i, dueToday!:i, byType!:[#FacetCount]',
    'CalendarHoliday': 'date!:d, name!:s, kind!:e(HOLIDAY|MAKEUP_WORKDAY), legalBasis:s',
    'WorkingDaysResult': 'tenant!:tn, from!:d, to!:d, count!:i, days!:[d]',
    'AddWorkingDaysResult': 'from!:ts, workingDays!:i, dueAt!:ts, skippedDates!:[d]',
    'FreezeStatus': 'tenant!:tn, evaluatedAt!:ts, frozen!:b, active!:[#ActiveWindow]',
    'ActiveWindow': 'windowCode!:s, kind!:e(MAINTENANCE|FREEZE), environments!:[#Environment], startsAt!:ts, endsAt!:ts, exemptions:[s]',
    'IncidentAction': 'title!:s, owner!:s, dueAt:d',
    'IncidentTimelineEntry': 'id!:u, kind!:e(NOTE|ACTION|DECISION|COMMUNICATION|STATUS_CHANGE|ESCALATION), content!:s, occurredAt!:ts, actor!:s, from:#IncidentStatus, to:#IncidentStatus',
    'IncidentLink': 'id!:u, targetType!:#LinkTargetType, targetRef!:s, note:s',
    'EscalationResult': 'incidentCode!:s, privacyCaseRef!:s, escalatedAt!:ts',
    'VerifyMetrics': 'rowsMatched:i, filesMatched:i, hashChainValid:b, restoreSeconds:i, rowCountDiff:i',
    'BackupRunAck': 'runId!:u, objectCode!:s, freshness!:#Freshness',
    'VerificationAck': 'verificationId!:u, objectCode!:s, result!:e(PASSED|FAILED)',
    'RestoreEstimate': 'sizeGb!:n, durationMinutes!:i, tables!:i',
    'TenantRestoreStep': 'stepNo!:i, stepCode!:s, status!:e(PENDING|RUNNING|SUCCEEDED|FAILED|SKIPPED|ROLLED_BACK), startedAt:ts, finishedAt:ts, rowsAffected:i, '
                         'tables:[#TableRowCount], message:s',
    'TableRowCount': 'table!:s, before!:i, after!:i',
    'TenantRestoreStepList': 'requestNo!:s, items!:[#TenantRestoreStep]',
    'DownloadLink': 'url!:s, expiresAt!:ts, sha256!:hash, sizeBytes!:i',
    'ConnectionTestResult': 'ok!:b, readOnly!:b, tables!:i, estimatedRows!:i, latencyMs:i, errorCode:err, checkedAt!:ts',
    'MigrationPlanItem': 'objectType!:#ObjectType, converter!:s, targetPh!:ph, order!:i, dependsOn:[#ObjectType], filter:s, fixRules:[s], enabled!:b',
    'MigrationRunSummary': 'runId!:u, runNo!:i, mode!:#RunMode, status!:#MigrationRunStatus, finishedAt:ts',
    'MigrationRunItemResult': 'objectType!:#ObjectType, targetPh!:ph, status!:#JobStatus, read!:i, converted!:i, written!:i, rejected!:i, skipped!:i',
    'MigrationReconciliationReport': 'runId!:u, planCode!:s, matched!:b, computedAt!:ts, items!:[#ReconciliationItem], downloadPdf:s, downloadCsv:s',
    'ReconciliationItem': 'objectType!:#ObjectType, sourceCount!:i, targetCount!:i, missing!:i, extra!:i, mismatched!:i, sourceChecksum:hash, targetChecksum:hash, '
                          'checksumAlgo!:e(SHA256), matched!:b',
    'ShadowSample': 'sampledAt!:ts, route!:s, legacyStatus!:i, datahubStatus!:i, matched!:b, diffKind:s, diffPaths:[s], latencyMs:i',
    'CutoverChecklistItem': 'itemCode!:#ChecklistItemCode, description!:s, checkKind!:e(AUTO|MANUAL), status!:e(PENDING|PASSED|FAILED|WAIVED), evidence:s, checkedBy:s, checkedAt:ts',
    'CutoverLogEntry': 'action!:s, from:#CutoverStatus, to:#CutoverStatus, actor!:s, approvedBy:s, occurredAt!:ts, note:s',
    'ShadowAck': 'accepted!:i, matched!:i, groupMatchRate!:n',
    'AuditEntry': 'auditId!:u, occurredAt!:ts, actor!:s, approver:s, action!:s, objectType!:s, objectId!:s, reason:s, outcome!:e(SUCCESS|DENIED|FAILED), traceId:trace',
    'Health': 'status!:#HealthState, readOnly!:b, readOnlyReason:s, components!:[#ComponentHealth], checkedAt!:ts',
    'ComponentHealth': 'component!:s, status!:#HealthState, consumerLagSeconds:i, detail:s',
    'ProblemDetails': 'type!:s, title!:s, status!:i, detail:s, instance:s, code!:s, traceId:trace, errors:[#FieldError]',
    'FieldError': 'field!:s, message!:s, code:s',
}

INPUT = {
    'ApproveInput': 'comment:s',
    'RejectInput': 'comment!:s10',
    'ReasonInput': 'reason!:s10',
    'CancelInput': 'reason:s',
    'ParamValueInput': 'value!:any, reason!:s10',
    'ParamValidateInput': 'items!:[#ParamValidateItem]',
    'ParamValidateItem': 'key!:pkey, value!:any',
    'BundleExportInput': 'namespaces!:[s], includeDefaults:b',
    'BundleImportInput': 'bundle!:o, sha256!:hash, targetTenant:tn, dryRun:b',
    'FeatureFlagInput': 'flagKey!:fkey, description!:s10, ownerPh!:ph, ownerUser!:s, retireBy!:d, level!:#ParamLevel, defaultValue!:b',
    'FeatureFlagPatch': 'enabled:b, retireBy:d, reason!:s10',
    'EgressInput': 'host!:s, port:i, purpose!:#EgressPurpose, usedBy!:ph, expiresAt:d, reason!:s10',
    'NamespaceSchemaInput': 'ownerPh!:ph, title!:s, description:s, approvalOwner:ph, cacheTtlSeconds:i, schemaVersion!:i, definitions!:[#ParamDefinitionInput]',
    'ParamDefinitionInput': 'key!:pkey, type!:#ParamType, default!:any, domain!:#ParamDomain, level!:#ParamLevel, ceiling:#ParamDomain, secure!:b, approvalOwner:ph, group!:s, '
                            'label!:s, description!:s, unit:s, removalDate:d',
    'ParamBatchGetInput': 'tenant!:tn, keys:[pkey], ns:s, flags:[fkey], includeEgress:b',
    'SeedDefaultsInput': 'profile!:s, namespaces:[s]',
    'DlqSourceInput': 'sourceCode!:scode, sourcePh!:ph, ingestChannel!:e(KAFKA|API|FEDERATED), replayMode!:#ReplayMode, replayTarget:s, maxRatePerSecond!:i, supportsRevision!:b, '
                      'owners:[s], description:s',
    'DlqSourcePatch': 'replayMode:#ReplayMode, replayTarget:s, maxRatePerSecond:i, supportsRevision:b, owners:[s], status:e(ACTIVE|PAUSED), reason:s',
    'DlqMessageInput': 'tenant!:tn, sourceCode!:scode, sourcePh!:ph, messageId!:s, reason!:s, errorCode!:err, stage!:s, attempts!:i, errorClass:e(TRANSIENT|BUSINESS|CONTRACT|UNKNOWN), '
                       'flow:s, version:s, traceId:trace, errorMessage:s, firstFailedAt:ts, schemaRef:s, contentType!:s, payload!:any',
    'DlqBatchInput': 'items!:[#DlqMessageInput]',
    'ReconcileInput': 'from:ts, to:ts',
    'DlqFilter': 'sourceCode:[scode], flow:[s], errorCode:[err], errorClass:[#ErrorClass], status:[#DlqStatus], age:e(1h|24h|7d), assignee:s, priority:[#Priority], groupId:u, q:s',
    'GroupAssignInput': 'assignee!:s, priority:#Priority, note:s',
    'PayloadRevealInput': 'reason!:s10, purpose!:e(DIAGNOSE|EDIT|SUPPORT), revision:i',
    'TriageInput': 'errorClass!:#ErrorClass, priority!:#Priority, assignee:s, note:s, notifyOwner:b',
    'AssignInput': 'assignee:s, note:s',
    'BulkTriageInput': 'dlqIds!:[u], errorClass:#ErrorClass, priority:#Priority, assignee:s, note:s',
    'RevisionInput': 'content!:any, reason!:s10, schemaRef:s',
    'ErrorGuideInput': 'title!:s, causes!:[s], steps!:[s], replayable!:#Replayable, defaultClass:#ErrorClass, links:[s], locale:s, status:e(DRAFT|PUBLISHED|RETIRED)',
    'ReplayInput': 'revision:i, note:s',
    'ReplayJobInput': 'filter:#DlqFilter, dlqIds:[u], useRevision!:#UseRevision, ratePerSecond:i, stopOnFailurePercent:i, reason!:s10',
    'ReplayJobPatch': 'ratePerSecond!:i',
    'ReplayResultInput': 'idempotencyKey!:ikey, result!:e(SUCCEEDED|FAILED|DUPLICATE_IGNORED), errorCode:s, message:s, processedAt!:ts',
    'DiscardInput': 'reasonCode!:#DiscardReasonCode, reason!:s10',
    'BulkDiscardInput': 'dlqIds!:[u], reasonCode!:#DiscardReasonCode, reason!:s10',
    'TemplateInput': 'templateCode!:tcode, channel!:#Channel, ownerPh!:ph, title!:s, description:s, category!:e(TASK|JOB_RESULT|ALERT|INFO), mandatory:b, urgent:b, '
                     'variables!:[#TemplateVariable]',
    'TemplateVersionInput': 'locale!:s, subject:s, body!:s',
    'PreviewInput': 'sampleData!:o',
    'NotificationInput': 'type!:tcode, recipients!:[#RecipientRef], variables!:o, channels:[#Channel], priority:#NotifyPriority, sourceRef!:s, expiresAt:ts',
    'RecipientResolveInput': 'recipients!:[#RecipientRef], channels:[#Channel]',
    'NotificationPreferencesInput': 'prefs!:[#NotificationPrefInput], quietHours:s',
    'NotificationPrefInput': 'typeGroup!:s, channel!:#Channel, enabled!:b',
    'NotificationRuleInput': 'ruleCode!:s, eventType!:s, condition:s, templateCode!:tcode, recipients!:[#RecipientRef], priority:#NotifyPriority, createTask:b, taskType:ttype, enabled:b',
    'NotificationRulePatch': 'condition:s, templateCode:tcode, recipients:[#RecipientRef], priority:#NotifyPriority, createTask:b, taskType:ttype, enabled:b',
    'BounceInput': 'messageRef!:s, bounceType!:e(HARD|SOFT), smtpCode:s, occurredAt!:ts',
    'TaskTypeInput': 'taskType!:ttype, title!:s, viewPermission!:s, defaultDueWorkingDays:i, linkTemplate!:s, fourEyes:b',
    'TaskUpsertInput': 'taskType!:ttype, assignees!:[#RecipientRef], excludeUsers:[s], dueAt:ts, dueWorkingDays:i, summary!:s, sourceVersion!:i, priority:#NotifyPriority',
    'TaskCloseInput': 'outcome!:e(DONE|CANCELLED), sourceVersion!:i, note:s',
    'WorkCalendarInput': 'weekendDays!:[#Weekday], holidays!:[#CalendarHolidayInput], reason:s',
    'CalendarHolidayInput': 'date!:d, name!:s, kind!:e(HOLIDAY|MAKEUP_WORKDAY), legalBasis:s',
    'AddWorkingDaysInput': 'from!:ts, workingDays!:i',
    'MaintenanceWindowInput': 'kind!:e(MAINTENANCE|FREEZE), scope!:e(PLATFORM|TENANT), environments:[#Environment], startsAt!:ts, endsAt!:ts, reason!:s10, notify:b, exemptions:[s]',
    'MaintenanceWindowPatch': 'environments:[#Environment], startsAt:ts, endsAt:ts, reason:s, notify:b, exemptions:[s]',
    'IncidentInput': 'title!:s, description!:s, severity!:#Severity, category!:#IncidentCategory, assignee:s, hasPersonalData:b, affectedSystems:[s], detectedAt:ts',
    'IncidentPatch': 'title:s, description:s, severity:#Severity, assignee:s, hasPersonalData:b, affectedSystems:[s]',
    'IncidentTransitionInput': 'to!:#IncidentStatus, note:s',
    'TimelineInput': 'kind!:e(NOTE|ACTION|DECISION|COMMUNICATION), content!:s, occurredAt:ts',
    'IncidentLinkInput': 'targetType!:#LinkTargetType, targetRef!:s, note:s',
    'EscalatePrivacyInput': 'dataCategories!:[s], estimatedSubjects!:i, discoveredAt!:ts, summary!:s',
    'IncidentCloseInput': 'rootCause!:s30, lessonsLearned!:s30, actions:[#IncidentAction]',
    'IncidentReportInput': 'tenant!:tn, sourceRef!:s, sourceType!:e(ALERT|AUDIT_CHAIN|PRIVACY|OTHER), severity!:#Severity, title!:s, occurredAt!:ts, links:[#IncidentLinkInput]',
    'BackupRunReport': 'objectCode!:s, tool!:#BackupTool, startedAt!:ts, finishedAt:ts, result!:#BackupResult, sizeBytes:i, location:s, tenant:tn, errorMessage:s',
    'VerificationReport': 'objectCode!:s, method!:#VerifyMethod, result!:e(PASSED|FAILED), metrics:#VerifyMetrics, evidenceRef:s, verifiedAt!:ts, tenant:tn',
    'TenantRestoreInput': 'targetTime!:ts, scope!:e(FULL_TENANT|MODULES), modules:[s], includeObjects:b, includeIdentity:b, includeSecrets:b, reason!:s30',
    'RestoreApproveInput': 'comment:s, maintenanceNotice:b',
    'TenantExportInput': 'purpose!:#ExportPurpose, includeObjects:b, format!:e(PG_COPY|PG_DUMP), recipientRef:#RecipientRef, reason!:s10',
    'MergeTransferInput': 'mergePlanId!:u, module!:s, sourceTenant!:tn, targetTenant!:tn, mappingRef!:s, dryRun!:b',
    'DrDrillInput': 'kind!:#DrillKind, startedAt!:ts, finishedAt!:ts, rtoMeasuredMinutes:i, rpoMeasuredSeconds:i, result!:e(PASSED|PASSED_WITH_ISSUES|FAILED), issues:[s], evidenceRef:s',
    'LegacySourceInput': 'sourceCode!:s, name!:s, legacySystem!:#LegacySystem, jdbcUrl!:s, credentialRef!:vault, schemas!:[s], networkZone:s',
    'MigrationPlanInput': 'planCode!:s, sourceCode!:s, title!:s, description:s, targetCutoverDate:d',
    'MigrationPlanItemsInput': 'items!:[#MigrationPlanItemInput]',
    'MigrationPlanItemInput': 'objectType!:#ObjectType, converter!:s, targetPh!:ph, order!:i, dependsOn:[#ObjectType], filter:s, fixRules:[s], enabled:b',
    'MigrationRunInput': 'planCode!:s, mode!:#RunMode, items:[#ObjectType], sampleLimit:i, basedOnDryRun:u, retryOf:u, errorIds:[u], reason:s',
    'CutoverTransitionInput': 'action!:e(REQUEST|APPROVE|REJECT|ROLLBACK), target:e(PARTIAL_CUTOVER|CUT_OVER), trafficPercent:i, reason!:s10',
    'MigrationErrorFixInput': 'errorIds!:[u], status!:e(FIXED_AT_SOURCE|RULE_ADDED|WONT_MIGRATE), reason:s10, ruleRef:s',
    'NormalizationRulesInput': 'rules!:[#NormalizationRule], reason!:s10',
    'ChecklistConfirmInput': 'evidence!:s, comment:s',
    'DegradedModeInput': 'readOnly!:b, reason!:s10',
    'ShadowSampleBatch': 'items!:[#ShadowSampleInput]',
    'ShadowSampleInput': 'groupCode!:s, requestHash!:hash, route!:s, legacyStatus!:i, datahubStatus!:i, legacyBodyHash!:hash, datahubBodyHash!:hash, diffPaths:[s], latencyMs:i, sampledAt!:ts',
    'ReportGenerateInput': 'period!:e(MONTH|QUARTER), from!:d, to!:d',
}

# giới hạn số phần tử theo FRS
MAX_ITEMS = {('DlqBatchInput', 'items'): 500, ('BulkTriageInput', 'dlqIds'): 1000, ('BulkDiscardInput', 'dlqIds'): 1000, ('ReplayJobInput', 'dlqIds'): 1000,
             ('NotificationInput', 'recipients'): 500, ('MigrationErrorFixInput', 'errorIds'): 1000, ('NormalizationRulesInput', 'rules'): 100, ('ShadowSampleBatch', 'items'): 1000, ('ParamValidateInput', 'items'): 200}
STR_MAX = {('TriageInput', 'note'): 2000, ('TimelineInput', 'content'): 4000, ('TemplateVersionInput', 'subject'): 200, ('TemplateVersionInput', 'body'): 20000,
           ('TaskTypeInput', 'title'): 120, ('FeatureFlagInput', 'description'): 500}
INT_RANGE = {('DlqSourceInput', 'maxRatePerSecond'): (1, 100), ('DlqSourcePatch', 'maxRatePerSecond'): (1, 100), ('ReplayJobInput', 'ratePerSecond'): (1, 100),
             ('ReplayJobPatch', 'ratePerSecond'): (1, 100), ('ReplayJobInput', 'stopOnFailurePercent'): (1, 100), ('TaskTypeInput', 'defaultDueWorkingDays'): (0, 60),
             ('EgressInput', 'port'): (1, 65535), ('CutoverTransitionInput', 'trafficPercent'): (1, 100)}


def build():
    S = {}
    for name, vals in ENUMS.items():
        S[name] = {'type': 'string', 'enum': vals}
    for name, (pat, desc) in PATTERNS.items():
        S[name] = {'type': 'string', 'pattern': pat, 'description': desc}
    for n, sp in READ.items():
        S[n] = obj(sp, CTX)
    for n, (base, extra) in DETAIL.items():
        S[n] = obj(READ[base] + ', ' + extra, CTX)
    for grp in (PLAIN, INPUT):
        for n, sp in grp.items():
            S[n] = obj(sp)
    for (n, f), mx in MAX_ITEMS.items():
        S[n]['properties'][f]['maxItems'] = mx
    for (n, f), mx in STR_MAX.items():
        S[n]['properties'][f]['maxLength'] = mx
    for (n, f), (lo, hi) in INT_RANGE.items():
        S[n]['properties'][f].update({'minimum': lo, 'maximum': hi})
    for n in list(S):
        if n.endswith('Patch') and 'required' in S[n] and n not in ('FeatureFlagPatch', 'ReplayJobPatch'):
            del S[n]['required']
        if n.endswith(('Input', 'Patch', 'Batch')) and S[n].get('type') == 'object':
            S[n]['additionalProperties'] = False
    S['DlqMessageInput']['additionalProperties'] = False
    S['ProblemDetails']['properties']['type']['format'] = 'uri'
    return S
