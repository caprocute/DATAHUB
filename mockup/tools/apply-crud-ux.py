#!/usr/bin/env python3
"""Gắn chuẩn CRUD mockup (docs/ui_ux_rule.md): data-crud-*, filter nâng cao, empty-state."""
from __future__ import annotations

import re
from pathlib import Path

PAGES = Path(__file__).resolve().parents[1] / "pages"

# id bảng chính → (total, pageSize) — khớp copy mô tả trang khi có
TABLE_META: dict[str, tuple[int, int]] = {
    "hoso-table": (18, 10),
    "tv-table": (42, 10),
    "api-table": (86, 10),
    "routes-table": (134, 10),
    "dlq-table": (47, 10),
    "queue-table": (12, 10),
    "pii-table": (36, 10),
    "user-table": (56, 10),
    "bpmn-table": (14, 10),
    "task-table": (8, 10),
    "reg-table": (48, 10),
    "models-table": (6, 10),
    "decisions-table": (24, 10),
    "alerts-table": (32, 10),
    "portal-catalog-table": (20, 10),
}

ADV_FILTER = """
      <div class="crud-filter" data-crud-filter>
        <div class="crud-filter__row">
          <button type="button" class="btn btn--sm" data-crud-filter-toggle title="Hiện bộ lọc nâng cao">Bộ lọc nâng cao</button>
          <button type="button" class="btn btn--sm" data-crud-reset title="Đặt lại bộ lọc">↺ Đặt lại</button>
          <button type="button" class="btn btn--sm btn--primary" data-demo="Tìm kiếm phía máy chủ (CRUD-FLT-04)" title="Tìm kiếm">Tìm kiếm</button>
        </div>
        <div class="crud-filter__advanced hidden">
          <div class="field mb-0">
            <label class="field__label">Từ ngày</label>
            <input class="input" type="date" title="Ngày tạo từ">
          </div>
          <div class="field mb-0">
            <label class="field__label">Đến ngày</label>
            <input class="input" type="date" title="Ngày tạo đến">
          </div>
          <div class="field mb-0">
            <label class="field__label">Trạng thái</label>
            <select class="select" title="Lọc trạng thái"><option>Tất cả</option><option>Đang hoạt động</option><option>Nháp</option></select>
          </div>
        </div>
      </div>
"""

EMPTY = """
    <div class="empty-state hidden" data-crud-no-result>
      <div class="empty-state__icon">⌕</div>
      <div class="empty-state__title">Không tìm thấy dữ liệu phù hợp</div>
      <div class="empty-state__desc">Thử đổi từ khóa hoặc đặt lại bộ lọc.</div>
      <button type="button" class="btn btn--sm" data-crud-reset title="Đặt lại bộ lọc">Đặt lại bộ lọc</button>
    </div>
"""


def count_rows(table_html: str) -> int:
    return len(re.findall(r"<tr[\s>]", table_html.split("<tbody", 1)[-1] if "<tbody" in table_html else ""))


def enrich_table_open_tag(tag: str, table_body_hint: str = "") -> str:
    if "data-crud-total" in tag:
        return tag
    tid_m = re.search(r'id="([^"]+)"', tag)
    tid = tid_m.group(1) if tid_m else None
    if tid and tid in TABLE_META:
        total, size = TABLE_META[tid]
    else:
        rows = max(1, count_rows(table_body_hint))
        # mock: giả định còn dữ liệu phía máy chủ
        total = max(rows, 20) if rows < 15 else rows
        size = 10
    if 'class="table"' in tag and "table--sticky" not in tag:
        tag = tag.replace('class="table"', 'class="table table--sticky"', 1)
    elif "class=" not in tag:
        tag = tag.replace("<table", '<table class="table table--sticky"', 1)
    attrs = f' data-crud-total="{total}" data-crud-page-size="{size}" data-crud-page="1"'
    return tag[:-1] + attrs + ">"


def patch_all_tables(html: str) -> str:
    out = []
    pos = 0
    for m in re.finditer(r"<table\b[^>]*>", html):
        out.append(html[pos : m.start()])
        end_table = html.find("</table>", m.end())
        body = html[m.end() : end_table] if end_table > 0 else ""
        out.append(enrich_table_open_tag(m.group(0), body))
        pos = m.end()
    out.append(html[pos:])
    return "".join(out)


def ensure_filter_once(html: str) -> str:
    if "data-crud-filter" in html:
        return html
    if 'class="table-wrap' not in html:
        return html
    return html.replace('<div class="table-wrap', ADV_FILTER + "\n    <div class=\"table-wrap", 1)


def ensure_empty_once(html: str) -> str:
    if "data-crud-no-result" in html:
        return html
    # after first </table></div> of first table-wrap
    m = re.search(r'(<div class="table-wrap[^"]*">[\s\S]*?</table>\s*</div>)', html)
    if not m:
        return html
    return html[: m.end()] + EMPTY + html[m.end() :]


def ensure_bulk_for_checkbox_tables(html: str) -> str:
    for tid in re.findall(r'id="([^"]+)"[^>]*data-crud-total|data-crud-total="\d+"[^>]*id="([^"]+)"', html):
        pass
    for m in re.finditer(r'<table\b[^>]*id="([^"]+)"[^>]*>', html):
        tid = m.group(1)
        if f'data-crud-bulk="{tid}"' in html:
            continue
        # window around thead
        chunk = html[m.start() : m.start() + 500]
        if "checkbox" not in chunk.lower():
            continue
        # find preceding table-wrap
        before = html[: m.start()]
        tw = before.rfind('<div class="table-wrap')
        if tw < 0:
            continue
        bulk = f"""
    <div class="crud-bulk" data-crud-bulk="{tid}">
      <span>Bạn đã chọn <span class="crud-bulk__count" data-crud-bulk-count>0</span> bản ghi</span>
      <button type="button" class="btn btn--sm btn--primary" data-demo="Thao tác hàng loạt" title="Thao tác hàng loạt">Thao tác hàng loạt</button>
      <button type="button" class="btn btn--sm btn--danger" data-demo="Xóa hàng loạt — cần xác nhận" title="Xóa hàng loạt">Xóa đã chọn</button>
    </div>
"""
        html = html[:tw] + bulk + html[tw:]
    return html


def ensure_primary_cta(html: str, name: str) -> str:
    labels = {
        "events.html": ("＋ Đăng ký chủ đề", "Đăng ký chủ đề Kafka"),
        "monitoring.html": ("＋ Tạo luật cảnh báo", "Tạo luật cảnh báo"),
    }
    if name not in labels or "page-head__actions" not in html:
        return html
    # Chỉ xét khối page-head__actions đầu trang
    m = re.search(r'<div class="page-head__actions">([\s\S]*?)</div>', html)
    if not m:
        return html
    if "btn--primary" in m.group(1):
        return html
    label, demo = labels[name]
    return html.replace(
        '<div class="page-head__actions">',
        f'<div class="page-head__actions">\n    <button class="btn btn--primary" data-demo="{demo}" title="{label}">{label}</button>',
        1,
    )


def note_ux(html: str) -> str:
    if "ui_ux_rule.md" in html or "mock-note" not in html:
        return html
    return html.replace(
        '<div class="mock-note">',
        '<div class="mock-note">\n  <strong>UI/UX:</strong> bám <a href="../../docs/ui_ux_rule.md">chuẩn CRUD</a>.\n',
        1,
    )


def id_first_tables(html: str, page: str) -> str:
    """Gán id cho bảng đầu không có id — để pagination/bulk ổn định."""
    slug = page.replace(".html", "")
    n = 0

    def repl(m: re.Match[str]) -> str:
        nonlocal n
        tag = m.group(0)
        if 'id="' in tag:
            return tag
        n += 1
        return tag[:-1] + f' id="{slug}-table-{n}">'

    return re.sub(r"<table class=\"table\"[^>]*>", repl, html)


def patch_file(path: Path) -> bool:
    if path.name in {"login.html"}:
        return False
    html = path.read_text(encoding="utf-8")
    orig = html
    html = id_first_tables(html, path.name)
    html = patch_all_tables(html)
    html = ensure_filter_once(html)
    html = ensure_empty_once(html)
    html = ensure_bulk_for_checkbox_tables(html)
    html = ensure_primary_cta(html, path.name)
    html = note_ux(html)
    if html != orig:
        path.write_text(html, encoding="utf-8")
        return True
    return False


def main() -> None:
    changed = []
    for path in sorted(PAGES.glob("*.html")):
        if patch_file(path):
            changed.append(path.name)
    print("updated:", ", ".join(changed) if changed else "(none)")


if __name__ == "__main__":
    main()
