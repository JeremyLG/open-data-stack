locals {
  lightdash_roles = toset([
    "bigquery.dataViewer",
    "bigquery.jobUser"
  ])
}

resource "google_service_account" "lightdash_sa" {
  account_id   = "lightdash"
  project      = var.project
  display_name = "Lightdash Service Account"
  description  = "Lightdash service account"
}

resource "google_project_iam_member" "sa_iam_lightdash" {
  for_each = local.lightdash_roles
  project  = var.project
  role     = "roles/${each.key}"
  member   = "serviceAccount:${google_service_account.lightdash_sa.email}"
}

resource "google_service_account_key" "lightdash_sa_key" {
  service_account_id = google_service_account.lightdash_sa.name
  public_key_type    = "TYPE_X509_PEM_FILE"
}

output "lightdash_sa_key" {
  value     = google_service_account_key.lightdash_sa_key.private_key
  sensitive = true
}
