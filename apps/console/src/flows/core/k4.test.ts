/**
 * K4 — danh mục thành phần (D-07, FR-D-070…073).
 *
 * Trọng tâm là **chất lượng dữ liệu chỉ mục**, không phải giao diện: màn D-07 chỉ vẽ lại
 * thứ `catalog-index.json` mang sẵn, nên một lỗi sinh chỉ mục là lỗi của cả màn. Lỗi đã
 * bắt được ở đợt này thuộc đúng dạng đó và **im lặng** (BR-D-04b): `build-catalog.mjs` đọc
 * nhầm khóa siêu dữ liệu của `dataformat`/`language`/`entity` (khóa đúng là `model`) nên
 * 95/751 nút mất sạch tiêu đề, mô tả và nhãn — mà mọi kiểm đếm vẫn xanh vì số nút không đổi.
 */

import { describe, expect, it } from 'vitest';
import {
  ALL_KINDS,
  CATALOG_COUNTS,
  CATALOG_LICENSE,
  CATALOG_NODES,
  CATALOG_RUNTIME,
  CATALOG_SOURCE,
  CATALOG_TOTAL,
  groupProps,
  labelsOfKind,
  loadSchema,
  lookupNode,
  searchNodes,
  type NodeKind,
} from './catalog';

describe('K4-1 — duyệt toàn bộ danh mục', () => {
  it('có đủ 751 nút chia theo bảy loại', () => {
    expect(CATALOG_TOTAL).toBe(751);
    expect(CATALOG_COUNTS).toEqual({
      component: 323,
      kamelet: 252,
      pattern: 74,
      dataformat: 48,
      language: 26,
      entity: 21,
      loadbalancer: 7,
    });
  });

  it('tab của màn danh mục phủ hết mọi loại có trong dữ liệu', () => {
    // Bảng thành phần chỉ hiện 5 loại thả được vào sơ đồ; màn D-07 phải đủ cả bảy,
    // nếu không `entity`/`loadbalancer` không có đường nào tra cứu tới.
    const kinds = new Set(CATALOG_NODES.map((n) => n.kind));
    for (const k of kinds) expect(ALL_KINDS).toContain(k);
    expect(ALL_KINDS).toHaveLength(kinds.size);
  });

  it('số đếm của tab khớp số mục lọc ra được', () => {
    for (const kind of ALL_KINDS) {
      expect(searchNodes('', { kind })).toHaveLength(CATALOG_COUNTS[kind]);
    }
  });
});

describe('K4-1 — siêu dữ liệu không được rỗng (lỗi im lặng đã bắt)', () => {
  it('mọi nút đều có tiêu đề và mô tả thật', () => {
    const noTitle = CATALOG_NODES.filter((n) => !n.title);
    const noDesc = CATALOG_NODES.filter((n) => !n.description);
    expect(noTitle).toEqual([]);
    // Từng có đúng 95 nút rỗng mô tả: 48 dataformat + 26 language + 21 entity.
    expect(noDesc).toEqual([]);
  });

  it('ba loại từng đọc nhầm khóa nay có tiêu đề khác tên trần', () => {
    // Lối hỏng cũ để lại `title === name` (vì `m.title ?? name` rơi về nhánh sau).
    // Kiểm theo tỷ lệ chứ không tuyệt đối: vài nút gốc vốn có tiêu đề trùng tên.
    for (const kind of ['dataformat', 'language', 'entity'] as NodeKind[]) {
      const list = searchNodes('', { kind });
      const titled = list.filter((n) => n.title !== n.name);
      expect(titled.length).toBeGreaterThan(list.length / 2);
    }
  });

  it('ba loại đó có nhãn để lọc được', () => {
    for (const kind of ['dataformat', 'language', 'entity'] as NodeKind[]) {
      expect(labelsOfKind(kind).length).toBeGreaterThan(0);
    }
  });

  it('bốn lược đồ CRD trần vẫn có tiêu đề lấy từ chính lược đồ', () => {
    // `ObjectMeta`, `Pipe*`, `KameletConfiguration` không có khối `model` nào cả.
    for (const name of ['PipeErrorHandler', 'PipeConfiguration', 'KameletConfiguration']) {
      const n = lookupNode(`entity/${name}`);
      expect(n?.title).toBeTruthy();
      expect(n?.title).not.toBe(name);
    }
    expect(lookupNode('entity/ObjectMeta')?.description).toBeTruthy();
  });
});

describe('K4-2 — tìm kiếm có xếp hạng', () => {
  it('khớp tên chính xác đứng đầu', () => {
    expect(searchNodes('timer', { kind: 'component' })[0]?.name).toBe('timer');
    expect(searchNodes('kafka', { kind: 'component' })[0]?.name).toBe('kafka');
  });

  it('tìm được cả theo mô tả và nhãn, không chỉ theo tên', () => {
    // `sql-stored` không có chữ "procedure" trong tên — chỉ mô tả mới có. Tìm ra được
    // nghĩa là chuỗi tìm kiếm đã gộp cả mô tả, không chỉ so tên.
    expect(searchNodes('stored procedure', { kind: 'component' }).map((n) => n.name)).toContain(
      'sql-stored',
    );
    // Nhãn cũng phải vào chuỗi tìm: `cloud` là nhãn, không nằm trong tên nút nào.
    const byLabel = searchNodes('cloud', { kind: 'component' });
    expect(byLabel.some((n) => !n.name.includes('cloud') && n.labels.includes('cloud'))).toBe(true);
  });

  it('mọi từ khóa phải cùng khớp', () => {
    for (const n of searchNodes('aws s3', { kind: 'kamelet' })) {
      const hay = `${n.name} ${n.title} ${n.description} ${n.labels.join(' ')}`.toLowerCase();
      expect(hay).toContain('aws');
      expect(hay).toContain('s3');
    }
  });

  it('lọc theo nhãn thu hẹp đúng tập kết quả', () => {
    const all = searchNodes('', { kind: 'component' });
    const [top] = labelsOfKind('component');
    const filtered = searchNodes('', { kind: 'component', label: top.label });
    expect(filtered).toHaveLength(top.count);
    expect(filtered.length).toBeLessThan(all.length);
    for (const n of filtered) expect(n.labels).toContain(top.label);
  });

  it('số trên chip nhãn khớp số mục lọc ra được, mọi nhãn mọi loại', () => {
    // Bản gốc có 3 component khai `"cloud,cloud"`. Không khử trùng thì chip hiện 94
    // trong khi bấm vào chỉ ra 91 dòng — người dùng đếm được sự chênh lệch đó.
    for (const kind of ALL_KINDS) {
      for (const { label, count } of labelsOfKind(kind)) {
        expect(searchNodes('', { kind, label })).toHaveLength(count);
      }
    }
  });

  it('không nút nào còn nhãn lặp', () => {
    const dup = CATALOG_NODES.filter((n) => new Set(n.labels).size !== n.labels.length);
    expect(dup).toEqual([]);
  });

  it('không truyền `role` thì hiện cả nút chỉ đứng đầu luồng', () => {
    // Màn tra cứu khác bảng thành phần: không được giấu mục nào.
    expect(searchNodes('', { kind: 'component' }).some((n) => n.consumerOnly)).toBe(true);
  });
});

describe('K4-3 — dữ liệu cho trang chi tiết', () => {
  it('component mang đủ tọa độ Maven để dán vào pom.xml', () => {
    const timer = lookupNode('component/timer');
    expect(timer?.groupId).toBe('org.apache.camel.quarkus');
    expect(timer?.artifactId).toBe('camel-quarkus-timer');
    expect(timer?.version).toBeTruthy();
    expect(timer?.camelArtifact).toBe('org.apache.camel:camel-timer');

    const missing = searchNodes('', { kind: 'component' }).filter((n) => !n.artifactId);
    expect(missing).toEqual([]);
  });

  it('`nativeSupported` chỉ đặt cho component, và phân biệt được với "không áp dụng"', () => {
    // `undefined` = không có extension riêng; `false` = có nhưng native chưa chạy được.
    // Gộp hai thứ này lại sẽ cảnh báo nhầm cho toàn bộ pattern/dataformat/language.
    for (const n of searchNodes('', { kind: 'component' })) {
      expect(typeof n.nativeSupported).toBe('boolean');
    }
    for (const kind of ['pattern', 'language', 'dataformat'] as NodeKind[]) {
      for (const n of searchNodes('', { kind })) expect(n.nativeSupported).toBeUndefined();
    }
  });

  it('kamelet khai phụ thuộc logic thay cho tọa độ Maven', () => {
    const s3 = lookupNode('kamelet/aws-s3-source');
    expect(s3?.artifactId).toBeUndefined();
    expect(s3?.dependencies).toContain('camel:aws2-s3');
  });

  it('cú pháp URI có ở mọi component', () => {
    expect(lookupNode('component/timer')?.syntax).toBe('timer:timerName');
    expect(searchNodes('', { kind: 'component' }).filter((n) => !n.syntax)).toEqual([]);
  });

  it('giữ được cảnh báo deprecated của bản gốc', () => {
    expect(CATALOG_NODES.filter((n) => n.deprecated).length).toBeGreaterThan(0);
  });

  it('chia nhóm thuộc tính theo nhóm gốc, bắt buộc lên đầu', () => {
    const groups = groupProps({
      required: ['b'],
      properties: {
        a: { type: 'string', $comment: 'group:common' },
        b: { type: 'string', $comment: 'group:common' },
        z: { type: 'string', $comment: 'group:producer (advanced)' },
      },
    });
    expect(groups.map((g) => g.group)).toEqual(['common', 'advanced']);
    expect(groups[0].props.map((p) => p.name)).toEqual(['b', 'a']);
    expect(groups[0].props[0].required).toBe(true);
    // Trường đánh `(advanced)` gom hết vào nhóm nâng cao dù nhóm gốc là gì.
    expect(groups[1].props.map((p) => p.name)).toEqual(['z']);
  });

  it('nạp được lược đồ thật và chia nhóm ra tab dùng được', async () => {
    const timer = lookupNode('component/timer')!;
    const schema = await loadSchema(timer);
    expect(Object.keys(schema.properties ?? {}).length).toBeGreaterThan(0);
    expect(groupProps(schema).length).toBeGreaterThan(0);
  });

  it('kamelet không có lược đồ trả về rỗng, không ném lỗi', async () => {
    // Chỉ mục có 751 nút nhưng trên đĩa chỉ 742 tệp lược đồ: 9 kamelet không có tham số
    // cấu hình nên nhà sản xuất không phát hành lược đồ. Chúng vẫn là mục hợp lệ — màn
    // chi tiết phải hiện "không có tham số" thay vì báo lỗi tải, và muốn vậy `loadSchema`
    // phải im lặng trả rỗng thay vì ném (IP-07 §6).
    const schema = await loadSchema({
      name: 'khong-ton-tai-tren-dia',
      kind: 'kamelet',
      title: 't',
      description: '',
      labels: [],
    });
    expect(schema).toEqual({});
  });

  it('mọi nút trong chỉ mục đều nạp được lược đồ mà không ném', async () => {
    // Quét cả 751 nút: đây là đường mà màn chi tiết đi với *bất kỳ* mục nào người dùng
    // bấm vào. Một nút làm `loadSchema` ném là một màn trắng.
    const empty: string[] = [];
    for (const n of CATALOG_NODES) {
      const s = await loadSchema(n);
      if (Object.keys(s.properties ?? {}).length === 0) empty.push(`${n.kind}/${n.name}`);
    }
    // Đúng 9 kamelet thiếu lược đồ như tài liệu ghi — con số này mà đổi là dữ liệu vendor
    // đã đổi, phải xem lại chứ không sửa test cho xanh.
    expect(empty.filter((r) => r.startsWith('kamelet/'))).toHaveLength(9);
  });
});

describe('K4-5 — nguồn và giấy phép (nghĩa vụ tuân thủ)', () => {
  it('khai đúng nguồn, giấy phép và nhánh runtime', () => {
    expect(CATALOG_LICENSE).toBe('Apache-2.0');
    expect(CATALOG_SOURCE).toContain('@kaoto/camel-catalog');
    // Bảng tham số chỉ đúng với đúng phiên bản runtime này — khớp ADR-002/020.
    expect(CATALOG_RUNTIME).toBe('camel-quarkus 3.35.0');
  });
});
