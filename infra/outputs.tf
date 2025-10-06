output "kubectl_environment" {
   value = "aws eks update-kubeconfig --region ${var.region} --name ${aws_eks_cluster.k8s.name}"  
}

output "cluster-name" {
   value = aws_eks_cluster.k8s.name 
}

output "prefix" {
  value = var.tag_prefix
}

output "region" {
  value = var.region
}

# output "pg_dbname" {
#   value = aws_db_instance.default.db_name
# }

# output "pg_user" {
#   value = aws_db_instance.default.username
# }

# output "pg_password" {
#   value = aws_db_instance.default.password
#   sensitive = true
# }

# output "pg_address" {
#   value = aws_db_instance.default.address
# }

# output "redis_host" {
#   value = lookup(aws_elasticache_cluster.redis.cache_nodes[0], "address", "No redis created")
# }

# output "redis_port" {
#   value = lookup(aws_elasticache_cluster.redis.cache_nodes[0], "port", "No redis created")
# }

# output "redis_host" {
#   value = aws_elasticache_replication_group.redis.primary_endpoint_address
# }

# output "redis_port" {
#   value = var.redis_port
# }

# output "redis_password" {
#   value = var.redis_password
# }

# output "redis_tls_enabled" {
#   value = var.redis_tls_enabled
  
# }

# output "s3_bucket" {
#   value = aws_s3_bucket.tfe-bucket.bucket
# }

# needed for the loadbalancer ingress plugin
# output "kubernetes_oidc" {
#   value = aws_eks_cluster.k8s.identity[0].oidc[0].issuer
# }

# output "AmazonEKSLoadBalancerControllerRole" {
#   value = aws_iam_role.tfe_s3_role.arn
# }

# output "storage_role_iam" {
#   value = aws_iam_role.access_storage.arn
# }

output "public1_subnet_id" {
  value = aws_subnet.public1.id
}

output "public2_subnet_id" {
  value = aws_subnet.public2.id
}

output "vpc_id" {
  value = aws_vpc.main.id  
}