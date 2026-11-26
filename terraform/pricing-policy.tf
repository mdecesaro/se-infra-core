resource "kubernetes_config_map" "opencost_pricing" {
  metadata {
    name      = "pricing-configs"
    namespace = "opencost"
    # O Terraform criará o namespace se ele não existir através do depends_on no Helm
  }

  data = {
    "default.json" = jsonencode({
      "kind"             = "custom"
      "description"      = "Preços customizados para k3s local"
      "CPU"              = "21.90"
      "RAM"              = "7.30"
      "storage"          = "0.10"
      "network"          = "0.00"
      "gpu"              = "0.00"
      "loadBalancerCost" = "0.00"
    })
  }
}