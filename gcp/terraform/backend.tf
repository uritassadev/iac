provider "google" {
  project = var.project_id
  region = var.region
}
terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "~> 6.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.7"
    }
  }
  backend "gcs" {
    bucket = "uri-labs-gcs"
    prefix = "terraform-state/gcp"
  }  
}