import type { SeqEdge, StageNode } from './flow/model'

const MARKER = '# @lgsp-canvas-v1: '

export type CanvasGraph = { nodes: StageNode[]; edges: SeqEdge[] }

/**
 * Nhúng graph XYFlow vào comment YAML để round-trip (không phụ thuộc parse Camel đầy đủ).
 *
 * Bản tin mẫu đã pin **không** được nhúng: theo FR-04-033 mẫu chỉ phục vụ lúc thiết kế,
 * còn định nghĩa luồng thì đi vào Git và triển khai ra môi trường thật — mẫu có thể chứa
 * dữ liệu cá nhân nên không để lọt vào đó.
 */
export function embedCanvas(yaml: string, graph: CanvasGraph): string {
  const json = JSON.stringify({
    nodes: graph.nodes.map((n) => ({
      id: n.id,
      type: n.type,
      position: n.position,
      data: { ...n.data, pinnedSample: undefined },
    })),
    edges: graph.edges.map((e) => ({
      id: e.id,
      source: e.source,
      target: e.target,
      type: e.type,
      data: e.data,
    })),
  })
  const b64 = btoa(unescape(encodeURIComponent(json)))
  return `${MARKER}${b64}\n${stripCanvas(yaml).trimStart()}`
}

export function stripCanvas(yaml: string): string {
  return yaml
    .split('\n')
    .filter((line) => !line.startsWith(MARKER.trim()) && !line.startsWith('# @lgsp-canvas-v1:'))
    .join('\n')
}

export function extractCanvas(yaml: string): CanvasGraph | null {
  const line = yaml.split('\n').find((l) => l.startsWith(MARKER) || l.startsWith('# @lgsp-canvas-v1:'))
  if (!line) return null
  const b64 = line.replace(/^# @lgsp-canvas-v1:\s*/, '').trim()
  try {
    const json = decodeURIComponent(escape(atob(b64)))
    const parsed = JSON.parse(json) as CanvasGraph
    if (!Array.isArray(parsed.nodes) || !Array.isArray(parsed.edges)) return null
    return parsed
  } catch {
    return null
  }
}
