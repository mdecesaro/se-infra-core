resource "kubernetes_deployment" "ml_backend" {
  metadata {
    name      = "ml-backend"
    namespace = kubernetes_namespace.ml_app.metadata[0].name
    labels = {
      app  = "ml-backend"
      tier = "inference"
      managed-by = "terraform"
    }
  }

  spec {
    replicas = var.ml_backend_replicas
    
    # Estratégia de Atualização: Garante que o serviço não caia durante o deploy
    strategy {
      type = "RollingUpdate"
      rolling_update {
        max_unavailable = "50%"
        max_surge       = "1"
      }
    }

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
          name  = "ml-api"
          image = "tiangolo/uvicorn-gunicorn-fastapi:python3.11-slim"
          
          port {
            container_port = 80
            name           = "http"
          }

          # Injeção de Variáveis de Ambiente
          env {
            name  = "MINIO_ENDPOINT"
            value = "http://${var.pi_ip}:9000" # Adicionado http:// para evitar erro de protocolo na SDK
          }
          env {
            name  = "MINIO_ACCESS_KEY"
            value = var.minio_access_key
          }
          env {
            name  = "MINIO_SECRET_KEY"
            value = var.minio_secret_key
          }

          # --- OS PONTOS QUE FALTAVAM PARA O 100% ---

          # 1. Recursos (FinOps): Requests e Limits bem definidos
          resources {
            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
            requests = {
              cpu    = var.ml_backend_cpu_request
              memory = var.ml_backend_memory_request
            }
          }

          # 2. Liveness Probe: Reinicia o pod se o Python travar (Deadlock)
          liveness_probe {
            http_get {
              path = "/"
              port = 80
            }
            initial_delay_seconds = 30 # Tempo para o modelo de ML carregar
            period_seconds        = 15
            timeout_seconds       = 5
          }

          # 3. Readiness Probe: Garante que o tráfego só chegue quando a API estiver pronta
          readiness_probe {
            http_get {
              path = "/"
              port = 80
            }
            initial_delay_seconds = 10
            period_seconds        = 5
          }

          # 4. Lifecycle: Dá tempo da API fechar conexões antes de morrer
          lifecycle {
            pre_stop {
              exec {
                command = ["/bin/sh", "-c", "sleep 10"]
              }
            }
          }
        }
      }
    }
  }
}