resource "aws_route53_zone" "jumia-challenge" {
  name = "jumia-challenge.eu"
  tags = local.tags
  # vpc {
  #   vpc_id = module.vpc.vpc_id
  # }
}

# resource "aws_kms_key" "jumia_zone_key" {
#   customer_master_key_spec = "ECC_NIST_P256"
#   deletion_window_in_days  = 7
#   key_usage                = "SIGN_VERIFY"
#   policy = jsonencode({
#     Statement = [
#       {
#         Action = [
#           "kms:DescribeKey",
#           "kms:GetPublicKey",
#           "kms:Sign",
#           "kms:Verify",
#         ],
#         Effect = "Allow"
#         Principal = {
#           Service = "dnssec-route53.amazonaws.com"
#         }
#         Resource = "*"
#         Sid      = "Allow Route 53 DNSSEC Service",
#       },
#       {
#         Action = "kms:*"
#         Effect = "Allow"
#         Principal = {
#           AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
#         }
#         Resource = "*"
#         Sid      = "Enable IAM User Permissions"
#       },
#     ]
#     Version = "2012-10-17"
#   })
# }


# resource "aws_route53_key_signing_key" "jumia_zone_key" {
#   hosted_zone_id             = aws_route53_zone.jumia-challenge.id
#   key_management_service_arn = aws_kms_key.jumia_zone_key.arn
#   name                       = "example"
# }

# resource "aws_route53_hosted_zone_dnssec" "example" {
#   depends_on = [
#     aws_route53_key_signing_key.jumia_zone_key
#   ]
#   hosted_zone_id = aws_route53_key_signing_key.jumia_zone_key.hosted_zone_id
# }


# resource "aws_route53_resolver_config" "jumia-challenge" {
#   resource_id              = module.vpc.vpc_id
#   autodefined_reverse_flag = "DISABLE"
# }

# resource "aws_route53_resolver_dnssec_config" "jumia-challenge" {
#   resource_id = module.vpc.vpc_id
# }