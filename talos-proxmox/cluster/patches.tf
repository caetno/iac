locals {
  # TODO: Try rebuilding the cluster with the concatinated yaml
  cilium_patch = <<-YAML
    apiVersion: v1alpha1
    kind: KubeFlannelCNIConfig
    $patch: delete
    ---
    apiVersion: v1alpha1
    kind: KubeProxyConfig
    enabled: false
  YAML
  # cilium_patch = yamlencode(concat([
  #   {
  #     apiVersion = "v1alpha1"
  #     kind       = "KubeFlannelCNIConfig"
  #     "$patch"   = "delete"
  #   },
  #   {
  #     apiVersion = "v1alpha1"
  #     kind       = "KubeProxyConfig"
  #     enabled    = false
  #   }
  # ]))

  install_patch = yamlencode({
    apiVersion = "v1alpha1"
    kind       = "UnattendedInstallConfig"
    installer = {
      image = local.installer_image
    }
    provisioning = {
      diskSelector = {
        match = "disk.dev_path == \"/dev/sda\""
      }
    }

  })

  vip_patch = yamlencode({
    machine = {
      network = {
        interfaces = [
          {
            deviceSelector = {
              physical = true
            }
            dhcp = true
            vip = {
              ip = var.virtual_ip
            }
          },
        ]
      }
    }
  })
}
