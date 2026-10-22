
variable "talos_version" {
  type    = string
  default = "1.14.1"
}

variable "cluster_name" {
  type    = string
  default = "terraformed-cluster"
}

variable "virtual_ip" {
  type    = string
  default = "192.168.178.61"
}

variable "node_cidr" {
  type    = string
  default = "192.168.178.0/24"
}
