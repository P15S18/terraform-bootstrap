# Terraform Bootstrap for Remote State Backend

This project bootstraps enterprise-grade Terraform remote state infrastructure on AWS by creating:

* S3 bucket for Terraform state storage
* S3 versioning for rollback protection
* S3 encryption for secure state storage
* Public access block for security hardening
* Lifecycle rules for old state version cleanup
* DynamoDB table for Terraform state locking

---

# Project Structure

```bash
terraform-bootstrap/
│
├── provider.tf
├── main.tf
├── variables.tf
├── outputs.tf
├── terraform.tfvars
└── versions.tf
```

At bootstrap stage, Terraform state remains local because backend infrastructure does not yet exist.

---

# Terraform Version Configuration

## versions.tf

```hcl
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
```

---

# AWS Provider Configuration

## provider.tf

```hcl
provider "aws" {
  region = var.region
}
```

---

# Input Variables

## variables.tf

```hcl
variable "region" {
  default = "ap-south-1"
}

variable "bucket_name" {
  default = "company-terraform-state-prod-001"
}

variable "dynamodb_table_name" {
  default = "terraform-lock"
}
```

> Bucket name must be globally unique.

---

# Core Infrastructure

## main.tf

This creates production-ready Terraform backend infrastructure.

---

## Create S3 Bucket

```hcl
resource "aws_s3_bucket" "terraform_state" {
  bucket = var.bucket_name

  tags = {
    Name        = "Terraform State Bucket"
    Environment = "Shared"
  }
}
```

---

## Enable Versioning

Critical for state rollback and recovery.

```hcl
resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}
```

---

## Enable Encryption

Secures Terraform state metadata.

```hcl
resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
```

---

## Block Public Access

Prevents accidental exposure.

```hcl
resource "aws_s3_bucket_public_access_block" "public_block" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
```

---

## Lifecycle Rule

Automatically removes old state versions after 90 days.

```hcl
resource "aws_s3_bucket_lifecycle_configuration" "lifecycle" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    id     = "cleanup-old-versions"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}
```

---

## Create DynamoDB Lock Table

Used for Terraform state locking.

```hcl
resource "aws_dynamodb_table" "terraform_lock" {
  name         = var.dynamodb_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name = "Terraform Lock Table"
  }
}
```

---

# Outputs

## outputs.tf

```hcl
output "bucket_name" {
  value = aws_s3_bucket.terraform_state.bucket
}

output "dynamodb_table" {
  value = aws_dynamodb_table.terraform_lock.name
}
```

---

# Variable Values

## terraform.tfvars

```hcl
region              = "ap-south-1"
bucket_name         = "company-terraform-state-prod-001"
dynamodb_table_name = "terraform-lock"
```

---

# Initial Bootstrap Execution

Run once to create backend resources:

```bash
terraform init
terraform plan
terraform apply
```

---

# AWS Resources Created

## S3 Bucket

```bash
company-terraform-state-prod-001
```

Future Terraform state paths:

```bash
app/dev/terraform.tfstate
app/sit/terraform.tfstate
app/prod/terraform.tfstate
```

---

## DynamoDB Table

```bash
terraform-lock
```

---

# Using Remote Backend in Main Infrastructure

After bootstrap completes, configure backend in application Terraform projects:

```hcl
terraform {
  backend "s3" {
    bucket         = "company-terraform-state-prod-001"
    key            = "app/dev/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "terraform-lock"
  }
}
```

---

# Why These Feature
