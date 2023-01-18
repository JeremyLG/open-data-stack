locals {
  dbt_roles = toset([
    "bigquery.dataEditor",
    "bigquery.user",
    "storage.objectAdmin"
  ])
}

resource "google_service_account" "dbt_sa" {
  account_id   = "dbt-runner"
  project      = var.project
  display_name = "dbt Service Account"
  description  = "dbt service account"
}

resource "google_project_iam_member" "sa_iam_dbt" {
  for_each = local.dbt_roles
  project  = var.project
  role     = "roles/${each.key}"
  member   = "serviceAccount:${google_service_account.dbt_sa.email}"
}

resource "google_cloud_run_service" "dbt-serverless" {
  provider = google-beta
  location = var.region
  name     = "dbt-serverless"

  template {
    metadata {
      annotations = {
        "run.googleapis.com/execution-environment" : "gen2"
      }
    }
    spec {
      containers {
        image = "${var.region}-docker.pkg.dev/${var.project}/${var.repository_id}/dbt-serverless:latest"
        env {
          name  = "GOOGLE_CLOUD_PROJECT"
          value = var.project
        }
        resources {
          limits = {
            "cpu"  = "1000m"
            memory = "2048Mi"
          }
        }

      }
      service_account_name = google_service_account.dbt_sa.email
      timeout_seconds      = 900
    }
  }
  autogenerate_revision_name = false

  traffic {
    percent         = 100
    latest_revision = true
  }

  depends_on = [
    google_project_service.services
  ]
}


output "dbt-serverless_cloud_run" {
  value = google_cloud_run_service.dbt-serverless.status[0].url
}

resource "google_storage_bucket" "dbt_static_website" {
  name          = "${var.project}-dbt-docs"
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
