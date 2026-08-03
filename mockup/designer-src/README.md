# Trình thiết kế luồng (UI-04-07…09)

Mockup React của màn thiết kế kéo thả, chạy thử và duyệt trong console PH-04.

## Công nghệ

| Thành phần | Lựa chọn | ADR |
|---|---|---|
| Động cơ sơ đồ | [`@xyflow/react`](https://reactflow.dev/) (XYFlow / React Flow) | [ADR-017](../../docs/05-adr/README.md#adr-017) |
| Catalog / YAML DSL | Mẫu Kaoto · Camel YAML DSL | [ADR-015](../../docs/05-adr/README.md#adr-015) |
| UI xung quanh | Ant Design v6 + token shadcn | [ADR-016](../../docs/05-adr/README.md#adr-016) |
| Layout tự động | dagre | — |

## Năng lực

- Kéo thành phần từ palette → thả lên canvas; chèn giữa cạnh bằng nút ＋
- Nhánh `choice`, thuộc tính theo JSON Schema catalog
- **DataMapper** — ánh xạ trường nguồn→đích trên chặng `transform`
- **Hoàn tác / làm lại** (⌘Z · ⇧⌘Z hoặc Ctrl+Z · Ctrl+Y)
- Tab **Chạy thử** (UI-04-08) và **Duyệt** (UI-04-09) trong cùng app (`#test`, `#review`)
- YAML Camel sống theo sơ đồ

## Lệnh

```bash
cd mockup/designer-src
npm install
npm run dev      # http://127.0.0.1:5173
npm run build    # ghi ra mockup/pages/designer/index.html (một tệp)
```

`mockup/pages/designer.html` chỉ còn chuyển hướng sang bản React (giữ đường dẫn cũ).
