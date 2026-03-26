output "ml_api_endpoint" {
  description = "URL para enviar inferências para a API de ML"
  value       = "http://${var.pi_ip}:30080"
}

output "opencost_ui_url" {
  description = "Painel de monitoramento de custos (FinOps)"
  value       = "http://${var.pi_ip}:32090"
}

output "minio_console_url" {
  description = "Interface do MinIO (S3 Local) para gestão de modelos"
  value       = "http://${var.pi_ip}:9000"
}

output "deployment_status" {
  description = "Namespace de produção criado"
  value       = kubernetes_namespace.ml_app.metadata[0].name
}