import { describe, expect, it } from 'vitest';
import { deserialize } from './deserialize';
import { serialize } from './serialize';
import {
  KAMELET_PROP_TYPES,
  readProps,
  writeProps,
  readMeta,
  writeMeta,
  validateProps,
} from './kamelet';
import { readLinks, updateLink, setLinkKamelet, allowedInPipe, validatePipe } from './pipe';

const KAMELET = `apiVersion: camel.apache.org/v1
kind: Kamelet
metadata:
  name: nguon-mau
spec:
  definition:
    title: Nguon mau
    description: Sinh ban tin theo chu ky
    required:
      - message
    properties:
      period:
        title: Period
        description: Khoang cach giua hai ban tin
        type: integer
        default: 1000
      message:
        title: Message
        description: Noi dung ban tin
        type: string
        example: xin chao
  template:
    from:
      uri: timer:tick
      steps:
        - to:
            uri: kamelet:sink
`;

const PIPE = `apiVersion: camel.apache.org/v1
kind: Pipe
metadata:
  name: ong-mau
spec:
  source:
    ref:
      kind: Kamelet
      apiVersion: camel.apache.org/v1
      name: timer-source
    properties:
      message: xin chao
  sink:
    ref:
      kind: Kamelet
      apiVersion: camel.apache.org/v1
      name: log-sink
`;

describe('K3-1 — tham số Kamelet', () => {
  it('đọc đúng dạng JSON Schema gốc mà 243 kamelet vendor dùng', () => {
    const props = readProps(deserialize(KAMELET));
    expect(props.map((p) => p.name)).toEqual(['period', 'message']);
    const period = props.find((p) => p.name === 'period')!;
    expect(period.type).toBe('integer');
    expect(period.default).toBe(1000);
    expect(period.required).toBe(false);
    const message = props.find((p) => p.name === 'message')!;
    expect(message.required).toBe(true);
    expect(message.example).toBe('xin chao');
  });

  it('ghi lại giữ nguyên tiêu đề và mô tả của chính kamelet', () => {
    const res = deserialize(KAMELET);
    const next = writeProps(res, readProps(res));
    const meta = readMeta(next);
    expect(meta.title).toBe('Nguon mau');
    expect(meta.description).toBe('Sinh ban tin theo chu ky');
  });

  it('quay vòng tham số không mất dữ liệu', () => {
    const res = deserialize(KAMELET);
    const out = serialize(writeProps(res, readProps(res)), KAMELET);
    expect(out).toContain('period');
    expect(out).toContain('message');
    expect(out).toContain('default: 1000');
    expect(out).toMatch(/required:\s*\n\s*- message/);
    expect(out).toContain('timer:tick');
  });

  it('thêm tham số mới rồi đọc lại thấy đủ', () => {
    const res = deserialize(KAMELET);
    const props = readProps(res);
    props.push({ name: 'soLan', type: 'integer', required: true, title: 'So lan' });
    const next = writeProps(res, props);
    expect(readProps(next).map((p) => p.name)).toContain('soLan');
    expect(readProps(next).find((p) => p.name === 'soLan')!.required).toBe(true);
  });

  it('`required` rỗng thì bỏ hẳn khóa, không ghi mảng rỗng', () => {
    const res = deserialize(KAMELET);
    const props = readProps(res).map((p) => ({ ...p, required: false }));
    expect(serialize(writeProps(res, props), KAMELET)).not.toMatch(/required:\s*\[\]/);
  });

  /** Trùng tên là lỗi nặng nhất: map `properties` chỉ giữ một, tham số kia biến mất lặng lẽ. */
  it('bắt được tham số trùng tên và tên không hợp lệ', () => {
    expect(validateProps([
      { name: 'a', type: 'string', required: false },
      { name: 'a', type: 'string', required: false },
    ])).toContainEqual(expect.stringContaining('khai hai lần'));
    expect(validateProps([{ name: '1sai', type: 'string', required: false }])).toHaveLength(1);
    expect(validateProps([{ name: '', type: 'string', required: false }])).toHaveLength(1);
  });

  it('sửa tiêu đề kamelet không đụng tham số', () => {
    const res = writeMeta(deserialize(KAMELET), { title: 'Ten moi' });
    expect(readMeta(res).title).toBe('Ten moi');
    expect(readProps(res)).toHaveLength(2);
  });
});

describe('K3-3 — Pipe', () => {
  it('đọc đủ mắt theo đúng thứ tự chạy', () => {
    const links = readLinks(deserialize(PIPE));
    expect(links.map((l) => l.role)).toEqual(['source', 'sink']);
    expect(links[0].kameletName).toBe('timer-source');
    expect(links[0].properties.message).toBe('xin chao');
    expect(links[1].kameletName).toBe('log-sink');
  });

  it('đổi tham số giữ nguyên tham chiếu Kamelet', () => {
    const res = deserialize(PIPE);
    const src = readLinks(res)[0];
    const next = updateLink(res, src.path, { message: 'da doi' });
    const out = serialize(next, PIPE);
    expect(out).toContain('da doi');
    // `apiVersion`/`kind` của ref phải còn — Camel cần để tra đúng Kamelet.
    expect(out).toContain('apiVersion: camel.apache.org/v1');
    expect(out).toContain('name: timer-source');
  });

  it('đổi Kamelet của một mắt giữ nguyên apiVersion/kind', () => {
    const res = deserialize(PIPE);
    const sink = readLinks(res).find((l) => l.role === 'sink')!;
    const out = serialize(setLinkKamelet(res, sink.path, 'kafka-sink'), PIPE);
    expect(out).toContain('kafka-sink');
    expect(out).not.toContain('log-sink');
    expect(out).toMatch(/kind: Kamelet/);
  });

  /** Pipe không rẽ nhánh — thả `choice` vào là dựng ra thứ Camel không nạp được. */
  it('khóa mọi thao tác rẽ nhánh trên Pipe', () => {
    for (const eip of ['choice', 'doTry', 'multicast', 'loadBalance', 'split']) {
      expect(allowedInPipe(eip), `${eip} lẽ ra phải bị khóa`).toBe(false);
    }
    for (const ok of ['to', 'log', 'setBody', 'setHeader']) {
      expect(allowedInPipe(ok), `${ok} lẽ ra phải cho phép`).toBe(true);
    }
  });

  it('thiếu nguồn hoặc đích thì báo lỗi', () => {
    expect(validatePipe(deserialize(PIPE))).toHaveLength(0);
    const thieuSink = `apiVersion: camel.apache.org/v1
kind: Pipe
metadata:
  name: thieu
spec:
  source:
    ref:
      kind: Kamelet
      name: timer-source
`;
    expect(validatePipe(deserialize(thieuSink))).toContainEqual(
      expect.stringContaining('phải có đích'),
    );
  });
});

describe('K3-6 — cấu trúc khớp kamelet gốc của nhà sản xuất', () => {
  /**
   * `camel/dancu` **không có** `camel-quarkus-kamelet` và kho Maven offline cũng không có
   * gói đó, nên không nạp Kamelet/Pipe bằng Camel thật ở môi trường này được.
   *
   * Thay vào đó đối chiếu với **243 lược đồ kamelet đã vendor** — chính dữ liệu nhà sản
   * xuất phát hành. Kamelet do trình thiết kế sinh phải có cùng hình dạng `spec.definition`
   * (JSON Schema: `properties` map, `required` mảng, `type` trong tập cho phép) thì mới
   * dùng được ở nơi khác.
   */
  const VENDOR = import.meta.glob('./generated/schemas/kamelet/*.json', {
    import: 'default',
    eager: true,
  }) as Record<string, { properties?: Record<string, { type?: string }>; required?: string[] }>;

  it('có dữ liệu kamelet gốc để đối chiếu', () => {
    expect(Object.keys(VENDOR).length).toBeGreaterThan(200);
  });

  it('kiểu tham số ta sinh nằm trong tập kiểu nhà sản xuất dùng', () => {
    const vendorTypes = new Set<string>();
    for (const schema of Object.values(VENDOR)) {
      for (const p of Object.values(schema.properties ?? {})) {
        if (p?.type) vendorTypes.add(p.type);
      }
    }
    // Mọi kiểu trình soạn cho chọn phải là kiểu nhà sản xuất **thật sự dùng**.
    for (const t of KAMELET_PROP_TYPES) {
      expect(vendorTypes, `kiểu "${t}" không thấy ở kamelet gốc nào`).toContain(t);
    }
  });

  /**
   * Danh sách kiểu là **hợp đồng với dữ liệu vendor**. Enum của `KameletConfiguration`
   * (`string|number|boolean`) sai cả hai đầu: thiếu `integer` — kiểu phổ biến thứ ba, 111
   * lần — và có `number` mà **không kamelet gốc nào dùng**. Đi theo enum ấy thì trình soạn
   * vừa thiếu kiểu người dùng cần vừa chào kiểu lạ.
   */
  it('không chào kiểu nào mà kamelet gốc không dùng', () => {
    const vendorTypes = new Set<string>();
    for (const schema of Object.values(VENDOR)) {
      for (const p of Object.values(schema.properties ?? {})) {
        if (p?.type) vendorTypes.add(p.type);
      }
    }
    expect(vendorTypes.has('number'), 'kamelet gốc không dùng `number`').toBe(false);
    for (const t of KAMELET_PROP_TYPES) expect(vendorTypes).toContain(t);
  });

  it('kiểu `number` lạ được quy về `integer`, không thành chuỗi', () => {
    const la = `apiVersion: camel.apache.org/v1
kind: Kamelet
metadata:
  name: la
spec:
  definition:
    properties:
      soLuong:
        type: number
  template:
    from:
      uri: timer:tick
      steps: []
`;
    expect(readProps(deserialize(la))[0].type).toBe('integer');
  });

  it('kamelet ta sinh có cùng hình dạng với kamelet gốc', () => {
    const res = writeProps(deserialize(KAMELET), readProps(deserialize(KAMELET)));
    const spec = (res.rest as { spec?: { definition?: Record<string, unknown> } }).spec;
    const def = spec?.definition ?? {};
    // Gốc: `properties` là **map**, `required` là **mảng tên** — không phải dạng khác.
    expect(typeof def.properties).toBe('object');
    expect(Array.isArray(def.properties)).toBe(false);
    expect(Array.isArray(def.required)).toBe(true);

    const mau = Object.values(VENDOR).find((v) => v.required?.length && v.properties)!;
    expect(Array.isArray(mau.required)).toBe(true);
    expect(Array.isArray(mau.properties)).toBe(false);
  });
});

describe('K3 — thay đổi chỉ đụng cây vẫn phải ra YAML', () => {
  /**
   * Lỗi thật đã gặp: `useMemo` sinh YAML đọc `treeRef.current` nhưng danh sách phụ thuộc
   * chỉ có `nodes`/`edges`. Sửa tham số Kamelet **không** đụng sơ đồ, nên memo không tính
   * lại và YAML hiện ra vẫn là bản cũ — người dùng tưởng thao tác của mình rơi mất.
   *
   * Test này khóa **bản chất** của lỗi ở tầng lõi: đổi cây thôi phải cho YAML khác.
   */
  it('sửa tham số Kamelet cho ra YAML khác, dù sơ đồ không đổi', () => {
    const res = deserialize(KAMELET)
    const truoc = serialize(res, KAMELET)

    const props = readProps(res)
    props[0] = { ...props[0], description: 'Mo ta hoan toan moi' }
    const sau = serialize(writeProps(res, props), KAMELET)

    expect(sau).not.toBe(truoc)
    expect(sau).toContain('Mo ta hoan toan moi')
    // Và không đụng gì tới phần luồng.
    expect(sau).toContain('timer:tick')
    expect(sau).toContain('kamelet:sink')
  })

  it('sửa tiêu đề Kamelet cũng cho ra YAML khác', () => {
    const res = deserialize(KAMELET)
    expect(serialize(writeMeta(res, { title: 'Ten hoan toan moi' }), KAMELET)).toContain(
      'Ten hoan toan moi',
    )
  })
})
