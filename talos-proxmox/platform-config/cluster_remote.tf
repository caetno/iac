data "terraform_remote_state" "cluster_state" {
  backend = "local"

  config = {
    path = "${path.module}/../cluster/terraform.tfstate"
  }
}

locals {
  cluster    = data.terraform_remote_state.cluster_state.outputs.cluster
  kubeconfig = data.terraform_remote_state.cluster_state.outputs.kubeconfig

  ca_certificate     = local.kubeconfig.ca_certificate
  client_certificate = local.kubeconfig.client_certificate
  client_key         = local.kubeconfig.client_key
  host               = local.kubeconfig.host

  # ca_certificate     = data.terraform_remote_state.cluster_state.kubeconfig.client_configuration.ca_certificate
  # client_certificate = data.terraform_remote_state.cluster_state.kubeconfig.client_configuration.client_certificate
  # client_key         = data.terraform_remote_state.cluster_state.kubeconfig.client_configuration.client_key
}
