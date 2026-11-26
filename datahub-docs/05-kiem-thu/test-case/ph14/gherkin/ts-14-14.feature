# language: vi
# Sinh tự động từ D05-02-PH14 bằng ph14/tools/gen_gherkin.py; không sửa tay.
@PH-14 @TS-14-14
Tính năng: TS-14-14 · Hồ sơ cấp mã ĐVQHNS, đăng ký doanh nghiệp, văn bản quy phạm pháp luật

  @TC-14-036 @P2 @Dương @Biên @Âm
  Kịch bản: TC-14-036 ĐVQHNS theo khoảng thời gian, tự phân trang
    # Truy vết: FR-14-020 · API-14-075 · ERR-14-003, 128 · UC-14-13 · LGC-NGSP-004.
    Biết S-PH04; V-DVQHNS; 250 hồ sơ, 20 dòng/trang; `14.adapter.max-pages = 100`.
    Khi gọi khoảng 1 ngày.
    Và gọi khoảng 5 năm.
    Và đặt phản hồi lớn hơn `14.adapter.max-response-mb`.
    Thì bước 1 gộp 13 trang thành một phản hồi; bước 2 `400` ERR-14-003 (khoảng quá rộng); bước 3 `502` ERR-14-128.

  @TC-14-037 @P2 @Dương
  Kịch bản: TC-14-037 Đăng ký doanh nghiệp và văn bản quy phạm: trúng đệm
    # Truy vết: FR-14-021, 022 · API-14-075 · UC-14-14 · NFR-14-004 · LGC-NGSP-005, 007.
    Biết S-HT-MC; V-DKKD, V-VBQPPL.
    Khi gọi `V-DKKD.getLatest` hai lần.
    Và gọi `V-VBQPPL.search` hai lần, lần hai `freshData = true`.
    Thì lần hai bước 1 `COMPLETED_CACHE`, không gọi ra; bước 2 lần hai gọi ra quốc gia; mọi truy vấn văn bản (tìm toàn văn, lĩnh vực, cơ quan, người ký, chức danh) trả đúng.
