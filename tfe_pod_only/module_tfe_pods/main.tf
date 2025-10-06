# data "terraform_remote_state" "infra" {
#   backend = "local"

#   config = {
#     path = "${path.module}/../../infra/terraform.tfstate"
#   }
# }

# data "aws_eks_cluster" "default" {
#   name = data.terraform_remote_state.infra.outputs.cluster-name
# }

# data "aws_eks_cluster_auth" "default" {
#   name = data.terraform_remote_state.infra.outputs.cluster-name
# }

# provider "kubernetes" {
#   host                   = data.aws_eks_cluster.default.endpoint
#   cluster_ca_certificate = base64decode(data.aws_eks_cluster.default.certificate_authority[0].data)
#   token                  = data.aws_eks_cluster_auth.default.token
# }

# provider "helm" {
#   kubernetes {
#     host                   = data.aws_eks_cluster.default.endpoint
#     cluster_ca_certificate = base64decode(data.aws_eks_cluster.default.certificate_authority[0].data)
#     token                  = data.aws_eks_cluster_auth.default.token
#   }
# }

locals {
  namespace  = "terraform-enterprise"
  full_chain = "${acme_certificate.certificate.certificate_pem}${acme_certificate.certificate.issuer_pem}"
}


# code idea from https://itnext.io/lets-encrypt-certs-with-terraform-f870def3ce6d
data "aws_route53_zone" "base_domain" {
  name = var.dns_zonename
}

resource "tls_private_key" "private_key" {
  algorithm = "RSA"
}

resource "acme_registration" "registration" {
  account_key_pem = tls_private_key.private_key.private_key_pem
  email_address   = var.certificate_email
}

resource "acme_certificate" "certificate" {
  account_key_pem = acme_registration.registration.account_key_pem
  common_name     = "${var.dns_hostname}.${var.dns_zonename}"

  recursive_nameservers        = ["1.1.1.1:53"]
  disable_complete_propagation = true

  dns_challenge {
    provider = "route53"

    config = {
      AWS_HOSTED_ZONE_ID = data.aws_route53_zone.base_domain.zone_id
    }
  }

  depends_on = [acme_registration.registration]
}


data "aws_route53_zone" "selected" {
  name         = var.dns_zonename
  private_zone = false
}

resource "kubernetes_namespace" "terraform-enterprise" {
  metadata {
    name = local.namespace
  }
}

resource "kubernetes_secret" "example" {
  metadata {
    name      = local.namespace
    namespace = local.namespace
  }

  data = {
    ".dockerconfigjson" = <<DOCKER
{
  "auths": {
    "images.releases.hashicorp.com": {
      "auth": "${base64encode("terraform:${var.tfe_license}")}"
    }
  }
}
DOCKER
  }

  type = "kubernetes.io/dockerconfigjson"
}





# # The default for using the helm chart from internet
resource "helm_release" "tfe" {
  name       = local.namespace
  repository = "helm.releases.hashicorp.com"
  chart      = "hashicorp/terraform-enterprise"
  namespace  = local.namespace
  version    = "1.6.5"
  

  values = [
    templatefile("${path.module}/overrides.yaml", {
      tag_prefix        = var.tag_prefix
      replica_count     = var.replica_count
      # region            = data.terraform_remote_state.infra.outputs.region
      enc_password      = var.tfe_encryption_password
      pg_dbname         = kubernetes_secret.postgres.data.POSTGRES_DB
      pg_user           = kubernetes_secret.postgres.data.POSTGRES_USER
      pg_password       = kubernetes_secret.postgres.data.POSTGRES_PASSWORD 
      pg_address        = "${var.tag_prefix}-postgres.${local.namespace}.svc.cluster.local:5432"
      fqdn              = "${var.dns_hostname}.${var.dns_zonename}"
      s3_bucket         = "${var.tag_prefix}-bucket"
      s3_bucket_key     = kubernetes_secret.minio_root.data.appAccessKey
      s3_bucket_secret  = kubernetes_secret.minio_root.data.appSecretKey
      s3_endpoint       = "http://${var.tag_prefix}-minio.${local.namespace}.svc.cluster.local:9000"
      cert_data         = "${base64encode(local.full_chain)}"
      key_data          = "${base64encode(nonsensitive(acme_certificate.certificate.private_key_pem))}"
      ca_cert_data      = "${base64encode(local.full_chain)}"
      redis_host        = "${var.tag_prefix}-redis.${local.namespace}.svc.cluster.local"
      redis_port        = "6379"
      tfe_license       = var.tfe_license
      tfe_release       = var.tfe_release
    })
  ]
  depends_on = [
    kubernetes_secret.example, kubernetes_namespace.terraform-enterprise, kubernetes_secret.postgres, kubernetes_secret.minio_root, kubernetes_pod.postgres, kubernetes_pod.minio
  ]

}

data "kubernetes_service" "example" {
  metadata {
    name      = local.namespace
    namespace = local.namespace
  }
  depends_on = [helm_release.tfe]
}


resource "aws_route53_record" "tfe" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = var.dns_hostname
  type    = "CNAME"
  ttl     = "300"
  records = [data.kubernetes_service.example.status.0.load_balancer.0.ingress.0.hostname]

  depends_on = [helm_release.tfe]
}

