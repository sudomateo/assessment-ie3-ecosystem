resource "kubernetes_deployment" "frontend" {
  metadata {
    name = "taskly-frontend"
    labels = {
      app       = "taskly"
      component = "frontend"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app       = "taskly"
        component = "frontend"
      }
    }

    template {
      metadata {
        labels = {
          app       = "taskly"
          component = "frontend"
        }
      }

      spec {
        container {
          name  = "taskly-frontend"
          image = "sudomateo/taskly-frontend:${var.frontend_tag}"

          port {
            container_port = 80
          }

          liveness_probe {
            http_get {
              path = "/"
              port = 80
            }

            initial_delay_seconds = 3
            period_seconds        = 3
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "frontend" {
  metadata {
    name = "taskly-frontend"
  }

  spec {
    selector = {
      app       = kubernetes_deployment.frontend.metadata.0.labels.app
      component = kubernetes_deployment.frontend.metadata.0.labels.component
    }

    port {
      protocol    = "TCP"
      port        = 80
      target_port = 80
    }
  }
}
