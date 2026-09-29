package lgsp.authz_test

import data.lgsp.authz

test_health_always_allowed if {
	authz.allow with input as {"action": "health.read", "roles": []}
}

test_approve_requires_reviewer if {
	authz.allow with input as {
		"action": "onboarding.approve",
		"roles": ["INTEGRATION_REVIEWER"],
	}
}

test_approve_denied_for_developer if {
	not authz.allow with input as {
		"action": "onboarding.approve",
		"roles": ["INTEGRATION_DEVELOPER"],
	}
}

test_submit_allowed_for_developer if {
	authz.allow with input as {
		"action": "onboarding.submit",
		"roles": ["INTEGRATION_DEVELOPER"],
	}
}

test_data_rdm_status_authenticated if {
	authz.allow with input as {
		"action": "data.rdm.status",
		"roles": ["INTEGRATION_DEVELOPER"],
	}
}

test_data_status_denied_without_roles if {
	not authz.allow with input as {
		"action": "data.mdm.status",
		"roles": [],
	}
}

test_data_privacy_status_platform_admin if {
	authz.allow with input as {
		"action": "data.privacy.status",
		"roles": ["PLATFORM_ADMIN"],
	}
}

# ---------- WP-31 · PH-07 RDM (SRS-19 §3.4.7) ----------

test_rdm_read_allowed_for_any_authenticated_role if {
	authz.allow with input as {
		"action": "rdm.catalog.read",
		"roles": ["OPERATOR"],
	}
}

test_rdm_read_denied_without_roles if {
	not authz.allow with input as {
		"action": "rdm.catalog.read",
		"roles": [],
	}
}

test_rdm_write_allowed_for_data_steward if {
	authz.allow with input as {
		"action": "rdm.entry.write",
		"roles": ["DATA_STEWARD"],
	}
}

test_rdm_write_allowed_for_platform_admin if {
	authz.allow with input as {
		"action": "rdm.entry.write",
		"roles": ["PLATFORM_ADMIN"],
	}
}

# Cổng chặn thật của WP-31: đọc được **không** kéo theo ghi được.
# Bảng SRS-19 để trống ô ghi của OPERATOR/INTEGRATION_* — test này giữ đúng điều đó.
test_rdm_write_denied_for_operator if {
	not authz.allow with input as {
		"action": "rdm.entry.write",
		"roles": ["OPERATOR"],
	}
}

test_rdm_write_denied_for_integration_admin if {
	not authz.allow with input as {
		"action": "rdm.entry.write",
		"roles": ["INTEGRATION_ADMIN"],
	}
}
