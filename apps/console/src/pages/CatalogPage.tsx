import { Button, Form, Input, Table, Typography, message } from 'antd'
import { useEffect, useState } from 'react'
import { apiGet, apiPost } from '../api/client'

type Service = {
  id: string
  serviceCode: string
  title: string
  status: string
  publicPath?: string | null
  routeFile?: string | null
}

export function CatalogPage() {
  const [items, setItems] = useState<Service[]>([])
  const [loading, setLoading] = useState(false)

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

  useEffect(() => {
    void refresh()
  }, [])

  return (
    <div className="page-card">
      <Typography.Title level={3}>Catalog API</Typography.Title>
      <Typography.Paragraph type="secondary">
        PH-02 — đăng ký dịch vụ và publish (sinh file route APISIX declarative).
      </Typography.Paragraph>

      <Form
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
              row.status === 'DRAFT' ? (
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
              ) : (
                <Typography.Text type="secondary">{row.routeFile}</Typography.Text>
              ),
          },
        ]}
      />
    </div>
  )
}
