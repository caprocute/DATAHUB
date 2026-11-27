---
ma_tai_lieu: D02-04-PH09
ten: Đặc tả use case phân hệ PH-09 Quyền riêng tư
phien_ban: 0.3
ngay: 2026-11-27
trang_thai: Dự thảo
nguoi_doc: Hội đồng thẩm định, kỹ sư, kiểm thử viên
phan_he: PH-09
mo_ta: Đặc tả 34 use case của phân hệ Quyền riêng tư (phân loại, mục đích và chấp thuận, che, giả danh và ẩn danh, lưu giữ, quyền chủ thể, DPIA, vi phạm 72 giờ), mỗi use case một khối 15 mục kèm mã lỗi và câu thông báo lấy từ FRS, làm cầu nối giữa FRS với thiết kế, màn hình, API và kịch bản kiểm thử
tai_lieu_lien_quan: D02-03-PH09 FRS; D03-02-PH09 SDD; D03-03-PH09 CSDL; D03-04-PH09 API; D03-06-PH09 Màn hình; D05-02-PH09 Kiểm thử
---

# D02-04-PH09 · Đặc tả use case Quyền riêng tư

## Tóm tắt cho hội đồng thẩm định

Tài liệu đặc tả 34 use case của PH-09, phủ toàn bộ 64 FR (42 mức M, 18 mức S, 4 mức C) của [D02-03-PH09](../frs/D02-03-PH09-frs-quyen-rieng-tu.md). Use case đi theo vòng đời của dữ liệu cá nhân (DLCN): cơ quan phân loại từng trường và ghi sổ hoạt động xử lý; đơn vị khai thác dữ liệu Nhạy cảm lập yêu cầu theo mục đích và được chủ quản chấp thuận; PH-09 đẩy chấp thuận và chính sách che vào gói OPA ký để các điểm thực thi (PH-03, PH-04, PH-06, PH-14, PH-19) quyết định trong vài mili giây; dữ liệu ra ngoài được che, giả danh hóa hoặc ẩn danh hóa; dữ liệu hết hạn lưu bị xóa; công dân thực hiện quyền của mình; cán bộ ATTT lập đánh giá tác động và xử lý vi phạm trong 72 giờ. Căn cứ pháp lý: CMP-LAW-05 (Luật BVDLCN 91/2025), CMP-LAW-18 (NĐ 356/2025), CMP-LAW-01 (Luật Dữ liệu 60/2024), CMP-LAW-03 (NĐ 278/2025), CMP-LAW-16 (Luật An ninh mạng 116/2025).

Bốn điểm hội đồng cần lưu ý. Thứ nhất, hệ cũ (Viettel 2021) chỉ có che cấu hình tay từng luồng (LGC-TOOL-012) và tra cứu BHXH (LGC-NGSP-003), nên phần lớn use case là năng lực mới (§5.3). Thứ hai, PH-09 chỉ là nơi quản lý và nguồn chính sách: quyết định trực tuyến do OPA và các điểm thực thi làm, bảy use case máy với máy (UC-09-05, 12, 13, 15, 18, 19, 23) mô tả đường đó. Thứ ba, quyết định có hậu quả lớn đều qua bốn mắt hoặc ba người (LP-09-01), và thao tác đặc quyền bị từ chối nếu không ghi được nhật ký (BR-09-057). Thứ tư, không use case nào cho phép giá trị `SENSITIVE` xuất hiện ở dạng rõ trong log hay sự kiện (BR-09-025).

## 1. Giới thiệu

Chương này nói tài liệu dùng để làm gì, phủ những gì, ai cần đọc phần nào, thuật ngữ và tài liệu cần mở song song.

### 1.1. Mục đích

Tài liệu chuyển 64 chức năng của FRS PH-09 thành kịch bản làm việc của người và hệ thống: ai làm, điều kiện nào, trình tự nào, hỏng ở đâu thì người dùng thấy câu thông báo gì. Kỹ sư dùng làm đầu vào cho SDD, API và màn hình; kiểm thử viên dựng ca TS-09-nn theo từng use case; hội đồng thẩm định kiểm tra mỗi chức năng bảo vệ DLCN có đường đi đủ từ người dùng đến quyết định ở điểm thực thi.

### 1.2. Phạm vi

Trong phạm vi: 11 nhóm A đến K của FRS. Ngoài phạm vi: lưu nội dung bản tin đi qua, mã hóa trường (`dh-crypto`, SEC-31), lưu nhật ký kiểm toán (PH-13), chạy quy trình duyệt (PH-11), phát hiện sự cố (PH-18); các phân hệ này là tác nhân phụ. Ở MVP chỉ có phân loại khai báo trong mã (`@Classified`, `x-dh-classification`); UC-09-02 nhập lại các khai báo này.

### 1.3. Người đọc

Hội đồng thẩm định đọc tóm tắt, chương 4, 5, 8; kỹ sư và kiểm thử viên đọc chương 6, 7 cùng FRS §9; cán bộ ATTT và chủ quản dữ liệu đọc use case có vai trò của mình.

### 1.4. Thuật ngữ và viết tắt

Thuật ngữ chung theo D00-01 và FRS §1.4, §4; bảng nhắc các từ dày đặc trong luồng.

| Thuật ngữ | Giải thích |
|---|---|
| DLCN | Dữ liệu cá nhân, gồm cơ bản và nhạy cảm theo Luật BVDLCN 91/2025 |
| DPIA | Đánh giá tác động xử lý DLCN, hồ sơ gửi Cục A05 |
| Hoạt động xử lý | Một mục của sổ xử lý DLCN: mục đích, cơ sở pháp lý, loại dữ liệu, bên nhận, thời hạn lưu, vai trò kiểm soát hoặc xử lý |
| Chấp thuận | Quyết định của chủ quản cho một HTTT dùng một hợp đồng theo một mục đích, có hạn và điều kiện |
| PAP, PIP, PDP, PEP | PH-09 là nơi quản lý và nguồn chính sách (PAP, PIP); OPA ở PH-12 là điểm quyết định (PDP); DU là điểm thực thi (PEP) |
| Kế hoạch che | Danh sách trường, kiểu che và tham số PH-09 trả cho PEP theo (vai trò, mục đích, kênh, hợp đồng) |
| Đóng an toàn | Khi không có kế hoạch che hợp lệ thì chỉ trả trường `PUBLIC` (đọc) hoặc từ chối (luồng), không trả dữ liệu thô |
| Giả danh hóa | Thay giá trị bằng bí danh: HMAC-SHA256 không đảo ngược hoặc token đảo ngược qua OpenBao transit |
| Ẩn danh hóa | Biến đổi để không thể xác định lại cá nhân, kiểm chứng bằng k ≥ 10 (k-ẩn danh) và rủi ro tái định danh |
| DSR | Yêu cầu của chủ thể dữ liệu (biết, truy cập, sửa, xóa, hạn chế, phản đối, rút đồng ý) |
| DS, DA, DO, OR, SV, TA, TO, SO, PA, AU, VW | Cán bộ quản lý dữ liệu, người duyệt dữ liệu, chủ quản dữ liệu, đầu mối tổ chức, chủ dịch vụ, quản trị tenant, vận hành tenant, cán bộ ATTT, quản trị nền tảng, kiểm toán, người xem |

: Thuật ngữ và viết tắt dùng trong tài liệu

### 1.5. Tài liệu tham chiếu

[D02-03-PH09 FRS](../frs/D02-03-PH09-frs-quyen-rieng-tu.md) (nguồn chuẩn: §3 tác nhân và quyền, §4 khái niệm, §7 BR, §8 tham số, §9 mã lỗi, thông báo, sự kiện, API, §10.1 màn hình, Phụ lục A enum); [D02-08](../D02-08-ma-tran-phan-quyen.md) (quyền, vai trò); [D03-07](../../03-thiet-ke/attt/D03-07-thiet-ke-attt.md) §3.2 và §6 (bốn mức phân loại, vai trò kiểm soát và xử lý, DPIA, quyền chủ thể, vi phạm 72 giờ); D02-01 (REQ-09, BP); D00-01 (hệ mã); D00-04 (sổ tra cứu gọn); K-UC, K-TRINH-BAY; `docs/07-srs/SRS-PH-09-privacy.md` (SRS cũ của repo).

### 1.6. Cấu trúc tài liệu

Chương 2 quy ước đọc; 3 tác nhân; 4 sơ đồ tổng; 5 truy vết hai chiều; 6 ba mươi bốn khối đặc tả và năm sơ đồ trình tự; 7 luồng phụ; 8 mã mới, đề nghị cho FRS và đồng bộ; 9 câu hỏi mở.

## 2. Quy ước đọc đặc tả

Mỗi use case dùng một khối `::: dac-ta` 15 mục theo thứ tự của K-UC: Mục tiêu · Tác nhân chính · Tác nhân phụ · Mức ưu tiên · FR hiện thực · Truy vết · Tiền điều kiện · Kích hoạt · Đảm bảo tối thiểu · Đảm bảo thành công · Luồng chính · Luồng thay thế · Luồng ngoại lệ · Quy tắc áp dụng · Màn hình, API. Năm use case tiêu biểu có thêm sơ đồ trình tự ngay sau khối.

Luồng chính đánh số 1, 2, 3. Luồng thay thế ghi `số bước + chữ` (3a rẽ tại bước 3) và nêu bước quay lại. Luồng ngoại lệ ghi `E1`, `E2` kèm bước, mã `ERR-09-nnn`, mã HTTP trong ngoặc và câu thông báo trong ngoặc kép (nguyên văn FRS §9.1; dấu `{…}` do máy chủ điền). ERR-09-101…113 là lỗi data plane, không hiện cho người dùng cuối mà ghi vào nhật ký điểm thực thi, UI-09-01 và UI-09-20 (FRS §9.2). Lỗi thiếu quyền chức năng dùng mã nền ERR-00-401, ERR-00-403, ERR-00-428 và không nhắc lại từng use case. Luồng phụ dùng chung ghi `LP-09-nn` (chương 7).

Quy ước chung: lệnh ghi qua `/api/privacy/v1` mang `Idempotency-Key` (BR-09-061; dùng lại khóa với thân khác: ERR-09-081, 409) và `If-Match` khi sửa (xung đột: ERR-09-004, 409); đối tượng của tenant khác trả như không tồn tại (ERR-09-001, 404); mọi bảng chạy dưới RLS theo `tenant_id` (BR-09-060); mọi thao tác ghi sinh kiểm toán qua thư viện chung vào PH-13, không ghi được thì thao tác đặc quyền bị từ chối (ERR-09-010, BR-09-057). Dữ liệu ví dụ giả lập, tenant `T68`.

| Vai | Người hoặc hệ thống | Ghi chú |
|---|---|---|
| SO | **Dũng** (cán bộ ATTT, đóng vai bộ phận bảo vệ DLCN, GĐ-09-01) | Soạn sổ, DPIA, xử lý DSR, vi phạm; giữ `PERM-09-unmask` được cấp riêng |
| TA, PA, DO | **Mai** (Sở KH&CN, quản trị tenant), **Hà** (vận hành nền tảng), **Phúc** (Sở Tư pháp, chủ quản dữ liệu hộ tịch) | Mai soạn chính sách; Phúc thẩm định chấp thuận |
| DS, DA, TO, OR, SV | **Lan**, **Quân**, **Chi** (trực), **Thảo** (đầu mối Sở Y tế), **Bình** (chủ dịch vụ) | Quản lý, duyệt dữ liệu; lập yêu cầu khai thác |
| HTTT | `HT-HOTICH` (hộ tịch), `HT-YTE` (y tế), `HT-BHXH` | Hợp đồng `API-HOTICH-KHAISINH` mức `SENSITIVE`, mục đích `TTHC-HO-TICH`, `THONG-KE` |
| Chủ thể | Công dân giả lập "Nguyễn Văn A", CCCD `001090012345` | Chỉ có băm HMAC trong PH-09; gửi yêu cầu qua cổng dịch vụ công |

: Người, hệ thống và đối tượng giả lập dùng trong ví dụ

## 3. Tác nhân

PH-09 có 12 nhóm tác nhân người, chủ thể dữ liệu (người ngoài hệ thống, không đăng nhập) và các tác nhân hệ thống. Cán bộ ATTT gánh phần lớn use case vì đóng vai bộ phận bảo vệ DLCN; việc có cần vai trò riêng `ROLE-PRIVACY_OFFICER` còn mở (Q09-01). Các điểm thực thi là tác nhân chính của use case máy với máy và chỉ gọi data plane `/privacy/v1` bằng mTLS, danh tính SPIFFE và scope `privacy:*` (FRS §3.3).

| Tác nhân | Vai (`ROLE-*`) hoặc loại | Quyền, scope chính |
|---|---|---|
| SO | ROLE-SECURITY_OFFICER | `PERM-09-classify`, `ropa`, `policy`, `policy-approve`, `reidentify`, `retention`, `dsr`, `breach`, `audit-read`; `unmask` cấp riêng |
| TA | ROLE-TENANT_ADMIN | `PERM-09-classify`, `ropa`, `purpose-request`, `policy`, `policy-approve`, `anonymize`, `retention`, `dsr`, `breach`, `config` |
| DS | ROLE-DATA_STEWARD | `PERM-09-ropa`, `policy`, `anonymize`, `retention`, `dsr`, `consent` (○); chỉ đề xuất phân loại |
| DA | ROLE-DATA_APPROVER | `PERM-09-ropa`, `policy-approve` |
| DO | ROLE-DATA_OWNER | `PERM-09-purpose-approve`, `unmask` (○), `classify` (○) |
| OR, SV | ROLE-ORG_REQUESTER, ROLE-SERVICE_OWNER | `PERM-09-purpose-request` (○); SV đề xuất phân loại |
| TO, PA | ROLE-TENANT_OPERATOR, ROLE-PLATFORM_ADMIN | TO: `PERM-09-read`, `breach` (ghi nhận ban đầu); PA: `config` (trần, sàn), danh mục nền |
| AU, VW | ROLE-AUDITOR, ROLE-VIEWER | `PERM-09-audit-read` (AU), `PERM-09-read` |
| Chủ thể dữ liệu | Người ngoài hệ thống | Gửi yêu cầu qua cổng dịch vụ công, quầy, văn bản |
| HTTT thành viên | ROLE-PARTNER_SYSTEM | `purpose:{mã}`, `privacy:consent`, `privacy:register` |
| PEP: PH-03, PH-04, PH-06, PH-14, PH-19 | Điểm thực thi | `privacy:decide`, `privacy:apply` (PH-04) |
| PH-02, 11, 12, 13, 17, 18, 20; OpenBao, Job ARX | Phân hệ, hạ tầng | Hợp đồng, quy trình, OPA, kiểm toán, dữ liệu AI, sự cố, chấm dứt tenant; ký, HMAC, ẩn danh |

: Tác nhân của PH-09 và quyền chính

## 4. Sơ đồ use case tổng

Để đọc được trên trang A4, 34 use case chia thành bốn hình theo vòng đời: dữ liệu và sổ xử lý; mục đích và chấp thuận; che, giả danh và ẩn danh; lưu giữ, quyền chủ thể, vi phạm và giám sát. Mermaid không có ký pháp use case nên dùng `flowchart`: hình bo tròn là người, hình hai viền là hệ thống, chữ nhật bo góc là use case; đường liền nối tác nhân với use case.

```{.mermaid caption="Use case phân loại dữ liệu và sổ hoạt động xử lý"}
flowchart TB
  TA([TA, SO])
  DS([DS, SV])
  DO([DO])
  PX[[PH-02, PH-04, PH-06, PH-14]]
  subgraph PL["Phân loại và sổ xử lý"]
    U01(UC-09-01 Danh mục phân loại)
    U02(UC-09-02 Đăng ký phần tử)
    U03(UC-09-03 Đề xuất, xác nhận phân loại)
    U04(UC-09-04 Quét phát hiện DLCN)
    U05(UC-09-05 Mức phân loại hợp đồng)
    U06(UC-09-06 Chặn bí mật nhà nước)
    U07(UC-09-07 Sổ hoạt động xử lý)
    U08(UC-09-08 Cơ sở pháp lý, mục đích)
    U01 ~~~ U02 ~~~ U03 ~~~ U04 ~~~ U05 ~~~ U06 ~~~ U07 ~~~ U08
  end
  TA --- U01 & U03 & U04 & U06 & U07 & U08
  DS --- U02 & U03 & U07
  DO --- U03 & U06 & U08
  PX --- U02 & U05 & U06
```

Hình cho thấy DS và chủ dịch vụ chỉ đề xuất phân loại, TA, SO, DO mới xác nhận (BR-09-003); phân hệ khác tự đăng ký phần tử và kiểm nhãn chặn qua scope `privacy:register`, `privacy:decide`.

```{.mermaid caption="Use case mục đích và chấp thuận khai thác"}
flowchart TB
  OR([OR, SV])
  DO([DO])
  PEP[[PEP: PH-03, PH-04, PH-06, PH-14, PH-19]]
  OPA[[OPA PH-12]]
  subgraph MD["Mục đích và chấp thuận"]
    U09(UC-09-09 Lập yêu cầu khai thác)
    U10(UC-09-10 Thẩm định, chấp thuận)
    U11(UC-09-11 Gia hạn, tạm dừng, thu hồi)
    U12(UC-09-12 Bundle OPA có ký)
    U13(UC-09-13 Quyết định mục đích)
    U14(UC-09-14 Bất thường, báo cáo khai thác)
    U15(UC-09-15 Chặn kích hoạt hợp đồng)
    U09 ~~~ U10 ~~~ U11 ~~~ U12 ~~~ U13 ~~~ U14 ~~~ U15
  end
  OR --- U09 & U11
  DO --- U10 & U11 & U14
  U10 -.-> U12
  U11 -.-> U12
  OPA --- U12
  PEP --- U13 & U14 & U15
```

Hình cho thấy chấp thuận đi một chiều từ người quyết định tới gói OPA ký rồi tới điểm thực thi; điểm thực thi hỏi OPA hoặc API quyết định (UC-09-13) và báo lượt khai thác ngược lại (UC-09-14).

```{.mermaid caption="Use case chính sách che, giả danh hóa và ẩn danh hóa"}
flowchart TB
  TA([TA, SO, DS])
  DA([DA])
  PEP[[PEP, PH-04, PH-17]]
  BAO[[OpenBao, Job ARX]]
  subgraph CHE["Che dữ liệu"]
    U16(UC-09-16 Kiểu che, soạn chính sách)
    U17(UC-09-17 Mô phỏng, duyệt, phát hành)
    U18(UC-09-18 Kế hoạch che)
    U19(UC-09-19 Áp che bản tin)
    U20(UC-09-20 Xem giá trị đầy đủ)
    U21(UC-09-21 Che log, quét rò rỉ)
    U16 ~~~ U17 ~~~ U18 ~~~ U19 ~~~ U20 ~~~ U21
  end
  subgraph GD["Giả danh và ẩn danh"]
    U22(UC-09-22 Miền và khóa)
    U23(UC-09-23 Giả danh hóa giá trị)
    U24(UC-09-24 Khôi phục giá trị gốc)
    U25(UC-09-25 Ẩn danh hóa, rủi ro)
    U26(UC-09-26 Dữ liệu cho AI, tập ẩn danh)
    U22 ~~~ U23 ~~~ U24 ~~~ U25 ~~~ U26
  end
  TA --- U16 & U17 & U20 & U21 & U22 & U24 & U25 & U26
  DA --- U17 & U22 & U25
  PEP --- U18 & U19 & U23
  BAO --- U22 & U23 & U24 & U25
```

Hình cho thấy ba lớp: soạn và duyệt chính sách (người), áp chính sách (máy), và ngoại lệ có kiểm soát (xem đầy đủ, khôi phục) ghi nhật ký trước khi thực hiện.

```{.mermaid caption="Use case lưu giữ, quyền chủ thể, đồng ý, DPIA, vi phạm và giám sát"}
flowchart TB
  SO([SO, TA])
  DS([DS, DA])
  TO([TO])
  CT([Chủ thể dữ liệu])
  HT[[HTTT, PH-06, PH-19, PH-18, PH-20]]
  subgraph LG["Lưu giữ và quyền chủ thể"]
    U27(UC-09-27 Lịch lưu giữ, tác vụ xóa)
    U28(UC-09-28 Giữ pháp lý, xóa mật mã)
    U29(UC-09-29 Tiếp nhận, xác minh, xử lý DSR)
    U30(UC-09-30 Hạn, trả lời, báo cáo truy cập)
    U31(UC-09-31 Sự đồng ý)
  end
  subgraph TT["Tuân thủ và giám sát"]
    U32(UC-09-32 Hồ sơ DPIA)
    U33(UC-09-33 Vi phạm DLCN 72 giờ)
    U34(UC-09-34 Nhật ký, bảng điều khiển, cấu hình)
  end
  SO --- U27 & U28 & U29 & U30 & U32 & U33 & U34
  DS --- U27 & U29 & U31 & U32
  TO --- U33
  CT -.-> U29
  CT -.-> U31
  HT --- U28 & U29 & U31 & U33
```

Hình cho thấy chủ thể dữ liệu không đăng nhập Datahub: yêu cầu đến qua cổng dịch vụ công hoặc quầy (nét đứt) và do cán bộ ATTT xử lý; TO ghi nhận vi phạm ban đầu nhưng chỉ SO, TA đóng hồ sơ.


## 5. Bảng tổng hợp use case và truy vết

Bốn bảng dưới đây nối use case với FR, màn hình, API, yêu cầu nghiệp vụ, và đảo chiều từ FR về use case để kiểm tra độ phủ. Cả 42 FR mức M, 18 FR mức S và 4 FR mức C đều thuộc ít nhất một use case.

### 5.1. Use case và FR

Các use case máy với máy (05, 12, 13, 15, 18, 19, 23) có tác nhân chính là phân hệ gọi; mức ưu tiên là mức cao nhất trong các FR của use case.

| UC | Tên | Tác nhân chính | Mức | FR |
|---|---|---|---|---|
| UC-09-01 | Quản lý danh mục mức phân loại, loại dữ liệu cá nhân và tra cứu, xuất danh mục | TA, SO | M | 001, 002, 008 |
| UC-09-02 | Đăng ký phần tử dữ liệu từ phân hệ, lược đồ và khai báo MVP | TA, SO, DS | M | 003 |
| UC-09-03 | Đề xuất, xác nhận và hạ mức phân loại trường | DS, SV đề xuất | M | 004 |
| UC-09-04 | Quét phát hiện trường nghi dữ liệu cá nhân chưa phân loại | TA, SO, DS | S | 005 |
| UC-09-05 | Tính và công bố mức phân loại của hợp đồng API, topic, luồng | PH-02, PH-04, PH-10 | M | 006 |
| UC-09-06 | Gán, gỡ nhãn và chặn dữ liệu bí mật nhà nước | TA, SO, DO | M | 007 |
| UC-09-07 | Lập, duyệt, liên kết và xuất sổ hoạt động xử lý | SO, TA, DS | M | 009, 010, 011, 013 |
| UC-09-08 | Quản lý danh mục cơ sở pháp lý, văn bản căn cứ và mục đích khai thác | TA, SO, DO | M | 012, 014 |
| UC-09-09 | Lập yêu cầu khai thác theo mục đích | OR, SV, TA | M | 015 |
| UC-09-10 | Thẩm định, chấp thuận có điều kiện hoặc từ chối yêu cầu khai thác | DO | M | 016 |
| UC-09-11 | Gia hạn, sửa, tạm dừng, thu hồi chấp thuận và tự hết hạn | DO | M | 017 |
| UC-09-12 | Dựng, ký và phát hành bundle OPA | Hệ thống PH-09 | M | 018 |
| UC-09-13 | Quyết định mục đích trực tuyến cho điểm thực thi | PH-03, PH-04, PH-06, PH-14, PH-19 | M | 019 |
| UC-09-14 | Phát hiện khai thác vượt mục đích, hạn ngạch và báo cáo khai thác | DO, SO, TA | S | 020, 021 |
| UC-09-15 | Chặn kích hoạt hợp đồng mức Nhạy cảm khi chưa có mục đích và chấp thuận | PH-02, PH-04 | M | 022 |
| UC-09-16 | Quản lý kiểu che và soạn chính sách che | TA, SO, DS | M | 023, 024 |
| UC-09-17 | Mô phỏng, duyệt và phát hành chính sách che | TA, SO, DS | M | 025, 026 |
| UC-09-18 | Trả kế hoạch che trực tuyến, đệm và đóng an toàn | PH-03, PH-04, PH-06, PH-14, PH-19 | M | 027 |
| UC-09-19 | Áp che bản tin cho luồng PH-04 | PH-04 `dh-runtime` | M | 028 |
| UC-09-20 | Xem giá trị đầy đủ có lý do trong 60 giây | SO, DO | M | 029 |
| UC-09-21 | Cấu hình che log, trace và quét rò rỉ DLCN trong log | TA, SO, DS | M | 030 |
| UC-09-22 | Quản lý miền giả danh hóa và vòng đời khóa | TA, SO | M | 031, 034 |
| UC-09-23 | Giả danh hóa giá trị bằng HMAC hoặc token | PH-04, PH-17 và job chuẩn bị dữ liệu | M | 032 |
| UC-09-24 | Khôi phục giá trị gốc từ token | SO đề nghị và thực hiện | S | 033 |
| UC-09-25 | Cấu hình, chạy ẩn danh hóa và đánh giá rủi ro tái định danh | TA, SO, DS cấu hình và chạy | S | 035, 036, 037 |
| UC-09-26 | Chuẩn bị dữ liệu cho AI, môi trường không phải PROD và quản lý tập đã ẩn danh | TA, SO, DS | M | 038, 039 |
| UC-09-27 | Lập lịch lưu giữ, chạy tác vụ xóa hoặc giả danh hóa khi hết hạn và báo cáo | TA, SO, DS soạn | M | 040, 041, 044 |
| UC-09-28 | Giữ pháp lý và xóa mật mã khi chấm dứt tenant | TA, SO, DS đặt giữ | M | 042, 043 |
| UC-09-29 | Tiếp nhận, xác minh, tra cứu và chuyển xử lý yêu cầu của chủ thể dữ liệu | SO, DS, TA | M | 045, 046, 047, 048 |
| UC-09-30 | Theo dõi hạn, trả lời, đóng yêu cầu và báo cáo ai đã truy cập dữ liệu của chủ thể | SO, DS, TA | M | 049, 050, 051 |
| UC-09-31 | Quản lý mẫu và bản ghi sự đồng ý, tra cứu trạng thái | SO, TA, DS | S | 052, 053, 054 |
| UC-09-32 | Lập, duyệt, nhắc rà soát và xuất hồ sơ đánh giá tác động (DPIA) | SO, TA, DS soạn | M | 055, 056, 057 |
| UC-09-33 | Ghi nhận vi phạm DLCN, đồng hồ 72 giờ, thông báo Cục A05 và chủ thể | SO, TA, TO | M | 058, 059, 060 |
| UC-09-34 | Nhật ký bảo vệ dữ liệu, bảng điều khiển, báo cáo định kỳ và cấu hình tham số | SO, AU, TA, PA, VW | M | 061, 062, 063, 064 |
: Use case, tác nhân chính, mức ưu tiên và FR hiện thực (số đuôi của FR-09-nnn)

### 5.2. Use case, màn hình, API và kiểm thử

Mỗi use case có ít nhất một màn hình hoặc API. Use case 13, 18, 19, 23 không có màn riêng (kết quả xem ở UI-09-01, UI-09-20); use case 05, 12, 15 chỉ có màn hình xem kết quả.

| UC | Màn hình và API |
|---|---|
| UC-09-01 | UI-09-02, UI-09-03; API-09-001, 002, 007, 008, 009, 010, 019, 030, 031 |
| UC-09-02 | UI-09-02, UI-09-03; API-09-010, 011, 012, 013, 014, 243 |
| UC-09-03 | UI-09-02, UI-09-03; API-09-015, 016, 017, 018 |
| UC-09-04 | UI-09-04; API-09-020, 021, 022, 023, 024, 025, 026 |
| UC-09-05 | UI-09-02, UI-09-03 (xem kết quả); API-09-027, 028, 029 |
| UC-09-06 | UI-09-03; API-09-003, 004, 005, 006, 231 |
| UC-09-07 | UI-09-05, UI-09-06; API-09-032…044, 051, 052, 053 |
| UC-09-08 | UI-09-07; API-09-045…050, 054, 055, 056, 057 |
| UC-09-09 | UI-09-08; API-09-058…063 |
| UC-09-10 | UI-09-09; API-09-064, 065, 066 |
| UC-09-11 | UI-09-08, UI-09-09; API-09-067…073 |
| UC-09-12 | UI-09-09 (băng đồng bộ); API-09-074…078, 233 |
| UC-09-13 | Không có màn hình (kết quả xem ở UI-09-01, UI-09-20); API-09-227 |
| UC-09-14 | UI-09-01, UI-09-09; API-09-079…087, 237 |
| UC-09-15 | UI-09-09, UI-09-02; API-09-088, 089 |
| UC-09-16 | UI-09-10; API-09-090…095 |
| UC-09-17 | UI-09-10, UI-09-11; API-09-096…101 |
| UC-09-18 | Không có màn hình; API-09-228, 232 |
| UC-09-19 | Không có màn hình; API-09-229, 231 |
| UC-09-20 | UI-09-22, UI-09-20; API-09-102, 103, 241, 236 |
| UC-09-21 | UI-09-10, UI-09-01; API-09-104…108 |
| UC-09-22 | UI-09-12; API-09-109…118 |
| UC-09-23 | Không có màn hình; API-09-230 |
| UC-09-24 | UI-09-13, UI-09-12; API-09-119…124 |
| UC-09-25 | UI-09-14; API-09-125…136 |
| UC-09-26 | UI-09-14; API-09-137…144 |
| UC-09-27 | UI-09-15; API-09-145…155, 163 |
| UC-09-28 | UI-09-15; API-09-156…162 |
| UC-09-29 | UI-09-16; API-09-164…173, 178, 235, 244 |
| UC-09-30 | UI-09-16, UI-09-01; API-09-174…177, 179, 180, 181, 242 |
| UC-09-31 | UI-09-17; API-09-182…191, 234, 238, 245 |
| UC-09-32 | UI-09-18; API-09-192…201 |
| UC-09-33 | UI-09-19; API-09-202…214, 239, 240, 083 |
| UC-09-34 | UI-09-20, UI-09-01, UI-09-21; API-09-215…226 |
: Use case, màn hình và API (kịch bản kiểm thử TS-09-nn ứng với UC-09-nn)

### 5.3. Use case, yêu cầu nghiệp vụ, quy trình và chức năng hệ cũ

Mọi use case truy về REQ-09 (BO-04, mức M). BP-01…09 theo D02-01; BP-12 "Quản lý quyền riêng tư và dữ liệu cá nhân" là quy trình đã chốt ngày 27/11/2026, bổ sung vào D02-01 mục 6.2 (FRS Phụ lục B). Hệ cũ chỉ có hai chức năng liên quan là LGC-TOOL-012 (che dữ liệu nhạy cảm, nâng cấp thành chính sách tập trung) và LGC-NGSP-003 (tra cứu BHXH, giữ nguyên ở PH-14, PH-09 chỉ kiểm soát mục đích); "Không" là năng lực mới.

| UC | REQ | BP | LGC |
|---|---|---|---|
| UC-09-01 | REQ-09 | BP-08, BP-12 | Không |
| UC-09-02, UC-09-04 | REQ-09 | BP-04, BP-12 | Không |
| UC-09-03, UC-09-06, UC-09-07 | REQ-09 | BP-12 | Không |
| UC-09-05 | REQ-09 | BP-02, BP-04 | Không |
| UC-09-08 | REQ-09 | BP-12 | LGC-NGSP-003 |
| UC-09-09, UC-09-10 | REQ-09 | BP-01 | LGC-NGSP-003 |
| UC-09-11, UC-09-12 | REQ-09 | BP-12 | LGC-NGSP-003 |
| UC-09-13, UC-09-14 | REQ-09 | BP-06 | LGC-NGSP-003 |
| UC-09-15 | REQ-09 | BP-01, BP-02 | LGC-NGSP-003 |
| UC-09-16, UC-09-17, UC-09-18, UC-09-20, UC-09-21, UC-09-22, UC-09-23, UC-09-24, UC-09-25, UC-09-26 | REQ-09 | BP-12 | LGC-TOOL-012 |
| UC-09-19 | REQ-09 | BP-02 | LGC-TOOL-012 |
| UC-09-27, UC-09-29, UC-09-30, UC-09-31, UC-09-32, UC-09-34 | REQ-09 | BP-12 | Không |
| UC-09-28 | REQ-09 | BP-08 | Không |
| UC-09-33 | REQ-09 | BP-07 | Không |
: Use case, yêu cầu nghiệp vụ, quy trình và chức năng hệ cũ

### 5.4. Ma trận FR và use case

Bảng đảo chiều của 5.1 để kiểm tra độ phủ: mỗi FR ghi use case hiện thực. Không FR nào bị bỏ trống. Mỗi FR thuộc đúng một use case; các use case khác chỉ dùng lại kết quả qua luồng phụ hoặc tham chiếu chéo.

| FR | UC | FR | UC | FR | UC |
|---|---|---|---|---|---|
| 001 | 01 | 023 | 16 | 045 | 29 |
| 002 | 01 | 024 | 16 | 046 | 29 |
| 003 | 02 | 025 | 17 | 047 | 29 |
| 004 | 03 | 026 | 17 | 048 | 29 |
| 005 | 04 | 027 | 18 | 049 | 30 |
| 006 | 05 | 028 | 19 | 050 | 30 |
| 007 | 06 | 029 | 20 | 051 | 30 |
| 008 | 01 | 030 | 21 | 052 | 31 |
| 009 | 07 | 031 | 22 | 053 | 31 |
| 010 | 07 | 032 | 23 | 054 | 31 |
| 011 | 07 | 033 | 24 | 055 | 32 |
| 012 | 08 | 034 | 22 | 056 | 32 |
| 013 | 07 | 035 | 25 | 057 | 32 |
| 014 | 08 | 036 | 25 | 058 | 33 |
| 015 | 09 | 037 | 25 | 059 | 33 |
| 016 | 10 | 038 | 26 | 060 | 33 |
| 017 | 11 | 039 | 26 | 061 | 34 |
| 018 | 12 | 040 | 27 | 062 | 34 |
| 019 | 13 | 041 | 27 | 063 | 34 |
| 020 | 14 | 042 | 28 | 064 | 34 |
| 021 | 14 | 043 | 28 |  |  |
| 022 | 15 | 044 | 27 |  |  |
: Ma trận FR và use case (số đuôi của FR-09-nnn và UC-09-nn)

Năm FR chỉ là chức năng nội bộ của hệ thống, không có màn hình và không người nào bấm: 019, 027, 028, 032, 054 (FR-09-019 quyết định mục đích, FR-09-027 kế hoạch che, FR-09-028 áp che, FR-09-032 giả danh hóa, FR-09-054 tra đồng ý). Chúng được hiện thực ở UC-09-13, 18, 19, 23 và UC-09-31 (tra đồng ý), kết quả chỉ quan sát qua nhật ký điểm thực thi, UI-09-01 và UI-09-20. FR-09-018 (bundle) và FR-09-006 (mức hợp đồng) chạy tự động nhưng có màn hình xem kết quả.

## 6. Đặc tả chi tiết use case

Ba mươi bốn use case xếp theo nhóm A đến K của FRS. Mức ưu tiên ghi mức cao nhất trong các FR của use case, kèm đợt; FR mức C (Đợt 3) được nêu trong luồng nhưng không làm use case chậm sang Đợt 3 khi use case còn FR mức M.

### 6.1. UC-09-01 · Quản lý danh mục mức phân loại, loại dữ liệu cá nhân và tra cứu, xuất danh mục

::: dac-ta
**Mục tiêu.** Có danh mục mức phân loại và loại DLCN thống nhất, tra cứu và xuất được cùng lịch sử thay đổi để làm căn cứ giải trình.

**Tác nhân chính.** TA (Mai), SO (Dũng).

**Tác nhân phụ.** PA (nạp danh mục nền), AU (tra cứu), PH-13 (kiểm toán).

**Mức ưu tiên.** M · Đợt 2.

**FR hiện thực.** FR-09-001, FR-09-002, FR-09-008.

**Truy vết.** REQ-09; CMP-LAW-01, CMP-LAW-05, CMP-LAW-18; DD-08, DD-09; SEC-31; hệ cũ: không có.

**Tiền điều kiện.** Có `PERM-09-read` để xem, `PERM-09-policy` để sửa chính sách mức, `PERM-09-classify` để thêm loại DLCN; tenant đã khởi tạo (BP-08).

**Kích hoạt.** Mở UI-09-02, tab "Mức phân loại" hoặc "Loại DLCN".

**Đảm bảo tối thiểu.** Bốn mức và nhãn `STATE_SECRET` không bị sửa hay xóa; thay đổi lỗi không để lại bản ghi nửa chừng.

**Đảm bảo thành công.** Loại DLCN mới hoặc chính sách mức mới có hiệu lực, ghi kiểm toán; tệp xuất tải được.

**Luồng chính.**
1. Mai mở UI-09-02, xem bốn mức `PUBLIC`, `INTERNAL`, `RESTRICTED`, `SENSITIVE` và 18 loại DLCN nạp sẵn (API-09-001, API-09-007).
2. Mai chọn "Thêm loại DLCN" nhập mã `HEALTH_INSURANCE_NO`, nhóm `BASIC`, mô tả; hệ thống kiểm mã chưa dùng (API-09-008).
3. Hệ thống tạo loại mới, ghi kiểm toán và trả `201`.
4. Mai sửa chính sách hiển thị của mức `RESTRICTED` (API-09-002, kèm `If-Match`); thay đổi được đưa vào bundle ở UC-09-12.
5. Dũng chọn "Xuất danh mục" khoảng 12 tháng (API-09-030); hệ thống chạy nền, trả `exportId`; Dũng tải tệp ở API-09-031 khi `COMPLETED`.

**Luồng thay thế.**
- **2a. Ngừng loại DLCN.** Chuyển trạng thái `RETIRED` nếu không còn trường dùng (API-09-009).

**Luồng ngoại lệ.**
- **E1. Mã loại trùng (bước 2).** ERR-09-002 (409): "Mã {mã} đã được dùng. Chọn mã khác."
- **E2. Ngừng loại còn trường dùng (2a).** ERR-09-011 (409): "Mục {mã} đang được {n} trường sử dụng nên không ngừng được."
- **E3. Sửa lệch phiên bản (bước 4).** ERR-09-004 (409): "Dữ liệu đã được người khác thay đổi. Tải lại để xem bản mới."
- **E4. Khoảng xuất quá 12 tháng (bước 5).** ERR-09-036 (422): "Chọn khoảng thời gian tối đa 12 tháng."

**Quy tắc áp dụng.** BR-09-002, BR-09-021, BR-09-060.

**Màn hình, API.** UI-09-02, UI-09-03; API-09-001, 002, 007, 008, 009, 010, 019, 030, 031; kịch bản TS-09-01.
:::

### 6.2. UC-09-02 · Đăng ký phần tử dữ liệu từ phân hệ, lược đồ và khai báo MVP

::: dac-ta
**Mục tiêu.** Mọi trường có thể mang DLCN đều có mặt trong danh mục ở trạng thái đề xuất, không để trường lọt khỏi tầm kiểm soát.

**Tác nhân chính.** TA, SO, DS (nhập tay); PH-06, PH-02, PH-04, PH-10 (tự đăng ký, scope `privacy:register`).

**Tác nhân phụ.** Kho lược đồ PH-02, PH-10, SV (Bình).

**Mức ưu tiên.** M · Đợt 2.

**FR hiện thực.** FR-09-003.

**Truy vết.** REQ-09; SEC-31; NT-10; DD-09; BP-04; hệ cũ: không có.

**Tiền điều kiện.** Có `PERM-09-classify` hoặc token dịch vụ `privacy:register`; lược đồ đúng định dạng OpenAPI, JSON Schema hoặc Avro.

**Kích hoạt.** Chọn "Nhập lược đồ" ở UI-09-02; phân hệ gọi API-09-012; lần đầu nâng cấp lên đợt 2 chạy nhập khai báo MVP.

**Đảm bảo tối thiểu.** Phần tử đã có không bị ghi đè; lô lỗi báo từng dòng, phần hợp lệ vẫn được ghi.

**Đảm bảo thành công.** Mỗi phần tử có `ElementScope`, `ElementStatus = ACTIVE` và một đề xuất phân loại `PROPOSED` (nguồn `SCHEMA_IMPORT`, `DECLARATION` hoặc `MVP_IMPORT`).

**Luồng chính.**
1. Bình tải lược đồ OpenAPI của `API-HOTICH-KHAISINH` ở UI-09-02 (API-09-013).
2. Hệ thống đọc lược đồ, bóc các trường (`hoTen`, `soDinhDanh`, `ngaySinh`, `noiSinh`), kiểm không có nhãn bí mật nhà nước.
3. Hệ thống tạo phần tử `API_SCHEMA` cho từng trường chưa đăng ký, mỗi phần tử một đề xuất `PROPOSED`.
4. Hệ thống trả danh sách phần tử mới và số trường bỏ qua do đã đăng ký; phát yêu cầu tính mức hợp đồng cho UC-09-05.
5. PH-06 đăng ký `ph06_mdm.citizen.national_id` theo lô (API-09-012); hệ thống ghi đề xuất `PROPOSED` để UC-09-03 xác nhận.

**Luồng thay thế.**
- **1a. Nhập khai báo MVP.** Cán bộ chạy API-09-014; hệ thống nhập `@Classified`, `x-dh-classification` ở trạng thái `PROPOSED`, giữ nguyên mức đã khai (BR-09-007).
- **3a. Ngừng phần tử.** TA, SO hoặc DO của tổ chức sở hữu ngừng phần tử không còn dùng bằng API-09-243 kèm lý do; phần tử sang `RETIRED` và vẫn giữ lịch sử phân loại (FR-09-003).

**Luồng ngoại lệ.**
- **E1. Phần tử đã đăng ký, đăng ký đơn (bước 3).** ERR-09-014 (409): "Phần tử {đích} đã được đăng ký."
- **E2. Lược đồ hỏng (bước 2).** ERR-09-015 (422): "Không đọc được lược đồ: {lý do}."
- **E3. Có nhãn bí mật nhà nước (bước 2).** ERR-09-018 (422): "Dữ liệu mang nhãn bí mật nhà nước không được đưa vào Datahub." và phát EVT-09-14 (UC-09-06).
- **E4. Ngừng phần tử còn liên kết (3a).** ERR-09-006 (409): "Đối tượng đang ở trạng thái {trạng thái}, không thực hiện được thao tác này." khi phần tử còn trong hoạt động `ACTIVE` hoặc chấp thuận hiệu lực.

**Quy tắc áp dụng.** BR-09-001, BR-09-005, BR-09-007.

**Màn hình, API.** UI-09-02, UI-09-03; API-09-010, 011, 012, 013, 014, 243; kịch bản TS-09-02.
:::

### 6.3. UC-09-03 · Đề xuất, xác nhận và hạ mức phân loại trường

::: dac-ta
**Mục tiêu.** Mỗi trường có phân loại `CONFIRMED` đúng mức và đúng loại DLCN, làm căn cứ để che, chấp thuận và lưu giữ.

**Tác nhân chính.** DS (Lan), SV (Bình) đề xuất; TA, SO, DO của tổ chức sở hữu xác nhận.

**Tác nhân phụ.** PH-06 (đề xuất `ph06_mdm.*`), PH-13.

**Mức ưu tiên.** M · Đợt 2.

**FR hiện thực.** FR-09-004.

**Truy vết.** REQ-09; CMP-LAW-05; SEC-31, SEC-37; DD-09; FR-06-004; hệ cũ: không có.

**Tiền điều kiện.** Phần tử `ACTIVE`; người đề xuất có `PERM-09-classify` (DS, SV chỉ đề xuất); người xác nhận thuộc tổ chức sở hữu phần tử.

**Kích hoạt.** Bấm "Đề xuất" hoặc "Xác nhận" ở UI-09-03; chọn nhiều dòng ở UI-09-02 rồi "Xác nhận hàng loạt".

**Đảm bảo tối thiểu.** Phần tử chưa `CONFIRMED` coi như `SENSITIVE` (BR-09-001); đề xuất cũ không mất, chuyển `SUPERSEDED`.

**Đảm bảo thành công.** Đề xuất thành `CONFIRMED`, phát EVT-09-01 (và EVT-09-03 nếu mức hợp đồng đổi) để PEP xóa đệm.

**Luồng chính.**
1. Lan mở `ph06_mdm.citizen.national_id` ở UI-09-03 và đề xuất `DataClass = SENSITIVE`, `PersonalDataType = SENSITIVE`, loại `NATIONAL_ID`, `IdentifiabilityType = DIRECT` (API-09-015).
2. Hệ thống tạo đề xuất `PROPOSED`, báo hộp việc của Dũng.
3. Dũng xem so sánh với đề xuất khác (nếu có), bấm "Xác nhận" (API-09-016).
4. Hệ thống kiểm Dũng khác Lan, kiểm đề xuất có loại DLCN khi trường là DLCN, đặt `CONFIRMED`, chuyển bản cũ `SUPERSEDED`.
5. Hệ thống phát EVT-09-01, tính lại mức hợp đồng (UC-09-05), ghi kiểm toán.

**Luồng thay thế.**
- **3a. Từ chối.** Dũng từ chối kèm lý do (API-09-017), đề xuất thành `REJECTED`.
- **3b. Xác nhận hàng loạt.** Chỉ khi mẫu đã duyệt (BR-09-007), qua API-09-018.
- **3c. Hạ mức.** Đề nghị hạ `RESTRICTED` xuống `INTERNAL` kèm số văn bản căn cứ; cần hai người khác nhau trước khi `CONFIRMED` (LP-09-01).

**Luồng ngoại lệ.**
- **E1. Người xác nhận ngoài tổ chức sở hữu (bước 3).** ERR-09-008 (403): "Bạn chỉ thao tác được trên dữ liệu thuộc tổ chức của mình."
- **E2. Người đề xuất tự xác nhận (bước 4).** ERR-09-005 (403): "Bạn là người đề nghị hoặc đã quyết định ở bước trước nên không được duyệt bước này."
- **E3. Hạ mức thiếu căn cứ (3c).** ERR-09-013 (422): "Hạ mức phân loại cần nêu số văn bản căn cứ và lý do."
- **E4. Trường DLCN thiếu loại (bước 4).** ERR-09-012 (422): "Trường {tên} là dữ liệu cá nhân, cần chọn loại dữ liệu cá nhân phù hợp."

**Quy tắc áp dụng.** BR-09-001, BR-09-002, BR-09-003, BR-09-007.

**Màn hình, API.** UI-09-02, UI-09-03; API-09-015, 016, 017, 018; kịch bản TS-09-03.
:::

### 6.4. UC-09-04 · Quét phát hiện trường nghi dữ liệu cá nhân chưa phân loại

::: dac-ta
**Mục tiêu.** Tìm trường có dấu hiệu DLCN (số định danh 12 chữ số, mã số thuế, thẻ ngân hàng kiểm Luhn, SĐT, thư điện tử, tên cột gợi ý) chưa được phân loại.

**Tác nhân chính.** TA, SO, DS; Job quét theo lịch `09.scan.schedule-cron`.

**Tác nhân phụ.** Nguồn dữ liệu được quét, PH-13.

**Mức ưu tiên.** S · Đợt 2.

**FR hiện thực.** FR-09-005.

**Truy vết.** REQ-09; SEC-31, SEC-32; NFR-00-029; ADR 093; hệ cũ: không có.

**Tiền điều kiện.** Có `PERM-09-classify`; nguồn quét đã đăng ký và cho phép đọc mẫu.

**Kích hoạt.** Bấm "Chạy quét" ở UI-09-04; đến lịch quét định kỳ.

**Đảm bảo tối thiểu.** Mẫu đọc chỉ nằm trong bộ nhớ, giá trị mẫu không ghi vào kết quả hay log (BR-09-025).

**Đảm bảo thành công.** Lượt quét `COMPLETED`, kết quả vào hộp việc, phát EVT-09-02.

**Luồng chính.**
1. Dũng chọn phạm vi `ph06_mdm` và bấm "Chạy quét" (API-09-020); hệ thống tạo lượt quét `QUEUED`.
2. Job đọc `09.scan.sample-rows` (10.000) dòng mỗi bảng, áp các `DetectorType` và tính độ tin cậy.
3. Hệ thống ghi kết quả `OPEN` cho cột đạt ngưỡng `09.scan.confidence` (0,8), không ghi giá trị mẫu.
4. Lan mở hộp việc (API-09-023) và xử lý từng kết quả: xác nhận là DLCN (chuyển đề xuất ở UC-09-03) hoặc loại trừ (API-09-024).
5. Hệ thống phát EVT-09-02 khi lượt quét kết thúc.

**Luồng thay thế.**
- **1a. Sửa mẫu phát hiện.** TA sửa ngưỡng hoặc biểu thức của mẫu (API-09-026); mẫu mới phải qua kiểm thử độ phức tạp.

**Luồng ngoại lệ.**
- **E1. Nguồn không khả dụng (bước 2).** ERR-09-009 (503): "Chưa kết nối được {tên dịch vụ}. Thử lại sau ít phút."; lượt quét `FAILED`, giữ kết quả đã có.
- **E2. Mẫu không an toàn (1a).** ERR-09-016 (422): "Mẫu phát hiện không hợp lệ hoặc có thể làm chậm hệ thống."
- **E3. Đang có lượt quét cùng phạm vi (bước 1).** ERR-09-017 (409): "Đang có lượt quét cho phạm vi này. Chờ lượt quét xong."

**Quy tắc áp dụng.** BR-09-006, BR-09-025.

**Màn hình, API.** UI-09-04; API-09-020, 021, 022, 023, 024, 025, 026; kịch bản TS-09-04.
:::

### 6.5. UC-09-05 · Tính và công bố mức phân loại của hợp đồng API, topic, luồng

::: dac-ta
**Mục tiêu.** Mức của hợp đồng bằng mức cao nhất của các trường để mọi điểm thực thi biết hợp đồng nào cần mục đích, chấp thuận và che.

**Tác nhân chính.** PH-02, PH-04, PH-10 (scope `privacy:register`); hệ thống PH-09.

**Tác nhân phụ.** TA, SO xem kết quả; PH-03, PH-14 (nhận EVT-09-03).

**Mức ưu tiên.** M · Đợt 2.

**FR hiện thực.** FR-09-006.

**Truy vết.** REQ-09; SEC-24, SEC-37; BP-02, BP-04; D03-07 §3.2; SAD §8.3; hệ cũ: không có.

**Tiền điều kiện.** Hợp đồng đã đăng ký phần tử ở UC-09-02.

**Kích hoạt.** Phân loại trường đổi (EVT-09-01); hợp đồng mới hoặc đổi lược đồ; gọi API-09-029.

**Đảm bảo tối thiểu.** Trường chưa `CONFIRMED` làm mức hợp đồng thành `SENSITIVE` tạm thời, đánh dấu `provisional`.

**Đảm bảo thành công.** Mức hợp đồng cập nhật trong 60 giây (NFR-09-010), phát EVT-09-03 khi đổi.

**Luồng chính.**
1. PH-02 gọi `POST /contract-levels:recompute` (API-09-029) cho hợp đồng `API-HOTICH-KHAISINH`.
2. Hệ thống lấy các trường của lược đồ, tìm phân loại hiệu lực của từng trường.
3. Hệ thống lấy mức cao nhất làm mức hợp đồng; có trường chưa `CONFIRMED` thì mức `SENSITIVE`, cờ `provisional`.
4. Hệ thống lưu mức, phát EVT-09-03 nếu khác mức cũ để PH-02, PH-03, PH-04, PH-10 cập nhật.
5. TA, SO xem mức ở UI-09-02 hoặc gọi API-09-027, API-09-028.

**Luồng thay thế.**
- **1a. Kích hoạt do phân loại đổi.** EVT-09-01 làm hệ thống tự tính lại mọi hợp đồng chứa trường, không cần ai gọi.
- **3a. Mức đổi từ `SENSITIVE` xuống thấp.** Hệ thống nhắc rà lại chấp thuận còn hiệu lực ở UC-09-11.

**Luồng ngoại lệ.**
- **E1. Không thấy hợp đồng (bước 1).** ERR-09-001 (404): "Không tìm thấy {đối tượng} {mã}."
- **E2. Phân hệ sở hữu không khả dụng (bước 2).** ERR-09-009 (503): "Chưa kết nối được {tên dịch vụ}. Thử lại sau ít phút."; giữ mức cũ, thử lại.

**Quy tắc áp dụng.** BR-09-001, BR-09-004.

**Màn hình, API.** UI-09-02, UI-09-03 (xem kết quả); API-09-027, 028, 029; kịch bản TS-09-05.
:::

### 6.6. UC-09-06 · Gán, gỡ nhãn và chặn dữ liệu bí mật nhà nước

::: dac-ta
**Mục tiêu.** Chặn toàn bộ bản tin có phần tử mang nhãn `STATE_SECRET`, không lộ trường nào mang nhãn, và kiểm soát chặt việc gỡ nhãn.

**Tác nhân chính.** TA, SO, DO (gán, gỡ nhãn); PH-04, PH-14, PH-17 (gọi kiểm tra).

**Tác nhân phụ.** PH-13, PH-18 (cảnh báo an ninh).

**Mức ưu tiên.** M · Đợt 2.

**FR hiện thực.** FR-09-007.

**Truy vết.** REQ-09; CMP-LAW-01, CMP-LAW-16; SEC-26; hệ cũ: không có.

**Tiền điều kiện.** Có `PERM-09-classify` (người) hoặc `privacy:decide` (PEP); nhãn nạp ở UC-09-01.

**Kích hoạt.** Đề nghị gán nhãn ở UI-09-03; bản tin vào chặng `schema` của PH-04.

**Đảm bảo tối thiểu.** Thân lỗi không nêu trường nào mang nhãn (BR-09-005); phần tử không rõ phân loại xử lý như `SENSITIVE`, không như bí mật nhà nước, kèm cảnh báo cấu hình.

**Đảm bảo thành công.** Bản tin mang nhãn bị từ chối toàn bộ, ghi cảnh báo mức nghiêm trọng và phát EVT-09-14.

**Luồng chính.**
1. Dũng đề nghị gán `STATE_SECRET` cho phần tử `ph06_mdm.citizen.note` kèm số văn bản (API-09-004); nhãn có hiệu lực ngay.
2. PH-04 gọi `classification:check` (API-09-231) ở chặng `schema` cho một bản tin.
3. Hệ thống thấy phần tử mang nhãn trong bản tin, trả DENY lý do `STATE_SECRET` mà không nêu trường nào.
4. PH-04 từ chối cả bản tin; hệ thống ghi cảnh báo an ninh và phát EVT-09-14 cho SO, PH-13, PH-18.
5. Dũng xem nhãn ở UI-09-03 (API-09-003).

**Luồng thay thế.**
- **1a. Gỡ nhãn.** Một người đề nghị kèm số và ngày văn bản giải mật (API-09-005); người thứ hai duyệt (API-09-006); nhãn gỡ có hiệu lực khi đủ hai người (LP-09-01).
- **3a. Không xác định được phân loại.** Xử lý như `SENSITIVE` và cảnh báo cấu hình.
- **3b. Kiểm cấm gửi ra ngoài tỉnh (PH-14).** Khi `egressScope` là `OUT_OF_PROVINCE`, hệ thống kiểm cờ `noEgress` của từng trường và trả `egressBlocked`, `egressBlockedFields[]`; PH-14 không gửi lô (FR-09-007, BR-09-063, NFR-09-027; chủ đầu tư chốt 27/11/2026).

**Luồng ngoại lệ.**
- **E1. Có nhãn khi đăng ký phần tử (UC-09-02).** ERR-09-018 (422): "Dữ liệu mang nhãn bí mật nhà nước không được đưa vào Datahub."
- **E2. Chặn trên đường dữ liệu (bước 4).** ERR-09-101 (403): "Dữ liệu bị chặn theo quy định bảo vệ bí mật nhà nước."
- **E3. Gỡ nhãn thiếu văn bản (1a).** ERR-09-019 (422): "Gỡ nhãn bí mật nhà nước cần số và ngày văn bản giải mật."
- **E4. Người duyệt gỡ nhãn trùng người đề nghị (1a).** ERR-09-005 (403): "Bạn là người đề nghị hoặc đã quyết định ở bước trước nên không được duyệt bước này."

**Quy tắc áp dụng.** BR-09-005, BR-09-057.

**Màn hình, API.** UI-09-03; API-09-003, 004, 005, 006, 231; kịch bản TS-09-06.
:::

### 6.7. UC-09-07 · Lập, duyệt, liên kết và xuất sổ hoạt động xử lý

::: dac-ta
**Mục tiêu.** Mỗi trường DLCN đã xác nhận thuộc ít nhất một hoạt động xử lý `ACTIVE`, và sổ xuất được theo mẫu.

**Tác nhân chính.** SO (Dũng), TA, DS (soạn); DA (Quân) duyệt.

**Tác nhân phụ.** PH-11 (nếu tenant bật duyệt qua quy trình), PH-13.

**Mức ưu tiên.** M · Đợt 2.

**FR hiện thực.** FR-09-009, FR-09-010, FR-09-011, FR-09-013.

**Truy vết.** REQ-09; CMP-LAW-04, CMP-LAW-05; SEC-37, SEC-39; ADR-046; D03-07 §6.2, §6.3; hệ cũ: không có.

**Tiền điều kiện.** Có `PERM-09-ropa`; danh mục cơ sở pháp lý và văn bản có hiệu lực (UC-09-08); người duyệt khác người soạn.

**Kích hoạt.** Bấm "Lập hoạt động" ở UI-09-05 (trình hướng dẫn UI-09-06).

**Đảm bảo tối thiểu.** Bản nháp lưu được từng bước; hoạt động `ACTIVE` giữ nguyên khi phiên bản mới còn chờ duyệt (BR-09-011).

**Đảm bảo thành công.** Phiên bản `ACTIVE`, liên kết đủ, phát EVT-09-04.

**Luồng chính.**
1. Dũng lập hoạt động `HD-HO-TICH-01`: mục đích, cơ sở `STATE_TASK`, loại DLCN, nhóm chủ thể, bên nhận, vai trò `CONTROLLER`, thời hạn lưu 60 tháng và hành động `ARCHIVE` (API-09-033).
2. Hệ thống kiểm đủ mục bắt buộc và có thời hạn lưu (BR-09-012), giữ bản nháp `DRAFT`.
3. Dũng liên kết hoạt động với trường `ph06_mdm.citizen.national_id` và hợp đồng `API-HOTICH-KHAISINH` (API-09-042).
4. Dũng gửi duyệt (API-09-036); Quân duyệt (API-09-037); hệ thống kiểm Quân khác Dũng, chuyển `ACTIVE`, phát EVT-09-04.
5. Dũng xuất sổ theo mẫu (API-09-052); hệ thống chạy nền, Dũng tải tệp ở API-09-053.

**Luồng thay thế.**
- **1a. Sửa hoạt động `ACTIVE`.** Hệ thống tạo phiên bản mới `DRAFT`, so sánh với bản cũ (API-09-040).
- **4a. Từ chối.** Quân từ chối kèm lý do (API-09-038), hoạt động về `REJECTED`.
- **4b. Ngừng hoạt động.** Gỡ hết liên kết rồi `:retire` (API-09-039).

**Luồng ngoại lệ.**
- **E1. Mã trùng (bước 1).** ERR-09-002 (409): "Mã {mã} đã được dùng. Chọn mã khác."
- **E2. Thiếu mục bắt buộc (bước 2).** ERR-09-020 (422): "Hoạt động xử lý còn thiếu: {danh sách mục}."
- **E3. Hoạt động bắt buộc theo luật chọn đồng ý làm cơ sở (bước 1).** ERR-09-024 (422): "Hoạt động bắt buộc theo luật không dùng sự đồng ý làm cơ sở pháp lý."
- **E4. Duyệt sai người (bước 4).** ERR-09-005 (403): "Bạn là người đề nghị hoặc đã quyết định ở bước trước nên không được duyệt bước này."
- **E5. Ngừng khi còn liên kết (4b).** ERR-09-022 (409): "Hoạt động còn {n} liên kết đang hiệu lực. Gỡ liên kết trước khi ngừng."
- **E6. Kích hoạt hợp đồng khi còn trường chưa thuộc hoạt động.** ERR-09-023 (422): "Có {n} trường dữ liệu cá nhân chưa thuộc hoạt động xử lý nào."
- **E7. Từ chối hoặc ngừng thiếu lý do (4a, 4b).** ERR-09-007 (422): "Nhập lý do tối thiểu 20 ký tự."
- **E8. Mẫu xuất không có (bước 5).** ERR-09-025 (422): "Mẫu xuất {mã} không tồn tại."

**Quy tắc áp dụng.** BR-09-008, BR-09-009, BR-09-010, BR-09-011, BR-09-012, BR-09-025.

**Màn hình, API.** UI-09-05, UI-09-06; API-09-032…044, 051, 052, 053; kịch bản TS-09-07.
:::

### 6.8. UC-09-08 · Quản lý danh mục cơ sở pháp lý, văn bản căn cứ và mục đích khai thác

::: dac-ta
**Mục tiêu.** Có danh mục cơ sở pháp lý, văn bản căn cứ và mục đích khai thác, kèm cờ mục đích bắt buộc theo luật (`statutory`) dùng cho trường hợp chủ thể bị hạn chế xử lý.

**Tác nhân chính.** TA, SO, DO (mục đích của tổ chức mình).

**Tác nhân phụ.** DS.

**Mức ưu tiên.** M · Đợt 2.

**FR hiện thực.** FR-09-012, FR-09-014.

**Truy vết.** REQ-09; CMP-LAW-03, CMP-LAW-04, CMP-LAW-05; SEC-37; D03-07 §6.3; D02-08 scope `purpose:{mã}`; Q09-03.

**Tiền điều kiện.** `PERM-09-ropa` cho cơ sở pháp lý và văn bản; `PERM-09-purpose-approve` hoặc `PERM-09-policy` cho mục đích.

**Kích hoạt.** Mở UI-09-07, tab "Mục đích" hoặc "Cơ sở".

**Đảm bảo tối thiểu.** Mục đích hoặc văn bản đã dùng không bị xóa, chỉ ngừng.

**Đảm bảo thành công.** Mục được thêm hoặc sửa có hiệu lực, ghi kiểm toán.

**Luồng chính.**
1. Dũng mở tab "Cơ sở" ở UI-09-07, thêm văn bản căn cứ "Luật BVDLCN 91/2025" hiệu lực từ 01/01/2026 (API-09-049).
2. Dũng thêm cơ sở pháp lý `STATE_TASK` trỏ tới văn bản trên (API-09-046).
3. Phúc mở tab "Mục đích", thêm mục đích `TTHC-HO-TICH`, loại dữ liệu tối đa `SENSITIVE`, hạn tối đa 365 ngày, cờ `statutory` (API-09-055).
4. Hệ thống kiểm mã chưa dùng, ghi mục đích `ACTIVE` và kiểm toán.
5. Khi mục đích hết nhu cầu, Phúc gọi `:retire` (API-09-057); mục đích về `RETIRED`.

**Luồng thay thế.**
- **1a. Văn bản hết hiệu lực.** Sửa hiệu lực (API-09-050); cơ sở đang dùng văn bản đó hiện cảnh báo ở sổ xử lý.

**Luồng ngoại lệ.**
- **E1. Mã trùng (bước 2, 4).** ERR-09-002 (409): "Mã {mã} đã được dùng. Chọn mã khác."
- **E2. Chọn văn bản hết hiệu lực (bước 2).** ERR-09-021 (422): "Văn bản căn cứ {mã} không còn hiệu lực. Chọn căn cứ khác."
- **E3. Ngừng mục đích còn chấp thuận hiệu lực (bước 5).** ERR-09-006 (409): "Đối tượng đang ở trạng thái {trạng thái}, không thực hiện được thao tác này."

**Quy tắc áp dụng.** BR-09-009, BR-09-015, BR-09-047.

**Màn hình, API.** UI-09-07; API-09-045…050, 054, 055, 056, 057; kịch bản TS-09-08.
:::

### 6.9. UC-09-09 · Lập yêu cầu khai thác theo mục đích

::: dac-ta
**Mục tiêu.** HTTT có yêu cầu khai thác đầy đủ, đúng phạm vi mục đích, để chủ quản dữ liệu thẩm định.

**Tác nhân chính.** OR (Thảo), SV (Bình), TA.

**Tác nhân phụ.** PH-02 (đăng ký sử dụng), DO (nhận việc), PH-11 hoặc "Việc của tôi".

**Mức ưu tiên.** M · Đợt 2.

**FR hiện thực.** FR-09-015.

**Truy vết.** REQ-09; SEC-37; THR-51; BP-01; LGC-NGSP-003; D02-08 scope `purpose:{mã}`.

**Tiền điều kiện.** Có `PERM-09-purpose-request` (○ theo tổ chức); HTTT `ACTIVE` và đã có đăng ký sử dụng ở PH-02; mục đích `ACTIVE`.

**Kích hoạt.** Bấm "Lập yêu cầu" ở UI-09-08.

**Đảm bảo tối thiểu.** Bản nháp lưu được, chưa gửi thì chủ quản không thấy.

**Đảm bảo thành công.** Yêu cầu `SUBMITTED`, phát EVT-09-05 cho DO.

**Luồng chính.**
1. Thảo chọn HTTT `HT-YTE`, hợp đồng `API-HOTICH-KHAISINH`, mục đích `TTHC-HO-TICH` (API-09-059).
2. Thảo chọn trường cần (`hoTen`, `ngaySinh`), khối lượng dự kiến 2.000 lượt mỗi ngày và thời hạn đề nghị 180 ngày (API-09-061).
3. Hệ thống kiểm HTTT, trường nằm trong phạm vi mục đích, chưa có chấp thuận trùng bộ ba (HTTT, mục đích, hợp đồng).
4. Thảo gửi thẩm định (API-09-062); hệ thống chuyển `SUBMITTED`, phát EVT-09-05.

**Luồng thay thế.**
- **4a. Rút yêu cầu.** Rút khi chưa quyết định (API-09-063), yêu cầu thành `WITHDRAWN`.
- **1a. Xem chấp thuận hiện có.** Danh sách và chi tiết ở API-09-058, API-09-060, kể cả để gia hạn (UC-09-11).
- **1b. Đề nghị gia hạn.** OR lập yêu cầu loại `RENEWAL` (`AccessRequestKind`) kèm `renewsGrantId` của chấp thuận `ACTIVE` cùng HTTT và mục đích; DO duyệt ở UC-09-10, rồi hệ thống áp gia hạn ở UC-09-11 (FR-09-015, 016).

**Luồng ngoại lệ.**
- **E1. HTTT chưa hoạt động (bước 1).** ERR-09-027 (422): "HTTT {mã} chưa hoạt động hoặc chưa có đăng ký sử dụng hợp lệ."
- **E2. Mục đích đã ngừng (bước 1).** ERR-09-026 (422): "Mục đích {mã} không còn hiệu lực."
- **E3. Trường ngoài phạm vi mục đích (bước 3).** ERR-09-028 (422): "Trường {tên} nằm ngoài phạm vi của mục đích {mã}."
- **E4. Đã có chấp thuận còn hiệu lực (bước 3).** ERR-09-029 (409): "Đã có chấp thuận còn hiệu lực cho HTTT, mục đích và hợp đồng này."

**Quy tắc áp dụng.** BR-09-013, BR-09-015, BR-09-016.

**Màn hình, API.** UI-09-08; API-09-058…063; kịch bản TS-09-09.
:::

### 6.10. UC-09-10 · Thẩm định, chấp thuận có điều kiện hoặc từ chối yêu cầu khai thác

::: dac-ta
**Mục tiêu.** Quyết định khai thác dựa trên mục đích, trường cần, hoạt động xử lý và lịch sử khai thác, với điều kiện thu hẹp phạm vi.

**Tác nhân chính.** DO (Phúc).

**Tác nhân phụ.** OR (Thảo), PH-12 (OPA), PH-02, PH-03, Kafka.

**Mức ưu tiên.** M · Đợt 2.

**FR hiện thực.** FR-09-016.

**Truy vết.** REQ-09; CMP-LAW-03; SEC-37; THR-51; ADR-046; BP-01.

**Tiền điều kiện.** Có `PERM-09-purpose-approve` (○, tổ chức sở hữu hợp đồng); yêu cầu `SUBMITTED` hoặc `UNDER_REVIEW`; Phúc không phải người lập.

**Kích hoạt.** Mở việc ở UI-09-09 (hộp việc chấp thuận); nhắc khi quá `09.request.sla-days`.

**Đảm bảo tối thiểu.** Kiểm tra thất bại thì yêu cầu không đổi trạng thái; từ chối luôn có lý do.

**Đảm bảo thành công.** `PurposeGrant` `ACTIVE` (hoặc `SCHEDULED`), phát EVT-09-06 và kích hoạt dựng bundle (UC-09-12).

**Luồng chính.**
1. Phúc mở yêu cầu ở UI-09-09 (API-09-064, API-09-060), xem trường, mức, hoạt động xử lý và lịch sử khai thác của HTTT; hệ thống chuyển `UNDER_REVIEW`.
2. Phúc chọn `APPROVE_WITH_CONDITIONS`, thu hẹp còn `hoTen`, đặt hạn 180 ngày, hạn ngạch 3.000 lượt mỗi ngày, điều kiện `NO_EXPORT` (API-09-065).
3. Hệ thống kiểm Phúc không phải người lập, đúng tổ chức và hạn không vượt `09.grant.max-days`.
4. Hệ thống tạo `PurposeGrant`, phát EVT-09-06, thông báo Thảo và dựng bundle mới; chấp thuận có hiệu lực tại điểm thực thi trong 60 giây.

**Luồng thay thế.**
- **2a. Yêu cầu bổ sung.** `:request-info` (API-09-066) kèm lý do, yêu cầu về `NEEDS_INFO`, Thảo bổ sung rồi gửi lại.
- **2b. Từ chối.** `REJECT` kèm lý do; yêu cầu `REJECTED`, thông báo Thảo.
- **2c. Hiệu lực tương lai.** Ngày bắt đầu sau hôm nay thì chấp thuận `SCHEDULED`, tự `ACTIVE` khi đến ngày.

**Luồng ngoại lệ.**
- **E1. Duyệt yêu cầu của chính mình (bước 3).** ERR-09-005 (403): "Bạn là người đề nghị hoặc đã quyết định ở bước trước nên không được duyệt bước này."
- **E2. Ngoài tổ chức sở hữu (bước 3).** ERR-09-008 (403): "Bạn chỉ thao tác được trên dữ liệu thuộc tổ chức của mình."
- **E3. Hạn vượt tối đa (bước 3).** ERR-09-030 (422): "Thời hạn chấp thuận tối đa {n} ngày."
- **E4. Từ chối hoặc xin bổ sung thiếu lý do (2a, 2b).** ERR-09-007 (422): "Nhập lý do tối thiểu 20 ký tự."

**Quy tắc áp dụng.** BR-09-013, BR-09-014, BR-09-015, BR-09-016, BR-09-017; LP-09-01, LP-09-02.

**Màn hình, API.** UI-09-09; API-09-064, 065, 066; kịch bản TS-09-10.
:::

```{.mermaid caption="Trình tự chấp thuận mục đích đến hiệu lực tại điểm thực thi"}
sequenceDiagram
  actor DO as DO Phúc
  participant P as privacy-core
  participant K as Kafka
  participant B as bundle-builder
  participant V as OpenBao
  participant O as OPA PH-12
  participant E as PEP PH-03
  DO->>P: Quyết định APPROVE_WITH_CONDITIONS (API-09-065)
  P->>P: Kiểm người lập, tổ chức, hạn
  P->>P: Tạo PurposeGrant ACTIVE, ghi kiểm toán
  P->>K: EVT-09-06 purpose-grant.approved
  K->>B: Gom thay đổi 10 giây
  B->>B: Dựng dữ liệu purpose_grants, chạy Rego và golden set
  B->>V: Ký bundle bằng khóa transit
  V-->>B: Chữ ký
  B->>O: Phát hành bundle có validUntil 60 phút
  B->>K: EVT-09-11 bundle.published
  O-->>E: Nạp bundle, chấp thuận có hiệu lực
  P-->>DO: Hoàn tất, HTTT được thông báo
```

Hình cho thấy chấp thuận chỉ có hiệu lực khi bundle ký tới OPA, chậm nhất 60 giây (NFR-09-005); thu hồi đi đường sự kiện đẩy, 15 giây.

### 6.11. UC-09-11 · Gia hạn, sửa, tạm dừng, thu hồi chấp thuận và tự hết hạn

::: dac-ta
**Mục tiêu.** Giữ chấp thuận luôn đúng thực tế: gia hạn khi còn nhu cầu, tạm dừng khi nghi ngờ, thu hồi khi vi phạm hoặc hết nhu cầu.

**Tác nhân chính.** DO (Phúc); OR (Thảo) đề nghị gia hạn; job hết hạn.

**Tác nhân phụ.** PH-02, PH-03, PH-04, PH-12, PH-14 (nhận sự kiện).

**Mức ưu tiên.** M · Đợt 2.

**FR hiện thực.** FR-09-017.

**Truy vết.** REQ-09; SEC-37; THR-51, THR-54.

**Tiền điều kiện.** Chấp thuận ở trạng thái hợp lệ cho thao tác; `PERM-09-purpose-approve` (○).

**Kích hoạt.** Chọn thao tác ở UI-09-08 hoặc UI-09-09; job hằng ngày phát hiện sắp hết hạn; cảnh báo bất thường (UC-09-14).

**Đảm bảo tối thiểu.** Thao tác sai trạng thái không đổi gì; mọi thao tác có lý do và kiểm toán.

**Đảm bảo thành công.** Trạng thái mới có hiệu lực tại PEP trong 15 giây (đẩy) và chậm nhất 60 giây (bundle), đo theo NFR-09-024; chấp thuận quá `validTo` bị từ chối trong 60 giây và chuyển `EXPIRED` trong 5 phút (NFR-09-025).

**Luồng chính.**
1. Job phát EVT-09-10 khi chấp thuận còn `09.grant.expiring-notice-days` (30) ngày; Thảo thấy ở UI-09-08.
2. Thảo đề nghị gia hạn; Phúc gia hạn thêm 180 ngày (API-09-069, lần 1 trong tối đa 3 lần).
3. Hệ thống cập nhật `expiresAt`, phát EVT-09-06, dựng bundle (UC-09-12).
4. Chấp thuận không được gia hạn đến hạn thì job đặt `EXPIRED` và phát EVT-09-09.

**Luồng thay thế.**
- **2a. Sửa.** Đổi trường, điều kiện, hạn ngạch (API-09-070).
- **2b. Tạm dừng.** `:suspend` kèm lý do (API-09-071), phát EVT-09-07; khôi phục bằng `:resume` (API-09-072).
- **2c. Thu hồi.** `:revoke` kèm lý do (API-09-073), phát EVT-09-08; không hoàn tác, muốn dùng lại phải lập yêu cầu mới.
- **2d. Tự tạm dừng.** Khi `09.anomaly.auto-suspend` bật và có bất thường mức cao (UC-09-14), hệ thống tạm dừng và báo Phúc.

**Luồng ngoại lệ.**
- **E1. Gia hạn quá số lần (bước 2).** ERR-09-031 (422): "Chấp thuận đã gia hạn tối đa {n} lần. Lập yêu cầu mới."
- **E2. Thao tác sai trạng thái (2b, 2c).** ERR-09-006 (409): "Đối tượng đang ở trạng thái {trạng thái}, không thực hiện được thao tác này."
- **E3. Thiếu lý do (2b, 2c).** ERR-09-007 (422): "Nhập lý do tối thiểu 20 ký tự."

**Quy tắc áp dụng.** BR-09-013, BR-09-015, BR-09-017, BR-09-062; LP-09-02.

**Màn hình, API.** UI-09-08, UI-09-09; API-09-067…073; kịch bản TS-09-11.
:::

### 6.12. UC-09-12 · Dựng, ký và phát hành bundle OPA

::: dac-ta
**Mục tiêu.** Đưa chấp thuận, chính sách che và phân loại tới mọi OPA trong 60 giây, có chữ ký và hạn dùng để OPA không tin bundle giả hoặc quá hạn.

**Tác nhân chính.** Hệ thống PH-09 (bundle-builder).

**Tác nhân phụ.** OpenBao (ký), PH-12 (OPA, máy chủ bundle), PH-03; DA, TA, SO (phát hành thủ công, xem trạng thái).

**Mức ưu tiên.** M · Đợt 2.

**FR hiện thực.** FR-09-018.

**Truy vết.** REQ-09; SEC-26, SEC-36; THR-39, THR-40; ADR-006.

**Tiền điều kiện.** OpenBao transit khả dụng; kho `dh-policies` có Rego đã kiểm thử.

**Kích hoạt.** Sự kiện đổi chấp thuận, chính sách che, phân loại; làm mới 30 phút; bấm phát hành.

**Đảm bảo tối thiểu.** Bundle không qua kiểm thử hoặc không ký được thì không phát hành, bundle cũ vẫn dùng.

**Đảm bảo thành công.** Bundle mới có `bundleId`, `validUntil`, đã ký, mọi OPA nạp (p99 ≤ 60 giây).

**Luồng chính.**
1. Hệ thống gom thay đổi trong `09.bundle.debounce-seconds` (10), dựng `purpose_grants`, `mask_policies`, chỉ mục phân loại kèm băm nội dung.
2. Hệ thống chạy kiểm thử Rego và golden set 300 ca (NFR-09-008), kiểm kích thước ≤ 5 MB.
3. Hệ thống ký bằng khóa transit không xuất được, đặt `validUntil` = nay + `09.bundle.valid-minutes` (60).
4. Hệ thống phát lên máy chủ bundle PH-12, phát EVT-09-11 và theo dõi OPA đã nạp (API-09-078).
5. Điểm thực thi lấy bản hiện hành qua API-09-233 với `ETag`.

**Luồng thay thế.**
- **1a. Phát hành thủ công.** DA hoặc TA gọi API-09-076 khi cần gấp.
- **4a. Quay lại bundle trước.** Khi bundle mới gây lỗi, `:rollback` (API-09-077).
- **1b. Không có thay đổi.** Làm mới định kỳ chỉ gia hạn `validUntil`.

**Luồng ngoại lệ.**
- **E1. OpenBao không khả dụng (bước 3).** ERR-09-032 (503): "Chưa ký được gói chính sách vì OpenBao không khả dụng. Gói cũ vẫn có hiệu lực."
- **E2. Không qua kiểm thử (bước 2).** ERR-09-033 (422): "Gói chính sách không qua kiểm thử: {lỗi}. Không phát hành."
- **E3. Bundle quá `validUntil` (vận hành).** Hợp đồng `SENSITIVE` bị từ chối ở PEP (ERR-09-102), cảnh báo ở UI-09-09.

**Quy tắc áp dụng.** BR-09-017, BR-09-018.

**Màn hình, API.** UI-09-09 (băng đồng bộ); API-09-074…078, 233; kịch bản TS-09-12.
:::

### 6.13. UC-09-13 · Quyết định mục đích trực tuyến cho điểm thực thi

::: dac-ta
**Mục tiêu.** Cho phép hoặc từ chối một lời gọi tới hợp đồng theo mức, nhãn chặn, mục đích, chấp thuận và hạn chế xử lý của chủ thể.

**Tác nhân chính.** PH-03, PH-04, PH-06, PH-14, PH-19 (scope `privacy:decide`).

**Tác nhân phụ.** HTTT khai thác (mang `purpose:{mã}`), OPA.

**Mức ưu tiên.** M · Đợt 2.

**FR hiện thực.** FR-09-019.

**Truy vết.** REQ-09; LGC-NGSP-003; SEC-26, SEC-37; THR-51; BP-06.

**Tiền điều kiện.** Bundle hiện hành đã nạp; bên gọi có SPIFFE ID hợp lệ.

**Kích hoạt.** Lời gọi tới hợp đồng mức `RESTRICTED` trở lên.

**Đảm bảo tối thiểu.** Không rõ thì từ chối (đóng an toàn); mọi quyết định `SENSITIVE` có bản ghi kiểm toán.

**Đảm bảo thành công.** Trả `{decision, reasonCode, allowedFields, obligations, grantId, planVersion}` trong p95 ≤ 50 ms (NFR-09-001).

**Luồng chính.**
1. PH-03 gọi `POST /privacy/v1/purpose:decide` (API-09-227) cho `HT-YTE`, hợp đồng `API-HOTICH-KHAISINH`, `purpose:TTHC-HO-TICH`.
2. Hệ thống kiểm nhãn chặn; có nhãn thì DENY lý do `STATE_SECRET`. Điểm thực thi đệm `ALLOW` tối đa 15 giây và `DENY` tối đa 5 giây, thu hồi hoặc tạm dừng xóa đệm ngay (BR-09-062).
3. Hệ thống tra mức hợp đồng: `PUBLIC`, `INTERNAL` cho phép và ghi mục đích; `RESTRICTED` kiểm mục đích thuộc danh mục; `SENSITIVE` đòi chấp thuận `ACTIVE` phủ đủ trường và điều kiện.
4. Chủ thể đang bị hạn chế thì chỉ mục đích `statutory` được phép.
5. Hệ thống trả ALLOW kèm `allowedFields`, `obligations`; PEP đếm lượt và báo theo lô (UC-09-14).

**Luồng thay thế.**
- **1a. OPA cục bộ.** PEP dùng OPA, kết quả tương đương 100% golden set; gọi API chỉ khi cần giải thích.

**Luồng ngoại lệ.**
- **E1. Thiếu mục đích (bước 1).** ERR-09-103 (400): "Thiếu mã mục đích hợp lệ trong yêu cầu."
- **E2. Không có chấp thuận (bước 3).** ERR-09-102 (403): "Không có chấp thuận mục đích còn hiệu lực cho yêu cầu này."
- **E3. Chủ thể bị hạn chế (bước 4).** ERR-09-104 (403): "Chủ thể đang bị hạn chế xử lý, mục đích này không được phép."
- **E4. Bên gọi không được phép (bước 1).** ERR-09-111 (403): "Bên gọi không được phép dùng API quyền riêng tư."
- **E5. Nhãn bí mật nhà nước (bước 2).** ERR-09-101 (403): "Dữ liệu bị chặn theo quy định bảo vệ bí mật nhà nước."

**Quy tắc áp dụng.** BR-09-005, BR-09-019, BR-09-020, BR-09-047, BR-09-062.

**Màn hình, API.** Không có màn hình (kết quả xem ở UI-09-01, UI-09-20); API-09-227; kịch bản TS-09-13.
:::

### 6.14. UC-09-14 · Phát hiện khai thác vượt mục đích, hạn ngạch và báo cáo khai thác

::: dac-ta
**Mục tiêu.** Phát hiện bất thường trong 5 phút và cho chủ quản, cán bộ ATTT xử lý có ghi nhận; có báo cáo khai thác theo mục đích.

**Tác nhân chính.** DO (Phúc), SO (Dũng), TA.

**Tác nhân phụ.** PEP (báo lượt), PH-13, PH-18, AU.

**Mức ưu tiên.** S · Đợt 2.

**FR hiện thực.** FR-09-020, FR-09-021.

**Truy vết.** REQ-09; SEC-37, SEC-64, SEC-86; THR-51, THR-54; BO-04; BP-06.

**Tiền điều kiện.** Có chấp thuận hiệu lực được đếm lượt; quy tắc ngưỡng đã đặt (`09.anomaly.*`).

**Kích hoạt.** PEP gọi `usage-events:report`; mở UI-09-01, UI-09-09.

**Đảm bảo tối thiểu.** Cảnh báo không chứa giá trị DLCN, chỉ HTTT, hợp đồng, số lượt.

**Đảm bảo thành công.** Cảnh báo `OPEN` ở hộp việc, phát EVT-09-13 trong 5 phút sau khi vượt ngưỡng (NFR-09-026); báo cáo xuất được.

**Luồng chính.**
1. PH-03 báo lượt khai thác theo lô (API-09-237) mỗi phút.
2. Hệ thống đếm theo (HTTT, mục đích, hợp đồng) và so với hạn ngạch 3.000 lượt mỗi ngày và `09.anomaly.bulk-threshold`.
3. `HT-YTE` dùng 80% hạn ngạch: hệ thống tạo cảnh báo `QUOTA_EXCEEDED` mức cảnh báo, phát EVT-09-13 cho SO và Phúc.
4. Phúc xem (API-09-079, API-09-080) và ghi nhận đã xem (API-09-081).
5. Thảo hoặc Phúc xem báo cáo theo mục đích 12 tháng (API-09-086), xuất nền (API-09-087).

**Luồng thay thế.**
- **4a. Loại trừ.** `:dismiss` kèm lý do (API-09-082), cảnh báo `DISMISSED`.
- **4b. Chuyển vụ việc.** `:escalate` (API-09-083) tạo vụ việc ở UC-09-33.

**Luồng ngoại lệ.**
- **E1. Ngưỡng không hợp lệ (2a).** ERR-09-034 (422): "Ngưỡng cảnh báo không hợp lệ."
- **E2. Loại trừ thiếu lý do (4a).** ERR-09-007 (422): "Nhập lý do tối thiểu 20 ký tự."
- **E3. Khoảng báo cáo quá 12 tháng (bước 5).** ERR-09-036 (422): "Chọn khoảng thời gian tối đa 12 tháng."

**Quy tắc áp dụng.** BR-09-020, BR-09-060.

**Màn hình, API.** UI-09-01, UI-09-09; API-09-079…087, 237; kịch bản TS-09-14.
:::

### 6.15. UC-09-15 · Chặn kích hoạt hợp đồng mức Nhạy cảm khi chưa có mục đích và chấp thuận

::: dac-ta
**Mục tiêu.** Không hợp đồng chứa dữ liệu Nhạy cảm nào được kích hoạt khi chưa có mục đích, chấp thuận và hoạt động xử lý (SEC-37).

**Tác nhân chính.** PH-02, PH-04 (scope `privacy:register`).

**Tác nhân phụ.** SV (Bình), TA (xem hợp đồng bị chặn).

**Mức ưu tiên.** M · Đợt 2.

**FR hiện thực.** FR-09-022.

**Truy vết.** REQ-09; SEC-37; NT-10; THR-51; BP-01, BP-02.

**Tiền điều kiện.** Hợp đồng có mức đã tính ở UC-09-05.

**Kích hoạt.** Người dùng bấm kích hoạt hợp đồng ở PH-02 hoặc luồng ở PH-04.

**Đảm bảo tối thiểu.** PH-09 không khả dụng thì PH-02, PH-04 chặn kích hoạt hợp đồng `SENSITIVE` (đóng an toàn).

**Đảm bảo thành công.** Hợp đồng đủ điều kiện được trả "cho phép"; hợp đồng thiếu điều kiện được nêu lý do cụ thể.

**Luồng chính.**
1. PH-02 gọi `POST /activation-checks` (API-09-088) cho `API-HOTICH-KHAISINH`.
2. Hệ thống đọc mức hợp đồng; mức `SENSITIVE` thì kiểm có mục đích, chấp thuận và mọi trường DLCN thuộc hoạt động xử lý `ACTIVE`.
3. Thiếu điều kiện: hệ thống trả từ chối kèm danh sách thiếu (chấp thuận, hoạt động, trường chưa phân loại).
4. Đủ điều kiện: hệ thống trả cho phép; PH-02 kích hoạt.
5. TA xem hợp đồng đang bị chặn ở UI-09-09 (API-09-089).

**Luồng thay thế.**
- **2a. Mức `RESTRICTED`.** Chỉ cần mục đích thuộc danh mục; cần chấp thuận khi `09.grant.require-restricted` bật.

**Luồng ngoại lệ.**
- **E1. Thiếu điều kiện (bước 3).** ERR-09-035 (422): "Hợp đồng {mã} chứa dữ liệu Nhạy cảm, cần mục đích và chấp thuận của chủ quản trước khi kích hoạt."
- **E2. Còn trường chưa thuộc hoạt động (bước 2).** ERR-09-023 (422): "Có {n} trường dữ liệu cá nhân chưa thuộc hoạt động xử lý nào."
- **E3. PH-09 không khả dụng (bước 1).** ERR-09-009 (503): "Chưa kết nối được {tên dịch vụ}. Thử lại sau ít phút."

**Quy tắc áp dụng.** BR-09-001, BR-09-008, BR-09-019.

**Màn hình, API.** UI-09-09, UI-09-02; API-09-088, 089; kịch bản TS-09-15.
:::

### 6.16. UC-09-16 · Quản lý kiểu che và soạn chính sách che

::: dac-ta
**Mục tiêu.** Có chính sách che tập trung thay cho cấu hình che tay từng luồng của hệ cũ.

**Tác nhân chính.** TA (Mai), SO, DS (○).

**Tác nhân phụ.** PH-13.

**Mức ưu tiên.** M · Đợt 2.

**FR hiện thực.** FR-09-023, FR-09-024.

**Truy vết.** REQ-09; CMP-LAW-05; SEC-32; LGC-TOOL-012; D03-07 §3.2; DD-09 `mask_pattern`.

**Tiền điều kiện.** Có `PERM-09-policy`; kiểu che hợp kiểu dữ liệu của trường.

**Kích hoạt.** Mở UI-09-10, tab "Kiểu che" hoặc "Quy tắc".

**Đảm bảo tối thiểu.** Phiên bản `ACTIVE` không sửa tại chỗ; chỉ sửa bản `DRAFT`.

**Đảm bảo thành công.** Phiên bản nháp hợp lệ, sẵn sàng mô phỏng ở UC-09-17.

**Luồng chính.**
1. Mai xem bảy kiểu che `NONE`, `PARTIAL`, `REPLACE`, `KEYED_HASH`, `TOKENIZE`, `GENERALIZE`, `DROP` và mẫu `KEEP_LAST_N` (API-09-090); sửa mẫu che (API-09-091).
2. Mai tạo chính sách `CS-HO-TICH` bản nháp (API-09-093).
3. Mai thêm quy tắc: `NATIONAL_ID`, vai trò TO, mục đích `TTHC-HO-TICH`, kênh `API`, kiểu `PARTIAL` giữ 4 số cuối (API-09-095).
4. Hệ thống kiểm kiểu che hợp kiểu dữ liệu, không có hai quy tắc trùng ưu tiên, có quy tắc mặc định cho mức `SENSITIVE`.
5. Hệ thống lưu bản nháp và hiện ví dụ trước, sau che.

**Luồng thay thế.**
- **3a. Quy tắc cụ thể hơn.** Quy tắc cụ thể thắng quy tắc chung; trùng độ ưu tiên thì kiểu chặt hơn thắng (BR-09-022).

**Luồng ngoại lệ.**
- **E1. Kiểu che không hợp kiểu dữ liệu (bước 4).** ERR-09-037 (422): "Kiểu che {kiểu} không áp dụng được cho trường kiểu {kiểu dữ liệu}."
- **E2. Quy tắc xung đột hoặc thiếu mặc định (bước 4).** ERR-09-038 (422): "Chính sách có quy tắc trùng ưu tiên hoặc thiếu quy tắc mặc định cho mức Nhạy cảm."
- **E3. Sửa phiên bản không phải nháp (bước 3).** ERR-09-006 (409): "Đối tượng đang ở trạng thái {trạng thái}, không thực hiện được thao tác này."

**Quy tắc áp dụng.** BR-09-021, BR-09-022, BR-09-024.

**Màn hình, API.** UI-09-10; API-09-090…095; kịch bản TS-09-16.
:::

### 6.17. UC-09-17 · Mô phỏng, duyệt và phát hành chính sách che

::: dac-ta
**Mục tiêu.** Chính sách che mới chỉ có hiệu lực sau khi đã chạy thử và có người khác duyệt, tránh làm lộ hoặc che nhầm dữ liệu.

**Tác nhân chính.** TA, SO, DS (mô phỏng, gửi duyệt); DA (Quân), TA, SO (duyệt).

**Tác nhân phụ.** PH-03, PH-04, PH-06, PH-14, PH-19 (nhận EVT-09-12).

**Mức ưu tiên.** M · Đợt 2.

**FR hiện thực.** FR-09-025, FR-09-026.

**Truy vết.** REQ-09; SEC-32; NFR-00-029; ADR-046, ADR-051.

**Tiền điều kiện.** Bản nháp từ UC-09-16; `PERM-09-policy` để gửi, `PERM-09-policy-approve` để duyệt.

**Kích hoạt.** Bấm "Mô phỏng" ở UI-09-11; bấm "Gửi duyệt" ở UI-09-10.

**Đảm bảo tối thiểu.** Dữ liệu mẫu không lưu; chính sách `ACTIVE` cũ chạy tới khi bản mới được duyệt.

**Đảm bảo thành công.** Phiên bản mới `ACTIVE`, bản cũ `SUPERSEDED`, phát EVT-09-12, bundle mới (UC-09-12).

**Luồng chính.**
1. Mai dán 200 dòng dữ liệu mẫu giả lập vào UI-09-11, chọn vai trò TO, mục đích `TTHC-HO-TICH`, kênh `API` (API-09-101).
2. Hệ thống trả xem trước sau che, đánh dấu trường lộ ngoài dự kiến; kết quả đạt thì ghi "đạt mô phỏng".
3. Mai gửi duyệt (API-09-096); hệ thống kiểm đã đạt mô phỏng.
4. Quân xem so sánh hai phiên bản (API-09-100) và duyệt (API-09-097); hệ thống kiểm Quân khác Mai.
5. Hệ thống kích hoạt phiên bản mới, phát EVT-09-12 để PEP xóa đệm kế hoạch, dựng bundle.

**Luồng thay thế.**
- **4a. Từ chối.** Quân từ chối kèm lý do (API-09-098), phiên bản `REJECTED`.
- **5a. Quay lại phiên bản trước.** `:rollback` (API-09-099) khi bản mới gây sự cố.

**Luồng ngoại lệ.**
- **E1. Mẫu quá 1.000 dòng (bước 1).** ERR-09-039 (413): "Dữ liệu mẫu tối đa 1.000 dòng."
- **E2. Chưa mô phỏng đạt (bước 3).** ERR-09-040 (422): "Cần mô phỏng đạt trên bộ dữ liệu mẫu trước khi gửi duyệt."
- **E3. Tự duyệt (bước 4).** ERR-09-005 (403): "Bạn là người đề nghị hoặc đã quyết định ở bước trước nên không được duyệt bước này."
- **E4. Dữ liệu mẫu giống dữ liệu thật (bước 1).** ERR-09-080 (422): "Dữ liệu mẫu có dấu hiệu là dữ liệu cá nhân thật. Chỉ dùng dữ liệu giả."

**Quy tắc áp dụng.** BR-09-023, BR-09-025; LP-09-01.

**Màn hình, API.** UI-09-10, UI-09-11; API-09-096…101; kịch bản TS-09-17.
:::

### 6.18. UC-09-18 · Trả kế hoạch che trực tuyến, đệm và đóng an toàn

::: dac-ta
**Mục tiêu.** Cho điểm thực thi biết trường nào che kiểu nào, đệm được tối đa 5 phút, và hành xử an toàn khi PH-09 vắng.

**Tác nhân chính.** PH-03, PH-04, PH-06, PH-14, PH-19 (scope `privacy:decide`).

**Tác nhân phụ.** Không.

**Mức ưu tiên.** M · Đợt 2.

**FR hiện thực.** FR-09-027.

**Truy vết.** REQ-09; SEC-31, SEC-32; FR-04-067; FR-06-052.

**Tiền điều kiện.** Có chính sách `ACTIVE` hoặc chính sách mặc định.

**Kích hoạt.** PEP cần che một đối tượng; nhận EVT-09-12 hoặc EVT-09-01 thì làm mới.

**Đảm bảo tối thiểu.** Trường chưa phân loại xử lý như `SENSITIVE` (BR-09-001); không bao giờ trả dữ liệu thô khi không có kế hoạch.

**Đảm bảo thành công.** Trả `{planVersion, ttlSeconds, fields, failMode}` p95 ≤ 50 ms; `304` khi không đổi.

**Luồng chính.**
1. PH-06 gọi `POST /privacy/v1/mask-plans:resolve` (API-09-228) cho vai trò TO, mục đích `TTHC-HO-TICH`, kênh `API`, domain `CITIZEN`.
2. Hệ thống lấy phân loại các trường, áp chính sách `ACTIVE` theo thứ tự ưu tiên.
3. Hệ thống trả danh sách trường với `maskType`, `params`, `neverReveal` và `failMode`.
4. PEP đệm kế hoạch `09.plan.cache-seconds` (300) theo (vai trò, mục đích, kênh, hợp đồng) và xóa khi nhận sự kiện.
5. PEP lấy chỉ mục phân loại có `ETag` (API-09-232) để che nhanh.

**Luồng thay thế.**
- **3a. PH-09 vắng.** Hết đệm thì PEP đọc trả chỉ trường `PUBLIC` kèm `X-Datahub-Masking: fallback`; PEP luồng từ chối (đóng an toàn, BR-09-027).

**Luồng ngoại lệ.**
- **E1. Chưa lập được kế hoạch (bước 2).** ERR-09-105 (503): "Chưa lập được kế hoạch che, đang dùng chế độ đóng an toàn."
- **E2. Bên gọi không được phép (bước 1).** ERR-09-111 (403): "Bên gọi không được phép dùng API quyền riêng tư."

**Quy tắc áp dụng.** BR-09-001, BR-09-022, BR-09-027.

**Màn hình, API.** Không có màn hình; API-09-228, 232; kịch bản TS-09-18.
:::

### 6.19. UC-09-19 · Áp che bản tin cho luồng PH-04

::: dac-ta
**Mục tiêu.** Bản tin ra khỏi luồng đã được che đúng chính sách và không còn trường chưa phân loại.

**Tác nhân chính.** PH-04 `dh-runtime` (scope `privacy:apply`).

**Tác nhân phụ.** OpenBao (chỉ cho `KEYED_HASH`, `TOKENIZE`), PH-13.

**Mức ưu tiên.** M · Đợt 2.

**FR hiện thực.** FR-09-028.

**Truy vết.** REQ-09; LGC-TOOL-012; FR-04-067; SEC-32; BP-02.

**Tiền điều kiện.** Bản tin có `dh-data-classes` ở chặng `schema` và `dh-obligations` ở chặng `authz`.

**Kích hoạt.** Bản tin tới chặng `respond`.

**Đảm bảo tối thiểu.** Không ghi được vết thì từ chối; log không chứa giá trị `SENSITIVE` (BR-09-025).

**Đảm bảo thành công.** Trả bản tin đã xử lý kèm `applied[]`, `warnings[]` (p95 ≤ 30 ms cho 10 KB).

**Luồng chính.**
1. PH-04 gọi `POST /privacy/v1/messages:apply` (API-09-229) kèm kế hoạch và bản tin.
2. Hệ thống kiểm nhãn chặn trước (API-09-231); có nhãn thì từ chối toàn bản tin.
3. Hệ thống áp `PARTIAL`, `REPLACE`, `GENERALIZE`, `DROP` bằng thư viện `dh-privacy-client`; `KEYED_HASH`, `TOKENIZE` gọi miền giả danh (UC-09-23).
4. Trường chưa phân loại bị `DROP`; hệ thống ghi kiểm toán số lượng theo trường, không ghi giá trị.
5. Hệ thống trả bản tin đã xử lý.

**Luồng thay thế.**

**Luồng ngoại lệ.**
- **E1. Nhãn bí mật nhà nước (bước 2).** ERR-09-101 (403): "Dữ liệu bị chặn theo quy định bảo vệ bí mật nhà nước."
- **E2. Bản tin quá lớn (bước 1).** ERR-09-107 (413): "Bản tin hoặc lô vượt giới hạn cho phép."
- **E3. OpenBao lỗi (bước 3).** ERR-09-108 (503): "Không băm có khóa hoặc token hóa được vì OpenBao không khả dụng."
- **E4. Không ghi được vết (bước 4).** ERR-09-110 (503): "Không ghi được nhật ký thao tác che, thao tác bị từ chối."

**Quy tắc áp dụng.** BR-09-005, BR-09-025, BR-09-027.

**Màn hình, API.** Không có màn hình; API-09-229, 231; kịch bản TS-09-19.
:::

### 6.20. UC-09-20 · Xem giá trị đầy đủ có lý do trong 60 giây

::: dac-ta
**Mục tiêu.** Cán bộ có thẩm quyền xem giá trị thật của một trường đã che trong thời gian ngắn, có lý do, để xử lý nghiệp vụ.

**Tác nhân chính.** SO (Dũng), DO (Phúc, ○).

**Tác nhân phụ.** DU chứa dữ liệu (PH-06, PH-19), PH-13.

**Mức ưu tiên.** M · Đợt 2.

**FR hiện thực.** FR-09-029.

**Truy vết.** REQ-09; FR-00-034; SEC-32; FR-06-052.

**Tiền điều kiện.** `PERM-09-unmask` cấp riêng; trường không đánh dấu `neverReveal`; người dùng có quyền ở phạm vi đối tượng.

**Kích hoạt.** Bấm "Xem đầy đủ" ở màn của phân hệ chứa dữ liệu.

**Đảm bảo tối thiểu.** Ghi kiểm toán trước khi cấp phiếu (BR-09-057); giá trị rõ không ghi đĩa.

**Đảm bảo thành công.** Giá trị hiện đúng 60 giây (±1 giây) rồi tự che; phiếu hết hạn không dùng lại.

**Luồng chính.**
1. Dũng bấm "Xem đầy đủ" ở trường `nationalId` của bản ghi `G-10234` trên màn PH-06; UI-09-22 mở, Dũng nhập lý do.
2. Hệ thống kiểm quyền, lý do ≥ 20 ký tự, trường không `neverReveal`, số lần chưa vượt `09.mask.reveal-max-per-hour` (20) (API-09-102).
3. Hệ thống ghi kiểm toán, rồi cấp `RevealGrant` `ISSUED` hết hạn sau `09.mask.reveal-seconds` (60).
4. PH-06 xác thực phiếu (API-09-236), giải mã và trả giá trị cho giao diện; phiếu thành `VERIFIED`.
5. Giao diện đếm ngược theo `expiresAt` và `serverTime` do máy chủ trả (không theo đồng hồ trình duyệt) trong 60 giây rồi tự che; phiếu `EXPIRED`.

**Luồng thay thế.**
- **5a. Tra lịch sử xem.** AU, SO xem danh sách ở UI-09-20 (API-09-103) và chi tiết một phiếu, không kèm giá trị (API-09-241); vượt `09.mask.reveal-alert-per-hour` lần xem trong giờ thì phát EVT-09-15.

**Luồng ngoại lệ.**
- **E1. Chưa được cấp quyền (bước 2).** ERR-09-041 (403): "Bạn chưa được cấp quyền xem giá trị đầy đủ."
- **E2. Thiếu lý do (bước 2).** ERR-09-007 (422): "Nhập lý do tối thiểu 20 ký tự."
- **E3. Trường không cho xem (bước 2).** ERR-09-042 (422): "Trường {tên} không cho phép xem giá trị đầy đủ."
- **E4. Vượt số lần (bước 2).** ERR-09-043 (429): "Đã vượt số lần xem giá trị đầy đủ trong giờ. Thử lại sau."
- **E5. Không ghi được vết (bước 3).** ERR-09-010 (503): "Chưa ghi được nhật ký kiểm toán nên thao tác bị từ chối. Thử lại sau."
- **E6. Phiếu hết hạn khi xác thực (bước 4).** ERR-09-112 (403): "Phiếu xem giá trị đầy đủ không hợp lệ hoặc đã hết hạn."

**Quy tắc áp dụng.** BR-09-026, BR-09-057; LP-09-02.

**Màn hình, API.** UI-09-22, UI-09-20; API-09-102, 103, 241, 236; kịch bản TS-09-20.
:::

```{.mermaid caption="Trình tự xem giá trị đầy đủ có phiếu 60 giây"}
sequenceDiagram
  actor SO as SO Dũng
  participant U as UI-09-22 nhúng
  participant P as privacy-core
  participant A as PH-13 kiểm toán
  participant D as DU PH-06
  SO->>U: Bấm Xem đầy đủ và nhập lý do
  U->>P: POST reveal-grants (API-09-102)
  P->>P: Kiểm quyền, lý do, neverReveal, hạn mức mỗi giờ
  P->>A: Ghi kiểm toán trước khi cấp
  A-->>P: Đã ghi
  P-->>U: Phiếu ISSUED hết hạn sau 60 giây
  U->>D: Đọc giá trị kèm phiếu
  D->>P: Xác thực phiếu (API-09-236)
  P-->>D: Hợp lệ
  D-->>U: Giá trị đã giải mã, không ghi đĩa
  U->>U: Đếm ngược 60 giây rồi tự che
```

Hình cho thấy PH-09 không bao giờ thấy giá trị rõ, chỉ ghi vết và cấp phiếu; PH-13 không ghi được thì không cấp phiếu (ERR-09-010).

### 6.21. UC-09-21 · Cấu hình che log, trace và quét rò rỉ DLCN trong log

::: dac-ta
**Mục tiêu.** Che DLCN ngay ở nguồn ghi log và quét hằng ngày để bắt rò rỉ còn sót.

**Tác nhân chính.** TA, SO, DS (○).

**Tác nhân phụ.** Loki (kho log), PH-08, PH-13.

**Mức ưu tiên.** M · Đợt 2.

**FR hiện thực.** FR-09-030.

**Truy vết.** REQ-09; SEC-32; THR-18; NFR-00-029.

**Tiền điều kiện.** Có `PERM-09-policy`; Loki khả dụng cho quét.

**Kích hoạt.** Mở UI-09-10 tab "Log"; lịch `09.log.scan-cron` (hằng ngày 03:00); bấm "Quét ngay".

**Đảm bảo tối thiểu.** Kết quả quét chỉ ghi dòng, thời điểm, loại DLCN và băm, không ghi giá trị.

**Đảm bảo thành công.** Cấu hình che log có hiệu lực qua kế hoạch kênh `LOG`; kết quả rò rỉ vào hộp việc.

**Luồng chính.**
1. Mai xem cấu hình che log (API-09-104) và thêm trường `soDinhDanh` vào danh sách `[REDACTED]` (API-09-105).
2. Hệ thống kiểm cấu hình hợp lệ, lưu và công bố qua kế hoạch kênh `LOG`.
3. Đến lịch hoặc khi bấm "Quét ngay" (API-09-108), hệ thống quét mẫu log trong Loki bằng các `DetectorType`.
4. Hệ thống ghi kết quả rò rỉ (API-09-106) và hiện thẻ cảnh báo ở UI-09-01.
5. Mai xử lý từng kết quả: sửa nguồn ghi log rồi đánh dấu đã xử lý (API-09-107).

**Luồng thay thế.**
- **3a. Quét thấy giá trị rõ.** Tạo cảnh báo; nếu giá trị `SENSITIVE` thì SO cân nhắc vụ việc (UC-09-33).

**Luồng ngoại lệ.**
- **E1. Cấu hình sai (bước 2).** ERR-09-044 (422): "Cấu hình che log không hợp lệ: {lý do}."
- **E2. Loki không khả dụng (bước 3).** ERR-09-009 (503): "Chưa kết nối được {tên dịch vụ}. Thử lại sau ít phút."

**Quy tắc áp dụng.** BR-09-025, BR-09-058.

**Màn hình, API.** UI-09-10, UI-09-01; API-09-104…108; kịch bản TS-09-21.
:::

### 6.22. UC-09-22 · Quản lý miền giả danh hóa và vòng đời khóa

::: dac-ta
**Mục tiêu.** Tạo và vận hành miền giả danh cùng khóa trên OpenBao: tạo, xoay, ngừng, hủy.

**Tác nhân chính.** TA, SO (soạn); DA, TA, SO (duyệt xoay, hủy khóa).

**Tác nhân phụ.** OpenBao transit, PH-13, PH-18.

**Mức ưu tiên.** M · Đợt 2.

**FR hiện thực.** FR-09-031, FR-09-034.

**Truy vết.** REQ-09; SEC-34, SEC-38; ADR 091, ADR-012.

**Tiền điều kiện.** `PERM-09-policy` để tạo miền; `PERM-09-policy-approve` để xoay, ngừng, hủy; OpenBao khả dụng.

**Kích hoạt.** Mở UI-09-12; đến chu kỳ `09.pseudo.key-rotate-days` (365).

**Đảm bảo tối thiểu.** Xoay khóa giữ phiên bản cũ ở chế độ chỉ giải (`DECRYPT_ONLY`); không hủy khóa còn dữ liệu cần giải.

**Đảm bảo thành công.** Miền `ACTIVE` có khóa `ACTIVE`; thay đổi khóa phát EVT-09-16.

**Luồng chính.**
1. Mai tạo miền `GD-THONG-KE` cho mục đích `THONG-KE`, phương pháp `HMAC_SHA256` (API-09-110); hệ thống tạo khóa đầu tiên ở OpenBao.
2. Hệ thống kiểm chưa có miền cho mục đích này, lưu miền `ACTIVE`, phát EVT-09-16.
3. Đến chu kỳ xoay, Mai đề nghị xoay khóa; hệ thống cảnh báo xoay phá tính nhất quán bí danh và xin xác nhận (API-09-116).
4. Quân duyệt; hệ thống tạo phiên bản khóa mới `ACTIVE`, phiên bản cũ `DECRYPT_ONLY`.
5. Hết nhu cầu giải bằng khóa cũ, hai người duyệt hủy; hệ thống chờ `09.pseudo.destroy-delay-days` rồi hủy (API-09-117, API-09-118).

**Luồng thay thế.**
- **1a. Tạm dừng, ngừng miền.** `:suspend` (API-09-113), `:retire` cần duyệt (API-09-114); sửa mô tả, chu kỳ xoay (API-09-112).

**Luồng ngoại lệ.**
- **E1. Miền trùng (bước 2).** ERR-09-045 (409): "Đã có miền giả danh cho mục đích này."
- **E2. OpenBao lỗi (bước 1).** ERR-09-009 (503): "Chưa kết nối được {tên dịch vụ}. Thử lại sau ít phút."
- **E3. Xoay quá sớm (bước 3).** ERR-09-047 (409): "Vừa xoay khóa gần đây. Chờ tối thiểu {n} ngày."
- **E4. Hủy khóa còn dùng (bước 5).** ERR-09-046 (409): "Khóa còn được sử dụng, chưa hủy được."
- **E5. Tự duyệt (bước 4, 5).** ERR-09-005 (403): "Bạn là người đề nghị hoặc đã quyết định ở bước trước nên không được duyệt bước này."

**Quy tắc áp dụng.** BR-09-028, BR-09-029, BR-09-031, BR-09-033; LP-09-01.

**Màn hình, API.** UI-09-12; API-09-109…118; kịch bản TS-09-22.
:::

### 6.23. UC-09-23 · Giả danh hóa giá trị bằng HMAC hoặc token

::: dac-ta
**Mục tiêu.** Thay giá trị định danh bằng bí danh nhất quán trong cùng miền và cùng phiên bản khóa, để nối dữ liệu mà không lộ giá trị.

**Tác nhân chính.** PH-04 (bước giả danh của luồng), PH-17 và job chuẩn bị dữ liệu (UC-09-26).

**Tác nhân phụ.** OpenBao.

**Mức ưu tiên.** M · Đợt 2.

**FR hiện thực.** FR-09-032.

**Truy vết.** REQ-09; SEC-31, SEC-38; ADR 091.

**Tiền điều kiện.** Miền `ACTIVE` (UC-09-22).

**Kích hoạt.** Bước giả danh của luồng hoặc job chuẩn bị dữ liệu.

**Đảm bảo tối thiểu.** Lỗi thì không trả dữ liệu thô; giá trị rỗng giữ rỗng.

**Đảm bảo thành công.** Trả `PSN-{keyVersion}-{chuỗi}`, cùng đầu vào cho cùng bí danh (BR-09-029); HMAC ≥ 2.000 giá trị mỗi giây.

**Luồng chính.**
1. PH-04 gọi `POST /privacy/v1/pseudonyms:issue` (API-09-230) với miền `GD-THONG-KE`, `identifierKind = NATIONAL_ID` và lô 500 giá trị.
2. Hệ thống kiểm miền `ACTIVE` và kích thước lô.
3. Hệ thống chuẩn hóa giá trị (bỏ khoảng trắng, NFC, chỉ chữ số).
4. Hệ thống tính HMAC-SHA256 bằng khóa dẫn xuất giải bọc đệm ≤ 5 phút, hoặc token hóa qua transit.
5. Hệ thống trả danh sách bí danh và ghi kiểm toán số lượng.

**Luồng thay thế.**
- **4a. Chưa có đệm khóa.** Hệ thống gọi OpenBao giải bọc rồi đệm.

**Luồng ngoại lệ.**
- **E1. Miền không hoạt động (bước 2).** ERR-09-109 (422): "Miền giả danh không hoạt động cho mục đích này."
- **E2. Lô quá lớn (bước 2).** ERR-09-107 (413): "Bản tin hoặc lô vượt giới hạn cho phép."
- **E3. OpenBao lỗi (bước 4).** ERR-09-108 (503): "Không băm có khóa hoặc token hóa được vì OpenBao không khả dụng."
- **E4. Không ghi được vết (bước 5).** ERR-09-110 (503): "Không ghi được nhật ký thao tác che, thao tác bị từ chối."

**Quy tắc áp dụng.** BR-09-028, BR-09-029, BR-09-030.

**Màn hình, API.** Không có màn hình; API-09-230; kịch bản TS-09-23.
:::

### 6.24. UC-09-24 · Khôi phục giá trị gốc từ token

::: dac-ta
**Mục tiêu.** Trong trường hợp có căn cứ, giải token về giá trị gốc cho một số ít bản ghi.

**Tác nhân chính.** SO (Dũng) đề nghị và thực hiện; DO (Phúc), TA (Mai) hoặc DA duyệt.

**Tác nhân phụ.** OpenBao, PH-13.

**Mức ưu tiên.** S · Đợt 2.

**FR hiện thực.** FR-09-033.

**Truy vết.** REQ-09; SEC-34; ADR 091.

**Tiền điều kiện.** `PERM-09-reidentify` (SO); miền `TOKEN_TRANSIT`; khóa còn phiên bản giải được.

**Kích hoạt.** Bấm "Đề nghị khôi phục" ở UI-09-13.

**Đảm bảo tối thiểu.** Không ghi được vết thì không giải (ERR-09-010); tối đa 100 giá trị mỗi đề nghị.

**Đảm bảo thành công.** Đề nghị `EXECUTED`, kết quả hiện 60 giây rồi hủy, phát EVT-09-17.

**Luồng chính.**
1. Dũng lập đề nghị khôi phục 3 token của miền `GD-TOKEN-HOTICH` kèm mục đích và căn cứ (API-09-119).
2. Hệ thống kiểm miền đảo ngược được và số lượng, đặt `PENDING_L1`.
3. Phúc duyệt cấp một, rồi Mai duyệt cấp hai (API-09-122) trong `09.reid.approval-ttl-hours` (24); ba người khác nhau.
4. Dũng xác thực lại bước cao (MFA) và thực hiện trong `09.reid.exec-window-minutes` (30) (API-09-124); hệ thống ghi kiểm toán rồi giải mã theo lô qua transit.
5. Kết quả hiện 60 giây; hệ thống thông báo SO và TA, phát EVT-09-17.

**Luồng thay thế.**
- **3a. Từ chối.** Người duyệt từ chối kèm lý do (API-09-123), đề nghị `REJECTED`.

**Luồng ngoại lệ.**
- **E1. Miền HMAC (bước 2).** ERR-09-048 (422): "Miền {mã} dùng HMAC không đảo ngược, không khôi phục được giá trị gốc."
- **E2. Quá số giá trị (bước 2).** ERR-09-049 (422): "Mỗi đề nghị khôi phục tối đa {n} giá trị."
- **E3. Trùng người (bước 3).** ERR-09-005 (403): "Bạn là người đề nghị hoặc đã quyết định ở bước trước nên không được duyệt bước này."
- **E4. Hết hiệu lực (bước 4).** ERR-09-050 (409): "Đề nghị khôi phục đã hết hiệu lực. Lập đề nghị mới."
- **E5. Không ghi được vết (bước 4).** ERR-09-010 (503): "Chưa ghi được nhật ký kiểm toán nên thao tác bị từ chối. Thử lại sau."

**Quy tắc áp dụng.** BR-09-032, BR-09-057; LP-09-01.

**Màn hình, API.** UI-09-13, UI-09-12; API-09-119…124; kịch bản TS-09-24.
:::

### 6.25. UC-09-25 · Cấu hình, chạy ẩn danh hóa và đánh giá rủi ro tái định danh

::: dac-ta
**Mục tiêu.** Tạo tập dữ liệu thống kê đạt k ≥ 10 và rủi ro tái định danh không cao, đủ điều kiện coi là không còn là DLCN.

**Tác nhân chính.** TA, SO, DS (○) cấu hình và chạy; DA duyệt cấu hình; SO duyệt rủi ro mức `MEDIUM`.

**Tác nhân phụ.** Job ARX, Garage (lưu tập), PH-13.

**Mức ưu tiên.** S · Đợt 2.

**FR hiện thực.** FR-09-035, FR-09-036, FR-09-037.

**Truy vết.** REQ-09; SEC-38; ADR 092.

**Tiền điều kiện.** `PERM-09-anonymize`; nguồn là bảng hoặc tệp được chủ quản cho phép và đã phân loại đủ.

**Kích hoạt.** Bấm "Chạy" ở UI-09-14.

**Đảm bảo tối thiểu.** Không đạt k hoặc rủi ro `HIGH` thì không phát hành; job hủy được.

**Đảm bảo thành công.** Job `COMPLETED`, tập `READY` kèm báo cáo rủi ro.

**Luồng chính.**
1. Lan tạo cấu hình: loại bỏ `soDinhDanh`, tổng quát hóa `ngaySinh` thành năm, `noiSinh` lên cấp huyện, `k = 10` (API-09-126).
2. Quân duyệt cấu hình bốn mắt (API-09-129); cấu hình `ACTIVE`.
3. Lan chạy job (API-09-130); hệ thống tạo job `QUEUED` rồi Job ARX loại trường `DIRECT`, tổng quát hóa, chặn nhóm nhỏ hơn k, tối đa ba vòng.
4. Hệ thống kiểm còn ≥ 30% bản ghi, lưu tập ra Garage mã hóa SSE-C, rồi tính rủi ro theo ba mô hình (`PROSECUTOR`, `JOURNALIST`, `MARKETER`) (API-09-134).
5. Rủi ro `LOW`: tập `READY`; `MEDIUM`: job `AWAITING_RISK_REVIEW`, Dũng duyệt (API-09-135).

**Luồng thay thế.**
- **3a. Hủy job.** API-09-133; chạy lại với cấu hình khác.

**Luồng ngoại lệ.**
- **E1. k thấp hơn tối thiểu (bước 1).** ERR-09-051 (422): "Ngưỡng k phải từ {n} trở lên."
- **E2. Còn trường định danh trực tiếp (bước 1, 3).** ERR-09-052 (422): "Còn trường định danh trực tiếp {tên} chưa được loại bỏ hoặc xử lý."
- **E3. Còn quá ít bản ghi (bước 4).** ERR-09-054 (422): "Sau xử lý chỉ còn {x}% bản ghi, dữ liệu không còn giá trị thống kê."
- **E4. Rủi ro cao (bước 5).** ERR-09-053 (422): "Rủi ro tái định danh cao, không phát hành. Xem khuyến nghị của báo cáo."
- **E5. Duyệt rủi ro sai người (bước 5).** ERR-09-005 (403): "Bạn là người đề nghị hoặc đã quyết định ở bước trước nên không được duyệt bước này."

**Quy tắc áp dụng.** BR-09-034, BR-09-035, BR-09-036.

**Màn hình, API.** UI-09-14; API-09-125…136; kịch bản TS-09-25.
:::

```{.mermaid caption="Trình tự ẩn danh hóa tập dữ liệu và duyệt rủi ro"}
sequenceDiagram
  actor DS as DS Lan
  actor SO as SO Dũng
  participant P as privacy-core
  participant J as Job ARX
  participant G as Garage SSE-C
  DS->>P: Chạy ẩn danh hóa với cấu hình ACTIVE (API-09-130)
  P->>J: Tạo Job Kubernetes, job QUEUED
  J->>J: Loại DIRECT, tổng quát hóa, chặn nhóm nhỏ hơn k
  J->>G: Lưu tập đã ẩn danh
  J-->>P: Báo cáo k thực tế và rủi ro
  alt Rủi ro HIGH
    P-->>DS: ERR-09-053 không phát hành
  else Rủi ro MEDIUM
    P-->>SO: Việc duyệt rủi ro
    SO->>P: Duyệt (API-09-135)
    P-->>DS: Tập READY
  else Rủi ro LOW
    P-->>DS: Tập READY
  end
```

Hình cho thấy ba lối ra theo rủi ro: `MEDIUM` buộc SO quyết định, `HIGH` bị chặn hẳn; tập lưu ở kho mã hóa riêng, không đi qua PH-09.

### 6.26. UC-09-26 · Chuẩn bị dữ liệu cho AI, môi trường không phải PROD và quản lý tập đã ẩn danh

::: dac-ta
**Mục tiêu.** Cấp dữ liệu an toàn cho PH-17, kiểm thử ngoài PROD và dữ liệu mở, và quản lý vòng đời tập đã ẩn danh.

**Tác nhân chính.** TA, SO, DS (○).

**Tác nhân phụ.** PH-17 (dữ liệu AI), Job ARX, OpenBao.

**Mức ưu tiên.** M · Đợt 2 (FR-09-039 mức C, Đợt 3).

**FR hiện thực.** FR-09-038, FR-09-039.

**Truy vết.** REQ-09; SEC-38, SEC-49; D03-07 §3.2; Luật Dữ liệu 60/2024.

**Tiền điều kiện.** `PERM-09-anonymize`; mục tiêu `DataPrepTarget` cho phép.

**Kích hoạt.** Bấm "Chuẩn bị dữ liệu" ở UI-09-14; PH-17 gọi API-09-137.

**Đảm bảo tối thiểu.** Mục tiêu không cho phép thì không tạo gì; tập `PUBLISHED` không sửa.

**Đảm bảo thành công.** Tập `READY`, rồi `PUBLISHED` kèm điều kiện dùng; phát EVT-09-18.

**Luồng chính.**
1. Lan tạo yêu cầu chuẩn bị `AI_TRAINING` từ bảng hộ tịch (API-09-137).
2. Hệ thống kiểm mục tiêu, trường `SENSITIVE` thật bị chặn, nguồn đã phân loại; chọn đường ẩn danh (UC-09-25) hoặc giả danh không đảo ngược (UC-09-23).
3. Hệ thống đánh giá rủi ro; `HIGH` bị chặn.
4. Tập `READY` được Lan phát hành (API-09-142) kèm điều kiện dùng và hạn dùng (API-09-144); hệ thống phát EVT-09-18 cho PH-17.
5. Lan theo dõi trạng thái (API-09-138, API-09-140).

**Luồng thay thế.**
- **5a. Rút lại tập.** `:withdraw` (API-09-143); muốn sửa phải tạo tập mới.

**Luồng ngoại lệ.**
- **E1. Mục tiêu không cho dùng dữ liệu Nhạy cảm (bước 2).** ERR-09-055 (422): "Mục đích {mã} không cho phép dùng dữ liệu có trường Nhạy cảm."
- **E2. Rủi ro cao (bước 3).** ERR-09-053 (422): "Rủi ro tái định danh cao, không phát hành. Xem khuyến nghị của báo cáo."
- **E3. Sửa tập đã phát hành (bước 4).** ERR-09-056 (409): "Tập dữ liệu đã phát hành, không sửa được. Rút lại để tạo tập mới."
- **E4. Dữ liệu Hạn chế cho AI khi cờ tắt (bước 2).** ERR-09-082 (422): "Dữ liệu Hạn chế chưa được phép dùng cho AI. Đề nghị TA bật tham số 09.ai.allow-restricted."

**Quy tắc áp dụng.** BR-09-034, BR-09-035, BR-09-037.

**Màn hình, API.** UI-09-14; API-09-137…144; kịch bản TS-09-26.
:::

### 6.27. UC-09-27 · Lập lịch lưu giữ, chạy tác vụ xóa hoặc giả danh hóa khi hết hạn và báo cáo

::: dac-ta
**Mục tiêu.** Dữ liệu hết hạn lưu được xóa, giả danh hóa, ẩn danh hóa hoặc lưu trữ đúng lịch và có báo cáo tuân thủ.

**Tác nhân chính.** TA, SO, DS (○) soạn; DA, TA, SO duyệt; job lưu giữ.

**Tác nhân phụ.** Phân hệ sở hữu bảng (PH-06, PH-19), AU.

**Mức ưu tiên.** M · Đợt 2.

**FR hiện thực.** FR-09-040, FR-09-041, FR-09-044.

**Truy vết.** REQ-09; CMP-LAW-05; SEC-39; Q09-09.

**Tiền điều kiện.** `PERM-09-retention`; người duyệt khác người soạn.

**Kích hoạt.** Mở UI-09-15; job chạy theo `09.retention.run-cron` (01:00 hằng ngày).

**Đảm bảo tối thiểu.** Đối tượng đang giữ pháp lý không bị xóa; tác vụ không chạy chồng.

**Đảm bảo thành công.** 100% bản ghi hết hạn xử lý trong 24 giờ sau lịch (NFR-09-018), phát EVT-09-19.

**Luồng chính.**
1. Dũng lập lịch cho bảng `ph06_mdm.citizen_xref`: hạn 60 tháng, hành động `PSEUDONYMIZE` (API-09-146).
2. Hệ thống kiểm mọi bảng chứa DLCN đã có quy tắc; Dũng gửi duyệt (API-09-149), Quân duyệt (API-09-150).
3. Job chạy hằng ngày, xác định bản ghi hết hạn, bỏ đối tượng đang giữ pháp lý, tạo tác vụ `QUEUED` (API-09-154).
4. Phân hệ sở hữu thực hiện hành động; hệ thống chuyển tác vụ `COMPLETED`, phát EVT-09-19.
5. Dũng xem báo cáo tuân thủ thời hạn lưu (API-09-163).

**Luồng thay thế.**
- **3a. Chạy thử.** `dry-run` chỉ đếm bản ghi (API-09-154).

**Luồng ngoại lệ.**
- **E1. Bảng DLCN chưa có thời hạn (bước 2).** ERR-09-057 (422): "Bảng {tên} chứa dữ liệu cá nhân nhưng chưa có thời hạn lưu."
- **E2. Tác vụ đang chạy (bước 3).** ERR-09-061 (409): "Tác vụ xóa đang chạy, không chạy chồng."
- **E3. Phân hệ sở hữu lỗi (bước 4).** ERR-09-009 (503): "Chưa kết nối được {tên dịch vụ}. Thử lại sau ít phút."
- **E4. Tự duyệt (bước 2).** ERR-09-005 (403): "Bạn là người đề nghị hoặc đã quyết định ở bước trước nên không được duyệt bước này."

**Quy tắc áp dụng.** BR-09-038, BR-09-039, BR-09-040.

**Màn hình, API.** UI-09-15; API-09-145…155, 163; kịch bản TS-09-27.
:::

### 6.28. UC-09-28 · Giữ pháp lý và xóa mật mã khi chấm dứt tenant

::: dac-ta
**Mục tiêu.** Tạm hoãn xóa khi có yêu cầu của cơ quan có thẩm quyền; khi tenant chấm dứt thì hủy khóa sau bàn giao dữ liệu.

**Tác nhân chính.** TA, SO, DS (○) đặt giữ; DA, TA, SO duyệt xóa mật mã (hai người).

**Tác nhân phụ.** PH-20 (chấm dứt tenant), PH-06, PH-19, OpenBao.

**Mức ưu tiên.** M · Đợt 2.

**FR hiện thực.** FR-09-042, FR-09-043.

**Truy vết.** REQ-09; CMP-LAW-05; SEC-34, SEC-39; BP-08.

**Tiền điều kiện.** `PERM-09-retention`; xóa mật mã chỉ sau khi PH-20 xác nhận đã bàn giao.

**Kích hoạt.** Bấm "Đặt giữ pháp lý" hoặc "Đề nghị xóa mật mã" ở UI-09-15.

**Đảm bảo tối thiểu.** Có giữ pháp lý thì không xóa; sau duyệt còn thời gian chờ `09.shred.delay-days` (30) để hủy.

**Đảm bảo thành công.** Giữ có hiệu lực và phát EVT-09-20; xóa mật mã `EXECUTED` và phát EVT-09-21.

**Luồng chính.**
1. Dũng đặt giữ pháp lý cho bản ghi liên quan vụ việc, nhập số văn bản và cơ quan yêu cầu (API-09-157).
2. Hệ thống lưu giữ `ACTIVE`, các tác vụ xóa đối tượng này bị bỏ qua, phát EVT-09-20.
3. Khi tenant chấm dứt, PH-20 báo bàn giao xong; Dũng đề nghị xóa mật mã (API-09-159).
4. Hệ thống kiểm điều kiện: đã bàn giao, không còn giữ pháp lý; Quân duyệt, rồi Mai duyệt người thứ hai (API-09-161).
5. Hết thời gian chờ, hệ thống hủy KEK qua OpenBao, trạng thái `EXECUTED`, phát EVT-09-21 cho PH-20.

**Luồng thay thế.**
- **1a. Gỡ giữ.** `:release` (API-09-158) khi hết căn cứ; tác vụ xóa tiếp tục.
- **5a. Hủy trước khi thực hiện.** API-09-162 trong thời gian chờ; theo dõi ở API-09-160.

**Luồng ngoại lệ.**
- **E1. Thiếu căn cứ giữ (bước 1).** ERR-09-059 (422): "Giữ pháp lý cần số văn bản và cơ quan yêu cầu."
- **E2. Gỡ giữ đã gỡ (1a).** ERR-09-006 (409): "Đối tượng đang ở trạng thái {trạng thái}, không thực hiện được thao tác này."
- **E3. Chưa đủ điều kiện xóa mật mã (bước 4).** ERR-09-060 (422): "Chưa đủ điều kiện xóa mật mã tenant: {lý do}."
- **E4. Còn giữ pháp lý (bước 4).** ERR-09-058 (409): "Dữ liệu đang bị giữ pháp lý, không xóa được cho đến khi gỡ giữ."
- **E5. Tự duyệt (bước 4).** ERR-09-005 (403): "Bạn là người đề nghị hoặc đã quyết định ở bước trước nên không được duyệt bước này."

**Quy tắc áp dụng.** BR-09-033, BR-09-039, BR-09-041; LP-09-01.

**Màn hình, API.** UI-09-15; API-09-156…162; kịch bản TS-09-28.
:::

### 6.29. UC-09-29 · Tiếp nhận, xác minh, tra cứu và chuyển xử lý yêu cầu của chủ thể dữ liệu

::: dac-ta
**Mục tiêu.** Thực hiện quyền biết, truy cập, sửa, xóa, hạn chế, phản đối, rút đồng ý theo Luật BVDLCN, tìm đúng nơi giữ dữ liệu của chủ thể và giao việc.

**Tác nhân chính.** SO (Dũng), DS (Lan), TA; cổng dịch vụ công (scope `privacy:register`).

**Tác nhân phụ.** Chủ thể dữ liệu, PH-06, PH-19, PH-13, PH-14, bên kiểm soát khác, PH-11.

**Mức ưu tiên.** M · Đợt 2.

**FR hiện thực.** FR-09-045, FR-09-046, FR-09-047, FR-09-048.

**Truy vết.** REQ-09; CMP-LAW-04, CMP-LAW-05; SEC-37; ADR 091; LGC-NGSP-003; Q09-10.

**Tiền điều kiện.** `PERM-09-dsr`; PH-06, PH-19 đã đăng ký là nguồn tra cứu.

**Kích hoạt.** Bấm "Tiếp nhận" ở UI-09-16 hoặc cổng gọi API-09-165.

**Đảm bảo tối thiểu.** Chưa xác minh danh tính thì chỉ tiếp nhận, không tra cứu, không trả nội dung (BR-09-042); định danh rõ chỉ nằm trong phiếu, mã hóa envelope.

**Đảm bảo thành công.** Yêu cầu `IN_PROGRESS` kèm kết quả tra cứu và tác vụ đã giao.

**Luồng chính.**
1. Công dân Nguyễn Văn A gửi yêu cầu `ACCESS` qua cổng (API-09-165) kèm CCCD; hoặc Dũng tiếp nhận tại quầy ở UI-09-16.
2. Hệ thống kiểm đầu vào và chặn trùng, tính băm HMAC của CCCD, lưu định danh mã hóa, tạo `RECEIVED`, tính hạn 10 ngày làm việc, phát EVT-09-22 và gửi biên nhận.
3. Dũng xác minh danh tính bằng `VNEID` hoặc `ID_DOCUMENT` (API-09-167); yêu cầu sang `IN_PROGRESS`.
4. Dũng tra cứu (API-09-168): hệ thống hỏi PH-06, PH-19, nhật ký PH-13 và PH-14 theo băm, trả kết quả không chứa giá trị rõ (API-09-169).
5. Dũng tạo tác vụ chuyển PH-06 và PH-19 (API-09-170); các phân hệ báo hoàn tất (API-09-172).

**Luồng thay thế.**
- **1a. Người đại diện.** Ghi kèm giấy tờ đại diện (Q09-18); không chứng minh được thì ERR-09-065.
- **5a. Hạn chế xử lý.** `RESTRICT`: phát EVT-09-26, PH-06 khóa; gỡ bằng `:lift-restriction` kèm căn cứ (API-09-178).
- **5b. Xóa.** Có căn cứ pháp lý phải giữ thì từ chối có căn cứ; nguồn thẩm quyền quốc gia thì hướng dẫn tới cơ quan đăng ký (BR-09-046).
- **5c. Dữ liệu đi qua.** Chuyển bên kiểm soát (`CONTROLLER`), PH-09 chỉ cung cấp siêu dữ liệu.
- **5d. Rút yêu cầu.** Chủ thể hoặc người đại diện rút yêu cầu trước khi `RESPONDED`: SO, DS hoặc TA gọi API-09-244 kèm lý do, yêu cầu sang `WITHDRAWN`, tác vụ đang mở bị hủy (FR-09-045).

**Luồng ngoại lệ.**
- **E1. Thiếu loại hoặc định danh (bước 2).** ERR-09-062 (422): "Yêu cầu thiếu loại yêu cầu hoặc thông tin định danh chủ thể."
- **E2. Trùng yêu cầu (bước 2).** ERR-09-064 (409): "Chủ thể đã có yêu cầu cùng loại đang xử lý."
- **E3. Chưa xác minh mà tra cứu (bước 4).** ERR-09-063 (422): "Chưa xác minh danh tính chủ thể. Hoàn tất xác minh trước khi xử lý."
- **E4. Không phải chủ thể (bước 3).** ERR-09-065 (403): "Người gửi chưa chứng minh là chủ thể hoặc người đại diện hợp pháp."
- **E5. Chưa chuyển được tác vụ (bước 5).** ERR-09-066 (502): "Chưa chuyển được yêu cầu tới {đích}. Hệ thống sẽ thử lại."

**Quy tắc áp dụng.** BR-09-042, BR-09-043, BR-09-044, BR-09-045, BR-09-046, BR-09-047, BR-09-061.

**Màn hình, API.** UI-09-16; API-09-164…173, 178, 235, 244; kịch bản TS-09-29.
:::

```{.mermaid caption="Trình tự xử lý yêu cầu truy cập dữ liệu của chủ thể"}
sequenceDiagram
  actor CT as Chủ thể
  participant C as Cổng dịch vụ công
  participant P as privacy-core
  actor SO as SO Dũng
  participant M as PH-06
  participant Y as PH-19
  CT->>C: Gửi yêu cầu ACCESS kèm CCCD
  C->>P: POST subject-requests (API-09-165)
  P->>P: Tính băm HMAC, lưu định danh mã hóa, RECEIVED, hạn 10 ngày
  P-->>C: Biên nhận và EVT-09-22
  SO->>P: Ghi kết quả xác minh VNEID (API-09-167)
  SO->>P: Tra cứu theo băm (API-09-168)
  P->>M: Tìm theo băm chủ thể
  P->>Y: Tìm theo băm chủ thể
  M-->>P: Kết quả không chứa giá trị rõ
  Y-->>P: Kết quả không chứa giá trị rõ
  SO->>P: Tạo tác vụ chuyển và theo dõi hạn
  P-->>SO: Tác vụ hoàn tất, sẵn sàng trả lời (UC-09-30)
```

Hình cho thấy định danh rõ chỉ đi từ cổng tới PH-09 một lần để tính băm, các phân hệ khác chỉ nhận băm, và chỉ tra cứu sau khi xác minh.

### 6.30. UC-09-30 · Theo dõi hạn, trả lời, đóng yêu cầu và báo cáo ai đã truy cập dữ liệu của chủ thể

::: dac-ta
**Mục tiêu.** Trả lời đúng hạn, lưu bằng chứng 5 năm, và cung cấp báo cáo "ai đã truy cập dữ liệu của tôi".

**Tác nhân chính.** SO (Dũng), DS (Lan), TA.

**Tác nhân phụ.** Chủ thể dữ liệu, PH-13 (nhật ký truy cập), PH-11 hoặc đồng hồ nội bộ.

**Mức ưu tiên.** M · Đợt 2.

**FR hiện thực.** FR-09-049, FR-09-050, FR-09-051.

**Truy vết.** REQ-09; CMP-LAW-04; SEC-37; PH-13.

**Tiền điều kiện.** Yêu cầu `IN_PROGRESS`; `PERM-09-dsr`.

**Kích hoạt.** Cảnh báo EVT-09-23 (còn 3 ngày làm việc); bấm "Trả lời" ở UI-09-16.

**Đảm bảo tối thiểu.** Yêu cầu, bằng chứng và câu trả lời lưu 5 năm (BR-09-048); quá hạn chỉ cảnh báo, không tự đóng.

**Đảm bảo thành công.** Yêu cầu `CLOSED` kèm `DsrOutcome` và bằng chứng, phát EVT-09-25.

**Luồng chính.**
1. Hệ thống nhắc Dũng trước 3 ngày làm việc (EVT-09-23); quá hạn gắn cờ `overdue` và phát EVT-09-24.
2. Dũng xem yêu cầu sắp đến hạn (API-09-174) và lập báo cáo ai đã truy cập dữ liệu của chủ thể 12 tháng (API-09-179, API-09-180).
3. Dũng soạn câu trả lời kèm kết quả và bằng chứng (API-09-175).
4. Hệ thống kiểm mọi tác vụ đã `DONE` hoặc `REFUSED`, rồi Dũng đóng (API-09-176) với `FULFILLED`.
5. Hệ thống gửi câu trả lời qua kênh đã chọn, lưu bằng chứng, phát EVT-09-25.

**Luồng thay thế.**
- **3a. Từ chối có căn cứ.** `:reject` (API-09-177), `DsrOutcome = REFUSED`.
- **1a. Gia hạn.** SO gia hạn hạn trả lời một lần, kèm lý do và thông báo chủ thể, hạn mới không quá ngày pháp luật cho phép (API-09-242).
- **2a. Báo cáo tổng hợp.** TA, AU xem tuân thủ hạn theo quý (API-09-181).

**Luồng ngoại lệ.**
- **E1. Gia hạn thiếu lý do (1a).** ERR-09-007 (422): "Nhập lý do tối thiểu 20 ký tự."
- **E2. Thiếu kết quả hoặc bằng chứng (bước 3).** ERR-09-068 (422): "Câu trả lời thiếu kết quả hoặc bằng chứng đính kèm."
- **E3. Còn tác vụ mở (bước 4).** ERR-09-067 (422): "Còn {n} tác vụ chưa hoàn tất, chưa đóng được yêu cầu."
- **E4. Nhật ký không khả dụng (bước 2).** ERR-09-009 (503): "Chưa kết nối được {tên dịch vụ}. Thử lại sau ít phút."

**Quy tắc áp dụng.** BR-09-043, BR-09-044, BR-09-048.

**Màn hình, API.** UI-09-16, UI-09-01; API-09-174…177, 179, 180, 181, 242; kịch bản TS-09-30.
:::

### 6.31. UC-09-31 · Quản lý mẫu và bản ghi sự đồng ý, tra cứu trạng thái

::: dac-ta
**Mục tiêu.** Ghi nhận và rút sự đồng ý có bằng chứng, để HTTT có tiện ích không bắt buộc (ví dụ nhắc lịch tiêm chủng) biết còn được xử lý hay không.

**Tác nhân chính.** SO, TA, DS (○); HTTT (scope `privacy:consent`).

**Tác nhân phụ.** DA (duyệt mẫu), chủ thể dữ liệu, PH-13.

**Mức ưu tiên.** S · Đợt 2 (FR-09-054 mức C, Đợt 3).

**FR hiện thực.** FR-09-052, FR-09-053, FR-09-054.

**Truy vết.** REQ-09; CMP-LAW-05; SEC-37.

**Tiền điều kiện.** `PERM-09-consent`; mẫu `ACTIVE` khi ghi nhận.

**Kích hoạt.** Mở UI-09-17; HTTT gọi API-09-188 khi công dân đồng ý.

**Đảm bảo tối thiểu.** Mẫu đã có người đồng ý không sửa, chỉ tạo phiên bản mới.

**Đảm bảo thành công.** Bản ghi `GIVEN` có bằng chứng; rút đồng ý có hiệu lực tại tra cứu trong 60 giây (BR-09-051).

**Luồng chính.**
1. Dũng soạn mẫu `DY-NHAC-TIEM` nêu mục đích cụ thể, dữ liệu xử lý, cách rút lại (API-09-183, API-09-184) và gửi duyệt (API-09-185).
2. Quân duyệt, mẫu `ACTIVE` (API-09-186).
3. `HT-YTE` ghi nhận đồng ý của công dân qua API-09-188 kèm băm chủ thể, phiên bản mẫu, kênh `APP`, thời điểm, băm nội dung đã hiển thị.
4. Hệ thống kiểm đủ bằng chứng, lưu `GIVEN`, phát EVT-09-27.
5. `HT-YTE` tra trạng thái trước khi gửi nhắc (API-09-234); kết quả đệm tối đa 60 giây (`09.consent.cache-seconds`).

**Luồng thay thế.**
- **3a. Rút đồng ý.** API-09-189; bản ghi `WITHDRAWN`, phát EVT-09-28.
- **5a. Tra theo định danh rõ.** Bên có quyền nhập số điện thoại hoặc thư điện tử của công dân; PH-09 tính băm rồi trả danh sách đồng ý theo băm, không ghi định danh vào nhật ký (API-09-245). Xem một mẫu và các phiên bản của nó ở API-09-238.

**Luồng ngoại lệ.**
- **E1. Mẫu thiếu nội dung (bước 1).** ERR-09-069 (422): "Mẫu đồng ý cần nêu mục đích cụ thể, dữ liệu xử lý và cách rút lại."
- **E2. Sửa mẫu đã có người đồng ý (bước 1).** ERR-09-070 (409): "Mẫu đã có người đồng ý. Tạo phiên bản mới thay vì sửa."
- **E3. Thiếu bằng chứng (bước 3).** ERR-09-071 (422): "Thiếu bằng chứng đồng ý: kênh, thời điểm, phiên bản mẫu."
- **E4. Đồng ý đã rút (3a).** ERR-09-072 (409): "Sự đồng ý đã được rút hoặc hết hiệu lực."
- **E5. Vượt hạn mức gọi tra (bước 5).** ERR-09-113 (429): "Vượt hạn mức gọi API quyền riêng tư."

**Quy tắc áp dụng.** BR-09-049, BR-09-050, BR-09-051.

**Màn hình, API.** UI-09-17; API-09-182…191, 234, 238, 245; kịch bản TS-09-31.
:::

### 6.32. UC-09-32 · Lập, duyệt, nhắc rà soát và xuất hồ sơ đánh giá tác động (DPIA)

::: dac-ta
**Mục tiêu.** Có hồ sơ đánh giá tác động đầy đủ, cập nhật hằng năm hoặc khi thêm hoạt động rủi ro, sẵn sàng gửi Cục A05.

**Tác nhân chính.** SO (Dũng), TA, DS (○) soạn; DA (Quân) duyệt.

**Tác nhân phụ.** Cục A05 (nhận hồ sơ ngoài hệ thống).

**Mức ưu tiên.** M · Đợt 2 (FR-09-057 mức C, Đợt 3).

**FR hiện thực.** FR-09-055, FR-09-056, FR-09-057.

**Truy vết.** REQ-09; CMP-LAW-04, CMP-LAW-18; SEC-37; ADR 092; Q09-12.

**Tiền điều kiện.** `PERM-09-ropa`; hoạt động xử lý liên quan đã có (UC-09-07).

**Kích hoạt.** Bấm "Lập hồ sơ" ở UI-09-18; nhắc EVT-09-29 trước 30 ngày đến hạn rà soát.

**Đảm bảo tối thiểu.** Hồ sơ `ACTIVE` không sửa tại chỗ.

**Đảm bảo thành công.** Hồ sơ `ACTIVE`; sau khi gửi A05, `SUBMITTED_A05` kèm số công văn.

**Luồng chính.**
1. Dũng lập hồ sơ `PROCESSING` cho hoạt động `HD-HO-TICH-01` (API-09-193), nhập mô tả xử lý, đánh giá rủi ro, biện pháp giảm thiểu.
2. Hệ thống kiểm đủ mục (API-09-195); Dũng gửi duyệt (API-09-196).
3. Quân duyệt (API-09-197); hệ thống kiểm Quân khác Dũng, đặt `ACTIVE`.
4. Đến `09.dpia.review-months` (12) hoặc khi thêm hoạt động rủi ro, hệ thống nhắc rà soát (API-09-199).
5. Dũng xuất hồ sơ gửi A05 (API-09-200), gửi ngoài hệ thống rồi ghi số công văn (API-09-201).

**Luồng thay thế.**
- **3a. Từ chối.** API-09-198 kèm lý do.

**Luồng ngoại lệ.**
- **E1. Hồ sơ thiếu mục (bước 2).** ERR-09-073 (422): "Hồ sơ đánh giá tác động còn thiếu: {mục}."
- **E2. Tự duyệt (bước 3).** ERR-09-005 (403): "Bạn là người đề nghị hoặc đã quyết định ở bước trước nên không được duyệt bước này."
- **E3. Xuất khi chưa duyệt (bước 5).** ERR-09-074 (409): "Hồ sơ chưa được duyệt, chưa xuất gửi Cục A05 được."

**Quy tắc áp dụng.** BR-09-052, BR-09-053; LP-09-01.

**Màn hình, API.** UI-09-18; API-09-192…201; kịch bản TS-09-32.
:::

### 6.33. UC-09-33 · Ghi nhận vi phạm DLCN, đồng hồ 72 giờ, thông báo Cục A05 và chủ thể

::: dac-ta
**Mục tiêu.** Không bỏ lỡ hạn thông báo Cục A05, thông báo chủ thể khi rủi ro cao, và lưu hồ sơ khắc phục, bài học.

**Tác nhân chính.** SO (Dũng), TA, TO (Chi, chỉ ghi nhận ban đầu).

**Tác nhân phụ.** PH-18 (sự cố), PH-13 (cảnh báo), Cục A05, chủ thể bị ảnh hưởng.

**Mức ưu tiên.** M · Đợt 2.

**FR hiện thực.** FR-09-058, FR-09-059, FR-09-060.

**Truy vết.** REQ-09; CMP-LAW-18; SEC-37, SEC-74; BP-07; Q09-12, Q09-13.

**Tiền điều kiện.** `PERM-09-breach`; TO không đóng được hồ sơ.

**Kích hoạt.** Bấm "Ghi nhận vi phạm" ở UI-09-19; sự cố từ PH-18; cảnh báo EVT-09-13 chuyển lên (UC-09-14).

**Đảm bảo tối thiểu.** Hồ sơ không chứa giá trị DLCN rõ, chỉ số lượng, loại, băm (BR-09-056).

**Đảm bảo thành công.** Vụ việc `NOTIFIED` trước 72 giờ hoặc có căn cứ không thông báo; hồ sơ `CLOSED` khi hết nghĩa vụ.

**Luồng chính.**
1. Chi ghi nhận vụ việc (API-09-203) với `detectedAt` và mô tả; hệ thống tạo `REPORTED`, đồng hồ chạy, phát EVT-09-30.
2. Dũng đánh giá (API-09-206): phạm vi 1.200 hồ sơ, `BreachSeverity = HIGH`, có dữ liệu nhạy cảm; vụ việc sang `ASSESSING` rồi `NOTIFYING`.
3. Hệ thống phát EVT-09-31 ở 24, 48, 60 giờ cho SO, TA (API-09-207).
4. Dũng soạn thông báo A05 và chủ thể (API-09-208), xem lại các thông báo của vụ việc (API-09-239), nhập danh sách chủ thể bị ảnh hưởng theo băm (API-09-210).
5. Sau khi gửi ngoài hệ thống, Dũng ghi đã gửi kèm bằng chứng (API-09-209); hệ thống phát EVT-09-32, vụ việc `NOTIFIED` và đồng hồ 72 giờ dừng, đây là lần dừng duy nhất (BR-09-054).
6. Dũng ghi khắc phục, bài học (API-09-211, API-09-212), xem danh sách biện pháp (API-09-240), đóng hồ sơ (API-09-213) và tải hồ sơ (API-09-214).

**Luồng thay thế.**
- **2a. Không phải vi phạm.** `NOT_A_BREACH` cần SO duyệt và lý do.
- **4a. Miễn thông báo chủ thể.** Nêu căn cứ miễn trừ và lý do, SO duyệt.
- **1a. Từ bất thường.** `:escalate` ở UC-09-14 tạo vụ việc `ANOMALY`.

**Luồng ngoại lệ.**
- **E1. Thiếu thời điểm phát hiện hoặc mô tả (bước 1).** ERR-09-075 (422): "Vụ việc cần có thời điểm phát hiện và mô tả."
- **E2. Miễn thông báo chủ thể thiếu căn cứ (4a).** ERR-09-077 (422): "Không thông báo chủ thể cần nêu căn cứ miễn trừ và lý do."
- **E3. Vụ việc đã đóng (bước 4, 5).** ERR-09-006 (409): "Đối tượng đang ở trạng thái {trạng thái}, không thực hiện được thao tác này."
- **E4. Đóng khi còn nghĩa vụ (bước 6).** ERR-09-076 (409): "Còn nghĩa vụ thông báo chưa hoàn tất, chưa đóng được hồ sơ."

**Quy tắc áp dụng.** BR-09-054, BR-09-055, BR-09-056, BR-09-057.

**Màn hình, API.** UI-09-19; API-09-202…214, 239, 240, 083; kịch bản TS-09-33.
:::

```{.mermaid caption="Trình tự đồng hồ 72 giờ và thông báo vi phạm DLCN"}
sequenceDiagram
  actor TO as TO Chi
  actor SO as SO Dũng
  participant P as privacy-core
  participant K as Kafka
  participant A as Cục A05
  TO->>P: Ghi nhận vi phạm kèm detectedAt (API-09-203)
  P->>K: EVT-09-30 breach.recorded, đồng hồ 72 giờ chạy
  SO->>P: Đánh giá ảnh hưởng và mức nghiêm trọng (API-09-206)
  P->>K: EVT-09-31 tại 24, 48, 60 giờ
  K-->>SO: Cảnh báo còn hạn
  SO->>P: Soạn thông báo A05 và chủ thể (API-09-208)
  SO->>A: Gửi thông báo ngoài hệ thống
  SO->>P: Ghi đã gửi kèm bằng chứng (API-09-209)
  P->>K: EVT-09-32 breach.notified
  SO->>P: Ghi khắc phục, bài học và đóng hồ sơ (API-09-213)
```

Hình cho thấy việc gửi thông báo diễn ra ngoài Datahub nhưng bằng chứng và mốc giờ được ghi trong hệ thống; đồng hồ chạy từ lúc ghi nhận, không phải lúc đánh giá.

### 6.34. UC-09-34 · Nhật ký bảo vệ dữ liệu, bảng điều khiển, báo cáo định kỳ và cấu hình tham số

::: dac-ta
**Mục tiêu.** Tra được mọi thao tác bảo vệ dữ liệu, thấy tình trạng tuân thủ trong một màn hình, nhận báo cáo định kỳ, và chỉnh tham số `09.*` trong trần, sàn của PA.

**Tác nhân chính.** SO (Dũng), AU, TA (Mai), PA (Hà), VW (chỉ xem UI-09-01).

**Tác nhân phụ.** PH-13 (nguồn nhật ký), PH-08 (chỉ số).

**Mức ưu tiên.** M · Đợt 2 (FR-09-063 mức C, Đợt 3).

**FR hiện thực.** FR-09-061, FR-09-062, FR-09-063, FR-09-064.

**Truy vết.** REQ-09; SEC-37; NFR-00-029; FR-00-033, FR-00-034.

**Tiền điều kiện.** `PERM-09-audit-read` (nhật ký), `PERM-09-read` (bảng điều khiển), `PERM-09-config` (tham số, lịch báo cáo).

**Kích hoạt.** Mở UI-09-20, UI-09-01 hoặc UI-09-21.

**Đảm bảo tối thiểu.** Nhật ký không chứa giá trị `SENSITIVE`, chỉ tên trường, băm và số lượng (BR-09-058); sửa tham số áp dụng không cần khởi động lại.

**Đảm bảo thành công.** Dữ liệu tra, báo cáo hoặc tham số mới có hiệu lực, ghi kiểm toán.

**Luồng chính.**
1. Dũng tra nhật ký theo người, đối tượng, loại thao tác trong 90 ngày (API-09-215, API-09-216); xuất khi cần (API-09-217).
2. Dũng mở bảng điều khiển ở UI-09-01 (API-09-218): trường chưa phân loại, hợp đồng bị chặn, yêu cầu quá hạn, đồng hồ vi phạm, tuổi bundle; bấm vào thẻ xem chi tiết (API-09-219).
3. Mai lập báo cáo tuân thủ quý I (API-09-221), tải ở API-09-222 và đặt lịch lập hàng tháng (API-09-223).
4. Mai chỉnh `09.dsr.sla-days` từ 10 xuống 7 ở UI-09-21 (API-09-225).
5. Hệ thống kiểm giá trị trong miền của PA, lưu, ghi lịch sử (API-09-226) và áp dụng ngay.

**Luồng thay thế.**

**Luồng ngoại lệ.**
- **E1. Khoảng tra quá rộng (bước 1).** ERR-09-079 (422): "Chọn khoảng thời gian tối đa {n} ngày." với `{n}` là `09.audit.query-max-days`.
- **E2. Nguồn số liệu lỗi (bước 2).** ERR-09-009 (503): "Chưa kết nối được {tên dịch vụ}. Thử lại sau ít phút."
- **E3. Giá trị ngoài miền (bước 5).** ERR-09-078 (422): "Giá trị của {khóa} ngoài miền cho phép {miền}."
- **E4. Xung đột phiên bản (bước 5).** ERR-09-004 (409): "Dữ liệu đã được người khác thay đổi. Tải lại để xem bản mới."
- **E5. Lịch báo cáo sai (bước 3).** ERR-09-003 (400): "Dữ liệu không hợp lệ: {chi tiết}."

**Quy tắc áp dụng.** BR-09-058, BR-09-059, BR-09-060.

**Màn hình, API.** UI-09-20, UI-09-01, UI-09-21; API-09-215…226; kịch bản TS-09-34.
:::


## 7. Luồng phụ dùng chung

Bốn luồng phụ lặp lại ở nhiều use case nên đặc tả một lần; mã lỗi vẫn ghi ở luồng ngoại lệ.

| Mã | Luồng phụ | Dùng ở |
|---|---|---|
| LP-09-01 | Bốn mắt và ba người: người duyệt phải khác người đề nghị hoặc người quyết định ở bước trước, trùng thì khóa nút "Duyệt" và trả ERR-09-005 (403) nếu gọi thẳng API; người soạn chính sách không duyệt chính sách của mình; khôi phục giá trị gốc cần ba người khác nhau (FR-00-071, ADR-046) | UC-09-03, 06, 07, 10, 17, 22, 24, 25, 27, 28, 31, 32 |
| LP-09-02 | Lý do bắt buộc: quyết định từ chối, thu hồi, tạm dừng, loại trừ, xem đầy đủ cần lý do từ 20 ký tự, thiếu thì ERR-09-007 (422) "Nhập lý do tối thiểu 20 ký tự." | UC-09-07, 10, 11, 14, 20, 30 |
| LP-09-03 | Xung đột đồng thời và trạng thái: lệnh sửa mang `If-Match`, sai phiên bản trả ERR-09-004 (409); thao tác sai trạng thái trả ERR-09-006 (409); thiếu `If-Match` trả ERR-00-428 (428) | UC-09-01, 07, 08, 11, 16, 28, 33, 34 |
| LP-09-04 | Đóng an toàn: PH-09, OpenBao hoặc PH-13 không khả dụng thì PEP dùng kế hoạch đệm tối đa `09.plan.cache-seconds` rồi chỉ trả `PUBLIC` (đọc) hoặc từ chối (luồng); thao tác đặc quyền bị từ chối khi không ghi được vết (ERR-09-009, 010, 105, 108, 110) | UC-09-12, 13, 15, 18, 19, 20, 23, 24 |

: Luồng phụ dùng chung và use case dùng

## 8. Tổng hợp mã mới và đối chiếu

### 8.1. Mã mới và độ phủ

Tập này không tạo mã FR, BR, API, ERR, EVT, UI mới. Mã của tập: UC-09-01…34, LP-09-01…04, câu hỏi mở Q09-45…49; đề nghị kịch bản kiểm thử TS-09-01…34 ứng với UC-09-01…34 (1 − 1) cho D05-02-PH09. Cả 64 FR thuộc ít nhất một use case (§5.4). Mã ERR, EVT, API, UI, PERM, enum và tham số `09.*` lấy đúng FRS §8.2, §9, §10.1, Phụ lục A; câu thông báo nguyên văn FRS §9.1.

### 8.2. Kết quả đồng bộ với FRS 0.2

Sáu đề nghị của bản 0.1 đã được FRS 0.2 nhận (Phụ lục C, các dòng "UC §8.2"). Bảng ghi kết quả và chỗ tập này đã sửa theo.

| Mã | Nội dung bản 0.1 | Kết quả ở FRS 0.2 | Đã sửa trong tập |
|---|---|---|---|
| ĐN-UC-01 | ERR-09-012 chưa gắn luồng ngoại lệ | FR-09-004 nêu ERR-09-012 | UC-09-03 E4 giữ nguyên |
| ĐN-UC-02 | ERR-09-003 chưa có câu thông báo | §9.1: "Dữ liệu không hợp lệ: {chi tiết}." | UC-09-34 E5 dùng câu này |
| ĐN-UC-03 | Thiếu API gia hạn hạn trả lời | API-09-242 `:extend` (FR-09-049) | UC-09-30 nhánh 1a và danh sách API |
| ĐN-UC-04 | Thiếu API ngừng phần tử và rút yêu cầu | API-09-243 `:retire` (FR-09-003) và API-09-244 `:withdraw` (FR-09-045) | UC-09-02 nhánh 3a và E4, UC-09-29 nhánh 5d |
| ĐN-UC-05 | ERR-09-026 chưa gắn FR-09-015 | FR-09-015 nêu ERR-09-026 | UC-09-09 E2 giữ nguyên |
| ĐN-UC-06 | Tác nhân gọi `:suspend` khi tự tạm dừng | FRS coi là nghiệp vụ nội bộ của tác nhân `system:anomaly-detector`, không có API công khai | UC-09-11 nhánh 2d giữ nguyên |

: Kết quả đồng bộ đề nghị của tập UC với FRS 0.2

Bản 0.2 còn thêm vào các use case những điểm FRS 0.2 mới nêu: loại yêu cầu `RENEWAL` (UC-09-09 nhánh 1b), đệm quyết định 15 giây và 5 giây (BR-09-062, UC-09-13), `serverTime` cho đồng hồ xem đầy đủ (UC-09-20), ERR-09-079 ở nhật ký (UC-09-34 E1), ERR-09-080 ở mô phỏng (UC-09-17 E4), ERR-09-082 ở dữ liệu AI (UC-09-26 E4), tra đồng ý theo định danh (API-09-245, UC-09-31 nhánh 5a), và đồng hồ vi phạm chỉ dừng khi thông báo Cục A05 đã gửi (BR-09-054, UC-09-33).

### 8.3. Đề nghị đồng bộ cho tập khác

D02-08: xác nhận 13 quyền mới của FRS §3.2 và cặp loại trừ (SO không giữ `PERM-09-purpose-approve`; DS với DA; người soạn không duyệt chính sách của mình). D02-01: thêm BP-12 "Quản lý quyền riêng tư và dữ liệu cá nhân". D03-02-PH09 dùng năm sơ đồ trình tự làm nền luồng thành phần; D03-06-PH09 lấy câu thông báo từ chương 6 và đặt câu cho ERR-09-003; D03-04-PH09 đã có API-09-242, 243, 244; D05-02-PH09 dựng TS-09-nn ứng với UC-09-nn, ca đồng hồ (UC-09-20, 24, 30, 33) dùng đồng hồ giả lập. D00-02 chốt ADR 090 (điểm quyết định chính sách tập trung, PH-09 là PAP và PIP, OPA là PDP), ADR 091 (giả danh hóa HMAC-SHA256 theo tenant và mục đích, token qua OpenBao transit), ADR 092 (ẩn danh hóa k-ẩn danh bằng ARX), ADR 093 (phát hiện DLCN bằng bộ mẫu và kiểm tổng).

## 9. Câu hỏi mở

> **Câu hỏi mở Q09-45:** UC-09-33 bước 1: TO ghi nhận vi phạm ngoài giờ hành chính nhưng chỉ SO, TA đánh giá và gửi thông báo, trong khi đồng hồ 72 giờ chạy cả cuối tuần. Đề xuất lịch trực ngoài giờ cho SO; cần FRS chốt có phiên trực hay không.

> **Câu hỏi mở Q09-46:** UC-09-29 nhánh 5c: dữ liệu đi qua có nhiều bên kiểm soát (cơ quan cung cấp, cơ quan khai thác), chưa rõ ai trả lời chủ thể. Đề xuất PH-09 chỉ chuyển và theo dõi, bên kiểm soát gốc trả lời; cần pháp chế xác nhận theo NĐ 356/2025.

> **Câu hỏi mở Q09-47:** UC-09-10: DO duy nhất của tổ chức nghỉ phép thì yêu cầu quá `09.request.sla-days`. Đề xuất ủy quyền có thời hạn do TA gán (không vượt BR-09-014); cần FRS thêm khái niệm ủy quyền.

> **Câu hỏi mở Q09-48:** UC-09-24: khôi phục giá trị gốc cần ba người khác nhau (SO, DO, TA hoặc DA); tenant nhỏ có thể không đủ người. Đề xuất cho phép người duyệt cấp hai là PA của nền tảng và ghi rõ trong nhật ký; cần quyết định của chủ trì ATTT.

> **Câu hỏi mở Q09-49:** UC-09-20 nhánh 1a: giới hạn 20 lần xem đầy đủ mỗi giờ (`09.mask.reveal-max-per-hour`) tính theo lần bấm hay theo số trường, và xuất tệp thủy vân có tính vào hạn mức không. Đề xuất tính theo lần cấp phiếu, xuất tệp tính một lần mỗi tệp; cần thống nhất với FR-00-034.

## Lịch sử phiên bản

| Phiên bản | Ngày | Người | Nội dung |
|---|---|---|---|
| 0.1 | 26/11/2026 | Nhóm viết tài liệu (Claude) | Bản đầu theo K-UC và K-TRINH-BAY: 34 use case phủ 64 FR của FRS 0.1, bốn sơ đồ use case, năm sơ đồ trình tự (chấp thuận mục đích, xem đầy đủ, ẩn danh hóa, yêu cầu chủ thể, vi phạm 72 giờ), ma trận truy vết hai chiều, sáu đề nghị cho FRS |
| 0.2 | 26/11/2026 | Nhóm viết tài liệu (Claude) | Đồng bộ FRS 0.2: tên thư viện `dh-privacy-client`, nhánh ngừng phần tử, rút yêu cầu, gia hạn hạn trả lời, đề nghị gia hạn `RENEWAL`, tra đồng ý theo định danh, API-09-238 đến 245 vào bảng truy vết, ERR-09-079, 080, 082, BR-09-062, NFR-09-024 đến 026, đồng hồ 72 giờ dừng khi đã thông báo, mục 8.2 thành bảng kết quả |
| 0.3 | 27/11/2026 | Nhóm viết tài liệu (Claude) | Chốt câu hỏi mở đợt đồng bộ: Q388, Q393 |
