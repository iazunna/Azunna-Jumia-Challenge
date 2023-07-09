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
    adot = {
      most_recent              = true
      service_account_role_arn = module.adot_irsa.iam_role_arn
    }
    aws-ebs-csi-driver = {
      most_recent              = true
      service_account_role_arn = module.ebs_csi_irsa.iam_role_arn
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      addon_version            = "v1.12.6-eksbuild.2"
      preserve                 = true
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
    {
      rolearn = aws_iam_role.admin_role.arn
      username = "adminuser:{{SessionName}}"
      groups   = ["system:masters"]
    }
  ]


  ################################
  # Node Groups
  ################################

  eks_managed_node_group_defaults = {
    # By default, the module creates a launch template to ensure tags are propagated to instances, etc.,
    # so we need to disable it to use the default template provided by the AWS EKS managed node group service
    use_custom_launch_template = false

    ami_type                   = "BOTTLEROCKET_x86_64"
    platform                   = "bottlerocket"
    instance_types             = ["t3.medium", "t3a.medium", "t2.medium"]
    capacity_type              = "SPOT"
    force_update_version       = true
    subnet_ids                 = module.vpc.private_subnets
    ami_id                     = data.aws_ami.eks_default_bottlerocket.image_id
    enable_bootstrap_user_data = true
    labels                     = local.node_labels
    remote_access = {
      ec2_ssh_key               = module.key_pair.key_pair_name
      source_security_group_ids = [aws_security_group.remote_access.id]
    }

    metadata_options = {
      http_endpoint               = "enabled"
      http_tokens                 = "required"
      http_put_response_hop_limit = 2
      instance_metadata_tags      = "disabled"
    }

    # We are using the IRSA created below for permissions
    # However, we have to deploy with the policy attached FIRST (when creating a fresh cluster)
    # and then turn this off after the cluster/node group is created. Without this initial policy,
    # the VPC CNI fails to assign IPs and nodes cannot join the cluster
    # See https://github.com/aws/containers-roadmap/issues/1666 for more context
    iam_role_attach_cni_policy = false

    ebs_optimized     = true
    enable_monitoring = true

    create_iam_role          = true
    iam_role_name            = "eks-managed-node-group-role"
    iam_role_use_name_prefix = true
    iam_role_description     = "EKS managed node group for jumia phone validator app"
    iam_role_tags            = local.tags
    iam_role_additional_policies = {
      AmazonEC2ContainerRegistryReadOnly = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
    }

    block_device_mappings = {
      xvda = {
        device_name = "/dev/xvda"
        ebs = {
          volume_size           = 100
          volume_type           = "gp3"
          iops                  = 3000
          throughput            = 150
          encrypted             = true
          kms_key_id            = module.ebs_kms_key.key_arn
          delete_on_termination = true
        }
      }
    }

    tags = local.tags
  }

  eks_managed_node_groups = {

    jenkins-group = {
      min_size     = 1
      max_size     = 2
      desired_size = 1
      labels = merge(local.node_labels, {
        app = "jenkins"
      })

      taints = [
        {
          key    = "application"
          value  = "jenkins"
          effect = "PREFER_NO_SCHEDULE"
        }
      ]

      update_config = {
        max_unavailable_percentage = 50 # or set `max_unavailable`
      }

      description = "EKS managed node group for jenkins"
    }

    # Default node group - as provided by AWS EKS using Bottlerocket
    jumia-phone-validator-group = {
      min_size = 3
      max_size = 6

      desired_size               = 3
      ami_id                     = data.aws_ami.eks_default_bottlerocket.image_id
      enable_bootstrap_user_data = true

      labels = merge(local.node_labels, {
        app = "jumia-phone-validator"
      })

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

module "ebs_kms_key" {
  source  = "terraform-aws-modules/kms/aws"
  version = "~> 1.5"

  description = "Customer managed key to encrypt EKS managed node group volumes"

  # Policy
  key_administrators = [
    data.aws_caller_identity.current.arn
  ]

  key_service_roles_for_autoscaling = [
    # required for the ASG to manage encrypted volumes for nodes
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling",
    # required for the cluster / persistentvolume-controller to create encrypted PVCs
    module.eks.cluster_iam_role_arn,
  ]

  # Aliases
  aliases = ["eks/${local.name}/ebs"]

  tags = local.tags
}

module "key_pair" {
  source  = "terraform-aws-modules/key-pair/aws"
  version = "~> 2.0"

  key_name_prefix    = local.name
  create_private_key = true

  tags = local.tags
}

resource "aws_security_group" "remote_access" {
  name_prefix = "${local.name}-remote-access"
  description = "Allow remote SSH access"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "SSH access"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(local.tags, { Name = "${local.name}-remote-ssh" })
}

output "eks_private_key_openssh" {
  description = "Private key data in OpenSSH PEM (RFC 4716) format"
  value       = module.key_pair.private_key_openssh
  sensitive   = true
}

output "eks_private_key_pem" {
  description = "Private key data in PEM (RFC 1421) format"
  value       = module.key_pair.private_key_pem
  sensitive   = true
}