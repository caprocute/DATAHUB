# language: vi
# Sinh tự động từ D05-02-PH06 bằng ph06/tools/gen_gherkin.py; không sửa tay.
@PH-06 @TS-06-19
Tính năng: TS-06-19 · Tách bản ghi vàng và gỡ liên kết chéo nguồn

  @TC-06-083 @P1 @Dương
  Kịch bản: TC-06-083 Tách một bản ghi vàng thành hai
    # Truy vết: FR-06-038 · BR-06-023 · API-06-059 · UI-06-06 · EVT-06-04 · PERM-06-merge
    # Mục đích: Chứng minh tách phân bổ liên kết, tính lại sống sót, ghi `negativeLink`, theo FR-06-038.
    Biết bản ghi vàng X gom nhầm hai người, hai liên kết mỗi người (rủi ro cao, DA1 duyệt).
    Khi `POST .../{id}:split` phân bổ hai nhóm, lý do 40 ký tự.
    Và DA1 duyệt.
    Và `GET` hai bản ghi, `xrefs`.
    Thì bản ghi mới (hoặc `goldenId` cũ `MERGED` được khôi phục) cho nhóm sau; xref chuyển đúng; sống sót tính lại cho cả hai; `negativeLink` giữa hai bên; EVT-06-04 có `fromGoldenId`, `toGoldenIds[]`. KT: có (split).
    # Hậu điều kiện: Hai bản ghi vàng.

  @TC-06-084 @P1 @Âm
  Kịch bản: TC-06-084 Phân bổ tách không hợp lệ
    # Truy vết: FR-06-038 · API-06-059 · ERR-06-007, 032
    # Mục đích: Chứng minh mọi liên kết phải được phân đúng một nhóm và có ít nhất hai nhóm, theo FR-06-038.
    Biết bản ghi vàng Y bốn liên kết.
    Khi phân bổ thiếu một liên kết.
    Và phân bổ một liên kết vào hai nhóm.
    Và chỉ một nhóm.
    Và thiếu lý do.
    Thì bước 1, 2, 3 `422` ERR-06-032. Bước 4 `422` ERR-06-007. Bản ghi Y không đổi.
    # Hậu điều kiện: Không đổi.

  @TC-06-085 @P1 @Dương @Âm
  Kịch bản: TC-06-085 Xem và gỡ liên kết chéo nguồn
    # Truy vết: FR-06-044 · BR-06-018, 023 · API-06-066, 067 · ERR-06-006, 031 · EVT-06-14
    # Mục đích: Chứng minh gỡ liên kết `MANUAL`, hai chế độ `RelinkMode` và liên kết do người xác nhận không bị máy tự tách, theo FR-06-044.
    Biết bản ghi vàng Z hai liên kết; DS1.
    Khi `GET .../xrefs`.
    Và `POST .../xrefs/{id}:detach` `NEW_GOLDEN`, lý do.
    Và gỡ lại xref vừa `DETACHED`.
    Và chạy job lô trên domain.
    Thì bước 1 `XrefStatus` đúng. Bước 2 xref `DETACHED` `MANUAL`, bản ghi vàng mới, EVT-06-14. Bước 3 `409` ERR-06-006. Bước 4 không tự gắn lại xref đã gỡ (BR-06-023).
    # Hậu điều kiện: Z một liên kết.
