resource "vault_mount" "tenant_mount" {
  namespace = vault_namespace.tenant_namespace.path_fq
  path      = var.secret-mount
  type      = "kv-v2"
  options = {
    version = "2"
    type    = "kv-v2"
  }
}

resource "vault_kv_secret_v2" "tenant_secret" {
  namespace = vault_namespace.tenant_namespace.path_fq
  mount     = vault_mount.tenant_mount.path
  name      = var.secret-path
  data_json = jsonencode(
    {}
  )

  lifecycle {
    ignore_changes = [
      data_json
    ]
  }
}

resource "vault_policy" "app-policy" {
  namespace = vault_namespace.tenant_namespace.path_fq
  name      = "my-app-policy"

  policy = <<EOT
# Allows to read K/V secrets 
path "${var.secret-mount}/data/{{identity.entity.aliases.${vault_auth_backend.kubernetes.accessor}.metadata.BusinessSegmentName}}/{{identity.entity.aliases.${vault_auth_backend.kubernetes.accessor}.metadata.AppName}}/*" {
    capabilities = ["read"]
}
# Allows reading K/V secret versions and metadata
path "${var.secret-mount}/metadata/{{identity.entity.aliases.${vault_auth_backend.kubernetes.accessor}.metadata.BusinessSegmentName}}/{{identity.entity.aliases.${vault_auth_backend.kubernetes.accessor}.metadata.AppName}}/*" {
      capabilities = ["list", "read"]
}
EOT
}