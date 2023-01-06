resource "google_bigquery_dataset" "source_datasets" {
  for_each                   = local.source_datasets
  dataset_id                 = each.key
  description                = each.value
  project                    = var.project
  location                   = var.region
  delete_contents_on_destroy = true

  depends_on = [
    google_project_service.services,
  ]

  access {
    role          = "OWNER"
    user_by_email = google_service_account.bigquery_owner.email
  }
  access {
    role          = "WRITER"
    user_by_email = google_service_account.airbyte_sa.email
  }
  access {
    role          = "WRITER"
    user_by_email = google_service_account.dbt_sa.email
  }
  access {
    role          = "READER"
    user_by_email = google_service_account.lightdash_sa.email
  }
}
