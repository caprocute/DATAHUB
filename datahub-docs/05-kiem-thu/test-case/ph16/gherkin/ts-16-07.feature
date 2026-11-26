# language: vi
# Sinh tự động từ D05-02-PH16 bằng ph16/tools/gen_gherkin.py; không sửa tay.
@PH-16 @TS-16-07
Tính năng: TS-16-07 · Nhật ký tiếp nhận và xử lý lại quan sát bị loại

  @TC-16-028 @P2 @Dương @Âm
  Kịch bản: TC-16-028 Tra nhật ký tiếp nhận và xử lý lại quan sát bị loại
    # Truy vết: FR-16-016 · API-16-042, 044, 045, 024 · ERR-16-007, ERR-16-003 · UI-16-06
    Biết quan sát bị loại `ph01.khac.chi-so` (id `r1`) và bản tin sai lược đồ (id `r2`) từ TC-16-024.
    Khi `GET /sources/tc-ph01-event/ingest-logs?result=REJECTED&code=ERR-16-102`
    Và `GET /rejected-observations?sourceCode=tc-ph01-event`
    Và U-T90-VW `GET /sources/tc-ph01-event/ingest-logs`
    Và `PATCH /sources/tc-ph01-event` thêm `ph01.khac.chi-so` vào `contract.metricCodes`
    Và `POST /rejected-observations:reprocess` `{ids: [r1, r2], reason: "Đã bổ sung hợp đồng chỉ số"}`
    Và `POST /rejected-observations:reprocess` với `reason` 5 ký tự
    Và `POST /rejected-observations:reprocess` với `ids` rỗng
    Thì bước 1, 2 chỉ trả dòng khớp bộ lọc (`metricCode`, `code`, `detail`, `receivedAt`). Bước 3 `403` ERR-00-403. Bước 5 `200`, `reprocessed = 1` (`r1`), `stillRejected = [{id: r2, code: ERR-16-105}]`. Bước 6 `400` ERR-16-003 (`reason` ngắn hơn 20 ký tự theo lược đồ) hoặc `422` ERR-16-007. Bước 7 `400` ERR-16-003. Quan sát `r1` có `REPROCESSED` trong nhật ký, không trùng.
