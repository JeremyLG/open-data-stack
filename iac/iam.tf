resource "google_project_iam_member" "sa_iam_airbyte" {
  for_each = local.elt_roles
  project  = var.project
  role     = "roles/${each.key}"
  member   = "serviceAccount:${google_service_account.airbyte_sa.email}"
}

resource "google_project_iam_member" "sa_iam_dbt" {
  for_each = local.dbt_roles
  project  = var.project
  role     = "roles/${each.key}"
  member   = "serviceAccount:${google_service_account.dbt_sa.email}"
}


resource "google_project_iam_member" "sa_iam_cicd" {
  for_each = local.cicd_roles
  project  = var.project
  role     = "roles/${each.key}"
  member   = "serviceAccount:${google_service_account.github-actions_sa.email}"
}

