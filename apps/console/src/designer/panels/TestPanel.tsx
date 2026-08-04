import { App as AntApp, Button, Select } from 'antd';
import { useState } from 'react';

const SAMPLE_JSON = `{
  "soThuTu": "AB-2026-014735",
  "chuSoHuu": {
    "hoTen": "N.V.A",
    "soDinhDanh": "0011****1234"
  },
  "viTri": {
    "maTinh": "01",
    "maDonViHanhChinh": "00091"
  },
  "dienTich": 128.5
}`;

const SAMPLE_XML = `<ThuaDatRequest xmlns="http://datdai.gov.vn/v3">
  <SoThuTu>AB-2026-014735</SoThuTu>
  <MaDonViHanhChinh>00091</MaDonViHanhChinh>
  <DienTich>128.5</DienTich>
</ThuaDatRequest>`;

const WF = [
  { name: 'Tiếp nhận', left: 0, width: 2, ms: 4 },
  { name: 'Kiểm tra lược đồ', left: 2, width: 4, ms: 8 },
  { name: 'Ủy quyền', left: 6, width: 11, ms: 21 },
  { name: 'Chuẩn hóa CDM', left: 17, width: 6, ms: 12 },
  { name: 'Làm giàu', left: 23, width: 24, ms: 45, warn: true },
  { name: 'Định tuyến', left: 47, width: 2, ms: 3 },
  { name: 'Chuyển đổi', left: 49, width: 17, ms: 31 },
  { name: 'Gửi tới đích', left: 66, width: 33, ms: 62 },
  { name: 'Ghi vết', left: 99, width: 1, ms: 5 },
];

const HISTORY = [
  {
    at: '03/8 15:02:41',
    who: 'Nguyễn Văn Quản',
    mode: 'MOCK',
    src: 'Từ traceId · đã giả danh hóa',
    ms: '187ms',
    result: 'ok' as const,
  },
  {
    at: '03/8 14:47:12',
    who: 'Nguyễn Văn Quản',
    mode: 'MOCK',
    src: 'Nhập tay',
    ms: '204ms',
    result: 'err' as const,
  },
  {
    at: '03/8 14:31:55',
    who: 'Nguyễn Văn Quản',
    mode: 'TEST_SYSTEM',
    src: 'Bộ mẫu · thua-dat-co-ban',
    ms: '—',
    result: 'warn' as const,
  },
];

/** UI-04-08 — Chạy thử luồng (minh họa dữ liệu mẫu). */
export function TestPanel() {
  const { message } = AntApp.useApp();
  const [source, setSource] = useState<'tay' | 'mau' | 'trace'>('trace');
  const [dest, setDest] = useState('mock');

  return (
    <>
      <div className="grid grid--2 mb-5">
        <div className="panel">
          <div className="panel__head">Bản tin thử</div>
          <div className="panel__body">
            <div className="field">
              <label className="field__label">Nguồn bản tin</label>
              <div className="btn-group">
                {(
                  [
                    ['tay', 'Nhập tay'],
                    ['mau', 'Bộ mẫu'],
                    ['trace', 'Từ traceId'],
                  ] as const
                ).map(([id, label]) => (
                  <button
                    key={id}
                    type="button"
                    className={source === id ? 'btn btn--sm is-active' : 'btn btn--sm'}
                    onClick={() => setSource(id)}
                  >
                    {label}
                  </button>
                ))}
              </div>
            </div>

            {source === 'trace' && (
              <div className="field">
                <label className="field__label">Mã truy vết</label>
                <div className="input-group">
                  <input className="input input--mono" defaultValue="4bf92f3577b34da6a3ce929d0e0e4736" />
                  <button type="button" className="btn" onClick={() => message.success('Đã nạp bản tin từ traceId')}>
                    Nạp
                  </button>
                </div>
              </div>
            )}

            <div className="alert alert--warn mb-4">
              <span className="alert__icon">⊘</span>
              <div>
                <div className="alert__title">Giả danh hóa bắt buộc</div>
                Bản tin lấy từ dữ liệu thật luôn đi qua PH-09 trước khi dùng làm dữ liệu thử. Tùy chọn này không tắt
                được (BR-04-019).
              </div>
            </div>

            <div className="field">
              <label className="field__label">Nội dung bản tin</label>
              <pre className="code" style={{ maxHeight: 180 }}>
                {SAMPLE_JSON}
              </pre>
            </div>

            <div className="field">
              <label className="field__label">Chế độ đích</label>
              <Select
                style={{ width: '100%' }}
                value={dest}
                onChange={setDest}
                options={[
                  { value: 'mock', label: 'Giả lập — thay mọi lời gọi ra ngoài bằng phản hồi mẫu' },
                  { value: 'real', label: 'Hệ thống thử nghiệm thật' },
                ]}
              />
            </div>

            <div className="field">
              <label className="field__label">Phản hồi giả lập</label>
              <div className="table-wrap">
                <table className="table">
                  <thead>
                    <tr>
                      <th>Đích</th>
                      <th>Mã</th>
                      <th>Thân phản hồi</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr>
                      <td className="t-mono">rdm://don-vi-hanh-chinh</td>
                      <td>200</td>
                      <td className="t-mono t-small">{`{"tenDayDu":"P. Cửa Nam, Q. Hoàn Kiếm, TP Hà Nội"}`}</td>
                    </tr>
                    <tr>
                      <td className="t-mono">adapter://CSDL-DATDAI</td>
                      <td>200</td>
                      <td className="t-mono t-small">{`{"ketQua":"OK","maHoSo":"HS-99120"}`}</td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>

            <Button
              type="primary"
              block
              onClick={() => message.success('Đã chạy thử — PASSED · 187ms (minh họa)')}
            >
              ▷ Chạy thử
            </Button>
          </div>
        </div>

        <div className="panel">
          <div className="panel__head">
            Kết quả lần chạy
            <span className="badge badge--ok" style={{ marginLeft: 'var(--sp-2)' }}>
              PASSED
            </span>
            <span className="t-small t-muted" style={{ fontWeight: 400, marginLeft: 'auto' }}>
              187ms · 15:02:41
            </span>
          </div>
          <div className="panel__body">
            <div className="wf mb-5">
              {WF.map((s) => (
                <div key={s.name} style={{ display: 'contents' }}>
                  <div className="wf__name">{s.name}</div>
                  <div className="wf__track">
                    <div
                      className={s.warn ? 'wf__bar wf__bar--warn' : 'wf__bar'}
                      style={{ left: `${s.left}%`, width: `${s.width}%` }}
                    />
                  </div>
                  <div className="wf__ms">{s.ms}ms</div>
                </div>
              ))}
            </div>

            <div className="alert alert--warn mb-4">
              <span className="alert__icon">⚠</span>
              <div>
                <div className="alert__title">Chặng Làm giàu trả cảnh báo</div>
                Danh mục trả kết quả sau 45ms nhưng không khớp mã <span className="t-mono">00091</span>; bản tin đi tiếp
                với <span className="t-mono">enriched=false</span> đúng như cấu hình.
              </div>
            </div>

            <div className="field">
              <label className="field__label">Bản tin đầu ra</label>
              <pre className="code" style={{ maxHeight: 150 }}>
                {SAMPLE_XML}
              </pre>
            </div>

            <button type="button" className="btn btn--sm" onClick={() => message.info('So sánh với lần chạy trước')}>
              So sánh với lần chạy trước
            </button>
          </div>
        </div>
      </div>

      <div className="card">
        <div className="card__head">
          <div>
            <div className="card__title">Lịch sử chạy thử — phiên bản 4</div>
            <div className="card__sub">Giữ 30 ngày; bản ghi được một lần duyệt tham chiếu thì chỉ giữ phần tóm tắt</div>
          </div>
        </div>
        <div className="table-wrap">
          <table className="table">
            <thead>
              <tr>
                <th>Thời điểm</th>
                <th>Người chạy</th>
                <th>Chế độ đích</th>
                <th>Nguồn bản tin</th>
                <th className="table__num">Thời gian</th>
                <th>Kết quả</th>
                <th className="table__actions">Thao tác</th>
              </tr>
            </thead>
            <tbody>
              {HISTORY.map((r) => (
                <tr key={r.at}>
                  <td className="t-mono t-small">{r.at}</td>
                  <td>{r.who}</td>
                  <td>
                    <span className={`badge badge--${r.mode === 'TEST_SYSTEM' ? 'info' : 'muted'} badge--plain`}>
                      {r.mode}
                    </span>
                  </td>
                  <td className="t-small t-muted">{r.src}</td>
                  <td className="table__num">{r.ms}</td>
                  <td>
                    <span
                      className={`badge badge--${r.result === 'ok' ? 'ok' : r.result === 'err' ? 'err' : 'warn'}`}
                    >
                      {r.result === 'ok' ? 'PASSED' : r.result === 'err' ? 'FAILED' : 'TIMEOUT'}
                    </span>
                  </td>
                  <td className="table__actions">
                    <button type="button" className="btn btn--sm" onClick={() => message.info(`Xem lần chạy ${r.at}`)}>
                      Xem
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </>
  );
}
