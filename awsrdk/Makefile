SHELL=/bin/bash
VENV_DIR="venv"

RULE_NAME="PR-DS-P1-S3-Server-Side-Encryption"
RULE_DESCRIPTION="Config rule for remediating S3 Bucket server side encryption default not being set."
RULE_RESOURCE_TYPE="AWS::S3::Bucket"
RULE_RUNTIME="python3.8"
RULE_INPUT_PARAMETERS='{"infosec-approved-exceptions":[]}'

# Note this role needs to be made in advance!!!
RULE_ROLE_NAME="vci-tenant-infra-config-rule-$(RULE_NAME)"
RULE_ROLE_PATH="/transformers/"
# Note this list of policy ARNs will need to be adjusted to fit the requirements of your config rule.
# Note this is a starting point we will run access analyzer to generate a least privlege policy after initial development is complete.
RULE_ROLE_POLICY_ARNS= "arn:aws:iam::aws:policy/service-role/AWSConfigRole" "arn:aws:iam::aws:policy/AWSLambdaExecute" "arn:aws:iam::aws:policy/service-role/AmazonSSMAutomationRole" "arn:aws:iam::aws:policy/AmazonS3FullAccess"

define ASSUME_ROLE_POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "TrustAWSServicesToAssume",
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "config.amazonaws.com",
					"lambda.amazonaws.com",
          "ssm.amazonaws.com"
        ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
endef
export ASSUME_ROLE_POLICY

CLOUDFORMATION_PACKAGING_BUCKET_SUFFIX="cf-package"

REMEDIATION_ACTION="AWS-EnableS3BucketEncryption"
REMEDIATION_RETRIES=2
REMEDIATION_TIMEOUT=30
REMEDIATION_PARAMETERS="{\"BucketName\":{\"ResourceValue\":{\"Value\":\"RESOURCE_ID\"}}, \"AutomationAssumeRole\":{\"StaticValue\":{\"Values\":[{\"Fn::Sub\":\"arn:\$${AWS::Partition}:iam::\$${AWS::AccountId}:role$(RULE_ROLE_PATH)$(RULE_ROLE_NAME)\"}]}}}"

ANALYZER_NAME="$(RULE_ROLE_NAME)-analyzer"

define ANALYZER_CLOUDTRAIL_DETAILS
{
 "accessRole": "string: The ARN of the service role that IAM  Access  Analyzer  uses  to
              access  your CloudTrail trail and service last accessed informa-
              tion",
 "endTime": timestamp,
 "startTime": "2021-12-09T21:08:14+00:00 -- use this format",
 "trails": [
	 {
		 "allRegions": false,
		 "cloudTrailArn": "string: load me from lookup!",
		 "regions": ["us-east-1"]
	 }
	 ...
 ]
}
endef
export ANALYZER_CLOUDTRAIL_DETAILS



# TODO: remove is unused!
REMEDIATION_PARAMETERS_LIST = "BucketName.ResourceValue.Value|RESOURCE_ID" "AutomationAssumeRole.StaticValue.Values|[{\"Fn::Sub\":\"arn:\$${AWS::Partition}:iam::\$${AWS::AccountId}:role$(RULE_ROLE_PATH)$(RULE_ROLE_NAME)\"}]"
TEMPLATE_CLOUDFORMATION_TEMPLATE="config-rule-template.yaml"
INTERPOLATED_CLOUDFORMATION_TEMPLATE="interpolated-config-rule-template.yaml"



# The .PHONY line and help task allow parameterless make to display a self documenting help file based on the comments after each target.
.PHONY: help

help:
	@echo "$(REMEDIATION_PARAMETERS)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

usage:
	@echo "USAGE:"
	@echo " "
	@echo '   $$ make <target_name>'
	@echo " "
	@echo " Targets: "
	@echo " "
	@echo "  [help] - This target shows helpful hints and remediations for errors"
	@echo "           that can occour when using this make file."
	@echo " "
	@echo "  [python-version] - to see the python versions installed."
	@echo "                     Note: This make file uses python3 as the python executable(link)"
	@echo "                     due to the python executable(link) version is 2.7."
	@echo " "
	@echo "  [python-make-venv] - to setup the venv virtual environment in this directory"
	@echo "                       that scout will execute in."
	@echo " "
	@echo " "
	@echo "  [references] - to display links that were helpful in making this make file."
	@echo " "
	@echo "  [init] - to activate the venv virtual environment, install the required"
	@echo "                 pips, and then output the version."
	@echo " "


python-version: ## List python versions
	@python --version
	@python3 --version

python-make-venv:
	python3 -m venv ./$(VENV_DIR)

init: ## Initialize the python virtual environment with venv, and install pips.
	@source ./$(VENV_DIR)/bin/activate; \
	pip3 install rdk; \
	rdk --help; \

rdk-init: ## Run the AWS rdk libraries init function. Note here we are using the following flags:  --control-tower --config-bucket-exists-in-another-account --skip-code-bucket-creation
	@source ./$(VENV_DIR)/bin/activate; \
	pip3 install rdk; \
	echo "NOTE: The following flags are required when using and MPS vended account."; \
	echo "    --control-tower - This is used to skip recorder creation as MPS has the recorders locked down through SCP."; \
	echo "    --config-bucket-exists-in-another-account - This is used to indicate not to use the recoders s3 buckets account i.e. MPS"; \
	echo "    --skip-code-bucket-creation - This is used to skip the bucket creation for CloudFormation packaging as we use the Transformers supplied bucket suffixed by ${CLOUDFORMATION_PACKAGING_BUCKET_SUFFIX}"; \
	rdk init --control-tower --config-bucket-exists-in-another-account --skip-code-bucket-creation; \

rdk-create: ## Run the AWS rdk libraies create command that creates the rule using the supplied parameters.
	@source ./$(VENV_DIR)/bin/activate; \
	rdk create ${RULE_NAME} \
	--runtime ${RULE_RUNTIME} \
	--resource-type ${RULE_RESOURCE_TYPE} \
	--input-parameters ${RULE_INPUT_PARAMETERS} \
	--auto-remediate \
	--remediation-action ${REMEDIATION_ACTION} \
	--auto-remediation-retry-attempts ${REMEDIATION_RETRIES} \
	--auto-remediation-retry-time ${REMEDIATION_TIMEOUT} \
	--remediation-parameters ${REMEDIATION_PARAMETERS}; \

rdk-modify: ## Run the AWS rdk libraies modify command that modifies the rule using the supplied parameters.
	@source ./$(VENV_DIR)/bin/activate; \
	rdk modify ${RULE_NAME} \
	--runtime ${RULE_RUNTIME} \
	--resource-type ${RULE_RESOURCE_TYPE} \
	--input-parameters ${RULE_INPUT_PARAMETERS} \
	--auto-remediate \
	--remediation-action ${REMEDIATION_ACTION} \
	--auto-remediation-retry-attempts ${REMEDIATION_RETRIES} \
	--auto-remediation-retry-time ${REMEDIATION_TIMEOUT} \
	--remediation-parameters ${REMEDIATION_PARAMETERS}; \

rdk-deploy: ## Run the AWS rdk libraies deploy command that deploys the rule using the supplied parameters.
	@source ./$(VENV_DIR)/bin/activate; \
	echo "Looking up s3 bucket to deploy rdk assets to."; \
	$(eval CF_PACKAGING_BUCKET_NAME := $(shell aws s3api list-buckets --query="Buckets[?ends_with(Name,'${CLOUDFORMATION_PACKAGING_BUCKET_SUFFIX}')].Name" --output text)) \
	echo "  Found s3 Bucket [ ${CF_PACKAGING_BUCKET_NAME} ]"; \
	$(eval RULE_ROLE_ARN := $(shell aws iam get-role --role-name $(RULE_ROLE_NAME) --query "Role.Arn" --output text)) \
	echo "  Found Role ARN [ ${RULE_ROLE_ARN} ]"; \
	rdk deploy ${RULE_NAME} --custom-code-bucket ${CF_PACKAGING_BUCKET_NAME} --lambda-role-arn ${RULE_ROLE_ARN};

# rdk deploy ${RULE_NAME} --custom-code-bucket ${CF_PACKAGING_BUCKET_NAME} ;
# echo "PLEASE ADD THE FOLLOWING PARAMETER TO RDK DEPLOY: --lambda-role-arn <ROLE-ARN>"; \

rdk-undeploy: ## Run the AWS rdk libraies undeploy command that removes a deployment the rule using the supplied parameters.
	@source ./$(VENV_DIR)/bin/activate; \
	echo "Looking up s3 bucket where rdk assets are deployed to."; \
	$(eval CF_PACKAGING_BUCKET_NAME := $(shell aws s3api list-buckets --query="Buckets[?ends_with(Name,'${CLOUDFORMATION_PACKAGING_BUCKET_SUFFIX}')].Name" --output text)) \
	echo "  Found [ ${CF_PACKAGING_BUCKET_NAME} ]"; \
	rdk undeploy ${RULE_NAME} --custom-code-bucket ${CF_PACKAGING_BUCKET_NAME} ;
# echo "PLEASE ADD THE FOLLOWING PARAMETER TO RDK UNDEPLOY: --lambda-role-arn <ROLE-ARN>"; \

rdk-sample-ci: ## Run the AWS rdk libraies sample-ci command that generates the test models used by your rule.
	@source ./$(VENV_DIR)/bin/activate; \
	rdk sample-ci ${RULE_RESOURCE_TYPE};

rdk-logs: ## Run the AWS rdk libraies logs command that shows the logs for the rule you haev deployed.
	@source ./$(VENV_DIR)/bin/activate; \
	rdk logs ${RULE_NAME};

rdk-test: ## Run the AWS rdk libraies test-local command that showsruns the tests for this rule.
	@source ./$(VENV_DIR)/bin/activate; \
	rdk test-local ${RULE_NAME};

rdk-create-rule-template: ## TODO: remove if unused
	@source ./$(VENV_DIR)/bin/activate; \
	rdk create-rule-template -o "${RULE_NAME}-config-rule.yaml" ${RULE_NAME};

lookup-cf-package-bucket: ## This command is used to lookup the cloudformation deployment bucket.
	aws s3api list-buckets --query="Buckets[?ends_with(Name,'${CLOUDFORMATION_PACKAGING_BUCKET_SUFFIX}')].Name" --output text;

create-config-rule-role: ## Used to create the role this config rule needs for checks, lambda execution, ssm and resource access.
	aws iam	create-role --path "$(RULE_ROLE_PATH)" --role-name "$(RULE_ROLE_NAME)" \
		--assume-role-policy-document "$$ASSUME_ROLE_POLICY" \
		--description "Role for executing and remediating config rule: $(RULE_NAME)" \
		--tags "Key=vci:team,Value=transformers" "Key=vci:product,Value=transformers-tenant-infra" "Key=vci:contact,Value=transformers@vwcredit.com"; \
	for RULE_ROLE_POLICY_ARN in $(RULE_ROLE_POLICY_ARNS); do \
		aws iam	attach-role-policy --role-name "$(RULE_ROLE_NAME)" \
				--policy-arn "$$RULE_ROLE_POLICY_ARN"; \
	done; \

delete-config-rule-role: ## Detaches the config rule role policies and then deletes the role.
	for RULE_ROLE_POLICY_ARN in $(RULE_ROLE_POLICY_ARNS); do \
		aws iam	detach-role-policy --role-name "$(RULE_ROLE_NAME)" \
				--policy-arn "$$RULE_ROLE_POLICY_ARN"; \
	done; \
	aws iam	delete-role --role-name "$(RULE_ROLE_NAME)"; \


setup-accessanalyzer: ## Needs to be done in the vw-cred-infra-dev accounbt where the local cloudtrail s3 bucket is receiving events otherwise it does not have permissions
	@source ./$(VENV_DIR)/bin/activate; \
	$(eval RULE_ROLE_ARN := $(shell aws iam get-role --role-name $(RULE_ROLE_NAME) --query "Role.Arn" --output text)) \
	echo "  Found RULE_ROLE_ARN [ ${RULE_ROLE_ARN} ]"; \
	$(eval ANALYZER_LIST := $(shell aws accessanalyzer list-analyzers --query "analyzers[*].arn" --output text)) \
	echo "  Checking for analyzers - [$(ANALYZER_LIST)]"; \
	@if [ -z "$(ANALYZER_LIST)" ]; then \
		echo "  Creating analyzer ... [$(RULE_ROLE_NAME)-analyzer]"; \
		$(eval ANALYZER_ARN := $(shell aws accessanalyzer create-analyzer --analyzer-name "$(ANALYZER_NAME)" --type ACCOUNT --output text)); \
	else \
			echo "   Unexpected Error: Existing analyzers found - [$(ANALYZER_LIST)]"; \
	fi


# ifeq ($(strip $(ANALYZER_LIST)),)
# echo "  Creating analyzer ... [$(RULE_ROLE_NAME)-analyzer]"; \
# $(eval ANALYZER_ARN := $(shell aws accessanalyzer create-analyzer --analyzer-name "$(ANALYZER_NAME)" --type ACCOUNT --output text)) \
# echo "  Found ANALYZER_ARN [ ${ANALYZER_ARN} ]"; \
# else
# echo "   Unexpected Error: Existing analyzers found - [$(ANALYZER_LIST)]"; \
# endif

scan-role-accessanalyzer:
	@source ./$(VENV_DIR)/bin/activate; \
	$(eval ANALYZER_ARN := $(shell aws accessanalyzer get-analyzer --analyzer-name $(ANALYZER_NAME) --query "analyzer.arn" --output text)) \
	echo "  Found ANALYZER_ARN [ ${ANALYZER_ARN} ]"; \
	$(eval PREVIEW_ID := $(shell aws accessanalyzer create-access-preview \
	          --analyzer-arn $ANALYZER_ARN \
	          --configurations )) \
	echo "  Found PREVIEW_ID [ ${PREVIEW_ID} ]"; \


accessanalyzer-generate-policy:
	@source ./$(VENV_DIR)/bin/activate; \
	$(eval RULE_ROLE_ARN := $(shell aws iam get-role --role-name $(RULE_ROLE_NAME) --query "Role.Arn" --output text)) \
	$(eval ANALYZER_JOB_ID := $(shell aws accessanalyzer start-policy-generation \
		 --cloud-trail-details $(ANALYZER_CLOUDTRAIL_DETAILS) \
		 --policy-generation-details "principalArn=$RULE_ROLE_ARN")) \


accessanalyzer-get-generated-policy:
	@source ./$(VENV_DIR)/bin/activate; \
	$(eval RULE_ROLE_ARN := $(shell aws iam get-role --role-name $(RULE_ROLE_NAME) --query "Role.Arn" --output text)) \
	$(eval ANALYZER_JOB_ID := $(shell aws accessanalyzer list-policy-generations --principal-arn $(RULE_ROLE_ARN) --query "policyGenerations[*].jobId" --output text)) \
	$(eval ANALYZER_JOB_OUTPUT := $(shell aws accessanalyzer get-generated-policy --job-id $(ANALYZER_JOB_ID) \
		  --no-include-resource-placeholders \
			--no-include-service-level-template \
			--query "generatedPolicyResult.generatedPolicies[*].policy")) \
	echo "$(ANALYZER_JOB_OUTPUT)"


# echo "$(ANALYZER_JOB_OUTPUT)" | jq -R '.generatedPolicyResult.generatedPolicies[].policy'

# [--include-resource-placeholders | --no-include-resource-placeholders]
# [--include-service-level-template | --no-include-service-level-template]
# [--cli-input-json | --cli-input-yaml]
# [--generate-cli-skeleton <value>]

# aws accessanalyzer create-access-preview
#           --analyzer-arn ${ANALYZER_ARN}
#           --configurations

# aws accessanalyzer list-analyzers
# echo "  Issue found when trying accessanalyzer in the UI"; \
# echo "Invalid accessRole: Incorrect permissions assigned to access CloudTrail S3 bucket: infra-central-logs-bucket-kiydl316ogg0"
# --tags "Key=vci:team,Value=transformers" "Key=vci:product,Value=transformers-tenant-infra" "Key=vci:contact,Value=transformers@vwcredit.com" --output text)) \
# --tags "vci:team=transformers" "vci:product=transformers-tenant-infra" "vci:contact=transformers@vwcredit.com" --output text)) \
# --tags "Key=vci:team,Value=transformers" "Key=vci:product,Value=transformers-tenant-infra" "Key=vci:contact,Value=transformers@vwcredit.com"
# ifeq ($(strip $(ANALYZER_LIST)),)


convert-json-template-to-yaml: ## Converts the json template file to a yaml file.
	cat ${RULE_NAME}-config-rule.yaml | yq e --prettyPrint -

# setup-cf-template: # Abandoned idea of being able to interpolate into a CF templates - too many variavbles and decisions that need to be made and understood
# 	echo "  Using template [ ${TEMPLATE_CLOUDFORMATION_TEMPLATE} ]"; \
# 	yq eval '.Description = $(RULE_DESCRIPTION)' ${TEMPLATE_CLOUDFORMATION_TEMPLATE}>${INTERPOLATED_CLOUDFORMATION_TEMPLATE}; \
# 	yq eval -i '.Resources.ResourceConfigRule.Properties.ConfigRuleName = $(RULE_NAME)' ${INTERPOLATED_CLOUDFORMATION_TEMPLATE}; \
# 	yq eval -i '.Resources.ResourceConfigRule.Properties.Description = $(RULE_DESCRIPTION)' ${INTERPOLATED_CLOUDFORMATION_TEMPLATE}; \
# 	yq eval -i '.Resources.ResourceConfigRule.Properties.Scope.ComplianceResourceTypes = [$(RULE_RESOURCE_TYPE)]' ${INTERPOLATED_CLOUDFORMATION_TEMPLATE}; \
# 	yq eval -i '.Resources.ResourceConfigRuleRemediationConfiguration.Properties.TargetId = $(REMEDIATION_ACTION)' ${INTERPOLATED_CLOUDFORMATION_TEMPLATE}; \
#
# 	for REMEDIATION_PARAMETER in $(REMEDIATION_PARAMETERS_LIST); do \
# 		echo $${REMEDIATION_PARAMETER%|*}; \
# 		echo $${REMEDIATION_PARAMETER#*[|]}; \
# 		yq eval -i ".Resources.ResourceConfigRuleRemediationConfiguration.Properties.Parameters$${REMEDIATION_PARAMETER%|*} = \"$${REMEDIATION_PARAMETER#*[|]}\"" ${INTERPOLATED_CLOUDFORMATION_TEMPLATE}; \
# 	done; \
#
# 	# yq eval -i ".Resources.ResourceConfigRuleRemediationConfiguration.Properties.Parameters = \"$$REMEDIATION_PARAMETERS_YAML\"" ${INTERPOLATED_CLOUDFORMATION_TEMPLATE}; \
# 	#echo "$$REMEDIATION_PARAMETER"; \

references: ## Shows the references used when building this project.
	@echo "https://docs.python.org/3/library/venv.html"
	@echo "https://www.youtube.com/watch?v=7Iao8SR9Czg"
	@echo "https://www.youtube.com/watch?v=fBewaclMo2s"
	@echo "https://github.com/aws-samples/aws-iam-access-analyzer-samples"
	@echo "https://docs.aws.amazon.com/IAM/latest/UserGuide/access-analyzer-policy-generation.html#access-analyzer-policy-generation-cli"
