# language: vi
# Sinh tự động từ D05-02-PH03 bằng ph03/tools/gen_gherkin.py; không sửa tay.
@PH-03 @TS-03-04
Tính năng: TS-03-04 · Ngoại lệ luật WAF và luật vá ảo khẩn cấp

  @TC-03-020 @P1 @Dương
  Kịch bản: TC-03-020 Vòng đời ngoại lệ WAF: đề nghị, duyệt, hiệu lực, hết hạn
    # Truy vết: FR-03-007 · API-03-042, 043, 044, 046 · UI-03-07, 08, 17 · EVT-03-05, 06 · BR-03-006 · UC-03-14 · SEC-07.
    Biết U-T68-TO đề nghị; U-T68-SO1 duyệt; WAF `BLOCK`; cảnh báo giả `942100` trên `r-ho-tich`.
    Khi TO `POST /waf/exceptions` `{routeCode: r-ho-tich, ruleId: 942100, days: 30, reason}`.
    Và SO1 `POST /waf/exceptions/{id}:approve`.
    Và gửi payload kích hoạt luật 942100 tới `r-ho-tich` và tới route khác.
    Và tiến `faketime` tới còn 7 ngày, rồi hết hạn.
    Và thu hồi một ngoại lệ khác bằng `POST …:revoke`.
    Thì bước 1 `201`, `PENDING`; EVT: `waf-exception.changed`. Bước 2 `200`, hiệu lực ≤ 60 s. Bước 3 payload không bị chặn ở `r-ho-tich` nhưng bị chặn ở route khác (ngoại lệ chỉ một route, một luật). Bước 4 có EVT: `waf-exception.expiring` ở mốc 7 ngày, sau hạn luật 942100 chặn trở lại. Bước 5 `200`, hiệu lực ≤ 60 s. KT: có (`WAF_EXC_REQUEST`, `WAF_EXC_APPROVE`, `WAF_EXC_REVOKE`).

  @TC-03-021 @P1 @Âm
  Kịch bản: TC-03-021 Ngoại lệ WAF sai: quá 90 ngày, thiếu lý do, luật không có, trùng
    # Truy vết: FR-03-007 · API-03-043 · ERR-03-009, 010, 003 · UI-03-08 · BR-03-006.
    Biết U-T68-TO; đã có ngoại lệ hiệu lực cho `r-ho-tich`, `942100`.
    Khi `POST /waf/exceptions` với `days = 91`.
    Và thiếu `reason`.
    Và `ruleId = 999999` không có trong CRS.
    Và cùng `r-ho-tich`, `942100` lần hai.
    Và thân chứa trường lạ `{"foo": 1}`.
    Thì bước 1–3 `422` ERR-03-009 "Ngoại lệ cần có lý do, mã luật hợp lệ và thời hạn không quá 90 ngày." Bước 4 `409` ERR-03-010 kèm `existingExpiresAt`. Bước 5 `400` ERR-03-003. Không tạo ngoại lệ nào, KT: không.

  @TC-03-022 @P1 @Âm @Bảo @mật
  Kịch bản: TC-03-022 Tự duyệt ngoại lệ WAF, người duyệt thiếu vai trò, tách nhiệm
    # Truy vết: FR-03-007 · API-03-044, 045 · ERR-03-008, 022 · BR-03-006, 019 · UC-03-14.
    Biết U-T68-SO-VD tự đề nghị; U-T68-TO; U-T68-SO2.
    Khi U-T68-SO-VD đề nghị rồi tự `:approve`.
    Và U-T68-TO `:approve` ngoại lệ của người khác.
    Và U-T68-SO2 `:reject` có lý do; sau đó `:approve` lại.
    Thì bước 1 `403` ERR-03-008 dù người dùng có đủ quyền (lớp bốn mắt độc lập vai trò). Bước 2 403-PQ (TO không có `PERM-03-waf-approve`). Bước 3 từ chối `200`; duyệt sau từ chối `409` ERR-03-019. KT: có cho từng lần duyệt, từ chối; ghi người đề nghị và người duyệt.

  @TC-03-023 @P2 @Dương @Âm
  Kịch bản: TC-03-023 Luật vá ảo khẩn cấp: tạo, hiệu lực, gỡ
    # Truy vết: FR-03-008 · API-03-047, 048, 049 · UI-03-08 · ERR-03-009, 019, 022 · UC-03-15 · NFR-03-012 · SEC-09, 11.
    Biết U-T68-SO1; U-T68-TO; luật tùy biến chặn chuỗi `${jndi:` ở tham số `q`.
    Khi SO1 `POST /waf/virtual-patches` với mã luật hợp lệ, lý do, hạn 30 ngày.
    Và gửi `?q=${jndi:ldap://x}` tới route đã khai.
    Và SO1 `POST /waf/virtual-patches/{patchId}:retire`; gỡ lần hai.
    Và tạo luật có lý do rỗng; TO tạo luật.
    Thì bước 1 `201`; có hiệu lực ≤ 4 giờ theo cam kết, đo thực tế ≤ 60 s. Bước 2 `403` Lỗi GW 109. Bước 3 lần một `200`, lần hai `409` ERR-03-019. Bước 4 `422` ERR-03-009; TO nhận 403-PQ. KT: có (`VPATCH_CREATE`, `VPATCH_RETIRE`).
