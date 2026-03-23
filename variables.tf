variable "region" {
  default = "ap-south-1"
}

variable "bucket_name" {
  default = "company-terraform-state-prod-001"
}

variable "dynamodb_table_name" {
  default = "terraform-lock"
}
