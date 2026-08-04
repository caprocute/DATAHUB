import { Button, Form, Input, Space, Table, Typography, message } from 'antd'
import { useEffect, useState } from 'react'
import { apiGet, apiPost } from '../api/client'
import { useRoles } from '../auth/useRoles'

type Application = {
  id: string
  systemCode: string
  systemName: string
  ownerOrg: string
  status: string
  clientId?: string | null
  clientSecretSealed?: string | null
}

export function OnboardingPage() {
  const { canReview } = useRoles()
  const [items, setItems] = useState<Application[]>([])
  const [loading, setLoading] = useState(false)
  const [lastSecret, setLastSecret] = useState<string | null>(null)

  async function refresh() {
    setLoading(true)
    try {
      const data = await apiGet<{ items: Application[] }>('/onboarding/applications')
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
      <Typography.Title level={3}>Kết nạp hệ thống</Typography.Title>
      <Typography.Paragraph type="secondary">
        PH-01 — nộp hồ sơ; duyệt cần <code>INTEGRATION_REVIEWER</code>. List API không trả secret.
      </Typography.Paragraph>

      {lastSecret && (
        <Typography.Paragraph type="warning">
          Secret one-shot (chỉ hiện sau duyệt lần này): <Typography.Text code>{lastSecret}</Typography.Text>
        </Typography.Paragraph>
      )}

      <Form
        layout="vertical"
        style={{ maxWidth: 480, marginBottom: 24 }}
        onFinish={async (v) => {
          try {
            await apiPost('/onboarding/applications', v)
            message.success('Đã nộp hồ sơ')
            await refresh()
          } catch (e) {
            message.error(String(e))
          }
        }}
      >
        <Form.Item name="systemCode" label="Mã hệ thống" rules={[{ required: true }]}>
          <Input placeholder="HE_THONG_MOT_CUA" />
        </Form.Item>
        <Form.Item name="systemName" label="Tên hệ thống" rules={[{ required: true }]}>
          <Input />
        </Form.Item>
        <Form.Item name="ownerOrg" label="Đơn vị chủ quản" rules={[{ required: true }]}>
          <Input />
        </Form.Item>
        <Button type="primary" htmlType="submit">
          Nộp hồ sơ
        </Button>
      </Form>

      <Table
        rowKey="id"
        loading={loading}
        dataSource={items}
        pagination={false}
        columns={[
          { title: 'Mã', dataIndex: 'systemCode' },
          { title: 'Tên', dataIndex: 'systemName' },
          { title: 'Trạng thái', dataIndex: 'status' },
          { title: 'clientId', dataIndex: 'clientId' },
          {
            title: 'Thao tác',
            render: (_, row) =>
              row.status === 'SUBMITTED' && canReview ? (
                <Space>
                  <Button
                    size="small"
                    onClick={async () => {
                      try {
                        const approved = await apiPost<Application>(
                          `/onboarding/applications/${row.id}/approve`,
                        )
                        setLastSecret(approved.clientSecretSealed ?? null)
                        message.success('Đã duyệt')
                        await refresh()
                      } catch (e) {
                        message.error(String(e))
                      }
                    }}
                  >
                    Duyệt
                  </Button>
                </Space>
              ) : row.status === 'SUBMITTED' && !canReview ? (
                <Typography.Text type="secondary">Cần REVIEWER</Typography.Text>
              ) : null,
          },
        ]}
      />
    </div>
  )
}
