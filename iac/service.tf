resource "google_project_service" "services" {
  project                    = var.project
  for_each                   = local.services
  service                    = "${each.key}.googleapis.com"
  disable_on_destroy         = false
  disable_dependent_services = true
}
