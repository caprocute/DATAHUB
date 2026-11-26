# Số đo lát cắt mẫu F-07-010 · 26/11/2026

> Thử trọn quy trình "gói đặc tả máy đọc → phiên viết → phiên đánh giá độc lập → cổng G1–G6"
> trên một tính năng PH-07 (FR-07-010 Quản lý nhóm danh mục, API-07-007…010, khung cây
> UI-07-01). Số đo dùng để quyết định nhân rộng (bước 4 của báo cáo tư vấn).

## 1. Thời gian và lượt làm

| Pha | Ai làm | Giờ UTC | Thời gian | Lượt gọi công cụ | Ngữ cảnh cuối |
|---|---|---|---|---|---|
| Dựng công cụ và gói đặc tả PH-07 | Phiên điều phối (Opus 5.5) | 15:46–16:02 | 16 phút | ~45 | — |
| Viết mã vòng 1 | Tác nhân viết (Sonnet 5.5) | 16:02–16:50 | 48 phút | 135 | ~210 nghìn token |
| Đánh giá vòng 1 | Tác nhân đánh giá (Sonnet 5.5, ngữ cảnh riêng) | 16:51–17:00 | 10 phút | 37 | ~162 nghìn |
| Viết mã vòng 2 (sửa lỗi) | Tác nhân viết | 17:00–17:07 | 7 phút | 13 | ~233 nghìn |
| Đánh giá vòng 2 | Tác nhân đánh giá | 17:08–17:15 | 6 phút | 13 | ~183 nghìn |
| **Tổng tới khi G1–G4 xanh, không lỗi Cao** | | | **~1 giờ 30 phút** | ~245 | |

Ước tính chi phí nếu chạy bằng API (giá Sonnet 5.5: 2 US$/1 triệu token vào, 10 US$ ra, 0,10 US$ đọc cache): tác nhân viết khoảng 4–7 US$, tác nhân đánh giá khoảng 1–2 US$, phiên điều phối dựng gói (Opus) khoảng 3–5 US$. **Tổng khoảng 8–14 US$ cho một tính năng cỡ M.** Đây là **ước tính** từ số lượt và cỡ ngữ cảnh (lượt chạy trong phiên Claude Code, không qua Console nên không có hóa đơn từng lượt); sai số có thể ±50%.

## 2. Sản phẩm

| Hạng mục | Số liệu |
|---|---|
| Backend `dh-data` | Java chính 2.538 dòng, test 2.202 dòng; 47 test đơn vị + 40 tích hợp (Cucumber 14 kịch bản, rò rỉ chéo tenant 6, RLS 4, API 16); JaCoCo dòng `rdm` 97,6%, `shared` 92,5% |
| Web | `@datahub/ui`, `api-client`, `i18n`, `apps/console` ≈ 4.100 dòng; Vitest 54 test, phủ dòng 91,25%; ESLint 0 cảnh báo |
| E2E | Playwright 10 test + axe 0 vi phạm A/AA; tự dựng PostgreSQL 18 + backend + console |
| Gói đặc tả | tóm tắt 146 dòng, 13 quyết định sẵn sàng, Gherkin 14 kịch bản, 53 tính năng trong `features.json` |
| Công cụ dùng lại | `cat_lat_openapi.py`, `sinh_features.py`, `g1_dac_ta.py`, `g5_bao_mat.sh`, `cong.sh`, CI `datahub-code.yml`, khuôn K-GOI-DAC-TA |

## 3. Lỗi bị bắt, theo cổng

| Cổng | Bắt được gì | Nếu không có cổng |
|---|---|---|
| G1 (chạy thật hợp đồng, DDL) | OpenAPI nguồn không đọc được (khóa trùng) và 5 lỗi cấu trúc; Gherkin nguồn là văn xuôi không chạy được; RLS với kết nối pool không báo lỗi như tài liệu ghi (SS-07-07); sau khi PR #37 sửa nguồn, G1 tự báo vá thừa | Sinh mã từ hợp đồng hỏng hoặc test RLS dựa vào giả định sai |
| Kiểm sẵn sàng (đọc chéo) | 6 mâu thuẫn FRS ↔ OpenAPI ↔ DDL ↔ D02-08 (quyền, mã lỗi vòng, xóa mềm, mã lỗi kiểm tra, tiền điều kiện TC, `createdBy`) | Tác nhân viết tự chọn, mỗi lần một kiểu |
| G2–G4 tự động | Phiên viết tự chạy và tự sửa trước khi báo xong (số lần đỏ trong phiên không đếm) | — |
| Phiên đánh giá độc lập | **1 lỗi Cao mà mọi test tự động đều xanh**: khung cây nhóm tràn, nút "Thêm nhóm" không bấm được khi ~30 nhóm (luật bố cục CC-FE-14); 3 lỗi Thấp (POST ép số thành chuỗi, `px` viết cứng, PATCH rỗng); 1 test E2E chập chờn; phát hiện cổng G5 báo sai "có phát hiện" khi Semgrep không tải được luật | Lỗi Cao lọt vào mã mẫu và bị nhân bản sang mọi màn hình sau |
| G5 trên CI (PR #39) | Semgrep 0 phát hiện; **Trivy: 39 lỗ hổng (11 CRITICAL, 28 HIGH)** vì tác nhân viết chọn Spring Boot 4.0.2 cũ (Tomcat, Spring Security, Jackson, pgjdbc). Nâng 4.0.10, 87 test vẫn xanh. Gitleaks báo nhầm 5 chuỗi `Idempotency-Key` giả trong test | Mã mẫu mang lỗ hổng biết trước vào mọi phân hệ sau |
| CI lần đầu | Test E2E chập chờn T5 lặp lại: chờ `getAnimations()` rỗng treo khi có hiệu ứng lặp vô hạn; sửa chỉ chờ hiệu ứng hữu hạn. Hai lỗi hạ tầng CI: tag `trivy-action` không còn, Maven Central trả 429 cho Trivy | — |
| G6 người | henry duyệt 26/11 18:35 UTC sau khi PR #39 merge; cờ `passes` của F-07-010 lật trong PR riêng | — |

Hơn 40 ca phá ngoài Gherkin (JWT giả, `alg: none`, header tenant giả, `Idempotency-Key` chéo tenant, 8 PATCH song song cùng ETag, cha khác tenant…) đều đạt ngay vòng 1.

## 4. Bài học

1. **Chạy thật hợp đồng là việc rẻ nhất và lời nhất.** 16 phút dựng G1 bắt 7 lỗi mà bộ tài liệu đã qua nhiều lượt rà chéo bằng mắt không thấy.
2. **Tác nhân đánh giá độc lập là bắt buộc, không phải trang trí.** Phiên viết báo "mọi cổng xanh" thật, nhưng sản phẩm có lỗi chặn người dùng. Lỗi nằm ngoài vùng test của chính tác nhân viết (dữ liệu ít). Đánh giá bằng mắt (ảnh chụp) và dữ liệu cỡ thật mới lộ ra.
3. **Vòng sửa rất rẻ** (7 phút, 13 lượt) khi phát hiện có tệp:dòng và cách tái hiện. Chi phí nằm ở vòng 1.
4. **Gói đặc tả nhỏ đủ dùng.** Tác nhân viết chỉ cần 146 dòng tóm tắt + 13 quyết định + lát cắt 616 dòng + Gherkin; không phải đọc FRS 470 KB. Không có câu hỏi nào vào `hang-cho.md`.
5. **Rào chắn hoạt động cả với chính quy trình.** Bộ phân loại quyền chặn tác nhân đánh giá tự lật cờ `passes` (lý do "làm suy yếu giám sát"). Nghĩa là trong cấu hình hiện tại, cờ `passes` chỉ nên được lật bởi người (G6) hoặc bởi workflow CI sau khi mọi cổng xanh, không bởi tác nhân trong phiên. Khuôn đã ghi theo hướng này.
6. **Cổng phải phân biệt "không chạy được" với "đạt"/"trượt"** (G5 Semgrep). Cổng im lặng khi hỏng còn tệ hơn không có cổng.
7. **Khuôn phải ghim phiên bản mới nhất đã vá cho tác nhân.** Tác nhân chọn phiên bản theo trí nhớ huấn luyện, nên ra bản cũ có CVE. Hiến chương `datahub/AGENTS.md` nên ghi phiên bản chốt, và Trivy phải chạy được ngay trong phiên viết.
8. **Đặt tên biến không chứa `key`, `token`, `secret` cho giá trị test giả**, nếu không gitleaks quét lịch sử PR sẽ chặn.
9. **Phạm vi chưa phủ** của lát cắt này: APISIX, máy chủ định danh và OPA thật, Kafka và Debezium (mới tới outbox), Helm, bảng danh mục F-07-001. Lát cắt tiếp theo nên là F-07-001/003 (danh sách, tạo danh mục) để phủ bảng ProTable và luồng nhiều bước.

## 5. Ước tính khi nhân rộng (giả định, hiệu chỉnh sau 3–5 tính năng)

| Đại lượng | Ước từ lát cắt này |
|---|---|
| Mỗi tính năng cỡ S/M (đã có mã mẫu) | 5–10 US$, 30–60 phút máy, 1–2 vòng |
| Mỗi tính năng cỡ L | 15–30 US$, 2–3 vòng |
| PH-07 (41 S, 12 M theo `features.json`) | khoảng 350–700 US$ API, chưa tính tích hợp và người duyệt |
| Người | duyệt PR mẫu mỗi phân hệ, mọi thay đổi `spec/`, test, thư viện chung; xử lý `hang-cho.md` |

Khớp với khoảng 300–1.500 US$/phân hệ của báo cáo tư vấn, nghiêng về đầu thấp với phân hệ CRUD, đầu cao với phân hệ có luồng nền, tích hợp ngoài (PH-04, PH-14, PH-19).
