# language: vi
# Sinh tự động từ D05-02-PH16 bằng ph16/tools/gen_gherkin.py; không sửa tay.
@PH-16 @TS-16-27
Tính năng: TS-16-27 · Quản lý mẫu gói quốc gia

  @TC-16-094 @P1 @Dương @Âm
  Kịch bản: TC-16-094 Tạo, thử, kích hoạt mẫu gói quốc gia có phiên bản; mẫu sai
    # Truy vết: FR-16-050 · API-16-115, 116, 117, 114 · UI-16-17 · ERR-16-047 · BR-16-002, BR-16-021
    Biết T96; U-PA hoặc U-T96-TA; không có mẫu `KPI_REPORT`.
    Khi `POST /national/templates` `{templateCode: qg-bao-cao-chi-tieu, submissionType: KPI_REPORT, version: 1, schema: {…}, mapping: {…ánh xạ trường báo cáo sang gói…}, channelRef: "ph14:qg-sim", effectiveFrom: 2026-12-01}`
    Và `GET /national/templates/qg-bao-cao-chi-tieu`
    Và `POST /national/templates/qg-bao-cao-chi-tieu/versions/1:activate`
    Và tạo phiên bản 2 rồi kích hoạt
    Và `POST /national/templates` với `schema` không hợp lệ, hoặc `mapping` trỏ trường không có
    Và U-T96-TO (không có `PERM-16-national`) `POST /national/templates`
    Thì bước 1 `201`, `state = DRAFT`, `testResult` đạt thử trên báo cáo mẫu. Bước 3 `200`, `ACTIVE`. Bước 4 bản 2 `ACTIVE`, bản 1 `SUPERSEDED`; gói đã nộp theo bản 1 không đổi. Mẫu nằm ở cấu hình, đổi không cần phát hành (NFR-16-020). Bước 5 `422` ERR-16-047. Bước 6 `403` ERR-00-403; mẫu hiện hành giữ `ACTIVE`.
