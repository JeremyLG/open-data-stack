locals {
  services = toset(split("\n", trimspace(file("resources/services.txt"))))

  elt_roles = toset([
    "bigquery.admin"
  ])

  airbyte_machine_type = "e2-small"
  lightdash_machine_type = "e2-small"

  source_datasets = {
    # To add additional dataset, add values below in the format
    # dataset_name = "Dataset descriptions"
    generic_crm = "Raw data of our company from a Generic CRM"
  }
}
