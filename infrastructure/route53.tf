resource "aws_route53_zone" "jumia-challenge" {
  name = "jumia-challenge.com"
  tags = local.tags
}