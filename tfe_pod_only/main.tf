data "terraform_remote_state" "infra" {
  backend = "local"

  config = {
    path = "${path.module}/../infra/terraform.tfstate"
  }
}

data "aws_eks_cluster" "default" {
  name = data.terraform_remote_state.infra.outputs.cluster-name
}

data "aws_eks_cluster_auth" "default" {
  name = data.terraform_remote_state.infra.outputs.cluster-name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.default.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.default.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.default.token
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.default.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.default.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.default.token
  }
}



module "tfe_pods" {
  source = "./module_tfe_pods"
  
  for_each = var.tfe_instances

  tag_prefix               = each.value.tag_prefix
  dns_hostname            = each.value.dns_hostname
  dns_zonename            = var.dns_zonename
  certificate_email       = var.certificate_email
  tfe_license             = var.tfe_license
  tfe_encryption_password = var.tfe_encryption_password
  replica_count           = each.value.replica_count
  tfe_release             = each.value.tfe_release
}
