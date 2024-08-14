resource "kubernetes_namespace" "vault-auth" {
  metadata {
    name = var.kubernetes-vault-auth-namespace
  }
}

resource "kubernetes_service_account" "vault-sa" {
  metadata {
    name      = var.kubernetes-vault-auth-service-account
    namespace = kubernetes_namespace.vault-auth.id
  }
}
