terraform {
  backend "s3" {
    bucket = "terraform-state"
    key    = "infra/terraform.tfstate"
    region = "us-east-1"
    
    # Nova sintaxe para remover o Warning
    endpoints = {
      s3 = "http://192.168.178.31:9000"
    }

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
  }
}

provider "kubernetes" {
  config_path = "/etc/rancher/k3s/k3s.yaml"
}

# Mantemos o recurso para testar a migração
resource "kubernetes_namespace" "sprint3" {
  metadata {
    name = "automacao-github-actions"
  }
}