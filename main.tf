# 1. Namespace dedicado para a Aplicação
resource "kubernetes_namespace" "ml_app" {
  metadata {
    name = var.namespace_ml 
  }
}

# 2. Deployment do Backend
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
          image = "python:3.11-slim"
          
          command = ["sleep", "infinity"]

          port {
            container_port = 8000
          }

          # Variáveis de ambiente usando a variável pi_ip
          env {
            name  = "MINIO_ENDPOINT"
            value = "${var.pi_ip}:9000" 
          }
          env {
            name  = "MINIO_ACCESS_KEY"
            value = var.minio_access_key
          }
          env {
            name  = "MINIO_SECRET_KEY"
            value = var.minio_secret_key
          }

          resources {
            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
            requests = {
              cpu    = "200m"
              memory = "256Mi"
            }
          }
        }
      }
    }
  }
}

# 3. Service
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

# Namespace dedicado para não misturar com o app de ML
resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "kubecost"
  }
}

# Instalação do analisador de custos
resource "helm_release" "kubecost" {
  name       = "kubecost"
  repository = "https://kubecost.github.io/cost-analyzer/"
  chart      = "cost-analyzer"
  version    = "3.0.0" # Versão estável e moderna
  namespace  = kubernetes_namespace.monitoring.metadata[0].name

  set {
    name  = "global.clusterId"
    value = "pi-cluster"
  }
  set {
    name  = "prometheus.server.resources.requests.cpu"
    value = "100m"
  }
  set {
    name  = "prometheus.server.resources.requests.memory"
    value = "256Mi"
  }
}

# Output para você não ter que decorar o comando de acesso
output "kubecost_ui" {
  value = "Acesse o painel com: kubectl port-forward --namespace kubecost deploy/kubecost-cost-analyzer 9090"
}