# Combined output with all information for each instance
output "tfe_instances_info" {
  description = "Complete information for all TFE instances"
  value = {
    for instance_name, module_instance in module.tfe_pods :
    instance_name => {
      tfe_application_url                 = module_instance.tfe_application_url
      execute_script_to_create_user_admin = module_instance.execute_script_to_create_user_admin
      minio_service_name                  = module_instance.minio_service_name
      minio_endpoint                      = module_instance.minio_endpoint
      postgres_service_name               = module_instance.postgres_service_name
      postgres_endpoint                   = module_instance.postgres_endpoint
    }
  }
}

