SHELL := /bin/bash

include .env

.EXPORT_ALL_VARIABLES:

# ---------------------------------------------------------------------------------------- #
# -- < Variables > --
# ---------------------------------------------------------------------------------------- #
# -- access token to activate properly some APIs
# ACCESS_TOKEN    := $(shell gcloud auth print-access-token --project $(PROJECT))

# -- bucket definitions
DEPLOY_BUCKET   := $(PROJECT)-gcs-deploy

# ---------------------------------------------------------------------------------------- #
# -- < Feedback > --
# ---------------------------------------------------------------------------------------- #
# -- display environment variables only on local environment
ifeq ($(RUN_FROM), local)
$(info $(shell printf "=%.s" $$(seq 100)))

$(info BILLING_ID        = $(BILLING_ID))
$(info FOLDER_ID         = $(FOLDER_ID))
$(info ORG_ID            = $(ORG_ID))
$(info PROJECT           = $(PROJECT))
$(info ZONE              = $(ZONE))
$(info REGION            = $(REGION))
$(info DEPLOY_BUCKET     = $(DEPLOY_BUCKET))
$(info DBT_PROJECT       = $(DBT_PROJECT))
$(info DBT_DATASET       = $(DBT_DATASET))
$(info GITHUB_REPO       = $(GITHUB_REPO))

$(info $(shell printf "=%.s" $$(seq 100)))
endif

# ---------------------------------------------------------------------------------------- #
# This target will be called whenever make is called without any target. So this is the
# default target and must be the first declared.
# ---------------------------------------------------------------------------------------- #
define HERE_HELP
The available targets are:
--------------------------
help            Displays the current message
all             Initializes the application (project creation, bucket creation, docker upload and iac deployment)
create-project  Creates the main gcp project
create-bucket   Creates the deployment bucket necessary to store infrastructrue states
create-ar       Creates the artifactregistry repository necessary to store initial docker images
clean           Cleans all the files created by the setup process
dbt-init        Initializes a dbt project with credentials, profiles generation
dbt-build   	Builds the dbt serverless docker image
dbt-run         Runs the dbt serverless project through docker in local for testing
dbt-deploy   	Deploys the dbt serverless docker image to artifactregistry
airbyte-tunnel  Tunnels to the GCE Airbyte instance into our localhost:8002
airbyte-fuser   Kills the tunnel which was previously created for airbyte
ld-credentials  Creates the Lightdash credentials to upload on our GCP VM
ld-tunnel       Tunnels to the GCE Lightdash instance into our localhost:8003
ld-fuser        Kills the tunnel which was previously created for lightdash
iac-prepare     Prepares the terraform infrastructure by create the variable files
iac-plan        Produces the terraform plan to visualize what will be changed in the infrastructure
iac-deploy      Proceeds to the application of the terraform infrastructure
iac-clean       Cleans the intermediary terraform files to restart the process
reinit          Remove untracked files from the current git repository
delete-project  Delete the entire project
endef
export HERE_HELP

help:
	@echo "-- Welcome to the initialization setup help"
	@printf "=%.s" $$(seq 100)
	@echo ""
	@echo "$$HERE_HELP"
	@echo ""

# ---------------------------------------------------------------------------------------- #
# This target will perform the complete setup of the current repository.
# ---------------------------------------------------------------------------------------- #

all: create-project create-bucket create-ar dbt-deploy iac-clean iac-deploy

gcloud:
	gcloud projects add-iam-policy-binding $(PROJECT) \
		--member=user:$(ACCOUNT) \
		--role=roles/iam.serviceAccountTokenCreator

# -- This target triggers the creation of the necessary project
.PHONY: create-project
create-project:
	@echo "[$@] :: creating project..."
	@echo "$(PROJECT)"
	@gcloud projects create $(PROJECT) --name=$(PROJECT) --organization=$(ORG_ID) --folder=$(FOLDER_ID)
	@echo "[$@] :: linking billing account to project..."
	@gcloud beta billing projects link $(PROJECT) --billing-account=$(BILLING_ID)
	@echo "[$@] :: project creation is over."

create-ar:
	@echo "[$@] :: enabling apis..."
	@gcloud services enable artifactregistry.googleapis.com --project $(PROJECT)
	@echo "[$@] :: creating repository..."
	@gcloud artifacts repositories create $(REPOSITORY_ID) \
		--project $(PROJECT) \
		--location $(REGION) \
		--repository-format docker \
		--description "Docker repository"
	@echo "[$@] :: apis enabled"

# -- This target triggers the creation of the necessary buckets
.PHONY: create-bucket
create-bucket:
	@echo "[$@] :: creating bucket..."
	@gsutil ls -p $(PROJECT) gs://$(DEPLOY_BUCKET) 2>/dev/null || \
		gsutil mb -l EU -p $(PROJECT) gs://$(DEPLOY_BUCKET);
	@gsutil versioning set on gs://$(DEPLOY_BUCKET);
	@echo "[$@] :: bucket creation is over."

# -- This target triggers the deletion of the gcloud project
.PHONY: delete-project
delete-project:
	@echo "[$@] :: deleting project..."
	@gcloud projects delete $(PROJECT)
	@echo "[$@] :: deletion is over."

.PHONY: clean
clean: iac-clean

# ---------------------------------------------------------------------------------------- #
# Open data stack needed commands.
# ---------------------------------------------------------------------------------------- #
include includes/dbt.mk

airbyte-tunnel:
	@gcloud beta compute ssh --zone "$(ZONE)" "$(PROJECT)-airbyte"  --project "$(PROJECT)" -- -L 8002:localhost:8000 -N -f

airbyte-fuser:
	@fuser -k 8002/tcp

ld-credentials:
	@cd $(IAC_DIR) && terraform output dbt_sa_key | base64 --decode --ignore-garbage > ../credentials/lightdash-sa-creds.json

ld-tunnel:
	@gcloud beta compute ssh --zone "$(ZONE)" "$(PROJECT)-lightdash"  --project "$(PROJECT)" -- -L 8003:localhost:8080 -N -f

ld-fuser:
	@fuser -k 8003/tcp

# ---------------------------------------------------------------------------------------- #
# -- < IaC > --
# ---------------------------------------------------------------------------------------- #
# -- terraform variables declaration
IAC_DIR = iac/
DBT_DIR = $(DBT_PROJECT)/
TF_DIR = $(IAC_DIR).terraform/
TF_INIT  = $(TF_DIR)terraform.tfstate
TF_VARS  = $(IAC_DIR)terraform.tfvars
TF_PLAN  = $(IAC_DIR)tfplan
TF_STATE = $(wildcard $(IAC_DIR)*.tfstate $(TF_DIR)*.tfstate)
TF_FILES = $(wildcard $(IAC_DIR)*.tf)

# -- this target will clean the local terraform infrastructure
.PHONY: iac-clean
iac-clean:
	@echo "[$@] :: cleaning the infrastructure intermediary files"
	@rm -fr $(TF_PLAN) $(TF_VARS);
	@if [ ! -f $(IAC_DIR).iac-env ] || [ $$(cat $(IAC_DIR).iac-env || echo -n) != $(PROJECT) ]; then \
		echo "[$@] :: env has changed, removing also $(TF_DIR) and $(IAC_DIR).terraform.lock.hcl"; \
		rm -rf $(TF_DIR) $(IAC_DIR).terraform.lock.hcl; \
	fi;

	@echo "[$@] :: infrastructure cleaning DONE"

# -- this target will initialize the terraform initialization
.PHONY: iac-init
iac-init: $(TF_INIT) # provided for convenience
$(TF_INIT):
	@set -euo pipefail; \
	if [ ! -d $(TF_DIR) ]; then \
		function remove_me() { if (( $$? != 0 )); then rm -fr $(TF_DIR); fi; }; \
		trap remove_me EXIT; \
		echo "[iac-init] :: initializing terraform"; \
		echo "$(PROJECT)" > $(IAC_DIR).iac-env; \
		cd $(IAC_DIR) && terraform init \
			-backend-config=bucket=$(DEPLOY_BUCKET) \
			-backend-config=prefix=terraform-state/init \
			-input=false; \
	else \
		echo "[iac-init] :: terraform already initialized"; \
	fi;

# -- internal definition for easing changes
define HERE_TF_VARS
billing_id          = "$(BILLING_ID)"
folder_id           = "$(FOLDER_ID)"
org_id              = "$(ORG_ID)"
project             = "$(PROJECT)"
zone                = "$(ZONE)"
region              = "$(REGION)"
github_repo         = "$(GITHUB_REPO)"
github_owner        = "$(GITHUB_OWNER)"
github_token        = "$(GITHUB_TOKEN)"
repository_id       = "$(REPOSITORY_ID)"
endef
export HERE_TF_VARS

# -- this target will create the terraform.tfvars file
.PHONY: iac-prepare
iac-prepare: $(TF_VARS) # provided for convenience
$(TF_VARS): $(TF_INIT)
	@echo "[iac-prepare] :: generation of $(TF_VARS) file";
	@echo "$$HERE_TF_VARS" > $(TF_VARS);
	@echo "[iac-prepare] :: generation of $(TF_VARS) file DONE.";

# -- this target will create the tfplan file whenever the variables file and any *.tf
# file have changed
.PHONY: iac-plan iac-plan-clean
iac-plan-clean:
	@rm -f $(TF_PLAN)

iac-plan: iac-plan-clean $(TF_PLAN) # provided for convenience
$(TF_PLAN): $(TF_VARS) $(TF_FILES)
	@echo "[iac-plan] :: planning the iac in $(PROJECT)";
	@set -euo pipefail; \
	cd $(IAC_DIR) && terraform plan \
		-var-file $(shell basename $(TF_VARS)) \
		-out=$(shell basename $(TF_PLAN));
	@echo "[iac-plan] :: planning the iac for $(PROJECT) DONE.";

# -- this target will only trigger the iac of the current parent
.PHONY: iac-validate
iac-validate:
	@echo "[$@] :: validating the infrastructure for $(PROJECT)"
	@set -euo pipefail; \
	cd $(IAC_DIR) && terraform validate;
	@echo "[$@] :: infrastructure validated on $(PROJECT)"

# -- this target will only trigger the iac of the current parent
.PHONY: iac-sec
iac-sec:
	@echo "[$@] :: checking the infrastructure security for $(PROJECT)"
	@tfsec .
	@echo "[$@] :: security checked on $(PROJECT)"

# -- this target will only trigger the iac of the current parent
.PHONY: iac-version
iac-version:
	@cd $(IAC_DIR) && terraform -version

# -- this target will only trigger the iac of the current parent
.PHONY: iac-deploy
iac-deploy: iac-clean $(TF_PLAN)
	@echo "[$@] :: applying the infrastructure for $(PROJECT)"
	@set -euo pipefail; \
	cd $(IAC_DIR) && terraform apply -auto-approve -input=false $(shell basename $(TF_PLAN));
	@echo "[$@] :: infrastructure applied on $(PROJECT)"

# -- this target re-initializes the git working tree removing untracked and ignored files
.PHONY: reinit
reinit:
	@rm -rf $(IAC_DIR).terraform* $(IAC_DIR)terraform.tfstate* $(IAC_DIR)tfplan
