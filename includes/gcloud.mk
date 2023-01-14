gcloud: ## totot
	gcloud projects add-iam-policy-binding $(PROJECT) \
		--member=user:$(ACCOUNT) \
		--role=roles/iam.serviceAccountTokenCreator

.PHONY: create-project
create-project: ## Create the main gcp project
	@echo "[$@] :: creating project..."
	@echo "$(PROJECT)"
	@gcloud projects create $(PROJECT) --name=$(PROJECT) --organization=$(ORG_ID) --folder=$(FOLDER_ID)
	@echo "[$@] :: linking billing account to project..."
	@gcloud beta billing projects link $(PROJECT) --billing-account=$(BILLING_ID)
	@echo "[$@] :: project creation is over."

create-ar: ## Create the artifactregistry repository necessary to store initial docker images
	@echo "[$@] :: enabling apis..."
	@gcloud services enable artifactregistry.googleapis.com --project $(PROJECT)
	@echo "[$@] :: creating repository..."
	@gcloud artifacts repositories create $(REPOSITORY_ID) \
		--project $(PROJECT) \
		--location $(REGION) \
		--repository-format docker \
		--description "Docker repository"
	@echo "[$@] :: apis enabled"

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
