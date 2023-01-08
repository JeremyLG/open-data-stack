
resource "google_cloud_run_service" "dbt-serverless" {
  provider = google-beta
  location = var.region
  name     = "dbt-serverless"

  template {
    spec {
      containers {
        image ="${var.region}-docker.pkg.dev/${var.project}/${var.project}/dbt-serverless:1.2"
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


output "dbt-serverless_cloud_run" {
  value = google_cloud_run_service.dbt-serverless.status[0].url
}

resource "google_storage_bucket" "dbt_static_website" {
  name          = "dbt-static-docs-bucket"
  location      = "EU"
  storage_class = "COLDLINE"
  website {
    main_page_suffix = "index_merged.html"
    not_found_page   = "index_merged.html"
  }
}

# Make bucket public by granting allUsers READER access
resource "google_storage_bucket_access_control" "public_rule" {
  bucket = google_storage_bucket.dbt_static_website.id
  role   = "READER"
  entity = "allUsers"
}
