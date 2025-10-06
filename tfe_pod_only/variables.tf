variable "tfe_license" {
  description = "TFE license as a string"
  type        = string
}

variable "certificate_email" {
  description = "Email address to register the certificate"
  type        = string
}

variable "dns_zonename" {
  description = "DNS zonename"
  type        = string
}

variable "tfe_encryption_password" {
  description = "TFE encryption password"
  type        = string
  sensitive   = true
}

variable "tfe_instances" {
  description = "Map of TFE instances to deploy"
  type = map(object({
    tag_prefix    = string
    dns_hostname  = string
    replica_count = number
    tfe_release   = string
  }))
  default = {}
}