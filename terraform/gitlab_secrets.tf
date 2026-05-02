resource "aws_secretsmanager_secret" "demo" {
  count = var.create_demo_secret ? 1 : 0

  name        = "${local.name}/demo"
  description = "Sample secret consumed by examples/gitlab-ci/.gitlab-ci.yml. Safe to delete."
  tags        = local.tags
}

resource "aws_secretsmanager_secret_version" "demo" {
  count = var.create_demo_secret ? 1 : 0

  secret_id     = aws_secretsmanager_secret.demo[0].id
  secret_string = jsonencode({ message = "hello from secrets manager" })
}

locals {
  secrets_reader_secret_arns = concat(
    var.secrets_manager_secret_arns,
    var.create_demo_secret ? [aws_secretsmanager_secret.demo[0].arn] : [],
  )
}

data "aws_iam_policy_document" "gitlab_ci_secrets_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.gitlab.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.gitlab.url, "https://", "")}:aud"
      values   = [var.gitlab_url]
    }

    condition {
      test     = "StringLike"
      variable = "${replace(aws_iam_openid_connect_provider.gitlab.url, "https://", "")}:sub"
      values   = ["project_path:${var.gitlab_project_path}:*"]
    }
  }
}

resource "aws_iam_role" "gitlab_ci_secrets_reader" {
  name               = "${local.name}-gitlab-ci-secrets-reader"
  assume_role_policy = data.aws_iam_policy_document.gitlab_ci_secrets_trust.json
  tags               = local.tags
}

data "aws_iam_policy_document" "gitlab_ci_secrets_reader" {
  count = length(local.secrets_reader_secret_arns) > 0 ? 1 : 0

  statement {
    effect    = "Allow"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = local.secrets_reader_secret_arns
  }
}

resource "aws_iam_role_policy" "gitlab_ci_secrets_reader" {
  count = length(local.secrets_reader_secret_arns) > 0 ? 1 : 0

  name   = "secrets-read"
  role   = aws_iam_role.gitlab_ci_secrets_reader.id
  policy = data.aws_iam_policy_document.gitlab_ci_secrets_reader[0].json
}
