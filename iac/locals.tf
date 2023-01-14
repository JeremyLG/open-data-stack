locals {
  services = toset(split("\n", trimspace(file("resources/services.txt"))))


  cicd_roles = toset(split("\n", trimspace(file("resources/cicd.txt"))))

  source_datasets = {
    # To add additional dataset, add values below in the format
    # dataset_name = "Dataset descriptions"
    generic_crm = "Raw data of our company from a Generic CRM"
  }
}
