# language: vi
# Sinh tự động từ D05-02-PH20 bằng ph20/tools/gen_gherkin.py; không sửa tay.
@PH-20 @TS-20-14
Tính năng: TS-20-14 · Đặt, đổi hạn mức hợp đồng và ghi đè tạm thời

  @TC-20-059 @P1 @Dương
  Kịch bản: TC-20-059 Đặt hạn mức hợp đồng và đọc hạn mức hiệu lực
    # Truy vết: FR-20-026 · UC-20-14 · API-20-048, 049, 164 · BR-20-013 · EVT-20-05 · UI-20-05 · `PERM-20-quota`
    Biết `U-PA1`; `T96` có hợp đồng `ACTIVE`, hạn mức theo F-QUOTA; `S-PH03`.
    Khi `GET P/tenants/T96/quotas`
    Và `PUT P/tenants/T96/quotas` với `items` = `API_RPS` 600, `USERS` 2.500, `contractId`, `reason`, `ticketRef`, kèm `If-Match`
    Và `S-PH03` gọi `GET I/tenants/T96/enforcement`
    Thì bước 1 có `contractValue`, `platformCeiling`, `overrideValue`, `effectiveValue`, `lastUsage`, `source`, `pushStatus` cho 12 tài nguyên. Bước 2 `200`, `effectiveValue` = giá trị mới (tăng trong trần); `pushStatus` `PENDING` rồi `PUSHED`. EVT: `platform.tenant.quota-changed.v1`. Bước 3 `quotas[]` có `API_RPS` 600 để PH-03 áp ở APISIX. KT có `reason`, `ticketRef`.

  @TC-20-060 @P1 @Âm
  Kịch bản: TC-20-060 Hạn mức ngoài miền, vượt trần, hạ dưới mức đang dùng, hợp đồng không hợp lệ
    # Truy vết: FR-20-026, 027 · API-20-049 · BR-20-013, 014 · ERR-20-005, ERR-20-008, ERR-20-010, ERR-20-022, ERR-20-029, ERR-20-030, ERR-00-428
    Biết `U-PA1`; `T96` `OBJECT_STORAGE_GB` hợp đồng 500, đang dùng 300; hợp đồng `HD-HET-HAN` đã `EXPIRED`.
    Khi `PUT P/tenants/T96/quotas` với `API_RPS = 0`
    Và `PUT` với `API_RPS` vượt trần nền tảng
    Và `PUT` với `OBJECT_STORAGE_GB = 250` (thấp hơn mức dùng 300)
    Và `PUT` với `contractId` của hợp đồng đã hết hạn
    Và `PUT` thiếu `If-Match`; `If-Match` cũ; thiếu `ticketRef`
    Và `PUT P/tenants/COMMON/quotas`
    Thì bước 1, 2 `422` `ERR-20-029`. Bước 3 `422` `ERR-20-030`, nêu phải qua đề nghị có duyệt. Bước 4 `422` `ERR-20-022`. Bước 5 lần lượt `428` `ERR-00-428`, `412` `ERR-20-005`, `422` `ERR-20-008`. Bước 6 `403` `ERR-20-010`. Không đổi hạn mức.

  @TC-20-061 @P1 @Dương
  Kịch bản: TC-20-061 Đề nghị hạ hạn mức dưới mức đang dùng, duyệt bốn mắt, đẩy xuống nơi thực thi
    # Truy vết: FR-20-027 · UC-20-14 · API-20-050, 051, 052, 053, 164 · BR-20-008, 014 · EVT-20-05 · UI-20-05, 08 · `PERM-20-quota`, `PERM-20-approve`
    Biết `U-PA1`, `U-PA2`; `T96`; `gw-sim` xác nhận qua `EVT-03-11`; `ops-sim` nhận việc duyệt.
    Khi `U-PA1` `POST P/tenants/T96/quota-change-requests` với `items` = `OBJECT_STORAGE_GB` 250, `effectiveAt`, `reason`, `ticketRef`
    Và `U-PA2` `POST P/quota-change-requests/{requestId}:approve` với `comment`
    Và `GET P/tenants/T96/quota-change-requests?status=DONE`
    Và đọc `GET P/tenants/T96/quotas` và dung lượng đang dùng
    Thì bước 1 `201`, `PENDING_APPROVAL`. Bước 2 `200`, `APPROVED` rồi `DONE` sau khi `EVT-03-11` xác nhận áp. Bước 3 có đề nghị. Bước 4 `effectiveValue` = 250 nhưng tài nguyên đã cấp (300 GB) không bị cắt, chỉ chặn cấp mới (BR-20-014). EVT: `quota-changed` một lần. Từ chối: `U-PA2` `:reject` kèm `comment` thì `REJECTED`, hạn mức giữ 500.

  @TC-20-062 @P1 @Âm
  Kịch bản: TC-20-062 Tự duyệt đề nghị hạn mức, duyệt hai lần, từ chối thiếu ý kiến
    # Truy vết: FR-20-027 · API-20-050, 052, 053 · BR-20-008 · ERR-20-004, ERR-20-005, ERR-20-006, ERR-20-007, ERR-20-029, ERR-00-403
    Biết `U-PA1`, `U-PA2`, `U-PA3`; `U-T90-TA`; đề nghị `PENDING_APPROVAL` do `U-PA1` lập; đề nghị đã `APPROVED`.
    Khi `U-PA1` `:approve` đề nghị của chính mình
    Và `U-PA2` `:approve` đề nghị đã `APPROVED`
    Và `U-PA2` `:reject` thiếu `comment`
    Và `U-T90-TA` gọi `:approve`
    Và `U-PA2` `:approve` với `If-Match` cũ
    Và đề nghị có giá trị mới `API_RPS = 9999` rồi duyệt
    Thì bước 1 `403` `ERR-20-007`. Bước 2 `409` `ERR-20-006`. Bước 3 `400` `ERR-20-004`. Bước 4 `403` `ERR-00-403`. Bước 5 `412` `ERR-20-005`. Bước 6 `422` `ERR-20-029`. Đề nghị không đổi trạng thái khi bị từ chối.

  @TC-20-063 @P2 @Dương
  Kịch bản: TC-20-063 Ghi đè hạn mức tạm thời, thu hồi và tự hết hạn
    # Truy vết: FR-20-032 · UC-20-14 · API-20-054, 055, 048 · BR-20-013, 015 · EVT-20-05 · UI-20-05 · `PERM-20-quota`
    Biết `U-PA1`; `T96` `USERS` hợp đồng 2.000; `20.quota.override-max-days` = 30; `clock-sim`.
    Khi `POST P/tenants/T96/quota-overrides` với `resource = USERS`, `value = 2500`, `validFrom`, `validTo` sau 10 ngày, `reason`, `ticketRef`
    Và `GET P/tenants/T96/quotas`
    Và `clock-sim` đẩy 11 ngày; `GET P/tenants/T96/quotas`
    Và ghi đè thứ hai rồi `POST .../quota-overrides/{overrideId}:revoke` với `reason`
    Thì bước 1 `201`. Bước 2 `effectiveValue` `USERS` = 2.500 (lớn hơn của hợp đồng và ghi đè còn hạn), `source = OVERRIDE`. Bước 3 trả về 2.000, ghi đè `EXPIRED`. Bước 4 `200`, thu hồi trước hạn, hạn mức trở lại hợp đồng. EVT: `quota-changed` khi tạo, khi thu hồi, khi hết hạn.

  @TC-20-064 @P2 @Âm
  Kịch bản: TC-20-064 Ghi đè quá số ngày, vượt trần, thu hồi sai, thiếu lý do
    # Truy vết: FR-20-032 · API-20-054, 055 · BR-20-015 · ERR-20-004, ERR-20-006, ERR-20-008, ERR-20-010, ERR-20-029, ERR-20-031
    Biết `U-PA1`; `T96`; ghi đè đã `EXPIRED`; tenant `PLATFORM`.
    Khi ghi đè với `validTo` sau 45 ngày
    Và ghi đè `value` vượt trần nền tảng
    Và ghi đè thiếu `reason`
    Và `:revoke` ghi đè đã `EXPIRED`
    Và ghi đè `resource = KHONG_CO`; ghi đè `validTo` trước `validFrom`
    Và ghi đè cho `PLATFORM`
    Thì bước 1 `422` `ERR-20-031`. Bước 2 `422` `ERR-20-029`. Bước 3 `422` `ERR-20-008`. Bước 4 `409` `ERR-20-006`. Bước 5 `400` `ERR-20-004`. Bước 6 `403` `ERR-20-010`.

  @TC-20-065 @P3 @Âm @Chịu @lỗi
  Kịch bản: TC-20-065 Nơi thực thi không xác nhận áp hạn mức sau 15 phút
    # Truy vết: FR-20-027 · UC-20-14 · API-20-164, 048 · BR-20-013 · EVT-20-05 · UI-20-05
    Biết `U-PA1`; `T96`; `gw-sim` không phát `EVT-03-11`; `clock-sim`.
    Khi đổi hạn mức `API_RPS` của `T96` tăng trong trần
    Và đẩy `clock-sim` 15 phút
    Và `GET P/tenants/T96/quotas`
    Thì `pushStatus = PENDING` rồi cảnh báo ở UI-20-05, PH-20 không tự thử lại, không tự hoàn tác (Q20-49); khi `gw-sim` phát lại xác nhận thì `PUSHED`.
