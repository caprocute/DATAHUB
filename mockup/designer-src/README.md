# Trình thiết kế luồng (UI-04-07)

Mockup React của màn thiết kế kéo thả trong console PH-04.

## Công nghệ

| Thành phần | Lựa chọn | ADR |
|---|---|---|
| Động cơ sơ đồ | [`@xyflow/react`](https://reactflow.dev/) (XYFlow / React Flow) | [ADR-017](../../docs/05-adr/README.md#adr-017) |
| Catalog / YAML DSL | Mẫu Kaoto · Camel YAML DSL | [ADR-015](../../docs/05-adr/README.md#adr-015) |
| UI xung quanh | Ant Design v6 + token shadcn | [ADR-016](../../docs/05-adr/README.md#adr-016) |
| Layout tự động | dagre | — |

## Lệnh

```bash
cd mockup/designer-src
npm install
npm run dev      # http://127.0.0.1:5173
npm run build    # ghi ra mockup/pages/designer/index.html (một tệp)
```

## Thao tác trên sơ đồ

- Kéo thành phần từ cột trái thả lên canvas
- Bấm ＋ trên cạnh để chèn chặng vào giữa
- Kéo điểm nối để nối / đổi đường; EIP định tuyến (`choice`, …) được nhiều nhánh
- Chọn nút để sửa thuộc tính; YAML bên dưới cập nhật theo sơ đồ

Bản tĩnh đã build mở được từ mockup: [`../pages/designer/index.html`](../pages/designer/index.html). Tab Chạy thử / Duyệt vẫn ở [`../pages/designer.html`](../pages/designer.html).
