import { describe, expect, it } from 'vitest'
import { deserialize } from './deserialize'
import { serialize } from './serialize'
import {
  acceptsBean,
  beanRef,
  readBeans,
  readMetadata,
  refToBeanName,
  validateBeans,
  validateMetadata,
  writeBeans,
  writeMetadata,
} from './beans'

const WITH_BEANS = `- beans:
    - name: boChuyenDoi
      type: vn.lgsp.ChuyenDoiCdm
      properties:
        muiGio: Asia/Ho_Chi_Minh
    - name: khoBiMat
      type: vn.lgsp.KhoBiMat
      initMethod: khoiTao
      properties:
        password: '{{vault:lgsp/db#password}}'
- route:
    id: r
    from:
      uri: direct:a
      steps:
        - log:
            message: xin chao
`

describe('K5-1 — bean registry cấp tệp', () => {
  it('đọc đúng bean, giữ khóa ngoài lược đồ ta quản', () => {
    const beans = readBeans(deserialize(WITH_BEANS))
    expect(beans).toHaveLength(2)
    expect(beans[0].name).toBe('boChuyenDoi')
    expect(beans[0].type).toBe('vn.lgsp.ChuyenDoiCdm')
    expect(beans[0].properties.muiGio).toBe('Asia/Ho_Chi_Minh')
    // `initMethod` không thuộc bộ khóa ta quản nhưng **không được vứt**.
    expect(beans[1].rest.initMethod).toBe('khoiTao')
  })

  it('quay vòng không mất bean và không mất khóa lạ', () => {
    const res = deserialize(WITH_BEANS)
    const out = serialize(writeBeans(res, readBeans(res)), WITH_BEANS)
    expect(out).toContain('boChuyenDoi')
    expect(out).toContain('vn.lgsp.ChuyenDoiCdm')
    expect(out).toContain('initMethod: khoiTao')
    expect(out).toContain('Asia/Ho_Chi_Minh')
    // Route trong cùng tệp phải nguyên vẹn.
    expect(out).toContain('direct:a')
  })

  it('bean không thuộc tính nào thì không ghi `properties: {}`', () => {
    const res = deserialize(WITH_BEANS)
    const beans = readBeans(res).map((b) => ({ ...b, properties: {} }))
    expect(serialize(writeBeans(res, beans), WITH_BEANS)).not.toMatch(/properties:\s*\{\}/)
  })

  /** Camel giữ bean sau đè bean trước — cấu hình bean đầu biến mất lặng lẽ. */
  it('bắt được bean trùng tên', () => {
    const errs = validateBeans([
      { name: 'a', type: 'X', properties: {}, rest: {} },
      { name: 'a', type: 'Y', properties: {}, rest: {} },
    ])
    expect(errs.map((e) => e.message)).toContainEqual(expect.stringContaining('khai hai lần'))
  })

  it('bắt được thiếu tên hoặc thiếu lớp — hai trường lược đồ bắt buộc', () => {
    expect(validateBeans([{ name: '', type: 'X', properties: {}, rest: {} }])).toHaveLength(1)
    expect(validateBeans([{ name: 'a', type: '', properties: {}, rest: {} }])).toHaveLength(1)
  })
})

describe('K5-4 — BR-D-02: bean không chứa bí mật', () => {
  it('chặn bí mật đặt thẳng vào thuộc tính bean', () => {
    const errs = validateBeans([
      { name: 'a', type: 'X', properties: { password: 'matkhau-that' }, rest: {} },
    ])
    expect(errs[0].level).toBe('error')
    expect(errs[0].message).toContain('BR-D-02')
  })

  it('tham chiếu Vault / placeholder thì cho qua', () => {
    for (const v of ['{{vault:lgsp/db#password}}', '#khoBiMat', 'vault:x', '']) {
      expect(
        validateBeans([{ name: 'a', type: 'X', properties: { password: v }, rest: {} }]),
        `“${v}” lẽ ra phải cho qua`,
      ).toHaveLength(0)
    }
  })

  it('bắt cả `apiKey`, `token`, `privateKey` chứ không riêng `password`', () => {
    for (const k of ['apiKey', 'api_key', 'token', 'privateKey', 'clientSecret']) {
      expect(
        validateBeans([{ name: 'a', type: 'X', properties: { [k]: 'lo-that' }, rest: {} }]),
        `khóa “${k}” lẽ ra phải bị chặn`,
      ).toHaveLength(1)
    }
  })

  it('bộ mẫu trong repo không có bean nào lộ bí mật', () => {
    expect(validateBeans(readBeans(deserialize(WITH_BEANS)))).toHaveLength(0)
  })
})

describe('K5-2 — trường nhận bean', () => {
  it('nhận diện trường kiểu object và trường có tên gợi ý', () => {
    expect(acceptsBean('bat-ky', 'object')).toBe(true)
    expect(acceptsBean('aggregationStrategy')).toBe(true)
    expect(acceptsBean('myProcessor')).toBe(true)
    expect(acceptsBean('message')).toBe(false)
    expect(acceptsBean('uri')).toBe(false)
  })

  it('đổi qua lại giữa tên bean và tham chiếu `#ten`', () => {
    expect(beanRef('boChuyenDoi')).toBe('#boChuyenDoi')
    expect(refToBeanName('#boChuyenDoi')).toBe('boChuyenDoi')
    expect(refToBeanName('khong-phai-ref')).toBeUndefined()
    expect(refToBeanName(123)).toBeUndefined()
  })
})

describe('K5-3 — metadata cho Kamelet/Pipe', () => {
  const KAMELET_META = `apiVersion: camel.apache.org/v1
kind: Kamelet
metadata:
  name: nguon-mau
  labels:
    camel.apache.org/kamelet.type: source
  annotations:
    camel.apache.org/provider: LGSP
  uid: 123-abc
spec:
  template:
    from:
      uri: timer:tick
      steps: []
`

  it('đọc tên, nhãn và chú thích', () => {
    const m = readMetadata(deserialize(KAMELET_META))
    expect(m.name).toBe('nguon-mau')
    expect(m.labels['camel.apache.org/kamelet.type']).toBe('source')
    expect(m.annotations['camel.apache.org/provider']).toBe('LGSP')
  })

  /** `uid` là trường Kubernetes tự quản — sửa được là mời gọi lỗi khó lần. */
  it('giữ nguyên trường do Kubernetes quản, không cho người dùng đụng', () => {
    const res = deserialize(KAMELET_META)
    const out = serialize(writeMetadata(res, readMetadata(res)), KAMELET_META)
    expect(out).toContain('uid: 123-abc')
  })

  it('bắt được tên không hợp lệ theo RFC 1123', () => {
    expect(validateMetadata({ name: 'Ten Hoa', labels: {}, annotations: {} })).toHaveLength(1)
    expect(validateMetadata({ name: '', labels: {}, annotations: {} })).toHaveLength(1)
    expect(validateMetadata({ name: 'ten-hop-le', labels: {}, annotations: {} })).toHaveLength(0)
  })

  it('BR-D-02 áp cả cho nhãn và chú thích', () => {
    expect(
      validateMetadata({ name: 'a', labels: { token: 'lo-that' }, annotations: {} }),
    ).toHaveLength(1)
  })
})
