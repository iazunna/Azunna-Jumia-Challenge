data "aws_caller_identity" "current" {}

################################################################################
# EKS Module
################################################################################

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name                   = local.name
  cluster_version                = local.cluster_version
  cluster_endpoint_public_access = true

  cluster_ip_family = "ipv4"

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    aws-ebs-csi-driver = {
      most_recent = true
      service_account_role_arn = module.ebs_csi_irsa.iam_role_arn
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      addon_version = "v1.12.6-eksbuild.2"
      preserve      = true
      service_account_role_arn = module.vpc_cni_irsa.iam_role_arn
    }
  }

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.intra_subnets

  manage_aws_auth_configmap = true
  aws_auth_roles = [
    {
      rolearn  = module.karpenter.role_arn
      username = "system:node:{{EC2PrivateDNSName}}"
      groups = [
        "system:bootstrappers",
        "system:nodes",
      ]
    },
  ]


################################
# Node Groups
################################

  eks_managed_node_group_defaults = {
    ami_type       = "BOTTLEROCKET_x86_64"
    instance_types = ["t3.medium", "t3a.medium", "t2.medium"]
    capacity_type        = "SPOT"
    force_update_version = true

    # We are using the IRSA created below for permissions
    # However, we have to deploy with the policy attached FIRST (when creating a fresh cluster)
    # and then turn this off after the cluster/node group is created. Without this initial policy,
    # the VPC CNI fails to assign IPs and nodes cannot join the cluster
    # See https://github.com/aws/containers-roadmap/issues/1666 for more context
    iam_role_attach_cni_policy = false
  }

  eks_managed_node_groups = {

    # Default node group - as provided by AWS EKS using Bottlerocket
    jumia-phone-validator-group = {
      # By default, the module creates a launch template to ensure tags are propagated to instances, etc.,
      # so we need to disable it to use the default template provided by the AWS EKS managed node group service
      use_custom_launch_template = false

      min_size     = 3
      max_size     = 6
      ami_type = "BOTTLEROCKET_x86_64"
      platform = "bottlerocket"

      subnet_ids = module.vpc.private_subnets

      desired_size = 3
      ami_id                     = data.aws_ami.eks_default_bottlerocket.image_id
      enable_bootstrap_user_data = true

      labels = {
        type = "eks-managed"
        ManagedBy  = "Terraform"
      }

      taints = [
        {
          key    = "application"
          value  = "JumiaPhoneValidator"
          effect = "PREFER_NO_SCHEDULE"
        }
      ]

      update_config = {
        max_unavailable_percentage = 33 # or set `max_unavailable`
      }

      description = "EKS managed node group for jumia phone validator app"

      ebs_optimized           = true
      enable_monitoring       = true

      metadata_options = {
        http_endpoint               = "enabled"
        http_tokens                 = "required"
        http_put_response_hop_limit = 2
        instance_metadata_tags      = "disabled"
      }

      create_iam_role          = true
      iam_role_name            = "eks-managed-node-group-jumia-phone-validator"
      iam_role_use_name_prefix = false
      iam_role_description     = "EKS managed node group for jumia phone validator app"
      iam_role_tags = local.tags
      iam_role_additional_policies = {
        AmazonEC2ContainerRegistryReadOnly = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
      }

      tags = local.tags
    }
  }

  tags = local.tags
}

################################################################################
# Supporting Resources
################################################################################


data "aws_ami" "eks_default_bottlerocket" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["bottlerocket-aws-k8s-${local.cluster_version}-x86_64-*"]
  }
}