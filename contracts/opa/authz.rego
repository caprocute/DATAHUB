# LGSP PEP stub — SRS-19 roles (W0)
package lgsp.authz

import future.keywords.if
import future.keywords.in

default allow := false

# Roles chuẩn tối thiểu (SRS-19)
known_roles := {
	"PLATFORM_ADMIN",
	"INTEGRATION_ADMIN",
	"INTEGRATION_REVIEWER",
	"INTEGRATION_DEVELOPER",
	"OPERATOR",
	# Cán bộ quản trị dữ liệu — chủ thể của PH-06…09 (SRS-19 §2, WP-31)
	"DATA_STEWARD",
}

allow if {
	input.action == "health.read"
}

allow if {
	input.action == "onboarding.approve"
	"INTEGRATION_REVIEWER" in input.roles
}

allow if {
	input.action == "onboarding.approve"
	"PLATFORM_ADMIN" in input.roles
}

allow if {
	input.action == "onboarding.submit"
	some r in input.roles
	r in {"INTEGRATION_DEVELOPER", "INTEGRATION_ADMIN", "PLATFORM_ADMIN"}
}

allow if {
	input.action == "catalog.read"
	count(input.roles) > 0
}

# WP-30 — lgsp-data module status (authenticated realm role)
data_status_actions := {
	"data.rdm.status",
	"data.mdm.status",
	"data.privacy.status",
	"data.dq.status",
}

allow if {
	input.action in data_status_actions
	count(input.roles) > 0
}

allow if {
	input.action in data_status_actions
	"PLATFORM_ADMIN" in input.roles
}

# WP-31 — PH-07 RDM (SRS-19 §3.4.7).
#
# Đọc danh mục: mọi vai trò đã xác thực (hàng PA…LD của bảng đều là R) — danh mục là
# dữ liệu tra cứu dùng chung, chặn đọc chỉ làm mọi phân hệ khác phải đi vòng.
allow if {
	input.action == "rdm.catalog.read"
	count(input.roles) > 0
}

# Sửa mục / phiên bản: chỉ DATA_STEWARD (CU) và PLATFORM_ADMIN (U).
# Cố ý **không** cho INTEGRATION_ADMIN: bảng SRS-19 để trống ô đó.
allow if {
	input.action == "rdm.entry.write"
	some r in input.roles
	r in {"DATA_STEWARD", "PLATFORM_ADMIN"}
}
