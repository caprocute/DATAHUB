# language: vi
# Sinh tự động từ D05-02-PH14 bằng ph14/tools/gen_gherkin.py; không sửa tay.
@PH-14 @TS-14-15
Tính năng: TS-14-15 · Cổng tiếp hợp danh mục dùng chung quốc gia cho PH-07

  @TC-14-038 @P1 @Dương
  Kịch bản: TC-14-038 Danh sách, cấu trúc, dữ liệu, đề xuất bổ sung
    # Truy vết: FR-14-023 · API-14-079, 080, 081, 082, 083 · UC-14-15 · UI-14-11 · BR-14-036 · LGC-NGSP-006, LGC-DMDC-019.
    Biết S-PH07; V-DMDC; `sim-ndxp` có danh mục `DM_DANTOC`.
    Khi `GET /national-catalogs`; `GET …/DM_DANTOC/structure`; `GET …/DM_DANTOC/data`.
    Và `POST …/DM_DANTOC/proposals`; `GET …/proposals/{proposalId}`.
    Thì dữ liệu chuyển tiếp nguyên trạng; không có bảng dữ liệu danh mục ở CSDL PH-14; đề xuất ghi trạng thái.

  @TC-14-039 @P1 @Âm @Bảo @mật
  Kịch bản: TC-14-039 Người gọi không phải PH-07; đề xuất không có
    # Truy vết: FR-14-023 · API-14-079, 083 · ERR-14-001, 027 · BR-14-036.
    Biết S-HT-MC; S-PH07; PH-07 giả lập không khả dụng ở bước cuối.
    Khi S-HT-MC gọi `GET /national-catalogs`.
    Và S-PH07 `GET …/proposals/khong-co`.
    Và dừng PH-07 phía chuyển đổi, S-PH07 gọi lấy dữ liệu.
    Thì bước 1 `403`; bước 2 `404` ERR-14-001; bước 3 `502` ERR-14-027.
