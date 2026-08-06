import { describe, expect, it } from 'vitest'
import { deserialize } from './deserialize'
import { serialize } from './serialize'
import { flatten } from './flatten'
import { applyGraphToTree, unmappedNodes } from './unflatten'

/**
 * Luồng thật lấy từ CSDL đang chạy, chép vào `__fixtures__` để test không phụ thuộc
 * `/tmp` hay máy cụ thể. Gồm cả luồng **60 dòng do chính trình thiết kế sinh** —
 * ca N-9 giá trị nhất vì nó có `rest` kèm tham số, `choice`, `transform`, `enrich`.
 *
 * `npm run fixtures` đối chiếu bản sao `routes/` với bản gốc; tệp `db__*` là ảnh chụp
 * CSDL nên không nằm trong phạm vi đối chiếu đó.
 */
const FILES = import.meta.glob('./__fixtures__/*.camel.yaml', {
  query: '?raw',
  import: 'default',
  eager: true,
}) as Record<string, string>

describe('N-9 — tương thích ngược trên TOÀN BỘ luồng thật trong CSDL', () => {
  it('có dữ liệu thật để kiểm', () => {
    expect(Object.keys(FILES).length).toBeGreaterThan(0)
  })

  for (const [path, src] of Object.entries(FILES)) {
    const f = path.split('/').pop()!

    it(`mở được: ${f}`, () => {
      expect(() => deserialize(src)).not.toThrow()
    })

    it(`quay vòng không mất dữ liệu: ${f}`, () => {
      const res = deserialize(src)
      const out = serialize(res, src)

      // Mọi URI phải còn nguyên.
      for (const m of src.match(/uri:\s*'?([^'\n]+)'?/g) ?? []) {
        const v = m.replace(/uri:\s*'?/, '').replace(/'$/, '').trim()
        if (v) expect(out, `mất uri "${v}"`).toContain(v)
      }
      // Comment xuất xứ (BR-D-06).
      for (const c of src.match(/^\s*#.*/gm) ?? []) {
        expect(out, `mất comment`).toContain(c.trim())
      }
      // Không sinh khối rỗng — dấu hiệu mất cấu trúc (lỗi #6).
      for (const eip of ['doTry', 'doCatch', 'choice', 'multicast', 'loadBalance', 'split']) {
        expect(out, `${eip} thành khối rỗng`).not.toMatch(new RegExp(`${eip}:\\s*\\{\\}`))
      }
      expect(out, 'biểu thức rỗng').not.toMatch(/expression:\s*\{\}/)
    })

    it(`quay vòng hai lần ổn định: ${f}`, () => {
      const once = serialize(deserialize(src), src)
      expect(serialize(deserialize(once), once)).toBe(once)
    })

    it(`chiếu xuống sơ đồ rồi dựng ngược không lệch: ${f}`, () => {
      const base = deserialize(src)
      const g = flatten(base)
      // Mọi node phải có chỗ trong cây — lệch thì designer phải lùi về bộ sinh cũ.
      expect(unmappedNodes(base, g.nodes), 'có node lạc khỏi cây').toHaveLength(0)
      // Không sửa gì thì YAML phải y hệt.
      expect(serialize(applyGraphToTree(base, g.nodes, g.edges), src)).toBe(serialize(base, src))
    })
  }
})
