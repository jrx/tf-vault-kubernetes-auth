terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
    }

    vault = {
      source = "hashicorp/vault"
    }
  }
}

provider "vault" {
  namespace = var.vault-parent-namespace
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}