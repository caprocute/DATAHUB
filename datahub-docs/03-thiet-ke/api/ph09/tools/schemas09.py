#!/usr/bin/env python3
"""Lược đồ thành phần (components.schemas) của OpenAPI PH-09, viết bằng ngôn ngữ khai báo ngắn.

Mỗi dòng: `Tên: trường, trường, ...`; trường là `tên[!]:kiểu`, dấu `!` là bắt buộc.
Kiểu: s (chuỗi), sN (chuỗi tối đa N), i, n, b, ts (date-time), d (date), u (uuid), o (đối tượng tự do),
code (mã nghiệp vụ), hash (băm HMAC base64), `[kiểu]` (mảng), `#Tên` ($ref), `e(A|B)` (enum nhỏ tại chỗ).
Enum Phụ lục A đọc từ FRS (gen_openapi.py), nên tên enum dùng `#TênEnum`. Tên trường là camelCase của cột bảng
ở D03-03-PH09. Không có trường nào mang giá trị DLCN rõ ngoài các yêu cầu có chủ đích (định danh chủ thể trong
`SubjectRequestInput`, giá trị khi xem đầy đủ trong `RevealGrantIssued`); các trường đó có `x-dh-classification`.
"""
import re

CTX = 'id!:u, version!:i, createdAt:ts, createdBy:s, updatedAt:ts, updatedBy:s'
VER = ('versionNo!:i, status!:#VersionStatus, submittedBy:s, submittedAt:ts, decidedBy:s, decidedAt:ts, '
       'decisionComment:s, activatedAt:ts, supersededAt:ts')

# --- bản đọc (có CTX)
READ = {
    'DataClassPolicy': 'code!:#DataClass, rank!:i, name!:s, logPolicy!:#LogPolicy, displayPolicy!:#DisplayPolicy, encryptAtApp!:b',
    'BlockLabelRecord': 'label!:#BlockLabel, targetKind!:#TargetKind, targetId!:s, legalDoc!:s, assignedBy!:s, status!:e(ACTIVE|RELEASE_REQUESTED|RELEASED), '
                        'releaseRequestedBy:s, releaseRequestedAt:ts, releaseDoc:s, releasedBy:s, releasedAt:ts',
    'PersonalDataCategory': 'code!:code, name!:s, personalDataType!:#PersonalDataType, defaultClass!:#DataClass, defaultMaskPattern:#MaskPatternKind, '
                            'identifierKind:#IdentifierKind, builtin!:b, status!:#ElementStatus',
    'DataElement': 'scope!:#ElementScope, target!:s, contractRef:s, ownerOrgId!:s, source!:#ClassificationSource, status!:#ElementStatus, '
                   'declaredClass:#DataClass, classification:#ElementClassification, retiredAt:ts',
    'ElementClassification': 'elementId!:u, dataClass!:#DataClass, personalDataType!:#PersonalDataType, categoryCode:code, identifiability!:#IdentifiabilityType, '
                             'maskPattern:#MaskPatternKind, neverReveal!:b, noEgress!:b, status!:#ClassificationStatus, source!:#ClassificationSource, basis:s, '
                             'confirmedBy:s, confirmedAt:ts',
    'ClassificationChange': 'elementId!:u, fromClass:#DataClass, toClass!:#DataClass, fromPersonalDataType:#PersonalDataType, toPersonalDataType!:#PersonalDataType, '
                            'status!:#ClassificationStatus, basis:s, reason:s, proposedBy!:s, confirmedBy:s, confirmedAt:ts, confirmedBy2:s, confirmedAt2:ts, '
                            'rejectComment:s, source!:#ClassificationSource, downgrade!:b',
    'DetectorRule': 'detectorCode!:#DetectorType, name!:s, pattern:s, hasChecksum!:b, confidenceThreshold!:n, enabled!:b, builtin!:b',
    'ScanRun': 'scope!:o, sampleRows!:i, detectors!:[#DetectorType], status!:#ScanStatus, requestedBy:s, startedAt:ts, finishedAt:ts, suspectCount!:i, errorCode:s',
    'ScanFinding': 'scanId!:u, elementId:u, target!:s, detectorCode!:#DetectorType, confidence!:n, status!:#FindingStatus, resolutionNote:s',
    'ContractLevel': 'contractKind!:#ContractKind, contractId!:s, dataClass!:#DataClass, provisional!:b, blocked!:b, elementCount!:i, basis:o, computedAt!:ts',
    'ExportJob': 'status!:e(QUEUED|RUNNING|COMPLETED|FAILED), format!:#ReportFormat, fileRef:s, downloadUrl:s, expiresAt:ts, rowCount:i, requestedBy:s',
    'ProcessingActivity': 'code!:code, ' + VER + ', purposeText!:s, legalBasisCode!:code, legalDocIds!:[u], categories!:[code], subjectGroups!:[s], recipients:[s], '
                          'controllerRole!:#ControllerRole, measures:[s], retention!:#RetentionPolicy',
    'ActivityLink': 'activityId!:u, targetKind!:#TargetKind, targetId!:s',
    'LegalBasis': 'code!:code, basisType!:#LegalBasisType, name!:s, rule:s, status!:#ElementStatus, retiredAt:ts',
    'LegalDocument': 'code!:code, title!:s, docNo!:s, effectiveFrom!:d, effectiveTo:d, status!:#ElementStatus',
    'RopaTemplate': 'code!:code, name!:s, formats!:[#ReportFormat]',
    'Purpose': 'code!:code, name!:s, description:s, legalBasisCode!:code, allowedCategories!:[code], statutory!:b, maxDays:i, status!:#PurposeStatus',
    'AccessRequest': 'htttId!:s, registrationRef:s, ownerOrgId!:s, purposeCode!:code, contractKind!:#ContractKind, contractId!:s, fields!:[s], expectedVolume:i, '
                     'requestedDays!:i, justification!:s, status!:#AccessRequestStatus, submittedAt:ts, reviewer:s, decision:#AccessDecision, decisionReason:s, '
                     'decidedBy:s, decidedAt:ts, dueAt:ts, requestKind!:#AccessRequestKind, renewsGrantId:u',
    'PurposeGrant': 'htttId!:s, purposeCode!:code, contractKind!:#ContractKind, contractId!:s, requestId:u, fields!:[s], validFrom!:ts, validUntil!:ts, '
                    'status!:#GrantStatus, renewCount!:i, conditions!:[#GrantCondition], suspendedReason:s, revokedReason:s, revokedBy:s, revokedAt:ts',
    'PolicyBundle': 'bundleNo!:i, objectRef!:s, sizeBytes!:i, sha256!:s, testPassed!:b, publishedAt:ts, validUntil!:ts, signingKeyRef!:s, trigger!:e(AUTO|MANUAL|ROLLBACK)',
    'BundleSyncStatus': 'currentBundleNo!:i, points!:[#BundleSyncPoint], maxLagSeconds!:i',
    'UsageAnomaly': 'anomalyType!:#AnomalyType, htttId!:s, purposeCode:code, contractId:s, status!:#AnomalyStatus, detectedAt!:ts, evidence:o, handledBy:s, handledAt:ts, note:s',
    'AnomalyRules': 'quotaWarnPercent!:i, bulkThreshold!:i, offHours:s, dormantDays!:i, autoSuspend!:b',
    'UsageReport': 'from!:ts, to!:ts, rows!:[#UsageRow], totalAllowed!:i, totalDenied!:i, totalOffPurpose!:i',
    'ActivationCheck': 'contractKind!:#ContractKind, contractId!:s, dataClass!:#DataClass, allowed!:b, blockers!:[#Blocker]',
    'MaskTypeDef': 'code!:code, maskType!:#MaskType, patternKind:#MaskPatternKind, name!:s, defaultParams:o, reversible!:b, builtin!:b',
    'MaskPolicy': 'code!:code, ' + VER + ', scope!:#MaskPolicyScope, contractKind:#ContractKind, contractId:s, description:s, passedSimulationId:u, rules!:[#MaskRule]',
    'MaskSimulation': 'policyId!:u, policyVersion!:i, rowCount!:i, passed!:b, issues!:[#SimulationIssue], sampleResult:[o]',
    'RevealGrant': 'requestedBy!:s, elementId:u, status!:#RevealStatus, issuedAt!:ts, expiresAt!:ts, verifiedAt:ts',
    'LogMaskConfig': 'maskedPatterns!:[#DetectorType], scanWindowHours!:i, enabled!:b',
    'LeakFinding': 'detectorCode!:#DetectorType, source!:s, firstSeenAt!:ts, occurrences!:i, status!:#FindingStatus, resolutionNote:s',
    'LeakScan': 'status!:#ScanStatus, startedAt:ts, finishedAt:ts, findingCount!:i',
    'PseudonymDomain': 'domainCode!:code, purposeCode!:code, method!:#PseudonymMethod, rotateDays!:i, description:s, status!:#PseudonymDomainStatus, '
                       'currentKeyVersion!:i, lastRotatedAt:ts',
    'PseudonymKey': 'domainId!:u, keyVersion!:i, status!:#KeyVersionStatus, openbaoRef!:s, activatedAt:ts, disabledAt:ts, destroyRequestedBy:s, destroyedAt:ts',
    'ReidentificationRequest': 'domainId!:u, tokenCount!:i, purposeCode!:code, basis!:s, reason!:s, status!:#ReidStatus, requestedBy!:s, mfaVerified!:b, '
                               'l1By:s, l1At:ts, l2By:s, l2At:ts, approvalExpiresAt:ts, execDeadlineAt:ts, executedBy:s, executedAt:ts, rejectReason:s',
    'AnonymizationConfig': 'configCode!:code, ' + VER + ', privacyModel!:#PrivacyModel, k!:i, l:i, rules!:[#AnonRule], hierarchies:o, purposeCode!:code',
    'AnonymizationJob': 'configId!:u, sourceRef!:s, status!:#AnonJobStatus, target!:#DataPrepTarget, generalizationRounds:i, actualK:i, riskLevel:#RiskLevel, '
                        'startedAt:ts, finishedAt:ts, errorCode:s',
    'RiskReport': 'jobId:u, riskModel!:#RiskModel, riskLevel!:#RiskLevel, riskValue!:n, quasiIdentifiers!:[s], smallGroupRatio!:n, recommendations:[s], approvedBy:s, approvedAt:ts',
    'DataPreparation': 'target!:#DataPrepTarget, sourceRef!:s, purposeCode!:code, status!:#AnonJobStatus, jobId:u, datasetId:u, requestedBy!:s',
    'AnonymizedDataset': 'jobId!:u, status!:#DatasetStatus, objectRef!:s, rowCount!:i, actualK!:i, riskLevel!:#RiskLevel, usageTerms:s, expiresAt:ts, publishedAt:ts, withdrawReason:s',
    'RetentionSchedule': 'code!:code, ' + VER + ', lines!:[#RetentionLine]',
    'RetentionTask': 'tableName!:s, action!:#RetentionAction, status!:#RetentionTaskStatus, dryRun!:b, rowsProcessed:i, rowsSkippedHold:i, startedAt:ts, finishedAt:ts, errorCode:s',
    'LegalHold': 'scope!:o, basisDoc!:s, basisDate!:d, authority!:s, reviewOn:d, status!:#LegalHoldStatus, placedBy!:s, releasedBy:s, releasedAt:ts, releaseReason:s',
    'TenantShredRequest': 'status!:#CryptoShredStatus, exportConfirmed!:b, reason!:s, requestedBy!:s, approvedBy:s, approvedBy2:s, waitUntil:ts, executedAt:ts',
    'RetentionReport': 'asOf!:ts, rows!:[#RetentionReportRow], overdueCount!:i',
    'SubjectRequest': 'requestType!:#DsrType, status!:#DsrStatus, channel!:#DsrChannel, identifierType!:#SubjectIdentifierType, receivedAt!:ts, dueAt!:ts, overdue!:b, '
                      'verifiedAt:ts, assignedTo:s, outcome:#DsrOutcome, refusalBasis:s, responseRef:s, respondedAt:ts, closedAt:ts, restrictionActive!:b, subjectHash!:hash',
    'SubjectFinding': 'requestId!:u, target!:#DsrTarget, location!:s, recordCount!:i, categories!:[code]',
    'SubjectTask': 'requestId!:u, target!:#DsrTarget, status!:#DsrTaskStatus, externalRef:s, completedAt:ts, refusalReason:s',
    'AccessReport': 'requestId!:u, from!:ts, to!:ts, fileRef:s, entryCount:i, status!:e(QUEUED|COMPLETED|FAILED)',
    'SubjectRequestReport': 'from!:ts, to!:ts, received!:i, closedInTime!:i, overdue!:i, byType!:o',
    'ConsentTemplate': 'templateCode!:code, ' + VER + ', purposeCode!:code, title!:s, text!:s, dataProcessed!:[code], withdrawalGuide!:s, validityDays:i',
    'ConsentRecord': 'templateCode!:code, templateVersion!:i, subjectHash!:hash, status!:#ConsentStatus, channel!:#ConsentChannel, givenAt!:ts, expiresAt:ts, '
                     'withdrawnAt:ts, withdrawnChannel:#ConsentChannel, recordedBy:s',
    'ConsentProof': 'consentId!:u, templateCode!:code, templateVersion!:i, textHash!:s, channel!:#ConsentChannel, givenAt!:ts, evidence!:o, withdrawEvidence:o',
    'DpiaRecord': 'dpiaCode!:code, status!:#DpiaStatus, ' + VER.replace('status!:#VersionStatus, ', '') + ', activityId:u, dpiaKind!:#DpiaKind, description!:s, '
                  'risks!:[o], measures!:[o], reviewOn:d, submittedA05At:ts, a05Ref:s',
    'BreachCase': 'detectedAt!:ts, deadlineAt!:ts, source!:#BreachSource, description!:s, dataTypes!:[code], estimatedSubjects:i, incidentRef:s, '
                  'status!:#BreachStatus, severity:#BreachSeverity, reportedBy!:s, assessedBy:s, assessedAt:ts, notifiedA05At:ts, exemptBasis:s, '
                  'notBreachReason:s, affectedCount:i, lessons:s',
    'BreachClock': 'breachId!:u, detectedAt!:ts, deadlineAt!:ts, remainingMinutes!:i, level!:e(OK|WARN_24|WARN_48|WARN_60|OVERDUE), notifiedA05At:ts',
    'BreachNotification': 'breachId!:u, recipient!:#NotificationRecipient, status!:#NotificationStatus, draftRef:s, sentAt:ts, evidenceRef:s',
    'BreachAction': 'breachId!:u, description!:s, owner:s, dueAt:ts, doneAt:ts',
    'AuditEvent': 'occurredAt!:ts, actor!:s, action!:s, targetType!:s, targetId:s, outcome!:e(SUCCESS|DENIED|FAILED), purposeCode:code, traceId:s, details:o',
    'ComplianceDashboard': 'asOf!:ts, metrics!:[#DashboardMetric]',
    'DashboardMetric': 'code!:s, name!:s, value!:n, unit:s, trend:[n], link:s',
    'ComplianceReport': 'period!:s, status!:e(QUEUED|COMPLETED|FAILED), format!:#ReportFormat, fileRef:s, generatedAt:ts',
    'ReportSchedule': 'cron!:s, format!:#ReportFormat, enabled!:b, recipients:[s]',
    'SettingChange': 'key!:s, oldValue:o, newValue!:o, changedBy!:s, changedAt!:ts, reason:s',
}

# --- đối tượng con, không có CTX
PLAIN = {
    'Code': None,
    'RetentionPolicy': 'days!:i, action!:#RetentionAction, legalHoldAware:b',
    'GrantCondition': 'conditionType!:#ConditionType, params!:o',
    'BundleSyncPoint': 'pep!:s, bundleNo!:i, lagSeconds!:i, loadedAt:ts',
    'UsageRow': 'bucket!:ts, htttId!:s, purposeCode!:code, contractId:s, allowed!:i, denied!:i, offPurpose!:i',
    'Blocker': 'code!:s, message!:s',
    'MaskRule': 'seq!:i, priority!:i, condClass:#DataClass, condCategory:code, condPurpose:code, condRoles:[s], condChannel:#MaskChannel, maskType!:#MaskType, patternKind:#MaskPatternKind, params:o',
    'SimulationIssue': 'rowIndex:i, field:s, message!:s',
    'AnonRule': 'field!:s, identifiability!:#IdentifiabilityType, transform!:s, params:o',
    'RetentionLine': 'tableName!:s, retainDays!:i, action!:#RetentionAction, basis:s',
    'RetentionReportRow': 'tableName!:s, action!:#RetentionAction, dueRows!:i, overdueRows!:i, heldRows!:i',
    'Setting': 'key!:s, value!:o, defaultValue:o, floorValue:o, ceilingValue:o, source:e(DEFAULT|TENANT), updatedAt:ts',
    'SettingList': 'items!:[#Setting]',
    'BulkResult': 'created!:i, updated!:i, skipped!:i, errors!:[#ItemError]',
    'ItemError': 'index!:i, code!:s, message!:s',
    'ImportResult': 'proposed!:i, skipped!:i, errors!:[#ItemError]',
    'JobAccepted': 'jobId!:u, status!:e(QUEUED|RUNNING), statusUrl!:s',
    'DossierFile': 'breachId!:u, fileRef!:s, downloadUrl!:s, expiresAt!:ts',
    'ReidExecuteResult': 'requestId!:u, status!:#ReidStatus, tokenCount!:i, resultRef!:s, expiresAt!:ts',
    'ProblemDetails': 'type!:s, title!:s, status!:i, detail:s, instance:s, code!:s, traceId!:s, errors:[#FieldError]',
    'FieldError': 'field!:s, message!:s, max:i, min:i',
    'MaskPolicyDiff': 'fromVersion!:i, toVersion!:i, added!:[#MaskRule], removed!:[#MaskRule], changed!:[o]',
    'OpaBundle': 'bundleNo!:i',
}

# --- đầu vào
INPUT = {
    'DataClassPatch': 'logPolicy:#LogPolicy, displayPolicy:#DisplayPolicy',
    'BlockLabelInput': 'targetKind!:#TargetKind, targetId!:s, legalDoc!:s',
    'ReleaseRequestInput': 'releaseDoc!:s, reason!:s20',
    'ReleaseApproveInput': 'releaseDocNo!:s, releaseDocDate!:d, comment:s',
    'PersonalDataCategoryInput': 'code!:code, name!:s, personalDataType!:#PersonalDataType, defaultClass!:#DataClass, defaultMaskPattern:#MaskPatternKind, identifierKind:#IdentifierKind',
    'PersonalDataCategoryPatch': 'name:s, defaultClass:#DataClass, defaultMaskPattern:#MaskPatternKind, status:#ElementStatus',
    'ElementRegisterInput': 'items!:[#ElementRegisterItem]',
    'ElementRegisterItem': 'scope!:#ElementScope, target!:s, contractRef:s, ownerOrgId!:s, declaredClass:#DataClass',
    'ImportSchemaInput': 'format!:e(OPENAPI|JSON_SCHEMA|AVRO), contractKind!:#ContractKind, contractId!:s, ownerOrgId!:s, content!:s',
    'ImportDeclarationsInput': 'contractKind!:#ContractKind, contractId!:s, ownerOrgId!:s, declarations!:[o]',
    'ClassificationProposalInput': 'dataClass!:#DataClass, personalDataType!:#PersonalDataType, categoryCode:code, identifiability!:#IdentifiabilityType, maskPattern:#MaskPatternKind, noEgress:b, basis:s, reason:s',
    'ClassificationConfirmInput': 'comment:s',
    'ClassificationBulkConfirmInput': 'changeIds!:[u], comment:s',
    'RejectInput': 'reason!:s20',
    'ScanRunInput': 'scope!:o, sampleRows:i, detectors:[#DetectorType]',
    'FindingResolveInput': 'resolution!:e(CLASSIFY|EXCLUDE|FIXED), proposal:#ClassificationProposalInput, note:s',
    'DetectorRuleInput': 'name!:s, pattern:s, confidenceThreshold!:n, enabled!:b',
    'RecomputeInput': 'contractKind!:#ContractKind, contractId:s',
    'ExportInput': 'format!:#ReportFormat, filter:o, templateCode:code',
    'ProcessingActivityInput': 'code!:code, purposeText!:s, legalBasisCode!:code, legalDocIds!:[u], categories!:[code], subjectGroups!:[s], recipients:[s], '
                               'controllerRole!:#ControllerRole, measures:[s], retention!:#RetentionPolicy',
    'SubmitInput': 'comment:s',
    'ApproveInput': 'comment:s',
    'RetireInput': 'reason!:s20',
    'ReasonInput': 'reason!:s20',
    'CommentInput': 'comment:s',
    'ExtendInput': 'newDueAt!:ts, reason!:s20',
    'ConsentSearchInput': 'identifierType!:#SubjectIdentifierType, identifier!:s, templateCode:code, status:#ConsentStatus',
    'ActivityLinkInput': 'targetKind!:#TargetKind, targetId!:s',
    'LegalBasisInput': 'code!:code, basisType!:#LegalBasisType, name!:s, rule:s',
    'LegalBasisPatch': 'name:s, rule:s, status:#ElementStatus',
    'LegalDocumentInput': 'code!:code, title!:s, docNo!:s, effectiveFrom!:d, effectiveTo:d',
    'LegalDocumentPatch': 'effectiveTo:d, status:#ElementStatus',
    'PurposeInput': 'code!:code, name!:s, description:s, legalBasisCode!:code, allowedCategories!:[code], statutory:b, maxDays:i',
    'PurposePatch': 'name:s, description:s, allowedCategories:[code], maxDays:i',
    'AccessRequestInput': 'htttId!:s, registrationRef:s, purposeCode!:code, contractKind!:#ContractKind, contractId!:s, fields!:[s], expectedVolume:i, requestedDays!:i, justification!:s, requestKind:#AccessRequestKind, renewsGrantId:u',
    'AccessDecisionInput': 'decision!:#AccessDecision, comment:s, periodDays:i, conditions:[#GrantConditionInput]',
    'GrantConditionInput': 'conditionType!:#ConditionType, params!:o',
    'InfoRequestInput': 'questions!:[s]',
    'GrantRenewInput': 'days!:i, comment:s',
    'GrantAmendInput': 'fields:[s], conditions:[#GrantConditionInput], reason!:s20',
    'BundlePublishInput': 'reason!:s20',
    'EscalateInput': 'severity!:#BreachSeverity, description!:s',
    'ActivationCheckInput': 'contractKind!:#ContractKind, contractId!:s',
    'MaskPatternsInput': 'patterns!:[o]',
    'MaskPolicyInput': 'code!:code, scope!:#MaskPolicyScope, contractKind:#ContractKind, contractId:s, description:s, rules!:[#MaskRule]',
    'MaskPolicyVersionInput': 'rules!:[#MaskRule], description:s',
    'MaskSimulationInput': 'policyId!:u, policyVersion!:i, sample!:[o]',
    'RevealRequestInput': 'elementId!:u, recordRef!:s, reason!:s20',
    'LogMaskConfigInput': 'maskedPatterns!:[#DetectorType], scanWindowHours!:i, enabled:b',
    'LeakScanInput': 'sources:[s], windowHours:i',
    'PseudonymDomainInput': 'domainCode!:code, purposeCode!:code, method!:#PseudonymMethod, rotateDays:i, description:s',
    'PseudonymDomainPatch': 'description:s, rotateDays:i',
    'KeyRotateInput': 'reason!:s20, confirmInconsistency!:b',
    'KeyDestroyInput': 'reason!:s20, confirmation!:e(DESTROY)',
    'ReidRequestInput': 'domainCode!:code, tokens!:[s], purposeCode!:code, basis!:s, reason!:s20',
    'ReidApproveInput': 'level!:e(1|2), comment:s',
    'ReidExecuteInput': 'mfaAssertion!:s',
    'AnonymizationConfigInput': 'configCode!:code, privacyModel!:#PrivacyModel, k!:i, l:i, rules!:[#AnonRule], hierarchies:o, purposeCode!:code',
    'AnonymizationJobInput': 'configId!:u, sourceRef!:s, target!:#DataPrepTarget',
    'RiskAssessmentInput': 'sourceRef!:s, riskModel!:#RiskModel, quasiIdentifiers!:[s]',
    'DataPreparationInput': 'target!:#DataPrepTarget, sourceRef!:s, purposeCode!:code, configId:u',
    'DatasetPublishInput': 'usageTerms!:s, expiresAt:ts',
    'DatasetTermsInput': 'usageTerms!:s, expiresAt:ts',
    'RetentionScheduleInput': 'code!:code, lines!:[#RetentionLine]',
    'RetentionRunInput': 'scope:o, dryRun!:b',
    'LegalHoldInput': 'scope!:o, basisDoc!:s, basisDate!:d, authority!:s, reviewOn:d',
    'ShredRequestInput': 'exportConfirmed!:b, reason!:s20',
    'SubjectRequestInput': 'requestType!:#DsrType, channel!:#DsrChannel, identifierType!:#SubjectIdentifierType, identifier!:s, content:s, externalRef:s',
    'SubjectVerifyInput': 'method!:#VerificationMethod, result!:e(VERIFIED|FAILED), evidenceRef:s, note:s',
    'SubjectSearchInput': 'targets!:[#DsrTarget]',
    'SubjectTaskInput': 'target!:#DsrTarget, note:s',
    'TaskCompleteInput': 'status!:e(DONE|REFUSED), externalRef:s, refusalReason:s',
    'AssignInput': 'assignee!:s',
    'SubjectRespondInput': 'outcome!:#DsrOutcome, responseRef!:s, refusalBasis:s',
    'SubjectRejectInput': 'refusalBasis!:s, reason!:s20',
    'AccessReportInput': 'from!:ts, to!:ts',
    'ConsentTemplateInput': 'templateCode!:code, purposeCode!:code, title!:s, text!:s, dataProcessed!:[code], withdrawalGuide!:s, validityDays:i',
    'ConsentTemplateVersionInput': 'title:s, text!:s, dataProcessed:[code], withdrawalGuide:s, validityDays:i',
    'ConsentInput': 'templateCode!:code, templateVersion!:i, subjectIdentifierType!:#SubjectIdentifierType, subjectIdentifier!:s, channel!:#ConsentChannel, evidence!:o',
    'ConsentWithdrawInput': 'channel!:#ConsentChannel, evidence!:o',
    'DpiaRecordInput': 'dpiaCode!:code, activityId:u, dpiaKind!:#DpiaKind, description!:s, risks!:[o], measures!:[o], reviewOn:d',
    'DpiaSubmittedInput': 'a05Ref!:s, submittedAt!:ts',
    'BreachInput': 'detectedAt!:ts, source!:#BreachSource, description!:s, dataTypes:[code], estimatedSubjects:i, incidentRef:s',
    'BreachPatch': 'description:s, dataTypes:[code], estimatedSubjects:i',
    'BreachAssessInput': 'isBreach!:b, severity:#BreachSeverity, impact:s, estimatedSubjects:i, notBreachReason:s',
    'BreachNotificationInput': 'recipient!:#NotificationRecipient, draftRef:s, exemptBasis:s',
    'NotificationSentInput': 'sentAt!:ts, evidenceRef!:s',
    'AffectedSubjectsInput': 'hashes!:[hash]',
    'BreachActionInput': 'description!:s, owner:s, dueAt:ts',
    'LessonInput': 'lessons!:s',
    'BreachCloseInput': 'comment:s',
    'ComplianceReportInput': 'period!:s, format!:#ReportFormat',
    'ReportScheduleInput': 'cron!:s, format!:#ReportFormat, enabled!:b, recipients:[s]',
    'AnomalyRulesInput': 'quotaWarnPercent!:i, bulkThreshold!:i, offHours:s, dormantDays!:i, autoSuspend!:b',
    'SettingsUpdate': 'changes!:[#SettingChangeInput]',
    'SettingChangeInput': 'key!:s, value!:o, reason:s',
}

# --- data plane
DATA_PLANE = {
    'PurposeDecideRequest': 'htttId!:s, purposeCode!:code, contractKind!:#ContractKind, contractId!:s, fields:[s], subjectHash:hash, channel:#MaskChannel',
    'PurposeDecideResponse': 'allow!:b, reason!:e(GRANTED|NO_GRANT|BLOCK_LABEL|RESTRICTED_SUBJECT|SENSITIVE_NO_PURPOSE), grantId:u, ropaActivityId:u, allowedFields:[s], '
                             'conditions:[#GrantCondition], bundleNo!:i, ttlSeconds!:i',
    'MaskPlanRequest': 'contractKind!:#ContractKind, contractId!:s, purposeCode!:code, channel!:#MaskChannel, roles:[s], fields:[s]',
    'MaskPlanResponse': 'planId!:s, bundleNo!:i, failMode!:#FailMode, rules!:[#MaskPlanRule], ttlSeconds!:i',
    'MaskPlanRule': 'field!:s, dataClass!:#DataClass, maskType!:#MaskType, patternKind:#MaskPatternKind, params:o',
    'MessageApplyRequest': 'contractKind!:#ContractKind, contractId!:s, purposeCode!:code, channel!:#MaskChannel, roles:[s], message!:o',
    'MessageApplyResponse': 'message!:o, appliedFields!:[s], droppedFields!:[s], pseudonymized!:i, bundleNo!:i',
    'PseudonymIssueRequest': 'domainCode!:code, identifierKind!:#IdentifierKind, values!:[s]',
    'PseudonymIssueResponse': 'domainCode!:code, keyVersion!:i, method!:#PseudonymMethod, items!:[#PseudonymItem]',
    'PseudonymItem': 'index!:i, pseudonym!:s',
    'ClassificationCheckRequest': 'contractKind!:#ContractKind, contractId!:s, fields!:[s], egressScope:#EgressScope',
    'ClassificationCheckResponse': 'blocked!:b, blockLabel:#BlockLabel, effectiveClass!:#DataClass, egressBlocked!:b, egressBlockedFields:[s], fields!:[#FieldClass]',
    'FieldClass': 'field!:s, dataClass!:#DataClass, personalDataType!:#PersonalDataType, categoryCode:code, noEgress!:b, status!:#ClassificationStatus',
    'ClassificationIndex': 'bundleNo!:i, generatedAt!:ts, entries!:[#ClassificationIndexEntry]',
    'ClassificationIndexEntry': 'target!:s, dataClass!:#DataClass, personalDataType!:#PersonalDataType, categoryCode:code, neverReveal!:b, noEgress!:b, blocked!:b',
    'ConsentCheckRequest': 'templateCode!:code, subjectHash!:hash',
    'ConsentCheckResponse': 'status!:e(GIVEN|WITHDRAWN|EXPIRED|NONE), templateVersion:i, givenAt:ts, restrictionActive!:b, cacheSeconds!:i',
    'SubjectHashRequest': 'identifierType!:#SubjectIdentifierType, identifiers!:[s]',
    'SubjectHashResponse': 'keyRef!:s, items!:[#SubjectHashItem]',
    'SubjectHashItem': 'index!:i, subjectHash!:hash',
    'RevealVerifyRequest': 'token!:s, elementId!:u',
    'RevealVerifyResponse': 'valid!:b, grantId:u, status!:#RevealStatus, remainingSeconds!:i',
    'UsageEventsRequest': 'point!:s, events!:[#UsageEvent]',
    'UsageEvent': 'bucket!:ts, htttId!:s, purposeCode!:code, contractKind!:#ContractKind, contractId!:s, allowed!:i, denied!:i, offPurpose:i',
    'UsageEventsResponse': 'accepted!:i, rejected!:i',
    'RevealGrantIssued': 'grantId!:u, token!:s, status!:#RevealStatus, issuedAt!:ts, expiresAt!:ts, serverTime!:ts, remainingThisHour!:i, value!:s',
}

# schema thân yêu cầu không đi qua READ/INPUT: tên -> lớp phân loại DLCN của thân/phản hồi
CLASSIFIED = {
    'SubjectRequestInput': 'SENSITIVE', 'RevealGrantIssued': 'SENSITIVE', 'ConsentInput': 'RESTRICTED', 'SubjectRequest': 'RESTRICTED',
    'ConsentRecord': 'RESTRICTED', 'ReidRequestInput': 'RESTRICTED', 'ReidExecuteResult': 'SENSITIVE', 'BreachCase': 'RESTRICTED',
    'SubjectHashRequest': 'SENSITIVE', 'ConsentSearchInput': 'SENSITIVE', 'PseudonymIssueRequest': 'SENSITIVE', 'PseudonymIssueResponse': 'RESTRICTED',
    'MessageApplyRequest': 'SENSITIVE', 'MessageApplyResponse': 'RESTRICTED', 'AuditEvent': 'RESTRICTED',
}

TYPES = {'s': {'type': 'string'}, 'i': {'type': 'integer'}, 'n': {'type': 'number'}, 'b': {'type': 'boolean'},
         'ts': {'type': 'string', 'format': 'date-time'}, 'd': {'type': 'string', 'format': 'date'},
         'u': {'type': 'string', 'format': 'uuid'}, 'o': {'type': 'object', 'additionalProperties': True},
         'code': {'$ref': '#/components/schemas/Code'}, 'hash': {'$ref': '#/components/schemas/SubjectHash'}}


def split_top(spec):
    out, depth, cur = [], 0, ''
    for ch in spec:
        if ch in '([':
            depth += 1
        elif ch in ')]':
            depth -= 1
        if ch == ',' and depth == 0:
            out.append(cur.strip())
            cur = ''
        else:
            cur += ch
    if cur.strip():
        out.append(cur.strip())
    return out


def ty(t):
    if t.startswith('['):
        return {'type': 'array', 'items': ty(t[1:-1])}
    if t.startswith('#'):
        return {'$ref': '#/components/schemas/' + t[1:]}
    if t.startswith('e('):
        vals = t[2:-1].split('|')
        return {'type': 'integer' if all(v.isdigit() for v in vals) else 'string', 'enum': [int(v) if v.isdigit() else v for v in vals]}
    m = re.fullmatch(r's(\d+)', t)
    if m:
        return {'type': 'string', 'minLength': int(m.group(1))}
    return dict(TYPES[t])


def obj(spec, extra=None, cls=None):
    props, req = {}, []
    for tok in split_top(spec):
        name, t = tok.split(':', 1)
        if name.endswith('!'):
            name = name[:-1]
            req.append(name)
        props[name] = ty(t)
    if extra:
        merged = {}
        for tok in split_top(extra):
            n2, t2 = tok.split(':', 1)
            if n2.endswith('!'):
                n2 = n2[:-1]
                req.insert(0, n2)
            merged[n2] = ty(t2)
        props = {**merged, **props}
    s = {'type': 'object', 'properties': props}
    if req:
        s['required'] = list(dict.fromkeys(req))
    return s


def build_schemas(enums):
    """enums: tên -> danh sách giá trị (đọc từ Phụ lục A)."""
    S = {}
    for name, vals in enums.items():
        S[name] = {'type': 'string', 'enum': vals}
    S['Code'] = {'type': 'string', 'pattern': '^[A-Z][A-Z0-9_-]{1,47}$', 'description': 'Mã nghiệp vụ chữ hoa, số, `_`, `-`.'}
    S['SubjectHash'] = {'type': 'string', 'contentEncoding': 'base64', 'minLength': 43, 'maxLength': 44,
                        'description': 'HMAC-SHA256 32 byte (base64) của định danh đã chuẩn hóa, khóa riêng tenant; không đảo ngược được (BR-09-045).'}
    for n, sp in READ.items():
        S[n] = obj(sp, CTX)
        if n in CLASSIFIED:
            S[n]['x-dh-classification'] = CLASSIFIED[n]
    for grp in (PLAIN, INPUT, DATA_PLANE):
        for n, sp in grp.items():
            if sp is None:
                continue
            S[n] = obj(sp)
            if n in CLASSIFIED:
                S[n]['x-dh-classification'] = CLASSIFIED[n]
    # Patch: bỏ required
    for n in list(S):
        if n.endswith('Patch') and 'required' in S[n]:
            del S[n]['required']
    S['ReportFormat'] = S.get('ReportFormat', {'type': 'string', 'enum': ['PDF', 'XLSX', 'DOCX']})
    return S
