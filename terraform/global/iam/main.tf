# -----------------------------------------------------------------------------
# OIDC Provider - trusts GitHub Actions as identity provider
# -----------------------------------------------------------------------------
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]

  tags = {
    Name = "github-actions-oidc"
  }
}

# -----------------------------------------------------------------------------
# IAM Role - assumed by GitHub Actions
# -----------------------------------------------------------------------------
data "aws_iam_policy_document" "github_actions_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:kCn3333/aws-devops:*",
        "repo:kCn3333/clients-api:*"
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "github_actions" {
  name               = "github-actions-role"
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume.json
  description        = "Role assumed by GitHub Actions via OIDC"

  tags = {
    Name = "github-actions-role"
  }
}

# -----------------------------------------------------------------------------
# IAM Policy - what GitHub Actions is allowed to do
# -----------------------------------------------------------------------------
data "aws_iam_policy_document" "github_actions_permissions" {
  statement {
    sid    = "TerraformStateAccess"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket"
    ]
    resources = [
      "arn:aws:s3:::kcn-terraform-state",
      "arn:aws:s3:::kcn-terraform-state/*"
    ]
  }

  statement {
    sid       = "EC2Access"
    effect    = "Allow"
    actions   = ["ec2:*"]
    resources = ["*"]
  }

  statement {
    sid    = "IAMAccess"
    effect = "Allow"
    actions = [
      "iam:CreateRole", "iam:DeleteRole", "iam:GetRole", "iam:UpdateRole",
      "iam:AttachRolePolicy", "iam:DetachRolePolicy", "iam:ListAttachedRolePolicies",
      "iam:CreateInstanceProfile", "iam:DeleteInstanceProfile",
      "iam:GetInstanceProfile", "iam:AddRoleToInstanceProfile",
      "iam:RemoveRoleFromInstanceProfile", "iam:ListInstanceProfilesForRole",
      "iam:CreatePolicy", "iam:DeletePolicy", "iam:GetPolicy",
      "iam:GetPolicyVersion", "iam:ListPolicyVersions",
      "iam:CreatePolicyVersion", "iam:DeletePolicyVersion",
      "iam:CreateOpenIDConnectProvider", "iam:DeleteOpenIDConnectProvider",
      "iam:GetOpenIDConnectProvider", "iam:UpdateOpenIDConnectProviderThumbprint",
      "iam:TagRole", "iam:UntagRole", "iam:TagPolicy", "iam:TagOpenIDConnectProvider",
      "iam:ListRolePolicies",
      "iam:PassRole"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "ECSDeployAccess"
    effect = "Allow"
    actions = [
      "ecs:DescribeServices",
      "ecs:UpdateService",
      "ecs:DescribeTasks",
      "ecs:ListTasks",
      "ecs:DescribeTaskDefinition"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "github_actions" {
  name        = "github-actions-policy"
  description = "Permissions for GitHub Actions CI/CD pipeline"
  policy      = data.aws_iam_policy_document.github_actions_permissions.json

  tags = {
    Name = "github-actions-policy"
  }
}

resource "aws_iam_role_policy_attachment" "github_actions" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.github_actions.arn
}