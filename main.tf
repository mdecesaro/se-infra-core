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

resource "kubernetes_config_map" "opencost_pricing" {
  metadata {
    name      = "pricing-configs"
    namespace = "opencost"
  }

  data = {
    "default.json" = jsonencode({
      "kind"             = "custom"
      "description"      = "Preços customizados para k3s local"
      "CPU"              = "21.90"   # Preço estimado por vCPU/hora em USD
      "RAM"              = "7.30"   # Preço estimado por GB/hora em USD
      "storage"          = "0.10" # Preço por GB/hora de disco
      "network"          = "0.00"
      "gpu"              = "0.00"
      "loadBalancerCost" = "0.00"   # Aqui resolvemos o erro de syntax do LB
    })
  }
}

# 1. Recurso Helm do OpenCost
resource "helm_release" "opencost" {
  name             = "opencost"
  repository       = "https://opencost.github.io/opencost-helm-chart"
  chart            = "opencost"
  namespace        = "opencost"
  create_namespace = true

  depends_on = [
    helm_release.prometheus,
    kubernetes_config_map.opencost_pricing
  ]

  # --- CONEXÃO COM PROMETHEUS ---
  set {
    name  = "opencost.exporter.prometheus_config.external_prometheus_url"
    value = "http://prometheus-server.prometheus-system.svc.cluster.local:80"
  }
  
  set {
    name  = "opencost.opencost.customPricing.provider"
    value = "custom"
  }

  # --- FIX PARA O PROBLEMA DO "UNALLOCATED" ---
  set {
    name  = "opencost.exporter.force_cluster_id"
    value = "true"
  }

  set {
    name  = "opencost.exporter.default_cluster_id"
    value = "pi-cluster"
  }

  set {
    name  = "opencost.exporter.prometheus_config.cluster_label"
    value = "" # Importante: Deixa vazio para ignorar o filtro de cluster nas queries
  }

  set {
    name  = "opencost.exporter.container_cpu_external_label"
    value = "container"
  }

  # --- CONFIGURAÇÃO DE CUSTOS ---
  set {
    name  = "opencost.customPricing.enabled"
    value = "true"
  }
  
  set {
    name  = "opencost.customPricing.configMapName"
    value = "pricing-configs"
  }

  set {
    name  = "opencost.exporter.default_resources_reserves"
    value = "true"
  }

  set {
    name  = "opencost.exporter.refresh_pricing_interval"
    value = "10s"
  }

  set {
    name  = "opencost.exporter.resolution"
    value = "1m"
  }

  # --- OTIMIZAÇÃO PARA O RASPBERRY PI (BACKEND) ---
  set {
    name  = "opencost.exporter.resources.requests.memory"
    value = "128Mi"
  }

  set {
    name  = "opencost.exporter.resources.limits.memory"
    value = "256Mi"
  }
}

# 2. Exposição da UI via NodePort
resource "kubernetes_service" "opencost_ui_public" {
  metadata {
    name      = "opencost-ui-public"
    namespace = "opencost"
  }
  spec {
    selector = {
      "app.kubernetes.io/name" = "opencost"
    }
    port {
      name        = "http-ui"
      port        = 9090       # Porta do Service
      target_port = 9090       # Porta da UI do OpenCost
      node_port   = 32090      # Acesso externo via IP_DO_PI:32090
    }
    type = "NodePort"
  }
}