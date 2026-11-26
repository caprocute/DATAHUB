# language: vi
# Sinh tự động từ D05-02-PH13 bằng ph13/tools/gen_gherkin.py; không sửa tay.
@PH-13 @TS-13-01
Tính năng: TS-13-01 · Thu thập chỉ số, log, trace và lấy mẫu

  @TC-13-001 @P1 @Dương
  Kịch bản: TC-13-001 Thu chỉ số, log, trace từ DU giả lập có nhãn tenant
    # Truy vết: FR-13-001, 002, 003, 009 · UC-13-01 · NFR-13-027 · BR-13-027 · LGC-BUS-030 · LGC-NFR-004
    Biết F-DU-SIM ba DU; T68.
    Khi F-DU-SIM phát 100 mẫu chỉ số, 100 dòng log JSON, 20 span có `traceparent`.
    Và truy vấn Mimir, Loki, Tempo bằng nhãn `tenant="t68"` sau 60 giây.
    Thì cả ba nguồn có đủ dữ liệu; mọi dòng log là JSON có `trace_id`, `tenant`, `du`, `level`; nhãn `tenant` do hệ thống gắn từ chứng thư, không lấy từ nội dung do DU gửi (BR-13-027).

  @TC-13-002 @P1 @Âm @Bảo @mật
  Kịch bản: TC-13-002 Thiếu nhãn tenant, nhãn ngoài danh sách, nhãn cardinality cao
    # Truy vết: FR-13-001, 009 · BR-13-026, 027 · ERR-13-113, 114 · NFR-13-020
    Biết F-DU-SIM phát sai.
    Khi phát mẫu không có nhãn tenant.
    Và phát mẫu có nhãn `trace_id`, `user_id`, `client_ip` và một nhãn lạ.
    Và phát mẫu với nhãn `tenant="t01"` từ DU của T68.
    Thì bước 1: mẫu gán `_unattributed`, chỉ U-PA thấy; ERR-13-113 trên chỉ số bộ thu. Bước 2: nhãn bị bỏ, mẫu vẫn vào; ERR-13-114. Bước 3: nhãn bị ghi đè bằng `t68`; T01 không thấy mẫu nào.

  @TC-13-121 @P2 @Âm
  Kịch bản: TC-13-121 Log sai định dạng, span thiếu `traceparent`, trace chưa đủ quyết định lấy mẫu
    # Truy vết: FR-13-002, 003, 004 · BR-13-010, 011 · ERR-13-116, 117 · NFR-13-027
    Biết F-DU-SIM phát sai.
    Khi phát dòng log không phải JSON và dòng thiếu `trace_id`.
    Và phát span không có `traceparent`.
    Và phát trace nhưng bỏ span cuối, chờ quá thời gian quyết định.
    Thì dòng sai được bọc thành log JSON mức `WARN` kèm nguồn, không bị bỏ; span thiếu `traceparent` tạo trace mới có cờ; trace thiếu span: ERR-13-117, vẫn giữ nếu lỗi; DU nguồn bị đưa vào danh sách thiếu đo lường (NFR-13-027).

  @TC-13-003 @P2 @Biên
  Kịch bản: TC-13-003 Giới hạn số chuỗi hoạt động của tenant
    # Truy vết: FR-13-001 · NFR-13-020 · BR-13-026 · ERR-13-114 · EVT-13-14
    Biết `13.series.max-active = 1.000` ở T68 (giảm cho ca).
    Khi phát 850 chuỗi riêng biệt, rồi 1.001 chuỗi.
    Thì đạt 85 %: EVT: `capacity.warning`. Quá 1.000: chuỗi mới bị bỏ, chuỗi cũ vẫn ghi; ERR-13-114; cảnh báo hiển thị ở UI-13-01.

  @TC-13-004 @P1 @Dương
  Kịch bản: TC-13-004 Lấy mẫu trace theo đuôi giữ trace lỗi, chậm, nhạy cảm
    # Truy vết: FR-13-003, 004 · BR-13-010 · NFR-13-003 · ERR-13-116, 117
    Biết F-TRACE-MIX; `13.trace.success-sample-percent = 10`.
    Khi phát F-TRACE-MIX và chờ quá `13.trace.decision-wait-seconds`.
    Và đếm trace trong Tempo theo nhóm.
    Và phát một trace có 3.000 span và một trace thiếu span cha.
    Thì giữ đủ 10 trace lỗi, 5 chậm, 5 nhạy cảm; trong 80 trace bình thường giữ 6…10. Trace 3.000 span bị cắt, ERR-13-116; trace thiếu span: ERR-13-117, vẫn lưu.

  @TC-13-005 @P2 @Biên
  Kịch bản: TC-13-005 Bộ thu quá tải đệm và bỏ dữ liệu ít quan trọng
    # Truy vết: FR-13-001, 002 · ERR-13-115 · NFR-13-007, 013 · BR-13-015
    Biết một bản sao collector; F-DU-SIM phát gấp 3 lần ngưỡng.
    Khi phát tải cao 10 phút.
    Thì collector đệm; bỏ log mức `DEBUG`, `INFO` trước; giữ `ERROR` và bản ghi kiểm toán; ERR-13-115 hiện ở UI-13-01; DU nguồn không lỗi, không chậm.
