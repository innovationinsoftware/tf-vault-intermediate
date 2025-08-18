variable "tfe_token" {
  description = "HCP Terraform API token"
  type        = string
  sensitive   = true
}

variable "organization_name" {
  description = "HCP Terraform organization name"
  type        = string
}

variable "aws_access_key_id" {
  description = "AWS Access Key ID"
  type        = string
  sensitive   = true
}

variable "aws_secret_access_key" {
  description = "AWS Secret Access Key"
  type        = string
  sensitive   = true
}
