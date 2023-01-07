
resource "google_cloud_run_service" "dbt" {
  provider = google-beta
  location = var.region
  name     = "dbt"

  template {
    spec {
      containers {
        image ="${var.region}-docker.pkg.dev/${var.project}/${var.project}/dbt:latest"
        env {
          name  = "PROJECT"
          value = var.project
        }
        env {
          name  = "DBT_DATASET"
          value = "warehouse"
        }
        env {
          name  = "DBT_ENV"
          value = "dev"
        }
        resources {
          limits = {
            "cpu"  = "1000m"
            memory = "1Gi"
          }
        }

      }
      service_account_name  = google_service_account.dbt_sa.email
      container_concurrency = 1
      timeout_seconds       = 900
    }
  }
  autogenerate_revision_name = false

  traffic {
    percent         = 100
    latest_revision = true
  }
}


output "dbt_cloud_run" {
  value = google_cloud_run_service.dbt.status[0].url
}
