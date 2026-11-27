# language: vi
# Sinh tự động từ D05-02-PH13 bằng ph13/tools/gen_gherkin.py; không sửa tay.
@PH-13 @TS-13-08
Tính năng: TS-13-08 · Xử lý đứt chuỗi và neo không khớp

  @TC-13-027 @P1 @Âm @Bảo @mật
  Kịch bản: TC-13-027 Sửa trực tiếp một bản ghi đã neo bị phát hiện
    # Truy vết: FR-13-014, 015 · UC-13-08 · BR-13-012, 033 · ERR-13-109 · EVT-13-05 · API-13-079 · UI-13-14 · NFR-13-016
    Biết F-AUD-CUT; U-T68-SO, U-T68-TA nhận thông báo.
    Khi chạy kiểm tra gia tăng khi neo.
    Và `GET /verifications/{id}`; mở UI-13-14.
    Thì kết quả `BROKEN` nêu `seq` đầu tiên sai; ≤ 1 giờ phát hiện; ERR-13-109; cảnh báo Nghiêm trọng gửi SO và TA ngay; EVT: `audit.chain-broken`; không có nút sửa; chuỗi giữ nguyên.

  @TC-13-028 @P1 @Âm @Bảo @mật
  Kịch bản: TC-13-028 Neo không khớp bản WORM hoặc SIEM
    # Truy vết: FR-13-015 · UC-13-08 · ERR-13-110 · BR-13-012, 013 · EVT-13-05
    Biết F-AUD-1K; sửa bản neo ở bảng neo (tài khoản DBA thử).
    Khi chạy kiểm tra toàn vẹn.
    Thì so ba nơi thấy lệch; ERR-13-110 Nghiêm trọng; nêu nơi nào lệch; EVT: `chain-broken`; không tự ghi đè.

  @TC-13-029 @P2 @Dương
  Kịch bản: TC-13-029 Chuỗi nguyên vẹn không sinh cảnh báo giả
    # Truy vết: FR-13-015 · UC-13-08 · BR-13-012 · ERR-13-109
    Biết F-AUD-1K, qua 7 ngày kiểm tra hằng ngày.
    Khi chạy kiểm tra liên tiếp 7 lần với ghi liên tục.
    Thì 7 lần `PASSED`; 0 cảnh báo đứt chuỗi; 0 EVT `chain-broken`.

  @TC-13-127 @P2 @Dương @Bảo @mật
  Kịch bản: TC-13-127 Khôi phục chuỗi sau sự cố: nạp lại nguyên văn từ WORM, xác minh đạt, biên bản ký
    # Truy vết: FR-13-062 · UC-13-43 · BR-13-002, 033 · FR-13-011, 012, 013, 014 · ERR-13-109
    Biết F-AUD-LAG (chuỗi T68 khôi phục PITR về trước 4 phút so với lô WORM mới nhất, WORM đủ bản ghi); `ingest` chưa mở; U-OPS chạy `AuditRestore`; U-T68-SO, U-T68-TA đã ký biên bản mở và cửa sổ bảo trì.
    Khi so `head_seq`, `head_hash` của T68 với lô WORM mới nhất và neo gần nhất.
    Và chạy `AuditRestore`; sau đó mở lại `ingest` và để DU giả lập gửi lại bản ghi chưa lên WORM (có bản trùng `id`).
    Và chạy xác minh `ON_DEMAND` toàn chuỗi; đọc chuỗi `PLATFORM`.
    Và SO và TA ký biên bản; U-OPS lưu ở `dh-evidence`.
    Và tìm API, màn hình hay quyền `PERM-13-*` cho thao tác khôi phục.
    Thì bước 1: bảng đứng sau WORM khoảng 4 phút. Bước 2: bản ghi được chèn nguyên văn (giữ `seq`, `recorded_at`, `prev_hash`, `hash`) theo thứ tự, không bản ghi nào bị sửa hay dựng mới; bản trùng `id` bị bỏ qua (ERR-13-102), bản còn lại nhận `seq` nối tiếp. Bước 3: kết quả `PASSED` toàn chuỗi; có `AUDIT.CHAIN.RESTORE` (lý do, số tenant, khoảng `seq` nạp lại) ở chuỗi `PLATFORM` và ở SIEM. Bước 4: biên bản có chữ ký của cả SO và TA, lưu ở `dh-evidence`. Bước 5: không có API, màn hình hay quyền nào cho thao tác này (không đường nào sửa, nối lại hay dựng lại chuỗi). KT: có.

  @TC-13-128 @P3 @Dương @Biên
  Kịch bản: TC-13-128 Khôi phục chuỗi: bảng không đứng sau WORM, và nhiều tenant mất dữ liệu
    # Truy vết: FR-13-062 · UC-13-43 · BR-13-033
    Biết hai tình huống: (a) F-AUD-1K của T68 còn nguyên so với WORM; (b) T68, T01 cùng mất dữ liệu (F-AUD-LAG cho cả hai); chữ ký SO và TA đủ.
    Khi tình huống (a): chạy thủ tục.
    Và tình huống (b): chạy lần lượt T68 rồi T01; theo dõi thời điểm mở `ingest` của từng tenant.
    Thì tình huống (a): bỏ bước nạp lại, không chèn bản ghi nào, chỉ xác minh `PASSED` và lập biên bản. Tình huống (b): mỗi tenant được xác minh đạt rồi mới mở `ingest` cho tenant đó; `AUDIT.CHAIN.RESTORE` ghi số tenant và khoảng `seq` của từng tenant.

  @TC-13-129 @P2 @Âm @Bảo @mật
  Kịch bản: TC-13-129 Khôi phục chuỗi: băm WORM không khớp neo hoặc trigger từ chối thì dừng
    # Truy vết: FR-13-062 · UC-13-43 · BR-13-002, 033 · FR-13-015 · ERR-13-109, 110
    Biết F-AUD-LAG; một lô WORM thử bị đổi một bản ghi (băm không khớp neo); biến thể khác: bản ghi cần chèn không liền kề (thiếu một `seq`); biên bản đã ký.
    Khi chạy `AuditRestore` với lô bị đổi.
    Và chạy với lô thiếu một `seq` giữa chừng.
    Và thử chèn thủ công một bản ghi bằng tài khoản DBA thử để vượt `tg_audit_chain_guard`.
    Thì bước 1: dừng ngay, không chèn thêm bản ghi nào; xử lý như đứt chuỗi theo FR-13-015: ERR-13-109 hoặc ERR-13-110 mức Nghiêm trọng, cảnh báo SO và TA, EVT `audit.chain-broken`. Bước 2: `tg_audit_chain_guard` từ chối bản ghi không liền kề, thủ tục dừng. Bước 3: bị từ chối, không có đường vượt qua trigger; chuỗi giữ nguyên.

  @TC-13-130 @P2 @Âm @Bảo @mật
  Kịch bản: TC-13-130 Khôi phục chuỗi: thiếu chữ ký SO hoặc TA thì không chạy
    # Truy vết: FR-13-062 · UC-13-43 · BR-13-033
    Biết F-AUD-LAG; biên bản mở và cửa sổ bảo trì: biến thể 1 chỉ SO ký, biến thể 2 chỉ TA ký, biến thể 3 chưa ai ký.
    Khi U-OPS yêu cầu mở cửa sổ bảo trì và chạy `AuditRestore` với từng biến thể.
    Thì cả ba biến thể: không mở cửa sổ bảo trì, không chạy `AuditRestore`, `ingest` vẫn đóng, chuỗi không đổi; yêu cầu bị ghi nhận có lý do. Chỉ khi cả SO và TA cùng ký mới chạy được.

  @TC-13-131 @P2 @Âm
  Kịch bản: TC-13-131 Khôi phục chuỗi: xác minh toàn chuỗi không đạt sau khi nạp
    # Truy vết: FR-13-062 · UC-13-43 · FR-13-014, 015 · ERR-13-109
    Biết F-AUD-LAG; một bản ghi trong khoảng đã nạp có băm sai mà vẫn liền kề (dựng bằng DBA thử ở SIT); biên bản đã ký.
    Khi chạy `AuditRestore`, rồi xác minh `ON_DEMAND` toàn chuỗi.
    Thì xác minh `BROKEN`, nêu `seq` đầu tiên sai; chuỗi giữ trạng thái đứt, không mở `ingest` cho tenant, mở sự cố theo FR-13-015 (ERR-13-109); không ghi `AUDIT.CHAIN.RESTORE` loại thành công.
