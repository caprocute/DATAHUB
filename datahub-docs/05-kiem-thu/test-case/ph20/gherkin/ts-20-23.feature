# language: vi
# Sinh tự động từ D05-02-PH20 bằng ph20/tools/gen_gherkin.py; không sửa tay.
@PH-20 @TS-20-23
Tính năng: TS-20-23 · Lịch sử vòng đời và thông báo đổi trạng thái

  @TC-20-104 @P1 @Dương
  Kịch bản: TC-20-104 Tra lịch sử trạng thái, quyết định và đề nghị vòng đời
    # Truy vết: FR-20-043 · UC-20-23 · API-20-085, 072, 074 · UI-20-03 · `PERM-20-read`
    Biết `U-PA1`, `U-PO`, `U-PAU`; `T92` có chuỗi `PROVISIONING`, `ACTIVE`, `SUSPENDED`, `ACTIVE`, `SUSPENDED`.
    Khi `GET P/tenants/T92/status-history`
    Và `GET P/tenants/T92/status-history?type=SUSPEND&from=2026-01-01&to=2026-11-27`
    Và `GET P/tenants/T92/lifecycle-requests` bằng `U-PAU`
    Và mở tab "Lịch sử vòng đời" ở UI-20-03
    Thì bước 1 liệt kê theo thời gian: trạng thái cũ, mới, người, lý do, mã phiếu, văn bản quyết định, đề nghị liên quan. Bước 2 chỉ lần tạm ngừng. Bước 3 `U-PAU` xem được, không sửa. Bước 4 hiển thị đúng và không có nút ghi cho PO, PAU.

  @TC-20-105 @P2 @Âm
  Kịch bản: TC-20-105 Lịch sử: tenant không có, tham số sai
    # Truy vết: FR-20-043 · API-20-085, 072 · ERR-20-002, ERR-20-004
    Biết `U-PA1`, `U-T90-TA`.
    Khi `GET P/tenants/T89/status-history`
    Và `GET P/tenants/T92/status-history?from=ngay-sai`
    Và `GET P/tenants/T92/lifecycle-requests?type=KHONG-CO`
    Và `U-T90-TA` gọi `GET P/tenants/T92/status-history`
    Thì bước 1 `404` `ERR-20-002`. Bước 2, 3 `400` `ERR-20-004`. Bước 4 `403` `ERR-00-403`.

  @TC-20-106 @P2 @Dương
  Kịch bản: TC-20-106 Thông báo đổi trạng thái tới đầu mối và quản trị tỉnh
    # Truy vết: FR-20-044 · UC-20-23 · EVT-20-04 · BR-20-039 · NFR-20-020
    Biết `T92`; `ops-sim` nhận `NotificationApi`; ba đầu mối và `U-T92-TA`.
    Khi tạm ngừng rồi khôi phục `T92`
    Và đọc thư ở `ops-sim` và bản tin EVT-20-04
    Và `ops-sim` trả `503` khi gửi, đổi trạng thái `T92` lần nữa
    Thì bước 2 mỗi lần đổi trạng thái có một thư tới đầu mối và `TENANT_ADMIN` với nội dung nêu trạng thái mới, lý do, liên hệ; EVT-20-04 phát ≤ 5 giây (NFR-20-020) và chỉ chứa mã, trạng thái, không dữ liệu cá nhân (BR-20-039). Bước 3 đổi trạng thái vẫn thành công, thông báo thử lại qua outbox, kết quả gửi xem được ở API-20-085.

  @TC-20-107 @P2 @Âm
  Kịch bản: TC-20-107 Thông báo: PH-18 lỗi thử lại 6 lần, không còn đầu mối hoạt động
    # Truy vết: FR-20-044 · ERR-20-062 · ERR-20-021 · UC-20-23
    Biết `ops-sim` `503`; `T90` chỉ còn đầu mối `LEADER` (đầu mối `TENANT_ADMIN`, `TECHNICAL` đã vô hiệu); `U-PO`.
    Khi tạm ngừng `T90` khi `ops-sim` `503`; tiến đồng hồ 1 giờ
    Và đặt `T90` chỉ còn một đầu mối rồi đổi trạng thái
    Thì bước 1 thử lại 6 lần trong 1 giờ rồi cảnh báo PO ở UI-20-20 (`ERR-20-062`); trạng thái tenant vẫn đổi (thông báo không chặn). Bước 2 `ERR-20-021` ("Cần đủ đầu mối TENANT_ADMIN trước khi thông báo."), cảnh báo PO.
