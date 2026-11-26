"""Nguồn chuẩn danh mục operation PH-13 (API-13-nnn), nguồn: D02-03-PH13 §9.4.

Mỗi dòng: (mã, phương thức, đường dẫn tính từ tiền tố nhóm, mục đích, FR, quyền, idem, mã thành công, nhóm, operationId,
           lược đồ thân yêu cầu, lược đồ phản hồi, mã lỗi riêng của thao tác, tham số query thêm, ghi chú).
Quyền: tên PERM (dashboard, logs, ...) | "a|b" (một trong) | "svc:{scope}" | "mtls".
Sinh OpenAPI (gen_openapi.py), bảng Markdown (gen_md.py) từ đây; không sửa tay tệp sinh ra.
"""

BASES = {"obs": "/api/observability/v1", "aud": "/api/audit/v1", "plat": "/api/platform/v1"}

# nhóm → (tiền tố, tên tag)
GROUPS = {
    "dash": ("obs", "Bảng điều khiển"),
    "logs": ("obs", "Log, trace, nhật ký truy cập API"),
    "alert": ("obs", "Cảnh báo"),
    "rule": ("obs", "Luật cảnh báo và runbook"),
    "oncall": ("obs", "Lịch trực và kênh thông báo"),
    "sec": ("obs", "An ninh, SIEM và báo cáo sự cố"),
    "svc": ("obs", "Dịch vụ cho phân hệ khác"),
    "set": ("obs", "Tham số quan sát"),
    "plat": ("plat", "Vòng đời tenant"),
    "aud": ("aud", "Tra cứu nhật ký kiểm toán"),
    "ver": ("aud", "Toàn vẹn, neo và đối chiếu"),
    "exp": ("aud", "Xuất bằng chứng"),
    "int": ("obs", "Nội bộ (Alertmanager)"),
    "intaud": ("aud", "Nội bộ (DU nguồn)"),
}

# Tham số query dùng chung theo tên (định nghĩa ở gen_openapi.QP)
RNG = ["from", "to"]
PG = ["page", "size"]

OPS = [
    # ---- Bảng điều khiển
    ("001", "GET", "/overview", "Tổng quan nền tảng của tenant", "031", "dashboard", "", "200", "dash", "getOverview", None, "Overview", "", RNG + ["step"], "Sáu thẻ chỉ số, 5 cảnh báo mới, biểu đồ lượt gọi và độ trễ so vạch SLO."),
    ("002", "GET", "/components", "Sức khỏe các thành phần nền tảng", "031, 058", "dashboard", "", "200", "dash", "listComponents", None, "ComponentList", "014", ["layer", "status"], "Cũng nhận token dịch vụ scope `obs:health-read` cho phân hệ khác (FR-13-058)."),
    ("003", "GET", "/deployments", "Danh sách đơn vị triển khai và tài nguyên", "032", "dashboard", "", "200", "dash", "listDeployments", None, "DeploymentPage", "014", PG + ["q", "sort"], ""),
    ("004", "GET", "/deployments/{deploymentCode}", "Chi tiết đơn vị triển khai", "032", "dashboard", "", "200", "dash", "getDeployment", None, "PanelSet", "014", RNG + ["step"], ""),
    ("005", "GET", "/flows", "Bảng điều khiển các luồng", "033", "dashboard", "", "200", "dash", "listFlowDashboards", None, "FlowPage", "014", PG + RNG + ["q", "sort", "status"], ""),
    ("006", "GET", "/flows/{flowCode}/metrics", "Chỉ số một luồng", "033", "dashboard", "", "200", "dash", "getFlowMetrics", None, "PanelSet", "014", RNG + ["step"], ""),
    ("007", "GET", "/flows/{flowCode}/routes/{routeId}/metrics", "Chỉ số một route của luồng", "033", "dashboard", "", "200", "dash", "getRouteMetrics", None, "PanelSet", "014", RNG + ["step"], ""),
    ("008", "GET", "/endpoints/stats", "Thống kê theo endpoint", "034", "dashboard", "", "200", "dash", "getEndpointStats", None, "StatTable", "014", PG + RNG + ["api", "system", "sort"], "Giới hạn 31 ngày mỗi lần (ERR-13-005)."),
    ("009", "GET", "/apis/stats", "Thống kê theo API", "035", "dashboard", "", "200", "dash", "getApiStats", None, "StatTable", "014", PG + RNG + ["api", "sort"], "Chủ dịch vụ (SV) chỉ thấy API thuộc tổ chức mình."),
    ("010", "GET", "/systems/{systemCode}/stats", "Thống kê theo HTTT", "035", "dashboard", "", "200", "dash", "getSystemStats", None, "PanelSet", "014", RNG + ["step"], "Chủ dịch vụ (SV) chỉ thấy HTTT thuộc tổ chức mình."),
    ("011", "GET", "/gateways", "Danh sách nút gateway", "036", "dashboard", "", "200", "dash", "listGateways", None, "GatewayPage", "014", PG + ["status"], ""),
    ("012", "GET", "/gateways/{nodeId}", "Chi tiết nút gateway", "036", "dashboard", "", "200", "dash", "getGateway", None, "Gateway", "014", [], ""),
    ("013", "GET", "/gateways/{nodeId}/resources", "Tài nguyên của nút gateway", "037", "dashboard", "", "200", "dash", "getGatewayResources", None, "PanelSet", "014", RNG + ["step"], ""),
    ("014", "GET", "/kafka/cluster", "Bảng điều khiển cụm Kafka", "038", "dashboard", "", "200", "dash", "getKafkaCluster", None, "PanelSet", "014", RNG + ["step"], "Số liệu cụm từ Strimzi và PH-10; tenant chỉ thấy chủ đề `{tenant}.*`."),
    ("015", "GET", "/dashboards/business", "Bảng điều khiển hoạt động nghiệp vụ", "039", "dashboard", "", "200", "dash", "getBusinessDashboard", None, "PanelSet", "014", RNG + ["step"], ""),
    ("016", "GET", "/dashboards/security", "Bảng điều khiển an ninh", "040", "dashboard", "", "200", "dash", "getSecurityDashboard", None, "PanelSet", "014", RNG + ["step"], "Chỉ số an ninh tổng hợp; chi tiết cảnh báo ở API-13-056."),
    ("017", "GET", "/dashboard-sets", "Danh sách bộ dashboard chuẩn và trạng thái đồng bộ", "041", "admin", "", "200", "dash", "listDashboardSets", None, "DashboardSetList", "014", [], ""),
    ("018", "POST", "/dashboard-sets/{setCode}:sync", "Đồng bộ bộ dashboard sang Grafana của tenant", "041", "admin", "", "202", "dash", "syncDashboardSet", "DashboardSyncRequest", "DashboardSetSync", "014, 035", [], "Chạy nền; kết quả đọc lại bằng API-13-017."),
    # ---- Log, trace, nhật ký truy cập
    ("019", "POST", "/logs:search", "Tra log tập trung", "026", "logs", "", "200", "logs", "searchLogs", "LogSearchRequest", "LogSearchResult", "004, 005, 006, 011, 014, 015", ["cursor", "size"], "Giới hạn khoảng thời gian và số truy vấn đồng thời theo `13.query.*`."),
    ("020", "GET", "/logs/{logId}/context", "Ngữ cảnh quanh một dòng log", "027", "logs", "", "200", "logs", "getLogContext", None, "LogContext", "004, 006, 011, 014, 015", ["before", "after"], "Trả các dòng trước và sau cùng nguồn, cùng `trace_id` nếu có."),
    ("021", "GET", "/logs:tail", "Theo dõi log trực tiếp (SSE)", "027", "logs", "", "200", "logs", "tailLogs", None, "LogTailEvent", "006, 011, 014", ["query", "du", "service", "level"], "Luồng `text/event-stream`; tự tắt sau `13.live-tail.idle-minutes` không hoạt động."),
    ("022", "GET", "/traces", "Tìm trace theo điều kiện", "028", "logs", "", "200", "logs", "searchTraces", None, "TracePage", "004, 005, 006, 011, 014, 015", PG + RNG + ["service", "minDurationMs", "status", "flow", "system"], ""),
    ("023", "GET", "/traces/{traceId}", "Chi tiết trace và biểu đồ thác nước", "028", "logs", "", "200", "logs", "getTrace", None, "Trace", "030, 011, 014, 015", [], "Trace chỉ giữ 14 ngày (ERR-13-030)."),
    ("024", "GET", "/correlations/{traceId}", "Liên kết chỉ số, trace, log, kiểm toán theo trace_id", "029", "logs", "", "200", "logs", "getCorrelation", None, "Correlation", "030, 014", [], "Số bản ghi kiểm toán chỉ hiện khi người gọi có `PERM-13-audit-read`."),
    ("025", "POST", "/access-logs:search", "Tra nhật ký truy cập API", "030", "logs", "", "200", "logs", "searchAccessLogs", "AccessLogSearchRequest", "AccessLogPage", "004, 005, 006, 011, 014, 015", ["cursor", "size"], "Siêu dữ liệu lượt gọi từ ClickHouse; không có thân, không có chuỗi truy vấn."),
    ("026", "GET", "/access-logs/{recordId}", "Chi tiết một lượt gọi API", "030", "logs", "", "200", "logs", "getAccessLog", None, "AccessRecord", "014", [], ""),
    ("027", "GET", "/saved-queries", "Truy vấn đã lưu của tôi và được chia sẻ", "026", "logs", "", "200", "logs", "listSavedQueries", None, "SavedQueryList", "", ["kind"], ""),
    ("028", "POST", "/saved-queries", "Lưu một truy vấn", "026", "logs", "x", "201", "logs", "createSavedQuery", "SavedQueryCreate", "SavedQuery", "002, 006", [], ""),
    ("029", "DELETE", "/saved-queries/{queryId}", "Xóa truy vấn đã lưu", "026", "logs", "", "204", "logs", "deleteSavedQuery", None, None, "", [], "Chỉ chủ sở hữu xóa được; không dùng `If-Match` vì xóa cứng."),
    # ---- Cảnh báo
    ("030", "GET", "/alerts", "Danh sách cảnh báo", "045, 046, 047", "dashboard", "", "200", "alert", "listAlerts", None, "AlertPage", "", PG + RNG + ["status", "severity", "ruleCode", "groupKey", "q", "sort"], "Danh sách đã gom nhóm theo `groupKey` khi `groupBy=group`."),
    ("031", "GET", "/alerts/{alertId}", "Chi tiết cảnh báo", "047", "dashboard", "", "200", "alert", "getAlert", None, "AlertDetail", "", [], "Kèm lịch sử xử lý, lượt gửi thông báo, runbook của luật."),
    ("032", "POST", "/alerts/{alertId}:acknowledge", "Xác nhận cảnh báo", "047", "alert-ack", "", "200", "alert", "acknowledgeAlert", "AckRequest", "Alert", "020", [], "Dừng leo thang."),
    ("033", "POST", "/alerts/{alertId}:resolve", "Đánh dấu đã xử lý", "047", "alert-ack", "", "200", "alert", "resolveAlert", "ResolveRequest", "Alert", "020, 022", [], "Bắt buộc ghi nguyên nhân và hành động."),
    ("034", "POST", "/alerts/{alertId}:silence", "Tạm ẩn cảnh báo", "047", "alert-ack", "", "200", "alert", "silenceAlert", "SilenceRequest", "Alert", "020, 021", [], "Tối đa `13.alert.silence-max-days`; mức Nghiêm trọng tối đa 24 giờ."),
    # ---- Luật cảnh báo, runbook
    ("035", "GET", "/alert-rules", "Danh sách luật cảnh báo", "042, 043", "alert-admin|alert-ack", "", "200", "rule", "listAlertRules", None, "AlertRulePage", "", PG + ["scope", "status", "severity", "q"], "`scope=PLATFORM` là luật chuẩn của nền tảng."),
    ("036", "POST", "/alert-rules", "Tạo luật cảnh báo kèm runbook", "042", "alert-admin", "x", "201", "rule", "createAlertRule", "AlertRuleCreate", "AlertRule", "002, 017, 018", [], "Luật phải có runbook đủ năm mục (BR-13-008)."),
    ("037", "GET", "/alert-rules/{ruleCode}", "Chi tiết luật cảnh báo", "042, 043", "alert-admin|alert-ack", "", "200", "rule", "getAlertRule", None, "AlertRule", "", [], ""),
    ("038", "PATCH", "/alert-rules/{ruleCode}", "Sửa luật cảnh báo", "042", "alert-admin", "", "200", "rule", "updateAlertRule", "AlertRulePatch", "AlertRule", "017, 018, 019", [], "Luật chuẩn của nền tảng không sửa được (ERR-13-019)."),
    ("039", "POST", "/alert-rules/{ruleCode}:test", "Chạy thử luật trên dữ liệu 24 giờ gần nhất", "042", "alert-admin", "", "200", "rule", "testAlertRule", "AlertRuleTestRequest", "AlertRuleTestResult", "006, 018, 014, 015", [], "Không tạo cảnh báo thật."),
    ("040", "POST", "/alert-rules/{ruleCode}:disable", "Tắt luật cảnh báo", "042", "alert-admin", "", "200", "rule", "disableAlertRule", "StateChangeRequest", "AlertRule", "019, 008", [], "Cảnh báo đang mở của luật được đóng tự động."),
    ("041", "POST", "/alert-rules/{ruleCode}:enable", "Bật lại luật cảnh báo", "042", "alert-admin", "", "200", "rule", "enableAlertRule", None, "AlertRule", "019", [], ""),
    ("042", "GET", "/runbooks", "Danh sách runbook", "042", "alert-admin|alert-ack", "", "200", "rule", "listRunbooks", None, "RunbookPage", "", PG + ["q"], ""),
    ("043", "POST", "/runbooks", "Tạo runbook", "042", "alert-admin", "x", "201", "rule", "createRunbook", "RunbookCreate", "Runbook", "002, 017", [], "Đủ năm mục: ý nghĩa, kiểm tra đầu tiên, nguyên nhân thường gặp, cách xử lý, khi nào báo cấp trên."),
    ("044", "PATCH", "/runbooks/{runbookCode}", "Sửa runbook", "042", "alert-admin", "", "200", "rule", "updateRunbook", "RunbookPatch", "Runbook", "017", [], ""),
    # ---- Lịch trực, kênh
    ("045", "GET", "/oncall-schedules", "Danh sách lịch trực", "048", "alert-admin|alert-ack", "", "200", "oncall", "listOncallSchedules", None, "OncallSchedulePage", "", PG, ""),
    ("046", "POST", "/oncall-schedules", "Tạo lịch trực", "048", "alert-admin", "x", "201", "oncall", "createOncallSchedule", "OncallScheduleCreate", "OncallSchedule", "002, 034", [], "Kiểm hở khoảng, chồng ca, hai kênh độc lập cho nhóm Nghiêm trọng."),
    ("047", "PATCH", "/oncall-schedules/{scheduleCode}", "Sửa lịch trực", "048", "alert-admin", "", "200", "oncall", "updateOncallSchedule", "OncallSchedulePatch", "OncallSchedule", "034", [], ""),
    ("048", "GET", "/notification-channels", "Danh sách kênh thông báo", "048", "alert-admin|alert-ack", "", "200", "oncall", "listNotificationChannels", None, "NotificationChannelPage", "", PG + ["kind"], "Không trả bí mật của kênh; chỉ tham chiếu OpenBao."),
    ("049", "POST", "/notification-channels", "Tạo kênh thông báo", "048", "alert-admin", "x", "201", "oncall", "createNotificationChannel", "NotificationChannelCreate", "NotificationChannel", "002, 033", [], "Bí mật webhook ghi một chiều (`writeOnly`), lưu ở OpenBao."),
    ("050", "PATCH", "/notification-channels/{channelCode}", "Sửa kênh thông báo", "048", "alert-admin", "", "200", "oncall", "updateNotificationChannel", "NotificationChannelPatch", "NotificationChannel", "033", [], ""),
    ("051", "POST", "/notification-channels/{channelCode}:test", "Gửi thử qua kênh thông báo", "048", "alert-admin", "", "200", "oncall", "testNotificationChannel", None, "ChannelTestResult", "033", [], "Gửi một thông báo thử; kết quả thật, không giả lập."),
    ("052", "GET", "/alert-stats", "Thống kê hiệu quả cảnh báo", "050", "dashboard", "", "200", "alert", "getAlertStats", None, "AlertStats", "", RNG, "Tỷ lệ cảnh báo giả, MTTA, MTTR theo luật và mức."),
    ("053", "GET", "/monitoring-health", "Sức khỏe của chính hệ thống giám sát", "049", "dashboard", "", "200", "alert", "getMonitoringHealth", None, "MonitoringHealth", "014", [], "Gồm Watchdog, nhịp tim ngoài site, độ trễ thu thập."),
    # ---- An ninh
    ("054", "GET", "/detection-rules", "Danh sách luật phát hiện UC-SEC", "051", "security", "", "200", "sec", "listDetectionRules", None, "DetectionRulePage", "", PG + ["enabled"], ""),
    ("055", "PATCH", "/detection-rules/{ruleCode}", "Tinh chỉnh ngưỡng luật phát hiện", "051", "security", "", "200", "sec", "updateDetectionRule", "DetectionRulePatch", "DetectionRule", "008, 024, 028", [], "Cần lý do và xác thực lại phiên (step-up)."),
    ("056", "GET", "/security-alerts", "Danh sách cảnh báo an ninh", "052, 053", "security", "", "200", "sec", "listSecurityAlerts", None, "SecurityAlertPage", "", PG + RNG + ["status", "severity", "ruleCode"], ""),
    ("057", "GET", "/security-alerts/{alertId}", "Chi tiết cảnh báo an ninh", "053", "security", "", "200", "sec", "getSecurityAlert", None, "SecurityAlert", "", [], "Bằng chứng đã che giá trị Nhạy cảm."),
    ("058", "POST", "/security-alerts/{alertId}:acknowledge", "Tiếp nhận cảnh báo an ninh", "053", "security", "", "200", "sec", "acknowledgeSecurityAlert", "AckRequest", "SecurityAlert", "020", [], ""),
    ("059", "POST", "/security-alerts/{alertId}:close", "Đóng cảnh báo an ninh kèm kết luận", "053", "security", "", "200", "sec", "closeSecurityAlert", "SecurityCloseRequest", "SecurityAlert", "020, 023", [], "Ba kết luận: sự cố thật, báo nhầm, chấp nhận rủi ro (BR-13-024)."),
    ("060", "POST", "/security-alerts/{alertId}:propose-suspension", "Đề xuất tạm ngừng HTTT", "053", "security", "", "200", "sec", "proposeSuspension", "ProposeSuspensionRequest", "SecurityAlert", "008, 020, 028", [], "Chỉ đề xuất; quyết định ở PH-01 (EVT-13-04)."),
    ("061", "GET", "/siem-targets", "Danh sách mục tiêu SIEM", "054", "admin", "", "200", "sec", "listSiemTargets", None, "SiemTargetPage", "", PG, ""),
    ("062", "POST", "/siem-targets", "Tạo mục tiêu SIEM", "054", "admin", "x", "201", "sec", "createSiemTarget", "SiemTargetCreate", "SiemTarget", "002, 039", [], "Bí mật hoặc chứng thư client ghi một chiều (`writeOnly`)."),
    ("063", "PATCH", "/siem-targets/{targetCode}", "Sửa mục tiêu SIEM", "054", "admin", "", "200", "sec", "updateSiemTarget", "SiemTargetPatch", "SiemTarget", "039", [], ""),
    ("064", "POST", "/siem-targets/{targetCode}:test", "Gửi thử tới mục tiêu SIEM", "054", "admin", "", "200", "sec", "testSiemTarget", None, "ChannelTestResult", "039", [], ""),
    ("065", "POST", "/incident-reports:generate", "Sinh báo cáo sự cố từ cảnh báo an ninh", "055", "security", "x", "201", "sec", "generateIncidentReport", "IncidentReportRequest", "IncidentReport", "008", [], "Mẫu theo SEC-74; báo cáo vi phạm dữ liệu cá nhân theo NĐ 356/2025."),
    ("066", "GET", "/incident-reports/{reportId}", "Chi tiết báo cáo sự cố", "055", "security", "", "200", "sec", "getIncidentReport", None, "IncidentReport", "", [], "`Accept: application/pdf` để tải bản in."),
    # ---- Dịch vụ cho phân hệ khác
    ("067", "POST", "/metrics:query", "Truy vấn số liệu tổng hợp cho PH-16", "056", "svc:obs:metrics-read", "", "200", "svc", "queryMetrics", "MetricsQueryRequest", "MetricsQueryResult", "004, 005, 006, 011, 014, 015, 044", [], "Chỉ số đã gom, không có dữ liệu thô của người dùng."),
    ("068", "GET", "/metrics/summary", "Tóm tắt số liệu theo kỳ cho PH-16", "056", "svc:obs:metrics-read", "", "200", "svc", "getMetricsSummary", None, "MetricsSummary", "004, 014, 044", RNG, ""),
    ("069", "GET", "/diagnostics/{traceId}", "Ngữ cảnh chẩn đoán theo trace_id cho PH-18", "057", "svc:obs:diagnostics-read", "", "200", "svc", "getDiagnostics", None, "Diagnostics", "030, 014, 044", [], "Log lỗi đã che; không trả thân thông điệp nghiệp vụ."),
    # ---- Tham số
    ("070", "GET", "/settings", "Tham số quan sát 13.* của tenant", "008, 061", "admin", "", "200", "set", "getSettings", None, "Settings", "", [], "Kèm miền, mặc định và phạm vi sửa của từng khóa."),
    ("071", "PATCH", "/settings", "Sửa tham số, hạn mức, kiểm tra tổng hợp", "008, 061", "admin", "", "200", "set", "updateSettings", "SettingsPatch", "Settings", "040, 041", [], "Có hiệu lực trong 60 giây (NFR-13-030); ghi kiểm toán `OBS.SETTINGS.UPDATE`."),
    # ---- Vòng đời tenant (PH-20)
    ("072", "POST", "/tenants/{tenantCode}/observability:provision", "Khởi tạo quan sát và chuỗi kiểm toán cho tenant mới", "059", "svc:obs:tenant-provision", "x", "200", "plat", "provisionTenantObservability", "ProvisionRequest", "ProvisionResult", "042, 014, 044", [], "Lũy đẳng theo `Idempotency-Key` và tenant; sáu bước S1…S6 ghi vào sổ bước."),
    ("073", "POST", "/tenants/{tenantCode}/audit-chain:close", "Đóng chuỗi kiểm toán khi tenant ngừng hoặc sáp nhập", "060", "svc:obs:tenant-provision", "x", "200", "plat", "closeAuditChain", "CloseChainRequest", "CloseChainResult", "043, 014, 044", [], "Neo cuối `FINAL`; không nhận thêm bản ghi (ERR-13-043)."),
    # ---- Kiểm toán
    ("074", "POST", "/records:search", "Tra cứu nhật ký kiểm toán", "020, 023", "audit-read", "", "200", "aud", "searchAuditRecords", "AuditSearchRequest", "AuditRecordPage", "004, 005, 012, 013, 028, 029, 031, 011, 014, 015", ["cursor", "size"], "Mỗi lượt tra ghi `AUDIT.QUERY` (FR-13-019); cần lý do và xác thực lại phiên."),
    ("075", "GET", "/records/{auditId}", "Chi tiết bản ghi kiểm toán và xác minh băm", "021", "audit-read", "", "200", "aud", "getAuditRecord", None, "AuditRecordDetail", "014", [], "Trả kèm kết quả tính lại băm và neo bao phủ bản ghi."),
    ("076", "GET", "/objects/{objectType}/{objectId}/history", "Lịch sử theo đối tượng cho tab Lịch sử", "022", "svc:audit:history-read", "", "200", "aud", "getObjectHistory", None, "ObjectHistoryPage", "044, 014", PG, "DU gọi tự kiểm tra quyền `read` của đối tượng trước khi gọi."),
    ("077", "POST", "/verifications", "Yêu cầu kiểm tra toàn vẹn chuỗi theo yêu cầu", "014", "audit-export", "x", "202", "ver", "createVerification", "VerificationRequest", "Verification", "008, 028, 032", [], "Đọc từ bản sao chỉ-đọc; kết quả bằng EVT-13-07."),
    ("078", "GET", "/verifications", "Danh sách lượt kiểm tra toàn vẹn", "014", "audit-read", "", "200", "ver", "listVerifications", None, "VerificationPage", "", PG + ["status", "scope"], ""),
    ("079", "GET", "/verifications/{verificationId}", "Kết quả một lượt kiểm tra toàn vẹn", "014, 015", "audit-read", "", "200", "ver", "getVerification", None, "Verification", "", [], "Nếu đứt chuỗi, trả vị trí `firstBreakSeq` và mã ERR-13-109 hoặc ERR-13-110."),
    ("080", "GET", "/anchors", "Danh sách neo băm", "012, 021", "audit-read", "", "200", "ver", "listAnchors", None, "AnchorPage", "", PG + RNG, ""),
    ("081", "GET", "/anchors/{anchorId}", "Chi tiết neo băm", "012", "audit-read", "", "200", "ver", "getAnchor", None, "Anchor", "", [], "Kèm chữ ký, phiên bản khóa, đối tượng WORM và xác nhận SIEM."),
    ("082", "POST", "/exports", "Yêu cầu xuất bằng chứng kiểm toán ký số", "024", "audit-export", "x", "202", "exp", "createExport", "ExportRequest", "Export", "004, 008, 012, 013, 025, 028, 029", [], "Chạy nền; không tạo tệp chưa ký (BR-13-014)."),
    ("083", "GET", "/exports/{exportId}", "Trạng thái yêu cầu xuất bằng chứng", "024", "audit-export", "", "200", "exp", "getExport", None, "Export", "", [], ""),
    ("084", "GET", "/exports/{exportId}/download", "Tải gói bằng chứng", "024", "audit-export", "", "200", "exp", "downloadExport", None, None, "026, 027, 028", [], "Liên kết hiệu lực `13.export.link-ttl-minutes`; mỗi lượt tải ghi kiểm toán."),
    ("085", "GET", "/cross-tenant-access", "Báo cáo truy cập liên tenant", "025", "audit-read", "", "200", "aud", "listCrossTenantAccess", None, "CrossTenantAccessPage", "", PG + RNG + ["actorId"], "Quản trị tỉnh thấy mọi phiên vào tenant của mình."),
    ("086", "GET", "/reconciliations", "Kết quả đối chiếu số bản ghi theo DU", "017", "audit-read", "", "200", "ver", "listReconciliations", None, "ReconciliationPage", "", PG + RNG + ["du", "status"], ""),
    ("087", "GET", "/chain-status", "Trạng thái chuỗi kiểm toán của tenant", "011, 013, 016", "audit-read", "", "200", "ver", "getChainStatus", None, "ChainStatus", "", [], "Gồm đầu chuỗi, neo gần nhất, lô WORM chờ sao, số bản ghi đệm."),
    ("088", "GET", "/partitions", "Danh sách phân vùng kiểm toán", "018", "audit-read", "", "200", "ver", "listPartitions", None, "PartitionList", "", [], ""),
    # ---- Nội bộ
    ("089", "POST", "/internal/records:batch", "Ghi lô bản ghi kiểm toán dự phòng", "010, 016", "svc:audit:write", "", "202", "intaud", "ingestAuditBatch", "AuditBatchRequest", "AuditBatchResult", "003, 043, 044", [], "Kênh dự phòng khi Kafka không với tới; danh tính DU lấy từ token, tenant từ token."),
    ("090", "POST", "/internal/alertmanager:webhook", "Nhận cảnh báo từ Alertmanager", "044", "mtls", "", "200", "int", "receiveAlertmanagerWebhook", "AlertmanagerWebhook", None, "003, 014", [], "Webhook v4, lô tối đa 100 cảnh báo; lũy đẳng theo `(tenant, rule_code, fingerprint)`; lỗi cơ sở dữ liệu trả 503 để Alertmanager gửi lại."),
]

# Mã lỗi → HTTP (theo D02-03-PH13 §9.2); 101…126 là lỗi chạy nền, không có HTTP
ERR_HTTP = {
    1: 404, 2: 409, 3: 400, 4: 400, 5: 422, 6: 400, 7: 412, 8: 400, 9: 403, 10: 401, 11: 429, 12: 422, 13: 422, 14: 503, 15: 504,
    16: 423, 17: 422, 18: 422, 19: 403, 20: 409, 21: 422, 22: 422, 23: 422, 24: 422, 25: 409, 26: 503, 27: 410, 28: 403, 29: 422,
    30: 404, 31: 422, 32: 409, 33: 422, 34: 422, 35: 422, 36: 403, 37: 409, 38: 400, 39: 422, 40: 422, 41: 422, 42: 409, 43: 409, 44: 403,
}
