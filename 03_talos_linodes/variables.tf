variable "authorized_ssh_ipv4_nets" {
  type = set(string)
}

variable "authorized_ssh_ipv6_nets" {
  type = set(string)
}

variable "linode_token" {
  type      = string
  sensitive = true
  ephemeral = true
}
