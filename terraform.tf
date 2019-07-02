terraform {
  required_version = ">= 0.12.0"
  backend "gcs" {
    bucket      = "jx-development-terraform05-terraform-state"
    prefix      = "dev"
  }
}