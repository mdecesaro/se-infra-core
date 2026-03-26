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

# 1. Instalar o Prometheus (O "Banco de Dados" de métricas)
resource "helm_release" "prometheus" {
  name             = "prometheus"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "prometheus"
  namespace        = "prometheus-system"
  create_namespace = true

  # Configuração "Light" para o Raspberry Pi não explodir
  set {
    name  = "server.persistentVolume.enabled"
    value = "false" # Usa memória temporária para não travar o SD Card
  }
  
  set {
    name  = "alertmanager.enabled"
    value = "false" # Desativa o que não é essencial
  }

  set {
    name  = "server.resources.requests.memory"
    value = "256Mi"
  }
}

resource "helm_release" "opencost" {
  name       = "opencost"
  repository = "https://opencost.github.io/opencost-helm-chart"
  chart      = "opencost"
  namespace  = "opencost"
  create_namespace = true

  depends_on = [helm_release.prometheus] # Só instala se o Prometheus estiver OK

  set {
    name  = "opencost.exporter.prometheus_config.external_prometheus_url"
    value = "http://prometheus-server.prometheus-system.svc.cluster.local"
  }
  
  # O OpenCost precisa saber o nome do seu cluster
  set {
    name  = "opencost.exporter.cluster_id"
    value = "pi-cluster"
  }

  # Configuração de recursos humilde para o Pi
  set {
    name  = "opencost.exporter.resources.requests.memory"
    value = "128Mi" # Olha a diferença! De 3Gi para 128Mi
  }

  set {
    name  = "opencost.exporter.resources.limits.memory"
    value = "256Mi"
  }
}
