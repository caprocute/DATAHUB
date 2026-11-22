---
ma_tai_lieu: D02-03-PH07
ten: Đặc tả chức năng phân hệ PH-07 Danh mục dùng chung
phien_ban: 0.1
ngay: 2026-11-21
trang_thai: Dự thảo
nguoi_doc: Chủ đầu tư, nhóm phân tích nghiệp vụ, kiến trúc sư, đội phát triển dh-data, đội kiểm thử, đội di trú dữ liệu
phan_he: PH-07
nguoi_lap: Nhóm phân hệ PH-07
---

# D02-03-PH07 · Đặc tả chức năng phân hệ PH-07 Danh mục dùng chung

## 1. Mục đích, phạm vi và người đọc

### 1.1. Mục đích

Tài liệu này đặc tả đầy đủ các yêu cầu chức năng (functional requirements) của phân hệ PH-07 Danh mục dùng chung (Reference Data Management, viết tắt RDM) thuộc sản phẩm Datahub, nền tảng tích hợp và chia sẻ dữ liệu cấp tỉnh thế hệ mới thay thế LGSP cũ. Mục tiêu của tài liệu là để đội phát triển có thể lập trình ngay mà không phải đoán ý nghiệp vụ, để đội kiểm thử có thể viết ca kiểm thử dương tính và âm tính cho từng yêu cầu, và để chủ đầu tư có căn cứ nghiệm thu từng chức năng so với hệ cũ Aita Information.

Mỗi yêu cầu chức năng được viết theo mẫu thống nhất tại [D00-01 §4.3](../../00-chung/D00-01-thuat-ngu-quy-uoc.md), dùng kiểu dữ liệu chuẩn `T-*` tại D00-01 §5 và hệ mã truy vết tại D00-01 §3. Các chức năng dùng chung cho mọi phân hệ (xác thực, phân trang, xuất nhập chung, kiểm toán, thông báo, hộp "Việc của tôi") đã được đặc tả ở [D02-02 SRS §4](../D02-02-srs.md); tài liệu này chỉ ghi "Tuân thủ FR-00-nnn" và không viết lại, nhằm tránh hai nguồn sự thật mâu thuẫn nhau.

### 1.2. Phạm vi

Phạm vi của PH-07 gồm toàn bộ vòng đời của danh mục dùng chung trong Datahub: khai báo danh mục và lược đồ thuộc tính động; soạn bản nháp; nhập xuất Excel, CSV và API; kiểm tra hợp lệ; so sánh khác biệt; trình duyệt, phê duyệt và phát hành phiên bản có hiệu lực theo khoảng ngày; cung cấp dữ liệu danh mục cho các hệ thống thông tin (HTTT) qua API tra cứu, API truy vấn có cấu trúc, ảnh chụp tệp và sự kiện; đồng bộ với danh mục dùng chung quốc gia qua Nền tảng tích hợp, chia sẻ dữ liệu quốc gia (NDXP) thông qua PH-14; ánh xạ mã giữa danh mục và hệ thống mã ngoài; quản lý danh mục đơn vị hành chính (ĐVHC) theo mô hình chính quyền hai cấp từ ngày 01/7/2025 kèm lịch sử ba cấp và công cụ chuyển mã; chia sẻ danh mục toàn quốc giữa các tenant; và di trú dữ liệu từ hệ cũ Aita.

Ngoài phạm vi của tài liệu này là dữ liệu chủ (công dân, tổ chức, địa chỉ) thuộc PH-06, quy tắc chất lượng dữ liệu thuộc PH-08, chuyển đổi định dạng bản tin trong luồng tích hợp thuộc PH-04 (PH-04 chỉ gọi API chuyển mã của PH-07), và cơ chế kết nối kỹ thuật với NDXP thuộc PH-14 (PH-07 chỉ gọi qua cổng tiếp hợp mà PH-14 cung cấp).

### 1.3. Người đọc và cách đọc

Bảng sau giúp từng nhóm người đọc biết phần nào của tài liệu là trọng tâm với mình, để không phải đọc tuần tự hơn ba nghìn dòng.

| Người đọc | Phần nên đọc kỹ | Mục đích sử dụng |
|---|---|---|
| Chủ đầu tư, lãnh đạo Sở | Mục 2, mục 3, mục 9, mục 11 | Xác nhận phạm vi, đối chiếu với hệ cũ, trả lời câu hỏi mở |
| Phân tích nghiệp vụ, chủ sản phẩm | Toàn bộ, đặc biệt mục 4, 5, 6 | Làm cơ sở cho use case D02-04-PH07 và user story D02-05-PH07 |
| Kiến trúc sư, trưởng nhóm phát triển | Mục 4, 5, 7, 8, 10 | Thiết kế SDD D03-02-PH07, CSDL D03-03-PH07, API D03-04-PH07 |
| Lập trình viên backend `dh-data` | Mục 5 (từng FR), mục 6, mục 8 | Lập trình, viết kiểm thử đơn vị |
| Lập trình viên giao diện `dh-console` | Mục 4, mục 5 nhóm A, B, C, G | Màn hình D03-06-PH07 |
| Kiểm thử viên | Mục 5 (ngoại lệ, hậu điều kiện), mục 6, mục 7 | Ca kiểm thử D05-02-PH07 |
| Đội di trú | Mục 2.2, FR-07-051, mục 6 | Kịch bản di trú Aita |

### 1.4. Tài liệu liên quan

Các tài liệu dưới đây là nền tảng hoặc tài liệu anh em của FRS này; khi có mâu thuẫn, thứ tự ưu tiên là D02-08 và D02-07 (tài liệu chung đã ban hành), sau đó tới FRS này, sau đó tới tài liệu thiết kế.

| Mã | Tài liệu | Quan hệ |
|---|---|---|
| D00-01 | [Thuật ngữ và quy ước chung](../../00-chung/D00-01-thuat-ngu-quy-uoc.md) | Mẫu FR, kiểu dữ liệu, quy ước đặt tên |
| D00-03 | [Ma trận truy vết](../../00-chung/D00-03-ma-tran-truy-vet.md) | Nguồn của các mục LGC-DMDC-001…019, LGC-NGSP-006, LGC-BUS-036 |
| D02-01 | [BRD](../D02-01-brd.md) | REQ-07, REQ-20, REQ-22, BP-03, BP-08, BO-05, KPI-10, KPI-11 |
| D02-02 | [SRS chung](../D02-02-srs.md) | FR-00 và NFR-00 dùng chung |
| D02-07 | [Từ điển dữ liệu chung](../D02-07-tu-dien-du-lieu.md) | DD-07 ĐVHC, DD-11 outbox, DD-12 tệp, DD-14 tham số |
| D02-08 | [Ma trận phân quyền](../D02-08-ma-tran-phan-quyen.md) | Vai trò và quyền PERM-07 |
| D03-01 | [SAD](../../03-thiet-ke/D03-01-sad.md) | Phân loại dữ liệu §8.2, outbox §7.3, quy ước API §7.2 |
| D03-10 | [Thiết kế đa tenant](../../03-thiet-ke/D03-10-thiet-ke-da-tenant.md) | RLS, tenant `COMMON` và `PLATFORM` |
| D02-06-PH07 | [DFD PH-07](../dfd/D02-06-PH07-dfd-danh-muc.md) | Luồng dữ liệu của chính các FR trong tài liệu này |
| D02-04-PH07 | [Use case PH-07](../use-case/D02-04-PH07-use-case-danh-muc.md) | Kịch bản người dùng |
| D02-05-PH07 | [User story PH-07](../user-story/D02-05-PH07-user-story-danh-muc.md) | Hạng mục tồn đọng |
| D03-02-PH07 | [SDD PH-07](../../03-thiet-ke/sdd/D03-02-PH07-sdd-danh-muc.md) | Thiết kế chi tiết |
| D03-03-PH07 | [CSDL PH-07](../../03-thiet-ke/csdl/D03-03-PH07-csdl-danh-muc.md) | Bảng EN-07-01…19 |
| D03-04-PH07 | [API PH-07](../../03-thiet-ke/api/D03-04-PH07-api-danh-muc.md) | API-07-001…076, EVT-07-01…10, ERR-07 |
| D03-06-PH07 | [Màn hình PH-07](../../03-thiet-ke/uiux/D03-06-PH07-man-hinh-danh-muc.md) | UI-07-01…13 |
| D05-02-PH07 | [Ca kiểm thử PH-07](../../05-kiem-thu/test-case/D05-02-PH07-test-case.md) | TC-07 |
| ADR-050…057 | Quyết định kiến trúc PH-07 | Thuộc tính động jsonb, phiên bản copy-on-write, HYBRID, phân phối, DSL truy vấn, ĐVHC, nhập tệp, đồng bộ quốc gia |

### 1.5. Quy ước riêng của tài liệu

Trong tài liệu này, "danh mục" (tiếng Anh dùng trong mã nguồn là *catalog*) là một tập mã có cấu trúc dùng chung, ví dụ danh mục dân tộc hay danh mục ĐVHC; "bản ghi" (*item*) là một dòng của danh mục, có mã, tên và các thuộc tính; "phiên bản" (*version*) là một ảnh chụp đầy đủ của danh mục gồm lược đồ và bản ghi. Ký hiệu `{c}` trong đường dẫn API là mã danh mục, `{v}` là số phiên bản hoặc các từ khóa `current` (phiên bản đang hiệu lực) và `draft` (phiên bản đang mở). Thời điểm hiển thị theo giờ Việt Nam (UTC+7); mọi phép so sánh ngày hiệu lực dùng ngày theo giờ Việt Nam trừ khi ghi khác. Mọi ví dụ dùng tenant giả lập `T68` (Lâm Đồng) và người dùng giả lập; không có dữ liệu cá nhân thật.

## 2. Bối cảnh nghiệp vụ

### 2.1. Vai trò của danh mục dùng chung trong Datahub

Danh mục dùng chung là "từ vựng" mà các HTTT của tỉnh dùng để hiểu nhau. Khi hệ thống một cửa điện tử gửi hồ sơ sang hệ thống quản lý văn bản, trường "dân tộc" chỉ có nghĩa nếu hai bên dùng cùng một bảng mã dân tộc; trường "nơi cư trú" chỉ có nghĩa nếu hai bên dùng cùng một bảng mã ĐVHC và cùng hiểu mã đó tại cùng một thời điểm. Nếu mỗi hệ thống giữ một bản danh mục riêng và tự cập nhật, sai lệch sẽ phát sinh ngay sau lần thay đổi đầu tiên, và việc đối chiếu dữ liệu giữa các hệ thống trở thành công việc thủ công tốn kém. Vì lý do đó, BRD đặt mục tiêu BO-05 "Danh mục dùng chung thống nhất, đồng bộ với quốc gia", đo bằng KPI-10 (100% danh mục bắt buộc được quản lý tập trung và có phiên bản) và KPI-11 (độ trễ đồng bộ danh mục quốc gia sau khi quốc gia ban hành không quá 24 giờ).

PH-07 vì vậy vừa là công cụ quản trị cho cán bộ quản lý danh mục, vừa là dịch vụ cung cấp dữ liệu tham chiếu có độ sẵn sàng cao cho mọi HTTT và cho các phân hệ khác của Datahub. PH-04 (luồng tích hợp) và runtime `dh-runtime` tra mã danh mục trong lúc chuyển đổi bản tin; PH-20 dùng danh mục ĐVHC để khai báo tenant và tổ chức; PH-08 dùng danh mục làm miền giá trị cho quy tắc chất lượng. Do đó yêu cầu về hiệu năng và tính sẵn sàng của phần khai thác (nhóm D) cao hơn hẳn phần quản trị, và thiết kế phân phối qua bộ đệm và ảnh chụp (ADR-053) là hệ quả trực tiếp.

### 2.2. Hệ cũ Aita Information và các hạn chế

Hệ cũ Aita Information (do nhà thầu trước xây dựng năm 2021, chạy trên Spring Boot với giao diện Angular) quản lý danh mục theo mô hình thực thể – thuộc tính – giá trị (Entity–Attribute–Value, EAV) gồm bốn bảng. Bảng dưới đây tóm tắt cấu trúc thực tế của bốn bảng đó, được đối chiếu giữa tài liệu thiết kế CSDL v1.1 và các câu lệnh SQL trong tài liệu thiết kế chi tiết v1.7; hai tài liệu không khớp nhau ở một số cột, và cột thực tế là cột xuất hiện trong câu lệnh SQL.

| Bảng Aita | Cột thực tế | Ý nghĩa | Ghi chú đối chiếu |
|---|---|---|---|
| `category` | `id int(10)`, `name varchar(500)`, `category_code varchar(500)`, `is_update int(10)` | Danh mục | `is_update = 1` nghĩa là danh mục được cập nhật từ NGSP; giá trị khác là danh mục tạo tại chỗ hoặc đã sửa |
| `category_fields` | `id`, `category_id`, `name varchar(1000)`, `data`, `jhi_order`, `status int(10)` | Thuộc tính của danh mục | Tài liệu CSDL ghi cột `Order`; SQL dùng `jhi_order`; cột `data` không được mô tả ý nghĩa |
| `category_details` | `id`, `category_id` | Bản ghi (chỉ là một định danh, không có mã, không có tên) | Mã và tên bản ghi nằm trong các giá trị |
| `category_details_value` | `id`, `category_id` (theo tài liệu CSDL), `category_details_id`, `category_fields_id`, `value varchar(2000)` | Giá trị của một thuộc tính trên một bản ghi | Tài liệu CSDL thiếu cột `category_fields_id`; SQL thực tế có cột này |

Mô hình này linh hoạt ở chỗ cho phép mỗi danh mục có bộ thuộc tính tùy ý, nhưng có các hạn chế nghiêm trọng đã được nêu trong BRD và kiểm kê LGC-DMDC. Thứ nhất, mọi giá trị là chuỗi tối đa 2.000 ký tự, không có kiểu dữ liệu, không có ràng buộc bắt buộc, duy nhất hay miền giá trị, nên dữ liệu sai lọt vào mà không bị phát hiện. Thứ hai, bản ghi không có mã nghiệp vụ riêng; "mã" chỉ là giá trị của một thuộc tính mà người dùng quy ước, nên không có gì bảo đảm mã là duy nhất. Thứ ba, không có phiên bản và ngày hiệu lực: sửa một bản ghi là ghi đè, xóa là mất hẳn, nên không trả lời được câu hỏi "tại ngày 15/3/2025 mã này có nghĩa là gì", trong khi đây là câu hỏi bắt buộc với dữ liệu ĐVHC sau sắp xếp năm 2025. Thứ tư, không có quy trình duyệt, ai có quyền sửa là sửa thẳng vào dữ liệu đang được các HTTT dùng. Thứ năm, đồng bộ với danh mục quốc gia qua NGSP là thao tác thủ công, cờ `is_update` chỉ cho biết nguồn chứ không ngăn sửa. Thứ sáu, truy vấn theo giá trị thuộc tính phải nối bảng giá trị nhiều lần (mỗi thuộc tính một lần nối), hiệu năng kém khi danh mục lớn. Cuối cùng, khuôn tệp nhập rất cứng (ô A2 là tên danh mục, dòng 4 từ ô B4 là tên thuộc tính, từ dòng 5 là bản ghi, CSV phải mã hóa UTF-16) và không có bước xem trước lỗi, nên một dòng sai làm hỏng cả lần nhập hoặc tệ hơn là ghi một phần.

Các chức năng của Aita được kiểm kê thành 19 mục LGC-DMDC-001…019 trong D00-03 §4.5; cộng với LGC-NGSP-006 (kết nối danh mục quốc gia qua NGSP) và một phần LGC-BUS-036 (chuyển đổi ngữ nghĩa dữ liệu trong luồng). Mục 9 của tài liệu này chứng minh mọi mục LGC đều được ít nhất một FR phủ.

### 2.3. Yêu cầu mới

Ngoài việc thay thế đầy đủ chức năng của Aita, PH-07 đáp ứng các yêu cầu mới sau, mỗi yêu cầu xuất phát từ một nhu cầu nghiệp vụ cụ thể. Danh mục có lược đồ thuộc tính có kiểu, ràng buộc, kiểm tra theo JSON Schema, để dữ liệu sai bị chặn ngay khi nhập. Danh mục có phiên bản bất biến và hiệu lực theo khoảng ngày, để mọi HTTT tra được ý nghĩa của mã tại bất kỳ thời điểm nào và để kiểm toán truy ngược được ai đã thay đổi gì. Thay đổi đi qua bản nháp, so sánh khác biệt và duyệt bốn mắt, để không còn tình trạng sửa thẳng vào dữ liệu đang dùng (quy trình BP-03 của BRD). Nhập tệp chạy nền, có xem trước và báo lỗi theo dòng, cột, ghi theo kiểu tất cả hoặc không (FR-00-032). Danh mục quốc gia được đồng bộ tự động, phát hiện thay đổi trong 24 giờ, thay đổi phá vỡ phải được con người xác nhận. Có bảng ánh xạ mã giữa danh mục chuẩn và mã riêng của từng HTTT, để luồng tích hợp chuyển mã tự động thay vì viết cứng trong mã nguồn. Có API truy vấn có cấu trúc thay cho "API truy vấn CSDL tùy chọn" của Aita (LGC-DMDC-016), vì cho phép chạy câu SQL tự do là lỗ hổng an toàn thông tin nghiêm trọng.

### 2.4. Sắp xếp đơn vị hành chính năm 2025

Năm 2025, Việt Nam thực hiện sắp xếp ĐVHC quy mô lớn và chuyển sang mô hình chính quyền địa phương hai cấp (tỉnh và xã), bỏ cấp huyện. Theo Nghị quyết số 202/2025/QH15 về sắp xếp ĐVHC cấp tỉnh, cả nước còn 34 đơn vị hành chính cấp tỉnh (28 tỉnh và 6 thành phố trực thuộc trung ương). Các nghị quyết của Ủy ban Thường vụ Quốc hội năm 2025 sắp xếp ĐVHC cấp xã của từng tỉnh, và Quyết định số 19/2025/QĐ-TTg của Thủ tướng Chính phủ ban hành Bảng danh mục và mã số ĐVHC Việt Nam với 3.321 đơn vị cấp xã, hiệu lực từ ngày 01/7/2025. Mã cấp tỉnh có hai chữ số, mã cấp xã có năm chữ số.

> **Câu hỏi mở Q07-01:** Số hiệu, ngày ban hành và ngày hiệu lực của Nghị quyết 202/2025/QH15, Quyết định 19/2025/QĐ-TTg và danh sách các nghị quyết của UBTVQH về sắp xếp cấp xã cần được đối chiếu với Công báo trước khi phát hành bản 1.0; đồng thời cần xác nhận tổng số 3.321 đơn vị cấp xã là số tại ngày 01/7/2025 hay đã có điều chỉnh sau đó.

Sự kiện này có ba hệ quả trực tiếp cho PH-07. Thứ nhất, danh mục ĐVHC phải giữ được cả cấu trúc ba cấp cũ (tỉnh, huyện, xã, trước 01/7/2025) và hai cấp mới, vì dữ liệu hồ sơ phát sinh trước ngày 01/7/2025 vẫn mang mã cũ và vẫn phải tra được tên, cấp hành chính tại thời điểm phát sinh. Thứ hai, phải ghi lại quan hệ kế thừa nhiều – nhiều giữa đơn vị cũ và đơn vị mới (một xã mới hình thành từ nhiều xã cũ, một xã cũ có thể bị chia về nhiều xã mới), kèm căn cứ pháp lý. Thứ ba, phải cung cấp công cụ chuyển mã cũ sang mới và tra ngược, và khi một mã cũ bị chia về nhiều đơn vị mới thì công cụ không được tự đoán mà phải trả về danh sách ứng viên để con người hoặc hệ thống nghiệp vụ quyết định dựa trên địa chỉ chi tiết. Bản thân tenant cũng chịu ảnh hưởng: các tỉnh sáp nhập kéo theo sáp nhập tenant (PH-20, BP-08), và danh mục địa phương của các tenant cũ phải được kế thừa.

### 2.5. Đa tenant và ba loại nguồn danh mục

Datahub phục vụ nhiều tỉnh trên một nền tảng (REQ-20). Theo D03-10, dữ liệu mỗi tỉnh được cách ly bằng cột `tenant_id` và chính sách bảo mật mức dòng (Row-Level Security, RLS) của PostgreSQL. Danh mục toàn quốc như ĐVHC, dân tộc, quốc tịch, giới tính và các danh mục đồng bộ từ NDXP không thuộc riêng tỉnh nào; chúng được lưu một lần với `tenant_id = 'COMMON'`, mọi tenant đọc được, và chỉ tenant `PLATFORM` (quản trị nền tảng) được ghi. Cách làm này tránh 34 bản sao của cùng một danh mục quốc gia, tránh sai lệch giữa các tỉnh, và giảm chi phí đồng bộ xuống còn một lần cho cả nước.

Tuy nhiên, tỉnh thường có nhu cầu bổ sung mã địa phương vào danh mục quốc gia (ví dụ bổ sung loại hình đặc thù chưa có trong danh mục quốc gia). Nếu cho tỉnh sửa trực tiếp danh mục `COMMON` thì phá vỡ tính thống nhất; nếu bắt tỉnh sao chép sang danh mục riêng thì mất liên kết với bản quốc gia khi quốc gia cập nhật. Giải pháp (ADR-052) là danh mục HYBRID: tenant tỉnh tạo danh mục có `source_type = HYBRID`, `extends_catalog_id` trỏ tới danh mục `COMMON`, và chỉ chứa các bản ghi bổ sung có mã thuộc dải mã địa phương (`local_code_pattern`). Khi tra cứu, PH-07 trả về hợp của phiên bản `COMMON` đang hiệu lực và các bản ghi bổ sung, nên HTTT thấy một danh mục liền mạch. Ba loại nguồn được định nghĩa như sau: `LOCAL` là danh mục tỉnh tự quản hoàn toàn; `NATIONAL` là danh mục đồng bộ từ NDXP, chỉ đọc với người dùng và chỉ được cập nhật qua đồng bộ; `HYBRID` là danh mục mở rộng một danh mục `COMMON` hoặc `NATIONAL`.

## 3. Tác nhân, vai trò và quyền

### 3.1. Tác nhân

PH-07 có tác nhân con người và tác nhân máy. Bảng dưới liệt kê từng tác nhân, vai trò tương ứng theo [D02-08](../D02-08-ma-tran-phan-quyen.md) và công việc điển hình của họ trong PH-07.

| Tác nhân | Vai trò D02-08 | Phạm vi | Công việc điển hình trong PH-07 |
|---|---|---|---|
| Cán bộ quản lý danh mục của sở, ngành | `ROLE-DATA_STEWARD` (DS) | Tổ chức hoặc tenant; ký hiệu ○ nghĩa là chỉ trên danh mục có `owner_org_id` là tổ chức của mình | Tạo danh mục, khai báo lược đồ, soạn bản nháp, nhập xuất tệp, ghi ánh xạ, trình duyệt |
| Lãnh đạo phòng, đơn vị duyệt danh mục | `ROLE-DATA_APPROVER` (DA) | Tenant | Xem khác biệt, duyệt hoặc từ chối, phát hành; chạy và xác nhận đồng bộ quốc gia |
| Quản trị Datahub của tỉnh | `ROLE-TENANT_ADMIN` (TA) | Tenant | Quản lý mọi danh mục trong tenant (trừ duyệt, phát hành), ngừng hiệu lực, cấu hình tham số, cấp quyền khai thác danh mục hạn chế |
| Quản trị nền tảng | `ROLE-PLATFORM_ADMIN` (PA) | Tenant `PLATFORM`, ghi danh mục `COMMON` | Quản lý và phát hành danh mục `COMMON`, ĐVHC, đồng bộ quốc gia cho `COMMON`, nạp gói danh mục nền cho tenant mới, chạy di trú |
| Kỹ sư tích hợp | `ROLE-INTEGRATION_ENGINEER` (IE) | Tenant hoặc không gian làm việc | Xem danh mục và lược đồ, thử API tra cứu và truy vấn, quản lý ánh xạ mã dùng trong luồng |
| Nhà phát triển | `ROLE-DEVELOPER` | Ứng dụng được giao | Đọc tài liệu, lược đồ, thử API trên cổng nhà phát triển |
| Người xem | `ROLE-VIEWER` (VW) | Tenant | Xem, xuất danh mục |
| Kiểm toán, thanh tra | `ROLE-AUDITOR` (AU) | Tenant, chỉ đọc | Xem lịch sử thay đổi, xuất bằng chứng |
| HTTT thành viên (máy) | Client OAuth2 `client_credentials`, scope `rdm.read`, `rdm.query`, `rdm.write` | Tenant của HTTT | Tra cứu, truy vấn, tải ảnh chụp, nhận sự kiện, nhập lô vào bản nháp |
| PH-14 Kết nối quốc gia | Dịch vụ nội bộ | Nền tảng | Cổng tiếp hợp NDXP danh mục dùng chung |
| PH-20 Quản lý tenant | Dịch vụ nội bộ | Nền tảng | Gọi nạp gói danh mục nền khi khởi tạo tenant |
| Bộ lập lịch PH-07 | Tác vụ nền | Theo tenant | Chạy đồng bộ định kỳ, dọn bảng tạm, hết hạn tác vụ nhập |

### 3.2. Quyền PH-07 theo D02-08

Bảng dưới đây trích ma trận D02-08 §3.1 cho PH-07 và giải thích ý nghĩa nghiệp vụ của từng quyền khi áp vào các FR. Ký hiệu ● là được phép trong phạm vi vai trò, ○ là chỉ với danh mục do tổ chức mình làm chủ, — là không được phép.

| Quyền | Ý nghĩa trong PH-07 | PA | TA | DS | DA | IE | VW | AU | Các vai trò khác |
|---|---|---|---|---|---|---|---|---|---|
| `PERM-07-read` | Xem danh mục, lược đồ, phiên bản, bản ghi, tác vụ, lần đồng bộ, ánh xạ, lịch sử | ● | ● | ● | ● | ● | ● | ● | ● |
| `PERM-07-create` / `PERM-07-update` | Tạo, sửa danh mục, nhóm, lược đồ, bản ghi trên bản nháp, nhập tệp, nhập lô, ghi sự kiện sắp xếp ĐVHC, hủy bản nháp | ● (COMMON) | ● | ○ | — | — | — | — | — |
| `PERM-07-submit` | Trình duyệt phiên bản | ● (COMMON) | ● | ○ | — | — | — | — | — |
| `PERM-07-publish` | Duyệt và phát hành phiên bản (gồm phát hành thẳng khi không cần duyệt) | ● (COMMON) | — | — | ● | — | — | — | — |
| `PERM-07-export` | Xuất danh mục ra tệp | ● | ● | ● | ● | ● | ● | ● | ● |
| `PERM-07-sync` | Cấu hình nguồn, chạy đồng bộ, xác nhận hoặc từ chối thay đổi từ nguồn quốc gia | ● | ● | — | ● | — | — | — | — |

Ma trận này có hai điểm cần lưu ý. Thứ nhất, `ROLE-TENANT_ADMIN` không có `PERM-07-publish`: quản trị tỉnh quản lý được mọi danh mục nhưng không tự phát hành, vì phát hành là quyết định nghiệp vụ thuộc người duyệt danh mục. Thứ hai, D02-08 §4 cấm gán đồng thời DATA_STEWARD và DATA_APPROVER cho cùng một người trong cùng tenant; ngoài ra nguyên tắc bốn mắt (FR-00-071) áp dụng cho từng phiên bản: người có `PERM-07-publish` không được duyệt hoặc phát hành phiên bản do chính mình trình hoặc chính mình sửa lần cuối (BR-07-011).

### 3.3. Quyền đề xuất bổ sung D02-08

Một số thao tác của PH-07 chưa có quyền tương ứng trong D02-08. Nhóm PH-07 đề xuất bổ sung các quyền sau vào D02-08; trong thời gian chờ luồng lõi gộp, mã nguồn kiểm tra đúng các mã quyền này để không phải sửa lại khi D02-08 được cập nhật.

| Quyền đề xuất | Ý nghĩa | PA | TA | DS | DA | IE | Lý do đề xuất |
|---|---|---|---|---|---|---|---|
| `PERM-07-retire` | Ngừng hiệu lực danh mục đã phát hành | ● (COMMON) | ● | — | — | — | Thao tác ảnh hưởng mọi HTTT đang dùng, cần tách khỏi quyền sửa thông thường (đề xuất bổ sung D02-08) |
| `PERM-07-mapping` | Quản lý hệ thống mã ngoài và bảng ánh xạ mã | ● | ● | ● | — | ● | Kỹ sư tích hợp là người hiểu mã của HTTT nhưng không có quyền sửa danh mục (đề xuất bổ sung D02-08) |
| `PERM-07-grant` | Cấp, thu hồi quyền khai thác danh mục `RESTRICTED` cho HTTT | ● | ● | — | — | — | Là quyết định kiểm soát truy cập, thuộc quản trị tỉnh (đề xuất bổ sung D02-08) |
| `PERM-07-configure` | Đọc, ghi tham số `07.rdm.*` của tenant qua PH-18 | ● | ● | — | — | — | Tham số ảnh hưởng chính sách duyệt (đề xuất bổ sung D02-08) |
| `PERM-07-sync` cho DS (○) | Cho DS chạy đồng bộ theo yêu cầu và xem khác biệt với danh mục mình làm chủ, nhưng không xác nhận thay đổi phá vỡ | — | — | ○ | — | — | Khung PH-07 ban đầu giao đồng bộ cho DS; D02-08 hiện chỉ cho PA, TA, DA (đề xuất bổ sung D02-08, xem Q07-02) |

> **Câu hỏi mở Q07-02:** D02-08 không cấp `PERM-07-sync` cho DATA_STEWARD, trong khi thực tế người theo dõi danh mục quốc gia hằng ngày là cán bộ quản lý danh mục. Đề nghị chủ đầu tư quyết định có cấp `PERM-07-sync` phạm vi ○ cho DS (chỉ chạy và xem, không xác nhận thay đổi phá vỡ) hay giữ như D02-08. Trong khi chờ, FRS này theo D02-08.

### 3.4. Scope của HTTT thành viên

HTTT gọi PH-07 bằng token `client_credentials` hoặc mTLS qua gateway. Bảng dưới đây định nghĩa ba scope và điều kiện cấp; scope được sinh tự động theo D02-08 §5, không cấp tay.

| Scope | Cho phép | Được cấp khi |
|---|---|---|
| `rdm.read` | API-07-033, 041…046, 048…050 (danh sách danh mục, tra một mã, tra lô, lấy toàn bộ, cây, tìm kiếm, delta, lược đồ, ảnh chụp, dòng lịch sử), API-07-051 (chuyển mã ĐVHC), API-07-070 (chuyển mã ánh xạ) | Mặc định cho mọi HTTT `ACTIVE` |
| `rdm.query` | API-07-047 (truy vấn có cấu trúc) | Khi HTTT đăng ký sử dụng API truy vấn danh mục được duyệt ở PH-02 |
| `rdm.write` | API-07-031 (nhập lô vào bản nháp của danh mục được giao) | Khi HTTT được khai báo là nguồn dữ liệu của một danh mục cụ thể; chỉ ghi bản nháp, không trình, không phát hành |

> **Câu hỏi mở Q07-03:** D02-08 §5 viết scope dạng `rdm:read` (dấu hai chấm), còn khung PH-07 thống nhất dạng `rdm.read`. Cần luồng lõi chốt một ký pháp duy nhất cho toàn bộ scope của Datahub; FRS này dùng `rdm.read`, `rdm.query`, `rdm.write`.

## 4. Khái niệm và mô hình nghiệp vụ

### 4.1. Tổng quan mô hình

Sơ đồ dưới đây trình bày các khái niệm nghiệp vụ chính của PH-07 và quan hệ giữa chúng. Sơ đồ ở mức nghiệp vụ, không phải lược đồ CSDL; mỗi khái niệm được ghi kèm mã thực thể EN tương ứng để người đọc tra sang D03-03-PH07.

```mermaid
classDiagram
    direction LR
    class NhomDanhMuc["Nhóm danh mục (EN-07-01)"]
    class DanhMuc["Danh mục (EN-07-02)"]
    class PhienBan["Phiên bản (EN-07-03)"]
    class ThuocTinh["Định nghĩa thuộc tính (EN-07-04)"]
    class BanGhi["Bản ghi (EN-07-05)"]
    class KeThua["Sự kiện sắp xếp / kế thừa (EN-07-06)"]
    class Duyet["Lịch sử duyệt (EN-07-07)"]
    class TacVu["Tác vụ nhập xuất (EN-07-08)"]
    class NguonDB["Nguồn đồng bộ (EN-07-10)"]
    class LanDB["Lần đồng bộ (EN-07-11)"]
    class HeMa["Hệ thống mã ngoài (EN-07-13)"]
    class AnhXa["Ánh xạ mã (EN-07-14)"]
    class CapQuyen["Cấp quyền khai thác (EN-07-15)"]
    class DVHC["Chiếu ĐVHC admin_unit (EN-07-18)"]
    NhomDanhMuc "1" o-- "0..*" DanhMuc
    NhomDanhMuc "0..1" o-- "0..*" NhomDanhMuc : nhóm con
    DanhMuc "1" *-- "1..*" PhienBan
    DanhMuc "0..1" --> "0..1" DanhMuc : extends (HYBRID)
    PhienBan "1" *-- "0..*" ThuocTinh
    PhienBan "1" *-- "0..*" BanGhi
    PhienBan "1" *-- "0..*" KeThua
    PhienBan "1" *-- "0..*" Duyet
    BanGhi "0..*" --> "0..1" BanGhi : mã cha
    DanhMuc "1" o-- "0..*" TacVu
    DanhMuc "1" o-- "0..1" NguonDB
    NguonDB "1" *-- "0..*" LanDB
    HeMa "1" o-- "0..*" AnhXa
    DanhMuc "1" o-- "0..*" AnhXa
    DanhMuc "1" o-- "0..*" CapQuyen
    BanGhi ..> DVHC : chiếu khi phát hành DVHC
```

Sơ đồ cho thấy danh mục là trung tâm, nhưng đơn vị dữ liệu bất biến là phiên bản: thuộc tính, bản ghi, sự kiện kế thừa và lịch sử duyệt đều gắn với một phiên bản cụ thể chứ không gắn trực tiếp với danh mục. Đây là hệ quả của mô hình ảnh chụp đầy đủ (copy-on-write, ADR-051): khi tạo bản nháp mới, toàn bộ lược đồ và bản ghi của phiên bản hiện hành được sao chép sang phiên bản nháp, người dùng sửa trên bản sao, và phiên bản cũ không bao giờ bị động tới. Cách làm này tốn dung lượng hơn so với lưu khác biệt, nhưng đổi lại mọi phép tra cứu theo thời điểm chỉ là chọn đúng phiên bản rồi đọc thẳng, không phải dựng lại trạng thái từ chuỗi khác biệt; với quy mô danh mục (tối đa 200.000 bản ghi mỗi danh mục, NFR-07-011) chi phí lưu trữ là chấp nhận được. Các thực thể vận hành (tác vụ nhập xuất, nguồn và lần đồng bộ, ánh xạ, cấp quyền) gắn với danh mục, vì chúng tồn tại xuyên qua nhiều phiên bản.

### 4.2. Danh mục

Danh mục là một tập mã có cùng ý nghĩa nghiệp vụ, do một cơ quan chủ quản chịu trách nhiệm nội dung. Mỗi danh mục có mã (`code`, kiểu `T-CODE`, duy nhất trong tenant và không trùng mã danh mục `COMMON` đang hoạt động, BR-07-001), tên, mô tả, nhóm, cơ quan chủ quản (`owner_org_id`, tham chiếu logic tới tổ chức DD-02 của PH-20), nguồn (`source_type`), mức phân loại (`classification`), trạng thái (`status`), cấu hình phân cấp (`is_hierarchical`, `max_depth`, `level_names`), dải mã địa phương (`local_code_pattern`), danh mục gốc nếu là HYBRID (`extends_catalog_id`), chính sách duyệt (`require_approval`) và con trỏ tới phiên bản đang hiệu lực (`current_version_id`). Mã danh mục là định danh mà HTTT dùng trong đường dẫn API, nên mã không được đổi sau khi danh mục đã phát hành lần đầu (BR-07-040, đề xuất mới); đổi mã sẽ làm gãy mọi HTTT đang gọi.

### 4.3. Nhóm danh mục

Nhóm danh mục là cây phân loại giúp người dùng tìm danh mục trong danh sách hàng trăm danh mục, ví dụ nhóm "Hành chính" gồm nhóm con "Đơn vị hành chính", "Cơ quan nhà nước". Nhóm chỉ có ý nghĩa tổ chức hiển thị, không ảnh hưởng tới quyền hay tra cứu. Tenant `COMMON` có cây nhóm riêng cho danh mục toàn quốc; tenant tỉnh thấy cả cây nhóm `COMMON` (chỉ đọc) và cây nhóm của mình.

### 4.4. Lược đồ thuộc tính động và kiểu dữ liệu

Mỗi phiên bản có một lược đồ gồm các định nghĩa thuộc tính (`attribute_def`). Ngoài các trường hệ thống cố định (mã, tên, mã cha, thứ tự, trạng thái, mã thay thế, khoảng hiệu lực của bản ghi), mỗi danh mục có thể khai báo tối đa 100 thuộc tính động (NFR-07-011). Giá trị thuộc tính động được lưu trong cột `attrs` kiểu `jsonb` của bản ghi và được kiểm tra bằng JSON Schema sinh tự động từ lược đồ (ADR-050), thay cho mô hình EAV của Aita. Mã thuộc tính (`code`) là khóa trong `attrs`, viết theo dạng chữ thường có gạch dưới (snake_case, mẫu `^[a-z][a-z0-9_]{0,62}$`) để thuận tiện cho JSON; nhãn (`label`) là tên tiếng Việt hiển thị.

Bảng dưới đây định nghĩa mười một kiểu dữ liệu được phép cho thuộc tính động, cách biểu diễn trong JSON, cách nhập trong tệp và ràng buộc nào áp dụng được cho từng kiểu. Bảng này là căn cứ để sinh JSON Schema và để kiểm tra hợp lệ khi nhập tệp.

| Kiểu `data_type` | Ý nghĩa | Biểu diễn JSON | Cách ghi trong tệp nhập | Ràng buộc áp dụng được |
|---|---|---|---|---|
| `STRING` | Chuỗi ngắn một dòng | `string` | Văn bản | `max_length` (1…2.000, mặc định 255), `pattern`, `required`, `unique_in_version`, `default_value` |
| `TEXT` | Văn bản dài, nhiều dòng | `string` | Văn bản, cho phép xuống dòng | `max_length` (1…4.000, mặc định 4.000), `required` |
| `INTEGER` | Số nguyên 64 bit | `integer` | Chữ số, có thể có dấu trừ; không chấp nhận dấu phân cách hàng nghìn | `min_value`, `max_value`, `required`, `unique_in_version`, `default_value` |
| `DECIMAL` | Số thập phân chính xác | `string` theo mẫu số thập phân (tránh mất chính xác của số thực JSON) | Dấu chấm thập phân; trong xlsx chấp nhận ô kiểu số | `min_value`, `max_value`, `max_length` dùng làm tổng số chữ số (mặc định 19), `required` |
| `BOOLEAN` | Đúng hoặc sai | `boolean` | `TRUE`/`FALSE`, `Có`/`Không`, `1`/`0` (không phân biệt hoa thường) | `required`, `default_value` |
| `DATE` | Ngày | `string`, `format: date` (`yyyy-MM-dd`) | `dd/MM/yyyy` hoặc `yyyy-MM-dd`, hoặc ô kiểu ngày trong xlsx | `min_value`, `max_value` (dạng ngày), `required` |
| `DATETIME` | Thời điểm | `string`, `format: date-time`, lưu UTC | `dd/MM/yyyy HH:mm:ss` (hiểu là giờ Việt Nam) hoặc ISO 8601 có múi giờ | `min_value`, `max_value`, `required` |
| `ENUM` | Một giá trị trong tập liệt kê | `string`, `enum` | Mã giá trị (không phải nhãn); sheet `GiaTriHopLe` liệt kê | `enum_values` (mảng `{value, label}`, 1…500 phần tử), `required`, `default_value` |
| `CATALOG_REF` | Tham chiếu tới mã của một danh mục khác | `string` (mã bản ghi) | Mã bản ghi của danh mục được tham chiếu | `ref_catalog_code` (bắt buộc), `required`; giá trị phải tồn tại và `ACTIVE` trong phiên bản hiệu lực của danh mục đích tại ngày `effective_from` của phiên bản đang soạn |
| `URI` | Địa chỉ tài nguyên | `string`, `format: uri` | Văn bản | `max_length` (≤ 2.048), `required` |
| `EMAIL` | Địa chỉ thư điện tử của cơ quan | `string`, `format: email` | Văn bản | `required`; chỉ dùng cho hộp thư công vụ của cơ quan, không cho thư cá nhân (BR-07-025) |

Ý nghĩa của từng ràng buộc như sau. `required` bắt buộc mọi bản ghi `ACTIVE` phải có giá trị khác rỗng; bản ghi `DEPRECATED` được miễn để không chặn việc ngừng dùng bản ghi cũ thiếu dữ liệu. `unique_in_version` bắt buộc giá trị (sau khi chuẩn hóa: cắt khoảng trắng hai đầu, so sánh không phân biệt hoa thường với chuỗi) không trùng giữa các bản ghi trong cùng phiên bản, giá trị rỗng không tính là trùng. `max_length` giới hạn số ký tự Unicode (đếm theo điểm mã sau chuẩn hóa NFC), không phải số byte. `pattern` là biểu thức chính quy theo cú pháp ECMA-262 được neo hai đầu, độ dài biểu thức tối đa 500 ký tự, và được thử biên dịch khi khai báo để chặn biểu thức gây quay lui thảm họa (thời gian khớp thử trên chuỗi 2.000 ký tự phải dưới 50 ms). `min_value` và `max_value` là cận đóng. `enum_values` là danh sách giá trị cho phép, mỗi giá trị theo mẫu `T-CODE` và có nhãn tiếng Việt. `default_value` được điền khi bản ghi mới không có giá trị; giá trị mặc định phải tự hợp lệ với chính ràng buộc của thuộc tính. `queryable` cho phép thuộc tính xuất hiện trong bộ lọc của API truy vấn có cấu trúc (BR-07-018) và kéo theo việc tạo chỉ mục biểu thức trên `attrs`, vì vậy mỗi danh mục giới hạn tối đa 10 thuộc tính `queryable` (tham số `07.rdm.max-queryable-attributes`). `searchable` đưa giá trị thuộc tính vào chỉ mục tìm kiếm không dấu cùng với tên bản ghi. `status = HIDDEN` ẩn thuộc tính khỏi giao diện, tệp xuất và API khai thác nhưng vẫn giữ giá trị, tương đương trạng thái thuộc tính của Aita (LGC-DMDC-018).

Danh mục không được chứa dữ liệu cá nhân (BR-07-025). Khi khai báo thuộc tính, hệ thống từ chối mức phân loại Nhạy cảm và cảnh báo (phải xác nhận) nếu mã hoặc nhãn thuộc tính chứa các từ gợi ý dữ liệu cá nhân như "số định danh", "CCCD", "CMND", "ngày sinh", "số điện thoại cá nhân", "địa chỉ thường trú", "họ tên công dân". Danh sách từ gợi ý là tham số `07.rdm.pii-keywords` để quản trị nền tảng cập nhật.

### 4.5. Phiên bản và hiệu lực theo khoảng ngày

Phiên bản là ảnh chụp đầy đủ của danh mục tại một thời điểm, gồm lược đồ và toàn bộ bản ghi. Số phiên bản (`version_no`) tăng dần từ 1 trong mỗi danh mục và không bao giờ tái sử dụng kể cả khi một bản nháp bị hủy. Mỗi phiên bản đã phát hành có khoảng hiệu lực nửa mở `[effective_from, effective_to)`: phiên bản có hiệu lực từ đầu ngày `effective_from` (00:00 giờ Việt Nam) đến hết ngày liền trước `effective_to`; `effective_to` rỗng nghĩa là còn hiệu lực vô thời hạn. Khoảng hiệu lực của các phiên bản đã phát hành không chồng lấn; khi phát hành phiên bản mới, `effective_to` của phiên bản đang có `effective_to` rỗng được gán bằng `effective_from` của phiên bản mới (BR-07-007). Nhờ quy tắc này, với mọi ngày bất kỳ có tối đa một phiên bản hiệu lực, và phép tra cứu theo thời điểm (BR-07-008) luôn cho kết quả xác định.

Ba nhãn "Đang hiệu lực", "Sắp hiệu lực" và "Hết hiệu lực" không phải trạng thái lưu trong CSDL mà được tính từ khoảng hiệu lực so với ngày hiện tại: "Sắp hiệu lực" khi `effective_from` lớn hơn hôm nay; "Đang hiệu lực" khi hôm nay nằm trong khoảng; "Hết hiệu lực" khi `effective_to` nhỏ hơn hoặc bằng hôm nay. Lý do không lưu nhãn này là để tránh phải có tác vụ nền chuyển trạng thái lúc nửa đêm, vốn dễ sai khi tác vụ trễ hoặc lỗi. Con trỏ `current_version_id` của danh mục được tính lại khi phát hành và khi bước sang ngày mới (tác vụ nền đầu ngày chỉ làm mới con trỏ và bộ đệm, không đổi dữ liệu); kể cả khi tác vụ này trễ, API khai thác vẫn chọn phiên bản theo khoảng hiệu lực chứ không theo con trỏ.

### 4.6. Bản ghi

Bản ghi là một dòng của danh mục trong một phiên bản. Trường hệ thống của bản ghi gồm: mã (`code`, `T-CODE`, lưu chữ hoa, duy nhất trong phiên bản theo so sánh không phân biệt hoa thường, BR-07-002); tên (`name`, `T-NAME`); tên tìm kiếm (`name_search`, cột sinh tự động: chữ thường, bỏ dấu tiếng Việt, đổi "đ" thành "d"); mã cha (`parent_code`); độ sâu (`depth`, 1 cho gốc); đường dẫn tổ tiên (`path`, mảng mã từ gốc tới cha); tên cấp (`level_name`, lấy từ `level_names[depth-1]` của danh mục); thứ tự (`sort_order`); trạng thái (`status`); mã thay thế (`replaced_by`, mảng mã); khoảng hiệu lực riêng của bản ghi (`valid_from`, `valid_to`, tùy chọn, dùng khi một bản ghi chỉ có hiệu lực trong một phần khoảng của phiên bản); thuộc tính động (`attrs`); cờ bản ghi mở rộng địa phương (`is_local_extension`, chỉ cho HYBRID); và tham chiếu hệ cũ (`legacy_ref`).

Mã bản ghi giữ nguyên ý nghĩa qua các phiên bản: cùng một mã ở phiên bản 3 và phiên bản 4 là cùng một đối tượng nghiệp vụ. Vì vậy mã bản ghi không được đổi; nếu nghiệp vụ cần đổi mã, người dùng ngừng dùng mã cũ, thêm mã mới và ghi `replaced_by` (với ĐVHC thì ghi sự kiện `RECODE`). Mã đã từng phát hành không được gán lại cho đối tượng khác (BR-07-021 với ĐVHC và BR-07-040 với mọi danh mục).

### 4.7. Phân cấp

Danh mục phân cấp (`is_hierarchical = true`) tổ chức bản ghi thành cây (hoặc rừng nhiều gốc) theo mã cha. Mã cha phải tồn tại trong cùng phiên bản, cây không được có vòng, độ sâu không vượt `max_depth` (tối đa 10), và bản ghi `ACTIVE` không được có cha `DEPRECATED` (BR-07-014). Hệ thống tự tính `depth`, `path` và `level_name` mỗi khi mã cha thay đổi, người dùng không nhập các trường này. Tên cấp (`level_names`) là mảng nhãn theo độ sâu, ví dụ `["Tỉnh", "Xã"]` cho ĐVHC hiện hành; phiên bản lịch sử của ĐVHC trước 01/7/2025 dùng `["Tỉnh", "Huyện", "Xã"]`. Vì tên cấp có thể khác nhau giữa các phiên bản, `level_names` được chụp vào phiên bản khi phát hành (trong `stats` của phiên bản) để tra cứu lịch sử hiển thị đúng tên cấp tại thời điểm đó.

### 4.8. Ngừng dùng và kế thừa

Bản ghi đã từng phát hành không bị xóa (BR-07-003). Khi một mã không còn dùng, người dùng chuyển bản ghi sang `DEPRECATED` trong bản nháp và có thể ghi danh sách mã thay thế `replaced_by`. Bản ghi ngừng dùng vẫn được tra cứu, kết quả trả kèm trạng thái và mã thay thế (BR-07-004), để HTTT đang lưu dữ liệu cũ vẫn hiểu được mã và biết chuyển sang mã nào. Với danh mục ĐVHC, quan hệ kế thừa phong phú hơn nên được ghi thành sự kiện sắp xếp (`item_succession`) có loại sự kiện, danh sách mã nguồn, danh sách mã đích, ngày hiệu lực và căn cứ pháp lý; `replaced_by` của bản ghi ĐVHC được hệ thống tự điền từ sự kiện sắp xếp.

### 4.9. Nguồn danh mục và quyền cập nhật

Nguồn danh mục quyết định ai được sửa. Danh mục `LOCAL` do tenant tự quản theo quy trình bản nháp – duyệt – phát hành. Danh mục `NATIONAL` chỉ được cập nhật qua đồng bộ từ NDXP (BR-07-009); mọi API sửa trả `ERR-07-003`, kể cả với quản trị tỉnh, để bảo đảm bản trong Datahub luôn trùng bản quốc gia. Danh mục `HYBRID` có lược đồ và bản ghi gốc kế thừa từ danh mục gốc (chỉ đọc), và chỉ chứa bản ghi bổ sung có mã khớp `local_code_pattern`, không trùng mã của danh mục gốc (BR-07-010). Danh mục thuộc tenant `COMMON` chỉ tenant `PLATFORM` được ghi, bất kể nguồn.

### 4.10. Phân loại dữ liệu danh mục

Mỗi danh mục có một mức phân loại theo SAD §8.2. `PUBLIC` (Công khai, mặc định) áp dụng cho hầu hết danh mục; mọi HTTT `ACTIVE` có scope `rdm.read` đều tra được. `INTERNAL` (Nội bộ) áp dụng cho danh mục chỉ dùng trong cơ quan nhà nước; HTTT tra được nhưng không xuất hiện trên cổng nhà phát triển công khai. `RESTRICTED` (Hạn chế) áp dụng cho danh mục có thông tin đầu mối hoặc nội dung chưa công bố; chỉ HTTT được cấp quyền trên đúng danh mục đó mới khai thác được (BR-07-019, FR-07-052), giao diện hiển thị theo quyền và nhật ký che một phần. Mức Nhạy cảm bị cấm trong danh mục (BR-07-025), vì danh mục là dữ liệu tham chiếu được nhân bản rộng rãi vào bộ đệm, ảnh chụp và HTTT, không thể áp các biện pháp bảo vệ của dữ liệu nhạy cảm.

### 4.11. Sơ đồ trạng thái danh mục

Sơ đồ sau mô tả vòng đời của một danh mục (`catalog.status`).

```mermaid
stateDiagram-v2
    [*] --> DRAFT : Tạo danh mục (FR-07-003, FR-07-022)\nkèm phiên bản nháp số 1
    DRAFT --> DRAFT : Sửa thông tin, lược đồ, bản ghi
    DRAFT --> [*] : Xóa mềm (FR-07-009)\ndeleted_at được gán
    DRAFT --> ACTIVE : Phát hành phiên bản đầu tiên (FR-07-016)
    ACTIVE --> ACTIVE : Phát hành phiên bản mới
    ACTIVE --> RETIRED : Ngừng hiệu lực (FR-07-009)\ncó lý do, không bị tham chiếu
    RETIRED --> [*]
```

Danh mục bắt đầu ở `DRAFT` khi được tạo và luôn có sẵn phiên bản nháp số 1. Danh mục chỉ được xóa (xóa mềm) khi còn `DRAFT`, tức là chưa từng có phiên bản nào được phát hành, vì khi đó chưa HTTT nào có thể đã dùng nó. Khi phiên bản đầu tiên được phát hành, danh mục chuyển sang `ACTIVE` và không bao giờ quay về `DRAFT`; các lần phát hành tiếp theo không đổi trạng thái danh mục. Danh mục `ACTIVE` có thể bị ngừng hiệu lực thành `RETIRED`, lúc đó phiên bản hiện hành được đóng khoảng hiệu lực tại ngày ngừng, API khai thác trả `ERR-07-031` (HTTP 410) cho tra cứu tại thời điểm sau ngày ngừng nhưng vẫn trả dữ liệu cho tra cứu tại thời điểm trước đó, để dữ liệu lịch sử vẫn hiểu được. `RETIRED` là trạng thái cuối; không có thao tác kích hoạt lại, vì nhu cầu đó được đáp ứng bằng cách tạo danh mục mới, tránh nhầm lẫn cho HTTT đã xử lý sự kiện ngừng hiệu lực.

### 4.12. Sơ đồ trạng thái phiên bản

Sơ đồ sau mô tả vòng đời của một phiên bản (`catalog_version.status`), là trọng tâm của quy trình BP-03.

```mermaid
stateDiagram-v2
    [*] --> DRAFT : Tạo bản nháp (FR-07-011)\nhoặc tạo danh mục, đồng bộ, di trú
    DRAFT --> DRAFT : Sửa lược đồ, bản ghi, nhập tệp, nhập lô
    DRAFT --> IN_REVIEW : Trình duyệt (FR-07-015)\nkiểm tra hợp lệ đạt
    DRAFT --> PUBLISHED : Phát hành thẳng (FR-07-016)\nrequire_approval = false,\nkhông vượt ngưỡng, không phá vỡ
    DRAFT --> DISCARDED : Hủy bản nháp (FR-07-017)
    IN_REVIEW --> DRAFT : Từ chối (FR-07-015)\nbắt buộc lý do
    IN_REVIEW --> APPROVED : Duyệt (FR-07-015)\nngười duyệt khác người trình
    IN_REVIEW --> DRAFT : Người trình rút lại
    APPROVED --> PUBLISHED : Phát hành (FR-07-016)
    APPROVED --> DRAFT : Người duyệt thu hồi duyệt\ntrước khi phát hành
    PUBLISHED --> [*]
    DISCARDED --> [*]
```

Mỗi danh mục có tối đa một phiên bản mở, tức là ở một trong ba trạng thái `DRAFT`, `IN_REVIEW`, `APPROVED` (BR-07-005); quy tắc này tránh hai nhóm cùng soạn hai bản nháp rồi ghi đè lên nhau. Chỉ ở `DRAFT` mới sửa được nội dung; sang `IN_REVIEW` thì nội dung bị khóa để người duyệt duyệt đúng cái họ thấy. Bị từ chối, phiên bản quay về `DRAFT` và lý do được lưu ở lịch sử duyệt (`version_review`). Người trình được rút lại phiên bản đang chờ duyệt về `DRAFT` (ví dụ phát hiện sai sót), và người duyệt được thu hồi quyết định duyệt khi phiên bản còn `APPROVED`, vì giữa lúc duyệt và lúc phát hành có thể có thông tin mới. Lối tắt `DRAFT` sang `PUBLISHED` chỉ mở khi danh mục cấu hình không cần duyệt và thay đổi không vượt ngưỡng, không phá vỡ (BR-07-012, BR-07-026); người phát hành vẫn phải có `PERM-07-publish` và không phải người sửa cuối (bốn mắt). Phiên bản đồng bộ quốc gia được tự phát hành khi không phá vỡ và nguồn bật `auto_apply` (FR-07-037); trường hợp này chủ thể phát hành là tác nhân hệ thống và ghi kiểm toán như vậy. `PUBLISHED` và `DISCARDED` là trạng thái cuối, phiên bản đã phát hành là bất biến (BR-07-006).

### 4.13. Sơ đồ trạng thái bản ghi

Sơ đồ sau mô tả vòng đời của một mã bản ghi xuyên qua các phiên bản. Vì bản ghi được sao chép sang từng phiên bản, "trạng thái" ở đây là trạng thái của cùng một mã trong phiên bản nháp so với phiên bản trước.

```mermaid
stateDiagram-v2
    [*] --> MOI_TRONG_NHAP : Thêm trong bản nháp\n(chưa từng phát hành)
    MOI_TRONG_NHAP --> [*] : Xóa khỏi bản nháp (API-07-030)\nhoặc REPLACE không có trong tệp
    MOI_TRONG_NHAP --> ACTIVE : Phiên bản được phát hành
    ACTIVE --> ACTIVE : Sửa tên, thuộc tính, thứ tự\ntrong bản nháp mới
    ACTIVE --> DEPRECATED : Ngừng dùng (FR-07-012, FR-07-019)\ncó thể kèm mã thay thế
    DEPRECATED --> ACTIVE : Khôi phục trong bản nháp mới\n(cùng ý nghĩa, phải có lý do)
    DEPRECATED --> DEPRECATED : Sửa mã thay thế
```

Trạng thái lưu của bản ghi chỉ có `ACTIVE` và `DEPRECATED`; "mới trong nháp" là trạng thái suy ra (bản ghi `ACTIVE` trong bản nháp mà mã chưa xuất hiện ở bất kỳ phiên bản đã phát hành nào). Chỉ bản ghi mới trong nháp mới xóa được; bản ghi đã từng phát hành chỉ ngừng dùng được (BR-07-003, `ERR-07-013`). Cho phép khôi phục một mã đã ngừng dùng vì có trường hợp ngừng nhầm, nhưng chỉ khi mã giữ đúng ý nghĩa cũ; khôi phục được phân loại là thay đổi không phá vỡ và phải có ghi chú lý do trong `change_note` của phiên bản.

### 4.14. Sơ đồ trạng thái tác vụ nhập và xuất

Tác vụ nhập (`import_job` với `job_type = IMPORT`) đi qua các trạng thái sau. Đây là trạng thái đề xuất của FRS; D03-03-PH07 dùng đúng tập giá trị này cho ràng buộc `CHECK`.

```mermaid
stateDiagram-v2
    [*] --> UPLOADED : Tải tệp lên (API-07-033)
    UPLOADED --> SCANNING : Gửi quét mã độc (DD-12)
    SCANNING --> PARSING : scan_status = CLEAN
    SCANNING --> FAILED : scan_status = INFECTED\nhoặc quét quá hạn
    PARSING --> VALIDATING : Đọc xong, đã ghi import_row
    PARSING --> FAILED : Tệp hỏng, sai mã hóa,\nvượt giới hạn, thiếu cột
    VALIDATING --> VALIDATED : Kiểm tra liên dòng xong\n(có thể còn dòng lỗi)
    VALIDATED --> COMMITTING : Xác nhận ghi (API-07-036)
    VALIDATED --> CANCELLED : Hủy (API-07-037)
    VALIDATED --> EXPIRED : Quá 24 giờ (BR-07-016)
    COMMITTING --> COMMITTED : Ghi vào bản nháp thành công
    COMMITTING --> FAILED : Lỗi giao dịch, bản nháp đã đổi
    UPLOADED --> CANCELLED
    SCANNING --> CANCELLED
    PARSING --> CANCELLED
    COMMITTED --> [*]
    FAILED --> [*]
    CANCELLED --> [*]
    EXPIRED --> [*]
```

Tác vụ nhập có hai pha tách biệt (ADR-056). Pha một gồm `UPLOADED`, `SCANNING`, `PARSING`, `VALIDATING` và kết thúc ở `VALIDATED` với kết quả xem trước; pha này không đụng tới bản nháp nên người dùng có thể thử nhiều lần mà không có rủi ro. Tệp chỉ được phân tích khi kết quả quét mã độc là `CLEAN` (DD-12, BR-07-041 đề xuất mới). Pha hai bắt đầu khi người dùng xác nhận: `COMMITTING` ghi toàn bộ dòng hợp lệ vào bản nháp trong một giao dịch, thành công thì `COMMITTED`, thất bại thì `FAILED` và bản nháp không thay đổi gì. Kết quả xem trước hết hạn sau 24 giờ (`EXPIRED`), vì sau thời gian đó bản nháp có khả năng đã bị sửa và kết quả kiểm tra không còn đúng. Tác vụ xuất (`job_type = EXPORT`) đơn giản hơn với các trạng thái `QUEUED`, `RUNNING`, `COMPLETED`, `FAILED` và `EXPIRED` (tệp kết quả hết hạn tải sau 24 giờ, FR-00-031); sơ đồ của tác vụ xuất không vẽ riêng vì là chuỗi tuyến tính.

### 4.15. Sơ đồ trạng thái lần đồng bộ

Lần đồng bộ quốc gia (`sync_run.status`) đi qua các trạng thái sau.

```mermaid
stateDiagram-v2
    [*] --> RUNNING : Lịch chạy hoặc chạy theo yêu cầu (FR-07-036)
    RUNNING --> NO_CHANGE : Phiên bản nguồn không đổi\nhoặc khác biệt rỗng
    RUNNING --> APPLIED : Không phá vỡ và auto_apply = true\nđã tạo và phát hành phiên bản
    RUNNING --> PENDING_CONFIRMATION : Có thay đổi phá vỡ\nhoặc auto_apply = false
    RUNNING --> FAILED : Nguồn lỗi, quá thời gian,\nlỗi kiểm tra hợp lệ
    PENDING_CONFIRMATION --> APPLIED : Xác nhận (FR-07-037)\nphát hành phiên bản đồng bộ
    PENDING_CONFIRMATION --> REJECTED : Từ chối, bắt buộc lý do
    PENDING_CONFIRMATION --> REJECTED : Có lần chạy mới hơn thay thế
    NO_CHANGE --> [*]
    APPLIED --> [*]
    REJECTED --> [*]
    FAILED --> [*]
```

Mỗi lần chạy bắt đầu ở `RUNNING`, gọi PH-14 để lấy metadata và dữ liệu, rồi tính khác biệt với phiên bản hiện hành của danh mục trong Datahub. Khi không có khác biệt, lần chạy kết thúc ở `NO_CHANGE` mà không tạo phiên bản. Khi chỉ có thay đổi không phá vỡ và nguồn bật `auto_apply`, hệ thống tạo phiên bản với `origin = SYNC` và phát hành ngay, kết thúc `APPLIED`. Khi có thay đổi phá vỡ, hoặc nguồn tắt `auto_apply`, lần chạy dừng ở `PENDING_CONFIRMATION` chờ người có `PERM-07-sync` xác nhận hoặc từ chối (BR-07-017); trong khi chờ, phiên bản đồng bộ tồn tại dưới dạng bản nháp `origin = SYNC` và chiếm suất phiên bản mở của danh mục. Nếu một lần chạy mới phát hiện phiên bản nguồn mới hơn trong lúc lần trước còn chờ, lần trước bị chuyển `REJECTED` với lý do "được thay thế bởi lần chạy {runId}" và bản nháp được tính lại, để người xác nhận luôn xem khác biệt với dữ liệu nguồn mới nhất.

### 4.16. Thuật ngữ bổ sung

Bảng dưới đây liệt kê các thuật ngữ riêng của PH-07 chưa có trong D00-01; luồng lõi sẽ gộp vào D00-01 §2.

| Thuật ngữ | Định nghĩa |
|---|---|
| Danh mục gốc (base catalog) | Danh mục `COMMON` hoặc `NATIONAL` được một danh mục HYBRID mở rộng |
| Dải mã địa phương (local code range) | Biểu thức chính quy mà mã bản ghi bổ sung của danh mục HYBRID phải khớp, ví dụ `^68L[0-9]{3}$` |
| Thay đổi phá vỡ (breaking change) | Thay đổi có thể làm HTTT đang dùng danh mục bị lỗi hoặc hiểu sai: ngừng dùng mã, đổi mã cha, xóa thuộc tính, đổi kiểu thuộc tính, thu hẹp ràng buộc |
| Ngưỡng thay đổi lớn | Tỷ lệ số bản ghi bị thêm, sửa hoặc ngừng dùng trên tổng số bản ghi của phiên bản gốc, vượt ngưỡng thì bắt buộc duyệt |
| Ảnh chụp (snapshot) | Tệp JSON nén gzip và tệp CSV chứa toàn bộ bản ghi của một phiên bản đã phát hành, lưu ở kho đối tượng |
| Sự kiện sắp xếp (succession event) | Bản ghi quan hệ kế thừa giữa các mã ĐVHC cũ và mới, có loại, căn cứ pháp lý, ngày hiệu lực |
| Hệ thống mã ngoài (code system) | Bộ mã riêng của một HTTT hoặc một cơ quan, cần ánh xạ sang mã danh mục chuẩn |
| Độ phủ ánh xạ | Tỷ lệ bản ghi `ACTIVE` của danh mục có ít nhất một ánh xạ không tạm thời sang một hệ thống mã |

## 5. Đặc tả chi tiết yêu cầu chức năng

### 5.0. Cách đọc đặc tả và quy định chung cho mọi FR

Mỗi FR dưới đây gồm một bảng tóm tắt theo mẫu D00-01 §4.3, tiếp theo là bảng đầu vào, danh sách bước xử lý đánh số và bảng ngoại lệ. Bước xử lý được viết để kiểm thử viên kiểm chứng được từng bước; các bước kiểm tra quyền và tenant chung không lặp lại ở mọi FR mà được quy định một lần trong mục này.

Các quy định sau áp dụng cho mọi FR của PH-07 trừ khi FR ghi khác. Tenant được xác định từ ngữ cảnh xác thực, không lấy từ tham số do client gửi (tuân thủ FR-00-010); mọi truy vấn chạy dưới RLS với `app.tenant_id` của phiên làm việc. Đối tượng thuộc tenant khác hoặc thuộc tổ chức khác (với vai trò phạm vi ○) trả `404` thay vì `403`, để không lộ sự tồn tại của đối tượng (D02-08 §7, FR-00-011). Thao tác tạo nhận tiêu đề `Idempotency-Key` (chuỗi 8…64 ký tự, lưu 24 giờ); gửi lại cùng khóa và cùng nội dung trả lại kết quả cũ, cùng khóa khác nội dung trả `ERR-07-022`. Thao tác sửa, xóa, chuyển trạng thái yêu cầu tiêu đề `If-Match` chứa ETag (giá trị cột `version` của đối tượng); không khớp trả `ERR-07-018` (HTTP 412, tuân thủ FR-00-052); thiếu tiêu đề trả `428 Precondition Required`. Lỗi trả theo RFC 9457 với trường `type`, `title`, `status`, `detail`, `instance`, `code` (mã `ERR-07-nnn`), `traceId` và với lỗi hợp lệ thì thêm mảng `errors` gồm `{field, code, message}`; thông điệp tiếng Việt nói rõ sai gì và cách sửa (tuân thủ FR-00-080). Thao tác ghi trên danh mục `NATIONAL` (trừ qua đồng bộ) hoặc trên danh mục `COMMON` khi tenant hiện hành không phải `PLATFORM` trả `ERR-07-003`. Thao tác ghi trên danh mục `RETIRED` trả `ERR-07-031`. Mọi thao tác ghi thành công sinh bản ghi kiểm toán qua PH-13 theo FR-00-040, FR-00-041 với các trường chung: thời điểm, tenant, chủ thể (người hoặc máy), địa chỉ nguồn, hành động, loại đối tượng, mã đối tượng, giá trị trước và sau (chỉ các trường thay đổi), kết quả, lý do, `traceId`; cột "Kiểm toán" của từng FR chỉ ghi phần riêng. Sự kiện được ghi vào bảng outbox trong cùng giao dịch với thay đổi dữ liệu (SAD §7.3, DD-11), nên sự kiện không bao giờ phát ra cho một thay đổi bị hủy và không bao giờ mất khi thay đổi đã ghi.

Kiểu dữ liệu chuẩn dùng trong bảng đầu vào theo D00-01 §5. Ngoài ra FRS dùng các kiểu bổ trợ sau: `T-INT` là số nguyên 32 bit, `T-ATTR-CODE` là mã thuộc tính theo mẫu `^[a-z][a-z0-9_]{0,62}$`, `T-REGEX` là biểu thức chính quy ECMA-262 tối đa 500 ký tự, `T-FILE` là tệp đính kèm dạng multipart.

### 5.1. Nhóm A — Danh mục và lược đồ

#### FR-07-001 · Liệt kê danh mục, đếm số lượng, lọc theo nhóm, nguồn, trạng thái, phân loại

Chức năng này là màn hình đầu tiên của PH-07 và là API cho HTTT biết có những danh mục nào. Nó thay chức năng "danh sách danh mục, số lượng danh mục" của Aita và bổ sung bộ lọc theo các thuộc tính mới.

| Trường | Nội dung |
|---|---|
| Mã, tên | FR-07-001 · Liệt kê danh mục, đếm số lượng, lọc theo nhóm, nguồn, trạng thái, phân loại |
| Mức ưu tiên | M |
| Truy vết | REQ-07; LGC-DMDC-001 |
| Tác nhân, quyền | Mọi vai trò có `PERM-07-read`; HTTT với scope `rdm.read` (qua FR-07-033) |
| Tiền điều kiện | Người dùng đã đăng nhập và chọn tenant làm việc (FR-00-004) |
| Đầu ra | Trang kết quả gồm `items[]` (mã, tên, nhóm, nguồn, phân loại, trạng thái, cơ quan chủ quản, số phiên bản hiện hành, ngày hiệu lực hiện hành, số bản ghi hiện hành, có phiên bản mở hay không, tenant sở hữu `COMMON` hay tenant hiện hành), `page`, `size`, `totalElements`, `totalPages`; và khối `facets` đếm số danh mục theo từng giá trị của nguồn, trạng thái, phân loại và theo nhóm |
| Hậu điều kiện | Không thay đổi dữ liệu |
| Sự kiện phát ra | Không |
| Kiểm toán | Không ghi kiểm toán cho thao tác xem danh sách (danh mục không chứa dữ liệu Nhạy cảm, FR-00-040 không yêu cầu) |

Đầu vào là các tham số truy vấn của API-07-001; giao diện UI-07-01 giữ chúng trên URL theo FR-00-022.

| Tham số | Kiểu | Bắt buộc | Ràng buộc | Ví dụ |
|---|---|---|---|---|
| `q` | T-NAME | Không | Tìm không dấu, không phân biệt hoa thường trên mã và tên danh mục (FR-00-020); 1…100 ký tự | `dan toc` |
| `groupId` | T-ID | Không | Lọc theo nhóm và mọi nhóm con của nó | `0193…a1` |
| `sourceType` | T-ENUM[] | Không | Một hoặc nhiều trong `LOCAL`, `NATIONAL`, `HYBRID` | `NATIONAL,HYBRID` |
| `status` | T-ENUM[] | Không | `DRAFT`, `ACTIVE`, `RETIRED`; mặc định `DRAFT,ACTIVE` | `ACTIVE` |
| `classification` | T-ENUM[] | Không | `PUBLIC`, `INTERNAL`, `RESTRICTED` | `PUBLIC` |
| `scope` | T-ENUM | Không | `ALL` (mặc định), `TENANT` (chỉ của tenant), `COMMON` (chỉ toàn quốc) | `ALL` |
| `ownerOrgId` | T-ID | Không | Lọc theo cơ quan chủ quản | |
| `hasOpenVersion` | T-BOOL | Không | Chỉ danh mục đang có phiên bản mở | `true` |
| `page`, `size` | T-INT | Không | `page` ≥ 0; `size` ∈ {10, 20, 50, 100, 200}, mặc định 20 (FR-00-021) | `0`, `20` |
| `sort` | T-CODE | Không | `code`, `name`, `updatedAt`, `itemCount`, kèm `,asc` hoặc `,desc`; mặc định `name,asc` | `updatedAt,desc` |

Xử lý gồm các bước sau.

1. Hệ thống kiểm tra tham số; tham số sai miền giá trị trả `400` với mảng `errors`.
2. Hệ thống truy vấn danh mục của tenant hiện hành và của tenant `COMMON` (theo `scope`), loại bỏ danh mục đã xóa mềm (`deleted_at` khác rỗng).
3. Với người dùng chỉ có `PERM-07-read`, danh mục ở trạng thái `DRAFT` (chưa phát hành) chỉ hiện cho người có `PERM-07-create`/`update` trên danh mục đó hoặc `PERM-07-publish`; người xem thông thường chỉ thấy `ACTIVE` và `RETIRED`. Danh mục `RESTRICTED` hiện tên và mã cho mọi người có `PERM-07-read` trong tenant (giao diện quản trị), vì hạn chế áp dụng cho khai thác dữ liệu của HTTT chứ không cho cán bộ trong tenant.
4. Hệ thống áp các bộ lọc, trong đó `q` so khớp trên cột chuẩn hóa không dấu của mã và tên.
5. Hệ thống tính `facets` trên cùng tập kết quả trước khi phân trang, để người dùng thấy số lượng theo từng giá trị lọc (đáp ứng "số lượng danh mục" của LGC-DMDC-001).
6. Hệ thống sắp xếp, phân trang và trả kết quả.

Các ngoại lệ của FR-07-001 được liệt kê trong bảng sau.

| Điều kiện | Mã lỗi | HTTP | Hành vi |
|---|---|---|---|
| Tham số sai kiểu hoặc ngoài miền | — (lỗi hợp lệ chung) | 400 | Trả `errors` theo tham số |
| `size` > 200 | ERR-07-026 | 400 | Từ chối, gợi ý dùng phân trang |
| `groupId` không tồn tại trong tenant hoặc `COMMON` | — | 200 | Trả danh sách rỗng, không báo lỗi (tránh lộ nhóm của tenant khác) |

#### FR-07-002 · Xem chi tiết danh mục: thông tin, thuộc tính, phiên bản, bản ghi

Chức năng này cung cấp toàn bộ thông tin của một danh mục trên một màn hình nhiều tab (UI-07-02), thay chức năng xem chi tiết của Aita (tên, danh sách thuộc tính, danh sách bản ghi) và bổ sung phiên bản, ánh xạ, đồng bộ, lịch sử.

| Trường | Nội dung |
|---|---|
| Mã, tên | FR-07-002 · Xem chi tiết danh mục: thông tin, thuộc tính, phiên bản, bản ghi |
| Mức ưu tiên | M |
| Truy vết | REQ-07; LGC-DMDC-003 |
| Tác nhân, quyền | Mọi vai trò có `PERM-07-read` |
| Tiền điều kiện | Danh mục tồn tại, chưa bị xóa mềm, thuộc tenant hiện hành hoặc `COMMON` |
| Đầu ra | Khối thông tin danh mục (mọi trường của EN-07-02 trừ `legacy_ref` chỉ hiện cho PA), danh sách phiên bản (số, trạng thái, nhãn hiệu lực tính toán, ngày hiệu lực, số bản ghi, thống kê thay đổi, người phát hành), lược đồ thuộc tính của phiên bản được chọn, trang bản ghi của phiên bản được chọn; với danh mục HYBRID thêm thông tin danh mục gốc và số bản ghi bổ sung; ETag của danh mục |
| Hậu điều kiện | Không thay đổi dữ liệu |
| Sự kiện phát ra | Không |
| Kiểm toán | Không |

Đầu vào gồm mã danh mục trên đường dẫn và các tham số chọn phiên bản, phân trang bản ghi; bảng dưới mô tả chi tiết.

| Tham số | Kiểu | Bắt buộc | Ràng buộc | Ví dụ |
|---|---|---|---|---|
| `{c}` | T-CODE | Có | Mã danh mục, không phân biệt hoa thường | `DAN_TOC` |
| `{v}` (API-07-013, 022, 026) | T-INT hoặc từ khóa | Không | Số phiên bản, `current` (mặc định) hoặc `draft` | `current` |
| `q` (bản ghi) | T-NAME | Không | Tìm không dấu trên mã, tên, thuộc tính `searchable` | `kinh` |
| `status` (bản ghi) | T-ENUM[] | Không | `ACTIVE`, `DEPRECATED`; mặc định cả hai | `ACTIVE` |
| `parentCode` (bản ghi) | T-CODE | Không | Lọc con trực tiếp | `68` |
| `changeType` (bản ghi, chỉ với `draft`) | T-ENUM[] | Không | `ADDED`, `CHANGED`, `DEPRECATED`, `UNCHANGED` so với phiên bản gốc của bản nháp | `ADDED,CHANGED` |
| `page`, `size`, `sort` | T-INT, T-CODE | Không | Như FR-07-001; `sort` theo `sortOrder` (mặc định), `code`, `name` | |

Xử lý gồm các bước sau.

1. Hệ thống tìm danh mục theo mã chuẩn hóa chữ hoa trong tenant hiện hành, nếu không có thì tìm trong `COMMON`; không thấy trả `ERR-07-001`.
2. Hệ thống áp quy tắc hiển thị danh mục `DRAFT` như bước 3 của FR-07-001; người không đủ quyền nhận `ERR-07-001`.
3. Hệ thống xác định phiên bản: `current` là phiên bản có khoảng hiệu lực chứa ngày hôm nay; nếu danh mục chưa có phiên bản phát hành thì `current` trỏ tới bản nháp số 1 cho người có quyền soạn; `draft` là phiên bản mở; không có trả `ERR-07-006`.
4. Hệ thống trả thông tin danh mục kèm ETag, danh sách phiên bản sắp theo `version_no` giảm dần, lược đồ thuộc tính của phiên bản chọn sắp theo `sort_order` (thuộc tính `HIDDEN` chỉ hiện với người có quyền soạn, có đánh dấu).
5. Hệ thống trả trang bản ghi của phiên bản chọn. Với bản nháp, mỗi bản ghi kèm `changeType` so với phiên bản gốc để giao diện tô màu thay đổi.
6. Với danh mục HYBRID, trang bản ghi là hợp của bản ghi của phiên bản hiệu lực của danh mục gốc (đánh dấu `inherited = true`, chỉ đọc) và bản ghi bổ sung (`is_local_extension = true`).

Các ngoại lệ được liệt kê trong bảng sau.

| Điều kiện | Mã lỗi | HTTP | Hành vi |
|---|---|---|---|
| Không tìm thấy danh mục hoặc không đủ quyền xem bản nháp | ERR-07-001 | 404 | |
| Không tìm thấy phiên bản yêu cầu | ERR-07-006 | 404 | |
| `size` > 200 | ERR-07-026 | 400 | |

#### FR-07-003 · Tạo danh mục thủ công

Chức năng này cho phép cán bộ quản lý danh mục tạo một danh mục mới qua trình hướng dẫn ba bước (UI-07-03): thông tin chung, lược đồ thuộc tính, cấu hình phân cấp và nguồn. Danh mục mới luôn kèm phiên bản nháp số 1 để người dùng nhập bản ghi ngay.

| Trường | Nội dung |
|---|---|
| Mã, tên | FR-07-003 · Tạo danh mục thủ công |
| Mức ưu tiên | M |
| Truy vết | REQ-07; LGC-DMDC-004 |
| Tác nhân, quyền | DS (○, tổ chức chủ quản phải là tổ chức của người dùng), TA, PA (với `COMMON`); `PERM-07-create` |
| Tiền điều kiện | Tenant hiện hành ở trạng thái hoạt động; nếu tạo danh mục `COMMON` thì tenant hiện hành là `PLATFORM` |
| Đầu ra | `201 Created`, tiêu đề `Location: /api/rdm/v1/catalogs/{code}`, thân là chi tiết danh mục (như FR-07-002) kèm `draftVersionNo = 1`; ETag |
| Hậu điều kiện | Một bản ghi `catalog` trạng thái `DRAFT`; một `catalog_version` số 1 trạng thái `DRAFT`, `origin = MANUAL`, `item_count = 0`; các `attribute_def` của phiên bản 1 nếu có khai báo; `current_version_id` rỗng |
| Sự kiện phát ra | EVT-07-01 `{tenant}.rdm.catalog.created.v1` với `catalogCode`, `name`, `sourceType`, `classification`, `ownerOrgId` |
| Kiểm toán | Hành động `RDM_CATALOG_CREATE`, đối tượng `catalog/{code}`, giá trị sau là toàn bộ thông tin danh mục và danh sách mã thuộc tính |

Đầu vào là thân yêu cầu JSON của API-07-002; bảng dưới mô tả từng trường.

| Trường | Kiểu | Bắt buộc | Ràng buộc | Ví dụ |
|---|---|---|---|---|
| `code` | T-CODE | Có | Mẫu `^[A-Z0-9][A-Z0-9_.-]{0,63}$` sau khi đổi chữ hoa; duy nhất trong tenant, không trùng mã danh mục `COMMON` `ACTIVE` (BR-07-001); không dùng tiền tố dành riêng `SYS_`, `COMMON_` | `LOAI_HINH_CSKD` |
| `name` | T-NAME | Có | 1…255 ký tự sau cắt khoảng trắng, chuẩn hóa NFC | `Loại hình cơ sở kinh doanh` |
| `description` | T-TEXT | Không | ≤ 4.000 ký tự | |
| `groupId` | T-ID | Không | Nhóm tồn tại trong tenant (hoặc `COMMON` nếu tạo danh mục `COMMON`) | |
| `ownerOrgId` | T-ID | Có | Tổ chức tồn tại và hoạt động trong tenant (kiểm tra qua API module PH-20); với DS phải là tổ chức của người dùng | |
| `sourceType` | T-ENUM | Có | `LOCAL` hoặc `HYBRID`; `NATIONAL` chỉ tạo qua FR-07-038 | `LOCAL` |
| `extendsCatalogCode` | T-CODE | Khi `HYBRID` | Danh mục `COMMON` hoặc `NATIONAL` đang `ACTIVE`; không được là HYBRID khác | `DAN_TOC` |
| `localCodePattern` | T-REGEX | Khi `HYBRID` | Biên dịch được; không khớp bất kỳ mã nào đang có của danh mục gốc | `^68L[0-9]{3}$` |
| `classification` | T-ENUM | Không | `PUBLIC` (mặc định), `INTERNAL`, `RESTRICTED` | `PUBLIC` |
| `isHierarchical` | T-BOOL | Không | Mặc định `false` | `false` |
| `maxDepth` | T-INT | Khi phân cấp | 2…10 | `3` |
| `levelNames` | T-JSON (mảng T-NAME) | Không | Số phần tử bằng `maxDepth`; mỗi phần tử 1…50 ký tự | `["Ngành","Nhóm","Loại"]` |
| `requireApproval` | T-BOOL | Không | Mặc định `true` | `true` |
| `attributes` | Mảng đối tượng thuộc tính | Không | Tối đa 100 phần tử, mỗi phần tử theo đầu vào của FR-07-005 | |
| `effectiveFrom` | T-DATE | Không | Ngày hiệu lực dự kiến của phiên bản 1, ≥ hôm nay | `2027-01-01` |

Xử lý gồm các bước sau.

1. Hệ thống chuẩn hóa `code` sang chữ hoa, cắt khoảng trắng hai đầu của các trường văn bản và chuẩn hóa NFC.
2. Hệ thống kiểm tra quyền: người dùng có `PERM-07-create`; nếu là DS thì `ownerOrgId` thuộc tổ chức của người dùng; nếu tenant là `PLATFORM` thì danh mục được tạo với `tenant_id = 'COMMON'`.
3. Hệ thống kiểm tra tính duy nhất của `code` trong tenant và trong `COMMON` (với danh mục `ACTIVE` hoặc `DRAFT`); trùng trả `ERR-07-002`. Mã của danh mục đã xóa mềm được giải phóng sau 30 ngày lưu giữ (FR-00-051).
4. Hệ thống kiểm tra các trường theo bảng đầu vào; với `HYBRID`, kiểm tra danh mục gốc và biểu thức dải mã: thử khớp biểu thức với mọi mã của phiên bản hiệu lực của danh mục gốc, nếu có mã khớp thì trả `ERR-07-012` kèm tối đa 10 mã khớp làm ví dụ, vì dải mã địa phương chồng lên mã quốc gia sẽ gây xung đột khi quốc gia bổ sung mã.
5. Hệ thống kiểm tra từng thuộc tính theo FR-07-005 (kiểu, ràng buộc, cấm dữ liệu nhạy cảm, tối đa 10 `queryable`).
6. Hệ thống tạo trong một giao dịch: bản ghi `catalog` với `status = DRAFT`; `catalog_version` số 1 `DRAFT`; các `attribute_def` gắn với phiên bản 1; bản ghi outbox EVT-07-01.
7. Với danh mục HYBRID, phiên bản 1 không sao chép bản ghi của danh mục gốc; lược đồ được sao chép từ phiên bản hiệu lực của danh mục gốc và đánh dấu `inherited` (chỉ được thêm thuộc tính mới, không sửa thuộc tính kế thừa).
8. Hệ thống ghi kiểm toán và trả `201`.

Các ngoại lệ của FR-07-003 được liệt kê trong bảng sau.

| Điều kiện | Mã lỗi | HTTP | Hành vi |
|---|---|---|---|
| Mã danh mục trùng | ERR-07-002 | 409 | Không tạo gì; thông điệp nêu danh mục trùng thuộc tenant hay `COMMON` |
| Tenant không phải `PLATFORM` mà yêu cầu tạo danh mục `COMMON`, hoặc `sourceType = NATIONAL` | ERR-07-003 | 403 | |
| Danh mục gốc không tồn tại hoặc không `ACTIVE` | ERR-07-001 | 404 | |
| Dải mã địa phương chồng lên mã của danh mục gốc | ERR-07-012 | 422 | Trả ví dụ mã khớp |
| Thuộc tính không hợp lệ | ERR-07-009 | 422 | `errors` chỉ rõ chỉ số thuộc tính và ràng buộc sai |
| Thuộc tính mức Nhạy cảm hoặc gợi ý dữ liệu cá nhân chưa xác nhận | ERR-07-036 | 422 | |
| `Idempotency-Key` đã dùng với nội dung khác | ERR-07-022 | 409 | |
| DS chọn tổ chức chủ quản không phải tổ chức mình | — | 403 | Lỗi phân quyền chung |

#### FR-07-004 · Cập nhật thông tin danh mục

Chức năng này cho phép sửa các thông tin mô tả và chính sách của danh mục (tên, mô tả, đơn vị chủ quản, nhóm, chính sách duyệt, phân loại). Khác với Aita chỉ cho sửa tên, các thông tin này không thuộc phiên bản nên sửa trực tiếp, không cần bản nháp; nhưng mỗi lần sửa đều được ghi kiểm toán và phát sự kiện.

| Trường | Nội dung |
|---|---|
| Mã, tên | FR-07-004 · Cập nhật thông tin danh mục (tên, mô tả, đơn vị chủ quản, nhóm, chính sách duyệt) |
| Mức ưu tiên | M |
| Truy vết | REQ-07; LGC-DMDC-009 |
| Tác nhân, quyền | DS (○), TA, PA (`COMMON`); `PERM-07-update`. Đổi `requireApproval` từ `true` sang `false` và đổi `classification` cần TA hoặc PA |
| Tiền điều kiện | Danh mục tồn tại, không `RETIRED`, không `NATIONAL` (riêng danh mục `NATIONAL` chỉ cho sửa `groupId`, `description`, `classification` vì đây là thông tin quản lý tại chỗ, không phải nội dung quốc gia) |
| Đầu ra | `200` với chi tiết danh mục mới và ETag mới |
| Hậu điều kiện | Các trường được gửi được cập nhật; `version` của danh mục tăng 1; nếu đổi `name` thì tên mới hiển thị ở mọi phiên bản (tên danh mục không thuộc phiên bản) |
| Sự kiện phát ra | EVT-07-02 `{tenant}.rdm.catalog.updated.v1` với `catalogCode` và danh sách trường đã đổi |
| Kiểm toán | Hành động `RDM_CATALOG_UPDATE`, giá trị trước và sau của các trường thay đổi |

Đầu vào là thân JSON Merge Patch (RFC 7396) của API-07-004; chỉ các trường dưới đây được phép, trường khác bị từ chối.

| Trường | Kiểu | Bắt buộc | Ràng buộc | Ví dụ |
|---|---|---|---|---|
| `name` | T-NAME | Không | 1…255 ký tự | `Danh mục loại hình cơ sở kinh doanh` |
| `description` | T-TEXT | Không | ≤ 4.000 | |
| `groupId` | T-ID | Không | Nhóm tồn tại; `null` để bỏ nhóm | |
| `ownerOrgId` | T-ID | Không | Tổ chức hoạt động; DS không được chuyển sang tổ chức khác (chỉ TA, PA) | |
| `requireApproval` | T-BOOL | Không | Đổi sang `false` cần TA hoặc PA; không đổi được khi đang có phiên bản `IN_REVIEW` | `false` |
| `classification` | T-ENUM | Không | Hạ mức từ `RESTRICTED` xuống mức thấp hơn cần TA và lý do | `INTERNAL` |
| `reason` | T-TEXT | Khi đổi `requireApproval` hoặc `classification` | 10…1.000 ký tự | `Theo Quyết định 123/QĐ-UBND` |

Các trường `code`, `sourceType`, `extendsCatalogCode`, `isHierarchical`, `maxDepth`, `levelNames`, `localCodePattern` không sửa được qua chức năng này; cấu hình phân cấp và nguồn có chức năng riêng (FR-07-007, FR-07-008) vì chúng ảnh hưởng tới dữ liệu.

Xử lý gồm các bước sau.

1. Hệ thống kiểm tra `If-Match` khớp `version` của danh mục.
2. Hệ thống kiểm tra quyền theo từng trường được gửi như mô tả ở cột ràng buộc.
3. Hệ thống kiểm tra trạng thái danh mục và nguồn.
4. Hệ thống kiểm tra giá trị từng trường; nếu đổi `classification` lên `RESTRICTED`, hệ thống cảnh báo trong phản hồi số HTTT đã khai thác danh mục trong 30 ngày qua (lấy từ chỉ số `rdm_lookup_total`) mà chưa được cấp quyền, vì các HTTT này sẽ bị từ chối ngay sau thay đổi.
5. Hệ thống cập nhật, tăng `version`, ghi outbox EVT-07-02 và kiểm toán trong một giao dịch.
6. Nếu `classification` thay đổi, hệ thống làm mới bộ đệm chính sách truy cập của danh mục trên mọi pod qua sự kiện nội bộ.

Các ngoại lệ được liệt kê trong bảng sau.

| Điều kiện | Mã lỗi | HTTP | Hành vi |
|---|---|---|---|
| ETag không khớp | ERR-07-018 | 412 | Giao diện hiện khác biệt và cho chọn tải lại (FR-00-052) |
| Danh mục `RETIRED` | ERR-07-031 | 410 | |
| Danh mục `NATIONAL` hoặc `COMMON` (tenant không phải `PLATFORM`) với trường không được phép | ERR-07-003 | 403 | |
| Đổi `requireApproval` khi có phiên bản `IN_REVIEW` | ERR-07-004 | 409 | |
| Thiếu `reason` khi bắt buộc | — | 400 | Lỗi hợp lệ chung |

#### FR-07-005 · Khai báo thuộc tính động có kiểu và ràng buộc

Chức năng này cho phép thêm thuộc tính động vào lược đồ của bản nháp. Đây là nâng cấp quan trọng nhất so với Aita, nơi thuộc tính chỉ có tên; ở Datahub mỗi thuộc tính có kiểu, ràng buộc và cờ khai thác, nhờ đó dữ liệu được kiểm tra chặt và HTTT nhận được JSON Schema chính xác.

| Trường | Nội dung |
|---|---|
| Mã, tên | FR-07-005 · Khai báo thuộc tính động có kiểu và ràng buộc |
| Mức ưu tiên | M |
| Truy vết | REQ-07; LGC-DMDC-004, LGC-DMDC-018 |
| Tác nhân, quyền | DS (○), TA, PA (`COMMON`); `PERM-07-update` |
| Tiền điều kiện | Danh mục có phiên bản `DRAFT` (`{v}` là `draft` hoặc số của bản nháp); danh mục không `NATIONAL`; số thuộc tính hiện có < 100 |
| Đầu ra | `201` với định nghĩa thuộc tính đã tạo; ETag mới của phiên bản |
| Hậu điều kiện | Một `attribute_def` mới gắn với bản nháp; `schema_hash` của bản nháp được tính lại; nếu có `default_value` thì mọi bản ghi `ACTIVE` hiện có trong bản nháp được điền giá trị mặc định; `version` của phiên bản tăng 1 |
| Sự kiện phát ra | Không (sự kiện phát khi phát hành) |
| Kiểm toán | Hành động `RDM_ATTRIBUTE_CREATE`, đối tượng `catalog/{c}/version/{n}/attribute/{code}`, giá trị sau là định nghĩa thuộc tính |

Đầu vào là thân JSON của API-07-023; bảng dưới mô tả từng trường và ý nghĩa ràng buộc đã nêu ở mục 4.4.

| Trường | Kiểu | Bắt buộc | Ràng buộc | Ví dụ |
|---|---|---|---|---|
| `code` | T-ATTR-CODE | Có | Duy nhất trong phiên bản; không trùng tên trường hệ thống (`code`, `name`, `parent_code`, `sort_order`, `status`, `replaced_by`, `valid_from`, `valid_to`, `depth`, `path`, `level_name`) | `loai_hinh` |
| `label` | T-NAME | Có | 1…255 ký tự, duy nhất trong phiên bản (không phân biệt hoa thường, dấu) vì dùng làm tiêu đề cột trong tệp | `Loại hình` |
| `dataType` | T-ENUM | Có | Một trong 11 kiểu ở mục 4.4 | `ENUM` |
| `required` | T-BOOL | Không | Mặc định `false`. Nếu `true` mà bản nháp đã có bản ghi `ACTIVE` thì phải có `defaultValue`, nếu không thì `ERR-07-014` | `true` |
| `uniqueInVersion` | T-BOOL | Không | Mặc định `false`; chỉ cho `STRING`, `INTEGER`, `URI`, `EMAIL`, `CATALOG_REF` | `false` |
| `maxLength` | T-INT | Không | Theo kiểu, xem mục 4.4 | `100` |
| `pattern` | T-REGEX | Không | Chỉ cho `STRING`; biên dịch được, thử khớp ≤ 50 ms | `^[0-9]{5}$` |
| `minValue`, `maxValue` | Chuỗi theo kiểu | Không | Cho `INTEGER`, `DECIMAL`, `DATE`, `DATETIME`; `minValue` ≤ `maxValue` | `0`, `100` |
| `enumValues` | T-JSON | Khi `ENUM` | Mảng 1…500 phần tử `{value: T-CODE, label: T-NAME}`, `value` duy nhất | `[{"value":"PHUONG","label":"Phường"}]` |
| `refCatalogCode` | T-CODE | Khi `CATALOG_REF` | Danh mục tồn tại, `ACTIVE`, trong tenant hoặc `COMMON`; không tự tham chiếu chính danh mục đang soạn | `DVHC` |
| `defaultValue` | Chuỗi theo kiểu | Không | Phải hợp lệ với chính ràng buộc của thuộc tính | `XA` |
| `sortOrder` | T-INT | Không | Mặc định lớn nhất hiện có + 10 | `30` |
| `queryable` | T-BOOL | Không | Mặc định `false`; tối đa 10 thuộc tính `queryable` mỗi danh mục; không cho `TEXT` | `true` |
| `searchable` | T-BOOL | Không | Mặc định `false`; chỉ cho `STRING`, `TEXT` | `false` |
| `description` | T-TEXT | Không | ≤ 4.000 | |
| `dataClass` | T-ENUM | Không | `PUBLIC`, `INTERNAL`, `RESTRICTED`; không nhận `SENSITIVE`; mặc định bằng phân loại của danh mục | `PUBLIC` |
| `piiAcknowledged` | T-BOOL | Không | Người dùng xác nhận thuộc tính không chứa dữ liệu cá nhân khi hệ thống cảnh báo từ gợi ý | `true` |

Xử lý gồm các bước sau.

1. Hệ thống xác định bản nháp; phiên bản không ở `DRAFT` trả `ERR-07-004`.
2. Hệ thống kiểm tra `If-Match` với `version` của phiên bản.
3. Hệ thống kiểm tra `code`, `label` duy nhất và không trùng trường hệ thống.
4. Hệ thống kiểm tra tổ hợp kiểu – ràng buộc theo bảng mục 4.4; ràng buộc không áp dụng được cho kiểu đã chọn bị từ chối (không âm thầm bỏ qua), vì bỏ qua sẽ làm người dùng tưởng ràng buộc có hiệu lực.
5. Hệ thống kiểm tra `dataClass` khác `SENSITIVE`, và so `code`, `label` với danh sách từ gợi ý dữ liệu cá nhân `07.rdm.pii-keywords` (so khớp không dấu, không phân biệt hoa thường); nếu khớp mà `piiAcknowledged` khác `true` thì trả `ERR-07-036` kèm từ khớp.
6. Hệ thống kiểm tra giới hạn số thuộc tính (100) và số thuộc tính `queryable` (theo `07.rdm.max-queryable-attributes`, mặc định 10).
7. Nếu `required = true` và bản nháp có bản ghi `ACTIVE`, hệ thống yêu cầu `defaultValue` và điền giá trị mặc định cho mọi bản ghi `ACTIVE` chưa có giá trị; nếu `uniqueInVersion = true` mà có giá trị mặc định thì chỉ chấp nhận khi bản nháp có tối đa một bản ghi `ACTIVE`.
8. Hệ thống tạo `attribute_def`, tính lại `schema_hash` (SHA-256 của dạng chuẩn JSON Schema), tăng `version` của phiên bản, ghi kiểm toán, tất cả trong một giao dịch.

Các ngoại lệ được liệt kê trong bảng sau.

| Điều kiện | Mã lỗi | HTTP | Hành vi |
|---|---|---|---|
| Phiên bản không phải `DRAFT` | ERR-07-004 | 409 | |
| Danh mục `NATIONAL` hoặc `COMMON` với tenant tỉnh | ERR-07-003 | 403 | |
| `code` hoặc `label` trùng; kiểu và ràng buộc không tương thích; regex lỗi hoặc quá chậm; `enumValues` trùng | ERR-07-009 | 422 | `errors` chỉ rõ trường |
| Thêm thuộc tính bắt buộc không có giá trị mặc định khi đã có bản ghi | ERR-07-014 | 422 | |
| Mức Nhạy cảm hoặc tên gợi ý dữ liệu cá nhân chưa xác nhận | ERR-07-036 | 422 | |
| Vượt 100 thuộc tính hoặc vượt số `queryable` | ERR-07-009 | 422 | |
| ETag không khớp | ERR-07-018 | 412 | |

#### FR-07-006 · Sửa, ẩn, xóa, sắp thứ tự thuộc tính trong bản nháp có kiểm tra tương thích

Chức năng này cho phép thay đổi lược đồ của bản nháp. Vì thay đổi lược đồ có thể làm HTTT đang dùng danh mục bị lỗi, hệ thống kiểm tra tương thích với dữ liệu hiện có và phân loại thay đổi phá vỡ ngay khi sửa, để người dùng biết trước rằng phiên bản sẽ phải qua duyệt.

| Trường | Nội dung |
|---|---|
| Mã, tên | FR-07-006 · Sửa, ẩn, xóa, sắp thứ tự thuộc tính trong bản nháp có kiểm tra tương thích |
| Mức ưu tiên | M |
| Truy vết | REQ-07; LGC-DMDC-010, LGC-DMDC-018 |
| Tác nhân, quyền | DS (○), TA, PA (`COMMON`); `PERM-07-update` |
| Tiền điều kiện | Bản nháp `DRAFT`; thuộc tính tồn tại trong bản nháp; với HYBRID chỉ sửa được thuộc tính không kế thừa |
| Đầu ra | `200` (sửa, sắp thứ tự) hoặc `204` (xóa); phản hồi kèm `compatibility`: `{breaking: bool, reasons: [..], affectedItems: n}` |
| Hậu điều kiện | Định nghĩa thuộc tính được cập nhật hoặc xóa khỏi bản nháp; giá trị trong `attrs` của bản ghi bản nháp được chuyển đổi (đổi kiểu) hoặc xóa khóa (xóa thuộc tính); `schema_hash` tính lại; `stats.breaking` của bản nháp được cập nhật |
| Sự kiện phát ra | Không |
| Kiểm toán | `RDM_ATTRIBUTE_UPDATE` / `RDM_ATTRIBUTE_DELETE` / `RDM_ATTRIBUTE_REORDER`, giá trị trước, sau và kết luận tương thích |

Đầu vào của thao tác sửa (API-07-024) là JSON Merge Patch gồm các trường như FR-07-005 trừ `code`; thao tác sắp thứ tự là một danh sách `[{code, sortOrder}]` gửi cùng API-07-024 với `attrCode = _order`; thao tác xóa (API-07-025) không có thân. Bảng dưới đây là quy tắc tương thích, quyết định thay đổi nào được phép, thay đổi nào là phá vỡ (BR-07-013) và khi nào hệ thống chặn.

| Thay đổi | Điều kiện được phép | Phá vỡ? | Hành vi với dữ liệu |
|---|---|---|---|
| Sửa `label`, `description`, `sortOrder` | Luôn | Không | Không đổi dữ liệu |
| Đổi `status` sang `HIDDEN` | Luôn | Có (HTTT mất trường) | Giữ giá trị |
| Đổi `status` từ `HIDDEN` sang `ACTIVE` | Luôn | Không | |
| Bật `required` | Mọi bản ghi `ACTIVE` có giá trị, hoặc có `defaultValue` để điền | Có (thu hẹp) | Điền mặc định |
| Tắt `required` | Luôn | Không | |
| Bật `uniqueInVersion` | Không có giá trị trùng | Có | |
| Giảm `maxLength`, thêm hoặc đổi `pattern`, tăng `minValue`, giảm `maxValue`, bỏ phần tử `enumValues` | Mọi giá trị hiện có thỏa ràng buộc mới | Có (thu hẹp) | Không đổi |
| Tăng `maxLength`, bỏ `pattern`, nới khoảng giá trị, thêm phần tử `enumValues` | Luôn | Không | |
| Đổi `dataType` | Mọi giá trị hiện có chuyển đổi được theo bảng chuyển đổi kiểu dưới đây | Có | Chuyển đổi giá trị trong cùng giao dịch |
| Đổi `refCatalogCode` | Mọi giá trị hiện có tồn tại trong danh mục đích mới | Có | |
| Bật hoặc tắt `queryable`, `searchable` | Giới hạn số `queryable` | Không | Tạo hoặc xóa chỉ mục khi phát hành |
| Xóa thuộc tính | Thuộc tính tồn tại ở phiên bản gốc: luôn được nhưng là phá vỡ; thuộc tính mới thêm trong nháp: luôn được | Có nếu đã từng phát hành | Xóa khóa khỏi `attrs` của bản ghi bản nháp |

Bảng chuyển đổi kiểu xác định cặp kiểu nào đổi được và cách chuyển giá trị; cặp không có trong bảng bị từ chối với `ERR-07-014`.

| Từ | Sang | Quy tắc chuyển giá trị |
|---|---|---|
| `STRING` | `TEXT` | Giữ nguyên |
| `TEXT` | `STRING` | Được nếu mọi giá trị ≤ `maxLength` mới và không chứa xuống dòng |
| `STRING` | `INTEGER`, `DECIMAL`, `DATE`, `DATETIME`, `BOOLEAN`, `URI`, `EMAIL` | Được nếu mọi giá trị khác rỗng phân tích được theo quy tắc nhập tệp của kiểu đích (mục 4.4) |
| `STRING` | `ENUM` | Được nếu tập giá trị khác rỗng là tập con của `enumValues` mới (so khớp sau chuẩn hóa `T-CODE`) |
| `STRING` | `CATALOG_REF` | Được nếu mọi giá trị là mã tồn tại trong danh mục đích |
| `INTEGER` | `DECIMAL`, `STRING` | Giữ giá trị, đổi biểu diễn |
| `DECIMAL` | `INTEGER` | Được nếu mọi giá trị không có phần thập phân khác 0 |
| `DATE` | `DATETIME` | Ghép 00:00:00 giờ Việt Nam |
| `ENUM`, `CATALOG_REF`, `BOOLEAN`, `DATE`, `DATETIME`, `URI`, `EMAIL` | `STRING` | Giữ dạng chuỗi chuẩn |

Xử lý gồm các bước sau.

1. Hệ thống kiểm tra bản nháp ở `DRAFT`, `If-Match` của phiên bản, quyền và thuộc tính không phải thuộc tính kế thừa của HYBRID.
2. Hệ thống tính tập thay đổi giữa định nghĩa cũ và mới.
3. Với mỗi thay đổi, hệ thống quét toàn bộ bản ghi của bản nháp để kiểm tra điều kiện được phép theo bảng tương thích; dừng sớm khi gặp 100 vi phạm đầu tiên.
4. Nếu có vi phạm, hệ thống trả `ERR-07-014` với `errors` gồm tối đa 100 mục `{itemCode, value, reason}` và không thay đổi gì.
5. Nếu được phép, hệ thống áp thay đổi định nghĩa và chuyển đổi dữ liệu trong cùng một giao dịch.
6. Hệ thống đánh giá thay đổi là phá vỡ hay không so với phiên bản gốc của bản nháp (không so với trạng thái nháp trước đó, để việc sửa đi sửa lại trong nháp không tạo phá vỡ giả); cập nhật `stats.breaking` và trả khối `compatibility`.
7. Hệ thống tính lại `schema_hash`, tăng `version` của phiên bản và ghi kiểm toán.

Các ngoại lệ được liệt kê trong bảng sau.

| Điều kiện | Mã lỗi | HTTP | Hành vi |
|---|---|---|---|
| Không thấy thuộc tính | ERR-07-009 | 422 | `errors[0].field = attrCode` |
| Phiên bản không `DRAFT` | ERR-07-004 | 409 | |
| Dữ liệu hiện có không tương thích | ERR-07-014 | 422 | Liệt kê vi phạm |
| Sửa thuộc tính kế thừa của HYBRID, danh mục `NATIONAL` | ERR-07-003 | 403 | |
| ETag không khớp | ERR-07-018 | 412 | |

#### FR-07-007 · Cấu hình phân cấp

Chức năng này bật, tắt và cấu hình phân cấp của danh mục: danh mục có phải dạng cây không, số cấp tối đa, tên từng cấp. Vì cấu hình phân cấp ràng buộc dữ liệu bản ghi, thay đổi được kiểm tra trên bản nháp và có hiệu lực khi bản nháp phát hành.

| Trường | Nội dung |
|---|---|
| Mã, tên | FR-07-007 · Cấu hình phân cấp (cây theo mã cha, số cấp tối đa, tên cấp) |
| Mức ưu tiên | M |
| Truy vết | REQ-07; LGC-DMDC-002 |
| Tác nhân, quyền | DS (○), TA, PA (`COMMON`); `PERM-07-update` |
| Tiền điều kiện | Danh mục có bản nháp `DRAFT`; danh mục không `NATIONAL`, không HYBRID (HYBRID kế thừa cấu hình phân cấp của danh mục gốc) |
| Đầu ra | `200` với cấu hình mới và kết quả kiểm tra cây |
| Hậu điều kiện | Cấu hình phân cấp được ghi vào bản nháp (trường `stats.hierarchy` của phiên bản) và đồng bộ lên `catalog` khi phát hành; `depth`, `path`, `level_name` của bản ghi bản nháp được tính lại |
| Sự kiện phát ra | Không |
| Kiểm toán | `RDM_HIERARCHY_UPDATE`, giá trị trước và sau |

Đầu vào là các trường cấu hình phân cấp gửi qua API-07-004 với tiền tố `hierarchy` (áp vào bản nháp) hoặc ở bước 3 của trình hướng dẫn tạo danh mục; bảng dưới mô tả.

| Trường | Kiểu | Bắt buộc | Ràng buộc | Ví dụ |
|---|---|---|---|---|
| `hierarchy.isHierarchical` | T-BOOL | Có | | `true` |
| `hierarchy.maxDepth` | T-INT | Khi `true` | 2…10 (BR-07-014) | `2` |
| `hierarchy.levelNames` | Mảng T-NAME | Không | Độ dài = `maxDepth` | `["Tỉnh","Xã"]` |

Xử lý gồm các bước sau.

1. Hệ thống kiểm tra quyền, bản nháp, nguồn.
2. Nếu tắt phân cấp: mọi bản ghi phải có `parent_code` rỗng, nếu không trả `ERR-07-010` kèm số bản ghi có mã cha; người dùng phải xóa mã cha trước (hoặc nhập lại tệp với cột `MA_CHA` trống). Tắt phân cấp là thay đổi phá vỡ.
3. Nếu bật hoặc đổi `maxDepth`: hệ thống dựng cây từ `parent_code` của bản nháp, kiểm tra mã cha tồn tại, không vòng, độ sâu ≤ `maxDepth`; giảm `maxDepth` dưới độ sâu thực tế trả `ERR-07-011` kèm danh sách bản ghi vượt cấp. Giảm `maxDepth` là thay đổi phá vỡ; tăng thì không.
4. Hệ thống tính lại `depth`, `path`, `level_name` cho mọi bản ghi và lưu.
5. Hệ thống tăng `version` của bản nháp và ghi kiểm toán.

Các ngoại lệ được liệt kê trong bảng sau.

| Điều kiện | Mã lỗi | HTTP | Hành vi |
|---|---|---|---|
| Còn bản ghi có mã cha khi tắt phân cấp, mã cha không tồn tại, có vòng | ERR-07-010 | 422 | Liệt kê tối đa 100 bản ghi |
| Độ sâu thực tế vượt `maxDepth` mới | ERR-07-011 | 422 | |
| Danh mục HYBRID hoặc `NATIONAL` | ERR-07-003 | 403 | |
| Không có bản nháp | ERR-07-006 | 404 | Gợi ý tạo bản nháp (FR-07-011) |

#### FR-07-008 · Thiết lập nguồn và quyền cập nhật

Chức năng này thiết lập nguồn của danh mục (LOCAL, NATIONAL, HYBRID) và dải mã địa phương, thay cho cờ `Is_update` của Aita vốn chỉ cho biết nguồn mà không ngăn sửa (LGC-DMDC-017). Ở Datahub, nguồn quyết định trực tiếp ai được ghi và qua kênh nào.

| Trường | Nội dung |
|---|---|
| Mã, tên | FR-07-008 · Thiết lập nguồn và quyền cập nhật (LOCAL/NATIONAL/HYBRID, dải mã địa phương) |
| Mức ưu tiên | M |
| Truy vết | REQ-07; LGC-DMDC-017 |
| Tác nhân, quyền | TA, PA (`COMMON`); `PERM-07-update`. DS chỉ được đặt khi tạo danh mục (FR-07-003) |
| Tiền điều kiện | Danh mục tồn tại, không `RETIRED`, không có phiên bản `IN_REVIEW` hoặc `APPROVED` |
| Đầu ra | `200` với thông tin danh mục mới |
| Hậu điều kiện | `source_type`, `local_code_pattern`, `extends_catalog_id` được cập nhật theo bảng chuyển nguồn dưới đây |
| Sự kiện phát ra | EVT-07-02 với trường `sourceType` trong danh sách trường đã đổi |
| Kiểm toán | `RDM_CATALOG_SOURCE_CHANGE`, giá trị trước, sau, lý do |

Đầu vào gồm các trường `sourceType`, `localCodePattern`, `reason` (bắt buộc, 10…1.000 ký tự) gửi qua API-07-004. Bảng dưới đây quy định các chuyển đổi nguồn được phép, vì không phải mọi chuyển đổi đều có ý nghĩa nghiệp vụ.

| Từ | Sang | Điều kiện | Hệ quả |
|---|---|---|---|
| `LOCAL` | `NATIONAL` | Chỉ qua FR-07-038 khi đăng ký nguồn đồng bộ và lần đồng bộ đầu tiên được xác nhận | Danh mục trở thành chỉ đọc; phiên bản đồng bộ đầu tiên được so sánh với phiên bản `LOCAL` cuối |
| `NATIONAL` | `LOCAL` | Nguồn đồng bộ bị tắt; cần PA (với `COMMON`) hoặc TA và lý do (ví dụ quốc gia ngừng cung cấp danh mục) | Danh mục trở thành tự quản; lịch sử phiên bản giữ nguyên |
| `LOCAL` | `HYBRID` | Không được | Phải tạo danh mục HYBRID mới, vì bản ghi `LOCAL` hiện có không phân biệt được bản ghi nào là bổ sung |
| `HYBRID` | `LOCAL` | Không được | Như trên |
| Bất kỳ | Bất kỳ, chỉ đổi `localCodePattern` (HYBRID) | Mọi bản ghi bổ sung hiện có vẫn khớp biểu thức mới và biểu thức mới không khớp mã nào của danh mục gốc | Thay đổi thu hẹp dải là phá vỡ |

Xử lý gồm các bước sau.

1. Hệ thống kiểm tra quyền, `If-Match`, trạng thái danh mục và phiên bản mở.
2. Hệ thống kiểm tra cặp chuyển đổi có trong bảng trên; nếu không trả `ERR-07-004` với thông điệp nêu cách làm thay thế.
3. Với đổi `localCodePattern`, hệ thống kiểm tra mọi bản ghi bổ sung (của mọi phiên bản đã phát hành và bản nháp) khớp biểu thức mới; vi phạm trả `ERR-07-012`.
4. Hệ thống cập nhật, ghi outbox EVT-07-02 và kiểm toán.

Các ngoại lệ được liệt kê trong bảng sau.

| Điều kiện | Mã lỗi | HTTP | Hành vi |
|---|---|---|---|
| Chuyển nguồn không được phép, hoặc có phiên bản đang chờ duyệt | ERR-07-004 | 409 | |
| Bản ghi bổ sung không khớp dải mới hoặc dải chồng mã gốc | ERR-07-012 | 422 | |
| Tenant tỉnh sửa danh mục `COMMON` | ERR-07-003 | 403 | |

#### FR-07-009 · Xóa danh mục chưa phát hành; ngừng hiệu lực danh mục đã phát hành

Chức năng này thay chức năng "xóa danh mục" của Aita, vốn xóa hẳn dữ liệu kể cả khi HTTT đang dùng. Ở Datahub, danh mục chưa từng phát hành được xóa mềm; danh mục đã phát hành chỉ được ngừng hiệu lực, giữ nguyên lịch sử để dữ liệu cũ vẫn tra được.

| Trường | Nội dung |
|---|---|
| Mã, tên | FR-07-009 · Xóa danh mục chưa phát hành; ngừng hiệu lực danh mục đã phát hành |
| Mức ưu tiên | M |
| Truy vết | REQ-07; LGC-DMDC-012 |
| Tác nhân, quyền | Xóa: DS (○), TA, PA (`COMMON`) với `PERM-07-update`. Ngừng hiệu lực: TA, PA (`COMMON`) với `PERM-07-retire` (đề xuất bổ sung D02-08) |
| Tiền điều kiện | Xóa: `catalog.status = DRAFT`. Ngừng hiệu lực: `catalog.status = ACTIVE`, không có phiên bản mở ở `IN_REVIEW`/`APPROVED` |
| Đầu ra | Xóa: `204`. Ngừng hiệu lực: `200` với danh mục trạng thái `RETIRED` |
| Hậu điều kiện | Xóa: `deleted_at` được gán, phiên bản nháp chuyển `DISCARDED`, tác vụ nhập đang mở bị hủy; dữ liệu giữ 30 ngày rồi xóa vật lý (FR-00-051). Ngừng hiệu lực: `status = RETIRED`; `effective_to` của phiên bản hiện hành được gán bằng `retireDate`; bản nháp `DRAFT` (nếu có) chuyển `DISCARDED`; nguồn đồng bộ (nếu có) bị tắt; bộ đệm được làm mới |
| Sự kiện phát ra | Ngừng hiệu lực: EVT-07-03 `{tenant}.rdm.catalog.retired.v1` với `catalogCode`, `retireDate`, `reason`, `replacementCatalogCode`. Xóa: không phát (danh mục chưa từng công bố cho HTTT) |
| Kiểm toán | `RDM_CATALOG_DELETE` hoặc `RDM_CATALOG_RETIRE`, kèm lý do |

Đầu vào của thao tác ngừng hiệu lực (API-07-006) được mô tả trong bảng sau; thao tác xóa (API-07-005) chỉ cần `If-Match` và xác nhận ở giao diện (FR-00-050).

| Trường | Kiểu | Bắt buộc | Ràng buộc | Ví dụ |
|---|---|---|---|---|
| `retireDate` | T-DATE | Có | ≥ hôm nay; > `effective_from` của phiên bản hiện hành | `2027-01-01` |
| `reason` | T-TEXT | Có | 10…1.000 ký tự (FR-00-050) | `Thay bằng danh mục LOAI_HINH_DN_2027` |
| `legalBasis` | T-TEXT | Không | ≤ 1.000 | `Quyết định 45/QĐ-UBND ngày 01/12/2026` |
| `replacementCatalogCode` | T-CODE | Không | Danh mục tồn tại, `ACTIVE` | `LOAI_HINH_DN_2027` |

Xử lý của thao tác ngừng hiệu lực gồm các bước sau.

1. Hệ thống kiểm tra quyền `PERM-07-retire`, `If-Match`, trạng thái danh mục.
2. Hệ thống kiểm tra danh mục không bị thuộc tính `CATALOG_REF` của phiên bản hiệu lực của bất kỳ danh mục `ACTIVE` nào khác (trong tenant và, với danh mục `COMMON`, ở mọi tenant) tham chiếu (BR-07-020); nếu có trả `ERR-07-032` kèm danh sách danh mục tham chiếu.
3. Hệ thống kiểm tra danh mục không là danh mục gốc của danh mục HYBRID `ACTIVE` nào; nếu có trả `ERR-07-032`.
4. Hệ thống cảnh báo (không chặn) số bảng ánh xạ và số HTTT đã tra cứu danh mục trong 30 ngày, để người dùng cân nhắc.
5. Hệ thống trong một giao dịch: gán `effective_to` của phiên bản hiện hành, hủy bản nháp nếu có, tắt nguồn đồng bộ, đổi `status = RETIRED`, ghi outbox EVT-07-03 và kiểm toán.
6. Từ ngày `retireDate`, API khai thác trả `ERR-07-031` cho tra cứu tại thời điểm ≥ `retireDate`; tra cứu tại thời điểm trước đó vẫn trả dữ liệu lịch sử.

Xử lý của thao tác xóa gồm các bước sau.

1. Hệ thống kiểm tra quyền, `If-Match`, `status = DRAFT`.
2. Hệ thống gán `deleted_at`, chuyển bản nháp sang `DISCARDED`, hủy tác vụ nhập chưa kết thúc, ghi kiểm toán.

Các ngoại lệ được liệt kê trong bảng sau.

| Điều kiện | Mã lỗi | HTTP | Hành vi |
|---|---|---|---|
| Xóa danh mục đã phát hành | ERR-07-004 | 409 | Thông điệp hướng dẫn dùng ngừng hiệu lực |
| Ngừng hiệu lực danh mục đang bị tham chiếu | ERR-07-032 | 409 | Liệt kê danh mục tham chiếu |
| Danh mục đã `RETIRED` | ERR-07-031 | 410 | |
| Có phiên bản đang chờ duyệt hoặc đã duyệt | ERR-07-004 | 409 | |
| `retireDate` không hợp lệ | ERR-07-017 | 422 | |
| Danh mục `NATIONAL` đang đồng bộ, tenant tỉnh với `COMMON` | ERR-07-003 | 403 | Danh mục `NATIONAL` phải chuyển về `LOCAL` hoặc PA ngừng ở `COMMON` |

#### FR-07-010 · Quản lý nhóm danh mục

Chức năng này quản lý cây nhóm danh mục để phân loại danh mục khi hiển thị (mục 4.3).

| Trường | Nội dung |
|---|---|
| Mã, tên | FR-07-010 · Quản lý nhóm danh mục (cây phân loại danh mục) |
| Mức ưu tiên | S |
| Truy vết | REQ-07; mới |
| Tác nhân, quyền | Xem: `PERM-07-read`. Tạo, sửa, xóa: TA, PA (`COMMON`) với `PERM-07-create`/`update`; DS không quản lý nhóm vì nhóm dùng chung cho mọi tổ chức trong tỉnh |
| Tiền điều kiện | Không |
| Đầu ra | API-07-007 trả cây nhóm (tenant và `COMMON`) kèm số danh mục mỗi nhóm; API-07-008, 009 trả nhóm; API-07-010 trả `204` |
| Hậu điều kiện | `catalog_group` được tạo, sửa hoặc xóa mềm |
| Sự kiện phát ra | Không |
| Kiểm toán | `RDM_GROUP_CREATE` / `UPDATE` / `DELETE` |

Đầu vào của thao tác tạo, sửa được mô tả trong bảng sau.

| Trường | Kiểu | Bắt buộc | Ràng buộc | Ví dụ |
|---|---|---|---|---|
| `code` | T-CODE | Có (tạo) | Duy nhất trong tenant; không sửa sau khi tạo | `HANH_CHINH` |
| `name` | T-NAME | Có | 1…255 | `Hành chính` |
| `parentId` | T-ID | Không | Nhóm tồn tại cùng tenant; không tạo vòng; độ sâu ≤ 5 | |
| `sortOrder` | T-INT | Không | Mặc định 0 | `10` |
| `description` | T-TEXT | Không | ≤ 4.000 | |

Xử lý gồm các bước sau.

1. Khi tạo, hệ thống kiểm tra mã duy nhất, nhóm cha tồn tại, độ sâu ≤ 5.
2. Khi sửa `parentId`, hệ thống kiểm tra nhóm cha mới không phải chính nó hoặc hậu duệ của nó.
3. Khi xóa, hệ thống kiểm tra nhóm không còn danh mục (kể cả danh mục `RETIRED`) và không còn nhóm con; nếu còn trả `ERR-07-037`.
4. Hệ thống ghi kiểm toán.

Các ngoại lệ được liệt kê trong bảng sau.

| Điều kiện | Mã lỗi | HTTP | Hành vi |
|---|---|---|---|
| Mã nhóm trùng, nhóm cha tạo vòng hoặc vượt độ sâu | ERR-07-041 (mới) | 409 | |
| Nhóm còn danh mục hoặc nhóm con | ERR-07-037 | 409 | |
| Tenant tỉnh sửa nhóm `COMMON` | ERR-07-003 | 403 | |

### 5.2. Nhóm B — Bản ghi và phiên bản

#### FR-07-011 · Tạo bản nháp phiên bản mới từ phiên bản hiện hành

Chức năng này mở một bản nháp để soạn thay đổi. Bản nháp là bản sao đầy đủ của phiên bản gốc (copy-on-write), nên người dùng sửa thoải mái mà HTTT vẫn đọc phiên bản đang hiệu lực không bị ảnh hưởng. Đây là điểm khác căn bản với Aita, nơi mọi sửa đổi đi thẳng vào dữ liệu đang dùng.

| Trường | Nội dung |
|---|---|
| Mã, tên | FR-07-011 · Tạo bản nháp phiên bản mới từ phiên bản hiện hành |
| Mức ưu tiên | M |
| Truy vết | REQ-07, BP-03; LGC-DMDC-011 |
| Tác nhân, quyền | DS (○), TA, PA (`COMMON`); `PERM-07-create`. Nội bộ: tiến trình đồng bộ (FR-07-036), nhập lô API (FR-07-023, tự mở nháp nếu cấu hình cho phép) |
| Tiền điều kiện | Danh mục `ACTIVE`; không `NATIONAL` (trừ tiến trình đồng bộ); không có phiên bản mở (BR-07-005) |
| Đầu ra | `201` với chi tiết phiên bản nháp: `versionNo` mới, `baseVersionNo`, `status = DRAFT`, `itemCount`, ETag |
| Hậu điều kiện | Một `catalog_version` mới `DRAFT` với `version_no = max + 1`, `origin` theo nguồn tạo; mọi `attribute_def` và `catalog_item` của phiên bản gốc được sao chép sang phiên bản mới (định danh mới, cùng mã); với ĐVHC, không sao chép `item_succession` (sự kiện sắp xếp thuộc phiên bản ghi nhận) |
| Sự kiện phát ra | Không |
| Kiểm toán | `RDM_VERSION_CREATE`, `baseVersionNo`, `versionNo`, `origin` |

Đầu vào của API-07-012 được mô tả trong bảng sau.

| Trường | Kiểu | Bắt buộc | Ràng buộc | Ví dụ |
|---|---|---|---|---|
| `baseVersionNo` | T-INT | Không | Phiên bản đã phát hành của danh mục; mặc định là phiên bản có `effective_from` lớn nhất (kể cả phiên bản sắp hiệu lực), không phải phiên bản đang hiệu lực, để không làm mất thay đổi đã phát hành nhưng chưa tới ngày | `4` |
| `effectiveFrom` | T-DATE | Không | Ngày hiệu lực dự kiến; > `effective_from` của phiên bản gốc | `2027-01-01` |
| `changeNote` | T-TEXT | Không | ≤ 4.000 | `Bổ sung loại hình mới theo QĐ 12` |

Xử lý gồm các bước sau.

1. Hệ thống khóa dòng danh mục (`SELECT … FOR UPDATE`) để tuần tự hóa các yêu cầu tạo bản nháp đồng thời.
2. Hệ thống kiểm tra không có phiên bản ở `DRAFT`, `IN_REVIEW`, `APPROVED`; có thì trả `ERR-07-005` kèm số phiên bản đang mở và người đang soạn.
3. Hệ thống xác định phiên bản gốc theo `baseVersionNo` hoặc mặc định; nếu người dùng chọn một phiên bản cũ hơn phiên bản mới nhất, hệ thống cảnh báo rằng các thay đổi của phiên bản mới hơn sẽ không có trong bản nháp và sẽ hiện thành khác biệt khi so sánh.
4. Hệ thống tạo `catalog_version` mới và sao chép thuộc tính, bản ghi bằng câu lệnh `INSERT … SELECT` trong cùng giao dịch; với danh mục 200.000 bản ghi, thao tác phải xong trong 10 giây (NFR-07-011). Nếu dự kiến vượt 3 giây, giao diện hiện tiến độ (FR-00-054).
5. Hệ thống đặt `stats` của bản nháp về `{added: 0, changed: 0, deprecated: 0, breaking: false}` và ghi kiểm toán.

Các ngoại lệ được liệt kê trong bảng sau.

| Điều kiện | Mã lỗi | HTTP | Hành vi |
|---|---|---|---|
| Đã có phiên bản mở | ERR-07-005 | 409 | Trả số phiên bản mở |
| Danh mục chưa phát hành (đã có nháp số 1) | ERR-07-005 | 409 | |
| Danh mục `NATIONAL` hoặc `COMMON` với tenant tỉnh | ERR-07-003 | 403 | |
| Danh mục `RETIRED` | ERR-07-031 | 410 | |
| `baseVersionNo` không phải phiên bản đã phát hành | ERR-07-006 | 404 | |
| `effectiveFrom` không lớn hơn phiên bản gốc | ERR-07-017 | 422 | |

#### FR-07-012 · Thêm, sửa, ngừng dùng bản ghi trên bản nháp

Chức năng này là thao tác soạn thảo hằng ngày trên bản nháp (UI-07-05): thêm bản ghi, sửa tên, mã cha, thứ tự, thuộc tính, ngừng dùng bản ghi, và xóa bản ghi mới thêm. Nó thay chức năng cập nhật danh sách bản ghi của Aita, với khác biệt là bản ghi đã từng phát hành không bị xóa.

| Trường | Nội dung |
|---|---|
| Mã, tên | FR-07-012 · Thêm, sửa, ngừng dùng bản ghi trên bản nháp |
| Mức ưu tiên | M |
| Truy vết | REQ-07, BP-03; LGC-DMDC-011 |
| Tác nhân, quyền | DS (○), TA, PA (`COMMON`); `PERM-07-update` |
| Tiền điều kiện | Bản nháp `DRAFT`; danh mục không `NATIONAL`; với HYBRID chỉ thao tác trên bản ghi bổ sung |
| Đầu ra | Thêm: `201` với bản ghi. Sửa: `200`. Ngừng dùng: `200`. Xóa: `204`. Mọi phản hồi kèm ETag mới của bản nháp và `stats` cập nhật |
| Hậu điều kiện | Bản ghi được thêm, sửa, chuyển `DEPRECATED` hoặc xóa trong bản nháp; `depth`, `path`, `level_name` tính lại cho bản ghi và cây con khi mã cha đổi; `item_count`, `stats` của bản nháp cập nhật; `updated_by` của bản nháp là người thao tác (dùng cho bốn mắt) |
| Sự kiện phát ra | Không |
| Kiểm toán | `RDM_ITEM_CREATE` / `RDM_ITEM_UPDATE` / `RDM_ITEM_DEPRECATE` / `RDM_ITEM_DELETE`, đối tượng `catalog/{c}/version/{n}/item/{code}`, giá trị trước và sau các trường thay đổi |

Đầu vào của thao tác thêm (API-07-027) và sửa (API-07-028, JSON Merge Patch) được mô tả trong bảng sau.

| Trường | Kiểu | Bắt buộc | Ràng buộc | Ví dụ |
|---|---|---|---|---|
| `code` | T-CODE | Có (thêm); không sửa được | Chuẩn hóa chữ hoa; duy nhất trong bản nháp (BR-07-002); với HYBRID khớp `local_code_pattern` và không trùng mã danh mục gốc (BR-07-010); không trùng mã đã từng phát hành rồi bị xóa khỏi lịch sử (không có, vì không xóa) | `68L001` |
| `name` | T-NAME | Có | 1…255 ký tự | `Hợp tác xã nông nghiệp công nghệ cao` |
| `parentCode` | T-CODE | Không | Chỉ khi phân cấp; tồn tại trong bản nháp; không vòng; độ sâu ≤ `max_depth`; cha phải `ACTIVE` nếu bản ghi `ACTIVE` (BR-07-014) | `68L000` |
| `sortOrder` | T-INT | Không | Mặc định lớn nhất trong cùng cha + 10 | `20` |
| `validFrom`, `validTo` | T-DATE | Không | `validFrom` < `validTo`; nằm trong khoảng hiệu lực của phiên bản | |
| `attrs` | T-JSON | Theo lược đồ | Đối tượng có khóa là mã thuộc tính; kiểm tra theo JSON Schema của bản nháp | `{"loai_hinh":"HTX"}` |

Đầu vào của thao tác ngừng dùng (API-07-029) được mô tả trong bảng sau; thao tác xóa (API-07-030) không có thân.

| Trường | Kiểu | Bắt buộc | Ràng buộc | Ví dụ |
|---|---|---|---|---|
| `replacedBy` | Mảng T-CODE | Không | 0…50 mã; mỗi mã tồn tại và `ACTIVE` trong bản nháp; không chứa chính nó | `["68L010"]` |
| `reason` | T-TEXT | Không | ≤ 1.000 | `Gộp vào loại hình 68L010` |
| `cascade` | T-BOOL | Không | Mặc định `false`; `true` thì ngừng dùng cả cây con (vì BR-07-014 cấm con `ACTIVE` có cha `DEPRECATED`) | `false` |

Xử lý gồm các bước sau.

1. Hệ thống kiểm tra bản nháp ở `DRAFT`, `If-Match` với `version` của bản nháp (khóa lạc quan theo phiên bản, đơn giản hơn khóa theo từng bản ghi và đủ dùng vì một bản nháp thường do một người soạn; với bảng sửa trực tiếp, giao diện gửi `If-Match` theo `version` của bản ghi để hai người sửa hai bản ghi khác nhau không xung đột, xem Q07-04).
2. Hệ thống chuẩn hóa mã và tên, áp giá trị mặc định cho thuộc tính thiếu.
3. Hệ thống kiểm tra hợp lệ bản ghi theo FR-07-013 (kiểm tra mức bản ghi: kiểu, bắt buộc, mẫu, miền, tham chiếu, mã cha, vòng, độ sâu, duy nhất).
4. Khi ngừng dùng: nếu bản ghi có con `ACTIVE` và `cascade = false` thì trả `ERR-07-010` với danh sách con; nếu `cascade = true` thì ngừng dùng cả cây con. Ngừng dùng là thay đổi phá vỡ.
5. Khi xóa: nếu mã đã xuất hiện ở bất kỳ phiên bản đã phát hành nào thì trả `ERR-07-013`; nếu bản ghi có con trong bản nháp thì trả `ERR-07-010`.
6. Khi sửa `parentCode`: hệ thống kiểm tra không vòng (cha mới không thuộc cây con của bản ghi), tính lại `depth`, `path` cho bản ghi và toàn bộ cây con, kiểm tra độ sâu cây con sau khi dời không vượt `max_depth`. Đổi mã cha của bản ghi đã từng phát hành là thay đổi phá vỡ.
7. Hệ thống ghi thay đổi, cập nhật `stats` (đếm lại theo so sánh với phiên bản gốc), tăng `version` của bản nháp, ghi kiểm toán, trong một giao dịch.

> **Câu hỏi mở Q07-04:** Cần xác nhận với người dùng có nhu cầu nhiều người cùng soạn một bản nháp đồng thời hay không. Nếu có, khóa lạc quan theo từng bản ghi (cột `version` của `catalog_item`) được dùng cho sửa bản ghi, còn khóa theo phiên bản chỉ dùng cho thao tác lược đồ và chuyển trạng thái; FRS đề xuất phương án này làm mặc định.

Các ngoại lệ được liệt kê trong bảng sau.

| Điều kiện | Mã lỗi | HTTP | Hành vi |
|---|---|---|---|
| Mã trùng trong bản nháp | ERR-07-008 | 409 | |
| Thuộc tính sai lược đồ | ERR-07-009 | 422 | `errors` theo thuộc tính |
| Mã cha không tồn tại, tạo vòng, cha `DEPRECATED`, còn con `ACTIVE` khi ngừng dùng không cascade | ERR-07-010 | 422 | |
| Vượt `max_depth` | ERR-07-011 | 422 | |
| Mã ngoài dải địa phương hoặc trùng mã gốc (HYBRID) | ERR-07-012 | 422 | |
| Xóa bản ghi đã từng phát hành | ERR-07-013 | 409 | Hướng dẫn dùng ngừng dùng |
| Bản nháp không `DRAFT` | ERR-07-004 | 409 | |
| Danh mục `NATIONAL`, sửa bản ghi kế thừa của HYBRID | ERR-07-003 | 403 | |
| Không tìm thấy mã bản ghi trong bản nháp | ERR-07-007 | 404 | |
| ETag không khớp | ERR-07-018 | 412 | |

#### FR-07-013 · Kiểm tra hợp lệ bản ghi theo lược đồ

Chức năng này là bộ kiểm tra dùng chung cho mọi đường ghi dữ liệu (nhập tay, nhập tệp, nhập lô API, đồng bộ, di trú) và có thể được gọi tường minh để kiểm tra toàn bộ bản nháp trước khi trình (API-07-016). Dùng một bộ kiểm tra duy nhất bảo đảm cùng một bản ghi cho cùng một kết luận dù đi qua kênh nào.

| Trường | Nội dung |
|---|---|
| Mã, tên | FR-07-013 · Kiểm tra hợp lệ bản ghi theo lược đồ (kiểu, bắt buộc, duy nhất, mã cha, vòng, độ sâu) |
| Mức ưu tiên | M |
| Truy vết | REQ-07, BP-03; mới |
| Tác nhân, quyền | Gọi tường minh: người có `PERM-07-update` hoặc `PERM-07-publish`; gọi ngầm: mọi FR ghi bản ghi |
| Tiền điều kiện | Phiên bản tồn tại (kiểm tra được cả phiên bản đã phát hành để chẩn đoán, nhưng không sửa) |
| Đầu ra | `200` với `{valid: bool, errorCount, warningCount, errors: [{itemCode, field, code, message, severity}], checkedAt}`; tối đa 1.000 lỗi trong phản hồi, đầy đủ tải qua `?format=xlsx` |
| Hậu điều kiện | Kết quả kiểm tra gần nhất được lưu vào `stats.validation` của phiên bản kèm `version` của phiên bản tại thời điểm kiểm tra; thao tác trình duyệt dùng kết quả này nếu `version` không đổi |
| Sự kiện phát ra | Không |
| Kiểm toán | Không ghi kiểm toán cho kiểm tra (không thay đổi dữ liệu nghiệp vụ) |

Đầu vào của API-07-016 gồm `{c}`, `{v}` và tùy chọn `level` (`ITEM`, `FULL`, mặc định `FULL`). Bảng dưới đây là danh mục các quy tắc kiểm tra, mã quy tắc dùng trong trường `errors[].code` (để giao diện và báo cáo lỗi nhập tệp hiển thị nhất quán), mức nghiêm trọng và mức kiểm tra.

| Mã quy tắc | Nội dung kiểm tra | Mức | Phạm vi |
|---|---|---|---|
| `CODE_REQUIRED` | Mã khác rỗng | Lỗi | Bản ghi |
| `CODE_FORMAT` | Mã khớp mẫu T-CODE sau chuẩn hóa chữ hoa | Lỗi | Bản ghi |
| `CODE_DUPLICATE` | Mã không trùng trong phiên bản (so sánh không phân biệt hoa thường, BR-07-002) | Lỗi | Liên bản ghi |
| `CODE_OUT_OF_RANGE` | HYBRID: mã khớp `local_code_pattern`, không trùng mã gốc (BR-07-010) | Lỗi | Bản ghi |
| `NAME_REQUIRED`, `NAME_TOO_LONG` | Tên khác rỗng, ≤ 255 ký tự | Lỗi | Bản ghi |
| `ATTR_REQUIRED` | Thuộc tính `required` có giá trị với bản ghi `ACTIVE` | Lỗi | Bản ghi |
| `ATTR_TYPE` | Giá trị đúng kiểu (mục 4.4) | Lỗi | Bản ghi |
| `ATTR_MAX_LENGTH`, `ATTR_PATTERN`, `ATTR_RANGE`, `ATTR_ENUM` | Giá trị thỏa ràng buộc | Lỗi | Bản ghi |
| `ATTR_UNKNOWN` | Khóa trong `attrs` không có trong lược đồ | Lỗi khi nhập API; cảnh báo và bỏ qua khi nhập tệp có cột thừa | Bản ghi |
| `ATTR_UNIQUE` | Thuộc tính `unique_in_version` không trùng | Lỗi | Liên bản ghi |
| `ATTR_REF_NOT_FOUND` | Giá trị `CATALOG_REF` tồn tại và `ACTIVE` trong phiên bản hiệu lực của danh mục đích tại `effective_from` của phiên bản đang kiểm tra | Lỗi | Liên danh mục |
| `PARENT_NOT_FOUND` | Mã cha tồn tại trong phiên bản | Lỗi | Liên bản ghi |
| `PARENT_CYCLE` | Không có vòng | Lỗi | Liên bản ghi |
| `PARENT_DEPRECATED` | Bản ghi `ACTIVE` không có cha `DEPRECATED` | Lỗi | Liên bản ghi |
| `DEPTH_EXCEEDED` | Độ sâu ≤ `max_depth` | Lỗi | Liên bản ghi |
| `PARENT_NOT_ALLOWED` | Danh mục không phân cấp thì mã cha rỗng | Lỗi | Bản ghi |
| `REPLACED_BY_INVALID` | Mã thay thế tồn tại, `ACTIVE`, khác chính nó | Lỗi | Liên bản ghi |
| `VALIDITY_RANGE` | `validFrom` < `validTo` và nằm trong khoảng hiệu lực phiên bản | Lỗi | Bản ghi |
| `NAME_DUPLICATE_SIBLING` | Hai bản ghi `ACTIVE` cùng cha trùng tên (không dấu, không phân biệt hoa thường) | Cảnh báo | Liên bản ghi |
| `EMPTY_VERSION` | Phiên bản có ít nhất một bản ghi `ACTIVE` | Lỗi (chỉ khi trình, phát hành) | Phiên bản |
| `PII_SUSPECT` | Giá trị thuộc tính khớp mẫu số định danh cá nhân 12 chữ số hoặc số điện thoại di động | Cảnh báo | Bản ghi |

Xử lý của kiểm tra toàn bộ (`FULL`) gồm các bước sau.

1. Hệ thống sinh (hoặc lấy từ bộ đệm theo `schema_hash`) JSON Schema của phiên bản.
2. Hệ thống duyệt luồng mọi bản ghi theo lô 5.000, áp các quy tắc phạm vi "Bản ghi".
3. Hệ thống chạy các quy tắc liên bản ghi bằng truy vấn tập hợp trên CSDL (đếm trùng mã, trùng giá trị duy nhất; dựng cây bằng truy vấn đệ quy giới hạn độ sâu `max_depth + 1` để phát hiện vòng và vượt cấp).
4. Hệ thống kiểm tra tham chiếu `CATALOG_REF` bằng một truy vấn nối với phiên bản hiệu lực của từng danh mục đích.
5. Hệ thống tổng hợp kết quả, lưu vào `stats.validation` cùng `version` của phiên bản, trả phản hồi.
6. Kiểm tra toàn bộ trên bản nháp 200.000 bản ghi phải xong trong 30 giây; nếu dự kiến vượt 3 giây, API trả `202` kèm đường dẫn theo dõi tiến độ (FR-00-054).

Các ngoại lệ được liệt kê trong bảng sau.

| Điều kiện | Mã lỗi | HTTP | Hành vi |
|---|---|---|---|
| Không tìm thấy phiên bản | ERR-07-006 | 404 | |
| Gọi ngầm từ FR ghi mà bản ghi sai | ERR-07-009, 010, 011, 012, 008 | 422/409 | Theo quy tắc vi phạm đầu tiên nhóm theo mã lỗi; `errors` chứa toàn bộ vi phạm của bản ghi |

#### FR-07-014 · So sánh khác biệt giữa hai phiên bản, phân loại phá vỡ và không phá vỡ

Chức năng này tính và hiển thị khác biệt giữa hai phiên bản bất kỳ của cùng danh mục, đồng thời phân loại từng thay đổi là phá vỡ hay không phá vỡ. Đây là căn cứ để người duyệt quyết định (UI-07-07), để áp quy tắc bắt buộc duyệt (BR-07-012), để tính sự kiện phát hành và delta (FR-07-031), và để đồng bộ quốc gia quyết định tự áp dụng hay chờ xác nhận (FR-07-037). Vì có nhiều nơi dùng, thuật toán được đặc tả chính xác dưới đây.

| Trường | Nội dung |
|---|---|
| Mã, tên | FR-07-014 · So sánh khác biệt giữa hai phiên bản, phân loại phá vỡ/không phá vỡ |
| Mức ưu tiên | M |
| Truy vết | REQ-07, BP-03; mới |
| Tác nhân, quyền | Mọi người có `PERM-07-read`; nội bộ: FR-07-015, 016, 031, 036 |
| Tiền điều kiện | Hai phiên bản tồn tại và thuộc cùng danh mục |
| Đầu ra | `200` với khối `summary` và trang `changes` như mô tả ở bước 7; `?format=xlsx` trả tệp khác biệt |
| Hậu điều kiện | Khi so bản nháp với phiên bản gốc, `stats` của bản nháp được cập nhật |
| Sự kiện phát ra | Không |
| Kiểm toán | Không |

Đầu vào của API-07-021 được mô tả trong bảng sau.

| Tham số | Kiểu | Bắt buộc | Ràng buộc | Ví dụ |
|---|---|---|---|---|
| `{v}` | T-INT hoặc `draft`, `current` | Có | Phiên bản "sau" | `draft` |
| `against` | T-INT hoặc `current`, `base` | Không | Phiên bản "trước"; mặc định `base` (phiên bản gốc của bản nháp) hoặc phiên bản liền trước | `current` |
| `changeType` | T-ENUM[] | Không | Lọc `ADDED`, `CHANGED`, `DEPRECATED`, `REACTIVATED`, `REMOVED`, `ATTRIBUTE_*` | |
| `breakingOnly` | T-BOOL | Không | Chỉ thay đổi phá vỡ | `true` |
| `page`, `size` | T-INT | Không | `size` ≤ 200 | |

Thuật toán tính khác biệt gồm hai phần, khác biệt lược đồ và khác biệt bản ghi, và được thực hiện như sau.

1. **Ghép lược đồ.** Hệ thống ghép thuộc tính của hai phiên bản theo `code`. Thuộc tính chỉ có ở phiên bản sau là `ATTRIBUTE_ADDED`; chỉ có ở phiên bản trước là `ATTRIBUTE_REMOVED`; có ở cả hai thì so từng trường định nghĩa và sinh `ATTRIBUTE_TYPE_CHANGED` nếu `data_type` đổi, `ATTRIBUTE_CONSTRAINT_CHANGED` nếu ràng buộc đổi, `ATTRIBUTE_META_CHANGED` nếu chỉ nhãn, mô tả, thứ tự, cờ `queryable`, `searchable` đổi.
2. **Ghép bản ghi.** Hệ thống ghép bản ghi theo mã chuẩn hóa chữ hoa bằng một phép nối ngoài đầy đủ (full outer join) trên CSDL, không nạp toàn bộ vào bộ nhớ.
3. **Phân loại từng cặp bản ghi.** Mã chỉ có ở phiên bản sau là `ADDED`. Mã chỉ có ở phiên bản trước là `REMOVED` (chỉ xảy ra khi so phiên bản không liền kề có bản ghi mới thêm rồi bị xóa trong nháp, hoặc khi so với dữ liệu nguồn quốc gia). Mã có ở cả hai: nếu trạng thái từ `ACTIVE` sang `DEPRECATED` là `DEPRECATED`; từ `DEPRECATED` sang `ACTIVE` là `REACTIVATED`; ngược lại so các trường `name`, `parent_code`, `sort_order`, `replaced_by`, `valid_from`, `valid_to` và từng khóa trong `attrs` (chỉ khóa của thuộc tính có ở cả hai phiên bản; khóa của thuộc tính bị thêm hoặc xóa đã được tính ở bước 1, không tính lặp lại cho từng bản ghi); có ít nhất một trường khác là `CHANGED` kèm danh sách trường thay đổi và giá trị trước, sau; không trường nào khác là `UNCHANGED` (không trả về trừ khi yêu cầu).
4. **So sánh giá trị.** Chuỗi so sau chuẩn hóa NFC và cắt khoảng trắng hai đầu, phân biệt hoa thường (đổi hoa thường của tên là một thay đổi có ý nghĩa hiển thị). Số thập phân so theo giá trị (`1.50` bằng `1.5`). Ngày giờ so theo thời điểm UTC. Mảng `replaced_by` so như tập hợp không thứ tự. Giá trị rỗng, `null` và khóa vắng mặt được coi là bằng nhau.
5. **Phân loại phá vỡ.** Mỗi thay đổi được gắn cờ `breaking` theo bảng phân loại dưới đây (mục 3 §18 của khung chung và BR-07-013).
6. **Tổng hợp.** Hệ thống đếm `added`, `changed`, `deprecated`, `reactivated`, `removed`, `attributeChanges`, `breakingCount`, tính `changeRatio = (added + changed + deprecated + reactivated + removed) / max(1, itemCount của phiên bản trước)` và `breaking = breakingCount > 0`.
7. **Trả kết quả.** `summary` gồm các số đếm trên, `changeRatio`, `breaking`, `largeChange = changeRatio > ngưỡng` (tham số `07.rdm.large-change-threshold-percent`, mặc định 10); `changes` là trang các mục `{itemCode, changeType, breaking, fields: [{field, before, after}], breakingReasons}`, sắp xếp phá vỡ trước, sau đó theo mã.

Bảng phân loại phá vỡ dưới đây là nguồn sự thật duy nhất cho mọi nơi cần quyết định phá vỡ; mỗi dòng có lý do để người duyệt hiểu vì sao hệ thống cảnh báo.

| Thay đổi | Phá vỡ | Lý do |
|---|---|---|
| `ADDED` bản ghi | Không | HTTT cũ không biết mã mới nhưng không lỗi với dữ liệu hiện có |
| `CHANGED` tên, `sort_order`, thuộc tính giá trị | Không | Ý nghĩa mã giữ nguyên |
| `CHANGED` `parent_code` của bản ghi đã từng phát hành | Có | HTTT lọc theo cha hoặc hiển thị cây sẽ sai |
| `CHANGED` `valid_to` rút ngắn | Có | Mã hết hiệu lực sớm hơn dự kiến |
| `DEPRECATED` | Có | HTTT đang dùng mã phải chuyển sang mã khác |
| `REACTIVATED` | Không | Mã trở lại dùng được với nghĩa cũ |
| `REMOVED` | Có | Mã biến mất |
| `ATTRIBUTE_ADDED` không bắt buộc | Không | |
| `ATTRIBUTE_ADDED` bắt buộc | Có | HTTT gửi dữ liệu lên (nhập lô API) sẽ thiếu trường |
| `ATTRIBUTE_REMOVED`, thuộc tính chuyển `HIDDEN` | Có | HTTT đọc trường sẽ không còn giá trị |
| `ATTRIBUTE_TYPE_CHANGED` | Có | Bộ phân tích JSON của HTTT có thể lỗi |
| `ATTRIBUTE_CONSTRAINT_CHANGED` thu hẹp (giảm độ dài, thêm mẫu, thu hẹp khoảng, bỏ giá trị liệt kê, bật bắt buộc, bật duy nhất) | Có | Dữ liệu HTTT gửi lên hợp lệ trước đây có thể bị từ chối |
| `ATTRIBUTE_CONSTRAINT_CHANGED` nới rộng | Không | |
| `ATTRIBUTE_META_CHANGED` | Không | |
| Tắt phân cấp, giảm `max_depth`, thu hẹp `local_code_pattern` | Có | |

Các ngoại lệ được liệt kê trong bảng sau.

| Điều kiện | Mã lỗi | HTTP | Hành vi |
|---|---|---|---|
| Phiên bản không tồn tại hoặc khác danh mục | ERR-07-006 | 404 | |
| `size` > 200 | ERR-07-026 | 400 | |

#### FR-07-015 · Trình duyệt, duyệt, từ chối phiên bản

Chức năng này hiện thực máy trạng thái duyệt bốn mắt của PH-07 (quyết định nền §16): người soạn trình bản nháp, người duyệt khác người soạn xem khác biệt rồi duyệt hoặc từ chối. Việc chờ duyệt được đăng vào hộp "Việc của tôi" của PH-12 qua sự kiện, không dùng Flowable ở MVP vì luồng duyệt danh mục đơn giản, cố định và cần phản hồi nhanh.

| Trường | Nội dung |
|---|---|
| Mã, tên | FR-07-015 · Trình duyệt, duyệt, từ chối phiên bản (bốn mắt, ngưỡng thay đổi lớn) |
| Mức ưu tiên | M |
| Truy vết | REQ-07, BP-03; mới; tuân thủ FR-00-070, FR-00-071, FR-00-072 |
| Tác nhân, quyền | Trình, rút lại: DS (○), TA, PA (`COMMON`) với `PERM-07-submit`. Duyệt, từ chối, thu hồi duyệt: DA, PA (`COMMON`) với `PERM-07-publish` |
| Tiền điều kiện | Trình: bản nháp `DRAFT`, kiểm tra hợp lệ không có lỗi. Duyệt, từ chối: phiên bản `IN_REVIEW`. Thu hồi duyệt: phiên bản `APPROVED` |
| Đầu ra | `200` với phiên bản ở trạng thái mới, `diffSummary` |
| Hậu điều kiện | Trình: `status = IN_REVIEW`, `submitted_by/at` được gán, một dòng `version_review` `SUBMIT` kèm `diff_stats`. Duyệt: `status = APPROVED`, `approved_by/at`, dòng `APPROVE`. Từ chối: `status = DRAFT`, dòng `REJECT` kèm lý do. Rút lại hoặc thu hồi duyệt: `status = DRAFT`, dòng `version_review` hành động `SUBMIT` hoặc `APPROVE` kèm ghi chú "rút lại"/"thu hồi" |
| Sự kiện phát ra | Trình: EVT-07-04 `{tenant}.rdm.catalog.submitted.v1` (để PH-12 tạo việc cho người có `PERM-07-publish` phù hợp). Từ chối: EVT-07-06 `{tenant}.rdm.catalog.rejected.v1` (để PH-12 đóng việc, báo người trình). Duyệt: không có sự kiện riêng; PH-12 đóng việc khi nhận EVT-07-05 lúc phát hành hoặc qua lời gọi trực tiếp API đóng việc (xem Q07-05) |
| Kiểm toán | `RDM_VERSION_SUBMIT` / `APPROVE` / `REJECT` / `WITHDRAW` / `UNAPPROVE`, kèm ý kiến, `diff_stats` |

> **Câu hỏi mở Q07-05:** Khung chung không cấp sự kiện riêng cho thao tác duyệt (approved). Cần thống nhất với PH-12 cách đóng việc chờ duyệt khi phiên bản được duyệt mà chưa phát hành: dùng thêm sự kiện `{tenant}.rdm.catalog.approved.v1` (đề xuất mã EVT-07-11) hay PH-07 gọi API đóng việc của PH-12. FRS đề xuất thêm EVT-07-11 để thống nhất cơ chế.

Đầu vào của các thao tác (API-07-017, 018, 019) được mô tả trong bảng sau.

| Trường | Kiểu | Bắt buộc | Ràng buộc | Ví dụ |
|---|---|---|---|---|
| `comment` | T-TEXT | Có với duyệt và từ chối (FR-00-072); không bắt buộc khi trình | Từ chối: 10…4.000 ký tự; duyệt: 1…4.000 | `Đồng ý, đề nghị phát hành từ 01/01/2027` |
| `effectiveFrom` | T-DATE | Không (trình) | Cập nhật ngày hiệu lực dự kiến | `2027-01-01` |
| `legalBasis` | T-TEXT | Không (trình) | ≤ 1.000 | `Quyết định 12/QĐ-SKHĐT` |
| `action` | T-ENUM | Có với API-07-017 khi rút lại | `SUBMIT` (mặc định), `WITHDRAW` | |
| `action` | T-ENUM | Có với API-07-018 khi thu hồi | `APPROVE` (mặc định), `UNAPPROVE` | |

Xử lý của thao tác trình gồm các bước sau.

1. Hệ thống kiểm tra quyền `PERM-07-submit` (DS chỉ với danh mục của tổ chức mình), `If-Match`, `status = DRAFT`.
2. Hệ thống dùng kết quả kiểm tra hợp lệ trong `stats.validation` nếu `version` không đổi kể từ lần kiểm tra; ngược lại chạy FR-07-013 mức `FULL`. Còn lỗi thì trả `ERR-07-009` kèm số lỗi và đường dẫn tải báo cáo.
3. Hệ thống tính khác biệt với phiên bản gốc theo FR-07-014; khác biệt rỗng (không có thay đổi nào) thì từ chối với `ERR-07-004` và thông điệp "Bản nháp không có thay đổi so với phiên bản gốc".
4. Hệ thống chuyển `status = IN_REVIEW`, gán `submitted_by/at`, ghi `version_review` (`SUBMIT`, `diff_stats`), ghi outbox EVT-07-04 với `catalogCode`, `versionNo`, `submittedBy`, `diffSummary`, `ownerOrgId`, `requiredPermission = PERM-07-publish`, và kiểm toán.

Xử lý của thao tác duyệt gồm các bước sau.

1. Hệ thống kiểm tra quyền `PERM-07-publish`, `If-Match`, `status = IN_REVIEW`.
2. Hệ thống kiểm tra bốn mắt (BR-07-011): người duyệt khác `submitted_by` và khác người sửa nội dung cuối cùng của bản nháp (`updated_by` của phiên bản và người sửa cuối của mọi bản ghi, thuộc tính trong bản nháp); vi phạm trả `ERR-07-015`. Kiểm tra được thực hiện trên tập người đã sửa bản nháp (lấy từ cột `updated_by` của bản ghi và thuộc tính thuộc bản nháp) vì người đã đóng góp nội dung cũng không được tự duyệt.
3. Hệ thống chuyển `status = APPROVED`, gán `approved_by/at`, ghi `version_review` (`APPROVE`, ý kiến) và kiểm toán.

Xử lý của thao tác từ chối gồm các bước sau.

1. Hệ thống kiểm tra quyền, `If-Match`, `status = IN_REVIEW`, ý kiến từ 10 ký tự.
2. Hệ thống kiểm tra bốn mắt như thao tác duyệt (người trình không tự từ chối; người trình muốn sửa thì dùng rút lại).
3. Hệ thống chuyển `status = DRAFT`, xóa `submitted_by/at`, ghi `version_review` (`REJECT`, lý do), ghi outbox EVT-07-06 và kiểm toán.

Xử lý của thao tác rút lại và thu hồi duyệt: người trình (hoặc TA) rút lại khi `IN_REVIEW`; người duyệt đã duyệt (hoặc người khác có `PERM-07-publish`) thu hồi khi `APPROVED`; cả hai đưa phiên bản về `DRAFT`, ghi `version_review` và ghi outbox EVT-07-06 với `reason = WITHDRAWN` hoặc `UNAPPROVED` để PH-12 đóng việc.

Các ngoại lệ được liệt kê trong bảng sau.

| Điều kiện | Mã lỗi | HTTP | Hành vi |
|---|---|---|---|
| Phiên bản không ở trạng thái cho phép, bản nháp không có thay đổi | ERR-07-004 | 409 | |
| Bản nháp còn lỗi hợp lệ | ERR-07-009 | 422 | Trả số lỗi, liên kết báo cáo |
| Người duyệt là người trình hoặc người sửa nội dung | ERR-07-015 | 403 | |
| Từ chối không có lý do đủ dài | — | 400 | Lỗi hợp lệ chung |
| ETag không khớp | ERR-07-018 | 412 | |

#### FR-07-016 · Phát hành phiên bản với ngày hiệu lực và căn cứ pháp lý

Chức năng này đưa một phiên bản vào sử dụng: gán khoảng hiệu lực, đóng phiên bản trước, sinh ảnh chụp, làm mới bộ đệm và phát sự kiện cho HTTT. Đây là thao tác quan trọng nhất về tính đúng đắn của PH-07, vì sau khi phát hành phiên bản trở thành bất biến.

| Trường | Nội dung |
|---|---|
| Mã, tên | FR-07-016 · Phát hành phiên bản với ngày hiệu lực và căn cứ pháp lý |
| Mức ưu tiên | M |
| Truy vết | REQ-07, BP-03; mới |
| Tác nhân, quyền | DA, PA (`COMMON`) với `PERM-07-publish`; tiến trình đồng bộ (tác nhân hệ thống) khi `auto_apply`; tiến trình di trú và nạp gói nền (tác nhân hệ thống, PA khởi chạy) |
| Tiền điều kiện | Phiên bản `APPROVED`; hoặc `DRAFT` khi danh mục `require_approval = false`, thay đổi không vượt ngưỡng và không phá vỡ (BR-07-026); kiểm tra hợp lệ không lỗi; danh mục không `RETIRED` |
| Đầu ra | `200` với phiên bản `PUBLISHED`, `effectiveFrom`, `effectiveTo`, `snapshotUri`, nhãn hiệu lực |
| Hậu điều kiện | Phiên bản `PUBLISHED`, bất biến; `published_by/at`, `effective_from`, `legal_basis` gán; phiên bản đã phát hành có `effective_to` rỗng trước đó được gán `effective_to = effective_from` mới (BR-07-007); `catalog.status = ACTIVE` (nếu là lần đầu); `current_version_id` cập nhật nếu phiên bản mới có hiệu lực từ hôm nay; ảnh chụp JSON.gz và CSV được ghi lên kho đối tượng; với danh mục `DVHC`, bảng chiếu `admin_unit` (EN-07-18) được làm mới trong cùng giao dịch; chỉ mục biểu thức cho thuộc tính `queryable` mới được tạo |
| Sự kiện phát ra | EVT-07-05 `{tenant}.rdm.catalog.published.v1` với `catalogCode`, `versionNo`, `effectiveFrom`, `effectiveTo` của phiên bản trước, `stats`, `breaking`, `snapshotUri`, `schemaHash`; với `DVHC` có sự kiện sắp xếp thì thêm EVT-07-10 `common.rdm.adminunit.reorganized.v1` |
| Kiểm toán | `RDM_VERSION_PUBLISH`, `versionNo`, `effectiveFrom`, `legalBasis`, `stats`, `breaking`, kênh (`APPROVED` hay `DIRECT`) |

Đầu vào của API-07-020 được mô tả trong bảng sau; các trường cũng có thể đã được gán trước qua API-07-014.

| Trường | Kiểu | Bắt buộc | Ràng buộc | Ví dụ |
|---|---|---|---|---|
| `effectiveFrom` | T-DATE | Có (nếu chưa gán) | ≥ hôm nay (BR-07-027), trừ `origin` là `SYNC` hoặc `MIGRATION` được hồi tố có lý do; > `effective_from` của mọi phiên bản đã phát hành (BR-07-007) | `2027-01-01` |
| `legalBasis` | T-TEXT | Có với danh mục `require_approval = true`; không bắt buộc với danh mục khác | ≤ 1.000 ký tự; số hiệu, ngày, cơ quan ban hành văn bản | `Quyết định 12/QĐ-SKHĐT ngày 20/12/2026` |
| `changeNote` | T-TEXT | Không | ≤ 4.000 | |
| `retroactiveReason` | T-TEXT | Khi hồi tố | 10…1.000 | `Đồng bộ phiên bản quốc gia ban hành ngày 15/11/2026` |

Xử lý gồm các bước sau.

1. Hệ thống kiểm tra quyền `PERM-07-publish` và `If-Match`.
2. Hệ thống kiểm tra trạng thái: nếu `APPROVED` thì tiếp; nếu `DRAFT` thì kiểm tra `require_approval = false`, tính khác biệt (FR-07-014) và yêu cầu `largeChange = false` và `breaking = false` (BR-07-012, BR-07-026), vi phạm trả `ERR-07-016` kèm `summary`; trạng thái khác trả `ERR-07-004`.
3. Hệ thống kiểm tra bốn mắt: người phát hành khác người sửa nội dung cuối và khác người trình (BR-07-011); với phát hành thẳng từ `DRAFT`, người phát hành khác mọi người đã sửa bản nháp. Tác nhân hệ thống (đồng bộ, di trú, nạp gói nền) được miễn, vì không có người soạn.
4. Hệ thống kiểm tra ngày hiệu lực theo BR-07-007 và BR-07-027; vi phạm trả `ERR-07-017`.
5. Hệ thống chạy lại kiểm tra hợp lệ nếu `version` của phiên bản khác với lần kiểm tra lưu trong `stats.validation` (trường hợp không xảy ra với `APPROVED` vì nội dung bị khóa, nhưng kiểm tra để phòng thủ) và kiểm tra lại tham chiếu `CATALOG_REF` tại ngày `effectiveFrom` (danh mục đích có thể đã đổi từ lúc duyệt).
6. Hệ thống trong một giao dịch, sau khi khóa dòng danh mục: gán `effective_to` cho phiên bản đã phát hành có `effective_to` rỗng và `effective_from` nhỏ hơn; chuyển phiên bản sang `PUBLISHED`, gán các trường phát hành và `stats` cuối cùng; cập nhật `catalog.status` và `current_version_id`; với `DVHC`, làm mới bảng chiếu `admin_unit` (FR-07-044); ghi `version_review` `PUBLISH`; ghi outbox EVT-07-05 (và EVT-07-10 nếu có sự kiện sắp xếp); ghi kiểm toán.
7. Sau khi giao dịch cam kết, tác vụ nền sinh ảnh chụp: tệp `s3://dh-{tenant}-rdm/snapshots/{catalogCode}/{versionNo}.json.gz` (mảng bản ghi theo thứ tự mã, kèm khối `meta` gồm lược đồ, `schemaHash`, khoảng hiệu lực, `sha256` của nội dung) và tệp `.csv.gz` cùng tên; ghi `snapshot_uri` vào phiên bản (cột kỹ thuật cho phép ghi sau phát hành, không thuộc nội dung bất biến). Nếu sinh ảnh chụp lỗi, tác vụ thử lại theo lũy thừa tối đa 5 lần và cảnh báo vận hành; API khai thác vẫn phục vụ từ CSDL trong thời gian đó.
8. Bộ đệm L1 và L2 được làm mới con trỏ phiên bản hiệu lực khi các pod nhận EVT-07-05 (ADR-053); dữ liệu của phiên bản mới được nạp lười theo khóa `version_id`.
9. Toàn bộ thao tác với phiên bản 50.000 bản ghi kể cả ảnh chụp xong trong 30 giây; sự kiện lên Kafka trong 5 giây sau cam kết (NFR-07-007).

Bảng dưới đây minh họa quy tắc khoảng hiệu lực khi phát hành, vì đây là điểm dễ sai nhất khi có phiên bản sắp hiệu lực.

| Tình huống | Trước khi phát hành | Phát hành v5 với `effectiveFrom` | Sau khi phát hành |
|---|---|---|---|
| Thông thường | v4 `[2026-01-01, ∅)` | `2027-01-01` | v4 `[2026-01-01, 2027-01-01)`, v5 `[2027-01-01, ∅)` |
| Có phiên bản sắp hiệu lực | v3 `[2026-01-01, 2026-12-01)`, v4 `[2026-12-01, ∅)` (hôm nay 21/11/2026) | `2027-01-01` | v4 `[2026-12-01, 2027-01-01)`, v5 `[2027-01-01, ∅)` |
| Ngày không hợp lệ | v4 `[2026-12-01, ∅)` | `2026-11-25` | Từ chối `ERR-07-017` vì nhỏ hơn `effective_from` của v4 |
| Hồi tố đồng bộ | v4 `[2026-01-01, ∅)` | `2026-11-15`, `origin = SYNC` | v4 `[2026-01-01, 2026-11-15)`, v5 `[2026-11-15, ∅)`; ghi lý do hồi tố |

Các ngoại lệ được liệt kê trong bảng sau.

| Điều kiện | Mã lỗi | HTTP | Hành vi |
|---|---|---|---|
| Phiên bản không `APPROVED` (hoặc `DRAFT` hợp lệ) | ERR-07-004 | 409 | |
| Phát hành thẳng nhưng vượt ngưỡng hoặc phá vỡ | ERR-07-016 | 409 | Hướng dẫn trình duyệt |
| Người phát hành là người trình hoặc người sửa | ERR-07-015 | 403 | |
| Ngày hiệu lực sai, hồi tố không có lý do | ERR-07-017 | 422 | |
| Còn lỗi hợp lệ, tham chiếu `CATALOG_REF` không còn | ERR-07-009 | 422 | |
| Thiếu căn cứ pháp lý khi bắt buộc | — | 400 | |
| ETag không khớp | ERR-07-018 | 412 | |

#### FR-07-017 · Hủy bản nháp

Chức năng này bỏ một bản nháp không dùng nữa, giải phóng suất phiên bản mở để tạo bản nháp khác.

| Trường | Nội dung |
|---|---|
| Mã, tên | FR-07-017 · Hủy bản nháp |
| Mức ưu tiên | M |
| Truy vết | REQ-07; mới |
| Tác nhân, quyền | DS (○), TA, PA (`COMMON`) với `PERM-07-update` |
| Tiền điều kiện | Phiên bản `DRAFT` (phiên bản `IN_REVIEW` phải rút lại trước, `APPROVED` phải thu hồi duyệt trước); không phải nháp số 1 của danh mục chưa phát hành (trường hợp đó dùng xóa danh mục, FR-07-009); không phải bản nháp đồng bộ đang gắn với lần đồng bộ `PENDING_CONFIRMATION` (dùng từ chối đồng bộ, FR-07-037) |
| Đầu ra | `204` |
| Hậu điều kiện | `status = DISCARDED`; số phiên bản không được tái sử dụng; bản ghi và thuộc tính của phiên bản bị xóa vật lý sau 7 ngày bởi tác vụ dọn dẹp (phiên bản `DISCARDED` vẫn giữ dòng `catalog_version` và `version_review` để kiểm toán); tác vụ nhập đang ở `VALIDATED` của bản nháp chuyển `CANCELLED` |
| Sự kiện phát ra | Không |
| Kiểm toán | `RDM_VERSION_DISCARD`, `versionNo`, lý do, `stats` tại thời điểm hủy |

Đầu vào của API-07-015 gồm `{c}`, `{v}`, tiêu đề `If-Match` và tham số `reason` (T-TEXT, không bắt buộc, ≤ 1.000 ký tự).

Xử lý gồm các bước sau.

1. Hệ thống kiểm tra quyền, `If-Match`, trạng thái và các điều kiện loại trừ ở tiền điều kiện.
2. Hệ thống chuyển `status = DISCARDED`, ghi `version_review` (`DISCARD`), hủy tác vụ nhập liên quan, ghi kiểm toán.
3. Giao diện yêu cầu xác nhận trước khi gọi (FR-00-050), hiển thị số thay đổi sẽ mất.

Các ngoại lệ được liệt kê trong bảng sau.

| Điều kiện | Mã lỗi | HTTP | Hành vi |
|---|---|---|---|
| Phiên bản không `DRAFT`, là nháp số 1 chưa phát hành, hoặc gắn với đồng bộ chờ xác nhận | ERR-07-004 | 409 | Thông điệp chỉ cách làm đúng |
| ETag không khớp | ERR-07-018 | 412 | |

#### FR-07-018 · Hiển thị bản ghi dạng bảng và dạng cây

Chức năng này hiển thị bản ghi của một phiên bản trên giao diện quản trị dưới hai dạng (UI-07-02 tab Bản ghi, UI-07-05), thay chức năng hiển thị dạng cây của Aita (LGC-DMDC-002) và bổ sung dạng bảng có lọc, sắp xếp, tô màu thay đổi.

| Trường | Nội dung |
|---|---|
| Mã, tên | FR-07-018 · Hiển thị bản ghi dạng bảng và dạng cây |
| Mức ưu tiên | M |
| Truy vết | REQ-07; LGC-DMDC-002 |
| Tác nhân, quyền | Mọi người có `PERM-07-read` |
| Tiền điều kiện | Phiên bản tồn tại |
| Đầu ra | Dạng bảng: trang bản ghi (API-07-026) với cột cố định và cột thuộc tính động theo `sort_order`, ẩn thuộc tính `HIDDEN`. Dạng cây: các nút gốc và con trực tiếp được nạp lười theo nút khi mở rộng (API-07-026 với `parentCode`), mỗi nút có `childCount` |
| Hậu điều kiện | Không thay đổi dữ liệu |
| Sự kiện phát ra | Không |
| Kiểm toán | Không |

Đầu vào là tham số của API-07-026: `{c}`, `{v}`, `view` (`table`, `tree`), `parentCode` (với `tree`, rỗng để lấy gốc), `q`, `status`, `changeType`, `attrs.{code}` (lọc bằng giá trị chính xác trên thuộc tính bất kỳ, chỉ trong giao diện quản trị), `page`, `size` (≤ 200), `sort`.

Xử lý gồm các bước sau.

1. Dạng bảng: hệ thống trả trang bản ghi theo bộ lọc; tìm `q` không dấu trên mã, tên và thuộc tính `searchable`; sắp xếp mặc định theo `path` rồi `sort_order` để bản ghi cùng nhánh đứng liền nhau.
2. Dạng cây: hệ thống trả các nút con trực tiếp của `parentCode`, mỗi nút kèm `childCount` (đếm con `ACTIVE` và `DEPRECATED`) để giao diện vẽ nút mở rộng; nút `DEPRECATED` hiển thị gạch ngang.
3. Khi `q` có giá trị ở dạng cây, hệ thống trả các nút khớp kèm toàn bộ tổ tiên (từ `path`) để giao diện mở sẵn nhánh chứa kết quả.
4. Với bản nháp, mỗi bản ghi kèm `changeType` để tô màu (thêm xanh lá, sửa vàng, ngừng dùng đỏ) theo design system.
5. Danh mục 200.000 bản ghi hiển thị trang đầu trong ≤ 1,5 giây (NFR-00-003).

Các ngoại lệ được liệt kê trong bảng sau.

| Điều kiện | Mã lỗi | HTTP | Hành vi |
|---|---|---|---|
| Không tìm thấy danh mục hoặc phiên bản | ERR-07-001, ERR-07-006 | 404 | |
| `view = tree` với danh mục không phân cấp | — | 400 | |

#### FR-07-019 · Ghi mã thay thế và quan hệ kế thừa cho bản ghi ngừng dùng

Chức năng này ghi và hiển thị quan hệ "mã cũ được thay bằng mã nào" để HTTT tự chuyển dữ liệu. Với danh mục thông thường, quan hệ nằm ở trường `replaced_by` của bản ghi; với ĐVHC, quan hệ được suy ra từ sự kiện sắp xếp (FR-07-045).

| Trường | Nội dung |
|---|---|
| Mã, tên | FR-07-019 · Ghi mã thay thế và quan hệ kế thừa cho bản ghi ngừng dùng |
| Mức ưu tiên | M |
| Truy vết | REQ-07; mới |
| Tác nhân, quyền | Ghi: DS (○), TA, PA (`COMMON`) với `PERM-07-update`. Xem: `PERM-07-read`, HTTT `rdm.read` |
| Tiền điều kiện | Bản nháp `DRAFT`; bản ghi `DEPRECATED` trong bản nháp (hoặc đang được ngừng dùng qua API-07-029) |
| Đầu ra | Bản ghi với `replacedBy` mới |
| Hậu điều kiện | `replaced_by` của bản ghi được cập nhật; sửa `replaced_by` của bản ghi đã ngừng dùng ở phiên bản trước là thay đổi không phá vỡ |
| Sự kiện phát ra | Không (đi kèm EVT-07-05 khi phát hành) |
| Kiểm toán | `RDM_ITEM_UPDATE` với trường `replacedBy` |

Đầu vào là trường `replacedBy` (mảng T-CODE, 0…50 phần tử) gửi qua API-07-029 hoặc API-07-028 với bản ghi `DEPRECATED`.

Xử lý gồm các bước sau.

1. Hệ thống kiểm tra mỗi mã trong `replacedBy` tồn tại, `ACTIVE` trong bản nháp và khác mã của chính bản ghi.
2. Hệ thống kiểm tra không tạo chuỗi thay thế vòng (A thay bằng B, B thay bằng A) bằng cách đi theo `replaced_by` của các bản ghi `DEPRECATED` tối đa 10 bước.
3. Với danh mục `DVHC`, trường `replaced_by` không nhập tay được mà được tính lại từ sự kiện sắp xếp của bản nháp mỗi khi sự kiện thay đổi (FR-07-045); nhập tay trả `ERR-07-035`.
4. Khi tra cứu (FR-07-026, 027), bản ghi `DEPRECATED` trả kèm `replacedBy` và, nếu yêu cầu `resolveReplacement = true`, trả thêm bản ghi thay thế cuối cùng sau khi đi hết chuỗi (tối đa 10 bước).

Các ngoại lệ được liệt kê trong bảng sau.

| Điều kiện | Mã lỗi | HTTP | Hành vi |
|---|---|---|---|
| Mã thay thế không tồn tại, không `ACTIVE`, trùng chính nó, tạo vòng | ERR-07-009 | 422 | `errors[].code = REPLACED_BY_INVALID` |
| Nhập tay `replacedBy` cho ĐVHC | ERR-07-035 | 422 | Hướng dẫn ghi sự kiện sắp xếp |

