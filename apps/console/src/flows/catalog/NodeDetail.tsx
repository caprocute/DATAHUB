import { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import {
  GROUP_VI,
  KIND_VI,
  groupProps,
  labelVi,
  loadSchema,
  lookupNode,
  refOf,
  type CatalogNode,
  type PropertiesSchema,
  type SchemaProp,
} from '../core/catalog'
import { clearPendingTarget, setPendingPick, type PendingTarget } from './pendingInsert'

/**
 * Trang chi tiết một nút catalog (K4-3 — FR-D-072).
 *
 * Bảng tham số nạp **lười**: 742 tệp lược đồ là ~10 MB, gộp hết vào bundle sẽ kéo thời
 * gian tải màn đầu của cả console. `loadSchema` đã có sẵn cơ chế nạp theo nhu cầu + cache.
 */
export function NodeDetail({
  nodeRef,
  pending,
}: {
  nodeRef: string
  pending: PendingTarget | null
}) {
  const node = lookupNode(nodeRef)
  const [schema, setSchema] = useState<PropertiesSchema | null>(null)
  const [showAdvanced, setShowAdvanced] = useState(false)
  const navigate = useNavigate()

  useEffect(() => {
    if (!node) return
    let alive = true
    setSchema(null)
    setShowAdvanced(false)
    void loadSchema(node).then((s) => {
      // Người dùng có thể đã bấm sang nút khác trong lúc chờ — bỏ kết quả cũ, nếu không
      // bảng tham số của nút trước sẽ đè lên nút đang xem.
      if (alive) setSchema(s)
    })
    return () => {
      alive = false
    }
  }, [node])

  if (!node) {
    return <p className="cat__hint">Không tìm thấy mục <code>{nodeRef}</code> trong danh mục.</p>
  }

  const groups = schema ? groupProps(schema) : []
  const total = schema ? Object.keys(schema.properties ?? {}).length : 0
  const visible = groups.filter((g) => showAdvanced || g.group !== 'advanced')
  const advancedCount = groups.find((g) => g.group === 'advanced')?.props.length ?? 0

  return (
    <article className="cat__detail">
      <header className="cat__detail-head">
        <div className="cat__detail-kind">{KIND_VI[node.kind]}</div>
        <h2 className="cat__detail-title">{node.title}</h2>
        <code className="cat__detail-name">{refOf(node)}</code>

        <div className="cat__flags">
          {node.deprecated && (
            <span className="cat__flag cat__flag--warn">
              Không dùng nữa — Camel sẽ gỡ ở bản sau, tránh dùng cho luồng mới
            </span>
          )}
          {node.supportLevel && (
            <span className="cat__flag">Mức hỗ trợ: {node.supportLevel}</span>
          )}
          {node.nativeSupported === false && (
            <span className="cat__flag cat__flag--warn">
              Chưa chạy được ở ảnh native — trái ADR-002/020, cần kiểm trước khi dùng
            </span>
          )}
          {node.consumerOnly && <span className="cat__flag">Chỉ dùng làm chặng tiếp nhận</span>}
          {node.producerOnly && <span className="cat__flag">Không dùng làm chặng tiếp nhận</span>}
        </div>

        {pending && (
          <button
            type="button"
            className="cat__add"
            onClick={() => {
              setPendingPick({ ref: refOf(node), code: pending.code })
              clearPendingTarget()
              navigate(`/flows/${pending.code}/design`)
            }}
          >
            Thêm vào luồng {pending.code}
          </button>
        )}
      </header>

      {node.description && <p className="cat__desc">{node.description}</p>}

      {node.labels.length > 0 && (
        <div className="cat__meta-labels">
          {node.labels.map((l) => (
            <span key={l} className="cat__chip is-static">
              {labelVi(l)}
            </span>
          ))}
        </div>
      )}

      {node.syntax && (
        <section className="cat__section">
          <h3>Cú pháp URI</h3>
          <code className="cat__syntax">{node.syntax}</code>
          <p className="cat__note">
            Phần sau dấu <code>:</code> là tham số đường dẫn — điền trực tiếp trong URI; các
            tham số còn lại đặt sau dấu <code>?</code>.
          </p>
        </section>
      )}

      <DependencySection node={node} />

      <section className="cat__section">
        <h3>
          Tham số cấu hình{' '}
          {schema && <span className="cat__tab-n">{total}</span>}
        </h3>

        {schema === null ? (
          <p className="cat__note">Đang nạp lược đồ…</p>
        ) : total === 0 ? (
          /* 9 kamelet không có tham số cấu hình nên nhà sản xuất không phát hành lược đồ.
             Chúng vẫn là mục hợp lệ — phải nói rõ "không có tham số" thay vì để người dùng
             tưởng lược đồ tải hỏng (IP-07 §6). */
          <p className="cat__note">
            Mục này không có tham số cấu hình — nhà sản xuất không phát hành lược đồ cho nó.
          </p>
        ) : (
          <>
            {visible.map((g) => (
              <div key={g.group} className="cat__group">
                <h4 className="cat__group-title">
                  {GROUP_VI[g.group]} <span className="cat__tab-n">{g.props.length}</span>
                </h4>
                <div className="cat__table-wrap">
                  <table className="cat__table">
                    <thead>
                      <tr>
                        <th scope="col">Tên</th>
                        <th scope="col">Kiểu</th>
                        <th scope="col">Mặc định</th>
                        <th scope="col">Mô tả</th>
                      </tr>
                    </thead>
                    <tbody>
                      {g.props.map((p) => (
                        <PropRow key={p.name} name={p.name} prop={p.prop} required={p.required} />
                      ))}
                    </tbody>
                  </table>
                </div>
              </div>
            ))}

            {advancedCount > 0 && !showAdvanced && (
              <button type="button" className="cat__more" onClick={() => setShowAdvanced(true)}>
                Hiện {advancedCount} tham số nâng cao
              </button>
            )}
          </>
        )}
      </section>
    </article>
  )
}

/**
 * Phụ thuộc cần thêm để luồng chạy được (FR-D-072).
 *
 * Hai dạng khác nhau, không gộp: `component` có **tọa độ Maven** đầy đủ để dán vào
 * `pom.xml`; `kamelet` chỉ khai **phụ thuộc logic** dạng `camel:aws2-s3` mà Camel K tự
 * phân giải. Hiện nhầm dạng sẽ dẫn người dùng đi thêm artifact không tồn tại.
 */
function DependencySection({ node }: { node: CatalogNode }) {
  if (node.artifactId) {
    return (
      <section className="cat__section">
        <h3>Phụ thuộc Maven</h3>
        <pre className="cat__pom">
{`<dependency>
  <groupId>${node.groupId}</groupId>
  <artifactId>${node.artifactId}</artifactId>
</dependency>`}
        </pre>
        <dl className="cat__kv">
          <dt>Phiên bản</dt>
          <dd>{node.version ?? '—'}</dd>
          {node.camelArtifact && (
            <>
              <dt>Artifact Camel gốc</dt>
              <dd><code>{node.camelArtifact}</code></dd>
            </>
          )}
          {node.firstVersion && (
            <>
              <dt>Có từ bản</dt>
              <dd>{node.firstVersion}</dd>
            </>
          )}
          {node.javaType && (
            <>
              <dt>Lớp Java</dt>
              <dd><code className="cat__javatype">{node.javaType}</code></dd>
            </>
          )}
        </dl>
      </section>
    )
  }

  if (node.dependencies?.length) {
    return (
      <section className="cat__section">
        <h3>Phụ thuộc</h3>
        <ul className="cat__deps">
          {node.dependencies.map((d) => (
            <li key={d}><code>{d}</code></li>
          ))}
        </ul>
        <p className="cat__note">
          Kamelet khai phụ thuộc theo tên logic; Camel tự phân giải ra artifact khi nạp.
        </p>
      </section>
    )
  }

  if (node.javaType) {
    return (
      <section className="cat__section">
        <h3>Nguồn gốc</h3>
        <dl className="cat__kv">
          <dt>Lớp Java</dt>
          <dd><code className="cat__javatype">{node.javaType}</code></dd>
          {node.firstVersion && (
            <>
              <dt>Có từ bản</dt>
              <dd>{node.firstVersion}</dd>
            </>
          )}
        </dl>
        <p className="cat__note">
          Mục này thuộc lõi Camel — không cần thêm phụ thuộc riêng.
        </p>
      </section>
    )
  }

  return null
}

function PropRow({
  name,
  prop,
  required,
}: {
  name: string
  prop: SchemaProp
  required: boolean
}) {
  // `enum` mô tả kiểu chính xác hơn `type` (bản gốc ghi `string` cho cả trường có enum).
  const type = prop.enum?.length ? 'enum' : (prop.type ?? '—')
  return (
    <tr className={prop.deprecated ? 'is-deprecated' : undefined}>
      <th scope="row">
        <code>{name}</code>
        {required && (
          <span className="cat__req" title="Bắt buộc">
            *
          </span>
        )}
        {prop.deprecated && <span className="cat__badge cat__badge--warn">cũ</span>}
      </th>
      <td>
        <span className="cat__type">{String(type)}</span>
        {prop.enum?.length ? (
          <div className="cat__enum">
            {prop.enum.map((e) => (
              <code key={e}>{e}</code>
            ))}
          </div>
        ) : null}
      </td>
      <td>
        {prop.default === undefined || prop.default === '' ? (
          <span className="cat__muted">—</span>
        ) : (
          <code>{String(prop.default)}</code>
        )}
      </td>
      <td className="cat__prop-desc">{prop.description || prop.title || ''}</td>
    </tr>
  )
}
