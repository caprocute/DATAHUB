import { describe, expect, it } from 'vitest'
import { NODE_H as MODEL_H, NODE_W as MODEL_W, makeStage } from '../core/model'
import { NODE_H as LAYOUT_H, NODE_W as LAYOUT_W, autoLayout } from './layout'
import type { CatalogNode } from '../core/catalog'

/**
 * Kích thước thẻ chặng phải **thống nhất một nguồn** (lỗi đường nối lệch cổng).
 *
 * React Flow neo cổng vào/ra theo kích thước đã đo của nút, còn dagre đặt nút theo kích
 * thước ta khai với nó. Trước đây `design/layout.ts` khai riêng 220×68 trong khi
 * `core/model.ts` khai 240×72 — mọi cạnh vẽ lệch 10px ngang, 2px dọc so với cổng thật.
 *
 * Bài kiểm này khóa lại bất biến đó: ai tách hai hằng số ra lần nữa sẽ đỏ ở đây thay vì
 * để người dùng phát hiện bằng mắt trên sơ đồ.
 */
describe('kích thước thẻ chặng — một nguồn sự thật', () => {
  it('layout và model dùng chung đúng một giá trị', () => {
    expect(LAYOUT_W).toBe(MODEL_W)
    expect(LAYOUT_H).toBe(MODEL_H)
  })

  it('chặng dựng mới khai `measured` khớp hằng số', () => {
    const cat: CatalogNode = {
      name: 'log',
      kind: 'component',
      title: 'Log Data',
      description: 'ghi nhật ký',
      labels: [],
    }
    const node = makeStage(cat, { position: { x: 0, y: 0 } })
    // Thiếu `measured` thì React Flow giữ nút ẩn; sai `measured` thì cổng lệch.
    expect(node.measured).toEqual({ width: MODEL_W, height: MODEL_H })
    expect(node.width).toBe(MODEL_W)
    expect(node.height).toBe(MODEL_H)
  })

  it('autoLayout đặt nút theo đúng bề rộng đã khai, không chồng lấn', () => {
    const cat: CatalogNode = {
      name: 'log',
      kind: 'component',
      title: 'Log',
      description: '',
      labels: [],
    }
    const a = { ...makeStage(cat, { position: { x: 0, y: 0 } }), id: 'a' }
    const b = { ...makeStage(cat, { position: { x: 0, y: 0 } }), id: 'b' }
    const laid = autoLayout(
      [a, b],
      [{ id: 'e1', source: 'a', target: 'b', type: 'seq' }],
    )
    const [pa, pb] = [laid.find((n) => n.id === 'a')!, laid.find((n) => n.id === 'b')!]

    // Nút sau phải nằm hẳn bên phải nút trước: khoảng cách ngang ít nhất bằng bề rộng
    // thẻ. Nếu layout dùng bề rộng nhỏ hơn thực tế, hai thẻ sẽ đè lên nhau.
    expect(pb.position.x - pa.position.x).toBeGreaterThanOrEqual(MODEL_W)
    // Cùng một hàng nên tâm dọc phải trùng — cổng trái/phải mới thẳng nhau.
    expect(pa.position.y).toBeCloseTo(pb.position.y, 5)
  })
})
