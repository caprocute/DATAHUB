import { Button, Form, Input, Select, Table, Typography, message } from 'antd'
import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { apiGet, apiPost } from '../api/client'
import { listRoutes, type RouteSummary } from '../api/routesApi'
import { useRoles } from '../auth/useRoles'

type Service = {
  id: string
  serviceCode: string
  title: string
  status: string
  publicPath?: string | null
  routeFile?: string | null
}

export function CatalogPage() {
  const { canReview, canDesign } = useRoles()
  const canPublish = canReview
  const [items, setItems] = useState<Service[]>([])
  const [activeRoutes, setActiveRoutes] = useState<RouteSummary[]>([])
  const [loading, setLoading] = useState(false)
  const [form] = Form.useForm()

  async function refresh() {
    setLoading(true)
    try {
      const data = await apiGet<{ items: Service[] }>('/catalog/services')
      setItems(data.items)
    } catch (e) {
      message.error(String(e))
    } finally {
      setLoading(false)
    }
  }

  async function loadActiveRoutes() {
    try {
      const data = await listRoutes()
      setActiveRoutes(data.items.filter((r) => r.status === 'ACTIVE'))
    } catch {
      /* ignore */
    }
  }

  useEffect(() => {
    void refresh()
    void loadActiveRoutes()
  }, [])

  return (
    <div className="page-card">
      <Typography.Title level={3}>Catalog API</Typography.Title>
      <Typography.Paragraph type="secondary">
        PH-02 — đăng ký / publish route APISIX. Liên kết luồng Camel đã ACTIVE tại{' '}
        <Link to="/flows">Luồng tích hợp</Link>.
      </Typography.Paragraph>

      {canDesign && (
        <Form
          form={form}
          layout="vertical"
          style={{ maxWidth: 560, marginBottom: 24 }}
          initialValues={{
            publicPath: '/demo/tra-cuu',
            upstreamUrl: 'http://host.docker.internal:8088',
            openapiYaml: 'openapi: 3.0.0\ninfo:\n  title: demo\n  version: 0.1.0\npaths: {}',
          }}
          onFinish={async (v) => {
            try {
              await apiPost('/catalog/services', v)
              message.success('Đã đăng ký')
              await refresh()
            } catch (e) {
              message.error(String(e))
            }
          }}
        >
          <Form.Item name="serviceCode" label="Mã dịch vụ" rules={[{ required: true }]}>
            <Input placeholder="tra-cuu-thua-dat" />
          </Form.Item>
          <Form.Item name="title" label="Tiêu đề" rules={[{ required: true }]}>
            <Input />
          </Form.Item>
          <Form.Item name="publicPath" label="Public path">
            <Input />
          </Form.Item>
          <Form.Item label="Luồng ACTIVE (gợi ý upstream)">
            <Select
              allowClear
              placeholder={
                activeRoutes.length
                  ? 'Chọn route ACTIVE → điền upstream Camel'
                  : 'Chưa có route ACTIVE — dùng upstream mặc định'
              }
              options={activeRoutes.map((r) => ({
                value: r.routeCode,
                label: `${r.routeCode} · ${r.sourceSystem}→${r.targetSystem ?? '?'}`,
              }))}
              onChange={(code) => {
                if (!code) return
                // DEV: Camel dancu lắng nghe 8088; path public gắn với dịch vụ
                form.setFieldsValue({
                  upstreamUrl: 'http://host.docker.internal:8088',
                  title: form.getFieldValue('title') || `Catalog · ${code}`,
                })
              }}
            />
          </Form.Item>
          <Form.Item name="upstreamUrl" label="Upstream Camel">
            <Input />
          </Form.Item>
          <Form.Item name="openapiYaml" label="OpenAPI YAML" rules={[{ required: true }]}>
            <Input.TextArea rows={6} />
          </Form.Item>
          <Button type="primary" htmlType="submit">
            Đăng ký
          </Button>
        </Form>
      )}

      <Table
        rowKey="id"
        loading={loading}
        dataSource={items}
        pagination={false}
        columns={[
          { title: 'Mã', dataIndex: 'serviceCode' },
          { title: 'Tiêu đề', dataIndex: 'title' },
          { title: 'Trạng thái', dataIndex: 'status' },
          { title: 'Path', dataIndex: 'publicPath' },
          {
            title: 'Thao tác',
            render: (_, row) =>
              row.status === 'DRAFT' && canPublish ? (
                <Button
                  size="small"
                  onClick={async () => {
                    try {
                      await apiPost(`/catalog/services/${row.id}/publish`)
                      message.success('Đã publish')
                      await refresh()
                    } catch (e) {
                      message.error(String(e))
                    }
                  }}
                >
                  Publish
                </Button>
              ) : row.status === 'DRAFT' && !canPublish ? (
                <Typography.Text type="secondary">Cần quyền publish</Typography.Text>
              ) : (
                <Typography.Text type="secondary" ellipsis>
                  {row.routeFile?.split('/').pop()}
                </Typography.Text>
              ),
          },
        ]}
      />
    </div>
  )
}
