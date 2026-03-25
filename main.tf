# 1. Namespace dedicado para a Aplicação
resource "kubernetes_namespace" "ml_app" {
  metadata {
    # USANDO VARIÁVEL AQUI
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
            # USANDO INTERPOLAÇÃO DE VARIÁVEL
            value = "${var.pi_ip}:9000" 
          }
          env {
            name  = "MINIO_ACCESS_KEY"
            value = "admin" # Futuramente usaremos sensitive variables aqui
          }
          env {
            name  = "MINIO_SECRET_KEY"
            value = "senha_devops_123"
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