resource "kubernetes_service" "ml_backend_svc" {
  metadata {
    name      = "ml-backend-service"
    namespace = kubernetes_namespace.ml_app.metadata[0].name
    labels = {
      app        = "ml-backend"
      managed-by = "terraform"
    }
  }

  spec {
    # Garante que o tráfego vá para os Pods com esse label
    selector = {
      app = "ml-backend"
    }

    type = "NodePort"

    port {
      name        = "http"
      port        = 80    # Porta do ClusterIP (Interna do cluster)
      target_port = 80    # Porta real onde a APP ouve dentro do Container
      node_port   = 30080 # Porta que você vai abrir no seu navegador (IP_DO_PI:30080)
    }
  }
}