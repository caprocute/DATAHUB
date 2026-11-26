# language: vi
# Sinh tự động từ D05-02-PH12 bằng ph12/tools/gen_gherkin.py; không sửa tay.
@PH-12 @TS-12-27
Tính năng: TS-12-27 · Chuyển đổi XACML, quyết định theo lô và bộ đệm

  @TC-12-086 @P1 @Dương @Âm
  Kịch bản: TC-12-086 XACML hợp lệ và sai lược đồ
    # Truy vết: FR-12-048 · UC-12-32 · API-12-088 · ERR-12-123 · CMP-LAW-09
    Biết HTTT thẩm định cũ gọi XACML; thân hợp lệ và thân sai.
    Khi `POST /api/authz/v1/xacml` với thân hợp lệ, rồi thân sai lược đồ.
    Thì kết quả `Permit` hoặc `Deny` khớp `decide` cùng dữ liệu; thân sai `400` ERR-12-123 với `Indeterminate`, bên gọi xử lý như từ chối.

  @TC-12-087 @P2 @Dương @Biên
  Kịch bản: TC-12-087 Quyết định theo lô 100 và vượt 100
    # Truy vết: FR-12-049 · UC-12-32 · API-12-087 · ERR-12-101
    Biết S-PEP; 100 và 101 yêu cầu.
    Khi `POST …/decide:batch` với 100 rồi 101 yêu cầu.
    Thì 100 yêu cầu trả đủ 100 kết quả cùng thứ tự; 101 `400` ERR-12-101.

  @TC-12-088 @P1 @Dương @Bảo @mật
  Kịch bản: TC-12-088 Bộ đệm: mất hiệu lực khi đổi gói, không đệm mức Nhạy cảm
    # Truy vết: FR-12-050 · BR-12-012 · NFR-12-009 · UC-12-32
    Biết PEP có bộ đệm; tài nguyên thường và Nhạy cảm.
    Khi hỏi hai lần; đổi gói chính sách (đổi `bundleRevision`); hỏi lại.
    Và hỏi hai lần tài nguyên Nhạy cảm và tài nguyên có nghĩa vụ `STEPUP`.
    Thì lần hai trúng đệm; sau đổi gói không dùng kết quả cũ; mức Nhạy cảm không đệm; trúng đệm ≥ 60 % sau 1 giờ (PERF).
