#!/usr/bin/env python3
"""Sinh backlog user story D02-05 từ khối đặc tả 17 mục của SRS (FR-00) và 20 FRS phân hệ.

    python3 datahub-docs/02-yeu-cau/backlog/tools/sinh_backlog.py          # ghi mọi đầu ra
    python3 datahub-docs/02-yeu-cau/backlog/tools/sinh_backlog.py --kiem   # chỉ in thống kê

Đầu ra (không sửa tay, chạy lại sau khi FRS đổi):
  * Các vùng `<!-- sinh:… -->` trong 02-yeu-cau/D02-05-backlog-user-story.md
  * 02-yeu-cau/D02-05-01-tieu-chi-chap-nhan.md (story đầy đủ kèm Gherkin)
  * 02-yeu-cau/backlog/gherkin/us-{ph}.feature (21 tệp, `# language: vi`)
  * 02-yeu-cau/backlog/D02-05-backlog-jira.csv, D02-05-backlog-gitlab.csv

Quy tắc chuyển đổi FR → story, cách tính điểm và gán wave ở D02-05 chương 3.
"""
from __future__ import annotations

import csv
import re
import sys
from collections import Counter, defaultdict
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
import doc_frs  # noqa: E402

DOCS = doc_frs.DOCS
REQ = DOCS / "02-yeu-cau"
MAIN = REQ / "D02-05-backlog-user-story.md"
APPX = REQ / "D02-05-01-tieu-chi-chap-nhan.md"
OUT = REQ / "backlog"

# ---------------------------------------------------------------- tham số
ROLE = {  # viết tắt D02-08 §3 -> tên vai trò dùng trong câu chuyện
    "PA": "quản trị nền tảng", "PO": "vận hành nền tảng", "TA": "quản trị tỉnh", "TO": "vận hành tỉnh",
    "SO": "cán bộ ATTT", "IE": "kỹ sư tích hợp", "IA": "người duyệt tích hợp", "SV": "chủ dịch vụ",
    "CA": "người duyệt dịch vụ", "OR": "cán bộ đầu mối của tổ chức", "DS": "cán bộ quản lý dữ liệu",
    "DA": "người duyệt danh mục", "DO": "chủ quản dữ liệu", "VW": "người xem", "AU": "kiểm toán viên",
    "PAD": "quản trị thanh toán", "PAP": "người phê duyệt thanh toán", "PAC": "kế toán đối soát",
    "POP": "vận hành thanh toán", "PTN": "HTTT đối tác thanh toán", "DEV": "nhà phát triển",
    "PAU": "kiểm toán viên",
}
ROLE_WORDS = [  # vai trò viết bằng chữ trong FRS
    ("Quản trị thanh toán", "PAD"), ("Người phê duyệt thanh toán", "PAP"), ("Kế toán", "PAC"),
    ("Đối soát viên", "PAC"), ("Vận hành thanh toán", "POP"), ("Nhà phát triển", "DEV"),
    ("Quản trị tỉnh", "TA"), ("Quản trị nền tảng", "PA"), ("Vận hành tỉnh", "TO"),
    ("Kỹ sư tích hợp", "IE"), ("Chủ dịch vụ", "SV"), ("Cán bộ ATTT", "SO"), ("Kiểm toán", "AU"),
]
# vai trò hưởng lợi khi tác nhân là "Hệ thống" hoặc "Mọi vai trò"
PH_BENEFIT = {"00": "TA", "01": "TA", "02": "SV", "03": "TO", "04": "IE", "05": "IE", "06": "DS",
              "07": "DS", "08": "DS", "09": "SO", "10": "IE", "11": "TO", "12": "TA", "13": "TO",
              "14": "IE", "15": "DEV", "16": "TA", "17": "IE", "18": "TO", "19": "PAC", "20": "PA"}
# wave phát triển của phân hệ (D01-02 §2.4) và đợt chuẩn của phân hệ (D03-01 §4.1)
PH_WAVE = {"00": "W1", "01": "W1", "02": "W1", "03": "W1", "04": "W1", "05": "W1", "06": "W4–W5",
           "07": "W2", "08": "W4–W5", "09": "W4", "10": "W2", "11": "W4", "12": "W1", "13": "W1–W2",
           "14": "W2", "15": "W4", "16": "W5", "17": "W5", "18": "W2", "19": "W4", "20": "W2"}
PH_DOT = {p: "MVP" for p in ("00", "01", "02", "03", "04", "05", "07", "10", "12", "13", "14", "18", "20")}
PH_DOT.update({"09": "Đợt 2", "11": "Đợt 2", "15": "Đợt 2", "19": "Đợt 2",
               "06": "Đợt 3", "08": "Đợt 3", "16": "Đợt 3", "17": "Đợt 3"})
DOT_RANK = {"MVP": 1, "Đợt 2": 2, "Đợt 3": 3, "Đợt sau": 4}
DOT_WAVE = {"Đợt 2": "W4", "Đợt 3": "W5", "Đợt sau": "Sau G5"}
WAVE_ORDER = ["W1", "W1–W2", "W2", "W4", "W4–W5", "W5", "Sau G5"]
EXTERNAL = re.compile(r"NDXP|PayGov|VNeID|CSDL quốc gia|SFTP|FTPS|SOAP|SMTP|SMS|ngân hàng|Debezium|Flowable|"
                      r"mô hình ngôn ngữ|LLM|Keycloak|OpenBao|Argo CD|Git", re.I)
FOUR_EYES = re.compile(r"bốn mắt|PENDING_APPROVAL|gửi duyệt|phê duyệt", re.I)
SRS_GROUP = re.compile(r"^###\s+4\.(\d+)\.\s+(.+?)\s*$")


# ---------------------------------------------------------------- tiện ích văn bản
def flat(s: str) -> str:
    s = re.sub(r"\s*\n\s*", " ", s or "").strip()
    s = re.sub(r"(theo |ở |trong )?bảng (dưới|sau)( đây)?", "theo bảng ở FR gốc", s)
    return re.sub(r"\s{2,}", " ", s)


def first_sentence(s: str, limit: int = 260) -> str:
    s = flat(s)
    m = re.search(r"(?<=[^.\d A-Z])\.(?=\s+[A-ZĐÂĂÊÔƠƯÁÀẢÃẠ`\"(])", s)
    if m:
        s = s[: m.start()]
    s = s.rstrip(" .;")
    if len(s) > limit:
        cut = s.rfind(";", 0, limit)
        cut = cut if cut > 80 else s.rfind(",", 0, limit)
        s = s[: cut if cut > 80 else limit].rstrip(" ,;") + " …"
    return s


PROPER = {"Keycloak", "Prometheus", "Kafka", "Kamelet", "Camel", "Garage", "Flowable", "Debezium", "OpenBao",
          "Argo", "Grafana", "Loki", "Tempo", "Mimir", "Valkey", "Apicurio", "PayGov", "Excel", "PostgreSQL",
          "Spring", "Git", "GitLab", "Harbor", "Cilium", "Istio", "ClickHouse", "Ceph", "Velero", "Barman",
          "Datahub", "Liquibase", "Quarkus", "Kaoto", "Swagger", "Redoc", "Postman", "Gravitee", "Pulsar"}
NOUN_START = ("Dashboard", "Danh sách", "Danh bạ", "Bảng", "Trang", "Màn", "Tab", "Hộp", "Báo cáo", "Nhật ký",
              "Trung tâm", "Chỉ số", "Bộ ", "Kênh", "Lịch sử", "Mẫu", "Ma trận", "Sổ", "Sơ đồ", "Biểu đồ", "Cây",
              "Hồ sơ", "Chế độ", "Khung", "Tham số", "Giao diện", "Thư viện", "Khuôn", "Nhãn", "Thông báo lỗi",
              "Lớp", "Vòng đời", "Tài liệu", "Hàng đợi", "Gói", "Cổng", "Trợ lý", "Ảnh chụp", "Chính sách",
              "Hạn ngạch", "Quy tắc", "Ngữ cảnh", "Cấu hình", "Mô hình", "Phiên bản", "Bản đồ", "Lịch")


def lower_first(s: str) -> str:
    w = re.split(r"[\s,;:(]", s, maxsplit=1)[0]
    if w in PROPER or not w:
        return s
    if (len(w) == 1 and w.isupper()) or (s[0].isupper() and w[1:].islower() and w.isalpha()):
        return s[0].lower() + s[1:]
    return s


def gh(s: str) -> str:
    """Một dòng an toàn cho Gherkin: không xuống dòng, không bắt đầu bằng từ khóa bảng."""
    s = flat(s).replace("|", "/")
    return s


def norm_dot(s: str) -> str:
    s = flat(s)
    for k in ("Đợt sau", "Sau", "Đợt 3", "Đợt 2", "Đ2b", "MVP"):
        if k in s:
            return {"Sau": "Đợt sau", "Đ2b": "Đợt 2"}.get(k, k)
    return "MVP"


def norm_prio(s: str) -> str:
    m = re.match(r"\s*([MSC])\b", s)
    return m.group(1) if m else "M"


# ---------------------------------------------------------------- đọc nguồn
def parse_srs():
    f = REQ / "D02-02-srs.md"
    lines = f.read_text(encoding="utf-8").splitlines()
    groups, frs, cur, in_block, label, group = {}, [], None, False, None, None
    letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    for ln in lines:
        m = SRS_GROUP.match(ln)
        if m and int(m.group(1)) <= 26:
            group = letters[int(m.group(1)) - 1]
            groups[group] = m.group(2).replace("`", "")
            continue
        m = doc_frs.FR_RE.match(ln)
        if m and m.group(2) == "00":
            cur = {"fr": m.group(1), "ph": "00", "title": m.group(3), "group": group, "f": {}}
            frs.append(cur)
            continue
        if cur is None:
            continue
        if ln.strip() == "::: dac-ta":
            in_block, label = True, None
            continue
        if in_block and ln.strip() == ":::":
            in_block, cur = False, None
            continue
        if in_block:
            m = doc_frs.LABEL_RE.match(ln)
            if m:
                label = m.group(1)
                cur["f"][label] = m.group(2).strip()
            elif label:
                cur["f"][label] = (cur["f"][label] + "\n" + ln).strip("\n")
    return {"file": f, "name": "Yêu cầu chức năng dùng chung (SRS)", "groups": groups,
            "frs": [x for x in frs if x["f"]]}


def ph_title(name: str) -> str:
    m = re.search(r"phân hệ PH-\d{2}\s+(.+)$", name)
    return m.group(1).strip() if m else name


# ---------------------------------------------------------------- chuyển FR thành story
def roles_in(text: str):
    found = []
    for code in re.findall(r"(?<![A-Za-z`-])(PAD|PAP|PAC|POP|PTN|DEV|PA|PO|TA|TO|SO|IE|IA|SV|CA|OR|DS|DA|DO|VW|AU)(?![A-Za-z`-])", text):
        if code not in found:
            found.append(code)
    for word, code in ROLE_WORDS:
        if word.lower() in text.lower() and code not in found:
            found.append(code)
    return found


def actor_of(fr):
    t = flat(fr["f"]["Tác nhân, quyền"])
    head = t.split(";")[0].split("(")[0]
    system = bool(re.match(r"\s*(Hệ thống|PH-\d{2}|Tác vụ|`dh-|DU |Bộ |Luồng|Runtime|Khai báo)", t)) and not roles_in(head)
    roles = roles_in(t)
    if ("Mọi người dùng" in t or "Mọi vai trò" in t) and not roles:
        return ("người dùng có quyền xem" if "read" in t else "người dùng"), False, roles
    if not roles and t.startswith("Người"):
        w = re.split(r"\s*(?:\(|;|,|`|\.|·| có | với | thuộc | được | và | hoặc | thực hiện | chọn | nhập )", t,
                     maxsplit=1)[0].split()
        who = " ".join(w[:5]).lower()
        return (who if who != "người" else "người dùng"), False, roles
    if not roles and t.startswith("HTTT"):
        return "HTTT khai thác", False, roles
    if not roles:
        return ROLE[PH_BENEFIT[fr["ph"]]], system or t.startswith("Hệ thống"), roles
    return ROLE[roles[0]], system, roles


def points(fr):
    f = fr["f"]
    steps = len(re.findall(r"^\d+\.\s", f["Luồng xử lý chính"], re.M))
    exc = max(1, len([l for l in f["Luồng ngoại lệ"].splitlines() if l.lstrip().startswith("- ")]))
    evt = 0 if flat(f["Sự kiện phát ra"]).startswith("Không") else 1
    alt = 0 if flat(f["Luồng thay thế"]).startswith("Không") else 1
    body = " ".join(f.values())
    ext = 1 if EXTERNAL.search(body) else 0
    four = 1 if FOUR_EYES.search(f["Luồng xử lý chính"] + f["Quy tắc nghiệp vụ"]) else 0
    raw = steps + exc + 2 * evt + alt + 2 * ext + 2 * four
    pts = 1 if raw <= 5 else 2 if raw <= 8 else 3 if raw <= 11 else 5 if raw <= 15 else 8
    return pts, raw


def exceptions(fr, n):
    txt = fr["f"]["Luồng ngoại lệ"]
    items = [l.lstrip()[2:] for l in txt.splitlines() if l.lstrip().startswith("- ")]
    if not items and ":" in txt and not flat(txt).startswith("Không"):
        items = [flat(txt)]
    out = []
    for it in items[:n]:
        it = flat(it)
        if ": " in it:
            cond, rest = it.split(": ", 1)
        else:
            cond, rest = it, ""
        errs = re.findall(r"ERR-\d{2}-\d{3}", rest) or re.findall(r"ERR-\d{2}-\d{3}", cond)
        http = re.search(r"\((\d{3})\)", rest)
        msg = re.search(r"[\"“]([^\"”]{4,200})[\"”]", rest)
        out.append((cond.strip(), errs, http.group(1) if http else "", msg.group(1) if msg else "", rest))
    return out


def build_story(fr, uc_map):
    f = fr["f"]
    who, system, roles = actor_of(fr)
    prio = norm_prio(f["Mức ưu tiên, đợt"])
    dot = norm_dot(f["Mức ưu tiên, đợt"].split("·", 1)[-1] if "·" in f["Mức ưu tiên, đợt"] else f["Mức ưu tiên, đợt"])
    if DOT_RANK.get(dot, 1) > DOT_RANK[PH_DOT[fr["ph"]]]:
        wave = DOT_WAVE[dot]
    else:
        wave = PH_WAVE[fr["ph"]]
    pts, raw = points(fr)
    title = fr["title"].replace("`", "")
    noun = title.startswith(NOUN_START)
    want = ("hệ thống có " if system and noun else "hệ thống " if system else "có " if noun else "") + lower_first(title)
    benefit = lower_first(first_sentence(f["Kết quả"], 220))
    if not benefit or benefit.startswith("Không"):
        benefit = lower_first(first_sentence(f["Mục đích"], 220))
    story = f"Là {who}, tôi muốn {want}, để {benefit}."
    ucs = uc_map.get(fr["fr"], [])
    num = fr["fr"][-3:]
    return {
        "us": f"US-{fr['ph']}-{num}", "fr": fr["fr"], "ph": fr["ph"], "group": fr["group"],
        "epic": f"EP-{fr['ph']}-{fr['group']}", "title": title, "story": story, "who": who,
        "prio": prio, "dot": dot, "wave": wave, "pts": pts, "raw": raw, "uc": ucs,
        "split": raw > 19, "roles": roles, "f": f,
        "ui_api": first_sentence(f["Màn hình, API"], 300),
        "trace": first_sentence(f["Truy vết"], 300),
    }


def gherkin(s):
    f = s["f"]
    pre = first_sentence(f["Tiền điều kiện"], 240)
    if not pre or pre.startswith("Không"):
        pre = f"người dùng đã đăng nhập với vai trò {s['who']}"
    trig = first_sentence(f["Kích hoạt"], 240)
    out_ = first_sentence(f["Đầu ra"], 240)
    if not out_ or out_.startswith("Không"):
        out_ = first_sentence(f["Kết quả"], 240)
    elif out_[0] in "`0123456789":
        out_ = "hệ thống trả " + out_
    post = first_sentence(f["Hậu điều kiện"], 240)
    evt = first_sentence(f["Sự kiện phát ra"], 160)
    aud = first_sentence(f["Kiểm toán"], 160)
    L = [f"  @{s['us']} @{s['fr']} @{s['prio']}",
         f"  Kịch bản: {s['us']} dương · {gh(s['title'])}",
         f"    Biết {gh(lower_first(pre))}",
         f"    Khi {gh(lower_first(trig))}",
         f"    Thì {gh(lower_first(out_))}"]
    if post and not post.startswith("Không"):
        L.append(f"    Và {gh(lower_first(post))}")
    if evt and not evt.startswith("Không"):
        L.append(f"    Và sự kiện được phát: {gh(evt)}")
    if aud and aud.startswith("Có"):
        L.append(f"    Và nhật ký kiểm toán ghi nhận thao tác")
    n = 2 if s["prio"] == "M" else 1
    for i, (cond, errs, http, msg, rest) in enumerate(exceptions(s, n), 1):
        L += ["", f"  @{s['us']} @{s['fr']} @{s['prio']} @âm",
              f"  Kịch bản: {s['us']} âm {i} · {gh(first_sentence(cond, 120))}",
              f"    Biết {gh(lower_first(pre))}",
              f"    Khi {gh(lower_first(first_sentence(cond, 200)))}"]
        if errs:
            L.append(f"    Thì hệ thống từ chối với {', '.join(errs)}" + (f" ({http})" if http else ""))
        else:
            r2 = re.sub(r"[\"“][^\"”]*[\"”]", "thông báo", rest).strip()
            r2 = first_sentence(r2, 200) if r2 and not r2.startswith("thông báo") else "hệ thống từ chối thao tác"
            L.append(f"    Thì {gh(lower_first(r2))}")
        if msg:
            L.append(f"    Và người dùng thấy thông báo \"{gh(msg)}\"")
    return L


def exceptions_of(s, n):
    return exceptions({"f": s["f"]}, n)


# gherkin() gọi exceptions(s, n) với s là story; story có khóa "f" nên dùng chung được


# ---------------------------------------------------------------- dựng đầu ra
def load():
    data = {"00": parse_srs()}
    data.update(doc_frs.parse_frs())
    uc_map = doc_frs.parse_uc()
    stories = []
    for ph in sorted(data):
        for fr in data[ph]["frs"]:
            stories.append(build_story(fr, uc_map))
    return data, stories


def epic_name(data, s):
    return data[s["ph"]]["groups"].get(s["group"], "")


def md_table(head, rows, caption, widths=None):
    sep = "|" + "|".join("-" * w for w in widths) + "|" if widths else "|" + "---|" * len(head)
    L = ["| " + " | ".join(head) + " |", sep]
    L += ["| " + " | ".join(str(c).replace("|", "/") for c in r) + " |" for r in rows]
    L += ["", f": {caption}"]
    return L


def region(text: str, name: str, body: list[str]) -> str:
    b, e = f"<!-- sinh:{name} -->", f"<!-- /sinh:{name} -->"
    pat = re.compile(re.escape(b) + r".*?" + re.escape(e), re.S)
    if not pat.search(text):
        raise SystemExit(f"Thiếu vùng {b} trong {MAIN.name}")
    return pat.sub(lambda _: b + "\n\n" + "\n".join(body).rstrip() + "\n\n" + e, text)


def uc_short(ucs):
    if not ucs:
        return "—"
    return ", ".join(u[-5:] if i else u for i, u in enumerate(ucs[:4])) + (" …" if len(ucs) > 4 else "")


def write_main(data, stories):
    text = MAIN.read_text(encoding="utf-8")
    by_ph = defaultdict(list)
    for s in stories:
        by_ph[s["ph"]].append(s)

    # tổng hợp theo phân hệ
    rows = []
    for ph in sorted(by_ph):
        ss = by_ph[ph]
        c = Counter(s["prio"] for s in ss)
        rows.append([f"PH-{ph}", ph_title(data[ph]["name"]) if ph != "00" else "Dùng chung (FR-00)",
                     len({s['epic'] for s in ss}), len(ss), sum(s["pts"] for s in ss),
                     c["M"], c["S"], c["C"], PH_WAVE[ph]])
    tot = [len(stories), sum(s["pts"] for s in stories)]
    rows.append(["**Cộng**", "", len({s['epic'] for s in stories}), f"**{tot[0]}**", f"**{tot[1]}**",
                 sum(1 for s in stories if s['prio'] == 'M'), sum(1 for s in stories if s['prio'] == 'S'),
                 sum(1 for s in stories if s['prio'] == 'C'), ""])
    text = region(text, "tong-hop-ph", md_table(
        ["PH", "Tên", "Epic", "Story", "Điểm", "M", "S", "C", "Wave"], rows,
        "Số epic, story, điểm và mức ưu tiên theo phân hệ (sinh tự động)"))

    # phân bố điểm
    pc = Counter(s["pts"] for s in stories)
    rows = [[p, pc[p], f"{100 * pc[p] / len(stories):.1f}%".replace(".", ","), p * pc[p]] for p in (1, 2, 3, 5, 8)]
    text = region(text, "phan-bo-diem", md_table(["Điểm", "Số story", "Tỷ lệ", "Tổng điểm"], rows,
                                                 "Phân bố story theo điểm ước lượng (sinh tự động)"))
    sp = [s for s in stories if s["split"]]
    text = region(text, "de-nghi-tach", [
        f"Có **{len(sp)}** story điểm thô trên 19 (đã chặn trần 8 điểm) được đánh dấu \"đề nghị tách\" để "
        "nhóm xem lại ở buổi làm rõ backlog trước khi đưa vào sprint: "
        + ", ".join(s["us"] for s in sp) + "."])

    # theo wave
    wv = defaultdict(lambda: [0, 0, 0])
    for s in stories:
        w = wv[s["wave"]]
        w[0] += 1
        w[1] += s["pts"]
        w[2] += s["pts"] if s["prio"] == "M" else 0
    rows = [[w, wv[w][0], wv[w][1], wv[w][2]] for w in WAVE_ORDER if w in wv]
    text = region(text, "theo-wave", md_table(["Wave", "Số story", "Tổng điểm", "Điểm mức M"], rows,
                                              "Story và điểm theo wave phát triển (sinh tự động)"))

    # danh sách epic và story theo phân hệ
    body = []
    n = 0
    for ph in sorted(by_ph):
        n += 1
        ss = by_ph[ph]
        name = ph_title(data[ph]["name"]) if ph != "00" else "Yêu cầu chức năng dùng chung (FR-00)"
        body += [f"### 6.{n}. PH-{ph} · {name}", "",
                 f"Phân hệ có {len({s['epic'] for s in ss})} epic, {len(ss)} story, tổng {sum(s['pts'] for s in ss)} điểm; "
                 f"wave phát triển {PH_WAVE[ph]}, đợt {PH_DOT[ph]}. Nguồn: "
                 + ("D02-02 SRS chương 4." if ph == "00" else f"D02-03-PH{ph} chương 6.") +
                 " Tiêu chí chấp nhận Gherkin của từng story ở D02-05-01 mục tương ứng.", ""]
        epics = defaultdict(list)
        for s in ss:
            epics[s["epic"]].append(s)
        for ep in sorted(epics):
            es = epics[ep]
            en = epic_name(data, es[0])
            body += [f"#### {ep} · {en}", "",
                     f"Epic gồm {len(es)} story, {sum(s['pts'] for s in es)} điểm "
                     f"({sum(1 for s in es if s['prio'] == 'M')} story mức M).", ""]
            rows = [[s["us"], s["story"], s["prio"], s["pts"] if not s["split"] else f"{s['pts']}*",
                     f"{s['dot']}, {s['wave']}", s["fr"] + (f"; {uc_short(s['uc'])}" if s["uc"] else "")] for s in es]
            body += md_table(["US", "Câu chuyện người dùng", "ƯT", "Điểm", "Đợt, wave", "FR; UC"], rows,
                             f"Story của epic {ep} {en}", [11, 48, 4, 8, 11, 14]) + [""]
    text = region(text, "danh-sach", body)
    MAIN.write_text(text, encoding="utf-8")


APPX_HEAD = """---
ma_tai_lieu: D02-05-01
ten: Phụ lục tiêu chí chấp nhận Gherkin của backlog user story
phien_ban: 0.1
ngay: 2026-11-27
trang_thai: Dự thảo
nguoi_doc: Kỹ sư phát triển, kiểm thử viên, PO hai phía
mo_ta: Phụ lục của D02-05 ghi đủ câu chuyện, truy vết và tiêu chí chấp nhận dạng Biết, Khi, Thì cho mọi story, sinh tự động từ khối đặc tả FR.
tai_lieu_lien_quan: D02-05 Backlog user story; D02-02 SRS; D02-03 FRS 20 phân hệ; D02-04 Use case; D05-02 Test case
---

# D02-05-01 · Phụ lục tiêu chí chấp nhận Gherkin của backlog user story

## Tóm tắt cho hội đồng thẩm định

**Mục tiêu.** Phụ lục ghi cho từng story của D02-05 câu chuyện người dùng, truy vết tới FR, UC, màn hình, API và tiêu chí chấp nhận viết theo Gherkin (Biết, Khi, Thì), để mỗi story đạt điều kiện sẵn sàng (DoR) của D01-02 §3.6 mà không phải viết tay lại.

**Phạm vi.** {n} story của 21 nhóm (FR-00 dùng chung và 20 phân hệ), sinh tự động bằng `02-yeu-cau/backlog/tools/sinh_backlog.py` từ khối đặc tả 17 mục của SRS và FRS. Bản chạy được của cùng nội dung nằm ở `02-yeu-cau/backlog/gherkin/us-{{ph}}.feature`.

**Căn cứ.** D01-02 §3.6 (DoR, DoD mức story); D02-05 chương 3 (quy tắc chuyển FR thành story); dàn ý bộ tài liệu SDLC mục D02-05.

**Những điểm hội đồng cần lưu ý.** (1) Phụ lục không thêm yêu cầu mới: mỗi câu Biết, Khi, Thì lấy từ Tiền điều kiện, Kích hoạt, Đầu ra, Hậu điều kiện và Luồng ngoại lệ của FR gốc, nên khi lệch thì FRS đúng. (2) Story mức M có một kịch bản dương và tối đa hai kịch bản âm; mức S, C có một kịch bản âm. (3) Kịch bản ở đây là tiêu chí chấp nhận mức story; ca kiểm thử chi tiết có dữ liệu ở D05-02.

## Giới thiệu tài liệu

### Mục đích

Cung cấp tiêu chí chấp nhận đầy đủ cho từng story để PO hai phía chấp nhận hoặc trả story tại sprint review và kiểm thử viên tự động hóa.

### Phạm vi

Mọi story ở D02-05 chương 6; không gồm story tách thêm khi làm rõ backlog (lấy số từ 501, ghi trực tiếp vào công cụ quản lý công việc).

### Người đọc

Kỹ sư phát triển và kiểm thử viên đọc theo phân hệ được giao; PO đọc khi chuẩn bị sprint review.

### Thuật ngữ và chữ viết tắt

Như D02-05 mục "Thuật ngữ và chữ viết tắt". Từ khóa Gherkin tiếng Việt: Tính năng (Feature), Kịch bản (Scenario), Biết (Given), Khi (When), Thì (Then), Và (And).

### Tài liệu tham chiếu

D02-05 Backlog user story; D02-02 SRS; D02-03-PH01…PH20; D02-04-PH01…PH20; D05-02.

### Cấu trúc tài liệu

Mỗi chương là một phân hệ, mỗi mục là một epic, mỗi tiểu mục là một story gồm câu chuyện, dòng truy vết và khối Gherkin.

"""


def write_appx(data, stories):
    by_ph = defaultdict(list)
    for s in stories:
        by_ph[s["ph"]].append(s)
    L = [APPX_HEAD.replace("{n}", str(len(stories))).replace("{{ph}}", "{ph}")]
    OUT.joinpath("gherkin").mkdir(parents=True, exist_ok=True)
    for i, ph in enumerate(sorted(by_ph), 1):
        ss = by_ph[ph]
        name = ph_title(data[ph]["name"]) if ph != "00" else "Yêu cầu chức năng dùng chung (FR-00)"
        L += [f"## {i}. PH-{ph} · {name}", "",
              f"Chương gồm {len(ss)} story của PH-{ph}. Tệp chạy được: `backlog/gherkin/us-{ph}.feature`.", ""]
        feat = ["# language: vi", f"# Sinh tự động từ D02-02/D02-03-PH{ph} bằng backlog/tools/sinh_backlog.py; không sửa tay.",
                f"@PH-{ph}", f"Tính năng: PH-{ph} · {name}", ""]
        epics = defaultdict(list)
        for s in ss:
            epics[s["epic"]].append(s)
        for j, ep in enumerate(sorted(epics), 1):
            es = epics[ep]
            en = epic_name(data, es[0])
            L += [f"### {i}.{j}. {ep} · {en}", "", f"Epic gồm {len(es)} story, {sum(s['pts'] for s in es)} điểm.", ""]
            feat += [f"  # ---- {ep} · {en}", ""]
            for s in es:
                g = gherkin(s)
                L += [f"#### {s['us']} · {s['title']}", "", s["story"], "",
                      f"*Epic* {ep} · *Ưu tiên* {s['prio']} · *Đợt* {s['dot']} · *Wave* {s['wave']} · *Điểm* {s['pts']}"
                      + (" (đề nghị tách)" if s["split"] else "") + f" · *FR* {s['fr']}"
                      + (f" · *UC* {', '.join(s['uc'])}" if s["uc"] else "") + ".", "",
                      f"*Truy vết* {s['trace']}. *Màn hình, API* {s['ui_api']}.", "",
                      "```gherkin"] + [x[2:] if x.startswith("  ") else x for x in g] + ["```", ""]
                feat += g + [""]
        (OUT / "gherkin" / f"us-{ph}.feature").write_text("\n".join(feat).rstrip() + "\n", encoding="utf-8")
    L += ["## Lịch sử phiên bản", "", "| Phiên bản | Ngày | Người | Nội dung |", "|---|---|---|---|",
          "| 0.1 | 27/11/2026 | Nhóm viết tài liệu (Claude) | Bản đầu, sinh tự động từ SRS và 20 FRS |", ""]
    APPX.write_text("\n".join(L), encoding="utf-8")


def write_csv(data, stories):
    epics = {}
    for s in stories:
        epics.setdefault(s["epic"], (s["ph"], epic_name(data, s)))
    prio = {"M": "High", "S": "Medium", "C": "Low"}
    with open(OUT / "D02-05-backlog-jira.csv", "w", newline="", encoding="utf-8-sig") as fh:
        w = csv.writer(fh)
        w.writerow(["Issue ID", "Parent ID", "Issue Type", "Summary", "Description", "Priority",
                    "Story Points", "Labels", "Labels", "Labels", "Fix Version", "Component"])
        for ep, (ph, name) in epics.items():
            w.writerow([ep, "", "Epic", f"{ep} · {name}", f"Epic của PH-{ph}, nhóm chức năng {name}.",
                        "", "", f"PH-{ph}", "epic", "", "", f"PH-{ph}"])
        for s in stories:
            desc = "\n".join([s["story"], "", f"Truy vết: {s['fr']}; UC: {', '.join(s['uc']) or '—'}; {s['trace']}",
                              f"Màn hình, API: {s['ui_api']}", "", "Tiêu chí chấp nhận:", "{code:gherkin}"]
                             + [x[2:] for x in gherkin(s)] + ["{code}"])
            w.writerow([s["us"], s["epic"], "Story", f"{s['us']} · {s['title']}", desc, prio[s["prio"]],
                        s["pts"], f"PH-{s['ph']}", s["dot"].replace(" ", "-"), "de-nghi-tach" if s["split"] else "",
                        s["wave"], f"PH-{s['ph']}"])
    with open(OUT / "D02-05-backlog-gitlab.csv", "w", newline="", encoding="utf-8") as fh:
        w = csv.writer(fh)
        w.writerow(["title", "description"])
        for s in stories:
            labels = f"~\"PH-{s['ph']}\" ~\"{s['epic']}\" ~\"{s['dot']}\" ~\"ưu tiên::{s['prio']}\""
            desc = "\n".join([s["story"], "", f"Truy vết: {s['fr']}; UC: {', '.join(s['uc']) or '—'}",
                              "", "```gherkin"] + [x[2:] for x in gherkin(s)] + ["```", "",
                              f"/label {labels}", f"/weight {s['pts']}", f"/milestone %\"{s['wave']}\""])
            w.writerow([f"{s['us']} · {s['title']}", desc])


def main():
    data, stories = load()
    allfr = {s["fr"] for s in stories}
    no_uc = [s["fr"] for s in stories if not s["uc"] and s["ph"] != "00"]
    print(f"story: {len(stories)}  điểm: {sum(s['pts'] for s in stories)}  epic: {len({s['epic'] for s in stories})}")
    print("FR không UC:", no_uc)
    print("đề nghị tách:", sum(s["split"] for s in stories))
    print("phân bố điểm:", sorted(Counter(s["pts"] for s in stories).items()))
    print("wave:", sorted(Counter(s["wave"] for s in stories).items()))
    if "--kiem" in sys.argv:
        for s in stories[::97]:
            print("\n", s["us"], s["story"])
            print("\n".join(gherkin(s)))
        return
    write_main(data, stories)
    write_appx(data, stories)
    write_csv(data, stories)
    print("Đã ghi", MAIN.name, APPX.name, "backlog/gherkin/*.feature, backlog/*.csv")


if __name__ == "__main__":
    main()
