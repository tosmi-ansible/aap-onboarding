package policies

# Default policy response indicating allowed status with no violations
default jt_naming_validation := {
	"allowed": true,
	"violations": [],
}

# Validate that job template name has correct organization and project name prefixes
jt_naming_validation := result if {
	# Extract values from input
	org_name := object.get(input, ["organization", "name"], "")
	jt_name := object.get(input, ["job_template", "name"], "")

	# Construct the expected prefix
	# expected_prefix := concat("-", [org_name])

	# Check if job template name starts with expected prefix
	# not startswith(jt_name, expected_prefix)

	not regex.match(`^\d{2}-\w+-.+`, jt_name)

	result := {
		"allowed": false,
		"violations": [sprintf("Job template naming for '%v' does not follow <id>-<org>-<rest>", [jt_name])],
	}
}

jt_naming_validation := result if {
	org_name := object.get(input, ["organization", "name"], "")
	jt_name := object.get(input, ["job_template", "name"], "")

	jt_parts := split(jt_name, "-")

	not jt_parts[1] == org_name

	result := {
		"allowed": false,
		"violations": [sprintf("Job template naming for '%v' does not follow <id>-<org>-<rest>", [jt_name])],
	}
}
