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
