---
ma_tai_lieu: D05-01
ten: Kế hoạch kiểm thử tổng thể (Master Test Plan)
phien_ban: 0.2
ngay: 2026-11-26
trang_thai: Dự thảo
nguoi_doc: Quản lý dự án, Trưởng nhóm kiểm thử, Kiểm thử viên, Trưởng nhóm kỹ thuật, Kiến trúc sư, Vận hành, Chủ đầu tư, Hội đồng thẩm định
mo_ta: Kế hoạch kiểm thử cấp cao nhất của Datahub theo ISO/IEC/IEEE 29119-3, chốt đối tượng, chiến lược theo rủi ro, mức và loại kiểm thử, cổng phát hành RG-1 đến RG-5, môi trường, dữ liệu, tổ chức và lịch kiểm thử.
tai_lieu_lien_quan: D00-01 Thuật ngữ và quy ước; D00-03 Ma trận truy vết; D02-01 BRD; D02-02 SRS; D03-01 SAD; D03-07 Thiết kế ATTT; D03-09 Hạ tầng và DR; D03-10 Thiết kế đa tenant; D05-02; D05-03; D05-04; D05-05
---

# D05-01 · Kế hoạch kiểm thử tổng thể (Master Test Plan)

## Tóm tắt cho hội đồng thẩm định

**Mục tiêu.** Tài liệu chốt cách Datahub được kiểm thử trước khi đưa vào vận hành: kiểm thử cái gì, đến mức nào, bằng công cụ và môi trường nào, ai làm và khi nào. Đây là kế hoạch kiểm thử cấp cao nhất; các kế hoạch chuyên đề về test case, hiệu năng, bảo mật và chấp nhận kế thừa và chỉ được chặt hơn.

**Phạm vi.** Toàn bộ vòng đời kiểm thử từ mốc khởi động T0 đến khi đợt 3 được nghiệm thu, cho 20 phân hệ và cả hai hồ sơ triển khai (tỉnh độc lập, nền tảng dùng chung). Tài liệu gồm chiến lược dựa trên rủi ro, bảy mức và mười lăm loại kiểm thử, tiêu chí vào, ra cùng năm cổng phát hành `RG-1` đến `RG-5`, môi trường, dữ liệu kiểm thử, tự động hóa, quản lý lỗi, chỉ số, tổ chức, lịch và ma trận truy vết từng yêu cầu phi chức năng tới phương pháp kiểm chứng. Hạ tầng phần cứng và hệ thống của bên thứ ba không thuộc phạm vi.

**Căn cứ.** STD-02 (ISO/IEC/IEEE 29119-3: cấu trúc kế hoạch kiểm thử), STD-03 (OWASP ASVS 5.0 mức 2: kiểm thử bảo mật ứng dụng), STD-04 (WCAG 2.2 mức AA: kiểm thử khả năng truy cập); CMP-LAW-06 và CMP-LAW-08 (Nghị định 331/2026/NĐ-CP, TCVN 14423:2026: kiểm tra an ninh mạng định kỳ và phát triển ứng dụng an toàn ở cấp độ 3); CMP-LAW-16 (Luật An ninh mạng 116/2025/QH15); CMP-LAW-05 và CMP-LAW-04 (Luật Bảo vệ dữ liệu cá nhân 91/2025/QH15, Nghị định 356/2025/NĐ-CP: cấm dùng dữ liệu cá nhân thật trong môi trường kiểm thử nếu không có căn cứ).

**Những điểm hội đồng cần lưu ý.** (1) Công sức kiểm thử được phân bổ theo rủi ro sản phẩm chứ không chia đều: 21 rủi ro `RSK-T01…21` được chấm ảnh hưởng nhân khả năng, năm rủi ro điểm cao nhất (cách ly tenant, bảo mật API, thanh toán, di trú, chạy song song strangler) nhận cường độ kiểm thử sâu nhất. (2) Mọi yêu cầu phi chức năng của SRS có một dòng trong ma trận ở chương 17 gắn với loại kiểm thử, công cụ, môi trường và cổng, nên không có chỉ tiêu nào để ngỏ phương pháp kiểm chứng. (3) Kiểm thử rò rỉ chéo tenant là bắt buộc, tự sinh theo mọi endpoint, kỳ vọng `404`, chặn merge khi không đạt. (4) Cổng `RG-1` đến `RG-5` là cổng kỹ thuật, là đầu vào cho cổng quản lý dự án chứ không thay thế; mỗi cổng có người quyết định rõ, riêng `RG-4` do chủ đầu tư quyết định. (5) Môi trường kiểm thử không dùng dữ liệu cá nhân thật; dữ liệu là tổng hợp hoặc đã che, có dữ liệu canary để phát hiện rò rỉ. (6) Lịch ở chương 14 là giả định theo mốc T0 và còn phụ thuộc các câu hỏi mở ở chương 21 (sandbox PayGov, môi trường thử NDXP, đơn vị kiểm thử xâm nhập độc lập, đối chiếu TCVN 14423:2026).

**Con số chính.**

| Chỉ số | Giá trị |
|---|---|
| Phân hệ là đối tượng kiểm thử | 20 (`PH-01…20`), cộng thành phần xuyên suốt mã `PH-00` |
| Mức kiểm thử | 7 (đơn vị, tích hợp module, tích hợp hệ thống, hợp đồng, đầu–cuối, hệ thống, chấp nhận) |
| Tỷ lệ tháp kiểm thử | Khoảng 60% đơn vị, 10% module, 15% tích hợp hệ thống, 10% hợp đồng, 5% đầu–cuối |
| Rủi ro sản phẩm và rủi ro hoạt động kiểm thử | 21 (`RSK-T01…21`) và 8 (`RSK-T30…37`) |
| Cổng phát hành | 5 (`RG-1…5`), cổng PR dùng lại Gate A, B, C, D, S |
| Môi trường phi sản xuất | 5 (DEV, TEST, STAGING, PERF, UAT) |
| Thí nghiệm kiểm thử hỗn loạn | 8 (`CX-01…08`) |
| Yêu cầu phi chức năng có dòng truy vết ở chương 17 | 42 |
| Ngưỡng độ phủ mã | Không dưới 80% backend, 70% giao diện (NFR-00-053) |
| Độ phủ kiểm thử rò rỉ chéo tenant | 100% endpoint không miễn trừ |
| Mức lỗi chặn phát hành | 0 lỗi S1 và S2 mở tại `RG-2` (với tính năng trong bản) và `RG-4` |
| Lịch | 18 tháng kể từ T0, `RG-4` đợt 3 ở T0 + 18 |

: Con số chính của kế hoạch kiểm thử tổng thể

Các con số trên lấy từ chương 2, 3, 4, 6, 7, 11, 14 và 17 của tài liệu này; số mục truy vết và số rủi ro có thể tăng khi D05-02 đến D05-05 được viết.

## 1. Giới thiệu

### 1.1. Mục đích

Tài liệu này là kế hoạch kiểm thử cấp cao nhất của dự án Datahub. Nó trả lời bốn câu hỏi mà mọi kế hoạch kiểm thử theo ISO/IEC/IEEE 29119-3 phải trả lời: **kiểm thử cái gì** (hạng mục và phạm vi), **kiểm thử đến mức nào** (chiến lược dựa trên rủi ro, mức và loại kiểm thử, tiêu chí vào và ra), **kiểm thử bằng gì và ở đâu** (công cụ, môi trường, dữ liệu kiểm thử) và **ai làm, khi nào** (tổ chức, vai trò, lịch theo mốc). Mọi kế hoạch kiểm thử chuyên đề phía sau — test case theo phân hệ (D05-02), kế hoạch kiểm thử hiệu năng (D05-03), kế hoạch kiểm thử bảo mật (D05-04) và kế hoạch kiểm thử chấp nhận (D05-05) — kế thừa các quyết định ở đây và chỉ được chặt hơn, không được lỏng hơn.

Kế hoạch phục vụ hội đồng thẩm định, quản lý dự án, chủ đầu tư, đội phát triển và đội kiểm thử; từng nhóm người đọc cần đọc phần nào được nêu ở mục 1.6.

### 1.2. Phạm vi tài liệu

Tài liệu bao phủ toàn bộ vòng đời kiểm thử của sản phẩm Datahub từ mốc khởi động T0 tới khi đợt 3 được nghiệm thu, cho cả hai hồ sơ triển khai (tỉnh độc lập on-prem và nền tảng dùng chung trên cloud Chính phủ, D03-01 §10). Kiểm thử của hạ tầng phần cứng, đường truyền và hệ thống của bên thứ ba (NDXP, PayGov, HTTT của sở) không thuộc phạm vi; Datahub chỉ kiểm thử phần tích hợp với chúng thông qua giả lập và môi trường thử của bên cung cấp.

Tài liệu không chứa test case chi tiết. Test case nằm ở D05-02, mỗi phân hệ một tập. Kịch bản tải chi tiết nằm ở D05-03; kịch bản kiểm thử xâm nhập và bảng kiểm ASVS chi tiết nằm ở D05-04; kịch bản UAT và biên bản nghiệm thu nằm ở D05-05.

### 1.3. Căn cứ và tài liệu tham chiếu

Kế hoạch được lập dựa trên các tài liệu và tiêu chuẩn dưới đây. Bảng cho biết mỗi căn cứ chi phối phần nào của kế hoạch, để khi căn cứ thay đổi người đọc biết phải rà lại mục nào.

| Căn cứ | Nội dung chi phối kế hoạch | Mục bị ảnh hưởng |
|---|---|---|
| D02-01 BRD | Mục tiêu `BO`, chỉ số `KPI-01…18`, yêu cầu `REQ-01…22`, phân đợt MVP / đợt 2 / đợt 3, tiêu chí thành công §11 | 2, 3, 6, 14 |
| D02-02 SRS | Yêu cầu dùng chung `FR-00-001…093`, phi chức năng `NFR-00-001…062` kèm phương pháp đo, hồ sơ quy mô "tỉnh vừa" | 5, 17 |
| D03-01 SAD | Phân hệ, đơn vị triển khai (DU), control/data plane, mẫu tích hợp, rủi ro kiến trúc `RSK-A01…A05` | 2, 3, 4 |
| D03-10 Thiết kế đa tenant | Cơ chế cách ly theo tầng, quy tắc phát triển §6 (quy tắc 6: kiểm thử rò rỉ chéo tenant, kỳ vọng `404`), saga khởi tạo tenant | 5.6 |
| D03-07 Thiết kế ATTT | Danh mục biện pháp `SEC-nn` theo cấp độ 3 | 5.5 |
| D03-09 Hạ tầng, triển khai, DR | Hồ sơ quy mô, quy trình diễn tập DR hằng quý, kiến trúc hai site | 5.3, 5.4, 7 |
| D00-01 Thuật ngữ và quy ước | Mã `TS-{PH}-{nn}`, `TC-{PH}-{nnn}`, quy tắc truy vết §3.2 (quy tắc 4: FR mức M có ít nhất hai TC dương và âm) | 12 |
| D00-03 Ma trận truy vết | 183 mục `LGC` của hệ cũ và kết luận Giữ nguyên / Nâng cấp / Thay thế / Loại bỏ | 5.1, 5.9 |
| ISO/IEC/IEEE 29119-3 (STD-02) | Cấu trúc tài liệu kế hoạch kiểm thử | Toàn tài liệu |
| OWASP ASVS 5.0 mức 2, OWASP API Security Top 10 2023 | Tiêu chí kiểm thử bảo mật ứng dụng và API (NFR-00-024) | 5.5 |
| WCAG 2.2 mức AA (STD-04) | Tiêu chí kiểm thử khả năng truy cập (NFR-00-040…045) | 5.7 |
| Luật An ninh mạng 116/2025/QH15, Nghị định 331/2026/NĐ-CP, TCVN 14423:2026 | Yêu cầu kiểm tra an ninh mạng định kỳ ở cấp độ 3 (nhóm "quản lý kiểm tra an ninh mạng" và "phát triển ứng dụng an toàn"; số mục cụ thể cần đối chiếu) | 5.5, 6 |
| Luật Bảo vệ dữ liệu cá nhân 91/2025/QH15, Nghị định 356/2025/NĐ-CP | Cấm dùng dữ liệu cá nhân thật trong môi trường kiểm thử nếu không có căn cứ; che dữ liệu | 8 |
| `docs/08-implementation/04-ke-hoach-phat-trien.md`, `02-huong-dan-lap-trinh.md` (repo) | Các wave W0–W6, lane `L-QA`, cổng CI hiện có Gate A/B/C/D/S | 9, 14 |

: Căn cứ pháp lý, tiêu chuẩn và tài liệu chi phối kế hoạch kiểm thử

> **Câu hỏi mở Q360:** Các nhóm yêu cầu "quản lý kiểm tra an ninh mạng" và "phát triển ứng dụng an toàn" ở cấp độ 3 của TCVN 14423:2026 (dự kiến mục 5.17 và 5.18) chưa được đối chiếu toàn văn. Cần xác nhận tần suất kiểm tra, đánh giá an ninh mạng bắt buộc (ví dụ kiểm thử xâm nhập trước vận hành và định kỳ hằng năm) để chốt lịch ở mục 14 và D05-04.

### 1.4. Quan hệ với các tài liệu kiểm thử khác

Bộ tài liệu kiểm thử được tổ chức thành năm tài liệu. Sơ đồ dưới đây cho thấy chiều kế thừa và chiều cung cấp bằng chứng giữa chúng.

```{.mermaid caption="Quan hệ giữa D05-01 và các tài liệu kiểm thử khác"}
flowchart TB
  SRS[D02-02 SRS<br/>FR-00, NFR-00] --> MTP
  FRS[D02-03 FRS 20 tập<br/>FR-PH, BR-PH] --> TC
  SAD[D03-01 SAD, D03-10 đa tenant<br/>D03-07 ATTT, D03-09 hạ tầng] --> MTP
  MTP[D05-01 Master Test Plan<br/>chiến lược, mức, cổng, môi trường]
  MTP --> TC[D05-02 Kịch bản và test case<br/>TS-PH-nn, TC-PH-nnn]
  MTP --> PERF[D05-03 Kế hoạch kiểm thử hiệu năng<br/>kịch bản k6, hồ sơ tải]
  MTP --> SECT[D05-04 Kế hoạch kiểm thử bảo mật<br/>ASVS, pentest, SEC-nn]
  MTP --> UAT[D05-05 Kế hoạch UAT<br/>kịch bản nghiệp vụ, biên bản]
  TC --> RTM[D00-03 RTM<br/>cột TC]
  PERF & SECT & UAT --> BC[Bằng chứng cổng phát hành RG-n]
  TC --> BC
```

Sơ đồ cho thấy D05-01 đứng giữa phần yêu cầu, thiết kế và các tài liệu kiểm thử chuyên đề. D05-02 nhận yêu cầu chức năng từ FRS nhưng nhận quy ước, mức kiểm thử và tiêu chí ra từ D05-01; mỗi test case khi được viết xong cập nhật cột TC trong RTM. D05-03, D05-04 và D05-05 chi tiết hóa ba loại kiểm thử có quy trình và bên tham gia riêng (đội hiệu năng, đơn vị kiểm thử bảo mật độc lập, người dùng nghiệp vụ của tỉnh). Kết quả của cả bốn tài liệu là bằng chứng để mở các cổng phát hành `RG-n` định nghĩa ở mục 6.

Phân chia trách nhiệm cụ thể giữa các tài liệu được ghi ở bảng dưới đây; nguyên tắc chung là D05-01 quyết định "làm gì và đạt bao nhiêu", tài liệu chuyên đề quyết định "làm cụ thể ra sao".

| Tài liệu | D05-01 quyết định | Tài liệu chuyên đề quyết định |
|---|---|---|
| D05-02 Test case | Quy ước mã, mẫu test case, số TC tối thiểu theo mức ưu tiên FR, kỹ thuật thiết kế bắt buộc | Từng `TS`, `TC` cụ thể, dữ liệu đầu vào, kết quả mong đợi |
| D05-03 Hiệu năng | Chỉ tiêu từ NFR-00-001…008, 060…062; hồ sơ "tỉnh vừa"; môi trường PERF; loại kiểm thử tải bắt buộc | Kịch bản k6, mô hình tải chi tiết, cách sinh dữ liệu khối lượng lớn, phân tích nút thắt |
| D05-04 Bảo mật | Phạm vi ASVS 5.0 L2, công cụ SAST/DAST, bộ kiểm thử rò rỉ chéo tenant, tần suất pentest, ngưỡng chặn | Bảng kiểm ASVS từng mục, kịch bản pentest, ánh xạ chi tiết `SEC-nn` → ca kiểm thử |
| D05-05 UAT | Tiêu chí vào/ra UAT, vai trò người dùng tham gia, gắn với KPI "Từ nghiệm thu" | Kịch bản nghiệp vụ theo `BP`, lịch buổi UAT, mẫu biên bản |

: Phân chia quyết định giữa D05-01 và các tài liệu kiểm thử chuyên đề

### 1.5. Thuật ngữ dùng trong tài liệu

Tài liệu dùng thuật ngữ đã định nghĩa ở D00-01. Một số thuật ngữ kiểm thử dưới đây chưa có trong D00-01 và được đề xuất bổ sung (mục 20).

| Thuật ngữ | Tiếng Anh | Nghĩa trong tài liệu này |
|---|---|---|
| Mức kiểm thử | Test level | Nhóm hoạt động kiểm thử theo phạm vi đối tượng: đơn vị, tích hợp module, tích hợp hệ thống, hợp đồng, đầu–cuối, hệ thống, chấp nhận |
| Loại kiểm thử | Test type | Nhóm hoạt động kiểm thử theo đặc tính chất lượng: chức năng, hiệu năng, bảo mật, khả năng truy cập… |
| Tháp kiểm thử | Test pyramid | Phân bổ số lượng kiểm thử: nhiều kiểm thử đơn vị nhanh ở đáy, ít kiểm thử đầu–cuối chậm ở đỉnh |
| Kiểm thử hợp đồng | Contract testing | Kiểm tra bên cung cấp và bên dùng một API hoặc sự kiện cùng tuân thủ một hợp đồng (OpenAPI, AsyncAPI, schema) mà không cần chạy cả hai cùng lúc |
| Kiểm thử rò rỉ chéo tenant | Cross-tenant leakage test | Ca kiểm thử tạo dữ liệu ở tenant A rồi truy cập bằng danh tính của tenant B, kỳ vọng không đọc, sửa, xóa, liệt kê hay suy ra được dữ liệu (D03-10 §6) |
| Kiểm thử hỗn loạn | Chaos engineering / chaos test | Chủ động gây lỗi hạ tầng (tắt pod, nút, mạng) trong môi trường kiểm soát để kiểm chứng khả năng chịu lỗi |
| Lưu lượng bóng | Shadow traffic | Bản sao lưu lượng thật của hệ cũ được gửi song song tới hệ mới; kết quả của hệ mới chỉ dùng để so sánh, không trả cho bên gọi |
| Kiểm thử hồi quy giao diện | Visual regression test | So sánh ảnh chụp giao diện với ảnh chuẩn đã duyệt để phát hiện thay đổi hiển thị ngoài ý muốn |
| Cổng phát hành | Release gate | Điểm kiểm soát chất lượng mà một bản dựng phải vượt qua trước khi được đưa lên môi trường hoặc giai đoạn tiếp theo; mã `RG-n` |
| Kiểm thử khói | Smoke test | Bộ kiểm thử ngắn kiểm tra các chức năng thiết yếu còn chạy sau khi triển khai |
| Ca kiểm thử bất ổn | Flaky test | Ca kiểm thử cho kết quả khác nhau qua các lần chạy mà mã không đổi |

: Thuật ngữ kiểm thử riêng của tài liệu

Chữ viết tắt chung (BRD, SRS, SAD, DU, PH, FR, NFR, REQ, KPI, RTM) theo D00-01 §2. Các chữ viết tắt riêng của tài liệu này: `MTP` (Master Test Plan, kế hoạch kiểm thử tổng thể), `TS` và `TC` (kịch bản và ca kiểm thử), `RG` (cổng phát hành), `RSK-T` (rủi ro kiểm thử), `CX` (thí nghiệm hỗn loạn), `SIT` (kiểm thử tích hợp hệ thống), `PERF`, `STAGING`, `TEST`, `UAT` (tên môi trường), `S1…S4` (mức nghiêm trọng của lỗi).

### 1.6. Người đọc và phần cần đọc

Tài liệu dài và nhiều nhóm người dùng; bảng dưới đây chỉ ra mỗi nhóm cần đọc chương nào để khỏi phải đọc toàn bộ.

| Người đọc | Mục đích đọc | Phần cần đọc |
|---|---|---|
| Hội đồng thẩm định | Đánh giá mọi yêu cầu phi chức năng đều có phương pháp kiểm chứng gắn công cụ, môi trường và cổng | Tóm tắt, chương 3, 5, 6, 17 |
| Chủ đầu tư, quản lý dự án | Biết cổng nào chặn phát hành, lịch kiểm thử theo đợt và rủi ro hoạt động | Chương 6, 13, 14, 15, 21 |
| Trưởng nhóm kiểm thử, kiểm thử viên | Áp dụng chiến lược, mẫu test case và quản lý lỗi hằng ngày | Chương 3 đến 5, 10, 11, 12 |
| Lập trình viên, trưởng nhóm kỹ thuật | Biết viết kiểm thử ở mức nào, dùng dữ liệu gì, pipeline chạy gì | Chương 4, 6.1, 7 đến 9, 12 |
| Kiến trúc sư, trưởng nhóm ATTT | Đối chiếu kiểm thử cách ly tenant, bảo mật, chịu lỗi với thiết kế | Chương 5.4 đến 5.6, 17 |
| Vận hành | Chuẩn bị môi trường, diễn tập DR và kiểm thử sẵn sàng | Chương 5.4, 7, 14 |

: Nhóm người đọc và phần cần đọc của kế hoạch kiểm thử

### 1.7. Cấu trúc tài liệu

Tài liệu theo trình tự của ISO/IEC/IEEE 29119-3: bối cảnh và đối tượng, chiến lược, mức và loại kiểm thử, tiêu chí và cổng, môi trường và dữ liệu, tự động hóa, quản lý lỗi và chỉ số, tổ chức và lịch, rủi ro, công cụ, truy vết. Bảng dưới đây liệt kê nội dung từng chương.

| Chương | Nội dung |
|---|---|
| 1. Giới thiệu | Mục đích, phạm vi, căn cứ, quan hệ với các tài liệu kiểm thử khác, thuật ngữ, người đọc, cấu trúc |
| 2. Bối cảnh kiểm thử | Đối tượng kiểm thử theo phân hệ, đơn vị triển khai, hồ sơ triển khai; trong và ngoài phạm vi |
| 3. Chiến lược kiểm thử dựa trên rủi ro | Nguyên tắc, phương pháp chấm rủi ro, bảng rủi ro sản phẩm |
| 4. Các mức kiểm thử | Bảy mức từ đơn vị đến chấp nhận, tháp kiểm thử |
| 5. Các loại kiểm thử | Chức năng, hồi quy, hiệu năng, sẵn sàng và DR, bảo mật, rò rỉ chéo tenant, khả năng truy cập, di trú, strangler, thanh toán, NDXP, Camel, giao diện, tương thích |
| 6. Tiêu chí vào, ra và cổng phát hành | Cổng PR, cổng `RG-1…5`, tiêu chí tạm dừng và tiếp tục |
| 7. Môi trường kiểm thử | Năm môi trường và giả lập dịch vụ ngoài |
| 8. Dữ liệu kiểm thử và che dữ liệu | Dữ liệu tổng hợp, che dữ liệu, dữ liệu canary |
| 9. Tự động hóa và tích hợp liên tục | Kiến trúc, ngân sách pipeline, chọn ca tự động hóa, báo cáo, ca bất ổn |
| 10. Quản lý lỗi | Mức nghiêm trọng, vòng đời, thời hạn sửa |
| 11. Chỉ số kiểm thử và báo cáo | Chỉ số và nhịp báo cáo |
| 12. Quy ước định danh và mẫu test case | Mã `TS`, `TC` và mẫu |
| 13. Tổ chức, vai trò và kỹ năng | Vai trò, RACI, đào tạo |
| 14. Lịch kiểm thử theo mốc | Lịch theo T0, wave và đợt |
| 15. Rủi ro kiểm thử và giả định | Rủi ro của hoạt động kiểm thử, giả định |
| 16. Công cụ | Công cụ theo nhóm |
| 17. Ma trận truy vết NFR → kiểm thử | Từng NFR tới loại kiểm thử, công cụ, môi trường, cổng |
| 18 đến 21 | Quan hệ với D05-02 đến D05-05, truy vết, mã đề xuất bổ sung D00-01, câu hỏi mở |

: Cấu trúc các chương của tài liệu

## 2. Bối cảnh kiểm thử

### 2.1. Đối tượng kiểm thử

Đối tượng kiểm thử (test item) của Datahub được chia theo ba chiều. Theo **phân hệ**, có 20 phân hệ `PH-01…PH-20`, mỗi phân hệ có FRS, SDD và tập test case riêng. Theo **đơn vị triển khai**, có sáu DU Spring Boot (`dh-connect`, `dh-integration`, `dh-data`, `dh-platform`, `dh-payment`, `dh-assist`), một DU Camel Quarkus (`dh-runtime`), hai ứng dụng giao diện (`dh-console`, `dh-portal`) và các thành phần bên thứ ba được cấu hình (APISIX, Kafka, Keycloak, OPA, PostgreSQL, OpenBao, Garage, Valkey). Theo **hồ sơ triển khai**, có hồ sơ tỉnh độc lập và hồ sơ nền tảng dùng chung, với ba chế độ cách ly tenant `SHARED`, `DEDICATED_DB`, `DEDICATED_CLUSTER` (D03-10 §2).

Bảng dưới đây liệt kê 20 phân hệ cùng đợt phát hành (theo D02-01 §8.3) và mức rủi ro sản phẩm được gán ở mục 3. Mức rủi ro quyết định cường độ kiểm thử: phân hệ rủi ro **Rất cao** bắt buộc đủ mọi mức kiểm thử ở mục 4 và các loại kiểm thử chuyên đề tương ứng; phân hệ rủi ro **Trung bình** được phép giảm kiểm thử đầu–cuối xuống luồng chính.

| PH | Tên | DU | Đợt | Mức rủi ro | Loại kiểm thử chuyên đề nổi bật |
|---|---|---|---|---|---|
| PH-01 | Kết nạp HTTT | `dh-connect` | **MVP** | Cao | Saga có bù trừ, cấp và thu hồi thông tin xác thực |
| PH-02 | Danh mục dịch vụ | `dh-connect` | **MVP** | Cao | Hợp đồng OpenAPI nhập vào, vòng đời API, gói sử dụng |
| PH-03 | Cổng API | `apisix`, `dh-connect` | **MVP** | Rất cao | Hiệu năng NFR-00-001/002, bảo mật API, đồng bộ cấu hình, chịu lỗi control plane |
| PH-04 | Lõi tích hợp, trình thiết kế luồng | `dh-integration`, `dh-runtime` | **MVP** | Rất cao | Kiểm thử luồng Camel, NFR-00-007, di trú luồng XML, song song strangler |
| PH-05 | Bộ điều hợp | `dh-integration`, `dh-runtime` | **MVP** | Cao | Kiểm thử Kamelet với Testcontainers (CSDL, SFTP, SOAP giả lập) |
| PH-06 | Dữ liệu chủ | `dh-data` | Đợt 3 | Trung bình | Độ chính xác đối sánh, hiệu năng lô |
| PH-07 | Danh mục dùng chung | `dh-data` | **MVP** | Cao | NFR-00-008, nhập xuất, di trú Aita, đồng bộ quốc gia |
| PH-08 | Chất lượng dữ liệu | `dh-data` | Đợt 3 | Trung bình | Đúng đắn quy tắc, lịch đo |
| PH-09 | Quyền riêng tư | `dh-data` | Đợt 2 | Rất cao | Che dữ liệu NFR-00-029, mục đích khai thác, kiểm toán |
| PH-10 | Sự kiện | `dh-integration`, Kafka | **MVP** | Rất cao | NFR-00-006, hợp đồng AsyncAPI, ACL Kafka theo tenant, cầu nối Pulsar |
| PH-11 | Quy trình liên thông | `dh-platform` | Đợt 2 | Trung bình | Kiểm thử BPMN với Flowable nhúng, hạn xử lý với đồng hồ giả lập |
| PH-12 | Định danh và phân quyền | Keycloak, OPA, `dh-platform` | **MVP** | Rất cao | Kiểm thử chính sách Rego, MFA, phiên, khóa tài khoản |
| PH-13 | Giám sát và kiểm toán | `dh-platform`, LGTM | **MVP** | Cao | Toàn vẹn chuỗi băm FR-00-042, nhãn tenant trên dữ liệu quan sát |
| PH-14 | Kết nối quốc gia | `dh-runtime`, `dh-integration` | **MVP** | Rất cao | Adapter NDXP bằng giả lập, kiểm thử hợp đồng định kỳ với môi trường thử |
| PH-15 | Cổng nhà phát triển | `dh-portal`, `dh-connect` | Đợt 2 | Trung bình | Khả năng truy cập ở 360 px, sandbox cách ly |
| PH-16 | Báo cáo chỉ tiêu | `dh-platform` | Đợt 3 | Thấp | Đúng đắn số liệu tổng hợp |
| PH-17 | Trợ lý AI | `dh-assist` | Đợt 3 | Trung bình | Đánh giá chất lượng câu trả lời, chống rò rỉ dữ liệu qua lời nhắc, tắt theo tenant |
| PH-18 | Vận hành, xử lý lỗi | `dh-platform` | **MVP** | Cao | DLQ, xử lý lại idempotent, công cụ di trú và đối chiếu |
| PH-19 | Thanh toán | `dh-payment` | Đợt 2 | Rất cao | Sandbox PayGov, chữ ký callback, idempotency, đối soát, `T-MONEY` |
| PH-20 | Quản trị tenant | `dh-platform` | **MVP** | Rất cao | Saga khởi tạo NFR-00-057, sáp nhập tenant, kiểm tra cách ly sau khởi tạo |

: Hai mươi phân hệ theo đơn vị triển khai, đợt, mức rủi ro và loại kiểm thử nổi bật

Ngoài 20 phân hệ, các **thành phần xuyên suốt** cũng là đối tượng kiểm thử riêng: thư viện dùng chung `libs/common-java` (bộ lọc tenant, Problem Details, `trace_id`), design system `@datahub/ui`, bộ manifest Kustomize và cấu hình Argo CD, chính sách mạng Cilium, cấu hình Istio ambient, cấu hình sao lưu và DR. Các thành phần này được kiểm thử theo cùng chiến lược nhưng không gắn mã phân hệ; test case của chúng dùng mã `PH` = `00` (ví dụ `TC-00-015`).

### 2.2. Trong phạm vi

Phạm vi kiểm thử gồm mọi yêu cầu `FR-00`, `NFR-00`, `FR-{PH}`, `NFR-{PH}`, `BR-{PH}` của 20 phân hệ theo đợt phát hành; mọi mục `LGC` có kết luận Giữ nguyên, Nâng cấp hoặc Thay thế trong D00-03 (179 mục), được kiểm chứng gián tiếp qua FR tương ứng; công cụ di trú dữ liệu và luồng từ hệ cũ (FR-00-090…093); cầu nối tạm và cơ chế chạy song song trong giai đoạn strangler; quy trình triển khai, nâng cấp, sao lưu, khôi phục và DR như những đối tượng kiểm thử có tiêu chí đạt riêng; tài liệu hướng dẫn cài đặt, vận hành và sử dụng ở mức kiểm tra thao tác theo tài liệu được (một người không thuộc đội phát triển làm theo tài liệu và đạt kết quả).

### 2.3. Ngoài phạm vi

Bảng dưới đây liệt kê những gì kế hoạch không kiểm thử, kèm lý do, để hội đồng thẩm định thấy ranh giới trách nhiệm là có chủ ý chứ không phải bỏ sót.

| Nội dung | Lý do | Cách xử lý phần giao |
|---|---|---|
| Chức năng nội tại của NDXP, CSDL quốc gia, PayGov, VNeID | Hệ thống của bên khác, Datahub không kiểm soát | Kiểm thử adapter bằng giả lập và kiểm thử hợp đồng với môi trường thử của bên cung cấp (mục 5.10, 5.11) |
| HTTT nghiệp vụ của sở, ngành | Ngoài phạm vi dự án (D02-01 §8.2) | Dùng HTTT giả lập; kiểm thử kết nối thật chỉ trong UAT và giai đoạn chuyển đổi |
| Phần cứng, đường truyền, ảo hóa của TTDL tỉnh | Thuộc dự án hạ tầng của tỉnh | Kiểm tra cụm K8s đạt yêu cầu tối thiểu D03-09 bằng bộ kiểm tra tiền triển khai trước khi cài |
| Ba chức năng hệ cũ loại bỏ (LGC-TOOL-022, LGC-TOOL-027, LGC-IAM-007) | Chủ đầu tư đã chấp thuận loại bỏ (D00-03 §5.1) | Có ca kiểm thử âm chứng minh chức năng không tồn tại (ví dụ không nạp được JAR vào runtime) |
| Hiệu năng và chất lượng của mô hình ngôn ngữ bên ngoài cho PH-17 | Không thuộc Datahub | Chỉ kiểm thử lớp cổng AI: giới hạn, che dữ liệu, khả năng tắt |
| Kiểm thử chứng nhận cấp độ ATTT của cơ quan có thẩm quyền | Do đơn vị thẩm định thực hiện | D05-04 cung cấp bằng chứng đầu vào cho hồ sơ D03-08 |

: Nội dung ngoài phạm vi kiểm thử, lý do và cách xử lý phần giao

## 3. Chiến lược kiểm thử dựa trên rủi ro

### 3.1. Nguyên tắc

Datahub là hạ tầng dùng chung của nhiều tỉnh. Một lỗi ở gateway hoặc ở lớp cách ly tenant không làm hỏng một màn hình mà làm gián đoạn dịch vụ công của hàng trăm HTTT, hoặc làm lộ dữ liệu của tỉnh này cho tỉnh khác. Vì vậy kế hoạch không chia đều công sức kiểm thử cho mọi chức năng mà phân bổ theo rủi ro sản phẩm: chỗ nào hậu quả lỗi càng nặng và khả năng lỗi càng cao thì kiểm thử càng sâu, càng sớm và càng tự động.

Chiến lược dựa trên năm nguyên tắc. Thứ nhất, **kiểm thử sớm và dịch trái** (shift-left): hợp đồng API và sự kiện được kiểm tra ngay khi viết (NT-04 của SAD), quy tắc cách ly tenant được kiểm tra ở mức đơn vị và tích hợp, không chờ tới kiểm thử hệ thống. Thứ hai, **tự động hóa là mặc định**: mọi kiểm thử lặp lại được phải chạy trong CI; kiểm thử thủ công chỉ dành cho kiểm thử khám phá, kiểm tra trình đọc màn hình, UAT và kiểm thử xâm nhập. Thứ ba, **kiểm thử trên hạ tầng thật thay vì giả lập nội bộ**: PostgreSQL, Kafka, Keycloak, OPA, Valkey được chạy thật bằng Testcontainers thay vì cơ sở dữ liệu nhúng, vì nhiều rủi ro lớn nhất (RLS, ACL Kafka, chính sách OPA) chỉ lộ ra trên thành phần thật. Thứ tư, **giả lập chỉ ở biên ngoài hệ thống**: NDXP, PayGov, HTTT của sở, máy chủ thư được giả lập bằng WireMock hoặc Microcks; không giả lập các phân hệ của chính Datahub ở mức tích hợp hệ thống. Thứ năm, **mỗi chỉ tiêu phi chức năng có một kiểm thử đo được**: không có NFR nào được nghiệm thu bằng nhận định chủ quan.

### 3.2. Phương pháp đánh giá rủi ro

Mỗi rủi ro sản phẩm được chấm theo hai thang 1–3. **Ảnh hưởng** (I) đo hậu quả nếu lỗi lọt ra môi trường thật: 3 là lộ dữ liệu, vi phạm pháp luật, sai lệch tài chính hoặc gián đoạn data plane; 2 là mất một chức năng quản trị hoặc sai số liệu báo cáo; 1 là bất tiện có cách làm thay. **Khả năng** (L) đo xác suất lỗi tồn tại: 3 là công nghệ mới với đội, logic phức tạp, phụ thuộc bên ngoài thay đổi; 2 là logic trung bình; 1 là chức năng đơn giản, đã có mẫu. Điểm rủi ro bằng I × L. Điểm 7–9 là **Rất cao**, 5–6 là **Cao**, 3–4 là **Trung bình**, 1–2 là **Thấp**.

Bảng sau ánh xạ mức rủi ro sang cường độ kiểm thử tối thiểu. Đây là ràng buộc cho D05-02: tập test case của một phân hệ phải đạt cường độ tương ứng với mức rủi ro cao nhất của các rủi ro gắn với phân hệ đó.

| Mức rủi ro | Kỹ thuật thiết kế test case bắt buộc | Mức kiểm thử bắt buộc | Tự động hóa | Rà soát độc lập |
|---|---|---|---|---|
| Rất cao | Phân hoạch tương đương, giá trị biên, bảng quyết định, chuyển trạng thái, đoán lỗi; kiểm thử dựa trên tấn công cho phần bảo mật | Đơn vị, tích hợp module, tích hợp hệ thống, hợp đồng, E2E luồng chính và luồng ngoại lệ, hệ thống, chấp nhận | 100% ca hồi quy tự động | Test case được người thứ hai (không phải tác giả FR) rà soát; kết quả kiểm thử chuyên đề được bên độc lập xác nhận |
| Cao | Phân hoạch tương đương, giá trị biên, chuyển trạng thái | Đơn vị, tích hợp module, tích hợp hệ thống, hợp đồng, E2E luồng chính | ≥ 90% ca hồi quy tự động | Rà soát chéo trong nhóm |
| Trung bình | Phân hoạch tương đương, giá trị biên | Đơn vị, tích hợp hệ thống, E2E luồng chính | ≥ 70% ca hồi quy tự động | Tự rà soát theo bảng kiểm |
| Thấp | Phân hoạch tương đương | Đơn vị, tích hợp hệ thống | Tùy chọn | Tự rà soát |

: Cường độ kiểm thử tối thiểu theo mức rủi ro

### 3.3. Bảng rủi ro sản phẩm

Bảng dưới đây là danh sách rủi ro sản phẩm ban đầu, mã `RSK-T{nn}` (theo cùng cách đặt mã rủi ro chuyên đề như `RSK-A{nn}` ở SAD §12). Mỗi rủi ro được gắn với yêu cầu bị đe dọa, điểm I × L, và đáp ứng kiểm thử — tức là loại kiểm thử và mức kiểm thử được dùng để giảm rủi ro. Bảng được rà lại ở mỗi cổng phát hành; rủi ro mới phát sinh từ lỗi thực tế (ví dụ một lớp lỗi lặp lại) được bổ sung.

| Mã | Rủi ro sản phẩm | Yêu cầu bị đe dọa | I | L | Điểm | Đáp ứng kiểm thử |
|---|---|---|---|---|---|---|
| RSK-T01 | Dữ liệu tenant này đọc, sửa hoặc liệt kê được từ tenant khác do quên đặt biến phiên, vai trò CSDL có `BYPASSRLS`, truy vấn native, khóa bộ nhớ đệm hoặc topic không có tiền tố | FR-00-010, 011; RSK-A03 | 3 | 3 | 9 | Bộ kiểm thử rò rỉ chéo tenant tự động sinh theo mọi endpoint (mục 5.6); ArchUnit chặn truy vấn native; kiểm tra khởi động DU; kiểm thử ACL Kafka, khóa Valkey, bucket; chạy ở mọi PR và trước mọi cổng |
| RSK-T02 | Gateway thêm độ trễ hoặc giảm thông lượng dưới tải, làm chậm dịch vụ công | NFR-00-001, 002; KPI-04 | 3 | 2 | 6 | Kiểm thử tải, chịu tải, bền với k6 trên PERF (mục 5.3); đo từ chỉ số APISIX |
| RSK-T03 | Data plane ngừng khi control plane, một nút hoặc một vùng sự cố; nâng cấp gây lỗi lượt gọi | NFR-00-010…013, 015; KPI-03 | 3 | 2 | 6 | Kiểm thử hỗn loạn với Chaos Mesh, kiểm thử nâng cấp cuốn chiếu dưới tải (mục 5.4) |
| RSK-T04 | Mất dữ liệu quá RPO hoặc khôi phục quá RTO khi mất site | NFR-00-014; KPI-16 | 3 | 2 | 6 | Diễn tập DR hằng quý có đo thời gian và đối chiếu dữ liệu (mục 5.4.4) |
| RSK-T05 | Lỗ hổng ứng dụng hoặc API (OWASP API Top 10: BOLA, xác thực hỏng, cấp quyền mức hàm) | NFR-00-024; REQ-03, REQ-12 | 3 | 3 | 9 | SAST Semgrep, DAST OWASP ZAP, bảng kiểm ASVS 5.0 L2, kiểm thử xâm nhập độc lập (mục 5.5) |
| RSK-T06 | Lộ thông tin xác thực hoặc bí mật trong mã, ảnh container, log; thành phần có lỗ hổng đã biết | NFR-00-022, 023; KPI-09 | 3 | 2 | 6 | gitleaks, Trivy chặn ở CI; quét log bằng bộ mẫu dữ liệu (mục 5.5) |
| RSK-T07 | Giá trị trường Nhạy cảm xuất hiện trong log, thư thông báo, tệp xuất | NFR-00-029; FR-00-034, 062 | 3 | 2 | 6 | Bộ quét mẫu dữ liệu canary trên log của mọi môi trường kiểm thử (mục 8.4); E2E kiểm tra tệp xuất |
| RSK-T08 | Sai lệch tiền, giao dịch trùng hoặc mất kết quả thanh toán; callback giả mạo | REQ-19; KPI-13, 14; FR-00-091 | 3 | 3 | 9 | Kiểm thử PH-19 với sandbox PayGov và giả lập, kiểm thử idempotency, chữ ký, đối soát (mục 5.10) |
| RSK-T09 | Di trú làm mất, nhân đôi hoặc biến dạng dữ liệu (tràn `int(10)`, ngày dạng chuỗi, EAV) | FR-00-090…093; REQ-22 | 3 | 3 | 9 | Kiểm thử di trú có đối chiếu số lượng và tổng kiểm tra, diễn tập di trú trên bản sao dữ liệu đã che (mục 5.8) |
| RSK-T10 | Hệ mới trả kết quả khác hệ cũ cho cùng yêu cầu khi chuyển lưu lượng theo strangler | REQ-22; BP-09 | 3 | 3 | 9 | Kiểm thử song song bằng lưu lượng bóng và so sánh phản hồi (mục 5.9) |
| RSK-T11 | Đặc tả NDXP hoặc PayGov thay đổi làm hỏng adapter | REQ-14, REQ-19; RSK-A04 | 3 | 2 | 6 | Kiểm thử hợp đồng định kỳ hằng đêm với môi trường thử của bên cung cấp; giả lập theo đặc tả (mục 5.11) |
| RSK-T12 | Luồng Camel chuyển đổi sai dữ liệu, không xử lý lỗi, mất bản tin; biên dịch native thiếu component | REQ-04, REQ-05; NFR-00-007; RSK-A02 | 3 | 2 | 6 | Kiểm thử luồng Camel ở cả chế độ JVM và native, kiểm thử bộ xử lý lỗi và DLQ (mục 5.12) |
| RSK-T13 | Sự kiện bị mất, trùng hoặc sai tenant giữa outbox, Kafka và subscriber | REQ-10; NFR-00-006 | 3 | 2 | 6 | Kiểm thử tích hợp outbox–Debezium–Kafka, kiểm thử hợp đồng AsyncAPI, kiểm thử kiểm tra header `dhtenant` |
| RSK-T14 | Nhật ký kiểm toán thiếu bản ghi hoặc bị sửa không phát hiện | FR-00-040…042; KPI-07 | 3 | 2 | 6 | Kiểm thử tích hợp sinh bản ghi cho mọi thao tác trong FR-00-040; kiểm thử công cụ kiểm tra toàn vẹn chuỗi băm |
| RSK-T15 | Giao diện không dùng được cho người khuyết tật hoặc không đạt tương phản trên nền glass | NFR-00-040…045; REQ-21 | 2 | 3 | 6 | axe-core tự động trên mọi màn, kiểm tra NVDA thủ công 10 luồng chính, kiểm tra tương phản trên nền glass (mục 5.7) |
| RSK-T16 | Giao diện Liquid Glass chậm hoặc hiển thị lệch giữa trình duyệt, chế độ sáng tối | NFR-00-005, 043, 044; RSK-A05 | 2 | 2 | 4 | Lighthouse CI, visual regression đa trình duyệt (mục 5.13, 5.14) |
| RSK-T17 | Khởi tạo tenant vượt thời gian hoặc để lại tài nguyên mồ côi khi lỗi giữa saga; sáp nhập tenant làm lẫn dữ liệu | NFR-00-057; REQ-20; KPI-12 | 3 | 2 | 6 | Kiểm thử saga có tiêm lỗi từng bước, đo thời gian, kiểm tra cách ly sau khởi tạo và sau sáp nhập |
| RSK-T18 | Thay đổi phá vỡ hợp đồng API giữa các DU hoặc với HTTT trong cùng phiên bản chính | NFR-00-055 | 2 | 3 | 6 | Kiểm thử hợp đồng do bên dùng dẫn dắt, kiểm tra thay đổi phá vỡ OpenAPI ở CI (mục 4.4) |
| RSK-T19 | Vi phạm ranh giới module làm mục ruỗng kiến trúc Modulith | NFR-00-054 | 2 | 2 | 4 | `ApplicationModules.verify()` và ArchUnit ở mọi PR |
| RSK-T20 | Trợ lý AI tiết lộ dữ liệu ngoài quyền người hỏi hoặc dữ liệu tenant khác | REQ-17 | 3 | 2 | 6 | Kiểm thử chống tiêm lời nhắc (prompt injection), kiểm thử rò rỉ chéo tenant trên kho vector |
| RSK-T21 | Hạn mức tenant không chặn được tenant "hàng xóm ồn ào" | D03-10 §5.3; NFR-00-060 | 2 | 2 | 4 | Kiểm thử tải nhiều tenant: một tenant vượt hạn mức, đo ảnh hưởng tới tenant khác |

: Danh sách rủi ro sản phẩm RSK-T01 đến RSK-T21 và đáp ứng kiểm thử

Sơ đồ dưới đây xếp các rủi ro trên vào ma trận ảnh hưởng – khả năng, để thấy vùng tập trung công sức kiểm thử.

```{.mermaid caption="Ma trận rủi ro sản phẩm theo ảnh hưởng và khả năng"}
quadrantChart
  title Ma trận rủi ro sản phẩm RSK-T
  x-axis Khả năng thấp --> Khả năng cao
  y-axis Ảnh hưởng thấp --> Ảnh hưởng cao
  quadrant-1 Rất cao - kiểm thử sâu nhất
  quadrant-2 Cao - theo dõi khả năng
  quadrant-3 Thấp
  quadrant-4 Trung bình - tự động hóa
  T01 cách ly tenant: [0.92, 0.95]
  T05 bảo mật API: [0.88, 0.9]
  T08 thanh toán: [0.85, 0.93]
  T09 di trú: [0.82, 0.88]
  T10 strangler: [0.78, 0.86]
  T02 hiệu năng gateway: [0.5, 0.9]
  T03 chịu lỗi: [0.45, 0.88]
  T04 DR: [0.4, 0.92]
  T15 truy cập: [0.8, 0.55]
  T18 hợp đồng: [0.75, 0.6]
  T16 Liquid Glass: [0.45, 0.5]
  T19 Modulith: [0.4, 0.45]
```

Ma trận cho thấy năm rủi ro điểm 9 (cách ly tenant, bảo mật API, thanh toán, di trú, strangler) nằm ở góc phải trên; đây là nơi kế hoạch đặt kiểm thử tự động chạy ở mọi PR (với RSK-T01, RSK-T05) hoặc bộ kiểm thử chuyên đề có bên độc lập xác nhận (RSK-T08, T09, T10). Nhóm rủi ro hạ tầng (hiệu năng, chịu lỗi, DR) có ảnh hưởng rất cao nhưng khả năng trung bình nhờ kiến trúc tách control/data plane; chúng được kiểm chứng bằng kiểm thử phi chức năng định kỳ trên môi trường PERF và STAGING thay vì ở mọi PR. Nhóm giao diện có khả năng cao nhưng ảnh hưởng vừa; chúng được tự động hóa rộng (axe-core, visual regression) để chi phí mỗi lần kiểm tra gần bằng không.

## 4. Các mức kiểm thử

### 4.1. Tổng quan và tháp kiểm thử

Datahub dùng bảy mức kiểm thử. Bốn mức dưới (đơn vị, tích hợp module, tích hợp hệ thống, hợp đồng) do đội phát triển viết và chạy trong pipeline của mỗi PR; ba mức trên (đầu–cuối, hệ thống, chấp nhận) do đội kiểm thử dẫn dắt và chạy trên môi trường dùng chung. Sơ đồ dưới đây thể hiện tháp kiểm thử cùng tỷ lệ số lượng ca mục tiêu và thời gian chạy điển hình mỗi ca.

```{.mermaid caption="Tổng quan và tháp kiểm thử"}
flowchart TB
  UAT["Chấp nhận UAT<br/>thủ công có kịch bản · theo đợt"]
  SYS["Hệ thống · phi chức năng<br/>k6, chaos, ZAP, DR · định kỳ trên PERF/STAGING"]
  E2E["Đầu–cuối E2E Playwright<br/>≈ 5% số ca · 10–60 giây/ca"]
  CON["Hợp đồng API và sự kiện<br/>≈ 10% · vài giây/ca"]
  SIT["Tích hợp hệ thống Testcontainers<br/>≈ 15% · 1–10 giây/ca"]
  MOD["Tích hợp module Modulith<br/>≈ 10% · dưới 2 giây/ca"]
  UNIT["Đơn vị JUnit 5 / Vitest<br/>≈ 60% · dưới 50 ms/ca"]
  UAT --- SYS --- E2E --- CON --- SIT --- MOD --- UNIT
```

Tháp đọc từ dưới lên: càng xuống đáy, ca kiểm thử càng nhiều, càng nhanh, càng rẻ và càng khoanh vùng lỗi chính xác; càng lên đỉnh, ca càng ít, càng chậm nhưng càng gần trải nghiệm thật. Tỷ lệ phần trăm là mục tiêu theo số ca của bộ tự động và được theo dõi bằng chỉ số ở mục 11; nếu tỷ lệ E2E vượt 10%, trưởng nhóm kiểm thử yêu cầu đẩy các kiểm tra logic xuống mức thấp hơn. Datahub khác tháp kinh điển ở chỗ tầng tích hợp hệ thống dày hơn thường lệ: lý do là nhiều quy tắc an toàn quan trọng nhất (RLS, ACL Kafka, chính sách OPA, chữ ký callback) nằm trong cấu hình thành phần hạ tầng, chỉ kiểm chứng được khi chạy thành phần thật. Lựa chọn này được ghi tại ADR-038.

Mỗi mức dưới đây được mô tả theo cùng khung: mục tiêu, đối tượng, người chịu trách nhiệm, công cụ, môi trường, tiêu chí vào và tiêu chí ra.

### 4.2. Kiểm thử đơn vị

**Mục tiêu.** Kiểm chứng logic của từng lớp, hàm, component một cách cô lập: quy tắc nghiệp vụ `BR`, kiểm tra hợp lệ đầu vào, ánh xạ dữ liệu, máy trạng thái, hàm tạo tên có tenant (D03-10 §6 quy tắc 4), hàm che dữ liệu, bộ xử lý `T-MONEY`.

**Đối tượng và cách làm.** Ở backend Java, mỗi lớp dịch vụ miền và lớp tiện ích có kiểm thử JUnit 5 với AssertJ; phụ thuộc ra ngoài module được thay bằng Mockito. Kiểm thử dựa trên thuộc tính (property-based testing) bằng jqwik được dùng cho các hàm có không gian đầu vào lớn: chuẩn hóa tìm kiếm không dấu (FR-00-020), chuyển đổi số tiền từ `int(10)` sang `numeric(19,0)`, phân tích ngày tháng hệ cũ. Chính sách OPA viết bằng Rego được kiểm thử bằng `opa test` với độ phủ quy tắc 100%, mỗi quy tắc có ca cho phép và ca từ chối, và mọi chính sách có ca kiểm tra điều kiện `input.tenant == data.resource.tenant` (D03-10 §4). Ở giao diện, component React và hook được kiểm thử bằng Vitest và Testing Library; lời gọi mạng được giả lập bằng MSW (Mock Service Worker) sinh từ OpenAPI. Luồng Camel có kiểm thử đơn vị cho từng processor và biểu thức JQ.

**Trách nhiệm.** Lập trình viên viết cùng PR với mã nguồn. Người rà soát PR kiểm tra có kiểm thử cho nhánh logic mới.

**Công cụ và môi trường.** JUnit 5, AssertJ, Mockito, jqwik, `opa test`, Vitest, Testing Library, MSW; chạy trên máy lập trình viên và runner CI, không cần môi trường dùng chung.

**Tiêu chí vào.** Mã biên dịch được; hợp đồng của module đã có.

**Tiêu chí ra.** 100% ca đạt; độ phủ dòng ≥ 80% cho mã nghiệp vụ backend và ≥ 70% cho giao diện (NFR-00-053), đo bằng JaCoCo và V8 coverage, tính trên mã mới của PR không được thấp hơn ngưỡng; độ phủ quy tắc Rego 100%; điểm đột biến (mutation score) bằng PIT ≥ 60% cho các gói `domain` của phân hệ rủi ro Rất cao, chạy hằng đêm thay vì ở PR để giữ ngân sách thời gian.

### 4.3. Kiểm thử tích hợp module (Spring Modulith)

**Mục tiêu.** Kiểm chứng mỗi module Spring Modulith hoạt động đúng với các module nó phụ thuộc trong cùng DU, chỉ giao tiếp qua `api` và `events`, và tôn trọng ranh giới kiến trúc (NT-05, NFR-00-054).

**Đối tượng và cách làm.** Có ba loại kiểm thử ở mức này. Loại thứ nhất là **kiểm tra cấu trúc**: một lớp kiểm thử mỗi DU gọi `ApplicationModules.of(...).verify()` để phát hiện phụ thuộc vòng và truy cập vào gói `internal` của module khác; bổ sung các quy tắc ArchUnit dự án như cấm `@Query(nativeQuery = true)` ngoài danh sách cho phép đã duyệt (D03-10 §6 quy tắc 2), cấm tạo `DataSource` ngoài cấu hình chung, cấm gọi `TenantContext.set` ngoài thư viện dùng chung, cấm đọc tenant từ `@PathVariable`, `@RequestParam`, `@RequestBody` (quy tắc 1), bắt buộc tác vụ `@Scheduled` đi qua `TenantContext.runAs` (quy tắc 5). Loại thứ hai là **kiểm thử module cô lập** bằng `@ApplicationModuleTest`: khởi động riêng một module với chế độ `STANDALONE` hoặc `DIRECT_DEPENDENCIES`, kiểm tra luồng nghiệp vụ trong module với CSDL thật (Testcontainers). Loại thứ ba là **kiểm thử sự kiện giữa module** bằng `Scenario` của Spring Modulith: kích hoạt một lệnh, chờ sự kiện miền được phát (ví dụ `CatalogPublished`), kiểm tra module nghe sự kiện xử lý đúng; kiểm tra bản ghi `event_publication` chuyển trạng thái hoàn tất, đảm bảo không mất sự kiện khi bên nghe lỗi.

**Trách nhiệm.** Lập trình viên của module; trưởng nhóm kỹ thuật duy trì bộ quy tắc ArchUnit.

**Công cụ và môi trường.** Spring Modulith Test, ArchUnit, JUnit 5, Testcontainers PostgreSQL; runner CI.

**Tiêu chí vào.** Kiểm thử đơn vị của module đạt.

**Tiêu chí ra.** `verify()` đạt; 0 vi phạm ArchUnit (không có cơ chế "đóng băng" vi phạm cũ, trừ ngoại lệ có ADR); mỗi sự kiện miền công bố có ít nhất một kiểm thử `Scenario`.

### 4.4. Kiểm thử tích hợp hệ thống với Testcontainers

**Mục tiêu.** Kiểm chứng một DU hoạt động đúng với các thành phần hạ tầng thật mà nó dùng: PostgreSQL 18 có RLS, Kafka (KRaft) và Apicurio, Keycloak, OPA, Valkey, OpenBao, kho S3 tương thích. Đây là mức phát hiện các lỗi mà giả lập không thấy được: chính sách RLS sai, migration Liquibase thiếu changeset chính sách, ACL Kafka không chặn, cấu hình xác thực token sai realm.

**Đối tượng và cách làm.** Mỗi DU có một lớp cơ sở kiểm thử dùng chung (`AbstractSystemIT`) khởi động một bộ container dùng lại giữa các lớp kiểm thử (Testcontainers chế độ tái sử dụng trong một lần chạy) để giảm thời gian. CSDL được khởi tạo bằng chính migration Liquibase sản xuất, với vai trò kết nối ứng dụng không có `BYPASSRLS` và không là chủ sở hữu bảng — giống hệt môi trường thật. Hai tenant kiểm thử `T90` và `T91` (mã giả, ngoài dải mã tỉnh thật) được tạo sẵn trong realm Keycloak container, với người dùng và client máy mỗi vai trò. API được gọi bằng REST Assured qua máy chủ thật (`@SpringBootTest(webEnvironment = RANDOM_PORT)`) hoặc MockMvc khi cần kiểm soát bộ lọc bảo mật; token được lấy thật từ Keycloak container, không giả mạo JWT, để kiểm tra đúng chuỗi xác thực.

Các nhóm kiểm thử bắt buộc ở mức này gồm: kiểm thử rò rỉ chéo tenant sinh tự động cho mọi endpoint (mục 5.6); kiểm tra khởi động DU từ chối chạy khi vai trò CSDL có `BYPASSRLS` hoặc bảng thiếu chính sách (D03-10 §4); kiểm thử outbox (ghi nghiệp vụ và sự kiện cùng giao dịch, rollback thì không có sự kiện); kiểm thử idempotency với header `Idempotency-Key` gửi lặp đồng thời; kiểm thử khóa lạc quan với `If-Match` (FR-00-052); kiểm thử nhật ký kiểm toán cho mọi loại thao tác ở FR-00-040; kiểm thử Problem Details RFC 9457 và mã `ERR-{PH}-{nnn}` cho mọi ngoại lệ đặc tả trong FRS.

Với `dh-runtime` (Camel Quarkus), mức này dùng `@QuarkusTest` kết hợp Testcontainers (Quarkus Dev Services bị tắt trong CI để cấu hình tường minh) và chạy lại một tập con trên ảnh native bằng `@QuarkusIntegrationTest` (mục 5.12).

**Trách nhiệm.** Lập trình viên viết; đội kiểm thử rà soát độ phủ các nhóm bắt buộc.

**Công cụ và môi trường.** Testcontainers (PostgreSQL, Kafka, Keycloak, Valkey, MinIO hoặc Garage cho S3, OpenBao chế độ dev), REST Assured, MockMvc, Awaitility cho kiểm tra bất đồng bộ; runner CI có Docker hoặc môi trường container tương thích. Ảnh container cho kiểm thử được kéo từ Harbor nội bộ (không kéo trực tiếp từ Internet) và ghim phiên bản trùng với phiên bản triển khai.

**Tiêu chí vào.** Mức đơn vị và tích hợp module đạt; migration chạy được trên CSDL trống.

**Tiêu chí ra.** 100% ca đạt; mỗi endpoint mới có ca rò rỉ chéo tenant đạt; mỗi ngoại lệ trong FRS có ca kiểm thử; tỷ lệ ca bất ổn < 1% (mục 9.5).

### 4.5. Kiểm thử hợp đồng API và sự kiện

**Mục tiêu.** Bảo đảm bên cung cấp và bên dùng mỗi API, mỗi sự kiện luôn tương thích, để các DU, giao diện, HTTT và adapter tiến hóa độc lập mà không vỡ nhau (NT-04, NFR-00-055).

**Phương án và lựa chọn.** Datahub đã có hợp đồng viết trước ở thư mục `contracts/` (OpenAPI 3.1, AsyncAPI 3.0 hoặc JSON Schema sự kiện, gói Rego). Kiểm thử hợp đồng vì vậy theo hướng **hợp đồng làm trung tâm** (contract-first), gồm ba lớp:

1. **Kiểm tra tĩnh hợp đồng.** Spectral lint OpenAPI và AsyncAPI theo bộ luật dự án (đường dẫn `/api/{nhóm}/v{n}`, lỗi `application/problem+json`, có `Idempotency-Key` ở lệnh tạo, không có tham số tên `tenant`). oasdiff so sánh với phiên bản đã phát hành trên nhánh chính và chặn merge khi có thay đổi phá vỡ trong cùng phiên bản chính (tương ứng Gate B hiện có của repo). Schema sự kiện được kiểm tra tương thích theo luật `BACKWARD_TRANSITIVE` của Apicurio trước khi đăng ký.
2. **Kiểm chứng bên cung cấp so với hợp đồng.** Mỗi DU chạy bộ kiểm thử xác thực phản hồi thật so với OpenAPI (thư viện kiểm tra hợp lệ OpenAPI gắn vào REST Assured ở mức 4.4): mọi phản hồi trong kiểm thử tích hợp được đối chiếu tự động với schema, sai khác làm ca thất bại. Với sự kiện, bên phát kiểm tra bản tin phát ra hợp lệ với schema đã đăng ký và có đủ thuộc tính CloudEvents (`dhtenant`, `traceparent`).
3. **Hợp đồng do bên dùng dẫn dắt** (consumer-driven contract) cho các cặp giao tiếp nội bộ có rủi ro cao: giao diện `dh-console` với từng DU, `dh-integration` với `dh-connect`, `dh-runtime` với API của PH-07, `dh-payment` với PH-13. Datahub dùng **Pact** cho lớp này vì hỗ trợ cả bên dùng TypeScript (giao diện) lẫn Java, và có Pact Broker để kiểm tra "có thể triển khai được không" (`can-i-deploy`) trước khi đưa một DU lên môi trường. Spring Cloud Contract được cân nhắc nhưng không chọn vì chỉ thuận lợi khi cả hai phía là Spring, trong khi phía dùng quan trọng nhất là giao diện React (ADR-038).

Với **hợp đồng ra bên ngoài** (NDXP, PayGov, VNeID), không thể yêu cầu bên cung cấp chạy kiểm chứng Pact. Datahub thay bằng giả lập sinh từ đặc tả bên cung cấp (Microcks nạp OpenAPI/WSDL) dùng trong CI, cộng với kiểm thử hợp đồng định kỳ gọi môi trường thử thật của bên cung cấp (mục 5.11, 5.10).

**Trách nhiệm.** Nhóm sở hữu hợp đồng (bên cung cấp) duy trì đặc tả; bên dùng viết kỳ vọng Pact; trưởng nhóm kỹ thuật duyệt thay đổi hợp đồng.

**Tiêu chí vào.** Hợp đồng đã có trong `contracts/` và được gắn phiên bản.

**Tiêu chí ra.** 0 lỗi lint mức `error`; 0 thay đổi phá vỡ chưa tăng phiên bản chính; `can-i-deploy` trả đạt cho DU sắp triển khai; mọi sự kiện công bố có schema đăng ký và ví dụ hợp lệ.

### 4.6. Kiểm thử đầu–cuối (E2E) với Playwright

**Mục tiêu.** Kiểm chứng các hành trình người dùng và hành trình máy–máy xuyên qua nhiều DU trên môi trường triển khai giống thật: đăng nhập qua Keycloak, thao tác giao diện, qua APISIX, tới DU, phát sự kiện, nhận ở subscriber giả lập.

**Đối tượng và cách làm.** Bộ E2E tập trung vào **luồng nghiệp vụ chính** theo `BP` của BRD và **luồng ngoại lệ quan trọng**, không lặp lại các kiểm tra đã có ở mức thấp. Ví dụ hành trình bắt buộc: kết nạp một HTTT tới khi HTTT gọi được API qua gateway (gắn KPI-05); thiết kế, chạy thử, duyệt, phát hành một luồng và gọi được luồng qua gateway (KPI-06); công bố danh mục và subscriber nhận sự kiện; khởi tạo một tenant mới và kiểm tra khói (KPI-12); với đợt 2, tạo giao dịch thanh toán qua sandbox tới khi đối soát khớp. Playwright chạy giao diện trên Chromium, Firefox và WebKit; phần máy–máy dùng API request context của Playwright hoặc kịch bản k6 ở chế độ chức năng. Mỗi ca E2E dùng tenant kiểm thử riêng sinh theo lần chạy để chạy song song không đụng nhau, và dọn dẹp bằng API quản trị nền tảng sau khi chạy. Bộ chọn phần tử dùng vai trò và nhãn truy cập (`getByRole`, `getByLabel`) thay vì lớp CSS, vừa ổn định vừa gián tiếp kiểm tra khả năng truy cập.

**Trách nhiệm.** Đội kiểm thử (lane `L-QA`) viết và duy trì; lập trình viên giao diện bảo đảm phần tử có nhãn truy cập.

**Công cụ và môi trường.** Playwright Test (TypeScript), trình ghi trace của Playwright làm bằng chứng; môi trường TEST (mỗi lần hợp nhất vào nhánh chính) và STAGING (trước cổng).

**Tiêu chí vào.** Bản dựng đã qua các mức 4.2–4.5; triển khai lên TEST thành công và kiểm thử khói đạt.

**Tiêu chí ra.** 100% hành trình mức ưu tiên M đạt; ca thất bại có trace, ảnh chụp và `trace_id` phía máy chủ đính kèm báo cáo lỗi.

### 4.7. Kiểm thử hệ thống

**Mục tiêu.** Kiểm chứng toàn hệ thống như một sản phẩm hoàn chỉnh so với SRS và FRS, gồm cả đặc tính phi chức năng: hiệu năng, sẵn sàng, bảo mật, khả năng truy cập, tương thích, cài đặt, nâng cấp, sao lưu, DR, vận hành theo tài liệu.

**Đối tượng và cách làm.** Kiểm thử hệ thống gồm hai phần. Phần chức năng là chạy toàn bộ tập test case của D05-02 cho các phân hệ trong đợt phát hành (tự động phần lớn, thủ công cho ca khám phá và ca cần phán đoán), cộng với kiểm thử khám phá theo phiên (session-based exploratory testing) có điều lệ (charter) cho mỗi phân hệ rủi ro Cao trở lên. Phần phi chức năng là các loại kiểm thử ở mục 5.3 đến 5.15, chạy trên PERF và STAGING theo lịch ở mục 14. Kiểm thử hệ thống được thực hiện trên **cả hai hồ sơ triển khai**: hồ sơ nền tảng dùng chung với ít nhất ba tenant chế độ `SHARED` và một tenant `DEDICATED_DB`, và hồ sơ tỉnh độc lập cài từ gói phân phối air-gapped trên một cụm sạch, để kiểm chứng NFR-00-056 (triển khai mới một tỉnh ≤ 3 ngày làm việc) bằng một người vận hành không thuộc đội phát triển làm theo tài liệu cài đặt.

**Trách nhiệm.** Trưởng nhóm kiểm thử chủ trì; đội vận hành tham gia các kiểm thử cài đặt, nâng cấp, DR; đơn vị kiểm thử bảo mật độc lập thực hiện kiểm thử xâm nhập.

**Tiêu chí vào.** Cổng `RG-2` đạt (mục 6); STAGING ổn định, cấu hình giống sản xuất về số bản sao và chính sách mạng.

**Tiêu chí ra.** Tiêu chí của cổng `RG-3` (mục 6).

### 4.8. Kiểm thử chấp nhận (UAT)

**Mục tiêu.** Người dùng nghiệp vụ và chủ đầu tư xác nhận hệ thống đáp ứng nhu cầu nghiệp vụ, đạt các KPI có thời điểm đo "Từ nghiệm thu" (D02-01 §3, §11) và có thể đưa vào vận hành.

**Đối tượng và cách làm.** UAT được tổ chức theo từng đợt phát hành, trên môi trường UAT với dữ liệu tổng hợp có hình dạng giống dữ liệu tỉnh thí điểm. Kịch bản UAT được viết theo quy trình nghiệp vụ `BP` chứ không theo màn hình, do người dùng thật của từng nhóm ở SRS §2.1 thực hiện (quản trị tỉnh, kỹ sư tích hợp, cán bộ nghiệp vụ, chủ quản dữ liệu, cán bộ đối soát với đợt 2). Ngoài UAT chức năng, UAT vận hành (operational acceptance) do đội vận hành TTDL tỉnh thực hiện trên tài liệu HDVH: khởi động, dừng, giám sát, xử lý sự cố mẫu, khôi phục. Đo KPI-18 (điểm SUS ≥ 75) bằng bảng hỏi SUS sau mỗi đợt UAT. Chi tiết ở D05-05.

**Trách nhiệm.** Chủ đầu tư và người dùng nghiệp vụ thực hiện, ký biên bản; đội kiểm thử chuẩn bị môi trường, dữ liệu, hướng dẫn và ghi nhận lỗi.

**Tiêu chí vào.** Cổng `RG-3` đạt; tài liệu HDSD bản dự thảo sẵn sàng; người dùng UAT đã được đào tạo.

**Tiêu chí ra.** Tiêu chí của cổng `RG-4` (mục 6).

### 4.9. Tóm tắt các mức

Bảng tóm tắt dưới đây gom các mức kiểm thử để tra nhanh khi lập kế hoạch sprint.

| Mức | Ai viết | Ai chạy | Khi nào | Môi trường | Công cụ chính | Chặn |
|---|---|---|---|---|---|---|
| Đơn vị | Lập trình viên | CI | Mọi PR | Runner CI | JUnit 5, AssertJ, jqwik, `opa test`, Vitest, Testing Library | Merge |
| Tích hợp module | Lập trình viên | CI | Mọi PR | Runner CI | Spring Modulith Test, ArchUnit | Merge |
| Tích hợp hệ thống | Lập trình viên | CI | Mọi PR (tập theo module bị đổi), toàn bộ khi merge | Runner CI | Testcontainers, REST Assured, MockMvc, Awaitility | Merge |
| Hợp đồng | Bên cung cấp và bên dùng | CI | Mọi PR đụng hợp đồng hoặc bên dùng; trước triển khai | Runner CI, Pact Broker | Spectral, oasdiff, Pact, Microcks | Merge, triển khai |
| E2E | Đội kiểm thử | CI | Mỗi lần merge (tập khói), hằng đêm (đầy đủ) | TEST, STAGING | Playwright | Lên STAGING |
| Hệ thống | Đội kiểm thử, vận hành, đơn vị độc lập | Đội kiểm thử | Mỗi bản ứng viên phát hành | STAGING, PERF | Toàn bộ mục 16 | `RG-3` |
| Chấp nhận | Đội kiểm thử chuẩn bị | Người dùng, chủ đầu tư | Mỗi đợt | UAT | Kịch bản D05-05, bảng hỏi SUS | `RG-4` |

: Bảy mức kiểm thử theo người viết, người chạy, thời điểm, môi trường và công cụ

## 5. Các loại kiểm thử

Mục này mô tả từng loại kiểm thử: nó kiểm chứng yêu cầu nào, làm thế nào, đạt khi nào. Loại kiểm thử nào có tài liệu chuyên đề thì mục này chỉ chốt phạm vi, chỉ tiêu và công cụ.

### 5.1. Kiểm thử chức năng

Kiểm thử chức năng kiểm chứng mọi `FR` và `BR`. Mỗi FR mức M có ít nhất hai test case, một dương tính và một âm tính (D00-01 §3.2 quy tắc 4); FR có ngoại lệ đặc tả thì mỗi ngoại lệ có một ca âm riêng kiểm tra đúng mã `ERR`, mã HTTP và hành vi. Các yêu cầu dùng chung `FR-00` được kiểm thử theo hai tầng: một bộ **kiểm thử khung dùng chung** (TS-00-nn) kiểm tra cơ chế một lần ở thư viện hoặc design system (phân trang, tìm không dấu, xuất Excel, xác nhận thao tác, Problem Details), và mỗi phân hệ có ca kiểm tra áp dụng đúng cơ chế đó trên màn và API của mình. Mục `LGC` được kiểm chứng gián tiếp: test case ghi cột "LGC" khi FR mà nó kiểm thử thay thế chức năng hệ cũ, nhờ đó RTM tính được độ phủ 179 mục LGC cần giữ.

Bộ tiêu chí chấp nhận `AT-{PH}-{nnn}` đã có trong SRS phân hệ của repo (`docs/07-srs/`, mục M10) được dùng làm đầu vào: D05-02 chuyển mỗi AT thành một hoặc nhiều TC, ghi mã AT gốc ở trường "Nguồn" để không mất truy vết với tài liệu cũ.

Các yêu cầu có tiêu chí thời gian (FR-00-003 tự đăng xuất sau 30 phút, hạn xử lý ở PH-11, hạn tải tệp 24 giờ ở FR-00-031) được kiểm thử bằng đồng hồ giả lập (`Clock` tiêm vào ở backend, `page.clock` của Playwright ở giao diện), không chờ thời gian thật.

### 5.2. Kiểm thử hồi quy

Mọi ca tự động ở mục 4 là bộ hồi quy. Bộ hồi quy được chia ba tầng theo thời gian chạy: **tầng PR** (đơn vị, module, tích hợp hệ thống của module bị đổi, hợp đồng) chạy ở mọi PR; **tầng hợp nhất** (toàn bộ tích hợp hệ thống, E2E khói) chạy mỗi lần merge vào nhánh chính; **tầng đêm** (E2E đầy đủ trên ba trình duyệt, visual regression, kiểm thử đột biến, DAST cơ bản, quét log) chạy hằng đêm trên TEST. Việc chọn ca theo module bị đổi dựa vào bản đồ phụ thuộc Modulith: đổi module A thì chạy ca của A và của các module phụ thuộc A. Trước mỗi cổng `RG-2` trở lên, toàn bộ bộ hồi quy chạy lại không chọn lọc. Lỗi đã sửa ở mức nghiêm trọng S1, S2 bắt buộc có ca hồi quy tự động trước khi đóng lỗi.

### 5.3. Kiểm thử hiệu năng

#### 5.3.1. Hồ sơ tải "tỉnh vừa" và các loại kiểm thử

Mọi chỉ tiêu hiệu năng đo trên hồ sơ quy mô "tỉnh vừa" của SRS §6.1: 200 HTTT thành viên, 2.000 API, 500 luồng, 5 triệu lượt gọi API mỗi ngày, cao điểm 300 lượt/giây, 200 người dùng giao diện đồng thời mỗi tenant. Dữ liệu nền được sinh tổng hợp (mục 8) với 1 triệu bản ghi cho màn danh sách lớn nhất. Mô hình lưu lượng hằng ngày được dựng theo hình dạng giờ hành chính (đỉnh 9–11 giờ và 14–16 giờ) với phân bố 80% đọc, 20% ghi, phân bố kích thước bản tin 1 KB / 10 KB / 100 KB theo tỷ lệ 70/25/5 cho tới khi có số liệu thật của tỉnh thí điểm (Q07 của SRS).

Bốn loại kiểm thử hiệu năng được dùng, định nghĩa như sau để mọi bên hiểu thống nhất. **Kiểm thử tải** (load test) chạy ở mức cao điểm danh định để đo chỉ tiêu. **Kiểm thử chịu tải** (stress test) tăng dần quá danh định tới khi hỏng để tìm điểm gãy và kiểm tra hệ suy giảm có kiểm soát (trả `429`/`503` thay vì treo). **Kiểm thử đột biến tải** (spike test) tăng vọt gấp 3 lần trong 1 phút để kiểm tra tự co giãn HPA/KEDA. **Kiểm thử bền** (soak test) chạy ở 70% danh định trong 8 giờ (24 giờ trước `RG-3` của MVP) để phát hiện rò rỉ bộ nhớ, tăng trưởng kết nối, phân mảnh.

#### 5.3.2. Kiểm chứng từng NFR hiệu năng

Bảng dưới đây hiện thực hóa phương pháp đo ở SRS cho từng NFR: kịch bản, điểm đo, điều kiện đạt. Mọi kịch bản k6 xuất kết quả lên Mimir (k6 output Prometheus remote write) để đối chiếu với chỉ số phía máy chủ trên cùng bảng Grafana.

| NFR | Kịch bản kiểm thử | Điểm đo | Điều kiện đạt |
|---|---|---|---|
| NFR-00-001 | k6 tải hằng số 300 lượt/giây trong 30 phút qua APISIX tới backend giả lập phản hồi cố định 20 ms; trộn xác thực token, rate limit, OPA | Chênh lệch giữa `apisix_http_latency{type="request"}` và `{type="upstream"}` (độ trễ do APISIX), đối chiếu với độ trễ phía k6 trừ độ trễ backend | p95 ≤ 50 ms, p99 ≤ 100 ms |
| NFR-00-002 | k6 tăng dần tới 1.000 lượt/giây, giữ 30 phút, APISIX 3 bản sao | Tỷ lệ lỗi `5xx` không do backend; thông lượng duy trì | ≥ 1.000 lượt/giây, lỗi do nền tảng < 0,1% |
| NFR-00-003 | k6 mô phỏng 200 người dùng đồng thời gọi API danh sách có lọc, sắp xếp, phân trang trên bảng 1 triệu bản ghi; đồng thời Playwright đo thời gian hiển thị màn danh sách (từ điều hướng tới khi bảng có dữ liệu) cho 20 phiên mẫu | Phía API: k6; phía giao diện: Playwright `performance.mark` | p95 ≤ 1,5 giây cả hai phía |
| NFR-00-004 | Như trên cho màn chi tiết và lệnh lưu biểu mẫu | Như trên | p95 ≤ 1 giây |
| NFR-00-005 | Lighthouse CI chạy 5 lần mỗi trang trên hồ sơ máy 4 nhân, 8 GB, giới hạn mạng 20 Mbps; INP đo bằng thư viện web-vitals trong kịch bản Playwright thao tác thật | LCP, INP trung vị 5 lần | LCP ≤ 2,5 giây, INP ≤ 200 ms |
| NFR-00-006 | k6 với phần mở rộng Kafka (xk6-kafka) phát 500 sự kiện/giây vào 50 topic; subscriber giả lập kiểu đẩy ghi thời điểm nhận; đồng hồ các nút đồng bộ NTP | Hiệu thời điểm nhận và thời điểm phát (dấu thời gian trong bản tin) | p95 ≤ 2 giây |
| NFR-00-007 | k6 gọi luồng chuẩn (nhận REST, chuyển đổi JSON bằng JQ, gửi tới đích giả lập) 300 lượt/giây; ảnh native | Chỉ số `camel_exchange_processing_seconds` của route trừ thời gian gọi đích | p95 ≤ 30 ms |
| NFR-00-008 | Kiểm thử chức năng có đo thời gian: nhập tệp 100.000 dòng hợp lệ qua API nhập PH-07, đo từ khi tải lên tới khi tác vụ nền hoàn tất | Thời điểm bản ghi tác vụ chuyển `COMPLETED` | ≤ 2 phút; đúng 100.000 bản ghi được ghi |
| NFR-00-060 | Nền tảng dùng chung khởi tạo 34 tenant; chạy kiểm thử tải trên 5 tenant đồng thời, 29 tenant ở mức nền | Chỉ tiêu NFR-00-001 của từng tenant | Đạt chỉ tiêu ở mọi tenant tải |
| NFR-00-061 | Chạy NFR-00-002 với N bản sao data plane rồi 2N bản sao | Thông lượng tối đa giữ lỗi < 0,1% | Tỷ lệ ≥ 1,8 |
| NFR-00-062 | Sinh 5 triệu bản ghi siêu dữ liệu/ngày × 365 ngày cho 1 tenant (dữ liệu tổng hợp); chạy truy vấn báo cáo chuẩn của PH-13 | Thời gian truy vấn, dung lượng | Truy vấn trả kết quả; ngưỡng thời gian chốt ở D05-03 |
| RSK-T21 | Một tenant phát gấp 3 hạn mức 500 lượt/giây, tenant khác ở tải danh định | Độ trễ và lỗi của tenant khác | Tenant khác vẫn đạt NFR-00-001; tenant vượt nhận `429` |

: Kịch bản, điểm đo và điều kiện đạt của từng NFR hiệu năng

> **Câu hỏi mở Q361:** NFR-00-062 chưa có chỉ tiêu thời gian truy vấn trên tập 12 tháng (khoảng 1,8 tỷ bản ghi mỗi tenant). Đề nghị bổ sung vào SRS (ví dụ truy vấn tổng hợp theo ngày cho một API trong 30 ngày ≤ 5 giây) để D05-03 có điều kiện đạt.

Chạy hiệu năng trên môi trường PERF có cấu hình bằng hồ sơ "tỉnh vừa" ở D03-09. Mỗi lần chạy ghi lại phiên bản phần mềm, cấu hình tài nguyên, kết quả và so sánh với đường cơ sở (baseline) lần trước; suy giảm quá 10% ở chỉ số p95 bất kỳ là lỗi mức S2 dù chưa vượt chỉ tiêu. Một kịch bản tải rút gọn (5 phút, 100 lượt/giây) chạy hằng đêm trên TEST để phát hiện suy giảm sớm.

### 5.4. Kiểm thử sẵn sàng, hỗn loạn và DR

#### 5.4.1. Đo sẵn sàng (NFR-00-010, 011)

Sẵn sàng không kiểm thử được bằng một lần chạy mà đo liên tục. Trên STAGING và sau này trên PROD, bộ kiểm tra tổng hợp (synthetic probe) bằng Grafana Synthetic Monitoring hoặc Blackbox Exporter gọi mỗi phút một API mẫu qua APISIX, một luồng mẫu trên `dh-runtime`, phát–nhận một sự kiện mẫu, và mở trang đăng nhập `dh-console`. Tỷ lệ phút thành công trên tổng phút (trừ thời gian bảo trì báo trước) là độ sẵn sàng. Trước `RG-4`, STAGING phải có ít nhất 14 ngày đo liên tục đạt ≥ 99,9% cho data plane và ≥ 99,5% cho control plane, như bằng chứng thiết kế đạt; cam kết chính thức đo trên PROD.

#### 5.4.2. Kiểm thử hỗn loạn

Kiểm thử hỗn loạn dùng **Chaos Mesh** (lựa chọn mặc định vì có sẵn các loại lỗi pod, mạng, IO, thời gian và lập lịch thí nghiệm bằng CRD, quản lý được qua GitOps); Litmus là phương án thay thế khi tỉnh đã dùng. Mỗi thí nghiệm có giả thuyết trạng thái ổn định (steady-state hypothesis) đo bằng chỉ số, phạm vi ảnh hưởng giới hạn bằng nhãn namespace, và điều kiện hủy tự động. Thí nghiệm chạy trên STAGING dưới tải nền k6 ở 50% danh định để thấy ảnh hưởng tới người dùng.

| Thí nghiệm | Yêu cầu | Cách gây lỗi | Giả thuyết trạng thái ổn định / điều kiện đạt |
|---|---|---|---|
| CX-01 Control plane ngừng 24 giờ | NFR-00-012 | Thu nhỏ mọi DU control plane (`dh-connect`, `dh-integration`, `dh-data`, `dh-platform`) về 0 bản sao và chặn mạng tới Keycloak admin; giữ 24 giờ (kiểm thử rút gọn 2 giờ mỗi tuần, bản đủ 24 giờ trước `RG-3`) | APISIX, `dh-runtime`, Kafka tiếp tục phục vụ với cấu hình đã nạp; tỷ lệ lỗi của lưu lượng nền không tăng quá 0,1 điểm phần trăm; token máy mới vẫn được cấp (Keycloak runtime vẫn chạy) |
| CX-02 Nâng cấp cuốn chiếu dưới tải | NFR-00-013 | Triển khai phiên bản mới qua Argo CD cho APISIX, `dh-runtime` và Kafka (Strimzi rolling) trong khi k6 chạy 300 lượt/giây | 0 lượt gọi lỗi do nâng cấp (k6 ghi mọi phản hồi khác 2xx của lưu lượng hợp lệ) |
| CX-03 Mất một nút | NFR-00-015 | Chaos Mesh `PodChaos` kiểu `pod-kill` cho mọi pod trên một nút, sau đó cách ly nút (cordon, drain mất kiểm soát hoặc tắt máy ảo) | Không mất dịch vụ ở probe tổng hợp; pod được lập lịch lại và sẵn sàng ≤ 5 phút |
| CX-04 Mất primary PostgreSQL | NFR-00-010, 014 | Xóa pod primary CloudNativePG | Chuyển đổi dự phòng tự động; không mất giao dịch đã xác nhận (đồng bộ); control plane phục hồi ≤ 5 phút |
| CX-05 Mất một broker Kafka | NFR-00-006, 010 | `pod-kill` một broker | Không mất sự kiện (kiểm đếm phát–nhận khớp), p95 độ trễ sự kiện tạm vượt nhưng về ≤ 2 giây trong 5 phút |
| CX-06 Trễ và mất gói tới đích ngoài | REQ-14, REQ-19 | `NetworkChaos` trễ 2 giây, mất 30% gói tới giả lập NDXP và PayGov | Circuit breaker mở, lỗi trả nhanh với mã `ERR` đúng, bản tin vào DLQ đúng chính sách, không cạn luồng xử lý |
| CX-07 OpenBao không truy cập được | ADR-012 | Chặn mạng tới OpenBao 30 phút | DU đang chạy tiếp tục phục vụ với bí mật đã nạp; cảnh báo phát trong ≤ 5 phút (KPI-15) |
| CX-08 Lệch đồng hồ | FR-00-042, chữ ký callback | `TimeChaos` lệch 10 phút trên một pod | Chữ ký callback quá cửa sổ thời gian bị từ chối; chuỗi băm kiểm toán không bị phá |

: Tám thí nghiệm hỗn loạn CX-01 đến CX-08

#### 5.4.3. Kiểm thử phục hồi ở mức thành phần

Ngoài thí nghiệm hỗn loạn, mỗi bản ứng viên phát hành chạy kiểm thử khôi phục: khôi phục CSDL tại một thời điểm (PITR) từ bản sao lưu Barman Cloud vào cụm mới và đối chiếu số dòng, tổng kiểm tra với nguồn ở thời điểm đó; khôi phục namespace bằng Velero; khôi phục bucket Garage. Đây cũng là kiểm chứng FR liên quan tới sao lưu ở PH-18.

#### 5.4.4. Diễn tập DR (NFR-00-014)

Diễn tập DR được thực hiện **hằng quý** trên kiến trúc hai site của D03-09 (site chính và site dự phòng của STAGING trước vận hành; của PROD sau vận hành, trong khung giờ bảo trì được duyệt). Kịch bản chuẩn: ghi lưu lượng nghiệp vụ tổng hợp có đánh số tuần tự liên tục; tại thời điểm T_x cắt toàn bộ site chính (mạng và nguồn ở mức mô phỏng); thực hiện quy trình chuyển site theo HDVH; đo **RTO** là thời gian từ T_x tới khi probe tổng hợp data plane xanh trở lại (đạt ≤ 1 giờ) và control plane xanh trở lại (đạt ≤ 4 giờ); đo **RPO** bằng cách tìm số tuần tự cuối cùng có mặt ở site dự phòng và quy đổi ra thời gian (đạt ≤ 15 phút). Diễn tập kết thúc bằng chuyển ngược về site chính và đối chiếu dữ liệu. Biên bản diễn tập là bằng chứng cho hồ sơ cấp độ (D03-08) và thuộc nhóm biện pháp SEC-70–79.

### 5.5. Kiểm thử bảo mật

Kiểm thử bảo mật được chia thành các lớp chạy ở tần suất khác nhau. Bảng dưới đây chốt từng lớp, công cụ, thời điểm, ngưỡng chặn và nhóm biện pháp `SEC-nn` (định nghĩa ở D03-07) được kiểm chứng. Kịch bản chi tiết, bảng kiểm ASVS từng mục và ánh xạ từng `SEC-nn` cụ thể nằm ở D05-04.

| Lớp | Công cụ | Thời điểm | Ngưỡng chặn | Nhóm SEC kiểm chứng |
|---|---|---|---|---|
| Quét bí mật | gitleaks (mã, lịch sử commit), Trivy secret scan (ảnh container) | Mọi PR; mọi ảnh trước khi đẩy lên Harbor | 0 phát hiện (NFR-00-022) | SEC-30–39 |
| SAST | Semgrep với bộ luật Java, TypeScript, YAML, Kubernetes và luật dự án (ví dụ cấm `nativeQuery`, cấm log trường được gắn chú thích `@Sensitive`); CodeQL tùy chọn | Mọi PR | 0 phát hiện mức ERROR chưa có ngoại lệ được duyệt | SEC-40–49 |
| Phân tích thành phần (SCA) và SBOM | Trivy (thư viện, ảnh, IaC), sinh SBOM CycloneDX; kiểm tra giấy phép | Mọi PR; hằng đêm quét lại kho ảnh | 0 CRITICAL, 0 HIGH chưa có ngoại lệ (NFR-00-023); giấy phép trong danh sách cho phép (RB-04) | SEC-50–59 |
| Quét cấu hình hạ tầng | Trivy config / Checkov cho Kustomize, Helm; kube-bench theo CIS Kubernetes Benchmark; Kyverno hoặc OPA Gatekeeper chính sách tuyển nhận | Mọi PR đụng `deploy/`; hằng tuần trên cụm | 0 vi phạm mức cao | SEC-10–19, SEC-50–59 |
| DAST | OWASP ZAP: quét cơ bản (baseline) giao diện hằng đêm; quét API theo OpenAPI (ZAP API scan) có xác thực bằng token kiểm thử cho mọi API nhóm `/api` | Hằng đêm trên TEST; quét đầy đủ trước `RG-3` | 0 cảnh báo High; Medium phải phân loại | SEC-40–49 |
| Kiểm thử ủy quyền tự động | Bộ kiểm thử rò rỉ chéo tenant (mục 5.6), ma trận vai trò × endpoint sinh từ D02-08 (mỗi cặp vai trò–quyền có ca cho phép và ca từ chối) | Mọi PR | 100% đạt | SEC-20–29, SEC-80–89 |
| Kiểm thử xác thực, phiên | Ca tích hợp cho MFA (FR-00-002), khóa tài khoản sau 5 lần sai (NFR-00-025), chính sách mật khẩu (NFR-00-026), tự đăng xuất, thu hồi token, client_credentials + mTLS / private_key_jwt (RFC 8705, RFC 7523) | Mọi PR đụng PH-12; trước cổng | 100% đạt | SEC-20–29 |
| Kiểm tra mã hóa đường truyền | testssl.sh vào biên và các điểm cuối mTLS; kiểm tra Istio `PeerAuthentication` chế độ STRICT | Trước `RG-3`; hằng tháng | TLS 1.3 ở biên, chỉ bộ mã an toàn cho 1.2 (NFR-00-020) | SEC-10–19 |
| Kiểm tra nhật ký và giám sát | Kiểm thử phát hiện: tạo sự kiện an ninh mẫu (đăng nhập sai liên tiếp, header `dhtenant` không khớp) và kiểm tra cảnh báo tới đích trong ≤ 5 phút | Trước `RG-3` | Cảnh báo đúng | SEC-60–69 |
| Bảng kiểm ASVS 5.0 L2 | Đánh giá theo từng yêu cầu L2, kết hợp bằng chứng tự động và kiểm tra thủ công | Trước `RG-3` mỗi đợt | 100% yêu cầu L2 áp dụng được ở trạng thái Đạt hoặc Ngoại lệ được duyệt (NFR-00-024) | SEC-40–49 |
| Kiểm thử xâm nhập | Đơn vị độc lập với đội phát triển, hộp xám, theo OWASP WSTG và API Security Top 10 2023, gồm kịch bản leo thang liên tenant | Trước vận hành chính thức mỗi đợt; định kỳ ít nhất hằng năm và khi thay đổi lớn (Q360) | 0 phát hiện Critical/High còn mở khi phát hành | Mọi nhóm |
| Kiểm tra bổ sung cấp độ 4 | Chỉ khi tenant hoặc hồ sơ nâng cấp | Theo D05-04 | Theo D03-07 | SEC-90–99 |

: Các lớp kiểm thử bảo mật theo công cụ, thời điểm và ngưỡng chặn

Các kiểm thử bảo mật tự động đều xuất kết quả ở định dạng SARIF về một nơi tập trung (DefectDojo hoặc trang bảo mật của nền tảng Git) để theo dõi ngoại lệ, hạn xử lý và xu hướng. Ngoại lệ (chấp nhận rủi ro tạm thời) phải có người duyệt là trưởng nhóm ATTT, hạn hết hiệu lực tối đa 90 ngày và lý do.

> **Câu hỏi mở Q362:** Cần xác định đơn vị kiểm thử xâm nhập độc lập (đơn vị chuyên trách an ninh mạng của tỉnh, doanh nghiệp được cấp phép, hay đơn vị do Bộ Công an chỉ định cho hồ sơ cấp độ) và yêu cầu năng lực, giấy phép của đơn vị đó theo NĐ 331/2026.

### 5.6. Kiểm thử rò rỉ chéo tenant (bắt buộc)

#### 5.6.1. Mục tiêu và luật kỳ vọng

FR-00-011 yêu cầu người dùng và hệ thống của tenant A không được đọc, sửa, xóa, liệt kê hay **suy ra sự tồn tại** của dữ liệu tenant B, với tiêu chí chấp nhận "bộ kiểm thử rò rỉ chéo tenant đạt 100% trên mọi API". D03-10 §6 quy tắc 6 quy định kỳ vọng `404` (không phải `403`), vì `403` tiết lộ rằng tài nguyên tồn tại. Đây là loại kiểm thử quan trọng nhất của kế hoạch (RSK-T01, điểm 9) và là cổng chặn merge.

Luật kỳ vọng của bộ kiểm thử được chốt như bảng dưới đây; mọi ngoại lệ phải ghi trong FRS và được trưởng nhóm ATTT duyệt.

| Thao tác của tenant B lên tài nguyên của tenant A | Kỳ vọng |
|---|---|
| `GET /…/{id}` đọc theo định danh | `404`, thân Problem Details không chứa định danh, tên hay bất kỳ thuộc tính nào của tài nguyên |
| `PUT`, `PATCH`, `DELETE`, `POST /…/{id}:{hành-động}` | `404`; dữ liệu của A không đổi (kiểm tra lại bằng token A: `version` giữ nguyên) |
| `GET` danh sách, tìm kiếm, xuất | `200` với danh sách không chứa bản ghi nào của A; tổng số (`totalElements`) không tính bản ghi của A |
| `POST` tạo với tham chiếu tới khóa của A (ví dụ gắn API của A vào gói của B) | `404` hoặc `422` với mã lỗi chung "tham chiếu không tồn tại", giống hệt khi tham chiếu tới định danh ngẫu nhiên |
| Tạo trùng mã nghiệp vụ `T-CODE` đã có ở A | Thành công (mã nghiệp vụ duy nhất trong phạm vi tenant); nếu bị từ chối với "đã tồn tại" thì là rò rỉ |
| Gửi `tenant_id` của A trong thân hoặc header `X-DH-Tenant` từ ngoài | Bị bỏ qua hoặc `ERR-00-003` (FR-00-010); bản ghi được tạo thuộc B |
| Thời gian phản hồi của định danh tồn tại ở A so với định danh ngẫu nhiên | Không phân biệt được về thống kê (kiểm tra kênh phụ ở D05-04, không chặn PR) |

: Kỳ vọng khi tenant B thao tác lên tài nguyên của tenant A

#### 5.6.2. Bộ kiểm thử tự động sinh theo mọi endpoint

Viết tay một ca rò rỉ cho mỗi endpoint là cần nhưng không đủ, vì dễ quên khi thêm endpoint. Datahub vì vậy có một **bộ kiểm thử sinh tự động** (`CrossTenantLeakageSuite`) trong thư viện kiểm thử dùng chung, chạy ở mức tích hợp hệ thống của mỗi DU, hoạt động như sau:

1. **Khám phá endpoint.** Bộ kiểm thử đọc toàn bộ ánh xạ endpoint lúc chạy (`RequestMappingHandlerMapping` của Spring, hoặc danh sách route của Quarkus) và đối chiếu với OpenAPI trong `contracts/`. Endpoint có trong mã mà không có trong hợp đồng, hoặc ngược lại, làm bộ kiểm thử thất bại — nhờ đó không endpoint nào "trốn" được.
2. **Phân loại.** Mỗi endpoint được phân loại theo phương thức và mẫu đường dẫn: đọc theo định danh, danh sách, ghi theo định danh, hành động, tạo. Endpoint nhóm `/api/platform/` (liên tenant, FR-00-012) và endpoint công khai không cần xác thực được đánh dấu bằng chú thích `@CrossTenantExempt(reason=…)`; danh sách miễn trừ được in vào báo cáo và được rà ở mỗi cổng.
3. **Gieo dữ liệu.** Với mỗi loại tài nguyên, bộ kiểm thử dùng "bộ gieo" (fixture factory) do phân hệ cung cấp — hợp đồng bắt buộc của mỗi module — để tạo một bản ghi hợp lệ dưới tenant `T90` và lấy định danh. Thiếu bộ gieo cho một loại tài nguyên có endpoint thì bộ kiểm thử thất bại với thông báo chỉ rõ module cần bổ sung.
4. **Tấn công.** Lấy token thật từ realm của tenant `T91` với vai trò mạnh nhất trong tenant (quản trị tenant) và với client máy; gọi mọi endpoint trên định danh của `T90` theo luật ở 5.6.1. Với danh sách và tìm kiếm, tìm kiếm thêm theo mã và tên của bản ghi `T90`.
5. **Kiểm tra phụ.** Sau mỗi thao tác ghi, kiểm tra lại bằng token `T90` rằng dữ liệu không đổi; kiểm tra bảng kiểm toán có bản ghi thất bại của `T91` mà không có dữ liệu `T90` trong trường giá trị.
6. **Báo cáo.** Xuất ma trận endpoint × thao tác × kết quả ở dạng JUnit XML và HTML, lưu làm bằng chứng cổng.

Bên cạnh bộ sinh tự động, các ca viết tay theo quy tắc 6 của D03-10 vẫn bắt buộc cho logic không suy ra được từ đường dẫn (ví dụ tham chiếu lồng trong thân yêu cầu, tham số lọc theo khóa ngoại, tệp đính kèm theo khóa đối tượng).

#### 5.6.3. Cách ly ở các tầng khác

Rò rỉ không chỉ qua REST. Bảng dưới đây liệt kê các kiểm thử cách ly theo tầng ở D03-10 §4, đều tự động.

| Tầng | Ca kiểm thử | Mức |
|---|---|---|
| PostgreSQL | Kết nối bằng vai trò ứng dụng, đặt `app.tenant_id = 'T91'`, `SELECT` mọi bảng nghiệp vụ (sinh từ `information_schema`) không thấy dòng của `T90`; không đặt biến phiên thì truy vấn lỗi; DU từ chối khởi động khi vai trò có `BYPASSRLS` | Tích hợp hệ thống |
| Migration | Lint migration: mọi bảng mới có `tenant_id NOT NULL` và chính sách RLS cùng changeset | PR (tĩnh) |
| Kafka | Principal của HTTT tenant `T91` không sản xuất, không tiêu thụ được topic `t90.*`; bản tin có header `dhtenant` không khớp tiền tố topic bị chuyển DLQ và phát cảnh báo | Tích hợp hệ thống; sau khởi tạo tenant |
| Valkey | Khóa luôn có tiền tố `{tenant}:` (kiểm thử hàm tạo tên); người dùng ACL của tenant không đọc khóa tenant khác | Đơn vị, tích hợp |
| Kho đối tượng | Khóa truy cập của `T91` không đọc, liệt kê được bucket `dh-t90-*`; URL ký sẵn của `T90` không dùng được để truy cập đối tượng khác | Tích hợp hệ thống |
| OPA | Mọi chính sách có ca `input.tenant != data.resource.tenant` cho kết quả từ chối | Đơn vị (`opa test`) |
| Keycloak, APISIX | Token realm `dh-t91` gọi route gắn nhãn tenant `T90` bị từ chối; header `X-DH-Tenant` do client gửi bị xóa | E2E |
| Quan sát | Người dùng quản trị tỉnh `T91` trên Grafana không thấy chỉ số, log, trace có nhãn `tenant="T90"` | E2E |
| Kho bí mật | Chính sách OpenBao của `T91` không đọc được `kv/dh/t90/*` | Tích hợp hệ thống |
| Tác vụ nền | Tác vụ chạy cho `T91` chỉ xử lý dữ liệu `T91` (gieo dữ liệu cả hai tenant, kiểm tra kết quả) | Tích hợp module |
| Trợ lý AI | Truy vấn ngữ nghĩa của `T91` không trả đoạn văn bản nhúng của `T90`; lời nhắc tiêm yêu cầu dữ liệu tenant khác bị từ chối | Tích hợp hệ thống |
| Sáp nhập tenant | Sau sáp nhập `T90` vào `T92`, `T91` vẫn không thấy dữ liệu nào; dữ liệu có `origin_tenant_id` đúng | Hệ thống |

: Ca kiểm thử cách ly ở các tầng ngoài API

Saga khởi tạo tenant (D03-10 §5.2) chạy chính bộ kiểm thử cách ly ở bước 9 (kiểm tra khói) dưới dạng rút gọn, để một tenant mới không bao giờ được chuyển `ACTIVE` khi ACL hay chính sách thiếu.

### 5.7. Kiểm thử khả năng truy cập (WCAG 2.2 AA)

Khả năng truy cập được kiểm thử ở ba tầng. **Tầng component**: mỗi component của `@datahub/ui` có câu chuyện Storybook cho mọi biến thể (sáng, tối, giảm trong suốt, trạng thái lỗi, vô hiệu) và addon a11y chạy axe-core trên từng câu chuyện trong CI. **Tầng màn hình**: mỗi màn `UI-{PH}-{nn}` có ít nhất một ca Playwright gọi `@axe-core/playwright` với thẻ quy tắc `wcag2a`, `wcag2aa`, `wcag21aa`, `wcag22aa` ở trạng thái đã tải dữ liệu và ở trạng thái mở hộp thoại; điều kiện đạt là 0 vi phạm mức A/AA (NFR-00-040). Lỗi axe ở tầng này chuyển Gate D hiện có của repo từ cảnh báo thành chặn từ cổng `RG-2`. **Tầng thủ công**: kiểm thử viên đã được đào tạo kiểm tra với trình đọc màn hình NVDA trên Firefox và Chrome (Windows) cho 10 luồng chính (danh sách chốt ở D05-05, ví dụ đăng nhập và MFA, kết nạp HTTT, công bố API, thiết kế và phát hành luồng, quản lý danh mục, duyệt yêu cầu, tra nhật ký kiểm toán, xử lý DLQ, khởi tạo tenant, đối soát thanh toán), theo bảng kiểm có các tiêu chí WCAG 2.2 mới như 2.4.11 Focus Not Obscured, 2.5.7 Dragging Movements (trình thiết kế luồng kéo thả phải có cách thao tác thay thế bằng bàn phím), 2.5.8 Target Size, 3.3.7 Redundant Entry, 3.3.8 Accessible Authentication.

Các NFR còn lại được kiểm chứng như sau. NFR-00-041 (tương phản): ngoài axe-core, một kiểm thử Playwright riêng chụp các thành phần chữ và vòng focus trên nền vật liệu glass đặt trên ba ảnh nền chuẩn (sáng, tối, nhiều màu) và tính tương phản thực tế từ điểm ảnh, vì axe-core không tính được tương phản qua `backdrop-filter`. NFR-00-042 (bàn phím): kịch bản Playwright chỉ dùng bàn phím đi hết 10 luồng chính, kiểm tra có liên kết "Bỏ qua tới nội dung" và thứ tự focus. NFR-00-043: chạy bộ visual regression với `reducedMotion: 'reduce'` và giả lập `prefers-reduced-transparency`, kiểm tra không còn hoạt ảnh và nền chuyển sang đặc. NFR-00-044: mọi ca axe và visual chạy ở cả hai chế độ sáng, tối. NFR-00-045: lint (ESLint quy tắc cấm import antd trực tiếp ngoài `@datahub/ui`, Stylelint cấm giá trị màu, khoảng cách không qua token `--dh-*`) chặn ở Gate C.

### 5.8. Kiểm thử di trú dữ liệu

Di trú (FR-00-090…093) có rủi ro điểm 9 (RSK-T09) và được kiểm thử như một sản phẩm riêng. Đối tượng gồm danh mục Aita (EAV), giao dịch thanh toán, cấu hình API, plan, application, subscription, topic, publisher, subscriber, luồng Camel XML.

**Dữ liệu nguồn kiểm thử.** Đội kiểm thử dựng một bản sao hệ cũ với dữ liệu tổng hợp có cùng lược đồ và cùng loại "bẩn" đã biết: số tiền sát và vượt giới hạn `int(10)` (2.147.483.647), `pay_date` ở nhiều định dạng chuỗi và giá trị rỗng, giá trị EAV mồ côi, ký tự tiếng Việt tổ hợp và dựng sẵn lẫn lộn, khóa trùng. Khi được chủ đầu tư cho phép, một bản trích dữ liệu thật **đã che** theo mục 8.3 được dùng cho diễn tập di trú trên môi trường UAT.

**Kiểm thử chuyển đổi.** Mỗi quy tắc chuyển đổi ở FR-00-091 có kiểm thử đơn vị dựa trên thuộc tính và kiểm thử với các giá trị biên. Bản ghi không chuyển được phải vào danh sách lỗi có lý do, không được im lặng bỏ qua.

**Đối chiếu.** Mỗi lần chạy công cụ di trú sinh báo cáo đối chiếu (FR-00-092) và bộ kiểm thử xác nhận báo cáo đó đúng bằng cách tính độc lập: số dòng theo từng thực thể và tenant ở nguồn và đích; tổng kiểm tra trên các cột khóa (băm SHA-256 của chuỗi giá trị đã chuẩn hóa theo khóa, sắp theo khóa); tổng tiền theo ngày, theo nhà cung cấp, theo trạng thái giao dịch phải khớp đến từng đồng; số dòng lỗi cộng số dòng thành công bằng số dòng nguồn. Điều kiện đạt: 100% khớp, hoặc sai khác được giải thích đầy đủ trong danh sách lỗi và được chủ quản dữ liệu chấp nhận.

**Luồng Camel XML.** Mỗi luồng XML của hệ cũ được chuyển sang YAML DSL bằng công cụ chuyển đổi, sau đó chạy cùng bộ bản tin đầu vào ghi lại từ hệ cũ trên cả hai phiên bản và so sánh đầu ra (mục 5.12); luồng dùng component không hỗ trợ native được đánh dấu chạy ở nhóm JVM (RSK-A02).

**Thông tin xác thực.** Kiểm thử âm xác nhận không bí mật nào của hệ cũ xuất hiện trong CSDL đích, log hay tệp báo cáo (FR-00-093): quét toàn bộ đích bằng danh sách giá trị bí mật mẫu đã gieo vào nguồn tổng hợp.

**Diễn tập.** Trước mỗi lần chuyển đổi một khối của hệ cũ, đội thực hiện ít nhất hai lần diễn tập di trú đầy đủ trên UAT, đo thời gian để lập kế hoạch cửa sổ chuyển đổi, và một lần diễn tập quay lui.

### 5.9. Kiểm thử song song strangler (so sánh hệ cũ – hệ mới)

Trong giai đoạn chuyển đổi (BP-09, REQ-22), mỗi API hoặc luồng được chuyển từ hệ cũ sang Datahub qua ba bước, mỗi bước có kiểm thử riêng.

```{.mermaid caption="Kiểm thử song song strangler (so sánh hệ cũ – hệ mới)"}
flowchart TB
  HT[HTTT gọi] --> GWO[Gateway cũ / điểm chia lưu lượng]
  GWO -->|100% phản hồi thật| OLD[Hệ LGSP cũ]
  GWO -.->|bản sao bất đồng bộ| SH[Bộ nhân bản lưu lượng]
  SH -.-> NEW[Datahub - chế độ bóng]
  OLD --> CMP[Bộ so sánh phản hồi]
  NEW --> CMP
  CMP --> RPT[Báo cáo sai khác<br/>theo API, theo trường]
```

Sơ đồ mô tả bước thứ nhất, **chạy bóng**: lưu lượng thật tới hệ cũ được nhân bản bất đồng bộ (bằng tính năng mirror của APISIX hoặc Istio đặt trước hệ cũ, hoặc ghi lại rồi phát lại) tới Datahub; Datahub xử lý nhưng phản hồi của nó không trả cho HTTT. Bộ so sánh ghép cặp phản hồi theo mã tương quan, chuẩn hóa các trường được phép khác (dấu thời gian, `trace_id`, thứ tự phần tử không có nghĩa, định dạng số) theo bảng luật do chủ quản API duyệt, rồi so sánh mã trạng thái, cấu trúc và giá trị. Chỉ yêu cầu đọc (idempotent) được nhân bản; yêu cầu ghi chỉ được nhân bản khi đích của Datahub trỏ tới đích giả lập, để không ghi hai lần vào hệ nghiệp vụ. Bước thứ hai, **chuyển dần** (canary): 5% → 25% → 50% → 100% lưu lượng sang Datahub, mỗi nấc giữ ít nhất 24 giờ làm việc và chỉ lên nấc khi tỷ lệ lỗi và độ trễ không kém hệ cũ. Bước thứ ba, **tắt hệ cũ** sau khi giữ 100% đủ thời gian quan sát do chủ đầu tư quyết định.

Điều kiện chuyển từ chạy bóng sang chuyển dần cho một API: ít nhất 7 ngày làm việc chạy bóng, ít nhất 10.000 cặp so sánh hoặc toàn bộ lưu lượng nếu ít hơn, tỷ lệ cặp khớp ≥ 99,9% sau chuẩn hóa, và mọi sai khác còn lại đã được phân tích là lỗi của hệ cũ hoặc thay đổi có chủ ý (ví dụ lỗi trả theo RFC 9457 thay cho định dạng cũ). Với sự kiện, cầu nối Pulsar–Kafka được kiểm thử bằng đếm và so sánh băm bản tin hai phía theo cửa sổ thời gian.

> **Câu hỏi mở Q363:** Việc nhân bản lưu lượng thật sang Datahub trong chế độ bóng là xử lý dữ liệu (có thể chứa dữ liệu cá nhân) trên hệ thống mới chưa vận hành chính thức. Cần chủ đầu tư và bộ phận pháp chế xác nhận căn cứ xử lý theo Luật 91/2025/QH15, và quyết định Datahub phải đạt những cổng nào (tối thiểu `RG-3` về bảo mật) trước khi nhận lưu lượng bóng.

### 5.10. Kiểm thử thanh toán PH-19

PH-19 có rủi ro điểm 9 (RSK-T08) vì liên quan tới tiền và dữ liệu tài chính. Kiểm thử gồm năm nhóm. **Nhóm máy trạng thái giao dịch**: mọi chuyển trạng thái hợp lệ và không hợp lệ (bảng quyết định từ máy trạng thái trong FRS PH-19, phụ thuộc Q03 của D00-03 về mã kết quả PayGov). **Nhóm idempotency và đồng thời**: gửi trùng lệnh tạo giao dịch cùng `Idempotency-Key` song song 50 luồng chỉ tạo một giao dịch; callback kết quả gửi lặp 10 lần chỉ ghi nhận một lần; callback đến trước phản hồi đồng bộ. **Nhóm chữ ký và chống giả mạo**: callback có chữ ký sai, thiếu, quá cửa sổ thời gian, phát lại mã sự kiện cũ đều bị từ chối và ghi kiểm toán; khóa ký nằm trong OpenBao transit, kiểm thử xác nhận không có khóa trong cấu hình DU. **Nhóm số tiền**: `T-MONEY` với giá trị 0, 1, giá trị vượt 2,1 tỷ, giá trị cực đại `numeric(19,0)`, hoàn tiền một phần, hoàn tiền nhiều lần không vượt số gốc. **Nhóm đối soát**: tệp đối soát tổng hợp có giao dịch khớp, lệch số tiền, có ở kênh mà không có ở Datahub và ngược lại, trùng dòng, tệp hỏng định dạng; kiểm chứng KPI-13 (≥ 99,5% tự động khớp trên tập dữ liệu chuẩn có tỷ lệ lệch biết trước) và KPI-14 (giao dịch lệch được phát hiện và cảnh báo trong ≤ 1 ngày làm việc, đo với đồng hồ giả lập).

Môi trường: ở CI và TEST, PayGov và các kênh thanh toán được giả lập bằng WireMock với kịch bản trạng thái (stateful scenario) và sinh tệp đối soát; ở STAGING, kết nối **sandbox của PayGov** (môi trường thử do PayGov cấp) để kiểm thử hợp đồng thật, chạy định kỳ hằng đêm bộ hợp đồng rút gọn và trước mỗi cổng bộ đầy đủ. Mỗi nhà cung cấp hoặc dịch vụ mới khi kích hoạt phải chạy giao dịch thử (PH-19 năng lực "kích hoạt có giao dịch thử"). Trong giai đoạn song song với khối Payment cũ, đối soát chéo kết quả hai hệ theo ngày là một phần của mục 5.9.

> **Câu hỏi mở Q364:** Cần xác nhận PayGov có cung cấp môi trường sandbox cho tích hợp mới, điều kiện cấp (hồ sơ, thời gian), có tệp đối soát mẫu và có giới hạn số giao dịch thử hay không. Nếu không có, kiểm thử hợp đồng thật chỉ thực hiện được trong UAT với giao dịch giá trị nhỏ, cần chủ đầu tư chấp thuận.

### 5.11. Kiểm thử adapter NDXP (PH-14) bằng giả lập

NDXP và các CSDL quốc gia không cho phép gọi tự do từ môi trường phát triển, và đặc tả có thể thay đổi (RSK-A04). Kiểm thử adapter vì vậy dựa trên giả lập có độ trung thực cao. **Microcks** nạp đặc tả của từng nhóm dịch vụ (OpenAPI cho REST, WSDL kèm ví dụ cho SOAP) và phục vụ phản hồi mẫu; WireMock được dùng cho kịch bản lỗi khó mô phỏng bằng đặc tả (hết hạn token OAuth do NDXP cấp, trả `5xx` gián đoạn, phản hồi chậm, phản hồi sai schema, SOAP Fault). Mỗi adapter có kiểm thử: lấy và làm mới token với NDXP, ánh xạ yêu cầu và phản hồi sang CDM, xử lý mọi mã lỗi đặc tả, thời gian chờ và thử lại có giới hạn, không lộ thông tin xác thực NDXP cho HTTT tỉnh (REQ-14), ghi nhật ký khai thác đủ trường cho KPI-07.

Kiểm thử hợp đồng thật được chạy hằng đêm từ STAGING tới môi trường thử của NDXP (nếu có) với một bộ yêu cầu chuẩn; kết quả khác với ví dụ trong giả lập làm phát cảnh báo cho nhóm PH-14 cập nhật đặc tả và giả lập trước khi lỗi xảy ra trên PROD. Danh sách dịch vụ được kiểm thử phụ thuộc danh mục dịch vụ hiện hành của NDXP (Q02 của D00-03).

> **Câu hỏi mở Q365:** Cần xác nhận NDXP có môi trường thử (staging) cho tỉnh, phạm vi dịch vụ có dữ liệu thử, và quy định về việc dùng dữ liệu thử của CSDL quốc gia (ví dụ công dân giả lập của CSDL dân cư) trong kiểm thử tự động định kỳ.

### 5.12. Kiểm thử luồng Camel (PH-04, PH-05)

Luồng tích hợp là mã do kỹ sư tích hợp của tỉnh viết qua trình thiết kế, nên kiểm thử luồng vừa là việc của đội sản phẩm (khung, Kamelet, error handler chuẩn) vừa là năng lực sản phẩm cung cấp cho người dùng (chạy thử trước khi phát hành, PH-04). Đội sản phẩm kiểm thử như sau. Mỗi Kamelet được duyệt có kiểm thử tích hợp với hệ đích thật trong Testcontainers (PostgreSQL, MySQL, Oracle XE nếu giấy phép cho phép, SQL Server, SFTP, máy chủ SOAP giả lập, Kafka, ActiveMQ Artemis). Khung route chuẩn có kiểm thử cho error handler: thử lại theo cấu hình, chuyển DLQ sau khi hết lần thử, bản tin trong DLQ được mã hóa và có hạn 7 ngày (SAD §8.3), xử lý lại từ DLQ idempotent. Luồng mẫu được kiểm thử bằng Camel Test JUnit 5 (`AdviceWith` thay đích bằng `mock:`), và chạy lại trên ảnh native bằng `@QuarkusIntegrationTest` vì phản xạ và tài nguyên có thể thiếu khi biên dịch native (RSK-A02). Trình thiết kế được kiểm thử về tính tương đương: YAML sinh từ giao diện kéo thả rồi nạp lại cho cùng sơ đồ (kiểm thử vòng tròn), và YAML hợp lệ theo schema Camel YAML DSL của phiên bản Camel đã ghim.

Đường phát hành luồng (dh-integration → Git → Argo CD → dh-runtime) có kiểm thử E2E: luồng được duyệt xuất hiện trên runtime trong thời gian chốt ở FRS PH-04, quay lui đưa phiên bản cũ trở lại, không có đường nào cho giao diện ra lệnh trực tiếp tới runtime (kiểm thử âm ở chính sách mạng).

Lưu ý: tính năng chạy thử của repo hiện đang mô phỏng (`RoutesService.testRun` dựng waterfall cố định, xem `docs/08-implementation/04-ke-hoach-phat-trien.md` WP-25). Kiểm thử chức năng của FR chạy thử chỉ được tính đạt khi chạy thử nạp Camel thật.

### 5.13. Kiểm thử giao diện Liquid Glass và hồi quy hiển thị

Giao diện theo phong cách Liquid Glass trên antd v6 (ADR-020) có rủi ro hiển thị riêng: hiệu ứng `backdrop-filter` khác nhau giữa trình duyệt, tương phản thay đổi theo nền, hiệu năng trên máy yếu. Kiểm thử gồm: **visual regression** ở tầng component bằng Storybook kết hợp Playwright chụp ảnh (`toHaveScreenshot`) cho mọi biến thể × sáng/tối × giảm trong suốt, và ở tầng màn hình cho các mẫu bố cục `PTN-nn`, với ngưỡng sai khác điểm ảnh 0,1% và ảnh chuẩn được duyệt bởi người thiết kế; ảnh chụp được tạo trong container cố định phông chữ để không lệch do hệ điều hành. **Kiểm thử dự phòng hiệu ứng**: giả lập máy yếu (CPU throttling ×4 trong Chrome DevTools Protocol) và kiểm tra cơ chế tự chuyển nền đặc ở D03-05 hoạt động. **Kiểm thử token**: so sánh giá trị token sinh ra với nguồn token, bảo đảm tương phản các cặp màu chuẩn đạt ngưỡng NFR-00-041 bằng kiểm thử đơn vị tính tương phản OKLCH.

### 5.14. Kiểm thử tương thích trình duyệt và thiết bị

Theo SRS §2.2, giao diện phải chạy trên hai phiên bản ổn định mới nhất của Chrome, Edge, Firefox, Safari và trên Cốc Cốc. Bộ E2E và visual regression chạy hằng đêm trên ba nhân Chromium, Firefox, WebKit của Playwright. Trước mỗi `RG-3`, kiểm thử viên chạy bộ E2E khói trên trình duyệt có thương hiệu thật (Chrome, Edge, Firefox trên Windows; Safari trên macOS; Cốc Cốc trên Windows) ở hai phiên bản, độ phân giải 1280×720 và 1920×1080 cho `dh-console`, và 360 px, 768 px cho `dh-portal` và màn xem báo cáo. Kết quả ghi theo ma trận trình duyệt × phiên bản × luồng.

### 5.15. Các loại kiểm thử khác

Ba loại kiểm thử sau có phạm vi nhỏ nhưng bắt buộc. **Kiểm thử cài đặt và nâng cấp**: cài mới hồ sơ tỉnh độc lập từ gói air-gapped trên cụm sạch không có Internet (NFR-00-056), nâng cấp từ phiên bản phát hành trước lên phiên bản mới có dữ liệu (migration Liquibase tiến, không mất dữ liệu), và khởi tạo tenant trên nền tảng dùng chung đo thời gian (NFR-00-057, ≤ 1 giờ tự động). **Kiểm thử khả năng vận hành**: kiểm tra 100% thành phần có liveness, readiness và chỉ số Prometheus (NFR-00-050) bằng một kiểm thử quét manifest và gọi điểm cuối; 100% log là JSON có `trace_id`, `tenant_id` (NFR-00-051) bằng kiểm thử lấy mẫu log trên TEST; thay đổi tham số áp dụng ≤ 60 giây không khởi động lại (NFR-00-052); kiểm tra lưu giữ log 90 ngày và nhật ký kiểm toán 12 tháng (NFR-00-027, 028) bằng kiểm tra cấu hình lưu giữ và truy vấn dữ liệu cũ nhất có. **Kiểm thử trợ lý AI** (PH-17, đợt 3): bộ câu hỏi chuẩn có đáp án để đo độ chính xác tìm dịch vụ, bộ lời nhắc tấn công để kiểm tra chống tiêm lời nhắc và rò rỉ dữ liệu, kiểm tra tắt hoàn toàn theo tenant.

## 6. Tiêu chí vào, ra và cổng phát hành

### 6.1. Cổng chất lượng ở mức PR

Ở mức PR, Datahub dùng lại các cổng CI đã có trong repo (`docs/08-implementation/02-huong-dan-lap-trinh.md` §7) và bổ sung nội dung kiểm thử; quy trình Git và cổng CI được ADR-037 và D04-02 chính thức hóa. Bảng dưới đây ghi nội dung kiểm thử mà mỗi cổng phải chứa theo kế hoạch này.

| Cổng CI | Nội dung kiểm thử bắt buộc theo D05-01 | Chặn merge |
|---|---|---|
| Gate A | Đơn vị, tích hợp module (`verify()`, ArchUnit), tích hợp hệ thống của module bị đổi, **bộ rò rỉ chéo tenant của DU bị đổi**, kiểm thử luồng Camel nếu đụng `routes/`, độ phủ mã mới đạt ngưỡng NFR-00-053 | Có |
| Gate B | Spectral, oasdiff, kiểm tra tương thích schema sự kiện, Pact (xác minh bên cung cấp, `can-i-deploy`) | Có |
| Gate C | Lint, kiểm tra kiểu, Vitest, lint token NFR-00-045, axe-core trên Storybook | Có |
| Gate D | axe-core trên màn bị đổi | Cảnh báo trước `RG-2`; chặn từ `RG-2` |
| Gate S | gitleaks, Semgrep, Trivy (thư viện, IaC, ảnh) | Có với phát hiện vượt ngưỡng mục 5.5 |

: Nội dung kiểm thử bắt buộc của từng cổng CI ở mức PR

### 6.2. Cổng phát hành RG-1 … RG-5

Cổng phát hành là điểm kiểm soát mà một bản dựng phải vượt qua trước khi lên môi trường hoặc giai đoạn tiếp theo. Mã `RG-{n}` được đề xuất mới (mục 20). Các cổng này là cổng kỹ thuật của kiểm thử; chúng là đầu vào cho cổng quản lý dự án (G1, G2… ở D01-02), không thay thế cổng quản lý.

```{.mermaid caption="Chuỗi cổng phát hành RG-1 … RG-5"}
flowchart TB
  PR[PR<br/>Gate A B C D S] --> RG1[RG-1<br/>Vào TEST]
  RG1 --> RG2[RG-2<br/>Ứng viên phát hành<br/>vào STAGING, PERF]
  RG2 --> RG3[RG-3<br/>Kết thúc kiểm thử hệ thống<br/>vào UAT]
  RG3 --> RG4[RG-4<br/>Nghiệm thu, vận hành<br/>PROD theo đợt]
  RG4 --> RG5[RG-5<br/>Cắt chuyển từng khối hệ cũ]
```

Sơ đồ cho thấy chuỗi cổng tuyến tính cho một đợt phát hành. Cổng `RG-1` diễn ra liên tục (mỗi lần merge); `RG-2` diễn ra mỗi khi đóng gói một bản ứng viên phát hành (thường cuối mỗi wave); `RG-3`, `RG-4` diễn ra một lần mỗi đợt (MVP, đợt 2, đợt 3) và có thể lặp nếu không đạt; `RG-5` diễn ra cho từng khối hệ cũ (Bus, Hub, APIM, DMDC, Payment) sau khi đợt chứa phân hệ thay thế đã qua `RG-4`.

Bảng dưới đây chốt tiêu chí vào, tiêu chí ra và người quyết định của từng cổng. Một cổng chỉ đạt khi mọi tiêu chí ra đạt hoặc có ngoại lệ ghi bằng văn bản được người quyết định ký.

| Cổng | Tiêu chí vào | Tiêu chí ra | Người quyết định |
|---|---|---|---|
| RG-1 Vào TEST | Mọi cổng PR đạt; merge vào nhánh chính | Triển khai tự động lên TEST thành công; kiểm thử khói đạt; toàn bộ tích hợp hệ thống và bộ rò rỉ chéo tenant của mọi DU đạt | Tự động |
| RG-2 Ứng viên phát hành | RG-1 đạt cho bản dựng; danh sách tính năng của bản ghi trong ghi chú phát hành | Toàn bộ hồi quy tự động đạt; E2E đầy đủ đạt trên ba nhân trình duyệt; 0 lỗi S1 mở, 0 lỗi S2 mở thuộc tính năng trong bản; ảnh ký cosign, SBOM đính kèm; Pact `can-i-deploy` đạt; DAST hằng đêm 0 High; kịch bản tải rút gọn không suy giảm > 10% | Trưởng nhóm kiểm thử |
| RG-3 Kết thúc kiểm thử hệ thống | RG-2 đạt; STAGING, PERF sẵn sàng; test case của D05-02 cho các PH trong đợt đã được rà soát | 100% TC mức M đã chạy, ≥ 98% đạt, phần không đạt không thuộc S1/S2; mọi FR mức M có ít nhất hai TC dương/âm đạt; mọi NFR áp dụng của đợt đạt theo ma trận mục 17 (hiệu năng, chaos CX-01…08, khôi phục, a11y, tương thích); bảng kiểm ASVS L2 đạt; pentest 0 Critical/High mở; bộ rò rỉ chéo tenant 100% với danh sách miễn trừ đã rà; độ phủ đạt NFR-00-053; tài liệu cài đặt và HDVH đã được kiểm thử thao tác | Hội đồng chất lượng (Trưởng nhóm kiểm thử, Trưởng nhóm kỹ thuật, Trưởng nhóm ATTT) |
| RG-4 Nghiệm thu, vận hành | RG-3 đạt; UAT hoàn tất theo D05-05; diễn tập DR gần nhất đạt; 14 ngày đo sẵn sàng trên STAGING đạt | Biên bản UAT ký; 0 lỗi S1, S2 mở; lỗi S3 còn mở có kế hoạch sửa được chủ đầu tư chấp nhận; các KPI "Từ nghiệm thu" đạt (KPI-03, 04, 07, 09, 12, 15, 16, 17); KPI-18 SUS ≥ 75; hồ sơ cấp độ có bằng chứng kiểm thử (D03-08); kế hoạch quay lui đã diễn tập | Chủ đầu tư |
| RG-5 Cắt chuyển khối hệ cũ | RG-4 của đợt chứa phân hệ thay thế đạt; di trú đã diễn tập ≥ 2 lần | Báo cáo đối chiếu di trú 100% khớp hoặc sai khác được chấp nhận; chạy bóng đạt điều kiện mục 5.9; chuyển dần 100% giữ đủ thời gian quan sát không có sự cố S1; đơn vị vận hành xác nhận | Chủ đầu tư, đơn vị vận hành tỉnh |

: Tiêu chí vào, tiêu chí ra và người quyết định của từng cổng phát hành

### 6.3. Tiêu chí tạm dừng và tiếp tục

Kiểm thử ở một mức hoặc trên một môi trường được tạm dừng khi xảy ra một trong các điều kiện: kiểm thử khói thất bại sau triển khai; có lỗi S1 chặn trên 30% số ca của đợt chạy; môi trường không ổn định khiến trên 10% số ca thất bại vì nguyên nhân hạ tầng; phát hiện dữ liệu cá nhân thật trên môi trường kiểm thử (dừng ngay, xử lý theo mục 8.3). Kiểm thử tiếp tục khi nguyên nhân đã được khắc phục, kiểm thử khói đạt lại và trưởng nhóm kiểm thử xác nhận; các ca đã chạy trên bản dựng lỗi được chạy lại.

## 7. Môi trường kiểm thử

### 7.1. Danh sách môi trường

Datahub dùng năm môi trường phi sản xuất. Bảng dưới đây mô tả mục đích, cấu hình, dữ liệu và cách triển khai của từng môi trường. Mọi môi trường được triển khai bằng Argo CD từ cùng bộ manifest Kustomize với overlay riêng (NT-06), nhờ đó khác biệt giữa môi trường chỉ nằm ở overlay và được rà soát được.

| Môi trường | Mục đích | Cấu hình | Dữ liệu | Triển khai | Dịch vụ ngoài |
|---|---|---|---|---|---|
| DEV | Phát triển, gỡ lỗi; môi trường tạm theo PR (preview) cho E2E của PR lớn | Tối giản: 1 bản sao, Docker Compose hoặc namespace tạm trên cụm dùng chung | Dữ liệu gieo tối thiểu | Tự động theo nhánh | Giả lập WireMock, Microcks |
| TEST | Tích hợp liên tục, E2E, hồi quy đêm, DAST hằng đêm | Thu nhỏ hồ sơ dùng chung: 2 bản sao cho data plane, đủ mọi thành phần (Keycloak, OPA, Kafka, OpenBao, Garage, LGTM), Istio và Cilium bật như sản xuất | Tổng hợp, sinh lại hằng tuần; tenant `T90`, `T91`, `T92` và tenant tạm theo lần chạy | Tự động mỗi lần merge | Giả lập |
| STAGING | Ứng viên phát hành, kiểm thử hệ thống, chaos, DR, kiểm thử xâm nhập; giống sản xuất | Như hồ sơ sản xuất về số bản sao, chính sách mạng, TLS, WAF; hai site cho diễn tập DR | Tổng hợp quy mô trung bình | Có duyệt, theo `RG-2` | Sandbox PayGov, môi trường thử NDXP (nếu có), còn lại giả lập |
| PERF | Kiểm thử hiệu năng, bền, chịu tải | Đúng hồ sơ "tỉnh vừa" của D03-09; nút sinh tải k6 tách riêng cụm để không tranh tài nguyên | Tổng hợp khối lượng lớn (1 triệu bản ghi màn danh sách, 2.000 API, 500 luồng, 34 tenant) | Có duyệt, theo lịch | Giả lập có độ trễ cấu hình được |
| UAT | Kiểm thử chấp nhận, diễn tập di trú, đào tạo | Như STAGING một site | Tổng hợp có hình dạng tỉnh thí điểm; bản trích hệ cũ đã che khi được phép | Có duyệt, theo `RG-3` | Sandbox PayGov, môi trường thử NDXP, HTTT giả lập và HTTT thử của sở nếu có |

: Năm môi trường kiểm thử theo mục đích, cấu hình, dữ liệu và cách triển khai

PERF và STAGING có thể dùng chung cụm vật lý luân phiên theo lịch để tiết kiệm tài nguyên, với điều kiện khi chạy hiệu năng không có hoạt động nào khác trên cụm. Việc mỗi môi trường đặt ở TTDL tỉnh thí điểm hay ở hạ tầng của nhà thầu phụ thuộc thỏa thuận (Q366).

> **Câu hỏi mở Q366:** Cần chốt nơi đặt và nguồn tài nguyên cho STAGING, PERF và UAT (TTDL tỉnh thí điểm, cloud Chính phủ hay hạ tầng nhà thầu), vì PERF phải đúng hồ sơ "tỉnh vừa" và STAGING phải có hai site để diễn tập DR. Quyết định này ảnh hưởng chi phí và lịch ở mục 14.

### 7.2. Giả lập dịch vụ ngoài

Bảng dưới đây liệt kê các dịch vụ ngoài được giả lập, công cụ và nguồn đặc tả. Giả lập được đóng gói thành ảnh container trong Harbor, có phiên bản, và cấu hình nằm trong kho Git kiểm thử để mọi môi trường dùng cùng hành vi.

| Dịch vụ ngoài | Công cụ giả lập | Nguồn đặc tả | Ghi chú |
|---|---|---|---|
| NDXP và dịch vụ quốc gia | Microcks (REST, SOAP), WireMock cho kịch bản lỗi | Đặc tả hiện hành từ NDXP (Q02) | Có chế độ token OAuth giả |
| PayGov và kênh thanh toán | WireMock có trạng thái; bộ sinh tệp đối soát | Đặc tả PayGov (Q03, Q364) | Callback có ký bằng khóa kiểm thử |
| HTTT của sở (bên cung cấp và bên dùng) | Ứng dụng HTTT giả lập (REST, webhook nhận, Kafka client) do đội kiểm thử viết | Hợp đồng trong `contracts/` | Ghi lại mọi yêu cầu nhận được để kiểm tra |
| Hệ cũ (CSDL, FTP, SOAP) | Testcontainers: CSDL, SFTP; Microcks cho SOAP | Lược đồ hệ cũ | Dữ liệu tổng hợp |
| LGSP cũ (Pulsar, gateway cũ) | Pulsar container, bản sao lược đồ CSDL cũ | Tài liệu hệ cũ | Cho kiểm thử cầu nối, di trú |
| VNeID | Realm Keycloak giả lập OIDC | Chuẩn OIDC | Khi có yêu cầu |
| Máy chủ thư, SMS | Mailpit, WireMock | — | Kiểm tra nội dung thư không chứa dữ liệu Hạn chế (FR-00-062) |
| LDAP/AD | OpenLDAP container | — | Cho PH-12 |
| SIEM tỉnh | Bộ nhận Syslog/OTLP giả lập | RFC 5424, OTLP | IF-08 |

: Công cụ và nguồn đặc tả để giả lập từng dịch vụ ngoài

## 8. Dữ liệu kiểm thử và che dữ liệu

### 8.1. Nguyên tắc

Kế hoạch đặt một nguyên tắc cứng: **không dùng dữ liệu cá nhân thật trong mọi môi trường kiểm thử** (DEV, TEST, STAGING, PERF), và chỉ dùng dữ liệu thật đã che ở UAT khi có văn bản chấp thuận của chủ đầu tư nêu căn cứ xử lý theo Luật 91/2025/QH15 và Nghị định 356/2025/NĐ-CP. Lý do là môi trường kiểm thử có nhiều người truy cập hơn, kiểm soát lỏng hơn sản xuất, và dữ liệu đi qua Datahub có thể thuộc diện nhạy cảm (số định danh, sức khỏe, tài chính). Mọi tài liệu, ảnh chụp, trace đính kèm báo cáo lỗi cũng tuân theo nguyên tắc này (D00-01 §8).

### 8.2. Dữ liệu tổng hợp

Dữ liệu tổng hợp được sinh bằng một bộ sinh dữ liệu chung (`dh-testdata`, dựa trên Datafaker với bộ từ điển tiếng Việt và luật riêng) có hạt giống (seed) cố định để tái lập được. Bộ sinh tạo: tổ chức, HTTT, API từ OpenAPI mẫu, luồng, danh mục với thuộc tính động, người dùng mỗi vai trò, giao dịch thanh toán, sự kiện. Dữ liệu có dạng cá nhân dùng giá trị **rõ ràng là giả**: số định danh 12 chữ số trong dải mã tỉnh không tồn tại, số điện thoại trong dải dành cho kiểm thử, thư điện tử thuộc miền `example.gov.vn`, tên ghép ngẫu nhiên. Mã tenant kiểm thử dùng dải `T90`–`T99`, ngoài dải mã tỉnh thật. Danh mục đơn vị hành chính dùng bản công khai (dữ liệu `COMMON`), vì đây là dữ liệu công khai, kèm các trường hợp sáp nhập để kiểm thử lịch sử hiệu lực.

Bộ dữ liệu được tổ chức thành ba cỡ: **nhỏ** (gieo cho từng ca kiểm thử, tạo và hủy trong ca), **chuẩn** (môi trường TEST, STAGING, UAT: khoảng 10 tenant, mỗi tenant 50 HTTT, 500 API) và **lớn** (PERF: hồ sơ "tỉnh vừa" và 34 tenant). Mỗi ca kiểm thử tự động tự tạo dữ liệu mình cần qua API hoặc bộ gieo, không phụ thuộc thứ tự chạy và không phụ thuộc dữ liệu do ca khác để lại.

### 8.3. Che dữ liệu khi buộc dùng dữ liệu từ hệ cũ

Khi diễn tập di trú cần dữ liệu có "độ bẩn" thật mà dữ liệu tổng hợp không mô phỏng hết, bản trích được che **trước khi rời môi trường sản xuất của hệ cũ**, trong vùng do đơn vị vận hành hệ cũ kiểm soát. Kỹ thuật che theo mức phân loại ở SAD §8.2: trường Nhạy cảm thay bằng giá trị tổng hợp giữ định dạng (format-preserving) và giữ tính nhất quán tham chiếu (cùng giá trị gốc cho cùng giá trị che trong một lần trích, qua hàm băm có khóa bí mật bị hủy sau khi trích); trường Hạn chế được che một phần hoặc làm nhiễu; số tiền giữ nguyên để kiểm thử chuyển đổi `int(10)` nhưng tách khỏi định danh người nộp. Bản trích đã che được kiểm tra bằng bộ quét mẫu dữ liệu trước khi nạp vào UAT; biên bản che dữ liệu được lưu.

> **Câu hỏi mở Q367:** Cần chủ đầu tư quyết định có cho phép dùng bản trích dữ liệu hệ cũ đã che cho diễn tập di trú ở UAT hay không, ai thực hiện việc che (đơn vị vận hành hệ cũ hay nhà thầu) và có cần đánh giá tác động xử lý dữ liệu cá nhân cho hoạt động này hay không.

### 8.4. Dữ liệu canary để phát hiện rò rỉ

Để kiểm chứng NFR-00-029 (0 giá trị trường Nhạy cảm trong log) và RSK-T07, bộ sinh dữ liệu gieo **giá trị canary**: các giá trị Nhạy cảm có mẫu đặc trưng dễ tìm (ví dụ số định danh bắt đầu bằng tiền tố canary cố định). Một tác vụ hằng đêm quét toàn bộ log trên Loki, trace trên Tempo, thân bản tin DLQ, thư trong Mailpit, tệp xuất và bản ghi kiểm toán của TEST và STAGING tìm các mẫu canary (và mẫu tổng quát số định danh, số tài khoản). Mỗi phát hiện là lỗi S1 bảo mật.

## 9. Tự động hóa và tích hợp liên tục

### 9.1. Kiến trúc tự động hóa

Mã kiểm thử nằm cùng kho với mã sản phẩm: kiểm thử đơn vị, module, tích hợp hệ thống nằm trong `src/test` của từng DU; kiểm thử giao diện cạnh component; E2E, kịch bản k6, thí nghiệm Chaos Mesh, cấu hình ZAP và giả lập nằm ở `tests/` (lane `L-QA`). Thư viện kiểm thử dùng chung (`libs/test-support`) chứa lớp cơ sở Testcontainers, bộ lấy token từ Keycloak kiểm thử, `CrossTenantLeakageSuite`, bộ gieo dữ liệu và trợ giúp kiểm tra Problem Details.

### 9.2. Ngân sách thời gian pipeline

Bảng dưới đây đặt ngân sách thời gian để vòng phản hồi đủ nhanh cho lập trình viên. Vượt ngân sách hai tuần liên tiếp là tín hiệu buộc tối ưu (song song hóa, chọn ca theo thay đổi, đẩy kiểm tra xuống mức thấp hơn).

| Giai đoạn pipeline | Nội dung | Ngân sách (p90) |
|---|---|---|
| PR — kiểm tra nhanh | Biên dịch, lint, đơn vị, ArchUnit, `verify()`, gitleaks, Semgrep | ≤ 8 phút |
| PR — kiểm tra đầy đủ | Tích hợp hệ thống của module bị đổi, rò rỉ chéo tenant của DU bị đổi, hợp đồng, Trivy, Vitest, axe Storybook | ≤ 20 phút tổng PR |
| Sau merge | Toàn bộ tích hợp hệ thống mọi DU, dựng ảnh native `dh-runtime`, ký ảnh, triển khai TEST, E2E khói | ≤ 35 phút |
| Hằng đêm | E2E đầy đủ ba trình duyệt, visual regression, đột biến PIT, ZAP, tải rút gọn, quét canary, hợp đồng thật NDXP/PayGov | ≤ 4 giờ |
| Hằng tuần | Bền 8 giờ trên PERF, chaos CX-01 rút gọn, CX-03, CX-05, kube-bench | Theo lịch |

: Ngân sách thời gian p90 của từng giai đoạn pipeline

### 9.3. Tiêu chí chọn ca để tự động hóa

Một ca kiểm thử được tự động hóa khi nó chạy lặp lại ở mỗi bản dựng, có kết quả mong đợi xác định được bằng máy, và chi phí bảo trì thấp hơn chi phí chạy tay qua vòng đời. Ca thuộc phân hệ rủi ro Rất cao được tự động hóa toàn bộ phần hồi quy (mục 3.2). Ca không tự động hóa: kiểm thử khám phá, kiểm tra trình đọc màn hình, đánh giá trải nghiệm, UAT, kiểm thử xâm nhập thủ công.

### 9.4. Báo cáo kết quả tự động

Mọi công cụ xuất kết quả về định dạng chuẩn (JUnit XML, SARIF, JSON của k6) và được tổng hợp trên một bảng điều khiển chất lượng (Allure Report hoặc ReportPortal) liên kết với mã TC, mã FR, mã NFR qua chú thích trong mã kiểm thử (ví dụ `@Tag("TC-07-045")`, `@Tag("FR-07-021")`). Nhờ liên kết này, RTM cập nhật được trạng thái kiểm thử của từng FR tự động.

### 9.5. Quản lý ca bất ổn

Ca bất ổn phá niềm tin vào pipeline. Hệ thống CI ghi lại mọi ca thất bại rồi đạt khi chạy lại; ca có tỷ lệ bất ổn > 2% trong 14 ngày bị cách ly (quarantine) khỏi tầng chặn merge, gán chủ sở hữu và phải sửa trong 5 ngày làm việc; ca cách ly quá 10 ngày làm việc phải sửa hoặc xóa có lý do. Ca thuộc bộ rò rỉ chéo tenant không bao giờ được cách ly: nếu bất ổn thì sửa ngay và chặn merge cho tới khi sửa xong. Chỉ tiêu toàn bộ: tỷ lệ ca bất ổn < 1%.

## 10. Quản lý lỗi

### 10.1. Mức nghiêm trọng và mức ưu tiên

Mỗi lỗi có hai thuộc tính độc lập. **Mức nghiêm trọng** (S1–S4) do người phát hiện đề xuất và trưởng nhóm kiểm thử xác nhận, đo tác động kỹ thuật và nghiệp vụ. **Mức ưu tiên** (P1–P4) do quản lý sản phẩm quyết định, đo thứ tự sửa. Thông thường ưu tiên đi theo nghiêm trọng, nhưng một lỗi S3 chặn buổi UAT có thể được nâng P1.

| Mức | Định nghĩa | Ví dụ |
|---|---|---|
| S1 Nghiêm trọng | Lộ dữ liệu (đặc biệt chéo tenant), lỗ hổng bảo mật Critical/High, sai lệch tiền, mất dữ liệu, data plane ngừng, không có cách làm thay | Bộ rò rỉ chéo tenant thất bại; callback giả mạo được chấp nhận; giá trị canary trong log |
| S2 Cao | Chức năng mức M không dùng được hoặc sai, có cách làm thay khó khăn; vi phạm chỉ tiêu NFR | Không phát hành được luồng; p95 gateway 70 ms; vi phạm axe mức A |
| S3 Trung bình | Chức năng sai ở trường hợp ít gặp, có cách làm thay dễ; lỗi giao diện ảnh hưởng hiểu nội dung | Lọc khoảng thời gian sai biên múi giờ; thông báo lỗi thiếu hướng dẫn khắc phục |
| S4 Thấp | Thẩm mỹ, chính tả, không ảnh hưởng chức năng | Lệch căn lề, sai chính tả |

: Định nghĩa mức nghiêm trọng của lỗi S1 đến S4 kèm ví dụ

### 10.2. Vòng đời lỗi

Mỗi lỗi đi qua một vòng đời có trạng thái và điều kiện chuyển rõ ràng, để không lỗi nào bị bỏ quên hoặc đóng khi chưa kiểm thử lại. Sơ đồ dưới đây mô tả các trạng thái và điều kiện chuyển.

```{.mermaid caption="Vòng đời lỗi"}
stateDiagram-v2
  [*] --> MOI: Ghi nhận
  MOI --> DA_PHAN_LOAI: Phân loại S/P, gán chủ sở hữu
  MOI --> TU_CHOI: Không phải lỗi / trùng
  DA_PHAN_LOAI --> DANG_SUA
  DA_PHAN_LOAI --> HOAN: Hoãn sang đợt sau (được duyệt)
  DANG_SUA --> CHO_KIEM_TRA: Đã merge, có ca hồi quy
  CHO_KIEM_TRA --> DONG: Kiểm thử lại đạt
  CHO_KIEM_TRA --> MO_LAI: Kiểm thử lại không đạt
  MO_LAI --> DANG_SUA
  HOAN --> DA_PHAN_LOAI: Đến đợt
  TU_CHOI --> [*]
  DONG --> [*]
```

Sơ đồ cho thấy vòng đời bảy trạng thái. Hai điểm kiểm soát quan trọng: lỗi chỉ được chuyển sang "Chờ kiểm tra" khi bản sửa đã merge và (với S1, S2) có ca hồi quy tự động; lỗi chỉ được "Hoãn" khi chủ đầu tư hoặc người được ủy quyền duyệt, và lỗi S1 không bao giờ được hoãn. Mỗi báo cáo lỗi phải có: môi trường, phiên bản, bước tái hiện, kết quả mong đợi và thực tế, `trace_id`, mã TC và FR liên quan, bằng chứng (trace Playwright, log đã che). Lỗi bảo mật được ghi trong không gian hạn chế quyền xem cho tới khi sửa xong.

### 10.3. Thời hạn sửa (SLA)

Bảng dưới đây đặt thời hạn phản hồi và sửa trong giai đoạn phát triển và kiểm thử, tính theo ngày làm việc từ khi lỗi được phân loại. Thời hạn xử lý sự cố trên sản xuất thuộc D06-03.

| Mức | Phân loại xong trong | Sửa xong (đã merge) trong | Kiểm thử lại trong |
|---|---|---|---|
| S1 | 4 giờ làm việc | 2 ngày; lỗ hổng bảo mật Critical 1 ngày | 1 ngày |
| S2 | 1 ngày | 5 ngày | 2 ngày |
| S3 | 3 ngày | Trong sprint kế tiếp | Trong sprint |
| S4 | 5 ngày | Theo ưu tiên backlog | — |

: Thời hạn phân loại, sửa và kiểm thử lại theo mức nghiêm trọng

## 11. Chỉ số kiểm thử và báo cáo

### 11.1. Chỉ số

Các chỉ số dưới đây được đo tự động từ CI, công cụ quản lý lỗi và bảng điều khiển chất lượng, hiển thị trên một bảng Grafana cho dự án.

| Chỉ số | Cách tính | Mục tiêu |
|---|---|---|
| Độ phủ yêu cầu | Số FR mức M có ≥ 2 TC (dương, âm) đạt / tổng FR mức M của đợt | 100% tại `RG-3` |
| Độ phủ NFR | Số NFR áp dụng có kết quả đo đạt / tổng NFR áp dụng | 100% tại `RG-3` |
| Độ phủ LGC | Số LGC (Giữ nguyên, Nâng cấp, Thay thế) có FR đã kiểm thử đạt / 179 | 100% tại `RG-4` đợt 2 (sau khi PH-19 phát hành) |
| Độ phủ mã | JaCoCo, V8 coverage | ≥ 80% backend, ≥ 70% giao diện |
| Độ phủ rò rỉ chéo tenant | Endpoint được bộ kiểm thử phủ / tổng endpoint không miễn trừ | 100% |
| Tỷ lệ đạt | Ca đạt / ca đã chạy, theo mức và theo phân hệ | Theo tiêu chí cổng |
| Mật độ lỗi | Lỗi S1–S3 / nghìn dòng mã thay đổi, theo phân hệ | Theo dõi xu hướng |
| Tỷ lệ lọt lỗi | Lỗi phát hiện ở UAT hoặc sản xuất / tổng lỗi của đợt | < 5% |
| Tuổi lỗi mở | Thời gian mở trung bình theo mức | Trong SLA mục 10.3 |
| Tỷ lệ ca bất ổn | Ca bất ổn / tổng ca tự động | < 1% |
| Thời gian pipeline | p90 mỗi giai đoạn | Trong ngân sách mục 9.2 |
| Hình dạng tháp | Tỷ lệ số ca theo mức | E2E ≤ 10% |

: Chỉ số kiểm thử, cách tính và mục tiêu

### 11.2. Báo cáo

Báo cáo kiểm thử được lập theo ba nhịp. **Hằng ngày** trong giai đoạn kiểm thử hệ thống và UAT: bảng điều khiển tự động, không lập văn bản. **Cuối mỗi sprint hoặc wave**: báo cáo tiến độ kiểm thử (test status report) một trang, gồm tiến độ chạy, lỗi mở theo mức, rủi ro mới, khuyến nghị. **Tại mỗi cổng `RG-3`, `RG-4`, `RG-5`**: báo cáo hoàn thành kiểm thử (test completion report) theo ISO/IEC/IEEE 29119-3, gồm tóm tắt, sai khác so với kế hoạch, đánh giá theo tiêu chí ra, lỗi còn mở và ngoại lệ, rủi ro tồn dư, bằng chứng đính kèm (kết quả tự động, báo cáo k6, biên bản chaos, DR, pentest, ASVS, a11y, đối chiếu di trú) và khuyến nghị phát hành.

## 12. Quy ước định danh và mẫu test case

### 12.1. Mã kịch bản và test case

Theo D00-01 §3.1, kịch bản kiểm thử có mã `TS-{PH}-{nn}` và test case có mã `TC-{PH}-{nnn}`, với `{PH}` là số phân hệ hai chữ số; kiểm thử thành phần xuyên suốt dùng `PH` = `00`. Một kịch bản gom các test case cùng mục tiêu (thường tương ứng một năng lực hoặc một use case), ví dụ `TS-07-03` "Nhập danh mục từ Excel" gồm `TC-07-021` đến `TC-07-034`. Mã không tái sử dụng; test case bị loại được đánh dấu "Đã hủy". Thí nghiệm hỗn loạn dùng mã `CX-{nn}` (mục 5.4.2) và được coi là test case hệ thống của `PH` = `00`; chúng được ghi trong D05-03.

Quy tắc số lượng tối thiểu: FR mức M có ít nhất hai TC, một dương tính và một âm tính (D00-01 §3.2 quy tắc 4); mỗi ngoại lệ đặc tả trong FR có một TC âm; mỗi `BR` có ít nhất một TC; mỗi API mới có ít nhất một TC rò rỉ chéo tenant (D03-10 §6 quy tắc 6) ngoài phần bộ sinh tự động; FR mức S có ít nhất một TC dương; FR mức C được kiểm thử khám phá.

### 12.2. Mẫu test case

Bảng dưới đây là mẫu bắt buộc cho mỗi test case trong D05-02. Với ca tự động, các trường được sinh từ chú thích trong mã kiểm thử và mô tả ngắn; không viết lại các bước bằng văn bản khi mã đã thể hiện rõ.

| Trường | Nội dung |
|---|---|
| Mã, tên | `TC-{PH}-{nnn}` · động từ + đối tượng + điều kiện, ví dụ "Từ chối nhập tệp có dòng sai kiểu ngày" |
| Kịch bản | `TS-{PH}-{nn}` |
| Truy vết | FR, BR, NFR, LGC, UC, API, UI; nguồn `AT-{PH}-{nnn}` nếu có |
| Loại | Dương tính / Âm tính / Biên / Rò rỉ chéo tenant / Bảo mật / Hiệu năng / Truy cập |
| Mức kiểm thử | Đơn vị / Module / Tích hợp hệ thống / Hợp đồng / E2E / Hệ thống / Chấp nhận |
| Mức ưu tiên | M / S / C (kế thừa FR) |
| Kỹ thuật thiết kế | Phân hoạch tương đương, giá trị biên, bảng quyết định, chuyển trạng thái, đoán lỗi |
| Tiền điều kiện | Tenant, vai trò, dữ liệu gieo (tham chiếu bộ gieo), cấu hình |
| Dữ liệu đầu vào | Giá trị cụ thể, chỉ dữ liệu tổng hợp |
| Các bước | Đánh số, mỗi bước một hành động |
| Kết quả mong đợi | Kiểm chứng được: mã HTTP, mã `ERR`, trạng thái dữ liệu, sự kiện phát ra, bản ghi kiểm toán |
| Hậu điều kiện, dọn dẹp | |
| Tự động hóa | Có / Không; đường dẫn mã kiểm thử |
| Môi trường | DEV / TEST / STAGING / PERF / UAT |

: Các trường của mẫu test case

Ví dụ một cặp test case cho FR-00-032 (nhập tệp tất cả hoặc không): `TC-07-021` (dương) — nhập tệp 1.000 dòng hợp lệ, kỳ vọng 1.000 bản ghi được tạo, một sự kiện `t90.rdm.catalog.items-imported.v1`, một bản ghi kiểm toán; `TC-07-022` (âm) — nhập tệp 1.000 dòng trong đó dòng 517 có ngày `31/02/2026`, kỳ vọng bước xem trước báo lỗi đúng dòng 517 cột "Ngày hiệu lực", sau khi xác nhận không dòng nào được ghi.

## 13. Tổ chức, vai trò và kỹ năng

### 13.1. Vai trò

Bảng dưới đây mô tả các vai trò tham gia kiểm thử. Một người có thể giữ nhiều vai trò, trừ vai trò kiểm thử xâm nhập phải độc lập với đội phát triển.

| Vai trò | Trách nhiệm chính |
|---|---|
| Trưởng nhóm kiểm thử (test manager) | Sở hữu D05-01, lập kế hoạch, quyết định `RG-2`, chủ trì hội đồng chất lượng `RG-3`, báo cáo |
| Kỹ sư tự động hóa kiểm thử (lane `L-QA`) | Khung E2E, k6, chaos, giả lập, thư viện `libs/test-support`, bảng điều khiển chất lượng |
| Kiểm thử viên chức năng | Viết TC D05-02 theo phân hệ, kiểm thử khám phá, kiểm tra NVDA, hỗ trợ UAT |
| Kỹ sư hiệu năng | D05-03, chạy và phân tích kiểm thử tải, đường cơ sở |
| Trưởng nhóm ATTT | D05-04, duyệt ngoại lệ bảo mật, đồng quyết định `RG-3` |
| Lập trình viên | Kiểm thử đơn vị, module, tích hợp hệ thống, hợp đồng, bộ gieo dữ liệu của module |
| Trưởng nhóm kỹ thuật, kiến trúc sư | Quy tắc ArchUnit, hợp đồng, đồng quyết định `RG-3` |
| Đội vận hành (DevOps/SRE) | Môi trường, pipeline, chaos, DR, kiểm thử cài đặt và nâng cấp |
| Đơn vị kiểm thử bảo mật độc lập | Kiểm thử xâm nhập (Q362) |
| Người dùng nghiệp vụ của tỉnh | Thực hiện UAT |
| Chủ đầu tư | Duyệt hoãn lỗi, quyết định `RG-4`, `RG-5` |

: Vai trò trong hoạt động kiểm thử và trách nhiệm chính

### 13.2. Ma trận RACI

Ma trận dưới đây phân công theo hoạt động: R thực hiện, A chịu trách nhiệm cuối cùng (một người), C được tham vấn, I được thông báo.

| Hoạt động | Trưởng nhóm KT | KS tự động hóa | Kiểm thử viên | KS hiệu năng | Trưởng nhóm ATTT | Lập trình viên | TN kỹ thuật | Vận hành | Chủ đầu tư |
|---|---|---|---|---|---|---|---|---|---|
| Lập và duy trì D05-01 | A/R | C | C | C | C | I | C | C | I |
| Viết test case D05-02 | A | C | R | — | C | C | C | — | I |
| Kiểm thử đơn vị, module, tích hợp | I | C | I | — | — | R | A | — | — |
| Kiểm thử hợp đồng | I | C | — | — | — | R | A | — | — |
| Bộ rò rỉ chéo tenant | A | R | C | — | C | R | C | — | I |
| E2E, hồi quy | A | R | R | — | — | C | I | C | — |
| Kiểm thử hiệu năng | A | C | — | R | — | C | C | C | I |
| Chaos, DR | A | C | — | C | C | C | C | R | I |
| Kiểm thử bảo mật, pentest | C | C | — | — | A/R | C | C | C | I |
| Khả năng truy cập | A | R | R | — | — | C | — | — | I |
| Di trú, song song strangler | A | R | R | — | C | R | C | R | C |
| Môi trường, dữ liệu kiểm thử | A | R | C | C | C | C | — | R | — |
| UAT | R | C | R | — | — | C | C | C | A |
| Quyết định cổng RG-3 | A | I | I | C | R | I | R | C | I |
| Quyết định cổng RG-4, RG-5 | R | I | I | I | C | I | C | C | A |

: Ma trận RACI của các hoạt động kiểm thử

### 13.3. Kỹ năng và đào tạo

Kế hoạch đòi hỏi các kỹ năng chưa phổ biến ở đội kiểm thử truyền thống. Bảng dưới đây ghi kỹ năng cần, đối tượng và hình thức đào tạo, thực hiện trong hai tháng đầu (T0 + 0 … T0 + 2) trước khi bước vào kiểm thử hệ thống MVP.

| Kỹ năng | Đối tượng | Hình thức |
|---|---|---|
| Testcontainers, Spring Modulith Test, ArchUnit | Lập trình viên, KS tự động hóa | Hội thảo nội bộ 1 ngày, mẫu trong `libs/test-support` |
| Pact và kiểm thử hợp đồng | Lập trình viên backend, frontend | Hội thảo nửa ngày, ví dụ cặp `dh-console` – `dh-connect` |
| Playwright, axe-core | KS tự động hóa, kiểm thử viên, lập trình viên giao diện | Khóa 2 ngày |
| Kiểm thử với NVDA, WCAG 2.2 | Kiểm thử viên, lập trình viên giao diện, người thiết kế | Khóa 1 ngày, có người khiếm thị tham gia đánh giá nếu tổ chức được |
| k6, phân tích hiệu năng trên Grafana | KS hiệu năng, vận hành | Khóa 2 ngày |
| Chaos Mesh, quy trình DR | Vận hành, KS tự động hóa | Thực hành trên STAGING |
| Kiểm thử bảo mật API, OWASP ASVS 5.0, ZAP | Kiểm thử viên, lập trình viên | Khóa 2 ngày |
| Cách ly đa tenant và bộ rò rỉ chéo tenant | Toàn đội | Buổi giới thiệu bắt buộc khi gia nhập dự án |
| Nghiệp vụ LGSP, thanh toán, danh mục | Kiểm thử viên | Tự học tài liệu hệ cũ, buổi trao đổi với cán bộ vận hành hệ cũ |

: Kỹ năng cần có, đối tượng và hình thức đào tạo

## 14. Lịch kiểm thử theo mốc

Lịch dùng mốc T0 (khởi động dự án) cộng số tháng, không gắn ngày lịch. Các mốc dưới đây là giả định làm việc của đội kiểm thử, căn theo các wave W0–W6 của kế hoạch phát triển trong repo và ba đợt phát hành của BRD; chúng phải được đồng bộ với kế hoạch dự án D01-02 khi tài liệu đó được phát hành (Q368).

| Mốc | Đợt / wave | Hoạt động kiểm thử chính | Cổng |
|---|---|---|---|
| T0 + 0 … 1 | W0 Nền tảng | Dựng pipeline Gate A/B/C/D/S, `libs/test-support`, Testcontainers chung, bộ rò rỉ chéo tenant bản đầu, bộ sinh dữ liệu, giả lập NDXP/PayGov bản đầu; đào tạo | — |
| T0 + 1 … 2 | W1 Lát cắt mỏng | E2E thin slice HTTT giả → Datahub → HTTT giả; Pact cặp đầu tiên; môi trường TEST | RG-1 vận hành liên tục |
| T0 + 2 … 6 | W2–W5 (phần MVP) | Viết D05-02 cho 12 PH MVP song song với FRS; kiểm thử tích hợp, hợp đồng, E2E theo từng phân hệ; PERF dựng xong ở T0 + 4, đường cơ sở hiệu năng đầu tiên; chaos CX-03, CX-05 bắt đầu hằng tuần trên STAGING từ T0 + 5 | RG-2 cuối mỗi wave |
| T0 + 6 | — | Diễn tập DR lần 1 trên STAGING; diễn tập di trú DMDC, APIM lần 1 | — |
| T0 + 6 … 8 | W6 MVP | Kiểm thử hệ thống MVP đầy đủ; tải, bền 24 giờ, CX-01 24 giờ, CX-02; ZAP đầy đủ, ASVS L2, pentest độc lập; NVDA 10 luồng; tương thích trình duyệt; cài đặt air-gapped | RG-3 MVP ở T0 + 8 |
| T0 + 8 … 9 | MVP | UAT MVP, UAT vận hành, SUS; diễn tập di trú lần 2; bắt đầu chạy bóng các API của khối APIM, DMDC | RG-4 MVP ở T0 + 9 |
| T0 + 9 … 12 | Chuyển đổi MVP | Chạy bóng, chuyển dần, cắt chuyển lần lượt DMDC, APIM, Hub, Bus; hồi quy mỗi bản vá; DR quý | RG-5 theo từng khối |
| T0 + 9 … 13 | Đợt 2 (PH-09, 11, 15, 19) | D05-02 đợt 2; kiểm thử PH-19 với sandbox PayGov; đối soát; kiểm thử che dữ liệu PH-09; kiểm thử hệ thống đợt 2, pentest | RG-3 đợt 2 ở T0 + 13 |
| T0 + 13 … 14 | Đợt 2 | UAT đợt 2 (cán bộ đối soát); song song khối Payment cũ, đối chiếu theo ngày | RG-4 đợt 2 ở T0 + 14 |
| T0 + 15 | Chuyển đổi Payment | Cắt chuyển khối Payment sau chu kỳ đối soát cuối tháng | RG-5 Payment |
| T0 + 14 … 17 | Đợt 3 (PH-06, 08, 16, 17) | D05-02 đợt 3; kiểm thử AI, đối sánh MDM; kiểm thử hệ thống | RG-3 đợt 3 ở T0 + 17 |
| T0 + 17 … 18 | Đợt 3 | UAT đợt 3; báo cáo hoàn thành kiểm thử tổng | RG-4 đợt 3 ở T0 + 18 |
| Hằng quý từ T0 + 6 | Mọi giai đoạn | Diễn tập DR (NFR-00-014) | — |
| Hằng năm và khi thay đổi lớn | Sau vận hành | Kiểm thử xâm nhập định kỳ, rà soát ASVS | — |

: Lịch kiểm thử theo mốc T0, wave, đợt và cổng

## 15. Rủi ro kiểm thử và giả định

### 15.1. Rủi ro của hoạt động kiểm thử

Khác với rủi ro sản phẩm ở mục 3, các rủi ro dưới đây đe dọa chính kế hoạch kiểm thử. Mã dùng chung dải `RSK-T` tiếp sau rủi ro sản phẩm.

| Mã | Rủi ro | Ảnh hưởng | Biện pháp |
|---|---|---|---|
| RSK-T30 | Không có sandbox PayGov hoặc môi trường thử NDXP | Kiểm thử hợp đồng thật dồn vào UAT, phát hiện muộn | Giả lập theo đặc tả sớm; xin quyền truy cập ngay từ T0 (Q364, Q365) |
| RSK-T31 | Môi trường PERF không đúng hồ sơ "tỉnh vừa" hoặc chậm sẵn sàng | Không kiểm chứng được NFR hiệu năng trước `RG-3` | Chốt tài nguyên ở T0 + 1 (Q366); chạy tải rút gọn trên TEST để phát hiện xu hướng |
| RSK-T32 | Hồ sơ quy mô "tỉnh vừa" khác thực tế tỉnh thí điểm | Chỉ tiêu đạt trên giấy nhưng không đạt thật | Cập nhật mô hình tải khi có số liệu (Q07 SRS); thêm hệ số an toàn 1,5 lần cho kiểm thử chịu tải |
| RSK-T33 | Pipeline chậm dần do Testcontainers và E2E | Lập trình viên né kiểm thử, giảm chất lượng | Ngân sách mục 9.2, tái sử dụng container, chọn ca theo module |
| RSK-T34 | Thiếu kiểm thử viên có kỹ năng truy cập, hiệu năng, bảo mật | Bỏ sót loại kiểm thử chuyên đề | Đào tạo mục 13.3; thuê chuyên gia theo đợt |
| RSK-T35 | Không có dữ liệu "bẩn" thật của hệ cũ cho di trú | Lỗi di trú lộ ra khi cắt chuyển | Dữ liệu tổng hợp mô phỏng lỗi đã biết; xin bản trích đã che (Q367); diễn tập ≥ 2 lần |
| RSK-T36 | Người dùng UAT không đủ thời gian tham gia | UAT kéo dài, KPI-18 không đo được | Lịch UAT thống nhất từ đầu đợt; UAT theo buổi ngắn có hướng dẫn |
| RSK-T37 | Tính năng mô phỏng (stub) trong repo bị tính nhầm là đã đạt | Nghiệm thu sai | Quy tắc mục 5.12: chỉ đạt khi chạy thật; kiểm thử phát hiện stub trên STAGING (cấm profile `dev`) |

: Rủi ro RSK-T30 đến RSK-T37 của hoạt động kiểm thử và biện pháp

### 15.2. Giả định

Kế hoạch dựa trên các giả định sau; giả định nào sai thì phải điều chỉnh kế hoạch. Đội phát triển tuân thủ D03-10 §6 và D04-01, viết kiểm thử mức thấp cùng PR. Hợp đồng API và sự kiện được viết trước mã như NT-04 yêu cầu. Hạ tầng CI có khả năng chạy container (Docker hoặc tương đương) với đủ tài nguyên cho Testcontainers song song. Chủ đầu tư bố trí người dùng nghiệp vụ cho UAT theo lịch mục 14. Các công cụ mã nguồn mở được chọn có giấy phép phù hợp RB-04 (k6 AGPL-3.0 chỉ dùng như công cụ nội bộ, không phân phối kèm sản phẩm). Đơn vị kiểm thử xâm nhập độc lập được lựa chọn trước T0 + 6.

## 16. Công cụ

Bảng dưới đây chốt bộ công cụ kiểm thử. Phiên bản cụ thể được ghim trong D04-02 cùng các thành phần khác. Mọi công cụ là mã nguồn mở hoặc có phiên bản cộng đồng, phù hợp RB-04 và chạy được trong môi trường air-gapped (ảnh container từ Harbor nội bộ).

| Nhóm | Công cụ | Dùng cho |
|---|---|---|
| Đơn vị backend | JUnit 5, AssertJ, Mockito, jqwik, PIT | Kiểm thử đơn vị, dựa trên thuộc tính, đột biến |
| Kiến trúc | Spring Modulith Test (`ApplicationModules.verify()`, `@ApplicationModuleTest`, `Scenario`), ArchUnit | Ranh giới module, quy tắc D03-10 §6 |
| Tích hợp | Testcontainers, REST Assured, MockMvc, Awaitility, Camel Test JUnit 5, `@QuarkusTest`, `@QuarkusIntegrationTest` | Tích hợp hệ thống, luồng Camel JVM và native |
| Chính sách | `opa test`, Conftest | Kiểm thử Rego, kiểm thử manifest |
| Hợp đồng | Spectral, oasdiff, Pact (JVM, JS) và Pact Broker, Apicurio compatibility rules, Microcks | Kiểm thử hợp đồng API và sự kiện |
| Giả lập | WireMock, Microcks, Mailpit, OpenLDAP, HTTT giả lập | Dịch vụ ngoài |
| Đơn vị giao diện | Vitest, Testing Library, MSW, Storybook (addon a11y, test runner) | Component, hook |
| E2E, giao diện | Playwright Test (Chromium, Firefox, WebKit), `toHaveScreenshot`, `@axe-core/playwright`, Lighthouse CI, web-vitals | E2E, visual regression, khả năng truy cập, hiệu năng giao diện |
| Truy cập thủ công | NVDA, công cụ đo tương phản | Kiểm tra trình đọc màn hình |
| Hiệu năng | k6, xk6-kafka, k6 Prometheus remote write, Grafana | Tải, chịu tải, bền, đột biến |
| Hỗn loạn | Chaos Mesh (mặc định), Litmus (thay thế) | CX-01…08 |
| Bảo mật | Semgrep, gitleaks, Trivy, Checkov, kube-bench, OWASP ZAP, testssl.sh, DefectDojo | SAST, bí mật, SCA, IaC, CIS, DAST, TLS, quản lý phát hiện |
| Dữ liệu | Datafaker (`dh-testdata`), công cụ che dữ liệu, bộ quét canary | Dữ liệu tổng hợp, che, phát hiện rò rỉ |
| Báo cáo | JUnit XML, SARIF, Allure Report hoặc ReportPortal, Grafana | Tổng hợp kết quả, chỉ số |
| Quản lý | Công cụ quản lý lỗi và test case của nền tảng Git dự án (issue, nhãn) hoặc công cụ quản lý kiểm thử tương đương | Vòng đời lỗi, liên kết TC–FR |

: Công cụ kiểm thử theo nhóm và mục đích dùng

## 17. Ma trận truy vết NFR → kiểm thử

Ma trận dưới đây là cam kết của kế hoạch với hội đồng thẩm định: mỗi NFR-00 có loại kiểm thử, công cụ, môi trường và cổng mà kết quả của nó chặn. Cột "Mục" chỉ chỗ mô tả chi tiết trong tài liệu này.

| NFR | Nội dung tóm tắt | Loại kiểm thử | Công cụ | Môi trường | Cổng | Mục |
|---|---|---|---|---|---|---|
| NFR-00-001 | Độ trễ thêm gateway p95 ≤ 50 ms | Tải | k6, chỉ số APISIX | PERF | RG-3 | 5.3 |
| NFR-00-002 | ≥ 1.000 lượt/giây, lỗi < 0,1% | Tải 30 phút | k6 | PERF | RG-3 | 5.3 |
| NFR-00-003 | Màn danh sách p95 ≤ 1,5 giây | Tải + đo giao diện | k6, Playwright | PERF | RG-3 | 5.3 |
| NFR-00-004 | Chi tiết, lưu p95 ≤ 1 giây | Tải + đo giao diện | k6, Playwright | PERF | RG-3 | 5.3 |
| NFR-00-005 | LCP ≤ 2,5 giây, INP ≤ 200 ms | Hiệu năng giao diện | Lighthouse CI, web-vitals | TEST (đêm), PERF | RG-2, RG-3 | 5.3 |
| NFR-00-006 | Độ trễ sự kiện p95 ≤ 2 giây | Tải Kafka | k6 + xk6-kafka | PERF | RG-3 | 5.3 |
| NFR-00-007 | Runtime luồng p95 ≤ 30 ms | Tải | k6, chỉ số Camel | PERF | RG-3 | 5.3 |
| NFR-00-008 | 100.000 dòng ≤ 2 phút | Chức năng có đo thời gian | REST Assured / k6 | PERF, STAGING | RG-3 | 5.3 |
| NFR-00-010 | Sẵn sàng data plane ≥ 99,9% | Đo liên tục bằng probe tổng hợp | Blackbox Exporter / Grafana Synthetic | STAGING, PROD | RG-4 | 5.4.1 |
| NFR-00-011 | Sẵn sàng control plane ≥ 99,5% | Như trên | Như trên | STAGING, PROD | RG-4 | 5.4.1 |
| NFR-00-012 | Data plane chạy 24 giờ khi control plane ngừng | Hỗn loạn CX-01 | Chaos Mesh, k6 | STAGING | RG-3 | 5.4.2 |
| NFR-00-013 | Nâng cấp không gián đoạn | Nâng cấp dưới tải CX-02 | Argo CD, k6 | STAGING | RG-3 | 5.4.2 |
| NFR-00-014 | RPO ≤ 15 phút, RTO ≤ 1 giờ / 4 giờ | Diễn tập DR hằng quý | Quy trình HDVH, bộ ghi tuần tự | STAGING hai site, PROD | RG-4 | 5.4.4 |
| NFR-00-015 | Mất một nút, phục hồi ≤ 5 phút | Hỗn loạn CX-03 | Chaos Mesh | STAGING | RG-3 | 5.4.2 |
| NFR-00-020 | TLS 1.3 biên, mTLS nội bộ | Kiểm tra cấu hình | testssl.sh, kiểm tra Istio | STAGING | RG-3 | 5.5 |
| NFR-00-021 | Mã hóa khi lưu, mã hóa trường Nhạy cảm | Kiểm tra cấu hình, tích hợp (đọc thô cột không ra bản rõ) | Testcontainers, kiểm tra thủ công | TEST, STAGING | RG-3 | 5.5 |
| NFR-00-022 | 0 bí mật trong mã, ảnh | Quét bí mật | gitleaks, Trivy | CI | PR (Gate S) | 5.5 |
| NFR-00-023 | 0 CRITICAL, 0 HIGH chưa ngoại lệ | SCA | Trivy | CI, hằng đêm | PR, RG-2 | 5.5 |
| NFR-00-024 | ASVS 5.0 L2 | Bảng kiểm, DAST, pentest | ZAP, Semgrep, thủ công | STAGING | RG-3 | 5.5 |
| NFR-00-025 | Khóa 15 phút sau 5 lần sai | Tích hợp | Testcontainers Keycloak | CI | PR | 5.5 |
| NFR-00-026 | Mật khẩu ≥ 12 ký tự, danh sách lộ | Tích hợp | Testcontainers Keycloak | CI | PR | 5.5 |
| NFR-00-027 | Lưu kiểm toán 12 tháng trực tuyến | Kiểm tra cấu hình lưu giữ | Thủ công, truy vấn | STAGING | RG-3 | 5.15 |
| NFR-00-028 | Lưu log vận hành 90 ngày | Kiểm tra cấu hình lưu giữ | Loki retention | STAGING | RG-3 | 5.15 |
| NFR-00-029 | 0 giá trị Nhạy cảm trong log | Quét canary | Bộ quét canary | TEST, STAGING | RG-2, RG-3 | 8.4 |
| NFR-00-040 | WCAG 2.2 AA, 0 lỗi axe, NVDA 10 luồng | Truy cập tự động và thủ công | axe-core, NVDA | TEST, STAGING | Gate D, RG-3 | 5.7 |
| NFR-00-041 | Tương phản kể cả trên glass | Truy cập, đo điểm ảnh | Playwright, kiểm thử token | TEST | RG-2 | 5.7, 5.13 |
| NFR-00-042 | Thao tác bàn phím | E2E chỉ bàn phím | Playwright | TEST | RG-2 | 5.7 |
| NFR-00-043 | Giảm chuyển động, trong suốt | Visual regression có giả lập tùy chọn | Playwright | TEST | RG-2 | 5.7 |
| NFR-00-044 | Sáng, tối | Visual regression, axe hai chế độ | Playwright, axe-core | TEST | RG-2 | 5.7 |
| NFR-00-045 | 100% dùng `@datahub/ui`, không CSS ngoài token | Lint | ESLint, Stylelint | CI | PR (Gate C) | 5.7 |
| NFR-00-050 | Liveness, readiness, chỉ số | Quét manifest, gọi điểm cuối | Conftest, kịch bản | CI, TEST | RG-2 | 5.15 |
| NFR-00-051 | `trace_id`, `tenant_id` trong log JSON | Lấy mẫu log | Truy vấn Loki | TEST | RG-2 | 5.15 |
| NFR-00-052 | Tham số áp dụng ≤ 60 giây | Tích hợp, E2E | Playwright, REST Assured | TEST | RG-2 | 5.15 |
| NFR-00-053 | Độ phủ ≥ 80% / 70% | Đo độ phủ | JaCoCo, V8 | CI | PR (Gate A, C) | 4.2 |
| NFR-00-054 | `verify()` đạt | Tích hợp module | Spring Modulith Test | CI | PR (Gate A) | 4.3 |
| NFR-00-055 | Tương thích ngược API | Hợp đồng | oasdiff, Pact | CI | PR (Gate B) | 4.5 |
| NFR-00-056 | Triển khai tỉnh ≤ 3 ngày | Cài đặt air-gapped theo tài liệu | Gói phân phối, đồng hồ | Cụm sạch | RG-3 | 5.15 |
| NFR-00-057 | Khởi tạo tenant ≤ 1 giờ | Hệ thống, đo thời gian saga | Playwright, API | STAGING | RG-3 | 5.15 |
| NFR-00-060 | ≥ 34 tenant | Tải nhiều tenant | k6 | PERF | RG-3 | 5.3 |
| NFR-00-061 | Gấp đôi tài nguyên ≥ 1,8 lần thông lượng | Tải so sánh | k6 | PERF | RG-3 | 5.3 |
| NFR-00-062 | 5 triệu bản ghi/ngày/tenant, 12 tháng | Dung lượng | Bộ sinh dữ liệu, truy vấn | PERF | RG-3 | 5.3 |

: Truy vết từng NFR tới loại kiểm thử, công cụ, môi trường và cổng

Các yêu cầu chức năng dùng chung có kiểm thử chuyên đề cũng được truy vết như sau: FR-00-010, 011, 012 → mục 5.6, cổng PR và mọi `RG`; FR-00-040…043 → mục 4.4 và RSK-T14; FR-00-090…093 → mục 5.8, cổng `RG-5`; FR-00-003 → mục 5.1 (đồng hồ giả lập).

## 18. Quan hệ với D05-02, D05-03, D05-04, D05-05

Phân chia trách nhiệm giữa các tài liệu kiểm thử đã nêu ở mục 1.4. Khi viết các tài liệu này, người viết phải giữ ba ràng buộc: không đặt chỉ tiêu lỏng hơn D05-01; mọi ca kiểm thử dùng mã theo mục 12; mọi bằng chứng được nộp vào báo cáo hoàn thành kiểm thử của cổng tương ứng ở mục 11.2. D05-02 viết theo thứ tự đợt: 12 tập MVP trước T0 + 6, 4 tập đợt 2 trước T0 + 11, 4 tập đợt 3 trước T0 + 15, cộng một tập `PH-00` cho thành phần xuyên suốt và bộ khung FR-00. D05-03 bổ sung chi tiết thí nghiệm `CX-nn` và mô hình tải. D05-04 bổ sung ánh xạ từng `SEC-nn` của D03-07 sang ca kiểm thử và bảng kiểm ASVS. D05-05 chốt danh sách 10 luồng NVDA cùng kịch bản UAT.

## 19. Truy vết

Bảng dưới đây ánh xạ yêu cầu, quyết định và rủi ro nguồn tới mục đáp ứng trong tài liệu này.

| Nguồn | Đáp ứng tại |
|---|---|
| REQ-01…22; BRD §8.3 phân đợt | Mục 2.1, 14 |
| BRD §11 tiêu chí thành công; KPI-03, 04, 07, 09, 12, 15, 16, 17, 18 | Mục 4.8, 6.2 (RG-4) |
| KPI-05, KPI-06 | Mục 4.6 |
| KPI-13, KPI-14 | Mục 5.10 |
| FR-00-001…082 | Mục 5.1, 12 |
| FR-00-010, 011, 012 | Mục 5.6 |
| FR-00-040…043 | Mục 4.4, 3.3 (RSK-T14) |
| FR-00-090…093 | Mục 5.8 |
| NFR-00-001…062 | Mục 5.3–5.15, 17 |
| D00-01 §3.2 quy tắc 4 | Mục 12.1 |
| D03-10 §4, §5.2, §6 | Mục 4.3, 5.6 |
| RSK-A02, A03, A04, A05 (SAD §12) | RSK-T12, T01, T11, T16 ở mục 3.3 |
| ADR-001 (Modulith) | Mục 4.3 |
| ADR-002, ADR-010 (Camel Quarkus, YAML DSL) | Mục 5.12 |
| ADR-003 (RLS) | Mục 5.6 |
| ADR-004 (Kafka) | Mục 4.4, 5.6.3 |
| ADR-006 (Keycloak, OPA) | Mục 4.2, 5.5 |
| ADR-009 (GitOps) | Mục 5.12, 7.1 |
| ADR-012 (OpenBao) | Mục 5.4.2 (CX-07), 5.10 |
| ADR-013 (tách control/data plane) | Mục 5.4.2 (CX-01) |
| ADR-020 (Liquid Glass) | Mục 5.13 |
| ADR-037 (quy trình Git, cổng CI) | Mục 6.1 |
| ADR-038 (chiến lược kiểm thử) | Mục 3, 4, 5.6 |
| LGC-NFR-002, 006, 010 | Mục 5.3, 5.4, 5.14 |
| Dải SEC-01…99 (D03-07) | Mục 5.5 |

: Truy vết nguồn yêu cầu và tài liệu tới mục đáp ứng

## 20. Mã và thuật ngữ mới đề xuất bổ sung D00-01

Tài liệu đề xuất bổ sung vào D00-01 các mã và thuật ngữ sau; luồng lõi gộp vào D00-01 theo §9.3.

| Loại | Đề xuất | Định nghĩa tại |
|---|---|---|
| Mã | `RG-{n}` — cổng phát hành kiểm thử (RG-1 vào TEST, RG-2 ứng viên phát hành, RG-3 kết thúc kiểm thử hệ thống, RG-4 nghiệm thu vận hành, RG-5 cắt chuyển khối hệ cũ) | D05-01 §6.2 |
| Mã | `RSK-T{nn}` — rủi ro sản phẩm (01–29) và rủi ro hoạt động kiểm thử (30–39), cùng cách đặt với `RSK-A{nn}` của SAD | D05-01 §3.3, §15.1 |
| Mã | `CX-{nn}` — thí nghiệm kiểm thử hỗn loạn | D05-01 §5.4.2, chi tiết D05-03 |
| Mã | `S1…S4` mức nghiêm trọng lỗi; `P1…P4` mức ưu tiên lỗi | D05-01 §10.1 |
| Quy ước | Tenant kiểm thử dùng dải `T90`–`T99`; tenant tạm theo lần chạy | D05-01 §8.2 |
| Quy ước | Mã `PH` = `00` cho test case của thành phần xuyên suốt (`TS-00-nn`, `TC-00-nnn`) | D05-01 §2.1 |
| Thuật ngữ | Mức kiểm thử, loại kiểm thử, tháp kiểm thử, kiểm thử hợp đồng, kiểm thử rò rỉ chéo tenant, kiểm thử hỗn loạn, lưu lượng bóng, visual regression, cổng phát hành, kiểm thử khói, ca kiểm thử bất ổn, giá trị canary | D05-01 §1.5, §8.4 |

: Mã, quy ước và thuật ngữ mới đề xuất bổ sung D00-01

## 21. Câu hỏi mở

> **Câu hỏi mở Q360:** Cần đối chiếu toàn văn các nhóm yêu cầu "quản lý kiểm tra an ninh mạng" và "phát triển ứng dụng an toàn" ở cấp độ 3 của TCVN 14423:2026 để chốt tần suất kiểm tra, đánh giá an ninh mạng và kiểm thử xâm nhập bắt buộc.

> **Câu hỏi mở Q361:** NFR-00-062 thiếu chỉ tiêu thời gian truy vấn trên tập dữ liệu 12 tháng; đề nghị bổ sung vào SRS.

> **Câu hỏi mở Q362:** Cần xác định đơn vị kiểm thử xâm nhập độc lập và yêu cầu năng lực, giấy phép theo NĐ 331/2026.

> **Câu hỏi mở Q363:** Cần xác nhận căn cứ pháp lý cho việc nhân bản lưu lượng thật (có thể chứa dữ liệu cá nhân) sang Datahub ở chế độ bóng, và cổng tối thiểu Datahub phải đạt trước khi nhận lưu lượng bóng.

> **Câu hỏi mở Q364:** Cần xác nhận PayGov có sandbox cho tích hợp mới, điều kiện cấp, tệp đối soát mẫu và giới hạn giao dịch thử.

> **Câu hỏi mở Q365:** Cần xác nhận NDXP có môi trường thử cho tỉnh, phạm vi dịch vụ có dữ liệu thử và quy định dùng dữ liệu thử của CSDL quốc gia trong kiểm thử tự động.

> **Câu hỏi mở Q366:** Cần chốt nơi đặt và nguồn tài nguyên cho STAGING (hai site), PERF (đúng hồ sơ "tỉnh vừa") và UAT.

> **Câu hỏi mở Q367:** Cần chủ đầu tư quyết định có cho phép dùng bản trích dữ liệu hệ cũ đã che cho diễn tập di trú, ai thực hiện việc che và có cần đánh giá tác động xử lý dữ liệu cá nhân hay không.

> **Câu hỏi mở Q368:** Lịch ở mục 14 là giả định của đội kiểm thử theo wave W0–W6 và ba đợt BRD; cần đồng bộ với kế hoạch dự án D01-02 và quan hệ giữa cổng `RG-n` với cổng quản lý G1, G2… khi D01-02 được phát hành.

> **Câu hỏi mở Q369:** Cần chủ đầu tư xác nhận danh sách 10 luồng chính kiểm tra bằng NVDA (NFR-00-040) đề xuất ở mục 5.7, và khả năng mời người dùng khiếm thị tham gia đánh giá trong UAT.

## Lịch sử phiên bản

| Phiên bản | Ngày | Người | Nội dung |
|---|---|---|---|
| 0.1 | 21/11/2026 | Nhóm viết tài liệu (Claude) | Bản đầu: bối cảnh, chiến lược theo rủi ro, mức và loại kiểm thử, cổng phát hành RG-1 đến RG-5, môi trường, dữ liệu, tự động hóa, quản lý lỗi, chỉ số, tổ chức, lịch, công cụ, ma trận truy vết NFR |
| 0.2 | 26/11/2026 | Nhóm viết tài liệu (Claude) | Áp chuẩn trình bày kết hợp, giữ nguyên nội dung kỹ thuật bản trước: thêm Tóm tắt cho hội đồng thẩm định; bổ sung metadata `mo_ta` và `tai_lieu_lien_quan`; gộp mục 1.3 thành Căn cứ và tài liệu tham chiếu; thêm mục 1.6 Người đọc và phần cần đọc, mục 1.7 Cấu trúc tài liệu, đoạn chữ viết tắt ở mục 1.5; thêm đoạn mở cho mục 10.2; chuyển hai sơ đồ Mermaid (cổng phát hành, strangler) sang `flowchart TB`; viết lại 31 chú thích bảng và ba chú thích hình để cụ thể và không trùng |
