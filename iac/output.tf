output "airbyte_sa_key" {
  value     = google_service_account_key.airbyte_sa_key.private_key
  sensitive = true
}

output "dbt_sa_key" {
  value     = google_service_account_key.dbt_sa_key.private_key
  sensitive = true
}

output "lightdash_sa_key" {
  value     = google_service_account_key.lightdash_sa_key.private_key
  sensitive = true
}
