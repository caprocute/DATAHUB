# language: vi
# Sinh tự động từ D05-02-PH02 bằng ph02/tools/gen_gherkin.py; không sửa tay.
@PH-02 @TS-02-22
Tính năng: TS-02-22 · Giao diện nội bộ và đối soát gateway

  @TC-02-066 @P1 @Dương @Âm @Bảo
  Kịch bản: TC-02-066 Giao diện nội bộ theo scope dịch vụ và `ETag`
    # Truy vết: FR-02-059 · API-02-080, 081, 082 · UC-02-35 · BR-02-025, 033 · ERR-02-014, 001 · EVT-02-05.
    Biết S-GW, S-PORTAL, S-FLOW; token người dùng.
    Khi S-GW `GET /internal/gateway/published-config` hai lần với `If-None-Match`.
    Và S-PORTAL gọi `/internal/gateway/published-config`; token người dùng gọi API nội bộ.
    Và S-GW đọc cấu hình T01 bằng token T68.
    Thì `200` rồi `304`, chỉ phiên bản `PUBLISHED`, gói, đăng ký `ACTIVE`; bước 2 403-PQ; bước 3 chỉ trả dữ liệu T68.

  @TC-02-067 @P2 @Dương @Âm
  Kịch bản: TC-02-067 Đối soát phát hiện route thừa, thiếu, lệch và đẩy lại
    # Truy vết: FR-02-060 · API-02-083, 084 · UI-02-17 · UC-02-36 · ERR-02-035, 014 · EVT-02-15 · NFR-02-020.
    Biết tiêm lệch ở M-GW: thiếu một route, thừa một route, sai trọng số; `02.reconcile.auto-repair` = false (Đợt 2).
    Khi chờ chu kỳ 5 phút; `GET /gateway-reconciliations/latest`.
    Và `POST /gateway-reconciliations` lần hai khi lần một chạy; U-T68-TO đẩy lại.
    Thì phát hiện ≤ 10 phút, EVT: `gateway.drift-detected`; lần hai `409` ERR-02-035; đẩy lại sửa route thiếu và lệch, route thừa chỉ báo.

  @TC-02-137 @P1 @Âm @Bảo @mật
  Kịch bản: TC-02-137 Ma trận scope của giao diện nội bộ: mỗi token chỉ gọi được operation của mình
    # Truy vết: FR-02-059 · API-02-017, 080, 081, 082 · UC-02-35 · BR-02-033 · ERR-02-014 · NFR-02-018.
    Biết S-GW (`catalog:gateway-read`), S-GW-ACK (`catalog:gateway-ack`), S-FLOW, S-PORTAL; token người dùng U-T68-TA.
    Khi với mỗi cặp (token, operation) trong {017, 080, 081, 082}, gọi operation.
    Và gọi bằng token người dùng U-T68-TA.
    Và gọi bằng token tenant T01 cho dữ liệu T68.
    Thì chỉ cặp đúng scope `200`, `204` hoặc `304`; 12 cặp sai scope `403` ERR-02-014; token người dùng `403`, kể cả TA; token T01 chỉ thấy dữ liệu T01. Hợp đồng Pact với PH-03, PH-04, PH-15 vẫn đạt.

  @TC-02-138 @P2 @Âm
  Kịch bản: TC-02-138 Đối soát gateway: đang chạy, gateway sự cố, tắt tự sửa, sai quyền
    # Truy vết: FR-02-060 · API-02-083, 084 · UI-02-17 · UC-02-36 · ERR-02-035, 033, 014.
    Biết M-GW có một route thừa, một route thiếu; `02.reconcile.auto-repair` = false; U-T68-TO, U-T68-VW.
    Khi U-T68-TO `POST /gateway-reconciliations` hai lần liền.
    Và đợi lần chạy xong; xem `GET /gateway-reconciliations/latest`.
    Và đặt M-GW từ chối nhận cấu hình rồi chạy lại.
    Và U-T68-VW gọi cả hai operation.
    Thì bước 1: `202` rồi `409` ERR-02-035. Bước 2: báo cáo nêu route thừa, thiếu, lệch; không tự đẩy lại vì tắt tự sửa. Bước 3: `202` rồi kết quả ở `operationId` ghi ERR-02-033 vì gateway không nhận cấu hình; không đánh dấu "đã khớp". Bước 4: `403` ERR-02-014.
