resource "helm_release" "external_dns" {
  repository_username = "anonymous"
  repository_password = ""

  name             = "external-dns"
  repository       = "https://charts.bitnami.com/bitnami"
  chart            = "external-dns"
  version          = "6.20.4"
  namespace        = "external-dns"
  create_namespace = true
  atomic           = true

  set {
    name = "aws.region"
    value = local.region
  }

  set {
    name = "domainFilters[0]"
    value = "jumia-devops-challenge.eu"
  }

  set {
    name = "logFormat"
    value = "json"
  }

  set {
    name = "txtOwnerId"
    value = "external-dns"
  }

  set {
    name = "sources[0]"
    value = "service"
  } 

  set {
    name = "sources[1]"
    value = "ingress"
  }
        
  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = "external-dns-sa"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.ext_dns_irsa.iam_role_arn
  }
  depends_on = [
    module.eks,
    helm_release.ingress
  ]
}
