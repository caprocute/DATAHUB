# language: vi
# Sinh tự động từ D05-02-PH13 bằng ph13/tools/gen_gherkin.py; không sửa tay.
@PH-13 @TS-13-24
Tính năng: TS-13-24 · Luật cảnh báo, runbook và bộ luật chuẩn

  @TC-13-068 @P1 @Dương
  Kịch bản: TC-13-068 Tạo luật kèm runbook, chạy thử trên 24 giờ, bật
    # Truy vết: FR-13-042 · UC-13-26 · API-13-036, 039, 042, 043 · UI-13-11 · BR-13-008, 009 · EVT-13-10
    Biết U-T68-TA; dữ liệu 24 giờ.
    Khi tạo runbook `rb-api-loi` đủ năm mục; tạo luật `luat-api-5xx` mức Nghiêm trọng có mô tả triệu chứng.
    Và `POST /alert-rules/luat-api-5xx:test`.
    Thì `201`; kết quả thử nêu số lần sẽ phát trong 24 giờ; EVT: `rule.changed`; KT: có (`OBS.RULE.CREATE`); hiệu lực ≤ 60 giây.

  @TC-13-123 @P1 @Dương
  Kịch bản: TC-13-123 Tenant mới có sẵn bộ luật chuẩn với runbook đủ năm mục
    # Truy vết: FR-13-042, 043 · UC-13-27 · API-13-035, 037, 042 · UI-13-11 · BR-13-008, 032 · NFR-13-028
    Biết F-RULE-STD; T90 vừa khởi tạo; U-PA phát hành bản mới.
    Khi liệt kê luật và runbook ở T90.
    Và U-PA phát hành bản luật chuẩn mới; đọc lại ở T68 sau 60 giây.
    Thì mọi luật chuẩn có runbook đủ năm mục; bản mới tới T68 ≤ 60 giây, EVT: `rule.changed`; luật nhân bản của tenant không bị đè.

  @TC-13-069 @P1 @Âm
  Kịch bản: TC-13-069 Luật thiếu runbook, biểu thức sai, mã trùng
    # Truy vết: FR-13-042 · API-13-036, 038, 043, 044 · ERR-13-017, 018, 002, 007, 037, 008 · BR-13-008, 009
    Biết U-T68-TA.
    Khi luật không runbook; runbook thiếu mục "khi nào báo cấp trên".
    Và biểu thức dùng nhãn `trace_id`.
    Và tạo luật trùng mã `luat-cpu-cao`; sửa với `If-Match` cũ; tắt không lý do.
    Thì ERR-13-017; ERR-13-018 (nêu "nhãn `trace_id` không được dùng làm nhãn chỉ số"); ERR-13-002; ERR-13-007; ERR-13-008. Luật Nghiêm trọng chỉ dựa trên mức dùng CPU bị từ chối (BR-13-009).

  @TC-13-070 @P1 @Âm @Bảo @mật
  Kịch bản: TC-13-070 Luật chuẩn nền tảng không sửa, không tắt, chỉ nhân bản
    # Truy vết: FR-13-042, 043 · API-13-035, 037, 038, 040, 041 · ERR-13-019 · BR-13-032
    Biết F-RULE-STD; U-T68-TA; U-PA.
    Khi U-T68-TA liệt kê luật; sửa, tắt một luật chuẩn; nhân bản thành luật riêng.
    Và U-PA sửa luật chuẩn ở PLATFORM.
    Thì sửa, tắt: `403` ERR-13-019; nhân bản được; U-PA sửa được, EVT: `rule.changed` tới mọi tenant.

  @TC-13-071 @P1 @Âm @Bảo @mật
  Kịch bản: TC-13-071 Luật của hai tenant trùng mã không lẫn
    # Truy vết: FR-13-042 · API-13-037, 038 · ERR-13-001 · BR-13-031
    Biết `luat-cpu-cao` ở T68 và T01 khác ngưỡng; U-T68-TA.
    Khi đọc và sửa `luat-cpu-cao`; so với T01.
    Thì chỉ thấy, sửa ngưỡng của T68; T01 không đổi.
