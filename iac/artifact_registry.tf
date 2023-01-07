resource "google_artifact_registry_repository" "docker" {
  provider      = google-beta
  location      = var.region
  repository_id = var.project
  description   = "Docker repository"
  format        = "DOCKER"
}
