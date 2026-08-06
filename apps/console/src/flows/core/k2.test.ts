import { describe, expect, it } from 'vitest';
import { deserialize } from './deserialize';
import { serialize } from './serialize';
import { flatten } from './flatten';
import { applyGraphToTree, unmappedNodes } from './unflatten';
import {
  addEntity, duplicateEntity, duplicateStep, insertAfter, insertIntoBranch,
  insertAfterAt, moveStep, newStep, removeEntity, removeStep, renameEntity, updateStepProps,
} from './mutate';

const SRC = `- route:
    id: r
    from:
      uri: direct:a
      steps:
        - log:
            message: mot
        - doTry:
            steps:
              - to:
                  uri: http://x
            doCatch:
              - exception:
                  - java.io.IOException
                steps:
                  - log:
                      message: loi-io
`;

const y = (r: ReturnType<typeof deserialize>) => serialize(r, undefined);

describe('K2 — sửa thẳng trên cây', () => {
  it('bộ mẫu đúng như mong đợi: 2 bước gốc, doTry ở vị trí 1', () => {
    const base = deserialize(SRC);
    expect(base.entities[0].steps.map((s) => s.name)).toEqual(['log', 'doTry']);
  });

  it('chèn bước mới vào cây, không phải lùi về bộ sinh cũ', () => {
    const base = deserialize(SRC);
    const first = base.entities[0].steps[0].path;
    const out = y(insertAfter(base, 0, first, newStep('log', { message: 'moi-them' })));
    expect(out).toContain('moi-them');
    // Cấu trúc lồng vẫn nguyên
    expect(out).toContain('doCatch');
    expect(out).toContain('java.io.IOException');
  });

  it('chèn bước vào trong khe doCatch', () => {
    const base = deserialize(SRC);
    const doTry = base.entities[0].steps[1];
    const doCatch = doTry.branches.find((b) => b.slot === 'doCatch')!;
    const out = y(insertIntoBranch(base, 0, doCatch.path, newStep('log', { message: 'trong-docatch' })));
    expect(out).toMatch(/doCatch:[\s\S]*trong-docatch/);
  });

  it('đường dẫn được tính lại sau khi chèn — không trỏ nhầm chỗ', () => {
    const base = deserialize(SRC);
    const first = base.entities[0].steps[0].path;
    const next = insertAfter(base, 0, first, newStep('log', { message: 'chen-giua' }));
    const paths = next.entities[0].steps.map((s) => s.path);
    expect(new Set(paths).size).toBe(paths.length);
    // Bước thứ hai bây giờ phải là bước vừa chèn
    expect(next.entities[0].steps[1].props.message).toBe('chen-giua');
    // Và doTry đẩy xuống vị trí 2, đường dẫn phải phản ánh đúng
    expect(next.entities[0].steps[2].name).toBe('doTry');
    expect(next.entities[0].steps[2].path).toContain('[2]');
  });

  it('xóa bước lồng chỉ xóa đúng nó', () => {
    const base = deserialize(SRC);
    const doTry = base.entities[0].steps[1];
    const inner = doTry.branches.find((b) => b.slot === 'doCatch')!.steps[0];
    const out = y(removeStep(base, 0, inner.path));
    expect(out).not.toContain('loi-io');
    expect(out).toContain('java.io.IOException');
    expect(out).toContain('doTry');
  });

  it('nhân bản bước giữ nguyên cây con', () => {
    const base = deserialize(SRC);
    const out = y(duplicateStep(base, 0, base.entities[0].steps[1].path));
    expect(out.match(/doTry:/g) ?? []).toHaveLength(2);
    expect(out.match(/java\.io\.IOException/g) ?? []).toHaveLength(2);
  });

  it('nhân bản không sinh anchor/alias YAML (&a1 / *a1)', () => {
    // Sao chép nông làm bản gốc và bản sao dùng chung mảng `exception`, thư viện `yaml`
    // nhận ra và ghi ra anchor. YAML vẫn hợp lệ nhưng tệp đem triển khai thành khó đọc
    // và phụ thuộc nơi tiêu thụ có nở alias hay không.
    const base = deserialize(SRC);
    const out = y(duplicateStep(base, 0, base.entities[0].steps[1].path));
    expect(out).not.toMatch(/&a\d/);
    expect(out).not.toMatch(/\*a\d/);
    expect(out.match(/java\.io\.IOException/g) ?? []).toHaveLength(2);
  });

  it('sửa thuộc tính bước', () => {
    const base = deserialize(SRC);
    const out = y(updateStepProps(base, 0, base.entities[0].steps[0].path, { message: 'da-sua' }));
    expect(out).toContain('da-sua');
    expect(out).not.toContain('mot');
  });

  it('đổi chỗ hai bước', () => {
    const base = deserialize(SRC);
    const next = moveStep(base, 0, base.entities[0].steps[0].path, 1);
    expect(next.entities[0].steps[0].name).toBe('doTry');
    expect(next.entities[0].steps[1].name).toBe('log');
  });
});

describe('K2-1 — nhiều route trong một tệp', () => {
  it('thêm và xóa route', () => {
    const base = deserialize(SRC);
    const added = addEntity(base, 'route-hai');
    expect(added.entities).toHaveLength(2);
    expect(y(added)).toContain('route-hai');
    expect(removeEntity(added, 1).entities).toHaveLength(1);
  });

  it('nhân bản route', () => {
    const base = deserialize(SRC);
    const dup = duplicateEntity(base, 0, 'r-ban-sao');
    expect(dup.entities).toHaveLength(2);
    const out = y(dup);
    expect(out).toContain('r-ban-sao');
    expect(out.match(/doTry:/g) ?? []).toHaveLength(2);
  });
});

describe('K2-4 — đổi tên route cập nhật tham chiếu', () => {
  const MULTI = `- route:
    id: goi-den
    from:
      uri: direct:goi-den
      steps:
        - log:
            message: dich
- route:
    id: nguoi-goi
    from:
      uri: direct:nguoi-goi
      steps:
        - to:
            uri: direct:goi-den`;

  it('đổi tên thì nơi gọi được sửa theo, và báo rõ số tham chiếu', () => {
    const base = deserialize(MULTI);
    const { resource, updatedRefs } = renameEntity(base, 0, 'ten-moi');
    const out = y(resource);
    expect(updatedRefs).toBe(1);
    expect(out).toContain('direct:ten-moi');
    expect(out).not.toContain('direct:goi-den');
  });

  it('route tiếp nhận qua rest/kafka thì không đụng tới uri', () => {
    const src = `- route:
    id: r
    from:
      uri: kafka:chu-de
      steps:
        - log:
            message: a`;
    const { resource, updatedRefs } = renameEntity(deserialize(src), 0, 'ten-khac');
    expect(updatedRefs).toBe(0);
    expect(y(resource)).toContain('kafka:chu-de');
  });
});

describe('K2 — thêm chặng KHÔNG còn ép lùi về bộ sinh cũ', () => {
  /**
   * Đây là hạn chế còn lại của K1: chặng mới chưa có đường dẫn nên `unmappedNodes` phát
   * hiện và cả luồng phải lùi về bộ sinh cũ — tức là mất sạch cấu trúc lồng. Mô phỏng
   * đúng đường đi của `DesignerPage.addStage`.
   */
  it('thêm chặng vào luồng có doTry: cây nhận được, cấu trúc lồng còn nguyên', () => {
    const base = deserialize(SRC);
    const g0 = flatten(base);

    // Đuôi luồng = node không có cạnh đi ra (đúng luật addStage dùng).
    const tail = g0.nodes.filter((n) => !g0.edges.some((e) => e.source === n.id)).pop()!;

    const { resource, path } = insertAfterAt(base, 0, tail.id, newStep('log', { message: 'chang-moi' }));
    expect(path, 'phải trả về đường dẫn thật của bước vừa chèn').toBeTruthy();

    // Sơ đồ mới lấy đường dẫn làm mã node — đúng cách DesignerPage làm.
    const g1 = flatten(resource);
    expect(g1.nodes.some((n) => n.id === path)).toBe(true);

    // Điều kiện then chốt: không còn node nào "lạc" khỏi cây.
    expect(unmappedNodes(resource, g1.nodes)).toHaveLength(0);

    const out = serialize(applyGraphToTree(resource, g1.nodes, g1.edges), undefined);
    expect(out).toContain('chang-moi');
    expect(out).toContain('doCatch');
    expect(out).toContain('java.io.IOException');
    expect(out).not.toContain('choice');
  });

  it('đường dẫn trả về trỏ đúng bước vừa chèn, không nhầm sang bước dịch chỗ', () => {
    const base = deserialize(SRC);
    // Chèn vào **giữa** để mọi bước sau bị đánh số lại — chỗ dễ nhận nhầm nhất.
    const first = base.entities[0].steps[0].path;
    const { resource, path } = insertAfterAt(base, 0, first, newStep('log', { message: 'o-giua' }));
    const found = resource.entities[0].steps.find((s) => s.path === path)!;
    expect(found.props.message).toBe('o-giua');
  });
});

describe('K2 — chặng thả vào canvas không chui nhầm vào nhánh', () => {
  /**
   * Luồng rẽ nhánh có **nhiều đuôi** (mỗi nhánh một đuôi). Lấy bừa một đuôi làm chỗ neo
   * thì chặng người dùng thả sẽ chui vào trong `doCatch` — họ xin một bước nối tiếp
   * route, lại nhận một bước trong nhánh xử lý lỗi. Neo phải ở **cấp gốc**.
   */
  it('luồng có doTry sinh nhiều đuôi, trong đó có đuôi nằm trong doCatch', () => {
    const g = flatten(deserialize(SRC));
    const tails = g.nodes.filter((n) => !g.edges.some((e) => e.source === n.id));
    expect(tails.length).toBeGreaterThan(1);
    expect(tails.some((t) => t.id.includes('doCatch'))).toBe(true);
  });

  it('neo không ở cấp gốc thì chặng mới nối vào cuối route, không vào doCatch', () => {
    const base = deserialize(SRC);
    const g = flatten(base);
    const tails = g.nodes.filter((n) => !g.edges.some((e) => e.source === n.id));
    const nested = tails.find((t) => t.id.includes('doCatch'))!;

    // Đúng luật của `adoptIntoTree`: neo ngoài cấp gốc bị bỏ qua.
    const topLevel = new Set(base.entities[0].steps.map((s) => s.path));
    const anchor = topLevel.has(nested.id) ? nested.id : undefined;
    const { resource, path } = insertAfterAt(base, 0, anchor, newStep('log', { message: 'noi-tiep' }));

    expect(path).not.toContain('doCatch');
    const last = resource.entities[0].steps[resource.entities[0].steps.length - 1];
    expect(last.props.message).toBe('noi-tiep');
  });
});
