airbyte-tunnel: ## Tunnel to the GCE Airbyte instance into our localhost:8002
	@gcloud beta compute ssh --zone "$(ZONE)" "$(PROJECT)-airbyte"  --project "$(PROJECT)" -- -L 8002:localhost:8000 -N -f

airbyte-fuser: ## Kill the tunnel which was previously created for airbyte
	@fuser -k 8002/tcp
