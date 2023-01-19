.PHONY: gcloud-init
gcloud-init: create-project create-bucket artifact ## gcloud initialization

.PHONY: create-folder
create-folder: ## Create the data folder
	@echo "[$@] :: creating folder"
	@gcloud resource-manager folders create \
		--display-name=$(FOLDER_NAME) \
		--organization=$(ORG_ID)
	@echo "[$@] :: folder creation is over."

.PHONY: create-project
create-project: ## Create the main gcp project
	@echo "[$@] :: creating project..."
	@echo "$(PROJECT)"
	# @if [ "$(FOLDER_ID)" != "" ]; then \
	# 	gcloud projects create $(PROJECT) --name=$(PROJECT) --folder=$(FOLDER_ID); \
	# elif [ "$(ORG_ID)" != "" ]; then \
	# 	gcloud projects create $(PROJECT) --name=$(PROJECT) --organization=$(ORG_ID); \
	# else \
	# 	gcloud projects create $(PROJECT) --name=$(PROJECT); \
	# fi;
	@echo "[$@] :: linking billing account to project..."
	@gcloud beta billing projects link $(PROJECT) --billing-account=$(BILLING_ID)
	@echo "[$@] :: project creation is over."

artifact: enable-ar create-ar

enable-ar: ## Enable the artifactregistry API
	@echo "[$@] :: enabling apis..."
	@gcloud services enable artifactregistry.googleapis.com --project $(PROJECT)
	@echo "[$@] :: api enabled"

create-ar: ## Create the artifactregistry repository necessary to store initial docker images
	@echo "[$@] :: creating repository..."
	@gcloud artifacts repositories create $(REPOSITORY_ID) \
		--project $(PROJECT) \
		--location $(REGION) \
		--repository-format docker \
		--description "Docker repository"
	@echo "[$@] :: repository created"

configure-docker:
	gcloud auth configure-docker --quiet $(REGION)-docker.pkg.dev

.PHONY: create-bucket
create-bucket: ## Create the deployment bucket necessary to store infrastructrue states
	@echo "[$@] :: creating bucket..."
	@gsutil ls -p $(PROJECT) gs://$(DEPLOY_BUCKET) 2>/dev/null || \
		gsutil mb -l EU -p $(PROJECT) gs://$(DEPLOY_BUCKET);
	@gsutil versioning set on gs://$(DEPLOY_BUCKET);
	@echo "[$@] :: bucket creation is over."

.PHONY: delete-project
delete-project: ## Delete the entire project
	@echo "[$@] :: deleting project..."
	@gcloud projects delete $(PROJECT)
	@echo "[$@] :: deletion is over."
