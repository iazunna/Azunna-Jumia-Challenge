
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

resource "aws_iam_role" "admin_role" {
  name               = "admin_role"
  path               = "/users/"
  assume_role_policy = data.aws_iam_policy_document.admin_assume_role.json
  managed_policy_arns = ["arn:aws:iam::aws:policy/AdministratorAccess"]
}