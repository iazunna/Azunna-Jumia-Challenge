resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  version          = "1.12.2"
  namespace        = "cert-manager"
  create_namespace = true
  atomic           = true
  values = file("values.cert-manager.yaml")

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = "cert-manager-sa"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.cert_manager_irsa.iam_role_arn
  }
  depends_on = [ 
    module.eks
  ]
}

resource "kubectl_manifest" "cluster_issuer" {
  yaml_body = <<EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-test
  namespace: cert-manager
spec:
  acme:
    email: jumia@example.com
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      # Secret resource that will be used to store the account's private key.
      name: letsencrypt-test-issuer-account-key
    solvers:
      - dns01:
          route53:
            region: ${local.region}
            role: ${module.cert_manager_irsa.iam_role_arn}
EOF
  depends_on = [helm_release.external_secrets]
}