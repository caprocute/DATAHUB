# language: vi
# Sinh tự động từ D05-02-PH09 bằng ph09/tools/gen_gherkin.py; không sửa tay.
@PH-09 @TS-09-12
Tính năng: TS-09-12 · Bundle OPA ký và phát hành

  @TC-09-039 @P1 @Dương
  Kịch bản: TC-09-039 Đổi chấp thuận kích hoạt dựng, ký và phát hành bundle
    # Truy vết: FR-09-018 · API-09-074, 075, 078, 233 · BR-09-018 · EVT-09-11 · NFR-09-005
    # Mục đích: Chứng minh bundle ký bằng khóa transit không xuất được, có `validUntil` = phát hành + 60 phút và mọi OPA nạp.
    Biết T90; 3 OPA của PH-12 giả lập đăng ký đẩy; `09.bundle.debounce-seconds = 10`, `valid-minutes = 60`.
    Khi phê duyệt chấp thuận mới.
    Và sau 10 giây `GET /policy-bundles` và `GET /policy-bundles/{id}`.
    Và `GET /policy-bundles:sync-status`; `GET /privacy/v1/bundles/current` kèm `If-None-Match`.
    Thì bước 2 bundle mới `PUBLISHED`, kết quả kiểm thử golden đạt, chữ ký hợp lệ, `validUntil` cách `issuedAt` 60 phút, kích thước ≤ 5 MB. EVT: `bundle.published`. Bước 3 cả 3 OPA có `bundle_loaded`, độ trễ ≤ 60 giây; lần gọi lại cùng `ETag` trả `304`.

  @TC-09-040 @P1 @Âm
  Kịch bản: TC-09-040 OpenBao ngừng, bộ ca chuẩn không đạt, quay lại bản trước
    # Truy vết: FR-09-018 · API-09-076, 077 · ERR-09-032, 033 · BR-09-018
    # Mục đích: Chứng minh không phát hành bundle chưa ký hoặc không qua kiểm thử, bản cũ vẫn hiệu lực.
    Biết T94; U-T90-DA1; Rego lỗi cố ý làm 1 trong 300 ca golden sai.
    Khi ngừng OpenBao rồi `POST /policy-bundles:publish`.
    Và bật lại; phát hành bundle có ca golden sai.
    Và DA1 `POST /policy-bundles/{prev}:rollback`.
    Thì bước 1 `503` ERR-09-032, bundle cũ vẫn hiệu lực. Bước 2 `422` ERR-09-033 nêu ca sai, không phát hành. Bước 3 `200`, EVT: `bundle.published` cho bản được quay lại, KT: có (bundle-rollback).

  @TC-09-041 @P1 @Âm @Bảo @mật
  Kịch bản: TC-09-041 OPA từ chối bundle sai chữ ký và quá `validUntil`
    # Truy vết: FR-09-018 · BR-09-018 · NFR-09-007 · API-09-233
    # Mục đích: Chứng minh OPA không nạp bundle bị sửa và từ chối hợp đồng `SENSITIVE` khi bundle quá hạn.
    Biết T90; bundle đã phát hành; OPA thử.
    Khi sửa 1 byte của bundle rồi cho OPA nạp.
    Và ngừng PH-09 qua `validUntil`; gọi quyết định cho API-HGD `SENSITIVE`.
    Thì bước 1 OPA từ chối, giữ bundle cũ, chỉ số `bundle_load_failed` tăng. Bước 2 quyết định `deny` cho `SENSITIVE`; hợp đồng `INTERNAL` vẫn được phục vụ theo bản chụp.

  @TC-09-042 @P1 @Dương
  Kịch bản: TC-09-042 Tương đương Rego và PH-09 trên 300 ca chuẩn
    # Truy vết: FR-09-018, 019, 027 · NFR-09-008 · API-09-227, 228
    # Mục đích: Chứng minh OPA và PH-09 cho kết quả trùng nhau 100 %.
    Biết T90; golden set 300 ca quyết định và kế hoạch che (Q09-42).
    Khi chạy bộ golden qua OPA và qua `purpose:decide`, `mask-plans:resolve`.
    Thì 300/300 ca trùng quyết định, mức che và điều kiện; ca lệch làm CI đỏ.
