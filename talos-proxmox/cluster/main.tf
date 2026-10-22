locals {
  # A configured IP must already be reachable at boot, for example through a DHCP reservation.
  # ip = null enables IPv4 discovery through the QEMU guest agent.
  nodes = {
    cp01 = {
      role     = "controlplane"
      pve_node = "pve01"
      vm_id    = 201
      memory   = 4096
      mac      = "BC:24:11:00:00:51"
      ip       = null
    }

    cp02 = {
      role     = "controlplane"
      pve_node = "pve02"
      vm_id    = 202
      memory   = 4096
      mac      = "BC:24:11:00:00:52"
      ip       = null
    }

    cp03 = {
      role     = "controlplane"
      pve_node = "pve03"
      vm_id    = 203
      memory   = 4096
      mac      = "BC:24:11:00:00:53"
      ip       = null
    }

    worker01 = {
      role     = "worker"
      pve_node = "pve01"
      vm_id    = 301
      memory   = 4096
      mac      = "BC:24:11:00:00:61"
      ip       = null
    }

    worker02 = {
      role     = "worker"
      pve_node = "pve02"
      vm_id    = 302
      memory   = 4096
      mac      = "BC:24:11:00:00:62"
      ip       = null
    }

    worker03 = {
      role     = "worker"
      pve_node = "pve03"
      vm_id    = 303
      memory   = 4096
      mac      = "BC:24:11:00:00:63"
      ip       = null
    }
  }

  pve_nodes = toset([
    for node in values(local.nodes) : node.pve_node
  ])

  controlplane_names = [
    for name, node in local.nodes : name
    if node.role == "controlplane"
  ]

  bootstrap_node = sort(local.controlplane_names)[0]
}

data "talos_image_factory_extensions_versions" "this" {
  talos_version = var.talos_version

  filters = {
    names = [
      "iscsi-tools",
      "qemu-guest-agent",
      "util-linux-tools",
    ]
  }
}

resource "talos_image_factory_schematic" "this" {
  schematic = yamlencode({
    customization = {
      systemExtensions = {
        officialExtensions = data.talos_image_factory_extensions_versions.this.extensions_info[*].name
      }
    }
  })
}

data "talos_image_factory_urls" "this" {
  talos_version = var.talos_version
  schematic_id  = talos_image_factory_schematic.this.id
  platform      = "metal"
}

locals {
  iso_url         = data.talos_image_factory_urls.this.urls.iso_secureboot
  installer_image = data.talos_image_factory_urls.this.urls.installer_secureboot
}

# The local datastore is node-local, so every Proxmox host needs its own ISO copy.
resource "proxmox_download_file" "talos_iso" {
  # lifecycle {
  #   destroy = false
  # }

  for_each = local.pve_nodes

  content_type = "iso"
  datastore_id = "local"
  file_name    = "talos_${var.talos_version}.iso"
  node_name    = each.key
  url          = local.iso_url
}

resource "proxmox_virtual_environment_vm" "vm" {
  for_each = local.nodes

  name      = each.key
  node_name = each.value.pve_node
  vm_id     = each.value.vm_id

  machine       = "q35"
  bios          = "ovmf"
  scsi_hardware = "virtio-scsi-pci"

  started         = true
  stop_on_destroy = true

  tags = sort(concat(["talos"], [each.value.role]))

  agent {
    enabled = true

    wait_for_ip {
      disabled = each.value.ip != null
      ipv4     = each.value.ip == null
    }
  }

  cpu {
    cores = 4
    type  = "x86-64-v2-AES"
  }

  memory {
    dedicated = each.value.memory
    floating  = 0 # Talos does not support memory ballooning or hotplug.
  }

  boot_order = [
    "scsi0",
    "ide0",
  ]

  cdrom {
    file_id   = proxmox_download_file.talos_iso[each.value.pve_node].id
    interface = "ide0"
  }

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
  }

  network_device {
    bridge      = "vmbr0"
    model       = "virtio"
    mac_address = each.value.mac
  }

  serial_device {
    device = "socket"
  }
}

locals {
  configured_node_ips = {
    for name, node in local.nodes : name => node.ip
    if node.ip != null
  }

  guest_ipv4_addresses = {
    for name, node in local.nodes :
    name => flatten(proxmox_virtual_environment_vm.vm[name].ipv4_addresses)
    if node.ip == null
  }

  matching_node_ips = {
    for name, addresses in local.guest_ipv4_addresses : name => [
      for ip in addresses : ip
      if cidrcontains(var.node_cidr, ip) && ip != var.virtual_ip
    ]
  }

  unique_node_ips = {
    for name, addresses in local.matching_node_ips :
    name => distinct(addresses)
  }

  discovered_node_ips = {
    for name, addresses in local.unique_node_ips :
    name => one(addresses)
  }

  node_ips = merge(local.discovered_node_ips, local.configured_node_ips)

  controlplane_ips = [
    for name in local.controlplane_names : local.node_ips[name]
  ]
}

#WARNING: Talos credentials are stored in state, so protect the state as a secret.
resource "talos_machine_secrets" "this" {
  #   lifecycle {
  #     destroy = false
  #   }
  talos_version = var.talos_version
}

locals {
  machine_configs = {
    controlplane = data.talos_machine_configuration.controlplane.machine_configuration
    worker       = data.talos_machine_configuration.worker.machine_configuration
  }
}

data "talos_machine_configuration" "controlplane" {
  talos_version    = var.talos_version
  cluster_name     = var.cluster_name
  machine_type     = "controlplane"
  cluster_endpoint = "https://${var.virtual_ip}:6443"
  machine_secrets  = local.machine_secrets
  config_patches = [
    local.install_patch,
    local.cilium_patch,
    local.vip_patch
  ]
}

data "talos_machine_configuration" "worker" {
  talos_version    = var.talos_version
  cluster_name     = var.cluster_name
  machine_type     = "worker"
  cluster_endpoint = "https://${var.virtual_ip}:6443"
  machine_secrets  = local.machine_secrets
  config_patches   = [local.install_patch]
}

data "talos_client_configuration" "this" {
  cluster_name         = var.cluster_name
  client_configuration = local.client_configuration
  endpoints            = local.controlplane_ips
  nodes                = values(local.node_ips)
}

resource "talos_machine_configuration_apply" "this" {
  for_each = local.nodes

  node     = local.node_ips[each.key]
  endpoint = local.node_ips[each.key]

  client_configuration        = local.client_configuration
  machine_configuration_input = local.machine_configs[each.value.role]
}

resource "talos_machine_bootstrap" "this" {
  depends_on = [talos_machine_configuration_apply.this]

  node     = local.node_ips[local.bootstrap_node]
  endpoint = local.node_ips[local.bootstrap_node]

  client_configuration = local.client_configuration
}

resource "talos_cluster_kubeconfig" "this" {
  depends_on = [
    talos_machine_bootstrap.this
  ]
  client_configuration = local.client_configuration
  node                 = var.virtual_ip
}
