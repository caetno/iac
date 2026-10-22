resource "helm_release" "cilium" {
  name       = "cilium"
  repository = "https://helm.cilium.io"
  chart      = "cilium"
  version    = "1.20.2"
  namespace  = "kube-system"

  values = [
    yamlencode(local.cilium_values)
  ]
}

locals {
  cilium_values = {
    l2announcements = {
      enabled = true
    }

    ipam = {
      mode = "kubernetes"
    }

    kubeProxyReplacement = true

    k8sServiceHost = "localhost"
    k8sServicePort = "7445"

    securityContext = {
      capabilities = {
        ciliumAgent = [
          "CHOWN",
          "KILL",
          "NET_ADMIN",
          "NET_RAW",
          "IPC_LOCK",
          "SYS_ADMIN",
          "SYS_RESOURCE",
          "DAC_OVERRIDE",
          "FOWNER",
          "SETGID",
          "SETUID",
        ]

        cleanCiliumState = [
          "NET_ADMIN",
          "SYS_ADMIN",
          "SYS_RESOURCE",
        ]
      }
    }

    cgroup = {
      autoMount = {
        enabled = false
      }

      hostRoot = "/sys/fs/cgroup"
    }

    bpf = {
      hostLegacyRouting = true
    }
  }
}

