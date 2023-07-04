data "aws_availability_zones" "available" {}

locals {
  name = "jumia-phone-validator"
  tags = {
    Managed-by = "Terraform"
    Environment = "dev"
  }
  # Networking Locals
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)
  region   = "eu-west-2"
  vpc_cidr = "10.0.0.0/16"

}