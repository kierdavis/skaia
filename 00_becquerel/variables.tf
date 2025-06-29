variable "authorized_ssh_ipv4_nets" {
  type = set(string)
}

variable "authorized_ssh_ipv6_nets" {
  type = set(string)
}

variable "authorized_ssh_public_keys" {
  type = set(string)
}

variable "cloudflare_token" {
  type      = string
  sensitive = true
  ephemeral = true
}

variable "cloudflare_zone_id" {
  type = string
}

variable "lets_encrypt_email" {
  type = string
}

variable "linode_token" {
  type      = string
  sensitive = true
  ephemeral = true
}
