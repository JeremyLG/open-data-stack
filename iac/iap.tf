# Enable IAP only if you have a personal DNS and an organization
resource "google_iap_brand" "project_brand" {
  support_email     = var.google_account
  application_title = "Cloud IAP Protected Apps"
  project           = google_project_service.services["iap"].project
}
