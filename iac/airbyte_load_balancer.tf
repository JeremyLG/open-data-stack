### These resources are created only if you specify a personal DNS
### and you want to redirect your instances to an https subdomain like 
### airbyte.yourdns, for example airbyte.example.com

# Put our instance in an unmanaged instance group
resource "google_compute_instance_group" "airbyte" {
  zone        = var.zone
  name        = "airbyte"
  description = "Airbyte instance group"

  instances = [
    google_compute_instance.airbyte_instance.id,
  ]
  network = google_compute_network.airbyte.id

  named_port {
    name = "http8000"
    port = "8000"
  }
}

# Give access to airbyte VM for our load balancer
resource "google_compute_firewall" "airbyte-lb" {
  name          = "allow-loadbalancer-airbyte"
  direction     = "INGRESS"
  network       = google_compute_network.airbyte.id
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
  target_tags   = ["airbyte"]
  allow {
    protocol = "tcp"
    ports    = ["8000"]
  }
}

# Global adress IP for our DNS record creation
resource "google_compute_global_address" "airbyte" {
  name = "airbyte"
}

output "ipv4_lb_airbyte" {
  value = google_compute_global_address.airbyte.address
}


# Health check to our airbyte VM
resource "google_compute_health_check" "airbyte" {
  name               = "airbyte-health-check"
  timeout_sec        = 1
  check_interval_sec = 1
  http_health_check {
    port               = 8000
    port_specification = "USE_FIXED_PORT"
    proxy_header       = "NONE"
    request_path       = "/api/v1/health"
  }
}

# Enable IAP access on our HTTPS web app
resource "google_iap_client" "airbyte_client" {
  display_name = "Airbyte Client"
  brand        = google_iap_brand.project_brand.name
}

# Back-end for our load balancer
resource "google_compute_backend_service" "airbyte" {
  name                  = "airbyte-backend"
  protocol              = "HTTP"
  port_name             = "http8000"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  timeout_sec           = 30
  health_checks = [
    google_compute_health_check.airbyte.id
  ]
  backend {
    group           = google_compute_instance_group.airbyte.self_link
    balancing_mode  = "UTILIZATION"
    capacity_scaler = 1.0
  }
  iap {
    oauth2_client_id     = google_iap_client.airbyte_client.client_id
    oauth2_client_secret = google_iap_client.airbyte_client.secret
  }
}

resource "google_compute_url_map" "airbyte" {
  name            = "web-map-http-airbyte"
  default_service = google_compute_backend_service.airbyte.id
}

resource "google_compute_managed_ssl_certificate" "airbyte" {
  provider = google-beta
  name     = "airbyte"

  managed {
    domains = [
      "airbyte.${var.dns}"
    ]
  }
}

resource "google_compute_target_https_proxy" "airbyte" {
  name    = "airbyte-https-proxy"
  url_map = google_compute_url_map.airbyte.id
  ssl_certificates = [
    google_compute_managed_ssl_certificate.airbyte.name
  ]
}

resource "google_compute_global_forwarding_rule" "airbyte" {
  name                  = "http-content-rule-airbyte"
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_range            = "443"
  target                = google_compute_target_https_proxy.airbyte.id
  ip_address            = google_compute_global_address.airbyte.id
}

# IAP Policy for our airbyte web app https endpoint
# TODO retrieve users dynamically or via a group
data "google_iam_policy" "iap_airbyte" {
  binding {
    role = "roles/iap.httpsResourceAccessor"
    members = [
      "user:${var.google_account}"
    ]
  }
}

resource "google_iap_web_backend_service_iam_policy" "airbyte_policy" {
  project             = var.project
  web_backend_service = google_compute_backend_service.airbyte.name
  policy_data         = data.google_iam_policy.iap_airbyte.policy_data
}
