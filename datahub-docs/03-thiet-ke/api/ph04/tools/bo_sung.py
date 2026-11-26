#!/usr/bin/env python3
"""Mô tả bổ sung và ví dụ yêu cầu, phản hồi cho từng operation của PH-04 (D03-04-PH04 bản 0.2).

gen_openapi.py nhập tệp này: DESC điền `description` cho operation chưa có; PATH_EX điền `example`
cho tham số đường dẫn; EX điền ví dụ tham số truy vấn (`q`), thân yêu cầu (`req`), thân phản hồi (`res`)
và tiêu đề `Location` (`loc`). Mọi ví dụ là dữ liệu giả lập của tenant T68 và được check_contracts.py
kiểm khớp lược đồ.
"""
H = "sha256:" + "3f9a1c2e" * 8
H2 = "sha256:" + "8b04d7e1" * 8
U = lambda n: f"0193a2b4-5c6d-7e8f-9a0b-1c2d3e4f5a{n:02d}"
T = lambda h, m=0: f"2026-11-26T{h:02d}:{m:02d}:00+07:00"
BASE = "/api/integration/v1"
F = "tra-cuu-ho-tich"
FP = f"{BASE}/flows/{F}"
YAML = "- route:\n    id: tra-cuu\n    from: {uri: 'platform-http:/ho-tich/tra-cuu', steps: [...]}\n"
ETAG = 'W/"3-3f9a1c2e"'

PATH_EX = {"flowCode": F, "versionNo": 3, "workspaceCode": "ho-tich", "runId": U(41), "caseId": U(44),
           "deploymentId": U(54), "commandId": U(61), "jobId": U(28), "seqNo": 4, "kind": "components",
           "name": "http", "proposalId": U(74), "templateCode": "tpl-rest-proxy"}
HDR_EX = {"If-Match": ETAG, "Idempotency-Key": "6f0b1d8c-2f7e-4b7a-9d0e-4c1f7a5e2b10",
          "If-None-Match": 'W/"camel-quarkus-3.33.2.p17.r4"'}

WS = {"id": U(1), "code": "ho-tich", "name": "Hộ tịch", "ownerOrgCode": "STP-T68", "status": "ACTIVE",
      "flowCount": 12, "myAccess": "MAINTAIN", "allowedActions": ["update", "archive"]}
ENV_PROD = {"environment": "PROD", "versionNo": 2, "syncStatus": "SYNCED", "healthStatus": "HEALTHY"}
FLOW = {"id": U(10), "code": F, "name": "Tra cứu hộ tịch qua NDXP", "workspaceCode": "ho-tich", "resourceKind": "ROUTE",
        "transport": "SYNC", "exposure": "EXTERNAL", "status": "ACTIVE", "sourceSystem": "DVC-T68", "targetSystems": ["NDXP"],
        "environments": [ENV_PROD], "allowedActions": ["update", "clone", "retire"]}
FLOW_D = {**FLOW, "origin": "TEMPLATE", "routes": [{"routeId": "tra-cuu", "stepCount": 9}]}
VER = {"versionNo": 3, "status": "DRAFT", "contentHash": H, "createdBy": "an.nv"}
VER_D = {**VER, "definitionYaml": YAML, "canvasLayout": {}, "samples": {}, "allowedActions": ["saveDraft", "submit"]}
VALID = {"level": "DESIGN", "errorCount": 0, "warnCount": 1,
         "findings": [{"rule": "VR-12", "severity": "WARN", "nodeId": "n7", "message": "Chặng gọi hệ đích chưa đặt thời gian chờ; mặc định 30 giây."}]}
SAVED = {"versionNo": 3, "contentHash": H, "savedAt": T(9, 3), "validation": VALID}
RUN = {"id": U(41), "versionNo": 3, "definitionHash": H, "mode": "MOCK", "status": "PASSED", "durationMs": 412,
       "matchesCurrentHash": True, "allowedActions": ["rerun"]}
STEP = {"seqNo": 4, "nodeId": "n4", "routeId": "tra-cuu", "stage": "transform", "status": "OK", "offsetMs": 96, "durationMs": 12}
CASE = {"name": "Tra cứu thành công", "mode": "MOCK", "body": "{\"soDinhDanh\": \"068000000001\"}",
        "assertions": [{"kind": "STATUS", "expected": 200}, {"kind": "STEP_VISITED", "nodeId": "n7"}], "timeoutSeconds": 30, "active": True}
DEP = {"id": U(54), "versionNo": 3, "environment": "TEST", "kind": "RELEASE", "desiredState": "RUNNING", "syncStatus": "PENDING",
       "requestedBy": "binh.tt", "requestedAt": T(10), "allowedActions": []}
CMD = {"id": U(61), "environment": "PROD", "action": "PAUSE", "scope": "FLOW", "status": "ISSUED", "expectedReplicas": 3,
       "ackedReplicas": 0, "issuedBy": "cuong.lv", "issuedAt": T(21, 55), "expiresAt": "2026-11-26T21:56:00+07:00"}
REASON = "Hệ đích NDXP bảo trì từ 22 giờ đến 23 giờ ngày 26/11."
TPL = {"code": "tpl-rest-proxy", "name": "Chuyển tiếp REST chín chặng", "category": "rest", "resourceKind": "ROUTE",
       "scope": "PLATFORM", "status": "ACTIVE", "catalogVersion": "camel-quarkus-3.33.2"}
PROP = {"id": U(74), "kind": "components", "name": "jt400", "type": "NEW_COMPONENT", "status": "OPEN", "createdBy": "an.nv", "createdAt": T(8)}
POL = {"kind": "components", "name": "exec", "decision": "DENIED", "scope": "PLATFORM", "policyVersion": 7}
ENVVAR = {"name": "ndxp-base-path", "description": "Đường gốc API NDXP theo môi trường.",
          "values": {"TEST": "/sandbox/v1", "STAGING": "/uat/v1", "PROD": "/v1"}, "usedBy": 4}
SSE_RUN = ('event: status\ndata: {"id": "' + U(41) + '", "status": "RUNNING"}\n\n'
           'event: step\ndata: {"seqNo": 4, "nodeId": "n4", "status": "OK", "durationMs": 12}\n\n'
           'event: completed\ndata: {"id": "' + U(41) + '", "status": "PASSED", "durationMs": 412}\n')
SSE_DEP = ('event: status\ndata: {"id": "' + U(54) + '", "syncStatus": "SYNCING"}\n\n'
           'event: replica\ndata: {"replica": "dh-rt-t68-core-7c9d-x2k4p", "contentHash": "' + H[:15] + '…"}\n\n'
           'event: completed\ndata: {"id": "' + U(54) + '", "syncStatus": "SYNCED"}\n')

DESC = {
  "listWorkspaces": "Trả mọi không gian làm việc của tenant mà người gọi thấy được, kèm `myAccess` (mức của người gọi) và `flowCount`. Danh sách nhỏ nên trả trọn, không phân trang.",
  "updateWorkspace": "Đổi tên, mô tả, đơn vị chủ quản. Mã không gian không đổi được. Không gian không tồn tại ERR-04-027.",
  "listWorkspaceMembers": "Trả danh sách người dùng và nhóm cùng mức truy cập VIEW, EDIT, MAINTAIN (FR-04-007).",
  "getFlow": "Trả thông tin luồng, route, trạng thái theo môi trường và `allowedActions`. Luồng của tenant khác hoặc ngoài phạm vi không gian trả ERR-04-001 (404).",
  "cloneFlow": "Tạo luồng mới với phiên bản 1 `DRAFT` sao từ phiên bản nguồn (mặc định mới nhất), kèm ca kiểm thử nếu chọn. Mã trùng ERR-04-002. Phát EVT-04-01 với `origin = CLONE`.",
  "getFlowDependencies": "Liệt kê phụ thuộc cứng (API công bố PH-02, luồng gọi luồng con) và mềm (ca kiểm thử, bản nháp, topic, kết nối). Phụ thuộc cứng chặn gỡ (ERR-04-017).",
  "listVersions": "Trả mọi phiên bản của luồng, mới nhất trước, kèm môi trường đang chạy từng phiên bản. Không phân trang vì số phiên bản có giới hạn tự nhiên.",
  "discardVersion": "Hủy phiên bản đang `DRAFT` hoặc `CHANGES_REQUESTED`; phiên bản chuyển `DISCARDED`, giải phóng chỗ cho phiên bản mở mới (BR-04-016). Trạng thái khác ERR-04-005.",
  "diffVersion": "So sánh theo chặng (`nodes`) và theo dòng YAML (`yamlUnifiedDiff`) với phiên bản gốc. Người duyệt gọi với `markViewed = true` để thỏa điều kiện đã xem khác biệt trước khi duyệt.",
  "downloadVersion": "Tải YAML triển khai (`yaml`), YAML kèm bố cục (`yaml+layout`) hoặc gói ZIP gồm YAML, ánh xạ, ca kiểm thử (`bundle`). Không bao giờ chứa giá trị bí mật.",
  "importYaml": "Thay định nghĩa của bản nháp bằng YAML tải lên; giữ bố cục cho chặng có `id` trùng khi `keepLayout`. Cú pháp lỗi ERR-04-008, bí mật ERR-04-010, vượt 512 KiB ERR-04-033.",
  "getLegacyImport": "Trả trạng thái tác vụ chuyển XML cũ và báo cáo: số route, số chặng chuyển được, chặng cần làm tay, thành phần bị cấm, kết nối cần khai ở PH-05, luồng đã tạo.",
  "endSession": "Rời trình thiết kế: xóa người gọi khỏi danh sách phiên soạn để người khác không còn thấy cảnh báo.",
  "validateVersion": "Chạy kiểm tra hợp lệ ở mức yêu cầu (`DESIGN`, `SUBMIT`, `PUBLISH`) trên phiên bản đã lưu và ghi kết quả vào `lastValidation`. Không đổi trạng thái phiên bản.",
  "listTestRuns": "Lịch sử chạy thử của luồng, lọc theo phiên bản, trạng thái, ca kiểm thử; mỗi lần chạy có `matchesCurrentHash` để biết còn dùng được cho BR-04-004 không.",
  "getTestRun": "Trả kết quả lần chạy: trạng thái, khẳng định, danh sách chặng (thân đã che, xem trước ≤ 64 KiB). Dùng để hỏi lại khi SSE mất kết nối.",
  "cancelTestRun": "Hủy lần chạy đang `QUEUED` hoặc `RUNNING`; sandbox đóng `CamelContext` của lần chạy. Lần chạy đã kết thúc ERR-04-005.",
  "listTestCases": "Danh sách ca kiểm thử của luồng kèm kết quả lần chạy gần nhất và cờ `onCurrentHash`.",
  "createTestCase": "Tạo ca kiểm thử (1…20 khẳng định, thân ≤ 256 KiB). Ca mới làm điều kiện gửi duyệt cần thêm một lần chạy đạt của ca này (BR-04-004).",
  "updateTestCase": "Sửa ca kiểm thử; kết quả cũ của ca không còn tính cho BR-04-004 cho tới khi chạy lại.",
  "deleteTestCase": "Ngừng dùng ca kiểm thử (`active = false`); lịch sử lần chạy theo ca vẫn giữ.",
  "withdrawVersion": "Người gửi rút yêu cầu duyệt khi chưa có quyết định; phiên bản về `DRAFT`. Thiếu lý do ERR-04-025.",
  "listReviewQueue": "Hàng đợi phiên bản `PENDING_REVIEW` mà người gọi được duyệt, kèm số giờ chờ, cờ quá hạn và `canDecide` (sai khi người gọi là người tạo, đóng góp hoặc gửi).",
  "listDeployments": "Lịch sử triển khai của luồng theo môi trường, mới nhất trước; bản ghi `current = true` là triển khai đang có hiệu lực.",
  "getDeployment": "Trả trạng thái đồng bộ, sức khỏe, commit Git và mã lỗi (nếu có) của một lần triển khai. Dùng để hỏi lại khi SSE mất kết nối.",
  "getRuntimeStatus": "Tình trạng runtime theo môi trường: phiên bản đang chạy, bản sao sẵn sàng, trạng thái từng route và số liệu một phút, tính từ nhịp tim EVT-04-12.",
  "getCommand": "Trả trạng thái lệnh và xác nhận theo từng bản sao (`acks`). `PARTIAL` sau 30 giây khi chưa đủ xác nhận; lý do từ chối nằm ở `acks[].reason`.",
  "listEndpoints": "Liệt kê điểm vào, điểm ra của luồng (URI đã che tham số nhạy cảm, kết nối, topic) kèm số liệu một giờ.",
  "getFlowMetrics": "Chuỗi số liệu (số trao đổi, lỗi, p95, DLQ) của luồng ở một môi trường, đọc từ PH-13 và lọc sẵn theo tenant. PH-13 không sẵn sàng ERR-04-047.",
  "listPolicies": "Chính sách thành phần hiệu lực: tầng nền (PLATFORM) và tầng tỉnh (TENANT) kèm `policyVersion`.",
  "getCatalogVersions": "Phiên bản catalog của tenant, các hồ sơ runtime (Quarkus, Camel Quarkus, thư viện nền, ảnh) và đợt nâng cấp đang chờ.",
  "listProposals": "Danh sách đề xuất cho phép hoặc bổ sung thành phần, lọc theo trạng thái.",
  "createProposal": "Người thiết kế đề xuất cho phép thành phần đang bị cấm hoặc bổ sung thành phần mới, kèm lý do ≥ 20 ký tự. Đề xuất mở trùng thành phần ERR-04-005.",
  "decideProposal": "PA quyết định đề xuất (cần ý kiến SO theo FR-04-080); chấp nhận kèm mức chính sách `ALLOWED` hoặc `PER_FLOW`. Đề xuất đã đóng ERR-04-005.",
  "listTemplates": "Khuôn mẫu nền và khuôn của tỉnh đang dùng được, lọc theo loại tài nguyên.",
  "getTemplate": "Chi tiết khuôn: YAML thân, lược đồ tham số (JSON Schema) để dựng biểu mẫu tạo luồng, bố cục xem trước. Khuôn không tồn tại ERR-04-039.",
  "createTemplate": "Tạo khuôn của tỉnh từ phiên bản luồng đã duyệt, kèm lược đồ tham số. Mã khuôn trùng ERR-04-005; phiên bản chưa duyệt ERR-04-005.",
  "deprecateTemplate": "Ngừng dùng khuôn của tỉnh; luồng đã tạo từ khuôn không bị ảnh hưởng. Khuôn nền không ngừng được ở đây (403).",
}

# q: tham số truy vấn; req: thân yêu cầu; res: thân phản hồi; loc: tiêu đề Location
EX = {
  "listWorkspaces": {"res": {"items": [WS]}},
  "createWorkspace": {"req": {"code": "dat-dai", "name": "Đất đai", "ownerOrgCode": "STNMT-T68"},
                      "res": {**WS, "id": U(2), "code": "dat-dai", "name": "Đất đai", "ownerOrgCode": "STNMT-T68", "flowCount": 0}},
  "updateWorkspace": {"req": {"name": "Hộ tịch và chứng thực"}, "res": {**WS, "name": "Hộ tịch và chứng thực"}},
  "archiveWorkspace": {"res": {**WS, "status": "ARCHIVED", "allowedActions": []}},
  "listWorkspaceMembers": {"res": {"members": [{"principalType": "USER", "principalId": "an.nv", "displayName": "Nguyễn Văn An", "accessLevel": "MAINTAIN"},
                                               {"principalType": "GROUP", "principalId": "tt-cntt-t68", "accessLevel": "EDIT"}]}},
  "replaceWorkspaceMembers": {"req": {"members": [{"principalType": "USER", "principalId": "an.nv", "accessLevel": "MAINTAIN"},
                                                  {"principalType": "USER", "principalId": "binh.tt", "accessLevel": "EDIT"}]},
                              "res": {"members": [{"principalType": "USER", "principalId": "an.nv", "accessLevel": "MAINTAIN"},
                                                  {"principalType": "USER", "principalId": "binh.tt", "accessLevel": "EDIT"}]}},
  "listFlows": {"q": {"status": ["ACTIVE"], "environment": "PROD", "limit": 25},
                "res": {"items": [FLOW], "page": {"next": "eyJrIjoyNX0", "hasMore": True}, "facets": {"status": {"ACTIVE": 18}}}},
  "createFlow": {"req": {"code": F, "name": "Tra cứu hộ tịch qua NDXP", "workspaceCode": "ho-tich", "resourceKind": "ROUTE",
                         "origin": "TEMPLATE", "templateCode": "tpl-rest-proxy", "templateParams": {"upstream": "ndxp-ho-tich"},
                         "sourceSystem": "DVC-T68", "targetSystems": ["NDXP"]},
                 "res": {**FLOW_D, "status": "DRAFT", "openVersionNo": 1, "environments": [], "allowedActions": ["update", "retire"]}},
  "getFlow": {"res": FLOW_D},
  "updateFlow": {"req": {"labels": {"linh-vuc": "ho-tich"}}, "res": {**FLOW_D, "labels": {"linh-vuc": "ho-tich"}}},
  "cloneFlow": {"req": {"code": "tra-cuu-ho-tich-v2", "name": "Tra cứu hộ tịch (bản 2)", "sourceVersionNo": 2},
                "res": {**FLOW_D, "id": U(11), "code": "tra-cuu-ho-tich-v2", "name": "Tra cứu hộ tịch (bản 2)", "status": "DRAFT",
                        "origin": "CLONE", "clonedFrom": F, "openVersionNo": 1, "environments": []}},
  "retireFlow": {"req": {"reason": "Thay bằng luồng tra-cuu-ho-tich-v2 theo kế hoạch của Sở Tư pháp."},
                 "res": {**FLOW_D, "allowedActions": [], "disabledReasons": {"update": "Luồng đang được gỡ."}}, "loc": f"{FP}/deployments/{U(55)}"},
  "getFlowDependencies": {"res": {"hard": [{"type": "API", "hard": True, "ref": "api-ho-tich-tra-cuu", "label": "API tra cứu hộ tịch", "environment": "PROD"}],
                                  "soft": [{"type": "TEST_CASE", "hard": False, "ref": U(44), "label": "Tra cứu thành công"}]}},
  "listVersions": {"res": {"items": [VER, {"versionNo": 2, "status": "APPROVED", "contentHash": H2, "approvedBy": "binh.tt", "environments": ["TEST", "STAGING", "PROD"]}]}},
  "createVersion": {"req": {"baseVersionNo": 2}, "res": VER_D},
  "getVersion": {"res": VER_D},
  "saveDraft": {"req": {"definitionYaml": YAML, "canvasLayout": {"n1": {"x": 120, "y": 80}}, "samples": {},
                        "catalogVersion": "camel-quarkus-3.33.2"}, "res": SAVED},
  "discardVersion": {"res": {**VER, "status": "DISCARDED"}},
  "diffVersion": {"q": {"base": 2, "markViewed": True},
                  "res": {"baseVersionNo": 2, "versionNo": 3, "nodes": [{"nodeId": "n5", "change": "ADDED"}, {"nodeId": "n7", "change": "MODIFIED", "fields": ["parameters.timeout"]}],
                          "summary": {"added": 1, "removed": 0, "modified": 1}}},
  "downloadVersion": {"q": {"format": "yaml"}, "res": YAML},
  "importYaml": {"req": {"yaml": YAML, "keepLayout": True}, "res": SAVED},
  "startLegacyImport": {"req": {"file": "(nội dung tệp context-hotich.xml)", "workspaceCode": "ho-tich", "connectionMap": "{\"dsHoTich\": \"pg-ho-tich\"}"},
                        "res": {"id": U(28), "status": "RUNNING", "fileName": "context-hotich.xml"}, "loc": f"{BASE}/legacy-imports/{U(28)}"},
  "getLegacyImport": {"res": {"id": U(28), "status": "COMPLETED", "fileName": "context-hotich.xml",
                              "report": {"routes": 3, "stepsConverted": 41, "stepsManual": 2, "forbiddenComponents": ["exec"], "connectionsToDeclare": ["pg-ho-tich"]},
                              "createdFlows": ["ht-dong-bo-khai-sinh"]}},
  "heartbeatSession": {"res": {"others": [{"userId": "binh.tt", "displayName": "Trần Thị Bình", "since": T(9)}], "catalogVersion": "camel-quarkus-3.33.2",
                               "expiresInSeconds": 120, "freeze": {"active": False}}},
  "endSession": {},
  "validateVersion": {"req": {"level": "SUBMIT", "targetEnvironment": "PROD"},
                      "res": {**VALID, "level": "SUBMIT", "errorCount": 1, "warnCount": 0,
                              "findings": [{"rule": "VR-05", "severity": "ERROR", "nodeId": "n6", "message": "Luồng đối ngoại thiếu chặng chuẩn: audit."}]}},
  "validateYaml": {"req": {"yaml": YAML, "resourceKind": "ROUTE", "exposure": "EXTERNAL"}, "res": VALID},
  "checkExpression": {"req": {"language": "simple", "expression": "${header.dh-tenant} == 'T68'", "predicate": True, "evaluate": True,
                              "sample": {"headers": {"dh-tenant": "T68"}}},
                      "res": {"valid": True, "result": True, "resultType": "java.lang.Boolean", "simulated": False}},
  "previewMapping": {"req": {"mapping": {"name": "ket-qua-tra-cuu", "dhmap": {"format": "dhmap/1", "fields": [{"to": "hoTen", "from": "$.fullName"}]}},
                             "sample": {"body": "{\"fullName\": \"Nguyễn Văn A\"}"}},
                     "res": {"jq": "{hoTen: .fullName}", "output": {"hoTen": "Nguyễn Văn A"}, "targetValid": True, "findings": [], "simulated": False}},
  "startTestRun": {"req": {"mode": "MOCK", "body": "{\"soDinhDanh\": \"068000000001\"}", "timeoutSeconds": 30,
                           "assertions": [{"kind": "STATUS", "expected": 200}]},
                   "res": {**{k: v for k, v in RUN.items() if k != "durationMs"}, "status": "QUEUED", "allowedActions": ["cancel"]}, "loc": f"{FP}/test-runs/{U(41)}"},
  "listTestRuns": {"q": {"versionNo": 3, "limit": 10}, "res": {"items": [RUN], "page": {"next": None, "hasMore": False}}},
  "getTestRun": {"res": {**RUN, "steps": [STEP]}},
  "streamTestRun": {"res": SSE_RUN},
  "getTestRunBody": {"q": {"side": "out"}, "res": {"hoTen": "Nguyễn Văn A", "soDinhDanh": "068******001"}},
  "cancelTestRun": {"res": {**RUN, "status": "CANCELLED", "allowedActions": ["rerun"]}},
  "listTestCases": {"res": {"items": [{**CASE, "id": U(44), "lastResult": {"status": "PASSED", "runId": U(41), "onCurrentHash": True}}]}},
  "createTestCase": {"req": CASE, "res": {**CASE, "id": U(44)}},
  "updateTestCase": {"req": {**CASE, "timeoutSeconds": 20}, "res": {**CASE, "id": U(44), "timeoutSeconds": 20}},
  "deleteTestCase": {},
  "submitVersion": {"req": {"changeNote": "Thêm chặng che số định danh theo yêu cầu ATTT.", "suggestedReviewers": ["binh.tt"]},
                    "res": {**VER_D, "status": "PENDING_REVIEW", "submittedBy": "an.nv", "submittedAt": T(9, 30), "allowedActions": ["withdraw"]}},
  "withdrawVersion": {"req": {"reason": "Cần bổ sung ca kiểm thử lỗi hệ đích."}, "res": {**VER_D, "status": "DRAFT"}},
  "reviewVersion": {"req": {"decision": "APPROVE", "comment": "Đã xem khác biệt, che dữ liệu đúng.",
                            "checklist": {"diff-viewed": True, "pii-purpose": True}, "publishTo": "TEST"},
                    "res": {**VER_D, "status": "APPROVED", "approvedBy": "binh.tt", "approvedAt": T(10), "allowedActions": ["release"]}},
  "listReviewQueue": {"q": {"mine": True},
                      "res": {"items": [{"flowCode": F, "flowName": "Tra cứu hộ tịch qua NDXP", "workspaceCode": "ho-tich", "versionNo": 3, "submittedBy": "an.nv",
                                         "submittedAt": T(9, 30), "waitingHours": 2.5, "overdue": False, "exposure": "EXTERNAL", "canDecide": True}],
                              "page": {"next": None, "hasMore": False}}},
  "listDeployments": {"q": {"environment": "PROD"},
                      "res": {"items": [{**DEP, "id": U(53), "versionNo": 2, "environment": "PROD", "syncStatus": "SYNCED", "healthStatus": "HEALTHY", "current": True}]}},
  "releaseVersion": {"req": {"versionNo": 3, "environment": "TEST", "note": "Phát hành thử nghiệm chặng che dữ liệu."}, "res": DEP, "loc": f"{FP}/deployments/{U(54)}"},
  "getDeployment": {"res": {**DEP, "syncStatus": "SYNCED", "healthStatus": "HEALTHY", "gitCommit": "9c1e4b7", "syncedAt": T(10, 3), "current": True}},
  "streamDeployment": {"res": SSE_DEP},
  "rollbackDeployment": {"req": {"environment": "PROD", "targetVersionNo": 2, "reason": "Phiên bản 3 tăng lỗi 504 khi gọi NDXP."},
                         "res": {**DEP, "id": U(56), "versionNo": 2, "environment": "PROD", "kind": "ROLLBACK"}, "loc": f"{FP}/deployments/{U(56)}"},
  "promoteDeployment": {"req": {"versionNo": 3, "fromEnvironment": "STAGING", "toEnvironment": "PROD"},
                        "res": {**DEP, "id": U(57), "environment": "PROD", "kind": "PROMOTE"}, "loc": f"{FP}/deployments/{U(57)}"},
  "getRuntimeStatus": {"res": {"environments": [{**ENV_PROD, "desiredState": "RUNNING", "readyReplicas": 3, "replicas": 3, "runtimeProfile": "core-native",
                                                 "routes": [{"routeId": "tra-cuu", "state": "Started", "exchanges1m": 42, "failures1m": 0, "p95ms": 180}]}]}},
  "issueCommand": {"req": {"environment": "PROD", "action": "PAUSE", "scope": "FLOW", "reason": REASON, "drain": True},
                   "res": CMD, "loc": f"{FP}/runtime/commands/{U(61)}"},
  "getCommand": {"res": {**CMD, "status": "ACKNOWLEDGED", "ackedReplicas": 3,
                         "acks": [{"replica": "dh-rt-t68-core-7c9d-x2k4p", "result": "APPLIED", "ackedAt": "2026-11-26T21:55:02+07:00"}]}},
  "resendCommand": {"res": {**CMD, "id": U(62)}, "loc": f"{FP}/runtime/commands/{U(62)}"},
  "listEndpoints": {"q": {"environment": "PROD"},
                    "res": {"items": [{"nodeId": "n1", "direction": "IN", "scheme": "platform-http", "httpMethod": "POST", "httpPath": "/ho-tich/tra-cuu",
                                       "metrics": {"exchanges1h": 2480, "failures1h": 3, "p95ms": 190}}]}},
  "getFlowMetrics": {"q": {"environment": "PROD", "from": "2026-11-26T09:00:00+07:00", "to": "2026-11-26T10:00:00+07:00", "step": "30m"},
                     "res": {"environment": "PROD", "step": "30m", "series": [{"name": "exchanges", "points": [[1795744800, 1210], [1795746600, 1270]]}]}},
  "getCatalogIndex": {"res": {"catalogVersion": "camel-quarkus-3.33.2", "runtime": "quarkus", "paletteRulesVersion": 4,
                              "entries": [{"kind": "COMPONENT", "name": "http", "titleVi": "Gọi HTTP", "groups": ["deliver"], "policy": "ALLOWED", "needsConnection": True}]}},
  "getComponentSchema": {"q": {"catalogVersion": "camel-quarkus-3.33.2"},
                         "res": {"entry": {"kind": "COMPONENT", "name": "http", "policy": "ALLOWED"}, "syntax": "http:httpUri",
                                 "properties": [{"name": "connectTimeout", "kind": "parameter", "type": "duration", "required": False, "default": "30s", "secret": False}], "flowsUsing": 14}},
  "listPolicies": {"res": {"items": [POL], "policyVersion": 7}},
  "updatePolicies": {"req": {"changes": [{"kind": "components", "name": "ftp", "decision": "PER_FLOW", "reason": "Chỉ cho luồng nhận tệp từ hệ thống hộ tịch cũ."}]},
                     "res": {"items": [POL, {"kind": "components", "name": "ftp", "decision": "PER_FLOW", "scope": "TENANT", "policyVersion": 8}], "policyVersion": 8}},
  "getCatalogVersions": {"res": {"tenantCatalogVersion": "camel-quarkus-3.33.2", "match": True,
                                 "profiles": [{"profile": "core-native", "quarkusVersion": "3.28.4", "camelQuarkusVersion": "3.33.2", "libVersion": "dh-lib 1.4.0"}]}},
  "listProposals": {"q": {"status": "OPEN"}, "res": {"items": [PROP]}},
  "createProposal": {"req": {"kind": "components", "name": "jt400", "type": "NEW_COMPONENT",
                             "justification": "Hệ thống hộ tịch cũ chạy trên IBM i, cần đọc hàng đợi dữ liệu."}, "res": PROP},
  "decideProposal": {"req": {"decision": "ACCEPTED", "note": "Đồng ý, chỉ cho từng luồng có SO duyệt.", "policyDecision": "PER_FLOW"},
                     "res": {**PROP, "status": "ACCEPTED", "decidedBy": "pa.admin", "decisionNote": "Đồng ý, chỉ cho từng luồng có SO duyệt."}},
  "listTemplates": {"q": {"resourceKind": "ROUTE"}, "res": {"items": [TPL]}},
  "getTemplate": {"res": {**TPL, "bodyYaml": YAML, "paramSchema": {"type": "object", "required": ["upstream"]}}},
  "createTemplate": {"req": {"code": "tpl-t68-tra-cuu", "name": "Tra cứu qua NDXP của tỉnh", "fromFlow": F, "fromVersionNo": 2,
                             "paramSchema": {"type": "object", "required": ["upstream"]}},
                     "res": {**TPL, "code": "tpl-t68-tra-cuu", "name": "Tra cứu qua NDXP của tỉnh", "scope": "TENANT", "bodyYaml": YAML}},
  "deprecateTemplate": {"res": {**TPL, "code": "tpl-t68-tra-cuu", "name": "Tra cứu qua NDXP của tỉnh", "scope": "TENANT", "status": "DEPRECATED"}},
  "getSettings": {"res": {"params": [{"key": "04.test.max-concurrent", "value": 5, "default": 5}],
                          "envVars": [ENVVAR]}},
  "replaceEnvVars": {"req": {"items": [ENVVAR]}, "res": {"items": [ENVVAR]}},
  "getFlowHistory": {"q": {"action": ["INT_VERSION_APPROVE"], "limit": 20},
                     "res": {"items": [{"at": T(10), "action": "INT_VERSION_APPROVE", "actor": "binh.tt", "versionNo": 3, "traceId": "4bf92f3577b34da6a3ce929d0e0e4736"}],
                             "page": {"next": None, "hasMore": False}}},
}
