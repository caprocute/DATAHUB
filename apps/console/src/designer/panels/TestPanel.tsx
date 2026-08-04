import { Typography } from 'antd'

/**
 * UI-04-08 — panel chạy thử trong designer shell.
 * Production-path dùng tab Chạy thử trên FlowsPage (API WP-25).
 * Không render HISTORY / waterfall giả.
 */
export function TestPanel() {
  return (
    <div className="panel">
      <div className="panel__head">Chạy thử</div>
      <div className="panel__body">
        <Typography.Paragraph type="secondary">
          Chưa gắn test-runner tại panel này. Mở tab <strong>Chạy thử</strong> trên trang Luồng
          tích hợp để gọi <code>POST …/test-runs</code> (WP-25).
        </Typography.Paragraph>
        <Typography.Text type="secondary" className="t-small">
          Stub FE chỉ khi <code>VITE_TEST_RUN_STUB=true</code> — mặc định tắt.
        </Typography.Text>
      </div>
    </div>
  )
}
