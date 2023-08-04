resource "kubernetes_ingress_v1" "taskly" {
  metadata {
    name = "taskly"
    annotations = {
      "kubernetes.io/ingress.class" = "azure/application-gateway"
    }
  }

  spec {
    rule {
      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = "taskly-frontend"
              port {
                number = 80
              }
            }
          }
        }

        path {
          path      = "/api"
          path_type = "Prefix"

          backend {
            service {
              name = "taskly-backend"
              port {
                number = 3030
              }
            }
          }
        }
      }
    }
  }
}
