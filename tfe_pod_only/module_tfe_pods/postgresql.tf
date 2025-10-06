resource "kubernetes_secret" "postgres" {
  metadata {
    name      = "${var.tag_prefix}-postgres-secret"
    namespace = local.namespace
  }
  data = {
    POSTGRES_USER     = "postgres"
    POSTGRES_PASSWORD = "postgresql"
    POSTGRES_DB       = "postgres"
  }
  type = "Opaque"
}

resource "kubernetes_pod" "postgres" {
  metadata {
    name      = "${var.tag_prefix}-postgres"
    namespace = local.namespace
    labels = { app = "postgres" }
  }
  spec {
    container {
      name  = "postgres"
      image = "postgres:16"

      port { container_port = 5432 }

      env {
        name = "POSTGRES_USER"
        value_from {
          secret_key_ref {
            name = kubernetes_secret.postgres.metadata[0].name
            key  = "POSTGRES_USER"
          }
        }
      }
      env {
        name = "POSTGRES_PASSWORD"
        value_from {
          secret_key_ref {
            name = kubernetes_secret.postgres.metadata[0].name
            key  = "POSTGRES_PASSWORD"
          }
        }
      }
      env {
        name = "POSTGRES_DB"
        value_from {
          secret_key_ref {
            name = kubernetes_secret.postgres.metadata[0].name
            key  = "POSTGRES_DB"
          }
        }
      }

      readiness_probe {
        exec { command = ["/bin/sh","-c","pg_isready -U $POSTGRES_USER"] }
        initial_delay_seconds = 5
        period_seconds        = 5
      }
      liveness_probe {
        exec { command = ["/bin/sh","-c","pg_isready -U $POSTGRES_USER"] }
        initial_delay_seconds = 30
        period_seconds        = 10
        failure_threshold     = 6
      }

      resources {}

      volume_mount {
        name       = "pgdata"
        mount_path = "/var/lib/postgresql/data"
      }
    }

    volume {
      name = "pgdata"
      empty_dir {}
    }
    restart_policy = "Always"
  }
}

resource "kubernetes_service" "postgres" {
  metadata {
    name      = "${var.tag_prefix}-postgres"
    namespace = local.namespace
    labels = { app = "postgres" }
  }
  spec {
    selector = { app = "postgres" }
    port {
      name        = "postgres"
      port        = 5432
      target_port = 5432
    }
  }
}
