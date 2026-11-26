# language: vi
# Sinh tự động từ D05-02-PH11 bằng ph11/tools/gen_gherkin.py; không sửa tay.
@PH-11 @TS-11-12
Tính năng: TS-11-12 · Chuyển việc, trao đổi ý kiến và đính kèm tệp trên việc

  @TC-11-073 @P1 @Dương
  Kịch bản: TC-11-073 Chuyển việc cho người khác
    # Truy vết: FR-11-040 · API-11-078 · EVT-11-09 · BR-11-020 · PERM-11-task, PERM-11-task-admin
    Biết việc `ASSIGNED` cho CB-TP; CB-TP2 cùng nhóm; TO.
    Khi CB-TP `POST /tasks/{id}:transfer` `{toUser:"CB-TP2", reason:"Nghỉ đột xuất"}`
    Và TO chuyển một việc của CB-BH cho CB-TP
    Thì bước 1 `200`, assignee mới, dòng thời gian ghi người chuyển và lý do, EVT: `task.assigned` `via = TRANSFER`; hộp việc CB-TP2 có, CB-TP mất. Bước 2 `200` nhờ `task-admin`.

  @TC-11-074 @P1 @Âm
  Kịch bản: TC-11-074 Chuyển việc không hợp lệ
    # Truy vết: FR-11-040 · API-11-078 · ERR-11-024 · ERR-00-403 · BR-11-020
    Biết CB-TP2 ngừng hoạt động ở PH-12 giả; `U-T91-CB1`; việc `duyetCapSo` có `separateFrom`; VW.
    Khi CB-TP chuyển cho chính mình
    Và chuyển cho người ngừng hoạt động
    Và chuyển cho `U-T91-CB1`
    Và chuyển việc cấp sở cho CB-LD (đã xử lý cấp phòng)
    Và CB-BH (không phải ứng viên, không `task-admin`) chuyển
    Và VW chuyển
    Thì bước 1 đến 4 `422` ERR-11-024 kèm lý do. Bước 5 `403` ERR-11-022. Bước 6 `403` ERR-00-403.

  @TC-11-075 @P3 @Dương
  Kịch bản: TC-11-075 Ý kiến và tệp đính kèm
    # Truy vết: FR-11-043 · API-11-083, 084, 085, 086 · BR-11-014, 025
    Biết việc của CB-TP; CB-TP2 cùng nhóm; `bien-ban.pdf` 1 MB; `11.task.attachmentMaxMb = 20`.
    Khi CB-TP `POST /tasks/{id}/comments` có `@CB-TP2`
    Và CB-TP `POST /tasks/{id}/attachments` `bien-ban.pdf`
    Và CB-TP2 `GET /comments`, `GET /attachments/{id}`
    Thì bình luận `201`, CB-TP2 nhận nhắc. Tệp `201` có `checksum` SHA-256, quét an toàn đạt; tải về trùng byte và `checksum`; `data_class` của tệp kế thừa từ biểu mẫu.

  @TC-11-076 @P2 @Âm
  Kịch bản: TC-11-076 Tệp sai loại, quá cỡ, người không có quyền
    # Truy vết: FR-11-043 · API-11-085, 086 · ERR-11-022, 027
    Biết `shell.exe` đổi đuôi `.pdf`; `lon-25mb.pdf`; CB-BH không liên quan.
    Khi CB-TP tải `shell.exe` đổi đuôi
    Và CB-TP tải `lon-25mb.pdf`
    Và CB-BH `GET /attachments/{id}`
    Và CB-BH `POST /comments`
    Thì bước 1 `422` ERR-11-027 (nhận dạng theo nội dung). Bước 2 `413` ERR-11-027. Bước 3 và 4 `403` ERR-11-022.
