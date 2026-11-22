---
ma_tai_lieu: ADR-037
ten: Quy trình Git trunk-based, Conventional Commits, review bắt buộc, cổng chất lượng CI
phien_ban: 0.1
ngay: 2026-11-21
trang_thai: Đề xuất
nguoi_doc: Kiến trúc sư, Trưởng nhóm kỹ thuật, Đội phát triển, Đội ATTT, Hội đồng thẩm định
---

# ADR-037 · Quy trình Git trunk-based, Conventional Commits, review bắt buộc, cổng chất lượng CI

## Bối cảnh

Datahub là một monorepo chứa sáu DU Spring Boot, một DU Camel Quarkus, giao diện và thư viện dùng chung, cùng một kho GitOps chứa manifest và luồng tích hợp theo tenant. Nhiều nhóm phân hệ phát triển song song; sản phẩm phải phát hành thường xuyên cho nhiều tỉnh, kể cả tỉnh on-prem không nâng cấp đồng thời. Hệ thống được thiết kế đạt ATTT cấp độ 3 theo Nghị định 331/2026/NĐ-CP và TCVN 14423:2026, trong đó cấp độ 3 có thêm nhóm yêu cầu phát triển ứng dụng an toàn; NFR-00-022, 023, 024, 053, 054, 055 đặt ngưỡng đo được cho bí mật, lỗ hổng, ASVS, độ phủ, ranh giới module và tương thích API. Một lỗi lập trình về tenant có thể làm lộ dữ liệu giữa các tỉnh (D03-10).

Kho mã hiện tại đã có CI tối thiểu (biên dịch, kiểm thử đơn vị, `ApplicationModules.verify()`, gitleaks) theo Gate A và Gate S của IP-02, nhưng chưa có SAST, SCA, quét ảnh, lint hợp đồng, kiểm thử giao diện, CODEOWNERS hay quy ước commit được kiểm tra; action CI được ghim theo thẻ trôi. Cần một quyết định chung về mô hình nhánh, quy ước commit, quy tắc duyệt và tập cổng chất lượng để D04-01 và D04-02 có nền thống nhất.

## Các phương án

Bảng dưới đây so sánh ba phương án mô hình nhánh, mỗi phương án đi kèm cách tổ chức duyệt và CI tương ứng.

| Phương án | Ưu điểm | Nhược điểm |
|---|---|---|
| A. Git Flow (`develop`, `release/*`, `feature/*` dài ngày, `hotfix/*`) | Quen thuộc; tách rõ mã đang phát triển và mã phát hành | Nhánh sống lâu gây xung đột tích tụ và lỗi tích hợp muộn giữa module; CI kiểm tra thứ không phải thứ sẽ phát hành; chậm phát hành; nhiều nhánh cần bảo vệ |
| B. **Trunk-based: nhánh ngắn ≤ 3 ngày vào `main`, squash merge, cờ tính năng; nhánh `release/X.Y` chỉ để vá dòng cũ; Conventional Commits; review bắt buộc theo CODEOWNERS và mức rủi ro; chín cổng CI chặn merge** | Tích hợp liên tục thật sự; `main` luôn phát hành được; lịch sử tuyến tính dễ truy vết; số phiên bản và changelog sinh tự động từ commit; cổng CI áp lên chính thứ sẽ phát hành | Đòi hỏi kỷ luật chia nhỏ việc và cờ tính năng; CI phải nhanh và ổn định; `main` đỏ ảnh hưởng mọi người |
| C. Mỗi phân hệ một kho mã riêng, mỗi kho tự chọn quy trình | Nhóm tự chủ | Mất kiểm tra ranh giới module của Spring Modulith; khó phát hành bộ đồng nhất cho tỉnh; quy trình không thống nhất, khó làm bằng chứng cấp độ |

Về quy ước commit, phương án tự do (chỉ yêu cầu "nêu vì sao" như IP-02) được so với Conventional Commits; Conventional Commits được ưu tiên vì máy đọc được, cho phép sinh số phiên bản SemVer và changelog tự động, và commitlint kiểm tra được. Về cổng chất lượng, phương án "cảnh báo, người duyệt quyết định" được so với "chặn merge theo ngưỡng"; phương án chặn được ưu tiên vì các ngưỡng đã là yêu cầu đo được trong D02-02.

## Quyết định

Chọn **phương án B**, với các nội dung sau, đặc tả chi tiết ở D04-02:

1. Một nhánh dài hạn `main`, được bảo vệ (cấm đẩy trực tiếp và đẩy ép, áp dụng cả quản trị viên); nhánh ngắn đặt tên `{loại}/{mã-việc}-{mô-tả}` theo D00-01 §6, sống tối đa 3 ngày làm việc; hợp nhất bằng squash; commit có chữ ký được xác minh.
2. Thông điệp commit và tiêu đề PR theo Conventional Commits 1.0, bổ sung loại `sec` và chân `Refs:` bắt buộc mã truy vết với `feat`, `fix`, `sec`; kiểm tra bằng commitlint.
3. Mọi thay đổi qua PR nhỏ (≤ 400 dòng khuyến nghị, ≤ 800 tối đa) có mẫu mô tả và liên kết FR/US/NFR/ADR; tối thiểu 2 người duyệt với mã chạy, trong đó 1 CODEOWNER phân hệ, cộng người duyệt bảo mật khi PR có nhãn `security-impact` hoặc `tenant-impact`; SLA phản hồi 4 giờ làm việc cho PR nhỏ.
4. Chín cổng CI CI-1–CI-9 chặn merge: build và kiểm tra tĩnh; kiểm thử đơn vị, Modulith verify, ArchUnit, lint migration; kiểm thử tích hợp có kiểm thử rò rỉ chéo tenant; độ phủ (NFR-00-053); hợp đồng (Spectral, oasdiff, Apicurio); giao diện (lint, kiểu, không CSS tự do); bảo mật (Semgrep, CodeQL hoặc FindSecBugs, SCA, gitleaks, quét IaC); ảnh container (Trivy); E2E với axe-core và Lighthouse. Không ai được bỏ qua cổng; ngoại lệ chỉ qua nhãn `gate-override` có lý do và được ghi nhận.
5. Phát hành theo SemVer, số phiên bản và changelog sinh từ commit; ảnh ký cosign, có SBOM CycloneDX và chứng thực nguồn gốc SLSA, cụm chỉ chạy ảnh đã ký; phụ thuộc ghim chính xác và cập nhật bằng Renovate.
6. Sửa nóng vẫn qua PR và các cổng tự động, chỉ rút ngắn thời gian duyệt (1 người trước, 1 người hậu kiểm), bắt buộc kiểm thử tái hiện.
7. Luồng Camel theo tenant đi vào runtime chỉ qua commit vào kho GitOps do `dh-integration` tạo sau khi duyệt, được CI kho GitOps kiểm tra cùng bộ luật như luồng viết tay.

Hệ cổng CI-1–CI-9 thay cho Gate A, B, C, D, S của IP-02; bảng đối chiếu ở D04-02 §6.3.

## Hệ quả

**Tích cực.** `main` luôn ở trạng thái phát hành được, rút ngắn thời gian từ yêu cầu tới production. Các quy tắc [tự động] của D04-01 có nơi thực thi cụ thể. Lịch sử Git có chữ ký, mã truy vết và người duyệt trở thành bằng chứng cho nhóm yêu cầu phát triển ứng dụng an toàn, quản lý cấu hình và quản lý lỗ hổng khi lập hồ sơ cấp độ (D03-08). Chuỗi cung ứng có chữ ký và SBOM sẵn sàng cho gói air-gapped (ADR-036) và cho nâng cấp độ 4.

**Tiêu cực và rủi ro.** Đội phải học cách chia nhỏ việc và dùng cờ tính năng; giai đoạn đầu số PR tăng. CI phải được đầu tư để giữ phản hồi ≤ 15 phút, cần runner có đủ tài nguyên cho Testcontainers và build native. Các công cụ quét mới sẽ phát hiện nhiều vấn đề trên mã hiện có; xử lý bằng đường cơ sở phát hiện và chế độ chặn theo phần thay đổi (D04-01 §10). Cần nhân sự đóng vai trò người duyệt bảo mật ở mỗi nhóm. Lựa chọn nền tảng Git (GitHub hay GitLab tự vận hành) và giấy phép CodeQL còn mở (Q353, Q355).

**Việc phải làm.** Tạo `CODEOWNERS`, mẫu PR, cấu hình commitlint, `renovate.json`, luật bảo vệ nhánh; bổ sung các cổng còn thiếu vào quy trình CI hiện có và ghim action theo SHA; đưa hai mô-đun Camel vào reactor Maven; cập nhật `AGENTS.md` trỏ tới D04-01 và D04-02.

## Trạng thái

Đề xuất.

## Truy vết

NFR-00-022, NFR-00-023, NFR-00-024, NFR-00-040, NFR-00-045, NFR-00-053, NFR-00-054, NFR-00-055; FR-00-011; ADR-001, ADR-009, ADR-010, ADR-012, ADR-036, ADR-038; D03-10 §6; D04-01; D04-02; SEC-40–49 và SEC-50–59 (D03-07). Kế thừa và thay thế phần quy trình (mục 6, 7) của IP-02 và mục 7 (DoD) của `AGENTS.md` trong kho mã; không có ADR tương ứng trong `docs/05-adr` của repo.
