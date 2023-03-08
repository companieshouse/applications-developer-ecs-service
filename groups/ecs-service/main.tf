provider "aws" {
  region  = var.aws_region
  version = "~> 4.54.0"
}

terraform {
  backend "s3" {}
}
