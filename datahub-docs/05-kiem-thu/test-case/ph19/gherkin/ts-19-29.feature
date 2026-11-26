# language: vi
# Sinh tự động từ D05-02-PH19 bằng ph19/tools/gen_gherkin.py; không sửa tay.
@PH-19 @TS-19-29
Tính năng: TS-19-29 · Di trú và chạy song song

  @TC-19-701 @P1 @Dương
  Kịch bản: TC-19-701 Nhập năm bảng hệ cũ
    # Truy vết: FR-19-065 · API-19-089, 090 · UI-19-27
    Biết U-PLA1; F-LEG-CSV (năm bảng: NCC, dịch vụ, đối tác, giao dịch, nhật ký; 10.000 giao dịch).
    Khi chạy lô `IMPORT` từ UI-19-27.
    Và mở kết quả.
    Thì bước 1 trả `202`; lần chạy `SUCCEEDED`. Bước 2: số bản ghi nhập bằng số dòng nguồn trừ dòng lỗi; giao dịch nhập có `origin = LEGACY`, mã hệ cũ trong `legacyRef`, không phát webhook, không sinh sự kiện kết quả; trạng thái hệ cũ được ánh xạ theo bảng của FR-19-065.

  @TC-19-702 @P1 @Âm
  Kịch bản: TC-19-702 Chạy lại lô không trùng
    # Truy vết: FR-19-065 · API-19-089
    Biết lô của TC-19-701 đã chạy.
    Khi chạy lại cùng lô (cùng `Idempotency-Key`).
    Và chạy lô mới cùng tệp, khóa khác.
    Thì bước 1 trả lại kết quả lần trước. Bước 2: 0 bản ghi mới, 10.000 "đã có" (khóa tự nhiên `legacyRef`).

  @TC-19-703 @P1 @Âm
  Kịch bản: TC-19-703 Dữ liệu hệ cũ bất thường
    # Truy vết: FR-19-065 · NFR-19-017
    Biết F-LEG-CSV có các dòng: số tiền 2.500.000.000 (vượt `int` 32 bit của hệ cũ); `pay_date` dạng `20261301` và `31/02/2026`; trạng thái mã lạ `9`; số tiền âm.
    Khi chạy lô.
    Thì số tiền 2,5 tỷ nhập đúng (`numeric(19,0)`). Các dòng sai ngày, trạng thái lạ, số âm vào báo cáo lỗi, có số dòng và lý do; các dòng còn lại vẫn nhập; báo cáo lỗi tải được qua API-19-090.

  @TC-19-704 @P1 @Dương
  Kịch bản: TC-19-704 Chuyển LEGACY → SHADOW → DATAHUB có phê duyệt
    # Truy vết: FR-19-066, 068 · BR-19-034 · API-19-047, 050 · UI-19-12, 13
    Biết P-LEG ở `LEGACY`; U-PLA1 lập, U-APR1 duyệt.
    Khi đề nghị `SHADOW`; duyệt.
    Và hệ cũ xử lý một giao dịch của P-LEG; bộ ghi song song gửi bản sao.
    Và sau 7 ngày `SHADOW` liên tiếp có đối chiếu FR-19-068 đạt 0 bản ghi lệch chưa giải thích, đề nghị `DATAHUB`; duyệt.
    Và C-LEG gọi `P: POST /payments`.
    Thì bước 1: chế độ `SHADOW`. Bước 2: Datahub ghi nhận bản sao `is_shadow = true`, không gọi NCC, không webhook; có trong báo cáo so sánh, không vào hạn mức, báo cáo, đối soát. Bước 3: `DATAHUB`. Bước 4 trả `201`.

  @TC-19-705 @P1 @Âm
  Kịch bản: TC-19-705 Gọi API khi còn ở LEGACY, tự duyệt chuyển chế độ
    # Truy vết: FR-19-066 · BR-19-034 · API-19-101, 047, 050 · ERR-19-006, 033, 035
    Biết P-LEG ở `LEGACY`; U-AA1 có `migration-switch` và `migration-approve` qua vai trò thử.
    Khi C-LEG gọi `P: POST /payments`.
    Và U-AA1 đề nghị rồi tự duyệt.
    Và đề nghị `DATAHUB` cho đối tác mới ở `SHADOW` 3 ngày.
    Thì bước 1 trả `409` ERR-19-006. Bước 2 trả `403` ERR-19-033. Bước 3 trả `422` ERR-19-035, `detail` nêu "chưa đủ 7 ngày SHADOW".

  @TC-19-706 @P1 @Dương
  Kịch bản: TC-19-706 Quay lui DATAHUB → LEGACY
    # Truy vết: FR-19-066
    Biết P-LEG ở `DATAHUB`, có 3 giao dịch `PENDING`.
    Khi đề nghị và duyệt quay về `LEGACY`.
    Và `PGSIM` gửi IPN cho 3 giao dịch.
    Thì bước 1: giao dịch mới của P-LEG đi hệ cũ. Bước 2: 3 giao dịch vẫn được Datahub xử lý tới trạng thái cuối và gửi webhook (không bỏ dở giao dịch đang chạy).

  @TC-19-707 @P2 @Dương
  Kịch bản: TC-19-707 Đối chiếu sau di trú phát hiện lệch
    # Truy vết: FR-19-068 · API-19-089, 090 · UI-19-27
    Biết sau TC-19-701; sửa tay 2 bản ghi hệ cũ (đổi số tiền, đổi trạng thái).
    Khi chạy lô `COMPARE` cho tháng đó.
    Thì số lượng, tổng tiền, phân bố trạng thái theo tháng và theo đối tác; liệt kê đúng 2 bản ghi lệch với giá trị hai phía.

  @TC-19-709 @P2 @Âm
  Kịch bản: TC-19-709 Đối chiếu sau di trú: kỳ không hợp lệ, không có quyền, chạy trùng
    # Truy vết: FR-19-068 · API-19-089 · ERR-19-001, 021, 046
    Biết U-PLA1; U-OPR1; một lô `COMPARE` đang chạy cho tháng 10.
    Khi `COMPARE` cho tháng tương lai.
    Và `COMPARE` tháng 10 lần nữa khi lô trước chưa xong.
    Và U-OPR1 tạo lô.
    Thì bước 1 trả `400` ERR-19-001. Bước 2 trả `409` ERR-19-021. Bước 3: 403-PQ.

  @TC-19-708 @P3 @Dương
  Kịch bản: TC-19-708 Lớp tương thích API hệ cũ
    # Truy vết: FR-19-067 · API-19-110
    Biết chỉ chạy khi OQ-19-17 xác nhận cần; cờ `payment.legacy-compat` bật.
    Khi gọi `P: POST /legacy-compat/createPayment` theo hợp đồng hệ cũ.
    Thì trả theo định dạng hệ cũ, có header `Deprecation` và `Sunset`; giao dịch tạo qua API-19-101. Phát hành "Sau".
