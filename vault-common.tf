resource "vault_namespace" "tenant_namespace" {
  path = var.vault-tenant-namespace
}

resource "vault_auth_backend" "kubernetes" {
  type      = "kubernetes"
  namespace = vault_namespace.tenant_namespace.path_fq
}

# Does not work because use_annotations_as_alias_metadata is not supported
# resource "vault_kubernetes_auth_backend_config" "kubernetes" {
#   namespace          = vault_namespace.tenant_namespace.path_fq
#   backend            = vault_auth_backend.kubernetes.path
#   kubernetes_host    = var.kubernetes-host
#   kubernetes_ca_cert = data.kubernetes_secret.vault-sa.data["ca.crt"]
#   token_reviewer_jwt = data.kubernetes_secret.vault-sa.data["token"]
# }

resource "vault_generic_endpoint" "kubernetes_alias_metadata" {
  namespace            = vault_namespace.tenant_namespace.path_fq
  path                 = "auth/kubernetes/config"
  disable_read         = true
  disable_delete       = true
  ignore_absent_fields = true

  data_json = <<EOT
{
  "kubernetes_host": "${var.kubernetes-host}",
  "token_reviewer_jwt": "${data.kubernetes_secret.vault-sa.data["token"]}",
  "kubernetes_ca_cert": "${replace(data.kubernetes_secret.vault-sa.data["ca.crt"], "\n", "\\n")}",
  "use_annotations_as_alias_metadata": true
}
EOT

  depends_on = [vault_auth_backend.kubernetes]
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
