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
