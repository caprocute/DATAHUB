import { ReactFlowProvider } from '@xyflow/react';
import { App as AntApp, Button, ConfigProvider } from 'antd';
import { useCallback, useState } from 'react';
import { Designer } from './Designer';
import { ROUTE_ID } from './flow/model';
import { AppShell } from './shell/AppShell';
import { antdThemeFor } from './theme/tokens';
import { useTheme } from './theme/useTheme';

export function App() {
  const { mode, toggle } = useTheme();
  const [dirty, setDirty] = useState(false);
  const [counts, setCounts] = useState({ errors: 0, warns: 0 });

  const onDirty = useCallback(() => setDirty(true), []);

  return (
    <ConfigProvider theme={antdThemeFor(mode)}>
      <AntApp>
        <AppShell
          activeId="designer"
          title="Thiết kế luồng"
          crumbs={[
            { text: 'Trang chủ', href: 'index.html' },
            { text: 'Luồng tích hợp', href: 'pages/routes.html' },
            { text: 'Thiết kế luồng' },
          ]}
          onToggleTheme={toggle}
        >
          <div className="mock-note">
            <strong>PH-04 — Thiết kế luồng bằng giao diện.</strong> Màn <span className="tag-ph">UI-04-07</span> trình
            thiết kế trực quan, dựng bằng XYFlow (React Flow) theo{' '}
            <a href="../../../docs/05-adr/README.md#adr-017">ADR-017</a>; danh mục thành phần và Camel YAML DSL theo mẫu{' '}
            <a href="https://kaoto.io/">Kaoto</a> (
            <a href="../../../docs/05-adr/README.md#adr-015">ADR-015</a>). Đặc tả tại mục M6 của{' '}
            <a href="../../../docs/07-srs/SRS-PH-04-integration-core.md">SRS PH-04</a>. Định nghĩa YAML sinh ra đi vào
            kho Git rồi triển khai bằng Argo CD. Đây là bản minh họa: sơ đồ kéo thả và bản YAML là thật, nhưng chưa nối
            hệ thống phía sau.
          </div>

          <div className="page-head">
            <div className="page-head__main">
              <h1 className="page-title">{ROUTE_ID}</h1>
              <p className="page-desc">
                Tra cứu thông tin thửa đất · phiên bản 4 <span className="badge badge--muted">DRAFT</span>
                <span className="t-small t-muted">
                  {dirty ? ' — có thay đổi chưa lưu' : ' — lưu lúc 15:04, người sửa: Nguyễn Văn Quản'}
                </span>
              </p>
            </div>
            <div className="page-head__actions">
              <a className="btn" href="../routes.html">
                ← Danh sách luồng
              </a>
              <Button onClick={() => setDirty(false)}>Lưu bản nháp</Button>
              <Button>▷ Chạy thử</Button>
              <Button
                type="primary"
                disabled={counts.errors > 0}
                title={
                  counts.errors > 0
                    ? `Còn ${counts.errors} lỗi cần xử lý trước khi gửi duyệt`
                    : 'Gửi luồng sang hàng đợi duyệt'
                }
              >
                Gửi duyệt
              </Button>
            </div>
          </div>

          <div className="tabs">
            <button className="tab is-active">Thiết kế</button>
            <a className="tab" href="../designer.html#test">
              Chạy thử
            </a>
            <a className="tab" href="../designer.html#review">
              Duyệt <span className="tab__count">4</span>
            </a>
          </div>

          <ReactFlowProvider>
            <Designer mode={mode} onDirty={onDirty} onStatus={setCounts} />
          </ReactFlowProvider>
        </AppShell>
      </AntApp>
    </ConfigProvider>
  );
}
