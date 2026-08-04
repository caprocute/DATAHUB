import { App as AntApp, Button, Input } from 'antd';
import { useEffect, useMemo, useState, type ReactNode } from 'react';
import type { ParsedGraph } from '../yaml/parse';
import { YamlParseError, graphFromYaml } from '../yaml/parse';

interface Props {
  yaml: string;
  routeId: string;
  /**
   * Nhận sơ đồ dựng lại từ YAML người dùng sửa tay (FR-04-026 round-trip).
   * Thiếu prop này thì bảng chỉ đọc.
   */
  onApplyGraph?: (graph: ParsedGraph) => void;
}

/** Tô màu YAML ở mức vừa đủ đọc: chú thích, khóa, chuỗi trong nháy, số. */
function highlight(src: string): ReactNode[] {
  return src.split('\n').map((line, i) => {
    const key = `l${i}`;

    if (/^\s*#/.test(line)) {
      return (
        <span className="c" key={key}>
          {line}
          {'\n'}
        </span>
      );
    }

    const m = /^(\s*(?:-\s+)?)([A-Za-z_][\w-]*)(:)(.*)$/.exec(line);
    if (!m) return <span key={key}>{line + '\n'}</span>;

    const [, indent, name, colon, rest] = m;
    const parts: ReactNode[] = [];
    // Phần sau dấu hai chấm có thể là chuỗi trong nháy đơn, số, hoặc từ khóa.
    const re = /('(?:[^']|'')*')|(\b\d+(?:\.\d+)?\b)/g;
    let last = 0;
    let mm: RegExpExecArray | null;
    while ((mm = re.exec(rest))) {
      if (mm.index > last) parts.push(rest.slice(last, mm.index));
      parts.push(
        <span className={mm[1] ? 's' : 'n'} key={`${key}-${mm.index}`}>
          {mm[0]}
        </span>,
      );
      last = mm.index + mm[0].length;
    }
    if (last < rest.length) parts.push(rest.slice(last));

    return (
      <span key={key}>
        {indent}
        <span className="k">{name}</span>
        {colon}
        {parts}
        {'\n'}
      </span>
    );
  });
}

export function YamlPanel({ yaml, routeId, onApplyGraph }: Props) {
  const body = useMemo(() => highlight(yaml), [yaml]);
  const lines = yaml.trimEnd().split('\n').length;
  const { message } = AntApp.useApp();

  const [editing, setEditing] = useState(false);
  const [draft, setDraft] = useState(yaml);
  const [error, setError] = useState<string | null>(null);

  // Sơ đồ đổi trong lúc không sửa tay thì bản nháp bám theo.
  useEffect(() => {
    if (!editing) setDraft(yaml);
  }, [yaml, editing]);

  function apply() {
    try {
      const graph = graphFromYaml(draft);
      onApplyGraph?.(graph);
      setError(null);
      setEditing(false);
      message.success(`Đã dựng lại sơ đồ: ${graph.nodes.length} chặng`);
    } catch (e) {
      // Không áp sơ đồ hỏng: giữ nguyên sơ đồ cũ và nói rõ vướng ở đâu.
      const at = e instanceof YamlParseError && e.line ? ` (dòng ${e.line})` : '';
      setError(`${e instanceof Error ? e.message : String(e)}${at}`);
    }
  }

  const copy = async () => {
    try {
      await navigator.clipboard.writeText(yaml);
      message.success('Đã chép định nghĩa YAML');
    } catch {
      // `file://` và trang không bảo mật có thể chặn clipboard.
      message.warning('Trình duyệt chặn chép tự động — hãy chọn và chép bằng tay');
    }
  };

  return (
    <div className="panel">
      <div className="panel__head">
        Định nghĩa Camel YAML DSL
        <span className="t-small t-muted" style={{ fontWeight: 400 }}>
          — sinh trực tiếp từ sơ đồ, {lines} dòng
        </span>
        <div style={{ marginLeft: 'auto' }} className="row">
          {onApplyGraph &&
            (editing ? (
              <>
                <Button
                  size="small"
                  onClick={() => {
                    setEditing(false);
                    setDraft(yaml);
                    setError(null);
                  }}
                >
                  Hủy
                </Button>
                <Button size="small" type="primary" onClick={apply}>
                  Dựng lại sơ đồ
                </Button>
              </>
            ) : (
              <Button size="small" onClick={() => setEditing(true)}>
                Sửa YAML
              </Button>
            ))}
          <Button size="small" onClick={copy}>
            Chép
          </Button>
        </div>
      </div>
      <div className="panel__body panel__body--flush">
        <p className="t-small t-muted yaml-note">
          Tệp này là thứ được đẩy vào kho Git tại đường dẫn{' '}
          <span className="t-mono">routes/{routeId}/route.camel.yaml</span>, rồi Argo CD đồng bộ xuống môi trường. Sơ đồ
          chỉ là cách nhìn của cùng một tệp.
        </p>
        {editing ? (
          <>
            <Input.TextArea
              className="t-mono"
              autoSize={{ minRows: 16, maxRows: 40 }}
              value={draft}
              onChange={(e) => setDraft(e.target.value)}
              spellCheck={false}
              aria-label="Sửa định nghĩa Camel YAML"
            />
            {error && (
              <p className="t-small yaml-error" role="alert">
                Chưa dựng lại được sơ đồ: {error}. Sơ đồ hiện tại giữ nguyên.
              </p>
            )}
          </>
        ) : (
          <pre className="code code--yaml">{body}</pre>
        )}
      </div>
    </div>
  );
}
