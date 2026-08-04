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
