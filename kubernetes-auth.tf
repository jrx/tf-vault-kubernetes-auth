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

resource "kubernetes_cluster_role_binding" "vault-auth-binding" {
  metadata {
    name = "vault-auth-binding"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "system:auth-delegator"
  }
  subject {
    kind      = "ServiceAccount"
    name      = var.kubernetes-vault-auth-service-account
    namespace = kubernetes_namespace.vault-auth.id
  }
}

resource "kubernetes_cluster_role" "read-serviceaccounts" {
  metadata {
    name = "read-serviceaccounts"
  }

  rule {
    api_groups = [""]
    resources  = ["serviceaccounts"]
    verbs      = ["get", "list"]
  }
}

resource "kubernetes_cluster_role_binding" "read-serviceaccounts-binding" {
  metadata {
    name = "read-serviceaccounts-binding"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.read-serviceaccounts.metadata.0.name
  }
  subject {
    kind      = "ServiceAccount"
    name      = var.kubernetes-vault-auth-service-account
    namespace = kubernetes_namespace.vault-auth.id
  }
}

resource "kubernetes_secret" "vault-sa" {
  metadata {
    name      = "${var.kubernetes-vault-auth-service-account}-secret"
    namespace = kubernetes_namespace.vault-auth.id
    annotations = {
      "kubernetes.io/service-account.name" = var.kubernetes-vault-auth-service-account
    }
  }

  type = "kubernetes.io/service-account-token"
}

data "kubernetes_secret" "vault-sa" {
  metadata {
    name      = kubernetes_secret.vault-sa.metadata.0.name
    namespace = kubernetes_namespace.vault-auth.id
  }
}
