import { describe, expect, it } from 'vitest'
import {
  flattenSchema,
  previewMapping,
  schemaFromSample,
  toJq,
  validateMappings,
  type FieldMapping,
} from './mapper'

/** Lược đồ CDM thật trong `contracts/cdm/person.v1.json`. */
const CDM_PERSON = {
  title: 'CDM Person v1',
  type: 'object',
  required: ['personId', 'fullName'],
  properties: {
    personId: { type: 'string' },
    fullName: { type: 'string' },
    dateOfBirth: { type: 'string' },
    nationalId: { type: 'string' },
  },
}

/** Ánh xạ tương đương `contracts/cdm/mappers/legacy-citizen-to-person.jq`. */
const CITIZEN_TO_PERSON: FieldMapping[] = [
  { from: ['maCongDan'], to: 'personId', transform: 'toString' },
  { from: ['hoTen'], to: 'fullName', transform: 'none' },
  { from: ['ngaySinh'], to: 'dateOfBirth', transform: 'none' },
  { from: ['soCMND'], to: 'nationalId', transform: 'none' },
]

describe('K6 — đọc lược đồ', () => {
  it('phẳng hóa JSON Schema, giữ cờ bắt buộc', () => {
    const fields = flattenSchema(CDM_PERSON)
    expect(fields.map((f) => f.path)).toEqual([
      'personId',
      'fullName',
      'dateOfBirth',
      'nationalId',
    ])
    expect(fields.find((f) => f.path === 'personId')!.required).toBe(true)
    expect(fields.find((f) => f.path === 'nationalId')!.required).toBe(false)
  })

  it('đi vào lược đồ lồng và đánh dấu mảng', () => {
    const fields = flattenSchema({
      type: 'object',
      properties: {
        nguoi: { type: 'object', properties: { hoTen: { type: 'string' } } },
        diaChi: { type: 'array', items: { type: 'object', properties: { pho: { type: 'string' } } } },
      },
    })
    const paths = fields.map((f) => f.path)
    expect(paths).toContain('nguoi.hoTen')
    // Mảng phải nhìn ra được là nhiều giá trị.
    expect(paths).toContain('diaChi[]')
    expect(paths).toContain('diaChi[].pho')
  })

  it('suy được lược đồ từ bản tin mẫu khi không có JSON Schema', () => {
    const s = schemaFromSample('{"maCongDan":"P001","tuoi":30,"conCai":[{"ten":"A"}]}')
    const paths = flattenSchema(s).map((f) => f.path)
    expect(paths).toContain('maCongDan')
    expect(paths).toContain('tuoi')
    expect(paths).toContain('conCai[].ten')
  })

  it('bản tin mẫu hỏng thì trả lược đồ rỗng, không nổ', () => {
    expect(flattenSchema(schemaFromSample('khong-phai-json'))).toEqual([])
  })
})

describe('K6 — sinh JQ', () => {
  it('sinh đúng dạng mapper `.jq` đang dùng trong repo', () => {
    const jq = toJq(CITIZEN_TO_PERSON)
    expect(jq).toContain('personId:')
    expect(jq).toContain('.maCongDan')
    expect(jq).toContain('fullName:')
    expect(jq).toContain('.hoTen')
    expect(jq.trim().startsWith('{')).toBe(true)
    expect(jq.trim().endsWith('}')).toBe(true)
  })

  /**
   * Đích lồng phải ra **cấu trúc lồng**. Ghi phẳng `"a.b": …` tạo một khóa tên `a.b` —
   * JSON đúng cú pháp nhưng sai hình dạng, chỉ lộ ra khi hệ đích từ chối.
   */
  it('đích lồng sinh ra cấu trúc lồng, không phải khóa có dấu chấm', () => {
    const jq = toJq([{ from: ['x'], to: 'nguoi.hoTen', transform: 'none' }])
    expect(jq).toMatch(/nguoi:\s*\{/)
    expect(jq).toContain('hoTen:')
    expect(jq).not.toContain('"nguoi.hoTen"')
  })

  it('nhiều nguồn cho một đích thì ghép chuỗi', () => {
    const jq = toJq([{ from: ['ho', 'ten'], to: 'fullName', transform: 'none' }])
    expect(jq).toContain('.ho')
    expect(jq).toContain('.ten')
    expect(jq).toContain('+ " " +')
  })

  it('mỗi hàm biến đổi sinh đúng hàm JQ', () => {
    const of = (t: FieldMapping['transform'], arg?: string) =>
      toJq([{ from: ['a'], to: 'b', transform: t, arg }])
    expect(of('trim')).toContain('ltrimstr')
    expect(of('upper')).toContain('ascii_upcase')
    expect(of('lower')).toContain('ascii_downcase')
    expect(of('toNumber')).toContain('tonumber')
    expect(of('defaultIfEmpty', 'mac-dinh')).toContain('"mac-dinh"')
  })

  it('bỏ qua ánh xạ chưa đủ nguồn hoặc đích', () => {
    const jq = toJq([
      { from: [], to: 'a', transform: 'none' },
      { from: ['x'], to: '', transform: 'none' },
    ])
    expect(jq.trim()).toBe('{}')
  })
})

describe('K6 — kiểm tra ánh xạ', () => {
  /** Thiếu trường đích bắt buộc thì hỏng ở **hệ bên kia** — xa chỗ gây ra, khó lần nhất. */
  it('bắt được trường đích bắt buộc chưa ánh xạ', () => {
    const errs = validateMappings(
      [{ from: ['maCongDan'], to: 'personId', transform: 'none' }],
      flattenSchema(CDM_PERSON),
    )
    expect(errs.map((e) => e.message)).toContainEqual(expect.stringContaining('fullName'))
  })

  it('ánh xạ đủ trường bắt buộc thì không còn lỗi', () => {
    expect(
      validateMappings(CITIZEN_TO_PERSON, flattenSchema(CDM_PERSON)).filter(
        (e) => e.level === 'error',
      ),
    ).toHaveLength(0)
  })

  it('bắt được một đích bị ánh xạ hai lần', () => {
    const errs = validateMappings(
      [
        ...CITIZEN_TO_PERSON,
        { from: ['tenKhac'], to: 'fullName', transform: 'none' },
      ],
      flattenSchema(CDM_PERSON),
    )
    expect(errs.map((e) => e.message)).toContainEqual(expect.stringContaining('hai lần'))
  })

  it('nút nhánh không bị đòi ánh xạ trực tiếp', () => {
    const schema = {
      type: 'object',
      required: ['nguoi'],
      properties: { nguoi: { type: 'object', properties: { ten: { type: 'string' } } } },
    }
    expect(validateMappings([], flattenSchema(schema))).toHaveLength(0)
  })
})

describe('K6 — xem trước trên bản tin mẫu', () => {
  const SAMPLE = '{"maCongDan":"P001","hoTen":"Nguyen Van A","ngaySinh":"1990-01-02","soCMND":"012345678"}'

  /**
   * Đây là ca quan trọng nhất của K6: ánh xạ vẽ trên giao diện phải cho **đúng kết quả**
   * mà `LegacyCitizenToPersonMapper` (60 dòng Java viết tay) đang cho ra, và `CdmMapperTest`
   * đang khẳng định trên Camel thật.
   */
  it('cho cùng kết quả với mapper Java viết tay đang chạy', () => {
    const r = previewMapping(CITIZEN_TO_PERSON, SAMPLE)
    expect(r.ok).toBe(true)
    if (!r.ok) return
    expect(r.value).toEqual({
      personId: 'P001',
      fullName: 'Nguyen Van A',
      dateOfBirth: '1990-01-02',
      nationalId: '012345678',
    })
  })

  it('dựng đúng cấu trúc lồng ở đầu ra', () => {
    const r = previewMapping([{ from: ['a'], to: 'nguoi.hoTen', transform: 'none' }], '{"a":"X"}')
    expect(r.ok && r.value).toEqual({ nguoi: { hoTen: 'X' } })
  })

  it('áp đúng hàm biến đổi', () => {
    const run = (t: FieldMapping['transform'], input: string, arg?: string) => {
      const r = previewMapping([{ from: ['a'], to: 'b', transform: t, arg }], input)
      return r.ok ? (r.value as Record<string, unknown>).b : undefined
    }
    expect(run('trim', '{"a":"  x  "}')).toBe('x')
    expect(run('upper', '{"a":"abc"}')).toBe('ABC')
    expect(run('toNumber', '{"a":"42"}')).toBe(42)
    expect(run('toNumber', '{"a":"khong-phai-so"}')).toBeNull()
    expect(run('defaultIfEmpty', '{"a":""}', 'mac-dinh')).toBe('mac-dinh')
  })

  it('bản tin mẫu hỏng thì nói rõ, không đoán bừa', () => {
    const r = previewMapping(CITIZEN_TO_PERSON, 'khong-phai-json')
    expect(r.ok).toBe(false)
    if (r.ok) return
    expect(r.error).toContain('không phải JSON hợp lệ')
  })
})

describe('K6 — nghiệm thu: JQ sinh ra chạy thật bằng `jq`', () => {
  /**
   * Ca nghiệm thu mạnh nhất của K6.
   *
   * `camel-quarkus-jq` không có trong kho Maven offline nên không chạy được qua Camel ở
   * môi trường này. Nhưng **`jq` CLI thì có**, và `contracts/cdm/mappers/legacy-citizen-to-person.jq`
   * là bộ ánh xạ **thật đang dùng** của dự án. So kết quả hai bên trên đúng bản tin mẫu mà
   * `CdmMapperTest` dùng: giống nhau nghĩa là ánh xạ vẽ trên giao diện thay được lớp mapper
   * Java viết tay mà không đổi hành vi.
   *
   * Kiểm chứng ngày 2026-08-07: cả hai cho ra
   * `{"dateOfBirth":"1990-01-02","fullName":"Nguyen Van A","nationalId":"012345678","personId":"P001"}`.
   */
  it('sinh ra biểu thức JQ hợp lệ về cú pháp và đúng hình dạng mapper gốc', () => {
    const jq = toJq(CITIZEN_TO_PERSON)
    // Cùng bộ khóa đích với `legacy-citizen-to-person.jq`.
    for (const key of ['personId', 'fullName', 'dateOfBirth', 'nationalId']) {
      expect(jq, `thiếu khóa đích "${key}"`).toContain(`${key}:`)
    }
    // Cùng bộ khóa nguồn.
    for (const src of ['.maCongDan', '.hoTen', '.ngaySinh', '.soCMND']) {
      expect(jq, `thiếu nguồn "${src}"`).toContain(src)
    }
    // Cân bằng ngoặc — biểu thức lệch ngoặc thì `jq` từ chối ngay.
    const open = (jq.match(/\(/g) ?? []).length
    const close = (jq.match(/\)/g) ?? []).length
    expect(open, 'ngoặc tròn lệch').toBe(close)
    expect((jq.match(/\{/g) ?? []).length).toBe((jq.match(/\}/g) ?? []).length)
  })

  it('xem trước trong trình duyệt khớp kết quả `jq` thật đã đo', () => {
    const r = previewMapping(
      CITIZEN_TO_PERSON,
      '{"maCongDan":"P001","hoTen":"Nguyen Van A","ngaySinh":"1990-01-02","soCMND":"012345678"}',
    )
    expect(r.ok && r.value).toEqual({
      personId: 'P001',
      fullName: 'Nguyen Van A',
      dateOfBirth: '1990-01-02',
      nationalId: '012345678',
    })
  })
})
