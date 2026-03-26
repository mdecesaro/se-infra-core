# --- PROMETHEUS (O BANCO DE DADOS) ---
resource "helm_release" "prometheus" {
  name             = "prometheus"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "prometheus"
  namespace        = "prometheus-system"
  create_namespace = true

  set {
    name  = "server.persistentVolume.enabled"
    value = "false" 
  }
  
  set {
    name  = "alertmanager.enabled"
    value = "false"
  }

  set {
    name  = "server.resources.requests.memory"
    value = "256Mi"
  }
}

# --- OPENCOST (O ANALISADOR DE CUSTOS) ---
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

  set {
    name  = "opencost.exporter.prometheus_config.external_prometheus_url"
    value = "http://prometheus-server.prometheus-system.svc.cluster.local:80"
  }
  
  set {
    name  = "opencost.opencost.customPricing.provider"
    value = "custom"
  }

  set {
    name  = "opencost.exporter.force_cluster_id"
    value = "true"
  }

  set {
    name  = "opencost.exporter.default_cluster_id"
    value = "pi-cluster"
  }

  set {
    name  = "opencost.customPricing.enabled"
    value = "true"
  }
  
  set {
    name  = "opencost.customPricing.configMapName"
    value = "pricing-configs"
  }

  # Otimização de Performance
  set {
    name  = "opencost.exporter.resources.requests.memory"
    value = "128Mi"
  }

  set {
    name  = "opencost.exporter.resources.limits.memory"
    value = "256Mi"
  }
}

# --- EXPOSIÇÃO DA UI (NODEPORT) ---
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
      port        = 9090
      target_port = 9090
      node_port   = 32090
    }
    type = "NodePort"
  }
}