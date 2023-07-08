module "vpc_cni_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name_prefix      = "VPC-CNI-IRSA"
  create_role           = true
  attach_vpc_cni_policy = true
  vpc_cni_enable_ipv4   = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-node"]
    }
  }

  tags = local.tags
}

module "cert_manager_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name_prefix           = "CERT-MANAGER-IRSA"
  create_role                = true
  attach_cert_manager_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["cert-manager:cert-manager-sa"]
    }
  }

  tags = local.tags
}

module "ebs_csi_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name_prefix      = "EBS-CSI-IRSA"
  create_role           = true
  attach_ebs_csi_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }

  tags = local.tags
}

module "alb_controller_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name_prefix                                                = "ALB-CONTROLLER-IRSA"
  create_role                                                     = true
  attach_load_balancer_controller_policy                          = true
  attach_load_balancer_controller_targetgroup_binding_only_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:alb-controller-sa"]
    }
  }

  tags = local.tags
}

module "ext_secrets_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name_prefix               = "EXT-SECRETS-IRSA"
  create_role                    = true
  attach_external_secrets_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["external-secrets:external-secrets-sa"]
    }
  }

  tags = local.tags
}

module "adot_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name_prefix                                = "ADOT-IRSA"
  create_role                                     = true
  attach_amazon_managed_service_prometheus_policy = true
  role_policy_arns = {
    policy0 = "arn:aws:iam::aws:policy/AmazonPrometheusRemoteWriteAccess"
    policy1 = "arn:aws:iam::aws:policy/AWSXrayWriteOnlyAccess"
    policy2 = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  }

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["default:adot-collector"]
    }
  }

  tags = local.tags
}

module "jenkins_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name_prefix = "JENKINS-IRSA"
  create_role      = true
  role_policy_arns = {
    policy0 = aws_iam_policy.jenkins_eks.arn
  }

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["jenkins:jenkins-sa", "jenkins:jenkins-agent-sa"]
    }
  }

  tags = local.tags
}

data "aws_iam_policy_document" "jenkins_eks" {

  statement {
    actions = [
      "eks:ListClusters",
      "eks:AccessKubernetesApi",
      "eks:DescribeCluster",
      "eks:ListNodegroups"
    ]

    resources = [module.eks.cluster_arn]
  }

}

resource "aws_iam_policy" "jenkins_eks" {

  name_prefix = "Jenkins_Policy-"
  path        = "/"
  description = "Provides permissions for Jenkins and Jenkins Agents"
  policy      = data.aws_iam_policy_document.jenkins_eks.json

  tags = local.tags
}