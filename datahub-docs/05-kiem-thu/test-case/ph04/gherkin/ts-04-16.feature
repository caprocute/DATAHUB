# language: vi
# Sinh tự động từ D05-02-PH04 bằng ph04/tools/gen_gherkin.py; không sửa tay.
@PH-04 @TS-04-16
Tính năng: TS-04-16 · Phát hành GitOps và nâng môi trường

  @TC-04-096 @P1 @Dương
  Kịch bản: TC-04-096 Phát hành lên TEST tới SYNCED
    # Truy vết: FR-04-042 · BR-04-012 · API-04-054 · UI-04-15 · UC-04-12 · EVT-04-06, 07, 12.
    Biết F-HT v4 `APPROVED`; IA1.
    Khi gọi `POST /flows/tra-cuu-ho-tich/deployments` với `{"versionNo":4,"environment":"TEST"}` và `Idempotency-Key`.
    Và mở SSE `.../deployments/{id}/events`.
    Và đọc `env/test` trên Gitea.
    Và gọi luồng qua `apisix-int` môi trường TEST.
    Thì bước 1 trả `202`, `syncStatus = PENDING`. Bước 2: `PENDING` → `SYNCING` (có `gitCommit`) → `SYNCED` khi mọi bản sao gửi nhịp tim EVT-04-12 có `contentHash` của v4; `healthStatus = HEALTHY`. Bước 3: commit có thông điệp chứa `flow=tra-cuu-ho-tich version=4 by=U-T68-IA1 trace=…`, `flow.dh.yaml` có `version: 4`, có chữ ký trong `.dh/signatures`. Bước 4: phản hồi do v4 sinh. EVT-04-06, 07 phát. KT: có (`INT_DEPLOY`).

  @TC-04-097 @P1 @Dương
  Kịch bản: TC-04-097 Nâng TEST → STAGING → PROD theo thứ tự
    # Truy vết: FR-04-045 · BR-04-019 · API-04-056 · UC-04-12 · NFR-04-009.
    Biết v4 `SYNCED`, `HEALTHY` ở TEST; `04.env.soak-minutes.STAGING = 1` (rút ngắn cho kiểm thử); TA có `PERM-04-promote`.
    Khi TA nâng v4 lên STAGING.
    Và sau 1 phút ổn định, TA nâng lên PROD.
    Và kiểm Gitea: `env/prod` nhận merge request, CI của kho cấu hình chạy, merge.
    Thì bước 1, 2 trả `202`. Bước 3: merge request có mô tả phiên bản, người duyệt, liên kết so sánh; sau merge, PROD `SYNCED`. Từ lệnh nâng PROD tới `SYNCED` p95 < 3 phút (NFR-04-009). v3 thành `SUPERSEDED` ở PROD.

  @TC-04-098 @P1 @Âm
  Kịch bản: TC-04-098 Sai thứ tự môi trường, chưa ổn định
    # Truy vết: FR-04-042, 045 · BR-04-019 · ERR-04-023.
    Biết `tc-moi` v1 `APPROVED`, chưa triển khai ở đâu; `04.env.soak-minutes.STAGING = 30`.
    Khi phát hành `tc-moi` v1 thẳng lên PROD.
    Và phát hành lên TEST, chờ `SYNCED`, nâng lên PROD (bỏ qua STAGING).
    Và nâng lên STAGING, ngay lập tức nâng lên PROD.
    Và cho TEST thành `DEGRADED` (đích mô phỏng trả 500), nâng lên STAGING.
    Thì bước 1, 2, 3, 4 trả `409` ERR-04-023, `detail` nêu môi trường trước và điều kiện còn thiếu (thời gian ổn định còn lại ở bước 3). Git: không cho PROD.

  @TC-04-099 @P1 @Âm @Bảo @mật
  Kịch bản: TC-04-099 Chỉ phiên bản đã duyệt được phát hành
    # Truy vết: FR-04-042 · BR-04-012 · ERR-04-005.
    Biết `tc-nhap` v1 `DRAFT`; F-HT phiên bản `PENDING_REVIEW`.
    Khi IA1 phát hành `tc-nhap` v1 lên TEST.
    Và IA1 phát hành phiên bản `PENDING_REVIEW` lên TEST.
    Và dùng tài khoản Git của nhân viên DevOps đẩy trực tiếp một `flow.camel.yaml` không có chữ ký vào `env/test`.
    Thì bước 1, 2 trả `409` ERR-04-005. Bước 3: CI kho cấu hình (ADR-068) từ chối vì thiếu chữ ký hợp lệ; nếu nhánh bảo vệ bị vượt qua thì `FlowLoader` của runtime từ chối nạp tệp không có chữ ký khớp `contentHash` đã duyệt, ghi `loadError`, phát cảnh báo an ninh PH-13. Luồng không chạy.

  @TC-04-100 @P1 @Âm @Khả @dụng
  Kịch bản: TC-04-100 Lỗi ghi Git
    # Truy vết: FR-04-042 · API-04-054 · ERR-04-022.
    Biết gitea trả `500` cho mọi lệnh đẩy (Chaos Mesh hoặc WireMock trước Gitea).
    Khi phát hành F-HT v4 lên TEST.
    Thì `202`; sau ba lần thử lại giãn cách, triển khai `FAILED`, `errorCode = ERR-04-022`; phiên bản vẫn `APPROVED`; nút "Thử lại" có trên UI-04-15. Runtime vẫn chạy phiên bản cũ.

  @TC-04-101 @P2 @Âm
  Kịch bản: TC-04-101 Quá hạn đồng bộ
    # Truy vết: FR-04-042 · BR-04-018.
    Biết `04.deploy.timeout-minutes = 2`; Argo CD tạm dừng đồng bộ ứng dụng `dh-runtime-t68-test`.
    Khi phát hành v4 lên TEST, chờ 2 phút.
    Thì `SYNCING` → `FAILED` với lý do lấy từ trạng thái Argo CD ("OutOfSync"); EVT-04-07 phát; thông báo người phát hành.

  @TC-04-102 @P1 @Âm
  Kịch bản: TC-04-102 Phát hành trong khoảng đóng băng, không có hồ sơ runtime
    # Truy vết: FR-04-042, 084 · BR-04-022 · ERR-04-041, 029.
    Biết TA đặt khoảng đóng băng 2 giờ tới; `tc-jvm` dùng thành phần chỉ JVM, tenant không được hồ sơ JVM.
    Khi phát hành F-HT v4 lên PROD.
    Và phát hành F-HT v4 lên TEST.
    Và phát hành `tc-jvm` lên TEST.
    Thì bước 1 trả `423` ERR-04-041 kèm `until`. Bước 2 trả `202` (đóng băng chỉ chặn PROD). Bước 3 trả `422` ERR-04-029.

  @TC-04-103 @P2 @Bảo @mật
  Kịch bản: TC-04-103 Lệch băm sau khi đồng bộ
    # Truy vết: FR-04-042, 051 · BR-04-018 · EVT-04-07, 12.
    Biết v4 `SYNCED` ở TEST; giả lập một bản sao báo nhịp tim với `contentHash` khác (bản sao bị sửa ConfigMap bằng tay).
    Khi sửa ConfigMap của luồng trong namespace `dh-rt-t68` bằng `kubectl`.
    Và chờ 2 nhịp tim.
    Thì argo CD tự đưa ConfigMap về bản Git (self-heal). Trong lúc lệch, triển khai `OUT_OF_SYNC`, EVT-04-07 phát; khi khớp lại thì về `SYNCED`. Cảnh báo PH-13 "Cấu hình runtime bị sửa ngoài GitOps".

  @TC-04-195 @P1 @Âm
  Kịch bản: TC-04-195 Phát hành khi kiểm tra mức PUBLISH còn lỗi hoặc catalog cũ
    # Truy vết: FR-04-042, 081 · UC-04-12 · API-04-054 · UI-04-15 · ERR-04-009, 042.
    Biết U-T68-IA1; F-HT v4 `APPROVED` nhưng chặng `deliver` dùng topic vừa bị thu hồi quyền (VR-05 mức `PUBLISH` thành `ERROR`); F-SOAP v3 `APPROVED` soạn trên `cv-1` trong khi catalog hiện hành là `cv-2`.
    Khi gọi `POST /flows/tra-cuu-ho-tich/deployments` với `{"versionNo":4,"environment":"TEST"}`.
    Và gọi `POST /flows/bhxh-soap/deployments` với `{"versionNo":3,"environment":"TEST"}`.
    Và lặp bước 1 trên UI-04-15.
    Thì bước 1 trả `422` ERR-04-009, `findings[]` chỉ chặng `deliver`. Bước 2 trả `409` ERR-04-042, kiểm catalog trước khi chạy đủ quy tắc. Bước 3: hộp thoại "Luồng còn 1 lỗi cần sửa trước khi phát hành." kèm "Mở bảng Vấn đề". Không tạo bản ghi `deployment`. Git: không. EVT: không.

  @TC-04-196 @P1 @Dương
  Kịch bản: TC-04-196 Đầu cuối phát hành lên PROD tới SYNCED theo trình tự SDD
    # Truy vết: FR-04-042, 045 · BR-04-012 · UC-04-12 · API-04-054 · EVT-04-06, 07, 12 · NFR-04-009.
    Biết U-T68-IA1; F-HT v4 `APPROVED`, đã `SYNCED`, `HEALTHY` ở TEST và STAGING đủ thời gian ổn định; nhánh `env/prod` của `dh-flows-t68` được bảo vệ; có thể giữ nhịp tim của runtime PROD 60 giây (D03-02-PH04 §5.5, hình phát hành tới SYNCED).
    Khi gọi `POST /flows/tra-cuu-ho-tich/deployments` với `{"versionNo":4,"environment":"PROD"}` và `Idempotency-Key`.
    Và đọc `deployment`, `ph04.outbox` ngay sau phản hồi.
    Và theo dõi Gitea: nhánh `release/tra-cuu-ho-tich-v4`, yêu cầu gộp, CI của kho.
    Và khi Argo CD báo Application đồng bộ, giữ nhịp tim 60 giây rồi thả.
    Và đọc lại `deployment`.
    Thì bước 1 trả `202` có `deploymentId`. Bước 2: `deployment` ở `PENDING`, một dòng outbox EVT-04-06 trong cùng giao dịch. Bước 3: commit có chữ ký, tác giả `dh-integration[bot]`, trailer `Dh-Published-By` và `Dh-Deployment: {id}`; yêu cầu gộp vào `env/prod` tự gộp sau khi CI chạy lại VR mức `PUBLISH` và ca kiểm thử. Bước 4: trong lúc giữ nhịp tim, triển khai chỉ ở `SYNCING` dù Argo CD đã báo đồng bộ. Bước 5: sau khi đủ bản sao báo `version = 4` và đúng `contentHash`, triển khai `SYNCED`, phát EVT-04-07. Từ gửi tới `SYNCED` (trừ 60 giây giữ) p95 < 3 phút. KT: có (`INT_DEPLOY`).
