resource "kubernetes_pod" "redis" {
  metadata {
    name      = "${var.tag_prefix}-redis"
    namespace = local.namespace
    labels    = { app = "redis" }
  }
  spec {
    container {
      name  = "redis"
      image = "redis:7"
      args  = ["redis-server", "--save", "", "--appendonly", "no"]

      port { container_port = 6379 }

      readiness_probe {
        exec { command = ["/bin/sh", "-c", "redis-cli ping | grep PONG"] }
        initial_delay_seconds = 5
        period_seconds        = 5
      }
      liveness_probe {
        exec { command = ["/bin/sh", "-c", "redis-cli ping | grep PONG"] }
        initial_delay_seconds = 20
        period_seconds        = 10
      }

      resources {}

      volume_mount {
        name       = "redis-data"
        mount_path = "/data"
      }
    }
    volume {
      name = "redis-data"
      empty_dir {}
    }
  }
}

resource "kubernetes_service" "redis" {
  metadata {
    name      = "${var.tag_prefix}-redis"
    namespace = local.namespace
  }
  spec {
    selector = { app = "redis" }
    port {
      name        = "redis"
      port        = 6379
      target_port = 6379
    }
  }
}

output "redis_service_name" {
  value = kubernetes_service.redis.metadata[0].name
}

output "redis_endpoint" {
  value = "redis.${local.namespace}.svc.cluster.local:6379"
}
