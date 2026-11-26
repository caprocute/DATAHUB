# language: vi
# Sinh tự động từ D05-02-PH17 bằng ph17/tools/gen_gherkin.py; không sửa tay.
@PH-17 @TS-17-31
Tính năng: TS-17-31 · Lập và rà soát sổ đăng ký hệ thống AI của tenant

  @TC-17-101 @P2 @Dương @Âm
  Kịch bản: TC-17-101 Lập hồ sơ hệ thống AI, thiếu mục, rà soát định kỳ, tự cập nhật khi cấu hình đổi
    # Truy vết: FR-17-054 · API-17-164, 165, 166, 167 · BR-17-072 · ERR-17-078 · UI-17-18
    # Mục đích: Chứng minh BR-17-072.
    Biết T90 bật; U-T90-TA1, U-T90-SO, U-T90-AU.
    Khi TA1 `POST /ai-system-records` thiếu mục "biện pháp" và "người chịu trách nhiệm".
    Và TA1 `POST /ai-system-records` đủ mục.
    Và đổi mô hình hội thoại mặc định sang `MV-CHAT-2`; `GET /ai-system-records`.
    Và SO `POST /ai-system-records/{id}:review`.
    Và AU `GET /ai-system-records`.
    Thì bước 1 `422` ERR-17-078 nêu mục thiếu. Bước 2 `201`. Bước 3 phần mô hình, dữ liệu tự cập nhật đúng `MV-CHAT-2`, đánh dấu cần rà soát. Bước 4 ghi nhận rà soát, KT: có. Bước 5 AU đọc được.

  @TC-17-102 @P3 @Âm @Bảo_mật
  Kịch bản: TC-17-102 Quyền ghi sổ đăng ký
    # Truy vết: FR-17-054 · API-17-165, 166 · ERR-00-403
    # Mục đích: Chứng minh chỉ người có `PERM-17-admin` ghi sổ.
    Biết U-T90-IE, U-T90-AU.
    Khi IE `POST /ai-system-records`.
    Và AU `PATCH /ai-system-records/{id}`.
    Thì cả hai `403` ERR-00-403.
