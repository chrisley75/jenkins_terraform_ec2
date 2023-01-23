terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 3.74.1"
    }
  }

  backend "s3" {
    bucket = "cley-tfstate-bucket"
    key    = "cley-infra-tfstate"
    region = "eu-west-3"
  }
}

provider "aws" {
  region = "eu-west-3"
}



module "s3-bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "2.6.0"
  bucket  = var.ansible_bucket

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
  force_destroy           = true
}
