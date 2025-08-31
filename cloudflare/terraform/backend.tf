provider "cloudflare" {
  api_token = var.cf_token
}
terraform {
  cloud { 
    organization = "uri-labs" 
    workspaces { 
      name = "cloudflare" 
    } 
  }
  required_version = ">= 1.0"
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5"
    }
  }
}