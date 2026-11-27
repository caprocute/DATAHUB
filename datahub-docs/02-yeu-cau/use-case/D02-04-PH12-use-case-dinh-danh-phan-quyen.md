---
ma_tai_lieu: D02-04-PH12
ten: Đặc tả use case phân hệ PH-12 Định danh và phân quyền
phien_ban: 0.2
ngay: 2026-11-27
trang_thai: Dự thảo
nguoi_doc: Hội đồng thẩm định, kỹ sư, kiểm thử viên
phan_he: PH-12
mo_ta: Đặc tả 42 use case của phân hệ Định danh và phân quyền theo vòng đời thật của tài khoản, danh tính máy, realm theo tenant và chính sách truy cập, làm căn cứ thiết kế màn hình, API và ca kiểm thử.
tai_lieu_lien_quan: D02-03-PH12 FRS; D02-08 Ma trận phân quyền; D03-04-PH12 API; D03-06-PH12 Màn hình; D05-02-PH12 Test case
---

# D02-04-PH12 · Đặc tả use case Định danh và phân quyền

## Tóm tắt cho hội đồng thẩm định

**Mục tiêu.** Tài liệu mô tả 42 use case của PH-12 Định danh và phân quyền, phủ toàn bộ 62 chức năng của [D02-03-PH12](../frs/D02-03-PH12-frs-dinh-danh-phan-quyen.md) (52 mức M, 9 mức S, 1 mức C). Use case đi theo ba câu chuyện thật của một tỉnh: cấp và thu hồi tài khoản cho cán bộ (tạo, kích hoạt, gán vai trò, khóa, vô hiệu); cấp và thu hồi danh tính cho hệ thống thông tin (client, chứng thư, bí mật, token, scope); và thay đổi quy tắc truy cập một cách có kiểm soát (soạn chính sách, kiểm thử, chạy khô, duyệt bốn mắt, phát hành gói ký, quay lui). Mỗi use case ghi tác nhân, điều kiện, luồng chính, nhánh thay thế, ngoại lệ kèm mã lỗi và câu thông báo người dùng nhìn thấy.

**Phạm vi.** 42 use case chia tám nhóm theo FRS: tài khoản (7), vai trò, nhóm và quyền (8), xác thực người dùng (5), danh tính HTTT và token (8), realm theo tenant (2), ủy quyền và chính sách (6), ghi vết và giám sát (4), quản trị (2). Mười ba use case do hệ thống hoặc phân hệ khác khởi động (APISIX, PH-01, PH-20, tác vụ định kỳ), vì phần lớn việc của PH-12 nằm trên đường dữ liệu chứ không có người bấm. Chức năng dùng chung FR-00 (đăng nhập ở ứng dụng, tự khóa phiên, hộp "Việc của tôi", kiểm toán chung) không đặc tả lại.

**Căn cứ pháp lý.** Như FRS: CMP-LAW-09 (Công văn 631/THH-THHT: SSO SAML 2 và OIDC, xác thực nhiều yếu tố, XACML), CMP-LAW-06 và CMP-LAW-08 (NĐ 331/2026, TCVN 14423:2026 cấp độ 3), CMP-LAW-05 (Luật BVDLCN 91/2025), CMP-LAW-01, CMP-LAW-03, CMP-LAW-10.

**Những điểm hội đồng cần lưu ý.** (1) Mọi thao tác cần người thứ hai (ngoại lệ tách nhiệm vụ, quyền có thời hạn, đặt lại yếu tố thứ hai của quản trị, chính sách, liên kết định danh ngoài) đều được đặc tả cả hai phía, người đề nghị và người duyệt, kèm ca người tự duyệt bị chặn (UC-12-10, 13, 18, 19, 35). (2) Thu hồi truy cập và chính sách mới phải có hiệu lực không quá 60 giây; UC-12-28 và UC-12-35 nêu từng bước từ lúc bấm tới lúc cổng từ chối. (3) Use case của đường dữ liệu (UC-12-31, 32) mô tả cách bên thực thi xử lý khi OPA lỗi: từ chối, không bao giờ cho qua. (4) Năm use case mức S hoặc Đợt 2 (UC-12-12, 14, 15, 39, 40) được tách riêng để có thể cắt khỏi MVP mà không ảnh hưởng use case khác.

**Con số chính.**

| Chỉ số | Giá trị |
|---|---|
| Use case | 42 (37 mức M, 5 mức S) |
| FR được phủ | 62 trên 62 (52 M, 9 S, 1 C) |
| Use case do hệ thống hoặc phân hệ khác khởi động | 13 |
| Luồng phụ dùng chung | 7 (LP-12-01…07) |
| Câu hỏi mở của tập | 5 (Q12-45…49) |

: Con số chính của tập use case PH-12

## 1. Giới thiệu

### 1.1. Mục đích và phạm vi

Tài liệu mô tả trình tự tương tác giữa người dùng, các phân hệ và hệ thống bên ngoài để hoàn thành từng việc nghiệp vụ của PH-12, từ cấp tài khoản cho cán bộ tới phát hành chính sách truy cập. Phạm vi là toàn bộ FR-12-001…062. Hành vi chi tiết của từng bước (đầu vào, kiểm tra, mã lỗi, câu thông báo) ở FR tương ứng; use case mô tả trình tự và vai trò, đủ để thiết kế màn hình, API và ca kiểm thử. Chức năng dùng chung FR-00 (đăng nhập một lần ở ứng dụng, tự khóa phiên, chọn tenant, hộp "Việc của tôi", thông báo, kiểm toán chung) không đặc tả lại; bước dựa vào chúng ghi "Tuân thủ FR-00-nnn".

Phạm vi không gồm: thực thi quyết định ủy quyền tại cổng (PH-03), che dữ liệu (PH-09), duyệt hồ sơ kết nạp HTTT (PH-01), điều phối khởi tạo tenant (PH-20), lưu nhật ký kiểm toán chung (PH-13). Các use case chỉ nêu điểm giao tiếp với những phân hệ đó (xem FRS mục 1.2).

### 1.2. Người đọc

Mỗi nhóm người đọc cần một phần khác nhau của tài liệu; bảng dưới chỉ ra nên đọc chương nào để khỏi phải đọc hết 42 use case.

| Người đọc | Phần cần đọc |
|---|---|
| Hội đồng thẩm định | Tóm tắt, chương 4 (sơ đồ tổng), chương 5 (truy vết) |
| Quản trị tỉnh, cán bộ ATTT | Chương 6 các use case nhóm tài khoản, vai trò, chính sách (UC-12-01…15, 18…20, 28, 34…36, 39) |
| Kỹ sư giao diện, BFF, kỹ sư dh-platform | Chương 6, đối chiếu cột Màn hình, API và bảng 5.2 |
| Kỹ sư hạ tầng định danh | Chương 6 các use case realm, token, khóa ký (UC-12-16, 25, 27, 29, 30) |
| Kiểm thử viên | Chương 6: mỗi luồng chính, thay thế, ngoại lệ là một ca kiểm thử ở D05-02-PH12 |

: Người đọc và phần cần đọc

### 1.3. Thuật ngữ và tài liệu tham chiếu

Thuật ngữ, chữ viết tắt và vai trò dùng chung với [D02-03-PH12](../frs/D02-03-PH12-frs-dinh-danh-phan-quyen.md) mục 1.4 và D00-01: tenant, realm, OIDC, PKCE, client, scope, JWKS, PDP, PEP, OPA, gói chính sách, chạy khô, MFA, step-up, tách nhiệm vụ, quyền có thời hạn. Tài liệu tham chiếu: D02-03-PH12 (FRS, nguồn của mọi mã lỗi, câu thông báo và quy tắc BR-12-001…045), D02-08 (ma trận vai trò, quyền), D03-04-PH12 (API), D03-06-PH12 (màn hình), D05-02-PH12 (ca kiểm thử), D02-02 (FR-00).

### 1.4. Cấu trúc tài liệu

Tài liệu gồm chín chương theo thứ tự từ tổng quan tới chi tiết; chương 6 chiếm phần lớn dung lượng.

| Chương | Nội dung |
|---|---|
| 2 | Quy ước đọc đặc tả |
| 3 | Tác nhân |
| 4 | Sơ đồ use case tổng (bảy hình theo nhóm) |
| 5 | Bảng tổng hợp use case và truy vết (UC ↔ FR, UC ↔ UI, API, UC ↔ REQ, BP, LGC) |
| 6 | Đặc tả chi tiết 42 use case |
| 7 | Luồng phụ dùng chung LP-12-01…07 |
| 8, 9 | Tổng hợp mã mới, câu hỏi mở |

: Cấu trúc tài liệu

## 2. Quy ước đọc đặc tả

Mỗi use case đặc tả bằng một bảng hai cột 15 mục theo thứ tự: Mục tiêu, Tác nhân chính, Tác nhân phụ, Mức ưu tiên, FR hiện thực, Truy vết, Tiền điều kiện, Kích hoạt, Đảm bảo tối thiểu, Đảm bảo thành công, Luồng chính, Luồng thay thế, Luồng ngoại lệ (kèm câu thông báo), Quy tắc áp dụng, Màn hình và API. Luồng chính đánh số 1, 2, 3. Luồng thay thế ghi `số bước + chữ` (ví dụ `3a`) và quay lại luồng chính. Luồng ngoại lệ ghi `E1`, `E2` kèm bước phát sinh và kết thúc use case hoặc quay lại bước nêu rõ. Câu thông báo trong ngoặc kép lấy từ FRS mục 9.2; mã lỗi `ERR-12-nnn` có thật ở FRS mục 9.1. Lỗi của điểm cuối OIDC trả theo RFC 6749, mã `ERR-12-1xx` ghi vào nhật ký và hiện ở trang Keycloak.

Dữ liệu ví dụ đều giả lập: tenant `T68` (realm `dh-t68`) và tenant nền tảng `PLATFORM` (realm `dh-platform`); người dùng **Mai** (TA, Sở KH&CN), **Dũng** và **Phương** (SO), **Hà** (PA), **Quân** (PO), **Kiên** (AU), **Lộc** (người quản lý trực tiếp, Sở Tư pháp), **Hùng** (đầu mối kỹ thuật HTTT, ROLE-ORG_REQUESTER); cán bộ `nguyenvana` (Sở Tư pháp, đơn vị `STP`); HTTT `HT-QLVB`, `HT-TUPHAP`; đơn vị `SKHCN`. Tiền tố API quản trị `/api/iam/v1`, API quyết định `/api/authz/v1`. Mọi API quản trị lấy tenant từ token (BR-12-004); đối tượng của tenant hoặc tổ chức khác trả `404` như không tồn tại (BR-12-041). Ghi kiểm toán theo FR-00-040, FR-00-041 và không nhắc lại ở từng bước, trừ khi có trường riêng.

## 3. Tác nhân

Tác nhân người dùng vai trò chuẩn của D02-08; tác nhân hệ thống là phân hệ, đơn vị triển khai hoặc hạ tầng. Cột "Use case chính" là các use case mà tác nhân là người khởi động hoặc người duyệt.

| Tác nhân | Loại | Use case chính |
|---|---|---|
| ROLE-TENANT_ADMIN, TA (Mai) | Chính | 01…05, 08…12, 14, 18…20, 23, 24, 28, 38, 40, 41 |
| ROLE-SECURITY_OFFICER, SO (Dũng) | Chính | 01, 04, 08, 10 (duyệt), 12 (duyệt), 13 (duyệt), 14, 18 (duyệt), 19 (duyệt), 20, 23, 26 (duyệt), 27 (duyệt), 28, 34…36, 38…40 |
| ROLE-PLATFORM_ADMIN, PA (Hà) | Chính | 13, 18, 26, 27, 29, 30, 34…36, 41 |
| ROLE-PLATFORM_OPERATOR, PO (Quân) | Chính | 13 (đề nghị), 38 |
| ROLE-AUDITOR, AU (Kiên) | Chính | 01, 08, 38, 40 |
| Cán bộ có tài khoản (`nguyenvana`) | Chính (không cần `PERM`) | 02 (kích hoạt), 06, 16, 17, 19 (liên kết VNeID) |
| Người quản lý trực tiếp (Lộc) | Chính (không cần `PERM`) | 14 |
| ROLE-ORG_REQUESTER (Hùng) | Chính | 24 |
| HTTT thành viên (`HT-QLVB`) | Chính (máy) | 25 |
| APISIX, thư viện PEP, `dh-runtime` | Chính (máy) | 31, 32 |
| PH-01, PH-15 | Chính (máy) | 21, 23, 24, 28 |
| PH-20 | Chính (máy) | 15, 29, 30 |
| PH-02, PH-07, PH-09, PH-10, PH-19 | Chính (máy) | 22 |
| Hệ thống: tác vụ định kỳ, bộ ghi chính sách, bộ phát hiện | Chính (máy) | 07, 27, 33, 37, 39 |
| Keycloak, OPA, OpenBao | Phụ | Nhiều use case |
| LDAP/AD của tỉnh, VNeID, ứng dụng SAML | Phụ (ngoài) | 19, 16 |
| PH-07, PH-13, PH-18, dịch vụ thư, bộ quét mã độc | Phụ | Nhiều use case |

: Tác nhân của PH-12 và use case chính

## 4. Sơ đồ use case tổng

Để đọc được trên trang A4, sơ đồ tổng chia bảy hình theo nhóm của FRS: tài khoản (Hình 1), vai trò và quyền (Hình 2), xác thực người dùng (Hình 3), danh tính HTTT và token (Hình 4), realm và quyết định ủy quyền (Hình 5), chính sách (Hình 6), ghi vết và quản trị (Hình 7). Tác nhân đặt bên trái, use case bên phải, mũi tên chỉ ai khởi động hoặc ai duyệt.

```{.mermaid caption="Use case nhóm tài khoản người dùng"}
flowchart LR
  TA([Quản trị tỉnh])
  SO([Cán bộ ATTT])
  AU([Kiểm toán viên])
  CB([Cán bộ])
  HT([Hệ thống])
  subgraph TK["Tài khoản người dùng"]
    U01[UC-12-01 Tìm, xem hồ sơ]
    U02[UC-12-02 Tạo và kích hoạt]
    U03[UC-12-03 Sửa, chuyển đơn vị]
    U04[UC-12-04 Khóa, vô hiệu]
    U05[UC-12-05 Nhập hàng loạt]
    U06[UC-12-06 Quên mật khẩu]
    U07[UC-12-07 Tác vụ định kỳ]
  end
  TA --> U01 & U02 & U03 & U04 & U05
  SO --> U01 & U04
  AU --> U01
  CB --> U02 & U06
  HT --> U07
```

Hình 1 cho thấy vòng đời tài khoản: TA tạo hoặc nhập, cán bộ tự kích hoạt (UC-12-02), TA và SO cùng có quyền khóa, còn tác vụ định kỳ (UC-12-07) là đường duy nhất tự vô hiệu tài khoản không dùng.

```{.mermaid caption="Use case nhóm vai trò, nhóm và quyền"}
flowchart LR
  TA([Quản trị tỉnh])
  SO([Cán bộ ATTT])
  AU([Kiểm toán viên])
  PA([Quản trị nền tảng])
  PO([Vận hành nền tảng])
  QL([Người quản lý])
  P20([PH-20])
  subgraph VT["Vai trò, nhóm và quyền"]
    U08[UC-12-08 Vai trò, quyền hiệu lực]
    U09[UC-12-09 Gán, gỡ vai trò]
    U10[UC-12-10 Ngoại lệ tách nhiệm vụ]
    U11[UC-12-11 Nhóm và đơn vị]
    U12[UC-12-12 Vai trò tùy biến]
    U13[UC-12-13 Quyền có thời hạn]
    U14[UC-12-14 Rà soát quyền]
    U15[UC-12-15 Chuyển định danh khi sáp nhập]
  end
  TA --> U08 & U09 & U10 & U11 & U12 & U14
  SO --> U08 & U10 & U12 & U13 & U14
  AU --> U08
  PA --> U13
  PO --> U13
  QL --> U14
  P20 --> U15
```

Hình 2 cho thấy các cặp đề nghị và duyệt: TA đề nghị, SO duyệt ngoại lệ (UC-12-10) và vai trò tùy biến (UC-12-12); PA hoặc PO đề nghị, người thứ hai duyệt quyền có thời hạn (UC-12-13). UC-12-15 do PH-20 gọi khi sáp nhập tenant.

```{.mermaid caption="Use case nhóm xác thực người dùng"}
flowchart LR
  CB([Cán bộ])
  TA([Quản trị tỉnh])
  SO([Cán bộ ATTT])
  PA([Quản trị nền tảng])
  subgraph XT["Xác thực người dùng"]
    U16[UC-12-16 Đăng nhập OIDC]
    U17[UC-12-17 Yếu tố thứ hai, step-up]
    U18[UC-12-18 Đặt lại yếu tố thứ hai]
    U19[UC-12-19 Liên kết định danh ngoài]
    U20[UC-12-20 Quản lý phiên]
  end
  CB --> U16 & U17 & U19
  TA --> U18 & U19 & U20
  SO --> U18 & U19 & U20
  PA --> U18
```

Hình 3 cho thấy cán bộ chỉ tự làm ba việc (đăng nhập, đăng ký yếu tố, liên kết VNeID); mọi việc còn lại là của quản trị. Đặt lại yếu tố thứ hai của tài khoản quản trị cần SO duyệt (UC-12-18).

```{.mermaid caption="Use case nhóm danh tính HTTT và token"}
flowchart LR
  TA([Quản trị tỉnh])
  SO([Cán bộ ATTT])
  PA([Quản trị nền tảng])
  DM([Đầu mối HTTT])
  P01([PH-01 và PH-15])
  SRC([PH-02, 07, 09, 10, 19])
  HT([HTTT thành viên])
  subgraph DT["Danh tính HTTT và token"]
    U21[UC-12-21 Cấp client]
    U22[UC-12-22 Sinh scope]
    U23[UC-12-23 Vòng đời client]
    U24[UC-12-24 Chứng thư, xoay bí mật]
    U25[UC-12-25 Lấy token máy]
    U26[UC-12-26 Tài khoản dịch vụ DU]
    U27[UC-12-27 Xoay khóa ký, JWKS]
    U28[UC-12-28 Thu hồi tức thời]
  end
  P01 --> U21 & U23 & U24
  SRC --> U22
  TA --> U23 & U24 & U28
  SO --> U23 & U26 & U27 & U28
  PA --> U26 & U27
  DM --> U24
  HT --> U25
```

Hình 4 cho thấy hai chủ thể cấp danh tính máy: PH-01 và PH-15 tạo client (UC-12-21), các phân hệ nguồn chỉ được đặt scope của loại mình (UC-12-22); quản trị tỉnh không tạo client trực tiếp mà chỉ quản lý chứng thư, bí mật, vòng đời và thu hồi.

```{.mermaid caption="Use case nhóm realm và quyết định ủy quyền"}
flowchart LR
  P20([PH-20])
  PA([Quản trị nền tảng])
  PEP([APISIX và thư viện PEP])
  DU([DU, HTTT thẩm định])
  subgraph RL["Realm theo tenant"]
    U29[UC-12-29 Khởi tạo realm, GitOps]
    U30[UC-12-30 Tạm ngừng, khôi phục]
  end
  subgraph QD["Quyết định ủy quyền"]
    U31[UC-12-31 Quyết định PEP và PDP]
    U32[UC-12-32 Theo lô, XACML, bộ đệm]
  end
  P20 --> U29 & U30
  PA --> U29 & U30
  PEP --> U31
  DU --> U32
```

Hình 5 gom hai nhóm máy nhiều nhất: PH-20 điều khiển vòng đời realm (UC-12-29, 30), còn bên thực thi gọi OPA ở đường dữ liệu (UC-12-31, 32); quản trị nền tảng chỉ vào thay PH-20 khi cần.

```{.mermaid caption="Use case nhóm chính sách truy cập"}
flowchart LR
  PA([Quản trị nền tảng])
  SO([Cán bộ ATTT])
  HT([Hệ thống])
  subgraph CS["Chính sách truy cập"]
    U33[UC-12-33 Sinh dữ liệu vai trò, quyền]
    U34[UC-12-34 Soạn, kiểm thử, chạy khô]
    U35[UC-12-35 Duyệt bốn mắt, phát hành]
    U36[UC-12-36 Thu hồi, quay lui]
  end
  HT --> U33
  PA --> U34 & U35 & U36
  SO --> U34 & U35 & U36
```

Hình 6 cho thấy vòng đời một thay đổi chính sách: soạn và chạy khô (UC-12-34), duyệt bốn mắt rồi phát hành (UC-12-35), thu hồi hoặc quay lui khi có sự cố (UC-12-36). Dữ liệu vai trò–quyền (UC-12-33) do hệ thống sinh, không qua duyệt từng lần.

```{.mermaid caption="Use case nhóm ghi vết, giám sát và quản trị"}
flowchart LR
  HT([Hệ thống])
  SO([Cán bộ ATTT])
  AU([Kiểm toán viên])
  TA([Quản trị tỉnh])
  PA([Quản trị nền tảng])
  DU([DU và phân hệ khác])
  subgraph GV["Ghi vết và giám sát"]
    U37[UC-12-37 Ghi vết]
    U38[UC-12-38 Tra nhật ký quyết định]
    U39[UC-12-39 Cảnh báo bất thường]
    U40[UC-12-40 Báo cáo tài khoản, MFA]
  end
  subgraph QT["Quản trị"]
    U41[UC-12-41 Tham số theo tenant]
    U42[UC-12-42 Tra danh bạ]
  end
  HT --> U37
  SO --> U38 & U39 & U40
  AU --> U38 & U40
  TA --> U38 & U40 & U41
  PA --> U41
  DU --> U42
```

Hình 7 cho thấy ghi vết là use case máy, còn tra cứu và cảnh báo là việc của SO, kiểm toán viên và TA; danh bạ (UC-12-42) là điểm duy nhất để phân hệ khác tra thông tin người dùng.

## 5. Bảng tổng hợp use case và truy vết

### 5.1. Use case và FR

Bảng dưới nối từng use case với FR hiện thực. Mỗi FR của PH-12 thuộc ít nhất một use case; mức của use case là mức cao nhất trong các FR nó hiện thực.

| UC | Tên | Tác nhân chính | Mức | FR |
|---|---|---|---|---|
| UC-12-01 | Tìm kiếm và xem hồ sơ người dùng | TA, SO, AU | M | 001, 002 |
| UC-12-02 | Tạo tài khoản và kích hoạt lần đầu | TA, cán bộ | M | 003, 006 |
| UC-12-03 | Sửa thông tin và chuyển đơn vị của người dùng | TA | M | 004 |
| UC-12-04 | Khóa, mở khóa, vô hiệu và kích hoạt lại tài khoản | TA, SO | M | 005 |
| UC-12-05 | Nhập người dùng hàng loạt từ tệp | TA | M | 009 |
| UC-12-06 | Đặt lại mật khẩu khi quên | Cán bộ | M | 007 |
| UC-12-07 | Tác vụ định kỳ: tự vô hiệu tài khoản, tạm ngừng client, đồng bộ đơn vị | Hệ thống | M | 008, 010 |
| UC-12-08 | Xem vai trò chuẩn và quyền hiệu lực | TA, SO, AU | M | 011, 016 |
| UC-12-09 | Gán và gỡ vai trò cho người dùng | TA | M | 012 |
| UC-12-10 | Đề nghị và duyệt ngoại lệ tách nhiệm vụ | TA, SO | M | 013 |
| UC-12-11 | Quản lý nhóm và đơn vị tổ chức | TA | M | 014 |
| UC-12-12 | Tạo vai trò tùy biến của tenant | TA, SO | S | 015 |
| UC-12-13 | Cấp quyền có thời hạn và vào tenant khác | PA, PO, SO | M | 017, 027 |
| UC-12-14 | Rà soát quyền định kỳ | TA, SO, người quản lý | S | 018 |
| UC-12-15 | Chuyển định danh và vai trò khi sáp nhập tenant | PH-20 | S | 019 |
| UC-12-16 | Đăng nhập OIDC, chống dò mật khẩu và làm mới token | Cán bộ | M | 020, 021, 038 |
| UC-12-17 | Đăng ký yếu tố thứ hai và xác thực lại bước lên | Cán bộ | M | 022, 023 |
| UC-12-18 | Đặt lại yếu tố thứ hai khi mất thiết bị | TA, PA, SO | M | 024 |
| UC-12-19 | Khai báo và duyệt liên kết định danh ngoài: LDAP/AD, SAML 2, VNeID | TA, SO | M | 025, 026, 028 |
| UC-12-20 | Quản lý phiên: xem, buộc đăng xuất | TA, SO | M | 029 |
| UC-12-21 | Cấp client OAuth cho HTTT và ứng dụng sandbox | PH-01, PH-15 | M | 030, 032 |
| UC-12-22 | Sinh scope của client từ dữ liệu đã duyệt | PH-02, 07, 09, 10, 19 | M | 036 |
| UC-12-23 | Quản lý vòng đời client: sửa, tạm ngừng, tiếp tục, thu hồi | TA, SO | M | 031 |
| UC-12-24 | Đăng ký chứng thư, khóa công khai và xoay bí mật client | TA, đầu mối HTTT | M | 033, 034 |
| UC-12-25 | HTTT lấy token bằng client_credentials | HTTT thành viên | M | 035 |
| UC-12-26 | Khai báo tài khoản dịch vụ của đơn vị triển khai | PA, SO | M | 037 |
| UC-12-27 | Xoay khóa ký và công bố JWKS | Hệ thống, PA, SO | M | 039 |
| UC-12-28 | Thu hồi truy cập tức thời | TA, SO | M | 040 |
| UC-12-29 | Khởi tạo realm của tenant và giữ cấu hình bằng GitOps | PH-20, PA | M | 041, 042 |
| UC-12-30 | Tạm ngừng, khôi phục, chuyển chỉ-đọc realm | PH-20, PA | M | 043 |
| UC-12-31 | Quyết định ủy quyền theo hợp đồng PEP và PDP | APISIX, thư viện PEP | M | 044, 045, 046, 047 |
| UC-12-32 | Quyết định theo lô, theo XACML và bộ đệm quyết định | DU, HTTT thẩm định | M | 048, 049, 050 |
| UC-12-33 | Sinh dữ liệu vai trò–quyền cho OPA | Hệ thống | M | 051 |
| UC-12-34 | Soạn, kiểm thử và chạy khô chính sách | PA, SO | M | 052, 053 |
| UC-12-35 | Duyệt bốn mắt và phát hành gói chính sách ký | PA, SO | M | 054 |
| UC-12-36 | Thu hồi và quay lui chính sách | SO, PA | M | 055 |
| UC-12-37 | Ghi vết sự kiện xác thực và quyết định ủy quyền | Hệ thống | M | 056, 057 |
| UC-12-38 | Tra cứu nhật ký quyết định và sự kiện an ninh | SO, AU, TA | M | 058 |
| UC-12-39 | Phát hiện hành vi bất thường và xử lý cảnh báo | SO | S | 059 |
| UC-12-40 | Báo cáo tình trạng tài khoản và xác thực hai yếu tố | SO, TA, AU | S | 060 |
| UC-12-41 | Cấu hình tham số phân hệ theo tenant | TA, PA | M | 061 |
| UC-12-42 | Tra cứu danh bạ người dùng cho phân hệ khác | DU, phân hệ | M | 062 |

: Use case và FR hiện thực (số FR viết gọn, FR-12-nnn)

### 5.2. Use case, màn hình và API

Bảng dưới cho biết use case dùng màn hình nào và gọi API nào, lấy từ cột "Màn hình, API" của từng FR. Use case máy không có màn hình.

| UC | UI | API |
|---|---|---|
| UC-12-01 | UI-12-01, 02 | API-12-001, 002 |
| UC-12-02 | UI-12-03, 18 | API-12-003, 009 |
| UC-12-03 | UI-12-02, 03 | API-12-004 |
| UC-12-04 | UI-12-02, 03 | API-12-005…008 |
| UC-12-05 | UI-12-04 | API-12-010…012 |
| UC-12-06 | UI-12-18 | Luồng chuẩn Keycloak, không có API quản trị |
| UC-12-07 | UI-12-07, 15 | — (tác vụ nội bộ) |
| UC-12-08 | UI-12-02, 05 | API-12-013, 019…021, 025 |
| UC-12-09 | UI-12-02, 06 | API-12-025…027 |
| UC-12-10 | UI-12-06, 17 | API-12-028…031 |
| UC-12-11 | UI-12-07 | API-12-032…035 |
| UC-12-12 | UI-12-05 | API-12-022…024 |
| UC-12-13 | UI-12-08, 17, 18 | API-12-036…040, 073, 074 |
| UC-12-14 | UI-12-09, 17 | API-12-041…044 |
| UC-12-15 | UI-12-19 | API-12-045, 046 |
| UC-12-16 | UI-12-18 | API-12-072…074, 076, 078 |
| UC-12-17 | UI-12-02, 18 | API-12-002, 073, 074 |
| UC-12-18 | UI-12-02, 17 | API-12-015 |
| UC-12-19 | UI-12-11, 18 | API-12-047…055 |
| UC-12-20 | UI-12-02 | API-12-016, 017 |
| UC-12-21 | UI-12-10 | API-12-056…058, 063 |
| UC-12-22 | UI-12-10 | API-12-067, 068 |
| UC-12-23 | UI-12-10 | API-12-059…062 |
| UC-12-24 | UI-12-10 | API-12-064…066 |
| UC-12-25 | — | API-12-074 |
| UC-12-26 | UI-12-10 | API-12-069…071 |
| UC-12-27 | UI-12-19 | API-12-075 |
| UC-12-28 | UI-12-02, 10 | API-12-018, 062, 077, 079 |
| UC-12-29 | UI-12-19 | API-12-080…083 |
| UC-12-30 | UI-12-19 | API-12-084, 085 |
| UC-12-31 | — | API-12-013, 086 |
| UC-12-32 | — | API-12-087, 088 |
| UC-12-33 | UI-12-12 | API-12-101, 102 |
| UC-12-34 | UI-12-12, 13 | API-12-089…095 |
| UC-12-35 | UI-12-13, 17 | API-12-096…098, 101 |
| UC-12-36 | UI-12-12 | API-12-099…101 |
| UC-12-37 | UI-12-14, 15 | API-12-103, 105 |
| UC-12-38 | UI-12-14 | API-12-103, 104 |
| UC-12-39 | UI-12-15 | API-12-106, 107 |
| UC-12-40 | UI-12-15 | API-12-108, 109 |
| UC-12-41 | UI-12-16 | API-12-110, 111 |
| UC-12-42 | — | API-12-014 |

: Use case, màn hình và API

### 5.3. Use case, REQ, quy trình và hệ cũ

Cột REQ luôn có REQ-12; REQ khác lấy từ mục 11.2 của FRS. Cột BP chỉ ghi quy trình mà FRS đã dẫn; dấu "—" là use case quản trị định danh không thuộc quy trình nào trong BP-01…09. Cột LGC theo mục 11.1 của FRS.

| UC | REQ | BP | LGC |
|---|---|---|---|
| UC-12-01 | REQ-12 | — | LGC-IAM-002, LGC-IAM-005 |
| UC-12-02, 03 | REQ-12 | — | LGC-IAM-002 |
| UC-12-04 | REQ-12 | — | LGC-IAM-005 |
| UC-12-05 | REQ-12 | BP-09 | LGC-IAM-002 |
| UC-12-06 | REQ-12 | — | — (mới, SEC-22) |
| UC-12-07 | REQ-12, REQ-07 | — | — (mới, SEC-27) |
| UC-12-08 | REQ-12 | — | LGC-IAM-002 |
| UC-12-09, 11 | REQ-12 | — | LGC-IAM-002, LGC-BUS-032 |
| UC-12-10 | REQ-12 | — | — (D02-08 §4) |
| UC-12-12 | REQ-12 | — | LGC-IAM-002 |
| UC-12-13 | REQ-12, REQ-20 | — | LGC-IAM-001 |
| UC-12-14 | REQ-12 | — | — (mới, SEC-27) |
| UC-12-15 | REQ-12, REQ-20 | BP-09 | — (D03-10 §6) |
| UC-12-16 | REQ-12 | — | LGC-IAM-001, 005, 006, 008 |
| UC-12-17, 18 | REQ-12 | — | LGC-IAM-003 |
| UC-12-19 | REQ-12 | — | LGC-IAM-001, 004, 007 (loại bỏ, VNeID thay thế), 008 |
| UC-12-20 | REQ-12 | — | LGC-IAM-001, 005 |
| UC-12-21 | REQ-12, REQ-01, REQ-15 | BP-01 | LGC-IAM-002, 006, LGC-APIM-020 |
| UC-12-22 | REQ-12, REQ-02, 09, 10 | — | LGC-NGSP-008 |
| UC-12-23 | REQ-12, REQ-01 | BP-07 | LGC-APIM-020 |
| UC-12-24 | REQ-12 | — | LGC-BUS-041, LGC-NGSP-008 |
| UC-12-25 | REQ-12 | — | LGC-IAM-006, LGC-BUS-041, LGC-NGSP-008 |
| UC-12-26, 27 | REQ-12 | — | — (SEC-24, SEC-25) |
| UC-12-28 | REQ-12 | BP-07 | LGC-IAM-005 |
| UC-12-29 | REQ-12, REQ-20 | BP-08 | LGC-IAM-002 |
| UC-12-30 | REQ-12, REQ-20 | — | — (D03-10 §5.1) |
| UC-12-31 | REQ-12, REQ-09 | — | LGC-BUS-032, LGC-BUS-041 |
| UC-12-32 | REQ-12 | — | — (CMP-LAW-09) |
| UC-12-33…35 | REQ-12 | — | — (ADR-068, ADR-069) |
| UC-12-36 | REQ-12 | BP-07 | — |
| UC-12-37 | REQ-12, REQ-13 | — | LGC-IAM-005 |
| UC-12-38, 40 | REQ-12, REQ-13 | — | — |
| UC-12-39 | REQ-12, REQ-13 | — | — (THR-09, THR-12) |
| UC-12-41 | REQ-12, REQ-18 | — | — |
| UC-12-42 | REQ-12 | — | — (FR-00-043, FR-00-070) |

: Use case, REQ, quy trình và hệ cũ

## 6. Đặc tả chi tiết use case

Bốn mươi hai use case dưới đây xếp theo nhóm của FRS: tài khoản (UC-12-01…07), vai trò, nhóm và quyền (08…15), xác thực người dùng (16…20), danh tính HTTT và token (21…28), realm (29, 30), ủy quyền và chính sách (31…36), ghi vết và giám sát (37…40), quản trị (41, 42). Mỗi use case là một khối 15 mục; bước nào cần chi tiết kiểm tra, ngưỡng, thông số thì dẫn tới FR hiện thực và quy tắc BR tương ứng.

### 6.1. UC-12-01 · Tìm kiếm và xem hồ sơ người dùng

::: dac-ta
**Mục tiêu.** Quản trị tỉnh, cán bộ ATTT và kiểm toán viên tìm được một tài khoản trong hàng nghìn tài khoản của tenant và thấy ngay tài khoản nào cần chú ý (khóa, thiếu yếu tố thứ hai, lâu không đăng nhập).

**Tác nhân chính.** ROLE-TENANT_ADMIN (Mai); ROLE-SECURITY_OFFICER (Dũng); ROLE-AUDITOR (Kiên).

**Tác nhân phụ.** Keycloak (trạng thái, yếu tố, phiên), PH-13 (tab Lịch sử, FR-00-043).

**Mức ưu tiên.** M.

**FR hiện thực.** FR-12-001, 002.

**Truy vết.** REQ-12; LGC-IAM-002, LGC-IAM-005; SEC-27.

**Tiền điều kiện.** Người xem có `PERM-12-read` và đã chọn tenant `T68` (FR-00-004).

**Kích hoạt.** Mai mở "Quản trị người dùng" ở UI-12-01.

**Đảm bảo tối thiểu.** Không thay đổi dữ liệu; không trả giá trị bí mật của yếu tố xác thực; không lộ người dùng của tenant hay tổ chức khác.

**Đảm bảo thành công.** Danh sách phân trang đúng bộ lọc; chi tiết đủ sáu tab.

**Luồng chính.**

1. Mai mở UI-12-01. Hệ thống gọi API-12-001 và hiện danh sách của `T68`, tài khoản `BLOCKED`, `LOCKED` xếp đầu, kèm sáu thẻ số đếm theo trạng thái làm bộ lọc nhanh.
2. Mai gõ "nguyen" vào ô tìm và chọn đơn vị `STP`. Hệ thống kiểm tra tham số rồi trả các dòng khớp (tên, tên đăng nhập, đơn vị, vai trò rút gọn, MFA, đăng nhập cuối, trạng thái); bộ lọc ghi lên URL (FR-00-022).
3. Mai bấm dòng `nguyenvana`. Hệ thống gọi API-12-002 và mở UI-12-02 ở tab Tổng quan.
4. Hệ thống gộp bản chiếu `ph12_iam` với trạng thái, yếu tố (chỉ loại và nhãn thiết bị), phiên đang mở từ Keycloak, rồi hiện các tab Vai trò, Quyền hiệu lực, Yếu tố xác thực, Phiên, Lịch sử; nút thao tác hiện theo quyền của Mai.

**Luồng thay thế.**

- **2a. Rà tài khoản sắp bị vô hiệu.** Mai lọc `inactiveDays` = 30 (hoặc bấm thẻ "Sắp bị vô hiệu"); hệ thống hiện các tài khoản gần ngưỡng 45 ngày của FR-12-008.
- **3a. Kiểm toán viên.** Kiên có `PERM-12-read` nên xem được mọi tab nhưng không thấy nút thao tác ghi.
- **4a. Keycloak chậm.** Hệ thống trả phần từ bản chiếu; hai khối Yếu tố xác thực và Phiên báo "Chưa lấy được", không lỗi cả trang.

**Luồng ngoại lệ.**

- **E1. Tham số sai miền (bước 2).** ERR-12-003 (400); "Bộ lọc không hợp lệ: {tên trường}."; Mai sửa bộ lọc.
- **E2. Không tìm thấy hoặc thuộc tenant, tổ chức khác (bước 3).** ERR-12-001 (404); "Không tìm thấy người dùng này trong tỉnh của anh/chị." Không phân biệt "không tồn tại" với "của tenant khác" (BR-12-041).
- **E3. Thiếu quyền (bước 1 hoặc 3).** ERR-12-007 (403); "Bạn không có quyền thực hiện thao tác này. Liên hệ quản trị tỉnh nếu cần được cấp quyền."
- **E4. Bản chiếu chậm so với Keycloak (bước 1).** Danh sách vẫn trả kèm dải thông báo "Dữ liệu có thể chậm tới {n} phút so với hệ thống xác thực."

**Quy tắc áp dụng.** BR-12-004, 037, 041, 045.

**Màn hình, API.** UI-12-01, 02; API-12-001, 002.
:::

### 6.2. UC-12-02 · Tạo tài khoản và kích hoạt lần đầu

::: dac-ta
**Mục tiêu.** Quản trị tỉnh cấp tài khoản cho một cán bộ mới mà không phải biết hay chuyển mật khẩu; cán bộ tự đặt mật khẩu và, nếu thuộc nhóm bắt buộc, đăng ký yếu tố thứ hai ngay lần đầu.

**Tác nhân chính.** ROLE-TENANT_ADMIN (Mai); cán bộ `nguyenvana`.

**Tác nhân phụ.** Keycloak, PH-07 (đơn vị), dịch vụ thư.

**Mức ưu tiên.** M.

**FR hiện thực.** FR-12-003, 006.

**Truy vết.** REQ-12; LGC-IAM-002; SEC-22, SEC-23, SEC-27.

**Tiền điều kiện.** Mai có `PERM-12-user-admin`; đơn vị `STP` còn hiệu lực ở PH-07; thư điện tử thuộc miền công vụ của `T68`.

**Kích hoạt.** Mai bấm "+ Tạo người dùng" ở UI-12-01.

**Đảm bảo tối thiểu.** Không có mật khẩu hay liên kết kích hoạt nào xuất hiện trong phản hồi API, log hay màn hình; thất bại giữa chừng không để lại tài khoản dở dang.

**Đảm bảo thành công.** Tài khoản `PENDING_ACTIVATION` rồi `ACTIVE` sau khi cán bộ kích hoạt; EVT-12-01, EVT-12-02 đã phát.

**Luồng chính.**

1. Mai mở UI-12-03, nhập tên đăng nhập `nguyenvana`, họ tên "Nguyễn Văn A", thư `nguyenvana@t68.gov.vn`, đơn vị `STP`, chức danh, người quản lý trực tiếp là Lộc, vai trò ban đầu `ROLE-INTEGRATION_ENGINEER` ở phạm vi `ORG` = `STP`, rồi bấm "Tạo".
2. Hệ thống gọi API-12-003 kèm `Idempotency-Key`; kiểm tra tên đăng nhập và thư chưa dùng trong realm `dh-t68`, đơn vị còn hiệu lực ở PH-07, thư thuộc miền công vụ.
3. Hệ thống tạo tài khoản ở Keycloak, trạng thái `PENDING_ACTIVATION`, không mật khẩu, kèm hành động bắt buộc đặt mật khẩu (và đăng ký yếu tố thứ hai nếu vai trò thuộc nhóm `mfa-required`).
4. Hệ thống gán vai trò ban đầu theo UC-12-09, rồi sinh liên kết kích hoạt dùng một lần, hiệu lực 24 giờ, gửi tới thư của cán bộ; thư chỉ chứa liên kết (FR-00-062).
5. Hệ thống ghi kiểm toán, phát EVT-12-01 (và EVT-12-03 nếu có vai trò), trả `201`; Mai thấy tài khoản ở trạng thái "Chờ kích hoạt".
6. `nguyenvana` mở liên kết ở UI-12-18; Keycloak kiểm tra mã còn hiệu lực, hiện yêu cầu mật khẩu ngay khi gõ (từ 14 ký tự, không trùng mật khẩu đã lộ, không chứa tên đăng nhập).
7. Cán bộ đặt mật khẩu mới hai lần; Keycloak lưu bản băm, đặt `ACTIVE`, hủy liên kết, báo `dh-platform` cập nhật bản chiếu (EVT-12-02), rồi chuyển cán bộ vào ứng dụng theo UC-12-16.

**Luồng thay thế.**

- **1a. Tenant bật liên kết LDAP/AD.** Nút "Tạo" thành "Nhập từ danh bạ"; tài khoản lấy thuộc tính từ LDAP, không đặt mật khẩu cục bộ (UC-12-19); bước 6 bỏ qua, xác thực bằng mật khẩu LDAP.
- **1b. Tạo nhiều người.** Mai dùng UC-12-05.
- **6a. Gửi lại liên kết.** Liên kết quá hạn: Mai bấm "Gửi lại liên kết kích hoạt" (API-12-009); hệ thống hủy liên kết cũ, sinh liên kết mới 24 giờ, giới hạn 3 lần mỗi giờ.
- **7a. Nhóm bắt buộc có yếu tố thứ hai.** Trước khi hoàn tất, Keycloak buộc đăng ký yếu tố thứ hai theo UC-12-17; quản trị chỉ chấp nhận WebAuthn.

**Luồng ngoại lệ.**

- **E1. Tên đăng nhập hoặc thư đã dùng (bước 2).** ERR-12-002 (409); "Tên đăng nhập hoặc thư điện tử này đã được dùng. Chọn giá trị khác."; quay lại bước 1.
- **E2. Đơn vị không có hoặc hết hiệu lực (bước 2).** ERR-12-004 (422); "Đơn vị {mã} không tồn tại hoặc đã hết hiệu lực."
- **E3. Thư ngoài miền công vụ (bước 2).** ERR-12-005 (422); "Thư điện tử phải thuộc miền {danh sách miền} của tỉnh."
- **E4. Vai trò ban đầu tạo cặp xung đột (bước 4).** Tài khoản vẫn tạo, vai trò đó chưa gán; ERR-12-009 hiện tại ô vai trò (xử lý tiếp ở UC-12-10).
- **E5. Keycloak không khả dụng (bước 3).** ERR-12-038 (503); "Hệ thống xác thực tạm thời không khả dụng; chưa tạo tài khoản. Thử lại sau."
- **E6. Liên kết hết hạn hoặc đã dùng (bước 6).** ERR-12-016 (410); "Liên kết đã hết hạn hoặc đã được dùng. Liên hệ quản trị tỉnh để được gửi liên kết mới."
- **E7. Mật khẩu không đạt (bước 7).** ERR-12-015 (422); "Mật khẩu cần ít nhất 14 ký tự, không trùng mật khẩu đã bị lộ và không chứa tên đăng nhập."; nhập lại.
- **E8. Gửi lại quá 3 lần mỗi giờ (bước 6a).** ERR-12-037 (429); "Thao tác quá nhiều lần. Thử lại sau {n} phút."

**Quy tắc áp dụng.** BR-12-014, 015, 017, 018, 029, 030, 045.

**Màn hình, API.** UI-12-03, 18; API-12-003, 009.
:::

### 6.3. UC-12-03 · Sửa thông tin và chuyển đơn vị của người dùng

::: dac-ta
**Mục tiêu.** Quản trị tỉnh cập nhật hồ sơ cán bộ và, khi cán bộ chuyển công tác, chuyển đơn vị mà không để sót quyền theo đơn vị cũ.

**Tác nhân chính.** ROLE-TENANT_ADMIN (Mai).

**Tác nhân phụ.** Keycloak, PH-07.

**Mức ưu tiên.** M.

**FR hiện thực.** FR-12-004.

**Truy vết.** REQ-12; LGC-IAM-002.

**Tiền điều kiện.** Mai có `PERM-12-user-admin`; tài khoản `nguyenvana` không ở `DISABLED`; Mai không sửa chính mình ở các trường quyền (BR-12-033).

**Kích hoạt.** Mai bấm "Sửa" ở UI-12-02 hoặc UI-12-03.

**Đảm bảo tối thiểu.** Không còn vai trò phạm vi tổ chức nào gắn với đơn vị cũ sau khi lưu; nếu lỗi, hồ sơ giữ nguyên.

**Đảm bảo thành công.** Keycloak và `ph12_iam` khớp nhau; EVT-12-02 đã phát khi đổi đơn vị.

**Luồng chính.**

1. Mai đổi đơn vị của `nguyenvana` từ `STP` sang `SKHCN` và chức danh, bấm "Lưu". Hệ thống gọi API-12-004 kèm `If-Match`.
2. Hệ thống kiểm tra phiên bản và lược đồ; kiểm tra `SKHCN` còn hiệu lực ở PH-07.
3. Hệ thống liệt kê vai trò phạm vi `ORG` đang gắn `STP` và yêu cầu Mai chọn từng vai trò: chuyển theo `SKHCN` hoặc gỡ.
4. Mai chọn: `ROLE-INTEGRATION_ENGINEER` chuyển sang `SKHCN`. Hệ thống kiểm tra vai trò sau chuyển vẫn đúng BR-12-037 và không tạo cặp xung đột.
5. Hệ thống cập nhật Keycloak và bản chiếu; vai trò bị gỡ thì thu hồi phiên của cán bộ (BR-12-036); đổi thư thì đặt lại cờ xác minh thư.
6. Hệ thống ghi kiểm toán giá trị trước và sau (che thư một phần), phát EVT-12-02 (và EVT-12-03 nếu vai trò bị gỡ), trả `200` kèm `ETag` mới.

**Luồng thay thế.**

- **1a. Chỉ đổi họ tên, chức danh.** Bỏ qua bước 2 phần PH-07 và bước 3, 4.
- **1b. Tài khoản `authSource=LDAP`.** Các trường nguồn LDAP (họ tên, thư, đơn vị) chỉ đọc; Mai sửa ở danh bạ LDAP rồi đồng bộ (UC-12-19).
- **3a. Không còn vai trò theo đơn vị cũ.** Bỏ qua bước 3, 4.

**Luồng ngoại lệ.**

- **E1. Phiên bản đã đổi (bước 1).** ERR-12-044 (412); "Thông tin này vừa được người khác sửa. Tải lại trang để xem bản mới nhất."
- **E2. Đơn vị mới không có (bước 2).** ERR-12-004 (422); "Đơn vị {mã} không tồn tại hoặc đã hết hiệu lực."
- **E3. Sửa trường nguồn LDAP (bước 1).** ERR-12-047 (422); "Trường này do danh bạ LDAP của tỉnh quản lý; sửa ở danh bạ rồi đồng bộ."
- **E4. Tài khoản đã vô hiệu (bước 1).** ERR-12-006 (409); "Tài khoản đã bị vô hiệu. Kích hoạt lại trước khi sửa."
- **E5. Dữ liệu sai lược đồ (bước 2).** ERR-12-003 (400), lỗi theo từng trường.
- **E6. Mai tự đổi vai trò, đơn vị của mình (bước 4).** ERR-12-013 (403); "Anh/chị không thể tự thực hiện thao tác này với tài khoản của mình." (LP-12-04)

**Quy tắc áp dụng.** BR-12-033, 036, 037, 041.

**Màn hình, API.** UI-12-02, 03; API-12-004.
:::

### 6.4. UC-12-04 · Khóa, mở khóa, vô hiệu và kích hoạt lại tài khoản

::: dac-ta
**Mục tiêu.** Khi nghi ngờ lộ tài khoản hoặc cán bộ nghỉ việc, TA hoặc SO chặn ngay tài khoản; khi cần, mở lại hoặc kích hoạt lại có kiểm soát. Tài khoản không bao giờ bị xóa vật lý.

**Tác nhân chính.** ROLE-TENANT_ADMIN (Mai); ROLE-SECURITY_OFFICER (Dũng).

**Tác nhân phụ.** Keycloak, APISIX (nhận danh sách chặn), dịch vụ thư.

**Mức ưu tiên.** M.

**FR hiện thực.** FR-12-005.

**Truy vết.** REQ-12; LGC-IAM-005; SEC-27, SEC-29.

**Tiền điều kiện.** Người thao tác có `PERM-12-user-lock`; chuyển trạng thái hợp lệ theo máy trạng thái tài khoản (FRS mục 4.3); người thao tác khác chủ tài khoản.

**Kích hoạt.** Người dùng chọn "Khóa", "Mở khóa", "Vô hiệu" hoặc "Kích hoạt lại" ở UI-12-02 hoặc UI-12-03.

**Đảm bảo tối thiểu.** Không tự thao tác trên mình; không để tỉnh hết quản trị tỉnh; thất bại thì trạng thái cũ giữ nguyên.

**Đảm bảo thành công.** Tài khoản ở trạng thái mới; với khóa, vô hiệu thì phiên, refresh token bị hủy và cổng từ chối token cũ không quá 60 giây (qua UC-12-28).

**Luồng chính.**

1. Dũng mở UI-12-02 của `nguyenvana`, bấm "Vô hiệu", nhập lý do "Nghỉ việc theo quyết định 123/QĐ-STP" trong hộp xác nhận (FR-00-050).
2. Nếu thao tác nhạy cảm, hệ thống yêu cầu xác thực lại bước lên (LP-12-03); Dũng xác nhận.
3. Hệ thống gọi API-12-007; kiểm tra Dũng khác chủ tài khoản, lý do đủ 10 ký tự, chuyển `ACTIVE` sang `DISABLED` hợp lệ, và không phải quản trị tỉnh cuối cùng.
4. Hệ thống đặt trạng thái ở Keycloak, hủy mọi phiên, thu hồi refresh token và đẩy mục danh sách chặn theo `sub` (UC-12-28).
5. Hệ thống ghi kiểm toán kèm lý do, phát EVT-12-02 và EVT-12-05, trả `200`.
6. Sau đó, khi cán bộ quay lại làm việc, Mai bấm "Kích hoạt lại" (API-12-008); hệ thống đặt `PENDING_ACTIVATION`, buộc đặt mật khẩu mới và đăng ký lại yếu tố thứ hai nếu thuộc nhóm bắt buộc, gửi liên kết (tiếp UC-12-02 bước 6).

**Luồng thay thế.**

- **1a. Mở khóa tài khoản `LOCKED`, `BLOCKED`.** Mai bấm "Mở khóa" (API-12-006); hệ thống xóa bộ đếm sai và bộ đếm khóa tạm 24 giờ, tài khoản về `ACTIVE`.
- **1b. Khóa tạm thủ công.** Dũng chọn "Khóa" (API-12-005) khi cần chặn gấp nhưng chưa quyết định vô hiệu.
- **3a. Tài khoản thuộc nhóm `_ADMIN`.** Chỉ SO hoặc quản trị cấp trên thực hiện được; TA không khóa được TA khác cùng cấp.

**Luồng ngoại lệ.**

- **E1. Tự thao tác (bước 3).** ERR-12-013 (403); "Anh/chị không thể tự khóa hoặc vô hiệu tài khoản của mình."
- **E2. Thiếu lý do (bước 1).** ERR-12-014 (400); "Nhập lý do (ít nhất 10 ký tự)."
- **E3. Chuyển trạng thái sai (bước 3).** ERR-12-006 (409); "Tài khoản đang ở trạng thái {trạng thái}, không thực hiện được thao tác này."
- **E4. Vô hiệu quản trị tỉnh cuối cùng (bước 3).** ERR-12-046 (409); "Tỉnh phải còn ít nhất một quản trị tỉnh đang hoạt động."
- **E5. Chưa xác thực bước lên (bước 2).** ERR-12-120 (401); "Cần xác thực lại để thực hiện thao tác này."

**Quy tắc áp dụng.** BR-12-014, 028, 033, 035.

**Màn hình, API.** UI-12-02, 03; API-12-005, 006, 007, 008.
:::

### 6.5. UC-12-05 · Nhập người dùng hàng loạt từ tệp

::: dac-ta
**Mục tiêu.** Khi chuyển từ hệ cũ sang Datahub hoặc khi tỉnh thêm một sở mới, TA tạo hàng trăm tài khoản một lượt, đúng vai trò chuẩn, kiểm tra được trước khi ghi, không có mật khẩu đi qua tệp.

**Tác nhân chính.** ROLE-TENANT_ADMIN (Mai).

**Tác nhân phụ.** Bộ quét mã độc (DD-12), Keycloak, PH-07, dịch vụ thư.

**Mức ưu tiên.** M.

**FR hiện thực.** FR-12-009.

**Truy vết.** REQ-12; LGC-IAM-002; FR-00-032, FR-00-090; BP-09.

**Tiền điều kiện.** Mai có `PERM-12-user-admin`; `T68` đã có danh mục đơn vị ở PH-07; bảng ánh xạ vai trò hệ cũ đã khai báo hoặc dùng bảng mặc định (FRS mục 11.3).

**Kích hoạt.** Mai bấm "Nhập từ tệp" ở UI-12-01 và mở UI-12-04.

**Đảm bảo tối thiểu.** Pha xem trước không ghi gì vào Keycloak; tệp nhập xóa sau 24 giờ; không dòng nào được gán cặp vai trò xung đột.

**Đảm bảo thành công.** Các dòng hợp lệ thành tài khoản `PENDING_ACTIVATION` đúng vai trò chuẩn; báo cáo và tệp lỗi có sẵn.

**Luồng chính.**

1. Mai tải tệp mẫu rồi tải lên tệp `nguoi-dung-t68.xlsx` (320 dòng). Hệ thống gọi API-12-010 (pha 1), quét mã độc, kiểm tra định dạng, trả `202` kèm `importId`; giao diện theo dõi tác vụ.
2. Hệ thống kiểm tra từng dòng như UC-12-02: tên đăng nhập, thư, đơn vị, miền thư, trùng trong tệp và trong realm.
3. Hệ thống ánh xạ cột `legacyRoles` sang vai trò chuẩn theo bảng ánh xạ; kiểm tra từng tổ hợp vai trò theo cặp xung đột, đánh dấu dòng "cần ngoại lệ" và không gán vai trò xung đột.
4. Mai gọi API-12-011 ở UI-12-04 và xem bản xem trước: 312 dòng hợp lệ, 5 cảnh báo, 3 lỗi theo dòng.
5. Mai chọn "Bỏ qua dòng lỗi" rồi bấm "Xác nhận". Hệ thống gọi API-12-012 (pha 2), tạo tài khoản theo lô 100 dòng ở `PENDING_ACTIVATION`, gán vai trò, gửi liên kết kích hoạt.
6. Hệ thống phát EVT-12-01 và EVT-12-03 cho từng tài khoản, trả báo cáo (tạo được, bỏ qua, lỗi) và tệp lỗi để Mai sửa, tải lại.

**Luồng thay thế.**

- **4a. Chỉ kiểm tra.** Mai dừng ở bước 4 và bỏ phiên nhập; không có gì được tạo.
- **2a. Tenant có LDAP.** Cột `authSource` nhận `LDAP`; bỏ liên kết kích hoạt, tài khoản xác thực bằng mật khẩu LDAP.
- **5a. Sửa rồi nhập lại.** Mai sửa 3 dòng lỗi, tải tệp chỉ gồm các dòng đó và chạy lại từ bước 1.

**Luồng ngoại lệ.**

- **E1. Tệp sai định dạng hoặc quá lớn (bước 1).** ERR-12-035 (400, 413 khi quá lớn); "Tệp không đúng mẫu hoặc quá 5.000 dòng."
- **E2. Vai trò cũ chưa có ánh xạ (bước 3).** ERR-12-036 (422); "Dòng {n}: vai trò {tên} chưa có ánh xạ. Thêm vào bảng ánh xạ hoặc bỏ cột này."
- **E3. Bộ quét mã độc không khả dụng (bước 1).** ERR-12-040 (503); "Chưa kiểm tra được tệp. Thử lại sau."; không nhận tệp.
- **E4. Phiên nhập quá 24 giờ chưa xác nhận (bước 5).** Phiên tự hủy; "Phiên nhập đã hết hạn. Tải tệp lại."
- **E5. Keycloak lỗi giữa chừng (bước 5).** ERR-12-038 (503); các lô đã tạo giữ nguyên, báo cáo ghi lô lỗi; Mai chạy lại lô còn thiếu (thao tác idempotent theo tên đăng nhập).

**Quy tắc áp dụng.** BR-12-030, 043, 045.

**Màn hình, API.** UI-12-04; API-12-010, 011, 012.
:::

### 6.6. UC-12-06 · Đặt lại mật khẩu khi quên

::: dac-ta
**Mục tiêu.** Cán bộ quên mật khẩu tự đặt lại bằng thư công vụ mà không ai biết tài khoản có tồn tại hay không, và mọi phiên cũ bị đăng xuất.

**Tác nhân chính.** Cán bộ `nguyenvana` (không cần `PERM`).

**Tác nhân phụ.** Keycloak, dịch vụ thư.

**Mức ưu tiên.** M.

**FR hiện thực.** FR-12-007.

**Truy vết.** REQ-12; LGC-IAM-002; SEC-22.

**Tiền điều kiện.** Tenant cho phép đặt lại tự phục vụ (tham số `12.password.self-reset`, mặc định bật); tài khoản `authSource=LOCAL`.

**Kích hoạt.** Cán bộ bấm "Quên mật khẩu" ở trang đăng nhập (UI-12-18).

**Đảm bảo tối thiểu.** Thông báo và thời gian phản hồi giống nhau cho tài khoản có và không tồn tại (BR-12-017); không ghi mật khẩu vào log (BR-12-045).

**Đảm bảo thành công.** Mật khẩu mới có hiệu lực; mọi phiên và refresh token cũ bị hủy; cán bộ nhận thư báo đổi mật khẩu; EVT-12-04 đã phát.

**Luồng chính.**

1. `nguyenvana` nhập tên đăng nhập và bấm "Gửi liên kết". Keycloak luôn hiện cùng một câu: "Nếu tài khoản tồn tại, chúng tôi đã gửi hướng dẫn tới thư điện tử đăng ký."
2. Nếu tài khoản `ACTIVE` và có thư công vụ, hệ thống gửi liên kết đặt lại dùng một lần, hiệu lực 30 phút; ghi EVT-12-16 cho yêu cầu.
3. Cán bộ mở liên kết; với tài khoản thuộc nhóm `mfa-required`, Keycloak yêu cầu yếu tố thứ hai trước khi cho đặt.
4. Cán bộ nhập mật khẩu mới theo chính sách (14 đến 128 ký tự, không trùng 5 mật khẩu gần nhất, không trùng danh sách đã lộ).
5. Keycloak lưu bản băm, thu hồi mọi phiên và refresh token, gửi thư "Mật khẩu của bạn vừa được đổi", phát EVT-12-04 và chuyển về trang đăng nhập.

**Luồng thay thế.**

- **2a. Tài khoản `LOCKED`, `BLOCKED`, `DISABLED` hoặc không tồn tại.** Không gửi liên kết, vẫn hiện câu chung ở bước 1; cán bộ liên hệ quản trị tỉnh (UC-12-04).
- **2b. Tài khoản `authSource=LDAP`.** Câu chung, không gửi liên kết; việc đổi mật khẩu thực hiện ở danh bạ LDAP của tỉnh.

**Luồng ngoại lệ.**

- **E1. Liên kết hết hạn (bước 3).** ERR-12-016 (410); "Liên kết đã hết hạn hoặc đã được dùng. Liên hệ quản trị tỉnh để được gửi liên kết mới."
- **E2. Mật khẩu không đạt (bước 4).** ERR-12-015 (422); "Mật khẩu cần ít nhất 14 ký tự, không trùng mật khẩu đã bị lộ và không chứa tên đăng nhập."
- **E3. Vượt 5 yêu cầu mỗi giờ cho một địa chỉ hoặc một tài khoản (bước 1).** ERR-12-037 (429); "Thao tác quá nhiều lần. Thử lại sau {n} phút."

**Quy tắc áp dụng.** BR-12-017, 018, 045.

**Màn hình, API.** UI-12-18 (trang của Keycloak); luồng chuẩn Keycloak, không có API quản trị.
:::

### 6.7. UC-12-07 · Tác vụ định kỳ: tự vô hiệu tài khoản, tạm ngừng client, đồng bộ đơn vị

::: dac-ta
**Mục tiêu.** Hệ thống tự dọn tài khoản người dùng không đăng nhập và client HTTT không gọi quá ngưỡng, và giữ thuộc tính đơn vị của người dùng khớp danh mục, để quản trị tỉnh không phải nhớ làm.

**Tác nhân chính.** Hệ thống (tác vụ định kỳ, tài khoản dịch vụ của `dh-platform`).

**Tác nhân phụ.** Keycloak, PH-07 (danh mục đơn vị), TA, SO và đầu mối kỹ thuật HTTT (nhận thông báo).

**Mức ưu tiên.** M (FR-12-008), S (FR-12-010).

**FR hiện thực.** FR-12-008, 010.

**Truy vết.** REQ-12; REQ-07; SEC-27; CMP-LAW-08; ADR-055.

**Tiền điều kiện.** Tenant `T68` ở trạng thái `ACTIVE`.

**Kích hoạt.** Đồng hồ hằng ngày 01:00 (tự vô hiệu) và 02:00 (đồng bộ đơn vị), hoặc sự kiện thay đổi danh mục đơn vị của PH-07.

**Đảm bảo tối thiểu.** Không vô hiệu theo suy đoán: không đọc được thời điểm đăng nhập cuối thì bỏ qua và ghi cảnh báo; thao tác idempotent, chạy lại không gây hại.

**Đảm bảo thành công.** Tài khoản không dùng quá ngưỡng bị `DISABLED` không quá 24 giờ sau ngưỡng; client không gọi 90 ngày bị `SUSPENDED`; thuộc tính đơn vị khớp danh mục.

**Luồng chính.**

1. Lúc 01:00 tác vụ liệt kê người dùng `ACTIVE` có đăng nhập cuối cũ hơn 45 ngày (30 ngày với vai trò `_ADMIN` và vai trò nền tảng) và client `ENABLED` có lần gọi cuối cũ hơn 90 ngày.
2. Bảy ngày trước ngưỡng, hệ thống gửi cảnh báo tới cán bộ và TA: "Tài khoản sẽ bị vô hiệu vào {ngày} nếu không đăng nhập".
3. Với người dùng vượt ngưỡng, hệ thống chuyển `DISABLED` như UC-12-04 (lý do hệ thống `INACTIVE_45_DAYS`); với client vượt ngưỡng, chuyển `SUSPENDED` như UC-12-23.
4. Hệ thống gửi thông báo tới TA và đầu mối kỹ thuật của HTTT, ghi kiểm toán, tăng chỉ số `iam_inactive_disabled_total`, phát EVT-12-02, EVT-12-07, EVT-12-05.
5. Lúc 02:00 hệ thống đọc danh mục đơn vị hiện hành và lịch sử kế thừa từ PH-07, đối chiếu `orgCode` từng người dùng: còn hiệu lực thì cập nhật tên đơn vị, cấp hành chính, cây nhóm; đơn vị đã sáp nhập thì ánh xạ sang đơn vị kế thừa, kèm vai trò phạm vi `ORG`.
6. Người dùng có đơn vị không còn và không có đơn vị kế thừa được đưa vào danh sách "cần rà soát"; hệ thống không tự đổi vai trò, phát EVT-12-02 cho người đổi đơn vị, gửi báo cáo lượt chạy cho TA ở UI-12-07 và UI-12-15.

**Luồng thay thế.**

- **1a. Quyền có thời hạn còn hiệu lực.** Tài khoản đang giữ quyền có thời hạn (UC-12-13) được bỏ qua lượt này.
- **1b. Tenant siết ngưỡng trong miền cho phép.** Ngưỡng mới áp dụng từ lượt chạy kế tiếp.
- **5a. Đơn vị chia tách thành nhiều đơn vị.** Không tự chuyển; đưa người dùng vào danh sách "cần rà soát" để TA chọn (UC-12-03).

**Luồng ngoại lệ.**

- **E1. Keycloak không phản hồi giữa chừng (bước 1 đến 4).** Dừng lượt, ghi cảnh báo, chạy lại sau 1 giờ; thao tác đã làm không hoàn tác. Người vận hành thấy cảnh báo ở UI-12-15.
- **E2. Không đọc được thời điểm đăng nhập cuối (bước 1).** Bỏ qua tài khoản đó và ghi cảnh báo.
- **E3. PH-07 không khả dụng (bước 5).** ERR-12-040 (503) ghi nhật ký; dùng bản đệm gần nhất; UI-12-07 hiện "Danh mục đơn vị chưa cập nhật được từ {thời điểm}".
- **E4. Người dùng vừa được sửa ở UC-12-03 (bước 5).** Bỏ qua người đó trong lượt này để tránh ghi đè.

**Quy tắc áp dụng.** BR-12-020, 035, 037, 041.

**Màn hình, API.** UI-12-07, 15; tác vụ nội bộ, không có API công khai.
:::

### 6.8. UC-12-08 · Xem vai trò chuẩn và quyền hiệu lực

::: dac-ta
**Mục tiêu.** Cán bộ ATTT, quản trị tỉnh và kiểm toán viên biết một vai trò mở ra những quyền gì và một cán bộ cụ thể đang thực sự có những quyền gì, đối chiếu được với ma trận D02-08.

**Tác nhân chính.** ROLE-SECURITY_OFFICER (Dũng); ROLE-TENANT_ADMIN (Mai); ROLE-AUDITOR (Kiên).

**Tác nhân phụ.** OPA (truy vấn đánh giá quyền trên gói hiện hành), bộ ghi chính sách (dữ liệu vai trò–quyền).

**Mức ưu tiên.** M.

**FR hiện thực.** FR-12-011, 016.

**Truy vết.** REQ-12; LGC-IAM-002; D02-08 §2, §3; SEC-27.

**Tiền điều kiện.** `PERM-12-read`; tenant `T68` đã khởi tạo xong (vai trò chuẩn đã có); gói chính sách hiện hành đã nạp.

**Kích hoạt.** Dũng mở "Vai trò và quyền" ở UI-12-05, hoặc tab "Quyền hiệu lực" ở UI-12-02.

**Đảm bảo tối thiểu.** Không thay đổi dữ liệu; kết quả tính bằng đúng logic lúc thực thi (cùng gói OPA) nên không lệch với quyết định thật.

**Đảm bảo thành công.** Người xem thấy bảng vai trò, quyền theo phân hệ và danh sách quyền hiệu lực kèm nguồn gốc và hạn.

**Luồng chính.**

1. Dũng mở UI-12-05. Hệ thống gọi API-12-019 và API-12-021, hiện 22 vai trò chuẩn (vai trò `PLATFORM_*` chỉ ở tenant `PLATFORM`) cùng vai trò tùy biến đã duyệt, kèm phạm vi, cờ MFA, số người đang giữ.
2. Dũng chọn `ROLE-INTEGRATION_APPROVER`. Hệ thống gọi API-12-020, hiện danh sách quyền theo phân hệ.
3. Dũng chọn quyền `PERM-05-approve` ở bảng quyền. Hệ thống trả danh sách vai trò mang quyền đó (tra ngược).
4. Dũng mở tab "Quyền hiệu lực" của `nguyenvana` ở UI-12-02. Hệ thống gọi API-12-013: lấy mọi bản gán đang hiệu lực tại thời điểm `at` (mặc định bây giờ), gồm vai trò thường, ngoại lệ và quyền có thời hạn.
5. Hệ thống hỏi OPA để tính tập quyền và phạm vi bằng cùng luật lúc thực thi (BR-12-001, 002), rồi trả từng quyền kèm phạm vi, nguồn gốc (vai trò, bản gán, quyền có thời hạn), hiệu lực tới khi nào và điều kiện bổ sung (cần mức xác thực 2, cần lý do).
6. Dũng thấy bảng quyền hiệu lực của `nguyenvana`, đối chiếu với D02-08.

**Luồng thay thế.**

- **1a. Xuất ma trận.** Dũng xuất bảng vai trò × quyền ra CSV theo FR-00-030 để dùng khi rà soát.
- **4a. Hỏi ngược theo quyền.** Dũng nhập quyền `PERM-12-policy-approve` ở API-12-025 và nhận danh sách người có quyền đó trong phạm vi hỏi, có phân trang.
- **5a. Giải thích.** Dũng bật "Giải thích" cho một quyền: hệ thống hiện chuỗi lý do (vai trò nào, luật nào cho phép, luật từ chối nào đã bỏ qua).
- **5b. Xem thời điểm khác.** Dũng chọn `at` trong tương lai để biết quyền nào hết hạn.

**Luồng ngoại lệ.**

- **E1. Không tìm thấy vai trò hoặc người dùng (bước 2 hoặc 4).** ERR-12-001 (404); "Không tìm thấy vai trò này." hoặc "Không tìm thấy người dùng này."
- **E2. Dữ liệu ma trận hoặc OPA chưa sẵn sàng (bước 1 hoặc 5).** ERR-12-040 (503); "Danh mục vai trò chưa sẵn sàng. Thử lại sau ít phút." hoặc "Chưa tính được quyền hiệu lực. Thử lại sau."
- **E3. Người xem không có `PERM-12-read` ở tenant của người dùng.** ERR-12-007 (403); "Bạn không có quyền thực hiện thao tác này. Liên hệ quản trị tỉnh nếu cần được cấp quyền."

**Quy tắc áp dụng.** BR-12-001, 002, 031, 041.

**Màn hình, API.** UI-12-02, 05; API-12-013, 019, 020, 021, 025.
:::

### 6.9. UC-12-09 · Gán và gỡ vai trò cho người dùng

::: dac-ta
**Mục tiêu.** Quản trị tỉnh gán cho cán bộ đúng vai trò, đúng phạm vi và hạn, hệ thống tự chặn các gán sai (vai trò nền tảng ở tỉnh, cặp xung đột, phạm vi ngoài đơn vị) và quyền thu hẹp có hiệu lực trong 60 giây.

**Tác nhân chính.** ROLE-TENANT_ADMIN (Mai).

**Tác nhân phụ.** Keycloak, bộ ghi chính sách (UC-12-33), OPA.

**Mức ưu tiên.** M.

**FR hiện thực.** FR-12-012.

**Truy vết.** REQ-12; LGC-IAM-002; LGC-BUS-032; D02-08 §2.

**Tiền điều kiện.** Mai có `PERM-12-user-admin` và đã xác thực mức 2 trong 5 phút (LP-12-03); người được gán `ACTIVE` hoặc `PENDING_ACTIVATION`; vai trò tồn tại.

**Kích hoạt.** Mai bấm "Gán vai trò" ở UI-12-02 hoặc UI-12-06; hoặc UC-12-02, UC-12-05 gọi khi tạo.

**Đảm bảo tối thiểu.** Không ai tự gán, gỡ vai trò của mình; mỗi tenant luôn còn ít nhất một quản trị tỉnh; thất bại thì không gán gì.

**Đảm bảo thành công.** Bản gán lưu kèm phạm vi, hiệu lực; dữ liệu gói chính sách yêu cầu tái sinh; EVT-12-03 đã phát.

**Luồng chính.**

1. Mai mở UI-12-06 cho `nguyenvana`, chọn vai trò `ROLE-INTEGRATION_ENGINEER`, phạm vi `ORG` = `SKHCN`, hiệu lực từ hôm nay, nhập lý do "Điều chuyển sang Sở KH&CN", bấm "Gán".
2. Hệ thống gọi API-12-026; kiểm tra Mai khác người được gán và lý do không rỗng.
3. Hệ thống kiểm tra vai trò gán được cho người: vai trò `PLATFORM_*` chỉ ở tenant `PLATFORM`, `PARTNER_SYSTEM` chỉ gán cho client.
4. Hệ thống kiểm tra phạm vi: vai trò phạm vi tổ chức phải có `scopeType=ORG` và đơn vị là đơn vị của người dùng hoặc cấp trên của đơn vị đó; phạm vi `WORKSPACE` phải là không gian có thật ở PH-04.
5. Hệ thống chạy kiểm tra cặp xung đột (UC-12-10 nếu vướng) với mọi vai trò đang hiệu lực của người đó, gồm cả quyền có thời hạn.
6. Hệ thống lưu bản gán, cập nhật vai trò ở Keycloak, yêu cầu tái sinh dữ liệu gói (UC-12-33), ghi kiểm toán, phát EVT-12-03, trả `201`.
7. Vai trò thuộc nhóm `mfa-required` thì hệ thống đặt cờ buộc `nguyenvana` đăng ký yếu tố thứ hai ở lần đăng nhập kế tiếp (UC-12-17).

**Luồng thay thế.**

- **1a. Gỡ vai trò.** Mai chọn "Gỡ" (API-12-027); bước 3 đến 5 bỏ qua; hệ thống kiểm tra không gỡ quản trị tỉnh cuối cùng và thu hồi mọi phiên của người dùng nếu là hạ quyền (BR-12-036).
- **1b. Gán có hiệu lực từ ngày sau, hoặc có hạn.** Bản gán chỉ sinh hiệu lực trong khoảng `validFrom` đến `validTo`; hết hạn tự gỡ.
- **2a. Xem danh sách bản gán.** Mai lọc bản gán theo người, vai trò, phạm vi (API-12-025) ở UI-12-02.

**Luồng ngoại lệ.**

- **E1. Tự gán hoặc gỡ cho chính mình (bước 2).** ERR-12-013 (403); "Anh/chị không thể tự gán hoặc gỡ vai trò của mình."
- **E2. Vai trò hoặc phạm vi sai (bước 3, 4).** ERR-12-010 (422); "Vai trò {vai trò} không gán được với phạm vi {phạm vi} cho người dùng này."
- **E3. Xung đột tách nhiệm vụ (bước 5).** ERR-12-009 (409); "Anh/chị không được giữ cùng lúc {vai trò A} và {vai trò B}: {lý do}. Có thể đề nghị ngoại lệ có thời hạn." Mai có thể chuyển sang UC-12-10.
- **E4. Gỡ quản trị tỉnh cuối cùng (bước 1a).** ERR-12-046 (409); "Tỉnh phải còn ít nhất một quản trị tỉnh đang hoạt động."
- **E5. Thiếu lý do (bước 2).** ERR-12-014 (400); "Nhập lý do gán hoặc gỡ vai trò."
- **E6. Chưa xác thực bước lên (điều kiện).** ERR-12-120 (401); "Cần xác thực lại để thực hiện thao tác này."
- **E7. Vai trò hoặc người dùng không tồn tại, hoặc thuộc tenant khác (bước 1).** ERR-12-001 (404) theo LP-12-06; "Không tìm thấy đối tượng này trong tỉnh của anh/chị."

**Quy tắc áp dụng.** BR-12-030, 031, 033, 036, 037.

**Màn hình, API.** UI-12-02, 06; API-12-025, 026, 027.
:::

### 6.10. UC-12-10 · Đề nghị và duyệt ngoại lệ tách nhiệm vụ

::: dac-ta
**Mục tiêu.** Khi tỉnh thiếu nhân sự và buộc phải để một người giữ hai vai trò xung đột, ngoại lệ chỉ có sau khi cán bộ ATTT duyệt, có lý do, có hạn tối đa 90 ngày và tự gỡ khi hết hạn.

**Tác nhân chính.** ROLE-TENANT_ADMIN (Mai) đề nghị; ROLE-SECURITY_OFFICER (Dũng) duyệt.

**Tác nhân phụ.** Hộp "Việc của tôi" (FR-00-070), PH-13, OPA.

**Mức ưu tiên.** M.

**FR hiện thực.** FR-12-013.

**Truy vết.** REQ-12; D02-08 §4; SEC-27; FR-00-071; ADR-046.

**Tiền điều kiện.** Mai có `PERM-12-sod-exception`, Dũng có `PERM-12-approve`; bảng bảy cặp xung đột đã nạp vào gói chính sách; có một lần gán bị chặn bởi ERR-12-009 hoặc Mai mở "Đề nghị ngoại lệ".

**Kích hoạt.** UC-12-09 phát hiện xung đột ở bước 5; hoặc Mai mở "Đề nghị ngoại lệ" ở UI-12-06.

**Đảm bảo tối thiểu.** Không có ngoại lệ nào hiệu lực mà thiếu người duyệt thứ hai; cặp có AUDITOR đối với quyền ghi của PH-19 không bao giờ có ngoại lệ.

**Đảm bảo thành công.** Ngoại lệ `ACTIVE` kèm bản gán; hẹn giờ tự gỡ vai trò phải gỡ khi hết hạn; EVT-12-12 và EVT-12-03 đã phát.

**Luồng chính.**

1. Mai gán `ROLE-INTEGRATION_ENGINEER` cho `nguyenvana`, người đang giữ `ROLE-INTEGRATION_APPROVER`; hệ thống từ chối bước gán, hiện cặp xung đột kèm lý do (ERR-12-009).
2. Mai chọn "Đề nghị ngoại lệ" ở UI-12-06, nhập lý do (từ 20 ký tự) "Sở KH&CN chỉ còn một cán bộ tích hợp trong 60 ngày", vai trò phải gỡ khi hết hạn và thời hạn 60 ngày. Hệ thống gọi API-12-029.
3. Hệ thống kiểm tra thời hạn không quá 90 ngày, tạo ngoại lệ `REQUESTED`, đưa việc vào hộp "Việc của tôi" của các SO của `T68`.
4. Dũng mở việc ở UI-12-17 và xem cặp vai trò, lý do, thời hạn, bản gán đang chờ. Hệ thống yêu cầu Dũng xác thực lại bước lên (LP-12-03).
5. Dũng bấm "Duyệt" và nhập ý kiến. Hệ thống gọi API-12-030, kiểm tra bốn mắt (LP-12-01): Dũng khác Mai và khác `nguyenvana`.
6. Hệ thống đặt ngoại lệ `ACTIVE`, thực hiện việc gán đang chờ, đặt hẹn giờ tự gỡ khi hết hạn; ghi kiểm toán, phát EVT-12-12 và EVT-12-03; thông báo cho Mai và cho `nguyenvana`.
7. Khi hết 60 ngày, hệ thống tự gỡ vai trò phải gỡ và thu hồi phiên của người đó.

**Luồng thay thế.**

- **5a. Dũng từ chối.** Dũng nhập ý kiến; API-12-030 đặt `REJECTED`; việc gán không thực hiện; Mai nhận ý kiến.
- **3a. Mai rút đề nghị.** Trước khi duyệt, ngoại lệ chuyển `CANCELLED`.
- **7a. Dũng thu hồi sớm.** Dũng gọi API-12-031 (kèm lý do, LP-12-02); hệ thống gỡ vai trò ngay, ngoại lệ `REVOKED`.

**Luồng ngoại lệ.**

- **E1. Người duyệt trùng người đề nghị hoặc người được gán (bước 5).** ERR-12-008 (403); "Anh/chị là người đề nghị hoặc người được gán nên không được duyệt ngoại lệ này." Nút "Duyệt" bị khóa kèm giải thích.
- **E2. Thời hạn vượt tối đa (bước 2).** ERR-12-043 (422); "Thời hạn ngoại lệ tối đa {n} ngày."
- **E3. Cặp không được cấp ngoại lệ (bước 2).** ERR-12-009 (409); "Cặp vai trò này không được cấp ngoại lệ."
- **E4. Thiếu lý do (bước 2).** ERR-12-014 (400); "Nhập lý do đề nghị ngoại lệ (ít nhất 20 ký tự)."
- **E5. Chưa xác thực bước lên (bước 4).** ERR-12-120 (401); "Cần xác thực lại để thực hiện thao tác này."

**Quy tắc áp dụng.** BR-12-030, 033; bốn mắt theo FR-00-071.

**Màn hình, API.** UI-12-06, 17; API-12-028, 029, 030, 031.
:::

### 6.11. UC-12-11 · Quản lý nhóm và đơn vị tổ chức

::: dac-ta
**Mục tiêu.** Quản trị tỉnh có cây đơn vị khớp danh mục PH-07 và các nhóm công việc riêng, để phạm vi của vai trò theo tổ chức được tính đúng.

**Tác nhân chính.** ROLE-TENANT_ADMIN (Mai).

**Tác nhân phụ.** PH-07 (cây đơn vị), Keycloak.

**Mức ưu tiên.** M.

**FR hiện thực.** FR-12-014.

**Truy vết.** REQ-12; LGC-IAM-002; LGC-BUS-032.

**Tiền điều kiện.** Mai có `PERM-12-user-admin`; cây đơn vị của `T68` đã nạp từ PH-07 (UC-12-07).

**Kích hoạt.** Mai mở "Nhóm và đơn vị" ở UI-12-07.

**Đảm bảo tối thiểu.** Không tạo vòng lặp nhóm; không xóa nhóm còn thành viên; nhóm `ORG` không bị sửa tay.

**Đảm bảo thành công.** Nhóm lưu ở Keycloak và `ph12_iam`; phạm vi tổ chức kế thừa xuống nhóm con.

**Luồng chính.**

1. Mai mở UI-12-07. Hệ thống gọi API-12-032 và hiện cây: nhóm loại `ORG` là bản chiếu cây đơn vị của PH-07 (chỉ đọc), nhóm loại `CUSTOM` do TA tạo.
2. Mai bấm "+ Nhóm", nhập mã `to-tich-hop`, tên "Tổ tích hợp liên sở", chọn nhóm cha `SKHCN`. Hệ thống gọi API-12-033.
3. Hệ thống kiểm tra mã chưa dùng và nhóm cha không tạo vòng lặp.
4. Hệ thống lưu nhóm ở Keycloak và `ph12_iam`; phạm vi tổ chức của vai trò kế thừa xuống nhóm con theo cây `ORG`.
5. Mai chọn nhóm vừa tạo, thêm ba thành viên và bấm "Lưu". Hệ thống gọi API-12-035 (đặt toàn bộ danh sách thành viên); nếu việc này làm đổi phạm vi tổ chức của ai thì phát EVT-12-03.

**Luồng thay thế.**

- **2a. Sửa nhóm.** Mai đổi tên hoặc nhóm cha qua API-12-034 kèm `If-Match` (LP-12-05).
- **5a. Chuyển hàng loạt thành viên.** Mai chọn "Chuyển thành viên" giữa hai nhóm `CUSTOM`.
- **1a. Đổi cây đơn vị.** Nhóm `ORG` không sửa ở đây; đổi cây ở PH-07 rồi chờ đồng bộ 02:00 (UC-12-07).
- **5b. Xóa nhóm.** Chỉ xóa được khi không còn thành viên hay vai trò phụ thuộc.

**Luồng ngoại lệ.**

- **E1. Vòng lặp nhóm (bước 3).** ERR-12-012 (422); "Nhóm cha này làm thành vòng lặp: {đường đi}."
- **E2. Mã nhóm đã dùng (bước 3).** ERR-12-002 (409); "Mã nhóm này đã được dùng. Chọn mã khác." (câu mới, ghi ở mục Đề nghị đồng bộ).
- **E3. Nhóm còn thành viên hoặc đang dùng (bước 5b).** ERR-12-011 (409); "Nhóm còn {n} thành viên. Chuyển hoặc gỡ họ trước khi xóa."
- **E4. Sửa nhóm `ORG` (bước 1a).** ERR-12-010 (422); "Nhóm đơn vị do danh mục đơn vị quản lý, không sửa ở đây."

**Quy tắc áp dụng.** BR-12-037, 039. Vai trò chỉ gán cho từng người, không gán cho nhóm (BR-12-039).

**Màn hình, API.** UI-12-07; API-12-032, 033, 034, 035.
:::

### 6.12. UC-12-12 · Tạo vai trò tùy biến của tenant

::: dac-ta
**Mục tiêu.** Tỉnh cần một vai trò đặc thù (ví dụ "Cán bộ tra cứu hồ sơ") thì dựng được từ các quyền không đặc quyền có sẵn, qua cùng quy trình duyệt bốn mắt như chính sách, mà không phải sửa mã Rego.

**Tác nhân chính.** ROLE-TENANT_ADMIN (Mai) đề nghị; ROLE-SECURITY_OFFICER (Dũng) duyệt.

**Tác nhân phụ.** Bộ ghi chính sách, OPA.

**Mức ưu tiên.** S (Đợt 2).

**FR hiện thực.** FR-12-015.

**Truy vết.** REQ-12; LGC-IAM-002; D02-08 §1; Q12-04.

**Tiền điều kiện.** Tenant bật tham số `12.role.custom-enabled` (mặc định tắt ở MVP); Mai có `PERM-12-user-admin`, Dũng có `PERM-12-policy-approve`.

**Kích hoạt.** Mai bấm "+ Vai trò tùy biến" ở UI-12-05.

**Đảm bảo tối thiểu.** Vai trò tùy biến không bao giờ mang quyền đặc quyền hay quyền ngoài phạm vi tenant; không phát hành khi thiếu bốn mắt.

**Đảm bảo thành công.** Vai trò `PUBLISHED` trong chính sách `custom-roles`, hiện ở danh mục và gán được.

**Luồng chính.**

1. Mai nhập mã `tra-cuu-ho-so`, tên "Cán bộ tra cứu hồ sơ", chọn các quyền từ danh mục (UC-12-08) rồi bấm "Lưu nháp". Hệ thống gọi API-12-022.
2. Hệ thống kiểm tra mã chưa dùng và quyền hợp lệ: không chứa quyền đặc quyền (mọi `approve`, `publish`, `admin`, `PERM-12-*`, `PERM-09-unmask`).
3. Hệ thống ghi vai trò vào dữ liệu của chính sách `custom-roles` ở trạng thái `DRAFT` và chạy các ca kiểm thử sinh sẵn (mỗi quyền một ca dương, một ca âm).
4. Mai gửi duyệt; luồng kiểm thử, chạy khô, duyệt bốn mắt, phát hành chạy theo UC-12-34 và UC-12-35 (Dũng duyệt).
5. Khi phát hành (EVT-12-09), vai trò xuất hiện ở danh mục và gán được theo UC-12-09; vai trò mang quyền `export` tự đặt `mfaRequired`.

**Luồng thay thế.**

- **1a. Sửa vai trò đã phát hành.** Mai gọi API-12-023, tạo phiên bản mới của chính sách `custom-roles`; việc gỡ quyền khỏi vai trò áp dụng cho mọi người giữ ngay khi phát hành.
- **1b. Ngừng dùng vai trò.** Mai gọi API-12-024 khi không còn người giữ.

**Luồng ngoại lệ.**

- **E1. Quyền đặc quyền (bước 2).** ERR-12-010 (422); "Vai trò tùy biến không được chứa quyền {quyền}."
- **E2. Mã trùng (bước 2).** ERR-12-002 (409); "Mã vai trò đã được dùng."
- **E3. Vai trò còn người giữ khi ngừng dùng (bước 1b).** ERR-12-011 (409); "Còn {n} người đang giữ vai trò này."
- **E4. Tính năng chưa bật (bước 1).** ERR-12-007 (403); "Tỉnh chưa bật vai trò tùy biến."

**Quy tắc áp dụng.** BR-12-007, 008, 009, 030.

**Màn hình, API.** UI-12-05; API-12-022, 023, 024.
:::

### 6.13. UC-12-13 · Cấp quyền có thời hạn và vào tenant khác

::: dac-ta
**Mục tiêu.** Nhân sự nền tảng cần vào một tỉnh để xử lý sự cố, hoặc cần một vai trò đặc quyền trong thời gian ngắn, chỉ làm được trong tối đa 4 giờ, có người duyệt thứ hai, và tỉnh bị truy cập luôn biết ai vào, vì sao.

**Tác nhân chính.** ROLE-PLATFORM_OPERATOR (Quân) đề nghị; ROLE-SECURITY_OFFICER (Dũng) duyệt.

**Tác nhân phụ.** ROLE-PLATFORM_ADMIN (Hà, người duyệt thay thế), ROLE-TENANT_ADMIN của `T68` (nhận thông báo), Keycloak (nhà môi giới `dh-platform`), OPA.

**Mức ưu tiên.** M.

**FR hiện thực.** FR-12-017, 027.

**Truy vết.** REQ-12; REQ-20; SEC-28, SEC-80, SEC-85; FR-00-004, FR-00-012; CMP-LAW-06; Q12-01.

**Tiền điều kiện.** Quân có `PERM-12-jit-request`, có tài khoản ở realm `dh-platform` và đã xác thực mức 3 (WebAuthn) trong 5 phút; tenant đích `T68` `ACTIVE` hoặc `SUSPENDED`; người duyệt có `PERM-12-jit-approve`.

**Kích hoạt.** Quân bấm "Đề nghị quyền" ở UI-12-08; sau khi được duyệt, Quân đổi tenant sang `T68` trên giao diện (FR-00-004 bước 3).

**Đảm bảo tối thiểu.** Không quyền cao nào thường trực; không ai tự duyệt cho mình; quyền hết hạn tự gỡ kể cả khi không ai nhớ.

**Đảm bảo thành công.** Quyền `ACTIVE` trong đúng thời lượng; phiên ở `T68` mang `acr` 3, claim `grant` và `exp` không quá hạn quyền; mọi hành động ghi vào chuỗi kiểm toán của `T68`; EVT-12-11 đã phát.

**Luồng chính.**

1. Quân chọn loại `TENANT_ACCESS`, tenant đích `T68`, vai trò `ROLE-PLATFORM_OPERATOR`, thời lượng 2 giờ, nhập lý do "Điều tra Kafka đầy đĩa" và mã phiếu `HT-2026-1184`, bấm "Gửi". Hệ thống gọi API-12-036.
2. Hệ thống kiểm tra thời lượng không quá 4 giờ và có mã phiếu, tạo yêu cầu `REQUESTED`, đưa vào hộp việc của người có `PERM-12-jit-approve` (UI-12-17).
3. Dũng xác thực mức 3, xem lý do, phiếu, phạm vi rồi bấm "Duyệt". Hệ thống gọi API-12-038, kiểm tra bốn mắt (LP-12-01).
4. Hệ thống đặt quyền `ACTIVE` với `expiresAt` = bây giờ + 2 giờ, tạo bản gán tạm trong dữ liệu gói chính sách (hiệu lực không quá 60 giây).
5. Hệ thống ghi kiểm toán vào chuỗi của `T68`, gửi thông báo tới Mai (nội dung: ai, vì sao, tới khi nào, mã phiếu), phát EVT-12-11.
6. Quân đổi sang `T68`. BFF yêu cầu ủy quyền ở realm `dh-t68` với gợi ý nhà môi giới nền tảng; Keycloak chuyển tới `dh-platform`; Quân đã có phiên SSO nên không nhập lại mật khẩu nhưng `acr` phải đạt 3.
7. Khi nhà môi giới trả về, realm `dh-t68` kiểm tra quyền có thời hạn còn hiệu lực cho cặp (Quân, `T68`), tạo tài khoản môi giới tạm gắn đúng vai trò và hạn, cấp token có `tenant` = `T68`, `acr` 3, claim `grant`.
8. Khi hết 2 giờ (hoặc bị thu hồi), tác vụ chạy mỗi 30 giây gỡ quyền, thu hồi phiên liên tenant của Quân ở `T68`, đẩy danh sách chặn (UC-12-28) và xóa tài khoản môi giới; OPA cũng kiểm tra `expiresAt` ở mọi quyết định.

**Luồng thay thế.**

- **3a. Người duyệt từ chối.** Dũng nhập ý kiến; API-12-039; quyền `REJECTED`; Quân nhận ý kiến.
- **2a. Quân rút lại.** Trước khi duyệt, yêu cầu `CANCELLED`; yêu cầu quá hạn chờ duyệt cũng thành `CANCELLED`.
- **8a. Thu hồi sớm.** SO hoặc TA của `T68` bấm "Thu hồi" (API-12-040, kèm lý do, LP-12-02); phiên bị cắt ngay (UC-12-28), quyền `REVOKED`.
- **1a. Quyền đặc quyền cho chính tenant nền tảng.** Loại `PRIVILEGE`, tenant đích `PLATFORM`; luồng như trên, không có bước 6, 7.
- **6a. Nhà thầu không thuộc nền tảng.** Nhà môi giới không bật; nhà thầu đăng nhập riêng ở realm `dh-t68` bằng tài khoản của mình kèm yếu tố thứ hai, và phải đăng nhập lại khi đổi tenant (Q12-01).
- **6b. Tenant `T68` đang `SUSPENDED`.** Chỉ quản trị tỉnh vào chỉ-đọc; quyền của nhân sự nền tảng hợp lệ khi quyền có thời hạn ghi rõ.

**Luồng ngoại lệ.**

- **E1. Thời lượng vượt 4 giờ hoặc thiếu mã phiếu (bước 1).** ERR-12-030 (422); "Quyền có thời hạn tối đa 4 giờ và phải kèm mã phiếu hỗ trợ."
- **E2. Thiếu lý do (bước 1).** ERR-12-014 (400); "Nhập lý do (ít nhất 10 ký tự)."
- **E3. Người duyệt trùng người đề nghị (bước 3).** ERR-12-008 (403); "Anh/chị là người đề nghị nên không được tự duyệt."
- **E4. Người đề nghị chưa xác thực mức 3 (bước 1).** ERR-12-120 (401); "Cần xác thực lại bằng khóa bảo mật trước khi đề nghị."
- **E5. Tenant đích đã chấm dứt hoặc sáp nhập (bước 1).** ERR-12-041 (409); "Tỉnh này không còn nhận truy cập."
- **E6. Không có quyền có thời hạn khi đổi tenant (bước 7).** ERR-12-007 (403); "Anh/chị không có quyền truy cập tỉnh {tên}. Đề nghị quyền có thời hạn ở Quyền truy cập."
- **E7. Quyền hết hạn giữa phiên.** Lời gọi kế tiếp bị từ chối ERR-12-116 (401); "Quyền truy cập tỉnh {tên} đã hết hạn."
- **E8. Nhà môi giới `dh-platform` không khả dụng (bước 6).** ERR-12-038 (503); "Chưa đăng nhập được tỉnh {tên}: hệ thống xác thực nền tảng tạm thời không khả dụng."

**Quy tắc áp dụng.** BR-12-003, 004, 031, 032, 033.

**Màn hình, API.** UI-12-08, 17, 18; API-12-036, 037, 038, 039, 040, 073, 074.
:::

### 6.14. UC-12-14 · Rà soát quyền định kỳ

::: dac-ta
**Mục tiêu.** Mỗi quý, người quản lý trực tiếp xác nhận từng quyền của cấp dưới còn cần hay không, quyền thừa được gỡ, và có biên bản rà soát cho thanh tra.

**Tác nhân chính.** ROLE-TENANT_ADMIN (Mai) hoặc ROLE-SECURITY_OFFICER (Dũng) mở chiến dịch; Lộc (người quản lý trực tiếp) rà soát.

**Tác nhân phụ.** Hộp "Việc của tôi" (FR-00-070), PH-13.

**Mức ưu tiên.** S (Đợt 2).

**FR hiện thực.** FR-12-018.

**Truy vết.** REQ-12; SEC-27; CMP-LAW-08; Q12-08.

**Tiền điều kiện.** Mai hoặc Dũng có `PERM-12-recert`; mỗi người dùng trong phạm vi có `managerUserId` hoặc được gán người rà soát thay thế; chưa có chiến dịch mở cho cùng phạm vi.

**Kích hoạt.** Mai bấm "Mở chiến dịch" ở UI-12-09, hoặc lịch tự động theo `12.recert.interval-days.admin` (90 ngày) và `12.recert.interval-days.other` (180 ngày).

**Đảm bảo tối thiểu.** Không ai rà soát quyền của chính mình; bản gán không được xác nhận mới bị gỡ, và vai trò quản trị không bị gỡ tự động mà chuyển cảnh báo mức cao.

**Đảm bảo thành công.** Chiến dịch `CLOSED` kèm báo cáo; quyền thừa đã gỡ; EVT-12-15 và EVT-12-03 đã phát.

**Luồng chính.**

1. Mai chọn phạm vi đơn vị `STP`, hạn trả lời 14 ngày và bấm "Mở chiến dịch". Hệ thống gọi API-12-041.
2. Hệ thống tạo các mục rà soát, mỗi mục là một bản gán hiện hành (người dùng, vai trò, phạm vi), gán người rà soát là người quản lý trực tiếp; nếu người quản lý chính là người được rà soát, chuyển lên cấp trên.
3. Hệ thống gửi việc vào "Việc của tôi" của Lộc và nhắc ở các ngày 7, 3, 1 trước hạn.
4. Lộc mở UI-12-09, chọn "Giữ" hoặc "Gỡ" cho từng mục (có chọn hàng loạt, nhập lý do khi gỡ). Mỗi quyết định gọi API-12-043.
5. Quá hạn mà mục chưa được trả lời, hệ thống gỡ bản gán đó theo UC-12-09 và thông báo cho Mai và người được rà soát.
6. Khi mọi mục xong hoặc hết hạn, hệ thống đóng chiến dịch (API-12-044), sinh báo cáo (tỷ lệ giữ, gỡ, quá hạn, danh sách vai trò đặc quyền), phát EVT-12-15.

**Luồng thay thế.**

- **5a. Vai trò quản trị.** Bản gán `_ADMIN` hoặc vai trò nền tảng quá hạn không tự gỡ; chuyển cảnh báo mức cao cho Dũng (UC-12-39).
- **6a. Đóng sớm.** Mai đóng sớm: các mục chưa trả lời thành "chưa rà soát" mà không gỡ.
- **2a. Người rà soát không còn hoạt động.** Mục tự chuyển lên cấp trên và ghi cảnh báo, không lỗi hiển thị.
- **4a. Xem tiến độ.** Mai xem bảng mục rà soát và báo cáo chiến dịch qua API-12-042.

**Luồng ngoại lệ.**

- **E1. Đã có chiến dịch mở cho cùng phạm vi (bước 1).** ERR-12-031 (409); "Đang có chiến dịch rà soát cho phạm vi này."
- **E2. Người rà soát tự xác nhận quyền của mình (bước 4).** ERR-12-008 (403); "Anh/chị không được tự rà soát quyền của mình."
- **E3. Thiếu `PERM-12-recert` (bước 1).** ERR-12-007 (403) theo LP-12-06.

**Quy tắc áp dụng.** BR-12-033, 044.

**Màn hình, API.** UI-12-09, 17; API-12-041, 042, 043, 044.
:::

### 6.15. UC-12-15 · Chuyển định danh và vai trò khi sáp nhập tenant

::: dac-ta
**Mục tiêu.** Khi hai tỉnh sáp nhập, cán bộ của tỉnh nguồn đăng nhập được ở tỉnh đích với vai trò tương ứng, HTTT có thông tin xác thực mới chạy song song với cũ, và realm nguồn chuyển chỉ-đọc.

**Tác nhân chính.** PH-20 (scope `iam:realm-provision`).

**Tác nhân phụ.** ROLE-TENANT_ADMIN của tenant đích (xác nhận kế hoạch), Keycloak, PH-07, PH-01.

**Mức ưu tiên.** S (Đợt 2).

**FR hiện thực.** FR-12-019.

**Truy vết.** REQ-12; REQ-20; D03-10 §6; SEC-80; BP-09.

**Tiền điều kiện.** Quy trình sáp nhập của PH-20 đã tới bước "Chuyển định danh"; realm nguồn và realm đích đều `ACTIVE`.

**Kích hoạt.** PH-20 gọi API kế hoạch chuyển định danh rồi API thực hiện.

**Đảm bảo tối thiểu.** Thao tác idempotent; tài khoản không chuyển được ghi vào danh sách "chưa chuyển" kèm lý do, không làm hỏng cả lượt; vai trò xung đột không tự chuyển.

**Đảm bảo thành công.** Tài khoản và vai trò có ở realm đích; client mới cấp song song; realm nguồn `READ_ONLY`; kiểm toán ở cả hai tenant.

**Luồng chính.**

1. PH-20 gọi API-12-045 (lập kế hoạch). Hệ thống so tài khoản nguồn với realm đích theo thư điện tử và tên đăng nhập, phát hiện trùng.
2. Hệ thống sinh báo cáo kế hoạch: tài khoản chuyển được, tài khoản trùng (cùng thư thì gộp, khác người cùng tên đăng nhập thì thêm hậu tố), vai trò ánh xạ được, vai trò vi phạm tách nhiệm vụ.
3. TA tenant đích xem báo cáo ở UI-12-19 và xác nhận; vai trò xung đột vào danh sách cần ngoại lệ (UC-12-10).
4. PH-20 gọi API-12-046 (thực hiện). Hệ thống tạo tài khoản ở realm đích; cùng chính sách mật khẩu thì giữ băm mật khẩu và yếu tố thứ hai, nếu không thì buộc đặt lại; giữ liên kết LDAP/AD nếu cùng nguồn.
5. Hệ thống chuyển bản gán vai trò theo ánh xạ đơn vị; client của HTTT được cấp mới ở realm đích song song với client cũ trong thời gian chuyển tiếp (mặc định 6 tháng).
6. Khi PH-20 chuyển tenant nguồn sang `MERGED`, hệ thống đặt realm nguồn `READ_ONLY` (UC-12-30), ghi kiểm toán ở cả hai tenant, phát EVT-12-01, EVT-12-03, EVT-12-06, EVT-12-13.

**Luồng thay thế.**

- **1a. Chỉ chạy kế hoạch.** PH-20 dừng sau bước 2 để dự báo; không thực hiện.
- **4a. Thực hiện từng phần.** PH-20 chuyển theo từng đơn vị.

**Luồng ngoại lệ.**

- **E1. Realm đích không `ACTIVE` (bước 1).** ERR-12-041 (409); "Tỉnh đích chưa sẵn sàng nhận định danh."
- **E2. Keycloak hoặc PH-07 không khả dụng giữa chừng (bước 4).** ERR-12-038 hoặc ERR-12-040 (503); saga PH-20 dừng ở bước này và thử lại từ bước lỗi, thao tác đã làm không lặp.
- **E3. Một tài khoản không chuyển được (bước 4).** Ghi vào danh sách "chưa chuyển" kèm lý do; lượt chuyển vẫn tiếp tục.
- **E4. Thiếu quyền (bước 1).** ERR-12-007 (403) nếu bên gọi không có scope `iam:realm-provision`.

**Quy tắc áp dụng.** BR-12-004, 030, 037, 041.

**Màn hình, API.** UI-12-19; API-12-045, 046.
:::

### 6.16. UC-12-16 · Đăng nhập OIDC, chống dò mật khẩu và làm mới token

::: dac-ta
**Mục tiêu.** Cán bộ đăng nhập một lần vào Datahub mà trình duyệt không giữ token; kẻ dò mật khẩu bị chặn sau vài lần sai; kẻ cắp refresh token bị phát hiện ngay lần dùng đầu tiên sau nạn nhân.

**Tác nhân chính.** Cán bộ `nguyenvana` (không cần `PERM`).

**Tác nhân phụ.** BFF của `dh-console` hoặc `dh-portal` (client bí mật), Keycloak, WAF Coraza ở APISIX (giới hạn tần suất), dịch vụ thư, ứng dụng SAML (SSO dùng chung phiên).

**Mức ưu tiên.** M.

**FR hiện thực.** FR-12-020, 021, 038.

**Truy vết.** REQ-12; LGC-IAM-001, LGC-IAM-005, LGC-IAM-006, LGC-IAM-008; SEC-20, SEC-21, SEC-22, SEC-25, SEC-29; CMP-LAW-09.

**Tiền điều kiện.** Realm `dh-t68` `ACTIVE`; client `dh-console` đã khai báo với `redirect_uri` khớp chính xác; tài khoản `ACTIVE`.

**Kích hoạt.** BFF chuyển trình duyệt tới điểm cuối `auth` của realm khi không có phiên (FR-00-001).

**Đảm bảo tối thiểu.** Không có mật khẩu hay token trong trình duyệt, log hay thông báo lỗi (BR-12-045); thông báo và thời gian phản hồi của đăng nhập sai giống nhau cho tài khoản có và không tồn tại.

**Đảm bảo thành công.** Phiên SSO ở Keycloak (nhàn rỗi tối đa 15 phút, tối đa 10 giờ); BFF giữ cặp token; EVT-12-16 đã ghi.

**Luồng chính.**

1. BFF dựng yêu cầu ủy quyền với `code_challenge` `S256` và chuyển trình duyệt của `nguyenvana` tới `/realms/dh-t68/protocol/openid-connect/auth` (API-12-073). Keycloak kiểm tra `redirect_uri` khớp chính xác, có PKCE `S256` và realm không bị tạm ngừng.
2. Keycloak hiện trang đăng nhập (UI-12-18) theo giao diện tenant. Cán bộ nhập tên đăng nhập và mật khẩu.
3. Keycloak xác thực mật khẩu hoặc chuyển cho nguồn ngoài (UC-12-19), áp chính sách khóa: mỗi lần sai tăng bộ đếm theo tài khoản và theo địa chỉ nguồn.
4. Với người dùng thuộc nhóm `mfa-required`, Keycloak chạy luồng yếu tố thứ hai (UC-12-17).
5. Keycloak tạo phiên SSO và trả mã ủy quyền dùng một lần hiệu lực 60 giây về `redirect_uri`.
6. BFF đổi mã lấy token ở điểm cuối `token` (API-12-074) kèm `code_verifier`; nhận access token ES256 sống 5 phút (mang `iss`, `aud`, `sub`, `tenant`, `roles`, `org`, `acr`), refresh token và `id_token`; trình duyệt chỉ nhận cookie phiên.
7. Keycloak cập nhật `lastLoginAt`, ghi sự kiện đăng nhập (UC-12-37); đăng nhập đúng đặt lại bộ đếm sai nhưng không đặt lại bộ đếm khóa tạm 24 giờ.
8. Ở phút thứ 4 của access token, hoặc khi một lời gọi trả `401` vì hết hạn, BFF giành khóa loại trừ theo phiên rồi gửi refresh token tới điểm cuối `token`. Keycloak kiểm tra token chưa từng dùng, phiên còn hiệu lực, phát cặp token mới và đánh dấu token cũ đã dùng.
9. BFF thay cặp token trong kho phiên và giải phóng khóa; cán bộ làm việc liền mạch.

**Luồng thay thế.**

- **1a. Đã có phiên SSO.** Người đã đăng nhập ở một ứng dụng OIDC hoặc SAML (UC-12-19) vào ứng dụng khác không phải nhập lại; bước 2 đến 4 bỏ qua nếu mức `acr` đủ (không nâng mức tự động).
- **3a. Đăng nhập qua LDAP/AD.** Keycloak chuyển xác thực tới LDAP của tỉnh; chính sách mật khẩu do LDAP quyết định.
- **3b. Sai nhiều lần.** Sau 5 lần sai liên tiếp tài khoản `LOCKED` 15 phút và Keycloak gửi thư cho chủ tài khoản; sau 3 lần khóa tạm trong 24 giờ tài khoản `BLOCKED`, chỉ TA hoặc SO mở (UC-12-04) và hệ thống phát cảnh báo (UC-12-39).
- **8a. Dùng lại refresh token.** Một refresh token đã dùng bị xuất trình lần nữa: Keycloak hủy cả họ token và phiên SSO, ghi `REFRESH_TOKEN_REUSE`, phát cảnh báo; BFF nhận `invalid_grant`, hủy phiên BFF và đưa người dùng về đăng nhập.
- **8b. Đăng xuất.** BFF gọi điểm cuối `logout` (API-12-076); Keycloak hủy phiên và gửi back-channel logout tới các ứng dụng.

**Luồng ngoại lệ.**

- **E1. Sai tên hoặc mật khẩu (bước 3).** ERR-12-111 (401); "Tên đăng nhập hoặc mật khẩu không đúng." (cùng một câu cho mọi trường hợp, BR-12-017).
- **E2. Tài khoản khóa tạm (bước 3).** ERR-12-112 (423); "Tài khoản tạm khóa do đăng nhập sai nhiều lần. Thử lại sau {n} phút."
- **E3. Tài khoản khóa hẳn hoặc vô hiệu (bước 3).** ERR-12-113 (403); "Tài khoản đã bị khóa. Liên hệ quản trị tỉnh."
- **E4. `state`, `code_verifier` hoặc `redirect_uri` không khớp, hoặc thiếu PKCE (bước 1, 6).** ERR-12-114 (400); "Phiên đăng nhập không hợp lệ. Vui lòng đăng nhập lại."
- **E5. Yêu cầu dùng grant bị cấm (bước 1).** ERR-12-122 (400, `unsupported_grant_type`); không có câu cho người dùng, ghi nhật ký vì là lỗi cấu hình ứng dụng.
- **E6. Tenant tạm ngừng (bước 1).** ERR-12-121 (403); "Tỉnh {tên} đang tạm ngừng hoạt động."
- **E7. Quá nhiều lần thử từ một địa chỉ (bước 3).** ERR-12-125 (429); "Quá nhiều lần thử. Vui lòng đợi {n} phút rồi thử lại."
- **E8. Refresh token đã dùng (bước 8a).** ERR-12-115 (401); "Phiên đăng nhập đã bị đóng vì lý do an toàn. Vui lòng đăng nhập lại."
- **E9. Phiên hết hạn (bước 8).** ERR-12-116 (401); "Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại."
- **E10. Keycloak không phản hồi (bước 1 hoặc 8).** Trang lỗi PTN-13 "Hệ thống đang gặp sự cố. Vui lòng thử lại sau ít phút." (503); với bước 8, BFF thử lại 2 lần trong 10 giây rồi báo ERR-12-038.

**Quy tắc áp dụng.** BR-12-004, 017, 018, 019, 021, 022, 026, 045.

**Màn hình, API.** UI-12-18; API-12-072, 073, 074, 076, 078.
:::

### 6.17. UC-12-17 · Đăng ký yếu tố thứ hai và xác thực lại bước lên

::: dac-ta
**Mục tiêu.** Cán bộ giữ vai trò quyền cao đăng ký được yếu tố thứ hai (TOTP, hoặc WebAuthn cho quản trị) và, trước thao tác nhạy cảm, được yêu cầu xác thực lại trong 5 phút mà không bỏ qua được bằng gọi API trực tiếp.

**Tác nhân chính.** Cán bộ (Dũng khi bấm "Phát hành" ở UC-12-35).

**Tác nhân phụ.** Keycloak, OPA, BFF, PEP.

**Mức ưu tiên.** M.

**FR hiện thực.** FR-12-022, 023.

**Truy vết.** REQ-12; LGC-IAM-003; SEC-23; FR-00-002; RFC 9470; CMP-LAW-09.

**Tiền điều kiện.** Người dùng đã qua bước mật khẩu; có thiết bị tạo mã TOTP hoặc khóa WebAuthn.

**Kích hoạt.** (a) Keycloak đánh giá luồng xác thực có điều kiện sau bước mật khẩu; hoặc người dùng chọn "Bảo mật tài khoản". (b) OPA trả nghĩa vụ `STEPUP` khi `acr` thấp hơn mức yêu cầu hoặc `auth_time` cũ hơn 5 phút.

**Đảm bảo tối thiểu.** Giá trị bí mật của yếu tố không bao giờ đọc ra hay hiển thị lại; thao tác nhạy cảm không thực hiện khi chưa đạt mức.

**Đảm bảo thành công.** 100% tài khoản nhóm `mfa-required` có yếu tố thứ hai; token mang `acr` và `auth_time` mới; thao tác gốc được thực hiện sau xác thực lại.

**Luồng chính.**

1. Dũng vừa được gán `ROLE-SECURITY_OFFICER` (UC-12-09). Ở lần đăng nhập kế tiếp, sau bước mật khẩu, Keycloak xác định Dũng thuộc nhóm `mfa-required` và buộc đăng ký yếu tố thứ hai trước khi vào ứng dụng.
2. Vai trò quản trị chỉ chấp nhận WebAuthn nên trang đăng ký (UI-12-18) không hiện TOTP; Dũng chạm khóa FIDO2 và đặt nhãn "Khóa YubiKey số 1". Hệ thống khuyến nghị đăng ký ít nhất hai khóa vì không có mã khôi phục tự phục vụ.
3. Keycloak lưu khóa công khai, ghi kiểm toán, gửi thư thông báo cho Dũng, phát EVT-12-04; token sau đó mang `acr` 3.
4. Về sau, Dũng mở bản nháp chính sách và bấm "Phát hành". PEP hỏi OPA; OPA trả nghĩa vụ `STEPUP` vì `auth_time` đã quá 5 phút.
5. PEP trả `401` kèm `WWW-Authenticate: Bearer error="insufficient_user_authentication", acr_values="3", max_age="300"` (ERR-12-120).
6. BFF hiện hộp "Xác nhận lại danh tính" và chuyển Dũng tới Keycloak kèm `acr_values`, `max_age` (API-12-073).
7. Dũng chạm khóa; Keycloak cấp token mới có `acr` và `auth_time` mới (API-12-074); mã phiên sinh lại sau step-up.
8. BFF tự gửi lại thao tác "Phát hành" với token mới; OPA cho qua.

**Luồng thay thế.**

- **1a. Người không thuộc nhóm bắt buộc.** Cán bộ bật yếu tố thứ hai tự nguyện ở "Bảo mật tài khoản"; khi được gán vai trò bắt buộc thì bị buộc đăng ký ở lần đăng nhập kế tiếp.
- **2a. Cán bộ thuộc nhóm bắt buộc nhưng không phải quản trị.** Chọn TOTP bằng quét mã QR và nhập mã xác nhận, hoặc WebAuthn.
- **3a. Thêm hoặc gỡ yếu tố.** Dũng thêm, gỡ yếu tố ở "Bảo mật tài khoản" sau xác thực lại bước lên; không gỡ được yếu tố cuối cùng khi thuộc nhóm bắt buộc.
- **4a. Đã xác thực lại trong 5 phút.** Thao tác đi thẳng, không hỏi lại.
- **7a. Hủy hộp xác nhận.** Thao tác không thực hiện, không có lỗi.
- **Mất thiết bị.** Xử lý ở UC-12-18; nếu còn một yếu tố khác, gỡ yếu tố bị mất ở "Bảo mật tài khoản".

**Luồng ngoại lệ.**

- **E1. Mã TOTP sai hoặc hết hạn (bước 2, 7).** ERR-12-111 (401); "Mã xác thực không đúng hoặc đã hết hạn. Nhập mã mới trên ứng dụng xác thực." Mỗi lần sai tính vào số lần sai khóa tài khoản (UC-12-16).
- **E2. Bỏ qua bước đăng ký (bước 1).** Không vào được ứng dụng; trang đăng ký hiện lại "Vai trò của bạn bắt buộc xác thực hai yếu tố."
- **E3. Thiết bị không hỗ trợ WebAuthn với vai trò chỉ chấp nhận WebAuthn (bước 2).** "Thiết bị này không hỗ trợ khóa bảo mật. Dùng trình duyệt khác hoặc liên hệ quản trị tỉnh."
- **E4. Gỡ yếu tố cuối cùng của tài khoản bắt buộc (bước 3a).** ERR-12-010 (422); "Tài khoản của anh/chị bắt buộc có yếu tố thứ hai."
- **E5. Cần xác thực bước lên (bước 5).** ERR-12-120 (401); "Cần xác thực lại để thực hiện thao tác này."
- **E6. Xác thực lại thất bại (bước 7).** Tính vào số lần sai; "Xác thực lại không thành công. Thử lại."
- **E7. Mức yêu cầu 3 nhưng chưa đăng ký WebAuthn (bước 6).** "Thao tác này cần khóa bảo mật. Đăng ký khóa ở Bảo mật tài khoản."
- **E8. Keycloak không phản hồi (bước 6, 7).** Thao tác không thực hiện; "Hệ thống xác thực tạm thời không khả dụng. Thử lại sau." (503)

**Quy tắc áp dụng.** BR-12-015, 016, 019, 022, 045.

**Màn hình, API.** UI-12-02, 18; API-12-002, 073, 074.
:::

### 6.18. UC-12-18 · Đặt lại yếu tố thứ hai khi mất thiết bị

::: dac-ta
**Mục tiêu.** Cán bộ mất thiết bị xác thực lấy lại được tài khoản sau khi danh tính được xác minh bằng kênh khác; việc đặt lại chỉ do quản trị cao hơn một cấp, và tài khoản quản trị cần cán bộ ATTT duyệt.

**Tác nhân chính.** ROLE-TENANT_ADMIN (Mai) đặt lại cho người dùng không phải quản trị; ROLE-PLATFORM_ADMIN (Hà) đặt lại cho TA, SO và nhân sự nền tảng; ROLE-SECURITY_OFFICER (Dũng) duyệt tài khoản quản trị.

**Tác nhân phụ.** Keycloak, dịch vụ thư, hộp "Việc của tôi" (FR-00-070).

**Mức ưu tiên.** M.

**FR hiện thực.** FR-12-024.

**Truy vết.** REQ-12; LGC-IAM-003; SEC-23; BR-12-034.

**Tiền điều kiện.** Người đặt lại có `PERM-12-mfa-reset`, cao hơn một cấp về vai trò so với tài khoản đích, đã xác thực mức 3; tài khoản đích `ACTIVE` hoặc `LOCKED`; người duyệt (nếu có) có `PERM-12-approve`.

**Kích hoạt.** Quản trị bấm "Đặt lại yếu tố thứ hai" ở UI-12-02.

**Đảm bảo tối thiểu.** Không ai tự đặt lại cho mình; tài khoản quản trị không bị đặt lại khi thiếu người duyệt thứ hai; kênh xác minh được ghi lại.

**Đảm bảo thành công.** Mọi yếu tố cũ bị xóa, mọi phiên và refresh token bị cắt; người dùng bị buộc đăng ký yếu tố mới ở lần đăng nhập kế tiếp; EVT-12-04 và EVT-12-05 đã phát.

**Luồng chính.**

1. `nguyenvana` báo mất điện thoại cài TOTP. Mai mở UI-12-02 của `nguyenvana`, bấm "Đặt lại yếu tố thứ hai", nhập cách đã xác minh "gọi số đăng ký, xác nhận qua Lộc, thủ trưởng đơn vị" và lý do.
2. Hệ thống gọi API-12-015; kiểm tra Mai cao hơn một cấp so với `nguyenvana`, không phải chính mình, xác minh không rỗng.
3. `nguyenvana` không giữ vai trò quản trị nên hệ thống thực hiện ngay: xóa mọi yếu tố thứ hai ở Keycloak, đặt hành động bắt buộc đăng ký lại, thu hồi mọi phiên và refresh token (UC-12-28).
4. Hệ thống gửi thư tới `nguyenvana` ("yếu tố xác thực của bạn đã được đặt lại"), tới Mai và Dũng; ghi kiểm toán, phát EVT-12-04, EVT-12-05; trả `200`.
5. Ở lần đăng nhập kế tiếp, `nguyenvana` nhập mật khẩu rồi bị buộc đăng ký yếu tố mới (UC-12-17).

**Luồng thay thế.**

- **3a. Tài khoản quản trị.** Nếu đích có vai trò `_ADMIN`, `SECURITY_OFFICER` hoặc vai trò nền tảng, hệ thống trả `202`, tạo yêu cầu duyệt cho SO (UI-12-17); Dũng (khác người đặt lại) kiểm tra và duyệt (LP-12-01, LP-12-03); sau đó thực hiện như bước 3. Phát cảnh báo mức cao khi thực hiện.
- **3b. TA, SO.** Hà (PA) đặt lại cho Mai hoặc Dũng, kèm quyền có thời hạn khi tài khoản ở tenant khác (UC-12-13).
- **1a. Còn yếu tố khác.** Người dùng còn một khóa dự phòng thì tự gỡ yếu tố bị mất ở "Bảo mật tài khoản", không cần đặt lại.

**Luồng ngoại lệ.**

- **E1. Không đủ cấp (bước 2).** ERR-12-017 (403); "Chỉ quản trị cấp trên mới đặt lại được yếu tố thứ hai của tài khoản này." Yêu cầu chuyển lên cấp trên.
- **E2. Tự đặt lại (bước 2).** ERR-12-013 (403); "Anh/chị không thể tự đặt lại yếu tố thứ hai của mình."
- **E3. Thiếu mô tả xác minh (bước 1).** ERR-12-014 (400); "Nhập cách đã xác minh danh tính người dùng."
- **E4. Người duyệt trùng người đặt lại (bước 3a).** ERR-12-008 (403); "Anh/chị là người đề nghị nên không được tự duyệt."

**Quy tắc áp dụng.** BR-12-028, 033, 034.

**Màn hình, API.** UI-12-02, 17; API-12-015.
:::

### 6.19. UC-12-19 · Khai báo và duyệt liên kết định danh ngoài: LDAP/AD, SAML 2, VNeID

::: dac-ta
**Mục tiêu.** Tỉnh dùng được danh bạ LDAP/AD sẵn có, giữ ứng dụng cũ đăng nhập một lần bằng SAML 2, và (Đợt 2) cho cán bộ đăng nhập bằng VNeID, mà mỗi liên kết chỉ có hiệu lực sau khi cán bộ ATTT duyệt và không bao giờ tự tạo tài khoản.

**Tác nhân chính.** ROLE-TENANT_ADMIN (Mai) khai báo; ROLE-SECURITY_OFFICER (Dũng) duyệt kích hoạt; cán bộ liên kết VNeID của mình.

**Tác nhân phụ.** LDAP/AD của tỉnh (`ldaps://ldap.t68.gov.vn:636`), ứng dụng SAML (nhà cung cấp dịch vụ SP), VNeID, Keycloak, OpenBao (bí mật tài khoản đọc, khóa băm).

**Mức ưu tiên.** M (LDAP, SAML), C (VNeID, Đợt 2).

**FR hiện thực.** FR-12-025, 026, 028.

**Truy vết.** REQ-12; LGC-IAM-001, 004, 007 (loại bỏ, VNeID thay thế), 008; SEC-20, SEC-22; CMP-LAW-09, CMP-LAW-10; IF-06; Q12-02, Q12-11.

**Tiền điều kiện.** Mai có `PERM-12-admin`, Dũng có `PERM-12-approve`; với LDAP: tỉnh cung cấp máy chủ LDAPS (TLS từ 1.2), tài khoản đọc chỉ-đọc, chứng thư CA tin cậy, đích nằm trong danh sách egress của tenant; với SAML: metadata của SP có chứng thư ký còn hạn ít nhất 90 ngày và ACS dùng HTTPS; với VNeID: tenant bật `12.vneid.enabled` và cơ quan đã được cấp quyền tích hợp (GĐ-12-01).

**Kích hoạt.** Mai mở "Liên kết định danh" ở UI-12-11.

**Đảm bảo tối thiểu.** Bí mật của tài khoản đọc chỉ nằm ở OpenBao; không sao chép mật khẩu LDAP; không tự tạo tài khoản từ định danh ngoài; không lưu số định danh VNeID rõ.

**Đảm bảo thành công.** Liên kết `ACTIVE` sau khi Dũng duyệt; người dùng đăng nhập được bằng nguồn tương ứng; kiểm toán ghi đủ.

**Luồng chính.** (Biến thể LDAP/AD)

1. Mai nhập máy chủ `ldaps://ldap.t68.gov.vn:636`, cơ sở tìm kiếm `OU=CanBo,DC=t68,DC=gov,DC=vn`, bảng ánh xạ OU sang `orgCode`, tài khoản đọc và bí mật; bí mật ghi một chiều vào OpenBao. Hệ thống gọi API-12-048.
2. Mai bấm "Kiểm tra" (API-12-049). Hệ thống bắt tay TLS, xác minh chuỗi chứng thư, bind thử, tìm thử một người, đếm số người trong cơ sở tìm kiếm và hiện kết quả ánh xạ thuộc tính mẫu.
3. Mai khai "Bản xác nhận chính sách mật khẩu LDAP": nếu chính sách của tỉnh yếu hơn SEC-22 thì hệ thống bật MFA bắt buộc cho mọi người dùng nguồn LDAP (Q12-11).
4. Mai bấm "Gửi duyệt kích hoạt". Dũng mở việc ở UI-12-17, xác thực lại bước lên (LP-12-03), duyệt (LP-12-01).
5. Hệ thống tạo liên kết ở Keycloak ở chế độ chỉ-đọc: xác thực chuyển thẳng tới LDAP, mật khẩu không sao chép; đồng bộ gia tăng mỗi 15 phút (API-12-050 cho đồng bộ thủ công).
6. Người dùng thuộc cơ sở tìm kiếm được nhập thành tài khoản `authSource=LDAP` với đơn vị theo bảng ánh xạ; vai trò không tự gán từ nhóm LDAP và không bao giờ gán vai trò đặc quyền. Phát EVT-12-01, EVT-12-02.
7. Người dùng bị vô hiệu ở LDAP chuyển `DISABLED` ở Datahub không quá 15 phút sau và phiên bị thu hồi (UC-12-28).

**Luồng thay thế.**

- **1a. Biến thể SAML 2.** Mai nhập hoặc tải metadata của SP `qlvb-cu` ở UI-12-11 (API-12-052). Hệ thống kiểm tra entityId duy nhất, ACS HTTPS, chứng thư hợp lệ, yêu cầu ký; Dũng duyệt; hệ thống tạo SAML client (ký `Assertion` bằng khóa realm, `NameID` bền vững). Khi người dùng mở SP, SP gửi `AuthnRequest`; Keycloak kiểm tra chữ ký và entityId, dùng chung phiên SSO với OIDC (người đã đăng nhập không phải nhập lại), dựng `Assertion` hiệu lực 5 phút, ký và gửi về ACS. SP cần mã hóa `Assertion` thì bật bằng chứng thư mã hóa trong metadata; ngừng SP thì TA gỡ, SO duyệt (API-12-053).
- **1b. Biến thể VNeID (Đợt 2).** Cán bộ bấm "Đăng nhập bằng VNeID"; Keycloak chuyển tới VNeID theo OIDC, nhận số định danh và họ tên, tính HMAC-SHA256 với khóa theo tenant ở OpenBao, tra liên kết theo giá trị băm. Có liên kết với tài khoản `ACTIVE` thì tạo phiên mức `acr` 2 (giả định, Q12-02). Chưa có liên kết thì yêu cầu đăng nhập một lần bằng tài khoản nội bộ kèm yếu tố thứ hai để xác nhận rồi ghi liên kết (API-12-054). Gỡ liên kết: cán bộ hoặc TA (API-12-055); mọi phiên đăng nhập qua VNeID bị hủy.
- **1c. LDAP chỉ để xác thực.** Chế độ "chỉ xác thực" cho tài khoản đã tạo ở UC-12-02, không nhập người dùng.
- **1d. Tỉnh không có LDAP.** Dùng tài khoản cục bộ, không có use case này.

**Luồng ngoại lệ.**

- **E1. Không kết nối được LDAP, chứng thư không tin cậy hoặc bind sai (bước 2).** ERR-12-032 (422); "Không kết nối được tới danh bạ {máy chủ}: {lý do}."
- **E2. Bí mật không ghi được (bước 1).** ERR-12-039 (503); "Kho bí mật tạm thời không khả dụng; chưa lưu cấu hình."
- **E3. Trùng tên đăng nhập giữa người LDAP và tài khoản cục bộ (bước 6).** ERR-12-002 (409); dòng đó bỏ qua và ghi vào báo cáo đồng bộ.
- **E4. LDAP không khả dụng khi đăng nhập.** Người dùng LDAP thấy "Hệ thống danh bạ của tỉnh tạm thời không khả dụng. Thử lại sau."; tài khoản cục bộ không bị ảnh hưởng.
- **E5. Metadata SAML không hợp lệ (bước 1a).** ERR-12-033 (422); "Metadata của ứng dụng không hợp lệ: {lý do}."
- **E6. SP chưa đăng ký hoặc chữ ký `AuthnRequest` sai.** Từ chối, ghi cảnh báo an ninh; người dùng thấy "Ứng dụng này chưa được đăng ký đăng nhập một lần. Liên hệ quản trị tỉnh."
- **E7. Chứng thư SP sắp hết hạn trong 30 ngày.** Cảnh báo ở UI-12-11 và gửi thư cho Mai; không có lỗi.
- **E8. Người duyệt trùng người khai báo (bước 4).** ERR-12-008 (403); "Anh/chị là người khai báo nên không được tự duyệt."
- **E9. Số định danh chưa liên kết và không có tài khoản nội bộ (bước 1b).** Từ chối, không tự tạo tài khoản (BR-12-029); "Số định danh này chưa được liên kết với tài khoản Datahub. Liên hệ quản trị tỉnh."
- **E10. Số định danh đã liên kết tài khoản khác (bước 1b).** ERR-12-034 (409); "Số định danh này đã liên kết với một tài khoản khác." kèm cảnh báo an ninh.
- **E11. VNeID lỗi hoặc quá thời gian chờ (bước 1b).** "Chưa đăng nhập được bằng VNeID. Dùng cách đăng nhập khác hoặc thử lại sau." Không phải lỗi hệ thống.

**Quy tắc áp dụng.** BR-12-018, 020, 021, 022, 029, 038, 045.

**Màn hình, API.** UI-12-11, 18; API-12-047, 048, 049, 050, 051, 052, 053, 054, 055.
:::

### 6.20. UC-12-20 · Quản lý phiên: xem, buộc đăng xuất

::: dac-ta
**Mục tiêu.** Quản trị tỉnh và cán bộ ATTT xem các phiên đang mở của một tài khoản và cắt phiên khi nghi ngờ lộ; hạn mức phiên và thời hạn phiên do hệ thống tự thực thi.

**Tác nhân chính.** ROLE-TENANT_ADMIN (Mai); ROLE-SECURITY_OFFICER (Dũng).

**Tác nhân phụ.** Keycloak, BFF (back-channel logout), APISIX (danh sách chặn).

**Mức ưu tiên.** M.

**FR hiện thực.** FR-12-029.

**Truy vết.** REQ-12; LGC-IAM-001, LGC-IAM-005; SEC-29; FR-00-003, FR-00-005.

**Tiền điều kiện.** Người xem có `PERM-12-read`; người buộc đăng xuất có `PERM-12-user-lock`; tài khoản đích có ít nhất một phiên đang mở.

**Kích hoạt.** Quản trị mở tab "Phiên" ở UI-12-02; hoặc một người dùng mở phiên mới vượt hạn mức.

**Đảm bảo tối thiểu.** Không tự buộc đăng xuất tất cả phiên của mình qua trang quản trị; phiên bị hủy không dùng lại được.

**Đảm bảo thành công.** Phiên bị buộc đăng xuất nhận `401` ở lời gọi kế tiếp; mọi người dùng có tối đa 3 phiên (quản trị 1) và không phiên nào quá 10 giờ; EVT-12-05 đã phát.

**Luồng chính.**

1. Dũng mở tab "Phiên" của `nguyenvana`. Hệ thống gọi API-12-016, lấy danh sách từ Keycloak: thiết bị, trình duyệt, địa chỉ nguồn, mức `acr`, bắt đầu, hoạt động cuối, hết hạn.
2. Dũng thấy một phiên từ địa chỉ lạ, chọn phiên và bấm "Buộc đăng xuất", nhập lý do "Địa chỉ lạ ngoài giờ" rồi xác nhận (FR-00-050).
3. Hệ thống gọi API-12-017; hủy phiên ở Keycloak, gọi back-channel logout tới BFF để hủy phiên BFF, thu hồi refresh token và đẩy danh sách chặn (UC-12-28).
4. Hệ thống ghi kiểm toán kèm lý do, phát EVT-12-05, trả `204`; tab Phiên làm mới.
5. Khi `nguyenvana` mở phiên thứ 4, Keycloak thu hồi phiên cũ nhất và thông báo cho người đó (quản trị chỉ 1 phiên).
6. Phiên chạm 10 giờ hoặc nhàn rỗi 15 phút (5 đến 15 phút theo tenant) tự hết hạn; đổi mật khẩu, đổi yếu tố thứ hai hoặc bị khóa thì mọi phiên bị thu hồi.

**Luồng thay thế.**

- **2a. "Buộc đăng xuất tất cả".** Dũng cắt toàn bộ phiên của `nguyenvana`.
- **2b. Phiên đã hết hạn trước khi hủy.** Danh sách tự làm mới, không báo lỗi.
- **1a. Cán bộ xem phiên của mình.** Dùng trang "Phiên đăng nhập của tôi" (FR-00-005), không qua use case này.

**Luồng ngoại lệ.**

- **E1. Tự buộc đăng xuất tất cả phiên của mình qua trang quản trị (bước 2).** ERR-12-013 (403); "Dùng trang Phiên đăng nhập của tôi."
- **E2. Thiếu lý do (bước 2).** ERR-12-014 (400); "Nhập lý do buộc đăng xuất."
- **E3. Keycloak không phản hồi (bước 1, 3).** ERR-12-038 (503); "Chưa lấy được danh sách phiên. Thử lại sau."
- **E4. Không tìm thấy tài khoản (bước 1).** ERR-12-001 (404) theo LP-12-06.

**Quy tắc áp dụng.** BR-12-022, 028, 033.

**Màn hình, API.** UI-12-02; API-12-016, 017.
:::

### 6.21. UC-12-21 · Cấp client OAuth cho HTTT và ứng dụng sandbox

::: dac-ta
**Mục tiêu.** Khi hồ sơ kết nạp HTTT được duyệt, HTTT có ngay danh tính truy cập đúng mức hợp đồng, đúng phạm vi, và bí mật (nếu có) chỉ giao một lần cho đầu mối; nhà phát triển có client sandbox chỉ gọi được API thử nghiệm.

**Tác nhân chính.** PH-01 (scope `iam:client-provision`) trong saga kết nạp; PH-15 (scope `iam:dev-client`) thay mặt nhà phát triển.

**Tác nhân phụ.** Keycloak, OpenBao (bản bọc bí mật dùng một lần), ROLE-ORG_REQUESTER (Hùng, nhận bí mật), ROLE-TENANT_ADMIN (xem client).

**Mức ưu tiên.** M (FR-12-030), S (FR-12-032, Đợt 2).

**FR hiện thực.** FR-12-030, 032.

**Truy vết.** REQ-12; REQ-01; REQ-15; LGC-IAM-002, LGC-IAM-006 (thay thế), LGC-APIM-020; SEC-24, SEC-25; BP-01.

**Tiền điều kiện.** HTTT `HT-QLVB` ở PH-01 đã `APPROVED`, chưa có client cho mã đó; hợp đồng đã có mức phân loại cao nhất (D03-07 §4); bên gọi có scope tương ứng.

**Kích hoạt.** PH-01 gọi API tạo client ở bước "tạo client" của saga kết nạp (D03-01 §7.3); với sandbox, nhà phát triển bấm "Tạo thông tin xác thực" ở cổng PH-15.

**Đảm bảo tối thiểu.** Bí mật không nằm ở bất kỳ phản hồi, log hay CSDL quản trị; thất bại thì saga PH-01 dừng và bù trừ (xóa client đã tạo dở); cấp lặp với cùng `Idempotency-Key` trả kết quả cũ.

**Đảm bảo thành công.** Client `ENABLED` ở Keycloak và `ph12_iam`, đúng phương thức xác thực theo mức hợp đồng; EVT-12-06 đã phát.

**Luồng chính.**

1. PH-01 gọi API-12-058 kèm mã HTTT `HT-QLVB`, đơn vị `SKHCN`, mức hợp đồng Hạn chế, phương thức mong muốn `private_key_jwt`, danh sách scope đã duyệt kèm nguồn, và `Idempotency-Key`.
2. Hệ thống kiểm tra bên gọi có scope `iam:client-provision` và HTTT chưa có client.
3. Hệ thống kiểm tra phương thức phù hợp mức hợp đồng (Hạn chế trở lên cần mTLS hoặc `private_key_jwt`, Nhạy cảm cần mTLS; `client_secret` chỉ cho mức Công khai, Nội bộ).
4. Hệ thống kiểm tra mọi scope đều có nguồn duyệt, rồi tạo client ở Keycloak: `clientId` bằng mã HTTT viết thường (`ht-qlvb`), chỉ bật `client_credentials`, tắt grant `password` và `implicit`, ràng buộc token với chứng thư hoặc khóa.
5. Hệ thống gán scope (UC-12-22). Nếu dùng `client_secret`, hệ thống sinh bí mật từ 256 bit, ghi vào Keycloak và cất một bản bọc dùng một lần (hiệu lực 24 giờ) trong OpenBao.
6. Hệ thống ghi kiểm toán, phát EVT-12-06, trả `201` kèm tham chiếu bí mật bọc (không có bí mật); Hùng nhận bí mật một lần ở PH-01.
7. Với `mTLS` hoặc `private_key_jwt`: client `ENABLED` nhưng `credentialReady=false` tới khi chứng thư hoặc khóa công khai được đăng ký (UC-12-24). Mai xem client ở UI-12-10 qua API-12-056, 057.

**Luồng thay thế.**

- **1a. Dùng `private_key_jwt`.** PH-01 truyền khóa công khai ngay trong lời gọi; bỏ bước 7.
- **1b. Cấp song song khi chuyển đổi từ hệ cũ.** Thông tin xác thực mới cấp bên cạnh Consumer Key, Secret của hệ cũ trong thời gian chạy song song (BP-09).
- **1c. Ứng dụng sandbox (Đợt 2).** PH-15 gọi API-12-063 kèm mã ứng dụng, chủ ứng dụng và scope `sandbox:*`. Hệ thống tạo client mức `PUBLIC`, cờ `sandbox=true`, hạn 180 ngày, cho phép `client_secret`, cất bí mật bọc và trả tham chiếu để PH-15 hiển thị đúng một lần cho nhà phát triển.
- **1d. Nhà phát triển cần xoay bí mật.** PH-15 gọi UC-12-24; hết 180 ngày client sandbox tự `SUSPENDED`, gia hạn qua PH-15.

**Luồng ngoại lệ.**

- **E1. HTTT đã có client (bước 2).** ERR-12-018 (409); "HTTT {mã} đã có danh tính truy cập."
- **E2. Phương thức không đạt mức hợp đồng (bước 3).** ERR-12-022 (422); "Hợp đồng mức {mức} cần xác thực bằng chứng thư mTLS hoặc khóa công khai, không dùng bí mật chia sẻ."
- **E3. Scope không có nguồn duyệt (bước 4).** ERR-12-019 (422); "Phạm vi {scope} chưa được duyệt cho HTTT này."
- **E4. Keycloak hoặc OpenBao không khả dụng (bước 4, 5).** ERR-12-038, ERR-12-039 (503); saga PH-01 dừng và bù trừ.
- **E5. Sandbox có scope thật (bước 1c).** ERR-12-019 (422); "Ứng dụng sandbox chỉ nhận phạm vi thử nghiệm."
- **E6. Chủ ứng dụng sandbox không còn (bước 1c).** ERR-12-001 (404).
- **E7. OpenBao lỗi khi cấp sandbox (bước 1c).** ERR-12-039 (503); PH-15 hiện "Chưa tạo được thông tin xác thực. Thử lại sau."

**Quy tắc áp dụng.** BR-12-004, 021, 023, 024, 025.

**Màn hình, API.** UI-12-10; API-12-056, 057, 058, 063.
:::

### 6.22. UC-12-22 · Sinh scope của client từ dữ liệu đã duyệt

::: dac-ta
**Mục tiêu.** Quyền của máy luôn khớp với dữ liệu đã duyệt ở phân hệ nguồn: đăng ký sử dụng API, mục đích khai thác, publication, subscription; không ai sửa scope bằng tay.

**Tác nhân chính.** PH-02, PH-09, PH-10, PH-07, PH-19 (scope `iam:client-provision`, mỗi nguồn chỉ đặt loại scope của mình).

**Tác nhân phụ.** Bộ ghi chính sách (UC-12-33), ROLE-TENANT_ADMIN và ROLE-SECURITY_OFFICER (xem scope).

**Mức ưu tiên.** M.

**FR hiện thực.** FR-12-036.

**Truy vết.** REQ-12; REQ-02; REQ-09; REQ-10; LGC-NGSP-008; D02-08 §5; SEC-24.

**Tiền điều kiện.** Client `ht-qlvb` tồn tại và không `REVOKED`.

**Kích hoạt.** Phân hệ nguồn gọi cập nhật tập scope khi một đăng ký sử dụng, mục đích, publication hay subscription được duyệt, đổi hoặc thu hồi.

**Đảm bảo tối thiểu.** Nguồn không đặt được scope ngoài loại của mình; scope của nguồn khác giữ nguyên; scope bị gỡ không còn hiệu lực quá 60 giây.

**Đảm bảo thành công.** Tập scope hiện hành theo từng nguồn lưu ở `ph12_iam`; gói chính sách yêu cầu tái sinh; EVT-12-08 đã phát.

**Luồng chính.**

1. PH-02 duyệt đăng ký sử dụng API "Tra cứu hộ tịch" gói `goi-co-ban` cho `HT-QLVB`, rồi gọi API-12-068 đặt tập scope của nguồn mình: `api:tra-cuu-ho-tich:goi-co-ban`.
2. Hệ thống kiểm tra mỗi nguồn chỉ được đặt loại scope của mình: PH-02 đặt `api:{mã API}:{mã gói}`, PH-09 đặt `purpose:{mã}`, PH-10 đặt `topic:{tên}:publish`, `topic:{tên}:subscribe`.
3. Hệ thống thay tập scope của nguồn PH-02 bằng tập mới, giữ nguyên scope của các nguồn khác.
4. Hệ thống cập nhật dữ liệu client trong gói chính sách (UC-12-33); scope thêm có hiệu lực ở token kế tiếp, scope bị gỡ không còn hiệu lực ở OPA trong không quá 60 giây.
5. Hệ thống ghi kiểm toán (scope thêm, bớt, nguồn, tham chiếu duyệt), phát EVT-12-08, trả `200` kèm tập scope hiện hành theo nguồn.
6. Mai và Dũng mở tab Scope (chỉ đọc) của client ở UI-12-10 qua API-12-067 và thấy mỗi scope kèm đường liên kết tới phân hệ nguồn.

**Luồng thay thế.**

- **1a. Đăng ký bị thu hồi.** Nguồn gọi đặt tập rỗng; scope biến mất.
- **4a. Tập scope lớn hơn 50.** Token mang scope gom nhóm theo tiền tố và OPA đối chiếu bằng dữ liệu gói.
- **1b. Nhiều nguồn cùng cập nhật.** Mỗi nguồn chỉ thay phần của mình, không xung đột.

**Luồng ngoại lệ.**

- **E1. Nguồn đặt loại scope không phải của mình (bước 2).** ERR-12-019 (422); "Nguồn {nguồn} không được cấp phạm vi {scope}."
- **E2. Client đã thu hồi (bước 1).** ERR-12-020 (409); "Danh tính của HTTT đã bị thu hồi."
- **E3. Người dùng cố sửa scope bằng tay.** Giao diện không có chức năng này; gọi API trả ERR-12-007 (403).

**Quy tắc áp dụng.** BR-12-024, 025.

**Màn hình, API.** UI-12-10 (tab Scope, chỉ đọc); API-12-067, 068.
:::

### 6.23. UC-12-23 · Quản lý vòng đời client: sửa, tạm ngừng, tiếp tục, thu hồi

::: dac-ta
**Mục tiêu.** TA và SO tạm ngừng, tiếp tục hoặc thu hồi danh tính của một HTTT khi cần (nghi lộ khóa, HTTT ngừng dùng), và token đã cấp bị chặn trong 60 giây.

**Tác nhân chính.** ROLE-TENANT_ADMIN (Mai) sửa; ROLE-SECURITY_OFFICER (Dũng) và TA tạm ngừng, tiếp tục, thu hồi; PH-01 thu hồi khi chấm dứt kết nối.

**Tác nhân phụ.** Keycloak, APISIX, đầu mối kỹ thuật của HTTT (Hùng, nhận thông báo), tác vụ UC-12-07.

**Mức ưu tiên.** M.

**FR hiện thực.** FR-12-031.

**Truy vết.** REQ-12; REQ-01; LGC-APIM-020; SEC-24, SEC-27; BP-07.

**Tiền điều kiện.** Client `ht-qlvb` tồn tại; chuyển trạng thái hợp lệ theo máy trạng thái client (FRS mục 4.4); người thao tác có `PERM-12-client` (sửa) hoặc `PERM-12-user-lock` (đổi trạng thái).

**Kích hoạt.** Người dùng chọn thao tác ở UI-12-10; PH-01 gọi khi hủy kết nối; UC-12-07 tạm ngừng tự động sau 90 ngày không gọi.

**Đảm bảo tối thiểu.** Cấu hình và chứng thư của client tạm ngừng được giữ; client thu hồi không bao giờ dùng lại mã.

**Đảm bảo thành công.** Trạng thái mới ở Keycloak, `ph12_iam` và danh sách chặn; HTTT không lấy được token mới; EVT-12-07 và EVT-12-05 đã phát.

**Luồng chính.**

1. Dũng nghi `HT-QLVB` lộ khóa. Ở UI-12-10 chọn client `ht-qlvb`, bấm "Tạm ngừng" và nhập lý do "Nghi lộ khóa riêng, ticket ATTT-0412".
2. Hệ thống gọi API-12-060; kiểm tra chuyển `ENABLED` sang `SUSPENDED` hợp lệ và lý do đủ ký tự.
3. Hệ thống đặt `SUSPENDED` ở Keycloak và thu hồi tức thời theo UC-12-28 (token đã cấp bị chặn trong 60 giây); chứng thư và cấu hình giữ nguyên.
4. Hệ thống ghi kiểm toán, phát EVT-12-07, thông báo Hùng (đầu mối kỹ thuật).
5. Sau khi HTTT thay khóa (UC-12-24), Hùng xác nhận còn dùng; Mai bấm "Tiếp tục" (API-12-061). Hệ thống đặt `ENABLED`, buộc xoay bí mật nếu đã quá hạn.
6. Khi HTTT chấm dứt kết nối, PH-01 hoặc Mai gọi "Thu hồi" (API-12-062): hệ thống đặt `REVOKED` vĩnh viễn, xóa bí mật bọc, hủy đăng ký chứng thư, gỡ toàn bộ scope, đẩy danh sách chặn; mã client không dùng lại.

**Luồng thay thế.**

- **1a. Sửa đầu mối, mô tả.** Mai gọi API-12-059 kèm `If-Match`; không đổi trạng thái, không thu hồi gì.
- **1b. Nâng mức hợp đồng.** Ví dụ Hạn chế lên Nhạy cảm: hệ thống buộc đổi phương thức xác thực trong cùng yêu cầu (không hạ phương thức khi từ mức Hạn chế, BR-12-024).
- **5a. Tiếp tục sau tạm ngừng tự động vì 90 ngày không gọi.** Cần đầu mối xác nhận còn dùng.
- **6a. Muốn gọi tiếp sau khi thu hồi.** Phải cấp client mới (UC-12-21).

**Luồng ngoại lệ.**

- **E1. Chuyển trạng thái sai (bước 2).** ERR-12-020 (409); "Danh tính của HTTT đang ở trạng thái {trạng thái}, không thực hiện được thao tác này."
- **E2. Thiếu lý do (bước 1).** ERR-12-014 (400); "Nhập lý do (ít nhất 10 ký tự)."
- **E3. Phiên bản đã đổi (bước 1a).** ERR-12-044 (412); "Thông tin này vừa được người khác sửa. Tải lại trang để xem bản mới nhất."
- **E4. Không có quyền (bước 1).** ERR-12-007 (403) theo LP-12-06.
- **E5. Chưa xác thực bước lên (bước 1).** ERR-12-120 (401) theo LP-12-03.

**Quy tắc áp dụng.** BR-12-020, 024, 028, 033.

**Màn hình, API.** UI-12-10; API-12-059, 060, 061, 062.
:::

### 6.24. UC-12-24 · Đăng ký chứng thư, khóa công khai và xoay bí mật client

::: dac-ta
**Mục tiêu.** HTTT xác thực bằng chứng thư mTLS hoặc khóa công khai mà không cần bí mật chia sẻ; nếu còn dùng bí mật thì xoay được định kỳ hoặc khẩn mà không gián đoạn.

**Tác nhân chính.** ROLE-TENANT_ADMIN (Mai); ROLE-ORG_REQUESTER (Hùng, đầu mối nhận bí mật); PH-15 cho client sandbox; PH-01 trong saga kết nạp.

**Tác nhân phụ.** Keycloak, OpenBao (PKI, bản bọc bí mật), APISIX (nhận dấu vân tay), ROLE-SECURITY_OFFICER (yêu cầu xoay khẩn).

**Mức ưu tiên.** M.

**FR hiện thực.** FR-12-033, 034.

**Truy vết.** REQ-12; SEC-24; RFC 8705, RFC 7523; LGC-BUS-041; LGC-NGSP-008; NFR-00-022.

**Tiền điều kiện.** Mai có `PERM-12-client`; client `ht-qlvb` `ENABLED` hoặc `SUSPENDED` với `authMethod` là `TLS_CLIENT_AUTH`, `PRIVATE_KEY_JWT` (đăng ký chứng thư) hoặc `CLIENT_SECRET` (xoay bí mật, không có lần xoay đang chuyển tiếp).

**Kích hoạt.** Mai bấm "Đăng ký chứng thư", "Đăng ký khóa công khai" hoặc "Xoay bí mật" ở UI-12-10; hoặc bí mật tới hạn 180 ngày; hoặc SO yêu cầu xoay khẩn.

**Đảm bảo tối thiểu.** Bí mật mới chỉ giao một lần qua bản bọc của OpenBao, không bao giờ trả trong phản hồi API, log, CSDL; thất bại thì bí mật hiện tại vẫn dùng được.

**Đảm bảo thành công.** `credentialReady=true` (với chứng thư) hoặc bí mật mới có hiệu lực, bí mật cũ chết sau 24 giờ; EVT-12-08 đã phát.

**Luồng chính.** (Đăng ký chứng thư)

1. Mai tải chứng thư `ht-qlvb.crt` hoặc dán JWKS. Hệ thống gọi API-12-064 (chứng thư) hoặc API-12-065 (khóa công khai).
2. Hệ thống phân tích: chứng thư phải nối tới CA của HTTT do OpenBao PKI cấp hoặc CA tỉnh đã chấp nhận, còn hạn ít nhất 30 ngày; khóa công khai phải là thuật toán cho phép (ES256, PS256).
3. Hệ thống tính dấu vân tay `x5t#S256` của chứng thư hoặc `kid` của khóa, lưu cùng hạn dùng; cho phép tối đa 2 chứng thư hoặc khóa đang hiệu lực để xoay không gián đoạn.
4. Hệ thống đặt `credentialReady=true`, đẩy dấu vân tay tới APISIX để so với claim `cnf` của token, ghi kiểm toán, phát EVT-12-08.
5. Trước hạn 30, 14, 7 ngày, hệ thống thông báo Hùng và Mai.

**Luồng thay thế.**

- **1a. Xoay bí mật (client `CLIENT_SECRET`).** Mai bấm "Xoay bí mật" và xác nhận (API-12-066). Hệ thống kiểm tra không có lần xoay đang chuyển tiếp, sinh bí mật mới từ 256 bit, đặt hiệu lực ngay, giữ bí mật cũ thêm 24 giờ (`12.client.secret-rotation-overlap-hours`), cất bản bọc dùng một lần trong OpenBao và thông báo Hùng nhận ở PH-01 hoặc PH-15; hết 24 giờ vô hiệu bí mật cũ, phát EVT-12-08. Hệ thống nhắc trước hạn 180 ngày vào ngày 30, 14, 7; quá hạn thì client `SUSPENDED` (UC-12-07).
- **1b. Xoay khẩn.** Dũng yêu cầu xoay khẩn khi nghi lộ (`invalidateOld=true`): bí mật cũ vô hiệu ngay, token đang lưu hành bị chặn theo UC-12-28.
- **1c. Xoay chứng thư.** Mai đăng ký chứng thư mới khi chứng thư cũ còn hiệu lực rồi gỡ cái cũ sau khi HTTT chuyển xong; client không còn chứng thư hiệu lực thì `credentialReady=false`.
- **1d. PH-01 trong saga.** PH-01 gọi API-12-064 sau khi cấp chứng thư từ CA của HTTT.

**Luồng ngoại lệ.**

- **E1. Chứng thư hoặc khóa không hợp lệ (bước 2).** ERR-12-021 (422); "Chứng thư không hợp lệ: {lý do: không tin cậy, hết hạn, thuật toán không được phép}."
- **E2. Đã đủ 2 chứng thư (bước 3).** ERR-12-043 (422); "Mỗi HTTT chỉ đăng ký tối đa 2 chứng thư cùng lúc. Gỡ chứng thư cũ trước."
- **E3. Client không dùng mTLS, `private_key_jwt` (bước 1) hoặc không dùng bí mật chia sẻ (1a).** ERR-12-022 (422); "HTTT này đang dùng bí mật chia sẻ." hoặc "HTTT này không dùng bí mật chia sẻ."
- **E4. Đang chuyển tiếp lần xoay trước (1a).** ERR-12-023 (409); "Đang có lần xoay bí mật trong thời gian chuyển tiếp tới {thời điểm}."
- **E5. OpenBao không khả dụng (1a).** ERR-12-039 (503); "Kho bí mật tạm thời không khả dụng; chưa xoay bí mật. Bí mật hiện tại vẫn dùng được."

**Quy tắc áp dụng.** BR-12-023, 024, 045.

**Màn hình, API.** UI-12-10; API-12-064, 065, 066.
:::

### 6.25. UC-12-25 · HTTT lấy token bằng client_credentials

::: dac-ta
**Mục tiêu.** HTTT thành viên lấy được access token ngắn hạn (5 phút), đúng phạm vi được duyệt, để gọi API qua Datahub mà không có người dùng cuối.

**Tác nhân chính.** HTTT thành viên `HT-QLVB` (client `ht-qlvb`, không cần `PERM`); Kafka listener ngoài dùng cùng token (SASL OAUTHBEARER).

**Tác nhân phụ.** Keycloak, lớp biên APISIX (kết thúc mTLS, chuyển dấu vân tay chứng thư), PH-13 (nhật ký).

**Mức ưu tiên.** M.

**FR hiện thực.** FR-12-035.

**Truy vết.** REQ-12; LGC-IAM-006; LGC-NGSP-008; LGC-BUS-041; SEC-24, SEC-25; CMP-LAW-09.

**Tiền điều kiện.** Client `ht-qlvb` `ENABLED`, `credentialReady=true`; realm `dh-t68` `ACTIVE`.

**Kích hoạt.** HTTT gửi yêu cầu tới điểm cuối `token` của realm tenant.

**Đảm bảo tối thiểu.** Không cấp token khi client tạm ngừng, thu hồi hoặc realm không hoạt động; không có refresh token cho máy; token chỉ mang giao của scope yêu cầu và scope được cấp.

**Đảm bảo thành công.** HTTT nhận access token ES256 sống 300 giây, gọi API được trong thời gian đó; sự kiện cấp token đã ghi (lấy mẫu).

**Luồng chính.**

1. HTTT gửi `POST /realms/dh-t68/protocol/openid-connect/token` (API-12-074) với `grant_type=client_credentials`, `scope=api:tra-cuu-ho-tich:goi-co-ban` và xác thực bằng mTLS; lớp biên kết thúc mTLS và chuyển dấu vân tay chứng thư tới Keycloak qua tiêu đề tin cậy.
2. Keycloak xác thực client: chứng thư khớp dấu vân tay đã đăng ký (hoặc chữ ký JWT hợp lệ với `exp` không quá 60 giây và `jti` chưa dùng, hoặc bí mật đúng).
3. Keycloak kiểm tra client `ENABLED` và realm `ACTIVE`.
4. Keycloak tính tập scope cấp bằng giao của scope yêu cầu và scope được cấp (UC-12-22); thiếu một phần thì cấp phần giao và ghi cảnh báo.
5. Keycloak phát access token JWT ký ES256, `expires_in=300`, mang `iss`, `sub`, `azp`, `tenant`, `org`, `scope`, `aud`, `jti` và `cnf` (khi mTLS).
6. Hệ thống ghi sự kiện (UC-12-37, lấy mẫu theo `12.event.token-sample`) và cập nhật `lastUsedAt` của client mỗi phút một lần.
7. HTTT gọi API với `Authorization: Bearer`; APISIX xác minh chữ ký bằng JWKS (UC-12-27) và hỏi OPA (UC-12-31).

**Luồng thay thế.**

- **2a. Client dùng `client_secret` ở mức thấp.** Xác thực bằng bí mật; token không có `cnf`.
- **5a. Yêu cầu nhiều lần liên tiếp.** HTTT nên dùng lại token tới gần hết hạn; vượt tần suất cho phép bị từ chối (E5).

**Luồng ngoại lệ.**

- **E1. Xác thực client sai (bước 2).** ERR-12-117 (401, `invalid_client`); cộng bộ đếm thất bại, vượt ngưỡng thì cảnh báo (UC-12-39). Lỗi theo RFC 6749 và hiển thị ở nhật ký người vận hành.
- **E2. Client tạm ngừng hoặc thu hồi (bước 3).** ERR-12-118 (403, `unauthorized_client`).
- **E3. Realm không hoạt động (bước 3).** ERR-12-121 (403); "Tỉnh {tên} đang tạm ngừng hoạt động."
- **E4. Scope giao rỗng (bước 4).** ERR-12-119 (400, `invalid_scope`).
- **E5. Dùng grant bị cấm hoặc vượt tần suất (bước 1).** ERR-12-122 (400, `unsupported_grant_type`) hoặc ERR-12-125 (429).

**Quy tắc áp dụng.** BR-12-004, 021, 024, 025, 026, 045.

**Màn hình, API.** Không có màn hình; API-12-074.
:::

### 6.26. UC-12-26 · Khai báo tài khoản dịch vụ của đơn vị triển khai

::: dac-ta
**Mục tiêu.** Mỗi đơn vị triển khai (DU) có đúng tài khoản dịch vụ và scope nội bộ cần thiết, xác thực bằng danh tính pod hoặc khóa riêng ở OpenBao, xoay khóa tự động, và mọi thay đổi đều qua duyệt bốn mắt.

**Tác nhân chính.** ROLE-PLATFORM_ADMIN (Hà) khai báo; ROLE-SECURITY_OFFICER (Dũng) duyệt.

**Tác nhân phụ.** Kho cấu hình GitOps, Keycloak (realm `dh-platform`), OpenBao, DU sử dụng tài khoản (ví dụ `dh-integration`).

**Mức ưu tiên.** M.

**FR hiện thực.** FR-12-037.

**Truy vết.** REQ-12; SEC-24, SEC-26; D02-08 §5 (scope máy nội bộ).

**Tiền điều kiện.** DU đã khai báo ở D03-01 §4; scope của tài khoản đã được phân hệ sở hữu định nghĩa (ví dụ `adapter:verify` của PH-05, `event:topic-register` của PH-10, `iam:*` của PH-12); Hà có `PERM-12-realm-admin`, Dũng có `PERM-12-approve`.

**Kích hoạt.** Khởi tạo nền tảng hoặc thêm DU mới (qua yêu cầu thay đổi ở GitOps); xoay khóa theo lịch.

**Đảm bảo tối thiểu.** Không sửa trực tiếp, không tài khoản dùng chung giữa các DU; khóa riêng chỉ ở OpenBao hoặc pod sở hữu, không có trong phản hồi.

**Đảm bảo thành công.** Tài khoản dịch vụ ở Keycloak và `ph12_iam` với đúng scope; khóa xoay mỗi 90 ngày; EVT-12-08 đã phát.

**Luồng chính.**

1. Hà mở yêu cầu thay đổi khai báo tài khoản dịch vụ ở kho cấu hình cho DU `dh-integration`: scope `adapter:verify`, `iam:directory-read`, phương thức xác thực `private_key_jwt`.
2. Dũng duyệt yêu cầu thay đổi (khác Hà; LP-12-01).
3. Hệ thống tạo client ở realm `dh-platform` dạng tài khoản dịch vụ, xác thực bằng chứng thư theo danh tính pod (SPIFFE) hoặc `private_key_jwt` với khóa ở OpenBao (API-12-070).
4. Hệ thống gán scope đúng khai báo; scope nội bộ chỉ cấp cho loại này (BR-12-025).
5. Hệ thống xoay khóa mỗi 90 ngày không gián đoạn (hai khóa cùng hiệu lực trong chuyển tiếp, API-12-071) và báo cáo xoay lên UI-12-10 (API-12-069).
6. Hệ thống ghi kiểm toán, phát EVT-12-08, trả `201` với scope và hạn xoay khóa (không có khóa riêng).

**Luồng thay thế.**

- **1a. DU ngừng dùng.** Gỡ khai báo, tài khoản `REVOKED`.
- **1b. Thêm scope.** Qua cùng quy trình duyệt, không sửa trực tiếp.

**Luồng ngoại lệ.**

- **E1. Người duyệt trùng người khai báo (bước 2).** ERR-12-008 (403); "Anh/chị là người khai báo nên không được tự duyệt."
- **E2. Scope không do phân hệ sở hữu định nghĩa (bước 4).** ERR-12-019 (422); "Phạm vi {scope} chưa được phân hệ sở hữu đăng ký."
- **E3. OpenBao không khả dụng (bước 3, 5).** ERR-12-039 (503); "Chưa cấp được khóa cho tài khoản dịch vụ. Thử lại sau."

**Quy tắc áp dụng.** BR-12-014, 025; bốn mắt theo FR-00-071.

**Màn hình, API.** UI-12-10 (tab Tài khoản dịch vụ); API-12-069, 070, 071.
:::

### 6.27. UC-12-27 · Xoay khóa ký và công bố JWKS

::: dac-ta
**Mục tiêu.** Khóa ký token của realm xoay đều mỗi 90 ngày mà không làm gián đoạn xác minh ở cổng; khi nghi lộ khóa, xoay khẩn có người duyệt thứ hai.

**Tác nhân chính.** Hệ thống (Keycloak, tác vụ xoay khóa); ROLE-PLATFORM_ADMIN (Hà) xoay khẩn; ROLE-SECURITY_OFFICER (Dũng) duyệt.

**Tác nhân phụ.** APISIX (lấy JWKS), PH-20 và PH-13 (nhận EVT-12-13).

**Mức ưu tiên.** M.

**FR hiện thực.** FR-12-039.

**Truy vết.** REQ-12; SEC-25; NFR-00-021; Q12-07.

**Tiền điều kiện.** Realm có khóa ký đang hoạt động (ES256 hoặc PS256); Hà có `PERM-12-realm-admin` khi xoay khẩn.

**Kích hoạt.** Lịch mỗi 90 ngày; hoặc lệnh xoay khẩn của Hà.

**Đảm bảo tối thiểu.** Xác minh token luôn thành công với khóa hiện hành và khóa vừa xoay; không giữ khóa quá 90 ngày.

**Đảm bảo thành công.** Một khóa ký đang hoạt động; khóa cũ biến mất khỏi JWKS sau 1 ngày; EVT-12-13 (loại `key-rotated`) đã phát.

**Luồng chính.**

1. Keycloak công bố các khóa công khai đang hoạt động và khóa cũ chỉ-xác-minh ở `/realms/dh-t68/protocol/openid-connect/certs` (API-12-075); mỗi khóa có `kid`.
2. APISIX lấy JWKS, đệm 10 phút và làm mới ngay khi gặp `kid` chưa biết.
3. Bảy ngày trước hạn 90 ngày, hệ thống tạo khóa mới ở trạng thái "đang hoạt động" để ký token mới; khóa cũ chuyển "chỉ xác minh".
4. Sau 1 ngày, khóa cũ bị gỡ khỏi JWKS.
5. Hệ thống ghi kiểm toán, phát EVT-12-13; lịch xoay hiện ở UI-12-19; chỉ số `iam_key_age_days` cập nhật.

**Luồng thay thế.**

- **3a. Xoay khẩn.** Hà đề nghị xoay khẩn khi nghi lộ khóa; Dũng duyệt (LP-12-01, LP-12-03); khóa cũ bị gỡ ngay và mọi token đã phát bị coi không hợp lệ; người dùng đăng nhập lại, HTTT lấy token mới (UC-12-25).
- **3b. Tác vụ xoay thất bại.** Hệ thống cảnh báo mức cao trước hạn 7 ngày.

**Luồng ngoại lệ.**

- **E1. Keycloak không khả dụng.** APISIX tiếp tục dùng JWKS đệm tới khi đủ 24 giờ hoặc gặp `kid` lạ; token mới không phát được; cảnh báo "Keycloak không khả dụng" ở người vận hành.
- **E2. `kid` lạ trong khi Keycloak không khả dụng.** Token bị từ chối ERR-12-116 (401); "Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại."
- **E3. Xoay khẩn thiếu người duyệt thứ hai (bước 3a).** ERR-12-008 (403).

**Quy tắc áp dụng.** BR-12-027.

**Màn hình, API.** UI-12-19 (lịch xoay khóa); API-12-075.
:::

### 6.28. UC-12-28 · Thu hồi truy cập tức thời

::: dac-ta
**Mục tiêu.** Khi nghi ngờ lộ tài khoản hoặc khóa, TA hoặc SO cắt truy cập của người dùng hoặc client, và cổng từ chối token đã cấp trong không quá 60 giây dù token chưa hết hạn.

**Tác nhân chính.** ROLE-TENANT_ADMIN (Mai); ROLE-SECURITY_OFFICER (Dũng); PH-01 khi hủy kết nối; hệ thống khi vô hiệu, tạm ngừng tự động.

**Tác nhân phụ.** Keycloak, APISIX (kéo danh sách chặn qua API), DU qua thư viện PEP (nhận EVT-12-05).

**Mức ưu tiên.** M.

**FR hiện thực.** FR-12-040.

**Truy vết.** REQ-12; LGC-IAM-005; SEC-25; BP-07.

**Tiền điều kiện.** Đối tượng bị thu hồi (người dùng `nguyenvana` hoặc client `ht-qlvb`) tồn tại trong tenant; người thao tác có `PERM-12-user-lock` (hoặc PH-01 có scope `iam:client-provision`).

**Kích hoạt.** Người dùng bấm "Thu hồi truy cập" ở UI-12-02 hoặc UI-12-10; hoặc UC-12-04, 07, 18, 23 gọi.

**Đảm bảo tối thiểu.** Không ai tự thu hồi truy cập của mình; Keycloak lỗi thì vẫn ghi danh sách chặn để cổng chặn trước.

**Đảm bảo thành công.** Đối tượng nhận `401` ở mọi cổng trong ≤ 60 giây; mục danh sách chặn tồn tại tới hết hạn giữ.

**Luồng chính.**

1. Dũng chọn tài khoản `nguyenvana` ở UI-12-02, bấm "Thu hồi truy cập", nhập lý do "Máy bị mất" và xác nhận.
2. Hệ thống gọi API-12-018; kiểm tra lý do và Dũng không phải chính tài khoản đó.
3. Hệ thống vô hiệu (người dùng) hoặc tạm ngừng (client) đối tượng ở Keycloak, hủy mọi phiên, thu hồi mọi refresh token.
4. Hệ thống ghi một mục vào danh sách chặn: `sub` hoặc `client`, mốc `notBefore` = bây giờ, hạn giữ bằng thời hạn token lớn nhất cộng 30 giây; mọi token có `iat` trước mốc bị từ chối.
5. Hệ thống phát EVT-12-05 để các DU nhận qua Kafka; APISIX lấy danh sách qua API-12-079 mỗi 10 giây bằng scope `iam:revocation-read`.
6. Hệ thống hiện "Đã áp dụng ở {n}/{m} nút cổng" theo số phiên bản danh sách mà các nút báo về; ghi kiểm toán kèm lý do và người thực hiện; trả `202`.
7. `nguyenvana` gọi API kế tiếp bằng token cũ và nhận `401` ở cổng trong không quá 60 giây.

**Luồng thay thế.**

- **1a. Thu hồi client.** Dũng hoặc Mai thu hồi client `ht-qlvb` (API-12-062); PH-01 gọi API này khi hủy kết nối (UC-12-23).
- **1b. Thu hồi một token cụ thể.** Gọi điểm cuối `revoke` của Keycloak theo RFC 7009 (API-12-077): thêm mục `jti`.
- **1c. Thu hồi hàng loạt theo đơn vị.** Lặp từng tài khoản, có xác nhận kép.

**Luồng ngoại lệ.**

- **E1. Thiếu lý do (bước 2).** ERR-12-014 (400); "Nhập lý do thu hồi."
- **E2. Tự thu hồi (bước 2).** ERR-12-013 (403); "Anh/chị không thể tự thu hồi truy cập của mình."
- **E3. Không đẩy được danh sách tới một nút cổng quá 60 giây (bước 6).** Cảnh báo nghiêm trọng gửi SO; token còn hiệu lực tối đa 5 phút; giao diện hiện "Chưa áp dụng ở {n} nút."
- **E4. Keycloak không phản hồi (bước 3).** ERR-12-038 (503); hệ thống vẫn ghi danh sách chặn để cổng chặn trước và thử Keycloak lại.

**Quy tắc áp dụng.** BR-12-026, 028, 033.

**Màn hình, API.** UI-12-02, 10; API-12-018, 062, 077, 079.
:::

### 6.29. UC-12-29 · Khởi tạo realm của tenant và giữ cấu hình bằng GitOps

::: dac-ta
**Mục tiêu.** Tỉnh mới có realm Keycloak riêng giống hệt mẫu, quản trị tỉnh đầu tiên nhận thư kích hoạt, và cấu hình bảo mật của realm luôn khớp kho Git; mọi sai lệch được phát hiện trong tối đa 1 giờ.

**Tác nhân chính.** PH-20 (scope `iam:realm-provision`) trong saga khởi tạo tenant; ROLE-PLATFORM_ADMIN (Hà) đối chiếu.

**Tác nhân phụ.** Keycloak (`keycloak-config-cli`), OpenBao, kho Git cấu hình và Argo CD, ROLE-SECURITY_OFFICER (duyệt thay đổi mẫu).

**Mức ưu tiên.** M.

**FR hiện thực.** FR-12-041, 042.

**Truy vết.** REQ-12; REQ-20; LGC-IAM-002; SEC-20, SEC-65; THR-38; BP-08; NFR-00-057.

**Tiền điều kiện.** Bản ghi tenant `T68` đã tạo ở bước `S01_RECORD` của saga (D03-10 §5.2); mẫu `dh-realm-template` có ở kho cấu hình; chưa có realm `dh-t68`.

**Kích hoạt.** PH-20 gọi API tạo realm kèm mã tenant; về sau là đồng hồ hằng giờ, hoặc Hà bấm "Đối chiếu ngay" ở UI-12-19, hoặc yêu cầu hợp nhất thay đổi mẫu được duyệt.

**Đảm bảo tối thiểu.** Gọi lại cùng `idempotencyKey` thì tiếp tục từ bước đang dở, không tạo trùng; bí mật client chỉ ở OpenBao; quản trị tỉnh không sửa được cấu hình bảo mật realm.

**Đảm bảo thành công.** Realm `dh-t68` `ACTIVE` giống mẫu bản `gitCommit` (khởi tạo ≤ 5 phút); `driftStatus=CLEAN` ở các lần kiểm tra hằng giờ; EVT-12-13 đã phát.

**Luồng chính.**

1. PH-20 gọi API-12-080 kèm mã tenant `T68`, `idempotencyKey` và thư điện tử quản trị tỉnh đầu tiên `mai@t68.gov.vn`. Hệ thống kiểm tra bên gọi có scope `iam:realm-provision` và mã hợp lệ.
2. Hệ thống tạo realm `dh-t68` từ mẫu ở trạng thái `PROVISIONING` bằng `keycloak-config-cli`: chính sách mật khẩu, phát hiện dò, thời hạn token, danh sách grant cho phép, luồng xác thực.
3. Hệ thống tạo khóa ký ES256, client `dh-console`, `dh-portal` (bí mật, PKCE `S256`, `redirect_uri` khớp tên miền tenant), ghi bí mật client vào OpenBao.
4. Hệ thống tạo 22 vai trò chuẩn (trừ `PLATFORM_*`), nhóm `mfa-required` ánh xạ theo vai trò, vai trò `realm-user-admin` cho quản trị tỉnh; cấu hình nhà môi giới nền tảng ở trạng thái ẩn (UC-12-13).
5. Hệ thống tạo quản trị tỉnh đầu tiên ở `PENDING_ACTIVATION`, gán `TENANT_ADMIN`, buộc đặt mật khẩu và đăng ký WebAuthn, gửi liên kết kích hoạt (UC-12-02 bước 6).
6. Hệ thống kiểm tra khói rồi đặt realm `ACTIVE`, nạp dữ liệu gói chính sách của tenant (UC-12-33), ghi kiểm toán, phát EVT-12-13 và EVT-12-01, trả `201` cho PH-20.
7. Hằng giờ, tác vụ giám sát xuất cấu hình bảo mật của từng realm và so với mẫu ở Git; không khác biệt thì ghi `driftStatus=CLEAN`.
8. Một quản trị Keycloak sửa chính sách mật khẩu của `dh-t68` ngoài Git. Lần kiểm tra kế tiếp đặt `driftStatus=DRIFTED`, phát cảnh báo mức cao cho SO và PA nêu trường lệch và người thay đổi; nếu `12.realm.auto-reconcile` bật (mặc định bật cho trường bảo mật), hệ thống tự áp lại mẫu sau 15 phút, trừ khi SO xác nhận "giữ tạm" kèm lý do.
9. Hà xem trạng thái ở UI-12-19 (API-12-081, API-12-082); khi cần bấm "Áp lại mẫu" (API-12-083, trả `202`). Hệ thống ghi kiểm toán mỗi lần lệch và áp lại, phát EVT-12-13 (loại `drift`, `reconciled`).

**Luồng thay thế.**

- **1a. Saga thử lại.** PH-20 gọi lại cùng `idempotencyKey`; hệ thống tiếp tục từ bước dở. Bù trừ: PH-20 gọi xóa realm đang ở `PROVISIONING`.
- **9a. Thay đổi mẫu hợp lệ.** Hà soạn yêu cầu hợp nhất ở Git, Dũng duyệt (khác người), CI chạy kiểm thử cấu hình trên realm thử rồi áp dần theo từng tenant. Thay đổi khẩn cấp cũng đi qua yêu cầu hợp nhất nhưng SO duyệt ưu tiên.

**Luồng ngoại lệ.**

- **E1. Realm đã có ở trạng thái khác `PROVISIONING` (bước 1).** ERR-12-041 (409); "Realm của tỉnh {mã} đã tồn tại."
- **E2. Keycloak hoặc kho cấu hình không khả dụng (bước 2).** ERR-12-038, ERR-12-040 (503); saga PH-20 dừng ở `FAILED`, cho phép thử lại từ bước này.
- **E3. OpenBao không khả dụng (bước 3).** ERR-12-039 (503); chưa ghi được bí mật client nên chưa đặt realm `ACTIVE`.
- **E4. Thiếu thư điện tử quản trị đầu tiên hoặc sai miền (bước 1).** ERR-12-003 (400); "Cần thư điện tử hợp lệ của quản trị tỉnh đầu tiên."
- **E5. Không xuất được cấu hình (bước 7).** ERR-12-038 (503); ghi `driftStatus=UNKNOWN`, cảnh báo sau 3 lần liên tiếp.
- **E6. Áp lại khi realm đang được đối chiếu (bước 9).** ERR-12-042 (409); "Realm đang được đối chiếu, thử lại sau."
- **E7. Quản trị tỉnh cố sửa cấu hình bảo mật.** Keycloak từ chối vì vai trò `realm-user-admin` không có quyền `manage-realm` (BR-12-038); không có chức năng nào cho phép.

**Quy tắc áp dụng.** BR-12-004, 014, 021, 031, 038.

**Màn hình, API.** UI-12-19; API-12-080, 081, 082, 083.
:::

### 6.30. UC-12-30 · Tạm ngừng, khôi phục, chuyển chỉ-đọc realm

::: dac-ta
**Mục tiêu.** Khi tenant bị tạm ngừng, sáp nhập hoặc chấm dứt, định danh của tỉnh đổi trạng thái đồng bộ với vòng đời tenant: trong 60 giây người dùng thường không còn dùng được token, riêng quản trị tỉnh vào được ở chế độ chỉ-đọc.

**Tác nhân chính.** PH-20 (scope `iam:realm-provision`); ROLE-PLATFORM_ADMIN (Hà) khi PH-20 chưa phản hồi.

**Tác nhân phụ.** Keycloak, OpenBao (xóa bí mật khi `DELETED`), APISIX (danh sách chặn), ROLE-TENANT_ADMIN (nhận thông báo).

**Mức ưu tiên.** M.

**FR hiện thực.** FR-12-043.

**Truy vết.** REQ-12; REQ-20; D03-10 §5.1; ERR-20-001.

**Tiền điều kiện.** Realm `dh-t68` tồn tại; chuyển trạng thái hợp lệ theo máy trạng thái realm (FRS mục 4.7); Hà có `PERM-12-realm-admin` khi thay PH-20.

**Kích hoạt.** PH-20 đổi trạng thái tenant `T68` (tạm ngừng, khôi phục, sáp nhập, chấm dứt).

**Đảm bảo tối thiểu.** Không xóa dữ liệu người dùng trừ khi `DELETED` sau khi đã bàn giao và hết thời gian giữ; thao tác idempotent.

**Đảm bảo thành công.** Realm ở trạng thái đích; EVT-12-13 và EVT-12-05 đã phát.

**Luồng chính.**

1. PH-20 gọi API-12-084 (tạm ngừng) kèm lý do "Chưa gia hạn hợp đồng", `essentialScopes` rỗng.
2. Hệ thống kiểm tra chuyển `ACTIVE` sang `SUSPENDED` hợp lệ.
3. Hệ thống hủy mọi phiên người dùng trừ quản trị tỉnh, đẩy danh sách chặn cho mọi client và người dùng của realm (UC-12-28), đặt cờ chỉ-đọc trong token của quản trị tỉnh.
4. Hệ thống ghi kiểm toán, phát EVT-12-13 và EVT-12-05, trả `200` (trạng thái, số phiên đã hủy, số mục danh sách chặn).
5. Trong 60 giây, người dùng thường của `T68` đăng nhập nhận ERR-12-121, mọi client nhận `403`; Mai đăng nhập được ở chế độ chỉ-đọc.
6. Khi tenant được khôi phục, PH-20 gọi API-12-085; hệ thống đặt `ACTIVE`, bỏ chặn và cờ chỉ-đọc, thông báo Mai.

**Luồng thay thế.**

- **1a. Tạm ngừng có API thiết yếu.** Với `essentialScopes[]` theo quyết định tạm ngừng cho phép, client vẫn lấy được token nhưng chỉ chứa scope thiết yếu.
- **1b. Sáp nhập.** Realm sang `READ_ONLY`: token có cờ chỉ-đọc cho mọi người dùng, không cấp client mới (client cũ chuyển tiếp theo UC-12-15).
- **1c. Chấm dứt.** Realm sang `DELETED` sau khi dữ liệu đã bàn giao và hết thời gian giữ: xóa realm, hủy khóa ký, xóa bí mật client ở OpenBao.
- **1d. PH-20 chưa phản hồi.** Hà gọi API-12-084 hoặc API-12-085 trực tiếp.

**Luồng ngoại lệ.**

- **E1. Chuyển trạng thái sai (bước 2).** ERR-12-041 (409); "Realm đang ở trạng thái {trạng thái}, không chuyển sang {trạng thái đích} được."
- **E2. Người dùng đăng nhập khi realm tạm ngừng (bước 5).** ERR-12-121 (403); "Tỉnh {tên} đang tạm ngừng hoạt động." (kèm ERR-20-001 của PH-20).
- **E3. Keycloak không phản hồi (bước 3).** ERR-12-038 (503); PH-20 thử lại, thao tác idempotent.

**Quy tắc áp dụng.** BR-12-028, 038.

**Màn hình, API.** UI-12-19; API-12-084, 085.
:::

### 6.31. UC-12-31 · Quyết định ủy quyền theo hợp đồng PEP và PDP

::: dac-ta
**Mục tiêu.** Mọi yêu cầu API và thao tác nghiệp vụ của Datahub được kiểm tra quyền bằng một hợp đồng duy nhất giữa bên thực thi (PEP) và OPA (PDP); mặc định từ chối, từ chối thắng cho phép, cách ly tenant, và hết thời gian chờ không bao giờ mở cửa.

**Tác nhân chính.** APISIX (PH-03), thư viện PEP của DU, `dh-runtime`.

**Tác nhân phụ.** OPA cục bộ trong pod, gói chính sách đã ký (UC-12-33, 35), bên gọi qua API quyết định (scope `iam:decide`), PH-09 (áp mặt nạ).

**Mức ưu tiên.** M.

**FR hiện thực.** FR-12-044, 045, 046, 047.

**Truy vết.** REQ-12; REQ-09; LGC-BUS-032, LGC-BUS-041; SEC-26, SEC-80, SEC-81, SEC-85, SEC-31, SEC-37; ADR-006; CMP-LAW-05, CMP-LAW-09.

**Tiền điều kiện.** OPA đã nạp gói chính sách ký hợp lệ (gói gốc `base-authz` của nền tảng và gói của tenant); token đã được xác minh chữ ký ở cổng.

**Kích hoạt.** Mỗi yêu cầu API hoặc thao tác nghiệp vụ cần kiểm tra quyền.

**Đảm bảo tối thiểu.** Không có luật cho phép nào khớp thì không được phép; mọi lỗi, hết thời gian chờ, OPA chưa nạp gói đều bị xử lý như từ chối; không "thử lại rồi cho qua"; tài nguyên mức Nhạy cảm không ghi được vết thì không phục vụ.

**Đảm bảo thành công.** Quyết định `allow` hoặc từ chối kèm lý do, `fieldMask`, `privacyMode`, `obligations[]`; nhật ký quyết định đã sinh (UC-12-37).

**Luồng chính.**

1. `nguyenvana` (vai trò `ROLE-INTEGRATION_ENGINEER`, phạm vi `ORG` = `SKHCN`) gọi `PUT /api/integration/v1/connections/qlvb-soap` của tenant `T68`. APISIX xác minh chữ ký token và dựng `input` từ token đã xác minh (không từ tham số bên gọi): `tenant`, `subject` (loại, mã, vai trò, scope, đơn vị, `acr`, `auth_time`), `resource` (loại, mã, đơn vị chủ quản, mức phân loại), `action`, `context`.
2. APISIX gọi OPA cục bộ với thời gian chờ tối đa 50 ms (`12.pep.timeout-ms`).
3. OPA đặt `allow := false` mặc định, tính tập `deny` từ gói gốc rồi gói tenant: tenant của yêu cầu khác tenant của tài nguyên và không có quyền có thời hạn hợp lệ thì từ chối `TENANT_MISMATCH`; tài nguyên nhãn bí mật nhà nước thì từ chối `DATA_CLASSIFIED_SECRET` không điều kiện.
4. OPA kiểm tra ba lớp: vai trò (giao vai trò trong token và bản gán còn hiệu lực, quyền thuộc `role_perms`), tổ chức (ma trận ghi ○ hoặc bản gán `ORG` thì đơn vị chủ quản của tài nguyên phải là đơn vị gán hoặc cấp dưới), thuộc tính dữ liệu (mức phân loại so với `acr` và hợp đồng, mục đích khai thác). Điều kiện bổ sung của tenant chỉ làm chặt thêm.
5. OPA trả `allow`, `reason`, `matchedPolicy`, `bundleRevision`, `fieldMask`, `privacyMode`, `obligations[]`, `evaluationTimeMs`. Với `read`, `export`, OPA tính `fieldMask`: trường Nhạy cảm `hidden` trừ khi có `PERM-09-unmask` kèm lý do và `acr` đủ; trường Hạn chế `masked` khi mục đích không nằm trong danh sách cho phép.
6. Khi cho phép, APISIX thực hiện nghĩa vụ trả về (`AUDIT`, `STEPUP`, `MASK`, `TTL`) rồi chuyển yêu cầu tới `dh-integration`; khi từ chối, trả `403`, hoặc `404` nếu đối tượng thuộc tenant hay tổ chức khác (D02-08 §7).
7. Quyết định được ghi vết theo UC-12-37.

**Luồng thay thế.**

- **1a. DU không có OPA cạnh.** Gọi `POST /api/authz/v1/decide` (API-12-086) bằng scope `iam:decide`; API luôn trả `200` với `allow` đúng, lỗi của chính cuộc gọi tách riêng.
- **3a. Truy cập liên tenant hợp lệ.** `input.subject.grantId` khớp quyền có thời hạn còn hiệu lực cho tenant của tài nguyên thì không bị `TENANT_MISMATCH` (UC-12-13).
- **5a. Thao tác đòi xác thực bước lên.** Lớp thuộc tính trả nghĩa vụ `STEPUP` thay vì từ chối (UC-12-17).
- **5b. Xuất dữ liệu.** Mọi trường Hạn chế trở lên mặc định `masked` trừ khi có quyền và lý do (FR-00-034).
- **5c. Truy vấn quyền hiệu lực.** UC-12-08 dùng cùng logic qua API-12-013.

**Luồng ngoại lệ.**

- **E1. Từ chối do không có luật cho phép (bước 3, 4).** `reason` = `NO_MATCHING_POLICY`, `ROLE_MISSING`, `ORG_SCOPE_MISMATCH`, `SCOPE_MISSING`, `PURPOSE_NOT_DECLARED`; người dùng thấy ERR-12-007 (403) "Bạn không có quyền thực hiện thao tác này. Liên hệ quản trị tỉnh nếu cần được cấp quyền."; đối tượng của tổ chức khác trả ERR-12-001 (404).
- **E2. Thiếu trường bắt buộc trong `input` (bước 2).** ERR-12-101 (400); không có câu hiển thị (lỗi lập trình ở PEP), PEP từ chối yêu cầu gốc với `403`.
- **E3. Bên gọi API quyết định chưa xác thực hoặc thiếu scope (bước 1a).** ERR-12-102 (401).
- **E4. Lỗi đánh giá Rego (bước 3).** ERR-12-103 (500); xử lý như từ chối, cảnh báo nghiêm trọng, gói bị đánh dấu lỗi để đề xuất quay lui (UC-12-36).
- **E5. OPA quá tải hoặc chưa nạp gói, hoặc hết thời gian chờ (bước 2).** ERR-12-104 (503); xử lý như từ chối với `reason=POLICY_ERROR`; người dùng thấy "Hệ thống tạm thời không xác nhận được quyền của anh/chị. Thử lại sau."
- **E6. Không ghi được vết cho tài nguyên mức Nhạy cảm (bước 7).** ERR-12-124 (403); "Hệ thống chưa ghi được vết truy cập nên không phục vụ dữ liệu này. Thử lại sau."
- **E7. Thực thể chưa khai báo tập trường (bước 5).** `fieldMask` rỗng kèm cảnh báo `ENTITY_FIELDS_UNDECLARED`; API trả `403` (BR-12-040).

**Quy tắc áp dụng.** BR-12-001, 002, 003, 004, 005, 006, 007, 013, 036, 037, 040, 041.

**Màn hình, API.** Không có màn hình; API-12-013, 086.
:::

### 6.32. UC-12-32 · Quyết định theo lô, theo XACML và bộ đệm quyết định

::: dac-ta
**Mục tiêu.** Bên thực thi hỏi quyền cho nhiều đối tượng trong một lời gọi, bên tích hợp theo chuẩn XACML nhận quyết định đúng chuẩn, và thư viện PEP giảm tải cho OPA bằng bộ đệm mà không bao giờ dùng quyết định lỗi thời.

**Tác nhân chính.** DU và thư viện PEP (lô, bộ đệm); HTTT tích hợp theo XACML hoặc hệ thống thẩm định (scope `iam:decide`).

**Tác nhân phụ.** OPA, PH-13 (nhật ký quyết định).

**Mức ưu tiên.** M (FR-12-048), S (FR-12-049, 050).

**FR hiện thực.** FR-12-048, 049, 050.

**Truy vết.** REQ-12; CMP-LAW-09; ADR-006; Q12-03.

**Tiền điều kiện.** Như UC-12-31; bảng ánh xạ thuộc tính XACML sang `input` đã cấu hình; tham số `12.cache.ttl-seconds` lớn hơn 0 (mặc định 60) với bộ đệm.

**Kích hoạt.** PEP cần quyết định cho nhiều đối tượng cùng chủ thể, cùng hành động; hoặc bên gọi gửi `POST /api/authz/v1/xacml` với `Content-Type: application/xacml+xml` hoặc `application/xacml+json`; hoặc mỗi lần PEP cần quyết định.

**Đảm bảo tối thiểu.** Phần tử lỗi trong lô không làm hỏng cả lô; `NotApplicable` và `Indeterminate` được hiểu là không được phép; bộ đệm không bao giờ giữ quyết định của gói cũ.

**Đảm bảo thành công.** Lô trả mảng kết quả khớp `itemId`; phản hồi XACML đúng lược đồ; quyết định lấy từ bộ đệm hoặc OPA đúng chính sách hiện hành.

**Luồng chính.**

1. Dịch vụ `dh-integration` cần biết quyền xem của `nguyenvana` trên 60 luồng ở một trang danh sách. PEP gửi một yêu cầu lô tới `POST /api/authz/v1/decide:batch` (API-12-087) gồm `subject`, `action`, `context` chung và `items[]`.
2. Hệ thống kiểm tra số phần tử không quá 100 và mỗi phần tử có `itemId`.
3. OPA đánh giá từng phần tử độc lập theo UC-12-31; phần tử lỗi trả từ chối kèm `reason=POLICY_ERROR`.
4. Hệ thống trả `200` với `results[]` (`itemId`, `allow`, `reason`, `fieldMask`) và ghi vết từng phần tử (UC-12-37).
5. Ở đường dữ liệu thường, PEP tra bộ đệm cục bộ theo khóa (có `bundleRevision`). Trúng và chưa quá TTL: trả quyết định đã đệm kèm nghĩa vụ, bỏ qua OPA. Trượt: hỏi OPA và đệm kết quả khi nghĩa vụ `TTL` cho phép (tối đa 60 giây; quyết định từ chối chỉ đệm tối đa 10 giây).
6. Khi gói chính sách đổi `bundleRevision` (UC-12-35), toàn bộ bộ đệm cũ không còn khớp khóa nên không cần xóa tay.

**Luồng thay thế.**

- **1a. Gọi theo XACML.** Hệ thống thẩm định gửi yêu cầu XACML (API-12-088). Hệ thống kiểm tra scope `iam:decide` và lược đồ (yêu cầu 2.0 được chuyển sang 3.0 nội bộ), trích `Subject`, `Resource`, `Action`, `Environment`, ánh xạ sang `input` của OPA và gọi OPA. Phản hồi: `Permit` khi `allow=true`; `Deny` khi có luật từ chối khớp; `NotApplicable` khi không có chính sách nào khớp; `Indeterminate` khi lỗi. Phản hồi dạng JSON khi gửi bằng JSON Profile; quyết định được ghi vết như mọi quyết định.
- **5a. Không đệm.** Không đệm quyết định cho tài nguyên mức Nhạy cảm, nghĩa vụ `STEPUP`, và quyết định có `AUDIT` mức `FULL` của dữ liệu cá nhân.
- **5b. Tắt đệm.** Đặt TTL bằng 0; hoặc bộ đệm không khả dụng (hết bộ nhớ) thì hỏi OPA trực tiếp và ghi nhận độ trễ tăng; bộ nhớ đệm đầy thì loại mục cũ nhất, không có lỗi hiển thị.
- **2a. DU có OPA cạnh.** Gọi cục bộ từng phần tử; API lô dành cho bên không có OPA cạnh.

**Luồng ngoại lệ.**

- **E1. Lô quá 100 phần tử hoặc thiếu `itemId` (bước 2).** ERR-12-101 (400); PEP chia nhỏ lô.
- **E2. OPA quá tải hoặc chưa nạp gói (bước 3).** ERR-12-104 (503); cả lô xử lý như từ chối.
- **E3. Yêu cầu XACML sai lược đồ (bước 1a).** ERR-12-123 (400); phản hồi `Indeterminate` kèm `StatusCode` `urn:oasis:names:tc:xacml:1.0:status:syntax-error`.
- **E4. Thiếu thuộc tính bắt buộc (bước 1a).** Phản hồi `Indeterminate` kèm `missing-attribute`.
- **E5. Bên gọi thiếu scope (bước 1a).** ERR-12-102 (401).
- **E6. OPA lỗi hoặc quá tải (bước 1a).** ERR-12-103, ERR-12-104; phản hồi `Indeterminate`.

**Quy tắc áp dụng.** BR-12-001, 006, 012.

**Màn hình, API.** Không có màn hình; API-12-087, 088.
:::

### 6.33. UC-12-33 · Sinh dữ liệu vai trò–quyền cho OPA

::: dac-ta
**Mục tiêu.** Quyền hiệu lực của người dùng và scope của client luôn khớp dữ liệu gốc (ma trận D02-08, bản gán, đơn vị, scope) trong tối đa 60 giây, được đóng gói và ký để OPA chỉ nạp dữ liệu đáng tin.

**Tác nhân chính.** Hệ thống (bộ ghi chính sách của `dh-platform`).

**Tác nhân phụ.** OpenBao (khóa ký gói), bucket `dh-platform-policy`, OPA, ROLE-PLATFORM_ADMIN (xem kết quả).

**Mức ưu tiên.** M.

**FR hiện thực.** FR-12-051.

**Truy vết.** REQ-12; D02-08 §3; SEC-26; ADR-068.

**Tiền điều kiện.** Ma trận D02-08 đã chuyển thành tệp dữ liệu `permissions` ở kho `dh-policies` qua CI; khóa ký gói có ở OpenBao.

**Kích hoạt.** Sự kiện thay đổi dữ liệu nguồn (gán vai trò, quyền có thời hạn, đơn vị, scope client, tenant đổi trạng thái); hoặc đồng hồ 30 giây; hoặc đổi ma trận D02-08; hoặc kích hoạt tay `POST /policy-data:regenerate`.

**Đảm bảo tối thiểu.** Dữ liệu không nhất quán thì không phát hành gói mới, giữ gói cũ; OPA từ chối gói không có chữ ký hợp lệ.

**Đảm bảo thành công.** Gói dữ liệu mới có chữ ký ở kho; mọi OPA nạp thành công trong ≤ 60 giây; EVT-12-09 đã phát.

**Luồng chính.**

1. Mai gán vai trò cho `nguyenvana` (UC-12-09); EVT-12-03 phát ra. Bộ ghi chính sách gom thay đổi nguồn trong cửa sổ 5 giây rồi dựng `data.json` của `T68`: `role_perms`, `assignments` (hiệu lực, phạm vi, hạn), `grants`, `org_tree`, `client_scopes`.
2. Hệ thống kiểm tra nhất quán: mọi vai trò trong `assignments` có trong `role_perms`; không có quyền nào ngoài danh mục D02-08; không có người dùng mang cặp xung đột không có ngoại lệ.
3. Hệ thống đóng gói gói dữ liệu của tenant, ký bằng khóa lấy từ OpenBao và đặt vào `dh-platform-policy/t68/`.
4. OPA tải gói của tenant cùng gói gốc mỗi 30 giây, xác minh chữ ký rồi mới nạp; mỗi OPA báo `bundleRevision` đang chạy.
5. Hệ thống đo độ trễ từ lúc dữ liệu nguồn đổi tới lúc mọi OPA nạp và ghi `iam_policy_reload_seconds` (mục tiêu ≤ 60 giây); phát EVT-12-09 khi gói mới có hiệu lực.
6. Hà xem gói hiện hành và trạng thái nạp ở UI-12-12 (API-12-101).

**Luồng thay thế.**

- **1a. Đổi ma trận D02-08 (gói gốc, mọi tenant).** Không tự phát hành: đi qua UC-12-34 và UC-12-35 vì thay đổi quyền của nền tảng cần người duyệt.
- **1b. Tenant mới.** Gói dữ liệu khởi tạo trong UC-12-29.
- **1c. Kích hoạt tay.** PA hoặc hệ thống gọi API-12-102, trả `202`.

**Luồng ngoại lệ.**

- **E1. Dữ liệu nguồn không nhất quán (bước 2).** ERR-12-040 (503); giữ gói cũ, UI-12-12 hiện "Gói dữ liệu của tỉnh chưa cập nhật từ {thời điểm}: {lý do}."; cảnh báo cho PA.
- **E2. OpenBao không ký được (bước 3).** ERR-12-039 (503); giữ gói cũ, cảnh báo nghiêm trọng.
- **E3. Gói vượt kích thước tối đa 20 MiB (bước 3).** Lỗi dựng, cảnh báo, chia dữ liệu theo đơn vị.

**Quy tắc áp dụng.** BR-12-010, 030, 036.

**Màn hình, API.** UI-12-12; API-12-101, 102.
:::

### 6.34. UC-12-34 · Soạn, kiểm thử và chạy khô chính sách

::: dac-ta
**Mục tiêu.** Người soạn viết chính sách Rego, biết chắc nó đúng cú pháp, qua ca kiểm thử và, trước khi ai duyệt, biết chính sách mới sẽ đổi bao nhiêu quyết định trên lưu lượng thật.

**Tác nhân chính.** ROLE-PLATFORM_ADMIN (Hà, chính sách nền tảng); ROLE-SECURITY_OFFICER (Dũng, chính sách của tỉnh).

**Tác nhân phụ.** Kho Git `dh-policies`, `opa check`, `opa test`, nhật ký quyết định (Loki, đã che dữ liệu), hai OPA cô lập.

**Mức ưu tiên.** M.

**FR hiện thực.** FR-12-052, 053.

**Truy vết.** REQ-12; SEC-26; ADR-006; ADR-068.

**Tiền điều kiện.** Người soạn có `PERM-12-policy-edit` và đã xác thực mức 3 trong 5 phút khi lưu; kho chính sách hoạt động; với chạy khô, nhật ký quyết định có đủ yêu cầu của cửa sổ chạy khô.

**Kích hoạt.** Dũng bấm "+ Chính sách" hoặc "Phiên bản mới" ở UI-12-12; sau đó bấm "Chạy khô" ở UI-12-13.

**Đảm bảo tối thiểu.** Phiên bản nháp không ảnh hưởng OPA nào đang chạy; chính sách của tỉnh không có luật `allow`, không nới quyền; sửa nội dung làm mất kết quả kiểm thử và chạy khô đã có.

**Đảm bảo thành công.** Phiên bản `DRAFT` đạt cú pháp, kiểm thử (ít nhất một ca dương, một ca âm, độ phủ từ 90%) và có báo cáo chạy khô gắn đúng `contentHash`, sẵn sàng gửi duyệt.

**Luồng chính.**

1. Dũng tạo chính sách `ngoai-gio-lam-viec` (phạm vi `TENANT`, mô tả "Chặn ghi cấu hình ngoài giờ hành chính") ở UI-12-12. Hệ thống gọi API-12-091 (hoặc API-12-092 cho phiên bản mới từ bản `PUBLISHED`); phiên bản ở `DRAFT`.
2. Dũng viết luật Rego `deny` và các ca kiểm thử (đầu vào JSON, kết quả mong đợi) ở trình soạn có tô màu cú pháp.
3. Khi lưu, hệ thống chạy `opa check` và `opa fmt`, rồi `opa test` (API-12-094) với các ca đã khai báo, đo độ phủ.
4. Với chính sách phạm vi `TENANT`, hệ thống kiểm tra tĩnh: chỉ được thêm luật `deny` và nghĩa vụ, không có luật `allow`, không tham chiếu dữ liệu tenant khác.
5. Hệ thống lưu nội dung vào Git (một commit mỗi phiên bản), ghi `contentHash`; kết quả kiểm thử gắn với `contentHash`.
6. Dũng chuyển UI-12-13 và bấm "Chạy khô". Hệ thống gọi API-12-095 (`202`): lấy mẫu yêu cầu quyết định gần nhất từ nhật ký đã che (toàn bộ từ chối và quyết định mức Nhạy cảm, lấy mẫu phần còn lại).
7. Hệ thống chạy hai OPA cô lập, một với gói đang `PUBLISHED`, một với gói đã thay phiên bản nháp, so kết quả từng yêu cầu.
8. Hệ thống tổng hợp: số yêu cầu, số đổi, tỷ lệ đổi, cho phép sang từ chối, từ chối sang cho phép, nhóm theo chủ thể, tài nguyên, chính sách, 20 ví dụ tiêu biểu; đánh dấu "nới quyền" cho mọi trường hợp từ chối sang cho phép và đánh dấu đỏ khi tỷ lệ đổi vượt 20%.
9. Hệ thống gắn kết quả với `contentHash` và `bundleRevision`; Dũng thấy "sẽ chặn thêm 1.240 yêu cầu vốn đang được phép, chủ yếu từ HTTT HT-QLVB" và tải báo cáo CSV cho người duyệt.

**Luồng thay thế.**

- **1a. Bỏ bản nháp.** Phiên bản chuyển `DISCARDED`.
- **1b. Soạn từ phiên bản cũ.** Để quay lui nội dung.
- **2a. Nhiều người đóng góp.** Mỗi người được ghi nhận để bốn mắt tính đủ (UC-12-35).
- **6a. Mẫu quá ít.** Dưới 100 yêu cầu: báo "Mẫu quá ít để đánh giá tác động", vẫn cho gửi duyệt nhưng ghi dấu.
- **6b. Quá thời gian 10 phút.** Dừng, trả kết quả một phần kèm cảnh báo.
- **9a. Sửa lại.** Sửa nội dung thì kết quả hết hiệu lực; chạy lại từ bước 3.

**Luồng ngoại lệ.**

- **E1. Sai cú pháp (bước 3).** ERR-12-024 (422); "Chính sách sai cú pháp ở dòng {n}: {thông báo}."
- **E2. Ca kiểm thử không đạt hoặc thiếu ca âm (bước 3).** ERR-12-025 (409); "Còn {n} ca kiểm thử không đạt hoặc chưa có ca âm."
- **E3. Chính sách của tỉnh có luật cho phép hoặc nới quyền (bước 4).** ERR-12-028 (422); "Chính sách của tỉnh chỉ được thêm luật từ chối. Luật {tên} cho phép truy cập."
- **E4. Phiên bản đã đổi (bước 5).** ERR-12-044 (412); "Chính sách vừa được người khác sửa. Tải lại."
- **E5. Nhật ký quyết định không đọc được (bước 6).** ERR-12-040 (503); "Chưa lấy được lưu lượng mẫu. Thử lại sau."
- **E6. Gửi duyệt khi chưa chạy khô đúng nội dung (UC-12-35).** ERR-12-026 (409); "Chưa chạy khô trên đúng nội dung hiện tại."

**Quy tắc áp dụng.** BR-12-007, 008, 009, 011.

**Màn hình, API.** UI-12-12, 13; API-12-089, 090, 091, 092, 093, 094, 095.
:::

### 6.35. UC-12-35 · Duyệt bốn mắt và phát hành gói chính sách ký

::: dac-ta
**Mục tiêu.** Một thay đổi chính sách chỉ có hiệu lực sau khi người thứ hai, khác người soạn, người gửi và mọi người đóng góp, xem tác động thật rồi duyệt; gói phát hành được ký và có hiệu lực ở mọi OPA trong không quá 60 giây.

**Tác nhân chính.** Người soạn (Dũng, hoặc Hà với chính sách nền tảng) gửi duyệt; ROLE-SECURITY_OFFICER thứ hai (Phương) duyệt.

**Tác nhân phụ.** OpenBao (ký gói), bucket `dh-platform-policy`, OPA (nạp nóng), Kafka, hộp "Việc của tôi" (FR-00-070).

**Mức ưu tiên.** M.

**FR hiện thực.** FR-12-054.

**Truy vết.** REQ-12; SEC-23, SEC-26; ADR-046, ADR-069; FR-00-071, FR-00-072.

**Tiền điều kiện.** Phiên bản `DRAFT` có kiểm thử đạt và chạy khô trên đúng `contentHash` (BR-12-009); người gửi có `PERM-12-policy-edit`, người duyệt có `PERM-12-policy-approve` và đã xác thực mức 3 trong 5 phút.

**Kích hoạt.** Người soạn bấm "Gửi duyệt"; người duyệt mở yêu cầu ở "Việc của tôi" (UI-12-17).

**Đảm bảo tối thiểu.** Không phiên bản nào `PUBLISHED` mà thiếu người duyệt thứ hai; OPA chỉ nạp gói có chữ ký hợp lệ; không sửa trực tiếp trên pod hay kho gói; không gửi duyệt khi chưa chạy khô đúng nội dung.

**Đảm bảo thành công.** Phiên bản `PUBLISHED`, phiên bản cũ `SUPERSEDED`; mỗi mã chính sách có đúng một phiên bản `PUBLISHED`; bộ đệm quyết định cũ không còn khớp; EVT-12-09 đã phát.

**Luồng chính.**

1. Dũng bấm "Gửi duyệt" ở UI-12-13. Hệ thống gọi API-12-096, kiểm tra điều kiện BR-12-009, khóa nội dung, đặt `PENDING_REVIEW` và đưa vào hộp việc của người có `PERM-12-policy-approve`.
2. Người duyệt mở yêu cầu ở UI-12-17, xem so sánh với phiên bản `PUBLISHED`, kết quả kiểm thử, báo cáo chạy khô; hệ thống yêu cầu xác thực bước lên mức 3 (LP-12-03).
3. Hệ thống kiểm tra người duyệt khác người soạn, người gửi và mọi người đóng góp (LP-12-01).
4. Tỷ lệ đổi của chạy khô là 24% vượt ngưỡng 20%: Phương phải tích xác nhận bổ sung và nhập ý kiến "Đã trao đổi với đầu mối HT-QLVB".
5. Người duyệt bấm "Phê duyệt và phát hành". Hệ thống gọi API-12-097: phiên bản `APPROVED`; dựng gói gồm mọi phiên bản `PUBLISHED` cộng phiên bản này, chạy lại `opa test` toàn gói, ký bằng khóa của OpenBao, đặt vào `dh-platform-policy/`.
6. OPA tải gói, xác minh chữ ký, nạp nóng. Khi OPA đầu tiên xác nhận `bundleRevision` mới, phiên bản thành `PUBLISHED`, bản cũ `SUPERSEDED`; UI-12-13 hiện tiến độ n/m nút OPA đã nạp (API-12-101).
7. Hệ thống ghi kiểm toán (người soạn, người duyệt, tác động), phát EVT-12-09.

**Luồng thay thế.**

- **5a. Người duyệt từ chối.** Người duyệt nhập ý kiến (API-12-098): `CHANGES_REQUESTED`; người soạn sửa và gửi lại (nội dung đổi thì chạy lại kiểm thử và chạy khô).
- **1a. Người soạn rút lại trước khi duyệt.** Phiên bản về `DRAFT`.
- **4a. Tác động nhỏ.** Dưới 20% và không có trường hợp nới quyền: bỏ bước xác nhận bổ sung.
- **6a. Tỉnh chỉ có một SO.** Xem Q12-14: SO của `PLATFORM` duyệt qua quyền có thời hạn (UC-12-13).

**Luồng ngoại lệ.**

- **E1. Người duyệt trùng người soạn, người gửi hoặc người đóng góp (bước 3).** ERR-12-008 (403); "Anh/chị là người soạn hoặc người đóng góp chính sách này nên không được duyệt." Nút "Phê duyệt và phát hành" bị khóa với chính người soạn.
- **E2. Chưa chạy khô hoặc kiểm thử chưa đạt (bước 1).** ERR-12-026 (409) "Chưa chạy khô trên đúng nội dung hiện tại." hoặc ERR-12-025 (409) "Còn {n} ca kiểm thử không đạt hoặc chưa có ca âm."
- **E3. Thiếu xác nhận khi tác động lớn (bước 4).** ERR-12-029 (409); "Thay đổi này đổi {tỷ lệ}% quyết định. Tích xác nhận và nhập ý kiến để tiếp tục."
- **E4. Chuyển trạng thái sai (bước 5).** ERR-12-027 (409); "Phiên bản đang ở trạng thái {trạng thái}."
- **E5. Không ký được gói (bước 5).** ERR-12-039 (503); phiên bản vẫn `APPROVED`, thử lại, chưa `PUBLISHED`.
- **E6. Gói không nạp được ở OPA nào trong 5 phút (bước 6).** Cảnh báo nghiêm trọng, đề xuất quay lui (UC-12-36).

**Quy tắc áp dụng.** BR-12-008, 009, 010, 011, 016.

**Màn hình, API.** UI-12-13, 17; API-12-096, 097, 098, 101.
:::

### 6.36. UC-12-36 · Thu hồi và quay lui chính sách

::: dac-ta
**Mục tiêu.** Khi một chính sách hoặc gói mới gây hại (chặn nhầm, lộ quyền), cán bộ ATTT gỡ nó khỏi mọi OPA trong 60 giây và khôi phục tình trạng trước đó mà không phải chạy lại quy trình duyệt.

**Tác nhân chính.** ROLE-SECURITY_OFFICER (Dũng); ROLE-PLATFORM_ADMIN (Hà) thực hiện kỹ thuật khi cần.

**Tác nhân phụ.** OpenBao (ký lại khi dựng gói mới), OPA, PA, TA và những người duyệt phiên bản bị thu hồi (nhận thông báo).

**Mức ưu tiên.** M.

**FR hiện thực.** FR-12-055.

**Truy vết.** REQ-12; SEC-26; BP-07.

**Tiền điều kiện.** Có phiên bản `PUBLISHED` cần thu hồi hoặc có gói trước đó đã từng `PUBLISHED` ở kho; Dũng có `PERM-12-policy-approve` và đã xác thực mức 3 trong 5 phút.

**Kích hoạt.** Dũng bấm "Thu hồi" ở một phiên bản hoặc "Quay lui gói" ở UI-12-12; hoặc cảnh báo tự động đề xuất khi gói mới gây lỗi.

**Đảm bảo tối thiểu.** Không thu hồi được chính sách gốc `base-authz` (chỉ quay lui); không để tenant không có chính sách (luôn có gói hiện hành); mặc định từ chối giữ nguyên trong khi đổi gói.

**Đảm bảo thành công.** Gói đích là gói hiện hành ở mọi OPA trong ≤ 60 giây; phiên bản bị thu hồi `REVOKED`; bộ đệm quyết định tự mất hiệu lực; EVT-12-10 đã phát.

**Luồng chính.**

1. Sau khi phát hành chính sách `ngoai-gio-lam-viec`, đầu mối `HT-QLVB` báo bị chặn nhầm. Dũng mở UI-12-12, chọn "Quay lui gói" về `bundleRevision` trước và nhập lý do "Chặn nhầm luồng đồng bộ ban đêm của HT-QLVB".
2. Hệ thống gọi API-12-100; kiểm tra gói đích có chữ ký hợp lệ.
3. Hệ thống đặt gói đích làm gói hiện hành (không cần chạy khô vì đây là bản đã duyệt trước đó); đặt phiên bản bị thu hồi `REVOKED`, các phiên bản `SUPERSEDED` được đặt lại `PUBLISHED`.
4. OPA nạp gói (≤ 60 giây), bộ đệm quyết định tự mất hiệu lực vì `bundleRevision` đổi.
5. Hệ thống thông báo Hà, Mai và những người duyệt phiên bản bị thu hồi; ghi kiểm toán, phát EVT-12-10, trả `200` kèm `bundleRevision` hiện hành.

**Luồng thay thế.**

- **1a. Thu hồi một phiên bản.** Dũng chọn "Thu hồi" (API-12-099); hệ thống dựng gói mới không có phiên bản bị thu hồi, ký lại bằng OpenBao rồi phát hành.
- **1b. Sự cố chung nhiều tenant.** Hà quay lui gói gốc, SO của tenant `PLATFORM` xác nhận trong vòng 24 giờ (ghi vào kiểm toán).
- **1c. Phục hồi.** Soạn lại từ phiên bản bị thu hồi qua UC-12-34.
- **1d. Xem gói.** Dũng xem danh sách gói và trạng thái nạp qua API-12-101.

**Luồng ngoại lệ.**

- **E1. Thu hồi chính sách gốc (bước 1a).** ERR-12-027 (409); "Không thu hồi được chính sách gốc. Hãy quay lui về gói trước."
- **E2. Gói đích không còn ở kho hoặc chữ ký sai (bước 2).** ERR-12-024 (422); "Gói đích không hợp lệ."
- **E3. Thiếu lý do (bước 1).** ERR-12-014 (400); "Nhập lý do."
- **E4. OpenBao không ký được khi dựng gói mới (bước 1a).** ERR-12-039 (503); thao tác quay lui (không cần ký lại) vẫn thực hiện được.
- **E5. Chưa xác thực bước lên.** ERR-12-120 (401) theo LP-12-03.

**Quy tắc áp dụng.** BR-12-010, 016, 033.

**Màn hình, API.** UI-12-12; API-12-099, 100, 101.
:::

### 6.37. UC-12-37 · Ghi vết sự kiện xác thực và quyết định ủy quyền

::: dac-ta
**Mục tiêu.** Mọi đăng nhập, thu hồi, thay đổi quyền và mọi quyết định từ chối hay truy cập dữ liệu nhạy cảm đều truy vết được tới người, thời điểm, địa chỉ nguồn, mà không bao giờ ghi mật khẩu, token hay dữ liệu cá nhân dạng rõ; tài nguyên nhạy cảm không có vết thì không được truy cập.

**Tác nhân chính.** Hệ thống (Keycloak, `dh-platform`, OPA, PEP).

**Tác nhân phụ.** Kafka, PH-13 (chuỗi băm kiểm toán, WORM), Loki, OTel Collector (bộ lọc che dữ liệu), ROLE-SECURITY_OFFICER (xem ở UI-12-14, UI-12-15).

**Mức ưu tiên.** M.

**FR hiện thực.** FR-12-056, 057.

**Truy vết.** REQ-12; REQ-13; LGC-IAM-005; SEC-26, SEC-61, SEC-62; FR-00-040, FR-00-041; CMP-LAW-05; ADR-031.

**Tiền điều kiện.** Bộ nghe sự kiện của Keycloak, bộ ghi outbox của `dh-platform` và phần ghi quyết định của OPA đã bật; bộ thu OTel Collector có bộ lọc che dữ liệu.

**Kích hoạt.** Mỗi sự kiện xác thực, mỗi thao tác quản trị định danh, mỗi quyết định của OPA.

**Đảm bảo tối thiểu.** Không ghi mật khẩu, mã TOTP, bí mật, token đầy đủ, số định danh rõ; tên đăng nhập sai không ghi; thao tác quản trị không ghi được kiểm toán thì không thực hiện.

**Đảm bảo thành công.** 100% quyết định từ chối và quyết định mức Hạn chế, Nhạy cảm có bản ghi; log an ninh online 12 tháng; chuỗi kiểm toán online 12 tháng và WORM 5 năm.

**Luồng chính.**

1. `nguyenvana` đăng nhập (UC-12-16). Keycloak phát sự kiện; bộ nghe chuẩn hóa thành bản ghi gồm `eventType`, `subject`, `clientId`, `tenant`, `sourceIp`, `userAgent`, `result`, `failureReason`, `acr`.
2. Bộ nghe gửi bản ghi vào Kafka `t68.iam.auth.event-recorded.v1` (EVT-12-16); thao tác quản trị ở `dh-platform` ghi cùng giao dịch với dữ liệu (outbox) rồi gửi cùng đường.
3. PH-13 nhận, ghi vào chuỗi băm kiểm toán của tenant cho thay đổi quyền, đổi yếu tố, thu hồi; sự kiện đăng nhập vào kho log an ninh.
4. Khi `nguyenvana` gọi API, OPA ghi quyết định vào bộ đệm cục bộ; PEP gắn `traceId` khớp PH-04 và PH-13.
5. Bộ thu che dữ liệu: giá trị trường Nhạy cảm không ghi (chỉ tên trường); mã tài nguyên mức Nhạy cảm thay bằng băm có khóa để tra được "ai đã truy cập đối tượng X" mà không lộ đối tượng.
6. Hệ thống ghi 100% quyết định từ chối và 100% quyết định cho phép trên dữ liệu mức Hạn chế, Nhạy cảm; quyết định cho phép trên dữ liệu Công khai, Nội bộ lấy mẫu 10% (Q12-12). Quyết định từ chối và mức Nhạy cảm cũng vào chuỗi băm của PH-13 (WORM 5 năm); phần còn lại ở Loki nhãn `tenant`.

**Luồng thay thế.**

- **2a. Sự kiện số lượng lớn.** Cấp token máy (UC-12-25) lấy mẫu theo `12.event.token-sample`, vẫn ghi 100% lỗi xác thực.
- **6a. Đường ghi vết lỗi với dữ liệu thường.** PEP vẫn phục vụ; bộ đệm cục bộ giữ tối đa 24 giờ, cảnh báo cho vận hành; quyết định sau khi khôi phục được gửi lại.
- **6b. Khối lượng ghi vượt ngưỡng.** Tăng tỷ lệ lấy mẫu chỉ cho nhóm Công khai, Nội bộ; không bao giờ cho từ chối hay Nhạy cảm.

**Luồng ngoại lệ.**

- **E1. Không gửi được tới Kafka (bước 2).** Bộ nghe đệm vào hàng đợi bền trên đĩa tối đa 24 giờ và gửi lại; hàng đợi đầy thì cảnh báo nghiêm trọng, không chặn đăng nhập.
- **E2. Thao tác quản trị không ghi được kiểm toán (bước 2).** Giao dịch thất bại, thao tác không thực hiện; người dùng thấy "Chưa ghi được nhật ký nên thao tác chưa thực hiện. Thử lại sau." (ERR-12-040).
- **E3. Phát hiện giá trị bí mật hoặc trường Nhạy cảm trong bản ghi (bước 5).** Bản ghi bị che hoặc loại, cảnh báo an ninh, cảnh báo cấu hình.
- **E4. Không ghi được vết với tài nguyên mức Nhạy cảm (bước 6).** ERR-12-124 (403); "Hệ thống chưa ghi được vết truy cập nên không phục vụ dữ liệu này. Thử lại sau." (lý do `AUDIT_UNAVAILABLE`, BR-12-013).

**Quy tắc áp dụng.** BR-12-013, 045.

**Màn hình, API.** UI-12-14, 15; API-12-103, 105.
:::

### 6.38. UC-12-38 · Tra cứu nhật ký quyết định và sự kiện an ninh

::: dac-ta
**Mục tiêu.** Cán bộ ATTT, kiểm toán viên và quản trị tỉnh tìm được vì sao một yêu cầu bị từ chối hoặc ai đã truy cập một đối tượng, theo `traceId` trong vài giây, với dữ liệu đã che.

**Tác nhân chính.** ROLE-SECURITY_OFFICER (Dũng); ROLE-AUDITOR (Kiên); ROLE-TENANT_ADMIN (Mai); PA, PO (tenant khác chỉ trong quyền có thời hạn).

**Tác nhân phụ.** Loki (nhãn `tenant`) qua PH-13, PH-04 (liên kết truy vết bản tin).

**Mức ưu tiên.** M.

**FR hiện thực.** FR-12-058.

**Truy vết.** REQ-12; REQ-13; SEC-61; CMP-LAW-05.

**Tiền điều kiện.** Người dùng có `PERM-12-decision-read` và đã chọn tenant làm việc; nhật ký có dữ liệu trong khoảng tra.

**Kích hoạt.** Dũng mở "Nhật ký quyết định" ở UI-12-14.

**Đảm bảo tối thiểu.** Không thay đổi dữ liệu; trường Nhạy cảm luôn che kể cả khi xuất CSV; mỗi lần tra có ghi kiểm toán điều kiện lọc.

**Đảm bảo thành công.** Kết quả phân trang đúng bộ lọc kèm biểu đồ tỷ lệ từ chối; chi tiết quyết định xem được.

**Luồng chính.**

1. Dũng chọn khoảng thời gian 7 ngày, lọc kết quả "Từ chối", chủ thể `nguyenvana`, rồi bấm "Tra".
2. Hệ thống gọi API-12-103; kiểm tra khoảng thời gian không quá 31 ngày.
3. Hệ thống truy vấn Loki của `T68` qua PH-13, trả kết quả phân trang (thời điểm, chủ thể, tài nguyên, hành động, kết quả, chính sách, lý do, thời gian đánh giá) kèm biểu đồ tỷ lệ từ chối theo thời gian.
4. Dũng bấm một dòng. Hệ thống gọi API-12-104 và hiện đầy đủ `input` đã che, chính sách khớp, `bundleRevision` và lý do (`ORG_SCOPE_MISMATCH`); có liên kết mở truy vết bản tin ở PH-04, PH-13 theo `traceId`.
5. Dũng xuất CSV (FR-00-030, có thủy vân tên người xuất; trường Nhạy cảm vẫn che).
6. Hệ thống ghi kiểm toán việc tra cứu kèm điều kiện lọc.

**Luồng thay thế.**

- **1a. Tra ngược "ai đã truy cập đối tượng X".** Dũng nhập mã đối tượng; hệ thống băm theo khóa của tenant để so với các bản ghi mức Nhạy cảm.
- **1b. Tra sự kiện an ninh.** Dũng chuyển sang tab sự kiện xác thực (API-12-105, UC-12-37).
- **1c. Dữ liệu cũ hơn 12 tháng.** Hướng dẫn yêu cầu xuất từ kho WORM qua PH-13.
- **1d. Kiểm toán viên.** Kiên chỉ xem, không có nút thao tác.

**Luồng ngoại lệ.**

- **E1. Khoảng thời gian quá dài (bước 2).** ERR-12-003 (400); "Chỉ tra được tối đa 31 ngày mỗi lần."
- **E2. Không có quyền (bước 1).** ERR-12-007 (403); đối tượng thuộc tenant khác ERR-12-001 (404).
- **E3. Loki hoặc PH-13 chậm hoặc lỗi (bước 3).** ERR-12-040 (503); "Chưa tra được nhật ký. Thử lại sau."
- **E4. Quá nhiều kết quả (bước 3).** Hơn 10.000 dòng: "Kết quả quá nhiều. Thu hẹp bộ lọc." (chỉ hiện 10.000 dòng đầu).

**Quy tắc áp dụng.** BR-12-041, 045.

**Màn hình, API.** UI-12-14; API-12-103, 104.
:::

### 6.39. UC-12-39 · Phát hiện hành vi bất thường và xử lý cảnh báo

::: dac-ta
**Mục tiêu.** Cán bộ ATTT được báo trong 60 giây khi có dấu hiệu dò mật khẩu, lộ token, đổi cấu hình trái phép hay truy cập ngoài giờ, xem được bằng chứng và cắt truy cập ngay từ cảnh báo.

**Tác nhân chính.** ROLE-SECURITY_OFFICER (Dũng); hệ thống (bộ phát hiện).

**Tác nhân phụ.** Loki, kênh thông báo của SO (FR-00-061), ROLE-TENANT_ADMIN và ROLE-PLATFORM_ADMIN (nhận cảnh báo nghiêm trọng), PH-13.

**Mức ưu tiên.** S.

**FR hiện thực.** FR-12-059.

**Truy vết.** REQ-12; REQ-13; SEC-64; THR-09, THR-12; BP-07.

**Tiền điều kiện.** Nhật ký xác thực và quyết định đã đổ vào Loki; Dũng có `PERM-12-alert`.

**Kích hoạt.** Đánh giá định kỳ mỗi phút trên cửa sổ thời gian của từng quy tắc; hoặc sự kiện tức thì.

**Đảm bảo tối thiểu.** Nhật ký chậm thì báo "Dữ liệu giám sát chậm" thay vì bỏ sót im lặng; thông báo không chứa dữ liệu, chỉ liên kết (FR-00-062).

**Đảm bảo thành công.** Cảnh báo `OPEN` rồi `ACKNOWLEDGED`; SO nhận cảnh báo trong 60 giây; EVT-12-14 đã phát.

**Luồng chính.**

1. Bộ phát hiện đánh giá chín quy tắc AN-01…09 trên nhật ký của `T68`; ví dụ AN-01 (một địa chỉ đăng nhập thất bại hơn 20 lần mỗi phút), AN-05 (refresh token bị dùng lại, mức Nghiêm trọng), AN-07 (xác thực client sai hơn 10 lần mỗi phút).
2. Một địa chỉ `203.0.113.7` thử đăng nhập 35 lần trong một phút. Hệ thống tạo cảnh báo `alertId` mức Cao kèm đối tượng, số liệu và liên kết tới nhật ký liên quan; cảnh báo lặp trong 30 phút được gộp.
3. Hệ thống gửi thông báo tới Dũng trong tối đa 60 giây qua kênh cấu hình (trong ứng dụng, thư), phát EVT-12-14.
4. Dũng mở cảnh báo ở UI-12-15 (API-12-106), xem bằng chứng, bấm "Xác nhận" (API-12-107) và, nếu cần, thu hồi truy cập ngay (UC-12-28).
5. Khi cảnh báo giả nhiều, Dũng tinh chỉnh ngưỡng trong miền cho phép; thay đổi ghi kiểm toán (UC-12-41).

**Luồng thay thế.**

- **2a. Cảnh báo mức Nghiêm trọng.** Dùng lại refresh token, đặt lại yếu tố thứ hai của quản trị, realm lệch cấu hình: gửi thêm cho Mai và Hà.
- **4a. Phát hiện trong UC khác.** Tài khoản bị khóa hẳn (UC-12-16) và quản trị gán vai trò ngoài giờ (UC-12-09, AN-09) cũng sinh cảnh báo.

**Luồng ngoại lệ.**

- **E1. Không gửi được thông báo (bước 3).** Cảnh báo vẫn hiện ở UI-12-15 và chuyển PH-13; ghi cảnh báo "Không gửi được thông báo".
- **E2. Nhật ký chậm quá 5 phút (bước 1).** Cảnh báo "Dữ liệu giám sát chậm" tới người vận hành.
- **E3. Ngưỡng ngoài miền cho phép (bước 5).** ERR-12-043 (422); "Ngưỡng vượt trần của nền tảng."

**Quy tắc áp dụng.** BR-12-019, 026, 028.

**Màn hình, API.** UI-12-15; API-12-106, 107.
:::

### 6.40. UC-12-40 · Báo cáo tình trạng tài khoản và xác thực hai yếu tố

::: dac-ta
**Mục tiêu.** Cán bộ ATTT và quản trị tỉnh thấy mỗi ngày độ phủ xác thực hai yếu tố và danh sách tài khoản, client cần xử lý (không dùng, giữ nhiều vai trò đặc quyền, bí mật hoặc chứng thư sắp hết hạn).

**Tác nhân chính.** ROLE-SECURITY_OFFICER (Dũng); ROLE-TENANT_ADMIN (Mai); ROLE-AUDITOR (Kiên); ROLE-PLATFORM_ADMIN.

**Tác nhân phụ.** Bản chiếu `ph12_iam`, Keycloak, tác vụ báo cáo hằng ngày.

**Mức ưu tiên.** S.

**FR hiện thực.** FR-12-060.

**Truy vết.** REQ-12; REQ-13; SEC-23, SEC-27; CMP-LAW-08.

**Tiền điều kiện.** Bản chiếu người dùng và client đã đồng bộ; người xem có `PERM-12-read`.

**Kích hoạt.** Báo cáo tự động chạy hằng ngày lúc 06:00; hoặc Dũng mở "Báo cáo tài khoản" ở UI-12-15 hoặc gọi API.

**Đảm bảo tối thiểu.** Không thay đổi dữ liệu; thông báo tóm tắt chỉ có liên kết, không chứa danh sách người.

**Đảm bảo thành công.** Báo cáo có số liệu theo ngày, lưu 24 tháng; Dũng và Mai nhận bản tóm tắt.

**Luồng chính.**

1. Lúc 06:00 hệ thống tổng hợp số tài khoản theo trạng thái (`ACTIVE`, `LOCKED`, `BLOCKED`, `DISABLED`, `PENDING_ACTIVATION`) và theo đơn vị.
2. Hệ thống tính độ phủ MFA: số tài khoản nhóm `mfa-required` đã có yếu tố thứ hai trên tổng số (mục tiêu 100%), kèm danh sách tài khoản chưa có.
3. Hệ thống liệt kê tài khoản không đăng nhập từ 30 ngày, người giữ từ hai vai trò đặc quyền trở lên, tài khoản có ngoại lệ tách nhiệm vụ còn hiệu lực, quyền có thời hạn còn hiệu lực.
4. Hệ thống liệt kê client có bí mật quá 150 ngày, chứng thư hết hạn trong 30 ngày, client không gọi quá 60 ngày.
5. Hệ thống gửi bản tóm tắt cho Dũng và Mai (liên kết, không chứa danh sách người).
6. Dũng mở UI-12-15, gọi API-12-108 (báo cáo tài khoản) và API-12-109 (độ phủ MFA), xem biểu đồ độ phủ MFA theo ngày và xuất CSV (FR-00-030).

**Luồng thay thế.**

- **6a. Lọc theo đơn vị.** TA đơn vị rà soát khi có phạm vi `ORG`.
- **6b. Kiểm toán viên.** Kiên xem toàn bộ báo cáo, không có thao tác ghi.

**Luồng ngoại lệ.**

- **E1. Bản chiếu chưa đồng bộ kịp (bước 6).** Báo cáo hiện thời điểm dữ liệu "tính đến {thời điểm}".
- **E2. Không có quyền (bước 6).** ERR-12-007 (403).
- **E3. Keycloak không khả dụng (bước 2).** Báo cáo dùng bản chiếu và ghi "Chưa cập nhật yếu tố xác thực mới nhất."

**Quy tắc áp dụng.** BR-12-015, 020.

**Màn hình, API.** UI-12-15; API-12-108, 109.
:::

### 6.41. UC-12-41 · Cấu hình tham số phân hệ theo tenant

::: dac-ta
**Mục tiêu.** Quản trị tỉnh điều chỉnh các tham số định danh của tỉnh (thời gian phiên, ngưỡng khóa, miền thư công vụ, ngưỡng cảnh báo) trong trần do nền tảng đặt và không bao giờ yếu hơn mức bắt buộc của cấp độ 3.

**Tác nhân chính.** ROLE-TENANT_ADMIN (Mai) đổi trong trần; ROLE-PLATFORM_ADMIN (Hà) đặt trần.

**Tác nhân phụ.** PH-18 (kho tham số theo tenant), kho cấu hình GitOps và CI (áp tham số bảo mật vào realm), ROLE-SECURITY_OFFICER, ROLE-AUDITOR (xem).

**Mức ưu tiên.** M.

**FR hiện thực.** FR-12-061.

**Truy vết.** REQ-12; REQ-18; NFR-00-052; SEC-22, SEC-27, SEC-29.

**Tiền điều kiện.** Mai và Hà có `PERM-12-admin`; khóa `12.*` đã khai báo (FRS mục 8.2).

**Kích hoạt.** Mai mở "Cài đặt Định danh" ở UI-12-16.

**Đảm bảo tối thiểu.** Tham số của tenant chỉ siết chặt hơn mức nền; thất bại thì giá trị cũ giữ nguyên.

**Đảm bảo thành công.** Giá trị lưu theo tenant, có hiệu lực theo thời hạn nêu và nằm trong ngưỡng an toàn; kiểm toán ghi giá trị trước và sau; EVT-12-13 đã phát khi đổi tham số bảo mật của realm.

**Luồng chính.**

1. Mai mở UI-12-16. Hệ thống gọi API-12-110 và hiện danh sách tham số kèm giá trị hiện hành, mặc định, miền cho phép và giải thích.
2. Mai đổi `12.lockout.max-failures` từ 5 xuống 4 và nhập lý do "Theo yêu cầu của đơn vị ATTT tỉnh".
3. Hệ thống gọi API-12-111 kèm `If-Match`; kiểm tra giá trị nằm trong miền (3 đến 10) và không yếu hơn yêu cầu bắt buộc (ví dụ độ dài mật khẩu tối thiểu 14, ngưỡng vô hiệu không quá 45 ngày).
4. Hệ thống lưu giá trị theo tenant; tham số bảo mật của realm được ghi vào tệp giá trị của tenant ở kho cấu hình và CI áp vào realm (UC-12-29); tham số của OPA và PEP có hiệu lực trong 60 giây.
5. Hệ thống ghi kiểm toán giá trị trước và sau, phát EVT-12-13 khi đổi tham số bảo mật của realm, trả `200` kèm danh sách tham số hiện hành.

**Luồng thay thế.**

- **2a. Khôi phục mặc định.** Mai bấm "Khôi phục mặc định".
- **2b. PA đổi trần.** Hà đổi trần; tenant đang vượt trần bị kéo về trần và có thông báo.
- **1a. SO, AU xem.** Có `PERM-12-read`, chỉ xem.

**Luồng ngoại lệ.**

- **E1. Vượt trần hoặc yếu hơn mức bắt buộc (bước 3).** ERR-12-043 (422); "Giá trị vượt giới hạn cho phép ({tối thiểu} đến {tối đa})."
- **E2. Phiên bản đã đổi (bước 3).** ERR-12-044 (412); "Giá trị vừa được người khác sửa. Tải lại."
- **E3. Thiếu lý do (bước 2).** ERR-12-014 (400); "Nhập lý do thay đổi."
- **E4. PH-18 không khả dụng (bước 1).** Dùng giá trị đệm 60 giây rồi mặc định; cảnh báo cho PA.

**Quy tắc áp dụng.** BR-12-018, 019, 020, 022, 038.

**Màn hình, API.** UI-12-16; API-12-110, 111.
:::

### 6.42. UC-12-42 · Tra cứu danh bạ người dùng cho phân hệ khác

::: dac-ta
**Mục tiêu.** Các màn hình và phân hệ khác hiển thị tên người nhất quán (người duyệt, thành viên không gian làm việc, tab Lịch sử) mà chỉ lấy dữ liệu tối thiểu, không lộ thư điện tử, điện thoại, yếu tố xác thực hay vai trò.

**Tác nhân chính.** DU và phân hệ gọi bằng scope `iam:directory-read` (PH-04, PH-13, `dh-platform` cho hộp việc và tab Lịch sử).

**Tác nhân phụ.** Bản chiếu người dùng `ph12_iam` (bảo mật mức dòng theo tenant).

**Mức ưu tiên.** M.

**FR hiện thực.** FR-12-062.

**Truy vết.** REQ-12; FR-00-043, FR-00-070; SEC-82.

**Tiền điều kiện.** Bên gọi có token dịch vụ hợp lệ và scope `iam:directory-read`; tenant của lời gọi lấy từ token.

**Kích hoạt.** Phân hệ cần hiển thị thông tin người dùng theo mã.

**Đảm bảo tối thiểu.** Không trả dữ liệu của tenant khác; không tiết lộ sự tồn tại của đối tượng ngoài tenant; không trả trường nhạy cảm.

**Đảm bảo thành công.** Bên gọi nhận `userId`, `displayName`, `orgCode`, `orgName`, `title`, `state`.

**Luồng chính.**

1. Hộp "Việc của tôi" của `dh-platform` cần hiển thị tên người đề nghị của 20 việc; gọi `GET /api/iam/v1/directory/users` (API-12-014) với danh sách mã người dùng.
2. Hệ thống kiểm tra scope `iam:directory-read` và lấy tenant `T68` từ token, không từ tham số.
3. Hệ thống tra bản chiếu người dùng của tenant (bảo mật mức dòng) và trả thông tin tối thiểu.
4. Tài khoản `DISABLED` vẫn được trả để hiển thị lịch sử (tên vẫn hiện, kèm nhãn "đã nghỉ").
5. Bên gọi đệm kết quả tối đa 5 phút và hiển thị tên trên màn hình.

**Luồng thay thế.**

- **1a. Tìm theo từ khóa.** Dùng cho ô chọn người (chọn người duyệt, thành viên không gian làm việc); chỉ trả người `ACTIVE`.

**Luồng ngoại lệ.**

- **E1. Mã không có hoặc thuộc tenant khác (bước 3).** Bỏ khỏi kết quả, không báo lỗi, không tiết lộ sự tồn tại (BR-12-041).
- **E2. Quá 100 mã (bước 1).** ERR-12-003 (400).
- **E3. Vượt 50 yêu cầu mỗi giây mỗi bên gọi (bước 1).** ERR-12-037 (429).
- **E4. Bản chiếu chưa sẵn sàng (bước 3).** ERR-12-040 (503); bên gọi hiển thị mã người dùng thay tên.

**Quy tắc áp dụng.** BR-12-004, 041, 042.

**Màn hình, API.** Không có màn hình; API-12-014.
:::

## 7. Luồng phụ dùng chung

Bảy luồng phụ dưới đây lặp lại ở nhiều use case; use case dẫn mã LP thay vì viết lại.

| Mã | Luồng phụ | Dùng ở |
|---|---|---|
| LP-12-01 | Bốn mắt: hệ thống so người duyệt với người đề nghị, người soạn, người gửi duyệt và (với ngoại lệ, quyền có thời hạn) người được hưởng; trùng thì khóa nút "Duyệt" kèm giải thích, gọi thẳng API trả ERR-12-008 (403) và ghi sự kiện an ninh. Câu hiện: "Anh/chị là người đề nghị hoặc người soạn nên không được tự duyệt." (BR-12-008, FR-00-071) | UC-12-10, 12, 13, 14, 18, 19, 26, 27, 35 |
| LP-12-02 | Lý do bắt buộc: hộp thoại có ô lý do từ 10 ký tự; thiếu trả ERR-12-014 (400), câu "Nhập lý do (ít nhất 10 ký tự)." | UC-12-04, 10, 13, 18, 28, 36 |
| LP-12-03 | Xác thực lại bước lên: OPA trả nghĩa vụ `STEPUP` khi `acr` thấp hơn mức yêu cầu hoặc `auth_time` quá 5 phút; BFF chuyển người dùng tới trang xác nhận của Keycloak rồi tự gửi lại thao tác. Gọi API trực tiếp không bỏ qua được: trả ERR-12-120 (401), câu "Cần xác thực lại để thực hiện thao tác này." (UC-12-17, BR-12-016) | UC-12-04, 13, 18, 19, 23, 28, 35, 36 |
| LP-12-04 | Không tự thao tác trên mình: gán, gỡ vai trò, khóa, thu hồi, đặt lại yếu tố thứ hai của chính mình bị chặn ERR-12-013 (403), câu "Anh/chị không thể tự thực hiện thao tác này với tài khoản của mình." (BR-12-033) | UC-12-03, 04, 09, 18, 20, 28 |
| LP-12-05 | Sửa đồng thời: mọi lệnh sửa gửi `If-Match`; phiên bản đã đổi trả ERR-12-044 (412), câu "Thông tin này vừa được người khác sửa. Tải lại trang để xem bản mới nhất."; lệnh ghi gửi `Idempotency-Key`, dùng lại với thân khác trả ERR-12-045 (422) | UC-12-03, 11, 23, 34, 41 |
| LP-12-06 | Cách ly tenant và tổ chức: đối tượng của tenant hoặc tổ chức khác trả ERR-12-001 (404) cùng thân với "không tồn tại"; thiếu quyền trả ERR-12-007 (403), câu "Bạn không có quyền thực hiện thao tác này. Liên hệ quản trị tỉnh nếu cần được cấp quyền." (BR-12-004, 041) | Mọi use case có người dùng |
| LP-12-07 | Phụ thuộc không khả dụng: Keycloak lỗi ERR-12-038 (503) "Hệ thống xác thực tạm thời không khả dụng. Thử lại sau ít phút."; OpenBao lỗi ERR-12-039 (503) "Kho bí mật tạm thời không khả dụng; chưa lưu hoặc chưa xoay. Thử lại sau."; dịch vụ khác ERR-12-040 (503). Thao tác thất bại giữa chừng không để lại trạng thái dở dang | UC-12-02, 05, 13, 21, 24, 26, 29, 35 |

: Luồng phụ dùng chung

## 8. Tổng hợp mã mới và đối chiếu

Tập này không tạo mã FR, API, ERR mới. Mã mới: UC-12-01…42, LP-12-01…07. Đối chiếu: mọi FR của FRS (62 trên 62, gồm 52 mức M, 9 mức S, 1 mức C) có ít nhất một use case (mục 5.1); FR-12-028 (VNeID, mức C, Đợt 2) hiện thực ở nhánh thay thế của UC-12-19; FR-12-015, 018, 019, 032 (Đợt 2) có UC-12-12, 14, 15 và nhánh sandbox của UC-12-21. Các câu thông báo mới do use case đề xuất, nếu có, ghi ở mục "Đề nghị đồng bộ" cuối tài liệu.

### Đề nghị đồng bộ

> **Đợt đồng bộ chéo cuối (27/11/2026).** Các đề nghị dưới đây đã được xét; kết luận từng dòng (đã sửa, đã khớp sẵn, câu hỏi mở, không làm) ghi ở [D00-03-01 Sổ đồng bộ chéo cuối](../../00-chung/D00-03-01-so-dong-bo-cuoi.md).

Các việc dưới đây ở tài liệu dùng chung hoặc tập khác do luồng khác chịu trách nhiệm; tập này chỉ ghi lại để đợt đồng bộ cuối xử lý.

| Tài liệu | Đề nghị |
|---|---|
| D00-04 §2, §3.2 | Cập nhật PH-12 "đủ tập FRS và use case"; chạy `kiem_tra_ma.py --cap-nhat-so-tra-cuu` để cập nhật dải UC-12-01…42 (số kế tiếp là 43) |
| D03-06-PH12 §5.2 (bảng thông báo) | Thêm một câu mới do UC-12-11 đề xuất: ERR-12-002 cho mã nhóm trùng, "Mã nhóm này đã được dùng. Chọn mã khác." (bảng hiện chỉ có câu cho tên đăng nhập, thư) |
| D02-03-PH12 (FRS) mục 11 | Thêm bảng FR → UC (theo mục 5.1 của tập này) để hai tập tham chiếu chéo được; làm rõ ở FR-12-017 ai là "người thứ hai" khi vào tenant khác (Q12-45) |
| D05-02-PH12 (test case) | Mỗi luồng chính, thay thế, ngoại lệ của UC-12-01…42 là một ca; bộ ca bốn mắt (LP-12-01) chạy cho UC-12-10, 12, 13, 14, 18, 19, 26, 27, 35; bộ ca fail-closed cho UC-12-31, 32 |
| D03-04-PH12 (API) | Đối chiếu cột Quyền hoặc scope của API với tiền điều kiện của từng UC ở mục 6; UC-12-19 dùng chung API cho LDAP/AD, SAML, VNeID |

: Đề nghị đồng bộ cho tài liệu dùng chung và tập khác

## 9. Câu hỏi mở

> **Câu hỏi mở Q12-45:** UC-12-13 (quyền có thời hạn vào tenant khác): FRS ghi người duyệt là "PA khác hoặc SO". Cần xác nhận người duyệt quyền vào `T68` là SO của chính `T68` (tỉnh đồng ý cho vào), hay đủ một PA khác của nền tảng. Đề xuất: truy cập tenant khác (`TENANT_ACCESS`) cần SO của tenant đích duyệt, chỉ khi sự cố mức nghiêm trọng mới cho PA khác duyệt thay và phải thông báo ngay cho TA; vai trò đặc quyền của chính tenant `PLATFORM` (`PRIVILEGE`) do PA khác duyệt.

> **Câu hỏi mở Q12-46:** UC-12-04, UC-12-28 cắt phiên và token trong 60 giây nhưng chưa nói tác vụ bất đồng bộ do người đó khởi chạy trước đó (nhập tệp ở UC-12-05, chạy khô ở UC-12-34, tác vụ xuất CSV ở UC-12-38) có tiếp tục không. Đề xuất: tác vụ chỉ-đọc chạy tiếp tới khi xong và ghi nhận người khởi tạo đã `DISABLED`; tác vụ ghi (nhập tệp pha 2) bị hủy ở lô kế tiếp. Cần xác nhận với cán bộ ATTT.

> **Câu hỏi mở Q12-47:** UC-12-31 bước 2, khi OPA hết thời gian chờ 50 ms, bên thực thi từ chối và trả ERR-12-104 (503) cho người dùng. Mã `503` có thể làm ứng dụng và HTTT tự thử lại dồn dập đúng lúc OPA quá tải. Cần thống nhất với PH-03 mã trả cho người gọi (`503` kèm `Retry-After`, hay `403` kèm lý do `POLICY_ERROR`) và quy tắc thử lại chỉ cho phương thức đọc.

> **Câu hỏi mở Q12-48:** UC-12-24 (xoay bí mật): bản bọc dùng một lần hiệu lực 24 giờ và bí mật cũ cũng giữ thêm 24 giờ (`12.client.secret-rotation-overlap-hours`). Nếu đầu mối kỹ thuật chưa kịp nhận bản bọc (nghỉ cuối tuần), HTTT mất kết nối ngay khi bí mật cũ chết. Cần xác nhận cho gia hạn bí mật cũ thêm một lần có lý do, hoặc tính thời gian chuyển tiếp từ lúc đầu mối nhận bản bọc thay vì từ lúc xoay.

> **Câu hỏi mở Q12-49:** UC-12-39: tỉnh vừa thường chỉ có một cán bộ ATTT (GĐ-12-06 giả định tối thiểu hai) nên cảnh báo mức Nghiêm trọng (AN-05, AN-06, AN-08) ngoài giờ có thể không ai nhận trong 60 giây. Đề xuất chuyển cảnh báo mức Nghiêm trọng ngoài giờ hành chính cho vận hành nền tảng (PO) đang trực, kèm quyền chỉ thu hồi truy cập; cần chủ đầu tư xác nhận trách nhiệm trực 24/7 và kênh thông báo.

## Lịch sử phiên bản

| Phiên bản | Ngày | Người | Nội dung |
|---|---|---|---|
| 0.1 | 26/11/2026 | Nhóm viết tài liệu (Claude) | Bản đầu theo khuôn K-UC và quy chuẩn K-TRINH-BAY: tóm tắt cho hội đồng, giới thiệu, 42 use case khối 15 mục phủ 62 FR của FRS 0.1, bảy sơ đồ use case tổng, ba bảng truy vết (FR, UI và API, REQ, BP và LGC), bảy luồng phụ dùng chung, năm câu hỏi mở (Q12-45…49) |
| 0.2 | 27/11/2026 | Nhóm viết tài liệu (Claude) | Đồng bộ chéo cuối: dùng tên bước S01_RECORD theo D03-10 |
