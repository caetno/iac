terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 3.3.0"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.3.0"
    }
  }
}

provider "kubernetes" {
  client_certificate     = base64decode(local.client_certificate)
  client_key             = base64decode(local.client_key)
  cluster_ca_certificate = base64decode(local.ca_certificate)
  host                   = local.host
}

provider "helm" {
  kubernetes = {
    client_certificate     = base64decode(local.client_certificate)
    client_key             = base64decode(local.client_key)
    cluster_ca_certificate = base64decode(local.ca_certificate)
    host                   = local.host
  }
}

