#!/usr/bin/env python3
"""Soát YAML đặc tả API (03-thiet-ke/api/**/*.yaml) những lỗi Spectral bỏ lọt.

1. Khóa trùng trong cùng một ánh xạ (YAML cho phép, giá trị sau đè giá trị trước).
2. Khóa "lạ" mang giá trị rỗng: dấu hiệu của ánh xạ dạng { description: a, b } mà
   phần sau dấu phẩy bị đọc thành một khóa mới. Mô tả có dấu phẩy phải đặt trong nháy.

    pip install pyyaml
    python3 datahub-docs/build/tools/kiem_tra_yaml.py
"""
from __future__ import annotations

import sys
from pathlib import Path

import yaml

DOCS = Path(__file__).resolve().parents[2]
API = DOCS / "03-thiet-ke" / "api"
loi: list[str] = []


class Loader(yaml.SafeLoader):
    pass


def ghep(loader: Loader, node: yaml.MappingNode, deep: bool = False):
    da_gap: dict = {}
    for k, v in node.value:
        key = loader.construct_object(k, deep=deep)
        try:
            hash(key)
        except TypeError:
            continue
        if key in da_gap:
            loi.append(f"{loader.tep}:{k.start_mark.line + 1}: khóa trùng `{key}` "
                       f"(lần đầu dòng {da_gap[key]})")
        else:
            da_gap[key] = k.start_mark.line + 1
        if (isinstance(key, str) and " " in key.strip() and isinstance(v, yaml.ScalarNode)
                and v.tag == "tag:yaml.org,2002:null" and node.flow_style):
            loi.append(f"{loader.tep}:{k.start_mark.line + 1}: khóa rỗng `{key.strip()}` trong "
                       "ánh xạ {...}: mô tả có dấu phẩy chưa đặt trong nháy?")
    return loader.construct_mapping(node, deep=deep)


Loader.add_constructor(yaml.resolver.BaseResolver.DEFAULT_MAPPING_TAG, ghep)

teps = sorted(API.glob("**/*.yaml"))
for tep in teps:
    ld = Loader(tep.read_text(encoding="utf-8"))
    ld.tep = str(tep.relative_to(DOCS))
    try:
        ld.get_single_data()
    except yaml.YAMLError as e:
        loi.append(f"{ld.tep}: không đọc được YAML: {e}")
    finally:
        ld.dispose()

for l in loi:
    print(f"::error::{l}")
print(f"{len(teps)} tệp YAML, {len(loi)} lỗi.")
sys.exit(1 if loi else 0)
