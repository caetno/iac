output "node_ips" {
  value = local.node_ips
}

output "talosconfig" {
  value     = data.talos_client_configuration.this.talos_config
  sensitive = true
}
output "cluster" {
  value = {
    name = var.cluster_name
    ip   = var.virtual_ip
  }
}

output "kubeconfig" {
  value     = talos_cluster_kubeconfig.this.kubernetes_client_configuration
  sensitive = true
}

output "kubeconfig_raw" {
  value     = talos_cluster_kubeconfig.this.kubeconfig_raw
  sensitive = true
}

output "talosconfig_raw" {
  value     = data.talos_client_configuration.this.talos_config
  sensitive = true
}

resource "local_sensitive_file" "talosconfig" {
  content  = data.talos_client_configuration.this.talos_config
  filename = "${path.module}/talosconfig"
}

resource "local_sensitive_file" "kubeconfig" {
  content  = talos_cluster_kubeconfig.this.kubeconfig_raw
  filename = "${path.module}/kubeconfig"
}
