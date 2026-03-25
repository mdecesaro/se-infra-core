output "kubecost_ui_command" {
  value       = "kubectl port-forward --namespace ${var.namespace_monitoring} deploy/kubecost-cost-analyzer 9090"
  description = "Execute este comando no seu terminal para abrir o painel de custos"
}

output "ml_namespace" {
  value = kubernetes_namespace.ml_app.metadata[0].name
}