resource "vault_namespace" "tenant_namespace" {
  path = var.vault-tenant-namespace
}

resource "vault_auth_backend" "kubernetes" {
  type      = "kubernetes"
  namespace = vault_namespace.tenant_namespace.path_fq
}

resource "vault_kubernetes_auth_backend_config" "kubernetes" {
  namespace                         = vault_namespace.tenant_namespace.path_fq
  backend                           = vault_auth_backend.kubernetes.path
  kubernetes_host                   = var.kubernetes-host
  kubernetes_ca_cert                = data.kubernetes_secret.vault-sa.data["ca.crt"]
  token_reviewer_jwt                = data.kubernetes_secret.vault-sa.data["token"]
  use_annotations_as_alias_metadata = true
}

resource "vault_kubernetes_auth_backend_role" "my-app" {
  namespace                        = vault_namespace.tenant_namespace.path_fq
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = "my-app"
  bound_service_account_names      = [var.kubernetes-app-service-account]
  bound_service_account_namespaces = [var.kubernetes-app-namespace]
  token_ttl                        = 3600
  token_policies = [
    vault_policy.app-policy.name,
    vault_policy.pki-policy.name
  ]
  audience = "https://kubernetes.default.svc"
}
