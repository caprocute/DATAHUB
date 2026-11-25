# language: vi
# Sinh tự động từ D05-02-PH04 bằng ph04/tools/gen_gherkin.py; không sửa tay.
@PH-04 @TS-04-10
Tính năng: TS-04-10 · Kamelet, Pipe, bean, ghi chú, luồng con

  @TC-04-057 @P2 @Dương
  Kịch bản: TC-04-057 Soạn Kamelet tự viết và dùng trong luồng
    # Truy vết: FR-04-018 · UI-04-08 · UC-04-07
    Biết F-KAM v1 `DRAFT`, tham số `pattern` và `maskChar`.
    Khi trên UI-04-08, khai báo tham số, đánh dấu không nhạy cảm, lưu.
    Và đưa F-KAM qua duyệt và phát hành TEST.
    Và mở F-HT v4, tìm "ma hoa" trong bảng thành phần.
    Thì bước 1: VR-15 không có lỗi. Bước 3: F-KAM có trong nhóm "Chặng chuẩn Datahub" với nhãn "Của tỉnh", có `source = TENANT`; khi kéo vào, biểu mẫu sinh từ khai báo tham số.

  @TC-04-058 @P2 @Âm
  Kịch bản: TC-04-058 Kamelet sai
    # Truy vết: FR-04-018 · ERR-04-036, 029 · BR-04-003
    Biết IE1.
    Khi tạo Kamelet tên `dh-receive-action` (trùng Kamelet nền).
    Và tạo Kamelet có tham số `apiKey` không đánh dấu `format: password`.
    Và tạo Kamelet dùng `smb` (không hồ sơ nào có).
    Thì bước 1 trả `409` ERR-04-036. Bước 2: finding VR-15 `ERROR`. Bước 3: ở mức `PUBLISH` có ERR-04-029.

  @TC-04-059 @P3 @Dương @Âm
  Kịch bản: TC-04-059 Soạn Pipe
    # Truy vết: FR-04-019 · UI-04-09
    Biết kamelet `kafka-source`, F-KAM (`action`), `http-sink`.
    Khi tạo Pipe `source: kafka-source`, `steps: [F-KAM]`, `sink: http-sink`.
    Và đặt `http-sink` vào `source`.
    Thì bước 1: hợp lệ. Bước 2: finding VR-15 "Kamelet loại sink không dùng làm nguồn".

  @TC-04-060 @P3 @Dương @Âm
  Kịch bản: TC-04-060 Bean khai báo và cấu hình cấp tệp
    # Truy vết: FR-04-021 · UI-04-10 · ERR-04-011
    Biết danh sách lớp bean cho phép có `vn.datahub.runtime.beans.VietnameseNormalizer`.
    Khi khai báo bean lớp được phép, dùng `#normalizer` ở chặng `transform`.
    Và khai báo bean `java.lang.ProcessBuilder`.
    Thì bước 1 hợp lệ. Bước 2: VR-04 `ERROR` ở `SUBMIT`, "Lớp không được phép"; gửi duyệt trả ERR-04-009 với ERR-04-011 trong finding.

  @TC-04-061 @P3 @Dương
  Kịch bản: TC-04-061 Ghi chú dán và luồng con
    # Truy vết: FR-04-026 · BR-04-007 · UI-04-04
    Biết F-HT v4.
    Khi thêm hai ghi chú dán màu khác nhau.
    Và chọn ba chặng, "Tách thành luồng con".
    Thì bước 1: ghi chú lưu ở bố cục, không có trong YAML (BR-04-007). Bước 2: sinh route `direct:{flow}-sub-1` trong cùng tệp, chỗ cũ thay bằng `to: direct:…`; quay vòng YAML giữ nguyên băm sau khi tách.
