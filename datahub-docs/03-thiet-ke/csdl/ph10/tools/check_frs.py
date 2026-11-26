#!/usr/bin/env python3
"""Đối chiếu DDL ph10_event với phụ lục A của D02-03-PH10 (nguồn chuẩn enum, tên trường).

Chạy từ thư mục csdl/ph10:  python3 tools/check_frs.py
Kiểm ba điều, in LỆCH khi sai, mã thoát 1 nếu có lệch:
  1. Mỗi enum A.2 ánh xạ tới cột: tập giá trị CHECK trong DDL bằng đúng tập ở FRS.
  2. Mỗi trường A.3 (bỏ phần JSON lồng trong ngoặc) có cột snake_case trong bảng gợi ý,
     trừ ngoại lệ đã ghi ở D03-03-PH10 §1.3.
  3. Không có giá trị CHECK dạng UPPER_SNAKE nào trong DDL mà FRS không có (chống tự đặt enum).
"""
import os, re, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DOCS = os.path.dirname(os.path.dirname(os.path.dirname(ROOT)))
FRS = os.path.join(DOCS, "02-yeu-cau", "frs", "D02-03-PH10-frs-su-kien.md")
sql = open(os.path.join(ROOT, "ddl", "ph10_event.sql"), encoding="utf-8").read()
frs = open(FRS, encoding="utf-8").read()
appx = frs[frs.index("## Phụ lục A."):]


def section(num):
    m = re.search(r"#### A\.2\.%d\..*?\n(.*?)(?=\n#### |\n### )" % num, appx, re.S)
    return m.group(1)


def row_values(num, label):
    for line in section(num).split("\n"):
        cells = [c.strip() for c in line.split("|")]
        if len(cells) > 2 and (cells[1] == f"`{label}`" or cells[1].startswith(f"`{label}` (")):
            return set(re.findall(r"`([A-Z][A-Z0-9_]+)`", re.sub(r"\([^()]*\)", "", cells[2])))  # bỏ chú thích trong ngoặc
    raise SystemExit(f"Không tìm thấy dòng {label} ở A.2.{num}")


def first_col_codes(num):
    out = set()
    for line in section(num).split("\n"):
        cells = [c.strip() for c in line.split("|")]
        if len(cells) > 2:
            m = re.fullmatch(r"`([A-Z][A-Z0-9_]+)`", cells[1])
            if m:
                out.add(m.group(1))
    return out


def inline_values(num, after=None):
    text = section(num)
    if after:
        text = text[text.index(after):].split("\n")[0]
    return set(re.findall(r"`([A-Z][A-Z0-9_]+)`", text))


# FRS enum -> danh sách (bảng, cột) trong DDL
ENUMS = [
    (first_col_codes(1), [("event_project", "status")]),
    (first_col_codes(2), [("topic", "status")]),
    (row_values(3, "topicKind"), [("topic", "topic_kind")]),
    (row_values(3, "dataClass"), [("topic", "data_class")]),
    (row_values(3, "cleanupPolicy"), [("topic", "cleanup_policy")]),
    (row_values(4, "SchemaVersion.status"), [("schema_version", "status")]),
    (row_values(4, "EventSchema.schemaFormat"), [("event_schema", "schema_format")]),
    (row_values(4, "EventSchema.compatibility"), [("event_schema", "compatibility")]),
    (row_values(5, "partyType"), [("publisher", "party_type")]),
    (row_values(5, "partyType") - {"LEGACY_BRIDGE"}, [("subscriber", "party_type")]),
    (row_values(5, "status"), [("publisher", "status"), ("subscriber", "status")]),
    (row_values(5, "suspendSource"), [("publisher", "suspend_source"), ("subscriber", "suspend_source"),
                                      ("publication", "suspend_source"), ("subscription", "suspend_source")]),
    (inline_values(6), [("publication", "status")]),
    (row_values(7, "status"), [("subscription", "status")]),
    (row_values(7, "deliveryMode"), [("subscription", "delivery_mode"), ("comm_type", "delivery_mode")]),
    (row_values(7, "startPosition"), [("subscription", "start_position")]),
    (row_values(7, "alertState"), [("subscription", "alert_state"), ("lag_sample_5m", "alert_state")]),
    (row_values(7, "SigningKey.status"), [("signing_key", "status")]),
    (first_col_codes(8), [("comm_type", "comm_type_code")]),
    (inline_values(8, "`CommType.direction`") - set(), [("comm_type", "direction")]),
    (first_col_codes(9), [("routing_mode", "routing_mode_code"), ("topic", "routing_mode")]),
    (inline_values(9, "`RoutingMode.ordering`"), [("routing_mode", "ordering")]),
    (row_values(10, "requestType"), [("approval_request", "request_type")]),
    (row_values(10, "status"), [("approval_request", "status")]),
    (row_values(10, "targetType"), [("approval_request", "target_type")]),
    (row_values(11, "DlqEntry.status"), [("dlq_entry", "status")]),
    (row_values(11, "DlqEntry.origin"), [("dlq_entry", "origin")]),
    (row_values(11, "ReplayRequest.status"), [("replay_request", "status")]),
    (row_values(11, "ReplayRequest.replayMode"), [("replay_request", "replay_mode")]),
    (row_values(11, "ReplayRequest.rangeType"), [("replay_request", "range_type")]),
    (row_values(11, "DeliveryFailure.failureClass"), [("delivery_failure", "failure_class")]),
    (row_values(13, "sourceKind"), [("manifest_import_job", "source_kind")]),
    (row_values(13, "status"), [("manifest_import_job", "status")]),
    (row_values(14, "LegacyMapping.legacyType"), [("legacy_mapping", "legacy_type")]),
    (row_values(14, "LegacyMapping.targetType"), [("legacy_mapping", "target_type")]),
    (row_values(14, "MigrationBridge.startFrom"), [("migration_bridge", "start_from")]),
    (row_values(14, "LegacyMapping.status"), [("legacy_mapping", "status")]),
    (row_values(14, "LegacyMapping.confidence"), [("legacy_mapping", "confidence")]),
    (row_values(14, "MigrationBridge.direction"), [("migration_bridge", "direction")]),
    (row_values(14, "MigrationBridge.status"), [("migration_bridge", "status")]),
]
# JSON trong cột: kiểm bằng chuỗi có mặt trong DDL
JSON_ENUMS = [row_values(7, "push.failurePolicy"), row_values(7, "push.payloadFormat"),
              row_values(7, "endpointVerification.result"), row_values(4, "piiFindings[].severity"),
              row_values(13, "changeKind")]

tables = {m.group(1): m.group(2) for m in re.finditer(r"CREATE TABLE ph10_event\.(\w+) \((.*?)\n\)( PARTITION BY [^;]+)?;", sql, re.S)}
problems = []


def ddl_enum(table, col):
    body = tables[table]
    m = re.search(r"CHECK \(\(?(?:%s IS NULL OR )?%s IN \(([^)]*)\)" % (col, col), body)
    if not m:
        return None
    return set(re.findall(r"'([A-Z][A-Z0-9_]+)'", m.group(1)))


for frs_vals, targets in ENUMS:
    for t, c in targets:
        got = ddl_enum(t, c)
        if got is None:
            problems.append(f"LỆCH enum: {t}.{c} không có CHECK IN")
        elif got != frs_vals:
            problems.append(f"LỆCH enum {t}.{c}: DDL thừa {sorted(got - frs_vals)}, thiếu {sorted(frs_vals - got)}")
for vals in JSON_ENUMS:
    for v in vals:
        if f'"{v}"' not in sql and f"'{v}'" not in sql:
            problems.append(f"LỆCH enum JSON: {v} không có trong DDL")

# 2. Trường A.3
def snake(s):
    return re.sub(r"(?<=[a-z0-9])([A-Z])", r"_\1", s).lower()

EXCEPT = {("dlq_entry", "dlq_entry_id"): "id", ("legacy_mapping", "mapping_id"): "id",
          ("delivery_failure", "offset"): "record_offset", ("subscriber", "is_flow"): None}
a3 = appx[appx.index("### A.3."):appx.index("### A.4.")]
for line in a3.split("\n"):
    cells = [c.strip() for c in line.split("|")]
    if len(cells) < 4 or not cells[2].startswith("`"):
        continue
    tnames = re.findall(r"`(\w+)`", cells[2])
    if not tnames or tnames[0] == "outbox_event":
        continue
    tname = tnames[0]
    fields_txt = cells[3]
    while re.search(r"\([^()]*\)", fields_txt):
        fields_txt = re.sub(r"\([^()]*\)", "", fields_txt)
    fields = re.findall(r"`(\w+)`", fields_txt)
    if tname == "subscriber":  # "như Publisher với subscriberCode"
        fields = [f for f in publisher_fields if f != "publisherCode"] + [f for f in fields if f != "Publisher"]
    if tname not in tables:
        problems.append(f"LỆCH bảng: {tname} (A.3) không có trong DDL")
        continue
    cols = set(re.findall(r"^\s+(\w+)\s+\w", tables[tname], re.M))
    for f in fields:
        sc = snake(f)
        if (tname, sc) in EXCEPT:
            alt = EXCEPT[(tname, sc)]
            if alt and alt not in cols:
                problems.append(f"LỆCH cột ngoại lệ {tname}.{alt}")
            continue
        if sc not in cols:
            problems.append(f"LỆCH cột: {tname}.{sc} (trường {f}) không có")
    if tname == "publisher":
        publisher_fields = fields

# Bảng phụ ghi ở A.3
for extra in ["dlq_payload", "comm_type_setting", "routing_mode_setting", "outbox_event"]:
    if extra not in tables:
        problems.append(f"LỆCH bảng phụ {extra} không có")

# 3. Giá trị UPPER_SNAKE trong DDL nhưng không có ở FRS
frs_tokens = set(re.findall(r"`([A-Z][A-Z0-9_]+)`", appx))
ddl_tokens = set()
for body in tables.values():
    for m in re.finditer(r"IN \(([^)]*)\)", body):
        ddl_tokens |= set(re.findall(r"'([A-Z][A-Z0-9_]{2,})'", m.group(1)))
for t in sorted(ddl_tokens - frs_tokens):
    problems.append(f"LỆCH: giá trị {t} trong DDL không có ở phụ lục A")

print(f"Đã đối chiếu {sum(len(t) for _, t in ENUMS)} cột enum, {len(JSON_ENUMS)} enum trong JSON, {len(tables)} bảng")
for p in problems:
    print(p)
print("Sạch: DDL khớp phụ lục A" if not problems else f"{len(problems)} lệch")
sys.exit(1 if problems else 0)
