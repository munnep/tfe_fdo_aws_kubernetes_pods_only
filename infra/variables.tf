variable "tag_prefix" {
  description = "default prefix of names"
}

variable "region" {
  description = "region to create the environment"
}

variable "vpc_cidr" {
  description = "which private subnet do you want to use for the VPC. Subnet mask of /16"
}

variable "rds_password" {
  description = "password for the RDS postgres database user"
}

variable "k8s_min_size" {
  description = "Kubernetes nodes minimal size"
  default     = 1
}

variable "redis_port" {
  description = "port for redis to listen on"
  default     = 6380
}

variable "redis_tls_enabled" {
  description = "redis tls enabled"
  default     = true
}

variable "redis_password" {
  description = "password for the redis database"
  default     = "redis-password-secure"
}


variable "k8s_max_size" {
  description = "Kubernetes nodesmaximal size"
  default     = 1
}

variable "k8s_desired_size" {
  description = "Kubernetes nodes running of instances"
  default     = 2
}