# language: vi
# Sinh tự động từ D05-02-PH19 bằng ph19/tools/gen_gherkin.py; không sửa tay.
@PH-19 @TS-19-09
Tính năng: TS-19-09 · Đăng ký và phê duyệt đối tác

  @TC-19-201 @P1 @Dương
  Kịch bản: TC-19-201 Đăng ký đối tác Nháp
    # Truy vết: FR-19-017 · API-19-030, 031 · UI-19-11, 12 · LGC-PAY-022
    Biết U-ADM1.
    Khi trên UI-19-11 bấm "Đăng ký đối tác", nhập mã `P-YT`, tên, cơ quan chủ quản, một địa chỉ quay về `https://yt.t68.test/ket-qua`, đầu mối kỹ thuật; lưu.
    Thì `POST /partners` trả `201`, `status = DRAFT`, `routingMode = DATAHUB` (mặc định cho đối tác mới, không có ở hệ cũ); `disabledReasons.SUBMIT_ONBOARD` nêu "chưa gắn HTTT thành viên", "chưa gán dịch vụ". KT: có.

  @TC-19-207 @P1 @Âm
  Kịch bản: TC-19-207 Hồ sơ đối tác sai, trùng mã, sửa khi đã chấm dứt
    # Truy vết: FR-19-017 · API-19-030, 032 · ERR-19-038, 039, 016, 021, 045
    Biết U-ADM1; P-DVC đã có; một đối tác `TERMINATED`.
    Khi tạo đối tác mã `P-DVC`.
    Và tạo với `agencyCode` không có trong danh mục PH-07.
    Và tạo với địa chỉ quay về `http://yt.t68.test` (không `https`).
    Và sửa đối tác `TERMINATED`.
    Và sửa P-DVC với `If-Match` cũ.
    Thì bước 1 trả `409` ERR-19-038. Bước 2 trả `422` ERR-19-039. Bước 3 trả `422` ERR-19-016. Bước 4 trả `409` ERR-19-021. Bước 5 trả `412` ERR-19-045.

  @TC-19-202 @P1 @Dương
  Kịch bản: TC-19-202 Gửi duyệt và duyệt đối tác
    # Truy vết: FR-19-018 · BR-19-011 · API-19-033, 050 · UI-19-12, 13
    Biết `P-YT` đã gắn HTTT `HT-0099` và gán S-HT; U-ADM1, U-APR1.
    Khi U-ADM1 bấm "Gửi duyệt".
    Và U-APR1 duyệt ở UI-19-13.
    Thì bước 1: `status = PENDING_APPROVAL`, đề nghị `PARTNER_ONBOARD`. Bước 2: `status = ACTIVE`. EVT: `partner.activated`.

  @TC-19-203 @P1 @Âm
  Kịch bản: TC-19-203 Gửi duyệt khi thiếu điều kiện, người lập tự duyệt
    # Truy vết: FR-19-018 · BR-19-011 · API-19-033, 050 · ERR-19-021, 033
    Biết P-NEW (thiếu HTTT, chưa gán dịch vụ); U-AA1 lập đề nghị cho bản sao đủ điều kiện.
    Khi gửi duyệt P-NEW.
    Và U-AA1 duyệt đề nghị mình lập.
    Thì bước 1 trả `409` ERR-19-021 với hai mục thiếu. Bước 2 trả `403` ERR-19-033.

  @TC-19-204 @P1 @Dương
  Kịch bản: TC-19-204 Tạm dừng đối tác: chặn tạo mới, vẫn truy vấn và nhận webhook
    # Truy vết: FR-19-018 · API-19-034, 035, 101, 102 · ERR-19-005
    Biết U-ADM1; bản sao P-DVC tên P-DVC2 có TX-PEND3 `PENDING`; C-DVC2.
    Khi tạm dừng P-DVC2 có lý do.
    Và C-DVC2 `P: POST /payments`.
    Và C-DVC2 `P: GET /payments/{TX-PEND3}`.
    Và `PGSIM` gửi IPN thành công cho TX-PEND3.
    Và mở lại P-DVC2.
    Thì bước 2 trả `403` ERR-19-005. Bước 3 trả `200`. Bước 4: ST: `PENDING` → `SUCCEEDED`; WH: `transaction.succeeded` vẫn gửi tới P-DVC2. Bước 5: `ACTIVE`, tạo giao dịch được. KT: có cho bước 1, 5.

  @TC-19-205 @P2 @Âm
  Kịch bản: TC-19-205 Tạm dừng, mở lại sai trạng thái và thiếu quyền
    # Truy vết: FR-19-018 · API-19-034, 035 · ERR-19-021, 046, 001
    Biết P-NEW `DRAFT`; P-SUS; U-OPR1.
    Khi tạm dừng P-NEW.
    Và mở lại P-SUS không có lý do.
    Và U-OPR1 tạm dừng P-DVC.
    Thì bước 1 trả `409` ERR-19-021. Bước 2 trả `400` ERR-19-001. Bước 3 trả 403-PQ.

  @TC-19-206 @P1 @Dương
  Kịch bản: TC-19-206 Chấm dứt đối tác thu hồi mọi client
    # Truy vết: FR-19-018, 019 · BR-19-011 · API-19-033, 050, 036
    Biết `P-YT` `ACTIVE` có hai client; U-ADM1, U-APR1.
    Khi U-ADM1 gửi `{"action":"TERMINATE"}`.
    Và U-APR1 duyệt.
    Và client của `P-YT` xin token và gọi `P: GET /services`.
    Thì bước 2: `status = TERMINATED`; cả hai client bị thu hồi ở PH-12. Bước 3: không lấy được token mới; token cũ bị từ chối trong ≤ 60 giây. Đối tác `TERMINATED` không mở lại được (không có `RESUME` trong `allowedActions`).
