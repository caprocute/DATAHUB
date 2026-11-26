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

  @TC-14-109 @P2 @Âm @Biên
  Kịch bản: TC-14-109 ĐVQHNS: khoảng thời gian, cỡ trang, số trang vượt giới hạn, hết hạn mức nền
    # Truy vết: FR-14-020 · API-14-075 · ERR-14-104, 108 · BR-14-013 · LGC-NGSP-004.
    Biết S-PH04; V-DVQHNS (`BACKGROUND`); 3.000 hồ sơ, 20 dòng/trang; `14.adapter.max-pages = 100`; ở bước 4 mức dùng hạn mức đạt 75 %.
    Khi `listDossiersByRange` khoảng 32 ngày.
    Và `listDossiersByRange` khoảng 31 ngày với `size = 101`.
    Và `listDossiersByRange` khoảng 31 ngày, `size = 20`, nguồn có 3.000 hồ sơ (150 trang).
    Và với mức dùng 75 %, gọi từ lịch đồng bộ rồi gọi dịch vụ `ESSENTIAL` V-LLTP.
    Thì bước 1 và 2 `422` ERR-14-108; khoảng đúng 31 ngày chấp nhận. Bước 3 dừng ở trang 100, `422` ERR-14-108 kèm `partial`. Bước 4 lượt `BACKGROUND` bị hoãn `429` ERR-14-104, lượt V-LLTP vẫn `200`; tác vụ nền không làm ngưng dịch vụ công.

  @TC-14-110 @P2 @Âm
  Kịch bản: TC-14-110 Đăng ký doanh nghiệp: mã số sai mẫu, không tìm thấy, bỏ qua đệm
    # Truy vết: FR-14-021 · API-14-075 · ERR-14-102, 108 · BR-14-014 · LGC-NGSP-005.
    Biết S-HT-MC; V-DKKD (đệm 600 giây); `sim-ndxp` `OK`, sau đó `BIZ404`.
    Khi gọi với mã số doanh nghiệp 9 chữ số, rồi 11 chữ số, rồi có chữ cái.
    Và gọi với mã 10 chữ số hợp lệ khi `BIZ404`; gọi lại ngay.
    Và gọi với khoảng thời gian 45 ngày.
    Thì bước 1 `422` ERR-14-108 "Mã số doanh nghiệp gồm 10 hoặc 13 chữ số.", không gọi ra. Bước 2 `404` ERR-14-102 "Không tìm thấy doanh nghiệp có mã số {mã}."; lần gọi lại vẫn gọi ra quốc gia vì lỗi không được đệm. Bước 3 `422` ERR-14-108. Mã số doanh nghiệp được băm trong nhật ký thường.

  @TC-14-111 @P3 @Âm
  Kịch bản: TC-14-111 Văn bản quy phạm: từ khóa rỗng hoặc quá dài, không tìm thấy
    # Truy vết: FR-14-022 · API-14-075 · ERR-14-102, 108 · BR-14-014 · LGC-NGSP-007.
    Biết S-HT-MC; V-VBQPPL (dịch vụ `PUBLIC`, đệm 3.600 giây); `sim-ndxp` `OK`, sau đó `BIZ404`.
    Khi `searchFullText` với `keyword` rỗng.
    Và `searchFullText` với `keyword` 201 ký tự.
    Và `getDocument` mã `VB-KHONG-CO` khi `BIZ404`.
    Và `searchFullText` với `keyword` 200 ký tự.
    Thì bước 1 và 2 `422` ERR-14-108 "Từ khóa tìm kiếm từ 1 đến 200 ký tự." Bước 3 `404` ERR-14-102 "Không tìm thấy văn bản VB-KHONG-CO." Bước 4 `200` (biên hợp lệ). Dịch vụ `PUBLIC` không đòi mục đích nhưng vẫn kiểm tra đăng ký sử dụng và ghi giao dịch.

  @TC-14-155 @P2 @Dương
  Kịch bản: TC-14-155 ĐVQHNS: mốc `watermark`, đệm chi tiết 300 giây, danh sách không đệm, ưu tiên nền
    # Truy vết: FR-14-020 · API-14-075 · UC-14-13 · BR-14-013, 014 · LGC-NGSP-004.
    Biết S-PH04; V-DVQHNS; 60 hồ sơ cập nhật trong ngày; `sim-ndxp` `OK`; hạn mức dưới 70 %.
    Khi `listDossiersByRange` khoảng 1 ngày từ lịch đồng bộ; ghi `watermark`.
    Và gọi lại với `from` bằng `watermark`.
    Và `getDossier` cùng mã hai lần liên tiếp.
    Và gọi lại `listDossiersByRange` cùng tham số hai lần.
    Thì bước 1 `200`, `items[]` kèm `watermark` là thời điểm cập nhật lớn nhất. Bước 2 chỉ trả hồ sơ cập nhật sau mốc đó; người tiêu thụ tự khử trùng theo mã hồ sơ. Bước 3 lượt hai `X-DH-Cache: HIT` (đệm 300 giây). Bước 4 cả hai lượt gọi ra quốc gia, danh sách không đệm. Giao dịch lượt từ lịch mang ưu tiên `BACKGROUND`.
