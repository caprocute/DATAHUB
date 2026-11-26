# language: vi
# Sinh tự động từ D05-02-PH12 bằng ph12/tools/gen_gherkin.py; không sửa tay.
@PH-12 @TS-12-09
Tính năng: TS-12-09 · Nhóm và đơn vị tổ chức

  @TC-12-035 @P1 @Dương
  Kịch bản: TC-12-035 Tạo cây nhóm và đặt thành viên
    # Truy vết: FR-12-014 · UC-12-11 · UI-12-07 · API-12-032, 033, 034, 035 · LGC-BUS-032 · BR-12-039
    Biết U-T68-TA1; nhóm `phong-cntt` có ở cả T68 và T01.
    Khi tạo `so-a` → `phong-a1`; `PUT /groups/{id}/members` 3 người.
    Và `GET /groups` ở T68 và T01.
    Thì cây đúng, phạm vi kế thừa xuống nhóm con; mỗi tenant chỉ thấy `phong-cntt` của mình; KT: có (group.create, group.members).

  @TC-12-036 @P2 @Âm
  Kịch bản: TC-12-036 Vòng lặp nhóm và nhóm đang được dùng
    # Truy vết: FR-12-014 · BR-12-039 · API-12-034 · ERR-12-012 · ERR-12-011
    Biết cây `so-a` → `phong-a1`; một vai trò phạm vi gắn `phong-a1`.
    Khi `PATCH` đặt cha của `so-a` là `phong-a1`.
    Và gỡ nhóm `phong-a1` khi còn được dùng.
    Thì bước 1 `422` ERR-12-012; bước 2 `409` ERR-12-011.
