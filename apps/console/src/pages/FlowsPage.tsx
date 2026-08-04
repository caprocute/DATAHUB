import { Typography } from 'antd'

export function FlowsPage() {
  return (
    <div className="page-card">
      <Typography.Title level={3}>Luồng tích hợp</Typography.Title>
      <Typography.Paragraph type="secondary">
        Thin-slice W1: gọi qua gateway{' '}
        <code>GET http://localhost:9080/demo/tra-cuu</code> (Bearer Keycloak) → Camel →
        WireMock.
      </Typography.Paragraph>
      <Typography.Paragraph>
        Designer đầy đủ ở wave sau. Hiện dùng màn <strong>Kết nạp</strong> và{' '}
        <strong>Catalog</strong> để chuẩn bị client/route.
      </Typography.Paragraph>
    </div>
  )
}
