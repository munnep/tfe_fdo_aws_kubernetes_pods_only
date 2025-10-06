variable "tag_prefix" {
  description = "default prefix of names"
}

variable "region" {
  description = "region to create the environment"
}

variable "vpc_cidr" {
  description = "which private subnet do you want to use for the VPC. Subnet mask of /16"
}


variable "k8s_min_size" {
  description = "Kubernetes nodes minimal size"
  default     = 1
}




variable "k8s_max_size" {
  description = "Kubernetes nodesmaximal size"
  default     = 1
}

variable "k8s_desired_size" {
  description = "Kubernetes nodes running of instances"
  default     = 2
}