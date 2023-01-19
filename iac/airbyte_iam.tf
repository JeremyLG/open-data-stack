locals {
  airbyte_roles = toset([
    "bigquery.dataEditor",
    "bigquery.user"
  ])
}

resource "google_service_account" "airbyte_sa" {
  account_id   = "airbyte"
  project      = var.project
  display_name = "Airbyte Service Account"
  description  = "Airbyte service account"
}

resource "google_project_iam_member" "sa_iam_airbyte" {
  for_each = local.airbyte_roles
  project  = var.project
  role     = "roles/${each.key}"
  member   = "serviceAccount:${google_service_account.airbyte_sa.email}"
}

resource "google_iap_tunnel_instance_iam_member" "airbyte_iap" {
  provider = google-beta
  instance = google_compute_instance.airbyte_instance.name
  zone     = var.zone
  role     = "roles/iap.tunnelResourceAccessor"
  member   = "user:${var.google_account}"
}
