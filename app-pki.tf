resource "kubernetes_manifest" "vault-pki-secret" {
  manifest = {
    apiVersion = "secrets.hashicorp.com/v1beta1"
    kind       = "VaultPKISecret"
    metadata = {
      name      = "vault-pki-app"
      namespace = kubernetes_service_account.app-sa.metadata[0].namespace
    }
    spec = {
      namespace = vault_namespace.tenant_namespace.id
      mount     = vault_mount.pki_int.path
      role      = var.kubernetes-app-business-segment
      destination = {
        name   = var.kubernetes-app-pki-destination
        create = true
      }
      commonName   = "one.test.example.com"
      format       = "pem"
      revoke       = true
      clear        = true
      expiryOffset = "10s"
      ttl          = "120s"
      vaultAuthRef = "static-auth"
    }
  }
}