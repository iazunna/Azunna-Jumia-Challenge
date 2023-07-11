
locals {
  zone_recursive_ns = join(":53,", aws_route53_zone.jumia_challenge.name_servers)
}
resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  version          = "1.12.2"
  namespace        = "cert-manager"
  create_namespace = true
  atomic           = true
  values           = [file("values.cert-manager.yaml")]

  set {
    name  = "installCRDs"
    value = "true"
  }

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name = "extraArgs[0]"
    value = "--issuer-ambient-credentials"
  }

  set {
    name = "extraArgs[1]"
    value = "--dns01-recursive-nameservers-only"
  }

  set {
    name = "extraArgs[2]"
    value = "--dns01-recursive-nameservers=8.8.8.8:53,1.1.1.1:53,${local.zone_recursive_ns}"
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
    module.eks,
    helm_release.ingress,
    aws_route53_zone.jumia_challenge,
    # aws_route53_zone.devops
  ]
}

resource "kubectl_manifest" "cluster_issuer" {
  yaml_body  = <<EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-test
  namespace: cert-manager
spec:
  acme:
    email: admin@jumia-devops-challenge.eu
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      # Secret resource that will be used to store the account's private key.
      name: letsencrypt-test-issuer-account-key
    solvers:
      - dns01:
          route53:
            region: ${local.region}
        selector:
          dnsZones:
            - 'jumia-devops-challenge.eu'
            - '*.jumia-devops-challenge.eu'
EOF
  depends_on = [
    helm_release.cert_manager, 
    aws_route53_zone.jumia_challenge,
    # aws_route53_zone.devops
  ]
}