# Kubernetes ServiceAccount

resource "kubernetes_service_account" "app-sa" {
  metadata {
    name      = var.kubernetes-app-service-account
    namespace = var.kubernetes-app-namespace
    annotations = {
      "vault.hashicorp.com/alias-metadata-BusinessUnitName"    = var.kubernetes-app-business-unit
      "vault.hashicorp.com/alias-metadata-BusinessSegmentName" = var.kubernetes-app-business-segment
      "vault.hashicorp.com/alias-metadata-AppName"             = var.kubernetes-app-service-account
      "vault.hashicorp.com/alias-metadata-TLSDomain"           = "one.test.example.com"
    }
  }
}

resource "kubernetes_manifest" "vault-auth" {
  manifest = {
    apiVersion = "secrets.hashicorp.com/v1beta1"
    kind       = "VaultAuth"
    metadata = {
      name      = "static-auth"
      namespace = kubernetes_service_account.app-sa.metadata[0].namespace
    }
    spec = {
      namespace = vault_namespace.tenant_namespace.id
      method    = "kubernetes"
      mount     = vault_auth_backend.kubernetes.path
      kubernetes = {
        role           = vault_kubernetes_auth_backend_role.my-app.role_name
        serviceAccount = kubernetes_service_account.app-sa.metadata[0].name
        audiences      = ["https://kubernetes.default.svc"]
      }
    }
  }
}

# K/V Secret

resource "kubernetes_manifest" "vault-static-secret" {
  manifest = {
    apiVersion = "secrets.hashicorp.com/v1beta1"
    kind       = "VaultStaticSecret"
    metadata = {
      name      = "vault-kv-app"
      namespace = kubernetes_service_account.app-sa.metadata[0].namespace
    }
    spec = {
      namespace = vault_namespace.tenant_namespace.id
      type      = "kv-v2"
      mount     = var.secret-mount
      path      = var.secret-path
      destination = {
        name   = var.kubernetes-app-secret-destination
        create = true
      }
      refreshAfter = "30s"
      vaultAuthRef = "static-auth"
    }
  }
}

# PKI Secret

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
        type   = "kubernetes.io/tls"
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