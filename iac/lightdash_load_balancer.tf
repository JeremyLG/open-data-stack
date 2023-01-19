### These resources are created only if you specify a personal DNS
### and you want to redirect your instances to an https subdomain like 
### lightdash.yourdns, for example lightdash.example.com

# Put our instance in an unmanaged instance group
resource "google_compute_instance_group" "lightdash" {
  zone        = var.zone
  name        = "lightdash"
  description = "lightdash instance group"

  instances = [
    google_compute_instance.lightdash_instance.id,
  ]
  network = google_compute_network.lightdash.id

  named_port {
    name = "http8080"
    port = "8080"
  }
}

# Give access to lightdash VM for our load balancer
resource "google_compute_firewall" "lightdash-lb" {
  name          = "allow-loadbalancerhttplightdash"
  direction     = "INGRESS"
  network       = google_compute_network.lightdash.id
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
  target_tags   = ["lightdash"]
  allow {
    protocol = "tcp"
    ports    = ["8080"]
  }
}

# Global adress IP for our DNS record creation
resource "google_compute_global_address" "lightdash" {
  name = "lightdash"
}

output "ipv4_lb_lightdash" {
  value = google_compute_global_address.lightdash.address
}

# Health check to our lightdash VM
resource "google_compute_health_check" "lightdash" {
  name               = "lightdash-health-check"
  timeout_sec        = 1
  check_interval_sec = 1
  http_health_check {
    port               = 8080
    port_specification = "USE_FIXED_PORT"
    proxy_header       = "NONE"
    request_path       = "/"
  }
}

# Enable IAP access on our HTTPS web app
resource "google_iap_client" "lightdash_client" {
  display_name = "Lightdash Client"
  brand        = google_iap_brand.project_brand.name
}

# Back-end for our load balancer
resource "google_compute_backend_service" "lightdash" {
  name                  = "lightdash-backend"
  protocol              = "HTTP"
  port_name             = "http8080"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  timeout_sec           = 30
  health_checks         = [google_compute_health_check.lightdash.id]
  backend {
    group           = google_compute_instance_group.lightdash.self_link
    balancing_mode  = "UTILIZATION"
    capacity_scaler = 1.0
  }
  iap {
    oauth2_client_id     = google_iap_client.lightdash_client.client_id
    oauth2_client_secret = google_iap_client.lightdash_client.secret
  }
}

resource "google_compute_url_map" "lightdash" {
  name            = "web-map-httplightdash"
  default_service = google_compute_backend_service.lightdash.id
}

resource "google_compute_managed_ssl_certificate" "lightdash" {
  provider = google-beta
  name     = "myservice-ssl-cert"

  managed {
    domains = [
      "lightdash.${var.dns}"
    ]
  }
}

resource "google_compute_target_https_proxy" "lightdash" {
  provider = google-beta
  name     = "lightdash-https-proxy"
  url_map  = google_compute_url_map.lightdash.id
  ssl_certificates = [
    google_compute_managed_ssl_certificate.lightdash.name
  ]
}

resource "google_compute_global_forwarding_rule" "lightdash" {
  name                  = "http-content-rule-lightdash"
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_range            = "443"
  target                = google_compute_target_https_proxy.lightdash.id
  ip_address            = google_compute_global_address.lightdash.id
}

# Lightdash IAP policy for our https webapp
# TODO retrieve users dynamically or via a group
data "google_iam_policy" "iap_lightdash" {
  binding {
    role = "roles/iap.httpsResourceAccessor"
    members = [
      "user:${var.google_account}"
    ]
  }
}

resource "google_iap_web_backend_service_iam_policy" "lightdash_policy" {
  project             = var.project
  web_backend_service = google_compute_backend_service.lightdash.name
  policy_data         = data.google_iam_policy.iap_lightdash.policy_data
}
