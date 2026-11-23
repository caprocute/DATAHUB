---
ma_tai_lieu: D03-06-00
ten: Kiến trúc thông tin, khung bố cục và mẫu màn hình chuẩn
phien_ban: 0.1
ngay: 2026-11-21
trang_thai: Dự thảo
nguoi_doc: Nhà thiết kế giao diện, Kỹ sư giao diện, Kiểm thử viên, Chuyên viên phân tích nghiệp vụ, AI agent sinh mã
nguoi_lap: Luồng giao diện
---

# D03-06-00 · Kiến trúc thông tin, khung bố cục và mẫu màn hình chuẩn

## 1. Mục đích, phạm vi và cách dùng

### 1.1. Mục đích

Tài liệu này là phần chung mở đầu của bộ thiết kế màn hình D03-06. Nó trả lời ba câu hỏi mà mọi màn hình của Datahub đều phải trả lời giống nhau: người dùng tìm thấy màn hình ở đâu trong hệ thống (kiến trúc thông tin, information architecture, viết tắt IA), màn hình nằm trong khung nào (khung bố cục, layout shell) và màn hình được dựng theo khuôn nào (mẫu màn hình, screen pattern, mã `PTN-{nn}`). Khi ba câu hỏi này đã được trả lời một lần ở đây, các tập thiết kế màn hình theo phân hệ chỉ cần chọn mẫu và mô tả phần khác biệt về nghiệp vụ. Nhờ vậy, hơn hai trăm màn hình của hai mươi phân hệ có cùng cách điều hướng, cùng vị trí nút, cùng cách báo lỗi, và kỹ sư hay AI agent sinh mã có thể dựng một màn mới mà không phải tự thiết kế lại bố cục.

Tài liệu đáp ứng trực tiếp nhóm yêu cầu giao diện dùng chung `FR-00-001`…`FR-00-082` và các yêu cầu phi chức năng về trải nghiệm `NFR-00-003`, `NFR-00-005`, `NFR-00-040`…`NFR-00-045` của D02-02. Nó kế thừa ý tưởng của bộ quy tắc CRUD cũ trong `docs/ui_ux_rule.md` (cấu trúc màn hình, bộ lọc, bảng, trạng thái bắt buộc, tiêu chí nghiệm thu) và nâng cấp chúng thành mẫu có thể kiểm thử, áp dụng cho cả những loại màn không phải CRUD như trình thiết kế luồng, dashboard trực ca hay trang tra log.

### 1.2. Quan hệ với các tài liệu khác

Bộ tài liệu giao diện được tổ chức thành hai tầng. Tầng design system (D03-05) định nghĩa "viên gạch": token giá trị, vật liệu Liquid Glass và các thành phần `CMP-*`. Tầng thiết kế màn hình (D03-06) định nghĩa "căn nhà": cách ghép các viên gạch thành màn hình. Sơ đồ dưới đây cho thấy chiều phụ thuộc giữa các tài liệu.

```mermaid
flowchart TB
    subgraph DS["D03-05 · Design system"]
        T["D03-05-02<br/>Token"]
        G["D03-05-01<br/>Vật liệu Liquid Glass<br/>CMP-GlassSurface, CMP-ThemeProvider"]
        A["D03-05-03<br/>Thành phần nguyên tử"]
        C["D03-05-04<br/>Thành phần phức hợp, tổ chức, khung<br/>CMP-AppShell, CMP-DataTable…"]
    end
    subgraph SC["D03-06 · Thiết kế màn hình"]
        P["D03-06-00 (tài liệu này)<br/>IA, khung bố cục, PTN-01…14,<br/>vi văn bản, nghiệm thu chung"]
        U1["D03-06-PH02<br/>UI-02-nn"]
        U2["D03-06-PH07<br/>UI-07-nn"]
        U3["D03-06-PH19<br/>UI-19-nn"]
    end
    SRS["D02-02 SRS<br/>FR-00, NFR-00"] --> P
    FRS["D02-03 FRS phân hệ<br/>FR-PH-nnn"] --> U1 & U2 & U3
    T --> G --> A --> C --> P
    P --> U1 & U2 & U3
    U1 & U2 & U3 --> TC["D05-02 test case<br/>TC-PH-nnn"]
```

Sơ đồ đọc từ trên xuống. Token ở D03-05-02 là nguồn giá trị duy nhất; vật liệu glass ở D03-05-01 dùng token để tạo bốn bề mặt kính; thành phần nguyên tử và phức hợp ở D03-05-03 và D03-05-04 dùng cả hai. Tài liệu này không định nghĩa thêm thành phần nào mà chỉ quy định **thành phần nào đặt ở vùng nào, trên vật liệu nào, hành xử ra sao** trong từng mẫu màn hình. Các tập UI phân hệ (ví dụ `D03-06-PH07` cho danh mục dùng chung) nhận đầu vào nghiệp vụ từ FRS phân hệ và đầu vào bố cục từ tài liệu này. Kiểm thử viên lấy tiêu chí nghiệm thu của mẫu (mục 4) và tiêu chí chung (mục 6) để sinh test case ở D05-02.

Ranh giới trách nhiệm giữa D03-05-04 và tài liệu này cần được hiểu đúng để tránh mô tả trùng. D03-05-04 đặc tả **thành phần khung** (`CMP-AppShell`, `CMP-Topbar`, `CMP-Sidebar`, `CMP-TenantSwitcher`, `CMP-UserMenu`, `CMP-CommandPalette`, `CMP-NotificationCenter`) ở mức API thành phần: thuộc tính, sự kiện, trạng thái nội tại. Tài liệu này đặc tả **cách các thành phần đó được dùng** trong ứng dụng `dh-console` và `dh-portal`: cây menu cụ thể, route cụ thể, quy tắc hiển thị theo quyền, kích thước vùng và hành vi responsive. Khi hai tài liệu mâu thuẫn về giá trị thị giác, D03-05-02 (token) thắng; khi mâu thuẫn về cách dùng trong màn hình, tài liệu này thắng.

### 1.3. Cách một tập UI phân hệ tham chiếu mẫu màn hình

Mỗi màn hình trong tập UI phân hệ được khai báo bằng một khối đặc tả cố định. Khối này đủ để kỹ sư dựng màn hình và để kiểm thử viên biết phải kiểm tra gì; mọi điều không ghi trong khối được hiểu là **kế thừa nguyên vẹn mẫu PTN** đã chọn. Mẫu khai báo dưới đây là bắt buộc; các trường đánh dấu "nếu có" được bỏ qua khi không áp dụng.

```markdown
### UI-07-03 · Danh sách danh mục

| Trường | Giá trị |
|---|---|
| Mẫu | PTN-08 Cây + bảng (biến thể: cây nhóm danh mục bên trái) |
| Ứng dụng | dh-console |
| Route | /du-lieu/danh-muc?nhom={ma-nhom}&q=&trang-thai=&sap-xep=&trang=&co= |
| Mục menu | Dữ liệu dùng chung › Danh mục dùng chung |
| Tiêu đề tab | Danh mục dùng chung · Datahub |
| Quyền vào màn | PERM-07-view |
| Quyền theo hành động | Thêm: PERM-07-create; Nhập: PERM-07-import; Xuất: PERM-07-export; Công bố: PERM-07-publish |
| FR phục vụ | FR-07-001, FR-07-004, FR-07-021; tuân thủ FR-00-020…024, FR-00-030, FR-00-053 |
| Thành phần | CMP-PageHeader, CMP-Tree, CMP-FilterBar, CMP-DataTable, CMP-BulkActionBar, CMP-StatusTag |
| Cột / trường | (bảng cột: tên, kiểu, định dạng, sắp xếp được, mặc định ẩn/hiện) |
| Hành động | (bảng hành động: nhãn, vị trí, điều kiện trạng thái, quyền, xác nhận, lý do) |
| Trạng thái khác biệt | Rỗng: "Nhóm này chưa có danh mục nào" + nút Thêm danh mục / Nhập từ Excel |
| Phím tắt riêng (nếu có) | — |
| API | API-07-010 (danh sách), API-07-011 (cây nhóm) |
| Khác biệt so với mẫu | Cây bên trái hiển thị số danh mục mỗi nhóm; chọn nút cây cập nhật query `nhom` |
```

Bảng khai báo trên có bốn quy tắc đi kèm. Thứ nhất, trường "Mẫu" chỉ được chọn một PTN; nếu màn hình là tổ hợp (ví dụ chi tiết có tab chứa danh sách), chọn mẫu của khung ngoài (PTN-02) và ghi mẫu của phần trong ở trường "Khác biệt so với mẫu". Thứ hai, trường "Trạng thái khác biệt" chỉ ghi những trạng thái có nội dung riêng (ví dụ thông điệp trạng thái rỗng); các trạng thái còn lại kế thừa bảng trạng thái của mẫu và không được bỏ. Thứ ba, route phải theo quy tắc URL ở mục 2.4 và phải nằm dưới nhánh route của mục menu ghi ở trường "Mục menu". Thứ tư, mọi lệch khỏi mẫu về bố cục hay hành vi phải được nêu ở "Khác biệt so với mẫu" kèm lý do; lệch không nêu được coi là lỗi khi duyệt thiết kế.

### 1.4. Phạm vi

Tài liệu áp dụng cho hai ứng dụng web của Datahub là `dh-console` (giao diện quản trị cho mọi phân hệ) và `dh-portal` (cổng nhà phát triển của PH-15). Tài liệu không áp dụng cho trang đăng nhập (do Keycloak phục vụ theo FR-00-001, giao diện trang đăng nhập được tùy biến bằng chủ đề Keycloak dùng chung token ở D03-05-02 nhưng nằm ngoài bố cục mô tả ở đây), cho thư điện tử thông báo và cho báo cáo xuất tệp.

## 2. Kiến trúc thông tin

### 2.1. Hai ứng dụng và lý do tách

Datahub có hai ứng dụng giao diện với hai đối tượng người dùng khác nhau về bản chất. Bảng dưới đây so sánh hai ứng dụng để giải thích vì sao chúng có IA, khung bố cục và quy tắc truy cập khác nhau dù dùng chung design system `@datahub/ui`.

| Tiêu chí | `dh-console` | `dh-portal` |
|---|---|---|
| Đối tượng | Cán bộ của tỉnh và của đơn vị vận hành nền tảng: quản trị nền tảng, quản trị tỉnh, kỹ sư tích hợp, cán bộ nghiệp vụ, chủ quản dữ liệu, cán bộ đối soát, lãnh đạo, kiểm toán viên | Nhà phát triển HTTT (thường là nhân sự nhà thầu, không phải cán bộ nhà nước) |
| Phân hệ phục vụ | PH-01 … PH-20 (trừ phần công khai của PH-15) | PH-15 (danh mục API công khai, tài liệu, thử API, sandbox, ứng dụng của nhà phát triển) |
| Đăng nhập | Bắt buộc với mọi trang, OIDC qua realm của tenant (FR-00-001), MFA cho vai trò quản trị (FR-00-002) | Trang danh mục và tài liệu có thể xem không đăng nhập nếu tenant bật chế độ công khai; trang "Ứng dụng của tôi", "Thông tin xác thực", "Sandbox" bắt buộc đăng nhập |
| Mật độ thông tin | Cao: bảng, biểu mẫu dài, log | Vừa: văn bản tài liệu, ví dụ mã |
| Chiều rộng tối thiểu | 1366×768 mục tiêu thiết kế (mục 3.4) | Từ 360px (D02-02 §2.2) |
| Ngôn ngữ | Tiếng Việt | Tiếng Việt mặc định, tiếng Anh nên có |
| Bố cục | Sidebar + topbar (mục 3) | Topbar ngang + mục lục trái trong trang tài liệu (PTN-14) |
| Quan hệ quản trị | Quản trị nội dung cổng (trang giới thiệu, API công khai, duyệt ứng dụng) đặt trong `dh-console`, nhóm "Kết nối & API" | Chỉ hiển thị, không quản trị |

Việc tách hai ứng dụng có ba lý do. Thứ nhất, bề mặt tấn công khác nhau: `dh-portal` có thể mở ra ngoài mạng nội bộ tỉnh, còn `dh-console` chỉ truy cập từ mạng quản trị; tách mã và tách miền giúp chính sách mạng và CSP đơn giản. Thứ hai, nhịp phát hành khác nhau: nội dung cổng thay đổi theo tài liệu API, còn console thay đổi theo tính năng. Thứ ba, người dùng khác nhau về thói quen: nhà phát triển quen bố cục tài liệu kiểu "mục lục trái, nội dung giữa, ví dụ phải", còn cán bộ quản trị cần điều hướng chức năng sâu.

### 2.2. Nguyên tắc tổ chức menu

Menu của `dh-console` được chia theo **nhóm nhiệm vụ của người dùng**, không theo tên kỹ thuật của phân hệ hay đơn vị triển khai. Người dùng không cần biết "PH-10" hay "dh-integration" là gì; họ cần biết "tôi muốn cho hai hệ thống trao đổi sự kiện thì vào đâu". Năm nguyên tắc sau chi phối việc sắp xếp cây menu.

1. **Nhãn là việc, không là hệ thống.** Nhãn menu dùng danh từ nghiệp vụ quen thuộc với cán bộ ("Hệ thống thành viên", "Danh mục dùng chung", "Giao dịch") chứ không dùng tên công nghệ ("Kafka topic", "APISIX route"). Thuật ngữ kỹ thuật chỉ xuất hiện ở cấp 2 khi người dùng mục tiêu là kỹ sư (ví dụ "Topic sự kiện" cho kỹ sư tích hợp).
2. **Tối đa hai cấp trong sidebar.** Cấp 1 là nhóm nhiệm vụ (không điều hướng, chỉ mở/đóng), cấp 2 là màn hình đích. Mọi cấp sâu hơn (chi tiết đối tượng, tab) đi bằng điều hướng trong trang và được thể hiện trên breadcrumb, không thêm cấp menu thứ ba. Giới hạn này giữ sidebar đọc được trong một lần nhìn và tránh menu kiểu cây thư mục của hệ cũ.
3. **Mỗi nhóm không quá chín mục cấp 2.** Khi một nhóm vượt chín mục, tách nhóm hoặc gộp màn hình thành tab trong một trang.
4. **Thứ tự nhóm theo tần suất.** Nhóm dùng hằng ngày (Tổng quan, Việc của tôi) ở trên; nhóm dùng thỉnh thoảng (Quản trị) ở dưới. Trong một nhóm, mục thường dùng nhất đứng đầu.
5. **Ẩn theo quyền, không ẩn theo phân hệ chưa triển khai bằng cờ trong mã.** Một mục hiện khi người dùng có quyền xem màn hình đích và phân hệ đã được bật cho tenant (cấu hình PH-20). Phân hệ thuộc đợt sau chưa phát hành thì không có mục trong bản dựng, không hiện dạng "sắp ra mắt".

### 2.3. Cây điều hướng của `dh-console`

#### 2.3.1. Sơ đồ tổng quát

Sơ đồ dưới đây thể hiện mười hai nhóm cấp 1 của sidebar và các mục cấp 2. Mục có hậu tố "(Đ2)" hoặc "(Đ3)" thuộc đợt 2 hoặc đợt 3 theo bảng phân hệ của D03-01 §4.1; các mục còn lại thuộc MVP.

```mermaid
flowchart LR
    ROOT(["dh-console"])
    ROOT --> N0["Tổng quan"]
    ROOT --> N1["Việc của tôi"]
    ROOT --> N2["Kết nối & API"]
    ROOT --> N3["Tích hợp"]
    ROOT --> N4["Dữ liệu dùng chung"]
    ROOT --> N5["Thanh toán (Đ2)"]
    ROOT --> N6["Quy trình (Đ2)"]
    ROOT --> N7["Giám sát & kiểm toán"]
    ROOT --> N8["Vận hành"]
    ROOT --> N9["Quản trị"]
    ROOT -.-> AI["Trợ lý AI (Đ3)<br/>bảng bên + CommandPalette"]
    ROOT -.-> TB["Thanh trên: tìm kiếm, thông báo,<br/>tenant, tài khoản, trợ giúp"]

    N0 --> N0a["Bảng điều khiển"]
    N1 --> N1a["Hộp việc"] & N1b["Yêu cầu tôi đã gửi"] & N1c["Tác vụ nền"]
    N2 --> N2a["Hệ thống thành viên"] & N2b["Danh mục API"] & N2c["Gói sử dụng"] & N2d["Đăng ký sử dụng"] & N2e["Chính sách cổng API"] & N2f["Nút gateway"] & N2g["Cổng nhà phát triển (Đ2)"]
    N3 --> N3a["Luồng tích hợp"] & N3b["Bộ điều hợp"] & N3c["Kết nối nguồn"] & N3d["Dự án sự kiện"] & N3e["Topic sự kiện"] & N3f["Sơ đồ kết nối"] & N3g["Dịch vụ quốc gia"]
    N4 --> N4a["Danh mục dùng chung"] & N4b["Đồng bộ danh mục quốc gia"] & N4c["Dữ liệu chủ (Đ3)"] & N4d["Chất lượng dữ liệu (Đ3)"] & N4e["Quyền riêng tư (Đ2)"]
    N5 --> N5a["Giao dịch"] & N5b["Đối soát"] & N5c["Hoàn tiền"] & N5d["Dịch vụ thu"] & N5e["Nhà cung cấp & đối tác"] & N5f["Kênh thanh toán"]
    N6 --> N6a["Mô hình quy trình"] & N6b["Phiên quy trình"]
    N7 --> N7a["Bảng giám sát"] & N7b["Cảnh báo"] & N7c["Tra log"] & N7d["Truy vết"] & N7e["Nhật ký kiểm toán"] & N7f["Báo cáo chỉ tiêu (Đ3)"]
    N8 --> N8a["Hàng đợi lỗi (DLQ)"] & N8b["Tham số hệ thống"] & N8c["Sao lưu & khôi phục"] & N8d["Di trú hệ cũ"]
    N9 --> N9a["Người dùng"] & N9b["Nhóm & vai trò"] & N9c["Chính sách truy cập"] & N9d["Cài đặt tỉnh"] & N9e["Tenant (nền tảng)"]
```

Sơ đồ được đọc từ trái sang phải: gốc là ứng dụng, tầng giữa là nhóm cấp 1 hiển thị trên sidebar, tầng phải là mục cấp 2 dẫn tới màn hình. Hai nút nối bằng nét đứt (Trợ lý AI và thanh trên) không phải nhóm menu mà là các điểm vào luôn có mặt ở mọi màn hình. Nhóm "Tổng quan" chỉ có một mục nên được hiển thị như một mục đơn ở cấp 1, không có mũi tên mở rộng. Nhóm "Cài đặt cá nhân" không nằm trên sidebar mà được mở từ menu tài khoản trên thanh trên (mục 2.10).

#### 2.3.2. Bảng mục menu chi tiết

Bảng dưới đây là đặc tả chuẩn của cây menu. Kỹ sư dùng nó để sinh cấu hình route và menu; kiểm thử viên dùng nó để kiểm tra hiển thị theo quyền (mục 2.6). Cột "Nhóm người dùng chính" dùng tên nhóm ở D02-02 §2.1; vai trò phân quyền cụ thể (`ROLE-*`) sẽ được ánh xạ ở D02-08. Cột "Mẫu chính" cho biết PTN của màn hình đích; các màn con (chi tiết, biểu mẫu) có mẫu riêng được khai báo trong tập UI phân hệ. Cột "Đợt" theo D03-01 §4.1.

| # | Nhóm cấp 1 | Mục cấp 2 | PH | Route | Nhóm người dùng chính | Mẫu chính | Đợt |
|---|---|---|---|---|---|---|---|
| 1 | Tổng quan | Bảng điều khiển | PH-13 | `/tong-quan` | Mọi nhóm (nội dung thẻ theo quyền) | PTN-06 | MVP |
| 2 | Việc của tôi | Hộp việc | Dùng chung (FR-00-070) | `/viec-cua-toi` | Mọi nhóm có quyền duyệt | PTN-10 | MVP |
| 3 | Việc của tôi | Yêu cầu tôi đã gửi | Dùng chung | `/viec-cua-toi/da-gui` | Mọi nhóm | PTN-10 | MVP |
| 4 | Việc của tôi | Tác vụ nền | Dùng chung (FR-00-031, FR-00-054) | `/viec-cua-toi/tac-vu-nen` | Mọi nhóm | PTN-01 | MVP |
| 5 | Kết nối & API | Hệ thống thành viên | PH-01 | `/ket-noi/he-thong` | Quản trị tỉnh | PTN-01 | MVP |
| 6 | Kết nối & API | Danh mục API | PH-02 | `/ket-noi/api` | Quản trị tỉnh, Kỹ sư tích hợp | PTN-01 | MVP |
| 7 | Kết nối & API | Gói sử dụng | PH-02 | `/ket-noi/goi-su-dung` | Quản trị tỉnh | PTN-01 | MVP |
| 8 | Kết nối & API | Đăng ký sử dụng | PH-02 | `/ket-noi/dang-ky` | Quản trị tỉnh, Chủ quản dữ liệu | PTN-01 | MVP |
| 9 | Kết nối & API | Chính sách cổng API | PH-03 | `/ket-noi/chinh-sach` | Quản trị tỉnh | PTN-01 | MVP |
| 10 | Kết nối & API | Nút gateway | PH-03 | `/ket-noi/gateway` | Quản trị tỉnh, Quản trị nền tảng | PTN-11 | MVP |
| 11 | Kết nối & API | Cổng nhà phát triển | PH-15 (quản trị) | `/ket-noi/cong-nha-phat-trien` | Quản trị tỉnh | PTN-12 | Đợt 2 |
| 12 | Tích hợp | Luồng tích hợp | PH-04 | `/tich-hop/luong` | Kỹ sư tích hợp | PTN-01 (danh sách), PTN-07 (thiết kế) | MVP |
| 13 | Tích hợp | Bộ điều hợp | PH-05 | `/tich-hop/bo-dieu-hop` | Kỹ sư tích hợp | PTN-01 | MVP |
| 14 | Tích hợp | Kết nối nguồn | PH-05 | `/tich-hop/ket-noi-nguon` | Kỹ sư tích hợp | PTN-01 | MVP |
| 15 | Tích hợp | Dự án sự kiện | PH-10 | `/tich-hop/du-an` | Kỹ sư tích hợp | PTN-01 | MVP |
| 16 | Tích hợp | Topic sự kiện | PH-10 | `/tich-hop/topic` | Kỹ sư tích hợp | PTN-01 | MVP |
| 17 | Tích hợp | Sơ đồ kết nối | PH-10 | `/tich-hop/so-do` | Kỹ sư tích hợp, Quản trị tỉnh | PTN-07 (chế độ xem) | MVP |
| 18 | Tích hợp | Dịch vụ quốc gia | PH-14 | `/tich-hop/dich-vu-quoc-gia` | Quản trị tỉnh, Kỹ sư tích hợp | PTN-01 | MVP |
| 19 | Dữ liệu dùng chung | Danh mục dùng chung | PH-07 | `/du-lieu/danh-muc` | Cán bộ nghiệp vụ | PTN-08 | MVP |
| 20 | Dữ liệu dùng chung | Đồng bộ danh mục quốc gia | PH-07 | `/du-lieu/dong-bo-quoc-gia` | Cán bộ nghiệp vụ, Quản trị tỉnh | PTN-01 | MVP |
| 21 | Dữ liệu dùng chung | Dữ liệu chủ | PH-06 | `/du-lieu/du-lieu-chu` | Cán bộ nghiệp vụ | PTN-01 | Đợt 3 |
| 22 | Dữ liệu dùng chung | Chất lượng dữ liệu | PH-08 | `/du-lieu/chat-luong` | Cán bộ nghiệp vụ, Chủ quản dữ liệu | PTN-06 | Đợt 3 |
| 23 | Dữ liệu dùng chung | Quyền riêng tư | PH-09 | `/du-lieu/quyen-rieng-tu` | Chủ quản dữ liệu | PTN-01 | Đợt 2 |
| 24 | Thanh toán | Giao dịch | PH-19 | `/thanh-toan/giao-dich` | Cán bộ đối soát | PTN-01 | Đợt 2 |
| 25 | Thanh toán | Đối soát | PH-19 | `/thanh-toan/doi-soat` | Cán bộ đối soát | PTN-01 | Đợt 2 |
| 26 | Thanh toán | Hoàn tiền | PH-19 | `/thanh-toan/hoan-tien` | Cán bộ đối soát | PTN-01 | Đợt 2 |
| 27 | Thanh toán | Dịch vụ thu | PH-19 | `/thanh-toan/dich-vu` | Quản trị tỉnh, Cán bộ đối soát | PTN-08 | Đợt 2 |
| 28 | Thanh toán | Nhà cung cấp & đối tác | PH-19 | `/thanh-toan/doi-tac` | Quản trị tỉnh | PTN-01 | Đợt 2 |
| 29 | Thanh toán | Kênh thanh toán | PH-19 | `/thanh-toan/kenh` | Quản trị tỉnh | PTN-06 | Đợt 2 |
| 30 | Quy trình | Mô hình quy trình | PH-11 | `/quy-trinh/mo-hinh` | Kỹ sư tích hợp, Quản trị tỉnh | PTN-01, PTN-07 | Đợt 2 |
| 31 | Quy trình | Phiên quy trình | PH-11 | `/quy-trinh/phien` | Quản trị tỉnh, Cán bộ nghiệp vụ | PTN-01 | Đợt 2 |
| 32 | Giám sát & kiểm toán | Bảng giám sát | PH-13 | `/giam-sat/bang-dieu-khien` | Quản trị tỉnh, Quản trị nền tảng | PTN-06 | MVP |
| 33 | Giám sát & kiểm toán | Cảnh báo | PH-13 | `/giam-sat/canh-bao` | Quản trị tỉnh | PTN-01 | MVP |
| 34 | Giám sát & kiểm toán | Tra log | PH-13 | `/giam-sat/log` | Quản trị tỉnh, Kỹ sư tích hợp | PTN-11 | MVP |
| 35 | Giám sát & kiểm toán | Truy vết | PH-13 | `/giam-sat/truy-vet` | Kỹ sư tích hợp | PTN-11 | MVP |
| 36 | Giám sát & kiểm toán | Nhật ký kiểm toán | PH-13 | `/giam-sat/kiem-toan` | Kiểm toán viên, Quản trị tỉnh | PTN-11 | MVP |
| 37 | Giám sát & kiểm toán | Báo cáo chỉ tiêu | PH-16 | `/giam-sat/chi-tieu` | Lãnh đạo, Quản trị tỉnh | PTN-06 | Đợt 3 |
| 38 | Vận hành | Hàng đợi lỗi (DLQ) | PH-18 | `/van-hanh/dlq` | Quản trị tỉnh, Kỹ sư tích hợp | PTN-01 | MVP |
| 39 | Vận hành | Tham số hệ thống | PH-18 | `/van-hanh/tham-so` | Quản trị tỉnh | PTN-12 | MVP |
| 40 | Vận hành | Sao lưu & khôi phục | PH-18 | `/van-hanh/sao-luu` | Quản trị tỉnh, Quản trị nền tảng | PTN-01 | MVP |
| 41 | Vận hành | Di trú hệ cũ | PH-18 | `/van-hanh/di-tru` | Quản trị tỉnh | PTN-05 (chạy), PTN-01 (lịch sử) | MVP |
| 42 | Quản trị | Người dùng | PH-12 | `/quan-tri/nguoi-dung` | Quản trị tỉnh | PTN-01 | MVP |
| 43 | Quản trị | Nhóm & vai trò | PH-12 | `/quan-tri/vai-tro` | Quản trị tỉnh | PTN-08 | MVP |
| 44 | Quản trị | Chính sách truy cập | PH-12 | `/quan-tri/chinh-sach` | Quản trị tỉnh | PTN-01 | MVP |
| 45 | Quản trị | Cài đặt tỉnh | PH-20 (phần tenant tự quản) | `/quan-tri/cai-dat-tinh` | Quản trị tỉnh | PTN-12 | MVP |
| 46 | Quản trị | Tenant | PH-20 | `/nen-tang/tenant` | Quản trị nền tảng | PTN-01 | MVP |

Có bốn điểm trong bảng cần thuyết minh. Thứ nhất, màn "Bảng điều khiển" ở mục 1 thuộc PH-13 về dữ liệu nhưng đóng vai trò trang chủ của mọi người dùng, nên nội dung thẻ được lắp theo quyền: cán bộ đối soát thấy thẻ giao dịch, kỹ sư tích hợp thấy thẻ luồng lỗi, lãnh đạo thấy thẻ chỉ tiêu; người không có quyền xem số liệu nào chỉ thấy thẻ "Việc của tôi" và "Thông báo mới". Thứ hai, mục "Tenant" (mục 46) dùng nhánh route `/nen-tang/` thay vì `/quan-tri/` vì đây là màn của vai trò nền tảng, thao tác trên nhiều tenant; nó chỉ xuất hiện trong nhóm Quản trị khi người dùng có vai trò nền tảng, và được đặt cuối nhóm, ngăn cách bằng `CMP-Divider` với nhãn "Nền tảng". Thứ ba, màn thiết kế luồng (PTN-07) không có mục menu riêng; người dùng vào từ danh sách luồng (`/tich-hop/luong/{ma-luong}/thiet-ke`) để luôn có ngữ cảnh luồng nào đang sửa. Thứ tư, PH-17 (Trợ lý AI) không có mục menu vì nó là năng lực xuyên suốt, được mở bằng nút trên thanh trên hoặc từ CommandPalette (mục 2.12).

#### 2.3.3. Lối vào ngoài sidebar

Một số màn không nằm trên sidebar nhưng vẫn có route ổn định và có thể liên kết sâu. Bảng sau liệt kê các lối vào đó để không màn nào "mồ côi".

| Màn hình | Route | Lối vào | Mẫu |
|---|---|---|---|
| Cài đặt cá nhân | `/ca-nhan/cai-dat` | Menu tài khoản (`CMP-UserMenu`) › Cài đặt cá nhân | PTN-12 |
| Phiên đăng nhập của tôi | `/ca-nhan/phien` | Menu tài khoản › Phiên đăng nhập (FR-00-005) | PTN-01 |
| Thông báo (toàn trang) | `/ca-nhan/thong-bao` | Trung tâm thông báo › Xem tất cả | PTN-01 |
| Bộ lọc đã lưu | `/ca-nhan/bo-loc` | Menu tài khoản › Bộ lọc đã lưu (FR-00-024) | PTN-01 |
| Trợ giúp | Mở HDSD theo ngữ cảnh ở tab mới | Nút trợ giúp trên thanh trên (FR-00-082) | — |
| Trang lỗi 403, 404, 500, bảo trì | `/loi/403`, `/loi/404`, `/loi/500`, `/bao-tri` | Hệ thống tự điều hướng | PTN-13 |
| Chọn tenant | `/chon-tenant` | Sau đăng nhập khi người dùng thuộc nhiều tenant và chưa có tenant mặc định | PTN-13 (biến thể) |

### 2.4. Quy tắc URL

URL là một phần của giao diện: người dùng chia sẻ URL cho đồng nghiệp, dán vào phiếu hỗ trợ, đánh dấu trang. Vì vậy URL phải ổn định, đọc được và mang đủ trạng thái để mở lại đúng màn hình (FR-00-022). Các quy tắc dưới đây áp dụng cho `dh-console`; `dh-portal` theo cùng quy tắc với tiền tố riêng ở mục 2.14.

**Đường dẫn (path).** Đường dẫn gồm các đoạn tiếng Việt không dấu viết `kebab-case`, theo cấu trúc `/{nhóm}/{tài-nguyên}/{mã-đối-tượng}/{màn-con}`. Đoạn `{nhóm}` khớp với nhóm menu (bảng ở mục 2.3.2), đoạn `{tài-nguyên}` khớp với mục cấp 2. Các màn con chuẩn dùng từ cố định sau để mọi phân hệ thống nhất: `/moi` (tạo mới, PTN-03), `/{ma}` (chi tiết, PTN-02), `/{ma}/sua` (sửa, PTN-03), `/{ma}/thiet-ke` (designer, PTN-07), `/{ma}/lich-su` (tab Lịch sử có thể liên kết sâu), `/nhap` (nhập dữ liệu, PTN-09). Tab trong trang chi tiết được phản ánh bằng đoạn cuối, ví dụ `/ket-noi/api/tra-cuu-ho-tich/phien-ban`, để có thể gửi liên kết thẳng tới tab.

**Mã đối tượng trong URL.** Khi đối tượng có mã nghiệp vụ duy nhất trong tenant và bất biến (mã danh mục, mã API, mã luồng, mã HTTT, mã giao dịch), URL dùng mã đó thay cho khóa nội bộ, ví dụ `/du-lieu/danh-muc/DM_GIOI_TINH` chứ không phải `/du-lieu/danh-muc/5f2c…`. Mã nghiệp vụ giúp người dùng đọc được URL và giúp phiếu hỗ trợ có nghĩa. Khi đối tượng không có mã nghiệp vụ ổn định (bản ghi kiểm toán, phiên quy trình, thông báo), URL dùng định danh do hệ thống sinh nhưng là định danh công khai (ULID hoặc UUID), không bao giờ dùng khóa tự tăng của CSDL, vì khóa tự tăng cho phép suy đoán số lượng bản ghi và vi phạm tinh thần FR-00-011. Mã trong URL được mã hóa theo RFC 3986; mã chứa ký tự đặc biệt phải được `encodeURIComponent`.

**Tham số truy vấn (query).** Mọi trạng thái người dùng có thể muốn chia sẻ được giữ trên query: từ khóa, bộ lọc, sắp xếp, trang, số dòng mỗi trang, tab con, khoảng thời gian. Bảng dưới quy định tên tham số dùng chung để `CMP-FilterBar`, `CMP-DataTable` và `CMP-Pagination` có thể đồng bộ với URL qua một hook chung `useUrlState` mà không cần cấu hình theo màn.

| Tham số | Ý nghĩa | Ví dụ | Ghi chú |
|---|---|---|---|
| `q` | Từ khóa tìm kiếm | `q=da%20nang` | Cắt khoảng trắng đầu cuối trước khi ghi lên URL |
| `trang` | Số trang, bắt đầu từ 1 | `trang=3` | Bỏ khỏi URL khi bằng 1 |
| `co` | Cỡ trang | `co=50` | Chỉ nhận 10, 20, 50, 100 (FR-00-021); bỏ khi bằng 20 |
| `sap-xep` | Trường và chiều sắp xếp | `sap-xep=ngay-tao:giam` | Chiều `tang` hoặc `giam`; nhiều trường nối bằng dấu phẩy nếu màn cho phép đa cột |
| `{tên-trường}` | Giá trị lọc | `trang-thai=phat-hanh,cho-duyet` | Nhiều giá trị nối bằng dấu phẩy (FR-00-023) |
| `tu`, `den` | Khoảng thời gian | `tu=2026-11-01&den=2026-11-21` | Ngày theo ISO `yyyy-MM-dd`; thời điểm theo ISO có múi giờ |
| `khoang` | Khoảng tương đối | `khoang=24h` | Dùng cho PTN-06 và PTN-11; loại trừ `tu`/`den` |
| `chon` | Đối tượng đang mở trong Drawer hoặc bảng bên | `chon=GD20261121000123` | Cho phép liên kết sâu tới Drawer chi tiết |
| `bo-loc` | Mã bộ lọc đã lưu | `bo-loc=bl_01J…` | FR-00-024; khi có, các tham số lọc khác ghi đè lên bộ lọc đã lưu |

Ba quy tắc về hành vi đi kèm bảng trên. Thứ nhất, giá trị trên URL dùng **mã giá trị** (ví dụ `phat-hanh`) chứ không dùng nhãn hiển thị (ví dụ "Phát hành"), để URL không đổi khi đổi nhãn hay đổi ngôn ngữ. Thứ hai, thay đổi bộ lọc hoặc từ khóa ghi lên URL bằng `replace` (không tạo mục lịch sử mới cho mỗi phím gõ), còn chuyển trang và mở chi tiết dùng `push` để nút Quay lại của trình duyệt hoạt động như người dùng kỳ vọng. Thứ ba, tham số không hợp lệ (cỡ trang 37, trang âm, giá trị lọc không tồn tại) bị bỏ qua và được sửa lại trên URL bằng `replace`, kèm một `CMP-Toast` mức thông tin "Một số điều kiện lọc không còn hợp lệ nên đã được bỏ qua."; không hiển thị trang lỗi.

**Không đưa dữ liệu nhạy cảm lên URL.** URL được ghi trong log truy cập, lịch sử trình duyệt và tiêu đề Referer, nên tuyệt đối không đặt lên URL số định danh cá nhân, số điện thoại, nội dung bản tin hay bí mật. Khi người dùng tìm kiếm theo trường mức Nhạy cảm (ví dụ tra giao dịch theo số CCCD người nộp), giá trị tìm kiếm được giữ trong trạng thái phiên của trang chứ không ghi lên query, và URL chia sẻ được sẽ không có điều kiện đó; giao diện hiển thị dòng chú thích "Điều kiện tìm theo thông tin cá nhân không được lưu trong liên kết chia sẻ."

**Liên kết sâu và quay về sau đăng nhập.** Mọi route đều mở được trực tiếp. Khi phiên hết hạn hoặc chưa đăng nhập, `dh-console` lưu URL đầy đủ (path và query) vào tham số `state` của luồng OIDC và quay về đúng URL sau đăng nhập (FR-00-001). Khi URL trỏ tới tenant khác tenant đang làm việc (xem mục 2.11), giao diện hỏi người dùng có muốn chuyển tenant hay không, không tự chuyển.

### 2.5. Breadcrumb và tiêu đề tab trình duyệt

Breadcrumb (`CMP-Breadcrumb`) đặt ở dòng đầu của `CMP-PageHeader`, phía trên tiêu đề trang. Breadcrumb thể hiện vị trí theo cấu trúc IA, không theo lịch sử duyệt: nhóm cấp 1, mục cấp 2, đối tượng cha (nếu có), đối tượng hiện tại. Ví dụ màn sửa một mục danh mục có breadcrumb "Dữ liệu dùng chung › Danh mục dùng chung › Giới tính › Sửa mục". Nhóm cấp 1 hiển thị dạng chữ không bấm được (vì nhóm không có trang riêng); các phần tử còn lại là liên kết, trừ phần tử cuối là trang hiện tại có `aria-current="page"`. Liên kết tới mục cấp 2 trên breadcrumb khôi phục bộ lọc gần nhất người dùng đã dùng ở danh sách đó trong phiên (mục 2.4 và hành vi "quay lại giữ bộ lọc" của PTN-01), vì đó là điều người dùng muốn khi bấm ngược.

Phần tử đối tượng trên breadcrumb hiển thị tên ngắn của đối tượng, cắt bằng dấu ba chấm ở 32 ký tự kèm `CMP-Tooltip` hiện đầy đủ. Khi breadcrumb dài hơn chiều rộng khả dụng, các phần tử giữa được gộp thành một nút "…" mở `CMP-DropdownMenu`, giữ nguyên phần tử đầu và hai phần tử cuối. Trang chủ "Tổng quan" và các trang cấp 2 không có đối tượng cha vẫn hiển thị breadcrumb hai phần tử để vị trí luôn nhất quán; riêng PTN-13 (trang lỗi) không có breadcrumb.

Tiêu đề tab trình duyệt (`document.title`) có dạng `{Tiêu đề trang} · {Tên đối tượng nếu có} · Datahub`, ví dụ "Sửa mục · Giới tính · Datahub". Khi người dùng đang ở chế độ liên tenant, tiền tố `[Liên tenant] ` được thêm vào đầu tiêu đề. Khi có việc chờ duyệt mới, không đưa số đếm lên tiêu đề tab, vì số đếm thay đổi liên tục gây nhiễu cho trình đọc màn hình; số đếm chỉ hiển thị trên huy hiệu của sidebar và thanh trên. Tiêu đề tab được cập nhật mỗi khi đổi route và được thông báo cho trình đọc màn hình bằng cách chuyển focus tới tiêu đề trang (mục 3.7).

### 2.6. Hiển thị và ẩn theo quyền

Datahub phân quyền theo hành động (`PERM-{PH}-{động-từ}`, định nghĩa ở D02-08) chứ không chỉ theo màn hình, kế thừa mục 6 của `docs/ui_ux_rule.md`. Giao diện dùng quyền để quyết định cái gì hiện ra, nhưng **backend luôn kiểm tra lại quyền trên mọi API**; ẩn trên giao diện chỉ phục vụ trải nghiệm, không phải biện pháp bảo vệ. Bảng dưới quy định hành vi giao diện cho từng loại phần tử khi người dùng thiếu quyền.

| Phần tử | Khi thiếu quyền | Lý do |
|---|---|---|
| Mục menu cấp 2 | Ẩn hoàn toàn | Người dùng không nên thấy chức năng họ không dùng được; giảm nhiễu |
| Nhóm menu cấp 1 | Ẩn khi mọi mục con đều bị ẩn | Tránh nhóm rỗng |
| Truy cập route trực tiếp (gõ URL, liên kết cũ) | Hiển thị trang 403 (PTN-13) trong khung ứng dụng, giữ sidebar và thanh trên | Người dùng hiểu là thiếu quyền chứ không phải trang hỏng; có nút "Về Tổng quan" và "Yêu cầu quyền" |
| Nút hành động chính (Thêm, Nhập, Xuất) | Ẩn | Tránh gợi ý một hành động không làm được |
| Hành động trên hàng, hành động trong trang chi tiết | Ẩn nếu thiếu quyền; hiện nhưng vô hiệu kèm tooltip lý do nếu đủ quyền mà trạng thái không cho phép | Phân biệt "không bao giờ làm được" với "chưa làm được lúc này" (FR-00-053) |
| Trường biểu mẫu không được sửa | Hiện ở dạng chỉ đọc, không ẩn | Kế thừa CRUD-U-03; người dùng cần thấy giá trị |
| Trường dữ liệu Nhạy cảm | Hiện bằng `CMP-MaskedValue`; nút "Hiện" chỉ có khi có quyền xem đầy đủ, bấm phải nêu lý do (`CMP-ReasonDialog`) và sinh bản ghi kiểm toán | FR-00-034, FR-00-040 |
| Thẻ trên bảng điều khiển | Ẩn thẻ | Bảng điều khiển lắp theo quyền |
| Tab trong trang chi tiết | Ẩn tab; riêng tab Lịch sử luôn hiện với người có quyền xem đối tượng | FR-00-043 |

Thông tin quyền được nạp một lần sau đăng nhập dưới dạng tập quyền hiệu lực của người dùng trong tenant hiện tại (do PH-12 trả về), lưu trong bộ nhớ của TanStack Query với khóa gắn tenant, và được làm mới khi đổi tenant hoặc khi API trả 403 bất ngờ (dấu hiệu quyền vừa bị thu hồi). Khi một thao tác bị backend từ chối 403 dù giao diện đã cho hiện nút, giao diện hiển thị `CMP-Alert` mức lỗi "Bạn không còn quyền thực hiện thao tác này. Quyền của bạn có thể vừa được thay đổi." kèm mã truy vết, làm mới tập quyền và vẽ lại màn hình.

Trang 403 có nút "Yêu cầu quyền" mở biểu mẫu nhanh (PTN-04) gửi yêu cầu tới quản trị tỉnh với nội dung tự điền: màn hình, quyền thiếu, lý do do người dùng nhập. Nút này chỉ hiện khi tenant bật quy trình yêu cầu quyền (cấu hình PH-12); nếu không, trang hiển thị tên và thư điện tử đầu mối quản trị của tỉnh.

### 2.7. Tìm kiếm toàn cục và CommandPalette

`dh-console` có một điểm tìm kiếm duy nhất: ô tìm kiếm dạng viên nang (`radius-pill`) giữa thanh trên, bấm vào hoặc nhấn `Ctrl+K` (trên macOS `⌘K`) mở `CMP-CommandPalette`. Ô tìm kiếm trên thanh trên không tự tìm; nó là nút mở bảng lệnh, hiển thị chữ giữ chỗ "Tìm màn hình, đối tượng hoặc lệnh" và gợi ý phím tắt bằng `CMP-Kbd`. Cách làm này giữ thanh trên gọn và cho người dùng một thói quen duy nhất.

CommandPalette là lớp nổi vật liệu `glass-modal`, rộng `size-modal-md`, đặt cách mép trên viewport 12% chiều cao, danh sách kết quả nằm trong giếng nội dung nền đặc. Kết quả được nhóm thành bốn nhóm theo thứ tự cố định dưới đây; mỗi nhóm hiển thị tối đa năm kết quả kèm dòng "Xem tất cả kết quả {nhóm}".

| Nhóm kết quả | Nguồn | Ví dụ | Hành vi khi chọn |
|---|---|---|---|
| Màn hình | Cây menu đã lọc theo quyền, cộng các lối vào ở mục 2.3.3 | Gõ "giao dich" ra "Thanh toán › Giao dịch" | Điều hướng tới route |
| Đối tượng | API tìm kiếm hợp nhất của các phân hệ theo mã và tên (mã API, mã danh mục, mã luồng, mã HTTT, mã giao dịch) | Gõ "DM_GIOI" ra danh mục "Giới tính" | Mở trang chi tiết (PTN-02) |
| Lệnh | Danh sách lệnh đăng ký bởi từng màn và lệnh toàn cục | "Tạo API mới", "Chuyển sang chế độ tối", "Đổi tenant", "Mở Hộp việc" | Thực thi lệnh; lệnh tạo mới mở PTN-03 hoặc PTN-04 |
| Hỏi trợ lý AI | PH-17 (Đợt 3, khi tenant bật) | Câu hỏi tự nhiên "API nào trả thông tin hộ tịch?" | Mở bảng bên Trợ lý AI với câu hỏi đã điền |

Tìm kiếm trong CommandPalette tuân thủ FR-00-020: không phân biệt hoa thường và dấu tiếng Việt, khớp theo tiền tố từ và khớp mã chính xác. Kết quả "Màn hình" và "Lệnh" được lọc ngay tại trình duyệt; kết quả "Đối tượng" gọi máy chủ sau 250ms kể từ lần gõ cuối, tối thiểu hai ký tự, và chỉ trả đối tượng người dùng có quyền xem trong tenant hiện tại. Người dùng điều hướng bằng phím mũi tên, `Enter` để chọn, `Esc` để đóng, `Tab` để chuyển giữa các nhóm. Khi mở lại, CommandPalette hiển thị năm mục gần đây của người dùng (lưu cục bộ theo người dùng và tenant).

Về truy cập, CommandPalette là `role="dialog"` có `aria-modal="true"`, ô nhập là `role="combobox"` với `aria-controls` trỏ tới danh sách `role="listbox"`, mục đang chọn được thông báo bằng `aria-activedescendant`. Khi đóng, focus trở về phần tử đã mở bảng lệnh.

### 2.8. Việc của tôi

"Việc của tôi" là nhóm menu đứng thứ hai, ngay sau Tổng quan, hiện thực FR-00-070…072. Nó tổng hợp mọi yêu cầu chờ người dùng xử lý từ mọi phân hệ: duyệt kết nạp HTTT (PH-01), duyệt phát hành API và đăng ký sử dụng (PH-02), duyệt phát hành luồng (PH-04), duyệt Kamelet mới (PH-05), duyệt công bố danh mục (PH-07), chấp thuận khai thác dữ liệu (PH-09), việc trong quy trình BPMN (PH-11), duyệt hoàn tiền (PH-19), duyệt thay đổi vai trò (PH-12). Mỗi phân hệ đăng ký loại việc của mình với hộp việc chung qua hợp đồng ở D03-04; giao diện không gọi riêng từng phân hệ.

Mục "Hộp việc" trên sidebar mang `CMP-Badge` đếm số việc chưa xử lý, giới hạn hiển thị "99+". Số đếm được cập nhật qua kênh đẩy thời gian thực (SSE) khi có, và thăm dò 60 giây một lần khi kênh đẩy không khả dụng. Khi số đếm tăng, không phát âm báo và không dùng `aria-live` mức `assertive`; thay vào đó trung tâm thông báo nhận một thông báo "Có yêu cầu mới chờ bạn duyệt" (mục 2.9). Bố cục và hành vi chi tiết của hộp việc theo PTN-10.

### 2.9. Trung tâm thông báo

Trung tâm thông báo (`CMP-NotificationCenter`) hiện thực FR-00-060. Nút chuông trên thanh trên mang huy hiệu số thông báo chưa đọc; bấm mở một lớp nổi vật liệu `glass-overlay` rộng 400px, neo dưới nút chuông, gồm ba tab "Tất cả", "Việc cần làm", "Tác vụ nền" và nút "Đánh dấu đã đọc tất cả". Mỗi thông báo có biểu tượng loại, tiêu đề một dòng, mô tả tối đa hai dòng, thời điểm tương đối ("5 phút trước", kèm thời điểm tuyệt đối trên tooltip) và liên kết sâu tới đối tượng. Thông báo kết quả tác vụ nền (xuất tệp lớn theo FR-00-031, nhập dữ liệu theo FR-00-054) có nút hành động trực tiếp như "Tải tệp" hay "Xem báo cáo lỗi".

Thông báo phân thành ba mức với hành vi hiển thị khác nhau. Mức thông tin chỉ tăng huy hiệu. Mức cần chú ý (việc chờ duyệt, tác vụ nền xong) tăng huy hiệu và hiện `CMP-Notification` góc trên phải trong 6 giây nếu người dùng đang ở trong ứng dụng. Mức khẩn (cảnh báo vận hành mức nghiêm trọng của PH-13 gửi tới người trực) hiện `CMP-Notification` không tự đóng cho tới khi người dùng xác nhận đã xem. Thông báo không bao giờ chứa dữ liệu Hạn chế hoặc Nhạy cảm trong nội dung; chỉ chứa mã đối tượng và liên kết (cùng tinh thần FR-00-062). Toàn bộ lịch sử thông báo xem được ở trang `/ca-nhan/thong-bao` theo PTN-01; cấu hình kênh nhận theo loại (FR-00-061) nằm trong Cài đặt cá nhân (PTN-12).

### 2.10. Menu tài khoản

Menu tài khoản (`CMP-UserMenu`) ở góc phải thanh trên hiển thị `CMP-Avatar` chữ cái đầu của người dùng; bấm mở `CMP-DropdownMenu` gồm, theo thứ tự: khối thông tin (họ tên, thư điện tử, đơn vị, danh sách vai trò trong tenant hiện tại), "Cài đặt cá nhân", "Phiên đăng nhập", "Bộ lọc đã lưu", lựa chọn nhanh chế độ giao diện (Sáng / Tối / Theo hệ thống bằng `CMP-SegmentedControl`), "Phím tắt" (mở Modal liệt kê phím tắt, cũng mở bằng `?`), và "Đăng xuất" ở cuối, ngăn cách bằng `CMP-Divider`. Đăng xuất kết thúc phiên Keycloak (đăng xuất phía máy chủ, không chỉ xóa token trình duyệt) và xóa toàn bộ bộ nhớ đệm TanStack Query.

### 2.11. Ngữ cảnh tenant và truy cập liên tenant

**Hiển thị tenant hiện tại.** Theo FR-00-004, mọi màn hình hiển thị tenant hiện tại trên thanh trên. `CMP-TenantSwitcher` đặt ngay bên phải logo ở thanh trên, hiển thị tên ngắn của tỉnh (ví dụ "Tỉnh Mẫu A", dữ liệu giả lập) kèm mã tenant dạng `CMP-Identifier`. Với người dùng chỉ thuộc một tenant, thành phần hiển thị dạng chữ tĩnh không có mũi tên. Với người dùng thuộc nhiều tenant, bấm vào mở danh sách tenant có ô tìm kiếm, nhóm "Gần đây" ở trên.

**Đổi tenant.** Đổi tenant là thao tác nặng: giao diện hiển thị `CMP-ConfirmDialog` nếu trang hiện tại có thay đổi chưa lưu, sau đó điều hướng về `/tong-quan` của tenant mới, xóa toàn bộ bộ nhớ đệm truy vấn (`queryClient.clear()`), nạp lại tập quyền và cây menu. Không giữ lại route cũ vì đối tượng của tenant cũ không tồn tại ở tenant mới. Tiêu chí kiểm thử: sau khi đổi tenant, không có yêu cầu mạng nào mang ngữ cảnh tenant cũ và không có dữ liệu của tenant cũ trong bộ nhớ đệm (FR-00-004).

**Chế độ liên tenant.** Theo FR-00-012, chỉ vai trò nền tảng được truy cập dữ liệu của tenant không phải tenant nhà của họ, phải nêu lý do và được ghi kiểm toán. Người dùng có vai trò nền tảng chọn một tenant khác trong `CMP-TenantSwitcher` (danh sách có nhóm riêng "Truy cập liên tenant") thì giao diện mở `CMP-ReasonDialog` yêu cầu chọn loại lý do (hỗ trợ sự cố, kiểm tra cấu hình, theo yêu cầu của tỉnh, khác) và nhập mô tả tối thiểu 20 ký tự, tùy chọn kèm mã phiếu hỗ trợ. Sau khi xác nhận, máy chủ cấp một phiên liên tenant có thời hạn (mặc định 60 phút) và giao diện bước vào chế độ liên tenant với các dấu hiệu sau.

1. **Dải cảnh báo liên tenant** cố định ngay trên thanh trên, cao 32px, nền `color-warning-bg`, chữ `color-warning-on-bg`, có biểu tượng khiên và nội dung "Bạn đang truy cập dữ liệu của {Tên tỉnh} ở chế độ liên tenant. Mọi thao tác đều được ghi nhật ký kiểm toán. Còn {mm} phút." kèm nút "Kết thúc truy cập". Dải này là `CMP-Banner` biến thể `cross-tenant`, không đóng được, có `role="region"` và `aria-label="Cảnh báo truy cập liên tenant"`. Dải dùng nền đặc chứ không glass, vì đây là thông tin an toàn bắt buộc phải đọc được tuyệt đối.
2. **Viền khung** của vùng nội dung có thêm đường viền trên 2px màu `color-warning` (giá trị `-solid`) chạy suốt chiều ngang, để dù người dùng cuộn mất dải cảnh báo (dải không cuộn, nhưng phòng trường hợp ảnh chụp màn hình bị cắt) vẫn nhận ra.
3. **Tiền tố tiêu đề tab** `[Liên tenant]` như mục 2.5.
4. **Thao tác ghi** trong chế độ liên tenant mặc định bị vô hiệu kèm tooltip "Chế độ liên tenant chỉ cho phép xem"; tenant có thể cấp quyền ghi cho phiên liên tenant theo quy trình riêng của PH-20, khi đó mỗi thao tác ghi lại hỏi lý do bằng `CMP-ReasonDialog`.
5. **Hết hạn**: hai phút trước khi phiên liên tenant hết hạn, dải cảnh báo chuyển sang nội dung "Phiên liên tenant sẽ kết thúc sau 2 phút" và có nút "Gia hạn" (phải nêu lý do lần nữa). Khi hết hạn, giao diện quay về tenant nhà và hiển thị `CMP-Toast` thông báo.

Việc không dùng màu làm phương tiện duy nhất được bảo đảm vì dải có chữ và biểu tượng; màu vàng chỉ tăng cường nhận biết.

### 2.12. Trợ lý AI (PH-17)

Trợ lý AI thuộc Đợt 3 và có thể tắt theo tenant (D02-02 §5). Nó không chiếm mục menu mà có hai lối vào: nút biểu tượng "Trợ lý" trên thanh trên (chỉ hiện khi tenant bật) và nhóm "Hỏi trợ lý AI" trong CommandPalette. Khi mở, trợ lý hiển thị dạng **bảng bên** (complementary panel) gắn mép phải của vùng nội dung, rộng 400px, vật liệu `glass-chrome` khi nằm trên canvas, nội dung hội thoại trong giếng nền đặc. Bảng bên đẩy vùng nội dung thu hẹp lại chứ không phủ lên, để người dùng vừa đọc câu trả lời vừa thao tác trên màn hình (ví dụ trợ lý gợi ý ánh xạ trường trong khi kỹ sư đang ở PTN-07). Dưới `bp-xl`, bảng bên chuyển thành `CMP-Drawer` phủ.

Trợ lý nhận ngữ cảnh màn hình hiện tại (route, mã đối tượng, mã lỗi đang hiển thị) để trả lời đúng chỗ, ví dụ nút "Giải thích lỗi này" xuất hiện cạnh mã lỗi trong `CMP-Alert` khi trợ lý được bật. Mọi câu trả lời có nhãn "Nội dung do AI tạo, cần kiểm tra lại" và không bao giờ tự thực hiện thao tác ghi; trợ lý chỉ đề xuất, người dùng bấm áp dụng. Bảng bên có `role="complementary"` và `aria-label="Trợ lý AI"`.

### 2.13. Ma trận nhóm người dùng và nhóm menu

Ma trận dưới đây cho biết nhóm người dùng nào thường thấy nhóm menu nào. Nó không thay thế phân quyền ở D02-08 mà dùng làm căn cứ thiết kế: kiểm tra rằng mỗi nhóm người dùng có ít nhất một đường vào cho nhu cầu chính của họ, và sidebar của nhóm người dùng ít dùng (lãnh đạo, kiểm toán viên) đủ gọn. Ký hiệu: **●** là nhóm menu chính của người dùng (dùng thường xuyên), **○** là thấy một phần (một vài mục hoặc chỉ xem), ô trống là thường không thấy.

| Nhóm menu \ Nhóm người dùng | Quản trị nền tảng | Quản trị tỉnh | Kỹ sư tích hợp | Cán bộ nghiệp vụ | Chủ quản dữ liệu | Cán bộ đối soát | Lãnh đạo | Kiểm toán viên |
|---|---|---|---|---|---|---|---|---|
| Tổng quan | ● | ● | ● | ● | ● | ● | ● | ● |
| Việc của tôi | ● | ● | ● | ● | ● | ● | ○ | ○ |
| Kết nối & API | ○ | ● | ● | | ○ | | | ○ |
| Tích hợp | ○ | ● | ● | | | | | ○ |
| Dữ liệu dùng chung | | ○ | ○ | ● | ● | | | ○ |
| Thanh toán | | ○ | | | | ● | ○ | ○ |
| Quy trình | | ● | ○ | ○ | | | | |
| Giám sát & kiểm toán | ● | ● | ○ | | ○ | ○ | ○ | ● |
| Vận hành | ● | ● | ○ | | | | | |
| Quản trị | ● | ● | | | | | | ○ |

Từ ma trận có thể rút ra hai hệ quả thiết kế. Thứ nhất, lãnh đạo chủ yếu chỉ thấy Tổng quan và Báo cáo chỉ tiêu, nên bảng điều khiển phải tự đủ cho họ (PTN-06 có thẻ chỉ tiêu và liên kết tới báo cáo), không bắt họ đi tìm trong menu. Thứ hai, kiểm toán viên thấy nhiều nhóm ở mức "○" (chỉ đọc), nên mọi màn họ vào phải hiển thị đúng ở chế độ chỉ đọc: nút ghi bị ẩn, tab Lịch sử luôn có.

### 2.14. Kiến trúc thông tin của `dh-portal`

`dh-portal` có cấu trúc phẳng hơn, điều hướng bằng thanh trên ngang thay cho sidebar, vì số mục ít và người dùng đến từ công cụ tìm kiếm hoặc liên kết trực tiếp tới tài liệu một API. Bảng dưới liệt kê các khu vực của cổng.

| Khu vực | Route | Đăng nhập | Mẫu | Mô tả |
|---|---|---|---|---|
| Trang chủ | `/` | Không bắt buộc | PTN-14 (biến thể trang chào) | Giới thiệu, ô tìm API lớn, nhóm API nổi bật, hướng dẫn bắt đầu |
| Danh mục API | `/api` | Không bắt buộc (theo cấu hình tenant) | PTN-01 (biến thể thẻ) | Lọc theo lĩnh vực, cơ quan cung cấp, kiểu xác thực; hiển thị dạng lưới thẻ hoặc bảng |
| Tài liệu một API | `/api/{ma-api}/{phien-ban}` | Không bắt buộc | PTN-14 | Mục lục, nội dung, khung thử API |
| Hướng dẫn | `/huong-dan/{bai}` | Không bắt buộc | PTN-14 | Bài hướng dẫn: xác thực, mã lỗi, giới hạn, sự kiện |
| Ứng dụng của tôi | `/ung-dung` | Bắt buộc | PTN-01, PTN-02 | Ứng dụng của nhà phát triển, đăng ký sử dụng API, trạng thái duyệt |
| Thông tin xác thực | `/ung-dung/{ma}/xac-thuc` | Bắt buộc | PTN-02 (tab) | Client ID, xoay vòng bí mật; bí mật chỉ hiện một lần bằng `CMP-SecretField` |
| Sandbox | `/sandbox` | Bắt buộc | PTN-11 (biến thể) | Lịch sử lượt gọi thử, dữ liệu giả lập |
| Tài khoản | `/tai-khoan` | Bắt buộc | PTN-12 | Thông tin cá nhân, giao diện, thông báo |

Thanh trên của cổng gồm logo và tên cổng của tỉnh, các liên kết "API", "Hướng dẫn", "Ứng dụng của tôi", ô tìm kiếm (cũng mở bằng `Ctrl+K`, chỉ có nhóm "API" và "Bài hướng dẫn"), chọn ngôn ngữ và nút đăng nhập hoặc menu tài khoản. Dưới `bp-md`, các liên kết gộp vào nút menu mở `CMP-Drawer`.

## 3. Khung bố cục

### 3.1. Giải phẫu `CMP-AppShell`

`CMP-AppShell` là khung chứa mọi màn hình của `dh-console`. Nó gồm năm lớp xếp chồng từ dưới lên theo trục z: canvas, sidebar, topbar, vùng nội dung và các lớp phủ. Thứ tự này đồng thời là thứ tự vật liệu: canvas là nền trang trí, sidebar và topbar là kính trên canvas, vùng nội dung chứa các khối nền đặc, lớp phủ là kính nổi trên tất cả. Bảng dưới đây mô tả từng lớp, vật liệu và token kích thước.

| Lớp | Thành phần | Vật liệu | Token chính | Lớp chồng |
|---|---|---|---|---|
| Canvas | Nền `body` | `color-canvas` cộng lớp phủ `color-canvas-wash` cố định theo viewport | | `z-base` |
| Sidebar | `CMP-Sidebar` | `glass-chrome` | `size-sidebar`, `size-sidebar-collapsed`, `radius-xl`, `shadow-2`, `space-2` (khoảng cách mép) | `z-sidebar` |
| Thanh trên | `CMP-Topbar` | `glass-chrome` khi nội dung chưa cuộn dưới nó; `glass-chrome-scrolled` cộng `glass-scroll-edge` khi nội dung cuộn dưới | `size-topbar`, `shadow-2` khi cuộn | `z-topbar` |
| Vùng nội dung | `<main>` chứa `CMP-PageHeader` và các khối `CMP-Card`, `CMP-DataTable`, `CMP-Form` | Nền trong suốt để lộ canvas; mỗi khối nội dung là bề mặt đặc `color-surface-solid` với `radius-lg`, `shadow-1` | `size-page-max`, `space-6` (lề), `space-8` (khoảng giữa phần lớn) | `z-base`, tiêu đề bảng dính `z-sticky` |
| Lớp phủ | `CMP-Drawer`, `CMP-Modal`, `CMP-CommandPalette`, `CMP-Popover`, `CMP-DropdownMenu`, `CMP-Notification`, `CMP-Toast`, `CMP-Tooltip` | `glass-modal` (Drawer, Modal, CommandPalette), `glass-overlay` (Popover, Dropdown, Notification), nền đảo đặc `color-surface-inverse` (Toast, Tooltip) | `size-drawer-md`, `size-drawer-lg`, `size-modal-sm/md/lg`, `radius-xl`, `shadow-3`, `shadow-4`, `color-scrim` | `z-drawer`, `z-modal`, `z-popover`, `z-tooltip`, `z-toast`, `z-session-dialog` |

Quy tắc "không đặt kính chồng kính" chi phối trực tiếp khung này. Sidebar và topbar là hai bề mặt kính nằm cạnh nhau trên canvas chứ không chồng lên nhau; vùng nội dung không bao giờ được đặt bề mặt kính (một `CMP-Card` không được dùng `glass-chrome` để "trông đẹp hơn"). Khi một lớp phủ mở, nó nằm trên `color-scrim` che toàn bộ khung, nên kính của lớp phủ làm nhòe một nền đã bị che chứ không làm nhòe trực tiếp kính của sidebar; trường hợp ngoại lệ duy nhất là popover mở từ trong Modal, được phép vì `glass-overlay` có độ đục 0,94.

### 3.2. Sơ đồ vùng

Sơ đồ dưới đây vẽ khung ở độ rộng 1600px (mốc `bp-xxl`), mật độ Chuẩn, sidebar mở rộng. Số đo trong ngoặc là token; các số px là giá trị của token ở mật độ Chuẩn để dễ hình dung.

```text
┌──────────────────────────────────────────────────────────────────────────────────────────┐
│ canvas: color-canvas + color-canvas-wash (cố định theo viewport)                         │
│ ┌8px┐                                                                                    │
│  ┌────────────────────┐ ┌──────────────────────────────────────────────────────────────┐ │
│  │ SIDEBAR            │ │ TOPBAR  glass-chrome → glass-chrome-scrolled khi cuộn        │ │
│  │ glass-chrome       │ │ [≡] [Tỉnh Mẫu A ▾] [ Tìm…  Ctrl K ]  [AI][?][🔔3][Avatar▾] │ │
│  │ radius-xl, shadow-2│ │ cao size-topbar (56px)                                       │ │
│  │ rộng size-sidebar  │ ├──────────────────────────────────────────────────────────────┤ │
│  │ (256px)            │ │░░ glass-scroll-edge 16px (chỉ khi cuộn) ░░░░░░░░░░░░░░░░░░░░░│ │
│  │                    │ │ MAIN (nền trong suốt, lộ canvas), lề space-6 (24px)          │ │
│  │ [Logo Datahub]     │ │  ┌ CMP-PageHeader (trên canvas, không có nền) ─────────────┐ │ │
│  │                    │ │  │ Breadcrumb                                               │ │ │
│  │ ▸ Tổng quan        │ │  │ Tiêu đề trang (font-title-2)       [Phụ] [Hành động chính]│ │ │
│  │ ▸ Việc của tôi  12 │ │  └──────────────────────────────────────────────────────────┘ │ │
│  │ ▾ Kết nối & API    │ │       space-6                                                │ │
│  │    Hệ thống TV     │ │  ┌ Khối đặc color-surface-solid, radius-lg, shadow-1 ───────┐ │ │
│  │  ● Danh mục API    │ │  │ CMP-FilterBar                                            │ │ │
│  │    Gói sử dụng     │ │  │──────────────────────────────────────────────────────────│ │ │
│  │ ▸ Tích hợp         │ │  │ CMP-DataTable (tiêu đề dính z-sticky)                    │ │ │
│  │ ▸ Dữ liệu dùng chung│ │  │                                                         │ │ │
│  │ …                  │ │  │ CMP-Pagination                                           │ │ │
│  │                    │ │  └──────────────────────────────────────────────────────────┘ │ │
│  │ [« Thu gọn]        │ │  rộng tối đa size-page-max (1600px) với trang biểu mẫu/chi tiết│ │
│  └────────────────────┘ └──────────────────────────────────────────────────────────────┘ │
│ └8px┘ cao: 100vh − 2×8px                                                                 │
└──────────────────────────────────────────────────────────────────────────────────────────┘
```

Sơ đồ cho thấy sidebar là một tấm kính nổi cách mép trái, mép trên và mép dưới viewport một khoảng `space-2` (8px), bo góc `radius-xl`, cao bằng chiều cao viewport trừ hai lần khoảng cách mép. Thanh trên bắt đầu sau mép phải của sidebar cộng `space-2`, kéo tới mép phải viewport, dính ở đầu cột nội dung và không bo góc vì nó là một dải liền với cột. Vùng `main` nằm dưới thanh trên trong cùng cột và cuộn độc lập; khi cuộn, nội dung trượt bên dưới thanh trên, kích hoạt chuyển vật liệu. `CMP-PageHeader` nằm trực tiếp trên canvas (không có khối nền) để tạo nhịp thở giữa thanh trên và khối nội dung đầu tiên.

### 3.3. Quyết định: sidebar nổi cách mép

Có hai cách đặt sidebar kính: dính sát mép trái viewport, cao toàn màn, không bo góc (kiểu thanh bên truyền thống của antd `Layout.Sider`); hoặc nổi cách mép 8px, bo `radius-xl`, có bóng `shadow-2` (kiểu thanh bên của các ứng dụng Liquid Glass). Datahub **chọn sidebar nổi cách mép** vì bốn lý do.

1. **Kính cần thấy được nền để đọc ra là kính.** Một tấm kính dính sát mép chỉ có canvas phía sau ở một phía, mép ngoài trùng mép viewport nên mất viền phản quang (`glass-highlight-top`, `glass-edge`); nó trông như một cột màu xám nhạt phẳng. Khi nổi cách mép, dải canvas 8px với `color-canvas-wash` bao quanh tạo đường viền tự nhiên và người dùng nhận ra lớp điều hướng là một lớp riêng nằm trên nội dung, đúng tinh thần ADR-020.
2. **Phân tầng thị giác rõ.** Bóng `shadow-2` cùng góc bo tách sidebar khỏi vùng nội dung mà không cần đường kẻ phân cách, giảm số đường kẻ trên màn hình vốn đã nhiều bảng.
3. **Token đã chuẩn bị cho phương án này.** D03-05-02 định nghĩa `radius-xl` dùng cho "sidebar dạng nổi" và `shadow-2` cho "Sidebar nổi", nên phương án này không cần token mới.
4. **Đồng nhất với lớp phủ.** Drawer cũng bo `radius-xl` ở cạnh hở; sidebar thu thành Drawer ở dưới `bp-lg` (mục 3.4) giữ nguyên hình dạng, chuyển đổi không gây giật hình.

Cái giá của phương án nổi là mất 16px chiều rộng (8px mỗi bên của sidebar) và thêm một vùng canvas có thể bấm nhầm. Ở 1366px với sidebar thu gọn, mất 16px là chấp nhận được (vùng nội dung vẫn còn hơn 1270px). Vùng canvas quanh sidebar không có hành vi bấm. Ở chế độ glass "Tắt" (D03-05-01), sidebar vẫn nổi, bo góc, nền `color-surface-solid` và giữ `shadow-2`, để bố cục không thay đổi giữa các chế độ glass; chỉ vật liệu thay đổi.

### 3.4. Lưới, lề và hành vi responsive

Vùng nội dung dùng lưới 12 cột của antd (`Row`/`Col`) để các khối thẻ, biểu mẫu hai cột và lưới KPI căn thẳng hàng. Lưới không phải token riêng mà là quy ước bố cục dùng các token khoảng cách. Bảng dưới đây quy định lề, khoảng cách cột (gutter) và trạng thái sidebar theo điểm ngắt.

| Khoảng độ rộng viewport | Sidebar | Lề vùng nội dung | Gutter | Số cột hữu dụng | Ghi chú |
|---|---|---|---|---|---|
| ≥ `bp-xxl` (1600px) | Mở rộng `size-sidebar` | `space-6` | `space-6` | 12 | Bảng điều khiển hiển thị lưới 4 thẻ KPI một hàng; nội dung trang biểu mẫu/chi tiết giới hạn `size-page-max` và căn giữa |
| `bp-xl` … < `bp-xxl` (1200–1599px) | Mở rộng; ở 1200–1365px mặc định thu gọn `size-sidebar-collapsed` | `space-6` | `space-5` | 12 | 1366×768 là độ phân giải mục tiêu: sidebar mở rộng vẫn còn ≈ 1062px cho nội dung |
| `bp-lg` … < `bp-xl` (992–1199px) | Thu gọn `size-sidebar-collapsed` | `space-5` | `space-4` | 12 | Biểu mẫu hai cột vẫn giữ; lưới KPI 2 thẻ một hàng |
| `bp-md` … < `bp-lg` (768–991px) | Ẩn; mở bằng nút ≡ thành `CMP-Drawer` trái | `space-4` | `space-4` | 12 | Biểu mẫu chuyển một cột; bảng cuộn ngang với cột hành động dính phải |
| < `bp-md` (dưới 768px) | Như trên | `space-4` | `space-3` | 4 (gộp) | Chỉ đảm bảo đọc và thao tác cơ bản; PTN-07 hiển thị thông báo "Trình thiết kế cần màn hình rộng tối thiểu 992px" |

Có ba điểm cần giải thích. Thứ nhất, D02-02 §2.2 đặt màn hình tối thiểu 1280×720 cho màn quản trị, còn D03-05-02 §12.3 lấy 1366×768 làm độ phân giải mục tiêu thiết kế. Hai số không mâu thuẫn: thiết kế tối ưu cho 1366×768, và mọi màn vẫn phải dùng được đầy đủ (không mất chức năng, không cuộn ngang toàn trang) ở 1280×720 với sidebar thu gọn; kiểm thử viên chạy cả hai kích thước. Thứ hai, ở 1200–1365px sidebar mặc định thu gọn nhưng người dùng có thể mở rộng; lựa chọn được ghi nhớ theo người dùng. Khi sidebar thu gọn, mục cấp 1 chỉ còn biểu tượng (`size-icon-lg`) và rê chuột hoặc focus vào biểu tượng mở popover `glass-overlay` liệt kê mục cấp 2; popover này mở được bằng phím `Enter` hoặc `→`. Thứ ba, chiều cao 768px buộc khung tiết kiệm chiều dọc: thanh trên 56px (48px ở mật độ Gọn), không có thanh chân trang (footer) trong `dh-console`, và `CMP-PageHeader` một dòng tiêu đề.

Chiều rộng tối đa `size-page-max` chỉ áp dụng cho trang biểu mẫu (PTN-03), chi tiết (PTN-02) và cài đặt (PTN-12); trang danh sách (PTN-01), dashboard (PTN-06), designer (PTN-07) và tra log (PTN-11) dùng toàn bộ chiều rộng vì dữ liệu dạng bảng và biểu đồ hưởng lợi từ chiều ngang. Cột biểu mẫu đơn không vượt `size-form-max`.

### 3.5. Hành vi chuyển vật liệu của thanh trên

Thanh trên có hai trạng thái vật liệu. Khi `main` ở vị trí cuộn bằng 0, không có nội dung nào nằm dưới thanh trên, chỉ có canvas; thanh trên dùng `glass-chrome` và không có bóng. Khi `main` cuộn xuống quá 4px, nội dung bắt đầu trượt dưới thanh trên; thanh trên chuyển sang `glass-chrome-scrolled` (độ đục cao hơn, để chữ cấp hai và liên kết đạt tương phản dù dưới nó là bảng màu sặc sỡ), thêm `shadow-2` và một dải `glass-scroll-edge` cao 16px ngay dưới mép dưới, làm nội dung mờ dần khi trượt vào. Quá trình chuyển dùng `motion-duration-base` với `motion-ease-standard`; khi giảm chuyển động, chuyển tức thì.

Việc phát hiện cuộn dùng `IntersectionObserver` trên một phần tử mốc cao 1px đặt đầu `main`, không dùng sự kiện `scroll` để tránh tốn tài nguyên. Quy tắc chuyển vật liệu này là **bắt buộc**, không phải tùy chọn thẩm mỹ: `glass-chrome` không đạt tương phản chữ cấp hai trong trường hợp xấu nhất (D03-05-02 §5), nên để nguyên `glass-chrome` khi có nội dung bên dưới là lỗi truy cập.

### 3.6. Thanh "Bỏ qua tới nội dung", landmark và thứ tự focus

**Bỏ qua tới nội dung.** Phần tử focus được đầu tiên của trang là liên kết "Bỏ qua tới nội dung chính" (NFR-00-042). Liên kết ẩn khỏi màn hình bằng kỹ thuật ẩn trực quan (không dùng `display:none`) cho tới khi nhận focus, khi đó nó hiện ở góc trên trái, trên mọi lớp (`z-toast`), dạng nút nền `color-surface-inverse` chữ `color-text-on-inverse`, có vòng focus kép. Kích hoạt liên kết chuyển focus tới tiêu đề `h1` của trang trong `main` (có `tabindex="-1"`). Trang có bảng lớn (PTN-01, PTN-11) có thêm liên kết thứ hai "Bỏ qua tới bảng dữ liệu".

**Landmark ARIA.** Khung dùng landmark HTML5 để người dùng trình đọc màn hình nhảy nhanh giữa các vùng. Bảng sau quy định ánh xạ.

| Vùng | Phần tử / vai trò | Nhãn truy cập |
|---|---|---|
| Thanh trên | `<header role="banner">` | (không cần nhãn, chỉ có một banner) |
| Sidebar | `<nav aria-label="Điều hướng chính">` | "Điều hướng chính" |
| Breadcrumb | `<nav aria-label="Vị trí hiện tại">` | "Vị trí hiện tại" |
| Vùng nội dung | `<main id="noi-dung-chinh">` | (duy nhất) |
| Bảng bên Trợ lý AI, bảng Inspector của PTN-07 | `<aside role="complementary">` | "Trợ lý AI", "Thuộc tính nút" |
| Dải liên tenant, dải thông báo hệ thống | `<section role="region">` | "Cảnh báo truy cập liên tenant", "Thông báo hệ thống" |
| Vùng thông báo động | `<div aria-live>` (mục 3.7) | |

**Thứ tự focus.** Thứ tự focus theo thứ tự đọc thị giác: liên kết bỏ qua, dải cảnh báo (nếu có, chỉ các nút trong dải), thanh trên (nút ≡, chọn tenant, ô tìm kiếm, Trợ lý, Trợ giúp, Thông báo, Tài khoản), sidebar (các mục theo thứ tự hiển thị), rồi `main` (breadcrumb, tiêu đề, hành động trang, bộ lọc, bảng, phân trang). Không dùng `tabindex` dương. Trong sidebar, toàn bộ cây menu chỉ chiếm một điểm dừng `Tab`; di chuyển giữa các mục bằng phím mũi tên lên, xuống, `→` để mở nhóm, `←` để đóng nhóm (mẫu "tree view" của ARIA APG), giúp người dùng bàn phím không phải nhấn `Tab` hai mươi lần để vào nội dung. Khi đổi route, focus được chuyển tới `h1` của trang mới để trình đọc màn hình đọc tiêu đề.

### 3.7. Vùng thông báo động

Khung có hai vùng `aria-live` cố định, luôn tồn tại trong DOM từ khi tải trang (vùng live được thêm động thường không được trình đọc màn hình theo dõi). Vùng `polite` nhận các thông báo không khẩn: kết quả lưu thành công, số kết quả sau khi lọc ("Tìm thấy 128 kết quả"), tác vụ nền xong. Vùng `assertive` chỉ nhận thông báo cần ngắt ngang: lỗi lưu, mất kết nối, phiên sắp hết hạn. `CMP-Toast` và `CMP-Notification` không tự là vùng live mà đẩy nội dung văn bản vào hai vùng này qua một dịch vụ dùng chung, để tránh việc trình đọc đọc trùng hai lần. Thông báo lặp lại giống hệt trong vòng 2 giây được gộp.

### 3.8. Dải thông báo hệ thống và dải liên tenant

Phía trên thanh trên có thể xuất hiện tối đa hai dải ngang, xếp theo thứ tự cố định từ trên xuống: dải liên tenant (mục 2.11) rồi dải thông báo hệ thống. Khi có dải, toàn bộ khung (sidebar và cột nội dung) dịch xuống tương ứng; dải không phủ lên nội dung.

Dải thông báo hệ thống (`CMP-Banner`) do quản trị nền tảng hoặc quản trị tỉnh phát (ví dụ "Hệ thống bảo trì từ 22:00 đến 23:30 ngày 25/11/2026. Các luồng tích hợp vẫn hoạt động."). Dải có bốn mức theo sắc thái trạng thái (`color-info`, `color-warning`, `color-error`, `color-success` với cặp `-bg`/`-on-bg`), luôn có biểu tượng và chữ, cao tối thiểu 32px, nền đặc. Dải mức thông tin và thành công đóng được, lựa chọn đóng ghi nhớ theo mã thông báo; dải mức cảnh báo và lỗi chỉ thu gọn được về một dòng. Khi có nhiều thông báo hệ thống cùng lúc, chỉ hiển thị thông báo mức cao nhất kèm liên kết "và {n} thông báo khác" mở popover. Dải liên tenant luôn ưu tiên trên cùng và không bao giờ bị gộp.

### 3.9. Chế độ toàn màn hình

Hai loại màn cần tận dụng tối đa diện tích: designer (PTN-07) khi kỹ sư thiết kế luồng lớn, và dashboard trực ca (PTN-06) chiếu lên màn hình lớn ở phòng điều hành. Hai màn này có nút "Toàn màn hình" (biểu tượng `Maximize2` của Lucide) ở góc phải `CMP-PageHeader`, phím tắt `F` khi focus không ở trong ô nhập.

Ở chế độ toàn màn hình, khung ẩn sidebar và thanh trên, gọi Fullscreen API của trình duyệt, chỉ giữ lại một thanh công cụ nổi nhỏ vật liệu `glass-overlay` ở góc trên phải gồm tên màn, đồng hồ (với dashboard), nút "Thoát toàn màn hình" (phím `Esc`). Dải liên tenant và dải thông báo hệ thống mức lỗi **vẫn hiển thị** trong chế độ toàn màn hình vì là thông tin an toàn. Hộp thoại sắp hết phiên (`CMP-SessionTimeoutDialog`, `z-session-dialog`) vẫn hiển thị; riêng dashboard trực ca có thể được cấu hình một phiên kiosk chỉ đọc dài hạn theo chính sách PH-12, khi đó không có hộp thoại hết phiên.

### 3.10. Khung của `dh-portal`

Cổng nhà phát triển dùng khung khác: thanh trên ngang vật liệu `glass-chrome` (chuyển `glass-chrome-scrolled` khi cuộn như mục 3.5) cao `size-topbar`, rộng toàn màn hình, nội dung căn giữa giới hạn `size-page-max`. Không có sidebar ứng dụng; trang tài liệu có mục lục trái riêng là một phần của PTN-14. Cổng có chân trang trên canvas gồm liên kết điều khoản sử dụng, chính sách bảo vệ dữ liệu cá nhân, đầu mối hỗ trợ của tỉnh và phiên bản cổng. Chữ thân trong cổng dùng `font-callout` thay vì `font-body` để dễ đọc văn bản dài.

## 4. Mẫu màn hình chuẩn

### 4.1. Cách đọc một mẫu

Mỗi mẫu `PTN-{nn}` dưới đây được đặc tả theo cùng một khung: mục đích, khi dùng và khi không dùng, ví dụ màn thực tế trong Datahub, sơ đồ vùng, bảng thành phần và vật liệu theo vùng, hành vi, trạng thái, phím tắt, tiêu chí nghiệm thu và sai lầm thường gặp. Sơ đồ vùng chỉ vẽ phần `main` (vùng nội dung) vì sidebar và thanh trên đã được quy định ở mục 3 và giống nhau cho mọi mẫu của `dh-console`. Bảng dưới tóm tắt mười bốn mẫu để người thiết kế chọn nhanh.

| Mã | Tên | Câu hỏi chọn mẫu | Ví dụ điển hình |
|---|---|---|---|
| PTN-01 | Danh sách | Người dùng cần tìm, lọc, so sánh nhiều bản ghi cùng loại? | Danh sách API, danh sách giao dịch |
| PTN-02 | Chi tiết | Người dùng cần xem đầy đủ một đối tượng và thao tác trên nó? | Chi tiết API, chi tiết HTTT |
| PTN-03 | Biểu mẫu trang | Tạo/sửa đối tượng có trên 8 trường hoặc nhiều nhóm? | Tạo dịch vụ thu, sửa gói sử dụng |
| PTN-04 | Biểu mẫu nhanh | Tạo/sửa đối tượng nhỏ, tối đa khoảng 8 trường, không rời ngữ cảnh? | Thêm mục danh mục, thêm đầu mối kỹ thuật |
| PTN-05 | Wizard | Quy trình nhiều bước có thứ tự bắt buộc, bước sau phụ thuộc bước trước? | Kết nạp HTTT, đăng ký API từ OpenAPI |
| PTN-06 | Dashboard | Theo dõi chỉ số tổng hợp, xu hướng? | Tổng quan, bảng giám sát |
| PTN-07 | Designer | Tạo dựng cấu trúc dạng đồ thị bằng thao tác trực quan? | Thiết kế luồng, sơ đồ topic |
| PTN-08 | Cây + bảng | Dữ liệu phân cấp, chọn nút cha để xem con? | Cây danh mục, nhóm dịch vụ thu |
| PTN-09 | Nhập có xem trước | Nạp hàng loạt từ tệp? | Nhập danh mục Excel |
| PTN-10 | Hộp việc và duyệt | Xử lý hàng đợi yêu cầu chờ quyết định? | Hộp việc |
| PTN-11 | Giám sát thời gian thực / tra log | Khám phá khối lượng lớn sự kiện theo thời gian? | Tra log, truy vết, nhật ký kiểm toán |
| PTN-12 | Cài đặt | Cấu hình tham số theo nhóm, ít thay đổi? | Cài đặt cá nhân, tham số hệ thống |
| PTN-13 | Trang lỗi và trạng thái hệ thống | Không thể hiển thị nội dung bình thường? | 403, 404, bảo trì |
| PTN-14 | Tài liệu cổng nhà phát triển | Đọc tài liệu dài có cấu trúc và thử API? | Tài liệu API trên dh-portal |

### 4.2. Bảng trạng thái chuẩn dùng chung

Mọi mẫu có tải dữ liệu đều phải xử lý đầy đủ bộ trạng thái dưới đây, kế thừa và mở rộng mục 5 của `docs/ui_ux_rule.md`. Mỗi mẫu ở các mục sau chỉ ghi phần **cụ thể hóa** của mình (vị trí, nội dung); những gì không ghi được hiểu là theo bảng này. Mã trạng thái `ST-xx` là mã cục bộ của tài liệu này, dùng để kiểm thử viên tham chiếu.

| Mã | Trạng thái | Điều kiện | Hiển thị chuẩn | Thành phần |
|---|---|---|---|---|
| ST-01 | Đang tải lần đầu | Chưa có dữ liệu trong bộ nhớ đệm | Skeleton đúng hình dạng nội dung sẽ hiện (hàng bảng, thẻ, khối mô tả) tại chỗ vùng dữ liệu; tiêu đề trang và hành động chính hiện ngay; không dùng vòng xoay toàn trang. Skeleton chỉ hiện sau 200ms để tránh nháy khi máy chủ trả nhanh | `CMP-Skeleton` |
| ST-02 | Đang tải lại | Đã có dữ liệu cũ, đang lấy dữ liệu mới (đổi trang, lọc, làm mới) | Giữ dữ liệu cũ hiển thị, thêm thanh tiến độ mảnh 2px ở mép trên khối dữ liệu và đặt `aria-busy="true"`; không xóa trắng bảng | `CMP-ProgressBar` (không xác định) |
| ST-03 | Rỗng (chưa có dữ liệu) | Truy vấn không điều kiện trả 0 bản ghi | Minh họa đơn sắc, tiêu đề nói rõ chưa có gì, một câu giải thích đối tượng này dùng để làm gì, nút hành động chính (nếu có quyền) và liên kết HDSD | `CMP-EmptyState` |
| ST-04 | Không có kết quả | Có điều kiện lọc/tìm, trả 0 bản ghi | "Không tìm thấy {đối tượng} phù hợp" kèm điều kiện đang áp dụng và nút "Xóa bộ lọc"; không hiện nút Thêm mới như hành động chính | `CMP-EmptyState` (biến thể tìm kiếm) |
| ST-05 | Lỗi tải | Máy chủ trả 5xx, hết thời gian chờ | Tại vùng dữ liệu: biểu tượng lỗi, thông điệp theo FR-00-080, mã lỗi và mã truy vết có nút sao chép, nút "Thử lại". Các vùng khác của trang vẫn dùng được | `CMP-Alert` hoặc `CMP-ResultPage` (khi lỗi toàn trang), `CMP-CopyButton` |
| ST-06 | Mất kết nối | Trình duyệt `offline` hoặc yêu cầu mạng thất bại không có phản hồi | `CMP-Banner` mức cảnh báo ngay dưới thanh trên "Mất kết nối tới máy chủ. Đang thử kết nối lại…"; dữ liệu đã tải vẫn hiển thị, thao tác ghi bị vô hiệu; tự thử lại theo lũy thừa (2, 4, 8, 16, tối đa 30 giây); khi có lại kết nối, dải chuyển "Đã kết nối lại" 3 giây rồi tự ẩn và dữ liệu được làm mới | `CMP-Banner` |
| ST-07 | Không có quyền (403) | API trả 403 cho truy vấn chính của trang | PTN-13 biến thể 403 trong khung ứng dụng | `CMP-ResultPage` |
| ST-08 | Đối tượng không tồn tại hoặc đã bị xóa (404/410) | Mở chi tiết bằng URL cũ, hoặc đối tượng bị xóa khi đang xem | PTN-13 biến thể "Không tìm thấy" với tên loại đối tượng và mã đã tìm; nếu đối tượng bị xóa mềm và người dùng có quyền khôi phục thì có nút "Xem trong thùng rác" (FR-00-051); nút "Về danh sách {đối tượng}" giữ bộ lọc gần nhất | `CMP-ResultPage` |
| ST-09 | Đang lưu | Đã gửi yêu cầu ghi, chưa có phản hồi | Nút gửi chuyển trạng thái `loading` (vòng xoay trong nút, nhãn giữ nguyên), vô hiệu mọi nút gửi khác để không gửi trùng; biểu mẫu không bị khóa đọc; sau 3 giây chưa xong thì chuyển thành tác vụ nền (FR-00-054) | `CMP-Button` (loading), `CMP-JobProgress` |
| ST-10 | Lưu thành công | Phản hồi 2xx | `CMP-Toast` "Đã lưu {đối tượng} {tên}." 4 giây, có nút "Xem" nếu thao tác tạo mới; điều hướng theo quy tắc của mẫu | `CMP-Toast` |
| ST-11 | Lỗi kiểm tra hợp lệ | 400/422 với danh sách lỗi theo trường | Lỗi tại từng trường (FR-00-081), `CMP-Alert` tóm tắt đầu biểu mẫu liệt kê số lỗi có liên kết nhảy tới trường; focus chuyển tới trường lỗi đầu tiên | `CMP-FormField`, `CMP-Alert` |
| ST-12 | Lỗi nghiệp vụ | 409/422 với mã `ERR-{PH}-{nnn}` | `CMP-Alert` mức lỗi trong ngữ cảnh thao tác (đầu biểu mẫu hoặc trong hộp thoại), thông điệp nghiệp vụ dễ hiểu, mã lỗi ở dòng phụ | `CMP-Alert` |
| ST-13 | Xung đột phiên bản | 412 do `If-Match` không khớp (FR-00-052) | `CMP-Modal` "Đối tượng đã được {người} cập nhật lúc {giờ}" với `CMP-DiffViewer` so sánh bản của bạn và bản mới nhất; ba lựa chọn "Tải bản mới nhất" (mặc định), "Ghi đè" (cần quyền, màu cảnh báo, hỏi xác nhận), "Hủy" để tự sao chép dữ liệu | `CMP-Modal`, `CMP-DiffViewer` |
| ST-14 | Hết phiên | Không thao tác quá ngưỡng (FR-00-003) | `CMP-SessionTimeoutDialog` 2 phút trước; khi hết, biểu mẫu chưa lưu được giữ bản nháp cục bộ (không gồm trường bí mật) để khôi phục sau đăng nhập | `CMP-SessionTimeoutDialog` |
| ST-15 | Chỉ đọc | Người dùng có quyền xem nhưng không có quyền sửa, hoặc chế độ liên tenant | Nút ghi ẩn hoặc vô hiệu theo mục 2.6; biểu mẫu hiển thị dạng mô tả | |

Thời gian chờ mặc định của một yêu cầu đọc từ giao diện là 15 giây, của yêu cầu ghi là 30 giây; vượt thời gian chờ được xử lý như ST-05. TanStack Query được cấu hình thử lại tự động tối đa 2 lần cho yêu cầu đọc lỗi mạng hoặc 5xx (không thử lại 4xx), và không bao giờ tự thử lại yêu cầu ghi trừ khi API có khóa idempotency.

### 4.3. Hành vi dùng chung

Bốn hành vi dưới đây xuất hiện ở nhiều mẫu nên được quy định một lần.

**Giữ bộ lọc khi quay lại.** Khi người dùng rời một danh sách (mở chi tiết, mở biểu mẫu) rồi quay lại bằng breadcrumb, nút Quay lại của trình duyệt, nút "Quay lại" trong trang hoặc mục menu, danh sách hiển thị đúng bộ lọc, sắp xếp, trang và vị trí cuộn trước đó. Với nút Quay lại của trình duyệt, điều này có sẵn vì trạng thái nằm trên URL. Với breadcrumb và mục menu, khung lưu URL gần nhất của mỗi danh sách trong `sessionStorage` theo khóa route và tenant; bấm mục menu khi đang ở chính danh sách đó thì xóa bộ lọc về mặc định (hành vi "về đầu").

**Cảnh báo rời trang khi chưa lưu.** Mọi biểu mẫu (PTN-03, PTN-04, PTN-05, PTN-07, PTN-12) theo dõi trạng thái "đã thay đổi" (dirty) so với giá trị ban đầu. Khi người dùng điều hướng trong ứng dụng, đóng Drawer/Modal hoặc đổi tenant trong lúc biểu mẫu dirty, giao diện mở `CMP-ConfirmDialog` "Bạn có thay đổi chưa lưu" với ba nút "Ở lại" (mặc định, focus đầu), "Bỏ thay đổi" (màu cảnh báo) và, khi biểu mẫu hợp lệ, "Lưu và rời đi". Khi đóng tab hoặc tải lại trang, dùng sự kiện `beforeunload` của trình duyệt (trình duyệt tự hiển thị hộp thoại của nó). Biểu mẫu không dirty thì không hỏi.

**Chống gửi trùng.** Mọi nút gửi bị vô hiệu ngay khi bấm cho tới khi có phản hồi (ST-09). Mọi thao tác tạo mới và thao tác nghiệp vụ gửi kèm tiêu đề `Idempotency-Key` sinh ở trình duyệt khi mở biểu mẫu, để nếu người dùng bấm lại sau lỗi mạng thì máy chủ không tạo hai bản ghi (kế thừa CRUD-ACT-04, 05).

**Xung đột ETag.** Mọi màn sửa lấy `ETag` khi tải đối tượng và gửi `If-Match` khi lưu. Phản hồi 412 dẫn tới ST-13. Thao tác trên hàng của danh sách (đổi trạng thái) cũng gửi `If-Match` theo phiên bản đối tượng mà danh sách đang hiển thị.

### 4.4. PTN-01 · Danh sách

**Mục đích.** Cho người dùng tìm, lọc, sắp xếp, so sánh nhiều bản ghi cùng loại và đi tới từng bản ghi. Đây là mẫu phổ biến nhất của Datahub, chiếm khoảng một nửa số màn hình.

**Khi dùng.** Tập đối tượng phẳng (không phân cấp) có thể lớn tới hàng triệu bản ghi (NFR-00-003). **Khi không dùng.** Dữ liệu phân cấp (dùng PTN-08); luồng sự kiện theo thời gian cần khám phá tự do (PTN-11); hàng đợi cần quyết định (PTN-10).

**Ví dụ trong Datahub.** Danh sách API (PH-02, `/ket-noi/api`), danh sách giao dịch thanh toán (PH-19, `/thanh-toan/giao-dich`), danh sách HTTT thành viên (PH-01), danh sách luồng (PH-04), danh sách người dùng (PH-12), hàng đợi lỗi DLQ (PH-18).

**Sơ đồ vùng.**

```text
┌ main ─────────────────────────────────────────────────────────────────────────┐
│ ① PageHeader (trên canvas)                                                    │
│   Breadcrumb                                                                  │
│   Tiêu đề "Danh mục API" (font-title-2)  [Xuất ▾] [Nhập] [+ Thêm API]        │
│   Mô tả ngắn một dòng (tùy chọn, color-text-secondary)                        │
│ ② (tùy chọn) Dải thẻ tóm tắt: 4 × CMP-KpiCard nhỏ hoặc CMP-SegmentedControl  │
│   lọc nhanh theo trạng thái "Tất cả 1.204 | Phát hành 980 | Chờ duyệt 12 …"  │
│ ┌ ③ Khối dữ liệu (color-surface-solid, radius-lg, shadow-1) ────────────────┐│
│ │ FilterBar: [🔍 Tìm theo tên, mã…] [Trạng thái ▾] [Lĩnh vực ▾] [+ Bộ lọc] ││
│ │            [Bộ lọc đã lưu ▾]                    [Xóa bộ lọc] [⚙ Cột] [⟳] ││
│ │ Chip điều kiện đang áp dụng: (Trạng thái: Phát hành ×) (Lĩnh vực: Tư pháp ×)│
│ │──────────────────────────────────────────────────────────────────────────── ││
│ │ ④ BulkActionBar (chỉ khi chọn ≥1): "Đã chọn 3" [Tạm dừng] [Xuất] [Bỏ chọn]││
│ │ ⑤ DataTable                                                               ││
│ │ [☐] Mã ↕ │ Tên ↕         │ Trạng thái │ Cơ quan    │ Cập nhật ↓  │ ⋯     ││
│ │ [☐] …    │ …             │ ●Phát hành │ …          │ 21/11/2026  │ ⋯     ││
│ │──────────────────────────────────────────────────────────────────────────── ││
│ │ ⑥ Pagination: "1–20 trong 1.204" [10|20|50|100] ‹ 1 2 3 … 61 › Tới trang[ ]││
│ └──────────────────────────────────────────────────────────────────────────── ┘│
└───────────────────────────────────────────────────────────────────────────────┘
```

Sơ đồ cho thấy toàn bộ bộ lọc, bảng và phân trang nằm trong **một** khối đặc duy nhất, để người dùng hiểu chúng là một khối thao tác liên kết; PageHeader nằm ngoài khối, trên canvas. Vùng ② là tùy chọn và chỉ dùng khi số lượng theo trạng thái là thông tin có giá trị (ví dụ số API chờ duyệt).

**Thành phần và vật liệu theo vùng.**

| Vùng | Thành phần | Vật liệu | Ghi chú |
|---|---|---|---|
| ① | `CMP-PageHeader`, `CMP-Breadcrumb`, `CMP-Button` (primary cho hành động chính, default cho phụ), `CMP-DropdownMenu` (Xuất) | Trên canvas, không nền | Tối đa một nút primary; tối đa ba nút hiển thị, còn lại vào menu "Thêm" |
| ② | `CMP-KpiCard` hoặc `CMP-SegmentedControl` | Khối đặc | Bấm thẻ áp bộ lọc tương ứng |
| ③ | `CMP-FilterBar`, `CMP-SearchField`, `CMP-Select`, `CMP-DateRangePicker`, `CMP-Tag` (chip điều kiện) | Đặc | Popup của Select, DatePicker là `glass-overlay` |
| ④ | `CMP-BulkActionBar` | Đặc, dính `z-sticky` đầu bảng | Thay chỗ hàng tiêu đề bảng, không đẩy nội dung |
| ⑤ | `CMP-DataTable` (ProTable), `CMP-StatusTag`, `CMP-Identifier`, `CMP-Timestamp`, `CMP-Money`, `CMP-DropdownMenu` (⋯) | Đặc; tiêu đề cột `color-surface-solid-2` dính `z-sticky` | Hàng chọn `color-fill-selected` |
| ⑥ | `CMP-Pagination` | Đặc | |
| Chi tiết nhanh | `CMP-Drawer` `size-drawer-md` | `glass-modal`, nội dung trong giếng đặc | Tùy chọn: xem nhanh không rời danh sách, query `chon` |

**Hành vi.**

1. *Tải.* Truy vấn danh sách gửi đầy đủ điều kiện từ URL lên máy chủ; phân trang, lọc, sắp xếp luôn ở máy chủ (FR-00-021, CRUD-FLT-08). Mặc định sắp xếp "Cập nhật gần nhất giảm dần" trừ khi FRS quy định khác.
2. *Tìm kiếm.* Ô tìm kiếm áp dụng sau 400ms ngừng gõ hoặc khi nhấn `Enter` (CRUD-FLT-03), tìm không phân biệt hoa thường và dấu (FR-00-020). Placeholder nêu rõ tìm theo trường nào ("Tìm theo tên hoặc mã API").
3. *Lọc.* Bộ lọc cơ bản (tối đa bốn) luôn hiện; bộ lọc nâng cao mở bằng "+ Bộ lọc" trong `CMP-Popover`. Mỗi thay đổi bộ lọc đưa trang về 1 (CRUD-FLT-06) và xóa lựa chọn hàng. Điều kiện đang áp dụng hiện thành chip có nút xóa từng chip. "Xóa bộ lọc" chỉ hiện khi có điều kiện. Lưu bộ lọc thường dùng (FR-00-024) qua "Bộ lọc đã lưu ▾ › Lưu bộ lọc hiện tại".
4. *Sắp xếp.* Bấm tiêu đề cột sắp xếp được xoay vòng tăng → giảm → mặc định; tiêu đề có `aria-sort`. Một tiêu chí chính tại một thời điểm (CRUD-TBL-05).
5. *Cột.* Nút "Cột" cho ẩn/hiện và đổi thứ tự cột (kéo thả có phương án bàn phím: nút lên/xuống ở mỗi dòng, WCAG 2.5.7); lựa chọn ghi nhớ theo người dùng. Cột mã và cột hành động không ẩn được.
6. *Bảng.* Tên hoặc mã đối tượng ở cột đầu là liên kết mở chi tiết (CRUD-R-02); cả hàng không phải là vùng bấm để tránh mở nhầm khi bôi chọn chữ. Chữ dài cắt bằng "…" với tooltip (CRUD-TBL-07). Trường trống hiển thị "—" (CRUD-R-05). Số và tiền căn phải, dùng `font-feature-tabular`. Trạng thái dùng `CMP-StatusTag` có chữ (CRUD-TBL-09, FR-00-053). Bảng có cuộn ngang thì cột hành động dính phải (CRUD-TBL-11).
7. *Hành động trên hàng.* Tối đa hai hành động hiện thành `CMP-IconButton` có tooltip; còn lại trong menu "⋯". Chỉ hiện hành động hợp lệ với trạng thái của hàng (mục 2.6).
8. *Chọn và hàng loạt.* Checkbox tiêu đề ba trạng thái (CRUD-SEL-02); lựa chọn giữ khi đổi trang, xóa khi đổi bộ lọc. Thao tác hàng loạt trả kết quả theo từng bản ghi; thành công một phần hiển thị `CMP-Modal` liệt kê bản ghi thất bại và lý do (CRUD-SEL-08, CRUD-D-09).
9. *Xóa.* Xác nhận bằng `CMP-ConfirmDialog` nêu tên bản ghi (CRUD-D-02); sau xóa, tải lại trang hiện tại giữ bộ lọc; nếu trang trống thì lùi một trang (CRUD-D-07, 08).
10. *Xuất.* Xuất theo bộ lọc hiện tại (FR-00-030); trên 10.000 dòng chạy nền và báo qua trung tâm thông báo (FR-00-031); hộp thoại xuất nêu rõ số dòng sẽ xuất và trường nhạy cảm bị che (FR-00-034).
11. *Làm mới.* Nút "⟳" làm mới thủ công; danh sách không tự làm mới định kỳ trừ khi FRS yêu cầu (ví dụ DLQ làm mới 30 giây), khi đó có công tắc "Tự làm mới" và thời điểm cập nhật cuối.
12. *Phân trang.* "1–20 trong 1.204", chọn cỡ trang, ô "Tới trang" chỉ nhận 1…tổng số trang (CRUD-PAG-01…07). Với tập rất lớn mà đếm tổng tốn kém (log, giao dịch nhiều triệu), API được phép trả tổng ước lượng; khi đó hiển thị "1–20 trong khoảng 1,2 triệu" và ẩn ô "Tới trang".

**Trạng thái cụ thể.** ST-01: 8 hàng skeleton cao `size-table-row`. ST-03: trong khối dữ liệu, ẩn FilterBar, hiện `CMP-EmptyState` với nút hành động chính và nút "Nhập từ tệp" nếu có. ST-04: bảng giữ hàng tiêu đề, thân bảng hiện EmptyState biến thể tìm kiếm. ST-05: thân bảng hiện Alert lỗi có "Thử lại", FilterBar vẫn dùng được.

**Phím tắt.** `/` focus ô tìm kiếm; `N` mở tạo mới (khi có quyền); `J`/`K` di chuyển hàng đang focus; `Enter` mở chi tiết hàng đang focus; `X` chọn/bỏ chọn hàng; `Shift+X` chọn tất cả trên trang; `Esc` bỏ chọn.

**Tiêu chí nghiệm thu PTN-01.**

- [ ] Mọi điều kiện lọc, từ khóa, sắp xếp, trang, cỡ trang đều xuất hiện trên URL; mở URL đó ở tab mới cho cùng kết quả.
- [ ] Gõ "da nang" tìm ra bản ghi chứa "Đà Nẵng".
- [ ] Đổi bộ lọc đưa về trang 1 và xóa lựa chọn hàng.
- [ ] Mở chi tiết rồi bấm breadcrumb quay lại: bộ lọc, trang, vị trí cuộn được khôi phục.
- [ ] Tổng bản ghi, cỡ trang, tổng số trang luôn khớp `ceil(tổng / cỡ)`.
- [ ] ST-01, ST-03, ST-04, ST-05 hiển thị đúng khi giả lập API tương ứng.
- [ ] Cột hành động dính phải khi cuộn ngang ở 1280px.
- [ ] Hành động trên hàng chỉ hiện khi đủ quyền và hợp lệ với trạng thái.
- [ ] Xóa bản ghi cuối của trang 3 tự lùi về trang 2.
- [ ] Bảng 1 triệu bản ghi phản hồi p95 ≤ 1,5 giây (NFR-00-003).
- [ ] Toàn bộ thao tác thực hiện được chỉ bằng bàn phím; axe-core 0 lỗi.

**Sai lầm thường gặp.** Lọc phía trình duyệt trên dữ liệu đã tải; để cả hàng là vùng bấm; dùng màu không chữ cho trạng thái; đặt nhiều nút primary; đánh số thứ tự bắt đầu lại từ 1 ở mỗi trang; quên xóa lựa chọn khi đổi bộ lọc; đặt bộ lọc ra ngoài khối dữ liệu thành một thẻ riêng; để bảng trắng khi lỗi.

### 4.5. PTN-02 · Chi tiết

**Mục đích.** Hiển thị đầy đủ một đối tượng nghiệp vụ, trạng thái vòng đời, quan hệ với đối tượng khác, lịch sử thay đổi, và là nơi thực hiện các thao tác trên đối tượng.

**Khi dùng.** Mọi đối tượng có mã, có vòng đời hoặc có quan hệ. **Khi không dùng.** Đối tượng quá nhỏ chỉ vài trường (dùng Drawer xem nhanh từ PTN-01).

**Ví dụ trong Datahub.** Chi tiết API (PH-02, `/ket-noi/api/{ma-api}` với tab Tổng quan, Phiên bản, Gói sử dụng, Đăng ký, Thống kê, Lịch sử); chi tiết HTTT thành viên (PH-01, tab Hồ sơ, Ứng dụng và thông tin xác thực, Đầu mối, API đang dùng, Lịch sử); chi tiết giao dịch (PH-19); chi tiết danh mục (PH-07, tab Mục, Thuộc tính, Phiên bản, Lịch sử).

**Sơ đồ vùng.**

```text
┌ main (giới hạn size-page-max) ────────────────────────────────────────────────┐
│ ① PageHeader                                                                  │
│   Breadcrumb: Kết nối & API › Danh mục API › Tra cứu hộ tịch                  │
│   [‹] Tra cứu hộ tịch  ●Phát hành  v2.1      [Sửa] [Ngừng khuyến nghị] [⋯]   │
│   Mã: API_HOTICH_TRACUU [⧉] · Cơ quan: Sở Tư pháp · Cập nhật 21/11/2026 14:05│
│ ② Tabs: Tổng quan | Phiên bản (3) | Gói sử dụng | Đăng ký (12) | Lịch sử     │
│ ┌ ③ Nội dung tab ───────────────────────────────────────┐ ┌ ④ Cột phụ ──────┐│
│ │ Khối đặc "Thông tin chung" (DescriptionList 2 cột)     │ │ Khối đặc         ││
│ │                                                        │ │ "Trạng thái &    ││
│ │ Khối đặc "Cấu hình"                                    │ │  vòng đời"       ││
│ │                                                        │ │ (Steps/Timeline) ││
│ │ Khối đặc "Đối tượng liên quan" (DataTable gọn)         │ │ Khối "Thông tin  ││
│ │                                                        │ │  hệ thống"       ││
│ └────────────────────────────────────────────────────────┘ └──────────────────┘│
└───────────────────────────────────────────────────────────────────────────────┘
```

Sơ đồ có hai cột ở tab Tổng quan: cột chính 8/12 chứa các khối thông tin, cột phụ 4/12 chứa trạng thái vòng đời và thông tin hệ thống (người tạo, ngày tạo, người cập nhật, ngày cập nhật theo CRUD-R-03, R-04). Dưới `bp-xl`, cột phụ chuyển xuống dưới cột chính. Các tab khác dùng toàn chiều rộng.

**Thành phần và vật liệu theo vùng.**

| Vùng | Thành phần | Vật liệu |
|---|---|---|
| ① | `CMP-PageHeader`, `CMP-StatusTag`, `CMP-Identifier`, `CMP-CopyButton`, `CMP-Button`, `CMP-DropdownMenu` | Trên canvas |
| ② | `CMP-Tabs` | Trên canvas; thanh tab dính dưới thanh trên khi cuộn (`z-sticky`), lúc dính có nền `color-canvas` |
| ③ | `CMP-Card`, `CMP-DescriptionList`, `CMP-DataTable`, `CMP-CodeEditor` (chỉ đọc), `CMP-JsonViewer`, `CMP-MaskedValue` | Đặc |
| ④ | `CMP-Card`, `CMP-Steps` hoặc `CMP-Timeline`, `CMP-ApprovalPanel` (khi đối tượng đang chờ duyệt) | Đặc |
| Tab Lịch sử | `CMP-AuditTrail`, `CMP-DiffViewer` | Đặc |

**Tab Lịch sử (bắt buộc, FR-00-043).** Mọi trang chi tiết đối tượng phải có tab "Lịch sử" ở vị trí cuối cùng, hiển thị nhật ký kiểm toán của chính đối tượng đó từ PH-13. Tab dùng `CMP-AuditTrail`: dòng thời gian theo thứ tự mới nhất trên cùng, mỗi mục gồm thời điểm, chủ thể (người hoặc máy, kèm đơn vị), hành động (Tạo, Sửa, Đổi trạng thái, Duyệt, Từ chối, Xem dữ liệu nhạy cảm, Xuất), lý do nếu có, kết quả và mã truy vết. Mục "Sửa" mở rộng được để xem `CMP-DiffViewer` giá trị trước và sau (đã che theo FR-00-041). Tab có bộ lọc theo loại hành động, chủ thể và khoảng thời gian, phân trang máy chủ, và có liên kết "Mở trong Nhật ký kiểm toán" tới PTN-11 với bộ lọc đối tượng điền sẵn. Tab Lịch sử là chỉ đọc tuyệt đối, không có hành động sửa hay xóa (FR-00-042). Route `/{ma}/lich-su` mở thẳng tab này.

**Hành vi.**

1. Tiêu đề trang là tên đối tượng; mã nghiệp vụ hiện ở dòng phụ kèm nút sao chép.
2. Hành động trên đối tượng đặt ở góc phải PageHeader, theo thứ tự: hành động chính của trạng thái hiện tại (primary, ví dụ "Gửi duyệt" khi Nháp, "Phát hành" khi đã duyệt), "Sửa", rồi menu "⋯" chứa hành động ít dùng và hành động phá hủy (cuối menu, chữ màu lỗi, ngăn cách bằng đường kẻ). Chỉ hiện hành động hợp lệ (FR-00-053).
3. Thao tác ảnh hưởng vận hành (tạm dừng, thu hồi, ngừng) mở `CMP-ReasonDialog` bắt buộc lý do (FR-00-050); thao tác phá hủy mở `CMP-ConfirmDialog`.
4. Tab được giữ trên URL (mục 2.4); dữ liệu từng tab tải lười khi mở tab lần đầu, có số đếm trên nhãn tab nếu rẻ để tính.
5. Đối tượng đang chờ duyệt hiển thị `CMP-Alert` mức thông tin dưới PageHeader "Đối tượng đang chờ {người/nhóm} duyệt từ {thời điểm}" và nếu người xem là người duyệt thì hiện `CMP-ApprovalPanel` ở cột phụ.
6. Trường mức Nhạy cảm hiện bằng `CMP-MaskedValue`; "Hiện" cần lý do và được kiểm toán.
7. Khi đối tượng bị người khác thay đổi trong lúc đang xem (nhận qua kênh đẩy nếu có), hiện `CMP-Alert` "Đối tượng vừa được cập nhật" với nút "Tải lại"; không tự thay dữ liệu dưới mắt người dùng.
8. Nút "‹" quay lại chỉ hiện khi có màn cha xác định (CRUD-UI-04) và về danh sách với bộ lọc đã giữ.

**Trạng thái cụ thể.** ST-01: skeleton PageHeader (tiêu đề, nhãn trạng thái) và hai khối DescriptionList. ST-08: đối tượng bị xóa khi đang xem dẫn tới thay nội dung bằng PTN-13 "Không tìm thấy", giữ breadcrumb. Tab không có dữ liệu (ví dụ chưa có đăng ký) dùng `CMP-EmptyState` cỡ nhỏ trong tab.

**Phím tắt.** `E` sửa (khi có quyền); `[`/`]` chuyển tab trước/sau; `H` mở tab Lịch sử; `Alt+←` quay lại danh sách.

**Tiêu chí nghiệm thu PTN-02.**

- [ ] Có tab "Lịch sử" ở cuối, hiển thị đúng bản ghi kiểm toán của đối tượng, không có hành động sửa/xóa.
- [ ] Mở `/{ma}/lich-su` hiển thị đúng tab Lịch sử.
- [ ] Hiển thị đủ người tạo, ngày tạo, người cập nhật, ngày cập nhật; trường trống hiện "—".
- [ ] Ở mỗi trạng thái vòng đời, chỉ các hành động hợp lệ được hiện.
- [ ] Thao tác tạm dừng/thu hồi bắt buộc lý do; lý do xuất hiện trong tab Lịch sử.
- [ ] Mở URL đối tượng không tồn tại hiển thị PTN-13 "Không tìm thấy" kèm mã đã tìm.
- [ ] "Hiện" trường nhạy cảm sinh bản ghi kiểm toán loại "Xem dữ liệu nhạy cảm".
- [ ] Ở 1280px, cột phụ không bị cắt; dưới `bp-xl` chuyển xuống dưới.

**Sai lầm thường gặp.** Thiếu tab Lịch sử hoặc đặt lịch sử thành một danh sách ở cuối trang; hiện mọi nút rồi báo lỗi khi bấm; dùng một khối thẻ duy nhất dài cả trang; đặt mã nghiệp vụ không có nút sao chép; dùng id nội bộ trên URL.

### 4.6. PTN-03 · Biểu mẫu trang

**Mục đích.** Tạo mới hoặc sửa một đối tượng có nhiều trường, chia nhóm, cần không gian và sự tập trung của cả một trang.

**Khi dùng.** Trên khoảng 8 trường, có nhóm trường phụ thuộc nhau, có trình soạn mã hoặc bảng con. **Khi không dùng.** Đối tượng nhỏ (PTN-04); quy trình có bước bắt buộc theo thứ tự (PTN-05).

**Ví dụ trong Datahub.** Tạo/sửa gói sử dụng (PH-02, kiểu xác thực, rate limit, quota, danh sách đường dẫn); tạo dịch vụ thu (PH-19); sửa hồ sơ HTTT (PH-01); tạo chính sách cổng API (PH-03); tạo quy tắc chất lượng (PH-08).

**Sơ đồ vùng.**

```text
┌ main (giới hạn size-page-max) ────────────────────────────────────────────────┐
│ ① PageHeader: Breadcrumb · "Tạo gói sử dụng" (hoặc "Sửa gói: {tên}")         │
│ ┌ ② Mục lục nhóm (≥ bp-xl) ┐ ┌ ③ Biểu mẫu (cột rộng tối đa size-form-max) ──┐ │
│ │ ● Thông tin chung        │ │ Alert tóm tắt lỗi (chỉ khi có lỗi)            │ │
│ │ ○ Xác thực               │ │ ┌ Khối đặc "Thông tin chung" ──────────────┐ │ │
│ │ ○ Giới hạn               │ │ │ Nhãn *  [ trường ]   Nhãn  [ trường ]     │ │ │
│ │ ○ Đường dẫn cho phép     │ │ │ Mô tả trợ giúp (font-footnote)            │ │ │
│ │ (dính, cuộn theo)        │ │ └───────────────────────────────────────────┘ │ │
│ └──────────────────────────┘ │ ┌ Khối đặc "Xác thực" ──────────────────────┐ │ │
│                              │ └───────────────────────────────────────────┘ │ │
│                              └───────────────────────────────────────────────┘ │
│ ④ Thanh thao tác dính đáy (color-surface-solid, shadow-2, z-sticky)           │
│   "Có thay đổi chưa lưu"                         [Hủy] [Lưu nháp] [Lưu]      │
└───────────────────────────────────────────────────────────────────────────────┘
```

Biểu mẫu chia thành các khối đặc theo nhóm nghiệp vụ; mỗi khối có tiêu đề `font-title-3`. Mục lục nhóm bên trái giúp nhảy nhanh trong biểu mẫu dài và đánh dấu nhóm có lỗi bằng biểu tượng kèm chữ "(2 lỗi)". Thanh thao tác dính đáy luôn nhìn thấy để người dùng không phải cuộn xuống cuối mới lưu được; thanh này là bề mặt đặc chứ không glass vì nó nằm trên nội dung.

**Thành phần và vật liệu.** ① `CMP-PageHeader` trên canvas. ② danh sách liên kết neo (anchor) trên canvas. ③ `CMP-Form`, `CMP-FormField`, các điều khiển nguyên tử (`CMP-Input`, `CMP-Select`, `CMP-NumberInput`, `CMP-Switch`, `CMP-DatePicker`, `CMP-SecretField`, `CMP-CodeEditor`), `CMP-Alert`; khối `CMP-Card` đặc. ④ `CMP-Button`, nền đặc.

**Hành vi.**

1. Biểu mẫu sửa tải dữ liệu mới nhất và `ETag` (CRUD-U-02); lưu gửi `If-Match` (ST-13).
2. Nhãn đặt trên trường (không đặt bên trái) để chịu được nhãn tiếng Việt dài và chuyển một cột dễ dàng; trường bắt buộc đánh dấu `*` kèm `aria-required`, và chú thích "Trường có dấu * là bắt buộc" ở đầu biểu mẫu.
3. Kiểm tra hợp lệ phía trình duyệt khi rời trường (blur) và khi gửi; lỗi máy chủ ánh xạ về trường theo con trỏ JSON của RFC 9457 (FR-00-081). Không kiểm tra từng phím gõ, trừ định dạng mã.
4. Trường không sửa được hiển thị chỉ đọc (CRUD-U-03); trường phụ thuộc (ví dụ chọn kiểu xác thực mTLS thì hiện trường chứng chỉ) hiện/ẩn ngay với chuyển động `motion-duration-base`.
5. "Lưu" xong điều hướng tới PTN-02 của đối tượng (tạo mới) hoặc quay về trang trước (sửa), kèm ST-10. "Lưu nháp" chỉ có với đối tượng có trạng thái Nháp. "Hủy" quay lại, hỏi nếu dirty.
6. Biểu mẫu dirty được tự lưu bản nháp cục bộ 10 giây một lần (không gồm trường bí mật); mở lại biểu mẫu khi có bản nháp cục bộ thì hiện `CMP-Alert` "Có bản nháp chưa lưu lúc {giờ}" với "Khôi phục" và "Bỏ".
7. Bố cục hai cột chỉ dùng cho cặp trường ngắn liên quan (Từ ngày/Đến ngày); dưới `bp-md` luôn một cột.

**Trạng thái cụ thể.** ST-01 (chỉ khi sửa): skeleton các khối trường. ST-09 đến ST-13 theo bảng chung; ST-11 chuyển focus tới trường lỗi đầu tiên và cuộn tới đó.

**Phím tắt.** `Ctrl+S` lưu; `Ctrl+Enter` lưu khi focus trong vùng soạn thảo; `Esc` không đóng trang (chỉ đóng popup).

**Tiêu chí nghiệm thu PTN-03.**

- [ ] Gửi biểu mẫu thiếu trường bắt buộc: lỗi hiện tại từng trường, có tóm tắt đầu trang, focus tới trường lỗi đầu tiên.
- [ ] Lỗi 422 từ máy chủ hiện đúng tại trường tương ứng.
- [ ] Bấm "Lưu" hai lần liên tiếp chỉ tạo một bản ghi.
- [ ] Rời trang khi dirty hiện hộp thoại; khi không dirty không hỏi.
- [ ] Hai người sửa cùng đối tượng: người lưu sau nhận hộp thoại xung đột có so sánh khác biệt.
- [ ] Thanh thao tác luôn nhìn thấy ở 1366×768.
- [ ] Mọi trường có nhãn liên kết `for`/`id`; trình đọc màn hình đọc nhãn, trạng thái bắt buộc và lỗi.

**Sai lầm thường gặp.** Đặt nút Lưu chỉ ở cuối biểu mẫu dài; chỉ báo lỗi ở đầu trang; dùng placeholder thay nhãn; ẩn trường không sửa được; xóa dữ liệu đã nhập khi máy chủ báo lỗi.

### 4.7. PTN-04 · Biểu mẫu nhanh (Drawer/Modal)

**Mục đích.** Tạo hoặc sửa đối tượng nhỏ mà không rời ngữ cảnh đang làm việc.

**Khi dùng.** Tối đa khoảng 8 trường, một nhóm, không có bảng con. Dùng **Drawer** khi người dùng cần nhìn danh sách phía sau để tham chiếu (thêm mục danh mục, thêm đầu mối kỹ thuật, sửa nhanh tham số); dùng **Modal** cho thao tác ngắn có tính quyết định (đổi tên, nhập lý do, xác nhận có thêm trường). **Khi không dùng.** Biểu mẫu dài, có trình soạn mã lớn, hoặc cần liên kết sâu bền vững (dùng PTN-03).

**Ví dụ trong Datahub.** Thêm mục danh mục (PH-07, Drawer); thêm đầu mối kỹ thuật cho HTTT (PH-01, Drawer); xoay vòng bí mật ứng dụng (PH-01, Modal, hiện bí mật một lần); yêu cầu quyền từ trang 403 (Modal); tạo topic nhanh (PH-10, Drawer).

**Sơ đồ vùng (Drawer).**

```text
                              ┌ Drawer glass-modal, size-drawer-md, radius-xl cạnh hở ┐
 (nội dung trang phía sau     │ ① Tiêu đề "Thêm mục danh mục" (font-title-3)    [×] │
  bị che bởi color-scrim)     │ ┌ ② Giếng nội dung đặc (radius đồng tâm 12px) ──────┐ │
                              │ │ Nhãn * [ trường ]                                  │ │
                              │ │ Nhãn   [ trường ]                                  │ │
                              │ │ (cuộn trong giếng nếu dài)                         │ │
                              │ └────────────────────────────────────────────────────┘ │
                              │ ③ Chân: [Hủy]               [Lưu và thêm tiếp] [Lưu] │
                              └────────────────────────────────────────────────────────┘
```

Khung Drawer là vật liệu `glass-modal`, cách mép phải và mép trên/dưới viewport `space-2`, bo `radius-xl`. Toàn bộ trường nhập nằm trong giếng nội dung nền `color-surface-solid` có bán kính đồng tâm (`radius-xl` trừ `space-2` = 12px), vì `glass-modal` không đạt tương phản chữ liên kết trong trường hợp xấu nhất. Tiêu đề và chân nằm trực tiếp trên kính, chỉ chứa chữ chính và nút.

**Thành phần.** `CMP-Drawer` hoặc `CMP-Modal`, `CMP-Form`, `CMP-FormField`, `CMP-Button`. Popup Select bên trong là `glass-overlay` (ngoại lệ kính trên kính được phép).

**Hành vi.**

1. Mở bằng hành động trên trang; focus vào trường đầu tiên; focus bị giữ trong lớp phủ (focus trap); đóng trả focus về nút đã mở.
2. Đóng bằng `Esc`, nút ×, bấm vào scrim (chỉ Drawer, không áp dụng cho Modal có dữ liệu dirty) đều qua kiểm tra dirty.
3. "Lưu" xong đóng lớp phủ, hiện ST-10, làm mới danh sách phía sau và làm nổi bật hàng mới 2 giây (`color-fill-selected` mờ dần). "Lưu và thêm tiếp" giữ lớp phủ mở, xóa trường, focus trường đầu.
4. Drawer có thể liên kết sâu qua query (`?chon={ma}&che-do=sua`) nếu FRS yêu cầu.
5. Không mở lớp phủ thứ hai chồng lên lớp phủ thứ nhất, trừ hộp thoại xác nhận (`CMP-ConfirmDialog`) và `CMP-ReasonDialog`.
6. Bí mật hiển thị một lần (thông tin xác thực mới) dùng `CMP-SecretField` với nút sao chép, cảnh báo "Bí mật chỉ hiển thị một lần" và yêu cầu tích "Tôi đã lưu bí mật" trước khi đóng được.

**Phím tắt.** `Esc` đóng; `Ctrl+Enter` lưu.

**Tiêu chí nghiệm thu PTN-04.**

- [ ] Focus vào trường đầu khi mở, bị giữ trong lớp phủ, trả về nút mở khi đóng.
- [ ] Chữ liên kết và chữ cấp hai chỉ nằm trong giếng đặc, không nằm trực tiếp trên `glass-modal`.
- [ ] `Esc` khi dirty hiện hộp thoại xác nhận.
- [ ] "Lưu và thêm tiếp" tạo bản ghi và giữ lớp phủ mở với trường trống.
- [ ] Ở chế độ glass "Tắt", khung Drawer nền đặc, bố cục không đổi.

**Sai lầm thường gặp.** Nhồi biểu mẫu dài vào Modal; Modal mở Modal; đặt chữ trực tiếp lên kính; đóng mất dữ liệu khi bấm nhầm ra ngoài.

### 4.8. PTN-05 · Wizard

**Mục đích.** Dẫn người dùng qua quy trình nhiều bước có thứ tự, trong đó bước sau phụ thuộc kết quả bước trước, và kết thúc bằng một bước rà soát trước khi gửi.

**Khi dùng.** Từ 3 đến 7 bước; có kiểm tra hoặc phân tích giữa các bước; người dùng ít làm nên cần được dẫn. **Khi không dùng.** Chỉ để chia một biểu mẫu dài cho "đỡ rối" mà các bước không phụ thuộc nhau (dùng PTN-03 có mục lục nhóm).

**Ví dụ trong Datahub.** Kết nạp HTTT thành viên (PH-01: thông tin hệ thống → đầu mối → hồ sơ pháp lý → rà soát → gửi duyệt); đăng ký API từ OpenAPI (PH-02: tải đặc tả → kiểm tra và xem trước endpoint → phân loại → gói sử dụng → rà soát); kích hoạt dịch vụ thu có giao dịch thử (PH-19); chạy di trú hệ cũ (PH-18: chọn nguồn → chọn phạm vi → chạy thử đối chiếu → chạy thật → báo cáo FR-00-092); khởi tạo tenant (PH-20).

**Sơ đồ vùng.**

```text
┌ main (giới hạn size-page-max) ────────────────────────────────────────────────┐
│ ① PageHeader: Breadcrumb · "Kết nạp hệ thống thành viên"        [Lưu và thoát]│
│ ② Steps: (1)✓ Thông tin ── (2)● Đầu mối ── (3)○ Hồ sơ ── (4)○ Rà soát        │
│ ┌ ③ Khối đặc nội dung bước (rộng tối đa size-form-max, căn giữa) ──────────┐  │
│ │ Tiêu đề bước, mô tả ngắn bước này để làm gì                               │  │
│ │ Trường / bảng / kết quả phân tích                                         │  │
│ └────────────────────────────────────────────────────────────────────────── ┘  │
│ ④ Thanh dính đáy:  [Hủy]                           [‹ Quay lại] [Tiếp tục ›] │
└───────────────────────────────────────────────────────────────────────────────┘
```

**Thành phần và vật liệu.** ② `CMP-Steps` trên canvas (nhãn bước luôn có chữ, không chỉ số); ③ `CMP-Card` đặc chứa `CMP-Form`, `CMP-Upload`, `CMP-DataTable`, `CMP-JobProgress`; bước rà soát dùng `CMP-DescriptionList` theo nhóm có liên kết "Sửa" quay về bước tương ứng; ④ thanh đặc dính đáy.

**Hành vi.**

1. Mỗi bước được kiểm tra hợp lệ khi bấm "Tiếp tục"; không cho sang bước sau khi bước hiện tại lỗi. Có thể quay lại bước đã hoàn thành bằng nút "Quay lại" hoặc bấm vào bước trên `CMP-Steps`; không nhảy tới bước chưa tới.
2. Trạng thái wizard được lưu phía máy chủ dưới dạng bản nháp sau mỗi bước (đối tượng ở trạng thái Nháp), để người dùng "Lưu và thoát" rồi tiếp tục sau từ danh sách; bước hiện tại phản ánh trên URL (`?buoc=2`).
3. Bước chạy lâu (phân tích đặc tả, chạy thử di trú) chạy nền với `CMP-JobProgress` (FR-00-054); người dùng có thể rời trang và được báo qua trung tâm thông báo.
4. Bước cuối là "Rà soát" chỉ đọc; nút cuối mang tên hành động thật ("Gửi duyệt", "Kích hoạt", "Chạy di trú"), không dùng "Hoàn tất" chung chung.
5. Sau gửi, hiển thị `CMP-ResultPage` thành công với bước tiếp theo ("Yêu cầu đã được gửi tới Quản trị tỉnh. Bạn sẽ nhận thông báo khi có kết quả.") và nút "Xem hồ sơ", "Về danh sách".

**Trạng thái cụ thể.** Khi mở wizard từ bản nháp đã bị người khác gửi duyệt, hiện ST-13 biến thể "Bản nháp này đã được gửi duyệt bởi {người}" và chuyển sang PTN-02.

**Phím tắt.** `Alt+→` tiếp tục; `Alt+←` quay lại.

**Tiêu chí nghiệm thu PTN-05.**

- [ ] Không sang được bước sau khi bước hiện tại có lỗi; lỗi hiện tại trường.
- [ ] "Lưu và thoát" rồi mở lại từ danh sách tiếp tục đúng bước, đúng dữ liệu.
- [ ] Tải lại trình duyệt ở bước 3 vẫn ở bước 3.
- [ ] Bước rà soát hiển thị toàn bộ dữ liệu đã nhập; "Sửa" quay về đúng bước.
- [ ] `CMP-Steps` thông báo cho trình đọc màn hình "Bước 2 trên 4, Đầu mối, hiện tại".

**Sai lầm thường gặp.** Mất dữ liệu khi quay lại bước trước; wizard một bước; nút cuối "Hoàn tất" không rõ hậu quả; không lưu nháp nên quy trình dài bị mất khi hết phiên.

### 4.9. PTN-06 · Dashboard

**Mục đích.** Cho người dùng nắm nhanh tình trạng tổng thể qua chỉ số tổng hợp, xu hướng và cảnh báo, rồi đi sâu vào chi tiết khi cần.

**Khi dùng.** Trang chủ của người dùng; bảng giám sát vận hành; tổng quan theo phân hệ (kênh thanh toán, chất lượng dữ liệu, chỉ tiêu). **Khi không dùng.** Khi người dùng cần thao tác trên từng bản ghi (PTN-01) hoặc khám phá sự kiện thô (PTN-11).

**Ví dụ trong Datahub.** Tổng quan (`/tong-quan`, thẻ lắp theo quyền); bảng giám sát PH-13 (lượt gọi API, tỷ lệ lỗi, độ trễ p95, luồng lỗi, DLQ tồn); dashboard kênh thanh toán PH-19 (giao dịch theo kênh, tỷ lệ thành công); điểm chất lượng dữ liệu PH-08; báo cáo chỉ tiêu PH-16.

**Sơ đồ vùng.**

```text
┌ main (toàn chiều rộng) ───────────────────────────────────────────────────────┐
│ ① PageHeader: "Bảng giám sát"  [Khoảng: 24 giờ qua ▾] [⟳ Tự làm mới: 30s ▾]  │
│              Cập nhật lúc 14:05:32                     [⛶ Toàn màn hình] [⋯] │
│ ② Hàng KPI (≥ bp-xxl: 4 thẻ; bp-lg…bp-xxl: 2–3; < bp-lg: 1–2)                │
│ ┌ KpiCard ──────┐ ┌ KpiCard ──────┐ ┌ KpiCard ──────┐ ┌ KpiCard ──────┐       │
│ │ Lượt gọi API  │ │ Tỷ lệ lỗi     │ │ Độ trễ p95    │ │ DLQ tồn       │       │
│ │ 4.812.300     │ │ 0,08% ▼0,02   │ │ 42 ms         │ │ 17 ⚠          │       │
│ │ ▁▂▃▅▆▇ so hôm qua│ (sparkline)   │ │               │ │               │       │
│ └───────────────┘ └───────────────┘ └───────────────┘ └───────────────┘       │
│ ③ Lưới biểu đồ 12 cột                                                        │
│ ┌ Card: Lưu lượng theo giờ (8 cột) ───────────┐ ┌ Card: Cảnh báo đang mở (4) ┐│
│ │ CMP-Chart (đường)                            │ │ Danh sách gọn, liên kết     ││
│ └──────────────────────────────────────────────┘ └─────────────────────────────┘│
│ ┌ Card: Top 10 API lỗi (6) ─────┐ ┌ Card: Luồng lỗi gần đây (6) ──────────────┐│
│ └───────────────────────────────┘ └────────────────────────────────────────────┘│
└───────────────────────────────────────────────────────────────────────────────┘
```

Sơ đồ đi từ tổng quát tới cụ thể: hàng KPI trả lời "mọi thứ có ổn không", lưới biểu đồ trả lời "vì sao", các danh sách gọn dẫn tới chi tiết. Thẻ KPI tuân thủ quy tắc của skill trực quan hóa dữ liệu ở D03-05-04 (`CMP-KpiCard`): số chính `font-display` với `font-feature-tabular`, nhãn ở trên, so sánh kèm mũi tên và chữ (không chỉ màu), sparkline không trục.

**Thành phần và vật liệu.** ① `CMP-PageHeader`, `CMP-Select` (khoảng thời gian), `CMP-Timestamp`; ② `CMP-KpiCard` đặc; ③ `CMP-Card` đặc chứa `CMP-Chart` (ECharts, ADR-023, bảng màu `color-chart-1…8`), danh sách gọn `CMP-DataTable` biến thể gọn, `CMP-StatusTag`. Tooltip của biểu đồ là nền đảo đặc.

**Hành vi.**

1. *Khoảng thời gian* chung cho cả trang, giữ trên URL (`khoang=24h` hoặc `tu`/`den`); lựa chọn sẵn: 15 phút, 1 giờ, 24 giờ, 7 ngày, 30 ngày, tùy chọn.
2. *Làm mới tự động* có các mức Tắt / 15 giây / 30 giây / 1 phút / 5 phút; mặc định 30 giây cho bảng giám sát, Tắt cho dashboard báo cáo. Chỉ làm mới khi tab trình duyệt đang hiển thị (`visibilitychange`); làm mới không nháy skeleton mà cập nhật tại chỗ (ST-02), và không đẩy thông báo vào vùng `aria-live` mỗi lần làm mới, trừ khi một KPI vượt ngưỡng cảnh báo.
3. *Đi sâu.* Bấm thẻ KPI hoặc điểm dữ liệu điều hướng tới màn chi tiết với bộ lọc tương ứng (ví dụ thẻ "DLQ tồn" tới `/van-hanh/dlq?trang-thai=cho-xu-ly`). Mọi biểu đồ có nút "Xem dạng bảng" hiển thị dữ liệu dưới dạng bảng có thể đọc bằng trình đọc màn hình (phương án thay thế cho biểu đồ, WCAG 1.1.1).
4. *Mỗi thẻ tải độc lập*: một thẻ lỗi hiển thị ST-05 trong thẻ, các thẻ khác vẫn hoạt động.
5. *Ngưỡng.* KPI vượt ngưỡng hiển thị `CMP-StatusTag` mức cảnh báo/lỗi kèm chữ ("Vượt ngưỡng 1%"), viền trái 3px màu trạng thái.
6. *Chế độ trực ca.* Bật bằng "⋯ › Chế độ trực ca": ép chủ đề tối (`data-theme="dark"`) bất kể cài đặt cá nhân, vào toàn màn hình (mục 3.9), tăng cỡ chữ KPI một bậc (`font-display-lg`), ẩn mọi điều khiển trừ khoảng thời gian và đồng hồ, bật làm mới 15 giây, tắt hiệu ứng glass (`data-glass="off"`) để giảm tải GPU khi chạy liên tục nhiều giờ trên màn hình lớn. KPI vượt ngưỡng nhấp nháy viền một lần rồi giữ nguyên (không nhấp nháy liên tục, WCAG 2.3.1), kèm biểu tượng.
7. *Tùy biến.* Người dùng có thể ẩn/hiện và sắp xếp thẻ trên trang Tổng quan (sắp xếp có phương án bàn phím bằng nút "Di chuyển lên/xuống"); bố cục lưu theo người dùng. Bảng giám sát vận hành có bố cục cố định do quản trị tỉnh cấu hình.

**Trạng thái cụ thể.** ST-01: skeleton từng thẻ đúng kích thước để bố cục không nhảy. Không có dữ liệu trong khoảng thời gian: biểu đồ hiện trục và dòng chữ "Không có dữ liệu trong khoảng thời gian đã chọn", không vẽ đường bằng 0 giả. Dữ liệu trễ (nguồn chỉ số chậm hơn 2 lần chu kỳ làm mới): dòng "Cập nhật lúc" chuyển màu cảnh báo kèm chữ "Dữ liệu có thể đã cũ".

**Phím tắt.** `R` làm mới; `F` toàn màn hình; `T` mở chọn khoảng thời gian.

**Tiêu chí nghiệm thu PTN-06.**

- [ ] Đổi khoảng thời gian cập nhật mọi thẻ và URL.
- [ ] Làm mới tự động dừng khi tab ẩn, tiếp tục khi tab hiện.
- [ ] Một thẻ lỗi không làm hỏng các thẻ khác.
- [ ] Mọi biểu đồ có "Xem dạng bảng"; số liệu bảng khớp biểu đồ.
- [ ] Không có thông tin nào chỉ truyền đạt bằng màu (kiểm tra ở chế độ xám).
- [ ] Chế độ trực ca: tối, toàn màn hình, glass tắt, dải liên tenant vẫn hiện nếu có.
- [ ] Bố cục ổn định khi tải (CLS < 0,1).

**Sai lầm thường gặp.** Quá nhiều thẻ KPI (trên 8) làm loãng; biểu đồ tròn nhiều lát; dùng màu đỏ/xanh không chữ; làm mới bằng cách tải lại toàn trang; vẽ số 0 khi thiếu dữ liệu.

### 4.10. PTN-07 · Designer (canvas)

**Mục đích.** Cho kỹ sư tạo dựng và xem cấu trúc dạng đồ thị (nút và cạnh) bằng thao tác trực quan, đồng bộ hai chiều với biểu diễn văn bản.

**Khi dùng.** Luồng tích hợp, mô hình quy trình, sơ đồ kết nối. **Khi không dùng.** Cấu trúc tuyến tính đơn giản biểu diễn tốt bằng bảng.

**Ví dụ trong Datahub.** Thiết kế luồng tích hợp PH-04 (`/tich-hop/luong/{ma}/thiet-ke`, đồng bộ Camel YAML DSL theo ADR-010); sơ đồ kết nối topic PH-10 (`/tich-hop/so-do`, chế độ chỉ xem, publisher → topic → subscriber); mô hình quy trình BPMN PH-11 (Đợt 2).

**Sơ đồ vùng.**

```text
┌ main (toàn chiều rộng, không lề dưới, cao = viewport − topbar) ───────────────┐
│ ① Thanh công cụ: [‹] Luồng "Đồng bộ hộ tịch" ●Nháp v5 · Đã lưu 14:02         │
│    [↶][↷] [Thiết kế|YAML|Chia đôi] [Kiểm tra] [Chạy thử] [Lưu] [Gửi duyệt][⛶]│
│ ┌ ② Bảng nút ──┐ ┌ ③ Canvas (nền color-surface-solid-2, lưới chấm) ──┐ ┌ ④ Inspector ┐│
│ │ 🔍 Tìm nút   │ │                                                    │ │ Thuộc tính  ││
│ │ ▾ Nguồn      │ │   [REST vào] ──▶ [Chuyển đổi] ──▶ [Gọi SOAP]       │ │ nút đang    ││
│ │   REST       │ │                       │                            │ │ chọn        ││
│ │   Lịch       │ │                       ▼                            │ │ (Form)      ││
│ │ ▾ Xử lý      │ │                  [Ghi log]                         │ │             ││
│ │ ▾ Đích       │ │                                  ┌ minimap ┐ [+][−]│ │             ││
│ └──────────────┘ └────────────────────────────────────────────────────┘ └─────────────┘│
│ ⑤ Bảng dưới thu gọn được: Vấn đề (3) | Kết quả chạy thử | Nhật ký            │
└───────────────────────────────────────────────────────────────────────────────┘
```

Designer chiếm toàn bộ vùng nội dung, không cuộn trang; mỗi vùng tự cuộn. Bảng nút trái rộng 240px, Inspector phải rộng 360px, cả hai thu gọn được; bảng dưới cao 240px khi mở. Canvas là bề mặt đặc (`color-surface-solid-2`) chứ không glass, vì nút và cạnh cần tương phản ổn định; các nút điều khiển nổi trên canvas (thu phóng, minimap) là `glass-overlay`.

**Thành phần và vật liệu.** ① thanh công cụ đặc; ② `CMP-NodePalette` đặc; ③ `CMP-FlowCanvas`, `CMP-FlowNode` (XYFlow), nền đặc; ④ `CMP-Inspector` đặc chứa `CMP-Form`; chế độ YAML dùng `CMP-CodeEditor` (Monaco); ⑤ `CMP-Tabs`, `CMP-LogViewer`, `CMP-DataTable`; so sánh phiên bản dùng `CMP-DiffViewer`.

**Hành vi.**

1. *Thêm nút.* Kéo từ bảng nút thả vào canvas, **hoặc** chọn nút trong bảng rồi nhấn `Enter` để chèn sau nút đang chọn (phương án không kéo thả, WCAG 2.5.7). Nối cạnh bằng kéo từ cổng ra tới cổng vào, **hoặc** trong Inspector chọn "Nút tiếp theo" từ danh sách.
2. *Bàn phím trên canvas.* `Tab` di chuyển giữa các nút theo thứ tự luồng, phím mũi tên dịch chuyển nút đang chọn 8px (`Shift` 32px), `Delete` xóa (có hoàn tác), `Ctrl+Z`/`Ctrl+Shift+Z` hoàn tác/làm lại. Mỗi nút có `aria-label` mô tả loại, tên và số cạnh vào/ra; có chế độ "Xem dạng danh sách" liệt kê nút và cạnh cho trình đọc màn hình.
3. *Đồng bộ YAML.* Chế độ Thiết kế, YAML và Chia đôi chuyển qua lại không mất dữ liệu; sửa YAML hợp lệ cập nhật canvas sau 500ms; YAML lỗi cú pháp hiện lỗi trong trình soạn và trong bảng Vấn đề, canvas giữ trạng thái hợp lệ gần nhất kèm dải "YAML đang có lỗi, sơ đồ hiển thị phiên bản hợp lệ gần nhất".
4. *Lưu.* Tự lưu bản nháp phía máy chủ 30 giây một lần khi có thay đổi, chỉ báo "Đang lưu… / Đã lưu {giờ}" trên thanh công cụ; `Ctrl+S` lưu ngay; lưu dùng `If-Match` (ST-13 hiển thị so sánh YAML). Rời trang khi có thay đổi chưa lưu lên máy chủ hỏi xác nhận.
5. *Kiểm tra và chạy thử.* "Kiểm tra" chạy xác thực cấu trúc, kết quả vào bảng Vấn đề, bấm một vấn đề chọn nút liên quan. "Chạy thử" mở Drawer nhập bản tin mẫu, chạy nền, kết quả hiển thị theo từng nút (nút đi qua có dấu ✓, nút lỗi có dấu ✕ và chữ).
6. *Chỉ xem.* Luồng đã phát hành mở ở chế độ chỉ xem; muốn sửa phải "Tạo phiên bản mới" (sinh bản nháp). Sơ đồ kết nối PH-10 luôn chỉ xem, bấm nút mở Drawer chi tiết topic/hệ thống.
7. *Màn hình nhỏ.* Dưới `bp-lg` hiển thị thông báo yêu cầu màn hình rộng và chế độ YAML chỉ đọc.

**Trạng thái cụ thể.** ST-01: canvas trống với skeleton 3 nút. Rỗng (luồng mới): canvas hiện gợi ý "Kéo một nút Nguồn vào đây hoặc nhấn Enter trên nút trong bảng bên trái để bắt đầu". Mất kết nối khi đang sửa: tiếp tục sửa cục bộ, chỉ báo "Chưa lưu lên máy chủ", tự đồng bộ khi có lại kết nối.

**Phím tắt.** `Ctrl+S` lưu; `Ctrl+Z`/`Ctrl+Shift+Z`; `Delete`; `Ctrl+D` nhân bản nút; `0` vừa khung; `+`/`−` thu phóng; `Ctrl+\` chuyển chế độ YAML; `F` toàn màn hình; `?` danh sách phím tắt.

**Tiêu chí nghiệm thu PTN-07.**

- [ ] Tạo một luồng ba nút hoàn toàn bằng bàn phím, không kéo thả.
- [ ] Sửa trên canvas cập nhật YAML và ngược lại, không mất thuộc tính.
- [ ] YAML lỗi không làm hỏng canvas; lỗi hiện ở bảng Vấn đề.
- [ ] Tự lưu hoạt động; hai người sửa cùng luồng nhận xung đột có so sánh.
- [ ] Luồng 200 nút thu phóng, kéo mượt (≥ 50 khung hình/giây trên máy văn phòng chuẩn).
- [ ] Trạng thái chạy thử của nút có chữ/biểu tượng, không chỉ màu.

**Sai lầm thường gặp.** Chỉ hỗ trợ kéo thả; canvas glass; mất dữ liệu khi chuyển chế độ YAML; Inspector là Modal che canvas; không có hoàn tác.

### 4.11. PTN-08 · Cây + bảng (master–detail)

**Mục đích.** Duyệt dữ liệu phân cấp: chọn một nút ở cây bên trái để xem và thao tác nội dung của nút đó ở bên phải.

**Khi dùng.** Danh mục phân cấp, nhóm dịch vụ, vai trò và quyền, đơn vị hành chính. **Khi không dùng.** Cây chỉ có một cấp (dùng bộ lọc của PTN-01).

**Ví dụ trong Datahub.** Danh mục dùng chung PH-07 (`/du-lieu/danh-muc`: cây nhóm danh mục trái, bảng danh mục phải; trong chi tiết một danh mục phân cấp như đơn vị hành chính: cây mục trái, chi tiết mục phải); nhóm dịch vụ thu PH-19; nhóm và vai trò PH-12 (cây nhóm trái, danh sách thành viên và quyền phải).

**Sơ đồ vùng.**

```text
┌ main ─────────────────────────────────────────────────────────────────────────┐
│ ① PageHeader: "Danh mục dùng chung"                     [Nhập] [+ Thêm]       │
│ ┌ ② Khối cây (đặc, rộng 280px, kéo giãn 240–480) ┐┊┌ ③ Khối chi tiết (đặc) ──┐│
│ │ [🔍 Tìm trong cây]                              │┊│ Tiêu đề nút đang chọn    ││
│ │ ▾ Tất cả (124)                                  │┊│ FilterBar                ││
│ │   ▾ Hành chính (18)                             │┊│ DataTable (như PTN-01)   ││
│ │     ● Đơn vị hành chính                         │┊│                          ││
│ │   ▸ Dân cư (22)                                 │┊│ Pagination               ││
│ │   ▸ Y tế (9)                                    │┊│                          ││
│ │ [+ Thêm nhóm]                                   │┊│                          ││
│ └─────────────────────────────────────────────────┘┊└──────────────────────────┘│
└───────────────────────────────────────────────────────────────────────────────┘
```

Hai khối đặc tách nhau bằng tay nắm kéo giãn (┊) có phương án bàn phím (focus tay nắm rồi dùng mũi tên trái/phải, `role="separator"` với `aria-valuenow`). Chiều rộng cây ghi nhớ theo người dùng. Dưới `bp-lg`, cây thu vào một `CMP-Drawer` mở bằng nút "Chọn nhóm" và tên nhóm đang chọn hiện trên tiêu đề khối chi tiết.

**Thành phần.** ② `CMP-Tree`, `CMP-SearchField`, `CMP-Badge` (số đếm); ③ như PTN-01 hoặc `CMP-DescriptionList` khi chi tiết là một mục.

**Hành vi.**

1. Nút đang chọn phản ánh trên URL (`?nhom={ma}` hoặc `/{ma-muc}`); mở URL tự mở rộng cây tới nút đó và cuộn tới.
2. Cây tải lười theo cấp với cây lớn (trên 500 nút); tìm trong cây gọi máy chủ, hiển thị kết quả kèm đường dẫn cha và tự mở rộng.
3. Bàn phím theo mẫu tree view của ARIA APG: mũi tên lên/xuống di chuyển, `→` mở/vào con, `←` đóng/về cha, `Home`/`End`, gõ ký tự để nhảy tới nút bắt đầu bằng ký tự đó.
4. Di chuyển nút (đổi cha) bằng kéo thả **hoặc** hành động "Di chuyển tới…" mở `CMP-TreeSelect` chọn cha mới; di chuyển hỏi xác nhận nếu nút có con.
5. Danh mục có phiên bản (PH-07): khối chi tiết hiển thị bộ chọn phiên bản và nhãn "Bản nháp"/"Đã công bố" rõ ràng; sửa chỉ trên bản nháp.

**Trạng thái cụ thể.** Cây rỗng: `CMP-EmptyState` trong khối cây với "Thêm nhóm đầu tiên". Chưa chọn nút: khối chi tiết hiện "Chọn một nhóm ở bên trái để xem danh mục" (mặc định chọn "Tất cả" để tránh trạng thái này ở trang danh sách).

**Phím tắt.** `Ctrl+Shift+F` focus tìm trong cây; `Alt+1`/`Alt+2` chuyển focus giữa khối cây và khối chi tiết.

**Tiêu chí nghiệm thu PTN-08.**

- [ ] Mở URL có `nhom` mở rộng đúng nhánh, chọn đúng nút.
- [ ] Toàn bộ thao tác cây bằng bàn phím theo APG.
- [ ] Di chuyển nút thực hiện được không cần kéo thả.
- [ ] Cây 10.000 nút tải lười, mở một cấp dưới 500ms.
- [ ] Kéo giãn bằng bàn phím hoạt động; độ rộng được ghi nhớ.

**Sai lầm thường gặp.** Tải toàn bộ cây lớn một lần; mất lựa chọn khi tải lại; chỉ cho đổi cha bằng kéo thả; cây và bảng cuộn chung một thanh cuộn.

### 4.12. PTN-09 · Nhập dữ liệu có xem trước

**Mục đích.** Nạp hàng loạt bản ghi từ tệp một cách an toàn: người dùng thấy trước dữ liệu sẽ được ghi, thấy lỗi theo dòng và cột, và quyết định ghi hay không (FR-00-032, FR-00-033).

**Khi dùng.** Mọi chức năng nhập tệp (Excel .xlsx, CSV UTF-8). **Khi không dùng.** Tải lên một tệp đính kèm đơn lẻ (dùng `CMP-Upload` trong biểu mẫu).

**Ví dụ trong Datahub.** Nhập danh mục từ Excel PH-07 (`/du-lieu/danh-muc/{ma}/nhap`, 100.000 dòng trong ≤ 2 phút theo NFR-00-008); nhập danh sách HTTT từ hệ cũ PH-01; nhập tệp đối soát PH-19; nhập người dùng hàng loạt PH-12.

**Sơ đồ vùng.** PTN-09 là một wizard ba bước chuyên biệt (kế thừa khung PTN-05).

```text
┌ main ─────────────────────────────────────────────────────────────────────────┐
│ ① PageHeader: "Nhập mục danh mục · Giới tính"                                 │
│ ② Steps: (1) Chọn tệp ── (2) Xem trước và kiểm tra ── (3) Kết quả            │
│ ┌ Bước 1 (khối đặc) ───────────────────────────────────────────────────────┐ │
│ │ [⬇ Tải tệp mẫu (.xlsx)]  Hướng dẫn cột bắt buộc (bảng nhỏ)               │ │
│ │ ┌ Vùng thả tệp ─────────────────────────────┐  hoặc [Chọn tệp]           │ │
│ │ └───────────────────────────────────────────┘  Tối đa 50 MB, .xlsx/.csv   │ │
│ │ Tùy chọn: Chế độ [Thêm mới | Thêm và cập nhật | Thay toàn bộ bản nháp]    │ │
│ └──────────────────────────────────────────────────────────────────────────┘ │
│ ┌ Bước 2 (khối đặc) ───────────────────────────────────────────────────────┐ │
│ │ Tóm tắt: 12.480 dòng · 12.452 hợp lệ · 28 lỗi · 310 sẽ cập nhật           │ │
│ │ [Tất cả | Chỉ dòng lỗi (28) | Thêm mới | Cập nhật]  [⬇ Tải báo cáo lỗi]   │ │
│ │ DataTable ảo hóa: Dòng │ Mã │ Tên │ … ô lỗi viền + biểu tượng + tooltip    │ │
│ │ ☐ Bỏ qua 28 dòng lỗi và ghi các dòng hợp lệ                              │ │
│ └──────────────────────────────────────────────────────────────────────────┘ │
│ ③ Thanh dính đáy: [Hủy]                        [‹ Chọn tệp khác] [Ghi dữ liệu]│
└───────────────────────────────────────────────────────────────────────────────┘
```

**Thành phần.** `CMP-Steps`, `CMP-Upload` (biến thể vùng thả, có nút chọn tệp cho người dùng bàn phím), `CMP-SegmentedControl`, `CMP-DataTable` (ảo hóa), `CMP-Alert`, `CMP-JobProgress`, `CMP-ResultPage`. Mọi vùng là bề mặt đặc.

**Hành vi.**

1. Tệp mẫu (FR-00-033) có hàng tiêu đề, dòng ví dụ, trang tính "Hướng dẫn" mô tả kiểu dữ liệu và giá trị hợp lệ; tệp mẫu sinh theo thuộc tính động hiện tại của danh mục.
2. Tải tệp lên kho tạm, phân tích chạy nền (FR-00-054) với `CMP-JobProgress` "Đang kiểm tra 6.200 / 12.480 dòng"; người dùng có thể rời trang và nhận thông báo khi xong.
3. Bước 2 hiển thị lỗi theo **dòng và cột** của tệp gốc (dòng tính như Excel, có tiêu đề là dòng 1). Ô lỗi có viền `color-error`, biểu tượng và thông điệp trên tooltip, đồng thời có cột "Lỗi" dạng chữ để không chỉ dựa vào màu. Báo cáo lỗi tải về là tệp gốc có thêm cột "Lỗi".
4. Ghi theo kiểu **tất cả hoặc không** (FR-00-032): nút "Ghi dữ liệu" bị vô hiệu khi còn lỗi, trừ khi người dùng tích "Bỏ qua {n} dòng lỗi"; khi đó nhãn nút đổi thành "Ghi {m} dòng hợp lệ". Chế độ "Thay toàn bộ bản nháp" yêu cầu `CMP-ConfirmDialog` nêu số bản ghi sẽ bị thay.
5. Ghi chạy nền; bước 3 hiển thị `CMP-ResultPage` với số đã thêm, đã cập nhật, đã bỏ qua, thời gian, liên kết tới đối tượng và mã tác vụ; toàn bộ lần nhập được ghi kiểm toán một bản ghi tổng hợp kèm tệp gốc.
6. Với dữ liệu có phiên bản (PH-07), nhập luôn ghi vào bản nháp, không ghi thẳng vào bản đã công bố.

**Trạng thái cụ thể.** Tệp sai định dạng hoặc vượt dung lượng: lỗi tại vùng thả, không chuyển bước. Tệp thiếu cột bắt buộc: dừng ở bước 2 với `CMP-Alert` liệt kê cột thiếu, không hiện bảng. Tệp mã hóa không phải UTF-8 (CSV): cảnh báo và cho chọn bảng mã.

**Tiêu chí nghiệm thu PTN-09.**

- [ ] Tải được tệp mẫu; nhập lại tệp mẫu đã điền đúng thì thành công.
- [ ] Tệp có 1 dòng lỗi: không dòng nào được ghi khi không tích bỏ qua.
- [ ] Lỗi chỉ ra đúng số dòng và tên cột theo tệp gốc.
- [ ] 100.000 dòng hoàn tất trong ≤ 2 phút (NFR-00-008); bảng xem trước cuộn mượt.
- [ ] Vùng thả tệp có phương án chọn tệp bằng bàn phím.
- [ ] Rời trang trong lúc phân tích, nhận thông báo khi xong, quay lại đúng bước 2.

**Sai lầm thường gặp.** Ghi từng phần rồi báo lỗi giữa chừng; báo lỗi chung chung "Tệp không hợp lệ"; đánh số dòng lệch so với Excel; xem trước chỉ 100 dòng đầu mà không nói rõ.

### 4.13. PTN-10 · Hộp việc và duyệt

**Mục đích.** Cho người duyệt xử lý nhanh và đúng hàng đợi yêu cầu chờ quyết định từ mọi phân hệ (FR-00-070…072).

**Khi dùng.** Hộp việc chung "Việc của tôi"; danh sách "Yêu cầu tôi đã gửi". **Khi không dùng.** Danh sách đối tượng thông thường có trạng thái "Chờ duyệt" (vẫn là PTN-01, nhưng liên kết sang hộp việc).

**Ví dụ trong Datahub.** `/viec-cua-toi` gồm: duyệt kết nạp HTTT, duyệt phát hành API, duyệt đăng ký sử dụng, duyệt phát hành luồng, duyệt công bố danh mục, chấp thuận khai thác dữ liệu, duyệt hoàn tiền, việc BPMN.

**Sơ đồ vùng.**

```text
┌ main (toàn chiều rộng) ───────────────────────────────────────────────────────┐
│ ① PageHeader: "Hộp việc"   [Chờ tôi (12) | Nhóm của tôi (5) | Đã xử lý]      │
│ ┌ ② Danh sách việc (đặc, 5/12) ──────┐ ┌ ③ Chi tiết việc (đặc, 7/12) ────────┐│
│ │ 🔍 [Loại ▾] [Hạn ▾] [Phân hệ ▾]     │ │ Duyệt phát hành API "Tra cứu hộ tịch"││
│ │ ┌────────────────────────────────┐ │ │ Gửi bởi Nguyễn Văn A · 20/11 09:12   ││
│ │ │● Phát hành API  Quá hạn 1 ngày │ │ │ Hạn: 22/11/2026 (còn 1 ngày)        ││
│ │ │  Tra cứu hộ tịch · Sở Tư pháp  │ │ │ ── Nội dung yêu cầu ──              ││
│ │ └────────────────────────────────┘ │ │ DescriptionList / DiffViewer        ││
│ │ ┌────────────────────────────────┐ │ │ ── Ý kiến các bước trước ──         ││
│ │ │  Hoàn tiền GD2026…  Hạn 23/11  │ │ │ Timeline                            ││
│ │ └────────────────────────────────┘ │ │ ── ApprovalPanel ──                 ││
│ │ …                                  │ │ Ý kiến * [________________]         ││
│ │                                    │ │ [Từ chối] [Yêu cầu bổ sung] [Duyệt] ││
│ └────────────────────────────────────┘ └──────────────────────────────────────┘│
└───────────────────────────────────────────────────────────────────────────────┘
```

Bố cục hai khung (danh sách và chi tiết) cho phép duyệt liên tục: duyệt xong một việc, khung chi tiết tự chuyển sang việc kế tiếp. Dưới `bp-xl`, khung chi tiết mở thành trang riêng.

**Thành phần.** `CMP-Tabs`/`CMP-SegmentedControl`, `CMP-FilterBar`, danh sách thẻ việc (`CMP-Card` gọn với `CMP-StatusTag`, `CMP-Timestamp`), `CMP-DescriptionList`, `CMP-DiffViewer`, `CMP-Timeline`, `CMP-ApprovalPanel`, `CMP-ReasonDialog`. Mọi vùng đặc.

**Hành vi.**

1. Việc sắp xếp mặc định theo hạn xử lý gần nhất; việc quá hạn đứng đầu, nhãn "Quá hạn {n} ngày" mức lỗi; sắp hết hạn (dưới 24 giờ) mức cảnh báo.
2. Việc chọn phản ánh trên URL (`?chon={ma-viec}`); thông báo trong trung tâm thông báo dẫn thẳng tới đây.
3. Khung chi tiết hiển thị nội dung yêu cầu do phân hệ nguồn cung cấp (thành phần nhúng đăng ký theo loại việc), cộng liên kết "Mở đối tượng" tới PTN-02 của phân hệ.
4. `CMP-ApprovalPanel`: ô ý kiến bắt buộc với mọi quyết định (FR-00-072), lý do từ chối tối thiểu 10 ký tự. Người tạo yêu cầu không thấy nút duyệt với loại việc áp dụng bốn mắt; thay vào đó là dòng "Bạn là người gửi yêu cầu này nên không thể tự duyệt" (FR-00-071).
5. Quyết định dùng `If-Match`; nếu việc đã được người khác trong nhóm xử lý, hiện `CMP-Alert` "Việc này đã được {người} xử lý lúc {giờ}" và loại việc khỏi danh sách.
6. Duyệt hàng loạt chỉ cho phép với loại việc được FRS đánh dấu là an toàn duyệt lô, cần một ý kiến chung và trả kết quả từng việc.
7. Tab "Đã xử lý" chỉ đọc, giữ lịch sử quyết định của người dùng.

**Trạng thái cụ thể.** Rỗng: "Bạn không có việc nào chờ xử lý" với minh họa nhẹ; không có nút hành động. Đã xử lý hết trong phiên: khung chi tiết hiện "Bạn đã xử lý hết việc trong danh sách".

**Phím tắt.** `J`/`K` việc kế/trước; `A` focus ô ý kiến rồi duyệt bằng `Ctrl+Enter`; `R` mở từ chối. Phím tắt duyệt không bao giờ thực hiện quyết định mà không qua ô ý kiến.

**Tiêu chí nghiệm thu PTN-10.**

- [ ] Hộp việc tổng hợp đúng việc từ mọi phân hệ đã bật cho tenant.
- [ ] Không duyệt hoặc từ chối được khi ô ý kiến trống; từ chối bắt buộc lý do.
- [ ] Người tạo không tự duyệt được yêu cầu loại bốn mắt, cả trên giao diện và API.
- [ ] Hai người cùng nhóm duyệt cùng việc: người sau nhận thông báo đã xử lý.
- [ ] Số đếm trên sidebar khớp số việc tab "Chờ tôi".
- [ ] Sau quyết định, khung chi tiết tự chuyển sang việc kế tiếp và focus vào tiêu đề việc.

**Sai lầm thường gặp.** Hộp việc riêng cho mỗi phân hệ; nút "Duyệt" một chạm không cần ý kiến; chỉ hiện mã đối tượng mà không có nội dung cần duyệt; không phân biệt việc của cá nhân và việc của nhóm.

### 4.14. PTN-11 · Giám sát thời gian thực và tra log

**Mục đích.** Cho người dùng khám phá khối lượng lớn sự kiện theo thời gian (log, trace, bản ghi kiểm toán, lượt gọi API) bằng khoảng thời gian và truy vấn, xem chi tiết từng sự kiện và theo dõi trực tiếp khi cần.

**Khi dùng.** Tra log, truy vết, nhật ký kiểm toán, trạng thái nút gateway, sandbox của cổng. **Khi không dùng.** Tập dữ liệu nghiệp vụ có phân trang thông thường (PTN-01).

**Ví dụ trong Datahub.** Tra log PH-13 (`/giam-sat/log`); truy vết theo `trace_id` (`/giam-sat/truy-vet/{trace-id}` với biểu đồ dải thời gian các span); nhật ký kiểm toán (`/giam-sat/kiem-toan`, xuất bằng chứng); nút gateway PH-03.

**Sơ đồ vùng.**

```text
┌ main (toàn chiều rộng) ───────────────────────────────────────────────────────┐
│ ① PageHeader: "Tra log"                     [Lưu truy vấn] [Xuất] [⋯]         │
│ ┌ ② Thanh truy vấn (đặc) ───────────────────────────────────────────────────┐ │
│ │ [Khoảng: 1 giờ qua ▾] [ trace_id:… AND muc:loi AND dich-vu:dh-runtime   ] │ │
│ │ [Dịch vụ ▾][Mức ▾][HTTT ▾]                     [▶ Chạy] [● Trực tiếp: Tắt]│ │
│ └───────────────────────────────────────────────────────────────────────────┘ │
│ ┌ ③ Biểu đồ histogram theo thời gian (đặc, cao 120px, kéo chọn để thu hẹp) ─┐ │
│ └───────────────────────────────────────────────────────────────────────────┘ │
│ ┌ ④ LogViewer ảo hóa (đặc, mono) ───────────────┐ ┌ ⑤ Chi tiết sự kiện ─────┐ │
│ │ 21/11 14:05:32.120  LỖI  dh-runtime  Gọi …    │ │ JsonViewer              │ │
│ │ 21/11 14:05:32.118  TT   apisix      200 …    │ │ trace_id [⧉] [Mở trace] │ │
│ │ … (hàng triệu dòng, cuộn ảo)                  │ │ Ngữ cảnh ±50 dòng       │ │
│ └───────────────────────────────────────────────┘ └─────────────────────────┘ │
└───────────────────────────────────────────────────────────────────────────────┘
```

**Thành phần.** `CMP-DateRangePicker` (có lựa chọn tương đối), `CMP-SearchField` biến thể truy vấn (có tô màu cú pháp và gợi ý trường), `CMP-Select`, `CMP-Chart` (histogram), `CMP-LogViewer` (ảo hóa, `font-mono-sm`), `CMP-JsonViewer`, `CMP-CopyButton`, `CMP-Switch` (trực tiếp). Mọi vùng đặc; chữ log dùng màu chữ tiêu chuẩn, mức log thể hiện bằng nhãn chữ ("LỖI", "CẢNH BÁO", "TT", "GỠ LỖI") cộng màu.

**Hành vi.**

1. *Khoảng thời gian* luôn bắt buộc, mặc định 1 giờ qua; khoảng tối đa theo loại dữ liệu (log 7 ngày một lần truy vấn, kiểm toán 31 ngày) để bảo vệ máy chủ; vượt thì gợi ý thu hẹp. Thời gian hiển thị theo Asia/Ho_Chi_Minh đến mili giây; tooltip hiển thị UTC.
2. *Truy vấn* có cú pháp đơn giản `trường:giá-trị`, `AND`/`OR`/`NOT`, dấu ngoặc kép cho cụm từ; gợi ý trường và giá trị khi gõ; lỗi cú pháp chỉ vị trí lỗi. Toàn bộ truy vấn và khoảng nằm trên URL (trừ giá trị nhạy cảm, mục 2.4).
3. *Ảo hóa.* `CMP-LogViewer` chỉ dựng các dòng trong khung nhìn; tải thêm theo con trỏ (cursor) khi cuộn tới cuối, không dùng phân trang số. Dòng dài cắt một dòng, bấm để mở chi tiết ở khung ⑤.
4. *Histogram* thể hiện số sự kiện theo khoảng; kéo chọn một đoạn (hoặc dùng ô nhập thời gian, phương án không kéo) để thu hẹp khoảng.
5. *Trực tiếp (live tail)* bật bằng công tắc: sự kiện mới chèn ở đầu, tối đa 1.000 dòng trong bộ nhớ; cuộn khỏi đầu tự tạm dừng chèn và hiện nút "{n} sự kiện mới · Về đầu"; không đẩy sự kiện vào vùng `aria-live`. Trực tiếp tự tắt sau 15 phút không tương tác.
6. *Che dữ liệu.* Giá trị trường mức Nhạy cảm đã được che ở nguồn (NFR-00-029); giao diện không có nút "hiện" cho log vận hành. Nhật ký kiểm toán hiển thị giá trị trước/sau đã che (FR-00-041).
7. *Nhật ký kiểm toán* có thêm hành động "Xuất bằng chứng" (gói tệp có chuỗi băm) và "Kiểm tra toàn vẹn"; không có hành động sửa/xóa (FR-00-042).
8. *Truy vết.* Trang trace hiển thị biểu đồ dải (waterfall) các span theo thời gian, cây span bên trái, chi tiết span bên phải; mọi `trace_id` trong ứng dụng (thông báo lỗi, log) là liên kết tới trang này.

**Trạng thái cụ thể.** Không có kết quả: "Không có sự kiện nào khớp truy vấn trong {khoảng}" kèm gợi ý mở rộng khoảng. Truy vấn quá tải (máy chủ trả 429 hoặc hết thời gian): thông báo "Truy vấn trả về quá nhiều dữ liệu, hãy thu hẹp khoảng thời gian hoặc thêm điều kiện". Kết quả bị cắt: "Đang hiển thị 10.000 sự kiện đầu tiên".

**Phím tắt.** `/` focus ô truy vấn; `Enter` trong ô truy vấn chạy; `L` bật/tắt trực tiếp; `J`/`K` dòng kế/trước; `Enter` mở chi tiết dòng; `C` sao chép dòng.

**Tiêu chí nghiệm thu PTN-11.**

- [ ] Cuộn qua 1 triệu dòng mượt, bộ nhớ trình duyệt không vượt 300 MB.
- [ ] Truy vấn và khoảng thời gian trên URL; mở lại cho cùng kết quả.
- [ ] Trực tiếp tự tạm dừng khi người dùng cuộn khỏi đầu.
- [ ] Không có giá trị nhạy cảm chưa che xuất hiện trên giao diện log.
- [ ] Mức log có chữ, không chỉ màu.
- [ ] Nhật ký kiểm toán không có thao tác sửa/xóa; xuất bằng chứng kiểm tra được chuỗi băm.

**Sai lầm thường gặp.** Phân trang số cho log; không giới hạn khoảng thời gian; dùng `aria-live` cho luồng trực tiếp; hiển thị giờ UTC không ghi rõ; chỉ dùng màu cho mức log.

