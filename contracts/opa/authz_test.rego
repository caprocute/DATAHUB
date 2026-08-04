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
