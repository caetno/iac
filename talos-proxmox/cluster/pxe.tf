variable "flatcar_version" {
  type    = string
  default = "4757.2.1"
}

variable "pxe_host" {
  type        = string
  default     = "pve01"
  description = "Proxmox Host on which the PXE Server should be deployed"
}

locals {
  pxe_server = {
    roles    = ["pxe"]
    pve_node = "pve01"
    vm_id    = 101
    cores    = 2
    memory   = 2024
  }
}

resource "proxmox_download_file" "flatcar_img" {
  # lifecycle {
  #   destroy = false
  # }

  content_type = "import"
  datastore_id = "local"
  file_name    = "flatcar_${var.flatcar_version}.qcow2" # Had to use qcow2 because of a file extension error
  node_name    = local.pxe_server.pve_node
  url          = "https://stable.release.flatcar-linux.net/amd64-usr/${var.flatcar_version}/flatcar_production_proxmoxve_image.img"
}

variable "butane" {
  type    = string
  default = <<-YAML
    variant: flatcar
    version: 1.0.0

    storage:
      files:
        - path: /opt/extensions/docker-compose/docker-compose-2.34.0-x86-64.raw
          mode: 0644
          contents:
            source: https://extensions.flatcar.org/extensions/docker-compose-2.34.0-x86-64.raw

      links:
        - path: /etc/extensions/docker-compose.raw
          target: /opt/extensions/docker-compose/docker-compose-2.34.0-x86-64.raw
          hard: false 
  YAML
}

data "ct_config" "ignition" {
  content = var.butane
}

# TODO: Should move this to a seperate Proxmox module/state in the future!
# The Promox cluster is still configured manually.

import {
  to = proxmox_storage_directory.local
  id = "local"
}

resource "proxmox_storage_directory" "local" {
  content          = ["backup", "import", "iso", "vztmpl", "snippets"]
  create_base_path = true
  create_subdirs   = true
  disable          = false
  id               = "local"
  nodes            = []
  path             = "/var/lib/vz"
  preallocation    = null
  shared           = false
}

resource "proxmox_virtual_environment_file" "user-data" {
  depends_on   = [data.ct_config.ignition]
  content_type = "snippets" #TODO: Requires activating snippets in the datastore, and SSH access. Alternative might be HTTP providing the snippet.
  datastore_id = "local"
  node_name    = local.pxe_server.pve_node

  source_raw {
    data      = data.ct_config.ignition.rendered
    file_name = "pxe01.ign"
  }
}

resource "proxmox_virtual_environment_vm" "pxe" {
  name      = "pxe01"
  node_name = var.pxe_host
  vm_id     = local.pxe_server.vm_id

  machine       = "q35"
  bios          = "ovmf"
  scsi_hardware = "virtio-scsi-pci"

  started         = true
  stop_on_destroy = true

  tags = local.pxe_server.roles

  initialization {
    user_data_file_id = proxmox_virtual_environment_file.user-data.id
  }
  agent {
    enabled = true

    wait_for_ip {
      ipv4 = true
    }
  }

  cpu {
    cores = local.pxe_server.cores
    type  = "x86-64-v2-AES"
  }

  memory {
    dedicated = local.pxe_server.memory
    floating  = 0 # Talos does not support memory ballooning or hotplug.
  }

  boot_order = [
    "virtio0",
  ]

  efi_disk {
    datastore_id      = "local-lvm"
    type              = "4m"
    pre_enrolled_keys = false # Talos enrolls its own Secure Boot keys from UEFI setup mode.
  }

  disk {
    datastore_id = "local-lvm"
    interface    = "scsi0"
    size         = 32
    discard      = "on"
    ssd          = true
    import_from  = proxmox_download_file.flatcar_img.id
    file_format  = "qcow2"
  }

  network_device {
    bridge = "vmbr0"
    model  = "virtio"
  }

  serial_device {
    device = "socket"
  }
}

output "pxe_ipv4_addresses" {
  value = proxmox_virtual_environment_vm.pxe.ipv4_addresses
}
