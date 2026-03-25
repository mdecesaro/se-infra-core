terraform {
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


locals {
  kube_config = "/etc/rancher/k3s/k3s.yaml"
}

provider "kubernetes" {
  config_path = local.kube_config
}

# --- Recursos da Sprint 3 ---
resource "kubernetes_namespace" "sprint3" {
  metadata {
    name = "automacao-github-actions"
  }
}

# --- Recursos da Sprint 4 (Terreno do Backend ML) ---

# 1. Namespace dedicado para a Aplicação
resource "kubernetes_namespace" "ml_app" {
  metadata {
    name = "ml-production"
  }
}

# 2. Deployment do Backend (O "Berço")
resource "kubernetes_deployment" "ml_backend" {
  metadata {
    name      = "ml-backend"
    namespace = kubernetes_namespace.ml_app.metadata[0].name
    labels = {
      app = "ml-backend"
    }
  }

  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "ml-backend"
      }
    }

    template {
      metadata {
        labels = {
          app = "ml-backend"
        }
      }

      spec {
        container {
          name  = "backend-container"
          # Imagem Placeholder até criarmos a nossa oficial no GHCR
          image = "python:3.11-slim"
          
          # Comando para manter o pod vivo sem dar erro de 'crash'
          command = ["sleep", "infinity"]

          port {
            container_port = 8000
          }

          # Variáveis de ambiente para conexão com o MinIO
          env {
            name  = "MINIO_ENDPOINT"
            value = "192.168.178.31:9000"
          }
          env {
            name  = "MINIO_ACCESS_KEY"
            value = "admin"
          }
          env {
            name  = "MINIO_SECRET_KEY"
            value = "senha_devops_123"
          }

          resources {
            limits = {
              cpu    = "0.5"
              memory = "512Mi"
            }
            requests = {
              cpu    = "0.2"
              memory = "256Mi"
            }
          }
        }
      }
    }
  }
}

# 3. Service (Exposição via IP do Pi)
resource "kubernetes_service" "ml_backend_svc" {
  metadata {
    name      = "ml-backend-service"
    namespace = kubernetes_namespace.ml_app.metadata[0].name
  }
  spec {
    selector = {
      app = "ml-backend"
    }
    type = "NodePort"
    port {
      port        = 80
      target_port = 8000
      node_port   = 30080
    }
  }
}


# RECURSO DE TESTE: Simula um disco na AWS para ver o Infracost calcular
resource "kubernetes_persistent_volume_claim" "teste_custo" {
  metadata {
    name = "disco-de-teste"
    namespace = kubernetes_namespace.ml_app.metadata[0].name
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "100Gi" # O Infracost vai precificar esse storage!
      }
    }
    # Dica para o Infracost tratar como um disco pago (GP2 da AWS)
    storage_class_name = "gp2" 
  }
}