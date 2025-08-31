provider "aws" {
  region = "eu-central-1"
}
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
  backend "s3" {
    bucket = "uri-labs"
    key    = "terraform-state/terraform.tfstate"
    region = "eu-central-1"
  }  
}