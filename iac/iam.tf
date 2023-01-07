resource "google_project_iam_member" "sa_iam_airbyte" {
  for_each = local.elt_roles
  project  = var.project
  role     = "roles/${each.key}"
  member   = "serviceAccount:${google_service_account.airbyte_sa.email}"
}

resource "google_project_iam_member" "sa_iam_dbt" {
  for_each = local.elt_roles
  project  = var.project
  role     = "roles/${each.key}"
  member   = "serviceAccount:${google_service_account.dbt_sa.email}"
}

