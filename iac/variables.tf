variable "billing_id" {
  type        = string
  description = "Your billing ID"
}

variable "folder_id" {
  type        = string
  description = "Your folder ID"
}

variable "org_id" {
  type        = string
  description = "Your organization ID"
}

variable "project" {
  type        = string
  description = "Your project"
}

variable "region" {
  type        = string
  description = "The region where to deploy your infrastructure"
}

variable "zone" {
  type        = string
  description = "The zone where to deploy your infrastructure"
}

variable "repository_id" {
  type        = string
  description = "The artifact registry repo of your project"
}

variable "github_owner" {
  type        = string
  description = "The github owner of your project"
}

variable "github_token" {
  type        = string
  sensitive   = true
  description = "The github token for your project"
}

variable "github_repo" {
  type        = string
  description = "The github repo of your project"
}
