data "terraform_remote_state" "identity_state" {
  backend = "local"

  config = {
    path = "${path.module}/../identity/terraform.tfstate"
  }
}

locals {
  identity_state_outputs = data.terraform_remote_state.identity_state.outputs

  machine_secrets      = local.identity_state_outputs.machine_secrets
  client_configuration = local.identity_state_outputs.client_configuration
}
