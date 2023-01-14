provider "google-beta" {
  project = var.project
  region  = var.region
  zone    = var.zone
}

provider "google" {
  project = var.project
  region  = var.region
  zone    = var.zone
}

provider "github" {
  token = var.github_token
  owner = var.github_owner
}
