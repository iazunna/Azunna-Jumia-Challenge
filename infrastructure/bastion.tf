locals {
  ingress_ports = ["22", "80", "443", "8888"]
}

resource "aws_security_group" "bastion" {
  name        = "bastion-sg"
  description = "Allow SSH, HTTP, HTTPS"

  dynamic "ingress" {
    for_each = local.ingress_ports
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  vpc_id = module.vpc.vpc_id

  tags = local.tags
}

data "aws_ami" "amazon-linux-2" {
  owners      = ["amazon"]
  most_recent = true

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "role" {
  name               = "bastion-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "role-policy-attachment" {
  role       = aws_iam_role.role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "systems_manager" {
  name = "bastion-instance-profile"
  role = aws_iam_role.role.name
}

resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.amazon-linux-2.id
  instance_type               = "t3.small"
  iam_instance_profile        = aws_iam_instance_profile.systems_manager.name
  subnet_id                   = module.vpc.public_subnets[0]
  vpc_security_group_ids      = [aws_security_group.bastion.id]
  associate_public_ip_address = true
  key_name = module.key_pair_bastion.key_pair_name

  root_block_device {
    volume_size = 20
  }

  user_data = file("../scripts/bastion-setup.sh")

  tags = merge(local.tags, {
    "Name" = "bastion-ec2"
    }
  )

  volume_tags = merge(local.tags, tomap({
    "Name" = "bastion-ebs"
    })
  )

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
}

module "key_pair_bastion" {
  source  = "terraform-aws-modules/key-pair/aws"
  version = "~> 2.0"

  key_name_prefix    = "bastion"
  create_private_key = true

  tags = local.tags
}

output "bastion_private_key_openssh" {
  description = "Private key data in OpenSSH PEM (RFC 4716) format"
  value       = module.key_pair_bastion.private_key_openssh
  sensitive   = true
}

output "bastion_private_key_pem" {
  description = "Private key data in PEM (RFC 1421) format"
  value       = module.key_pair_bastion.private_key_pem
  sensitive   = true
}
