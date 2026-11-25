# language: vi
# Sinh tự động từ mục 7 của D05-02-PH07; không sửa tay.
@PH-07 @UAT
Tính năng: Nghiệm thu người dùng tương đương hệ Aita

  Bối cảnh:
    Biết cán bộ nghiệp vụ của tỉnh thí điểm đã đăng nhập môi trường UAT
    Và dữ liệu danh mục của tỉnh đã được di trú từ hệ Aita

  @UAT-01
  Kịch bản: UAT-01 Xem danh sách danh mục của tỉnh, biết tổng số và tìm một danh mục theo tên
    # Chức năng Aita: LGC-DMDC-001; FR: FR-07-001; TC: TC-07-001
    Khi cán bộ xem danh sách danh mục của tỉnh, biết tổng số và tìm một danh mục theo tên
    Thì thấy đủ danh mục đã di trú, số lượng khớp biên bản đối soát

  @UAT-02
  Kịch bản: UAT-02 Xem một danh mục phân cấp dạng cây
    # Chức năng Aita: LGC-DMDC-002; FR: FR-07-030; TC: TC-07-210
    Khi cán bộ xem một danh mục phân cấp dạng cây
    Thì cây đúng cha con như hệ cũ

  @UAT-03
  Kịch bản: UAT-03 Xem chi tiết danh mục: tên, thuộc tính, bản ghi
    # Chức năng Aita: LGC-DMDC-003; FR: FR-07-002; TC: TC-07-001, 260
    Khi cán bộ xem chi tiết danh mục: tên, thuộc tính, bản ghi
    Thì nội dung khớp hệ cũ, thuộc tính ẩn của hệ cũ vẫn ẩn

  @UAT-04
  Kịch bản: UAT-04 Tạo danh mục mới bằng tay với 3 thuộc tính
    # Chức năng Aita: LGC-DMDC-004; FR: FR-07-003, 005; TC: TC-07-005
    Khi cán bộ tạo danh mục mới bằng tay với 3 thuộc tính
    Thì danh mục ở trạng thái bản nháp, có đủ thuộc tính

  @UAT-05
  Kịch bản: UAT-05 Tạo danh mục từ tệp Excel theo khuôn cũ của Aita
    # Chức năng Aita: LGC-DMDC-005; FR: FR-07-022; TC: TC-07-289
    Khi cán bộ tạo danh mục từ tệp Excel theo khuôn cũ của Aita
    Thì tệp khuôn cũ được nhận dạng, tạo được danh mục

  @UAT-06
  Kịch bản: UAT-06 Nhập bổ sung bản ghi từ Excel và từ CSV
    # Chức năng Aita: LGC-DMDC-006, 007; FR: FR-07-021; TC: TC-07-095
    Khi cán bộ nhập bổ sung bản ghi từ Excel và từ CSV
    Thì có bước xem trước, bản ghi lỗi được chỉ rõ dòng

  @UAT-07
  Kịch bản: UAT-07 Nhập qua API từ một hệ thống của tỉnh
    # Chức năng Aita: LGC-DMDC-008; FR: FR-07-023; TC: TC-07-252
    Khi cán bộ nhập qua API từ một hệ thống của tỉnh
    Thì bản ghi vào bản nháp, không phát hành tự động

  @UAT-08
  Kịch bản: UAT-08 Sửa tên danh mục, thêm thuộc tính, sửa bản ghi
    # Chức năng Aita: LGC-DMDC-009…011; FR: FR-07-004, 006, 012; TC: TC-07-283
    Khi cán bộ sửa tên danh mục, thêm thuộc tính, sửa bản ghi
    Thì sửa trên bản nháp; sau khi duyệt và phát hành, hệ thống khác thấy giá trị mới

  @UAT-09
  Kịch bản: UAT-09 Xóa một danh mục chưa dùng; thử xóa danh mục đã phát hành
    # Chức năng Aita: LGC-DMDC-012; FR: FR-07-009; TC: TC-07-011, 012
    Khi cán bộ xóa một danh mục chưa dùng; thử xóa danh mục đã phát hành
    Thì xóa được danh mục nháp; danh mục đã phát hành chỉ ngừng hiệu lực được

  @UAT-10
  Kịch bản: UAT-10 Xuất danh mục ra Excel và CSV
    # Chức năng Aita: LGC-DMDC-013, 014; FR: FR-07-024; TC: TC-07-131
    Khi cán bộ xuất danh mục ra Excel và CSV
    Thì tệp mở được, nhập lại được

  @UAT-11
  Kịch bản: UAT-11 Một hệ thống của tỉnh tra danh mục qua API
    # Chức năng Aita: LGC-DMDC-015; FR: FR-07-026, 027, 033; TC: TC-07-154
    Khi cán bộ một hệ thống của tỉnh tra danh mục qua API
    Thì tra theo mã, theo lô, lấy lược đồ

  @UAT-12
  Kịch bản: UAT-12 Lọc danh mục theo thuộc tính qua trình thử API
    # Chức năng Aita: LGC-DMDC-016; FR: FR-07-032; TC: TC-07-169
    Khi cán bộ lọc danh mục theo thuộc tính qua trình thử API
    Thì lọc được trên thuộc tính cho phép, không gõ SQL

  @UAT-13
  Kịch bản: UAT-13 Dùng danh mục dân tộc toàn quốc và bổ sung nhóm địa phương
    # Chức năng Aita: LGC-DMDC-017; FR: FR-07-048; TC: TC-07-216
    Khi cán bộ dùng danh mục dân tộc toàn quốc và bổ sung nhóm địa phương
    Thì thấy danh mục toàn quốc, bổ sung được mã trong dải tỉnh

  @UAT-14
  Kịch bản: UAT-14 Ẩn một thuộc tính khỏi hệ thống khai thác
    # Chức năng Aita: LGC-DMDC-018; FR: FR-07-006; TC: TC-07-024…038
    Khi cán bộ ẩn một thuộc tính khỏi hệ thống khai thác
    Thì thuộc tính ẩn trên giao diện, tệp xuất và API, giá trị vẫn giữ

  @UAT-15
  Kịch bản: UAT-15 Cập nhật danh mục quốc gia và xác nhận thay đổi phá vỡ
    # Chức năng Aita: LGC-DMDC-019, LGC-NGSP-006; FR: FR-07-036, 037; TC: TC-07-182, 183
    Khi cán bộ cập nhật danh mục quốc gia và xác nhận thay đổi phá vỡ
    Thì đồng bộ chạy theo lịch, thay đổi phá vỡ chờ xác nhận
