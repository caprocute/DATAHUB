# language: vi
# Sinh tự động từ D05-02-PH15 bằng ph15/tools/gen_gherkin.py; không sửa tay.
@PH-15 @TS-15-17
Tính năng: TS-15-17 · Khai báo sandbox của dịch vụ

  @TC-15-102 @P1 @Dương
  Kịch bản: TC-15-102 Khai báo MOCK và BACKEND
    # Truy vết: FR-15-034 · UC-15-18 · API-15-069, 070 · UI-15-23 · ERR-15-101 · BR-15-017, 018 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết U-T68-SV (chủ dịch vụ HT-TUPHAP); egress cho phép `sim-backend.sim.test`.
    Khi `PUT /catalog/apis/tra-cuu-ho-tich/sandbox` {versionNo `1.0.0`, mode `MOCK`, examplePolicy `FIRST`}.
    Và `PUT /catalog/apis/dm-hanh-chinh/sandbox` {mode `BACKEND`, backendUrl `https://sim-backend.sim.test/dmhc`}.
    Và `GET` cả hai.
    Thì `200`, có `ETag`; hồ sơ trả đúng; chế độ OFF cho `POST /try/requests` trả `422` ERR-15-101.

  @TC-15-103 @P1 @Âm
  Kịch bản: TC-15-103 Backend ngoài allowlist, thiếu cấu hình, phiên bản ngừng, không phải chủ
    # Truy vết: FR-15-034 · UC-15-18 · API-15-070 · ERR-15-005, 040, 119, 120 · BR-15-018 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết U-T68-SV, U-T68-OR; `ban-do-cu` RETIRED.
    Khi `backendUrl` `https://evil.test/`, `http://sim-backend.sim.test`, `https://10.0.0.5/`.
    Và `mode = BACKEND` thiếu `backendUrl`.
    Và cấu hình `ban-do-cu`.
    Và bình cấu hình `tra-cuu-ho-tich`.
    Thì `422` ERR-15-119; `409` ERR-15-120 "Chế độ BACKEND cần khai báo backendUrl"; `422` ERR-15-040; `403` ERR-15-005.

  @TC-15-104 @P1 @Âm @Bảo @mật
  Kịch bản: TC-15-104 Chặn SSRF ở khai báo và lúc gọi
    # Truy vết: FR-15-034, 037 · API-15-070, 072 · ERR-15-119 · BR-15-018 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết địa chỉ `https://localhost/`, `https://169.254.169.254/`, `https://[::1]/`, tên DNS trỏ `10.0.0.5`, URL 302 sang địa chỉ nội bộ.
    Khi khai báo từng địa chỉ.
    Và với tên DNS đổi trỏ sau khi khai báo (rebinding), thử API.
    Thì tất cả bị từ chối `422` ERR-15-119; địa chỉ được kiểm lại ở lúc gọi; không theo chuyển hướng ra ngoài allowlist; không có kết nối nào tới mạng nội bộ (đếm ở WireMock nội bộ bằng 0).
