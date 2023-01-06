resource "google_project_iam_binding" "sa_iam_bindings" {
  for_each = local.elt_roles
  project  = var.project
  role     = "roles/${each.key}"

  members = [
    "serviceAccount:${google_service_account.airbyte_sa.email}",
    "serviceAccount:${google_service_account.dbt_sa.email}",
  ]
}
