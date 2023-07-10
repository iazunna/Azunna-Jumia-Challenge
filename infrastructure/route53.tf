resource "aws_acm_certificate" "cert" {
  domain_name       = "jumia-devops-challenge.eu"
  validation_method = "DNS"

  tags = local.tags
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_zone" "jumia_challenge" {
  name = "jumia-devops-challenge.eu"
  tags = local.tags
}

resource "aws_route53_record" "dvo" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.jumia_challenge.zone_id
}

resource "aws_acm_certificate_validation" "cert_validation" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.dvo : record.fqdn]
  depends_on = [ 
    aws_route53domains_registered_domain.jumia_challenge
   ]
}

resource "aws_route53domains_registered_domain" "jumia_challenge" {
  domain_name = "jumia-devops-challenge.eu"

  dynamic name_server {
    for_each = toset(aws_route53_zone.jumia_challenge.name_servers)
    content {
      name = name_server.value
    }
  }

  tags = local.tags
}

# resource "aws_route53_zone" "devops" {
#   name = "devops.jumia-devops-challenge.eu"

#   tags = local.tags
# }

# resource "aws_route53_record" "devops-ns" {
#   zone_id = aws_route53_zone.jumia_challenge.zone_id
#   name    = "devops.jumia-devops-challenge.eu"
#   type    = "NS"
#   ttl     = "30"
#   records = aws_route53_zone.devops.name_servers
# }

# resource "aws_kms_key" "jumia_zone_key" {
#   provider = aws.kms_dnssec
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
#         ],
#         Effect = "Allow"
#         Principal = {
#           Service = "dnssec-route53.amazonaws.com"
#         }
#         Sid      = "Allow Route 53 DNSSEC Service",
#         Resource = "*"
#         Condition = {
#           StringEquals = {
#             "aws:SourceAccount" = data.aws_caller_identity.current.account_id
#           }
#           ArnLike = {
#             "aws:SourceArn" = "arn:aws:route53:::hostedzone/*"
#           }
#         }
#       },
#       {
#         Action = "kms:CreateGrant",
#         Effect = "Allow"
#         Principal = {
#           Service = "dnssec-route53.amazonaws.com"
#         }
#         Sid      = "Allow Route 53 DNSSEC Service to CreateGrant",
#         Resource = "*"
#         Condition = {
#           Bool = {
#             "kms:GrantIsForAWSResource" = "true"
#           }
#         }
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

# resource "aws_kms_key" "dev_ops_jumia_zone_key" {
#   provider = aws.kms_dnssec
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
#         ],
#         Effect = "Allow"
#         Principal = {
#           Service = "dnssec-route53.amazonaws.com"
#         }
#         Sid      = "Allow Route 53 DNSSEC Service",
#         Resource = "*"
#         Condition = {
#           StringEquals = {
#             "aws:SourceAccount" = data.aws_caller_identity.current.account_id
#           }
#           ArnLike = {
#             "aws:SourceArn" = "arn:aws:route53:::hostedzone/*"
#           }
#         }
#       },
#       {
#         Action = "kms:CreateGrant",
#         Effect = "Allow"
#         Principal = {
#           Service = "dnssec-route53.amazonaws.com"
#         }
#         Sid      = "Allow Route 53 DNSSEC Service to CreateGrant",
#         Resource = "*"
#         Condition = {
#           Bool = {
#             "kms:GrantIsForAWSResource" = "true"
#           }
#         }
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
#   hosted_zone_id             = aws_route53_zone.jumia_challenge.id
#   key_management_service_arn = aws_kms_key.jumia_zone_key.arn
#   name                       = "mainzonekey"
# }

# resource "aws_route53_hosted_zone_dnssec" "jumia_challenge" {
#   depends_on = [
#     aws_route53_key_signing_key.jumia_zone_key
#   ]
#   hosted_zone_id = aws_route53_key_signing_key.jumia_zone_key.hosted_zone_id
# }

# resource "aws_route53_key_signing_key" "devops_jumia_zone_key" {
#   hosted_zone_id             = aws_route53_zone.devops.id
#   key_management_service_arn = aws_kms_key.dev_ops_jumia_zone_key.arn
#   name                       = "devopsjumiachallengezonekey"
# }

# resource "aws_route53_hosted_zone_dnssec" "dev_ops_jumia_challenge" {
#   depends_on = [
#     aws_route53_key_signing_key.devops_jumia_zone_key
#   ]
#   hosted_zone_id = aws_route53_key_signing_key.devops_jumia_zone_key.hosted_zone_id
# }



