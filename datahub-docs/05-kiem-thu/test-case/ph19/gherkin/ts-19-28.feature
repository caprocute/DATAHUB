# language: vi
# Sinh tự động từ D05-02-PH19 bằng ph19/tools/gen_gherkin.py; không sửa tay.
@PH-19 @TS-19-28
Tính năng: TS-19-28 · Cấu hình và khởi tạo tenant

  @TC-19-676 @P2 @Dương
  Kịch bản: TC-19-676 Tạo phiên bản cấu hình có ngày hiệu lực
    # Truy vết: FR-19-063 · API-19-085, 086 · UI-19-26
    Biết U-TEN1; cấu hình v1 có `19.txn.ttl-minutes = 30`.
    Khi tạo v2 `ttl = 45`, hiệu lực 00:00 ngày mai.
    Và tạo giao dịch hôm nay; tiến đồng hồ qua 00:00; tạo giao dịch nữa.
    Thì bước 1 trả `201`; UI-19-26 hiện v2 "Sắp hiệu lực". Bước 2: giao dịch đầu `expiresAt` +30 phút, giao dịch sau +45 phút; mỗi giao dịch ghi `configVersion`. KT: có.

  @TC-19-677 @P2 @Âm
  Kịch bản: TC-19-677 Cấu hình ngoài khoảng, sai phiên bản
    # Truy vết: FR-19-063 · API-19-086 · ERR-19-001, 045, 046
    Biết U-TEN1; U-OPR1.
    Khi `ttl = 0`; giờ chốt đối soát `25:00`; ngày hiệu lực trong quá khứ.
    Và `If-Match` cũ.
    Và U-OPR1 tạo phiên bản.
    Thì bước 1 trả `400` ERR-19-001 chỉ đúng trường. Bước 2 trả `412` ERR-19-045. Bước 3: 403-PQ.

  @TC-19-678 @P1 @Dương
  Kịch bản: TC-19-678 Khởi tạo khi PH-20 bật phân hệ
    # Truy vết: FR-19-064 · NFR-19-025
    Biết T50 chưa bật PH-19.
    Khi phát sự kiện PH-20 `tenant.module.enabled` (PH-19, T50).
    Và phát lại sự kiện đó.
    Thì bước 1: cấu hình mặc định v1, topic `t50.payment.*`, bucket `dh-t50-payment`, `dh-t50-payment-worm`, đường dẫn OpenBao `kv/dh/t50/payment/` được tạo; API của T50 trả lời. Bước 2: không tạo trùng (xử lý một lần theo hộp nhận).

  @TC-19-679 @P1 @Âm
  Kịch bản: TC-19-679 Tenant tạm ngừng phân hệ
    # Truy vết: FR-19-064 · ERR-19-049
    Biết T50 đã bật; có một giao dịch `PENDING`.
    Khi PH-20 phát `tenant.module.suspended`.
    Và đối tác của T50 gọi `P: POST /payments`.
    Và `PGSIM` gửi IPN cho giao dịch `PENDING`.
    Thì bước 2 trả `503` ERR-19-049. Bước 3: IPN vẫn được nhận, xử lý (không bỏ tiền người nộp đã trả); giao dịch `SUCCEEDED`; webhook gửi bình thường.
