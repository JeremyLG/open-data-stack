resource "google_compute_instance" "lightdash_instance" {
  name                    = "${var.project}-lightdash"
  machine_type            = local.lightdash_machine_type
  project                 = var.project
  metadata_startup_script = file("../scripts/lightdash.sh")

  depends_on = [
    google_project_service.services,
  ]

  boot_disk {
    initialize_params {
      image = data.google_compute_image.debian_image.self_link
      size  = 50
      type  = "pd-balanced"
    }
  }
  network_interface {
    network = "default"
    access_config {
      network_tier = "PREMIUM"
    }
  }
}

