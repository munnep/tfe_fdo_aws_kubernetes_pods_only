terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">6.9.0"
    }
    acme = {
      source  = "vancluever/acme"
      version = "~> 2.5.3"
    }
  }

  required_version = ">= 1.1"
}

provider "aws" {
  region = var.region
}


