# authentication uri
output "tfe_application_url" {
  value = "https://${var.dns_hostname}.${var.dns_zonename}"
}

output "execute_script_to_create_user_admin" {
  value = "./configure_tfe.sh ${var.dns_hostname}.${var.dns_zonename} patrick.munne@hashicorp.com Password#1"
}

output "minio_service_name" { value = kubernetes_service.minio.metadata[0].name }
output "minio_endpoint" { value = "http://${var.tag_prefix}-minio.${local.namespace}.svc.cluster.local:9000" }



output "postgres_service_name" { value = kubernetes_service.postgres.metadata[0].name }
output "postgres_endpoint" { value = "${var.tag_prefix}-postgres.${local.namespace}.svc.cluster.local:5432" }
