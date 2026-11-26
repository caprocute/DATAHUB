#!/usr/bin/env python3
"""Lược đồ thành phần (components.schemas) của OpenAPI PH-17, viết bằng DSL ngắn của dsl17.py.

Tên trường là camelCase của cột bảng ở D03-03-PH17. Enum Phụ lục A của FRS đọc ở gen_openapi.py (tên `#TênEnum`).
Không có trường nào mang nội dung hội thoại chưa che, bí mật nhà cung cấp hay vector: `content` luôn là bản đã che,
bí mật chỉ là `secretRef` (đường dẫn OpenBao).
"""
from dsl17 import obj

CTX = 'id!:u, version!:i, createdAt:ts, createdBy:s, updatedAt:ts, updatedBy:s'
GEN = 'Nội dung do AI tạo, cần kiểm tra lại.'

READ = {
    'TenantPolicy': 'assistState!:#TenantAssistState, enabledChangeId:u, enabledAt:ts, decisionNumber:s, externalAllowed!:b, externalChangeId:u, currentNoticeId:u, killedAt:ts, '
                    'capabilities!:[#CapabilityPolicy], quotas:#QuotaSettings',
    'PolicyChange': 'changeType!:#PolicyChangeType, state!:#PolicyChangeState, decisionNumber:s, reason!:s, payload:o, requestedBy!:s, requestedAt!:ts, decidedBy:s, decidedAt:ts, rejectReason:s, expiresAt:ts',
    'CapabilityPolicy': 'capability!:#Capability, roleGroup!:s, enabled!:b',
    'ProviderGrant': 'providerId!:u, changeId!:u, grantedBy!:s, validFrom!:ts, validUntil:ts, revokedAt:ts, revokedBy:s, revokeReason:s',
    'AiNotice': 'versionNo!:i, title!:s, contentRef:s, body!:s, status!:e(DRAFT|PUBLISHED|RETIRED), publishedAt:ts, publishedBy:s, accepted:b',
    'KillSwitchRecord': 'scope!:#KillScope, scopeTenant:s, reason!:s, activatedBy!:s, activatedAt!:ts, propagatedAt:ts, releaseRequestedBy:s, releaseRequestedAt:ts, releasedBy:s, releasedAt:ts',
    'ModelProvider': 'providerCode!:code, name!:s, providerKind!:#ProviderKind, status!:#ProviderStatus, protocol!:e(OPENAI_COMPATIBLE|ANTHROPIC_MESSAGES|CUSTOM_HTTP), endpointUrl:s, region:s, '
                     'secretRef:s, commitmentValidTo:d, suspendedReason:s',
    'ProviderCommitment': 'providerId!:u, dataInCountry!:b, noTraining!:b, fileId!:u, validFrom!:d, validTo!:d, state!:e(ACTIVE|EXPIRED|SUPERSEDED), signedBy:s',
    'Model': 'modelCode!:code, name!:s, providerId!:u, modelKind!:#ModelKind, modelScope!:#ModelScope, capabilities!:[s], description:s, status!:e(ACTIVE|RETIRED)',
    'ModelVersion': 'modelId!:u, versionNo!:i, versionLabel!:s, upstreamName!:s, status!:#ModelVersionStatus, contextTokens!:i, embeddingDim:i, priceIn1k:n, priceOut1k:n, params:o, '
                    'submittedBy:s, submittedAt:ts, decidedBy:s, decidedAt:ts, approvedAt:ts, evalRunId:u, redteamRunId:u, rejectReason:s, retiredAt:ts',
    'TenantModel': 'versionId!:u, modelKind!:#ModelKind, enabled!:b, isDefault!:b, fallbackVersionId:u, enabledBy:s, enabledAt:ts, model:#ModelRef',
    'ModelRoute': 'versionId!:u, routeRef!:s, egressHost!:s, priority!:i, status!:#RouteStatus, syncedAt:ts, lastError:s',
    'RouteSyncRun': 'status!:e(REQUESTED|APPLIED|REJECTED|FAILED), requestedBy:s, requestedAt!:ts, finishedAt:ts, snapshotRef:s, errorCode:s',
    'GatewayLimits': 'requestsPerMinute!:i, tokensPerMinute!:i, breakerFailures!:i, breakerOpenSeconds!:i, updatedAt:ts, updatedBy:s',
    'ModelBreaker': 'routeId!:u, versionId!:u, breakerState!:e(CLOSED|HALF_OPEN|OPEN), failureCount!:i, openedAt:ts, resetBy:s, resetAt:ts',
    'ModelHealth': 'versionId!:u, state!:#HealthState, lastProbeAt:ts, latencyMs:i, consecutiveFailures!:i, breakerState:e(CLOSED|HALF_OPEN|OPEN)',
    'KnowledgeSource': 'sourceCode!:code, sourceType!:#SourceType, name!:s, sourceState!:e(ACTIVE|PAUSED|RETIRED), scope:o, schedule:s, lastIndexedAt:ts, documentCount!:i, chunkCount!:i, pausedAt:ts',
    'KnowledgeDocument': 'sourceId!:u, externalRef!:s, title!:s, indexStatus!:#DocumentIndexStatus, classLevel:#ClassLevel, chunkCount!:i, contentHash:s, indexedAt:ts, '
                         'failureCount!:i, lastErrorCode:s, skipReason:s, deleteReason:s, uploadStatus:#UploadStatus',
    'UploadDocument': 'sourceId!:u, title!:s, fileId!:u, uploadStatus!:#UploadStatus, declaredClass!:e(PUBLIC|INTERNAL), uploadedBy!:s, approvedBy:s, approvedAt:ts, rejectReason:s, indexStatus:#DocumentIndexStatus',
    'ClassificationSkip': 'sourceId!:u, externalRef!:s, title:s, classLevel:#ClassLevel, skipReason!:s, checkedAt!:ts',
    'IndexJob': 'sourceId!:u, jobKind!:#IndexJobKind, status!:#IndexJobStatus, triggerRef:s, attempt!:i, startedAt:ts, finishedAt:ts, chunksAdded:i, chunksDeleted:i, chunksSkipped:i, errorCode:s',
    'KnowledgeDeletion': 'sourceId:u, documentId:u, reason!:e(SOURCE_DELETED|CLASS_CHANGED|SOURCE_RETIRED|UPLOAD_STOPPED|PURGE|REVOKED), chunksDeleted!:i, deletedAt!:ts, deletedBy:s',
    'Conversation': 'userId!:s, title:s, state!:#ConversationState, screenContext:#ScreenContext, lastMessageAt:ts, messageCount!:i, expiresAt!:ts, deletedByUserAt:ts',
    'Message': 'conversationId!:u, seq!:i, role!:#MessageRole, content!:s, outcome:#AnswerOutcome, capability:#Capability, modelVersionId:u, tokensIn:i, tokensOut:i, traceId:s, '
               'aiGenerated!:b, citations:[#Citation], toolCalls:[#ToolCallSummary]',
    'SuggestedQuestion': 'questionText!:s, routePattern!:s, capability!:#Capability, sortNo!:i, enabled!:b',
    'Suggestion': 'suggestionKind!:#SuggestionKind, status!:#SuggestionStatus, targetRef:s, confidence:n, reason:s, content!:o, preview:o, expiresAt:ts, decidedAt:ts, modelVersionId:u, aiGenerated!:b',
    'Explanation': 'explanationKind!:e(ERROR_CODE|TRACE|DLQ_MESSAGE|REMEDIATION|INCIDENT_SUMMARY), subjectRef:s, summary!:s, causes:[s], steps:[s], citations:[#Citation], '
                   'aiGenerated!:b, modelVersionId:u, expiresAt:ts',
    'ToolDefinition': 'toolCode!:code, name!:s, targetModule!:s, targetRef!:s, scope!:s, capabilities!:[#Capability], readOnly!:b, timeoutMs!:i, enabled!:b, enabledBy:s, enabledAt:ts',
    'ToolCall': 'messageId!:u, userId!:s, toolCode!:code, depth!:i, argsMasked:o, resultSummary:s, outcome!:e(OK|DENIED|TIMEOUT|ERROR), durationMs!:i, actSubject!:s, occurredAt:ts',
    'GuardrailRule': 'ruleCode!:code, guardrailKind!:#GuardrailKind, action!:#GuardrailAction, category!:e(PROMPT_INJECTION|FORBIDDEN|PII|SECRET|LINK), patternKind!:e(REGEX|KEYWORD|DETECTOR), '
                     'pattern!:s, description:s, builtin!:b, enabled!:b',
    'PromptTemplate': 'templateCode!:code, name!:s, capability!:#Capability, description:s, activeVersionId:u, versions:[#PromptVersion]',
    'PromptVersion': 'templateId!:u, versionNo!:i, status!:#PromptVersionStatus, content!:s, contentHash!:s, evalRunId:u, redteamRunId:u, submittedBy:s, submittedAt:ts, decidedBy:s, decidedAt:ts, activatedAt:ts, rejectReason:s',
    'EvalSet': 'setCode!:code, capability!:#Capability, name!:s, description:s, caseCount!:i, cases:[#EvalCase]',
    'EvalCase': 'setId!:u, caseNo!:i, inputText!:s, expectedOutcome!:s, inputOrigin!:e(SYNTHETIC|PUBLIC_METADATA|ANON_DATASET), datasetLinkId:u, enabled!:b',
    'EvalRun': 'runKind!:e(EVAL|REDTEAM), evalSetId:u, subjectType!:e(MODEL_VERSION|PROMPT_VERSION|EMBED_VERSION|RAG_PARAMS|GUARDRAIL_CODE), subjectId:u, status!:#EvalRunStatus, '
               'triggerKind!:e(MODEL_CHANGE|PROMPT_CHANGE|EMBED_CHANGE|RAG_PARAMS|CODE_CHANGE|MANUAL|SCHEDULE), casesTotal:i, casesPassed:i, casesLeaked:i, score:n, passRate:n, startedAt:ts, finishedAt:ts, errorCode:s',
    'EvalResult': 'runId!:u, caseKind!:e(EVAL|REDTEAM), caseId!:u, passed!:b, score:n, outputMasked:s, blocked:b, note:s',
    'RedteamCase': 'caseCode!:code, category!:#RedteamCategory, attackText!:s, expectedBehavior!:e(BLOCK), status!:e(ACTIVE|RETIRED), origin!:e(SEED|INCIDENT|FEEDBACK), retiredReason:s, retiredAt:ts',
    'Feedback': 'messageId!:u, feedbackKind!:#FeedbackKind, status!:#FeedbackStatus, comment:s, assignedTo:s, closedAt:ts, resolution:s, promotedCaseId:u, dueAt:ts',
    'AiSystemRecord': 'recordCode!:code, name!:s, purpose!:s, models!:[s], dataUsed!:[s], riskLevel!:e(LOW|MEDIUM|HIGH), measures!:[s], ownerUserId!:s, status!:e(ACTIVE|REVIEW_DUE|RETIRED), lastReviewedAt:ts, nextReviewDue:d',
    'LogAccessGrant': 'grantee!:s, granteeRole!:e(SO|AUDITOR), reason!:s, scopeKind!:e(CONVERSATION|RANGE), conversationId:u, rangeFrom:ts, rangeTo:ts, grantedAt!:ts, expiresAt!:ts, state!:#LogAccessGrantState, revokedAt:ts, revokedBy:s',
    'ComplianceExport': 'exportKind!:e(COMPLIANCE_PACK|USAGE_REPORT), state!:#ExportState, periodFrom:ts, periodTo:ts, sha256:s, signatureRef:s, fileId:u, readyAt:ts, expiresAt:ts, requestedBy!:s, errorCode:s',
    'EvalDatasetLink': 'evalSetId!:u, datasetRef!:s, datasetStatus!:e(PUBLISHED|WITHDRAWN|EXPIRED), actualK:i, linkedBy!:s, linkedAt!:ts',
}

PLAIN = {
    'QuotaSettings': 'tenantTokensPerDay!:i, userRequestsPerDay!:i, userTokensPerDay!:i, maxInputChars!:i, maxTurns!:i, maxConversations!:i',
    'ModelRef': 'modelCode!:code, name!:s, versionLabel!:s, providerKind!:#ProviderKind',
    'ScreenContext': 'route!:s, objectRef:s, errorCode:s, tab:s',
    'Citation': 'rank!:i, chunkId:u, sourceId:u, objectRef!:s, title:s, linkRoute!:s, score!:n',
    'ToolCallSummary': 'toolCode!:code, depth!:i, outcome!:e(OK|DENIED|TIMEOUT|ERROR), durationMs!:i',
    'AssistStatus': 'enabled!:b, state!:#TenantAssistState, capabilities!:[#Capability], noticeRequired!:b, noticeVersion:i, remainingRequests!:i, remainingTokens!:i, killSwitchActive!:b',
    'UsageMe': 'day!:d, requestsUsed!:i, requestsLimit!:i, tokensUsed!:i, tokensLimit!:i',
    'KillSwitchState': 'tenant:#KillSwitchRecord, platform:#KillSwitchRecord, effective!:b',
    'ModelVersionDetail': 'version!:#ModelVersion, model:#Model, routes:[#ModelRoute], gate:#ReleaseGate',
    'ModelDetail': 'model!:#Model, versions!:[#ModelVersion]',
    'InvocationRecord': 'id!:u, occurredAt!:ts, capability!:#Capability, modelVersionId!:u, routeId:u, callerKind!:e(USER|DU), callerRef!:s, messageId:u, requestRef!:s, tokensIn!:i, tokensOut!:i, '
                        'latencyMs!:i, firstTokenMs:i, result!:#InvocationResult, errorCode:s, fallbackFromId:u, estCost!:n, traceId!:s',
    'InvocationStats': 'from!:ts, to!:ts, rows!:[#InvocationStatRow], totalCalls!:i, totalTokens!:i, estCost!:n',
    'InvocationStatRow': 'modelVersionId!:u, capability!:#Capability, result!:#InvocationResult, calls!:i, tokensIn!:i, tokensOut!:i, p95LatencyMs:i',
    'HealthProbe': 'checkedAt!:ts, state!:#HealthState, latencyMs:i, errorCode:s, probeKind!:e(SCHEDULED|MANUAL)',
    'KnowledgeStatus': 'sources!:i, documents!:i, chunks!:i, pendingJobs!:i, failedDocuments!:i, skippedByClass!:i, oldestUnindexedAt:ts, embeddingVersionId:u',
    'SourceHealth': 'sourceId!:u, state!:e(ACTIVE|PAUSED|RETIRED), freshnessSeconds:i, documents!:i, chunks!:i, failedDocuments!:i, lastJob:#IndexJob',
    'KnowledgeDocumentDetail': 'document!:#KnowledgeDocument, chunks!:[#ChunkSummary]',
    'ChunkSummary': 'chunkNo!:i, classLevel!:#ClassLevel, tokenCount!:i, contentPreview!:s, aclVisibility!:e(TENANT|ORG|ROLE)',
    'SearchResult': 'results!:[#SearchHit], aiGenerated!:b, traceId:s',
    'SearchHit': 'objectRef!:s, title!:s, snippet!:s, linkRoute!:s, score!:n, sourceType!:#SourceType',
    'MessageAnswer': 'message!:#Message, aiGenerated!:b, notice:s',
    'ScreenContextResult': 'valid!:b, capabilities!:[#Capability], actions!:[#ScreenAction], suggestedQuestions:[#SuggestedQuestion]',
    'ScreenAction': 'code!:code, label!:s, capability!:#Capability',
    'MappingSuggestionResult': 'suggestion!:#Suggestion, items!:[#MappingItem], aiGenerated!:b',
    'MappingItem': 'sourceField!:s, targetField!:s, expression:s, confidence!:n, reason:s',
    'ExpressionCheckResult': 'valid!:b, error:s, sampleOutput:o',
    'SuggestionPreview': 'suggestionId!:u, target!:s, changes!:[#PreviewChange], draftVersion:i',
    'PreviewChange': 'path!:s, before:o, after:o',
    'ApplyResult': 'suggestionId!:u, applied!:b, targetModule!:s, draftRef!:s, appliedBy!:s, appliedAt!:ts',
    'RedactionPreview': 'masked!:s, maskedCount!:i, patterns!:[s]',
    'ToolLimits': 'maxCallsPerTurn!:i, maxDepth!:i, timeoutMs!:i',
    'GuardrailTestResult': 'matched!:b, action:#GuardrailAction, matchedText:s',
    'LinkAllowlist': 'prefixes!:[#LinkPrefix]',
    'LinkPrefix': 'routePrefix!:s, note:s',
    'ReleaseGate': 'subjectType!:e(MODEL_VERSION|PROMPT_VERSION), subjectId!:u, evalPassed!:b, evalScore:n, minScore!:n, redteamPassed!:b, casesLeaked!:i, redteamCasesActive!:i, minRedteamCases!:i, '
                   'fourEyesReady!:b, open!:b, blockers!:[s]',
    'QualityMetric': 'metricDate!:d, period!:e(DAY|WEEK), capability:#Capability, metricCode!:e(CITED_RATE|NO_SOURCE_RATE|ACCEPT_RATE|EVAL_SCORE|HELPFUL_RATE|BLOCKED_RATE|LATENCY_P95_MS), '
                     'value!:n, sampleCount!:i, baselineValue:n',
    'QualityAlert': 'metricCode!:s, capability:#Capability, value!:n, threshold!:n, raisedAt!:ts, status!:e(OPEN|ACKNOWLEDGED)',
    'QualityThresholds': 'thresholds!:[#QualityThreshold]',
    'QualityThreshold': 'metricCode!:s, capability:#Capability, minValue:n, maxValue:n',
    'LogConversation': 'conversationId!:u, userId!:s, title:s, createdAt!:ts, messageCount!:i, expiresAt!:ts, state!:#ConversationState',
    'LogConversationDetail': 'conversation!:#LogConversation, messages!:[#Message], grantId!:u, grantExpiresAt!:ts',
    'LogRetention': 'retentionDays!:i, floorDays!:i, lastPurgeAt:ts, lastPurgedConversations:i, nextPurgeAt:ts',
    'UsageReport': 'from!:ts, to!:ts, rows!:[#UsageRow], totalRequests!:i, totalTokens!:i, estCost!:n',
    'UsageRow': 'day!:d, capability!:#Capability, modelVersionId:u, requests!:i, tokensIn!:i, tokensOut!:i, estCost!:n',
    'SettingList': 'items!:[#SettingItem]',
    'SettingItem': 'key!:s, value!:o, defaultValue:o, floorValue:o, ceilingValue:o, fourEyes!:b, unit:s, description:s',
    'SettingSchema': 'items!:[#SettingItem]',
    'ProblemDetails': 'type!:s, title!:s, status!:i, detail:s, code!:s, traceId!:s, instance:s, errors:[#FieldError]',
    'FieldError': 'field!:s, message!:s',
    # dữ liệu data plane
    'InferenceTask': 'taskCode!:code, name!:s, inputSchemaVersion!:i, maxInputChars!:i',
    'InferenceTaskList': 'tasks!:[#InferenceTask]',
    'ClassifyResult': 'label!:s, confidence!:n, modelVersionId!:u, requestRef!:s, aiGenerated!:b',
    'ExtractResult': 'fields!:o, missing:[s], confidence!:n, modelVersionId!:u, requestRef!:s, aiGenerated!:b',
    'ProcessSuggestionResult': 'suggestionId!:u, summary!:s, options:[#ProcessOption], requiresHumanDecision!:b, modelVersionId!:u, aiGenerated!:b',
    'ProcessOption': 'code!:s, label!:s, rationale:s',
    'EffectiveConfig': 'enabled!:b, state!:#TenantAssistState, capabilities!:[#Capability], models!:[#ModelRef], killSwitchActive!:b, bundleVersion:i',
    'ReadyStatus': 'ready!:b, checks!:[#ReadyCheck]',
    'ReadyCheck': 'name!:s, ok!:b, detail:s',
}

INPUT = {
    'PolicyChangeInput': 'changeType!:#PolicyChangeType, decisionNumber:s, reason!:s, capabilities:[#CapabilityPolicyInput], providerCodes:[code], settingKey:s, settingValue:o',
    'ReasonInput': 'reason!:s',
    'ApproveInput': 'comment:s',
    'CapabilityPolicySet': 'capabilities!:[#CapabilityPolicyInput]',
    'CapabilityPolicyInput': 'capability!:#Capability, roleGroup!:s, enabled!:b',
    'ProviderGrantInput': 'providerId!:u, changeId!:u, validUntil:ts',
    'AiNoticeInput': 'title!:s, body!:s, contentRef:s',
    'KillSwitchInput': 'reason!:s, scope:#KillScope, tenantIds:[s]',
    'ModelProviderInput': 'providerCode!:code, name!:s, providerKind!:#ProviderKind, protocol!:e(OPENAI_COMPATIBLE|ANTHROPIC_MESSAGES|CUSTOM_HTTP), endpointUrl:s, region:s, secretRef:s',
    'ModelProviderPatch': 'name:s, endpointUrl:s, region:s, secretRef:s',
    'ProviderCommitmentInput': 'dataInCountry!:b, noTraining!:b, fileId!:u, validFrom!:d, validTo!:d',
    'ModelInput': 'modelCode!:code, name!:s, providerId!:u, modelKind!:#ModelKind, modelScope:#ModelScope, capabilities!:[s], description:s',
    'ModelPatch': 'name:s, description:s, capabilities:[s]',
    'ModelVersionInput': 'versionLabel!:s, upstreamName!:s, contextTokens!:i, embeddingDim:i, priceIn1k:n, priceOut1k:n, params:o',
    'ModelVersionPatch': 'contextTokens:i, priceIn1k:n, priceOut1k:n, params:o',
    'TenantModelDefaultsInput': 'defaults!:[#ModelDefault]',
    'ModelDefault': 'modelKind!:#ModelKind, versionId!:u, fallbackVersionId:u',
    'GatewayLimitsInput': 'requestsPerMinute!:i, tokensPerMinute!:i, breakerFailures!:i, breakerOpenSeconds!:i',
    'RouteSyncInput': 'versionIds:[u], reason:s',
    'KnowledgeSourceInput': 'sourceCode!:code, sourceType!:#SourceType, name!:s, scope:o, schedule:s',
    'KnowledgeSourcePatch': 'name:s, scope:o, schedule:s',
    'CheckClassInput': 'externalRefs!:[s]',
    'FullReindexInput': 'reason:s',
    'UploadInput': 'sourceId!:u, title!:s, fileId!:u, declaredClass!:e(PUBLIC|INTERNAL)',
    'ConversationInput': 'title:s, screenContext:#ScreenContext',
    'MessageInput': 'content!:s, capability:#Capability, clientMessageId!:u, screenContext:#ScreenContext',
    'SearchInput': 'query!:s, sourceTypes:[#SourceType], limit:i',
    'SuggestedQuestionInput': 'questionText!:s, routePattern!:s, capability!:#Capability, sortNo:i, enabled:b',
    'ScreenContextInput': 'screenContext!:#ScreenContext',
    'MappingSuggestionInput': 'sourceSchemaRef!:s, targetSchemaRef!:s, sourceFields!:[s], targetFields!:[s], sampleRef:s, flowRef:s',
    'ExpressionCheckInput': 'expression!:s, sample!:o',
    'CodeMappingInput': 'localCodes!:[s], catalogCode!:code, localCatalogRef:s',
    'SuggestionEditInput': 'content!:o, comment:s',
    'ErrorCodeInput': 'errorCode!:s, context:o',
    'TraceInput': 'traceId!:s, window:i',
    'DlqMessageInput': 'messageRef!:s, maskedSample:o',
    'RemediationInput': 'explanationId:u, errorCode:s, subjectRef:s',
    'IncidentSummaryInput': 'incidentRef:s, traceIds:[s], from:ts, to:ts',
    'RedactionInput': 'lines!:[s]',
    'ToolEnablementInput': 'enabled!:b, reason:s',
    'ToolLimitsInput': 'maxCallsPerTurn!:i, maxDepth!:i, timeoutMs!:i',
    'GuardrailRuleInput': 'ruleCode!:code, guardrailKind!:#GuardrailKind, action!:#GuardrailAction, category!:e(PROMPT_INJECTION|FORBIDDEN|PII|SECRET|LINK), patternKind!:e(REGEX|KEYWORD|DETECTOR), pattern!:s, description:s',
    'GuardrailRulePatch': 'action:#GuardrailAction, pattern:s, description:s, enabled:b',
    'GuardrailTestInput': 'samples!:[s]',
    'LinkAllowlistInput': 'prefixes!:[#LinkPrefix]',
    'PromptTemplateInput': 'templateCode!:code, name!:s, capability!:#Capability, description:s',
    'PromptVersionInput': 'content!:s',
    'EvalSetInput': 'setCode!:code, capability!:#Capability, name!:s, description:s',
    'EvalCaseInput': 'inputText!:s, expectedOutcome!:s, inputOrigin!:e(SYNTHETIC|PUBLIC_METADATA|ANON_DATASET), datasetLinkId:u',
    'EvalCasePatch': 'inputText:s, expectedOutcome:s, enabled:b',
    'EvalRunInput': 'evalSetId!:u, subjectType!:e(MODEL_VERSION|PROMPT_VERSION|EMBED_VERSION|RAG_PARAMS|GUARDRAIL_CODE), subjectId:u',
    'RedteamCaseInput': 'caseCode!:code, category!:#RedteamCategory, attackText!:s',
    'RedteamCasePatch': 'attackText:s, status:e(ACTIVE|RETIRED), retiredReason:s',
    'RedteamRunInput': 'subjectType!:e(MODEL_VERSION|PROMPT_VERSION|GUARDRAIL_CODE), subjectId:u',
    'FeedbackInput': 'messageId!:u, feedbackKind!:#FeedbackKind, comment:s',
    'FeedbackTriageInput': 'assignedTo!:s, comment:s',
    'FeedbackResolveInput': 'resolution!:s',
    'QualityThresholdsInput': 'thresholds!:[#QualityThreshold]',
    'AiSystemRecordInput': 'recordCode!:code, name!:s, purpose!:s, models!:[s], dataUsed!:[s], riskLevel!:e(LOW|MEDIUM|HIGH), measures!:[s], ownerUserId!:s',
    'AiSystemRecordPatch': 'purpose:s, models:[s], dataUsed:[s], riskLevel:e(LOW|MEDIUM|HIGH), measures:[s], ownerUserId:s',
    'AiSystemRecordReviewInput': 'note!:s, nextReviewDue:d',
    'LogAccessGrantInput': 'reason!:s, scopeKind!:e(CONVERSATION|RANGE), conversationId:u, rangeFrom:ts, rangeTo:ts',
    'ComplianceExportInput': 'exportKind!:e(COMPLIANCE_PACK|USAGE_REPORT), periodFrom!:ts, periodTo!:ts',
    'SettingValueInput': 'value!:o, reason:s',
    'EvalDatasetLinkInput': 'evalSetId!:u, datasetRef!:s',
    'ClassifyInput': 'taskCode!:code, text!:s, labels:[s], purposeCode!:code, dataClass!:#ClassLevel',
    'ExtractInput': 'taskCode!:code, text!:s, fields!:[s], purposeCode!:code, dataClass!:#ClassLevel',
    'ProcessSuggestionInput': 'stepType!:e(APPROVAL|DATA_ENTRY), processRef!:s, formSchemaRef:s, context:o, purposeCode!:code',
    'DecisionInput': 'decision!:e(ACCEPTED|EDITED|REJECTED), decidedBy!:s, decidedAt!:ts',
}


def build(enums):
    S = {}
    for name, vals in enums.items():
        S[name] = {'type': 'string', 'enum': vals}
    S['Code'] = {'type': 'string', 'pattern': '^[A-Z][A-Z0-9_-]{1,47}$', 'description': 'Mã nghiệp vụ chữ hoa, số, `_`, `-`.'}
    S['SettingKey'] = {'type': 'string', 'pattern': '^17\\.[a-z0-9.-]+$', 'description': 'Khóa tham số `17.*` (FRS 8.2).'}
    for n, sp in READ.items():
        S[n] = obj(sp, CTX)
    for grp in (PLAIN, INPUT):
        for n, sp in grp.items():
            if sp is None:
                continue
            S[n] = obj(sp)
    for n in list(S):
        if n.endswith('Patch') and 'required' in S[n]:
            del S[n]['required']
    return S
