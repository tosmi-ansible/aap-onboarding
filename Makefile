POLICY_DIR := policies/

.PHONY: load-policies
load-policies: ## Load all policies onto the deployed OPA server
	@echo "Loading policies onto OPA server..."
	@OPA_URL=$$(oc get route -n opa-server opa -o jsonpath='{.spec.host}') && \
	echo "OPA URL: $$OPA_URL" && \
	for policy in `find $(POLICY_DIR)/*.rego ! -name '*_test.rego'`; do \
		policy_name=$$(basename "$$policy" .rego); \
		echo "Policy file: $$policy"; \
		echo "Policy name: $$policy_name"; \
		if curl -s -w "%{http_code}" -X PUT "http://$$OPA_URL/v1/policies/$$policy_name" \
			-H "Content-Type: text/plain" \
			--data-binary @$$policy | grep -q "200"; then \
			echo " ✓ Successfully loaded policy"; \
		else \
			echo " ✗ Failed to load policy"; \
		fi; \
	done


# Help and Documentation
.PHONY: help
help: ## Show this help message
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@awk '/^[a-zA-Z\-_0-9%]+:/ { \
		helpMessage = match($$0, /^([^:]+):[^#]*## (.+)/); \
		if (helpMessage) { \
			helpCommand = substr($$0, 1, index($$0, ":")-1); \
			helpMessage = substr($$0, index($$0, "##") + 3); \
			printf "  %-20s %s\n", helpCommand, helpMessage; \
		} \
	}' $(MAKEFILE_LIST) | sort
