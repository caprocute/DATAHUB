# language: vi
# Sinh tự động từ D05-02-PH09 bằng ph09/tools/gen_gherkin.py; không sửa tay.
@PH-09 @TS-09-36
Tính năng: TS-09-36 · Phân quyền theo ma trận PERM-09 và bốn mắt

  @TC-09-124 @P1 @Âm @Bảo @mật
  Kịch bản: TC-09-124 Quét ma trận 16 quyền trên 11 vai, kể cả quyền theo tổ chức
    # Truy vết: FR-09-004, 009, 015, 029, 045, 058, 061, 064 · API-09-015, 033, 059, 102, 165, 203, 215, 225 · ERR-09-008 · PERM-09-classify, PERM-09-ropa, PERM-09-purpose-request, PERM-09-unmask, PERM-09-dsr, PERM-09-breach, PERM-09-audit-read, PERM-09-config
    # Mục đích: Chứng minh ● được, — bị `403`, ○ chỉ với đối tượng thuộc tổ chức mình.
    Biết ma trận FRS 3.2; mỗi vai của T90 một người dùng (PA, TA, TO, SO, DS, DA, DO, OR, SV, VW, AU).
    Khi mỗi vai gọi một API đại diện của từng quyền.
    Và với ○ (DS, DO, OR, SV) gọi trên đối tượng của tổ chức mình và tổ chức khác.
    Thì Ô ● `2xx`; ô — ERR-00-403; ô ○ đối tượng khác tổ chức `403` ERR-09-008. Hai vai DS và DA không đồng thời giữ quyền trong cùng tenant.

  @TC-09-125 @P1 @Âm @Bảo @mật
  Kịch bản: TC-09-125 Quét mọi thao tác bốn mắt: người đề nghị hay soạn không duyệt dù đủ quyền
    # Truy vết: FR-09-004, 010, 016, 026, 033, 034, 035, 040, 043, 052, 056 · API-09-016, 037, 065, 097, 122, 129, 150, 161, 186, 197 · ERR-09-005 · BR-09-003, 014
    # Mục đích: Chứng minh ADR-046 áp cho 11 thao tác (hạ mức, gỡ nhãn, hoạt động, chính sách che, lịch lưu giữ, cấu hình ẩn danh, mẫu đồng ý, DPIA, khóa, xóa mật mã, chấp thuận).
    Biết U-T90-TA có cả `PERM-09-policy` và `PERM-09-policy-approve`; DA1; SO.
    Khi với từng thao tác, người soạn hoặc đề nghị gọi duyệt trên đối tượng của mình.
    Và người thứ hai khác gọi duyệt.
    Thì bước 1 `403` ERR-09-005 ở cả 11 thao tác, kể cả TA có đủ hai quyền. Bước 2 thành công, KT: có ghi cả hai người.

  @TC-09-126 @P1 @Âm @Bảo @mật
  Kịch bản: TC-09-126 Scope `privacy:*` đúng API, token người dùng không gọi data plane, token máy không gọi control plane
    # Truy vết: FR-09-019, 027, 028, 032, 054 · API-09-227, 229, 230, 234 · ERR-09-111 · PERM-09-config
    # Mục đích: Chứng minh scope tối thiểu cho từng tài khoản máy.
    Biết T90; S-T90-PEP-04 (`privacy:decide`), S-T90-APPLY-04, S-T90-PSEUDO, S-T90-CONSENT; U-T90-SO.
    Khi mỗi tài khoản gọi API của scope khác.
    Và U-T90-SO gọi `purpose:decide`.
    Và S-T90-PEP-04 gọi `PUT /settings`.
    Thì bước 1 `403` ERR-09-111. Bước 2 `403` ERR-09-111. Bước 3 ERR-00-403.

  @TC-09-127 @P1 @Âm
  Kịch bản: TC-09-127 Thiếu token, thiếu `If-Match`, ETag cũ, gọi lặp `Idempotency-Key`
    # Truy vết: FR-09-064, 045 · API-09-225, 165 · ERR-09-004 · BR-09-061
    # Mục đích: Chứng minh lỗi nền ERR-00-401, 428 và cạnh tranh ghi ERR-09-004.
    Biết T90; U-T90-TA; `ETag` cũ của `/settings`.
    Khi `PUT /settings` không token.
    Và `PUT /settings` thiếu `If-Match`.
    Và `PUT /settings` với `ETag` đã cũ.
    Và `POST /subject-requests` hai lần cùng `Idempotency-Key`.
    Thì bước 1 `401` ERR-00-401. Bước 2 `428` ERR-00-428. Bước 3 `409` ERR-09-004 "Dữ liệu đã được người khác thay đổi. Tải lại để xem bản mới." Bước 4 một yêu cầu duy nhất.
