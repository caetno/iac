
# TODO: We need to split the platform from platform-configuration. 
resource "kubernetes_manifest" "ciliumloadbalancerippool_lan" {
  manifest = {
    "apiVersion" = "cilium.io/v2"
    "kind"       = "CiliumLoadBalancerIPPool"
    "metadata" = {
      "name" = "lan"
    }
    "spec" = {
      "blocks" = [
        {
          "start" = "192.168.178.70"
          "stop"  = "192.168.178.90"
        },
      ]
    }
  }
}

resource "kubernetes_manifest" "cilium_l2_policy" {
  manifest = {
    apiVersion = "cilium.io/v2alpha1"
    kind       = "CiliumL2AnnouncementPolicy"

    metadata = {
      name = "lan"
    }

    spec = {
      loadBalancerIPs = true
    }
  }
}
