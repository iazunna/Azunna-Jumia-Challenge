module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = local.name
  cidr = local.vpc_cidr

  azs             = local.azs
  private_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k)]
  public_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 4)]

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }

  enable_nat_gateway = true
  enable_flow_log                      = true
  create_flow_log_cloudwatch_log_group = true
  create_flow_log_cloudwatch_iam_role  = true

  flow_log_destination_type = "cloud-watch-logs"

  flow_log_max_aggregation_interval         = 60
  flow_log_cloudwatch_log_group_name_prefix = "/aws/jumia-challenge-vpc-flow-logs/"
  flow_log_cloudwatch_log_group_name_suffix = "dev"

  vpc_flow_log_tags = local.tags
  tags = local.tags
}