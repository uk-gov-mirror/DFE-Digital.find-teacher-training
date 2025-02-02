ifndef VERBOSE
.SILENT:
endif

IMAGE=${DOCKER_IMAGE}

.PHONY: help
help: ## Show this help
	@grep -E '^[a-zA-Z\.\-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: webpacker-compile
webpacker-compile: ## Run webpack
		docker run --rm ${IMAGE} rails webpacker:compile

.PHONY: rubocop
rubocop: ## Run ruby linter
		docker run --rm ${IMAGE} rubocop app config lib spec --format clang

.PHONY: lint-sass
lint-sass: ## Run sass linter
		docker run --rm ${IMAGE} scss-lint app/webpacker/styles

.PHONY: brakeman
brakeman: ## Run Brakeman static analysis
		docker run --rm ${IMAGE} brakeman

.PHONY: rspec
rspec: ## Run Ruby tests
		docker run -t -e RAILS_ENV=test --name find-rspec-runner ${IMAGE} \
		                  rspec --format RspecJunitFormatter --out rspec-results.xml --format documentation
		test_result=$$?
		docker cp find-rspec-runner:/app/coverage .
		docker cp find-rspec-runner:/app/rspec-results.xml .
		exit ${test_result}

.PHONY: js.test
js.test: ## Run Javascript tests
		docker run --name find-yarn-test-runner ${IMAGE} /bin/sh -c 'apk add yarn && yarn install --frozen-lockfile && yarn test --coverage'
		test_result=$$?
		docker cp find-yarn-test-runner:/app/coverage .
		exit ${test_result}

.PHONY: shell
shell: ## Shell into the container
		docker run -it --rm ${IMAGE} sh

.PHONY: publish.codeclimate
publish.codeclimate: ## Publish coverage to Code Climate
		curl -L https://codeclimate.com/downloads/test-reporter/test-reporter-latest-linux-amd64 > ./cc-test-reporter
		chmod +x ./cc-test-reporter
		./cc-test-reporter before-build
		# As the tests were run in the docker container the paths to the coverage are prefixed with "/app/"
		# So we need to replace it with the docker hosts current directory
		sed "s|\"/app/|\"`pwd`/|g" coverage/.resultset.json -i
		# Format the two different test coverage formats (SimpleCov anf lcov) to code climates json format
		./cc-test-reporter format-coverage --input-type simplecov --output coverage/rspec.json
		./cc-test-reporter format-coverage --input-type lcov --output coverage/javascript.json
		# Aggregate the two results to form a single result for our code base
		./cc-test-reporter sum-coverage --output 'coverage/total.json' coverage/javascript.json coverage/rspec.json
		# Upload the our test coverage to code climate
		./cc-test-reporter upload-coverage --input coverage/total.json

.PHONY: qa
qa: ## Set DEPLOY_ENV to qa
	$(eval DEPLOY_ENV=qa)
	$(eval env=qa)
	$(eval AZ_SUBSCRIPTION=s121-findpostgraduateteachertraining-development)
	$(eval space=bat-qa)


.PHONY: staging
staging: ## Set DEPLOY_ENV to staging
	$(eval DEPLOY_ENV=staging)
	$(eval env=staging)
	$(eval AZ_SUBSCRIPTION=s121-findpostgraduateteachertraining-test)
	$(eval space=bat-staging)

.PHONY: production
production: ## Set DEPLOY_ENV to production
	$(eval DEPLOY_ENV=production)
	$(eval env=prod)
	$(eval AZ_SUBSCRIPTION=s121-findpostgraduateteachertraining-production)
	$(eval space=bat-prod)

.PHONY: sandbox
sandbox: ## Set DEPLOY_ENV to production
	$(eval DEPLOY_ENV=sandbox)
	$(eval env=sandbox)
	$(eval AZ_SUBSCRIPTION=s121-findpostgraduateteachertraining-production)
	$(eval space=bat-prod)

.PHONY: plan
plan: ## Run terraform for ${DEPLOY_ENV} eg: make qa plan, make staging plan, make production plan
	$(eval export TF_VAR_paas_app_secrets_file=terraform/workspace_variables/app_secrets.yml)
	$(eval export TF_VAR_paas_app_config_file=terraform/workspace_variables/app_config.yml)
	az account set -s ${AZ_SUBSCRIPTION} && az account show
	terraform init -backend-config terraform/workspace_variables/${DEPLOY_ENV}_backend.tfvars terraform

.PHONY: deploy
deploy: ## Run terraform apply for ${DEPLOY_ENV} eg: make qa plan, make staging plan, make production plan
	$(eval export TF_VAR_paas_app_secrets_file=terraform/workspace_variables/app_secrets.yml)
	$(eval export TF_VAR_paas_app_config_file=terraform/workspace_variables/app_config.yml)
	az account set -s ${AZ_SUBSCRIPTION} && az account show
	terraform init -backend-config terraform/workspace_variables/${DEPLOY_ENV}_backend.tfvars terraform
	terraform apply -var-file terraform/workspace_variables/${DEPLOY_ENV}.tfvars terraform

.PHONY: install-fetch-config
install-fetch-config: ## Install the fetch-config script
	[ ! -f bin/fetch_config.rb ] \
		&& curl -s https://raw.githubusercontent.com/DFE-Digital/bat-platform-building-blocks/master/scripts/fetch_config/fetch_config.rb -o bin/fetch_config.rb \
		&& chmod +x bin/fetch_config.rb \
		|| true

.PHONY: edit-app-secrets
edit-app-secrets: install-fetch-config ## Edit Find App Secrets
	. terraform/workspace_variables/$(DEPLOY_ENV).sh && bin/fetch_config.rb -s azure-key-vault-secret:$${TF_VAR_key_vault_name}/$${TF_VAR_key_vault_app_secret_name} \
		-e -d azure-key-vault-secret:$${TF_VAR_key_vault_name}/$${TF_VAR_key_vault_app_secret_name} -f yaml

.PHONY: print-app-secrets
print-app-secrets: install-fetch-config ## View Find App Secrets
	. terraform/workspace_variables/$(DEPLOY_ENV).sh && bin/fetch_config.rb -s azure-key-vault-secret:$${TF_VAR_key_vault_name}/$${TF_VAR_key_vault_app_secret_name} \
		-f yaml
.PHONY: console ## start a rails console, eg: make qa console
console:
	cf target -s ${space}
	cf ssh find-${env} -t -c "cd /app && /usr/local/bin/bundle exec rails c"
