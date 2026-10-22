terraform {
  required_version = ">= 1.11.0"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.112"
    }

    talos = {
      source  = "siderolabs/talos"
      version = "~> 0.12"
    }

    # For converting the Butane config into a FlatCar Ignition string.
    ct = {
      source  = "poseidon/ct"
      version = "0.14.0"
    }

    # matchbox = {
    #   source  = "poseidon/matchbox"
    #   version = "0.5.4"
    # }

    tls = {
      source  = "hashicorp/tls"
      version = "4.4.1"
    }

    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

# Talos
provider "talos" {}

# CT for butane -> ignition
provider "ct" {}

# Matchbox for matching the machines to their PXE configs
# provider "matchbox" {}



# Proxmox
# TODO: Should create another terraform state for the initial Proxmox Cluster configuration
# Progably will include some ansible to get things going for tofu to take over

#
# useradd -m -s /bin/bash tofu
# apt install sudo
# install -d -m 700 -o tofu -g tofu /home/tofu/.ssh
# TOFU="<ssh-ed25519 ...>"
# install -m 600 -o terraform -g terraform /dev/null /home/terraform/.ssh/authorized_keys
# echo $TOFU >> /home/tofu/.ssh/authorized_keys
#
# cat <<'EOF' > /tmp/terraform-sudoers
# terraform ALL=(root) NOPASSWD: /usr/sbin/pvesm
# terraform ALL=(root) NOPASSWD: /usr/sbin/qm
# terraform ALL=(root) NOPASSWD: /usr/bin/tee /var/lib/vz/snippets/[a-zA-Z0-9_][a-zA-Z0-9_.-]*
# EOF
#
# visudo -cf /tmp/terraform-sudoers &&
# install -o root -g root -m 440 /tmp/terraform-sudoers /etc/sudoers.d/terraform &&
# visudo -c

provider "proxmox" {
  # username = PROXMOX_VE_USERNAME
  # api_token = PROXMOX_VE_API_TOKEN
  # eendpoint = PROXMOX_VE_ENDPOINT
  insecure = true # Set to false once the Proxmox certificate is trusted.

  ssh {
    agent    = true
    username = "tofu"
    # private_key = tls_private_key.proxmox.private_key_pem
  }
}

