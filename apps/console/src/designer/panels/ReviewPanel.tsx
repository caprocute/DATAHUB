import { App as AntApp, Button } from 'antd';
import { useMemo, useState } from 'react';

const QUEUE = [
  {
    id: 'tra-cuu-thua-dat',
    ver: 'v4',
    who: 'Nguyễn Văn Quản',
    sent: '03/8 15:10',
    wait: '12 phút',
    tag: 'info' as const,
    tagLabel: 'đang xem',
    highlight: true,
  },
  {
    id: 'dong-bo-ho-so-tthc',
    ver: 'v9',
    who: 'Lê Minh Đức',
    sent: '03/8 09:22',
    wait: '6 giờ',
    tag: 'err' as const,
    tagLabel: 'KHẨN CẤP',
    highlight: false,
  },
  {
    id: 'lien-thong-van-ban',
    ver: 'v3',
    who: 'Phạm Thu Hà',
    sent: '31/7 16:40',
    wait: '3 ngày',
    waitUrgent: true,
    tag: 'warn' as const,
    tagLabel: 'quá hạn',
    highlight: false,
  },
  {
    id: 'tra-cuu-bhxh',
    ver: 'v2',
    who: 'Lê Minh Đức',
    sent: '02/8 11:05',
    wait: '1 ngày',
    tag: null,
    tagLabel: '',
    highlight: false,
  },
];

const HISTORY = [
  {
    id: 'tra-cuu-cong-dan',
    ver: 'v7',
    sender: 'Phạm Thu Hà',
    reviewer: 'Trần Thị Hoa',
    decision: 'ok' as const,
    commit: '9d4c7a1',
    at: '02/8 10:14',
  },
  {
    id: 'tra-cuu-thua-dat',
    ver: 'v3',
    sender: 'Nguyễn Văn Quản',
    reviewer: 'Trần Thị Hoa',
    decision: 'err' as const,
    commit: '—',
    at: '01/8 16:32',
  },
  {
    id: 'dong-bo-ho-so-tthc',
    ver: 'v8',
    sender: 'Lê Minh Đức',
    reviewer: 'Nguyễn Văn Quản',
    decision: 'ok' as const,
    urgent: true,
    commit: '3f81b02',
    at: '31/7 22:07',
  },
];

/** UI-04-09 — Hàng đợi duyệt (minh họa). */
export function ReviewPanel() {
  const { message } = AntApp.useApp();
  const [q, setQ] = useState('');
  const [note, setNote] = useState('');

  const rows = useMemo(() => {
    const needle = q.trim().toLowerCase();
    if (!needle) return QUEUE;
    return QUEUE.filter(
      (r) => r.id.includes(needle) || r.who.toLowerCase().includes(needle) || r.ver.includes(needle),
    );
  }, [q]);

  return (
    <>
      <div className="alert alert--info mb-5">
        <span className="alert__icon">ℹ</span>
        <div>
          <div className="alert__title">Nguyên tắc bốn mắt</div>
          Luồng do chính bạn gửi lên không hiển thị trong hàng đợi này. Người duyệt phải khác người tạo phiên bản
          (BR-04-016).
        </div>
      </div>

      <div className="card mb-5">
        <div className="card__head">
          <div>
            <div className="card__title">Chờ duyệt</div>
            <div className="card__sub">4 luồng — 1 quá hạn 3 ngày làm việc</div>
          </div>
          <div className="card__actions">
            <div className="search">
              <span className="search__icon">⌕</span>
              <input
                className="input"
                type="text"
                placeholder="Tìm luồng…"
                value={q}
                onChange={(e) => setQ(e.target.value)}
              />
            </div>
          </div>
        </div>
        <div className="table-wrap">
          <table className="table">
            <thead>
              <tr>
                <th>Mã luồng</th>
                <th>Phiên bản</th>
                <th>Người gửi</th>
                <th>Thời điểm gửi</th>
                <th>Thời gian chờ</th>
                <th>Nhãn</th>
                <th className="table__actions">Thao tác</th>
              </tr>
            </thead>
            <tbody>
              {rows.map((r) => (
                <tr key={`${r.id}-${r.ver}`} style={r.highlight ? { background: 'var(--c-brand-50)' } : undefined}>
                  <td className="t-mono">{r.id}</td>
                  <td className="t-mono">{r.ver}</td>
                  <td>{r.who}</td>
                  <td className="t-small t-muted">{r.sent}</td>
                  <td
                    className="t-small"
                    style={r.waitUrgent ? { color: 'var(--c-err-700)', fontWeight: 600 } : undefined}
                  >
                    {r.wait}
                  </td>
                  <td>{r.tag && <span className={`badge badge--${r.tag}`}>{r.tagLabel}</span>}</td>
                  <td className="table__actions">
                    <button
                      type="button"
                      className="btn btn--sm"
                      onClick={() => message.info(`Mở ${r.id} ${r.ver}`)}
                    >
                      Xem
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      <div className="card mb-5">
        <div className="card__head">
          <div>
            <div className="card__title">
              <span className="t-mono">tra-cuu-thua-dat</span> — phiên bản 4
            </div>
            <div className="card__sub">Gửi bởi Nguyễn Văn Quản lúc 03/8 15:10</div>
          </div>
          <div className="card__actions">
            <span className="badge badge--muted">PENDING_REVIEW</span>
          </div>
        </div>
        <div className="card__body">
          <div className="field">
            <label className="field__label">Thuyết minh thay đổi</label>
            <p className="t-muted">
              Bổ sung chặng làm giàu tên đơn vị hành chính đầy đủ để hệ thống đất đai không phải tự tra cứu. Nâng bộ
              chuyển đổi lên v3 theo lược đồ mới bên CSDL-DATDAI công bố ngày 28/7.
            </p>
          </div>

          <div className="divider" />

          <div className="field">
            <label className="field__label">So sánh với phiên bản đang chạy (v3)</label>
            <div className="diff">
              <div>
                <div className="diff__col-label">v3 — đang chạy</div>
                <pre className="code" style={{ maxHeight: 230 }}>
                  {`- to: "direct:normalize"
- to: "xslt:cdm-to-datdai-v2.xsl"
- to: "adapter://CSDL-DATDAI"
- wireTap:
    uri: "kafka:audit-log-topic"`}
                </pre>
              </div>
              <div>
                <div className="diff__col-label">v4 — chờ duyệt</div>
                <pre className="code" style={{ maxHeight: 230 }}>
                  {`- to: "direct:normalize"
- enrich:
    expression:
      simple: "rdm://don-vi-hanh-chinh/..."
    timeout: 200
- to: "xslt:cdm-to-datdai-v3.xsl"
- to: "adapter://CSDL-DATDAI"
- wireTap:
    uri: "kafka:audit-log-topic"`}
                </pre>
              </div>
            </div>
            <div className="field__hint">
              Xem song song cả sơ đồ và DSL —{' '}
              <a
                href="#design"
                onClick={(e) => {
                  e.preventDefault();
                  message.info('So sánh dạng sơ đồ — minh họa');
                }}
              >
                chuyển sang dạng sơ đồ
              </a>
            </div>
          </div>

          <div className="divider" />

          <div className="grid grid--2">
            <div>
              <div className="field__label mb-2">Cảnh báo còn tồn tại</div>
              <div className="alert alert--warn" style={{ marginBottom: 'var(--sp-2)' }}>
                <span className="alert__icon">⚠</span>
                <div>
                  Luật định tuyến không vét cạn — bản tin của tỉnh ngoài <span className="t-mono">01</span>,{' '}
                  <span className="t-mono">79</span> sẽ rơi vào nhánh lỗi.
                </div>
              </div>
              <div className="alert alert--warn" style={{ margin: 0 }}>
                <span className="alert__icon">⚠</span>
                <div>Hạn chờ làm giàu 200ms sát P99 thực tế 180ms của PH-07.</div>
              </div>
            </div>
            <div>
              <div className="field__label mb-2">Bằng chứng chạy thử</div>
              <dl className="dl">
                <dt>Kết quả</dt>
                <dd>
                  <span className="badge badge--ok">PASSED</span>
                </dd>
                <dt>Thời điểm</dt>
                <dd className="t-mono t-small">03/8 15:02:41</dd>
                <dt>Chế độ đích</dt>
                <dd>Giả lập</dd>
                <dt>Dữ liệu thử</dt>
                <dd className="t-small">Từ traceId, đã giả danh hóa</dd>
                <dt>Tổng thời gian</dt>
                <dd className="t-mono">187ms</dd>
              </dl>
              <button
                type="button"
                className="btn btn--sm mt-3"
                onClick={() => message.info('Mở chi tiết lần chạy thử')}
              >
                Xem chi tiết lần chạy
              </button>
            </div>
          </div>

          <div className="divider" />

          <div className="field">
            <label className="field__label">Nhận xét</label>
            <textarea
              className="textarea"
              placeholder="Bắt buộc nhập lý do khi trả lại luồng…"
              value={note}
              onChange={(e) => setNote(e.target.value)}
            />
          </div>

          <div className="row row--between">
            <div className="t-small t-muted">
              Sau khi phê duyệt: sinh commit vào kho Git, Argo CD đồng bộ ở chu kỳ kế tiếp.
            </div>
            <div className="row">
              <Button
                danger
                onClick={() => {
                  if (!note.trim()) {
                    message.warning('Nhập lý do trước khi trả lại');
                    return;
                  }
                  message.success('Đã trả lại luồng (minh họa)');
                }}
              >
                Trả lại
              </Button>
              <Button type="primary" onClick={() => message.success('Đã phê duyệt — sẽ sinh commit Git (minh họa)')}>
                Phê duyệt
              </Button>
            </div>
          </div>
        </div>
      </div>

      <div className="card">
        <div className="card__head">
          <div>
            <div className="card__title">Lịch sử duyệt gần đây</div>
            <div className="card__sub">Bản ghi duyệt được giữ vĩnh viễn phục vụ kiểm định</div>
          </div>
        </div>
        <div className="table-wrap">
          <table className="table">
            <thead>
              <tr>
                <th>Luồng</th>
                <th>Phiên bản</th>
                <th>Người gửi</th>
                <th>Người duyệt</th>
                <th>Quyết định</th>
                <th>Commit</th>
                <th>Thời điểm</th>
              </tr>
            </thead>
            <tbody>
              {HISTORY.map((r) => (
                <tr key={`${r.id}-${r.ver}-${r.at}`}>
                  <td className="t-mono">{r.id}</td>
                  <td className="t-mono">{r.ver}</td>
                  <td>{r.sender}</td>
                  <td>{r.reviewer}</td>
                  <td>
                    <span className={`badge badge--${r.decision === 'ok' ? 'ok' : 'err'}`}>
                      {r.decision === 'ok' ? 'Phê duyệt' : 'Trả lại'}
                    </span>
                    {r.urgent && (
                      <span className="badge badge--err" style={{ marginLeft: 4 }}>
                        KHẨN CẤP
                      </span>
                    )}
                  </td>
                  <td className={r.commit === '—' ? 't-small t-muted' : 't-mono t-small'}>{r.commit}</td>
                  <td className="t-small t-muted">{r.at}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </>
  );
}
