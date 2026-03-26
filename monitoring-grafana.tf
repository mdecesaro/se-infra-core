resource "helm_release" "grafana" {
  name             = "grafana"
  repository       = "https://grafana.github.io/helm-charts"
  chart            = "grafana"
  namespace        = "prometheus-system"
  create_namespace = true

  values = [
    yamlencode({
      adminPassword = "admin123"
      
      service = {
        type     = "NodePort"
        nodePort = 32000
      }

      persistence = {
        enabled = false
      }

      # --- AQUI ESTÁ A LIMPEZA: Desativa a importação automática de lixo ---
      sidecar = {
        dashboards = {
          enabled = true
          label   = "grafana_dashboard"
          # Isso faz o Grafana ignorar dashboards de outros namespaces (como o NGINX)
          searchNamespace = "prometheus-system"
        }
      }

      # --- FORÇA O DOWNLOAD DO DASHBOARD DO OPENCOST ---
      dashboards = {
        default = {
          opencost-official = {
            gnetId     = 22252
            revision   = 1
            datasource = "Prometheus"
          }
          # Se quiser garantir o NGINX via código também:
          nginx-ingress = {
            gnetId     = 9614
            revision   = 1
            datasource = "Prometheus"
          }
        }
      }

      # --- PROVEDOR DE DASHBOARDS ---
      dashboardProviders = {
        "dashboardproviders.yaml" = {
          apiVersion = 1
          providers = [
            {
              name            = "default"
              orgId           = 1
              folder          = ""
              type            = "file"
              disableDeletion = false
              editable        = true
              options = {
                path = "/var/lib/grafana/dashboards"
              }
            }
          ]
        }
      }

      # --- DATASOURCE (Ajustado para o nome exato que o dashboard espera) ---
      datasources = {
        "datasources.yaml" = {
          apiVersion = 1
          datasources = [
            {
              name      = "Prometheus"
              type      = "prometheus"
              url       = "http://prometheus-server.prometheus-system.svc.cluster.local"
              access    = "proxy"
              isDefault = true
            }
          ]
        }
      }

      resources = {
        limits   = { memory = "256Mi" }
        requests = { memory = "128Mi" }
      }
    })
  ]
}