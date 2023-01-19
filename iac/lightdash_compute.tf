locals {
  lightdash_machine_type = "e2-small"
}

resource "google_compute_network" "lightdash" {
  name                    = "lightdash"
  provider                = google-beta
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "lightdash" {
  name          = "lightdash"
  provider      = google-beta
  ip_cidr_range = "10.0.0.0/16"
  region        = var.region
  network       = google_compute_network.lightdash.id
}

resource "google_compute_instance" "lightdash_instance" {
  name                    = "lightdash"
  machine_type            = local.lightdash_machine_type
  project                 = var.project
  metadata_startup_script = file("../scripts/lightdash.sh")
  allow_stopping_for_update = true

  depends_on = [
    google_project_service.services,
  ]

  metadata = {
    enable-oslogin = true
  }

  boot_disk {
    initialize_params {
      image = data.google_compute_image.debian_image.self_link
      size  = 50
      type  = "pd-balanced"
    }
  }
  network_interface {
    network    = google_compute_network.lightdash.id
    subnetwork = google_compute_subnetwork.lightdash.id
    access_config {
      network_tier = "PREMIUM"
    }
  }
  tags = ["lightdash"]
}
