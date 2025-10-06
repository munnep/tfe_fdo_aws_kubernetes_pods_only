# Root + app credentials secret
resource "kubernetes_secret" "minio_root" {
  metadata {
    name      = "${var.tag_prefix}-minio-root-credentials"
    namespace = local.namespace
  }
  data = {
    rootUser     = "minioadmin"
    rootPassword = "minioadmin123456"
    appAccessKey = "app-user-access"
    appSecretKey = "app-user-secret-override"
  }
  type = "Opaque"
}

# MinIO Pod (ephemeral)
resource "kubernetes_pod" "minio" {
  metadata {
    name      = "${var.tag_prefix}-minio"
    namespace = local.namespace
    labels = {
      app     = "minio"
      storage = "ephemeral"
    }
  }
  spec {
    container {
      name  = "minio"
      image = "minio/minio:RELEASE.2025-09-07T16-13-09Z"
      args  = ["server", "/data", "--console-address", ":9001"]

      env {
        name = "MINIO_ROOT_USER"
        value_from {
          secret_key_ref {
            name = kubernetes_secret.minio_root.metadata[0].name
            key  = "rootUser"
          }
        }
      }
      env {
        name = "MINIO_ROOT_PASSWORD"
        value_from {
          secret_key_ref {
            name = kubernetes_secret.minio_root.metadata[0].name
            key  = "rootPassword"
          }
        }
      }
      port {
        container_port = 9000
      }
      port {
        container_port = 9001
      }
      volume_mount {
        name       = "data"
        mount_path = "/data"
      }
      readiness_probe {
        http_get {
          path = "/minio/health/ready"
          port = 9000
        }
        initial_delay_seconds = 10
        period_seconds        = 5
      }
      liveness_probe {
        http_get {
          path = "/minio/health/live"
          port = 9000
        }
        initial_delay_seconds = 20
        period_seconds        = 10
      }
    }
    volume {
      name = "data"
      empty_dir {}
    }
  }
}

# Service
resource "kubernetes_service" "minio" {
  metadata {
    name      = "${var.tag_prefix}-minio"
    namespace = local.namespace
  }
  spec {
    selector = {
      app = "minio"
    }
    port {
      name        = "api"
      port        = 9000
      target_port = 9000
    }
    port {
      name        = "console"
      port        = 9001
      target_port = 9001
    }
    type = "ClusterIP"
  }
}

# Init Job simplified (assumes pod reachable, uses secret creds)
resource "kubernetes_job" "minio_init" {
  metadata {
    name      = "${var.tag_prefix}-minio-init"
    namespace = local.namespace
  }
  spec {
    template {
      metadata {}
      spec {
        restart_policy = "OnFailure"
        container {
          name  = "init"
          image = "minio/mc:RELEASE.2025-08-13T08-35-41Z"
          env {
            name = "MINIO_ROOT_USER"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.minio_root.metadata[0].name
                key  = "rootUser"
              }
            }
          }
          env {
            name = "MINIO_ROOT_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.minio_root.metadata[0].name
                key  = "rootPassword"
              }
            }
          }
          env {
            name = "APP_ACCESS_KEY"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.minio_root.metadata[0].name
                key  = "appAccessKey"
              }
            }
          }
          env {
            name = "APP_SECRET_KEY"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.minio_root.metadata[0].name
                key  = "appSecretKey"
              }
            }
          }
          env {
            name  = "FORCE_RECREATE_USER"
            value = tostring(false)
          }
          command = ["/bin/sh", "-c"]
          args = [<<-EOT
            set -euo pipefail
            MINIO_ENDPOINT="http://${var.tag_prefix}-minio.${local.namespace}.svc.cluster.local:9000"
            echo "[init] Connecting to $MINIO_ENDPOINT"
            for i in $(seq 1 30); do
              if mc alias set local "$MINIO_ENDPOINT" "$MINIO_ROOT_USER" "$MINIO_ROOT_PASSWORD" >/dev/null 2>&1; then
                if mc ls local >/dev/null 2>&1; then
                  echo "[init] Connected on attempt $i"; break
                fi
              fi
              sleep 2
              if [ "$i" = 30 ]; then echo "Failed to connect" >&2; exit 1; fi
            done
            BUCKET="${var.tag_prefix}-bucket"
            USER="app-user"
            ACCESS_KEY="$APP_ACCESS_KEY"
            SECRET_KEY="$APP_SECRET_KEY"
            if ! mc ls local/$BUCKET >/dev/null 2>&1; then mc mb local/$BUCKET; fi
            USER_EXISTS=0; mc admin user info local $USER >/dev/null 2>&1 && USER_EXISTS=1 || true
            if [ "$FORCE_RECREATE_USER" = "true" ] && [ $USER_EXISTS -eq 1 ]; then mc admin user remove local $USER || true; USER_EXISTS=0; fi
            if [ $USER_EXISTS -eq 0 ]; then mc admin user add local $ACCESS_KEY $SECRET_KEY; mc admin policy attach local readwrite --user $ACCESS_KEY; fi
            echo "[init] Done"
          EOT
          ]
        }
      }
    }
  }

  depends_on = [kubernetes_pod.minio]
}


