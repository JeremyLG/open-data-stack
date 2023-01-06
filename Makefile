SHELL := /bin/bash

include .env

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
# -- display environment variables
$(info $(shell printf "=%.s" $$(seq 100)))

$(info BILLING_ID        = $(BILLING_ID))
$(info FOLDER_ID         = $(FOLDER_ID))
$(info ORG_ID            = $(ORG_ID))
$(info PROJECT           = $(PROJECT))
$(info ZONE              = $(ZONE))
$(info REGION            = $(REGION))
$(info DEPLOY_BUCKET     = $(DEPLOY_BUCKET))

$(info $(shell printf "=%.s" $$(seq 100)))

# ---------------------------------------------------------------------------------------- #
# This target will be called whenever make is called without any target. So this is the
# default target and must be the first declared.
# ---------------------------------------------------------------------------------------- #
define HERE_HELP
The available targets are:
--------------------------
help            Displays the current message
all             Initializes the application (project creation, bucket creation and iac deployment)
create-project  Creates the main gcp project
create-bucket   Creates the deployment bucket necessary to store infrastructrue states
clean           Cleans all the files created by the setup process
airbyte-tunnel  Tunnels to the GCE Airbyte instance into our localhost:8002
airbyte-fuser   Kills the tunnel which was previously created
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

all: create-project create-bucket iac-clean iac-deploy

# -- This target triggers the creation of the necessary project
.PHONY: create-project
create-project:
	@echo "[$@] :: creating project..."
	@echo "$(PROJECT)"
	@gcloud projects create $(PROJECT) --name=$(PROJECT) --organization=$(ORG_ID) --folder=$(FOLDER_ID)
	@echo "[$@] :: linking billing account to project..."
	@gcloud beta billing projects link $(PROJECT) --billing-account=$(BILLING_ID)
	@echo "[$@] :: project creation is over."

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

airbyte-tunnel:
	@gcloud beta compute ssh --zone "$(ZONE)" "$(PROJECT)-airbyte"  --project "$(PROJECT)" -- -L 8002:localhost:8000 -N -f

airbyte-fuser:
	@fuser -k 8002/tcp

lightdash-tunnel:
	@gcloud beta compute ssh --zone "$(ZONE)" "$(PROJECT)-lightdash"  --project "$(PROJECT)" -- -L 8003:localhost:8080 -N -f

lightdash-fuser:
	@fuser -k 8003/tcp

# ---------------------------------------------------------------------------------------- #
# -- < IaC > --
# ---------------------------------------------------------------------------------------- #
# -- terraform variables declaration
IAC_DIR = iac/
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

iac-plan: $(TF_PLAN) # provided for convenience
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
	@echo "[$@] :: infrastructure applied on $(PROJECT)"

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
