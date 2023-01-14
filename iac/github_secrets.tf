resource "github_actions_secret" "example_secret" {
  repository      = var.github_repo
  secret_name     = "ENV_FILE"
  plaintext_value = file("../.env.cicd")
}

resource "github_actions_secret" "project" {
  repository      = var.github_repo
  secret_name     = "PROJECT"
  plaintext_value = var.project
}

resource "github_actions_secret" "project_id" {
  repository      = var.github_repo
  secret_name     = "PROJECT_ID"
  plaintext_value = data.google_project.data_project.number
}
