import { App as AntApp, Button } from 'antd';
import { useMemo, type ReactNode } from 'react';

interface Props {
  yaml: string;
  routeId: string;
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

export function YamlPanel({ yaml, routeId }: Props) {
  const body = useMemo(() => highlight(yaml), [yaml]);
  const lines = yaml.trimEnd().split('\n').length;
  const { message } = AntApp.useApp();

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
        <pre className="code code--yaml">{body}</pre>
      </div>
    </div>
  );
}
