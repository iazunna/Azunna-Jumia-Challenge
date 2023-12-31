module "karpenter" {
  source = "terraform-aws-modules/eks/aws//modules/karpenter"

  cluster_name = module.eks.cluster_name

  irsa_oidc_provider_arn          = module.eks.oidc_provider_arn
  irsa_namespace_service_accounts = ["karpenter:karpenter"]

  tags = local.tags
}

resource "helm_release" "karpenter" {
  repository_username = "anonymous"
  repository_password = ""

  name             = "karpenter"
  repository       = "oci://public.ecr.aws/karpenter"
  chart            = "karpenter"
  version          = "v0.29.0"
  namespace        = "karpenter"
  create_namespace = true
  atomic           = true

  set {
    name  = "settings.aws.clusterName"
    value = module.eks.cluster_name
  }

  set {
    name  = "settings.aws.interruptionQueueName"
    value = module.eks.cluster_name
  }

  set {
    name  = "settings.aws.defaultInstanceProfile"
    value = "KarpenterNodeInstanceProfile-${module.eks.cluster_name}"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.karpenter.irsa_arn
  }

  set {
    name  = "controller.resources.requests.cpu"
    value = "1"
  }

  set {
    name  = "controller.resources.requests.memory"
    value = "1Gi"
  }

  set {
    name  = "controller.resources.limits.cpu"
    value = "1"
  }

  set {
    name  = "controller.resources.limits.memory"
    value = "1Gi"
  }

  depends_on = [
    module.eks,
    helm_release.ingress
  ]
}
