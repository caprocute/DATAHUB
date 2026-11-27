# language: vi
# Sinh tự động từ D05-02-PH14 bằng ph14/tools/gen_gherkin.py; không sửa tay.
@PH-14 @TS-14-10
Tính năng: TS-14-10 · Mục đích khai thác và ủy quyền theo mục đích

  @TC-14-028 @P1 @Dương
  Kịch bản: TC-14-028 Gọi dịch vụ DLCN đủ mục đích, mã thủ tục, mã hồ sơ
    # Truy vết: FR-14-011, 052 · API-14-075, 065 · UI-14-13 · UC-14-09 · BR-14-008, 009 · SEC-37.
    Biết S-HT-MC được cấp V-BHXH; U-T68-AU.
    Khi gọi V-BHXH `purposeCode = GIAI_QUYET_TTHC`, `procedureCode = 1.001234`, `caseCode = HS-2026-08-001234`.
    Và U-T68-AU mở UI-14-13, lọc theo HTTT và mục đích.
    Thì `200`; nhật ký khai thác có HTTT, người dùng cuối nếu có, mục đích, mã thủ tục, mã hồ sơ, dịch vụ, thời điểm; không có giá trị DLCN trong nhật ký.

  @TC-14-029 @P1 @Âm @Bảo @mật
  Kịch bản: TC-14-029 Từ chối: chưa được cấp, mục đích sai, thiếu mã hồ sơ, ngoài khung giờ
    # Truy vết: FR-14-011 · API-14-075 · ERR-14-106, 107, 132 · BR-14-008 · NFR-14-024.
    Biết S-HT-KHAC; S-HT-MC; `14.purpose.allowed-hours = 07:00-18:00`, giờ giả lập 22:00.
    Khi S-HT-KHAC gọi V-BHXH.
    Và S-HT-MC gọi với `purposeCode` không thuộc danh mục.
    Và S-HT-MC gọi V-BHXH thiếu `caseCode`.
    Và chuyển giờ giả lập 22:00, gọi đúng; rồi dừng OPA và gọi lại.
    Thì bước 1, 2 `403` ERR-14-106; bước 3 `422` ERR-14-107; bước 4 lần một `403` ERR-14-106, lần hai `503` ERR-14-132 (từ chối an toàn). Không lượt nào chạm `sim-ndxp`; mỗi lượt từ chối có dòng nhật ký.

  @TC-14-158 @P1 @Dương @Âm @Bảo
  Kịch bản: TC-14-158 Dịch vụ từ Hạn chế: PH-09 trả ropaActivityId thì cho phép, vắng thì từ chối
    # Truy vết: FR-14-011 · API-14-075 · ERR-14-106, 132 · BR-14-008, 009 · SEC-37 · API-09-227
    Biết S-HT-MC được cấp V-BHXH (mục `SENSITIVE`) và V-HT (mục `NORMAL`, `purposeRequired = false`); PH-09 giả lập `purpose:decide` có công tắc: trả `ropaActivityId`, bỏ `ropaActivityId`, `down`.
    Khi S-HT-MC gọi V-BHXH với mục đích, mã thủ tục, mã hồ sơ đủ; PH-09 trả `allow` kèm `ropaActivityId`.
    Và PH-09 trả `allow` nhưng không có `ropaActivityId` (mục đích chưa nằm trong sổ hoạt động xử lý); gọi lại V-BHXH.
    Và dừng PH-09 (`down`); gọi lại V-BHXH.
    Và gọi V-HT (dịch vụ `NORMAL`).
    Thì bước 1: `200`; PH-09 nhận đúng một lần `purpose:decide` trước khi gọi `sim-ndxp`; quyết định, `ropaActivityId` ghi vào nhật ký khai thác (không có DLCN). Bước 2: `403` ERR-14-106 (mục đích chưa có trong sổ), không chạm `sim-ndxp`, lượt có trạng thái `REJECTED` và dòng nhật ký. Bước 3: `503` ERR-14-132, từ chối an toàn, không chạm `sim-ndxp`. Bước 4: `200`, PH-09 không bị hỏi (bỏ qua bước kiểm sổ hoạt động xử lý).
