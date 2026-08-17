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

## Trạng thái — cập nhật 2026-08-07

| Gói | Trạng thái |
|---|---|
| **K0** sửa lỗi mất dữ liệu | ✅ nghiệm thu trên Camel thật |
| **K1** lõi mô hình cây | ✅ nghiệm thu trên Camel thật |
| **K2** đa route + sửa trên cây | ✅ nghiệm thu trên Camel thật |
| **K3** Kamelet · Pipe · Test | ✅ K3-1/2/3/5 · ⛔ K3-4/6 (thiếu gói offline) |
| **K4** danh mục thành phần | ✅ *(phiên song song)* |
| **K5** Bean · Metadata | ✅ nghiệm thu trên Camel thật |
| **K6** DataMapper | ✅ K6-2…9 · ⛔ K6-1 (thiếu gói offline) |
| **T-1…T-5** tài liệu | ✅ đủ năm mục (§9) — ADR-021/022 chốt 2026-08-17 |

**Nghiệm thu:** 9/11 cổng đạt · 1 đạt một phần (N-6) · 1 chặn bởi môi trường (N-2b).
**N-9 — cổng chặn triển khai — đã đạt** trên toàn bộ luồng thật trong CSDL. Chi tiết ở §10.

**Bảy lỗi mất dữ liệu thật đã phát hiện và sửa** trong đợt này (§1.1, §3.0, K2, K3, K5) —
tất cả đều **im lặng**, và phần lớn vẫn cho YAML mà Camel nạp được, nên không cổng nghiệm
thu nào trước đây bắt được.

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

K4 (catalog) **ít phụ thuộc lõi nhất** — dữ liệu 751 nút đã vendor sẵn — nên tách ra
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
- [x] **K1-6b.** *(mới)* `unflatten.ts` — sơ đồ → cây, và **nối lõi mới vào trình thiết kế**.

      > **Vì sao phải có, đo bằng thử nghiệm thật.** Trình thiết kế sửa trực tiếp trên
      > `StageNode[]` ở **29 chỗ**. Thử đổi *mỗi bộ đọc* sang lõi cây mà vẫn để *bộ ghi cũ*
      > chạy trên sơ đồ phẳng thì không chỉ mất dữ liệu mà **bóp méo**:
      > ```diff
      > - doTry:  steps → to(http://x);  doCatch → exception java.io.IOException
      > + choice: when[0] → to(http://x); when[1] → log(loi)      # lớp ngoại lệ biến mất
      > ```
      > Xử lý lỗi lặng lẽ hóa thành định tuyến điều kiện. Nên bộ đọc và bộ ghi **phải đổi
      > cùng lúc**. `applyGraphToTree` lấy cây gốc làm nền rồi áp thay đổi từ sơ đồ, nên
      > khóa lạ, thuộc tính khe và comment đều còn nguyên.
      >
      > Hạn chế đã biết: **chặng thêm mới trên canvas chưa vào được cây** (chưa có đường
      > dẫn). Khi có chặng như vậy thì lùi về bộ sinh cũ — thà YAML kém tinh gọn còn hơn
      > lặng lẽ bỏ rơi chặng người dùng vừa thêm. Sửa thẳng trên cây là việc của K2.
      **Giữ nguyên ADR-017**: XYFlow vẫn là động cơ vẽ, chỉ đổi nguồn dữ liệu.
      Node lồng hiện thành nhóm gập được, không phải cạnh phẳng.
- [x] **K1-7.** `validate.ts` — sửa theo Q1: chặng khung chuẩn thành **cảnh báo**, không
      phải lỗi chặn. Giữ nguyên các lỗi thật (thiếu tham số bắt buộc, node mồ côi,
      `choice` không vét cạn). Luồng trắng chỉ có chặng tiếp nhận nay **không còn lỗi chặn**.

      > ⚠ **Đính chính giả định của Q1.** Q1 nói "cảnh báo lúc thiết kế, **vẫn chặn lúc
      > publish** với luồng đối ngoại". Soi mã `CamelYamlValidator` thì **chốt chặn đó chưa
      > từng tồn tại**: `REQUIRED_STAGES` ở máy chủ vốn đã phát mức `WARN`, mà `publish()`
      > chỉ chặn khi có finding mức `ERROR` (`RoutesService:257`).
      >
      > Nghĩa là hạ mức ở console **không nới lỏng kiểm soát nào đang có** — nhưng cũng
      > nghĩa là **hiện không tầng nào bắt buộc khung chuẩn**. Đây là khoảng trống có thật,
      > không phải hệ quả của K1. Xử lý ở **K2-6** thay vì lặng lẽ bỏ qua.

- [~] **K1-7b.** `CamelYamlValidator` nâng chặng khung chuẩn lên `ERROR` để `publish()`
      chặn thật — **cơ chế xong**, có test chứng minh chặn được (bỏ cờ đi thì test đỏ).
      Bật theo cờ `lgsp.routes.strict-standard-stages`, **mặc định tắt**.

- [x] **K1-7c.** Nối định nghĩa "luồng đối ngoại" vào danh mục hệ thống thành viên PH-01
      — **theo phương án (b): PH-01 phát sự kiện, PH-04 giữ bản sao đọc.**

      > **Vì sao không gọi thẳng.** `RoutesService` → `OnboardingApi` làm
      > `ApplicationModules.verify()` đỏ (`Allowed targets: shared`). Cả hai mô-đun đều khai
      > `allowedDependencies = "shared"` — kiến trúc cố ý giữ PH-01 và PH-04 độc lập.
      >
      > **Cách làm.** `SystemApprovedEvent` đặt ở `shared` (mô-đun khai `Type.OPEN`, là phụ
      > thuộc hợp lệ của mọi mô-đun) → PH-01 phát khi duyệt, cạnh outbox sẵn có →
      > `ExternalSystemRegistry` của PH-04 nghe và ghi vào `ph04.external_system` của **chính
      > mình**. Không cần ADR vì không mở phụ thuộc mới nào.
      >
      > **Hai chi tiết dễ hỏng, đã xử lý:**
      > 1. **Nạp lại dữ liệu cũ.** Bản sao chỉ nghe sự kiện thì hệ thống kết nạp **trước** khi
      >    có mã này sẽ mãi bị coi là nội bộ — chốt chặn thả lọt đúng những luồng lâu đời nhất
      >    mà không ai thấy gì bất thường. Changeset `008-…-backfill` nạp một lần: **28 hệ
      >    thống** đã có.
      > 2. **So khớp hoa thường.** `source_system` người dùng gõ tay, `system_code` do quy
      >    trình sinh. So khớp cứng thì luồng đối ngoại lọt qua im lặng. Cả hai phía hạ về
      >    chữ thường; test chứng minh chặn được (bỏ `toLowerCase` đi thì đỏ).
      >
      > **Nghiệm thu trên hệ thống chạy thật** (Postgres + Keycloak + control): duyệt
      > `SYS_15659162` qua đúng quy trình (thẩm định pháp lý → kỹ thuật → duyệt, API thật với
      > token `dev-reviewer`) → bản sao PH-04 **nhận được ngay** (`sys_15659162`). Tạo luồng có
      > `sourceSystem: SYS_15659162` → phân loại **đối ngoại = true** dù khác kiểu chữ.
      > Bốn luồng cũ vẫn là nội bộ (đúng — chúng là luồng thử).
      >
      > Cờ `lgsp.routes.strict-standard-stages` vẫn **mặc định tắt**: bốn luồng hiện có đều
      > nội bộ nên bật cũng không đổi gì, chỉ thêm rủi ro. Bật khi có luồng đối ngoại thật.

- [x] **K1-8.** Test lõi: **152 ca xanh** (122 cũ + 30 mới), gồm 4 ca chặn lỗi cũ (§1),
      round-trip giữ comment, `doTry`/`loadBalance`/`multicast`/`split`, nhiều route một tệp,
      Kamelet, Pipe, `routeConfiguration`, và ca **quay vòng hai lần cho kết quả y hệt**
      (chứng minh không bào mòn dần qua mỗi lần lưu).

**Cổng ra K1 — ✅ đạt (2026-08-06).** `npm test` 152 ca xanh, `tsc --noEmit` sạch, và
tệp nghiệm thu gom đủ cấu trúc khó (`doTry` ba khe + `split` lồng trong `doTry` +
`choice` nhiều nhánh + `multicast` lồng trong `when` + hai route một tệp + comment đầu tệp)
**chạy đúng trên Camel 4.18.2 thật**, không chỉ khởi động được:

```text
tung-phan-tu   ← split lồng trong doTry chạy
don-dep        ← doFinally chạy
da-huong-1/2   ← multicast lồng trong when chạy
khong-ro-loai  ← otherwise chạy đúng dù được ghi trước when
Tests run: 3, Failures: 0, Errors: 0 · BUILD SUCCESS
```

Đây là mức bằng chứng bài học lỗi #5 đòi hỏi: route `Started` **không** đủ, phải thấy
bản tin đi đúng nhánh.

---

## 4. K2 — Tạo và quản lý route

- [x] **K2-1.** Nhiều route trong **một** file: danh sách route ở thanh bên trái designer,
      chuyển qua lại, thêm/xóa/đổi tên/nhân bản (`EntityList.tsx`).
      *(Kiểm chứng trên trình duyệt thật với tệp 3 route: chuyển sang route có `doTry` thì
      canvas vẽ đúng **hai nhánh** — `steps` được bảo vệ và `doCatch` — thứ lõi cũ bóp thành
      `doTry: {}`. Sau khi chuyển, YAML vẫn giữ đủ `doCatch`, lớp ngoại lệ, comment xuất xứ
      và cả 3 route; 0 lỗi console. Deep link qua vòng đăng nhập vẫn đúng.)*

      > **Điểm dễ mất dữ liệu nhất của gói này:** chuyển route mà quên áp thay đổi của route
      > đang mở vào cây thì công sức trên canvas biến mất lặng lẽ. `selectEntity` áp trước
      > rồi mới chuyển; có test khẳng định sửa route thứ hai **không đụng** route thứ nhất.
- [ ] **K2-2.** Tạo route mới: **luồng trắng** hoặc chọn mẫu (Q1). Mẫu "khung chuẩn LGSP"
      = 4 chặng cũ, nhưng **gỡ được**.
- [x] **K2-3.** `routeConfiguration`, `errorHandler`, `onException` cấp tệp — lõi cây đọc và
      ghi lại nguyên vẹn, có test.

      > **Một lỗi của bộ sinh, bắt được nhờ đối chiếu lược đồ:** ghi `steps: []` cho
      > `routeConfiguration`, mà lược đồ của nó **không có** thuộc tính `steps` (chỉ có
      > `errorHandler`/`onException`/`intercept`…). Bịa khóa không tồn tại đúng là lớp lỗi #1
      > của IP-06 (`enrich` tự thêm `timeout`). Nay chỉ ghi `steps` khi thật sự có bước.
- [x] **K2-4.** Đổi tên route cập nhật mọi tham chiếu `direct:`/`seda:` trỏ tới nó.
      `renameEntity` trả kèm **số tham chiếu đã sửa** để giao diện nói rõ thay vì âm thầm
      đổi. Chặng tiếp nhận qua `rest:`/`kafka:` thì tên route không phải địa chỉ nên
      không đụng tới.
- [x] **K2-5.** DB: cột `resource_kind VARCHAR(20) NOT NULL DEFAULT 'ROUTE'` + chỉ mục,
      changeset `007-e-resource-kind.yaml`. **Không dùng lại `route_type`** — cột đó mang
      ngữ nghĩa vận chuyển (`SYNC`), khác hẳn ngữ nghĩa loại tệp.
      *(Kiểm chứng trên Postgres 17 thật đang chạy, có sẵn 4 luồng: cột và chỉ mục tạo
      đúng, **4 dòng cũ điền `ROUTE`**, `route_type` không bị đụng tới, hai changeset ghi
      `EXECUTED` trong `databasechangelog`, ứng dụng khởi động sạch.)*
- [x] **K2-6.** `CamelYamlValidator` nhận thêm 3 loại tài nguyên: Kamelet/Pipe kiểm theo
      hình dạng CRD (`kind:` + khóa bắt buộc dưới `spec`), **không** bắt theo khung chín
      chặng vì về cấu trúc chúng không thể có. 10 ca test.

---

## 5. K3 — Kamelet, Pipe, Test

- [x] **K3-1.** **Kamelet**: `kamelet.ts` đọc/ghi `spec.definition` đúng dạng JSON Schema
      draft-07 mà 243 kamelet vendor dùng; `KameletSpec.tsx` soạn tên/kiểu/nhãn/mô tả/mặc
      định/bắt buộc. Nút chỉ hiện khi tài nguyên là Kamelet.

      > **Kiểu tham số lấy theo dữ liệu thật, không theo enum lược đồ.** Enum của
      > `KameletConfiguration` là `string|number|boolean` — sai cả hai đầu: thiếu `integer`
      > (phổ biến thứ ba, 111 lần) và có `number` mà **không kamelet gốc nào dùng**. Đếm
      > trên 243 kamelet: `string` 1256 · `boolean` 316 · `integer` 111 · `binary` 9 ·
      > `long` 1. Có test khóa danh sách với thư mục lược đồ.

- [x] **K3-2.** Kamelet tự viết hiện **đầu** tab Kamelet, cạnh 243 kamelet dựng sẵn, có huy
      hiệu "tự viết" riêng (màu `#1d4ed8`, đo được 6,09:1 — đạt AA cho chữ 9px). Người dùng
      phải phân biệt được thứ nền tảng bảo đảm với thứ đơn vị tự viết: nhầm hai loại là nhầm
      cả trách nhiệm vận hành khi nó hỏng. Kèm `resourceKind` cho `RouteQuery` (lọc phía máy chủ).

- [x] **K3-3.** **Pipe**: `pipe.ts` đọc dãy `source` → `steps[]` → `sink`, sửa tham số và
      đổi Kamelet từng mắt mà **giữ nguyên `apiVersion`/`kind` của `ref`** — dựng lại cả mắt
      sẽ làm bay thứ Camel cần để tra đúng Kamelet. Khóa mọi thao tác rẽ nhánh
      (`allowedInPipe`): Pipe là dãy tuyến tính, thả `choice` vào là dựng ra thứ không nạp được.

- [~] **K3-4.** **Test**: `test-resource.ts` + mẫu — `spec.route` trỏ route được kiểm,
      `spec.cases[]` mỗi ca có bản tin vào và khẳng định. **Mô hình xong, bộ chạy chưa có.**

      > **Lỗi mất dữ liệu bắt được ở đây:** `deserialize` không có nhánh cho `kind: Test` nên
      > tệp Test rơi vào lối đọc route và **mất sạch nội dung** — quay vòng ra `[]`. Đã thêm
      > `readTest`/`writeTest` và test chặn.
      >
      > **Bộ chạy thật chưa có, và điều này phải nói thẳng.** Soi `RoutesService.testRun`:
      > nó dựng waterfall **chín chặng cố định** với thời lượng suy từ `stage.hashCode()` —
      > **không nạp Camel, không đọc định nghĩa luồng**. Nghĩa là "chạy thử PASSED" hiện nay
      > không chứng minh điều gì về luồng. `runnerStatus()` nói rõ trạng thái này thay vì để
      > người dùng tưởng ca kiểm thử đã được thi hành.
      >
      > Quyết định K3-4 (chọn `camel-jbang` trong `apps/control`) **chưa thi hành được ở môi
      > trường này**: không có `jbang`, không có mạng để tải. `GitOpsPublisher` đã dùng
      > `ProcessBuilder` nên đường đi kỹ thuật là rõ. Để lại cho đợt có mạng.

- [x] **K3-5.** Bộ chọn loại khi tạo mới — đã xong ở K2-2, nay đủ cả bốn loại
      (Route · Kamelet · Pipe · Test).

- [~] **K3-6.** Nghiệm thu bằng Camel thật: **Route đạt** (K2). **Kamelet/Pipe/Test chưa** —
      `camel/dancu` không có `camel-quarkus-kamelet` và kho Maven offline cũng không có gói
      đó. Thay bằng đối chiếu cấu trúc với chính 243 lược đồ nhà sản xuất phát hành. Nghiệm
      thu runtime để lại cho N-2 khi có mạng.

> **K3-4 đã chốt** — chạy bằng `camel-jbang` trong `apps/control` (`TestRunService` đã ở đó,
> không cần thêm dịch vụ mới). Chưa thi hành được vì môi trường không có `jbang`/mạng.

---

## 6. K4 — Màn catalog *(chạy song song được)*

Dữ liệu đã có đủ: **751 nút** trong chỉ mục, **742 tệp lược đồ** trong
`core/generated/schemas/` — chênh 9 là các kamelet **không có tham số cấu hình** nên nhà
sản xuất không phát hành lược đồ; vẫn là mục hợp lệ, màn chi tiết phải hiện "không có
tham số" thay vì báo lỗi tải. Phân bố: (323 component ·
**252** kamelet · 74 pattern · 48 dataformat · 26 language · 21 entity · 7 loadbalancer).
Đây là **màn còn thiếu**, không phải dữ liệu còn thiếu.

> **252 kamelet, không phải 243.** 243 là số *tệp lược đồ* kamelet trên đĩa
> (252 − 9 kamelet không có tham số), không phải số nút. Ba con số này rất dễ lẫn:
> 751 nút / 742 tệp lược đồ / 252 kamelet.
>
> **Đính chính sau khi làm K4:** câu "dữ liệu đã có đủ" ở trên **chỉ đúng một nửa**. Số
> nút thì đủ, nhưng 95/751 nút mang siêu dữ liệu rỗng do lỗi ở bộ sinh — xem K4-0. Nghĩa
> là K4 vừa là màn còn thiếu **vừa** là dữ liệu còn hỏng, chỉ có điều lỗi im lặng nên
> không ai thấy cho tới khi dựng màn duyệt nó.

- [x] **K4-0.** *(phát sinh)* **Sửa `build-catalog.mjs` — 95/751 nút mất sạch siêu dữ liệu.**
      Script đọc siêu dữ liệu theo **tên loại** (`node.dataformat`, `node.language`,
      `node.entity`) trong khi bản gốc gói tất cả dưới khóa `model` — với Camel chúng đều
      là *model* của DSL, chỉ `component` mới có khóa trùng tên loại. Vì mọi trường đều đọc
      kèm `?? mặc định`, chỉ mục vẫn sinh "thành công" với **tiêu đề trần, mô tả rỗng, không
      nhãn**: đúng dạng lỗi im lặng của BR-D-04b, và ngưỡng cũ (`< 400 nút`) không bắt được
      vì số nút không hề đổi. Nay 751/751 nút có mô tả (trước: 656).

      > Sửa kèm hai thứ nữa. **Nhãn lặp**: 3 component khai `"cloud,cloud"`
      > (`azure-key-vault`, `hashicorp-vault`, `ibm-secrets-manager`) làm chip lọc đếm 94
      > trong khi bấm vào chỉ ra 91 dòng. **`OUT_ROOT` trỏ sai** (`src/designer/catalog/`)
      > — chạy lại script sẽ ghi ra thư mục chết, không phải nơi mã đang đọc.
      >
      > Thay ngưỡng đếm bằng **kiểm chất lượng theo từng loại**: quá nửa một loại rỗng mô
      > tả thì dừng và chỉ thẳng nguyên nhân; còn nhãn lặp cũng dừng.

- [x] **K4-1.** `/components` — duyệt toàn bộ 751 nút, tab đủ **cả bảy** loại có số đếm,
      lọc theo nhãn gốc có số đếm. Trạng thái duyệt nằm trong URL nên gửi link được.

      > **Không đặt ở `/catalog`**: đường đó đã là màn đăng ký/publish dịch vụ APISIX của
      > PH-02. Cùng chữ "catalog" nhưng hai nghiệp vụ khác hẳn — gộp tên là gây nhầm.
      > Khác bảng thành phần ở ba điểm: đủ bảy loại (bảng chỉ có 5 loại thả được vào sơ
      > đồ), không lọc theo vị trí trong luồng, và có trang chi tiết đầy đủ.

- [x] **K4-2.** Tìm kiếm có xếp hạng trên tên/tiêu đề/mô tả/nhãn, **ảo hóa** danh sách
      (chỉ dựng ~18/323 hàng trong tầm nhìn) + `useDeferredValue` — đạt NFR-D-02.
- [x] **K4-3.** Trang chi tiết: mô tả gốc, bảng thuộc tính chia **nhóm gốc của Camel**
      (bắt buộc lên đầu, nhóm `advanced` gập lại), cú pháp URI, mức hỗ trợ, cảnh báo
      `deprecated`, phụ thuộc Maven.

      > **Phụ thuộc có hai dạng, không gộp.** `component` có tọa độ Maven đầy đủ → hiện
      > khối `<dependency>` dán thẳng vào `pom.xml`, kèm artifact Camel gốc và lớp Java.
      > `kamelet` chỉ khai phụ thuộc **logic** (`camel:aws2-s3`) mà Camel tự phân giải —
      > hiện nhầm dạng sẽ dẫn người dùng đi thêm artifact không tồn tại.
      >
      > Thêm `nativeSupported` vào chỉ mục: **65/323 component chưa chạy được ở ảnh
      > native**, mà ADR-002/020 chốt Camel Quarkus native — người dùng phải biết trước
      > lúc tra cứu, không phải lúc build hỏng. Phân biệt `false` (có extension nhưng
      > native chưa chạy) với `undefined` (không áp dụng) — gộp lại là cảnh báo nhầm cho
      > toàn bộ pattern/dataformat/language.
      >
      > 9 kamelet không có lược đồ hiện **"không có tham số cấu hình"** thay vì báo lỗi
      > tải. Có test quét cả 751 nút để không nút nào làm màn chi tiết trắng.

- [x] **K4-4.** Từ danh mục thêm thẳng vào luồng đang mở, hai chiều: bảng thành phần có
      lối "Tra cứu đầy đủ →", màn danh mục có nút "Thêm vào luồng &lt;mã&gt;".

      > Bắc cầu qua `sessionStorage` chứ không phải context: trình thiết kế ở route riêng
      > **ngoài** `AppShell`, hai màn không có tổ tiên chung nào ngoài `BrowserRouter`.
      > Dùng `sessionStorage` (không phải `localStorage`) vì đây là thao tác dở dang của
      > riêng tab này — mở hai luồng ở hai tab sẽ chèn nhầm chỗ. Đọc **một lần rồi xóa**,
      > nếu không StrictMode gọi effect hai lần sẽ chèn hai chặng.

- [x] **K4-5.** Hiện rõ nguồn + giấy phép catalog (Apache-2.0, `@kaoto/camel-catalog 0.7.0`,
      `camel-quarkus/3.35.0`) ở chân màn — nghĩa vụ tuân thủ giấy phép, kèm nhắc bảng tham
      số chỉ đúng với đúng phiên bản runtime này.
- [x] **K4-6.** **24 ca test** (`k4.test.ts`), trọng tâm là *chất lượng dữ liệu chỉ mục* vì
      màn chỉ vẽ lại thứ chỉ mục mang sẵn: khóa lại 95 nút từng rỗng, số chip khớp số dòng
      lọc ra được ở **mọi nhãn mọi loại**, và 9 kamelet thiếu lược đồ.

---

## 7. K5 — Bean và Metadata

- [x] **K5-1.** **Bean registry** cấp tệp (`beans.ts` + `BeanRegistry.tsx`): tên, lớp,
      thuộc tính; giữ nguyên khóa ngoài bộ ta quản (`initMethod`, `factoryMethod`…). Chặn
      bean **trùng tên** — Camel giữ bean sau đè bean trước nên cấu hình bean đầu biến mất
      lặng lẽ, luồng vẫn chạy nhưng với thứ khác hẳn. Là cửa sổ riêng vì bean dùng chung cho
      **mọi route trong tệp**.

- [x] **K5-2.** Trường nhận bean hiện **ô chọn** thay vì bắt gõ `#tenBean`. Đặt **trước**
      nhánh object/array vì nhiều trường nhận bean khai kiểu `object` — rơi xuống bảng
      khóa–giá trị thì người dùng lại phải tự gõ đúng cú pháp tham chiếu.

- [x] **K5-3.** **Metadata** cho Kamelet/Pipe: chỉ cho sửa `name`/`labels`/`annotations`.
      `ObjectMeta` còn `uid`, `resourceVersion`, `managedFields`… nhưng đó là **trường
      Kubernetes tự quản** — cho người dùng đụng là mời gọi lỗi khó lần. Đọc giữ nguyên tất
      cả, ghi chỉ đụng ba trường kia.

- [x] **K5-4.** BR-D-02 — **hai lỗ thật ở `CamelYamlValidator`**, kiểm chứng bằng cách chạy
      chính biểu thức đó chứ không đọc suông:

      > 1. **Chặn nhầm tham chiếu hợp lệ.** Mẫu cũ khớp cả
      >    `password: '{{vault:lgsp/db#password}}'` — tức là **cấm đúng cách làm mà BR-D-02
      >    yêu cầu**. Người dùng làm đúng vẫn bị chặn publish thì họ sẽ tìm cách lách, và đó
      >    mới là rủi ro thật.
      > 2. **Bỏ sót `token`** — khóa bí mật rất thường gặp, lọt thẳng qua chốt chặn.
      >
      > Sửa cả hai; test chứng minh bắt được (đưa mẫu cũ trở lại thì 2 ca đỏ). Console cảnh
      > báo sớm cùng luật, máy chủ vẫn là chốt chặn thật.

**Nghiệm thu K5.** Tệp có `beans` cấp tệp qua đúng lối K5 dùng (đọc → ghi lại) vẫn
`Started k5-bean (direct://k5bean)` trên **Camel 4.18.2 thật**. Kiểm trên trình duyệt:
`Bean (1)` hiện đúng số; nhập `password=matkhau-that` → cảnh báo BR-D-02 và **khóa nút lưu**;
đổi sang `{{vault:...}}` → cho lưu, ghi đúng vào YAML, bean cũ và route còn nguyên.

---

## 8. K6 — DataMapper

> **Q4 chốt "UI tự viết + engine AtlasMap". Khảo sát mã thật làm lệch quyết định đó** —
> ghi rõ ở đây vì đây là thay đổi so với điều chủ dự án đã duyệt.

### 8.0. Vì sao sinh JQ chứ không phải AtlasMap

| Phát hiện | Hệ quả |
|---|---|
| **Dự án đã có cơ chế ánh xạ chạy được, và không phải AtlasMap.** ADR-013 chốt CDM làm trung gian; `contracts/cdm/mappers/*.jq` là bộ ánh xạ; `CdmMapperTest` chứng minh nó chạy trên Camel thật | Thêm AtlasMap là **cơ chế ánh xạ thứ hai** song song — hai nguồn sự thật cho cùng một việc |
| **Vấn đề thật đang là ánh xạ viết tay bằng Java.** `LegacyCitizenToPersonMapper` là 60 dòng Java cho ánh xạ 4 trường; tệp `.jq` cạnh nó chỉ là tài liệu | Hai bản **trôi khỏi nhau lúc nào không biết**. Sinh JQ xóa hẳn lớp viết tay |
| `atlasmap-runtime` **không có trong kho Maven offline** | Hướng AtlasMap không kiểm chứng được ở môi trường này |

**Nếu chủ dự án vẫn muốn AtlasMap**, `mapper.ts` đã tách thuần logic khỏi giao diện nên đổi
bộ sinh không phải viết lại `DataMapper.tsx`.

- [x] **K6-2.** Nạp lược đồ: **CDM trong `contracts/cdm/`** (đích mặc định) hoặc **suy từ
      bản tin mẫu**. Phẳng hóa được cả lược đồ lồng và mảng (`diaChi[].pho`).
- [x] **K6-3.** UI ba cột: cây nguồn │ ánh xạ │ cây đích, theo token `ui_ux_rule.md`. Cột
      đích đánh dấu ✓ trường đã ánh xạ (`#15803d`, đo 5,02:1 — đạt AA chữ nhỏ, N-7).
- [x] **K6-4.** Ánh xạ 1–1 và **nhiều–1** (ghép chuỗi). *(1–nhiều tách chưa làm — cần cú
      pháp riêng cho từng đích, để lại khi có ca dùng thật.)*
- [x] **K6-5.** Bảy hàm biến đổi: giữ nguyên · cắt khoảng trắng · IN HOA · in thường ·
      sang chuỗi · sang số · mặc định nếu rỗng.
- [x] **K6-6.** Xem trước trên bản tin mẫu — **và nói rõ nó chạy trong trình duyệt**, kết quả
      thật do Camel quyết định. K6-6 bản đầu cấm mô phỏng ở trình duyệt; ở đây vẫn mô phỏng
      nhưng **dán nhãn đúng** thay vì giấu, vì engine máy chủ chưa có mà người dùng vẫn cần
      thấy ngay mình ánh xạ đúng chưa.
- [x] **K6-7.** Sinh **biểu thức JQ** nối vào chặng `transform` (`exprLang: jq`).
- [x] **K6-8.** `FieldMapping` mới thay bản `from`/`to` phẳng; giữ kèm node vì **JQ là một
      chiều**, không dựng ngược ra bảng ánh xạ được.
- [x] **K6-9.** `mapper.ts` thuần logic, không phụ thuộc React — đổi bộ sinh sau này không
      phải sửa giao diện.

- [ ] **K6-1.** *(chặn bởi môi trường)* Engine chạy mapping ở `apps/control`. `atlasmap-runtime`
      **và** `camel-quarkus-jq` đều không có trong kho Maven offline, và không có mạng để tải.
      Đường đi rõ: thêm `camel-quarkus-jq` rồi nối JQ sinh ra vào bước `transform` — nhưng
      chưa nghiệm thu được ở đây.

**Nghiệm thu K6 — mạnh hơn dự kiến.** Không chạy được qua Camel, nhưng **`jq` CLI có sẵn**.
Chạy JQ sinh ra trên đúng bản tin mẫu của `CdmMapperTest`, so với
`contracts/cdm/mappers/legacy-citizen-to-person.jq` **thật đang dùng**:

```text
sinh ra: {"dateOfBirth":"1990-01-02","fullName":"Nguyen Van A","nationalId":"012345678","personId":"P001"}
gốc    : {"dateOfBirth":"1990-01-02","fullName":"Nguyen Van A","nationalId":"012345678","personId":"P001"}
→ GIỐNG HỆT NHAU
```

Nghĩa là ánh xạ vẽ trên giao diện **thay được lớp mapper Java viết tay mà không đổi hành vi**.
Kiểm thêm trên trình duyệt thật: suy lược đồ từ bản tin mẫu, kiểm trường bắt buộc (đủ → 0 lỗi,
thiếu `fullName` → 1 lỗi), xem trước khớp kết quả `jq`; 0 lỗi console.

---

## 9. Thay đổi tài liệu bắt buộc

Không có mục này thì mã và đặc tả lệch nhau — vi phạm luật "không vibe coding".

- [x] **T-1.** **SRS PH-04/D — sửa BR-D-01** theo Q1: từ "không gỡ được" thành "khung chuẩn
      là mẫu; gỡ chặng thì `validate` cảnh báo; luồng đối ngoại vẫn phải đủ chặng trước khi
      publish". Ghi rõ lý do đổi. *(SRS §10.1 — kèm lý do: ràng buộc cũ loại bỏ hẳn
      Kamelet/Pipe vốn về cấu trúc không thể có bốn chặng đó.)*
- [x] **T-2.** SRS PH-04/D — thêm FR cho: đa route (`FR-D-005…008`), Kamelet/Pipe/Test
      (`FR-D-060…064`), catalog (`FR-D-070…073`), bean/metadata **và DataMapper**
      (`FR-D-080…085`). *(Dự kiến ban đầu tách DataMapper thành `FR-D-09x` riêng; khi viết
      SRS thì gộp vào dải `FR-D-08x` cùng Bean/Metadata vì cả ba đều thuộc màn **D-08**.
      **Không có `FR-D-09x`** — sửa lại ở đây cho khớp SRS thay vì để tài liệu lệch nhau.)*
- [x] **T-3.** SRS PH-04/D — thêm màn **D-07 Catalog** và **D-08 DataMapper** vào mục 2 và
      ma trận mục 11. *(Cả bảng §2 lẫn ma trận §11 đều có: `D-07 | FR-D-070…073`,
      `D-08 | FR-D-080…085`.)*
- [x] **T-4.** **ADR mới** cho Q2 (bỏ bộ YAML tự viết, dùng thư viện + mô hình cây) và Q4
      (DataMapper tách UI/engine). Hai quyết định này đủ sức nặng kiến trúc để cần ADR.
      *(→ [ADR-021](../05-adr/README.md#adr-021) và [ADR-022](../05-adr/README.md#adr-022).
      ADR-022 ghi rõ **bản thi công lệch khỏi Q4**: sinh JQ chứ không nhúng `atlasmap-runtime`,
      bốn căn cứ ở §8.0. ADR-021 ghi rõ **`emit.ts` chưa gỡ** và vì sao đường lùi đó còn cần.)*
- [x] **T-5.** Cập nhật `docs/08-implementation/04-ke-hoach-phat-trien.md` chèn IP-07.
      *(Nối ở WP-24 + bảng liên kết §16 + lịch sử §17. Nhân tiện ghi rõ **`testRun` của WP-25
      đang mô phỏng** — DoD ở đó đánh `[x]` mà không nói bộ chạy không nạp Camel.)*

---

## 10. Nghiệm thu — kết quả 2026-08-07

| Cổng | Kiểm | Kết quả |
|---|---|---|
| **N-1** | `npm test` | ✅ **302 ca xanh** (122 trước IP-07 → 302), gồm 4 ca chặn lỗi cũ của IP-06 |
| **N-2** | Camel thật nạp YAML designer sinh | ✅ **Route** — `doTry`+`doCatch`+`doFinally`, `choice` nhiều nhánh, `multicast` lồng, nhiều route/tệp, `routeConfiguration`, `beans` cấp tệp, và **cấu trúc y hệt luồng thật `route-mse6qrrt`** đều `Started`.<br>⛔ **Kamelet/Pipe/Test** — xem N-2b |
| **N-2b** | Kamelet · Pipe · Test trên Camel | ⛔ **Chặn bởi môi trường**: `camel-quarkus-kamelet` không có trong kho Maven offline, không có mạng để tải. Thay bằng đối chiếu cấu trúc với **243 lược đồ nhà sản xuất** |
| **N-3** | Round-trip giữ comment | ✅ Dòng xuất xứ `# routeCode=… version=…` còn nguyên trên cả 5 tệp `routes/` **và** luồng thật từ CSDL |
| **N-3b** | Round-trip giữ biểu thức (lỗi #5) | ✅ 26 ngôn ngữ trong `schemas/language/` không mất giá trị; nghiệm thu trên Camel: `ping lgsp-camel-dancu:ok` |
| **N-4** | Round-trip cấu trúc phức | ✅ `doTry` ba khe, `loadBalance`, `multicast`, `split`, nhiều route/tệp — và **quay vòng hai lần cho kết quả y hệt** |
| **N-5** | NFR-D-01…08 | ✅ Bundle 570,11 → **629,90 KB gz** (+59,8 cho 6 gói, ~5 KB/gói). Không ngưỡng cũ nào tụt |
| **N-6** | e2e đa loại | ⚠ **Một phần**: tạo được cả 4 loại qua API thật với `resourceKind` đúng; chuỗi "Kamelet → dùng trong Pipe → chạy thử → publish" chưa chạy trọn vì thiếu N-2b |
| **N-7** | DataMapper | ✅ **Mạnh hơn kỳ vọng**: JQ sinh ra chạy bằng `jq` CLI cho kết quả **giống hệt** `contracts/cdm/mappers/legacy-citizen-to-person.jq` thật trên đúng bản tin mẫu của `CdmMapperTest` |
| **N-8** | Tiếp cận | ✅ Ba màu mới đều **đo tương phản** trước khi dùng: huy hiệu "tự viết" `#1d4ed8` 6,09:1 · dấu ✓ ánh xạ `#15803d` 5,02:1 · cả hai vượt ngưỡng AA 4,5:1 cho chữ nhỏ |
| **N-9** | **Tương thích ngược** | ✅ **Cổng chặn — đạt.** Xuất **toàn bộ 4 định nghĩa** từ CSDL đang chạy: mở được · quay vòng không mất URI/comment/cấu trúc · quay vòng hai lần ổn định · chiếu xuống sơ đồ rồi dựng ngược không lệch. Gồm luồng **60 dòng do chính designer sinh** |

### 10.1. Ba việc còn treo — cùng một nguyên nhân

Kho Maven offline thiếu gói, không có mạng để tải. **Cả ba đã có đường đi rõ, không còn
ẩn số kỹ thuật** — làm được trong một đợt có mạng:

| Việc | Gói cần | Sau khi có mạng |
|---|---|---|
| **K6-1** engine mapping | `camel-quarkus-jq` | Thêm vào `camel/dancu/pom.xml`, nối JQ sinh ra vào bước `transform` |
| **K3-6 / N-2b** nghiệm thu Kamelet/Pipe | `camel-quarkus-kamelet` | Nạp Kamelet/Pipe designer sinh vào Camel thật |
| **K3-4** bộ chạy Test | `jbang` | Thay `testRun` mô phỏng bằng chạy thật |

> ⚠ **`testRun` hiện đang mô phỏng.** Nó dựng waterfall chín chặng **cố định**, thời lượng
> suy từ `stage.hashCode()`, **không nạp Camel và không đọc định nghĩa luồng**. "Chạy thử
> PASSED" hiện chưa chứng minh gì về luồng — `runnerStatus()` nói rõ điều này cho người dùng.

### 10.2. Một việc chờ quyết định, không phải kỹ thuật

**K1-7c** — cơ chế chặn khung chuẩn lúc publish đã xong và chạy đúng, nhưng cờ
`lgsp.routes.strict-standard-stages` **mặc định tắt**. Bốn luồng hiện có đều là luồng thử
(`source_system` không khớp hồ sơ kết nạp nào) nên bật cũng không chặn thêm gì. Khi có luồng
đối ngoại thật thì chủ dự án quyết thời điểm bật.

---

## 11. Rủi ro

| Rủi ro | Mức | Xử lý |
|---|---|---|
| Viết lại lõi làm hỏng luồng đang chạy | **Cao** | N-9 chặn; giữ `parse.ts` cũ làm bộ đọc dự phòng tới khi N-9 đạt |
| `atlasmap-runtime` xung đột phụ thuộc với Spring Boot 4 | **Cao** | Kiểm ở K6-1 **trước** khi làm UI; nếu vỡ thì lùi về XSLT thuần |
| Khối lượng K6 vượt dự kiến | Trung bình | K6-4/5 làm được từng phần; ánh xạ 1–1 đã dùng được rồi |
| Bundle phình sau khi thêm `yaml` | Thấp | **Đã đo: 570,11 → 603,29 KB gz (+33 KB)** cho *cả* thư viện `yaml` lẫn toàn bộ lõi cây mới — thấp hơn ước tính 40 KB. `yaml` không có phụ thuộc con và `vite` đã kéo sẵn nên dedupe |
| Sửa BR-D-01 bị hiểu là nới lỏng kiểm soát | Trung bình | T-1 ghi rõ: cảnh báo lúc thiết kế, **vẫn chặn lúc publish** với luồng đối ngoại |

---

## 12. Lịch sử

| Ngày | Thay đổi |
|---|---|
| 2026-08-17 | **Đóng §9 — năm mục thay đổi tài liệu.** T-1/T-2/T-3 thực ra **đã xong từ 2026-08-06** trong SRS PH-04/D, chỉ chưa tick; rà lại từng mục trên SRS thật rồi mới đánh dấu. Sửa một chỗ tài liệu lệch nhau: T-2 hẹn `FR-D-09x` cho DataMapper nhưng SRS gộp vào `FR-D-080…085` — **không có `FR-D-09x`**. T-4 viết mới [ADR-021](../05-adr/README.md#adr-021) (mô hình cây + thư viện `yaml`; ghi rõ `emit.ts` **chưa gỡ** và vì sao đường lùi còn cần) và [ADR-022](../05-adr/README.md#adr-022) (DataMapper sinh JQ — **ghi thẳng là lệch khỏi Q4** chủ dự án đã duyệt). Bằng chứng của ADR-022 **kiểm chứng lại độc lập**, không chép số: chạy `toJq` rồi đưa qua `jq` CLI, kết quả trùng khít mapper contract. T-5 nối IP-06/IP-07 vào IP-04 và **ghi rõ `testRun` của WP-25 đang mô phỏng** |
| 2026-08-07 | **K6 xong và chạy nghiệm thu trọn bộ.** K6 sinh **JQ** thay vì nhúng AtlasMap — lệch khỏi Q4, lý do và ba căn cứ đo được ghi ở §8.0. Nghiệm thu K6 mạnh hơn kỳ vọng: JQ sinh ra chạy bằng `jq` CLI cho kết quả **giống hệt** mapper thật của repo. **N-9 (cổng chặn) đạt** trên toàn bộ 4 định nghĩa trong CSDL, gồm luồng 60 dòng do chính designer sinh; chép vào `__fixtures__/db__*` để giữ được bộ dữ liệu này. Thêm nhãn loại tài nguyên trên danh sách (K3-5). Ghi rõ ba việc còn treo vì thiếu gói offline và một việc chờ quyết định (§10.1, §10.2) |
| 2026-08-07 | **K4 xong — màn danh mục `/components` (D-07, FR-D-070…073).** Duyệt đủ 751 nút / bảy loại có số đếm, tìm kiếm xếp hạng + ảo hóa, trang chi tiết (bảng tham số theo nhóm gốc, cú pháp URI, phụ thuộc Maven), thêm thẳng vào luồng đang mở hai chiều, giấy phép Apache-2.0 ở chân màn. 24 ca test mới (274 tổng). **Lỗi im lặng bắt được khi dựng màn — K4-0:** `build-catalog.mjs` đọc siêu dữ liệu theo *tên loại* trong khi bản gốc gói dưới khóa `model`, làm **95/751 nút** (48 dataformat + 26 language + 21 entity) mất sạch tiêu đề/mô tả/nhãn; mọi kiểm đếm vẫn xanh vì số nút không đổi — đúng dạng BR-D-04b, và cũng chính là thứ khiến nhận định "dữ liệu đã có đủ" ở dòng 2026-08-05 chỉ đúng một nửa. Kèm 3 component nhãn lặp `"cloud,cloud"` làm chip đếm 94 / lọc ra 91, và `OUT_ROOT` trỏ thư mục chết. Thay ngưỡng `< 400 nút` (không bắt nổi lỗi này) bằng kiểm chất lượng theo từng loại. Thêm `nativeSupported` vào chỉ mục: **65/323 component chưa chạy được ở ảnh native** trong khi ADR-002/020 chốt Camel Quarkus native — phải biết lúc tra cứu, không phải lúc build hỏng |
| 2026-08-05 | Khởi tạo IP-07 sau khi chốt Q1–Q5. Phân tích hiện trạng: catalog **đã có đủ 742 lược đồ** (thiếu màn duyệt, không thiếu dữ liệu); nút thắt thật là mô hình phẳng `StageNode[]`/`SeqEdge[]` ở `core/model.ts` và bộ YAML tự viết chỉ đọc được tập con nó sinh ra; `route_type` hiện mang nghĩa vận chuyển (`SYNC`) nên Kamelet/Pipe/Test cần cột `resource_kind` riêng |
| 2026-08-06 | **K1-1…K1-6 xong.** `tree.ts` + `deserialize.ts` + `serialize.ts` + `flatten.ts`, 22 ca test mới (148 tổng). Nghiệm thu trên **Camel 4.18.2 thật**: `k1-nested` (doTry+doCatch+doFinally+choice 2 nhánh+multicast) và `k1-multi-a`/`k1-multi-b` (nhiều route một tệp — thứ lõi cũ **không mở nổi**) đều `Started`. Hai lỗi của chính bộ sinh mới bị test/Camel bắt kịp thời: (1) `otherwise` ghi thành **danh sách trần** → Camel từ chối `Unsupported type: SEQUENCE`; lược đồ vendor **không** phát hiện được vì thuộc tính `steps` của `otherwise` khai là null — phải ghi dạng đối tượng bọc `steps`; (2) `constant` ghi **hai lần** vì khóa ngôn ngữ dạng chuỗi rơi vào `props` còn dạng đầy đủ rơi vào `rest`, dọn thiếu một bên. Thêm `K1ChoiceOrderTest` chứng minh thứ tự khóa `otherwise` trước `when` **không** đổi ngữ nghĩa định tuyến (a=1→nhanh-mot, a=2→nhanh-hai, a=99→nhanh-khac) — "route khởi động được" không đủ, đúng bài học lỗi #5 |
| 2026-08-05 | **Chạy round-trip thật trên tệp trong `routes/` khi khảo sát — lộ hai lỗi mất dữ liệu đang tồn tại.** (1) Comment xuất xứ do `GitOpsPublisher` ghi (`# routeCode=at-5812634 version=1`) bị **thay bằng banner mặc định**, không phải xóa lộ liễu — mất dấu vết kiểm toán mà nhìn tệp không nhận ra (BR-D-06). (2) `setBody: {constant: "…"}` round-trip thành `expression: {}` — **nội dung bản tin biến mất im lặng**, mà route vẫn nạp được bằng Camel nên BR-D-04 không bắt được. Lỗi (2) ghi thành **lỗi #5** + gói **K0** để sửa ngay, không đợi hết đợt |
