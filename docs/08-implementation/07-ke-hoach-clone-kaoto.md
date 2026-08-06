# IP-07 — Kế hoạch clone mô hình Kaoto

> **Căn cứ.** [SRS PH-04/D](../07-srs/SRS-PH-04-designer.md) · [IP-06](06-ke-hoach-lam-lai-designer.md) (đã xong) ·
> [ADR-015](../05-adr/README.md#adr-015) (Kaoto = mẫu tham chiếu) · [ADR-017](../05-adr/README.md#adr-017) (XYFlow) ·
> quyết định của chủ dự án 2026-08-05.
>
> **Mục tiêu.** Clone **mô hình hoạt động** của Kaoto — không clone giao diện.
> Giao diện giữ định hướng riêng theo [`docs/ui_ux_rule.md`](../ui_ux_rule.md) và token mockup.
>
> **Quy ước.** `- [ ]` chỉ đánh `[x]` khi có bằng chứng chạy được. Mỗi gói map `FR-D-*`.

---

## 0. Năm quyết định nền — chốt 2026-08-05

| # | Vấn đề | Quyết định | Hệ quả |
|---|---|---|---|
| **Q1** | Khung chuẩn 4 chặng khóa (BR-D-01) chặn mô hình "luồng trắng" của Kaoto | Khung thành **mẫu gỡ được**; `validate.ts` **cảnh báo** thay vì khóa | **Phải sửa BR-D-01 trong SRS** (mục 9) |
| **Q2** | `emit.ts`/`parse.ts` tự viết, chỉ đọc được tập con nó tự sinh | Thay bằng thư viện **`yaml`** + **mô hình cây** `CamelResource`/`VisualEntity` | Viết lại lõi; bundle +~40KB gz |
| **Q3** | Phạm vi | Làm **cả bốn** hạng mục | Chia 6 đợt theo phụ thuộc (mục 2) |
| **Q4** | DataMapper | **UI tự viết** (React 19, theo `ui_ux_rule.md`) + **`atlasmap-runtime` Java** ở `apps/control` | Không kéo React 17/PatternFly vào console |
| **Q5** | Cách bắt đầu | Viết kế hoạch trước, chủ dự án duyệt rồi mới thi công | Chính là tài liệu này |

### 0.1. Vì sao Q4 không phải là "nhúng AtlasMap đầy đủ" theo nghĩa đen

Đo trên `apps/console/package.json`: console đang **React 19.1**, `antd 6`, `react-router 7`,
`@xyflow/react 12`. Gói giao diện AtlasMap peer **React 17** và dựa trên PatternFly 4 —
còn dùng các API React đã bị **gỡ khỏi React 19** (legacy context, string ref, `ReactDOM.render`).
Hạ console về React 17 sẽ làm vỡ `antd 6` (cần React 18+) và `@xyflow/react 12`.

Nhưng **engine AtlasMap là Java**, mà `apps/control` đã là Spring Boot — nên phần *thật sự*
có giá trị của AtlasMap (mô hình mapping, thư viện hàm biến đổi, bộ sinh biến đổi) chạy
được nguyên vẹn ở backend. Chỉ có lớp vẽ là tự làm. Đây là cách giữ đủ sức mạnh mà
không nhập khẩu mâu thuẫn phiên bản.

---

## 1. Điều phải giữ lại từ IP-06

Bốn lỗi ở [IP-06 §0](06-ke-hoach-lam-lai-designer.md) **vẫn phải có test chặn** sau khi
viết lại lõi — viết lại mã không có nghĩa là viết lại bài học:

| # | Lỗi cũ | Vẫn chặn bằng |
|---|---|---|
| 1 | `enrich` sinh `timeout` → Camel từ chối nạp route | Test khẳng định `enrich` không có `timeout`; `pollEnrich` thì có |
| 2 | Bộ đếm mã nút trùng mã do bộ đọc YAML đặt | Test sinh mã sau khi nạp sơ đồ có sẵn |
| 3 | Nút thiếu `measured` → React Flow giữ `visibility: hidden` | Test mọi lối thêm chặng |
| 4 | Tham chiếu `kind/name` không chuẩn hóa → khóa DSL sai | Test YAML không chứa tiền tố loại |

Thêm hai bài học từ chính IP-06, nay nâng thành ràng buộc:

- **Không nuốt dữ liệu người dùng.** JSON/YAML hỏng thì hiện ô thô để sửa (G4-6).
- **Không khóa oan.** Không kiểm được thì không chặn — khóa nhầm tệ hơn cho qua (G5-2).

### 1.1. Lỗi #5 — phát hiện khi khảo sát cho IP-07 *(mất dữ liệu, đang tồn tại)*

Chạy round-trip thật trên `routes/_examples/ping.camel.yaml` (2026-08-05):

```diff
- - setBody:
-     constant: "lgsp-camel-dancu:ok"
+ - setBody:
+     expression: {}
```

**Nội dung bản tin biến mất, không một cảnh báo nào.** Nguyên nhân: bộ sinh không xử lý
ngôn ngữ biểu thức `constant`, trong khi `schemas/pattern/setBody.json` liệt kê nó là một
trong các ngôn ngữ hợp lệ ngang hàng `simple`/`csimple`/`header`. Route sau round-trip vẫn
**nạp được bằng Camel** — nên BR-D-04 không bắt được — nhưng chạy ra kết quả sai.

Lỗi này **không do IP-07 gây ra** và cũng không đợi IP-07 mới sửa được. Xử lý:

- [x] **K0-1.** Sửa ngay ở lõi hiện tại, độc lập với đợt này: xử lý đủ bộ ngôn ngữ biểu thức
      của `setBody`/`setHeader`/`filter`/`when`, giữ **ngôn ngữ** chứ không chỉ giá trị.
      *(Nguyên nhân gốc là **hai phía cùng sai**: `parse.ts` chỉ đọc khóa `expression` nên
      không thấy `constant` nằm thẳng trên bước → giá trị rơi mất ngay lúc đọc; rồi
      `emit.ts` hardcode `{simple: expr}` nên kể cả đọc đúng cũng ghi sai ngôn ngữ.
      Cách sửa: `exprOfWithLang()` đọc cả hai dạng lồng/thẳng và trả kèm ngôn ngữ;
      `exprWith()` ghi lại đúng ngôn ngữ đã đọc. **Cố ý không đoán ngôn ngữ theo hình dạng
      chuỗi lúc ghi** — đoán sai chính là cơ chế của lỗi này; `detectLang` chỉ dùng để xem trước.)*
- [x] **K0-2.** Test chặn: 4 ca mới trong `describe('chặn lỗi đã từng làm hỏng sản phẩm')` —
      round-trip `setBody: constant`, **cả 26 ngôn ngữ** trong `schemas/language/`, `exprLang`
      không lọt ra YAML, và `EXPR_LANGS` phải khớp đúng thư mục lược đồ đã vendor.
      *(Kiểm chứng test thật sự chặn được: tạm đưa lỗi cũ trở lại → 2 ca **đỏ** đúng như kỳ vọng,
      khôi phục → xanh. Test không chứng minh được là đỏ được thì chỉ là trang trí.)*
- [x] **K0-3.** **Nghiệm thu BR-D-04 trên Camel thật** — nạp bản round-trip vào
      `camel/dancu` và chạy: `Started ping-health (direct://health)` và quan trọng hơn,
      nhật ký in `ping lgsp-camel-dancu:ok` — **thân bản tin còn nguyên**.
      *(Trước khi sửa, route này **vẫn khởi động được** nhưng in ra `ping ` rỗng — đó là
      lý do BR-D-04 một mình không bắt được lớp lỗi này. Từ nay N-3b mới là cổng chặn thật.)*
      Kiểm thêm `demo-tra-cuu.camel.yaml`: `setHeader` → `constant: GET` cũng giữ nguyên —
      một ca thật thứ hai mà lỗi cũ sẽ phá.

**Nghiệm thu cuối đợt (kế thừa BR-D-04):** Camel thật nạp được **cả bốn** loại tài nguyên
do trình thiết kế sinh. Không đạt thì coi như chưa xong.

---

## 2. Thứ tự thi công

```text
K1 lõi cây ──> K2 đa route ──> K3 Kamelet/Pipe ──> K4 catalog ──> K5 Bean/Metadata ──> K6 DataMapper ──> K7 nghiệm thu
                                      └────────────> K4 chạy song song được
```

**Lý do thứ tự.** K1 là điều kiện cần của mọi thứ còn lại: chừng nào mô hình còn là đồ thị
phẳng `StageNode[]`/`SeqEdge[]` thì không biểu diễn nổi Kamelet (`spec.template.from`) hay
Pipe (`spec.source`/`spec.sink`). Làm K3 trước K1 sẽ phải viết lại lần hai.

K4 (catalog) **ít phụ thuộc lõi nhất** — dữ liệu 742 lược đồ đã vendor sẵn — nên tách ra
làm song song được nếu cần kết quả sớm.

K6 (DataMapper) để cuối vì nó là hạng mục nặng nhất và phụ thuộc K5 (bean registry).

---

## 3. K1 — Lõi mô hình cây (không giao diện, test trước)

> Thay `apps/console/src/flows/core/`. Đây là gói rủi ro cao nhất của cả đợt.

### 3.0. Khảo sát trước khi viết — lỗi #6 *(mất cấu trúc lồng, im lặng)*

Đo bằng round-trip thật trên bộ mẫu (2026-08-06). Kết quả **nghiêm trọng hơn lỗi #5**:

| Cấu trúc | Bộ đọc báo | Thực tế sau round-trip |
|---|---|---|
| `doTry` | **OK** | `doTry: {}` — mất cả `steps` được bảo vệ **lẫn toàn bộ `doCatch`** |
| `loadBalance` | **OK** | `loadBalance: {}` — mất hết nhánh cân tải |
| `multicast` | **OK** | `multicast: {}` — mất hết nhánh |
| `split` | **OK** | mất `steps` con, chỉ còn biểu thức |
| nhiều route/tệp | lỗi rõ ràng | — |
| Kamelet · Pipe · `routeConfiguration` | lỗi rõ ràng | — |

Ba dòng cuối **báo lỗi đàng hoàng** nên người dùng biết đường tránh. Bốn dòng đầu mới là
vấn đề: bộ đọc **báo thành công** rồi lặng lẽ vứt cây con. Mở một luồng có `doTry` để xem
rồi bấm lưu là **xóa sạch nhánh xử lý lỗi** — không cảnh báo, và YAML sinh ra vẫn hợp lệ
nên Camel vẫn nạp được, y hệt cơ chế của lỗi #5.

Đây là lý do K1 **thay lõi** chứ không vá: nguồn gốc là mô hình phẳng
`StageNode[]`/`SeqEdge[]` không có chỗ biểu diễn cây con, nên mọi bộ đọc viết trên nó đều
sẽ phải vứt dữ liệu ở đúng chỗ này.

- [x] **K1-1.** Thêm phụ thuộc `yaml` (eemeli/yaml) — **2.9.0, không phụ thuộc con**, và
      `vite` đã kéo sẵn nên dedupe, chi phí bundle thực tế thấp hơn ước tính ban đầu.
      Lý do chọn: giữ được **comment** và thứ tự khóa khi round-trip.

      > **Đây không phải tiện nghi — là lỗi mất dữ liệu đang tồn tại, đã kiểm chứng.**
      > Cả **5/5** tệp trong `routes/` đều có comment, kể cả luồng đang chạy
      > `routes/at-5812634/route.camel.yaml`, và đó là **dòng xuất xứ do `GitOpsPublisher` ghi**.
      > Chạy thật `graphFromYaml` → `emitRouteYaml` trên chính tệp đó (2026-08-05):
      > ```diff
      > - # Generated by lgsp-control routes publish (WP-23)
      > - # routeCode=at-5812634 version=1
      > + # Sinh từ trình thiết kế luồng LGSP — Camel YAML DSL
      > + # Định nghĩa này đi vào kho Git rồi Argo CD triển khai, không sửa trực tiếp trên môi trường.
      > ```
      > Dấu vết `routeCode`/`version` **không bị xóa lộ liễu mà bị thay bằng banner trông cũng
      > chính thống như vậy** — nhìn tệp sau đó không ai biết là đã mất. BR-D-06 yêu cầu ghi
      > nhật ký mọi thay đổi, nên đây là lỗi kiểm toán. N-3 là **cổng chặn**.
- [x] **K1-2.** `tree.ts` — lớp `CamelResource`:
      ```text
      CamelResource (1 file YAML)
        ├── kind: Route | Kamelet | Pipe | Test
        ├── entities: VisualEntity[]        # nhiều route trong một file
        └── beans / metadata                # K5
      ```
- [x] **K1-3.** `tree.ts` — `VisualEntity` + `StepNode.branches`: cây node lồng nhau thay đồ thị phẳng.
      Mỗi node có **đường dẫn** (`route.from.steps.2.choice.when.0`) thay vì mã sinh tăng dần —
      đây là điều làm `doTry`/`loadBalance` lồng biểu diễn được, và **loại bỏ hẳn lỗi #2**
      của IP-06 vì không còn bộ đếm.
- [x] **K1-4.** `serialize.ts` — cây → YAML qua thư viện, giữ comment.
      *(Comment mở đầu tệp route **không** nằm ở `doc.commentBefore` mà ở `items[0].commentBefore` —
      đúng chỗ `GitOpsPublisher` ghi dòng xuất xứ. Test bắt được thiếu sót này ngay lần chạy đầu.)*
- [x] **K1-5.** `deserialize.ts` — YAML → cây. **Không còn khái niệm "ngoài tập con"**:
      đọc được `doTry`/`loadBalance`/`multicast`/`split` **kèm cây con**, nhiều route một
      tệp, `routeConfiguration`, Kamelet, Pipe.
- [x] **K1-6.** `flatten.ts` — cây → `StageNode[]`/`SeqEdge[]` cho XYFlow vẽ.
      **Giữ nguyên ADR-017**: XYFlow vẫn là động cơ vẽ, chỉ đổi nguồn dữ liệu.
      Node lồng hiện thành nhóm gập được, không phải cạnh phẳng.
- [ ] **K1-7.** `validate.ts` — sửa theo Q1: chặng khung chuẩn thành **cảnh báo**
      (`severity: warning`), không phải lỗi chặn. Giữ nguyên các lỗi thật (thiếu tham số
      bắt buộc, node mồ côi, `choice` không vét cạn).
- [ ] **K1-8.** Test lõi ≥ 120 ca: 4 ca chặn lỗi cũ (§1) + round-trip **giữ comment** +
      `doTry`/`loadBalance`/multi-route + 3 loại tài nguyên mới.

**Cổng ra K1:** `npm test` xanh, và round-trip một file YAML Camel thật lấy từ `routes/`
cho ra **đúng byte** ban đầu (trừ khác biệt thụt lề đã chuẩn hóa).

---

## 4. K2 — Tạo và quản lý route

- [ ] **K2-1.** Nhiều route trong **một** file: danh sách route ở thanh bên trái designer,
      chuyển qua lại, thêm/xóa/đổi tên/nhân bản.
- [ ] **K2-2.** Tạo route mới: **luồng trắng** hoặc chọn mẫu (Q1). Mẫu "khung chuẩn LGSP"
      = 4 chặng cũ, nhưng **gỡ được**.
- [ ] **K2-3.** `routeConfiguration`, `errorHandler`, `onException` cấp file — các entity
      này đã có lược đồ sẵn trong `core/generated/schemas/entity/`.
- [ ] **K2-4.** Đổi tên route cập nhật mọi tham chiếu `direct:`/`seda:` trỏ tới nó,
      hoặc cảnh báo rõ nếu không tự sửa được. **Không đổi lặng lẽ làm hỏng luồng khác.**
- [ ] **K2-5.** DB: thêm cột `resource_kind VARCHAR(20)` vào `ph04.route`
      (changeset Liquibase mới). **Không dùng lại `route_type`** — cột đó đang mang
      ngữ nghĩa vận chuyển (`SYNC`, mặc định ở `RoutesService:86`), khác hẳn ngữ nghĩa
      loại tệp. Gộp hai khái niệm vào một cột sẽ hỏng cả hai.
- [ ] **K2-6.** `CamelYamlValidator` (Java) nhận thêm 3 loại tài nguyên; `REQUIRED_STAGES`
      chuyển thành cảnh báo theo Q1.

---

## 5. K3 — Kamelet, Pipe, Test

- [ ] **K3-1.** **Kamelet**: `spec.definition` (JSON Schema tham số) + `spec.template.from`.
      Trình soạn tham số kamelet: tên, kiểu, mặc định, bắt buộc, mô tả.
- [ ] **K3-2.** Kamelet tự viết hiện trong bảng thành phần cạnh 243 kamelet dựng sẵn,
      phân biệt rõ nguồn.
- [ ] **K3-3.** **Pipe**: `spec.source` → `spec.steps[]` → `spec.sink`, kèm `errorHandler`.
      Canvas Pipe là **dãy tuyến tính**, không phải đồ thị nhánh — dùng lại `VisualEntity`
      nhưng khóa thao tác rẽ nhánh.
- [ ] **K3-4.** **Test** (Camel JBang / Citrus): gắn với một route, khai báo bản tin vào và
      khẳng định đầu ra.
- [ ] **K3-5.** Bộ chọn loại khi tạo mới: Route · Kamelet · Pipe · Test.
- [ ] **K3-6.** Nghiệm thu từng loại bằng Camel thật (xem N-2).

> **Câu hỏi mở K3-4** — chạy Test bằng `camel-jbang` trong container ở `apps/control`,
> hay đẩy sang runner riêng? Quyết định khi tới K3, không chặn K1/K2.

---

## 6. K4 — Màn catalog *(chạy song song được)*

Dữ liệu đã có đủ: **742 lược đồ** trong `core/generated/schemas/` (323 component ·
243 kamelet · 74 pattern · 48 dataformat · 26 language · 21 entity · 7 loadbalancer).
Đây là **màn còn thiếu**, không phải dữ liệu còn thiếu.

- [ ] **K4-1.** `/catalog` — duyệt toàn bộ, tab theo `kind`, lọc theo nhãn gốc có số đếm.
- [ ] **K4-2.** Tìm kiếm có xếp hạng, **ảo hóa** (NFR-D-02 < 50 ms/lần gõ).
- [ ] **K4-3.** Trang chi tiết: mô tả gốc, bảng thuộc tính đầy đủ theo nhóm, cú pháp URI,
      mức hỗ trợ, cảnh báo `deprecated`, phụ thuộc Maven.
- [ ] **K4-4.** Từ catalog kéo/thêm thẳng vào luồng đang mở.
- [ ] **K4-5.** Hiện rõ nguồn + giấy phép catalog (Apache-2.0, `camel-quarkus/3.35.0`) —
      nghĩa vụ tuân thủ giấy phép.

---

## 7. K5 — Bean và Metadata

- [ ] **K5-1.** **Bean registry** cấp file: `beans[]` với `name`, `type`, `properties`.
      Lược đồ đã có ở `schemas/entity/bean.json`.
- [ ] **K5-2.** Trường nào nhận bean thì hiện **Select** các bean đã khai, không bắt gõ tay
      chuỗi `#beanName`.
- [ ] **K5-3.** **Metadata** cho Kamelet/Pipe: `metadata.name`, `labels`, `annotations`
      (`ObjectMeta.json` đã có).
- [ ] **K5-4.** BR-D-02 vẫn tuyệt đối: bean **không** chứa bí mật — chỉ tham chiếu Vault /
      kết nối PH-05. Kiểm ở cả console và `CamelYamlValidator`.

---

## 8. K6 — DataMapper

> Kiến trúc theo Q4: **UI ở console (React 19), engine ở `apps/control` (Java)**.

- [ ] **K6-1.** Backend: thêm `atlasmap-runtime` vào `apps/control` (lane L-CTRL).
      Endpoint kiểm tra/chạy mapping. Kiểm giấy phép trước khi thêm phụ thuộc.
- [ ] **K6-2.** Nạp lược đồ nguồn/đích từ: XSD/JSON Schema tải lên, **CDM trong
      `contracts/cdm/`**, hoặc suy ra từ bản tin mẫu.
- [ ] **K6-3.** UI ba cột: cây nguồn │ đường nối │ cây đích. Vẽ bằng SVG, theo token
      của `ui_ux_rule.md`, đồng bộ chế độ sáng/tối với phần còn lại của console.
- [ ] **K6-4.** Kéo–thả trường sang trường; ánh xạ 1–1, nhiều–1 (ghép), 1–nhiều (tách).
- [ ] **K6-5.** Thư viện hàm biến đổi: chuỗi, số, ngày, điều kiện, tra bảng.
- [ ] **K6-6.** Xem trước trên bản tin mẫu — chạy thật qua engine ở K6-1, **không mô phỏng
      ở trình duyệt** (mô phỏng sẽ lệch với lúc chạy thật).
- [ ] **K6-7.** Sinh ra bước Camel thật (`.adm` qua atlasmap, hoặc XSLT), nối vào luồng.
- [ ] **K6-8.** Nâng cấp `FieldMapping` hiện tại (`from`/`to` phẳng ở `model.ts:5`) lên mô
      hình mới, **giữ đọc được luồng cũ**.
- [ ] **K6-9.** Cô lập sau một adapter (`mapper/engine.ts`) để đổi engine sau này không
      phải sửa UI.

---

## 9. Thay đổi tài liệu bắt buộc

Không có mục này thì mã và đặc tả lệch nhau — vi phạm luật "không vibe coding".

- [ ] **T-1.** **SRS PH-04/D — sửa BR-D-01** theo Q1: từ "không gỡ được" thành "khung chuẩn
      là mẫu; gỡ chặng thì `validate` cảnh báo; luồng đối ngoại vẫn phải đủ chặng trước khi
      publish". Ghi rõ lý do đổi.
- [ ] **T-2.** SRS PH-04/D — thêm FR cho: đa route (`FR-D-005…`), Kamelet/Pipe/Test
      (`FR-D-06x`), catalog (`FR-D-07x`), bean/metadata (`FR-D-08x`), DataMapper (`FR-D-09x`).
- [ ] **T-3.** SRS PH-04/D — thêm màn **D-07 Catalog** và **D-08 DataMapper** vào mục 2 và
      ma trận mục 11.
- [ ] **T-4.** **ADR mới** cho Q2 (bỏ bộ YAML tự viết, dùng thư viện + mô hình cây) và Q4
      (DataMapper tách UI/engine). Hai quyết định này đủ sức nặng kiến trúc để cần ADR.
- [ ] **T-5.** Cập nhật `docs/08-implementation/04-ke-hoach-phat-trien.md` chèn IP-07.

---

## 10. Nghiệm thu

| Cổng | Kiểm | Kỳ vọng |
|---|---|---|
| **N-1** | `npm test` | ≥ 120 ca lõi xanh, gồm 4 ca chặn lỗi cũ của IP-06 |
| **N-2** | **Camel thật nạp cả 4 loại** do designer sinh | `Started <id>` · BUILD SUCCESS cho Route · Kamelet · Pipe · Test |
| **N-3** | Round-trip giữ comment | Mở → lưu `routes/at-5812634/route.camel.yaml` → dòng `# routeCode=… version=…` **còn nguyên** |
| **N-3b** | Round-trip giữ biểu thức (lỗi #5) | 26 ngôn ngữ trong `schemas/language/` không mất giá trị; `setBody: {constant: …}` giữ nguyên |
| **N-4** | Round-trip cấu trúc phức | `doTry`, `loadBalance`, 3 route/file mở và lưu không mất cấu trúc |
| **N-5** | NFR-D-01…08 | Không hạng mục mới nào làm tụt ngưỡng cũ |
| **N-6** | e2e đa loại | Tạo Kamelet → dùng trong Pipe → chạy thử → publish |
| **N-7** | DataMapper | Ánh xạ CDM → định dạng đích, chạy thật, kết quả khớp kỳ vọng |
| **N-8** | Tiếp cận | Giữ chuẩn N-7 của IP-06: 0 nút thiếu nhãn, 0 chỗ dưới ngưỡng tương phản |
| **N-9** | Tương thích ngược | **Mọi luồng đang có trong CSDL mở được bằng lõi mới** |

> **N-9 là cổng chặn.** Lõi mới không đọc được dữ liệu cũ thì không được triển khai.

---

## 11. Rủi ro

| Rủi ro | Mức | Xử lý |
|---|---|---|
| Viết lại lõi làm hỏng luồng đang chạy | **Cao** | N-9 chặn; giữ `parse.ts` cũ làm bộ đọc dự phòng tới khi N-9 đạt |
| `atlasmap-runtime` xung đột phụ thuộc với Spring Boot 4 | **Cao** | Kiểm ở K6-1 **trước** khi làm UI; nếu vỡ thì lùi về XSLT thuần |
| Khối lượng K6 vượt dự kiến | Trung bình | K6-4/5 làm được từng phần; ánh xạ 1–1 đã dùng được rồi |
| Bundle phình sau khi thêm `yaml` | Thấp | ~40KB gz; đo lại ở N-5 |
| Sửa BR-D-01 bị hiểu là nới lỏng kiểm soát | Trung bình | T-1 ghi rõ: cảnh báo lúc thiết kế, **vẫn chặn lúc publish** với luồng đối ngoại |

---

## 12. Lịch sử

| Ngày | Thay đổi |
|---|---|
| 2026-08-05 | Khởi tạo IP-07 sau khi chốt Q1–Q5. Phân tích hiện trạng: catalog **đã có đủ 742 lược đồ** (thiếu màn duyệt, không thiếu dữ liệu); nút thắt thật là mô hình phẳng `StageNode[]`/`SeqEdge[]` ở `core/model.ts` và bộ YAML tự viết chỉ đọc được tập con nó sinh ra; `route_type` hiện mang nghĩa vận chuyển (`SYNC`) nên Kamelet/Pipe/Test cần cột `resource_kind` riêng |
| 2026-08-06 | **K1-1…K1-6 xong.** `tree.ts` + `deserialize.ts` + `serialize.ts` + `flatten.ts`, 22 ca test mới (148 tổng). Nghiệm thu trên **Camel 4.18.2 thật**: `k1-nested` (doTry+doCatch+doFinally+choice 2 nhánh+multicast) và `k1-multi-a`/`k1-multi-b` (nhiều route một tệp — thứ lõi cũ **không mở nổi**) đều `Started`. Hai lỗi của chính bộ sinh mới bị test/Camel bắt kịp thời: (1) `otherwise` ghi thành **danh sách trần** → Camel từ chối `Unsupported type: SEQUENCE`; lược đồ vendor **không** phát hiện được vì thuộc tính `steps` của `otherwise` khai là null — phải ghi dạng đối tượng bọc `steps`; (2) `constant` ghi **hai lần** vì khóa ngôn ngữ dạng chuỗi rơi vào `props` còn dạng đầy đủ rơi vào `rest`, dọn thiếu một bên. Thêm `K1ChoiceOrderTest` chứng minh thứ tự khóa `otherwise` trước `when` **không** đổi ngữ nghĩa định tuyến (a=1→nhanh-mot, a=2→nhanh-hai, a=99→nhanh-khac) — "route khởi động được" không đủ, đúng bài học lỗi #5 |
| 2026-08-05 | **Chạy round-trip thật trên tệp trong `routes/` khi khảo sát — lộ hai lỗi mất dữ liệu đang tồn tại.** (1) Comment xuất xứ do `GitOpsPublisher` ghi (`# routeCode=at-5812634 version=1`) bị **thay bằng banner mặc định**, không phải xóa lộ liễu — mất dấu vết kiểm toán mà nhìn tệp không nhận ra (BR-D-06). (2) `setBody: {constant: "…"}` round-trip thành `expression: {}` — **nội dung bản tin biến mất im lặng**, mà route vẫn nạp được bằng Camel nên BR-D-04 không bắt được. Lỗi (2) ghi thành **lỗi #5** + gói **K0** để sửa ngay, không đợi hết đợt |
