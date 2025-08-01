variable "authorized_ssh_public_keys" {
  type = set(string)
}

variable "b2_account_id" {
  type = string
}

variable "b2_account_key" {
  type      = string
  sensitive = true
  ephemeral = false # because it's persisted into a kubernetes_secret
}

variable "b2_archive_bucket" {
  type = string
}

variable "b2_archive_restic_password" {
  type      = string
  sensitive = true
  ephemeral = false # because it's persisted into a kubernetes_secret
}

variable "docker_hub_password" {
  type      = string
  sensitive = true
  ephemeral = true
}

variable "hydra_nix_signing_secret_key" {
  type      = string
  sensitive = true
  ephemeral = false
}

variable "hydra_postgres_password" {
  type      = string
  sensitive = true
  ephemeral = false
}

variable "refern_email" {
  type = string
}

variable "refern_identity_toolkit_api_key" {
  type      = string
  sensitive = true
  ephemeral = false # because it's persisted into a kubernetes_secret
}

variable "refern_password" {
  type      = string
  sensitive = true
  ephemeral = false # because it's persisted into a kubernetes_secret
}

variable "todoist_api_token" {
  type      = string
  sensitive = true
  ephemeral = false # because it's persisted into a kubernetes_secret
}

variable "todoist_email" {
  type = string
}
