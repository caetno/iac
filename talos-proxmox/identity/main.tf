terraform {
  required_version = ">= 1.11.0"

  required_providers {
    talos = {
      source  = "siderolabs/talos"
      version = "~> 0.12"
    }
  }
}

variable "talos_version" {
  type    = string
  default = "1.14.1"
}
# Talos
provider "talos" {}

resource "talos_machine_secrets" "this" {
  talos_version = var.talos_version
}

output "machine_secrets" {
  value     = talos_machine_secrets.this.machine_secrets
  sensitive = true
}

output "client_configuration" {
  value     = talos_machine_secrets.this.client_configuration
  sensitive = true
}
