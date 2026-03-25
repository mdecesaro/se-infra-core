terraform {
  reqrired_version = ">= 1.0.0"

  backend "s3" {
    bucket                      = "terraform-state"
    key                         = "infra/terraform.tfstate"
    region                      = "us-east-1"
    endpoints                   = { s3 = "http://192.168.178.31:9000" }
    force_path_style            = true
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
  }

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
  }
}

provider "kubernetes" {
  config_path = "/etc/rancher/k3s/k3s.yaml"
}

provider "helm" {
  kubernetes {
    config_path = "/etc/rancher/k3s/k3s.yaml"
  }
}