# language: vi
# Sinh tự động từ D05-02-PH11 bằng ph11/tools/gen_gherkin.py; không sửa tay.
@PH-11 @TS-11-15
Tính năng: TS-11-15 · Tra cứu và xem chi tiết phiên

  @TC-11-090 @P1 @Dương
  Kịch bản: TC-11-090 Liệt kê, lọc phiên và phạm vi xem
    # Truy vết: FR-11-021 · API-11-050 · UI-11-11 · BR-11-031 · bpm.instance.read
    Biết 20 phiên (`HS-01`…`HS-20`) nhiều trạng thái; VW, CB-TP, S-DVC (khởi tạo 10 phiên).
    Khi VW `GET /instances?processKey=LT_KHAI_SINH&status=RUNNING&dueStatus=DUE_SOON&page=0&size=10`
    Và VW `GET /instances?businessKey=HS-T90-2026-0003`
    Và CB-TP `GET /instances`
    Và S-DVC `GET /instances`
    Thì bước 1 lọc đúng, phân trang. Bước 2 một phiên. Bước 3 chỉ phiên có việc của CB-TP hoặc đơn vị. Bước 4 chỉ 10 phiên do S-DVC khởi tạo, biến đã che.

  @TC-11-091 @P2 @Âm
  Kịch bản: TC-11-091 Liệt kê phiên sai tham số
    # Truy vết: FR-11-021 · API-11-050 · ERR-11-003 · ERR-00-403
    Biết VW; người dùng không vai trò.
    Khi VW `GET /instances?status=FOO`
    Và VW `GET /instances?size=1000`
    Và VW `GET /instances?from=2027-02-01&to=2027-01-01`
    Và người không vai trò `GET /instances`
    Thì ba lần đầu `400` ERR-11-003. Bước 4 `403` ERR-00-403.

  @TC-11-092 @P1 @Dương
  Kịch bản: TC-11-092 Chi tiết phiên: sơ đồ, dòng thời gian, biến đã che
    # Truy vết: FR-11-022 · API-11-051, 053, 054, 055, 070 · UI-11-12 · BR-11-014
    Biết `HS-03` đang ở `capTheBHYT`; VW; TA có `PERM-09-unmask`.
    Khi VW `GET /instances/{id}`
    Và VW `GET /instances/{id}/timeline`
    Và VW `GET /instances/{id}/diagram`
    Và VW `GET /instances/{id}/variables`
    Và TA gọi lại `variables` có lý do mở che
    Thì chi tiết có `waitState = WAITING_SERVICE`; dòng thời gian đủ bước, người xử lý, lệnh `service_call`; sơ đồ đánh dấu bước xong và hiện tại; biến `SENSITIVE` ``. TA có lý do: hiện rõ, KT: có.

  @TC-11-093 @P1 @Âm
  Kịch bản: TC-11-093 Chi tiết phiên không tồn tại, ngoài phạm vi, hết lưu giữ
    # Truy vết: FR-11-022 · API-11-051 · ERR-11-001, 034
    Biết CB-BH; phiên của Tư pháp; phiên đã dọn; `U-T91-IE1`.
    Khi CB-BH `GET /instances/{id}`
    Và VW `GET /instances/khong-co`
    Và VW `GET /instances/{id đã dọn}`
    Và `U-T91-IE1` `GET /instances/{id}`
    Thì bước 1 `403` ERR-11-034. Bước 2 `404` ERR-11-001. Bước 3 `410` ERR-11-001. Bước 4 `404-ẩn`.
