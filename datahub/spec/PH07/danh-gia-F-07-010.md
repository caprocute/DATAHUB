# Đánh giá độc lập F-07-010 · Quản lý nhóm danh mục

Phiên `danh-gia-sonnet`, ngày 26/11/2026. Mã đánh giá: b62a060, a14a5ec, 9237bf6 (HEAD f045a66).
Chạy lại tiền cảnh từ đầu, không đọc tien-do.md/thông điệp commit trước khi chạy cổng.

## 1. Cổng

| Cổng | Lệnh | Kết quả thật |
|---|---|---|
| G1 | `g1_dac_ta.py goi.yaml` | XANH, 11/11 mục (Redocly, Gherkin 15 khối, DDL+RLS trên PG 18.7) |
| G2/G3/G4-API | `mvn verify` | XANH: 47 test đơn vị + 40 test IT (Cucumber 14/14 kịch bản, GroupApiIT 16, CrossTenantLeakIT 6, RlsIT 4); JaCoCo `check-rdm` và `check-shared` đạt (ngưỡng dòng 0,80) |
| G2 web | `npm ci && npm run check` | XANH: generate, typecheck, eslint `--max-warnings 0`, Vitest 54/54; phủ dòng 91,25%, nhánh 89,14% |
| G4 E2E | `npm run e2e` | XANH 8/8 (Playwright + axe) |
| G5 | `g5_bao_mat.sh` | **ĐỎ**: `npm audit` xanh; Semgrep không chạy được vì không tải được bộ luật `p/java`, `p/typescript`, `p/react`, `p/secrets` (proxy 403 tới semgrep.dev). Tập lệnh in "Semgrep có phát hiện" nhưng nguyên nhân là hạ tầng, không phải phát hiện. Trivy không có ở môi trường này (chạy ở CI). Không có cách hợp lệ để xanh G5 ở đây, nên không lật `passes` |

Toàn vẹn: `git diff 4b4166c HEAD -- datahub/spec datahub/tools datahub/AGENTS.md` chỉ có `tien-do.md`.
`RunCucumberIT` chọn đúng `../../spec/PH07/gherkin/F-07-010.feature` (không bản chép); 14 kịch bản = 14 test chạy.
Không tìm thấy `@Disabled`, `.skip`, `fixme`, `|| true`, ngưỡng hạ. `GroupSteps` khẳng định thật (status, `problem+json`,
traceId, errors[], thứ tự cây, hậu điều kiện CSDL, đúng 1 dòng outbox + trường kiểm toán). Không thấy step rỗng.

## 2. SS-07-03…13 đối chiếu mã

| Mã | Kết | Dẫn chứng |
|---|---|---|
| 03 quyền | Đạt | `CatalogGroupController.java:51,57,83,94` (create / update / read + vai trò TA|PA); thử thật: DS 403, thiếu perm 403, thiếu vai trò 403 |
| 04 vòng/độ sâu/trùng | Đạt | `CatalogGroupService.java:154-158,213-221`; `GroupTree.java:272-285`; thử thật: tự làm cha, gốc dưới lá, cấp 6: 409 ERR-07-039 |
| 05 xóa hẳn | Đạt | `CatalogGroupService.java:243-267` (đếm cả danh mục đã xóa mềm, nhóm con) |
| 06 422 ERR-07-009 | Đạt | JSON hỏng: 422 `errors[].code=TYPE`; sortOrder/parentId sai kiểu: 422. Lệch nhỏ: xem phát hiện T2 |
| 07 tenant đầu giao dịch | Đạt | `TenantJpaTransactionManager.java:264-284` (`set_config(...,true)`); vai trò `dh_data_app` không BYPASSRLS; `CrossTenantLeakIT` |
| 08 kiểm toán | Đạt | `AuditRecorder.java:443-468`; thấy `RDM_GROUP_UPDATE` before/after chỉ trường đổi, topic `t01.rdm.audit.recorded.v1` |
| 09 nguồn quyền JWT | Đạt | `SecurityConfig.java:157-201` RS256, perms/roles từ claim |
| 10 cây rừng | Đạt | `CatalogGroupService.java:77-93`; `catalogCounts` 116-124 |
| 11 TC-07-019 | Đạt | Gherkin tự tạo `HANH_CHINH` của T68 |
| 12 createdBy UUID | Đạt | `SecurityConfig.java:170-183` bắt `sub` là UUID; phản hồi `createdBy` là UUID |
| 13 trường lạ PATCH | Đạt | `GroupPatchParser.java:81-91`: `code` -> 422 UNKNOWN_FIELD |

## 3. Ca phá (chạy backend thật: PG 18 riêng + jar + khóa RSA riêng, ngoài repo)

| Ca | Kỳ vọng | Kết quả |
|---|---|---|
| PATCH `parentId` sang nhóm tenant khác (T01 -> nhóm T02) | Từ chối, không lộ tồn tại | 422 ERR-07-009 PARENT_NOT_FOUND. Đạt |
| POST `parentId` = nhóm COMMON bằng tenant tỉnh | 403 chỉ đọc | 403 ERR-07-003. Đạt |
| PATCH/DELETE nhóm tenant khác; PATCH/DELETE COMMON bằng tỉnh; PATCH COMMON bằng PA | 404 / 403 / 200 | 404 ERR-07-045; 403 ERR-07-003; PA 200. Đạt |
| Tên NFD; 256 ký tự; 255 ký tự; 255 tổ hợp dấu | NFC; 422; 201; 201 | `Tiếng` (NFC) 201; 422; 201; 201. Đạt |
| JWT khóa khác / hết hạn / thiếu `tenant` / `tenant=COMMON` / `T1` / alg none / `sub` không UUID / tenant kiểu SQLi | 401 | Tất cả 401 ERR-07-041. Đạt |
| Header `X-DH-Tenant: T02`, `X-Tenant-Id` với token T01 | Bỏ qua | Cây chỉ có nhóm T01 + COMMON. Đạt |
| `Idempotency-Key` cùng khóa, cùng thân, hai tenant | Không rò | T02 nhận id khác, không có `Idempotent-Replayed`. Đạt |
| Cùng khóa: phát lại / khác thân / khóa ngắn / 6 luồng song song | Replay; 409 ERR-07-022; 422; 1 bản ghi | Replay cùng id + header; 409; 422; 6/6 trả cùng id. Đạt |
| Xóa nhóm còn nhóm con; xóa con rồi cha | 409 ERR-07-037; 204 | 409; 204/204. Đạt |
| 8 PATCH song song cùng ETag | 1 thắng, còn lại 412 | 1x200, 7x412. Đạt |
| Mã `bad code`, `A;DROP`, `../x`, `Aé`, `-A`, rỗng, 65 ký tự, toàn rộng `ａｂｃ`, xuống dòng, `İ` | 422 | Tất cả 422. 64 ký tự 201. Đạt |
| Trường lạ `tenantId` ở POST; thân hỏng; Content-Type sai; If-Match `*`/tràn số; `parentId` UUID ngẫu nhiên | 422/415/400/422 | 422; 422 TYPE; 415 ERR-07-043; 400 ERR-07-040; 422. Đạt |
| POST `name: 5` (số, không phải chuỗi) | 422 TYPE | **201, tên "5"**. Không đạt (T2) |
| POST `sortOrder: -5` | OpenAPI không nêu cận; chấp nhận | 201. Ghi nhận |

Log backend: không có token/Bearer/stack trace.

## 4. Phát hiện

### Cao
**C1. Panel cây nhóm tràn khỏi khung, nút "Thêm nhóm" và các hàng dưới không với tới bằng chuột/cuộn** (vi phạm CC-FE-14,
AGENTS §5 "cuộn trong khung"). `datahub/web/apps/console/src/features/rdm/pages/catalog-groups-page.css:2-5`
(`.rdm-page` dùng `min-height:100%` thay vì chiều cao cố định, thiếu `min-height:0` cho lưới/panel) nên `.rdm-page__tree`
(`overflow:auto`, dòng 27) không bao giờ cuộn: panel tự giãn theo nội dung, `.dh-main` (`overflow:hidden`) cắt.
Tái hiện: mở màn với khoảng 30 nhóm ở 1440x900. Đo: `.dh-main` cao 844, `.rdm-page__groups` cao 1137, `.rdm-page__tree`
clientHeight = scrollHeight = 980 (không cuộn nội bộ), nút "Thêm nhóm" ở y=1169 > 900; `mouse.wheel` không đổi vị trí.
Test Vitest (jsdom) và e2e (ít nhóm) không bắt được. Với khung 1024x600 chỉ cần khoảng 10 nhóm (chưa đo riêng).

### Trung bình
**T1. G5 không chạy được Semgrep** (hạ tầng chặn tải luật), tập lệnh in thông báo gây hiểu nhầm là "có phát hiện" thay vì
"không chạy được". Không có bằng chứng SAST; soát tay (mục 6) không thấy lỗi nhưng không thay thế được cổng.

### Thấp
**T2. POST ép kiểu số thành chuỗi**: `CatalogGroupCreateRequest.java:15-26` giải mã bằng Jackson mặc định cho phép
`"name": 5` thành "5" (PATCH thì chặn đúng ở `GroupPatchParser.java:121`). Hai đường không nhất quán; OpenAPI nói `string`.
**T3. px viết cứng trong apps/**: `catalog-groups-page.css:3` (`minmax(260px, 340px)`), `:78-79` (`2px`, `1px`), `:84` (`16px`)
(AGENTS §2, CC-FE-13). ESLint không bắt CSS.
**T4. PATCH không đổi gì trả 200 với version cũ, không kiểm toán** (`CatalogGroupService.java:230-232`): chấp nhận được, ghi nhận.

## 5. Giao diện (ảnh `/tmp/danh-gia/main.png`, `dialog.png`, 1440x900, scale 1)

So với `ui-07-01.png`: bố cục khung (đầu trang, thanh bên, panel cây + vùng phải) đúng hướng; hifi có tiêu đề trang,
breadcrumb, thẻ số liệu, bảng; lát cắt chỉ làm khung cây nên thiếu phần đó (đúng phạm vi). Glass chỉ ở topbar/sidebar
(`app-shell.css:15`), nội dung và hộp thoại nền đặc, đạt. Không cuộn cấp cửa sổ (`documentElement` 900/900 ở 1440x900 và 600/600
ở 1024x600) nhưng do C1, nội dung bị cắt thay vì cuộn trong khung: ảnh chính thấy hàng "Hành chính, địa giới" bị cắt ở mép dưới
và không thấy nút Thêm nhóm. Hộp thoại gọn, nhãn tiếng Việt, hướng dẫn ô Mã rõ.

## 6. Soát D04-01

Ranh giới module (ArchitectureTest 11 test), DTO `record`, không trả entity (`CatalogGroupView` ở `api`), không `nativeQuery`,
SQL tham số hóa (`JdbcClient` với `:name`), tenant đặt đầu giao dịch bằng `set_config(...,true)`, không log token, không
`fetch`/`axios`/`localStorage` trong component (token ở bộ nhớ, PKCE dùng sessionStorage), chuỗi qua i18n (không thấy
literal tiếng Việt trong tsx), không màu hex/`rgb` viết cứng, không `style={{}}`; chỉ vướng T3.

## 7. Kết luận

**`passes` giữ `false`.** G1-G4 xanh thật và 11/11 quyết định SS đạt, backend chịu được mọi ca phá an toàn. Nhưng G5 không xanh
(Semgrep không chạy được) và có một lỗi Cao về bố cục (C1). Cần: sửa CSS để khung cây cuộn nội bộ cùng test
chặn hồi quy (e2e với >= 30 nhóm, kiểm nút Thêm nhóm trong viewport), chạy lại G5 ở môi trường có truy cập luật Semgrep.
Không đổi `features.json`.

## 8. Vòng 2 (commit đánh giá a08d27b, sửa ở cfedfca)

| Cổng | Kết quả |
|---|---|
| G1 | XANH 11/11 (sau khi gỡ vá SS-07-01/02, `goi.yaml` `sua_trung_khoa: false`) |
| `mvn verify` | XANH: 47 đơn vị + 40 IT (Cucumber 14/14), JaCoCo đạt |
| `npm run check` | XANH: Vitest 54/54, phủ dòng 91,25%, nhánh 89,14% |
| `npm run e2e` | Lần 1 ĐỎ 1/10 (ca "mã trùng", `expectNoAxeViolations` hết 60 s ở `waitForFunction(getAnimations)`); chạy lại 2 lần liền: 10/10 XANH. Ghi nhận ca chập chờn (T5, Thấp), chưa tái hiện được nguyên nhân |
| G5 | Không xét ở đây (CI: Semgrep, Trivy). Tập lệnh đã tách "không chạy được" khỏi "có phát hiện" |

Toàn vẹn: `tools/g5_bao_mat.sh` chỉ đổi cách báo (chặt hơn: thiếu Semgrep nay là lỗi); không hạ ngưỡng, không `@Disabled`/`.skip`.

**C1 đã sửa.** Tái hiện tự làm (35 nhóm thêm vào T01, build console từ HEAD): 1440x900 nút Thêm nhóm bottom=860, tài liệu 900,
cây cuộn nội bộ (scrollHeight 1399 > clientHeight 639); 1280x720 bottom=680, cây 1399 > 459; nhóm "035" và nút bấm được, hộp thoại mở.
Đối chứng CSS cũ (chèn lại quy tắc cũ bằng `addStyleTag`, xấp xỉ): nút bottom=1620 > viewport, cây không cuộn (1399=1399); khẳng định
đầu của E2E mới (nút trong màn hình) sẽ đỏ với CSS cũ. Không build lại nhánh cũ nguyên bản. Ảnh: `/tmp/danh-gia/v2-1280.png`.

**T2 đã sửa**: `name` là 5 / true / 1.5 / mảng, `description: 7` ở POST: 422 TYPE; PATCH số: 422; chuỗi hợp lệ 201.
**T3 đã sửa** (CSS dùng token). 3 ca phá chọn lại: cha khác tenant 422; cha COMMON 403; JWT khóa khác / thiếu tenant 401;
8 PATCH song song 1x200 + 7x412; xóa nhóm còn con 409. Đều đạt.

Kết luận vòng 2: không còn lỗi Cao; G1-G4 xanh (e2e sau một lần chập chờn). Đề xuất `passes: true` kèm `danh_gia`
(vong 2, "G5: chờ CI (Semgrep, Trivy)"). Việc ghi cờ này chưa thực hiện được trong phiên này (xem phản hồi gửi người điều phối).
