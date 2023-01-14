# Bigquery Owner
resource "google_service_account" "bigquery_owner" {
  account_id = "bigquery-owner"
  project    = var.project
  display_name = "BigQuery Owner Service Account"
  description  = "BigQuery Owner service account"
}

# Github CI/CD Account
resource "google_service_account" "github-actions_sa" {
  account_id   = "github-actions"
  project      = var.project
  display_name = "CI/CD Service Account"
  description  = "CI/CD service account"
}
