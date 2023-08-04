resource "kubernetes_deployment" "backend" {
  metadata {
    name = "taskly-backend"
    labels = {
      app       = "taskly"
      component = "backend"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app       = "taskly"
        component = "backend"
      }
    }

    template {
      metadata {
        labels = {
          app       = "taskly"
          component = "backend"
        }
      }

      spec {
        container {
          name  = "taskly-backend"
          image = "sudomateo/taskly-backend:${var.backend_tag}"

          port {
            container_port = 3030
          }

          liveness_probe {
            http_get {
              path = "/api/health"
              port = 3030
            }

            initial_delay_seconds = 3
            period_seconds        = 3
          }


          readiness_probe {
            http_get {
              path = "/api/health"
              port = 3030
            }

            initial_delay_seconds = 3
            period_seconds        = 3
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "backend" {
  metadata {
    name = "taskly-backend"
  }

  spec {
    selector = {
      app       = kubernetes_deployment.backend.metadata.0.labels.app
      component = kubernetes_deployment.backend.metadata.0.labels.component
    }

    port {
      protocol    = "TCP"
      port        = 3030
      target_port = 3030
    }
  }
}
