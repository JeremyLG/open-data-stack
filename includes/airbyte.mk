airbyte-tunnel: ## Tunnel to the GCE Airbyte instance into our localhost:8002
	@gcloud beta compute ssh airbyte --tunnel-through-iap --zone "$(ZONE)" --project "$(PROJECT)" -- -L 0.0.0.0:8002:localhost:8000 -N -f

airbyte-fuser: ## Kill the tunnel which was previously created for airbyte
	@fuser -k 8002/tcp
