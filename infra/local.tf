locals {
  az1                    = "${var.region}a"
  az2                    = "${var.region}b"
  tags = {
    "OwnedBy" = "patrick.munne@hashicorp.com"
  }
}