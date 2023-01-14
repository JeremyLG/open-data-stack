ld-credentials: ## Create the Lightdash credentials to upload on our GCP VM
	@cd $(IAC_DIR) && terraform output lightdash_sa_key | base64 --decode --ignore-garbage > ../credentials/lightdash-sa-creds.json

ld-tunnel: ## Tunnel to the GCE Lightdash instance into our localhost:8003
	@gcloud beta compute ssh --zone "$(ZONE)" "$(PROJECT)-lightdash"  --project "$(PROJECT)" -- -L 8003:localhost:8080 -N -f

ld-fuser: ## Kill the tunnel which was previously created for lightdash
	@fuser -k 8003/tcp
