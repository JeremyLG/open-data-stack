locals {
  airbyte_roles = toset([
    "bigquery.dataEditor",
    "bigquery.user"
  ])
  airbyte_machine_type   = "e2-small"
}

resource "google_service_account" "airbyte_sa" {
  account_id   = "airbyte"
  project      = var.project
  display_name = "Airbyte Service Account"
  description  = "Airbyte service account"
}

resource "google_project_iam_member" "sa_iam_airbyte" {
  for_each = local.airbyte_roles
  project  = var.project
  role     = "roles/${each.key}"
  member   = "serviceAccount:${google_service_account.airbyte_sa.email}"
}

resource "google_compute_instance" "airbyte_instance" {
  name                    = "airbyte"
  machine_type            = local.airbyte_machine_type
  project                 = var.project
  metadata_startup_script = file("../scripts/airbyte.sh")

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
