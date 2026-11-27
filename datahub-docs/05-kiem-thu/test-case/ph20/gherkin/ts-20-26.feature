# language: vi
# Sinh tự động từ D05-02-PH20 bằng ph20/tools/gen_gherkin.py; không sửa tay.
@PH-20 @TS-20-26
Tính năng: TS-20-26 · Điều phối chuyển dữ liệu sáp nhập theo phân hệ

  @TC-20-118 @P1 @Dương
  Kịch bản: TC-20-118 Bắt đầu chuyển dữ liệu T91 sang T90, kiểm đếm khớp
    # Truy vết: FR-20-048 · UC-20-26 · API-20-098, 099, 088, 167 · BR-20-023 · NFR-20-014 · EVT-20-04, 10 · UI-20-10 · `PERM-20-merge`
    Biết STAGING; `U-PA1`; kế hoạch `APPROVED`; F-MERGE đã giải quyết ánh xạ; `ops-sim` giả định hợp đồng `merge-transfers` (Q20-15).
    Khi `POST P/merge-plans/{id}:start` với `reason`, `ticketRef`, kèm `If-Match`, `Idempotency-Key`
    Và theo dõi `GET P/merge-plans/{id}/participants`
    Và kiểm đếm `USER`: nguồn 150, `SKIP` 6; `ORGANIZATION`: nguồn 25
    Và kiểm `id` và `origin_tenant_id` ở đích
    Thì bước 1 `202`, nguồn `T91` `MERGING` nhưng vẫn phục vụ, kế hoạch `TRANSFERRING`; EVT: `merge-started` và `status-changed`. Bước 2 thứ tự phụ thuộc PH-20 (tổ chức), PH-07, PH-01, PH-02, PH-10, PH-04, PH-05, PH-03, các phân hệ khác; mỗi phân hệ `SUCCEEDED`. Bước 3 `USER` nhập 144, `ORGANIZATION` nhập 25 (tổng tổ chức `T90` = 65) khớp 100 % (NFR-20-014). Bước 4 dữ liệu giữ `id` gốc, có `origin_tenant_id = T91`. Hết phân hệ thì kế hoạch sang `IDENTITY_TRANSFER`.

  @TC-20-119 @P1 @Âm
  Kịch bản: TC-20-119 Chuyển dữ liệu: kế hoạch chưa duyệt, chạy thử cũ, kiểm đếm lệch
    # Truy vết: FR-20-048 · API-20-098, 167 · BR-20-024 · ERR-20-005, ERR-20-006, ERR-20-008, ERR-20-043, ERR-20-113, ERR-00-428
    Biết `U-PA1`; kế hoạch `DRAFT`; kế hoạch `APPROVED` nhưng ánh xạ đổi sau chạy thử; `ops-sim` báo PH-01 nhập 119 trên 120.
    Khi `POST .../:start` khi `DRAFT`
    Và `POST .../:start` khi chạy thử cũ
    Và `POST .../:start` thiếu `reason`; thiếu `If-Match`; `If-Match` cũ
    Và chạy chuyển khi PH-01 nhập thiếu một bản ghi
    Thì bước 1 `409` `ERR-20-006`. Bước 2 `422` `ERR-20-043`. Bước 3 `422` `ERR-20-008`, `428` `ERR-00-428`, `412` `ERR-20-005`. Bước 4 phân hệ `FAILED` với `ERR-20-113` ("Kiểm đếm PH-01 lệch: nguồn 120, đích 119."), kế hoạch `FAILED` hoặc `CONFLICT_REVIEW` theo nguyên nhân; không sang `IDENTITY_TRANSFER`.

  @TC-20-120 @P2 @Dương @Âm
  Kịch bản: TC-20-120 Chạy lại chuyển của một phân hệ lỗi
    # Truy vết: FR-20-048 · API-20-100, 099 · ERR-20-004, ERR-20-006, ERR-20-043 · UI-20-10
    Biết `U-PA1`; kế hoạch `FAILED` ở PH-01 (`ops-sim` lỗi một lần); PH-07 `SUCCEEDED`.
    Khi `POST .../participants/PH-01:retry` với `reason`
    Và `POST .../participants/PH-07:retry` khi `SUCCEEDED`
    Và `POST .../participants/PH-01:retry` thiếu `reason`
    Và `POST .../participants/PH-01:retry` khi ánh xạ đã đổi (chạy thử cũ)
    Thì bước 1 `202`, phân hệ về `TRANSFERRING` rồi `SUCCEEDED`, kế hoạch tiếp tục. Bước 2 `409` `ERR-20-006`. Bước 3 `400` `ERR-20-004`. Bước 4 `422` `ERR-20-043`. Chạy lại không nhân bản dữ liệu đã chuyển (lũy đẳng theo `{mergePlanId}:{module}:transfer`).

  @TC-20-121 @P2 @Biên
  Kịch bản: TC-20-121 Dữ liệu phát sinh ở nguồn trong lúc chuyển được bù ở lượt cuối
    # Truy vết: FR-20-048, 051 · API-20-098, 106 · BR-20-023 · NFR-20-014 · UC-20-26
    Biết kế hoạch `TRANSFERRING`; trong lúc chuyển, tạo thêm 3 HTTT và sửa 2 tổ chức ở `T91`.
    Khi phát sinh thay đổi ở `T91` sau khi phân hệ đã chuyển xong
    Và chạy cutover (lượt bù cuối)
    Thì mỗi phân hệ chạy lượt bù theo `updated_at`; đích có đủ 3 HTTT và 2 sửa đổi; kiểm đếm sau bù khớp 100 %; không bản ghi nào bị ghi đè tự động.
