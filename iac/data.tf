data "google_project" "data_project" {
}

data "google_compute_image" "debian_image" {
  family  = "debian-10"
  project = "debian-cloud"
}
