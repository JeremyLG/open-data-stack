# ---------------------------------------------------------------------------------------- #
# -- < Building dbt-serverless > --
# ---------------------------------------------------------------------------------------- #

dbt-init:
	@envsubst < credentials/profiles.yml.tmpl > credentials/profiles.yml
	@dbt init --profiles-dir $(DBT_PROFILES_DIR)/ -s $(DBT_PROJECT)
	@dbt debug --profiles-dir $(DBT_PROFILES_DIR)/ --project-dir $(DBT_PROJECT)/

dbt-build:
	@echo "[$@] :: building the Docker image"
	@set -euo pipefail; \
	docker build . \
		-f Dockerfile.dbt \
		--tag $(REGION)-docker.pkg.dev/$(PROJECT)/$(REPOSITORY_ID)/dbt-serverless:latest \
		--build-arg DBT_PROJECT=$(DBT_PROJECT) \
		--build-arg DBT_DATASET=$(DBT_DATASET) \
		--build-arg DBT_PROFILES_DIR=$(DBT_PROFILES_DIR)
	@echo "[$@] :: docker build is over."

dbt-run: dbt-init dbt-build
	@docker run \
		--rm \
		--interactive \
		--tty \
		-p 8080:8080 \
		-v "$(HOME)/.config/gcloud:/gcp/config:ro" \
		-v /gcp/config/logs \
		--env CLOUDSDK_CONFIG=/gcp/config \
		--env GOOGLE_APPLICATION_CREDENTIALS=/gcp/config/application_default_credentials.json \
		--env GOOGLE_CLOUD_PROJECT=$(PROJECT) \
		$(REGION)-docker.pkg.dev/$(PROJECT)/$(REPOSITORY_ID)/dbt-serverless:latest
	@docker rmi -f $$(docker images -f "dangling=true" -q)
	@docker volume prune -f

dbt-deploy: dbt-init dbt-build
	@echo "[$@] :: Pushing docker image"
	@docker push $(REGION)-docker.pkg.dev/$(PROJECT)/$(REPOSITORY_ID)/dbt-serverless:latest
	@echo "[$@] :: docker push is over."
