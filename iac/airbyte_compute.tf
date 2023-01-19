locals {
  airbyte_machine_type = "e2-small"
}

resource "google_compute_network" "airbyte" {
  name                    = "airbyte"
  provider                = google-beta
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "airbyte" {
  name          = "airbyte"
  provider      = google-beta
  ip_cidr_range = "10.0.0.0/16"
  region        = var.region
  network       = google_compute_network.airbyte.id
}

resource "google_compute_firewall" "airbyte-iam-ssh" {
  project       = var.project
  name          = "allow-airbyte-ssh-from-iap"
  network       = google_compute_network.airbyte.id
  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["airbyte"]
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

resource "google_compute_instance" "airbyte_instance" {
  name                      = "airbyte"
  machine_type              = local.airbyte_machine_type
  project                   = var.project
  metadata_startup_script   = file("../scripts/airbyte.sh")
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
    network    = google_compute_network.airbyte.id
    subnetwork = google_compute_subnetwork.airbyte.id
    access_config {
      network_tier = "PREMIUM"
    }
  }
  tags = ["airbyte"]
}
