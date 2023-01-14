locals {
  lightdash_machine_type = "e2-small"
  lightdash_roles = toset([
    "bigquery.dataViewer",
    "bigquery.jobUser"
  ])
}

resource "google_service_account" "lightdash_sa" {
  account_id   = "lightdash"
  project      = var.project
  display_name = "Lightdash Service Account"
  description  = "Lightdash service account"
}

resource "google_project_iam_member" "sa_iam_lightdash" {
  for_each = local.lightdash_roles
  project  = var.project
  role     = "roles/${each.key}"
  member   = "serviceAccount:${google_service_account.lightdash_sa.email}"
}

resource "google_service_account_key" "lightdash_sa_key" {
  service_account_id = google_service_account.lightdash_sa.name
  public_key_type    = "TYPE_X509_PEM_FILE"
}

resource "google_compute_instance" "lightdash_instance" {
  name                    = "lightdash"
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

