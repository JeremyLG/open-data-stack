resource "google_project_iam_member" "sa_iam_cicd" {
  for_each = local.cicd_roles
  project  = var.project
  role     = "roles/${each.key}"
  member   = "serviceAccount:${google_service_account.github-actions_sa.email}"
}

