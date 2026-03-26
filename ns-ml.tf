resource "kubernetes_namespace" "ml_app" {
  metadata {
    name = var.namespace_ml 

    labels = {
      name        = var.namespace_ml
      team        = var.team_name
      managed-by  = "terraform"
      # Este label abaixo permite filtrar faturas no OpenCost depois
      cost-center = "ml-research" 
    }
  }
}