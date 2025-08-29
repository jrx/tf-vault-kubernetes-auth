# root CA

resource "vault_mount" "pki" {
  path                      = "pki"
  type                      = "pki"
  description               = "PKI engine for the root CA"
  default_lease_ttl_seconds = 157680000 # 5 years
  max_lease_ttl_seconds     = 157680000
}

resource "vault_pki_secret_backend_root_cert" "root" {
  depends_on           = [vault_mount.pki]
  backend              = vault_mount.pki.path
  type                 = "internal"
  common_name          = "test.ca.example.com"
  ttl                  = 157680000
  format               = "pem"
  private_key_format   = "der"
  key_type             = "rsa"
  key_bits             = 4096
  exclude_cn_from_sans = true
  max_path_length      = "-1"
  issuer_name          = "root"
}

resource "vault_pki_secret_backend_config_cluster" "root" {
  backend  = vault_mount.pki.path
  path     = "https://127.0.0.1:8200/v1/${var.vault-parent-namespace}/pki"
  aia_path = "https://127.0.0.1:8200/v1/${var.vault-parent-namespace}/pki"
}

resource "vault_pki_secret_backend_config_urls" "root" {
  backend = vault_mount.pki.path
  issuing_certificates = [
    "{{cluster_aia_path}}/issuer/{{issuer_id}}/der",
  ]
  crl_distribution_points = [
    "{{cluster_aia_path}}/issuer/{{issuer_id}}/crl/der",
  ]
  ocsp_servers = [
    "{{cluster_path}}/ocsp",
  ]
  enable_templating = true
}

# intermediate CA

resource "vault_mount" "pki_int" {
  namespace                 = vault_namespace.tenant_namespace.path_fq
  path                      = "pki_int"
  type                      = vault_mount.pki.type
  description               = "PKI engine for the intermediate CA"
  default_lease_ttl_seconds = 78840000 # 2.5 years
  max_lease_ttl_seconds     = 78840000
}

resource "vault_pki_secret_backend_intermediate_cert_request" "intermediate" {
  namespace   = vault_namespace.tenant_namespace.path_fq
  backend     = vault_mount.pki_int.path
  type        = vault_pki_secret_backend_root_cert.root.type
  common_name = "test-intermediate.ca.example.com"
}

resource "vault_pki_secret_backend_root_sign_intermediate" "intermediate" {
  backend              = vault_mount.pki.path
  csr                  = vault_pki_secret_backend_intermediate_cert_request.intermediate.csr
  common_name          = "test-intermediate.ca.example.com"
  exclude_cn_from_sans = true
  revoke               = true
  max_path_length      = "0"
  ttl                  = 78840000
}

resource "vault_pki_secret_backend_intermediate_set_signed" "intermediate" {
  namespace   = vault_namespace.tenant_namespace.path_fq
  backend     = vault_mount.pki_int.path
  certificate = vault_pki_secret_backend_root_sign_intermediate.intermediate.certificate
}

resource "vault_pki_secret_backend_config_cluster" "intermediate" {
  namespace = vault_namespace.tenant_namespace.path_fq
  backend   = vault_mount.pki_int.path
  path      = "https://127.0.0.1:8200/v1/${var.vault-parent-namespace}/${var.vault-tenant-namespace}/pki_int"
  aia_path  = "https://127.0.0.1:8200/v1/${var.vault-parent-namespace}/${var.vault-tenant-namespace}/pki_int"
}

resource "vault_pki_secret_backend_config_urls" "intermediate" {
  namespace = vault_namespace.tenant_namespace.path_fq
  backend   = vault_mount.pki_int.path
  issuing_certificates = [
    "{{cluster_aia_path}}/issuer/{{issuer_id}}/der",
  ]
  crl_distribution_points = [
    "{{cluster_aia_path}}/issuer/{{issuer_id}}/crl/der",
  ]
  ocsp_servers = [
    "{{cluster_path}}/ocsp",
  ]
  enable_templating = true
}

# Test role

resource "vault_pki_secret_backend_role" "test" {
  namespace        = vault_namespace.tenant_namespace.path_fq
  backend          = vault_mount.pki_int.path
  name             = var.kubernetes-app-business-segment
  allowed_domains  = ["test.example.com", "test2.example.com"]
  allow_subdomains = true
  key_type         = "rsa"
  max_ttl          = 2592000
}

# PKI Policy

resource "vault_policy" "pki-policy" {
  namespace = vault_namespace.tenant_namespace.path_fq
  name      = "my-pki-policy"

  policy = <<EOT
path "${vault_mount.pki_int.path}/issue/{{identity.entity.aliases.${vault_auth_backend.kubernetes.accessor}.metadata.BusinessSegmentName}}" {
  capabilities = [ "create", "update"]
}
path "${vault_mount.pki_int.path}/revoke" {
  capabilities = [ "create", "update"]
}
EOT
}

# Sentinel EGP

resource "vault_egp_policy" "restrict-common-name" {
  count             = (var.sentinel == true ? 1 : 0)
  namespace         = vault_namespace.tenant_namespace.path_fq
  name              = "restrict-common-name"
  paths             = ["pki_int/issue/team-a"]
  enforcement_level = "hard-mandatory"

  policy = file("${path.module}/pki.sentinel")
}
