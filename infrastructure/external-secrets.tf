resource "helm_release" "external_secrets" {
  name             = "external-secrets"
  repository       = "https://charts.external-secrets.io"
  chart            = "external-secrets"
  version          = "0.9.0"
  namespace        = "external-secrets"
  create_namespace = true
  atomic           = true

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = "external-secrets-sa"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.ext_secrets_irsa.iam_role_arn
  }
  depends_on = [
    module.eks,
    helm_release.ingress
  ]
}

resource "kubectl_manifest" "parameter_store_backend" {
  yaml_body  = <<EOF
apiVersion: external-secrets.io/v1beta1
kind: ClusterSecretStore
metadata:
  name: parameter-store-backend
  namespace: external-secrets
spec:
  provider:
    aws:
      service: ParameterStore
      region: ${local.region}
      auth:
        jwt:
          serviceAccountRef:
            name: external-secrets-sa
EOF
  depends_on = [helm_release.external_secrets]
}

resource "kubectl_manifest" "sm_backend" {
  yaml_body  = <<EOF
apiVersion: external-secrets.io/v1beta1
kind: ClusterSecretStore
metadata:
  name: secrets-manager-backend
  namespace: external-secrets
spec:
  provider:
    aws:
      service: SecretsManager
      region: ${local.region}
      auth:
        jwt:
          serviceAccountRef:
            name: external-secrets-sa
EOF
  depends_on = [helm_release.external_secrets]
}