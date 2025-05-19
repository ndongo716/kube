data "kubernetes_secret_v1" "example" {
  metadata {
    name      = "example-secret"
  }
  binary_data = {
    "POSTGRES_USER" = "odc"
    "POSTGRES_PASSWORD" = "odc123"
    "POSTGRES_DB" = "odcdb"
  }
}

resource "kubernetes_deployment" "fil-rouge-front" {
  metadata {
    name = "fil-rouge-front"
    labels = {
      app = "fil-rouge-front"
    }
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "fil-rouge-front"
      }
    }

    template {
      metadata {
        labels = {
          app = "fil-rouge-front"
        }
      }

      spec {
        container {
          name  = "fil-rouge-front"
          image = "genecodo/frontendk8s:v1"

          port {
            container_port = 80
          }

          resources {
            limits = {
              cpu    = "500m"
              memory = "256Mi"
            }
            requests = {
              cpu    = "150m"
              memory = "128Mi"
            }
          }

          image_pull_policy = "Always"
        }
      }
    }
  }
}

resource "kubernetes_service" "fil-rouge-front" {
  metadata {
    name = "fil-rouge-front"
  }

  spec {
    selector = {
      app = "fil-rouge-front"
    }

    port {
      protocol    = "TCP"
      port        = 80
      target_port = 80
      node_port   = 30517
    }

    type = "NodePort"
  }
}

# fil-rouge-back Deployment
resource "kubernetes_deployment" "fil-rouge-back" {
  metadata {
    name = "fil-rouge-back"
    labels = {
      app = "fil-rouge-back"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "fil-rouge-back"
      }
    }

    template {
      metadata {
        labels = {
          app = "fil-rouge-back"
        }
      }

      spec {
        container {
          name  = "fil-rouge-back"
          image = "madicke12/backend:v1"

          port {
            container_port = 8000
          }

          image_pull_policy = "Always"

          resources {
            limits = {
              memory = "256Mi"
              cpu    = "500m"
            }
            requests = {
              memory = "128Mi"
              cpu    = "150m"
            }
          }
        }
      }
    }
  }
}

# fil-rouge-back Service
resource "kubernetes_service" "fil-rouge-back" {
  metadata {
    name = "fil-rouge-back"
  }

  spec {
    selector = {
      app = "fil-rouge-back"
    }

    port {
      port        = 8000
      target_port = 8000
      node_port   = 30519
      protocol    = "TCP"
    }

    type = "NodePort"
  }
}

resource "kubernetes_persistent_volume_claim" "postgres_pvc" {
  metadata {
    name = "postgres-pvc"
  }

  spec {
    access_modes = ["ReadWriteOnce"]

    resources {
      requests = {
        storage = "1Gi"
      }
    }
  }
}

resource "kubernetes_secret" "postgres_credentials" {
  metadata {
    name = "postgres-credentials"
  }

  type = "Opaque"

  data = {
    POSTGRES_USER     = "odc"
    POSTGRES_PASSWORD = "odc123"
    POSTGRES_DB       = "odcdb"
  }
}

resource "kubernetes_deployment" "postgres" {
  metadata {
    name = "postgres"
    labels = {
      app = "postgres"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "postgres"
      }
    }

    template {
      metadata {
        labels = {
          app = "postgres"
        }
      }

      spec {
        container {
          name  = "postgres"
          image = "postgres:latest"

          port {
            container_port = 5432
          }

          env_from {
            secret_ref {
              name = kubernetes_secret.postgres_credentials.metadata[0].name
            }
          }

          volume_mount {
            name       = "postgres-data"
            mount_path = "/var/lib/postgresql/data"
          }

          readiness_probe {
            exec {
              command = ["pg_isready", "-U", "odc"]
            }
            initial_delay_seconds = 5
            period_seconds        = 5
          }

          resources {
            requests = {
              memory = "256Mi"
              cpu    = "250m"
            }
            limits = {
              memory = "512Mi"
              cpu    = "1000m"
            }
          }
        }

        volume {
          name = "postgres-data"

          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.postgres_pvc.metadata[0].name
          }
        }
      }
    }
  }
}

# Service for PostgreSQL
resource "kubernetes_service" "postgres_service" {
  metadata {
    name = "database"
  }

  spec {
    selector = {
      app = "postgres"
    }

    port {
      port        = 5432
      target_port = 5432
    }
  }
}
