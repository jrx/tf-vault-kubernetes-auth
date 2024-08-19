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

variable "kubernetes-host" {
  type    = string
  default = "https://172.20.0.1:443"
}

variable "kubernetes-app-service-account" {
  type    = string
  default = "my-app"
}

variable "kubernetes-app-secret-destination" {
  type    = string
  default = "secretkv"
}

variable "kubernetes-app-namespace" {
  type    = string
  default = "default"
}

variable "kubernetes-app-business-unit" {
  type    = string
  default = "tenant-1"
}

variable "kubernetes-app-business-segment" {
  type    = string
  default = "team-a"
}