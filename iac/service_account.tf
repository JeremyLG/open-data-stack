# Bigquery Owner
resource "google_service_account" "bigquery_owner" {
  account_id = "bigquery-owner"
  project    = var.project
}

# Airbyte service account
resource "google_service_account" "airbyte_sa" {
  account_id   = "airbyte"
  project      = var.project
  display_name = "Airbyte Service Account"
  description  = "Airbyte service account"
}
# Airbyte service account key
resource "google_service_account_key" "airbyte_sa_key" {
  service_account_id = google_service_account.airbyte_sa.name
  public_key_type    = "TYPE_X509_PEM_FILE"
}

# dbt service account
resource "google_service_account" "dbt_sa" {
  account_id   = "dbt-runner"
  project      = var.project
  display_name = "dbt Service Account"
  description  = "dbt service account"
}
# dbt service account key
resource "google_service_account_key" "dbt_sa_key" {
  service_account_id = google_service_account.dbt_sa.name
  public_key_type    = "TYPE_X509_PEM_FILE"
}

# Lightdash service account
resource "google_service_account" "lightdash_sa" {
  account_id   = "lightdash"
  project      = var.project
  display_name = "Lightdash Service Account"
  description  = "Lightdash service account"
}
# Lightdash service account key
resource "google_service_account_key" "lightdash_sa_key" {
  service_account_id = google_service_account.lightdash_sa.name
  public_key_type    = "TYPE_X509_PEM_FILE"
}

# Lightdash service account
resource "google_service_account" "github-actions_sa" {
  account_id   = "github-actions"
  project      = var.project
  display_name = "CI/CD Service Account"
  description  = "CI/CD service account"
}
