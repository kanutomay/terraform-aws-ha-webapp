terraform {
  # Configure the S3 backend for storing Terraform state
  backend "s3" {
    encrypt      = true
    use_lockfile = true
  }
}
