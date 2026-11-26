# language: vi
# Sinh tự động từ D05-02-PH19 bằng ph19/tools/gen_gherkin.py; không sửa tay.
@PH-19 @TS-19-26
Tính năng: TS-19-26 · Báo cáo định kỳ

  @TC-19-626 @P2 @Dương
  Kịch bản: TC-19-626 Báo cáo tháng khớp dữ liệu giao dịch
    # Truy vết: FR-19-058 · API-19-082 · UI-19-25
    Biết U-ACC1; tháng trước có 1.000 giao dịch sinh tổng hợp, 20 lần hoàn.
    Khi mở báo cáo "Tổng hợp thu theo dịch vụ", kỳ tháng trước.
    Và so tổng với truy vấn đối chứng SQL; so tổng hoàn tiền.
    Thì tổng thu, số lượt, theo dịch vụ, lĩnh vực, đối tác, NCC đều bằng; giao dịch thử bị loại; dòng hoàn tiền tách riêng, "thu thuần" = thu − hoàn. Phát hành Đ2b.

  @TC-19-627 @P3 @Dương
  Kịch bản: TC-19-627 Xuất báo cáo
    # Truy vết: FR-19-058 · API-19-083, 084 · NFR-19-009
    Biết như TC-19-626.
    Khi xuất XLSX và PDF.
    Thì tệp có tiêu đề, kỳ, tenant, người xuất, thời điểm; số liệu bằng màn hình. Phát hành Đ2b.

  @TC-19-628 @P3 @Âm
  Kịch bản: TC-19-628 Báo cáo sai kỳ, không có quyền
    # Truy vết: FR-19-058 · API-19-082 · ERR-19-001, 046, 020
    Biết U-OPR1 (không có `report-read`).
    Khi kỳ tháng tương lai; kỳ quý sai định dạng `2026-Q5`.
    Và mã báo cáo không tồn tại.
    Và U-OPR1 mở báo cáo.
    Thì bước 1 trả `400` ERR-19-001. Bước 2 trả `404` ERR-19-020. Bước 3: 403-PQ.
