# language: vi
# Sinh tự động từ D05-02-PH16 bằng ph16/tools/gen_gherkin.py; không sửa tay.
@PH-16 @TS-16-19
Tính năng: TS-16-19 · Cung cấp chỉ tiêu cho hệ khác và thẻ Tổng quan

  @TC-16-074 @P1 @Dương
  Kịch bản: TC-16-074 API đọc chỉ tiêu, báo cáo cho hệ khác và thẻ Tổng quan
    # Truy vết: FR-16-035, FR-16-037 · API-16-086, 087, 089 · UI-16-01 · BR-16-007, BR-16-009, BR-16-026 · NFR-16-006
    Biết S-T90-PH17 (scope `kpi.read`); `bc-thang-2026-09` `PUBLISHED`, `bc-thang-2026-08` `WITHDRAWN`, `bc-thang-2026-10` `DRAFT`; `16.overview.pinned-indicators` = `mttd,httt-ket-noi-ty-le,bi-mat-ngoai-kho,ho-so-cap-do-phe-duyet` (4 mã).
    Khi `GET /feed/indicator-values?periodCode=M-2026-09&onlyOfficial=true&groupCode=KET_NOI`
    Và `GET /feed/reports?reportType=PERIODIC&from=2026-01-01&to=2026-12-31`
    Và `GET /feed/indicator-values?indicatorCodes=mttd,httt-ket-noi-ty-le`
    Và `GET /cards?limit=4` (4 chỉ tiêu ghim theo `16.overview.pinned-indicators`, một chỉ tiêu `NO_DATA`) và mở `/tong-quan`; đặt lại tham số rỗng rồi `GET /cards`
    Thì bước 1 `200`, `FeedValue` có `value`, `unit`, `status`, `completeness`, `provisional = false`, `reportCode`. Bước 2 chỉ `bc-thang-2026-09` (không bản nháp, không bản `WITHDRAWN`), có `contentHash`, `downloadUrl`. Bước 3 đúng hai chỉ tiêu. p99 ≤ 300 ms ở 50 lượt/giây (đo ở TC-16-116). Bước 4 `cards[]` ≤ 4, mỗi thẻ có `displayValue`, `status`, `trend`, `link` tới `/giam-sat/chi-tieu/chi-so/{ma}`; chỉ tiêu thiếu số hiện "Chưa có số liệu", không điền số cũ; `/tong-quan` hiển thị đủ thẻ. Tham số rỗng thì thẻ lấy điểm tổng và chỉ tiêu `OFF_TRACK` có trọng số nhóm cao nhất.

  @TC-16-075 @P1 @Âm @Bảo @mật
  Kịch bản: TC-16-075 Đọc máy: thiếu scope, tenant khác, tham số sai
    # Truy vết: FR-16-035 · API-16-086, 087 · ERR-16-037, ERR-16-057
    Biết S-T90-NOSCOPE, S-T91-PH01 (scope `kpi.read` của T91), S-T90-PH17.
    Khi S-T90-NOSCOPE `GET /feed/reports`
    Và S-T91-PH01 `GET /feed/reports?reportCode=bc-thang-2026-09` (tenant T90)
    Và S-T90-PH17 `GET /feed/indicator-values?from=2026-12-01&to=2026-01-01`
    Thì bước 1 `403` ERR-00-403. Bước 2 không thấy dữ liệu T90 (`403` ERR-16-037 hoặc danh sách rỗng chỉ của T91). Bước 3 `400` ERR-16-057. Câu thông báo ERR-16-037 trả cho bên gọi máy.
