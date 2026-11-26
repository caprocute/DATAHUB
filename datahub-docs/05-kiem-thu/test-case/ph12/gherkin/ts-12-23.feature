# language: vi
# Sinh tự động từ D05-02-PH12 bằng ph12/tools/gen_gherkin.py; không sửa tay.
@PH-12 @TS-12-23
Tính năng: TS-12-23 · Token máy, scope và tài khoản dịch vụ

  @TC-12-068 @P1 @Dương
  Kịch bản: TC-12-068 Lấy token bằng client_credentials, TTL 5 phút, không refresh
    # Truy vết: FR-12-035 · UC-12-25 · API-12-074 · BR-12-026 · LGC-IAM-006 · NFR-12-006 · SEC-24
    Biết C-T68-A (mTLS), C-T68-B (secret, mức Công khai).
    Khi lấy token bằng mTLS và bằng `client_secret`; giải mã token.
    Thì `expires_in` ≤ 300, không có `refresh_token`, claim `tenant`, `scope` đúng phần giao; SK: `auth.token-issued`.

  @TC-12-069 @P1 @Âm
  Kịch bản: TC-12-069 Xác thực client sai, bị tạm ngừng, scope rỗng, grant bị cấm
    # Truy vết: FR-12-035 · API-12-074 · ERR-12-117, 118, 119 · BR-12-021, BR-12-024
    Biết C-T68-A; một client tạm ngừng; một client chưa có scope.
    Khi bí mật sai; chứng thư của client khác; client tạm ngừng; client scope rỗng.
    Và `client_credentials` của C-T68-N bằng bí mật.
    Thì ERR-12-117 (401), ERR-12-118 (403), ERR-12-119 (400); bước 2 bị từ chối vì mức Nhạy cảm bắt buộc mTLS.

  @TC-12-070 @P1 @Dương @Âm
  Kịch bản: TC-12-070 Scope chỉ sinh từ nguồn đã duyệt
    # Truy vết: FR-12-036 · UC-12-22 · UI-12-10 · API-12-067, 068 · BR-12-025 · ERR-12-019
    Biết giả lập PH-02, PH-07 duyệt scope `catalog:read`; U-T68-TA1.
    Khi nguồn PH-07 ghi scope `catalog:read`; `GET /clients/{id}/scopes`.
    Và TA `PUT …/scopes` thêm scope `payment:approve` không có nguồn; thêm scope loại của nguồn khác.
    Thì bước 1 scope xuất hiện, token chỉ mang phần giao với hợp đồng; bước 2 `422` ERR-12-019; không có đường ghi tay.

  @TC-12-071 @P1 @Dương @Âm
  Kịch bản: TC-12-071 Tài khoản dịch vụ nội bộ của đơn vị triển khai
    # Truy vết: FR-12-037 · UC-12-26 · UI-12-10 · API-12-069, 070, 071 · BR-12-014 · ERR-12-010
    Biết U-PA, U-PA2 (SO duyệt).
    Khi `POST /service-accounts` cho DU `dh-runtime`; `:rotate`.
    Và tạo tài khoản dịch vụ "dùng chung" không gắn DU.
    Thì bước 1 thành công, thông tin xác thực giao một lần; bước 2 `422` ERR-12-010; danh sách thấy đúng một chủ DU mỗi tài khoản.
