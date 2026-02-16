package policies_test

import data.policies

test_matching_prefixes_allowed if {
	test_input := {
		"job_template": {"name": "00-tenant3-org-config"},
		"organization": {"name": "tenant3"},
	}
	policies.jt_naming_validation.allowed == true with input as test_input
}

test_matching_prefixes_not_allowed if {
	test_input := {
		"job_template": {"name": "00tenant3-org-config"},
		"organization": {"name": "tenant3"},
	}
	policies.jt_naming_validation.allowed == false with input as test_input
}

test_org_name_mismatch_not_allowed if {
	test_input := {
		"job_template": {"name": "00-tenant3-org-config"},
		"organization": {"name": "tenant4"},
	}
	policies.jt_naming_validation.allowed == false with input as test_input
}
