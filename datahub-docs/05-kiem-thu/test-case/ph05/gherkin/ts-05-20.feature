# language: vi
# Sinh tự động từ D05-02-PH05 bằng ph05/tools/gen_gherkin.py; không sửa tay.
@PH-05 @TS-05-20
Tính năng: TS-05-20 · Chuyển đổi định dạng và chuẩn hóa

  @TC-05-077 @P1 @Dương
  Kịch bản: TC-05-077 XML sang JSON: thuộc tính, phần tử lặp theo XSD
    # Truy vết: FR-05-040 · API-05-054 · UI-05-10
    Biết U-T68-IE1; F-XML (phần tử `VanBan` lặp một lần, có thuộc tính `loai`).
    Thì `vanBan` là mảng một phần tử (theo XSD, không đoán theo số lần xuất hiện); thuộc tính thành `@loai`; văn bản kèm thuộc tính thành `#text`; tiền tố không gian tên bỏ theo bảng. Kết quả bằng đúng kết quả runtime trên cùng đầu vào (so băm).

  @TC-05-078 @P2 @Dương @Âm
  Kịch bản: TC-05-078 CSV windows-1258, TCVN3; VNI bị từ chối
    # Truy vết: FR-05-040 · API-05-050, 054 · ERR-05-032
    Biết ba tệp mẫu cùng nội dung "Nguyễn Thị Ánh" ở `windows-1258`, `TCVN3`; thao tác khai `encoding = VNI`.
    Thì JSON có đúng chuỗi Unicode NFC "Nguyễn Thị Ánh"; lưu `VNI` `422` ERR-05-032.

  @TC-05-079 @P1 @Dương
  Kịch bản: TC-05-079 Chuẩn hóa giá trị thiếu: DEFAULT, REJECT, PASS_NULL
    # Truy vết: FR-05-041 · API-05-054 · ERR-05-109 · UI-05-10
    Biết quy tắc: `$.ngayKy` thiếu khi `01/01/1900` → `PASS_NULL`; `$.coQuan` thiếu → `DEFAULT:Chưa rõ`; `$.so` thiếu → `REJECT`.
    Thì `ngayKy = null`, `coQuan = "Chưa rõ"`, bản ghi thiếu `so` bị từ chối; `warnings[]` nêu đường dẫn, giá trị gốc, quy tắc; số liệu "4 bản ghi · 1 bị từ chối". Ở runtime bản ghi đơn lẻ thiếu `so` trả ERR-05-109.

  @TC-05-080 @P2 @Âm
  Kịch bản: TC-05-080 Phản hồi sai lược đồ; mẫu quá lớn
    # Truy vết: FR-05-040, 032 · ERR-05-108, 035
    Biết thao tác có `responseSchemaRef`; SIM-HTTP trả `so` là số thay vì chuỗi; mẫu 1,5 MiB.
    Thì ERR-05-108 kèm đường dẫn trường sai; mẫu `413` ERR-05-035.
