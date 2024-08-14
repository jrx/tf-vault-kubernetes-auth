variable "vault-parent-namespace" {
  type    = string
  default = ""
}

variable "vault-tenant-namespace" {
  type    = string
  default = "tenant-1"
}

variable "secret-mount" {
  type    = string
  default = "secret"
}

variable "secret-path" {
  type    = string
  default = "team-a/my-app/test"
}

variable "kubernetes-vault-auth-namespace" {
  type    = string
  default = "vault-auth"
}

variable "kubernetes-vault-auth-service-account" {
  type    = string
  default = "vault-sa"
}