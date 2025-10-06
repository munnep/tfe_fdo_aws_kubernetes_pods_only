variable "tag_prefix" {
  description = "default prefix of names"
}


variable "dns_hostname" {
  description = "DNS hostname"
}

variable "dns_zonename" {
  description = "DNS zonename"
}

variable "certificate_email" {
  description = "email address to register the certificate"
}

variable "tfe_license" {
  description = "TFE license as a string"
}

variable "tfe_encryption_password" {
  description = "TFE encryption password"
}

variable "replica_count" { 
}

variable "tfe_release" {
  description = "Which release version of TFE to install"
}
