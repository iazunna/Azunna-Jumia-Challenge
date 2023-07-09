
data "aws_iam_policy_document" "admin_assume_role" {
  statement {
    sid     = "UserAssumeRole"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::992122884453:user/iazunna"]
    }
    effect = "Allow"
  }
}

data "aws_iam_policy_document" "iam_pass_role" {
  statement {
    effect    = "Allow"
    actions   = ["iam:PassRole"]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values = [
        "eks.amazonaws.com"
      ]
    }
  }
}

resource "aws_iam_role" "admin_role" {
  name                 = "admin_role"
  path                 = "/users/"
  assume_role_policy   = data.aws_iam_policy_document.admin_assume_role.json
  managed_policy_arns  = ["arn:aws:iam::aws:policy/AdministratorAccess"]
  max_session_duration = 43200
  inline_policy {
    name = "iamPassRole_policy"
    policy = data.aws_iam_policy_document.iam_pass_role.json
  }
}