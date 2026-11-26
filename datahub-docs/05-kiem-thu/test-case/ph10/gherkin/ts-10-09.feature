# language: vi
# Sinh tự động từ D05-02-PH10 bằng ph10/tools/gen_gherkin.py; không sửa tay.
@PH-10 @TS-10-09
Tính năng: TS-10-09 · Đồng bộ trạng thái với PH-01 và PH-04

  @TC-10-042 @P1 @Dương
  Kịch bản: TC-10-042 HTTT tạm ngừng ở PH-01 rồi hoạt động lại
    # Truy vết: FR-10-029 · EVT-10-07, 09 · NFR-10-009 · LGC-HUB-010, 011
    # Mục đích: Chứng minh luồng thành công, theo FR-10-029 (Đồng bộ trạng thái với PH-01 và PH-04).
    Biết SIM-PH01; `HT-DKKD` có PB-DKKD, PB-DKKD-K; `HT-THUE` có SB-THUE (SB-THUE đã bị SO tạm ngừng trước đó với `suspendSource = SECURITY`).
    Khi SIM-PH01 phát sự kiện `HT-DKKD` sang `SUSPENDED`; đo thời gian tới khi lượt phát bị từ chối.
    Và SIM-PH01 phát `HT-DKKD` và `HT-THUE` về `ACTIVE`.
    Thì bước 1 PB-DKKD, PB-DKKD-K và publication của chúng `SUSPENDED` với `suspendSource = PH01`; API phát trả 403-PQ trong ≤ 60 giây; ACL `WRITE` bị gỡ trong ≤ 2 phút. Bước 2 chỉ đối tượng có `suspendSource = PH01` tiếp tục; SB-THUE vẫn `SUSPENDED`. EVT: `publication.state-changed`. KT: có, chủ thể `system:dh-integration`.
    # Hậu điều kiện: Đối tượng ở trạng thái nêu ở kết quả mong đợi.

  @TC-10-043 @P2 @Dương @Âm
  Kịch bản: TC-10-043 Luồng ngừng ở PH-04; sự kiện lặp và sự kiện lỡ
    # Truy vết: FR-10-029 · EVT-04-09 · EVT-10-09
    # Mục đích: Chứng minh luồng thành công và các nhánh bị chặn nêu ở tên ca, theo FR-10-029 (Đồng bộ trạng thái với PH-01 và PH-04).
    Biết SIM-PH04; SB-FLOW có SUB-FLOW `ACTIVE`; PB-FLOW có publication `ACTIVE`.
    Khi SIM-PH04 phát EVT-04-09 cho `dkkd-dong-bo-thue` hai lần cùng `id`.
    Và đổi trực tiếp trạng thái luồng `dkkd-tong-hop` ở SIM-PH04 mà không phát sự kiện; chờ bộ đối soát mỗi giờ.
    Thì bước 1 SUB-FLOW `REVOKED`, SB-FLOW `RETIRED`; lần nhận thứ hai bị inbox bỏ qua (một dòng `inbox_event`, một EVT `subscription.state-changed`). Bước 2 bộ đối soát phát hiện và thu hồi publication của PB-FLOW.
    # Hậu điều kiện: Chỉ bước thành công để lại thay đổi; bước bị từ chối không đổi dữ liệu.
