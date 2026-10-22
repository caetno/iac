# import {
#   to = helm_release.test_nginx
#   id = "default/test-nginx"
# }

resource "helm_release" "test_nginx" {
  # https://artifacthub.io/packages/helm/bitnami/nginx
  name       = "test-nginx"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "nginx"
  version    = "25.2.1"
  namespace  = "default"

  values = [
    yamlencode(local.test_nginx_values)
  ]
}

locals {
  test_nginx_values = {
    metrics = {
      enabled = true
    }

  }
}
