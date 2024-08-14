resource "vault_namespace" "tenant_namespace" {
  path = var.vault-tenant-namespace
}

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

